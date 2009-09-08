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
    [userInfo release];
    [APIContext release];
    [requestParameterDict release];
    [response release];
    [error release];
    [creationDate release];
    [super dealloc];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext
{
	if (self = [super init]) {
		APIContext = [inAPIContext retain];
		creationDate = [[NSDate date] retain];
	}
	
	return self;
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
		return [NSURL URLWithString:[@"?" stringByAppendingString:[self preparedParameterString]] relativeToURL:APIContext.endpoint];
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

@synthesize target;
@synthesize actionOnSuccess;
@synthesize actionOnFailure;
@synthesize userInfo;
@synthesize APIContext;
@synthesize requestParameterDict;
@synthesize response;
@synthesize error;
@synthesize creationDate;
@end

@implementation BKRequest (ProtectedMethods)
- (void)requestQueue:(BKRequestQueue *)inQueue didCompleteWithData:(NSData *)inData
{
	BKRetainAssign(response, [[BKXMLMapper dictionaryMappedFromXMLData:inData] objectForKey:@"response"]);
	
	NSError *responseError = [self errorFromXMLMappedResponse];
	if (responseError) {
		BKRetainAssign(error, responseError);
		[target performSelector:actionOnFailure withObject:self];
	}

    [self postprocessResponse];
    [target performSelector:actionOnSuccess withObject:[self extractedResponse]];   
}

- (void)requestQueue:(BKRequestQueue *)inQueue didFailWithError:(NSString *)inHTTPRequestError
{
	NSInteger errorCode = BKUnknownError;
	
	if ([inHTTPRequestError isEqualToString:LFHTTPRequestConnectionError]) {
		errorCode = BKConnecitonLostError;
	}
	else if ([inHTTPRequestError isEqualToString:LFHTTPRequestTimeoutError]) {
		errorCode = BKConnecitonTimeoutError;
	}

	BKRetainAssign(error, [NSError errorWithDomain:BKBugzConnectionErrorDomain code:errorCode userInfo:nil]);	
	
	[target performSelector:actionOnFailure withObject:self];
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
		[params addObject:[NSString stringWithFormat:@"%@=%@", key, BKEscapedURLStringFromNSString([dict objectForKey:key])]];
	}
	
	return [params componentsJoinedByString:@"&"];	
}

- (NSError *)errorFromXMLMappedResponse
{
	NSDictionary *errorDictionary = [response objectForKey:@"error"];
	if ([errorDictionary count]) {
		NSString *errorDomain = BKBugzAPIErrorDomain;
		NSString *localizedMessage = NSLocalizedString(errorDictionary.textContent, nil);
		NSInteger errorCode = [[errorDictionary objectForKey:@"code"] integerValue];			
		
		return [NSError errorWithDomain:errorDomain code:errorCode userInfo:(!localizedMessage ? nil : [NSDictionary dictionaryWithObjectsAndKeys:localizedMessage, NSLocalizedDescriptionKey, nil])];		
	}
	
	return nil;
}

- (void)postprocessResponse
{    
}

- (id)extractedResponse
{
    return response;
}
@end
