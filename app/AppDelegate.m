#import "AppDelegate.h"
#import "MainWindowController.h"

@implementation AppDelegate {
    MainWindowController *mainWindowController;
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
	mainWindowController = [[MainWindowController alloc] init];
	[mainWindowController showWindow:self];
}

- (IBAction) sendFeedback:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:support-takeoff@ralfebert.de"]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
	return YES;
}

@end