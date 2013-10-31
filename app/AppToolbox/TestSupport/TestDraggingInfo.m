#import "TestDraggingInfo.h"

@implementation TestDraggingInfo

@synthesize draggingPasteboard, draggingDestinationWindow, draggingSourceOperationMask, draggingLocation, draggedImageLocation, draggedImage, draggingSource, draggingSequenceNumber, numberOfValidItemsForDrop;

+ (id) draggingInfoFor:(id<NSDraggingInfo>)original {
	TestDraggingInfo *info = [TestDraggingInfo new];
	info.draggingPasteboard = original.draggingPasteboard;
	info.draggingDestinationWindow = original.draggingDestinationWindow;
	info.draggingSourceOperationMask = original.draggingSourceOperationMask;
	info.draggingLocation = original.draggingLocation;
	info.draggedImageLocation = original.draggedImageLocation;
	info.draggedImage = original.draggedImage;
	info.draggingSource = original.draggingSource;
	info.draggingSequenceNumber = original.draggingSequenceNumber;
	return info;
}

- (void)slideDraggedImageTo:(NSPoint)screenPoint { }

#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
- (void)enumerateDraggingItemsWithOptions:(NSDraggingItemEnumerationOptions)enumOpts forView:(NSView *)view classes:(NSArray *)classArray searchOptions:(NSDictionary *)searchOptions usingBlock:(void (^)(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop))block { }
#endif

+ (id) draggingInfoForPasteboard:(NSPasteboard *)pboard {
	GHAssertNotNil(pboard, @"pasteboard");
	TestDraggingInfo *info = [TestDraggingInfo new];
	info.draggingPasteboard = pboard;
	info.draggingLocation = NSMakePoint(10, 10);
	info.draggedImageLocation = NSMakePoint(10, 10);
	info.draggingSourceOperationMask = NSDragOperationEvery;
	info.draggingSequenceNumber = 1234;
	return info;
}

+ (id) draggingInfoForObject:(id)obj {
	NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
	[pboard writeObjects:[NSArray arrayWithObject:obj]];
	
	return [self draggingInfoForPasteboard:pboard];
}

@end
