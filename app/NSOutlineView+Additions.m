#import "NSOutlineView+Additions.h"

#import "DocsOutlineDataSource.h"
#import "Foundation+Additions.h"

@implementation NSOutlineView (Additions)

- (void) expandAll {
	[self expandItem:nil expandChildren:YES];
}

- (void) selectRow:(NSInteger)row {
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[self scrollRowToVisible:row];
}

- (BOOL) fit:(id)item {
	//TODO: check if we can do without DocsOutlineDataSource
	return [self.delegate outlineView:self shouldSelectItem:item] && [((DocsOutlineDataSource*)self.dataSource) outlineView:self recommendsSelectItem:item];
}

- (void) selectFirst {
	for(int i = 0; i < [self numberOfRows]; i++) {
		id item = [self itemAtRow:i];
		if ([self fit:item]) {
			LogTrace(@"Selected first fitting item %@ in row %i", item, i);
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
			[self scrollRowToVisible:0];
			break;
		}
	}
}

- (void) selectNext {
	for(NSInteger i = [self selectedRow] + 1; i < [self numberOfRows]; i++) {
		id item = [self itemAtRow:i];
		if ([self fit:item]) {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
			[self scrollRowToVisible:i];
			break;
		}
	}
}

- (void) selectPrevious {
	for(NSInteger i = [self selectedRow] - 1; i >=0; i--) {
		id item = [self itemAtRow:i];
		if ([self fit:item]) {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];

			// Scroll up to the 2nd level node so that the context of the selection is visible
			// 2nd level is specific for TakeOff where 1st level are the books
			// Scroll up to the book if it is max 5 nodes away (otherwise the jump is too big and
			// confusing)
			int steps = 5;
			while(steps>=0 && i>0 && [self levelForRow:i]>1) { i--; steps--; }
			steps += 5;
			while(steps>=0 && i>0 && [self levelForRow:i]>0) { i--; steps--; }

			[self scrollRowToVisible:i];
			break;
		}
	}
}

- (NSString *) columnValueString:(NSString *)identifier {
	NSInteger col = [self columnWithIdentifier:identifier];
	NSAssert(col >= 0, @"Column %@ not found", identifier);

	NSMutableString *result = [NSMutableString string];
	for(NSInteger i = 0; i < self.numberOfRows; i++) {
		if (i > 0)
			[result appendString:@"\n"];
		[result appendString:[@"\t" times:(int)[self levelForRow:i]]];
		if (i == self.selectedRow)
			[result appendString:@"[["];
		[result appendString:[self preparedCellAtColumn:col row:i].title];
		if (i == self.selectedRow)
			[result appendString:@"]]"];
	}
	return [NSString stringWithString:result];
}

@end
