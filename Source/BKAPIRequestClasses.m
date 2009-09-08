//
// BKAPIRequestClasses.m
//
// Copyright (c) 2007-2009 Lithoglyph Inc. All rights reserved.
//

#import "BKAPIRequestClasses.h"
#import "BKAPIContext+ProtectedMethods.h"

@implementation BKVersionCheckRequest
- (NSURL *)requestURL
{
    return [NSURL URLWithString:@"api.xml" relativeToURL:APIContext.serviceRoot];
}

- (void)postprocessResponse
{
    [APIContext setEndpoint:[response objectForKey:@"url"]]
}
@end
