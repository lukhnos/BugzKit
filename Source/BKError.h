//
// BKError.h
//
// Copyright (c) 2009-2010 Lukhnos D. Liu (http://lukhnos.org)
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

#import <Foundation/Foundation.h>

// TODO: Remove these
extern NSString *const BKConnectionErrorDomain;
extern NSString *const BKAPIErrorDomain;

typedef enum {
    // TODO: Remove these
	BKConnecitonLostError = -1,
	BKConnectionTimeoutError = -2,
	BKConnectionServerHTTPError = -3,	// e.g. 404
	
	BKAPIMalformedResponseError = -100,
	BKUnknownError = -9999,
	
	BKNotInitializedError = 0,
	BKLogOnIncorrectUsernameOrPasswordError = 1,
	BKLogOnMultipleMatchesForUsernameError = 2,
	BKNotLoggedOnError = 3,
	BKArgumentMissingFromQueryError = 4,
	BKEditingCaseNotFoundError = 5,
	BKEditingCaseActionNotPermitted = 6,
	BKTimeTrackingError = 7,
	BKNewCaseCannotWriteToAnyProjectError = 8,
	BKCaseChangedSinceLastViewError = 9,
	BKSearchError = 10,
	BKWikiCreationError = 12,
	BKWikiPermissionError = 13,
	BKWikiLoadError = 14,
	BKWikiTemplateError = 15,
	BKWikiCommitError = 16,
	BKNoSuchProjectError = 17,
	BKNoSuchUserError = 18,
	BKAreaCreationError = 19,
	BKMilestoneCreationError = 20,
	BKProjectCreationError = 21,
	BKUserCreationError = 22,
	BKProjectPercentTimeError = 23,
	BKNoSuchMilestoneError = 24,
	BKMilestoneExecutionOrderViolationError = 25
} BKErrorCode;
