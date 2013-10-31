#import "RedirectResourceLoadDelegate.h"

#import <WebKit/WebKit.h>

@implementation RedirectResourceLoadDelegate

- (id)initWithBlock:(URLMappingBlock)pUrlMapper {
    self = [super init];
    if (self) {
        urlMapper = [pUrlMapper copy];
	}
    return self;
}

+ (RedirectResourceLoadDelegate *) delegateWithURLMapping:(URLMappingBlock)pUrlMapper {
	return [[RedirectResourceLoadDelegate alloc] initWithBlock:pUrlMapper];
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {

	NSParameterAssert(urlMapper);
	NSURL *url = urlMapper(request.URL);

	if (url && url != request.URL) {
		LogDebug(@"Redirected %@ -> %@", request.URL, url);
		return [NSURLRequest requestWithURL:url cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
	}
	else
		return request;
}


@end
