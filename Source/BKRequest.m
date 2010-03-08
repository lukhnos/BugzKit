//
// BKRequest.m
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

#import "BKRequest.h"
#import "BKError.h"
#import "BKPrivateUtilities.h"
#import "BKXMLMapper.h"

@interface BKRequest (PrivateMethods)
- (NSError *)errorFromXMLMappedResponse:(NSDictionary *)inXMLMappedResponse;
- (NSString *)preparedParameterString;
@end


@implementation BKRequest
- (void)dealloc
{
    [APIContext release], APIContext = nil;
    [requestParameterDict release], requestParameterDict = nil;
    [rawXMLMappedResponse release], rawXMLMappedResponse = nil;
	[processedResponse release], processedResponse = nil;
    [error release], error = nil;
    [super dealloc];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext
{
	if (self = [super init]) {
		APIContext = [inAPIContext retain];
	}
	
	return self;
}

#pragma mark NSObject methods

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> {APIContext: %p, req params: %@}", [self class], self, APIContext, requestParameterDict];			
}

#pragma mark Methods to be overriden

- (void)postprocessError:(NSError *)inError
{
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	return inXMLMappedResponse;
}

- (NSError *)validateResponse:(NSDictionary *)inXMLMappedResponse
{
	return nil;
}

#pragma mark Dynamic properties

- (NSString *)HTTPRequestContentType
{
	return @"application/x-www-form-urlencoded";
}

- (NSData *)requestData
{
    if (self.usesPOSTRequest) {
		return [[self preparedParameterString] dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	return nil;
}

- (NSInputStream *)requestInputStream
{
	return nil;
}

- (NSUInteger)requestInputStreamSize
{
	return 0;
}

- (NSURL *)requestURL
{
	if (!self.usesPOSTRequest) {
		NSString *paramsString = [self preparedParameterString];

		return [paramsString length] ? [NSURL URLWithString:[@"?" stringByAppendingString:paramsString] relativeToURL:APIContext.endpoint] : APIContext.endpoint;
	}
		
	return APIContext.endpoint;
}

- (BOOL)usesPOSTRequest
{
    return NO;
}


#pragma mark Dynamic setters

- (void)setRawXMLMappedResponse:(NSDictionary *)inMappedXMLDictionary
{
	NSDictionary *innerResponse = [inMappedXMLDictionary objectForKey:@"response"];
    
	// TODO: Determine if we should handle, e.g. empty response, etc.
    
	NSError *responseError = [self errorFromXMLMappedResponse:innerResponse];
	if (!responseError) {
		responseError = [self validateResponse:innerResponse];
	}
    
	if (responseError) {
        BKReleaseClean(rawXMLMappedResponse);
        BKReleaseClean(processedResponse);
		BKRetainAssign(error, responseError);        
		return;
	}
    
	BKReleaseClean(error);
    
    // TODO: Add a flag saying we don't need to do this--or altogether?
    BKRetainAssign(rawXMLMappedResponse, inMappedXMLDictionary);
	BKRetainAssign(processedResponse, [self postprocessResponse:innerResponse]);							
}

- (void)setProcessedResponse:(id)inResponse
{
    BKRetainAssign(processedResponse, inResponse);
	BKReleaseClean(error);
    BKReleaseClean(rawXMLMappedResponse);
}

- (void)setError:(NSError *)inError
{
    BKRetainAssign(error, inError);
    BKReleaseClean(rawXMLMappedResponse);
    BKReleaseClean(processedResponse);
}

@synthesize rawXMLMappedResponse;
@synthesize processedResponse;
@synthesize error;
@end


@implementation BKRequest (PrivateMethods)
- (NSError *)errorFromXMLMappedResponse:(NSDictionary *)inXMLMappedResponse
{
	NSDictionary *errorDictionary = [inXMLMappedResponse objectForKey:@"error"];
	if ([errorDictionary count]) {
		NSString *errorDomain = BKAPIErrorDomain;
		NSString *localizedMessage = NSLocalizedString(errorDictionary.textContent, nil);
		NSInteger errorCode = [[errorDictionary objectForKey:@"code"] integerValue];			
		
		return [NSError errorWithDomain:errorDomain code:errorCode userInfo:(!localizedMessage ? nil : [NSDictionary dictionaryWithObjectsAndKeys:localizedMessage, NSLocalizedDescriptionKey, nil])];		
	}
	
	return nil;
}

- (NSString *)preparedParameterString
{
	NSDictionary *dict = requestParameterDict;
	NSMutableArray *params = [NSMutableArray array];
	for (NSString *key in dict) {
		id value = [dict objectForKey:key];
		
		if (value == [NSNull null]) {
			value = @"";
		}
		else if ([value isKindOfClass:[NSNumber class]]) {
			value = [NSString stringWithFormat:@"%ju", (uintmax_t)[value unsignedIntegerValue]];
		}
		else if ([value isKindOfClass:[NSDate class]]) {
			CFLocaleRef currentLocale = CFLocaleCopyCurrent();		
			CFTimeZoneRef timeZone = CFTimeZoneCreateWithName(NULL, (CFStringRef)@"GMT", NO);			
			CFDateFormatterRef dateFormatter = CFDateFormatterCreate(NULL, currentLocale, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle);		
			CFDateFormatterSetProperty(dateFormatter, kCFDateFormatterTimeZone, timeZone);
			CFDateFormatterSetFormat(dateFormatter, (CFStringRef)@"yyyy-MM-dd'T'HH:mm:ss'Z'");			
            
			value = NSMakeCollectable(CFDateFormatterCreateStringWithDate(NULL, dateFormatter, (CFDateRef)value));
            
			CFRelease(dateFormatter);
			CFRelease(timeZone);
			CFRelease(currentLocale);
		}
		
		[params addObject:[NSString stringWithFormat:@"%@=%@", key, BKEscapedURLStringFromNSString(value)]];
	}
	
	return [params count] ? [params componentsJoinedByString:@"&"] : nil;
}
@end
