#import <Foundation/Foundation.h>

@class Entry;

@interface DocsOutlineDelegate : NSObject<NSOutlineViewDelegate> {
}

- (NSImage *) imageForItem:(Entry *)node;

@end
