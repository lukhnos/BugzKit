//
// BKEditCaseRequest.h
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

#import "BKRequest.h"

@interface BKEditCaseRequest : BKRequest
{
	NSDictionary *parameters;

	NSString *multipartSeparator;
	NSString *tempFilename;
	NSArray *attachmentURLs;	
}
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction parameters:(NSDictionary *)inParameters;
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction caseNumber:(NSUInteger)inCaseNumber parameters:(NSDictionary *)inParameters;
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction caseNumber:(NSUInteger)inCaseNumber parameters:(NSDictionary *)inParameters attachmentURLs:(NSArray *)inURLs attachmentsFromBugEventID:(NSUInteger)inEventID;
@property (readonly) NSDictionary *editedCase;
@property (readonly) NSString *editAction;
@end

extern NSString *const BKAssignCaseAction;
extern NSString *const BKCloseCaseAction;
extern NSString *const BKEditCaseAction;
extern NSString *const BKEmailCaseAction;
extern NSString *const BKForwardCaseAction;
extern NSString *const BKNewCaseAction;
extern NSString *const BKReactivateCaseAction;
extern NSString *const BKReopenCaseAction;
extern NSString *const BKReplyCaseAction;
extern NSString *const BKResolveCaseAction;
