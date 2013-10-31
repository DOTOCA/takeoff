#import <GHUnit/GHUnit.h>

#import "LocalStubURLProtocol.h"

@interface LocalStubURLProtocolTest : GHTestCase {}

@end

@implementation LocalStubURLProtocolTest

- (void) testLocalStubURLProtocol {
	[LocalStubURLProtocol registerProtocol];
	[TestHelper expect:@"Hello World" inResponseForURLString:@"http://www.example.org/test/test.html"];
	[LocalStubURLProtocol unregisterProtocol];
}

@end
