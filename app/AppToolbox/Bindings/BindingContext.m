#import "BindingContext.h"

@interface BindingContext ()

@property(nonatomic, strong) NSMutableArray *bindings;

@end

@implementation BindingContext

@synthesize bindings = _bindings;

- (id) init {
	self = [super init];
	if (self != nil) {
		self.bindings = [NSMutableArray array];
	}
	return self;
}

- (Binding *) bindModel:(NSObject *)model keyPath:(NSString *)modelKeyPath update:(dispatch_block_t)block {
	Binding *binding = [[Binding alloc] initWithModel:model modelKeyPath:modelKeyPath update:block];
	[self.bindings addObject:binding];
	LogDebug(@"Created %@", binding);
	return binding;
}

// internal method for Binding only
- (void) unbind:(Binding *)binding {
	NSUInteger i = [self.bindings indexOfObject:binding];
	if (i == NSNotFound) {
		NSLog(@"Error: Binding %@ was not bound, cannot unbind!", binding);
	} else {
		[self.bindings removeObjectAtIndex:i];
	}
}

- (void) unbindAll {
	self.bindings = [NSMutableArray array];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"BindingContext[%i bindings]", (int)[self.bindings count]];
}

- (void) dealloc {
	[self unbindAll];
}

@end
