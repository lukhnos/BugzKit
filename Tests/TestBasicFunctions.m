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
		sharedInstance.serviceRoot = [NSURL URLWithString:kTestEndpoint];
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
	requestQueue = [[BKRequestQueue alloc] init];
	requestQueue.shouldWaitUntilDone = YES;
}

- (void)tearDown
{
	objc_removeAssociatedObjects(self);
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
	BKAPIContext *faultyContext = [[[BKAPIContext alloc] init] autorelease];
	
	faultyContext.serviceRoot = [NSURL URLWithString:@"http://example.org"];	
	BKCheckVersionRequest *request = [[[BKCheckVersionRequest alloc] initWithAPIContext:faultyContext] autorelease];
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
	BKCheckVersionRequest *request = [[[BKCheckVersionRequest alloc] initWithAPIContext:[self sharedAPIContext]] autorelease];
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
	request.actionOnFailure = @selector(logOnExpectedToFail:);
	request.actionOnSuccess = @selector(logOnExpectedNotToComplete:);
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
	request.actionOnFailure = @selector(logOnDidFail:);
	request.actionOnSuccess = @selector(logOnDidComplete:);
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
	request.actionOnFailure = @selector(logOffDidFail:);
	request.actionOnSuccess = @selector(logOffDidComplete:);
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

static NSString *kProjects = @"kProjects";

- (void)testLists
{
	NSArray *lists = [NSArray arrayWithObjects:BKFilterList, BKProjectList, BKCategoryList, BKPriorityList, BKPeopleList, BKStatusList, BKMilestoneList, BKMailboxList, nil];
	
	for (NSString *t in lists) {
		BKListRequest *request = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:t writableItemsOnly:NO] autorelease];
		request.target = self;
		request.actionOnFailure = @selector(listDidFail:);								  
		request.actionOnSuccess = @selector(listDidComplete:);
		[requestQueue addRequest:request];
	}
	
	return;

	BKListRequest *projectListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKProjectList writableItemsOnly:NO] autorelease];
	projectListRequest.target = self;
	projectListRequest.actionOnFailure = @selector(listDidFail:);								  
	projectListRequest.actionOnSuccess = @selector(projectListDidComplete:);
	[requestQueue addRequest:projectListRequest];
	
	NSArray *projects = objc_getAssociatedObject(self, kProjects);
	for (NSDictionary *p in projects) {
		BKAreaListRequest *request = [[[BKAreaListRequest alloc] initWithAPIContext:[self sharedAPIContext] projectID:[[p objectForKey:@"ixProject"] integerValue] writableItemsOnly:NO] autorelease];
		request.target = self;
		request.actionOnFailure = @selector(listDidFail:);
		request.actionOnSuccess = @selector(areaListDidComplete:);
		request.userInfo = p;
		[requestQueue addRequest:request];
	}
}

- (void)listDidComplete:(BKListRequest *)inRequest
{
	STAssertTrue([inRequest.processedResponse isKindOfClass:[NSArray class]], @"Processed response must be some kind of array");	
	NSLog(@"request type: %@, returned array count: %d", inRequest.listType, [inRequest.processedResponse count]);
}

- (void)projectListDidComplete:(BKListRequest *)inRequest
{
	[self listDidComplete:inRequest];	
	objc_setAssociatedObject(self, kProjects, inRequest.fetchedList, OBJC_ASSOCIATION_RETAIN);
}

- (void)areaListDidComplete:(BKAreaListRequest *)inRequest
{
	STAssertTrue([inRequest.processedResponse isKindOfClass:[NSArray class]], @"Processed response must be some kind of array");		
	NSArray *areaNames = [inRequest.fetchedList valueForKeyPath:@"sArea"];	
	NSLog(@"Project %@, areas: %@", [inRequest.userInfo objectForKey:@"sProject"], [areaNames componentsJoinedByString:@","]);
}

- (void)listDidFail:(BKListRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);	
}

#pragma mark Test setting current filter

static NSString *kFilterList = @"kFilterList";
static NSString *kSavedCurrentFilterName = @"kSavedCurrentFilterName";

static NSString *kTestingCurrentFilterName = @"kTestingCurrentFilterName";

- (void)testSettingCurrentFilter
{
	BKListRequest *filterListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKFilterList writableItemsOnly:NO] autorelease];
	filterListRequest.target = self;
	filterListRequest.actionOnFailure = @selector(currentFilterSettingFail:);								  
	filterListRequest.actionOnSuccess = @selector(getCurrentFilter:);
	[requestQueue addRequest:filterListRequest];	
	
	filterListRequest.actionOnSuccess = @selector(checkCurrentFilterActuallySet:);	
	NSArray *filterList = objc_getAssociatedObject(self, kFilterList);
	for (NSDictionary *f in filterList) {
		NSString *filterName = [f objectForKey:@"sFilter"];
		objc_setAssociatedObject(self, kTestingCurrentFilterName, filterName, OBJC_ASSOCIATION_RETAIN);
		
		BKSetCurrentFilterRequest *setRequest = [[[BKSetCurrentFilterRequest alloc] initWithAPIContext:[self sharedAPIContext] filterName:filterName] autorelease];
		setRequest.target = self;
		setRequest.actionOnFailure = @selector(currentFilterSettingFail:);
		setRequest.actionOnSuccess = @selector(setCurrentFilterDidComplete:);
		
		[requestQueue addRequest:setRequest];
		[requestQueue addRequest:filterListRequest];
	}	

	objc_setAssociatedObject(self, kTestingCurrentFilterName, objc_getAssociatedObject(self, kSavedCurrentFilterName), OBJC_ASSOCIATION_RETAIN);
	BKSetCurrentFilterRequest *setRequest = [[[BKSetCurrentFilterRequest alloc] initWithAPIContext:[self sharedAPIContext] filterName:objc_getAssociatedObject(self, kSavedCurrentFilterName)] autorelease];
	setRequest.target = self;
	setRequest.actionOnFailure = @selector(currentFilterSettingFail:);
	setRequest.actionOnSuccess = @selector(setCurrentFilterDidComplete:);	
	[requestQueue addRequest:setRequest];

	[requestQueue addRequest:filterListRequest];
}

- (NSString *)currentFilterNameFromList:(NSArray *)inList
{
	for (NSDictionary *f in inList) {
		if ([[f objectForKey:@"status"] isEqualToString:@"current"]) {
			return [f objectForKey:@"sFilter"];
		}
	}
	
	return nil;
}

- (void)getCurrentFilter:(BKListRequest *)inRequest
{
	NSString *fn = [self currentFilterNameFromList:inRequest.fetchedList];	
	objc_setAssociatedObject(self, kFilterList, inRequest.fetchedList, OBJC_ASSOCIATION_RETAIN);
	objc_setAssociatedObject(self, kSavedCurrentFilterName, fn, OBJC_ASSOCIATION_RETAIN);
	
	NSLog(@"Current filter: %@", fn);
}

- (void)setCurrentFilterDidComplete:(BKSetCurrentFilterRequest *)inRequest
{
	NSLog(@"Current filter now set to: %@", inRequest.filterName);
}

- (void)checkCurrentFilterActuallySet:(BKListRequest *)inRequest
{
	NSString *fn = [self currentFilterNameFromList:inRequest.fetchedList];
	if (fn) {		
		STAssertEqualObjects([self currentFilterNameFromList:inRequest.fetchedList], objc_getAssociatedObject(self, kTestingCurrentFilterName), @"Current filter should be set to the desired one");
	}
	
	NSLog(@"We want filter set to: %@, actual filter name: %@", objc_getAssociatedObject(self, kTestingCurrentFilterName), fn);
}

- (void)currentFilterSettingFail:(BKListRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);	
}

#pragma mark Test case query

- (void)testCaseQuery
{
	BKQueryCaseRequest *query = [[[BKQueryCaseRequest alloc] initWithAPIContext:[self sharedAPIContext] query:nil columns:[NSArray arrayWithObjects:@"sTitle", nil]] autorelease];
	query.target = self;
	query.actionOnFailure = @selector(caseQueryDidFail:);
	query.actionOnSuccess = @selector(caseQueryDidComplete:);
	[requestQueue addRequest:query];
}

- (void)caseQueryDidComplete:(BKQueryCaseRequest *)inRequest
{
	NSLog(@"query string: %@, fetched case titles: %@", inRequest.query, [inRequest.fetchedCases valueForKeyPath:@"sTitle"]);
}

- (void)caseQueryDidFail:(BKQueryCaseRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);		
}

#pragma mark Test create new case

static NSString *kCurrentCaseInfo = @"kCurrentCaseInfo";

- (void)testCaseEdit_New
{
	NSDictionary *newCaseParams = [NSDictionary dictionaryWithObjectsAndKeys:
								   @"inbox", @"sProject",
								   @"test create new BugzKit case", @"sTitle",
								   nil];
	
	BKEditCaseRequest *edit = [[[BKEditCaseRequest alloc] initWithAPIContext:[self sharedAPIContext] editAction:BKNewCaseAction parameters:newCaseParams] autorelease];
	edit.target = self;
	edit.actionOnFailure = @selector(caseEditDidFail:);
	edit.actionOnSuccess = @selector(caseEditDidComplete:);
	[requestQueue addRequest:edit];
	
	NSDictionary *caseInfo = objc_getAssociatedObject(self, kCurrentCaseInfo);
	
	NSMutableDictionary *changeTitle = [NSMutableDictionary dictionaryWithDictionary:caseInfo];
	[changeTitle setObject:@"Set to new title for BugzKit test" forKey:@"sTitle"];
	edit = [[[BKEditCaseRequest alloc] initWithAPIContext:[self sharedAPIContext] editAction:BKEditCaseAction parameters:changeTitle] autorelease];
	edit.target = self;
	edit.actionOnFailure = @selector(caseEditDidFail:);
	edit.actionOnSuccess = @selector(caseEditDidComplete:);
	[requestQueue addRequest:edit];	
	
	caseInfo = objc_getAssociatedObject(self, kCurrentCaseInfo);
	edit = [[[BKEditCaseRequest alloc] initWithAPIContext:[self sharedAPIContext] editAction:BKResolveCaseAction parameters:changeTitle] autorelease];
	edit.target = self;
	edit.actionOnFailure = @selector(caseEditDidFail:);
	edit.actionOnSuccess = @selector(caseEditDidComplete:);
	[requestQueue addRequest:edit];	

	caseInfo = objc_getAssociatedObject(self, kCurrentCaseInfo);
	edit = [[[BKEditCaseRequest alloc] initWithAPIContext:[self sharedAPIContext] editAction:BKCloseCaseAction parameters:changeTitle] autorelease];
	edit.target = self;
	edit.actionOnFailure = @selector(caseEditDidFail:);
	edit.actionOnSuccess = @selector(caseEditDidComplete:);
	[requestQueue addRequest:edit];		

	caseInfo = objc_getAssociatedObject(self, kCurrentCaseInfo);
	edit = [[[BKEditCaseRequest alloc] initWithAPIContext:[self sharedAPIContext] editAction:BKReopenCaseAction parameters:changeTitle] autorelease];
	edit.target = self;
	edit.actionOnFailure = @selector(caseEditDidFail:);
	edit.actionOnSuccess = @selector(caseEditDidComplete:);
	[requestQueue addRequest:edit];		

	caseInfo = objc_getAssociatedObject(self, kCurrentCaseInfo);
	edit = [[[BKEditCaseRequest alloc] initWithAPIContext:[self sharedAPIContext] editAction:BKResolveCaseAction parameters:changeTitle] autorelease];
	edit.target = self;
	edit.actionOnFailure = @selector(caseEditDidFail:);
	edit.actionOnSuccess = @selector(caseEditDidComplete:);
	[requestQueue addRequest:edit];		

	caseInfo = objc_getAssociatedObject(self, kCurrentCaseInfo);
	edit = [[[BKEditCaseRequest alloc] initWithAPIContext:[self sharedAPIContext] editAction:BKCloseCaseAction parameters:changeTitle] autorelease];
	edit.target = self;
	edit.actionOnFailure = @selector(caseEditDidFail:);
	edit.actionOnSuccess = @selector(caseEditDidComplete:);
	[requestQueue addRequest:edit];			
}

- (void)caseEditDidComplete:(BKEditCaseRequest *)inRequest
{
	NSLog(@"edited case number: %@ (allowed operations: %@)", [inRequest.editedCase objectForKey:@"ixBug"], [inRequest.editedCase objectForKey:@"operations"]);	
	objc_setAssociatedObject(self, kCurrentCaseInfo, inRequest.editedCase, OBJC_ASSOCIATION_RETAIN);
}

- (void)caseEditDidFail:(BKEditCaseRequest *)inRequest
{
	STFail(@"request: %@, error: %@", inRequest, inRequest.error);	
}

- (void)testDeferredRequest
{
	BKListRequest *filterListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKFilterList writableItemsOnly:NO] autorelease];
	filterListRequest.target = self;
	filterListRequest.actionOnFailure = @selector(currentFilterSettingFail:);								  
	filterListRequest.actionOnSuccess = @selector(getCurrentFilter:);
	[requestQueue addRequest:filterListRequest deferred:YES];

	filterListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKProjectList writableItemsOnly:NO] autorelease];
	filterListRequest.target = self;
	filterListRequest.actionOnFailure = @selector(currentFilterSettingFail:);								  
	filterListRequest.actionOnSuccess = @selector(getCurrentFilter:);
	[requestQueue addRequest:filterListRequest deferred:YES];
	
	
	NSDate *date = [NSDate date];
	
	filterListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKPeopleList writableItemsOnly:NO] autorelease];
	filterListRequest.target = self;
	filterListRequest.actionOnFailure = @selector(currentFilterSettingFail:);								  
	filterListRequest.actionOnSuccess = @selector(getCurrentFilter:);
	[requestQueue addRequest:filterListRequest deferred:YES];
	
	filterListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKAreaList writableItemsOnly:NO] autorelease];
	filterListRequest.target = self;
	filterListRequest.actionOnFailure = @selector(currentFilterSettingFail:);								  
	filterListRequest.actionOnSuccess = @selector(getCurrentFilter:);
	[requestQueue addRequest:filterListRequest deferred:YES];
	
	filterListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKMilestoneList writableItemsOnly:NO] autorelease];
	filterListRequest.target = self;
	filterListRequest.actionOnFailure = @selector(currentFilterSettingFail:);								  
	filterListRequest.actionOnSuccess = @selector(getCurrentFilter:);
	[requestQueue addRequest:filterListRequest deferred:YES];
	

	NSArray *a = [requestQueue queuedRequestsWithPredicate:[NSPredicate predicateWithFormat:@"dateEnqueued < %@", date]];
	NSArray *b = [requestQueue queuedRequestsWithPredicate:[NSPredicate predicateWithFormat:@"dateEnqueued > %@", date]];	
	
	[requestQueue cancelAllRequests];
	NSArray *c = [requestQueue queuedRequestsWithPredicate:[NSPredicate predicateWithValue:YES]];

	STAssertTrue([a count] == 2, @"A must be 2");
	STAssertTrue([b count] == 3, @"B must be 3");
	STAssertTrue([c count] == 0, @"C must be 0");	
}

#pragma mark Test fetching people list and each's working schedule

- (void)testFetchPeopleWorkingSchedule
{
	BKListRequest *peopleListRequest = [[[BKListRequest alloc] initWithAPIContext:[self sharedAPIContext] list:BKPeopleList writableItemsOnly:NO] autorelease];
	peopleListRequest.blockOnSuccess = ^(BKRequest *inRequest) {
		NSMutableArray *idArray = [[[((BKListRequest *)inRequest).fetchedList valueForKeyPath:@"ixPerson"] mutableCopy] autorelease];
		[idArray addObject:[NSNumber numberWithUnsignedInteger:1]];
		
		for (NSNumber *n in idArray) {
			BKListWorkingScheduleRequest *scheduleRequest = [[[BKListWorkingScheduleRequest alloc] initWithAPIContext:[self sharedAPIContext] personID:[n unsignedIntegerValue]] autorelease];
			
			scheduleRequest.blockOnSuccess = ^(BKRequest *inRequest) {
				NSLog(@"Fetched schedule: %@", ((BKListWorkingScheduleRequest *)inRequest).fetchedWorkingSchedule);
			};
			
			scheduleRequest.blockOnFailure = ^(BKRequest *inRequest) {
				STFail(@"request: %@, error: %@", inRequest, inRequest.error);	
			};
			
			[requestQueue addRequest:scheduleRequest];
		}
	};
	
	
	peopleListRequest.blockOnFailure = ^(BKRequest *inRequest) {
		STFail(@"request: %@, error: %@", inRequest, inRequest.error);	
	};
	
	[requestQueue addRequest:peopleListRequest];
}

@end
