#import "LoadDelegate.h"

@implementation BlockyWebView

- (void) onMainFrameFinishLoad:(void (^)(void))block {
	self.frameLoadDelegate = [[LoadDelegate alloc] initWithBlock:block];
}

@end

@implementation LoadDelegate

- (id)initWithBlock:(void (^)(void))block {
    self = [super init];
    if (self) {
        onLoad = [block copy];
    }
    return self;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (frame == sender.mainFrame) {
		onLoad();
	}
}

@end
