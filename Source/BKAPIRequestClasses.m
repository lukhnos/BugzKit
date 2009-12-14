//
// BKAPIRequestClasses.m
//
// Copyright (c) 2007-2009 Lithoglyph Inc. All rights reserved.
//

#import "BKAPIRequestClasses.h"
#import "BKAPIContext+ProtectedMethods.h"
#import "BKError.h"
#import "BKPrivateUtilities.h"
#import "BKRequest+ProtectedMethods.h"

@implementation BKCheckVersionRequest
- (NSURL *)requestURL
{
    return [NSURL URLWithString:@"api.xml" relativeToURL:APIContext.serviceRoot];
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
    [APIContext setEndpoint:[NSURL URLWithString:[inXMLMappedResponse objectForKey:@"url"] relativeToURL:APIContext.serviceRoot]];
	[APIContext setMajorVersion:[[inXMLMappedResponse objectForKey:@"version"] integerValue]];
	[APIContext setMinorVersion:[[inXMLMappedResponse objectForKey:@"minversion"] integerValue]];
	return [super postprocessResponse:inXMLMappedResponse];
}
@end

@implementation BKLogOnRequest : BKRequest
+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext accountName:(NSString *)inAccountName password:(NSString *)inPassword
{
	return [[[self alloc] initWithAPIContext:inAPIContext accountName:inAccountName password:inPassword] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext accountName:(NSString *)inAccountName password:(NSString *)inPassword
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		requestParameterDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"logon", @"cmd", BKNotNil(inAccountName), @"email", BKNotNil(inPassword), @"password", nil] retain];
	}
	
	return self;
}

- (void)postprocessError:(NSError *)inError
{
	[APIContext setAuthToken:nil];
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	NSString *token = [inXMLMappedResponse objectForKey:@"token"];
    [APIContext setAuthToken:token];
	
	return token;
}
@end

@implementation BKLogOffRequest : BKRequest
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		requestParameterDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"logoff", @"cmd", inAPIContext.authToken, @"token", nil] retain];
	}
	
	return self;	
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	[APIContext setAuthToken:nil];
	return nil;
}
@end

NSString *const BKFilterList = @"BKFilterList";
NSString *const BKProjectList = @"BKProjectList";
NSString *const BKAreaList = @"BKAreaList";
NSString *const BKCategoryList = @"BKCategoryList";
NSString *const BKPriorityList = @"BKPriorityList";
NSString *const BKPeopleList = @"BKPeopleList";
NSString *const BKStatusList = @"BKStatusList";
NSString *const BKFixForList = @"BKFixForList";
NSString *const BKMailboxList = @"BKMailboxList";


static NSString *kListCommandKey = @"kListCommandKey";
static NSString *kListResultValueKeyPathKey = @"kListResultValueKeyPathKey";
static NSString *kFirstLevelValueKey = @"kFirstLevelValueKey";

@interface BKListRequest (PrivateMethods)
+ (NSDictionary *)listParameterDictionary;
+ (NSString *)commandForListType:(NSString *)inListType;
+ (NSString *)resultValueKeyPathKey:(NSString *)inListType;
+ (NSString *)firstLevelValueKey:(NSString *)inListType;
@end

@implementation BKListRequest
+ (NSDictionary *)listParameterDictionary

{
	NSDictionary *parameterDictionary = nil;
	if (!parameterDictionary) {
		parameterDictionary = [[NSMutableDictionary dictionary] retain];
		
		#define POPULATE(dict, key, cmd, kvPath, lvk) do { [(NSMutableDictionary *)dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:cmd, kListCommandKey, kvPath, kListResultValueKeyPathKey, lvk, kFirstLevelValueKey, nil] forKey:key]; } while(0);
		POPULATE(parameterDictionary, BKFilterList, @"listFilters", @"filters.filter", @"filters");
		POPULATE(parameterDictionary, BKProjectList, @"listProjects", @"projects.project", @"projects");
		POPULATE(parameterDictionary, BKAreaList, @"listAreas", @"areas.area", @"areas");
		POPULATE(parameterDictionary, BKCategoryList, @"listCategories", @"categories.category", @"categories");
		POPULATE(parameterDictionary, BKPriorityList, @"listPriorities", @"priorities.priority", @"priorities");
		POPULATE(parameterDictionary, BKPeopleList, @"listPeople", @"people.person", @"people");
		POPULATE(parameterDictionary, BKStatusList, @"listStatuses", @"statuses.status", @"statuses");
		POPULATE(parameterDictionary, BKFixForList, @"listFixFors", @"fixfors.fixfor", @"fixfors");
		POPULATE(parameterDictionary, BKMailboxList, @"listMailboxes", @"mailboxes.mailbox", @"mailboxes");		
		#undef POPULATE
	}
	
	return parameterDictionary;
}

+ (NSString *)commandForListType:(NSString *)inListType
{
	return [[[self listParameterDictionary] objectForKey:inListType] objectForKey:kListCommandKey];
}

+ (NSString *)resultValueKeyPathKey:(NSString *)inListType
{
	return [[[self listParameterDictionary] objectForKey:inListType] objectForKey:kListResultValueKeyPathKey];
}

+ (NSString *)firstLevelValueKey:(NSString *)inListType
{
	return [[[self listParameterDictionary] objectForKey:inListType] objectForKey:kFirstLevelValueKey];
}

- (void)dealloc
{
	[listType release];
	[super dealloc];
}

+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext list:(NSString *)inListType writableItemsOnly:(BOOL)inListOnlyWritables
{
	return [[[self alloc] initWithAPIContext:inAPIContext list:inListType writableItemsOnly:inListOnlyWritables] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext list:(NSString *)inListType writableItemsOnly:(BOOL)inListOnlyWritables
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		listType = [inListType retain];		
		requestParameterDict = [[NSMutableDictionary alloc] init];
		
		[(NSMutableDictionary *)requestParameterDict setObject:[[self class] commandForListType:listType] forKey:@"cmd"];
		[(NSMutableDictionary *)requestParameterDict setObject:inAPIContext.authToken forKey:@"token"];

		if (inListOnlyWritables) {
			[(NSMutableDictionary *)requestParameterDict setObject:[NSNumber numberWithBool:inListOnlyWritables] forKey:@"fWrite"];
		}
	}
	
	return self;
}

- (NSError *)validateResponse:(NSDictionary *)inXMLMappedResponse
{
	if (![inXMLMappedResponse objectForKey:[[self class] firstLevelValueKey:listType]]) {
		return [NSError errorWithDomain:BKAPIErrorDomain code:BKAPIMalformedResponseError userInfo:nil];
	}
	
	return [super validateResponse:inXMLMappedResponse];
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	id result = [inXMLMappedResponse valueForKeyPath:[[self class] resultValueKeyPathKey:listType]];
	if (!result) {
		result = [NSArray array];
	}
	
	return result;
}

- (NSArray *)fetchedList
{
	return [processedResponse isKindOfClass:[NSArray class]] ? processedResponse : nil;
}

@synthesize listType;
@end

@implementation BKAreaListRequest
+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext projectID:(NSUInteger)inProjectID writableItemsOnly:(BOOL)inListOnlyWritables
{
	return [[[self alloc] initWithAPIContext:inAPIContext projectID:inProjectID writableItemsOnly:inListOnlyWritables] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext projectID:(NSUInteger)inProjectID writableItemsOnly:(BOOL)inListOnlyWritables
{
	if (self = [super initWithAPIContext:inAPIContext list:BKAreaList writableItemsOnly:inListOnlyWritables]) {
		[(NSMutableDictionary *)requestParameterDict setObject:[NSNumber numberWithUnsignedInteger:inProjectID] forKey:@"ixProject"];
	}
	
	return self;
}

- (NSUInteger)projectID
{
	return (NSUInteger)[[requestParameterDict objectForKey:@"ixProject"] integerValue];
}
@end


@implementation BKSetCurrentFilterRequest
- (void)dealloc
{
	[filterName release];
	[super dealloc];
}

+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext filterName:(NSString *)inFilterName
{
	return [[[self alloc] initWithAPIContext:inAPIContext filterName:inFilterName] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext filterName:(NSString *)inFilterName
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		filterName = [inFilterName copy];
		
		// TODO: Check if API keeps the name
		// TODO: Ask if there's a way to set the sFilter to none
		requestParameterDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"setCurrentFilter", @"cmd", inAPIContext.authToken, @"token", ([inFilterName length] ? inFilterName : @"inbox"), @"sFilter", nil] retain];
	}
	
	return self;	
}

- (NSString *)HTTPRequestMethod
{
	return LFHTTPRequestPOSTMethod;
}

@synthesize filterName;
@end

@implementation BKQueryCaseRequest : BKRequest
+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext query:(NSString *)inQuery columns:(NSArray *)inColumnNames
{
	return [[[self alloc] initWithAPIContext:inAPIContext query:inQuery columns:inColumnNames maximum:NSUIntegerMax] autorelease];
}

+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext query:(NSString *)inQuery columns:(NSArray *)inColumnNames maximum:(NSUInteger)inMaximum
{
	return [[[self alloc] initWithAPIContext:inAPIContext query:inQuery columns:inColumnNames maximum:inMaximum] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext query:(NSString *)inQuery columns:(NSArray *)inColumnNames maximum:(NSUInteger)inMaximum
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		
		[d setObject:inAPIContext.authToken forKey:@"token"];
		[d setObject:@"search" forKey:@"cmd"];
		
		if (inQuery) {
			[d setObject:inQuery forKey:@"q"];
		}
		
		if ([inColumnNames count]) {
			[d setObject:[inColumnNames componentsJoinedByString:@","] forKey:@"cols"];
		}
		
		if (inMaximum && inMaximum != NSUIntegerMax) {
			[d setObject:[NSString stringWithFormat:@"%jd", (uintmax_t)inMaximum] forKey:@"max"];
		}			 
		
		requestParameterDict = [d retain];
	}
	
	return self;
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext query:(NSString *)inQuery columns:(NSArray *)inColumnNames
{
	return [self initWithAPIContext:inAPIContext query:inQuery columns:inColumnNames maximum:NSUIntegerMax];
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	id result = [inXMLMappedResponse valueForKeyPath:@"cases.case"];
	if (!result) {
		result = [NSArray array];
	}
	
	return result;
}

- (NSArray *)fetchedCases
{
	return processedResponse;
}

- (NSString *)query
{
	return [requestParameterDict objectForKey:@"q"];
}
@end


@implementation BKQueryEventRequest : BKQueryCaseRequest
+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext caseNumber:(NSUInteger)inCaseNumber
{
	return [[[self alloc] initWithAPIContext:inAPIContext caseNumber:inCaseNumber] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext caseNumber:(NSUInteger)inCaseNumber
{
	if (self = [super initWithAPIContext:inAPIContext query:[NSString stringWithFormat:@"%ju", (uintmax_t)inCaseNumber] columns:[NSArray arrayWithObject:@"events"]]) {
	}
	
	return self;
}

- (NSArray *)fetchedEvents
{
	NSArray *cases = [self fetchedCases];
	
	if ([cases count]) {
		return [[cases objectAtIndex:0] valueForKeyPath:@"events.event"];
	}
	
	return [NSArray array];
}
@end


NSString *const BKNewCaseAction = @"new";
NSString *const BKEditCaseAction = @"edit";
NSString *const BKAssignCaseAction = @"assign";
NSString *const BKReactivateCaseAction = @"reactivate";
NSString *const BKReopenCaseAction = @"reopen";
NSString *const BKResolveCaseAction = @"resolve";
NSString *const BKCloseCaseAction = @"close";
NSString *const BKEmailCaseAction = @"email";
NSString *const BKReplyCaseAction = @"reply";
NSString *const BKForwardCaseAction = @"forward";

@implementation BKEditCaseRequest
- (void)cleanUpTempFile
{
	if (![tempFilename length]) {
		return;
	}
	
	BOOL isDir = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempFilename isDirectory:&isDir]) {
		
		NSError *ourError = NULL;
		BOOL __unused removeResult = [[NSFileManager defaultManager] removeItemAtPath:tempFilename error:&ourError];
		NSAssert2(removeResult, @"Must remove the temp file at: %@, error: %@", tempFilename, ourError);
	}
}

- (void)prepareTempFile
{
	if ([tempFilename length]) {
		return;
	}
	
	NSString *bundleID = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(id)kCFBundleIdentifierKey];
	NSString *filenameRoot = [NSTemporaryDirectory() stringByAppendingFormat:@"%@.%@.data-XXXXXX", NSStringFromClass([self class]), bundleID];
	
	const char *filenameUTF8 = [filenameRoot UTF8String];
	char *writableFilename = (char *)calloc(1, strlen(filenameUTF8) + 1);
	strncpy(writableFilename, filenameUTF8, strlen(filenameUTF8));
	
	mktemp(writableFilename);
	tempFilename = [[NSString alloc] initWithUTF8String:writableFilename];
	
    // build the multipart form
    NSMutableString *multipartBegin = [NSMutableString string];
    NSMutableString *multipartEnd = [NSMutableString string];
    
	for (NSString *key in requestParameterDict) {
		NSString *value = [requestParameterDict objectForKey:key];
		[multipartBegin appendFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", multipartSeparator, key, value];
	}
	
	
    // add filename, if nil, generate a UUID
	
    [multipartEnd appendFormat:@"--%@--", multipartSeparator];
    
    
    // create the write stream
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:tempFilename append:NO];
    [outputStream open];
    
    const char *UTF8String;
    size_t writeLength;
    UTF8String = [multipartBegin UTF8String];
    writeLength = strlen(UTF8String);
	
	size_t __unused actualWrittenLength;
	actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
    NSAssert(actualWrittenLength == writeLength, @"Must write multipartBegin");
	
	NSUInteger fileIndex = 1;
	for (NSURL *u in attachmentURLs) {
		// TODO: Speed this part up (measure performance first)
		NSData *d = [NSData dataWithContentsOfURL:u];
		
		// TODO: Ensure the correctness
		NSString *lastPathComponent = [u lastPathComponent];
		
		NSMutableString *fileHeader = [NSMutableString string];
		
		[fileHeader appendFormat:@"--%@\r\nContent-Disposition: form-data; name=\"File%ju\"; filename=\"%@\"\r\n", multipartSeparator, (uintmax_t)fileIndex, lastPathComponent];
		[fileHeader appendFormat:@"Content-Type: %@\r\n\r\n", @"application/octet-stream"];
		
		
		UTF8String = [fileHeader UTF8String];
		writeLength = strlen(UTF8String);
		actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
		NSAssert(actualWrittenLength == writeLength, @"Must write fileHeader");
		
		actualWrittenLength = [outputStream write:[d bytes] maxLength:[d length]];
		NSAssert(actualWrittenLength == [d length], @"Must write binary data");
		
		NSString *fileEnd = @"\r\n";
		
		UTF8String = [fileEnd UTF8String];
		writeLength = strlen(UTF8String);
		actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
		NSAssert(actualWrittenLength == writeLength, @"Must write fileHeader");
		
		fileIndex++;
	}
	
    
    UTF8String = [multipartEnd UTF8String];
    writeLength = strlen(UTF8String);
	actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
    NSAssert(actualWrittenLength == writeLength, @"Must write multipartEnd");
    [outputStream close];
}

- (void)dealloc
{
	[self cleanUpTempFile];
	[multipartSeparator release];
	[tempFilename release];
	[attachmentURLs release];
	[super dealloc];
}

- (void)finalize
{
	[self cleanUpTempFile];
	[super finalize];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction caseNumber:(NSUInteger)inCaseNumber parameters:(NSDictionary *)inParameters attachmentURLs:(NSArray *)inURLs attachmentsFromBugEventID:(NSUInteger)inEventID;
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		
		[d setObject:inAPIContext.authToken forKey:@"token"];
		[d setObject:inAction forKey:@"cmd"];
		
		if (inCaseNumber) {
			[d setObject:[NSString stringWithFormat:@"%ju", (uintmax_t)inCaseNumber] forKey:@"ixBug"];
		}
				
		if (inEventID) {
			[d setObject:[NSString stringWithFormat:@"%ju", (uintmax_t)inEventID] forKey:@"ixBugEventAttachment"];
		}
		
		if ([inURLs count]) {
			[d setObject:[NSString stringWithFormat:@"%ju", (uintmax_t)[inURLs count]] forKey:@"nFileCount"];
		}
		
		if (inParameters) {
			[d addEntriesFromDictionary:inParameters];
		}
		
		requestParameterDict = [d retain];
		
		if ([inURLs count]) {
			attachmentURLs = [[NSArray alloc] initWithArray:inURLs];
		}
		
		multipartSeparator = [BKGenerateUUID() retain];		
	}
	
	return self;	
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction caseNumber:(NSUInteger)inCaseNumber parameters:(NSDictionary *)inParameters
{
	return [self initWithAPIContext:inAPIContext editAction:inAction caseNumber:inCaseNumber parameters:inParameters attachmentURLs:nil attachmentsFromBugEventID:0];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction parameters:(NSDictionary *)inParameters
{
	return [self initWithAPIContext:inAPIContext editAction:inAction caseNumber:0 parameters:inParameters attachmentURLs:nil attachmentsFromBugEventID:0];
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	id result = [inXMLMappedResponse valueForKeyPath:@"case"];
	if (!result) {
		result = [NSDictionary dictionary];
	}
	
	return result;
}

- (NSString *)editAction
{
	return [requestParameterDict objectForKey:@"cmd"];
}

- (NSDictionary *)editedCase
{
	return processedResponse;
}

- (NSString *)HTTPRequestMethod
{
	return LFHTTPRequestPOSTMethod;
}

- (NSString *)HTTPRequestContentType
{
	return [attachmentURLs count] ? [NSString stringWithFormat:@"multipart/form-data; boundary=%@", multipartSeparator] : [super HTTPRequestContentType];
}

- (NSUInteger)requestInputStreamSize
{
	if (![attachmentURLs count]) {
		return 0;
	}
	
	[self prepareTempFile];	
	NSError *fileError = NULL;
	NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:tempFilename error:&fileError];	
	return [[info objectForKey:NSFileSize] unsignedIntegerValue];
}

- (NSInputStream *)requestInputStream
{
	if (![attachmentURLs count]) {
		return 0;
	}
	
	[self prepareTempFile];
	return [NSInputStream inputStreamWithFileAtPath:tempFilename];
}

- (NSData *)requestData
{
	return [attachmentURLs count] ? nil : [super requestData];
}
@end

@implementation BKMailRequest

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction caseNumber:(NSUInteger)inCaseNumber parameters:(NSDictionary *)inParameters text:(NSString *)inText subject:(NSString *)inSubject from:(NSString *)inFrom to:(NSString *)inTo CC:(NSString *)inCC BCC:(NSString *)inBCC attachmentURLs:(NSArray *)inURLs attachmentsFromBugEventID:(NSUInteger)inEventID;
{
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	if (inParameters) {
		[params addEntriesFromDictionary:inParameters];
	}
	
	if ([inSubject length]) {
		[params setObject:inSubject forKey:@"sSubject"];
	}
	
	if ([inText length]) {
		[params setObject:inText forKey:@"sEvent"];
	}
	
	if ([inFrom length]) {
		[params setObject:inFrom forKey:@"sFrom"];
	}
	
	if ([inTo length]) {
		[params setObject:inTo forKey:@"sTo"];
	}

	if ([inCC length]) {
		[params setObject:inCC forKey:@"sCC"];
	}

	if ([inBCC length]) {
		[params setObject:inBCC forKey:@"sBCC"];
	}
			 
	if (self = [super initWithAPIContext:inAPIContext editAction:inAction caseNumber:inCaseNumber parameters:params attachmentURLs:inURLs attachmentsFromBugEventID:inEventID]) {
	}
	
	return self;
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction caseNumber:(NSUInteger)inCaseNumber text:(NSString *)inText subject:(NSString *)inSubject from:(NSString *)inFrom to:(NSString *)inTo CC:(NSString *)inCC BCC:(NSString *)inBCC attachmentURLs:(NSArray *)inURLs attachmentsFromBugEventID:(NSUInteger)inEventID
{
	return [self initWithAPIContext:inAPIContext editAction:inAction caseNumber:inCaseNumber parameters:nil text:inText subject:inSubject from:inFrom to:inTo CC:inCC BCC:inBCC attachmentURLs:inURLs attachmentsFromBugEventID:inEventID];
}

@end

const NSUInteger BKSiteWorkingSchedulePersonID = 1;

@implementation BKListWorkingScheduleRequest
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext personID:(NSUInteger)inPersonID
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		
		[d setObject:inAPIContext.authToken forKey:@"token"];
		[d setObject:@"listWorkingSchedule" forKey:@"cmd"];
		
		if (inPersonID) {
			[d setObject:[NSString stringWithFormat:@"%jd", (uintmax_t)inPersonID] forKey:@"ixPerson"];
		}
		
		requestParameterDict = [d retain];
	}
	
	return self;
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	id result = [inXMLMappedResponse valueForKeyPath:@"workingSchedule"];
	if (!result) {
		result = [NSDictionary dictionary];
	}
	
	return result;
}

- (NSDictionary *)fetchedWorkingSchedule
{
	return [processedResponse isKindOfClass:[NSDictionary class]] ? processedResponse : nil;	
}

@end


@implementation BKMarkAsViewedRequest
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext caseNumber:(NSUInteger)inCaseNumber
{
	return [self initWithAPIContext:inAPIContext caseNumber:inCaseNumber eventID:NSUIntegerMax];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext caseNumber:(NSUInteger)inCaseNumber eventID:(NSUInteger)inEventID
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		
		[d setObject:inAPIContext.authToken forKey:@"token"];
		[d setObject:@"view" forKey:@"cmd"];
		[d setObject:[NSString stringWithFormat:@"%jd", (uintmax_t)inCaseNumber] forKey:@"ixBug"];
		
		if (inEventID != NSUIntegerMax) {
			[d setObject:[NSString stringWithFormat:@"%jd", (uintmax_t)inEventID] forKey:@"ixBugEvent"];
		}
		
		requestParameterDict = [d retain];
	}
	
	return self;	
}
@end
