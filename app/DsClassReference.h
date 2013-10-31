#import <Foundation/Foundation.h>

#import "Entry.h"

@interface DsClassReference : NSObject {
	NSXMLDocument *doc;
}

- (id)initWithURL:(NSURL *)url;

@property (nonatomic, readonly) Entry *tasks;
@property (nonatomic, readonly) NSString *framework;

@end
