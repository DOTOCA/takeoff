#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "ColorGradientView.h"
#import "LoadDelegate.h"
#import "Library.h"

@class BindingContext;

@interface MainWindowController : NSWindowController {
	IBOutlet NSSplitView *splitView;
	IBOutlet NSPathControl *pathControl;
	IBOutlet NSButton *backButton;
	IBOutlet NSButton *forwardButton;
	IBOutlet NSButton *libraryButton;
	IBOutlet NSView *logoView;
    NSString *libraryPath;
	BindingContext *bindingContext;
}

@property (strong, nonatomic) NSString *searchTerm;
@property (strong, nonatomic) IBOutlet NSOutlineView *outlineView;
@property (strong, nonatomic) IBOutlet BlockyWebView *webView;
@property (strong, nonatomic) IBOutlet NSTextField *searchField;
@property (strong, nonatomic) IBOutlet Library *library;
@property (strong, nonatomic) NSString *libraryPath;

- (void) setEntry:(Entry *)obj;
- (IBAction) toggleAdd:(id)sender;
- (void) prepare;

- (void) takeOffSearchService:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

- (void) clearSearch;
- (void) updateBooks;

@end
