#import "ProgressWindow.h"

#import "MainThread.h"

@implementation ProgressWindow

@synthesize indicator = _indicator, label = _label, window = _window;

- (id)init {
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"ProgressWindow" owner:self];

		self.indicator.maxValue = 0;
		[self.indicator setIndeterminate:YES];
		[self.indicator startAnimation:self];

		progressValueSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
		dispatch_source_set_event_handler(progressValueSource, ^{
			[self.indicator incrementBy:dispatch_source_get_data(progressValueSource)];
		});
		dispatch_resume(progressValueSource);

	}
	return self;
}

- (void) startWork:(double)work {
	main_sync_exec(^{
		[self.indicator setIndeterminate:NO];
		self.indicator.maxValue += work*1000;
	});
}

- (void) worked:(double)progress {
	dispatch_source_merge_data(progressValueSource, progress*1000);
}

- (NSString *) message {
	return self.label.stringValue;
}

- (void) setMessage:(NSString *)message {
	self.label.stringValue = message;
}

- (void) sheetForWindow:(NSWindow *)parentWindow {
	[[NSApplication sharedApplication] beginSheet: self.window
								   modalForWindow: parentWindow
									modalDelegate: nil
								   didEndSelector: nil
									  contextInfo: nil];
}

- (void) close {
	if (self.window) {
		[[NSApplication sharedApplication] endSheet:self.window];
		[self.window orderOut:self];
		self.label = nil;
		self.indicator = nil;
		self.window = nil;
		dispatch_release(progressValueSource);
	}
}

+ (ProgressWindow *) blockWindow:(NSWindow *)window message:(NSString *)message {
	ProgressWindow *progress = [ProgressWindow new];
	progress.message = message;
	[progress sheetForWindow:window];
	return progress;
}

- (void) dealloc {
	[self close];
}

@end
