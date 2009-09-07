//
// BKXMLMapper.m
//
// Copyright (c) 2009 Lukhnos D. Liu (http://lukhnos.org)
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "BKXMLMapper.h"

NSString *const BKXMLMapperExceptionName = @"BKXMLMapperException";
NSString *const BKXMLTextContentKey = @"_text";

@interface NSDate (ISO8601)
+ (NSDate *)dateFromISO8601String:(NSString *)inString;
@end

@implementation NSDate (ISO8601)
+ (NSDate *)dateFromISO8601String:(NSString *)inString
{
	static NSDateFormatter *sISO8601 = nil;
	
	if (!sISO8601) {
		sISO8601 = [[NSDateFormatter alloc] init];
		[sISO8601 setTimeStyle:NSDateFormatterFullStyle];
		[sISO8601 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	}
	
	return [sISO8601 dateFromString:inString];
}
@end

@interface BKXMLMapper (Flattener)
+ (NSArray *)flattenedArray:(NSArray *)inArray;
+ (id)flattenedDictionary:(NSDictionary *)inDictionary;
+ (id)transformValue:(id)inValue usingTypeInferredFromKey:(NSString *)inKey;
@end

@implementation BKXMLMapper
- (void)dealloc
{
    [resultantDictionary release];
	[elementStack release];
	[currentElementName release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        resultantDictionary = [[NSMutableDictionary alloc] init];
		elementStack = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)runWithData:(NSData *)inData
{
	currentDictionary = resultantDictionary;
	
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:inData];
	[parser setDelegate:self];
	[parser parse];
	[parser release];
}

- (NSMutableDictionary *)resultantDictionary
{
	return [[resultantDictionary retain] autorelease];
}

+ (id)transformValue:(id)inValue usingTypeInferredFromKey:(NSString *)inKey
{
	// exceptions: s (returned directly), dt (date), hrs (NSTimeInterval), c (integer)
	// only two exceptions: s (returned directly), dt (date)
	
	if ([inKey length] < 2) {
		if ([inKey isEqualToString:@"c"]) {
			return [NSNumber numberWithUnsignedInteger:[inValue integerValue]];
		}
		
		if ([inKey isEqualToString:@"s"] && [inValue isKindOfClass:[NSDictionary class]] && ![inValue count]) {
			// s cannot be an empty dictionary--must be a string
			inValue = @"";
		}
		
		return inValue;
	}
			
	UniChar firstChar = [inKey characterAtIndex:0];
	UniChar secondChar = [inKey characterAtIndex:1];	
	UniChar thirdChar = [inKey length] > 2 ? [inKey characterAtIndex:2] : 0;	
	BOOL secondCharIsUpperCase = (secondChar >= 'A' &&  secondChar <= 'Z');
	BOOL thirdCharIsUpperCase = [inKey isEqualToString:@"dt"] ? YES : (thirdChar >= 'A' && thirdChar <= 'Z');

	// 's[A-Z][a-z]+ cannot be an empty dictionary
	if (firstChar == 's' && secondCharIsUpperCase  && [inValue isKindOfClass:[NSDictionary class]] && ![inValue count]) {
		return @"";
	}
	
	// other than that, returns everything
	if (![inValue isKindOfClass:[NSString class]]) {
		return inValue;
	}
	
	
	// transform 'f' or 'b'
	if ((firstChar == 'f' || firstChar == 'b') && secondCharIsUpperCase) {
		return [inKey isEqualToString:@"true"] ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;
	}
	
	// transform 'ix'
	if (firstChar == 'i' && secondChar == 'x' && thirdCharIsUpperCase) {
		return [NSNumber numberWithUnsignedInteger:[inValue integerValue]];
	}
	
	// transform 'dt'
	if (firstChar == 'd' && secondChar == 't' && thirdCharIsUpperCase) {
		return [NSDate dateFromISO8601String:inValue];
	}
	
	// transform 'hrs'
	if (firstChar == 'h' && secondChar == 'r' && thirdChar == 's') {
		return [NSNumber numberWithDouble:[inValue doubleValue]];
	}
	
	return inValue;
}

+ (NSArray *)flattenedArray:(NSArray *)inArray
{
	NSMutableArray *flattenedArray = [NSMutableArray array];
	
	for (id value in inArray) {
		if ([value isKindOfClass:[NSDictionary class]]) {
			[flattenedArray addObject:[self flattenedDictionary:value]];
		}
		else {
			[flattenedArray addObject:value];
		}
	}
			
	return flattenedArray;
}

+ (id)flattenedDictionary:(NSDictionary *)inDictionary
{
	if (![inDictionary count]) {
		return inDictionary;
	}
	
	NSString *textContent = [inDictionary objectForKey:BKXMLTextContentKey];
	if (textContent && [inDictionary count] == 1) {
		return textContent;
	}
	
	NSMutableDictionary *flattenedDictionary = [NSMutableDictionary dictionary];
	
	for (NSString *key in inDictionary) {
		id value = [inDictionary objectForKey:key];
		
		if ([value isKindOfClass:[NSDictionary class]]) {
			value = [self flattenedDictionary:value];
		}
		else if ([value isKindOfClass:[NSArray class]]) {
			value = [self flattenedArray:value];
		}
		else {
		}
		
		value = [self transformValue:value usingTypeInferredFromKey:key];
		[flattenedDictionary setObject:value forKey:key];
	}
	
	return flattenedDictionary;
}

+ (NSDictionary *)dictionaryMappedFromXMLData:(NSData *)inData
{
	BKXMLMapper *mapper = [[BKXMLMapper alloc] init];
	[mapper runWithData:inData];
	
	// flattens the text contents	
	
	
	NSMutableDictionary *resultantDictionary = [mapper resultantDictionary];	
	NSDictionary *result = [self flattenedDictionary:resultantDictionary];
	[mapper release];
	return result;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	NSMutableDictionary *mutableAttrDict = attributeDict ? [NSMutableDictionary dictionaryWithDictionary:attributeDict] : [NSMutableDictionary dictionary];

	// see if it's duplicated
	id element;
	if (element = [currentDictionary objectForKey:elementName]) {
		if (![element isKindOfClass:[NSMutableArray class]]) {
			if ([element isKindOfClass:[NSMutableDictionary class]]) {
				[element retain];
				[currentDictionary removeObjectForKey:elementName];
				
				NSMutableArray *newArray = [NSMutableArray arrayWithObject:element];
				[currentDictionary setObject:newArray forKey:elementName];
				[element release];
				
				element = newArray;
			}
			else {
				// ignore, because we have things like <event ixBugEvent="17" ixBug="5"> and inside a duplicate <ixBugEvent>17</ixBugEvent> 
			}
		}
		
		if ([element isKindOfClass:[NSMutableArray class]]) {
			[element addObject:mutableAttrDict];
		}
	}
	else {
		// plural tag rule: if the parent's tag is plural and the incoming is singular, we'll make it into an array (we only handles the -s case)
		
		if ([currentElementName length] > [elementName length] && [currentElementName hasPrefix:elementName] && [currentElementName hasSuffix:@"s"]) {
			[currentDictionary setObject:[NSMutableArray arrayWithObject:mutableAttrDict] forKey:elementName];
		}
		else {
			[currentDictionary setObject:mutableAttrDict forKey:elementName];
		}
	}
	
	[elementStack insertObject:currentDictionary atIndex:0];
	currentDictionary = mutableAttrDict;
	
	NSString *tmp = currentElementName;
	currentElementName = [elementName retain];
	[tmp release];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if (![elementStack count]) {
		@throw [NSException exceptionWithName:BKXMLMapperExceptionName reason:@"Unbalanced XML element tag closing" userInfo:nil];
	}
	
	currentDictionary = [elementStack objectAtIndex:0];
	[elementStack removeObjectAtIndex:0];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	NSString *existingContent = [currentDictionary objectForKey:BKXMLTextContentKey];
	if (existingContent) {
		NSString *newContent = [existingContent stringByAppendingString:string];
		[currentDictionary setObject:newContent forKey:BKXMLTextContentKey];		
	}
	else {
		[currentDictionary setObject:string forKey:BKXMLTextContentKey];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	[resultantDictionary release];
	resultantDictionary = nil;
}
@end

@implementation NSDictionary (BKXMLMapperExtension)
- (NSString *)textContent
{
    return [self objectForKey:BKXMLTextContentKey];
}

- (NSString *)textContentForKey:(NSString *)inKey
{
	return [[self objectForKey:inKey] objectForKey:BKXMLTextContentKey];
}

- (NSString *)textContentForKeyPath:(NSString *)inKeyPath
{
	return [[self valueForKeyPath:inKeyPath] objectForKey:BKXMLTextContentKey];
}

@end
