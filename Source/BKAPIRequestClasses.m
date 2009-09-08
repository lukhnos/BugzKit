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
	[APIContext setMajorVersion:[[inXMLMappedResponse objectForKey:@"version"] integerValue]];
	[APIContext setMinorVersion:[[inXMLMappedResponse objectForKey:@"minversion"] integerValue]];
	return [super postprocessResponse:inXMLMappedResponse];
}
@end

@implementation BKLogOnRequest : BKRequest
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext accountName:(NSString *)inAccountName password:(NSString *)inPassword
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		requestParameterDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"logon", @"cmd", inAccountName, @"email", inPassword, @"password", nil] retain];
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

@implementation BKLogOffRequest : BKRequest
- (id)initWithAPIContext:(BKAPIContext *)inAPIContext
{
	if (self = [super initWithAPIContext:inAPIContext]) {
		requestParameterDict = [[NSDictionary dictionaryWithObjectsAndKeys:@"logoff", @"cmd", inAPIContext.authToken, @"token", nil] retain];
	}
	
	return self;	
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	[APIContext setAuthToken:nil];
	return nil;
}
@end