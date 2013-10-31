#import <Foundation/Foundation.h>

@interface Binding : NSObject

- (id) initWithModel:(NSObject *)model modelKeyPath:(NSString *)modelKeyPath update:(dispatch_block_t)updateTargetBlock;

- (void) updateTarget;

@end
