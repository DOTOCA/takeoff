@protocol StorageContainer;

@interface StorageURLProtocol : NSURLProtocol

+ (void) registerStorage:(id<StorageContainer>)storage forScheme:(NSString *)scheme;
+ (void) unregisterProtocol;

@end
