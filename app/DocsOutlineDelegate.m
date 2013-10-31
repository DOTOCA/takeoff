#import "DocsOutlineDelegate.h"

#import "Entry.h"
#import "Book.h"

@implementation DocsOutlineDelegate

- (NSImage *) imageForItem:(Entry *)node {
	NSString *icon = node.icon;
	return icon ? [NSImage imageNamed:[NSString stringWithFormat:@"icon_%@.png", icon]] : nil;
}

- (void) outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(Entry *)entry {
	if ([cell isKindOfClass:[NSButtonCell class]]) {
		NSButtonCell *buttonCell = cell;
		buttonCell.buttonType = NSSwitchButton;
		buttonCell.title = nil;
		return;
	}

	NSString *title = entry.title;
	title = title ? title : @"";
	if ([entry isKindOfClass:[Book class]]) {
		[cell setFont:[NSFont boldSystemFontOfSize:11]];
		[cell setTextColor:[NSColor colorWithDeviceRed:112/255.0 green:126/255.0 blue:140/255.0 alpha:1.0]];
		[cell setTitle:[title uppercaseString]];
	} else {
		[cell setFont:[NSFont systemFontOfSize:11]];
		[cell setTextColor:[NSColor blackColor]];
		[cell setTitle:title];
	}
	[cell setImage:[self imageForItem:entry]];
}

-(BOOL) outlineView:(NSOutlineView*)outlineView isGroupItem:(Entry *)entry {
	return [entry isKindOfClass:[Book class]];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldSelectItem:(Entry *)entry {
	return ![entry isKindOfClass:[Book class]] && entry.url != nil;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // We want to allow tracking for all the button cells, even if we don't allow selecting that particular row.
    if ([cell isKindOfClass:[NSButtonCell class]]) {
        // We can also take a peek and make sure that the part of the cell clicked is an area that is normally tracked. Otherwise, clicking outside of the checkbox may make it check the checkbox
        NSRect cellFrame = [outlineView frameOfCellAtColumn:[[outlineView tableColumns] indexOfObject:tableColumn] row:[outlineView rowForItem:item]];
        NSUInteger hitTestResult = [cell hitTestForEvent:[NSApp currentEvent] inRect:cellFrame ofView:outlineView];
        return ((hitTestResult & NSCellHitTrackableArea) != 0);
    } else {
        // Only allow tracking on selected rows. This is what NSTableView does by default.
        return [outlineView isRowSelected:[outlineView rowForItem:item]];
	}
}

@end
