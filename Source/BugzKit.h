//
// BugzKit.h
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

#import "LFWebAPIKit.h"

@class BKBugzRequest;

@protocol BKBugzBaseDelegate <NSObject>
@end

@protocol BKBugzVersionCheckDelegate <NSObject>
- (void)bugzRequest:(BKBugzRequest *)inRequest versionCheckDidCompleteWithVersion:(NSString *)inMajorVersion minorVersion:(NSString *)inMinorVersion;
- (void)bugzRequest:(BKBugzRequest *)inRequest versionCheckDidFailWithError:(NSError *)inError;
@end

@protocol BKBugzLogOnDelegate <NSObject>
- (void)bugzRequest:(BKBugzRequest *)inRequest logOnDidCompleteWithToken:(NSString *)inToken;
- (void)bugzRequest:(BKBugzRequest *)inRequest logOnDidFailWithAmbiguousNameList:(NSArray *)inNameList;
- (void)bugzRequest:(BKBugzRequest *)inRequest logOnDidFailWithError:(NSError *)inError;
@end

@protocol BKBugzLogOffDelegate <NSObject>
- (void)bugzRequestLogOffDidComplete:(BKBugzRequest *)inRequest;
- (void)bugzRequest:(BKBugzRequest *)inRequest logOffDidFailWithError:(NSError *)inError;
@end



@interface BKBugzRequest : NSObject
{
    NSString *endpointRootString;
	
	// version check and login API change these states
	NSString *serviceEndpointString;
	NSString *authToken;	
    
    NSMutableArray *requestInfoQueue;
    LFHTTPRequest *request;   
}

// + (id)copy;
- (void)checkVersionWithDelegate:(id<BKBugzVersionCheckDelegate>)inDelegate;
- (void)logOnWithUserName:(NSString *)inUserName password:(NSString *)inPassword delegate:(id<BKBugzLogOnDelegate>)inDelegate;
- (void)logOffWithDelegate:(id<BKBugzLogOffDelegate>)inDelegate;


@property (retain) NSString *endpointRootString;
@property (retain) NSString *serviceEndpointString;
@property (retain) NSString *authToken;

// for unit testing purpose only
@property (assign) BOOL shouldWaitUntilDone;
@end

extern NSString *const BKBugzConnectionErrorDomain;
extern NSString *const BKBugzAPIErrorDomain;

typedef enum {
	BKUnknownError = -1,
	BKConnecitonLostError = -2,
	BKConnecitonTimeoutError = -3
} BKErrorCode;
