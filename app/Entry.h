#import <Cocoa/Cocoa.h>

@class Book;

@interface Entry : NSObject {
	NSURL *absoluteURL;
@public
	NSArray *filteredEntries;
}

typedef NSString* (^EntryToStringMapping)(Entry *entry);

@property (atomic, weak) Entry *parent;
@property (atomic, strong) NSArray *entries;

@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;
@property (nonatomic) BOOL match;
@property (nonatomic) float ranking;

@property (nonatomic, strong) NSArray *filteredEntries;

@property (nonatomic, readonly) Book *book;
@property (nonatomic, readonly) NSArray *path;
@property (nonatomic, readonly) NSURL *absoluteURL;
@property (nonatomic, readonly) NSString *titlePath;
@property (nonatomic, readonly) NSString *debugString;
@property (nonatomic, readonly) int level;
@property (nonatomic, readonly) NSUInteger titlePathLength;

- (id) initWithParent:(Entry *)aParent;
- (id) initWithDictionary:(NSDictionary *)aDictionary parent:(Entry *)aParent;
+ (Entry *) parseDebugString:(NSString *)string;
- (NSString *) debugString:(EntryToStringMapping)mapper;
- (NSString *) debugRankingString;

- (void) sortEntriesByTitle;

+ (Entry *) entryWithDictionary:(NSDictionary *)aDictionary;
+ (Entry *) entryWithParent:(Entry *)aParent;
+ (Entry *) entryWithParent:(Entry *)parent title:(NSString *)title;

- (NSMutableDictionary *) dictionary;

- (Entry *) entryForTitlePath:(NSString *)path;
- (Entry*) entryForAbsoluteURL:(NSURL *)findURL;
- (void) filter:(NSString *)newFilterTerm;

- (Entry*) findDepthFirst:(NSPredicate *)predicate filtered:(BOOL)filtered;

@end

extern NSArray *EMPTY_ARRAY;

