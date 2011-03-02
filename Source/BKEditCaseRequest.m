//
// BKEditCaseRequest.m
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

#import "BKEditCaseRequest.h"
#import "BKPrivateUtilities.h"

NSString *const BKAssignCaseAction = @"assign";
NSString *const BKCloseCaseAction = @"close";
NSString *const BKEditCaseAction = @"edit";
NSString *const BKEmailCaseAction = @"email";
NSString *const BKForwardCaseAction = @"forward";
NSString *const BKNewCaseAction = @"new";
NSString *const BKReactivateCaseAction = @"reactivate";
NSString *const BKReopenCaseAction = @"reopen";
NSString *const BKReplyCaseAction = @"reply";
NSString *const BKResolveCaseAction = @"resolve";

@implementation BKEditCaseRequest
- (void)cleanUpTempFile
{
	if (![tempFilename length]) {
		return;
	}
	
	BOOL isDir = NO;
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	if ([fileManager fileExistsAtPath:tempFilename isDirectory:&isDir]) {
		
		NSError *ourError = NULL;
		BOOL __unused removeResult = [[NSFileManager defaultManager] removeItemAtPath:tempFilename error:&ourError];
		NSAssert2(removeResult, @"Must remove the temp file at: %@, error: %@", tempFilename, ourError);
	}
	[fileManager release];
}

- (void)prepareTempFile
{
	if ([tempFilename length]) {
		return;
	}
	
	NSString *bundleID = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(id)kCFBundleIdentifierKey];
	NSString *filenameRoot = [NSTemporaryDirectory() stringByAppendingFormat:@"%@.%@.data-XXXXXX", NSStringFromClass([self class]), bundleID];
	
	const char *filenameUTF8 = [filenameRoot UTF8String];
	char *writableFilename = (char *)calloc(1, strlen(filenameUTF8) + 1);
	strncpy(writableFilename, filenameUTF8, strlen(filenameUTF8));
	
	mktemp(writableFilename);
	tempFilename = [[NSString alloc] initWithUTF8String:writableFilename];
	
    // build the multipart form
    NSMutableString *multipartBegin = [NSMutableString string];
    NSMutableString *multipartEnd = [NSMutableString string];
    
	for (NSString *key in requestParameterDict) {
		NSString *value = [requestParameterDict objectForKey:key];
		[multipartBegin appendFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", multipartSeparator, key, value];
	}
	
	
    // add filename, if nil, generate a UUID
	
    [multipartEnd appendFormat:@"--%@--", multipartSeparator];
    
    
    // create the write stream
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:tempFilename append:NO];
    [outputStream open];
    
    const char *UTF8String;
    size_t writeLength;
    UTF8String = [multipartBegin UTF8String];
    writeLength = strlen(UTF8String);
	
	size_t __unused actualWrittenLength;
	actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
    NSAssert(actualWrittenLength == writeLength, @"Must write multipartBegin");
	
	NSUInteger fileIndex = 1;
	for (NSURL *u in attachmentURLs) {
		// TODO: Speed this part up (measure performance first)
		NSData *d = [NSData dataWithContentsOfURL:u];
		
		// TODO: Ensure the correctness
		NSString *lastPathComponent = [u lastPathComponent];
		
		NSMutableString *fileHeader = [NSMutableString string];
		
		[fileHeader appendFormat:@"--%@\r\nContent-Disposition: form-data; name=\"File%ju\"; filename=\"%@\"\r\n", multipartSeparator, (uintmax_t)fileIndex, lastPathComponent];
		[fileHeader appendFormat:@"Content-Type: %@\r\n\r\n", @"application/octet-stream"];
		
		
		UTF8String = [fileHeader UTF8String];
		writeLength = strlen(UTF8String);
		actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
		NSAssert(actualWrittenLength == writeLength, @"Must write fileHeader");
		
		actualWrittenLength = [outputStream write:[d bytes] maxLength:[d length]];
		NSAssert(actualWrittenLength == [d length], @"Must write binary data");
		
		NSString *fileEnd = @"\r\n";
		
		UTF8String = [fileEnd UTF8String];
		writeLength = strlen(UTF8String);
		actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
		NSAssert(actualWrittenLength == writeLength, @"Must write fileHeader");
		
		fileIndex++;
	}
	
    
    UTF8String = [multipartEnd UTF8String];
    writeLength = strlen(UTF8String);
	actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
    NSAssert(actualWrittenLength == writeLength, @"Must write multipartEnd");
    [outputStream close];
}

- (void)dealloc
{
	[self cleanUpTempFile];
	[multipartSeparator release];
	[tempFilename release];
	[attachmentURLs release];
	[super dealloc];
}

- (void)finalize
{
	[self cleanUpTempFile];
	[super finalize];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction caseNumber:(NSUInteger)inCaseNumber parameters:(NSDictionary *)inParameters attachmentURLs:(NSArray *)inURLs attachmentsFromBugEventID:(NSUInteger)inEventID;
{
    self = [super initWithAPIContext:inAPIContext];
	if (self) {
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		
		[d setObject:inAPIContext.authToken forKey:@"token"];
		[d setObject:inAction forKey:@"cmd"];
		
		if (inCaseNumber) {
			[d setObject:[NSString stringWithFormat:@"%ju", (uintmax_t)inCaseNumber] forKey:@"ixBug"];
		}
				
		if (inEventID) {
			[d setObject:[NSString stringWithFormat:@"%ju", (uintmax_t)inEventID] forKey:@"ixBugEventAttachment"];
		}
		
		if ([inURLs count]) {
			[d setObject:[NSString stringWithFormat:@"%ju", (uintmax_t)[inURLs count]] forKey:@"nFileCount"];
		}
		
		if (inParameters) {
			[d addEntriesFromDictionary:inParameters];
		}
		
		requestParameterDict = [d retain];
		
		if ([inURLs count]) {
			attachmentURLs = [[NSArray alloc] initWithArray:inURLs];
		}
		
		multipartSeparator = [BKGenerateUUID() retain];		
	}
	
	return self;	
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction caseNumber:(NSUInteger)inCaseNumber parameters:(NSDictionary *)inParameters
{
	return [self initWithAPIContext:inAPIContext editAction:inAction caseNumber:inCaseNumber parameters:inParameters attachmentURLs:nil attachmentsFromBugEventID:0];
}

- (id)initWithAPIContext:(BKAPIContext *)inAPIContext editAction:(NSString *)inAction parameters:(NSDictionary *)inParameters
{
	return [self initWithAPIContext:inAPIContext editAction:inAction caseNumber:0 parameters:inParameters attachmentURLs:nil attachmentsFromBugEventID:0];
}

- (id)postprocessResponse:(NSDictionary *)inXMLMappedResponse
{
	id result = [inXMLMappedResponse valueForKeyPath:@"case"];
	if (!result) {
		result = [NSDictionary dictionary];
	}
	
	return result;
}

- (NSString *)editAction
{
	return [requestParameterDict objectForKey:@"cmd"];
}

- (NSDictionary *)editedCase
{
	return processedResponse;
}


- (BOOL)usesPOSTRequest
{
    return YES;
}

- (NSString *)HTTPRequestContentType
{
	return [attachmentURLs count] ? [NSString stringWithFormat:@"multipart/form-data; boundary=%@", multipartSeparator] : [super HTTPRequestContentType];
}

- (NSUInteger)requestInputStreamSize
{
	if (![attachmentURLs count]) {
		return 0;
	}
	
	[self prepareTempFile];	
	NSError *fileError = NULL;
	NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:tempFilename error:&fileError];	
	return [[info objectForKey:NSFileSize] unsignedIntegerValue];
}

- (NSInputStream *)requestInputStream
{
	if (![attachmentURLs count]) {
		return 0;
	}
	
	[self prepareTempFile];
	return [NSInputStream inputStreamWithFileAtPath:tempFilename];
}

- (NSData *)requestData
{
	return [attachmentURLs count] ? nil : [super requestData];
}
@end
