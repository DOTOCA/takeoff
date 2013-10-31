#import <GHUnit/GHUnit.h>

#import "MainWindowController.h"
#import "LoadDelegate.h"
#import "WebView+Utils.h"
#import "LocalStubURLProtocol.h"
#import "NSOutlineView+Additions.h"
#import "BookProvider.h"
#import "UITestingSupport.h"
#import "FileUtils.h"
#import "TakeOffUIBaseTest.h"

@interface ZzTakeOffUITestsWithPopulatedLibrary : TakeOffUIBaseTest {
}

@end

@implementation ZzTakeOffUITestsWithPopulatedLibrary

- (void) configureController {
	controller.libraryPath = [TestHelper pathForTestResource:@"testlib/"];
}

- (void) testUpdateLibrary {
	// TODO: update the library using the UI
}

- (void) testRubyExampleQuery {
	[self searchFor:@"ruby array" andExpectPath:@"Ruby 1.9.2-p290/Array"];
}

- (void) testCSSExampleQuery {
	[self searchFor:@"css display" andExpectPath:@"CSS/display"];
}

- (void) testTakeOffStyleLoaded {
	[self testCSSExampleQuery];
	[self testRubyExampleQuery];

	main_sync_exec(^{
		[browser loadjQuery];
		GHAssertEqualStrings(@"Georgia", [browser stringByEvaluatingJavaScriptFromString:@"$('h1').css('font-family')"], @"css style missing");
	});
}

- (void) testBrowserPrevNextLocation {
	[self loadEntry:[controller.library entryForTitlePath:@"CSS/background-position"]];
	[self assertBrowserButtons:@"--"];
	GHAssertEqualStrings(@"CSS/background-position", [self jumpBarText], nil);

	[self loadEntry:[controller.library entryForTitlePath:@"CSS/background-attachment"]];
	[self assertBrowserButtons:@"<-"];

	[self loadEntry:[controller.library entryForTitlePath:@"CSS/bottom"]];
	[self assertBrowserButtons:@"<-"];

	[[self prevButton] click];
	[self assertBrowserButtons:@"<>"];
	GHAssertEqualStrings(@"CSS/background-attachment", [self jumpBarText], nil);

	[[self prevButton] click];
	[self assertBrowserButtons:@"->"];

	[[self nextButton] click];
	[self assertBrowserButtons:@"<>"];

}

- (void) testNoResults {
	[self searchFor:@"css display" andExpectPath:@"CSS/display"];
	[self searchFor:@"garglgargl" andExpectPath:nil];
	[self searchFor:@"css direction" andExpectPath:@"CSS/direction"];
	[self searchFor:@"garglgargl" andExpectPath:nil];
	[self searchFor:@"css direction" andExpectPath:@"CSS/direction"];
}

- (void) testSearchFieldAlwaysFocused {
	[self checkSearchFieldIsFirstResponder];

	[self searchFor:@"css display" andExpectPath:@"CSS/display"];
	[self checkSearchFieldIsFirstResponder];

	[outline click];
	[self checkSearchFieldIsFirstResponder];
}

@end
