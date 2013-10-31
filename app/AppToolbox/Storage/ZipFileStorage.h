#import <Foundation/Foundation.h>

#import "StorageContainer.h"
@class ZipFile;

@interface ZipFileStorage : NSObject<StorageContainer> {
	NSString *zipPath;
	ZipFile *zip;
	NSMutableDictionary *filesToWrite;
	BOOL create;
}

- (id) initWithPath:(NSString *)path create:(BOOL)create;
- (NSArray *) listFiles;

@property (readonly, nonatomic) NSString *zipPath;

@end
