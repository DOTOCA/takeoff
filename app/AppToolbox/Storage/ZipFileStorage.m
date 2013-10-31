#import "ZipFileStorage.h"

#import "ZipFile.h"
#import "ZipReadStream.h"
#import "ZipWriteStream.h"
#import "FileInZipInfo.h"
#import "StorageURLProtocol.h"

@implementation ZipFileStorage

@synthesize zipPath;

- (NSString *) scheme {
	return [NSString stringWithFormat:@"takeoff-%@", [[zipPath lastPathComponent] stringByDeletingPathExtension]];
}

- (id)initWithPath:(NSString *)p_path create:(BOOL)p_create {
    self = [super init];
    if (self) {
		NSParameterAssert(p_path);
        zipPath = [p_path copy];
		create = p_create;
		if (!create) {
			NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath:zipPath]);
		}
		[StorageURLProtocol registerStorage:self forScheme:[self scheme]];
    }
    return self;
}

- (void) setZipMode:(ZipFileMode)mode {
	if(zip && zip.mode == mode)
		return;

	[self flush];

	BOOL zipExists = [[NSFileManager defaultManager] fileExistsAtPath:zipPath];
	if (create) {
		if (mode == ZipFileModeAppend) {
			mode = ZipFileModeCreate;
			create = NO;
		}
	} else {
		NSParameterAssert(zipExists);
	}

	zip = [[ZipFile alloc] initWithFileName:zipPath mode:mode];
	NSAssert(zip, @"zip");
}

- (NSString *) processPath:(NSString *)path {
	return [path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
}

- (NSData *) dataForPath:(NSString *)path {
	path = [self processPath:path];

	if (create) {
		return [filesToWrite valueForKey:path];
	}

	NSMutableData *data = nil;

	@synchronized(self) {
		[self setZipMode:ZipFileModeUnzip];

		LogTrace(@"Unzipping %@ from %@", path, zip);

		if (![zip locateFileInZip:path]) {
			NSLog(@"%@ not found in zip archive", path);
			return nil;
		}

		FileInZipInfo *info = [zip getCurrentFileInZipInfo];
		ZipReadStream *read = [zip readCurrentFileInZip];
		data = [NSMutableData dataWithLength:info.length];
		[read readDataWithBuffer:data];
		[read finishedReading];
	}

	return data;
}

- (void) setData:(NSData *)data forPath:(NSString *)path {
	@synchronized(self) {
		if (!filesToWrite) {
			filesToWrite = [NSMutableDictionary new];
		}

		// The underlying MiniZip library does not support overwriting / deleting files in a ZIP
		// But it is very convenient to be able to overwrite a file, at least while the file is still
		// opened. That's why all files end up in filesToWrite first and are written only on flush.
		path = [self processPath:path];
		[filesToWrite setValue:data forKey:path];
	}
}

- (void) remove {
	if (zip) {
		[zip close];
		zip = nil;
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:zipPath]) {
		NSLog(@"Deleting %@", zipPath);
		[[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
	}

	filesToWrite = nil;
	create = NO;
}

- (NSArray *) listFiles {
	NSMutableArray *result = [NSMutableArray array];

	@synchronized(self) {
		[self setZipMode:ZipFileModeUnzip];

		NSArray *infos = [zip listFileInZipInfos];
		for(FileInZipInfo *info in infos) {
			[result addObject:info.name];
		}

		[result sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	}

	return result;
}

- (void) flush {
	@synchronized(self) {
		if (filesToWrite) {
			// to write the files, we call setZipMode, which will flush the zip
			// because of that, so filesToWrite is taken aside
			NSDictionary *writeFiles = filesToWrite;
			filesToWrite = nil;
			[self setZipMode:ZipFileModeAppend];

			for(NSString *path in writeFiles) {
				NSData *data = [writeFiles valueForKey:path];
				ZipWriteStream *stream = [zip writeFileInZipWithName:path compressionLevel:ZipCompressionLevelDefault];
				[stream writeData:data];
				[stream finishedWriting];
			}


		}

		if (zip) {
			[zip close];
			zip = nil;
		}
	}
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@>", self.className, self.zipPath];
}

- (NSURL *) URLForPath:(NSString *)path {
	if(!([path hasPrefix:@"/"] || [path hasPrefix:@"http"])) {
		path = [@"/" stringByAppendingString:path];
	}
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", [self scheme], path]];
}

- (NSUInteger) hash {
	return zipPath.hash;
}

- (BOOL) isEqual:(id)anObject {
	return [anObject isKindOfClass:[ZipFileStorage class]] && [((ZipFileStorage *)anObject)->zipPath isEqual:zipPath];
}

- (void) dealloc {
	[StorageURLProtocol registerStorage:nil forScheme:[self scheme]];
	[self flush];
}

@end
