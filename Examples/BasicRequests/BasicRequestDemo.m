//
// BasicRequestDemo.m
//
// Copyright (c) 2011 Lukhnos D. Liu (http://lukhnos.org)
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

#import "BasicRequestDemo.h"
#import "RequestOperation.h"

#import "AccountInfo.h"

static const NSTimeInterval kRunloopTickInterval = 5.0;

@implementation BasicRequestsDemo
- (void)dealloc
{
    [opQueue waitUntilAllOperationsAreFinished];
    [opQueue release], opQueue = nil;
    [messagePort release], messagePort = nil;    
}

- (id)init
{
    self = [super init];
    if (self) {
        opQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)prepareRunloop
{
    if (messagePort) {
        return;
    }
    
    messagePort = [[NSPort alloc] init];        
    [[NSRunLoop currentRunLoop] addPort:messagePort forMode:NSDefaultRunLoopMode];
    runloopRunning = YES;    
}

- (void)enterRunloop
{
    while (runloopRunning) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:kRunloopTickInterval]];
    }

    [[NSRunLoop currentRunLoop] removePort:messagePort forMode:NSDefaultRunLoopMode];
    [messagePort invalidate];
    [messagePort release];
    messagePort = nil;
}

- (void)quitRunloop
{
    if (!messagePort) {
        return;
    }

    NSPortMessage *message = [[[NSPortMessage alloc] initWithSendPort:messagePort receivePort:messagePort components:nil] autorelease];
    [message setMsgid:0];
    [message sendBeforeDate:[NSDate date]];
    runloopRunning = NO;
}

- (void)run
{
    BKAPIContext *context = [[BKAPIContext alloc] init];
    context.serviceRoot = [NSURL URLWithString:DEMO_ENDPOINT_STRING];

    [self prepareRunloop];
    
    NSBlockOperation *convergeBlockOp = [[[NSBlockOperation alloc] init] autorelease];
    
    BKCheckVersionRequest *checkVersionReq = [[[BKCheckVersionRequest alloc] initWithAPIContext:context] autorelease];
    RequestOperation *checkVersionReqOp = [[[RequestOperation alloc] initWithRequest:checkVersionReq] autorelease];
    
    checkVersionReqOp.onCompletion = ^(void) {
        NSLog(@"Check version completed, response: %@", checkVersionReq.processedResponse);
    };    
    
    checkVersionReqOp.onFailure = ^(void) {
        NSLog(@"Check version request failed, error: %@", checkVersionReq.error);
    };
    
    BKLogOnRequest *logOnReq = [[[BKLogOnRequest alloc] initWithAPIContext:context accountName:DEMO_USER_NAME password:DEMO_USER_PASSWORD] autorelease];
    RequestOperation *logOnReqOp = [[[RequestOperation alloc] initWithRequest:logOnReq] autorelease];

    logOnReqOp.onCompletion = ^(void) {
        NSLog(@"Logged on, response: %@", logOnReq.processedResponse);
                
        // we can only create meaningful requests after successful login, because they require the auth token
        NSArray *lists = [NSArray arrayWithObjects:BKProjectList, BKMilestoneList, BKPeopleList, nil];
        for (NSString *listName in lists) {
            BKListRequest *listReq = [[[BKListRequest alloc] initWithAPIContext:context list:listName parameters:nil] autorelease];
            RequestOperation *listReqOp = [[[RequestOperation alloc] initWithRequest:listReq] autorelease];
            
            listReqOp.onCompletion = ^(void) {
                NSLog(@"List '%@' fetched: %@", listName, listReq.fetchedList);
            };    
            
            listReqOp.onFailure = ^(void) {
                NSLog(@"List '%@' fetch failed", listName);
            };
            
            // each list req op depends on the login request op
            [listReqOp addDependency:logOnReqOp];
            
            // and the converge block op depends on the newly dynamically added list request op
            // (now you know why people love NSOperationQueue?)
            [convergeBlockOp addDependency:listReqOp];
            
            // ... and add them to the op queue
            [opQueue addOperation:listReqOp];
        }        
    };    
    
    logOnReqOp.onFailure = ^(void) {
        NSLog(@"Failed logging on, error: %@", logOnReq.error);
    };
                                    
    [convergeBlockOp addDependency:checkVersionReqOp];    
    [logOnReqOp addDependency:checkVersionReqOp];

    [convergeBlockOp addDependency:logOnReqOp];
    
    [opQueue addOperation:checkVersionReqOp];
    [opQueue addOperation:logOnReqOp];
    [opQueue addOperation:convergeBlockOp];
    
    
    // see http://borkwarellc.wordpress.com/2010/09/06/block-retain-cycles/ why we need to do this:
    __block BasicRequestsDemo *blockSelf = self;
    
    [convergeBlockOp addExecutionBlock:^(void) {
        BOOL someOpFailedOrCancelled = NO;
        for (RequestOperation *op in [convergeBlockOp dependencies]) {
            if ([op isKindOfClass:[RequestOperation class]] && ([op isCancelled] || op.request.error != nil)) {
                someOpFailedOrCancelled = YES; 
                break;
            }
        }
        
        if (someOpFailedOrCancelled) {
            NSLog(@"Some operation failed or got cancelled.");
            [blockSelf quitRunloop];
        }
        else {
            NSLog(@"All dependent operations successfully ran.");
            
            // now we need to logout
            if (![logOnReqOp isCancelled] && logOnReq.error == nil) {            
                BKLogOffRequest *logOffReq = [[[BKLogOffRequest alloc] initWithAPIContext:context] autorelease];
                RequestOperation *logOffReqOp = [[[RequestOperation alloc] initWithRequest:logOffReq] autorelease];

                logOffReqOp.onCompletion = ^(void) {
                    NSLog(@"Successfully logged out.");
                    [blockSelf quitRunloop];
                };    
                
                logOffReqOp.onFailure = ^(void) {
                    NSLog(@"Failed logging out, error: %@", logOffReq.error);
                    [blockSelf quitRunloop];
                };
                
                [logOffReqOp addDependency:convergeBlockOp];
                [opQueue addOperation:logOffReqOp];
            }
            else {
                [blockSelf quitRunloop];
            }
        }        
    }];
    
    [self enterRunloop];
    [context release];
}
@end
