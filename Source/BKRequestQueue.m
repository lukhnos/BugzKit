//
// BKRequestQueue.m
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

#import "BKRequestQueue.h"
#import "BKRequest+ProtectedMethods.h"

@interface BKRequestQueue (PrivateMethods)
- (void)_runQueue;
- (void)runQueue;
@end

@implementation BKRequestQueue : NSObject
- (void)dealloc
{
    HTTPRequest.delegate = nil;
    [HTTPRequest cancelWithoutDelegateMessage];
	
    [queue release];
    [HTTPRequest release];
	[cachePolicy release];
	
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        queue = [[NSMutableArray alloc] init];
        HTTPRequest = [[LFHTTPRequest alloc] init];
        HTTPRequest.delegate = self;
    }
    
    return self;
}

- (void)addRequest:(BKRequest *)inRequest
{
	[self addRequest:inRequest deferred:NO];
}

- (void)addRequest:(BKRequest *)inRequest deferred:(BOOL)inDeferred
{
	[inRequest recycleIfUsedBefore];
    [queue addObject:inRequest];
	
	if (!inDeferred) {
		[self runQueue];
	}
}

- (NSArray *)queuedRequestsWithPredicate:(NSPredicate *)inPredicate
{
	NSMutableArray *result = [NSMutableArray array];
	
	for (BKRequest *r in queue) {
		if ([inPredicate evaluateWithObject:r]) {
			[result addObject:r];
		}
	}
	
	return result;
}

- (void)setShouldWaitUntilDone:(BOOL)inShouldWait
{
    HTTPRequest.shouldWaitUntilDone = inShouldWait;
}

- (BOOL)shouldWaitUntilDone
{
    return HTTPRequest.shouldWaitUntilDone;
}


- (void)_runQueue
{
    if ([HTTPRequest isRunning]) {
        return;
    }
    
    if (paused) {
        return;
    }
    
    if (![queue count]) {
        return;
    }

    BKRequest *nextRequest = [queue objectAtIndex:0];
	HTTPRequest.sessionInfo = nextRequest;
	HTTPRequest.contentType = nextRequest.HTTPRequestContentType;

	// we must remove in advance in this mode, otherwise if any exception is raised, the object never gets removed
	if (HTTPRequest.shouldWaitUntilDone) {
		[queue removeObjectAtIndex:0];
	}
	
	[nextRequest requestQueueWillBeginRequest:self];
	
	NSData *cachedData = nil;
	if (cachedData = [cachePolicy requestQueue:self cachedDataOfRequest:nextRequest]) {
		[nextRequest requestQueue:self didCompleteWithData:cachedData];
		[nextRequest requestQueueRequestDidFinish:self];
		[self runQueue];		
	}
	else {	
		BOOL __unused requestResult;
		requestResult = [HTTPRequest performMethod:nextRequest.HTTPRequestMethod onURL:nextRequest.requestURL withData:nextRequest.requestData];	
		NSAssert1(requestResult, @"HTTP request must be made, or is the BKRequest object bad: %@", nextRequest);
	}
	
	if (!HTTPRequest.shouldWaitUntilDone) {
		[queue removeObjectAtIndex:0];
	}    
}

- (void)runQueue
{
    if (self.shouldWaitUntilDone) {
        [self _runQueue];
    }
    else {
        [self performSelector:@selector(_runQueue) withObject:nil afterDelay:0.0];
    }
}

- (void)setPaused:(BOOL)inPaused
{
    BOOL resumeQueue = (paused && !inPaused);    
    paused = inPaused;
    
    if (resumeQueue) {
        [self runQueue];
    }    
}

- (BOOL)isRunning
{
	return [HTTPRequest isRunning];
}

- (void)cancelAllRequests
{
	[self cancelRequestsWithBlock:^(BKRequest *r) { return YES; }];
}

- (void)cancelRequest:(BKRequest *)inRequest
{
	[self cancelRequestsWithBlock:^(BKRequest *r) { return (BOOL)(inRequest == r); }];
}

- (void)cancelRequestsOfTarget:(id)inTarget
{
	[self cancelRequestsWithBlock:^(BKRequest *r) { return (BOOL)(inTarget == r.target); }];	
}

- (void)cancelRequestsWithPredicate:(NSPredicate *)inPredicate
{
	[self cancelRequestsWithBlock:^(BKRequest *r) { return [inPredicate evaluateWithObject:r]; }];
}

- (void)cancelRequestsWithBlock:(BOOL (^)(BKRequest *))inFilter
{
	if ([HTTPRequest isRunning]) {
		if (inFilter((BKRequest *)HTTPRequest.sessionInfo)) {
			[HTTPRequest cancelWithoutDelegateMessage];
			[[HTTPRequest.sessionInfo retain] autorelease];
			HTTPRequest.sessionInfo = nil;
		}
	}

	NSMutableArray *newQueue = [NSMutableArray array];
	for (BKRequest *request in queue) {
		if (!inFilter(request)) {
			[newQueue addObject:request];
		}
	}
	
	[queue removeAllObjects];
	[queue addObjectsFromArray:newQueue];
	[self runQueue];
}


#pragma mark LFHTTPRequest delegate methods

- (void)httpRequest:(LFHTTPRequest *)inRequest didReceiveStatusCode:(NSUInteger)statusCode URL:(NSURL *)url responseHeader:(CFHTTPMessageRef)header
{
	if (statusCode != 200) {
		[inRequest cancelWithoutDelegateMessage];
		[self httpRequest:inRequest didFailWithError:BKHTTPRequestServerError];
	}
}

- (void)httpRequestDidComplete:(LFHTTPRequest *)inRequest
{
	BKRequest *request = inRequest.sessionInfo;
	NSData *receivedData = inRequest.receivedData;
	
	[cachePolicy requestQueue:self storeData:receivedData ofRequest:request];
	
    [request requestQueue:self didCompleteWithData:receivedData];
	[request requestQueueRequestDidFinish:self];
    [self runQueue];
}

- (void)httpRequest:(LFHTTPRequest *)inRequest didFailWithError:(NSString *)inError
{
	BKRequest *request = inRequest.sessionInfo;
	
	[cachePolicy requestQueue:self storeData:nil ofRequest:request];
	
    [request requestQueue:self didFailWithError:inError];
	[request requestQueueRequestDidFinish:self];
    [self runQueue];
}

@synthesize cachePolicy;
@synthesize paused;
@end
