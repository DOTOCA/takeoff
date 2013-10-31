#import "ColorGradientView.h"

@implementation ColorGradientView

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	if (self.window) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:self.window];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:self.window];
	}
	if (newWindow) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redraw) name:NSWindowDidBecomeKeyNotification object:newWindow];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redraw) name:NSWindowDidResignKeyNotification object:newWindow];

	}
}

- (void) redraw {
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
	float dim = [self.window isKeyWindow] ? 1.0 : 1.2;
	[NSGraphicsContext saveGraphicsState];

	NSColor *startingColor = [NSColor colorWithDeviceWhite:dim*219/255.0 alpha:1.0];
	NSColor *endingColor = [NSColor colorWithDeviceWhite:dim*187/255.0 alpha:1.0];

	NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
	[gradient drawInRect:[self bounds] angle:-90];

	NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(NSMinX([self bounds]), NSMinY([self bounds]))];
    [line lineToPoint:NSMakePoint(NSMaxX([self bounds]), NSMinY([self bounds]))];
    [line setLineWidth:1.0];
	[[NSColor colorWithDeviceWhite:dim*85/255.0 alpha:1.0] set];
    [line stroke];

	[NSGraphicsContext restoreGraphicsState];
}

@end
