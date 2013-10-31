#import <GHUnit/GHUnit.h>

#import <WebKit/WebKit.h>
#import "LocalStubURLProtocol.h"
#import "StorageURLProtocol.h"
#import "LoadDelegate.h"
#import "RedirectResourceLoadDelegate.h"

enum {
	PageLoaded = 100
};

@interface RedirectResourceLoadDelegateTest : GHAsyncTestCase {
}

@end

@implementation RedirectResourceLoadDelegateTest

- (BOOL) shouldRunOnMainThread {
	return YES;
}

- (void) setUp {
	[StorageURLProtocol registerStorage:[Fixtures testZip:@"the-internet"] forScheme:@"takeoff-test"];
	[LocalStubURLProtocol registerProtocol];
	[LocalStubURLProtocol blockRequests];
}

- (void) tearDown {
	[LocalStubURLProtocol unregisterProtocol];
	[StorageURLProtocol unregisterProtocol];
}

- (void) testRedirectResourceLoadDelegate {
	[self prepare];

	BlockyWebView *webView = [BlockyWebView new];
	[webView onMainFrameFinishLoad:^{ [self notify:PageLoaded]; }];

	webView.resourceLoadDelegate = [RedirectResourceLoadDelegate delegateWithURLMapping:^(NSURL *url) {
		return ([url.scheme isEqualTo:@"http"]) ? [NSURL URLWithString:[[url absoluteString] stringByReplacingOccurrencesOfString:@"http://www" withString:@"takeoff-test://http-www"]] : nil;
	}];

	[webView.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.example.org/test/test.html"]]];
	[self waitForStatus:PageLoaded timeout:2];

	GHAssertEqualStrings(@"Example page", webView.mainFrameTitle, @"title");
	GHAssertEqualStrings(@"takeoff-test://http-www.example.org/test/test.html", webView.mainFrameURL, @"url");
}

@end
