#import "StorageURLProtocol.h"

#import "StorageContainer.h"
#import "Foundation+Additions.h"

@implementation StorageURLProtocol

#pragma mark
#pragma mark Protocol registration

static NSMapTable *storageByScheme;

+ (void) unregisterProtocol {
	@synchronized([StorageURLProtocol class]) {
		LogDebug(@"Unregistered all schemes");
		[NSURLProtocol unregisterClass:[StorageURLProtocol class]];
		storageByScheme = nil;
	}
}

+ (void) registerStorage:(id<StorageContainer>)storage forScheme:(NSString *)scheme {
	@synchronized([StorageURLProtocol class]) {
		if (!storageByScheme && storage) {
			storageByScheme = [NSMapTable mapTableWithStrongToWeakObjects];
			NSParameterAssert([NSURLProtocol registerClass:[StorageURLProtocol class]]);
		}
		if (storage) {
			LogDebug(@"Registered storage %@ for scheme %@", storage, scheme);
			[storageByScheme setObject:storage forKey:scheme];
		} else {
			LogDebug(@"Unregistered scheme %@", scheme);
			[storageByScheme removeObjectForKey:scheme];
		}
	}
}

#pragma mark
#pragma mark Helpers

- (void) error:(NSString *)message {
	LogDebug(@"%@", message);
	[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:@"StorageURLProtocol" code:0 userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]]];
}

#pragma mark
#pragma mark NSURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *)request {
	return [storageByScheme objectForKey:request.URL.scheme] != nil;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

- (void) startLoading {
	NSURL *url = [[[StorageURLProtocol canonicalRequestForRequest:[self request]] URL] URLByRemovingFragment];
	LogTrace(@"StorageURLProtocol: %@", url);

	// TODO: clarify this
	NSMutableArray *components = [NSMutableArray arrayWithArray:[url pathComponents]];
	if ([components count]>0 && [[components objectAtIndex:0] isEqualTo:@"/"]) {
		[components removeObjectAtIndex:0];
	}

	NSData *data = nil;

	if ([components count] == 2 && [[components objectAtIndex:0] isEqualToString:@"takeoff"]) {
		NSURL *url = [[NSBundle mainBundle] URLForResource:[components objectAtIndex:1] withExtension:nil subdirectory:@"css"];
		if (!url) {
			[self error:[NSString stringWithFormat:@"%@ not found", url]];
			return;
		}
		data = [NSData dataWithContentsOfURL:url];
	} else {
		data = [[storageByScheme objectForKey:url.scheme] dataForPath:url.resourceSpecifier];
	}

	if (!data) {
		[self error:[NSString stringWithFormat:@"URL %@ not found", url]];
		return;
	}

	NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url
														MIMEType:[url.absoluteString hasSuffix:@".html"] ? @"text/html" : nil
										   expectedContentLength:[data length]
												textEncodingName:@"UTF-8"];

	[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
	[[self client] URLProtocol:self didLoadData:data];
	[[self client] URLProtocolDidFinishLoading:self];
}

- (void) stopLoading {
    return;
}

@end
