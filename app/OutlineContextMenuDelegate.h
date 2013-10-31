#import "Library.h"

@interface OutlineContextMenuDelegate : NSObject<NSMenuDelegate> {
	IBOutlet NSOutlineView *outline;
	IBOutlet Library *books;
}

- (IBAction)reloadBook:(id)sender;

@end
