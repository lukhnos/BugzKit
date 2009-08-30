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

static NSString *LFPlistString(id plist)
{
	NSString *error;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
	
	if (!data) {
		return @"(not a valid plist)";
	}
	
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}


@implementation TestBasicFunctions
- (void)dealloc
{
	[super dealloc];
}

- (void)setUp
{	
	[BKBugzContext defaultContext].endpointRootString = kTestEndpoint;
	bugzRequest = [BKBugzRequest defaultRequest];
	bugzRequest.shouldWaitUntilDone = YES;
}

- (void)tearDown
{
}

- (void)testTruth
{
	STAssertTrue(YES, @"Truth");
}

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
	NSLog(@"Fetched cases: %@", LFPlistString(inCaseList));
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
	NSLog(@"Fetched projects: %@", LFPlistString(inProjectList));
}

- (void)bugzRequest:(BKBugzRequest *)inRequest projectListFetchDidFailWithError:(NSError *)inError
{
	STFail(@"%@", inError);			
}

@end
