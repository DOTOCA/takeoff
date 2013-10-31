#import <Foundation/Foundation.h>

#import <WebKit/WebKit.h>

@interface BlockyWebView : WebView {

}

- (void) onMainFrameFinishLoad:(void (^)(void))block;
@end

@interface LoadDelegate : NSObject {
	void (^onLoad)(void);
}

- (id)initWithBlock:(void (^)(void))block;

@end
