//
// BKRequest.h
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

#import "BKAPIContext.h"

@class BKRequest;

@interface BKRequest : NSObject
{
    id target;
    SEL actionOnSuccess;
    SEL actionOnFailure;
	
	void (^blockBeforeRequestStart)(BKRequest *);
	void (^blockOnSuccess)(BKRequest *);
	void (^blockOnFailure)(BKRequest *);
	void (^blockAfterRequestEnd)(BKRequest *);
	
    id userInfo;
    BKAPIContext *APIContext;
    NSDictionary *requestParameterDict;
	NSData *rawResponseData;
	NSDictionary *rawXMLMappedResponse;
    id processedResponse;
    NSError *error;
    NSDate *creationDate;
}
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext;
- (void)setTarget:(id)inTarget actionOnSuccess:(SEL)inActionOnSuccess actionOnFailure:(SEL)inActionOnFailure;

@property (assign) id target;
@property (assign) SEL actionOnSuccess;
@property (assign) SEL actionOnFailure;

@property (copy) void (^blockBeforeRequestStart)(BKRequest *);
@property (copy) void (^blockOnSuccess)(BKRequest *);
@property (copy) void (^blockOnFailure)(BKRequest *);
@property (copy) void (^blockAfterRequestEnd)(BKRequest *);
@property (retain) id userInfo;
@property (readonly) NSString *HTTPRequestMethod;
@property (readonly) NSString *HTTPRequestContentType;
@property (readonly) BKAPIContext *APIContext;
@property (readonly) NSData *rawResponseData;
@property (readonly) NSString *rawResponseString;
@property (readonly) NSDictionary *requestParameterDict;
@property (readonly) NSURL *requestURL;
@property (readonly) NSData *requestData;
@property (readonly) NSDictionary *rawXMLMappedResponse;
@property (readonly) id processedResponse;
@property (readonly) NSError *error;
@property (readonly) NSDate *creationDate;
@end
