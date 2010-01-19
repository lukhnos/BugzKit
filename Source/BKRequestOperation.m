//
// BKRequestOperation.m
//
// Copyright (c) 2007-2010 Lithoglyph Inc. All rights reserved.
//

#import "BKRequestOperation.h"
#import "BKPrivateUtilities.h"

@implementation BKRequestOperation
- (void)dealloc
{
    BKReleaseClean(request);
    [super dealloc];
}

- (id)initWithRequest:(BKRequest *)inRequest operationQueue:(NSOperationQueue *)inQueue
{
    if (self = [super init]) {
        request = [inRequest retain];
        operationQueue = inQueue;
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

- (void)handleRequestCompleted
{
}

- (void)handleRequestFailed
{
}

- (void)handleRequestOperationEnded
{
}

#pragma mark Overriden NSOperationQueue methods

- (void)cancel
{
    [super cancel];
    [self cancelFetch];    
    [self dispatchSelector:@selector(handleRequestCancelled)];
    [self dispatchSelector:@selector(handleRequestOperationEnded)];
}

- (void)main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [self dispatchSelector:@selector(handleRequestStarted)];

    [self fetchMappedXMLData];
    
    if (![self isCancelled]) {
        if (request.error) {
            [self dispatchSelector:@selector(handleRequestFailed)];            
        }
        else {
            [self dispatchSelector:@selector(handleRequestCompleted)];            
        }
        
        [self dispatchSelector:@selector(handleRequestOperationEnded)];
    }
    
    [pool drain];
}

@synthesize request;
@synthesize operationQueue;
@end
