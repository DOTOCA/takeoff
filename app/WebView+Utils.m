#import "WebView+Utils.h"

@implementation DOMNodeList (Utils)

- (NSMutableArray *)asMutableArray {
    NSUInteger count = [self length];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];

    unsigned i = 0;
    for ( ; i < count; i++) {
        [result addObject:[self item:i]];
    }

    return result;
}

- (NSArray *)asArray {
	return [[self asMutableArray] copy];
}

@end

@implementation WebView (Utils)

- (void) loadJSLibraries:(NSArray *)filenames {
	// load capture js dependencies
	for(NSString* js in filenames) {
		NSString *filePath = [[NSBundle mainBundle] pathForResource:js ofType:@"js"];
		NSAssert(filePath, @"%@ not found!", js);

		NSError *error;
		NSString *code = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
		NSAssert(code, @"File %@ could not be loaded: %@", filePath, error);
		[self.mainFrame.windowObject evaluateWebScript:code];
	}
}

- (void) loadjQuery {
	[self loadJSLibraries:[NSArray arrayWithObjects:@"jquery", nil]];
}

- (void) loadUnderscoreJS {
	[self loadJSLibraries:[NSArray arrayWithObjects:@"underscore", nil]];
}

- (NSURL *) URL {
	// mainFrameURL is annonying because it might be null after loading if loadRequest is loaded, and
	// it returns a String
	NSURL *url = self.mainFrame.provisionalDataSource.request.URL;
	if (!url)
		url = self.mainFrame.dataSource.request.URL;
	return url;
}

@end
