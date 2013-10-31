#import "FileStorage.h"

@implementation FileStorage

- (id)initWithPath:(NSString *)p_path {
    self = [super init];
    if (self) {
		NSParameterAssert(p_path);
        path = p_path;
    }
    return self;
}

+ (id) storageWithPath:(NSString *)p_path {
	return [[FileStorage alloc] initWithPath:p_path];
}

- (NSData *) dataForPath:(NSString *)relativePath {
	NSString *fullPath = [path stringByAppendingPathComponent:relativePath];
	return [NSData dataWithContentsOfFile:fullPath];
}

- (void) setData:(NSData *)data forPath:(NSString *)path {
	[NSException raise:@"UnsupportedOperation" format:@"Unsupported Operation"];
}

- (void) flush {

}

- (NSUInteger)hash {
	return path.hash;
}

- (BOOL)isEqual:(id)anObject {
	return [anObject isKindOfClass:[FileStorage class]] && [((FileStorage *)anObject)->path isEqual:path];
}

- (NSURL *) URLForPath:(NSString *)relativePath {
	return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", path, relativePath]];
}


@end
