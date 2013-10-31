#import <Foundation/Foundation.h>

@interface TestingSupport : NSObject

+ (void) waitForUICondition:(BOOL (^)(void))block message:(NSString *)message;
+ (void) waitForCondition:(BOOL (^)(void))block message:(NSString *)message timeout:(NSTimeInterval)timeout;

@end
