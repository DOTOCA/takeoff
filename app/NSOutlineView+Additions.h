#import <Foundation/Foundation.h>

@interface NSOutlineView (Additions)

- (BOOL) fit:(id)item;
- (void) selectRow:(NSInteger)row;
- (void) selectNext;
- (void) selectPrevious;
- (void) selectFirst;
- (void) expandAll;
- (NSString *) columnValueString:(NSString *)identifier;

@end
