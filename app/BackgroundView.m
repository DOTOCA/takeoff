#import "BackgroundView.h"

@implementation BackgroundView

- (void)drawRect:(NSRect)rect {
    [[NSColor colorWithDeviceRed:247/255.0 green:247/255.0 blue:245/255.0 alpha:1.0] setFill];
    NSRectFill(rect);
}

@end
