#import <Foundation/Foundation.h>

#import "ZipFileStorage.h"
#import "Book.h"

@interface Fixtures : NSObject

+ (NSString*) takeoffZipPath;
+ (id<StorageContainer>) emptyStorage;
+ (id<StorageContainer>) storageMock;
+ (ZipFileStorage *) testZip:(NSString *)name;
+ (Book *) testBook;
+ (Book *) testBook:(NSString *)name;
+ (NSURL *)exampleUrl;
+ (NSString *)archivePathForExampleUrl;
+ (void) clear;
+ (NSString *) tmpZipPath;
+ (ZipFileStorage *) tmpZipCreate:(BOOL)create;
+ (NSData *) exampleData;

@end
