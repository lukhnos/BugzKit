//
// BKRequestOperation.m
//
// Copyright (c) 2009-2011 Lithoglyph Inc. All rights reserved.
//

#import "BKRequestOperation.h"
#import "BKPrivateUtilities.h"

@implementation BKRequestOperation
- (void)dealloc
{
    BKReleaseClean(request);
    [super dealloc];
}

- (id)initWithRequest:(BKRequest *)inRequest
{
    self = [super init];
    if (self) {
        request = [inRequest retain];
    }
    
    return self;
}

- (void)fetchMappedXMLData;
{
}

- (void)cancelFetch
{    
}

// The default behavior is to invoke the selector in the same thread; you might want to do otherwise (no need to call super if overriden)
- (void)dispatchSelector:(SEL)inSelector
{
    [self performSelector:inSelector];
}

// Override these (no need to call super if overriden)
- (void)handleRequestStarted
{
}

- (void)handleRequestCancelled
{
}

- (void)processRequestCompletion
{
}

- (void)handleRequestCompleted
{
}

- (void)handleRequestFailed
{
}

- (void)handleRequestOperationEnded
{
}

// Internal handler

- (void)handleDependencyCancellation
{
    [self cancel];    
}

#pragma mark Overriden NSOperationQueue methods

- (void)cancel
{
	BOOL alreadyCanceled = [self isCancelled];
	BOOL alreadyFinished = [self isFinished];
	
    [super cancel];
	
    if (!alreadyCanceled && !alreadyFinished) {
        [self cancelFetch];    
        [self dispatchSelector:@selector(handleRequestCancelled)];
        [self dispatchSelector:@selector(handleRequestOperationEnded)];
    }
}

- (void)main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // see if any of the dependencies is cancelled or has error
    BOOL allDependenciesCompleted = YES;
    for (BKRequestOperation *dependency in [self dependencies]) {
        if ([dependency isCancelled] || ([dependency isKindOfClass:[BKRequestOperation class]] && dependency.request.error)) {
            allDependenciesCompleted = NO;
            break;
        }
    }
    
    if (allDependenciesCompleted) {    
        [self dispatchSelector:@selector(handleRequestStarted)];

        [self fetchMappedXMLData];
        
        if (![self isCancelled]) {
            if (request.error || !request.rawXMLMappedResponse) {
                [self dispatchSelector:@selector(handleRequestFailed)];            
            }
            else {
                [self processRequestCompletion];
                [self dispatchSelector:@selector(handleRequestCompleted)];            
            }
            
            [self dispatchSelector:@selector(handleRequestOperationEnded)];
        }
    }
    else {
        [self handleDependencyCancellation];
    }
    
    [pool drain];
}

@synthesize request;
@end
