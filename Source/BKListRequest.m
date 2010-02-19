//
// BKListRequest.m
//
// Copyright (c) 2007-2010 Lukhnos D. Liu (http://lukhnos.org)
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

#import "BKListRequest.h"
#import "BKError.h"
#import "BKRequest+ProtectedMethods.h"

NSString *const BKAreaList = @"BKAreaList";
NSString *const BKCategoryList = @"BKCategoryList";
NSString *const BKFilterList = @"BKFilterList";
NSString *const BKMailboxList = @"BKMailboxList";
NSString *const BKMilestoneList = @"BKMilestoneList";
NSString *const BKPeopleList = @"BKPeopleList";
NSString *const BKPriorityList = @"BKPriorityList";
NSString *const BKProjectList = @"BKProjectList";
NSString *const BKStatusList = @"BKStatusList";

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
		POPULATE(parameterDictionary, BKMilestoneList, @"listFixFors", @"fixfors.fixfor", @"fixfors");
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
