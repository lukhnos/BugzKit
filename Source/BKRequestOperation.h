//
// BKRequestOperation.h
//
// Copyright (c) 2007-2010 Lithoglyph Inc. All rights reserved.
//

#import "BKRequest.h"

@interface BKRequestOperation : NSOperation
{
    BKRequest *request;
    __weak NSOperationQueue *operationQueue;
}
- (id)initWithRequest:(BKRequest *)inRequest operationQueue:(NSOperationQueue *)inQueue;

// Override these (no need to call super)
- (void)fetchMappedXMLData;
- (void)cancelFetch;

// The default behavior is to invoke the selector in the same thread; you might want to do otherwise (no need to call super if overriden)
- (void)dispatchSelector:(SEL)inSelector;

// Override these (no need to call super if overriden)
- (void)handleRequestStarted;
- (void)handleRequestCancelled;
- (void)handleRequestCompleted;
- (void)handleRequestFailed;
- (void)handleRequestOperationEnded;

@property (readonly) BKRequest *request;
@property (readonly) __weak NSOperationQueue *operationQueue;
@end
