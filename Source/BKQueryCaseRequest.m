//
// BKQueryCaseRequest.m
//
// Copyright (c) 2009-2011 Lukhnos D. Liu (http://lukhnos.org)
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

#import "BKQueryCaseRequest.h"

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
