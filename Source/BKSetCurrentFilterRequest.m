//
// BKSetCurrentFilterRequest.m
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

#import "BKSetCurrentFilterRequest.h"

// TODO: Refactor this
#import "LFHTTPRequest.h"

@implementation BKSetCurrentFilterRequest
- (void)dealloc
{
	[filterName release];
	[super dealloc];
}

+ (id)requestWithAPIContext:(BKAPIContext *)inAPIContext filterName:(NSString *)inFilterName
{
	return [[[self alloc] initWithAPIContext:inAPIContext filterName:inFilterName] autorelease];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext filterName:(NSString *)inFilterName
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		filterName = [inFilterName copy];
		
		// TODO: Check if API keeps the name
		// TODO: Ask if there's a way to set the sFilter to none
		requestParameterDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"setCurrentFilter", @"cmd", inAPIContext.authToken, @"token", ([inFilterName length] ? inFilterName : @"inbox"), @"sFilter", nil] retain];
	}
	
	return self;	
}

- (BOOL)usesPOSTRequest
{
    return YES;
}

// TODO: Removes this
- (NSString *)HTTPRequestMethod
{
	return LFHTTPRequestPOSTMethod;
}

@synthesize filterName;
@end
