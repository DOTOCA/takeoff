#import "Binding.h"

@interface Binding ()

@property(nonatomic, weak) NSObject *model;
@property(nonatomic, copy) NSString *modelKeyPath;
@property(nonatomic, copy) dispatch_block_t updateTargetBlock;

@end


@implementation Binding

@synthesize model = _model, modelKeyPath = _modelKeyPath, updateTargetBlock = _updateTargetBlock;

- (id) initWithModel:(NSObject *)model modelKeyPath:(NSString *)modelKeyPath update:(dispatch_block_t)updateTargetBlock {
	self = [super init];
	if (self != nil) {
		self.model = model;
		self.modelKeyPath = modelKeyPath;
		self.updateTargetBlock = updateTargetBlock;
		[self updateTarget];
		[self.model addObserver:self forKeyPath:self.modelKeyPath options:NSKeyValueObservingOptionNew context:NULL];
	}
	return self;
}

- (void) updateTarget {
	self.updateTargetBlock();
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	LogTrace(@"  observed change: %@.%@ -> %@", [object class], keyPath, [change valueForKey:NSKeyValueChangeNewKey]);
	if (object == self.model) {
		[self updateTarget];
	}
}

- (NSString *) description {
	return [NSString stringWithFormat:@"Binding[%@.%@ ↔ %@]", [self.model class], self.modelKeyPath, self.updateTargetBlock];
}

- (void) dealloc {
	LogTrace(@"✝ %@", self);
	[self.model removeObserver:self forKeyPath:self.modelKeyPath];
}

@end
