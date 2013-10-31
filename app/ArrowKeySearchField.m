#import "ArrowKeySearchField.h"
#import "NSOutlineView+Additions.h"

@implementation ArrowKeySearchField

- (BOOL) performKeyEquivalent:(NSEvent *)event {
	NSString *str = [event charactersIgnoringModifiers];
	unichar keyChar = [str characterAtIndex:0];
	BOOL empty = [[self stringValue] length]==0;

	if (keyChar == NSDownArrowFunctionKey) {
		[view selectNext];
		return YES;
	} else if (keyChar == NSUpArrowFunctionKey) {
		[view selectPrevious];
		return YES;
	} else if (empty && keyChar == NSRightArrowFunctionKey) {
		[view expandItem:[view itemAtRow:[view selectedRow]]];
		return YES;
	} else if (empty && keyChar == NSLeftArrowFunctionKey) {
		[view collapseItem:[view itemAtRow:[view selectedRow]]];
		return YES;
	} else if (empty && keyChar == 27) {
		[view collapseItem:nil collapseChildren:YES];
		return YES;
	} else {
		return [super performKeyEquivalent:event];
	}
}

@end
