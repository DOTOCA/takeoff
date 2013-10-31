#import "OnlineBookProvider.h"

#import "Foundation+Additions.h"
#import "TakeoffFileDownload.h"

@implementation OnlineBookProvider

- (NSArray *) availableBooks {
	NSError *error = nil;
	NSArray *array = ([NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.ralfebert.de/products/takeoff/repo/index-1.2.json"]] options:0 error:&error]);

	if (error) {
        NSLog(@"Error with parsing index.json: %@", error);
		return [NSArray array];
	}

	NSArray *books = [array map:^(NSDictionary *dict){
		return [[TakeoffFileDownload alloc] initWithDictionary:dict parent:nil];
	}];

	return books;
}

@end
