#import "TakeoffFileDownload.h"

#import "Library.h"
#import "ZipFileStorage.h"
#import "FileUtils.h"

@implementation TakeoffFileDownload

- (id) initWithDictionary:(NSDictionary *)aDictionary parent:(Entry *)aParent {
    self = [super initWithDictionary:aDictionary parent:aParent];
    if (self) {
		downloadUrl = [aDictionary objectForKey:KEY_DOWNLOAD_URL];
		NSParameterAssert([downloadUrl hasSuffix:@".takeoff"]);
	}
	return self;
}

- (NSString *)zipPath {
	return [[FileUtils applicationSupportPath] stringByAppendingPathComponent:[downloadUrl.pathComponents lastObject]];
}

- (NSUInteger)hash {
	return [self zipPath].hash;
}

- (void) install:(id<ProgressHandler>)aprogress {
	NSURL *dlurl = [NSURL URLWithString:downloadUrl];
	LogDebug(@"Downloading %@", dlurl);
	progress = aprogress;

	NSURLConnection *urlConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:dlurl] delegate:self];
	if (urlConnection != nil) {
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (!done);
	}


}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    downloadedData = [NSMutableData data];
    filesize = [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSParameterAssert(downloadedData);
	[progress worked:BOOK_INSTALL_ESTIMATE*(data.length/filesize)];
	[downloadedData appendData:data];

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"%@: %@", self, error);
	downloadedData = nil;
	done = YES;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
	[downloadedData writeToFile:[self zipPath] atomically:YES];

	Library *library = (Library *)self.parent;
	self.parent = nil;
	[library loadBook:[self zipPath]];

	done = YES;
}

@end
