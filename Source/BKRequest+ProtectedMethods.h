//
// BKRequest+PrivateMethods.h
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

#import "BKRequest.h"
#import "BKRequestQueue.h"

@interface BKRequest (ProtectedMethods)
- (void)recycleIfUsedBefore;

- (void)requestQueueRequestDidiEnqueue:(BKRequestQueue *)inQueue;
- (void)requestQueueWillBeginRequest:(BKRequestQueue *)inQueue;
- (void)requestQueue:(BKRequestQueue *)inQueue didCompleteWithMappedXMLDictionary:(NSDictionary *)inMappedXMLDictionary rawData:(NSData *)inRawData usingCachedResponse:(BOOL)inUsingCache;
- (void)requestQueue:(BKRequestQueue *)inQueue didFailWithError:(NSString *)inHTTPRequestError;
- (void)requestQueueDidGetCancelled:(BKRequestQueue *)inQueue;
- (void)requestQueueRequestDidFinish:(BKRequestQueue *)inQueue;

- (NSDictionary *)preparedParameterDict;
- (NSString *)preparedParameterString;
- (NSError *)errorFromXMLMappedResponse:(NSDictionary *)inXMLMappedResponse;

// override these
- (NSError *)validateResponse:(NSDictionary *)inXMLMappedResponse;
- (void)postprocessError:(NSError *)inError;
- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse;
@end

extern NSString *const BKHTTPRequestServerError;