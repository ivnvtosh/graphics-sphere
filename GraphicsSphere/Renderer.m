//
//  Renderer.m
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import "Renderer.h"

@implementation Renderer {
	id<MTLDevice> device;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device {
	self = [super init];
	if (self) {
		device = device;
	}
	return self;
}

// MARK: - MTKViewDelegate

- (void)drawInMTKView:(nonnull MTKView *)view {
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
}

@end
