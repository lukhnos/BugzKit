//
// BKRequest.m
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

#import "BKRequest.h"
#import "BKRequest+ProtectedMethods.h"
#import "BKError.h"
#import "BKPrivateUtilities.h"
#import "BKXMLMapper.h"
#import "LFWebAPIKit.h"

@implementation BKRequest
- (void)dealloc
{
    target = nil;
    actionOnSuccess = NULL;
    actionOnFailure = NULL;
	[blockOnSuccess release];
	[blockOnFailure release];
    [userInfo release];
    [APIContext release];
    [requestParameterDict release];
	[rawResponseData release];
    [rawXMLMappedResponse release];
	[processedResponse release];
    [error release];
    [creationDate release];
    [super dealloc];
}

+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext
{
	return [[[[self class] alloc] initWithAPIContext:inAPIContext] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext
{
	if (self = [super init]) {
		APIContext = [inAPIContext retain];
		creationDate = [[NSDate date] retain];
	}
	
	return self;
}

- (void)setTarget:(id)inTarget actionOnSuccess:(SEL)inActionOnSuccess actionOnFailure:(SEL)inActionOnFailure
{
	target = inTarget;
	actionOnFailure = inActionOnFailure;
	actionOnSuccess = inActionOnSuccess;
}

- (NSString *)HTTPRequestContentType
{
	return LFHTTPRequestWWWFormURLEncodedContentType;
}

- (NSString *)HTTPRequestMethod
{
	return LFHTTPRequestGETMethod;
}

- (NSURL *)requestURL
{
	if ([self.HTTPRequestMethod isEqualToString:LFHTTPRequestGETMethod]) {
		NSString *paramsString = [self preparedParameterString];

		return [paramsString length] ? [NSURL URLWithString:[@"?" stringByAppendingString:paramsString] relativeToURL:APIContext.endpoint] : APIContext.endpoint;
	}
		
	return APIContext.endpoint;
}

- (NSData *)requestData
{
    if ([self.HTTPRequestMethod isEqualToString:LFHTTPRequestPOSTMethod]) {
		return [[self preparedParameterString] dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	return nil;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> {created: %@, target: %p, actionOnSuccess: %s, actionOnFailure: %s, userInfo: %@, APIContext: %p, req params: %@}",
			[self class],
			self,
			creationDate,
			target,
			actionOnSuccess,
			actionOnFailure,
			userInfo,
			APIContext,
			requestParameterDict];			
}

- (NSString *)rawResponseString
{
	return [[[NSString alloc] initWithData:rawResponseData encoding:NSUTF8StringEncoding] autorelease];
}

@synthesize target;
@synthesize actionOnSuccess;
@synthesize actionOnFailure;
@synthesize blockBeforeRequestStart;
@synthesize blockOnSuccess;
@synthesize blockOnFailure;
@synthesize blockAfterRequestEnd;
@synthesize userInfo;
@synthesize APIContext;
@synthesize requestParameterDict;
@synthesize rawResponseData;
@synthesize rawXMLMappedResponse;
@synthesize processedResponse;
@synthesize error;
@synthesize creationDate;
@end

@implementation BKRequest (ProtectedMethods)
- (void)recycleIfUsedBefore
{
	if (rawResponseData) {	
		BKRetainAssign(rawResponseData, nil);
		BKRetainAssign(rawXMLMappedResponse, nil);
		BKRetainAssign(processedResponse, nil);
		BKRetainAssign(error, nil);
		BKRetainAssign(creationDate, [NSDate date]);
	}
}

- (void)requestQueueWillBeginRequest:(BKRequestQueue *)inQueue
{
	if (blockBeforeRequestStart) {
		blockBeforeRequestStart(self);
	}
}

- (void)requestQueueRequestDidFinish:(BKRequestQueue *)inQueue
{
	if (blockAfterRequestEnd) {
		blockAfterRequestEnd(self);
	}
}

- (void)requestQueue:(BKRequestQueue *)inQueue didCompleteWithData:(NSData *)inData
{
	BKRetainAssign(rawResponseData, inData);
	BKRetainAssign(rawXMLMappedResponse, [BKXMLMapper dictionaryMappedFromXMLData:inData]);

	// TO DO: Determine if we should handle, e.g. empty response, etc.
	NSDictionary *innerResponse = [rawXMLMappedResponse objectForKey:@"response"];

	NSError *responseError = [self errorFromXMLMappedResponse:innerResponse];
	
	if (!responseError) {
		responseError = [self validateResponse:innerResponse];
	}
	
	if (responseError) {
		BKRetainAssign(error, responseError);
		BKRetainAssign(processedResponse, nil);
		
		[self postprocessError:responseError];
		
		if (blockOnFailure) {
			blockOnFailure(self);
		}
		else if (actionOnFailure) {
			[target performSelector:actionOnFailure withObject:self];
		}
		return;
	}

	BKRetainAssign(error, nil);
	BKRetainAssign(processedResponse, [self postprocessResponse:innerResponse]);							
	
	if (blockOnSuccess) {
		blockOnSuccess(self);
	}
	else if (actionOnSuccess) {
		[target performSelector:actionOnSuccess withObject:self];   
	}
}

- (void)requestQueue:(BKRequestQueue *)inQueue didFailWithError:(NSString *)inHTTPRequestError
{
	NSInteger errorCode = BKUnknownError;
	
	if ([inHTTPRequestError isEqualToString:LFHTTPRequestConnectionError]) {
		errorCode = BKConnecitonLostError;
	}
	else if ([inHTTPRequestError isEqualToString:LFHTTPRequestTimeoutError]) {
		errorCode = BKConnectionTimeoutError;
	}
	else if ([inHTTPRequestError isEqualToString:BKHTTPRequestServerError]) {
		errorCode = BKConnectionServerHTTPError;
	}

	BKRetainAssign(error, [NSError errorWithDomain:BKConnectionErrorDomain code:errorCode userInfo:nil]);	
	
	if (blockOnFailure) {
		blockOnFailure(self);
	}
	else if (actionOnFailure) {
		[target performSelector:actionOnFailure withObject:self];
	}
}

- (NSDictionary *)preparedParameterDict
{
	return requestParameterDict;
}

- (NSString *)preparedParameterString
{
	NSDictionary *dict = [self preparedParameterDict];
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
			// TO DO: See assert
			NSAssert(0, @"NSDate mapping not yet completed");
		}
		
		[params addObject:[NSString stringWithFormat:@"%@=%@", key, BKEscapedURLStringFromNSString(value)]];
	}
	
	return [params count] ? [params componentsJoinedByString:@"&"] : nil;
}

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

- (void)postprocessError:(NSError *)inError
{
}

- (NSError *)validateResponse:(NSDictionary *)inXMLMappedResponse
{
	return nil;
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	return inXMLMappedResponse;
}
@end

NSString *const BKHTTPRequestServerError = @"BKHTTPRequestServerError";