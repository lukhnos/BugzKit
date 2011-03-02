#import "RequestOperation.h"

@implementation RequestOperation
@synthesize onCompletion;
@synthesize onFailure;

- (void)dealloc
{
    [onCompletion release], onCompletion = nil;
    [onFailure release], onFailure = nil;
    [super dealloc];
}

- (void)fetchMappedXMLData
{
    NSLog(@"%s, making request: %@", __PRETTY_FUNCTION__, request.requestURL);

    NSError *error = NULL;
    NSData *data = [NSData dataWithContentsOfURL:request.requestURL options:0 error:&error];
    if (error || !data) {
        request.error = error ? error : [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:-1 userInfo:nil];
    }
    else {
        request.rawXMLMappedResponse = [BKXMLMapper dictionaryMappedFromXMLData:data];
    }
}

- (void)cancelFetch
{
    // in production code, cancel your HTTP request here
}

- (void)dispatchSelector:(SEL)inSelector
{
    // The default behavior is to invoke the selector in the same thread
    // In production code, you might want to handle your -handleRequestStarted in e.g. main thread, so dispatch the selector here
    [super dispatchSelector:inSelector];
}

// Override these (no need to call super if overriden)
- (void)handleRequestStarted
{
    // invoke callback when the op gets started (when it's the op's turn to run)
}

- (void)handleRequestCancelled
{
    // invoke callback when the op gets cancelled
}

- (void)processRequestCompletion
{
    // invoked in the same thread of the -main
    if (onCompletion) {
        onCompletion();
        
        // zap the block references to break retain cycle (esp. if the block references to the op)
        self.onCompletion = nil;
        self.onFailure = nil;
    }
}

- (void)handleRequestCompleted
{
    // invoke callback when the request (not the op) is completed successfully
}

- (void)handleRequestFailed
{
    // invoke callback when the op failed (data fetch failed, etc.)
    if (onFailure) {
        onFailure();

        // zap the block references to break retain cycle (esp. if the block references to the op)
        self.onCompletion = nil;
        self.onFailure = nil;
    }
}

- (void)handleRequestOperationEnded
{
    // invoke callback when the op is completed (even if it gets cancelled)
}

- (void)handleDependencyCancellation
{
    // you can decide if you want to cancel this op's dependencies if this op gets cancelled
    for (RequestOperation *op in [self dependencies]) {
        if (![op isKindOfClass:[RequestOperation class]]) {
            continue;
        }
        
        if ([op isCancelled] || op.request.error != nil) {
            [self cancel];
            return;
        }
    }
}
@end
