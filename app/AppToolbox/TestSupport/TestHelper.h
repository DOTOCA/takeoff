#import <Foundation/Foundation.h>

void AssertListOfStringsEqualIgnoringOrder(NSArray *actual, NSArray *expected);

@interface TestHelper : NSObject

+ (NSString *) loadStringForURL:(NSString *)url;
+ (void) expectNilForURLString:(NSString *)url;
+ (void) expect:(NSString *)expectedText inResponseForURLString:(NSString*)url;
+ (NSString *) pathForTestResource:(NSString *)name;
+ (NSURL *) URLForTestResource:(NSString *)path;
+ (NSString *) stringForTestResource:(NSString *)name;
+ (NSData *) dataForTestResource:(NSString *)name;
+ (void) assertBlank:(id)object;

@end
