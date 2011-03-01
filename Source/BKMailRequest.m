//
// BKMailRequest.m
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

#import "BKMailRequest.h"

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
