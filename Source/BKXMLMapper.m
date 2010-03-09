//
// BKXMLMapper.m
//
// Copyright (c) 2009-2010 Lukhnos D. Liu (http://lukhnos.org)
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
#import <expat.h>

NSString *const BKXMLMapperExceptionName = @"BKXMLMapperException";
NSString *const BKXMLTextContentKey = @"_text";

static void BKXMExpatParserStart(void *inContext, const char *inElement, const char **attributes);
static void BKXMExpatParserEnd(void *inContext, const char *inElement);
static void BKXMExpatParserCharData(void *inContext, const XML_Char *inString, int inLength);

@interface BKXMLMapper (Flattener)
- (NSArray *)flattenedArray:(NSArray *)inArray;
- (id)flattenedDictionary:(NSDictionary *)inDictionary;
- (id)transformValue:(id)inValue usingTypeInferredFromKey:(NSString *)inKey;

- (void)cleanUpForGCMode;
@end

@implementation BKXMLMapper
- (void)cleanUpForGCMode
{
	CFRelease(dateFormatter);
    dateFormatter = NULL;
}

- (void)finalize
{
    if (dateFormatter) {
        CFRelease(dateFormatter);
    }
    
	[super finalize];
}

- (void)dealloc
{
    if (dateFormatter) {
        CFRelease(dateFormatter);
    }

    [resultantDictionary release];
	[elementStack release];
	[currentElementName release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        
        
        @synchronized([self class]) {
            resultantDictionary = [[NSMutableDictionary alloc] init];
            elementStack = [[NSMutableArray alloc] init];
            
            CFLocaleRef currentLocale = CFLocaleCopyCurrent();		
            CFTimeZoneRef timeZone = CFTimeZoneCreateWithName(NULL, CFSTR("GMT"), NO);
            
            dateFormatter = CFDateFormatterCreate(NULL, currentLocale, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle);		
            CFDateFormatterSetProperty(dateFormatter, kCFDateFormatterTimeZone, timeZone);
            CFDateFormatterSetFormat(dateFormatter, CFSTR("yyyy-MM-dd'T'HH:mm:ss'Z'"));
            
            CFRelease(timeZone);
            CFRelease(currentLocale);
        }
    }
    
    return self;
}

- (void)runWithData:(NSData *)inData
{
	currentDictionary = resultantDictionary;
	
	/*
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:inData];
	[parser setDelegate:self];
	[parser parse];
	[parser release];
    parser = nil;
    */
    
    @synchronized([self class]) {
        XML_Parser parser = XML_ParserCreate("UTF-8");
        XML_SetElementHandler(parser, BKXMExpatParserStart, BKXMExpatParserEnd);
        XML_SetCharacterDataHandler(parser, BKXMExpatParserCharData);
        XML_SetUserData(parser, self);
        XML_Parse(parser, [inData bytes], [inData length], 1);
        XML_ParserFree(parser);
    }
}

- (NSMutableDictionary *)resultantDictionary
{
	return [[resultantDictionary retain] autorelease];
}

- (id)transformValue:(id)inValue usingTypeInferredFromKey:(NSString *)inKey
{
	// exceptions: s (returned directly), dt (date), hrs (NSTimeInterval), c (integer)
	// only two exceptions: s (returned directly), dt (date)
	
	NSUInteger length = [inKey length];
	
	if (length < 2) {
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
	UniChar thirdChar = length > 2 ? [inKey characterAtIndex:2] : 0;	
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
		return [inValue isEqualToString:@"true"] ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;
	}
	
	// transform 'ix'
	if (firstChar == 'i' && secondChar == 'x' && thirdCharIsUpperCase) {
		
		// if it's ixBugChildren or ixRelatedBugs, don't translate it
		if (length == 13 && ([inKey isEqualToString:@"ixBugChildren"] || [inKey isEqualToString:@"ixRelatedBugs"])) {
			return inValue;
		}		
		
		return [NSNumber numberWithUnsignedInteger:[inValue integerValue]];
	}
	
	// transform 'i' or 'n' or 'c'
	if ((firstChar == 'i' || firstChar == 'n' || firstChar == 'c') && secondCharIsUpperCase) {
		return [NSNumber numberWithInteger:[inValue integerValue]];
	}
	
	// transform 'dt'
	if (firstChar == 'd' && secondChar == 't' && thirdCharIsUpperCase) {
		
		NSAssert([inValue isKindOfClass:[NSString class]], @"must be string");
		return NSMakeCollectable(CFDateFormatterCreateDateFromString(NULL, dateFormatter, (CFStringRef)inValue, NULL));
		
	}
	
	// transform 'hrs'
	if (firstChar == 'h' && secondChar == 'r' && thirdChar == 's') {
		return [NSNumber numberWithDouble:[inValue doubleValue]];
	}
	
	return inValue;
}

- (NSArray *)flattenedArray:(NSArray *)inArray
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

- (id)flattenedDictionary:(NSDictionary *)inDictionary
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
			if ([value count]) {			
				value = [self flattenedDictionary:value];
			}
			else {
				value = nil;
			}
		}
		else if ([value isKindOfClass:[NSArray class]]) {
			value = [self flattenedArray:value];
		}
		else {
		}
		
		if (value) {
			value = [self transformValue:value usingTypeInferredFromKey:key];
			[flattenedDictionary setObject:value forKey:key];
		}
	}
	
	return flattenedDictionary;
}

+ (NSDictionary *)dictionaryMappedFromXMLData:(NSData *)inData
{
    // NSXMLParser only allows us to run one instance per thread at any give time, so we need to ensure this
    //	@synchronized(self) {
		BKXMLMapper *mapper = [[BKXMLMapper alloc] init];
		[mapper runWithData:inData];        
		
		// flattens the text contents	
		
		
		NSMutableDictionary *resultantDictionary = [mapper resultantDictionary];	
		NSDictionary *result = [mapper flattenedDictionary:resultantDictionary];
        [mapper cleanUpForGCMode];
		[mapper release];
        mapper = nil;
		return result;
	// }
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
		else if ([currentElementName length] > [elementName length] && [elementName hasSuffix:@"s"] && [currentElementName hasSuffix:@"ses"]) {
			// status, statuses
			[currentDictionary setObject:[NSMutableArray arrayWithObject:mutableAttrDict] forKey:elementName];
		}		
		else if ([currentElementName length] > [elementName length] && [elementName hasSuffix:@"x"] && [currentElementName hasSuffix:@"xes"]) {
			// box, boxes
			[currentDictionary setObject:[NSMutableArray arrayWithObject:mutableAttrDict] forKey:elementName];
		}		
		else if ([currentElementName length] > [elementName length] && [elementName hasSuffix:@"y"] && [currentElementName hasSuffix:@"ies"]) {
			// category, categories
			// priority, priorities
			[currentDictionary setObject:[NSMutableArray arrayWithObject:mutableAttrDict] forKey:elementName];
		}		
		
		else if ([currentElementName isEqualToString:@"people"] && [elementName isEqualToString:@"person"]) {
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

static void BKXMExpatParserStart(void *inContext, const char *inElement, const char **attributes)
{
    BKXMLMapper *mapper = (BKXMLMapper *)inContext;
    NSString *elementName = [NSString stringWithUTF8String:inElement];
    NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];
    
    const char **attr = attributes;
    while (*attr) {
        const char *key = *attr++;
        const char *value = *attr++;        
        [attrDict setObject:[NSString stringWithUTF8String:value] forKey:[NSString stringWithUTF8String:key]];
    }
    
    [mapper parser:nil didStartElement:elementName namespaceURI:nil qualifiedName:nil attributes:attrDict];
}

static void BKXMExpatParserEnd(void *inContext, const char *inElement)
{
    BKXMLMapper *mapper = (BKXMLMapper *)inContext;
    NSString *elementName = [NSString stringWithUTF8String:inElement];
    [mapper parser:nil didEndElement:elementName namespaceURI:nil qualifiedName:nil];
}

static void BKXMExpatParserCharData(void *inContext, const XML_Char *inString, int inLength)
{
    BKXMLMapper *mapper = (BKXMLMapper *)inContext;
    
    NSString *s = [[[NSString alloc] initWithBytes:inString length:inLength encoding:NSUTF8StringEncoding] autorelease];    
    [mapper parser:nil foundCharacters:s];
}
