#import <Foundation/Foundation.h>

#import "BookProvider.h"

@interface OnlineBookProvider : NSObject<BookProvider> {
	NSString *downloadUrl;
}

@end
