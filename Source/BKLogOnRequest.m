//
// BKLogOnRequest.m
//
// Copyright (c) 2009-2011 Lukhnos D. Liu (http://lukhnos.org)
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

#import "BKLogOnRequest.h"
#import "BKAPIContext+ProtectedMethods.h"
#import "BKPrivateUtilities.h"

@implementation BKLogOnRequest : BKRequest
+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext accountName:(NSString *)inAccountName password:(NSString *)inPassword
{
	return [[[self alloc] initWithAPIContext:inAPIContext accountName:inAccountName password:inPassword] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext accountName:(NSString *)inAccountName password:(NSString *)inPassword
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		requestParameterDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"logon", @"cmd", BKNotNil(inAccountName), @"email", BKNotNil(inPassword), @"password", nil] retain];
	}
	
	return self;
}

- (void)postprocessError:(NSError *)inError
{
	[APIContext setAuthToken:nil];
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	NSString *token = [inXMLMappedResponse objectForKey:@"token"];
    [APIContext setAuthToken:token];
	
	return token;
}
@end
