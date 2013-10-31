#import "Book.h"

#import "ZipFileStorage.h"
#import "Library.h"

#define KEY_SOURCE         @"source"

NSString * const BookStateStrings[] = {
	@"None",
	@"Available",
	@"Active",
	@"UninstallRequested",
	@"InstallRequested"
};

@implementation Book

@synthesize source, storage, state;

+ (id) loadFromStorage:(id<StorageContainer>)p_storage {
	NSParameterAssert(p_storage);
	NSData *jsonData = [p_storage dataForPath:@"index.json"];
	NSParameterAssert(jsonData);
	NSError *error = nil;
	NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
	NSAssert(dictionary, @"Outline could not be deserialized: %@", error);

	NSString *clName = [dictionary objectForKey:@"class"];
	if (!clName)
		clName = [Book className];

	Class cl = NSClassFromString(clName);

	NSAssert(cl, @"Class %@", clName);
	NSParameterAssert([cl isSubclassOfClass:[Book class]]);

	Book *book = [[cl alloc] initWithDictionary:dictionary parent:nil];
	book.storage = p_storage;
	return book;
}

- (id) initWithBareStorage:(id<StorageContainer>)p_storage {
	NSParameterAssert(p_storage);
	self = [super init];
    if (self) {
		self.storage = p_storage;
	}
    return self;
}

- (id) initWithDictionary:(NSDictionary *)aDictionary parent:(Entry *)aParent {
    self = [super initWithDictionary:aDictionary parent:aParent];
    if (self) {
		self.source = [aDictionary objectForKey:KEY_SOURCE];
	}
	return self;
}

- (NSMutableDictionary *) dictionary {
	NSMutableDictionary *dict = [super dictionary];
	[dict setValue:[self className] forKey:@"class"];
	return dict;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"<Book title=%@ storage=%@>", self.title, self.storage];
}

- (NSUInteger) hash {
	return storage.hash;
}

// TODO: comparing the hashes is a hack - storage should be compared with the current design - but TakeoffFileDownload doesn't have storage
- (BOOL) isEqual:(id)anObject {
	return [anObject isKindOfClass:[Book class]] && ((Book *)anObject).hash == self.hash;
}

- (void) updateIndex {
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.dictionary options:0 error:&error];
	NSAssert(jsonData != nil, @"index.json could not be serialized: %@", error);

	[storage setData:jsonData forPath:@"index.json"];
	[storage flush];
}

- (Book *) book {
	return self;
}

- (void) setState:(BookState)newState {
	BookState oldState = state;
	if (oldState != newState) {
		state = newState;
		NSLog(@"Book.state: %@ -> %@", BookStateStrings[oldState], BookStateStrings[newState]);
	}
}

// trigger
- (void) setParent:(Entry *)newParent {
	// None -> Active
	if (state == BookStateNone) {
		NSParameterAssert([newParent isKindOfClass:[Library class]]);
		[super setParent:newParent];
		self.state = BookStateAvailable;
	// * -> None
	} else if (!newParent) {
		[super setParent:nil];
		self.state = BookStateNone;
	} else {
		[NSException raise:@"StateTransitionNotAllowed" format:@"No transition for event setParent: in state %@",BookStateStrings[state]];
	}
}

// trigger
- (void) activate {
	if (state == BookStateAvailable) {
		self.state = BookStateActive;
	} else {
		[NSException raise:@"StateTransitionNotAllowed" format:@"No transition for event activate in state %@",BookStateStrings[state]];
	}
}

// trigger
- (void) install:(id<ProgressHandler>)progress {
	if (state == BookStateNone || state == BookStateInstallRequested) {
		self.state = BookStateActive;
	}
	else {
		[NSException raise:@"StateTransitionNotAllowed" format:@"No transition for event install in state %@",BookStateStrings[state]];
	}
}

- (BOOL) included {
	return (state == BookStateActive || state == BookStateInstallRequested);
}

// trigger
- (void) setIncluded:(BOOL)included {
	// Active -> UninstallRequested
	if (state == BookStateActive) {
		if (included) return;
		self.state = BookStateUninstallRequested;
	}
	// UninstallRequested -> Active
	else if (state == BookStateUninstallRequested) {
		if (!included) return;
		self.state = BookStateActive;
	}
	// Available -> InstallRequested
	else if (state == BookStateAvailable) {
		if (!included) return;
		self.state = BookStateInstallRequested;
	}
	// InstallRequested -> Available
	else if (state == BookStateInstallRequested) {
		if (included) return;
		self.state = BookStateAvailable;
	}
	else
		[NSException raise:@"StateTransitionNotAllowed" format:@"No transition for event setIncluded:%i in state %@", included, BookStateStrings[state]];
}

// trigger
- (void) handleLibraryChanges:(id<ProgressHandler>)progress {
	LogDebug(@"handleLibraryChanges: %@", self);
	// UninstallRequested -> None
	if (state == BookStateUninstallRequested) {
		[self setParent:nil];
		[storage remove];
	}
	// BookStateInstallRequested -> Active
	if (state == BookStateInstallRequested) {
		[self install:progress];
	}
	// Available -> None
	if (state == BookStateAvailable) {
		self.parent = nil;
	}
	// Do nothing in other states
}


@end
