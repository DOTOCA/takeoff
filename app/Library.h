#import "Book.h"

#import "BookProvider.h"

typedef enum {
	LibraryStateBrowser,
	LibraryStateAdd
} LibraryState;

@interface Library : Entry {
	NSOperationQueue *queue;
	NSString *filterTerm;
}

@property (nonatomic, assign) LibraryState state;
@property (nonatomic, readonly) NSMutableArray *bookProvider;
@property (copy) dispatch_block_t onUpdate;

+ (NSString *) archivePathByUrl:(NSURL *)url;
- (void) waitUntilAllBooksLoaded;
- (void) downloadUrl:(NSURL *)url;
- (void) scanFolder:(NSString *)path;
- (Book *) loadBook:(NSString *)path;
- (Book *) addBook:(Book *)book;
- (void) toggleAdd;
- (void) handleLibraryChanges:(id<ProgressHandler>)progress;

@end
