#import <Foundation/Foundation.h>

@interface FileStorage : NSObject {
	NSString *path;
}

- (id) initWithPath:(NSString *)p_path;
+ (id) storageWithPath:(NSString *)p_path;

@end
