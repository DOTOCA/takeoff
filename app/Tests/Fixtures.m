#import "Fixtures.h"

#import "Library.h"
#import "LocalStubURLProtocol.h"
#import "StorageURLProtocol.h"

@implementation Fixtures

+ (NSString*) takeoffZipPath {
	return [TestHelper pathForTestResource:@"test.takeoff"];
}

+ (id<StorageContainer>) emptyStorage {
	id mock = [OCMockObject mockForProtocol:@protocol(StorageContainer)];
	[[[mock stub] andReturn:nil] dataForPath:[OCMArg any]];
	return mock;
}

#define VALUE(V) [OCMArg checkWithBlock:^(id value) { return [value isEqualToString:V]; }]

+ (id<StorageContainer>) storageMock {
	id mock = [OCMockObject mockForProtocol:@protocol(StorageContainer)];
	//TODO: debug why just @"test.html" instead of OCMArg checkWithBlock does not work
	[[[mock stub] andReturn:[@"YES" dataUsingEncoding:NSUTF8StringEncoding]] dataForPath:VALUE(@"/test.html")];
	[[[mock stub] andReturn:[TestHelper dataForTestResource:@"test-index.json"]] dataForPath:@"index.json"];
	[[[mock stub] andReturn:nil] dataForPath:@"nothere.txt"];
	[[[mock stub] andReturn:[NSURL URLWithString:@"takeoff-test:/test.html"]] URLForPath:VALUE(@"test.html")];
	return mock;
}

+ (ZipFileStorage *) testZip:(NSString *)name {
	return [[ZipFileStorage alloc] initWithPath:[TestHelper pathForTestResource:[NSString stringWithFormat:@"%@.takeoff", name]] create:NO];
}

+ (Book *) testBook {
	return [Book loadFromStorage:[Fixtures testZip:@"test"]];
}

+ (Book *) testBook:(NSString *)name {
	return [Book loadFromStorage:[Fixtures testZip:name]];
}

+ (NSURL *)exampleUrl {
	return [NSURL URLWithString:@"http://www.example.org/test/test.html"];
}

+ (NSString *)archivePathForExampleUrl {
	return [Library archivePathByUrl:[Fixtures exampleUrl]];
}

+ (NSString *) tmpZipPath {
	return @"/tmp/test.zip";
}

+ (ZipFileStorage *) tmpZipCreate:(BOOL)create {
	return [[ZipFileStorage alloc] initWithPath:[self tmpZipPath] create:create];
}

+ (void) clear {
	[LocalStubURLProtocol unregisterProtocol];
	[StorageURLProtocol unregisterProtocol];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:[Fixtures archivePathForExampleUrl]])
		[fileManager removeItemAtPath:[Fixtures archivePathForExampleUrl] error:nil];
	if ([fileManager fileExistsAtPath:[self tmpZipPath]])
		[[NSFileManager defaultManager] removeItemAtPath:[self tmpZipPath] error:nil];
}

+ (NSData *) exampleData {
	return [@"Example" dataUsingEncoding:NSUTF8StringEncoding];
}

@end
