#import "DocSetBookProvider.h"

#import "DocSet.h"
#include <pwd.h>

@implementation DocSetBookProvider

- (NSArray *) availableBooks {

	char *home = getpwuid(getuid())->pw_dir;

	NSString *libraryDocSetPath = [[NSString stringWithCString:home encoding:NSUTF8StringEncoding] stringByAppendingPathComponent:@"Library/Developer/Shared/Documentation/DocSets/"];

	NSArray *docSetPaths = [NSArray arrayWithObjects:@"/Library/Developer/Documentation/DocSets/", @"/Library/Developer/Shared/Documentation/DocSets/", libraryDocSetPath, nil];

	NSLog(@"Scanning for docsets: %@", docSetPaths);

	NSFileManager *fileManager = [NSFileManager new];

	NSMutableArray *results = [NSMutableArray array];

	for(NSString *docsPath in docSetPaths) {

		if (![fileManager fileExistsAtPath:docsPath]) {
			NSLog(@"DocSetBookProvider: '%@' does not exist", docsPath);
			continue;
		}

		NSArray *files = [fileManager contentsOfDirectoryAtPath:docsPath error:nil];
		for(NSString *file in files) {
			if (![file hasSuffix:@".docset"] || [file rangeOfString:@"com.apple.adc.documentation"].location == NSNotFound)
				continue;

			NSString *docsetPath = [docsPath stringByAppendingPathComponent:file];
			[results addObject:[[DocSet alloc] initWithDocSetPath:docsetPath]];
		}

	}

	LogDebug(@"%@", results);
	return [NSArray arrayWithArray:results];
}

@end
