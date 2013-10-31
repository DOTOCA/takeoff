#import "MainWindowController.h"

#import "ImageAndTextCell.h"
#import "NSOutlineView+Additions.h"
#import "DocsOutlineDelegate.h"
#import "URLMapping.h"
#import "RedirectResourceLoadDelegate.h"
#import "DocSet.h"
#import "MainThread.h"
#import <Carbon/Carbon.h>
#import "WebView+Utils.h"
#import "DocSetBookProvider.h"
#import "ProgressWindow.h"
#import "OnlineBookProvider.h"
#import "FileUtils.h"
#import "BindingContext.h"

#define kMinOutlineViewSplit	250.0f

@interface MainWindowController (Private)
- (void) outlineSelectionDidChange;

- (void) setObserveOutlineSelection:(BOOL)enabled;
@end

@implementation MainWindowController {
    RedirectResourceLoadDelegate *resourceLoadDelegate;
}

@synthesize searchTerm, outlineView, webView, library, searchField, libraryPath;

- (id)init {
    self = [super initWithWindowNibName:@"MainWindow"];
    if (self) {
    }
    return self;
}

- (NSString *) searchTerm {
	return searchTerm;
}

- (void) setSearchTerm:(NSString *)value {
	// TODO: Inefficient workaround - refiltering when books are added is kind of complicated - just
	// waiting before filtering is the easy workaround for v1.1
	[library waitUntilAllBooksLoaded];

	// Keep the old selection
	NSInteger oldRow = outlineView.selectedRow;
	id oldItem = [outlineView itemAtRow:oldRow];
	LogTrace(@"oldItem: %@ in row %i", oldItem, (int) oldRow);

	// Set property
	searchTerm = value;

	// Update datasource accordingly (changes items)
	[library filter:value];
	LogTrace(@"((%@)) %@", value, library.debugRankingString);

	// Reloading the data clears the selection. We will restore it. But we don't want to send
	// out two events because of this, so we disable the observer for reloading.
	[self setObserveOutlineSelection:NO];

	// Refresh visible rows (clears selection)
	LogTrace(@"Reloading outline data");
	[outlineView reloadData];

	// Check if the selection still matches the search term, and if not, dismiss it
	if (![outlineView fit:oldItem]) {
		oldItem = nil;
	}

	// Expand the full tree for easy keyboard navigation after two letters
	// TODO: expand it immediately without the 2-letter-check, but make sure, this is fast enough for large result sets
	// (prob. gets number of items for scrollbar height)
	//TODO: trim whitespace
	if ([value length] > 0)
		[outlineView expandAll];

	// Restore the old selection if we had one and if it is still visible without sending out an event
	if (oldItem) {
		NSInteger row = [outlineView rowForItem:oldItem];
		if (row >= 0) {
			LogTrace(@"Restored selection to %@ in row %i", oldItem, (int) row);
			[outlineView selectRow:row];
			[self setObserveOutlineSelection:YES];
			return;
		}
	}

	// If there was no old selection or the old seleciton is not visible anymore:
	// Select the first item
	[outlineView selectFirst];

	// If the first item was selected or there is no selection now, in any case, no selection
	// event was sent out, so we do that
	[self outlineSelectionDidChange];

	// Re-activate notifications
	[self setObserveOutlineSelection:YES];
}

- (void) webView:(WebView *)view decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		 request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
	NSString *scheme = [[request URL] scheme];
	if ([@"source" isEqualToString:scheme]) {
		NSInteger selectedRow = [outlineView selectedRow];
		if (selectedRow >= 0) {
			Entry *entry = [outlineView itemAtRow:selectedRow];
			Book *node = entry.book;
			NSString *source = node.source;
			if (source) {
				NSString *src = [[request URL] resourceSpecifier];
				src = [src stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

				NSURL *sourceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", source, src]];
				LogDebug(@"%@", sourceUrl);
				[[NSWorkspace sharedWorkspace] openURL:sourceUrl];
			}
		}
	} else if ([scheme hasPrefix:@"http"]) {
		if (frame == view.mainFrame) {
			LogDebug(@"Opening URL externally: %@", request.URL);
			[[NSWorkspace sharedWorkspace] openURL:request.URL];
		}
	} else {
		[listener use];
	}
}

- (void) takeOffSearchService:(NSPasteboard *)pboard
					 userData:(NSString *)userData error:(NSString **)error {
	NSString *pboardString = [pboard stringForType:NSPasteboardTypeString];
	LogDebug(@"takeOffSearchService: %@", pboardString);
	if (pboardString) {
		[self performSelectorOnMainThread:@selector(setSearchTerm:) withObject:pboardString waitUntilDone:NO];
	}
}

- (void) setLibrary:(Library *)newLibrary {
	if (library) {
		NSLog(@"remove");
		library.onUpdate = nil;
	}

	library = newLibrary;
	LogDebug(@"setLibrary:%@", newLibrary);

	library.onUpdate = ^{
		main_async_exec(^{
			[self updateBooks];
		});
	};

	if (!self.libraryPath) {
		self.libraryPath = [FileUtils applicationSupportPath];
	}

	[library scanFolder:self.libraryPath];
	[library.bookProvider addObject:[DocSetBookProvider new]];
	[library.bookProvider addObject:[OnlineBookProvider new]];
}

- (void) clearSearch {
	[searchField setStringValue:@""];
	searchTerm = @"";
	[library filter:nil];
	[outlineView reloadData];
}

- (void) updateBooks {
	[[[outlineView tableColumns] objectAtIndex:0] setHidden:library.state == LibraryStateBrowser];
	[searchField setHidden:library.entries.count == 0 || library.state == LibraryStateAdd];
	[outlineView reloadData];
}

- (void) prepare {
	NSButtonCell *includedCell = [NSButtonCell new];
	NSTableColumn *includedColumn = [[outlineView tableColumns] objectAtIndex:0];
	[includedColumn setDataCell:includedCell];

	[backButton bind:@"enabled" toObject:webView withKeyPath:@"canGoBack" options:nil];
	[forwardButton bind:@"enabled" toObject:webView withKeyPath:@"canGoForward" options:nil];

	[[[outlineView tableColumns] objectAtIndex:1] setDataCell:[ImageAndTextCell new]];

	[outlineView setRefusesFirstResponder:YES];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusSearchField)
												 name:NSWindowDidBecomeKeyNotification object:self.window];

	[self setObserveOutlineSelection:YES];

	[self.window makeFirstResponder:searchField];

	[outlineView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, nil]];

	[NSApp setServicesProvider:self];

	[self updateBooks];
}

- (void) configureBrowser {
	[webView setPreferencesIdentifier:@"TakeOff"];
	[[webView preferences] setDefaultFontSize:16];
}

- (void) focusSearchField {
	[self.window makeFirstResponder:searchField];
}

- (void) awakeFromNib {
	bindingContext = [BindingContext new];
	[bindingContext bindModel:webView keyPath:@"hidden" update:^{
		logoView.hidden = !self.webView.isHidden;
	}];

	[self prepare];
	[self configureBrowser];
	[self focusSearchField];
}

#pragma mark - UI actions

- (IBAction) toggleAdd:(id)sender {
	// the underlying library changes while installation/uninstallation is performed
	// to not run in concurrency issues (index ... beyond bounds [0 .. 6]), the outline
	// is detached from the model
	id dataSource = outlineView.dataSource;
	outlineView.dataSource = nil;

	[self setObserveOutlineSelection:NO];

	[outlineView deselectAll:self];
	[self clearSearch];

	ProgressWindow *window = [ProgressWindow blockWindow:[NSApplication sharedApplication].mainWindow message:((library.state == LibraryStateAdd) ? @"Installing and indexing books..." : @"Loading available books...")];

	libraryButton.image = [NSImage imageNamed:(library.state == LibraryStateAdd) ? @"add" : @"add_on"];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		LogDebug(@"toggleAdd async");
		if (library.state == LibraryStateAdd) {
			[library handleLibraryChanges:window];
		}
		main_sync_exec(^{
			[library toggleAdd];
			[window close];
			outlineView.dataSource = dataSource;
			[self updateBooks];
			[self setObserveOutlineSelection:YES];
		});
	});
}

#pragma mark - Handle Outline Selection

- (void) setObserveOutlineSelection:(BOOL)enabled {
	LogTrace(@"setObserveOutlineSelection: %i", enabled);
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:outlineView];

	if (enabled) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(outlineSelectionDidChange)
													 name:NSOutlineViewSelectionDidChangeNotification
												   object:outlineView];
	}
}

- (void) outlineSelectionDidChange {
	LogTrace(@"outlineSelectionDidChange");
	NSInteger selectedRow = [outlineView selectedRow];
	[outlineView scrollRowToVisible:selectedRow];
	Entry *selectedObject = [outlineView itemAtRow:selectedRow];
	[self setEntry:selectedObject];
}

- (void) setJumpBarEntry:(Entry *)entry {
	if (!entry) {
		[pathControl setStringValue:@"/"];
		return;
	}

	NSMutableArray *titlePath = [NSMutableArray array];
	NSMutableArray *pathItems = [NSMutableArray array];

	Entry *node = entry;

	do {
		[titlePath insertObject:[node.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] atIndex:0];
		[pathItems insertObject:node atIndex:0];
	}
	while ((node = [outlineView parentForItem:node]) != nil && node != nil);

	NSString *titlePathString = [NSString stringWithFormat:@"/%@", [titlePath componentsJoinedByString:@"/"]];

	[pathControl setStringValue:titlePathString];

	DocsOutlineDelegate *delegate = outlineView.delegate;
	NSPathComponentCell *cell;
	int i = 0;
	for (Entry *node in pathItems) {
		cell = [pathControl.pathComponentCells objectAtIndex:i++];
		cell.image = [delegate imageForItem:node];
	}
}

- (void) setEntry:(Entry *)entry {
	LogTrace(@"setEntry:%@", entry);
	NSURL *entryURL = entry.absoluteURL;
	NSURL *currentURL = webView.URL;

	if (!entryURL) {
		[self setJumpBarEntry:nil];
		self.webView.hidden = YES;
	} else {
		if ([entryURL isEqual:currentURL]) {
			self.webView.hidden = NO;
			[self setJumpBarEntry:entry];
			return;
		}

		LogTrace(@"==> %@ (was: %@)", entryURL, currentURL);

		// redirect all requests accordingly
		if ([entryURL.scheme hasPrefix:@"takeoff"]) {
            // webview doesn't retain the delegate, so we store it
			webView.resourceLoadDelegate = resourceLoadDelegate = [RedirectResourceLoadDelegate delegateWithURLMapping:[URLMapping urlMapperForStorage:entry.book.storage]];
			[webView.preferences setJavaScriptEnabled:YES];
		} else {
			// DocSet pages try very hard to get into a frame and break the URL scheme using JavaScript
			[webView.preferences setJavaScriptEnabled:NO];
			// Setting this to nil is important because otherwise the takeoff- redirection from the
			// page before will still be active
			webView.resourceLoadDelegate = resourceLoadDelegate = nil;
		}

		// load page
		[webView.mainFrame loadRequest:[NSURLRequest requestWithURL:entryURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3]];
	}
}

- (void) updateOutlineSelectionWithBrowserLocation {
	// webView workaround to update the back/fw buttons in all cases
	[webView willChangeValueForKey:@"canGoBack"];
	[webView didChangeValueForKey:@"canGoBack"];
	[webView willChangeValueForKey:@"canGoForward"];
	[webView didChangeValueForKey:@"canGoForward"];

	// make the browser visible
	self.webView.hidden = NO;

	Entry *outlineEntry = [outlineView itemAtRow:[outlineView selectedRow]];
	NSURL *outlineURL = outlineEntry.absoluteURL;
	NSURL *webViewURL = webView.URL;
	if (![webViewURL isEqualTo:outlineURL]) {
		outlineEntry = [library entryForAbsoluteURL:webViewURL];
		if (outlineEntry) {
			LogDebug(@"Clearing search for: %@ => %@", webViewURL, outlineEntry);
			[self clearSearch];
			for (Entry *e in outlineEntry.path) {
				[outlineView expandItem:e];
			}

			[self setObserveOutlineSelection:NO];
			[outlineView selectRow:[outlineView rowForItem:outlineEntry]];
			[self setObserveOutlineSelection:YES];
		} else {
			NSLog(@"No outline entry found for %@", webViewURL);
		}
	}

	[self setJumpBarEntry:outlineEntry];
}

#pragma - WebView related

- (void) setWebView:(BlockyWebView *)view {
	webView = view;
	webView.frameLoadDelegate = self;
	webView.policyDelegate = self;
	webView.UIDelegate = self;
}

- (void) webView:(WebView *)w didFinishLoadForFrame:(WebFrame *)frame {
	[self updateOutlineSelectionWithBrowserLocation];
}

- (void) webView:(WebView *)w didChangeLocationWithinPageForFrame:(WebFrame *)frame {
	[self updateOutlineSelectionWithBrowserLocation];
}

- (NSUInteger) webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo {
	return WebDragDestinationActionNone;
}

#pragma mark - Split View Delegate

// -------------------------------------------------------------------------------
//	splitView:constrainMinCoordinate:
//
//	What you really have to do to set the minimum size of both subviews to kMinOutlineViewSplit points.
// -------------------------------------------------------------------------------
- (CGFloat) splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(int)index {
	return proposedCoordinate + kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:constrainMaxCoordinate:
// -------------------------------------------------------------------------------
- (CGFloat) splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(int)index {
	return proposedCoordinate - kMinOutlineViewSplit;
}

@end
