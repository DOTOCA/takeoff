#import "FileUtils.h"
#import "MainWindowController.h"
#import "UITestingSupport.h"

@interface TakeOffUIBaseTest : GHAsyncTestCase {
	MainWindowController *controller;
	NSOutlineView *outline;
	BlockyWebView *browser;
	NSWindow *window;
}

- (NSString *) jumpBarText;
- (void) waitForSelectedEntry:(Entry *)entry;
- (void) searchFor:(NSString *)searchTerm andExpectPath:(NSString *)titlePath;
- (void) configureController;
- (void) loadEntry:(Entry *)entry;
- (void) assertBrowserButtons:(NSString *)expected;
- (NSButton *) prevButton;
- (NSButton *) nextButton;
- (NSArray *) outlineTopLevelItems:(id)identifier;
- (void) checkSearchFieldIsFirstResponder;
- (NSToolbarItem *) toolbarButtonWithLabel:(NSString *)label;

@end
