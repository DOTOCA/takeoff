#import <Foundation/Foundation.h>

@protocol ProgressHandler <NSObject>

@property (assign) NSString *message;

- (void) startWork:(double)work;
- (void) worked:(double)progress;

@end
