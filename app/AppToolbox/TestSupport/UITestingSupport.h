#import <Foundation/Foundation.h>

#import "MainThread.h"

#define AssertWaitForUICondition(condition) { \
	NSDate *startTime = [NSDate date]; \
	__block BOOL result = NO; \
	while(-[startTime timeIntervalSinceNow]<2) { \
		main_sync_exec(^{ result = (BOOL)(condition); });  \
		if (result) break;  \
		[NSThread sleepForTimeInterval:0.01];  \
	}  \
	GHAssertTrue(result, [NSString stringWithCString:#condition encoding:NSUTF8StringEncoding]); \
}


@interface UITestingSupport

+ (void) flush;

@end

@interface NSView (UITestingSupport)
- (void) clickAt:(NSPoint)point;
- (id) findControl:(NSPredicate *)predicate;
- (void) click;
- (void) clickAt:(NSPoint)point;
- (void) dropOperation:(NSDragOperation)expectedOperation files:(id)path, ... NS_REQUIRES_NIL_TERMINATION;
@end

@interface NSTableView (UITestingSupport)
@property (readonly) NSArray *visibleColumns;
@property (readonly) NSArray *visibleColumnNames;
@end
