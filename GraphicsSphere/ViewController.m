//
//  ViewController.m
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import "ViewController.h"

@implementation ViewController {
	Renderer* renderer;
}

- (IBAction)segmentedCellDidChange:(NSSegmentedCell *)sender {
	switch (sender.selectedSegment) {
		case 1:
			[renderer renderUsingRayCasting];
			break;
		case 2:
			[renderer renderUsingRayTracing];
			break;
		default:
			break;
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	id<MTLDevice> device = MTLCreateSystemDefaultDevice();
	NSAssert(device && device.supportsRaytracing, @"Ray tracing isn't supported on this device");
	MTKView* view = (MTKView*)self.view;
	view.device = device;
	renderer = [[Renderer alloc] initWithDevice:device];
	view.delegate = renderer;
	view.colorPixelFormat = MTLPixelFormatRGBA16Float;
}

- (void)viewDidLayout {
	[super viewDidLayout];
	MTKView* view = (MTKView*)self.view;
	[renderer mtkView:view drawableSizeWillChange:view.bounds.size];
}

- (void)keyDown:(NSEvent *)event {
	if (!event.isARepeat) {
		[renderer keyDown:event.keyCode];
	}
}

- (void)keyUp:(NSEvent *)event {
	if (!event.isARepeat) {
		[renderer keyUp:event.keyCode];
	}
}

- (void)mouseDown:(NSEvent *)event {
	[renderer mouseDown:event.locationInWindow];
}

- (void)mouseDragged:(NSEvent *)event {
	[renderer mouseDragged:event.locationInWindow];
}

- (void)mouseUp:(NSEvent *)event {
	[renderer mouseUp:event.locationInWindow];
}

- (void)rightMouseDown:(NSEvent *)event {
	[renderer rightMouseDown:event.locationInWindow];
}

- (void)rightMouseDragged:(NSEvent *)event {
	[renderer rightMouseDragged:event.locationInWindow];
}

- (void)rightMouseUp:(NSEvent *)event {
	[renderer rightMouseUp:event.locationInWindow];
}

@end
