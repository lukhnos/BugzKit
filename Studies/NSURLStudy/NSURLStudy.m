#import <Cocoa/Cocoa.h>

int main()
{
	[[NSAutoreleasePool alloc] init];
	
	NSURL *a = [NSURL URLWithString:@"http://www.example.org"];
	NSURL *b = [NSURL URLWithString:@"/example.php" relativeToURL:a];
	NSURL *c = [NSURL URLWithString:@"?a=b" relativeToURL:b];
	
	NSLog(@"a: %@", [a absoluteString]);
	NSLog(@"b: %@, relative part: %@", [b absoluteString], [b relativePath]);
	NSLog(@"c: %@, relative part: %@, query: %@", [c absoluteString], [c relativePath], [c query]);
	
	
	return 0;
}
