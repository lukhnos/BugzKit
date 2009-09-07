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

@interface BKRequest : NSObject
{
    id target;
    SEL actionOnSuccess;
    SEL actionOnFailure;
    id userInfo;
    NSString *HTTPRequestMethod;
    BKAPIContext *APIContext;
    NSDictionary *requestParameterDict;
    NSDictionary *response;
    NSError *error;
    NSDate *creationDate;
}
@property (assign) id target;
@property (assign) SEL actionOnSuccess;
@property (assign) SEL actionOnFailure;
@property (retain) id userInfo;
@property (readonly) NSString *HTTPRequestMethod;
@property (readonly) BKAPIContext *APIContext;
@property (readonly) NSDictionary *requestParameterDict;
@property (readonly) NSURL *requestURL;
@property (readonly) NSData *requestData;
@property (readonly) NSDictionary *response;
@property (readonly) NSError *error;
@property (readonly) NSDate *creationDate;
@end
