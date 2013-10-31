#import <Foundation/Foundation.h>

#import "Entry.h"
#import "StorageContainer.h"
#import "ProgressHandler.h"

#define KEY_DOWNLOAD_URL   @"downloadUrl"
#define BOOK_INSTALL_ESTIMATE 100

typedef enum {
	BookStateNone,
	BookStateAvailable,
	BookStateActive,
	BookStateUninstallRequested,
	BookStateInstallRequested
} BookState;


@interface Book : Entry {
}

+ (id) loadFromStorage:(id<StorageContainer>)p_storage;
- (id) initWithBareStorage:(id<StorageContainer>)p_storage;
- (void) setIncluded:(BOOL)included;
- (void) handleLibraryChanges:(id<ProgressHandler>)progress;

@property (nonatomic, strong) id<StorageContainer> storage;
@property (nonatomic, strong) NSString *source;
@property (nonatomic, assign) BookState state;
@property (nonatomic, assign) BOOL included;

- (void) activate;
- (void) install:(id<ProgressHandler>)progress;
- (void) updateIndex;

@end
