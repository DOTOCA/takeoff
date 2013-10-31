#import "DocSet.h"

#import "Book.h"
#import "Entry.h"
#import "Foundation+Additions.h"
#import "FileStorage.h"
#import "DsIdx.h"
#import "DsClassReference.h"
#import "ZipFileStorage.h"
#import "FileUtils.h"
#import <sqlite3.h>

@implementation DocSet

@synthesize classDocPredicate;

- (NSDictionary *) docsetInfo {
	NSString *plistPath = [[NSURL URLWithString:@"../../Info.plist" relativeToURL:self.absoluteURL] path];
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	NSParameterAssert(dictionary);
	return dictionary;
}

- (id) initWithDocSetPath:(NSString *)pDocsetPath {
    self = [super init];
    if (self) {
		self.url = [NSString stringWithFormat:@"file://%@/", [pDocsetPath stringByAppendingPathComponent:@"Contents/Resources/Documents/"]];
		self.title = [[self docsetInfo] objectForKey:@"CFBundleName"];
		self.title = [self.title stringByReplacingOccurrencesOfString:@" Core Library" withString:@""];
		self.title = [self.title stringByReplacingOccurrencesOfString:@" Library" withString:@""];
		self.title = [self.title stringByReplacingOccurrencesOfString:@" doc set" withString:@""];
		LogDebug(@"=> %@ @ %@", self.title, self.url);
	}
    return self;
}

- (void) install:(id<ProgressHandler>)progress {
	NSString *name = [NSString stringWithFormat:@"docset_%@.takeoff", [[self docsetInfo] objectForKey:@"CFBundleIdentifier"]];
	NSString *zipPath = [[FileUtils applicationSupportPath] stringByAppendingPathComponent:name];

	self.storage = [[ZipFileStorage alloc] initWithPath:zipPath create:YES];

	DsIdx *dsidx = [[DsIdx alloc] initWithPath:[[NSURL URLWithString:@"../docSet.dsidx" relativeToURL:self.absoluteURL] path]];

	NSMutableDictionary *frameworks = [NSMutableDictionary dictionary];

	NSArray *allClasses = dsidx.allClasses;

	const double unit = (double)BOOK_INSTALL_ESTIMATE/allClasses.count;

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply([allClasses count], queue, ^(size_t index){
        ClassDoc *cl = [allClasses objectAtIndex:index];

		[progress worked:unit];

		if (classDocPredicate && ![classDocPredicate evaluateWithObject:cl])
			return;

		DsClassReference *classReference = [[DsClassReference alloc] initWithURL:[NSURL URLWithString:cl.path relativeToURL:self.absoluteURL]];

		NSString *frameworkName = cl.framework;

		if (!frameworkName) {
			frameworkName = classReference.framework;
		}

		if (!frameworkName) {
			NSLog(@"No framework for: %@", cl);
			return;
		}

		Entry *frameworkEntry;
		@synchronized(frameworks) {
			frameworkEntry = [frameworks objectForKey:frameworkName];
			if (!frameworkEntry) {
				frameworkEntry = [Entry entryWithParent:self title:frameworkName];
				[frameworks setObject:frameworkEntry forKey:frameworkName];
			}
		}

		if (!cl.name) {
			NSLog(@"Class without name: %@", cl);
		} else {
			Entry *classEntry = classReference.tasks;
			if (classEntry) {
				classEntry.parent = frameworkEntry;
				classEntry.url = cl.path;
				classEntry.title = cl.name;
				classEntry.icon = @"c";
			}
		}

    });

	[self sortEntriesByTitle];

	[self filter:nil];
	[self updateIndex];
	[super install:progress];

}

- (NSUInteger) hash {
	return self.url.hash;
}

- (BOOL)isEqual:(id)object {
	return [object isKindOfClass:[DocSet class]] && [self.url isEqual:((DocSet *)object).url];
}

@end
