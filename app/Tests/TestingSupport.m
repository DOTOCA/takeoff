#import "TestingSupport.h"

@implementation TestingSupport

//TODO: allow to build a message after waiting, so you can report about state there (block, varargs)
//TODO: use waitForCondition here
+ (void) waitForUICondition:(BOOL (^)(void))block message:(NSString *)message {
	NSDate *startTime = [NSDate date];
	while(-[startTime timeIntervalSinceNow]<2) {
		__block BOOL result = NO;

		[Display syncExec:^{
			result = block();
		}];

		if (result) {
			return;
		}
		[NSThread sleepForTimeInterval:0.01];
	}
	GHFail(message);
}

+ (void) waitForCondition:(BOOL (^)(void))block message:(NSString *)message timeout:(NSTimeInterval)timeout {
	NSDate *startTime = [NSDate date];
	while(-[startTime timeIntervalSinceNow] < timeout) {
		__block BOOL result = block();

		if (result) {
			return;
		}
		[NSThread sleepForTimeInterval:0.01];
	}
	GHFail(message);
}

@end
