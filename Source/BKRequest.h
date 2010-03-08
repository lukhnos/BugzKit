//
// BKRequest.h
//
// Copyright (c) 2009-2010 Lukhnos D. Liu (http://lukhnos.org)
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
    BKAPIContext *APIContext;
    NSDictionary *requestParameterDict;

	NSDictionary *rawXMLMappedResponse;
    id processedResponse;
    NSError *error;
}
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext;

// methods to be overriden by subclasses
- (void)postprocessError:(NSError *)inError;
- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse;
- (NSError *)validateResponse:(NSDictionary *)inXMLMappedResponse;

// properties used by request drivers
@property (readonly, nonatomic) NSString *HTTPRequestContentType;
@property (readonly, nonatomic) NSData *requestData;
@property (readonly, nonatomic) NSInputStream *requestInputStream;
@property (readonly, nonatomic) NSUInteger requestInputStreamSize;
@property (readonly, nonatomic) NSURL *requestURL;
@property (readonly, nonatomic) BOOL usesPOSTRequest;

// response
@property (retain, nonatomic) NSDictionary *rawXMLMappedResponse;
@property (retain, nonatomic) id processedResponse;
@property (retain, nonatomic) NSError *error;
@end
