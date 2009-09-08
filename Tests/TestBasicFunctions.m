//
// TestBasicFunctions.m
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

#import "TestBasicFunctions.h"
#import "TestEndpoint.h"
#import "BKPrivateUtilities.h"



@implementation TestBasicFunctions
+ (BKAPIContext *)sharedAPIContext
{
	static BKAPIContext *sharedInstance = nil;
	if (!sharedInstance) {
		sharedInstance = [[BKAPIContext alloc] init];
	}
	
	return sharedInstance;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)setUp
{	
	[BKBugzContext defaultContext].endpointRootString = kTestEndpoint;
	bugzRequest = [BKBugzRequest defaultRequest];
	bugzRequest.shouldWaitUntilDone = YES;
	
	
	[[self class] sharedAPIContext].serviceRoot = [NSURL URLWithString:kTestEndpoint];
	requestQueue = [[BKRequestQueue alloc] init];
	requestQueue.shouldWaitUntilDone = YES;
}

- (void)tearDown
{
	[requestQueue release];
}

- (void)testTruth
{
	STAssertTrue(YES, @"Truth");
}

- (void)test00_VersionCheckWithFaultyEndpoint
{
	[[self class] sharedAPIContext].serviceRoot = [NSURL URLWithString:@"http://example.org"];
	
	BKVersionCheckRequest *request = [[[BKVersionCheckRequest alloc] initWithAPIContext:[[self class] sharedAPIContext]] autorelease];
	request.target = self;
	request.actionOnSuccess = @selector(versionCheckExpectedNotToComplete:);
	request.actionOnFailure = @selector(versionCheckExpectedToFail:);
	[requestQueue addRequest:request];	
}

- (void)versionCheckExpectedNotToComplete:(BKRequest *)inRequest
{
	STFail(@"This request should not complete: %@, context: %@", inRequest, [[self class] sharedAPIContext]);
}

- (void)versionCheckExpectedToFail:(BKRequest *)inRequest
{
	STAssertNotNil(inRequest.error, @"Must have an error");
}

- (void)test01_VersionCheck
{
	BKVersionCheckRequest *request = [[[BKVersionCheckRequest alloc] initWithAPIContext:[[self class] sharedAPIContext]] autorelease];
	request.target = self;
	request.actionOnSuccess = @selector(versionCheckDidComplete:);
	request.actionOnFailure = @selector(commonAPIFailureHandler:);
	[requestQueue addRequest:request];
}

- (void)versionCheckDidComplete:(BKRequest *)inRequest
{
	STAssertNotNil([[self class] sharedAPIContext].endpoint, @"After check, endpoint must not be nil");
	
	NSLog(@"context: %@", [[self class] sharedAPIContext]);
}

- (void)commonAPIFailureHandler:(BKRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);
	NSLog(@"%s (request %p), error: %@", __PRETTY_FUNCTION__, inRequest, inRequest.error);
}

/*
#pragma mark Version check test

- (void)test0_VersionCheck
{
	[bugzRequest checkVersionWithDelegate:self];
}

- (void)bugzRequest:(BKBugzRequest *)inRequest versionCheckDidCompleteWithVersion:(NSString *)inMajorVersion minorVersion:(NSString *)inMinorVersion
{
	NSLog(@"Fogbuz API, version: %@.%@", inMajorVersion, inMinorVersion);	
}

- (void)bugzRequest:(BKBugzRequest *)inRequest versionCheckDidFailWithError:(NSError *)inError
{
	STFail(@"%@", inError);
}


#pragma mark Test Logging On and Off

- (void)testA_LogOn
{
	[bugzRequest logOnWithUserName:kTestLoginEmail password:kTestLoginPassword delegate:self];
}

- (void)bugzRequest:(BKBugzRequest *)inRequest logOnDidCompleteWithToken:(NSString *)inToken
{
	STAssertTrue([inToken length], @"Must now have obtained auth token");
}

- (void)bugzRequest:(BKBugzRequest *)inRequest logOnDidFailWithAmbiguousNameList:(NSArray *)inNameList
{
	STFail(@"Ambiguous login, suggested name list: %@", inNameList);
}

- (void)bugzRequest:(BKBugzRequest *)inRequest logOnDidFailWithError:(NSError *)inError
{
	STFail(@"%@", inError);	
}


- (void)testZ_LogOff
{
	[bugzRequest logOffWithDelegate:self];
}

- (void)bugzRequestLogOffDidComplete:(BKBugzRequest *)inRequest
{
	STAssertTrue(1, @"Must completed logging off");
}

- (void)bugzRequest:(BKBugzRequest *)inRequest logOffDidFailWithError:(NSError *)inError
{
	STFail(@"%@", inError);		
}

#pragma mark Test Case List Fetch

- (void)testCaseListFetch
{
	[bugzRequest fetchCaseListWithQuery:@"project:inbox" columns:@"sTitle,dtOpened" delegate:self];
}

- (void)bugzRequest:(BKBugzRequest *)inRequest caseListFetchDidCompleteWithList:(NSArray *)inCaseList
{
	NSLog(@"Fetched cases: %@", BKPlistString(inCaseList));
}

- (void)bugzRequest:(BKBugzRequest *)inRequest caseListFetchDidFailWithError:(NSError *)inError
{
}

#pragma mark Test Project List Fetch

- (void)testProjectListFetch
{
	[bugzRequest fetchProjectListWithDelegate:self];
}

- (void)bugzRequest:(BKBugzRequest *)inRequest projectListFetchDidCompleteWithList:(NSArray *)inProjectList
{
	NSLog(@"Fetched projects: %@", BKPlistString(inProjectList));
}

- (void)bugzRequest:(BKBugzRequest *)inRequest projectListFetchDidFailWithError:(NSError *)inError
{
	STFail(@"%@", inError);			
}
*/
@end
