#import <WebKit/WebKit.h>

@interface DOMNodeList (Utils)
- (NSMutableArray *) asMutableArray;
- (NSArray *) asArray;
@end

@interface WebView (Utils)

- (void) loadJSLibraries:(NSArray *)filenames;
- (void) loadjQuery;
- (void) loadUnderscoreJS;

@property (nonatomic, readonly) NSURL *URL;

@end
