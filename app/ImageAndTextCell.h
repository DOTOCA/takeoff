/*
  NSTextFieldCell which can display text and an image simultaneously.
 */

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell {
}

@property (nonatomic, strong) NSImage *image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end
