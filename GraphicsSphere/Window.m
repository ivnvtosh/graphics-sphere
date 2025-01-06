//
//  Window.m
//  GraphicsSphere
//
//  Created by Anton Ivanov on 05.01.2025.
//

#import "Window.h"

@implementation Window

- (void)keyDown:(NSEvent *)event {
	[self.contentViewController keyDown:event];
}

- (void)keyUp:(NSEvent *)event {
	[self.contentViewController keyUp:event];
}

- (void)mouseDown:(NSEvent *)event {
	[self.contentViewController mouseDown:event];
}

- (void)mouseDragged:(NSEvent *)event {
	[self.contentViewController mouseDragged:event];
}

- (void)mouseUp:(NSEvent *)event {
	[self.contentViewController mouseUp:event];
}

- (void)rightMouseDown:(NSEvent *)event {
	[self.contentViewController rightMouseDown:event];
}

- (void)rightMouseDragged:(NSEvent *)event {
	[self.contentViewController rightMouseDragged:event];
}

- (void)rightMouseUp:(NSEvent *)event {
	[self.contentViewController rightMouseUp:event];
}

@end
