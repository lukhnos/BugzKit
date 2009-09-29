//
// BKAPIContext.m
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
#import "BKAPIContext+ProtectedMethods.h"
#import "BKPrivateUtilities.h"

@implementation BKAPIContext
- (void)dealloc
{
    [serviceRoot release];
    [endpoint release];
    [authToken release];
    [super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> {serviceRoot: %@, API version: %@, endpoint: %@, authToken: %@}", [self class], self, BKQuotedString([serviceRoot absoluteString]), [NSString stringWithFormat:@"%jd.%jd", (uintmax_t)majorVersion, (uintmax_t)minorVersion], BKQuotedString([endpoint absoluteString]), BKQuotedString(authToken)];
}

- (NSURL *)serviceRoot
{
	return [[serviceRoot copy] autorelease];
}

- (void)setServiceRoot:(NSURL *)inRoot
{
	BKRetainAssign(serviceRoot, inRoot);
	majorVersion = 0;
	minorVersion = 0;
	BKReleaseClean(endpoint);
	BKReleaseClean(authToken);
}

@synthesize serviceRoot;
@synthesize majorVersion;
@synthesize minorVersion;
@synthesize endpoint;
@synthesize authToken;
@end

@implementation BKAPIContext (ProtectedMethods)
- (void)setMajorVersion:(NSUInteger)inVersion
{
	majorVersion = inVersion;
}

- (void)setMinorVersion:(NSUInteger)inVersion
{
	minorVersion = inVersion;
}

- (void)setAuthToken:(NSString *)inAuthToken
{
    BKRetainAssign(authToken, inAuthToken);
}

- (void)setEndpoint:(NSURL *)inEndpoint
{
    BKRetainAssign(endpoint, inEndpoint);
}
@end
