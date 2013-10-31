#import <GHUnit/GHUnit.h>
#import <OCMock/OCMock.h>

#import "MainWindowController.h"
#import "LoadDelegate.h"
#import "WebView+Utils.h"
#import "LocalStubURLProtocol.h"
#import "NSOutlineView+Additions.h"
#import "BookProvider.h"
#import "FileUtils.h"
#import "TakeOffUIBaseTest.h"
#import "TestDraggingInfo.h"

@interface ZzTakeOffUITestsWithEmptyLibrary : TakeOffUIBaseTest {
}

@end

@implementation ZzTakeOffUITestsWithEmptyLibrary

#pragma mark - Test setup

- (void) setUp {
	[[NSFileManager defaultManager] removeItemAtPath:[FileUtils applicationSupportPath] error:nil];
	[super setUp];
}

#pragma mark - Test cases

- (void) testDragToWebViewNotAllowed {
	NSUInteger result = [browser.UIDelegate webView:browser dragDestinationActionMaskForDraggingInfo:[TestDraggingInfo draggingInfoForObject:[NSURL URLWithString:@"http://www.google.de/"]]];
		GHAssertEquals((int)WebDragDestinationActionNone, (int)result, @"webView drop disabled");
}

- (void) testOutlineRegisteredDraggedTypes {
	[outline.registeredDraggedTypes containsObject:NSPasteboardTypeString];
}

- (void) testOutlineBooksSortedAlphabetically {
	NSArray *items = [self outlineTopLevelItems:@"Title"];

	NSArray *sortedItems = [items sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	GHAssertEqualObjects(sortedItems, items, @"Outline sorted");
}

- (void) testDropURLToDownload {
	[LocalStubURLProtocol registerProtocol];

	// Drag http://www.example.org/test/test.html into the outline
	[outline.dataSource outlineView:outline acceptDrop:[TestDraggingInfo draggingInfoForObject:[Fixtures exampleUrl]] item:nil childIndex:0];

	// Wait for EXAMPLE PAGE to appear in outline
	AssertWaitForUICondition([[self outlineTopLevelItems:@"Title"] containsObject:@"EXAMPLE PAGE"]);

	[LocalStubURLProtocol blockRequests];

	// Search and select item
	[self searchFor:@"example" andExpectPath:@"Example page/Example page"];

	// Check if dependencies have been resolved correctly by checking colors that are assigned by external
	// css style sheets
	main_sync_exec(^{
		NSParameterAssert([browser.preferences isJavaScriptEnabled]);

		[browser loadjQuery];
		GHAssertEqualStrings(@"Example page", browser.mainFrameTitle, @"title");
		GHAssertEqualStrings(@"Example page", [browser stringByEvaluatingJavaScriptFromString:@"document.title"], @"check: javascript in browser");
		GHAssertEqualStrings(@"Example page", [browser stringByEvaluatingJavaScriptFromString:@"$('title').text()"], @"check: jquery");

		GHAssertEqualStrings(@"rgb(255, 255, 0)", [browser stringByEvaluatingJavaScriptFromString:@"$('body').css('backgroundColor')"], @"css style sheet style.css missing, relative path");

		GHAssertEqualStrings(@"rgb(255, 0, 0)", [browser stringByEvaluatingJavaScriptFromString:@"$('h1').css('color')"], @"css style sheet global.css missing, absolute path");

		// CSS file linked by an external, absolute http:// URL - The WebResourceLoadDelegate should catch this and redirect the
		// URL to a takeoff:// URL
		GHAssertEqualStrings(@"rgb(0, 255, 0)", [browser stringByEvaluatingJavaScriptFromString:@"$('#nipper').css('color')"], @"css style sheet nipper.css missing, external http url");

	});
}

- (void) toggleLibraryButtonFrom:(NSCellStateValue)value {
	NSToolbarItem *library = [self toolbarButtonWithLabel:@"Library"];
	NSButton *button = (NSButton *)library.view;
	GHAssertNotNil(button, nil);

	GHAssertEquals((int)value, (int)button.state, nil);
	[button click];
	GHAssertEquals((int)(value == NSOnState ? NSOffState : NSOnState), (int)button.state, nil);
}

- (void) testAddButtonTogglesLibrary {
	main_sync_exec(^{
		controller.searchTerm = @"len";
	});

	GHAssertEqualObjects([NSArray arrayWithObject:@"Title"], outline.visibleColumnNames, nil);

	[self toggleLibraryButtonFrom:NSOffState];

	NSArray *expected = [NSArray arrayWithObjects:@"Included", @"Title", nil];
	GHAssertEqualObjects(expected, outline.visibleColumnNames, nil);
	[TestHelper assertBlank:controller.searchTerm];
	GHAssertEquals(-1, (int)(outline.selectedRow), nil);

	main_sync_exec(^{
		controller.searchTerm = @"css";
	});

	GHAssertEquals(1, (int)outline.numberOfRows, nil);

	[self toggleLibraryButtonFrom:NSOnState];

	[TestHelper assertBlank:controller.searchTerm];
}

- (NSUInteger) rowIndexForOutlineText:(NSString *)title {
	for(int row = 0; row<[outline numberOfRows]; row++) {
		NSCell *cell = [outline preparedCellAtColumn:[outline columnWithIdentifier:@"Title"] row:row];
		if([title isEqualToString:cell.stringValue]) {
			return row;
		}
	}

	return NSNotFound;
}

- (void) toggleOutlineItem:(NSString *)title from:(NSCellStateValue)state {
	int row = (int)[self rowIndexForOutlineText:title];
	GHAssertTrue(row >= 0, @"'%@' not found in outline", title);

	NSButtonCell *cell = (NSButtonCell *)[outline preparedCellAtColumn:[outline columnWithIdentifier:@"Included"] row:row];
	NSLog(@"%@", cell);
	GHAssertEquals((int)state, (int)cell.state, @"state before toggle not as expected");

	NSRect frame = [outline frameOfCellAtColumn:[outline columnWithIdentifier:@"Included"] row:row];
	NSPoint point = NSMakePoint(NSMidX(frame), NSMidY(frame));
	[outline clickAt:point];

	cell = (NSButtonCell *)[outline preparedCellAtColumn:[outline columnWithIdentifier:@"Included"] row:row];

	GHAssertEquals((int)(state == NSOnState ? NSOffState : NSOnState), (int)cell.state, @"state after toggle not as expected");
}

- (void) testDeleteBook {
	Book *book = [Book new];
	book.title = @"crap";
	[controller.library addBook:book];
	[book activate];

	[self toggleLibraryButtonFrom:NSOffState];

	[self toggleOutlineItem:@"CRAP" from:NSOnState];

	[self toggleLibraryButtonFrom:NSOnState];

	GHAssertTrue([self rowIndexForOutlineText:@"CRAP"] == NSNotFound, @"book still there");
}

- (void) testAddBook {
	Book *book = [Book new];
	book.title = @"New Book";

	id provider = [OCMockObject mockForProtocol:@protocol(BookProvider)];
	[[[provider expect] andReturn:[NSArray arrayWithObject:book]] availableBooks];

	[controller.library.bookProvider addObject:provider];

	[self toggleLibraryButtonFrom:NSOffState];

	[self toggleOutlineItem:@"NEW BOOK" from:NSOffState];

	[self toggleLibraryButtonFrom:NSOnState];

	GHAssertTrue([self rowIndexForOutlineText:@"NEW BOOK"] != NSNotFound, nil);
}

- (void) todotestHistoryMenu {
	GHFail(@"Menü History -> Back/Forward mit Cmd+Cursortasten Hotkeys, menu:History/Back present and working");
}

- (void) todotestIntegrationDialog {
	GHFail(@"menu:TakeOff/Integration... present");
}

@end
