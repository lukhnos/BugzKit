//
// BKAreaListRequest.m
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

#import "BKAreaListRequest.h"

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