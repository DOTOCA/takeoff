#import "Library.h"

#import "FileUtils.h"
#import "NSData+Utils.h"
#import "StorageURLProtocol.h"
#import <WebKit/WebKit.h>
#import "Book.h"
#import "ZipFileStorage.h"
#import "URLMapping.h"
#import "LoadDelegate.h"
#import "DocSet.h"

NSString * const LibraryStateStrings[] = {
	@"Browser",
	@"Add",
};

@implementation Library

@synthesize state, bookProvider, onUpdate;

- (id) init {
    self = [super init];
    if (self) {
		queue = [NSOperationQueue new];
		bookProvider = [NSMutableArray array];
		state = LibraryStateBrowser;
		self.title = @"Library";
    }
    return self;
}

- (Book *) loadBook:(NSString *)path {
	LogDebug(@"loadBook:%@", path);
	id<StorageContainer> storage = [[ZipFileStorage alloc] initWithPath:path create:NO];
	Book *book = [Book loadFromStorage:storage];
	[self addBook:book];
	[book activate];
	return book;
}

- (void) scanFolder:(NSString *)path {
	NSDirectoryEnumerator *files = [[NSFileManager defaultManager] enumeratorAtPath:path];
	LogDebug(@"scan: %@", path);
	for(NSString *filename in files) {
		if ([filename hasSuffix:@".takeoff"]) {
			LogDebug(@" - %@", filename);
			NSOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadBook:) object:[path stringByAppendingPathComponent:filename]];
			[queue addOperation:operation];
		}
	}
}

+ (NSString *) archivePathByUrl:(NSURL *)url {
	NSString *hash = [[[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding] sha1];
	NSString *path = [[[FileUtils applicationSupportPath] stringByAppendingPathComponent:hash] stringByAppendingString:@".takeoff"];
	return path;
}

- (void) waitUntilAllBooksLoaded {
	[queue waitUntilAllOperationsAreFinished];
}

- (void) refilter {
	[self filter:filterTerm];
}

- (Book *) addBook:(Book *)book {
	@synchronized(self) {

		NSUInteger index = [self.entries indexOfObject:book];
		if (self.entries && index != NSNotFound) {
			return [self.entries objectAtIndex:index];
		} else {
			book.parent = self;
		}

		[self refilter];

		[self sortEntriesByTitle];

		if (onUpdate)
			onUpdate();
	}
	return book;
}

- (void) setState:(LibraryState)newState {
	LibraryState oldState = state;
	if (oldState != newState) {
		state = newState;

		NSLog(@"Library.state: %@ -> %@", LibraryStateStrings[oldState], LibraryStateStrings[newState]);

		// after each transition
		[self filter:nil];
	}
}

- (void) addAvailableBooks {
	dispatch_queue_t default_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply([bookProvider count], default_queue, ^(size_t index){
		NSArray *availableBooks = ((id<BookProvider>)[bookProvider objectAtIndex:index]).availableBooks;
		for(Book *book in availableBooks) {
			if ([self.entries indexOfObject:book] == NSNotFound) {
				[self addBook:book];
			}
		}
    });
}

- (void) handleLibraryChanges:(id<ProgressHandler>)progress {
	LogDebug(@"handleLibraryChanges: %@", self);

	for(Book *book in self.entries) {
		if(book.state == BookStateInstallRequested) {
			[progress startWork:BOOK_INSTALL_ESTIMATE];
		}
	}

	for(Book *book in self.entries) {
		[book handleLibraryChanges:(id<ProgressHandler>)progress];
	}
}

// trigger 'toggleAdd'
- (void) toggleAdd {
	// Browser -> Add
	if (state == LibraryStateBrowser) {
		[self addAvailableBooks];
		self.state = LibraryStateAdd;
	// Add -> Browser
	} else if (state == LibraryStateAdd) {
		self.state = LibraryStateBrowser;
	} else
		[NSException raise:@"StateTransitionNotAllowed" format:@"No transition for event toggleAdd in state %@",LibraryStateStrings[state]];
}

- (void) filter:(NSString *)term {
	filterTerm = term;

	if (state == LibraryStateAdd) {
		if (term) {
			filteredEntries = [self.entries filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(Entry *entry, NSDictionary *bindings) {
				return (BOOL)([entry.title rangeOfString:term options:NSCaseInsensitiveSearch].location != NSNotFound);
			}]];
		} else {
			filteredEntries = self.entries;
		}

		for(Entry *entry in filteredEntries) {
			entry.filteredEntries = EMPTY_ARRAY;
		}
	} else {
		[super filter:term];
	}
}

- (void) dealloc {
	[StorageURLProtocol unregisterProtocol];
}

@end
