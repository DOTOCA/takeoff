#import "URLMapping.h"

@implementation URLMapping

// handle takeoff-bookname-protocol url schema

+ (NSString *) schemaPart:(int)index forURL:(NSURL *)url {
	NSArray *schemeParts = [url.scheme componentsSeparatedByString:@"-"];
	NSAssert([[schemeParts objectAtIndex:0] isEqualToString:@"takeoff"], @"takeoff url scheme");
	if (!(index < [schemeParts count])) {
		return nil;
	}
	return [schemeParts objectAtIndex:index];
}

+ (NSString *) bookNameForURL:(NSURL *)url {
	NSString *host = url.scheme;
	NSUInteger dash = [host rangeOfString:@"-"].location;
	NSAssert(dash != NSNotFound, @"no dash present in %@", host);
	return [host substringFromIndex:dash + 1];
}

// map a public or takeoff URL to the path under which the URL will be put in storage and vice versa

+ (NSString *) pathForURL:(NSURL *)url {
	NSString *str = url.resourceSpecifier;
	if([str hasPrefix:@"//"]) {
		str = [str substringFromIndex:2];
	}
	if (![url.scheme hasPrefix:@"takeoff"])
		return [NSString stringWithFormat:@"%@-%@", url.scheme, str];
	return str;
}

// map a storage path to its public URL

+ (NSURL *) publicURLForPath:(NSString *)path {
	NSUInteger dash = [path rangeOfString:@"-"].location;
	NSAssert(dash != NSNotFound, @"no dash present in %@", path);
	NSString *scheme = [path substringToIndex:dash];
	path = [path substringFromIndex:dash + 1];

	return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", scheme, path]];
}

// map a storage path to the takeoff URL

+ (NSURL *) takeoffURLForPath:(NSString *)path inBookNamed:(NSString *)name {
	// new-style download url
	if ([path hasPrefix:@"http"]) {
		return [URLMapping takeoffURLForPublicURL:[URLMapping publicURLForPath:path] inBookNamed:name];
	}

	// old-style just-a-path url
	if (![path hasPrefix:@"/"]) {
		path = [NSString stringWithFormat:@"/%@", path];
	}

	return [NSURL URLWithString:[NSString stringWithFormat:@"takeoff-%@:%@", name, path]];
}

// map a public URL to an internal takeoff protocol URL and vice versa

+ (NSURL *) takeoffURLForPublicURL:(NSURL *)url inBookNamed:(NSString *)name {
	NSString *urlString = url.absoluteString;
	return [NSURL URLWithString:[NSString stringWithFormat:@"takeoff-%@://%@", name, [urlString stringByReplacingOccurrencesOfString:@"://" withString:@"-"]]];
}

+ (NSURL *) publicURLForURL:(NSURL *)url {
	if (![url.scheme hasPrefix:@"takeoff-"])
		return url;

	NSString *specifier = url.resourceSpecifier;
	if([specifier hasPrefix:@"//"]) {
		specifier = [specifier substringFromIndex:2];
	}
	NSUInteger dash = [specifier rangeOfString:@"-"].location;
	NSAssert(dash != NSNotFound, @"no dash present in %@", specifier);
	NSString *scheme = [specifier substringToIndex:dash];
	specifier = [specifier substringFromIndex:dash + 1];

	return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", scheme, specifier]];
}

+ (URLMappingBlock) urlMapperForStorage:(id<StorageContainer>)storage {
	return [^(NSURL *url) {
		if ([url.scheme hasPrefix:@"takeoff"])
			return url;
		else
			return [storage URLForPath:[url.absoluteString stringByReplacingOccurrencesOfString:@"://" withString:@"-"]];
	} copy];
}

@end
