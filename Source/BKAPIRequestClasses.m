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

@implementation BKVersionCheckRequest
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

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext filterName:(NSString *)inFilterName
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		filterName = [inFilterName copy];
		
		// TO DO: Check if API keeps the name
		// TO DO: Ask if there's a way to set the sFilter to none
		requestParameterDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"setCurrentFilter", @"cmd", inAPIContext.authToken, @"token", ([inFilterName length] ? inFilterName : @"inbox"), @"sFilter", nil] retain];
	}
	
	return self;	
}

@synthesize filterName;
@end

@implementation BKQueryCaseRequest : BKRequest
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

NSString *const BKNewCaseAction = @"new";
NSString *const BKEditCaseAction = @"edit";
NSString *const BKAssignCaseAction = @"assign";
NSString *const BKReactiateCaseAction = @"reactivate";
NSString *const BKReopenCaseAction = @"reopen";
NSString *const BKResolveCaseAction = @"resolve";
NSString *const BKCloseCaseAction = @"close";
NSString *const BKEmailCaseAction = @"email";
NSString *const BKReplyCaseAction = @"reply";
NSString *const BKForwardCaseAction = @"forward";

@implementation BKEditCaseRequest
- (void)dealloc
{
	[parameters release];
	[super dealloc];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction parameters:(NSDictionary *)inParameters
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		
		[d setObject:inAPIContext.authToken forKey:@"token"];
		[d setObject:inAction forKey:@"cmd"];
		
		if (inParameters) {
			[d addEntriesFromDictionary:inParameters];
		}
		
		requestParameterDict = [d retain];
	}
	
	return self;	
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

@synthesize parameters;
@end