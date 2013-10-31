#import "Benchmark.h"

@implementation Benchmark

+ (double) run:(int(^)(int run))block times:(int)count {
	NSDate *start = [NSDate date];

	int proof = 0;
	for(int i = 1; i <= count; i++) {
		@autoreleasepool {
			proof += block(i);
		}
	}

	NSTimeInterval duration = -[start timeIntervalSinceNow];
	NSTimeInterval avgDuration = duration / count;
	NSLog(@"Benchmark %i runs, average %f ms, proof: %i", count, avgDuration*1000, proof);

	return avgDuration;
}

@end
