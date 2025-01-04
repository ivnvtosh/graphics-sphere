//
//  ViewController.m
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import "ViewController.h"

@implementation ViewController {
}

- (void)viewDidLoad {
	[super viewDidLoad];
	id<MTLDevice> device = MTLCreateSystemDefaultDevice();
	NSAssert(device && device.supportsRaytracing, @"Ray tracing isn't supported on this device");
	MTKView* view = (MTKView*)self.view;
	view.device = device;
}

@end
