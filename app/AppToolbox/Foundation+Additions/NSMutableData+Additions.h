#import <Foundation/Foundation.h>

@interface NSMutableData (Additions)

- (void) appendCString:(const char *)value;
- (void) appendUInt16Big:(u_int16_t)value;
- (void) appendUInt32Big:(u_int32_t)value;

@end
