//
// BKPrivateUtilities.h
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

#define BKRetainAssign(foo, bar)    do { id tmp = foo; foo = [(id)bar retain]; [tmp release]; } while(0)
#define BKReleaseClean(foo)	        do { id tmp = foo; foo = nil; [tmp release]; } while(0)
#define BKAutoreleasedCopy(foo)     ([[foo copy] autorelease])


#define BKNotNil(x)		(x ? (id)x : (id)[NSNull null])
#define BKNotNSNull(x)	(x == [NSNull null] ? nil : x)

NS_INLINE NSString *BKEscapedURLStringFromNSString(NSString *inStr)
{
	CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)inStr, NULL, CFSTR("&"), kCFStringEncodingUTF8);
	
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4	
	return (NSString *)[escaped autorelease];			    
#else
	return (NSString *)[NSMakeCollectable(escaped) autorelease];			    
#endif
}

NS_INLINE NSString *BKPlistString(id plist)
{
	NSString *error;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
	
	if (!data) {
		return @"(not a valid plist)";
	}
	
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

NS_INLINE NSString *BKQuotedString(id s)
{
	if (s) {
		if ([s isKindOfClass:[NSURL class]]) {
			return [NSString stringWithFormat:@"\"%@\"", [s absoluteString]];
		}
		
		return [NSString stringWithFormat:@"\"%@\"", [s description]];
	}
	
	return nil;
}
