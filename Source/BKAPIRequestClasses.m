//
// BKAPIRequestClasses.m
//
// Copyright (c) 2007-2009 Lithoglyph Inc. All rights reserved.
//

#import "BKAPIRequestClasses.h"
#import "BKAPIContext+ProtectedMethods.h"
#import "BKRequest+ProtectedMethods.h"

@implementation BKVersionCheckRequest
- (NSURL *)requestURL
{
    return [NSURL URLWithString:@"api.xml" relativeToURL:APIContext.serviceRoot];
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
    [APIContext setEndpoint:[NSURL URLWithString:[inXMLMappedResponse objectForKey:@"url"] relativeToURL:APIContext.serviceRoot]];
	return [super postprocessResponse:inXMLMappedResponse];
}
@end
