#import "FileUtils.h"

@implementation FileUtils

+ (NSString *) applicationSupportPath {
	NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
	NSAssert([executableName length] > 0, @"No CFBundleExecutable in Info.plist");
	NSArray *supportDirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSAssert([supportDirs count] > 0, @"Empty result for for NSApplicationSupportDirectory");
	NSString *path = [[supportDirs objectAtIndex:0] stringByAppendingPathComponent:executableName];

	BOOL directory;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&directory]) {
		NSAssert(directory, @"%@ exists, but is not a directory!", path);
		return path;
	}

	NSError *error;
	BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
	NSAssert(created, @"Application support folder %@ could not be created!", path);

	return path;
}

@end
