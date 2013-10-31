#import <Cocoa/Cocoa.h>

#import "ProgressHandler.h"

@interface ProgressWindow : NSObject<ProgressHandler> {
	NSProgressIndicator *__strong _indicator;
	NSTextField *__strong _label;
	NSWindow *_window;
	dispatch_source_t progressValueSource;
}

@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSTextField *label;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *indicator;

+ (ProgressWindow *) blockWindow:(NSWindow *)window message:(NSString *)message;
- (void) close;

@end
