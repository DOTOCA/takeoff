#import "TestHelper.h"

#import "Foundation+Additions.h"
#import <OCMock/OCMock.h>
#import <OCMock/OCMock.h>
#import <GHUnit/GHUnit.h>

void AssertListOfStringsEqualIgnoringOrder(NSArray *actual, NSArray *expected) {
	actual = [actual sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	expected = [expected sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	GHAssertEqualObjects(actual, expected, @"list equal elements");
}


@implementation TestHelper

+ (NSString *) loadStringForURL:(NSString *)url {
	NSError *error;
	return [NSString stringWithContentsOfURL:[[NSURL URLWithString:url] URLByRemovingFragment] encoding:NSUTF8StringEncoding error:&error];
}

+ (NSString *) pathForTestResource:(NSString *)path {
	NSString *name = [path lastPathComponent];
	NSString *directory = [path stringByDeletingLastPathComponent];

	NSString *fullPath = [[NSBundle mainBundle] pathForResource:name ofType:nil inDirectory:directory];
	NSAssert(fullPath, @"test resource %@ does not exist", path);
	return fullPath;
}

+ (NSURL *) URLForTestResource:(NSString *)path {
	return [NSURL fileURLWithPath:[self pathForTestResource:path]];
}

+ (NSData *) dataForTestResource:(NSString *)name {
	NSData *data = [NSData dataWithContentsOfFile:[TestHelper pathForTestResource:name]];
	NSAssert(data, @"test resource %@ does not exist", name);
	return data;
}

+ (NSString *) stringForTestResource:(NSString *)name {
	NSError *error;
	NSString *string = [NSString stringWithContentsOfFile:[TestHelper pathForTestResource:name] encoding:NSUTF8StringEncoding error:&error];
	NSAssert(string, @"test resource %@ does not exist: %@", name, error);
	return string;
}

+ (void) expectNilForURLString:(NSString *)url {
	id result = [TestHelper loadStringForURL:url];
	GHAssertNil(result, @"%@ not nil", result);
}

+ (void) expect:(NSString *)expectedText inResponseForURLString:(NSString*)url {
	NSString *text = [TestHelper loadStringForURL:url];
	GHAssertNotNil(text, @"Got nil for %@", url);
	NSRange pos = [text rangeOfString:expectedText];
	GHAssertTrue(pos.location != NSNotFound, @"URL response for URL %@ does not contain expected text %@ (response: %@)", url, expectedText, text);
}

+ (void) assertBlank:(id)object {
	GHAssertTrue(!object || [[object trim] length] == 0, @"but was '%@'", object);
}

@end
