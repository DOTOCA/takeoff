#import <Foundation/Foundation.h>

#import "StorageContainer.h"

typedef NSURL * (^URLMappingBlock)(NSURL *url);

@interface URLMapping : NSObject

+ (NSString *) pathForURL:(NSURL *)url;
+ (NSURL *) publicURLForPath:(NSString *)path;
+ (NSURL *) takeoffURLForPath:(NSString *)path inBookNamed:(NSString *)name;
+ (NSURL *) takeoffURLForPublicURL:(NSURL *)url inBookNamed:(NSString *)name;
+ (NSURL *) publicURLForURL:(NSURL *)url;
+ (NSString *) bookNameForURL:(NSURL *)url;
+ (URLMappingBlock) urlMapperForStorage:(id<StorageContainer>)storage;

@end
