#import <Foundation/Foundation.h>

#import "Binding.h"

@interface BindingContext : NSObject {

}

- (Binding *) bindModel:(NSObject *)model keyPath:(NSString *)modelKeyPath update:(dispatch_block_t)block;

- (void) unbind:(Binding *)binding;

- (void) unbindAll;

@end
