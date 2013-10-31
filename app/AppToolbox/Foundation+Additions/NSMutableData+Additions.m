#import "NSMutableData+Additions.h"

@implementation NSMutableData (Additions)

- (void) appendCString:(const char *)value {
	[self appendBytes:value length:strlen(value)];
}

- (void) appendUInt16Big:(u_int16_t)value {
	[self appendBytes:&(u_int16_t){OSSwapHostToBigInt16(value)} length:sizeof(value)];
}

- (void) appendUInt32Big:(u_int32_t)value {
	[self appendBytes:&(u_int32_t){OSSwapHostToBigInt32(value)} length:sizeof(value)];
}

@end
