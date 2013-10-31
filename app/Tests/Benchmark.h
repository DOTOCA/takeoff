#import <Foundation/Foundation.h>

@interface Benchmark : NSObject

+ (double) run:(int(^)(int run))block times:(int)count;

@end
