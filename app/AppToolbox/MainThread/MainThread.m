#import "MainThread.h"

void main_sync_exec(dispatch_block_t yield) {
	if ([NSThread isMainThread]) {
		yield();
	} else {
		dispatch_sync(dispatch_get_main_queue(), yield);
	}
}

void main_async_exec(dispatch_block_t yield) {
	dispatch_async(dispatch_get_main_queue(), yield);
}
