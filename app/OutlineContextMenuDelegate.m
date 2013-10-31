#import "OutlineContextMenuDelegate.h"

@implementation OutlineContextMenuDelegate

- (Entry *) outlineClickedItem {
	NSInteger clickedRow = [outline clickedRow];
	if (clickedRow < 0)
		return nil;
	return [outline itemAtRow:clickedRow];
}

- (void) menuNeedsUpdate:(NSMenu *)menu {
	Entry *node = [self outlineClickedItem];
	BOOL canReload = [node isKindOfClass:[Book class]] && ((Book *)node).state == BookStateActive;
	[[menu itemAtIndex:0] setHidden:!canReload];
}

- (IBAction) reloadBook:(id)sender {
	[((Book *)[self outlineClickedItem]) install:nil];
}

@end
