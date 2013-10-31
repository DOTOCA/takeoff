#import <Foundation/Foundation.h>

#import "Library.h"

@interface DocsOutlineDataSource : NSObject<NSOutlineViewDataSource> {
}

@property (strong, nonatomic) IBOutlet Library* library;

- (BOOL) outlineView:(NSOutlineView *)outlineView recommendsSelectItem:(id)item;

@end
