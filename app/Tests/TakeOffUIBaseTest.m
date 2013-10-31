#import "TakeOffUIBaseTest.h"
#import "FileUtils.h"
#import "MainWindowController.h"

@implementation TakeOffUIBaseTest

- (void) setUp {
	[[NSFileManager defaultManager] removeItemAtPath:[FileUtils applicationSupportPath] error:nil];

	[Fixtures clear];

	controller = [MainWindowController new];
	[self configureController];
	main_sync_exec(^{
		[NSBundle loadNibNamed:@"MainWindow" owner:controller];
		[controller.window makeKeyAndOrderFront:self];
	});
	window = controller.window;
	outline = controller.outlineView;
	browser = controller.webView;
}

- (void) tearDown {
	main_sync_exec(^{
		[controller close];
	});
	controller = nil;
	outline = nil;
	browser = nil;
	window = nil;
	[Fixtures clear];
}

- (void) configureController {

}

- (NSPathControl *) pathControl {
	NSPathControl *control = [window.contentView findControl:[NSPredicate predicateWithFormat:@"className=%@", @"NSPathControl"]];
	GHAssertNotNil(control, nil);
	return control;
}

- (NSString *) jumpBarText {
	NSMutableArray *texts = [NSMutableArray array];
	for(NSPathCell *cell in [self pathControl].pathComponentCells) {
		[texts addObject:cell.stringValue];
	}
	return [texts componentsJoinedByString:@"/"];
}

- (void) waitForSelectedEntry:(Entry *)entry {
	NSParameterAssert(entry);

	AssertWaitForUICondition(entry == [outline itemAtRow:outline.selectedRow]);
	AssertWaitForUICondition(![browser isLoading]);

	GHAssertFalse([browser isHidden], nil);
	GHAssertEqualStrings([entry.titlePath stringByReplacingOccurrencesOfString:@"Library/" withString:@""], [self jumpBarText], @"jump bar text");

	[UITestingSupport flush];
}

- (void) searchFor:(NSString *)searchTerm andExpectPath:(NSString *)titlePath {
	LogDebug(@"searchFor:\"%@\"", searchTerm);

	[outline deselectAll:self];

	main_sync_exec(^{
		[controller setSearchTerm:searchTerm];
	});

	if (titlePath) {
		Entry *entry = [controller.library entryForTitlePath:titlePath];
		[self waitForSelectedEntry:entry];
	} else {
		GHAssertEquals((int)0, (int)outline.numberOfRows, nil);
	}
}

- (void) loadEntry:(Entry *)entry {
	[controller.library waitUntilAllBooksLoaded];

	GHAssertNotNil(entry.absoluteURL, @"%@", entry);
	main_sync_exec(^{
		NSString *urlString = entry.absoluteURL.absoluteString;
		LogDebug(@"loadEntry:%@ %@", entry, urlString);

		for(Entry *e in entry.path) {
			[outline expandItem:e];
		}

		NSInteger row = [outline rowForItem:entry];
		NSAssert(row != -1, @"No row for %@", entry);
		[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	});

	[self waitForSelectedEntry:entry];
}

- (void) checkSearchFieldIsFirstResponder {
	NSView *firstResponder = (NSView *)controller.window.firstResponder;
	NSResponder *firstResponderPp = firstResponder.superview.superview;
	GHAssertEquals(controller.searchField, firstResponderPp, @"Search field %@ not the first responder: %@ %@", controller.searchField, firstResponder, firstResponderPp);
}

- (NSToolbarItem *) toolbarButtonWithLabel:(NSString *)label {
	return [[window.toolbar.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"label=%@", label]] objectAtIndex:0];
}

- (NSButton *) buttonWithTooltip:(NSString *)tooltip {
	NSButton *button = [window.contentView findControl:[NSPredicate predicateWithFormat:@"className=%@ and toolTip=%@", @"NSButton", tooltip]];
	GHAssertNotNil(button, nil);
	return button;
}

- (NSArray *) outlineTopLevelItems:(id)identifier {
	NSMutableArray *topLevelItems = [NSMutableArray new];
	main_sync_exec(^{
		for(int row = 0; row<[outline numberOfRows]; row++) {
			if ([outline levelForRow:row] == 0) {
				NSCell *cell = [outline preparedCellAtColumn:[outline columnWithIdentifier:identifier] row:row];
				[topLevelItems addObject:[cell stringValue]];
			}
		}
	});
	return topLevelItems;
}

- (NSButton *) prevButton {
	return [self buttonWithTooltip:@"Show the previous page"];
}

- (NSButton *) nextButton {
	return [self buttonWithTooltip:@"Show the next page"];
}

- (NSString *) browserButtons {
	return [NSString stringWithFormat:@"%@%@", [[self prevButton] isEnabled] ? @"<" : @"-", [[self nextButton] isEnabled] ? @">" : @"-"];
}

- (void) assertBrowserButtons:(NSString *)expected {
	AssertWaitForUICondition([[self browserButtons] isEqualTo:expected]);
}

@end
