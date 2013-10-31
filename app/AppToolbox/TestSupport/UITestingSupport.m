#import "UITestingSupport.h"

#import "LogLevels.h"
#import "Foundation+Additions.h"
#import <GHUnit/GHUnit.h>
#import "TestHelper.h"
#import "TestDraggingInfo.h"

@implementation UITestingSupport

+ (void) flush {
	// lets the test thread wait for all outstanding UI queue events
	main_sync_exec(^{});
}

@end

@implementation NSView (UITestingSupport)

- (void) sendEventAndWait:(NSEvent *)event {
	LogDebug(@"-> %@", event);
	[self.window postEvent:event atStart:NO];
	AssertWaitForUICondition([self.window nextEventMatchingMask:NSEventMaskFromType(event.type) untilDate:[NSDate date] inMode:NSEventTrackingRunLoopMode dequeue:NO] == nil);
}

- (id) findControl:(NSPredicate *)predicate {
	if ([predicate evaluateWithObject:self])
		return self;
	for(id c in self.subviews) {
		id result = [c findControl:predicate];
		if (result)
			return result;
	}
	return nil;
}

- (NSEvent *) mouseEvent:(NSEventType)type atPoint:(NSPoint)point {
	NSPoint wpoint = [self convertPointToBase:point];

	return [NSEvent mouseEventWithType: type
							  location: wpoint
						 modifierFlags: 0
							 timestamp: 0
						  windowNumber: self.window.windowNumber
							   context: [NSGraphicsContext graphicsContextWithWindow:self.window]
						   eventNumber: 0
							clickCount: 1
							  pressure: 0];
}

- (NSEvent *) enterExitEvent:(NSEventType)type atPoint:(NSPoint)point {
	NSPoint wpoint = [self convertPointToBase:point];

	return [NSEvent enterExitEventWithType: type
								  location: wpoint
							 modifierFlags: 0
								 timestamp: 0
							  windowNumber: self.window.windowNumber
								   context: [NSGraphicsContext graphicsContextWithWindow:self.window]
							   eventNumber: 0
							trackingNumber: 0
								  userData: nil];
}

- (void) clickAt:(NSPoint)point {
	main_sync_exec(^{
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		[self.window orderFrontRegardless];
		[self.window makeKeyAndOrderFront:self];
	});

	[self sendEventAndWait:[self enterExitEvent:NSMouseEntered atPoint:point]];
	[self sendEventAndWait:[self mouseEvent:NSLeftMouseDown atPoint:point]];
	[self sendEventAndWait:[self mouseEvent:NSLeftMouseUp atPoint:point]];
	[self sendEventAndWait:[self enterExitEvent:NSMouseExited atPoint:point]];
	[UITestingSupport flush];
}

- (void) click {
	LogDebug(@"Clicking %@", self);
	[self clickAt:NSMakePoint(self.frame.size.width / 2, self.frame.size.height / 2)];
}

// TODO: this is not perfect, because it works even if registerForDraggedTypes is missing,
// should simulate the real events.
- (void) dropOperation:(NSDragOperation)expectedOperation files:(id)path, ... {
	GHAssertNotNil(path, @"path");
	NSLog(@"dropFile:%@ on %@", path, self);

	va_list args;
    va_start(args, path);
	NSMutableArray *fileList = [NSMutableArray arrayWithObject:path];
	NSString *arg = nil;
	while((arg = va_arg(args, NSString*))!=nil) {
		[fileList addObject:arg];
    }
    va_end(args);

    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType]
				   owner:nil];
    [pboard setPropertyList:fileList forType:NSFilenamesPboardType];

	main_sync_exec(^{
		id<NSDraggingInfo> draggingInfo = [TestDraggingInfo draggingInfoForPasteboard:pboard];
		NSDragOperation op = [self draggingEntered:draggingInfo];
		GHAssertEquals(expectedOperation, op, @"draggingEntered");
		op = [self draggingUpdated:draggingInfo];
		GHAssertEquals(expectedOperation, op, @"draggingUpdated");
		if (expectedOperation != NSDragOperationNone) {
			GHAssertTrue([self prepareForDragOperation:draggingInfo], @"prepareForDragOperation");
			GHAssertTrue([self performDragOperation:draggingInfo], @"performDragOperation");
			[self concludeDragOperation:draggingInfo];
		}
	});
}

@end

@implementation NSTableView (UITestingSupport)

- (NSArray *) visibleColumns {
	return [self.tableColumns filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hidden=NO"]];
}

- (NSArray *) visibleColumnNames {
	return [[self.tableColumns filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hidden=NO"]] map:^(NSTableColumn *col){ return col.identifier;}];
}

@end
