#import "NSData+Utils.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSData (Hash)

- (NSString*) hexString {
	NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([self length] * 2)];
	const unsigned char *dataBuffer = [self bytes];
	int i;

	for (i = 0; i < [self length]; ++i)
		[stringBuffer appendFormat:@"%02x", (unsigned int)dataBuffer[ i ]];

	return stringBuffer;
}

- (NSString *) sha1 {
    unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([self bytes], (CC_LONG)[self length], hashBytes);
    return [[NSData dataWithBytes:hashBytes length:CC_SHA1_DIGEST_LENGTH] hexString];
}

- (NSString *) UTF8DataToString {
	return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

@end
