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

#import <objc/runtime.h>
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

- (BKAPIContext *)sharedAPIContext
{
	return [[self class] sharedAPIContext];
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
	
	
	[self sharedAPIContext].serviceRoot = [NSURL URLWithString:kTestEndpoint];
	requestQueue = [[BKRequestQueue alloc] init];
	requestQueue.shouldWaitUntilDone = YES;
}

- (void)tearDown
{
	[requestQueue release];
}


#pragma mark Test truth

- (void)testTruth
{
	STAssertTrue(YES, @"Truth");

}

#pragma mark Test failed version check

- (void)test00_VersionCheckWithFaultyEndpoint
{
	[self sharedAPIContext].serviceRoot = [NSURL URLWithString:@"http://example.org"];
	
	BKVersionCheckRequest *request = [[[BKVersionCheckRequest alloc] initWithAPIContext:[self sharedAPIContext]] autorelease];
	request.target = self;
	request.actionOnSuccess = @selector(versionCheckExpectedNotToComplete:);
	request.actionOnFailure = @selector(versionCheckExpectedToFail:);
	[requestQueue addRequest:request];	
}

- (void)versionCheckExpectedNotToComplete:(BKRequest *)inRequest
{
	STFail(@"This request should not complete: %@, context: %@", inRequest, [self sharedAPIContext]);
}

- (void)versionCheckExpectedToFail:(BKRequest *)inRequest
{
	STAssertNotNil(inRequest.error, @"Must have an error");
}


#pragma mark Test version check

- (void)test01_VersionCheck
{
	BKVersionCheckRequest *request = [[[BKVersionCheckRequest alloc] initWithAPIContext:[self sharedAPIContext]] autorelease];
	request.target = self;
	request.actionOnSuccess = @selector(versionCheckDidComplete:);
	request.actionOnFailure = @selector(commonAPIFailureHandler:);
	[requestQueue addRequest:request];
}

- (void)versionCheckDidComplete:(BKRequest *)inRequest
{
	STAssertNotNil([self sharedAPIContext].endpoint, @"After check, endpoint must not be nil");
}

- (void)commonAPIFailureHandler:(BKRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);
}


#pragma mark Test failed logon

- (void)test02_LogOnWithWrongPassword
{
	// you ain't going to use this as password are you?
	NSString *wrongPassword = @"zzzzzzzz";
	BKLogOnRequest *request = [[[BKLogOnRequest alloc] initWithAPIContext:[self sharedAPIContext] accountName:kTestLoginEmail password:wrongPassword] autorelease];
	request.target = self;
	request.actionOnSuccess = @selector(logOnExpectedNotToComplete:);
	request.actionOnFailure = @selector(logOnExpectedToFail:);
	[requestQueue addRequest:request];							   
}

- (void)logOnExpectedNotToComplete:(BKRequest *)inRequest
{
	STAssertNil([self sharedAPIContext].authToken, @"Logon should fail");
}

- (void)logOnExpectedToFail:(BKRequest *)inRequest
{
	STAssertEquals([inRequest.error code], 1, @"Should be an invalid username/password error");
	STAssertNil([self sharedAPIContext].authToken, @"Logon failure should zero out authToken");
}

#pragma mark Test successful logoff

- (void)test03_LogOnWithCorrectPassword
{
	// you ain't going to use this as password are you?
	BKLogOnRequest *request = [[[BKLogOnRequest alloc] initWithAPIContext:[self sharedAPIContext] accountName:kTestLoginEmail password:kTestLoginPassword] autorelease];
	request.target = self;
	request.actionOnSuccess = @selector(logOnDidComplete:);
	request.actionOnFailure = @selector(logOnDidFail:);
	[requestQueue addRequest:request];							   
}

- (void)logOnDidComplete:(BKRequest *)inRequest
{
	STAssertNotNil([self sharedAPIContext].authToken, @"Logon should return an authToken");
}

- (void)logOnDidFail:(BKRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);
}

- (void)testZZ_LogOff
{
	BKLogOffRequest *request = [[[BKLogOffRequest alloc] initWithAPIContext:[self sharedAPIContext]] autorelease];
	request.target = self;
	request.actionOnSuccess = @selector(logOffDidComplete:);
	request.actionOnFailure = @selector(logOffDidFail:);
	[requestQueue addRequest:request];	
}

- (void)logOffDidComplete:(BKRequest *)inRequest
{
	STAssertNil([self sharedAPIContext].authToken, @"authToken should be zeroed out after logoff");
}

- (void)logOffDidFail:(BKRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);
}


#pragma mark Test list items

- (void)testLists
{
	NSArray *lists = [NSArray arrayWithObjects:BKProjectList, BKCategoryList, BKPriorityList, BKPeopleList, BKStatusList, BKFixForList, BKMailboxList, nil];
	
	for (NSString *t in lists) {
		BKListRequest *request = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:t writableItemsOnly:NO] autorelease];
		request.target = self;
		request.actionOnSuccess = @selector(listDidComplete:);
		request.actionOnFailure = @selector(listDidFail:);								  
		[requestQueue addRequest:request];
	}

	BKListRequest *projectListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKProjectList writableItemsOnly:NO] autorelease];
	projectListRequest.target = self;
	projectListRequest.actionOnSuccess = @selector(projectListDidComplete:);
	projectListRequest.actionOnFailure = @selector(listDidFail:);								  
	[requestQueue addRequest:projectListRequest];
	
	NSArray *projects = objc_getAssociatedObject(self, @"projects");
	for (NSDictionary *p in projects) {
		BKAreaListRequest *request = [[[BKAreaListRequest alloc] initWithAPIContext:[self sharedAPIContext] projectID:[[p objectForKey:@"ixProject"] integerValue] writableItemsOnly:NO] autorelease];
		request.target = self;
		request.actionOnSuccess = @selector(areaListDidComplete:);
		request.actionOnFailure = @selector(listDidFail:);
		request.userInfo = p;
		[requestQueue addRequest:request];
	}
	
	objc_setAssociatedObject(self, @"projects", nil, OBJC_ASSOCIATION_RETAIN);	
}

- (void)listDidComplete:(BKListRequest *)inRequest
{
	STAssertTrue([inRequest.processedResponse isKindOfClass:[NSArray class]], @"Processed response must be some kind of array");	
	NSLog(@"request type: %@, returned array count: %d", inRequest.listType, [inRequest.processedResponse count]);
}

- (void)projectListDidComplete:(BKListRequest *)inRequest
{
	[self listDidComplete:inRequest];	
	objc_setAssociatedObject(self, @"projects", inRequest.processedResponse, OBJC_ASSOCIATION_RETAIN);
}

- (void)areaListDidComplete:(BKAreaListRequest *)inRequest
{
	STAssertTrue([inRequest.processedResponse isKindOfClass:[NSArray class]], @"Processed response must be some kind of array");		
	NSArray *areaNames = [inRequest.processedResponse valueForKeyPath:@"sArea"];	
	NSLog(@"Project %@, areas: %@", [inRequest.userInfo objectForKey:@"sProject"], [areaNames componentsJoinedByString:@","]);
}

- (void)listDidFail:(BKListRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);	
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


