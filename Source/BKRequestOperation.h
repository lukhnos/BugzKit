//
// BKRequestOperation.h
//
// Copyright (c) 2009-2011 Lithoglyph Inc. All rights reserved.
//

#import "BKRequest.h"

@interface BKRequestOperation : NSOperation
{
    BKRequest *request;
}
- (id)initWithRequest:(BKRequest *)inRequest;

// Override these (no need to call super)
- (void)fetchMappedXMLData;
- (void)cancelFetch;

// The default behavior is to invoke the selector in the same thread; you might want to do otherwise (no need to call super if overriden)
- (void)dispatchSelector:(SEL)inSelector;

// Override these (no need to call super if overriden)
- (void)handleRequestStarted;
- (void)handleRequestCancelled;
- (void)processRequestCompletion;   // invoked in the same thread of the -main
- (void)handleRequestCompleted;     // dispatched, usually in the thread the operation is created 
- (void)handleRequestFailed;
- (void)handleRequestOperationEnded;

// Internal handler for dependency-caused cancellation, invoked by -main
- (void)handleDependencyCancellation;

@property (readonly) BKRequest *request;
@end
