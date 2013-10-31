#import <Foundation/Foundation.h>

#import "URLMapping.h"

@interface RedirectResourceLoadDelegate : NSObject {
	URLMappingBlock urlMapper;
}

+ (RedirectResourceLoadDelegate *) delegateWithURLMapping:(URLMappingBlock)urlMapper;

@end
