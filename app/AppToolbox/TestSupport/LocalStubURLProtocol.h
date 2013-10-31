#import <Foundation/Foundation.h>

@interface URLResult : NSObject

@property (nonatomic) NSURLResponse *response;
@property (nonatomic) NSData *data;

+ (URLResult *)html:(NSString *)html forURL:(NSURL *)url;
+ (URLResult *)redirectTo:(NSURL *)toUrl forURL:(NSURL *)fromUrl;

@end

typedef id(^RequestResponseHandler)(NSURLRequest *req);

/**
 LocalStubURLProtocol is a NSURLProtocol that intercepts all NSURL activity and
 delegates data retrieval for URLs to an URLDataProvider block. Made for testing purposes
 where you don't want to rely on the internet.
 */
@interface LocalStubURLProtocol : NSURLProtocol {
}

/**---------------------------------------------------------------------------------------
 * @name Registering the protocol
 * ---------------------------------------------------------------------------------------
 */
/** Registers the protocol and start intercepting all NSURL usage.
 */
+ (void) registerProtocol;

/**
 Unregister the protocol.
 Clears the data provider and the url log.
 */
+ (void) unregisterProtocol;

/**---------------------------------------------------------------------------------------
 * @name Providing data for URLs
 * ---------------------------------------------------------------------------------------
 */

/**
 Configure a RequestResponseHandler block that will respond to NSURLRequests returning
 a URLResult object. As a shortcut, a RequestResponseHandler can return an NSString with
 HTML or an NSURL to send a redirect.
 */
+ (void) setRequestHandler:(RequestResponseHandler)handler;

/**
 Sets a data provider which will throw an exception so that no requests get through.
 */
+ (void) blockRequests;

/**---------------------------------------------------------------------------------------
 * @name Observing URL activity
 * ---------------------------------------------------------------------------------------
 */

/**
 Returns an NSArray with all the NSURLs that have been accessed since the protocol
 was registered.
 */
+ (NSArray *) urlLog;

@end
