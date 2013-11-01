#import "LocalStubURLProtocol.h"

@implementation URLResult

+ (URLResult *)html:(NSString *)html forURL:(NSURL *)url {
    URLResult *result = [[URLResult alloc] init];
    if (!html) {
        result.data = [@"not found" dataUsingEncoding:NSUTF8StringEncoding];
        result.response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:@{} ];
    } else {
        result.data = [html dataUsingEncoding:NSUTF8StringEncoding];
        result.response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{ @"Content-Type" : @"text/html" } ];
    }
    return result;
}

+ (URLResult *)redirectTo:(NSURL *)toUrl forURL:(NSURL *)fromUrl {
    URLResult *result = [[URLResult alloc] init];
    result.response = [[NSHTTPURLResponse alloc] initWithURL:fromUrl statusCode:301 HTTPVersion:@"HTTP/1.1" headerFields:@{ @"Location" : toUrl.absoluteString } ];
    return result;
}

@end

@implementation LocalStubURLProtocol

static RequestResponseHandler responseHandler;
static NSMutableArray *urlLog;

+ (void) registerProtocol {
	[self unregisterProtocol];
	[NSURLProtocol registerClass:[LocalStubURLProtocol class]];
	responseHandler = nil;
	urlLog = [NSMutableArray new];
}

+ (void) unregisterProtocol {
	[NSURLProtocol unregisterClass:[LocalStubURLProtocol class]];
	responseHandler = nil;
	urlLog = nil;
}

#pragma mark - Configuring responses for requests

+ (void) blockRequests {
	responseHandler = ^(NSURLRequest *req) {
		[NSException raise:@"BlockRequests" format:@"LocalStubURLProtocol should not have been triggered for %@.", req.URL];
        return (URLResult *)nil;
    };
}

+ (void) setRequestHandler:(RequestResponseHandler)handler {
    responseHandler = handler;
}

+ (NSArray *) urlLog {
	return urlLog;
}

#pragma mark - Helpers

- (void) error:(NSString *)message {
	NSLog(@"%@", message);
	[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:@"ArchiveURLProtocol" code:0 userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]]];
}

#pragma mark - NSURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *)request {
    return responseHandler && responseHandler(request) != nil;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

- (BOOL) isRedirect:(URLResult *)result {
    if([result.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) result.response;
        if (httpResponse.statusCode == 301 || httpResponse.statusCode == 302) {
            return true;
        }
    }
    return false;
}

- (URLResult *) responseFor:(NSURLRequest *)request {
    id result = responseHandler(request);
    if (!result) {
        return nil;
    }
    if ([result isKindOfClass:[URLResult class]]) {
        return result;
    }
    if ([result isKindOfClass:[NSString class]]) {
        return [URLResult html:(NSString *)result forURL:self.request.URL];
    }
    if ([result isKindOfClass:[NSURL class]]) {
        return [URLResult redirectTo:(NSURL *)result forURL:self.request.URL];
    }
    [NSException raise:@"SimpleRequestHandler" format:@"Unknown result object: %@", result];
    return nil;
}

- (void) startLoading {
	NSURL *url = self.request.URL;
	[urlLog addObject:url];

    URLResult *result = [self responseFor:self.request];

    while([self isRedirect:result]) {
        NSHTTPURLResponse *httpResponse = ((NSHTTPURLResponse *)result.response);
        NSURLRequest *newRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:httpResponse.allHeaderFields[@"Location"]]];
        [[self client] URLProtocol:self wasRedirectedToRequest:newRequest redirectResponse:result.response];
        result = [self responseFor:newRequest];
    }

	[[self client] URLProtocol:self didReceiveResponse:result.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	[[self client] URLProtocol:self didLoadData:result.data];
	[[self client] URLProtocolDidFinishLoading:self];

	NSLog(@"LocalStubURLProtocol responded: %@", url);
}

- (void) stopLoading {
    return;
}

@end
