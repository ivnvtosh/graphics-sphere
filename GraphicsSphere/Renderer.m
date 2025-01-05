//
//  Renderer.m
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import "Renderer.h"

@implementation Renderer {
	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	id<MTLLibrary> library;
	id<MTLBuffer> sceneBuffer;
	id<MTLComputePipelineState> raytracingPipeline;
	id<MTLRenderPipelineState> copyPipeline;
	id<MTLTexture> randomTexture;
	id<MTLTexture> accumulationTargets[2];
	
	MTLRenderPassDescriptor *drawableRenderDescriptor;
	
	struct Scene scene;
	
	float frameNumber;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device {
	self = [super init];
	if (self) {
		self->device = device;
		self->frameNumber = 0;
		[self setupScene];
		[self setupShader];
	}
	return self;
}

// MARK: - Setup Scene

- (void)setupScene {
	scene.camera.position = vector3(-6.0f, 0.0f, 0.0f);
	scene.sphere.position = vector3(0.0f, 0.0f, 0.0f);
	scene.sphere.color = vector3(1.0f, 1.0f, 1.0f);
	scene.sphere.radius = 1.0f;
	scene.light.position = vector3(-5.0f, 5.0f, 5.0f);
	scene.light.color = vector3(1.0f, 1.0f, 1.0f);
	scene.plane.position = vector3(0.0f, 0.0f, -1.0f);
	scene.plane.normal = vector3(0.0f, 0.0f, 1.0f);
	scene.plane.color = vector3(1.0f, 1.0f, 1.0f);
	scene.background_color = vector3(0.0f, 0.0f, 0.0f);
	sceneBuffer = [device newBufferWithLength:sizeof(struct Scene) options:MTLResourceStorageModeManaged];
}

- (void)updateScene:(CGSize)size {
	scene.camera.width = size.width;
	scene.camera.height = size.height;
	scene.camera.focus = size.width / 2.0f / tanf(FOV / 2.0f * M_PI / 180.0f);
	struct Scene* scene = (struct Scene *)((char *)sceneBuffer.contents);
	*scene = self->scene;
}

- (void)updateScene {
	self->frameNumber += 1;
	struct Scene* scene = (struct Scene *)((char *)sceneBuffer.contents);
	scene->light.position = vector3(cosf(self->frameNumber / 50.0f) * -20.0f, sinf(self->frameNumber / 50.0f) * 20.0f, 5.0f);
}

// MARK: - Setup Shader

- (void)setupShader {
	commandQueue = [device newCommandQueue];
	library = [device newDefaultLibrary];
	raytracingPipeline = [self newRaytracingPipeline];
	copyPipeline = [self newCopyPipeline];
}

- (id<MTLComputePipelineState>)newRaytracingPipeline {
	MTLComputePipelineDescriptor *descriptor = [[MTLComputePipelineDescriptor alloc] init];
	descriptor.label = @"Raytracing";
	descriptor.computeFunction = [library newFunctionWithName:@"raytracingKernel"];
	descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
	NSError *error = NULL;
	id<MTLComputePipelineState> pipeline = [
		device
		newComputePipelineStateWithDescriptor:descriptor
		options:0
		reflection:nil
		error:&error
	];
	if (error) {
		NSLog(@"%@", [error localizedDescription]);
	}
	return pipeline;
}

- (id<MTLRenderPipelineState>)newCopyPipeline {
	MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
	descriptor.vertexFunction = [library newFunctionWithName:@"copyVertex"];
	descriptor.fragmentFunction = [library newFunctionWithName:@"copyFragment"];
	descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
	NSError *error;
	id<MTLRenderPipelineState> pipeline = [
		device
		newRenderPipelineStateWithDescriptor:descriptor
		error:&error
	];
	if (error) {
		NSLog(@"%@", [error localizedDescription]);
	}
	return pipeline;
}

// MARK: - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
	[self updateScene:size];
	MTLTextureDescriptor* descriptor = [[MTLTextureDescriptor alloc] init];
	descriptor.pixelFormat = MTLPixelFormatRGBA32Float;
	descriptor.textureType = MTLTextureType2D;
	descriptor.width = size.width;
	descriptor.height = size.height;
	descriptor.storageMode = MTLStorageModePrivate;
	descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
	randomTexture = [device newTextureWithDescriptor:descriptor];
}

- (void)drawInMTKView:(nonnull MTKView *)view {
	[self updateScene];
	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
	
	NSUInteger width = (NSUInteger)view.frame.size.width;
	NSUInteger height = (NSUInteger)view.frame.size.height;
	MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
	MTLSize threadgroups = MTLSizeMake((width  + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width,
									   (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
									   1);
	
	id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
	[computeEncoder setBuffer:sceneBuffer offset:0 atIndex:0];
	[computeEncoder setTexture:randomTexture atIndex:0];
	[computeEncoder setComputePipelineState:raytracingPipeline];
	[computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];
	[computeEncoder endEncoding];
	
	if (view.currentDrawable) {
		MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
		renderPassDescriptor.colorAttachments[0].texture = view.currentDrawable.texture;
		renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
		renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);
		id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
		[renderEncoder setRenderPipelineState:copyPipeline];
		[renderEncoder setFragmentTexture:randomTexture atIndex:0];
		[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
		[renderEncoder endEncoding];
		[commandBuffer presentDrawable:view.currentDrawable];
	}
	
	[commandBuffer commit];
}

@end
