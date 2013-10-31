#import "DocsOutlineDataSource.h"

#import "Entry.h"
#import "Features.h"

#define entries(entry) (entry ? entry : library)->filteredEntries

@implementation DocsOutlineDataSource

@synthesize library;

- (NSArray *) childrenForItem:(Entry *)entry {
	return entries(entry);
}

- (BOOL) outlineView:(NSOutlineView *)outlineView recommendsSelectItem:(Entry *)node {
	BOOL altPressed = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask);
	return altPressed || node.match;
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(Entry*)entry {
	return [entries(entry) count];
}

- (id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(Entry*)entry {
	return [entries(entry) objectAtIndex:index];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(Entry*)entry {
	return [entries(entry) count] > 0;
}

- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(Entry *)item {
	if ([item isKindOfClass:[Book class]] && [tableColumn.identifier isEqualTo:@"Included"]) {
		return [NSNumber numberWithBool:((Book*)item).included];
	}
	return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item  {
	if ([item isKindOfClass:[Book class]] && [tableColumn.identifier isEqualTo:@"Included"]) {
		((Book *)item).included = [object boolValue];
	}
}

#ifdef FEATURE_DRAG_AND_DROP_IMPORT
- (NSURL *) urlForDraggingInfo:(id< NSDraggingInfo >)info {
	NSPasteboard *pb = [info draggingPasteboard];
	NSArray *results = [pb readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:nil];
	LogDebug(@"outlineView:validateDrop:%@ %@", pb.types, results);
	return results.count > 0 ? [results objectAtIndex:0] : nil;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id< NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	return [self urlForDraggingInfo:info] ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
	NSURL *url = [self urlForDraggingInfo:info];
	if (url) {
		[library downloadUrl:url];
		return true;
	}
	return false;
}
#endif

@end
