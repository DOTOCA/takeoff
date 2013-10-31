#import <Foundation/Foundation.h>

@interface TestDraggingInfo : NSObject<NSDraggingInfo> {

@private
    NSPasteboard *draggingPasteboard;
	NSWindow *draggingDestinationWindow;
	NSDragOperation draggingSourceOperationMask;
	NSPoint draggingLocation;
	NSPoint draggedImageLocation;
	NSImage *draggedImage;
	id draggingSource;
	NSInteger draggingSequenceNumber;
	NSInteger numberOfValidItemsForDrop;
}

+ (id) draggingInfoFor:(id<NSDraggingInfo>)original;
+ (id) draggingInfoForPasteboard:(NSPasteboard *)pboard;
+ (id) draggingInfoForObject:(id)obj;

@property (nonatomic, retain) NSPasteboard *draggingPasteboard;
@property (nonatomic, retain) NSWindow *draggingDestinationWindow;
@property (nonatomic, assign) NSDragOperation draggingSourceOperationMask;
@property (nonatomic, assign) NSPoint draggingLocation;
@property (nonatomic, assign) NSPoint draggedImageLocation;
@property (nonatomic, retain) NSImage *draggedImage;
@property (nonatomic, retain) id draggingSource;
@property (nonatomic, assign) NSInteger draggingSequenceNumber;
@property NSInteger numberOfValidItemsForDrop;

@end
