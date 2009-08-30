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
static NSString *kRequestHandlerPrefixKey = @"kRequestHandlerPrefixKey";
static NSString *kRequestProcessErrorKey = @"kRequestProcessErrorKey";
static NSString *kRequestExtraInfoKey = @"kRequestExtraInfoKey";
static NSString *kRequestResponseHandlerKey = @"kRequestResponseHandlerKey";
static NSString *kRequestFailureHandlerKey = @"kRequestFailureHandlerKey";

NS_INLINE NSString *BKEscapedURLStringFromNSString(NSString *inStr)
{
	CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)inStr, NULL, CFSTR("&"), kCFStringEncodingUTF8);
	
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4	
	return (NSString *)[escaped autorelease];			    
#else
	return (NSString *)[NSMakeCollectable(escaped) autorelease];			    
#endif
}

@implementation BKBugzContext
- (void)dealloc
{
    [endpointRootString release];
    
    [authToken release];
    authToken = nil;
    
    [super dealloc];
}

+ (BKBugzContext *)defaultContext
{
	static BKBugzContext *context = nil;
	if (!context) {
		context = [[BKBugzContext alloc] init];
	}
	
	return context;
}

- (void)setEndpointRootString:(NSString *)inEndpoint
{
	NSString *tmp = endpointRootString;
	
	if ([inEndpoint hasSuffix:@"@/"]) {
		endpointRootString = [inEndpoint retain];
	}
	else {
		endpointRootString = [[inEndpoint stringByAppendingString:@"/"] retain];
	}
	
	[tmp autorelease];
}

- (NSString *)endpointRootString
{
	return [[endpointRootString retain] autorelease];
}

@synthesize serviceEndpointString;
@synthesize authToken;
@end

@implementation BKBugzRequest
- (void)dealloc
{
    [context release];
    context = nil;
    
    [requestInfoQueue release];
    requestInfoQueue = nil;
    
	request.delegate = nil;
	[request cancelWithoutDelegateMessage];
    [request release];
    request = nil;
    
    [super dealloc];
}

+ (BKBugzRequest *)defaultRequest
{
	static BKBugzRequest *request = nil;
	if (!request) {
		request = [[BKBugzRequest alloc] init];
	}
	
	return request;
}

- (id)init
{
	if (self = [super init]) {
		context = [[BKBugzContext defaultContext] retain];
		requestInfoQueue = [[NSMutableArray alloc] init];
		request = [[LFHTTPRequest alloc] init];
		request.timeoutInterval = 30.0;
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

- (NSURL *)serviceURLWithCommand:(NSString *)inCommand arguments:(NSDictionary *)inArguments
{
	NSMutableArray *params = [NSMutableArray array];
	[params addObject:[NSString stringWithFormat:@"cmd=%@", inCommand]];
	
	for (NSString *key in inArguments) {
		[params addObject:[NSString stringWithFormat:@"%@=%@", key, BKEscapedURLStringFromNSString([inArguments objectForKey:key])]];
	}
	
	NSString *serviceURLString = [NSString stringWithFormat:@"%@%@", context.serviceEndpointString, [params componentsJoinedByString:@"&"]];
	return [NSURL URLWithString:serviceURLString];	
}

- (void)pushRequestInfoWithHTTPMethod:(NSString *)inHTTPMethod URL:(NSURL *)inURL data:(NSData *)inData handlerPrefix:(NSString *)inPrefix processDefaultErrorResponse:(BOOL)inProcessError delegate:(id)inDelegate extraInfo:(NSDictionary *)inExtraInfo
{
    id data = inData ? inData : (id)[NSNull null];
	id extra = inExtraInfo ? inExtraInfo : [NSDictionary dictionary];
	
	// assert that we have the <prefix>ResponseHandler, the delegate has the <prefix>DidFail handler:
	NSString *responseHandler = [NSString stringWithFormat:@"%@ResponseHandler:sessionInfo:", inPrefix];
	NSString *failureHandler = [NSString stringWithFormat:@"bugzRequest:%@DidFailWithError:", inPrefix];
	NSAssert1([self respondsToSelector:NSSelectorFromString(responseHandler)], @"API instance must respond to %@", responseHandler);
	NSAssert1([inDelegate respondsToSelector:NSSelectorFromString(failureHandler)], @"Delegate must respond to %s", failureHandler);
		
    [requestInfoQueue addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 inHTTPMethod, kRequestHTTPMethodKey, 
								 inURL, kRequestURLKey, 
								 data, kRequestDataKey, 
								 inPrefix, kRequestHandlerPrefixKey,
								 [NSNumber numberWithBool:inProcessError], kRequestProcessErrorKey, 
								 inDelegate, kRequestDelegateKey, 
								 extra, kRequestExtraInfoKey, 
								 responseHandler, kRequestResponseHandlerKey,
								 failureHandler, kRequestFailureHandlerKey,
								 nil]];
	[self runQueue];
}

#pragma mark Version Check

- (void)checkVersionWithDelegate:(id<BKBugzVersionCheckDelegate>)inDelegate
{
    NSString *URLString = [context.endpointRootString stringByAppendingString:@"api.xml"];    
    [self pushRequestInfoWithHTTPMethod:LFHTTPRequestGETMethod URL:[NSURL URLWithString:URLString] data:nil handlerPrefix:@"versionCheck" processDefaultErrorResponse:YES delegate:inDelegate extraInfo:nil];
}

- (void)versionCheckResponseHandler:(NSDictionary *)inResponse sessionInfo:(NSDictionary *)inSessionInfo
{
	id delegate = [inSessionInfo objectForKey:kRequestDelegateKey];
	NSAssert([delegate respondsToSelector:@selector(bugzRequest:versionCheckDidCompleteWithVersion:minorVersion:)], @"Delegate must have handler");
	
	NSString *majorVersion = [inResponse objectForKey:@"version"];
	NSString *minorVersion = [inResponse objectForKey:@"minversion"];
	context.serviceEndpointString = [NSString stringWithFormat:@"%@%@", context.endpointRootString, [inResponse objectForKey:@"url"]];
	
	[delegate bugzRequest:self versionCheckDidCompleteWithVersion:majorVersion minorVersion:minorVersion];
}

#pragma mark Log On

- (void)logOnWithUserName:(NSString *)inUserName password:(NSString *)inPassword delegate:(id<BKBugzLogOnDelegate>)inDelegate
{
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:inUserName, @"email",inPassword, @"password", nil];
	NSURL *serviceURL = [self serviceURLWithCommand:@"logon" arguments:params];	
	[self pushRequestInfoWithHTTPMethod:LFHTTPRequestPOSTMethod URL:serviceURL data:nil handlerPrefix:@"logOn" processDefaultErrorResponse:NO delegate:inDelegate extraInfo:params];
}

- (void)logOnResponseHandler:(NSDictionary *)inResponse sessionInfo:(NSDictionary *)inSessionInfo
{
	id delegate = [inSessionInfo objectForKey:kRequestDelegateKey];	
	
	NSString *token = [inResponse objectForKey:@"token"];	
	if (token) {
		NSAssert([delegate respondsToSelector:@selector(bugzRequest:logOnDidCompleteWithToken:)], @"Delegate must have handler");
		
		context.authToken = token;
		[delegate bugzRequest:self logOnDidCompleteWithToken:context.authToken];
	}
	else {
		// TO DO: Handle ambiguous names
		
		NSInteger errorCode = BKUnknownError;
		NSString *errorDomain = BKBugzAPIErrorDomain;
		NSString *localizedMessage = nil;
		
		NSDictionary *errorBlock = [inResponse objectForKey:@"error"];
		if (errorBlock) {
			localizedMessage = errorBlock.textContent;
			errorCode = [[errorBlock objectForKey:@"code"] integerValue];
		}
		
		NSError *error = [NSError errorWithDomain:errorDomain code:errorCode userInfo:(!localizedMessage ? nil : [NSDictionary dictionaryWithObjectsAndKeys:localizedMessage, NSLocalizedDescriptionKey, nil])];
		[delegate bugzRequest:self logOnDidFailWithError:error];
	}
}


#pragma mark Log Off

- (void)logOffWithDelegate:(id<BKBugzLogOffDelegate>)inDelegate
{
	NSAssert(context.authToken, @"Must have auth token");
	NSURL *serviceURL = [self serviceURLWithCommand:@"logoff" arguments:[NSDictionary dictionaryWithObjectsAndKeys:context.authToken, @"token", nil]];
	[self pushRequestInfoWithHTTPMethod:LFHTTPRequestPOSTMethod URL:serviceURL data:nil handlerPrefix:@"logOff" processDefaultErrorResponse:YES delegate:inDelegate extraInfo:nil];	
}

- (void)logOffResponseHandler:(NSDictionary *)inResponse sessionInfo:(NSDictionary *)inSessionInfo
{
	id delegate = [inSessionInfo objectForKey:kRequestDelegateKey];	
	NSAssert([delegate respondsToSelector:@selector(bugzRequestLogOffDidComplete:)], @"Delegate must have handler");
	
	context.authToken = nil;
	[delegate bugzRequestLogOffDidComplete:self];
}

#pragma mark Fetch Case List

- (void)fetchCaseListWithQuery:(NSString *)inQuery columns:(NSString *)inColumnList delegate:(id<BKBugzCaseListFetchDelegate>)inDelegate
{
	[self fetchCaseListWithQuery:inQuery columns:inColumnList maximumCount:NSUIntegerMax delegate:inDelegate];
}

- (void)fetchCaseListWithQuery:(NSString *)inQuery columns:(NSString *)inColumnList maximumCount:(NSUInteger)inMaximum delegate:(id<BKBugzCaseListFetchDelegate>)inDelegate
{
	NSAssert(context.authToken, @"Must have auth token");
	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:context.authToken forKey:@"token"];
	[params setObject:inQuery forKey:@"q"];
	if ([inColumnList length]) {
		[params setObject:inColumnList forKey:@"cols"];
	}
	
	if (inMaximum != NSUIntegerMax) {
		[params setObject:[NSString stringWithFormat:@"%ju", (uintmax_t)inMaximum] forKey:@"max"];
	}
	
	NSURL *serviceURL = [self serviceURLWithCommand:@"search" arguments:params];
	[self pushRequestInfoWithHTTPMethod:LFHTTPRequestGETMethod URL:serviceURL data:nil handlerPrefix:@"caseListFetch" processDefaultErrorResponse:YES delegate:inDelegate extraInfo:nil];
}

- (void)caseListFetchResponseHandler:(NSDictionary *)inResponse sessionInfo:(NSDictionary *)inSessionInfo
{
	id delegate = [inSessionInfo objectForKey:kRequestDelegateKey];
	NSAssert([delegate respondsToSelector:@selector(bugzRequest:caseListFetchDidCompleteWithList:)], @"Delegate must have handler");
	
	id caseList = [inResponse valueForKeyPath:@"cases.case"];
	
	if (![caseList isKindOfClass:[NSArray class]]) {
		caseList = [NSArray array];
	}
		
	[delegate bugzRequest:self caseListFetchDidCompleteWithList:caseList];
}

- (void)editCaseWithCommand:(NSString *)inCommand caseNumber:(NSUInteger)inCaseNumber arguments:(NSDictionary *)inArguments delegate:(id<BKBugzCaseEditDelegate>)inDelegate
{
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	if (inCaseNumber) {
		[params setObject:[NSString stringWithFormat:@"%ju", (intmax_t)inCaseNumber] forKey:@"ixBug"];
	}
	
	if (inArguments) {
		[params addEntriesFromDictionary:inArguments];
	}

	[params setObject:context.authToken forKey:@"token"];

	NSURL *serviceURL = [self serviceURLWithCommand:inCommand arguments:params];
	[self pushRequestInfoWithHTTPMethod:LFHTTPRequestPOSTMethod URL:serviceURL data:nil handlerPrefix:@"caseEdit" processDefaultErrorResponse:YES delegate:inDelegate extraInfo:nil];
}

- (void)newCaseWithArguments:(NSDictionary *)inArguments delegate:(id<BKBugzCaseEditDelegate>)inDelegate
{
	[self editCaseWithCommand:@"new" caseNumber:0 arguments:inArguments delegate:inDelegate];
}

- (void)editCaseWithCaseNumber:(NSUInteger)inCaseNumber arguments:(NSDictionary *)inArguments delegate:(id<BKBugzCaseEditDelegate>)inDelegate
{
	[self editCaseWithCommand:@"edit" caseNumber:inCaseNumber arguments:inArguments delegate:inDelegate];
}

- (void)assignCaseWithCaseNumber:(NSUInteger)inCaseNumber arguments:(NSDictionary *)inArguments delegate:(id<BKBugzCaseEditDelegate>)inDelegate
{
	[self editCaseWithCommand:@"assign" caseNumber:inCaseNumber arguments:inArguments delegate:inDelegate];
}

- (void)reactivateCaseWithCaseNumber:(NSUInteger)inCaseNumber arguments:(NSDictionary *)inArguments delegate:(id<BKBugzCaseEditDelegate>)inDelegate
{
	[self editCaseWithCommand:@"reactivate" caseNumber:inCaseNumber arguments:inArguments delegate:inDelegate];
}

- (void)reopenCaseWithCaseNumber:(NSUInteger)inCaseNumber arguments:(NSDictionary *)inArguments delegate:(id<BKBugzCaseEditDelegate>)inDelegate;
{
	[self editCaseWithCommand:@"reopen" caseNumber:inCaseNumber arguments:inArguments delegate:inDelegate];
}

- (void)resolveCaseWithCaseNumber:(NSUInteger)inCaseNumber arguments:(NSDictionary *)inArguments delegate:(id<BKBugzCaseEditDelegate>)inDelegate;
{
	[self editCaseWithCommand:@"resolve" caseNumber:inCaseNumber arguments:inArguments delegate:inDelegate];
}

- (void)closeCaseWithCaseNumber:(NSUInteger)inCaseNumber arguments:(NSDictionary *)inArguments delegate:(id<BKBugzCaseEditDelegate>)inDelegate;
{
	[self editCaseWithCommand:@"close" caseNumber:inCaseNumber arguments:inArguments delegate:inDelegate];
}

- (void)caseEditResponseHandler:(NSDictionary *)inResponse sessionInfo:(NSDictionary *)inSessionInfo
{
	id delegate = [inSessionInfo objectForKey:kRequestDelegateKey];
	NSAssert([delegate respondsToSelector:@selector(bugzRequest:caseEditDidCompleteWithArguments:)], @"Delegate must have handler");
	
	[delegate bugzRequest:self caseEditDidCompleteWithArguments:[inSessionInfo objectForKey:kRequestExtraInfoKey]];
}


- (void)fetchProjectListWithDelegate:(id<BKBugzProjectListFetchDelegate>)inDelegate
{
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:context.authToken forKey:@"token"];
	
	NSURL *serviceURL = [self serviceURLWithCommand:@"listProjects" arguments:params];
	[self pushRequestInfoWithHTTPMethod:LFHTTPRequestPOSTMethod URL:serviceURL data:nil handlerPrefix:@"projectListFetch" processDefaultErrorResponse:YES delegate:inDelegate extraInfo:nil];	
}

- (void)projectListFetchResponseHandler:(NSDictionary *)inResponse sessionInfo:(NSDictionary *)inSessionInfo
{
	id delegate = [inSessionInfo objectForKey:kRequestDelegateKey];
	NSAssert([delegate respondsToSelector:@selector(bugzRequest:projectListFetchDidCompleteWithList:)], @"Delegate must have handler");	
	
	NSLog(@"rsp: %@", inResponse);
	[delegate bugzRequest:self projectListFetchDidCompleteWithList:[inResponse valueForKeyPath:@"projects.project"]];
}

#pragma mark LFHTTPRequest delegates

- (void)httpRequest:(LFHTTPRequest *)inRequest didReceiveStatusCode:(NSUInteger)statusCode URL:(NSURL *)url responseHeader:(CFHTTPMessageRef)header
{
}

- (void)httpRequestDidComplete:(LFHTTPRequest *)inRequest
{
	NSDictionary *sessionInfo = inRequest.sessionInfo;	
	NSDictionary *mappedDictionary = [BKXMLMapper dictionaryMappedFromXMLData:request.receivedData];
	NSDictionary *response = [mappedDictionary objectForKey:@"response"];
	
	if ([[sessionInfo objectForKey:kRequestProcessErrorKey] boolValue]) {
		NSDictionary *errorDictionary = [response objectForKey:@"error"];
		if ([errorDictionary count]) {
			NSString *errorDomain = BKBugzAPIErrorDomain;
			NSString *localizedMessage = NSLocalizedString(errorDictionary.textContent, nil);
			NSInteger errorCode = [[errorDictionary objectForKey:@"code"] integerValue];			

			NSError *error = [NSError errorWithDomain:errorDomain code:errorCode userInfo:(!localizedMessage ? nil : [NSDictionary dictionaryWithObjectsAndKeys:localizedMessage, NSLocalizedDescriptionKey, nil])];		
			id delegate = [sessionInfo objectForKey:kRequestDelegateKey];
			SEL failureHandlerSel = NSSelectorFromString([sessionInfo objectForKey:kRequestFailureHandlerKey]);
			[delegate performSelector:failureHandlerSel withObject:self withObject:error];
			return;					
		}
	}
	
	[self performSelector:NSSelectorFromString([sessionInfo objectForKey:kRequestResponseHandlerKey]) withObject:response withObject:inRequest.sessionInfo];
}

- (void)httpRequest:(LFHTTPRequest *)inRequest didFailWithError:(NSString *)inError
{
	NSLog(@"%s, error: %@", __PRETTY_FUNCTION__, inError);
	
	NSString *errorDomain = BKBugzConnectionErrorDomain;
	NSString *localizedMessage = nil;
	NSInteger errorCode = BKUnknownError;
	
	if ([inError isEqualToString:LFHTTPRequestConnectionError]) {
		errorCode = BKConnecitonLostError;
	}
	else if ([inError isEqualToString:LFHTTPRequestTimeoutError]) {
		errorCode = BKConnecitonTimeoutError;
	}
	else {
		;
	}
	NSError *error = [NSError errorWithDomain:errorDomain code:errorCode userInfo:(!localizedMessage ? nil : [NSDictionary dictionaryWithObjectsAndKeys:localizedMessage, NSLocalizedDescriptionKey, nil])];
		
	NSDictionary *sessionInfo = inRequest.sessionInfo;
	id delegate = [sessionInfo objectForKey:kRequestDelegateKey];
	SEL failureHandlerSel = NSSelectorFromString([sessionInfo objectForKey:kRequestFailureHandlerKey]);
	[delegate performSelector:failureHandlerSel withObject:self withObject:error];
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

@synthesize context;
@end

NSString *const BKBugzConnectionErrorDomain = @"BKBugzConnectionErrorDomain";
NSString *const BKBugzAPIErrorDomain = @"BKBugzAPIErrorDomain";
