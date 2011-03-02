#import "BugzKit.h"

@interface RequestOperation : BKRequestOperation
{
    // remember to provide the actual ivars in 32-bit app
    // (auto synthesize is 64-bit ABI only)
}

// we implement a very simple, synchronous (in each thread) data fetch operation, which is not cancellable
// (i.e. it either completes, fails, or blocks its own thread until timeout)
@property (copy) void (^onCompletion)();
@property (copy) void (^onFailure)();
@end
