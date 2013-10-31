#import <Foundation/Foundation.h>

@protocol StorageContainer <NSObject>

- (NSData *) dataForPath:(NSString *)path;
- (void) setData:(NSData *)data forPath:(NSString *)path;
- (void) flush;
- (NSURL *) URLForPath:(NSString *)path;
- (void) remove;

@end
