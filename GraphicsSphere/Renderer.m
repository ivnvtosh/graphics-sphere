//
//  Renderer.m
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import "Renderer.h"

@implementation Renderer {
	id<MTLDevice> device;
	
	struct Scene scene;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device {
	self = [super init];
	if (self) {
		device = device;
		[self setupScene];
	}
	return self;
}

// MARK: - Setup Scene

- (void)setupScene {
	[self setupCamera];
	[self setupSphere];
}

- (void)setupCamera {
	scene.camera.position = vector3(3.0f, 0.0f, 0.0f);
	scene.camera.width = WIDTH;
	scene.camera.height = HEIGHT;
	scene.camera.focus = WIDTH / 2.0f / tanf(FOV / 2.0f * M_PI / 180.0f);
}

- (void)setupSphere {
	scene.sphere.position = vector3(0.0f, 0.0f, 0.0f);
	scene.sphere.color = vector3(1.0f, 1.0f, 1.0f);
	scene.sphere.radius = 1.0f;
}

// MARK: - MTKViewDelegate

- (void)drawInMTKView:(nonnull MTKView *)view {
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
}

@end
