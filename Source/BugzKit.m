//
// BugzKit.m
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

#import "BugzKit.h"
#import "BKXMLMapper.h"

static NSString *kRequestHTTPMethodKey = @"kRequestHTTPMethodKey";
static NSString *kRequestURLKey = @"kRequestURLKey";
static NSString *kRequestDataKey = @"kRequestDataKey";
static NSString *kRequestDelegateKey = @"kRequestDelegateKey";

@implementation BKBugzRequest
- (void)dealloc
{
    [endpointString release];
    endpointString = nil;
    
    [requestInfoQueue release];
    requestInfoQueue = nil;
    
    [request release];
    request = nil;
    
    [super dealloc];
}

- (id)init
{
	if (self = [super init]) {
		endpointString = @"";
		requestInfoQueue = [[NSMutableArray alloc] init];
		request = [[LFHTTPRequest alloc] init];
		request.delegate = self;
	}
	
	return self;
}

- (void)_runQueue
{
    if ([request isRunning]) {
        return;
    }
    
    if (![requestInfoQueue count]) {
        return;
    }

    NSDictionary *nextRequestInfo = [requestInfoQueue objectAtIndex:0];
	request.sessionInfo = nextRequestInfo;

	// we must remove in advance in this mode, otherwise if any exception is raised, the object never gets removed
	if (request.shouldWaitUntilDone) {
		[requestInfoQueue removeObjectAtIndex:0];
	}
	
    NSURL *requestURL = [nextRequestInfo objectForKey:kRequestURLKey];
    id requestData = [nextRequestInfo objectForKey:kRequestDataKey];	
    if (requestData == [NSNull null]) {
        requestData = nil;
    }
    
    BOOL canRequest = [request performMethod:[nextRequestInfo objectForKey:kRequestHTTPMethodKey] onURL:requestURL withData:requestData];
	NSAssert(canRequest, @"HTTP request must be made");

	if (!request.shouldWaitUntilDone) {
		[requestInfoQueue removeObjectAtIndex:0];
	}    
}

- (void)runQueue
{
    if (request.shouldWaitUntilDone) {
        [self _runQueue];
    }
    else {
        [self performSelector:@selector(_runQueue) withObject:nil afterDelay:0.0];
    }
}

- (void)pushRequestInfoWithHTTPMethod:(NSString *)inHTTPMethod URL:(NSURL *)inURL data:(NSData *)inData delegate:(id)inDelegate
{
    id data = inData ? inData : (id)[NSNull null];
    [requestInfoQueue addObject:[NSDictionary dictionaryWithObjectsAndKeys:inHTTPMethod, kRequestHTTPMethodKey, inURL, kRequestURLKey, data, kRequestDataKey, inDelegate, kRequestDelegateKey, nil]];
	[self runQueue];
}

- (void)checkVersionWithDelegate:(id<BKBugzVersionCheckDelegate>)inDelegate
{
    NSString *URLString = [endpointString stringByAppendingString:@"/api.xml"];
    
    [self pushRequestInfoWithHTTPMethod:LFHTTPRequestGETMethod URL:[NSURL URLWithString:URLString] data:nil delegate:inDelegate];
}

#pragma mark LFHTTPRequest delegates

- (void)httpRequest:(LFHTTPRequest *)inRequest didReceiveStatusCode:(NSUInteger)statusCode URL:(NSURL *)url responseHeader:(CFHTTPMessageRef)header
{
	NSLog(@"%s, status: %jd, URL: %@", __PRETTY_FUNCTION__, (uintmax_t)statusCode, url);
}

- (void)httpRequestDidComplete:(LFHTTPRequest *)inRequest
{
	NSLog(@"%s, response as string: %@", __PRETTY_FUNCTION__, [[[NSString alloc] initWithData:request.receivedData encoding:NSUTF8StringEncoding] autorelease]);
	
	NSDictionary *mappedDictionary = [BKXMLMapper dictionaryMappedFromXMLData:request.receivedData];
	NSLog(@"data: %@", mappedDictionary);
}

- (void)httpRequest:(LFHTTPRequest *)inRequest didFailWithError:(NSString *)error
{
	NSLog(@"%s, error: %@", __PRETTY_FUNCTION__, error);
}

#pragma mark Properties

- (BOOL)shouldWaitUntilDone
{
	return request.shouldWaitUntilDone;
}

- (void)setShouldWaitUntilDone:(BOOL)inValue
{
	request.shouldWaitUntilDone = inValue;
}


@synthesize endpointString;
@end

NSString *const BKBugzConnectionErrorDomain = @"BKBugzConnectionErrorDomain";
NSString *const BKBugzAPIErrorDomain = @"BKBugzAPIErrorDomain";
