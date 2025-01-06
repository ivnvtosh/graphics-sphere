//
//  Renderer.m
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import "Renderer.h"

#import <vector>

@implementation Renderer {
	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	id<MTLLibrary> library;
	
	id<MTLComputePipelineState> raycastingPipeline;
	id<MTLComputePipelineState> raytracingPipeline;
	id<MTLRenderPipelineState> copyPipeline;
	
	id<MTLTexture> randomTexture;
	id<MTLTexture> accumulationTargets[2];
	
	id<MTLBuffer> planeBuffer;
	id<MTLBuffer> sphereBuffer;
	id<MTLBuffer> sceneBuffer;
	
	scene* scene;
	NSPoint cursor_position;
	bool mouse_down;
	vector_float3 camera_move_direction;
	vector_float3 camera_angle;
	
	bool isRayCastring;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device {
	self = [super init];
	if (self) {
		self->device = device;
		self->mouse_down = false;
		self->isRayCastring = true;
		self->camera_angle = vector3(0.0f, 0.0f, 0.0f);
		[self setupScene];
		[self setupShader];
	}
	return self;
}

- (void)renderUsingRayCasting {
	self->isRayCastring = true;
	scene->frame_index = 0;
}

- (void)renderUsingRayTracing {
	self->isRayCastring = false;
	scene->frame_index = 0;
}

- (void)keyDown:(unsigned short)keyCode {
	switch (keyCode) {
		case 13:
			camera_move_direction.x += +1;
			break;
		case 1:
			camera_move_direction.x += -1;
			break;
		case 49:
			camera_move_direction.z += +1;
			break;
		case 6:
			camera_move_direction.z += -1;
			break;
		case 2:
			camera_move_direction.y += +1;
			break;
		case 0:
			camera_move_direction.y += -1;
			break;
		default:
			break;
	}
}

- (void)keyUp:(unsigned short)keyCode {
	switch (keyCode) {
		case 13:
			camera_move_direction.x -= +1;
			break;
		case 1:
			camera_move_direction.x -= -1;
			break;
		case 49:
			camera_move_direction.z -= +1;
			break;
		case 6:
			camera_move_direction.z -= -1;
			break;
		case 2:
			camera_move_direction.y -= +1;
			break;
		case 0:
			camera_move_direction.y -= -1;
			break;
		default:
			break;
	}
}

- (void)mouseDown:(NSPoint)point {
	cursor_position.x = point.x;
	cursor_position.y = point.y;
	mouse_down = true;
}

- (void)mouseDragged:(NSPoint)point {
	float speed = 0.1f;
	camera_angle.z += +(cursor_position.x - point.x) * speed;
	camera_angle.y += -(cursor_position.y - point.y) * speed;
	cursor_position.x = point.x;
	cursor_position.y = point.y;
}

- (void)mouseUp:(NSPoint)point {
	cursor_position.x = point.x;
	cursor_position.y = point.y;
	mouse_down = false;
}

- (void)rightMouseDown:(NSPoint)point {
	return;
}

- (void)rightMouseDragged:(NSPoint)point {
	return;
}

- (void)rightMouseUp:(NSPoint)point {
	return;
}


// MARK: - Setup Scene

- (void)setupScene {
	std::vector<plane> planes;
	
	planes.push_back(plane());
	
	planes[0].position = vector3(0.0f, 0.0f, -1.0f);
	planes[0].normal = vector3(0.0f, 0.0f, 1.0f);
	planes[0].material.color = vector3(0.7f, 0.7f, 0.7f);
	planes[0].material.light = false;
	planes[0].material.mirror = false;
	planes[0].material.glow_intensity = 0;
	
	std::vector<sphere> spheres;
	
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	spheres.push_back(sphere());
	
	spheres[0].position = vector3(0.0f, 0.0f, 0.0f);
	spheres[0].material.color = vector3(0.8f, 0.8f, 0.8f);
	spheres[0].material.light = false;
	spheres[0].material.mirror = false;
	spheres[0].material.transparent = false;
	spheres[0].radius = 1.0f;
	spheres[0].material.glow_intensity = 0;
	
	spheres[1].position = vector3(-1.0f, 1.25f, -0.75f);
	spheres[1].material.color = vector3(1.0f, 0.9f, 0.2f);
	spheres[1].material.light = true;
	spheres[1].material.mirror = false;
	spheres[1].material.transparent = false;
	spheres[1].radius = 0.25f;
	spheres[1].material.glow_intensity = 1;
	
	spheres[2].position = vector3(-1.0f, 0.6f, -0.775f);
	spheres[2].material.color = vector3(1.0f, 0.2f, 0.2f);
	spheres[2].material.light = true;
	spheres[2].material.mirror = false;
	spheres[2].material.transparent = false;
	spheres[2].radius = 0.20f;
	spheres[2].material.glow_intensity = 1;
	
	spheres[3].position = vector3(-0.5f, 0.9f, -0.9f);
	spheres[3].material.color = vector3(0.0f, 1.0f, 0.2f);
	spheres[3].material.light = true;
	spheres[3].material.mirror = false;
	spheres[3].material.transparent = false;
	spheres[3].radius = 0.1f;
	spheres[3].material.glow_intensity = 1;
	
	spheres[4].position = vector3(0.5f, 1.4f, -0.75f);
	spheres[4].material.color = vector3(0.6f, 0.6f, 0.6f);
	spheres[4].material.light = false;
	spheres[4].material.mirror = true;
	spheres[4].material.transparent = false;
	spheres[4].radius = 0.25f;
	spheres[4].material.glow_intensity = 0;
	
	spheres[5].position = vector3(-0.5f, 2.4f, -0.5f);
	spheres[5].material.color = vector3(0.6f, 0.6f, 0.6f);
	spheres[5].material.light = false;
	spheres[5].material.mirror = false;
	spheres[5].material.transparent = true;
	spheres[5].radius = 0.5f;
	spheres[5].material.glow_intensity = 0;
	
	spheres[6].position = vector3(-0.7f, 19.9f, 0.0f);
	spheres[6].material.color = vector3(1.0f, 1.0f, 1.0f);
	spheres[6].material.light = true;
	spheres[6].material.mirror = false;
	spheres[6].material.transparent = false;
	spheres[6].radius = 1.0f;
	spheres[6].material.glow_intensity = 2;
	
	spheres[7].position = vector3(1.7f, 17.9f, 0.0f);
	spheres[7].material.color = vector3(0.4f, 0.4f, 0.4f);
	spheres[7].material.light = false;
	spheres[7].material.mirror = true;
	spheres[7].material.transparent = false;
	spheres[7].radius = 1.0f;
	spheres[7].material.glow_intensity = 0;
	
	spheres[8].position = vector3(-1.4f, 17.9f, -0.5f);
	spheres[8].material.color = vector3(0.6f, 0.6f, 0.9f);
	spheres[8].material.light = false;
	spheres[8].material.mirror = false;
	spheres[8].material.transparent = true;
	spheres[8].radius = 0.5f;
	spheres[8].material.glow_intensity = 0;
	
	spheres[9].position = vector3(3.3f, 19.4f, -0.5f);
	spheres[9].material.color = vector3(0.4f, 0.4f, 0.4f);
	spheres[9].material.light = false;
	spheres[9].material.mirror = true;
	spheres[9].material.transparent = false;
	spheres[9].radius = 0.5f;
	spheres[9].material.glow_intensity = 0;
	
	spheres[10].position = vector3(-1.4f, 15.9f, -0.5f);
	spheres[10].material.color = vector3(0.9f, 0.9f, 0.9f);
	spheres[10].material.light = false;
	spheres[10].material.mirror = false;
	spheres[10].material.transparent = true;
	spheres[10].radius = 0.5f;
	spheres[10].material.glow_intensity = 0;
	
	spheres[11].position = vector3(-1.4f, 13.9f, -0.5f);
	spheres[11].material.color = vector3(0.9f, 0.9f, 0.9f);
	spheres[11].material.light = false;
	spheres[11].material.mirror = false;
	spheres[11].material.transparent = true;
	spheres[11].radius = 0.5f;
	spheres[11].material.glow_intensity = 0;
	
//	spheres[12].position = vector3(-15.7f, -19.9f, 0.6f);
//	spheres[12].material.color = vector3(1.0f, 1.0f, 1.0f);
//	spheres[12].material.light = true;
//	spheres[12].material.mirror = false;
//	spheres[12].material.transparent = false;
//	spheres[12].radius = 0.1f;
//	spheres[12].material.glow_intensity = 200;
//	
//	spheres[13].position = vector3(-15.7f, -21.0f, -0.82f);
//	spheres[13].material.color = vector3(0.9f, 0.5f, 0.5f);
//	spheres[13].material.light = false;
//	spheres[13].material.mirror = false;
//	spheres[13].material.transparent = true;
//	spheres[13].radius = 0.05f;
//	spheres[13].material.glow_intensity = 0;
	
	planeBuffer = [device newBufferWithLength:sizeof(struct plane) * planes.size() options:MTLResourceStorageModeManaged];
	sphereBuffer = [device newBufferWithLength:sizeof(struct sphere) * spheres.size() options:MTLResourceStorageModeManaged];
	
	memcpy(planeBuffer.contents, planes.data(), planeBuffer.length);
	memcpy(sphereBuffer.contents, spheres.data(), sphereBuffer.length);
	
	sceneBuffer = [device newBufferWithLength:sizeof(struct scene) options:MTLResourceStorageModeManaged];
	
	scene = (struct scene *)((char *)sceneBuffer.contents);
	scene->camera.position = vector3(-6.0f, 0.0f, 0.0f);
	scene->background_color = vector3(0.1f, 0.3f, 0.8f);
	scene->number_planes = (int)planes.size();
	scene->number_spheres = (int)spheres.size();
	scene->frame_index = 0;
}

- (void)updateScene:(CGSize)size {
	scene->camera.size.x = size.width;
	scene->camera.size.y = size.height;
	scene->camera.focus = size.width / 2.0f / tanf(FOV / 2.0f * M_PI / 180.0f);
	scene->frame_index = 0;
	[self camera_rotate:camera_angle];
}

- (void)updateScene {
	vector_float3 t = camera_move_direction * 0.025;
	vector_float3 move;
	
	move.x = scene->camera.matrix.columns[0][0] * t.x + scene->camera.matrix.columns[0][1] * t.y + scene->camera.matrix.columns[0][2] * t.z;
	move.y = scene->camera.matrix.columns[1][0] * t.x + scene->camera.matrix.columns[1][1] * t.y + scene->camera.matrix.columns[1][2] * t.z;
	move.z = scene->camera.matrix.columns[2][0] * t.x + scene->camera.matrix.columns[2][1] * t.y + scene->camera.matrix.columns[2][2] * t.z;
	
	scene->camera.position += move;
	[self camera_rotate:camera_angle];
	if (camera_move_direction.x != 0 || camera_move_direction.y != 0 || camera_move_direction.z != 0) {
		scene->frame_index = 0;
	}
	if (mouse_down) {
		scene->frame_index = 0;
	}
}

- (void)camera_rotate:(vector_float3)angle {
	scene->camera.matrix = (matrix_float3x3) {{
		{ 1, 0, 0 },
		{ 0, 1, 0 },
		{ 0, 0, 1 }
	}};
	[self rotate_z:angle.z];
	[self rotate_x:angle.x];
	[self rotate_y:angle.y];
}

- (void)rotate_x:(float)angle {
	auto radian = M_PI / 180.0f * angle;
	auto cos = std::cosf(radian);
	auto sin = std::sinf(radian);
	matrix_float3x3 temporary {{
		{ 1.0f, 0.0f, 0.0f },
		{ 0.0f, +cos, +sin },
		{ 0.0f, -sin, +cos }
	}};
	scene->camera.matrix = [self matrix_multiply:scene->camera.matrix by:temporary];
}

- (void)rotate_y:(float)angle {
	auto radian = M_PI / 180.0f * angle;
	auto cos = std::cosf(radian);
	auto sin = std::sinf(radian);
	matrix_float3x3 temporary {{
		{ +cos, 0.0f, -sin },
		{ 0.0f, 1.0f, 0.0f },
		{ +sin, 0.0f, +cos }
	}};
	scene->camera.matrix = [self matrix_multiply:scene->camera.matrix by:temporary];
}

- (void)rotate_z:(float)angle {
	auto radian = M_PI / 180.0f * angle;
	auto cos = std::cosf(radian);
	auto sin = std::sinf(radian);
	matrix_float3x3 temporary {{
		{ +cos, +sin, 0.0f },
		{ -sin, +cos, 0.0f },
		{ 0.0f, 0.0f, 1.0f }
	}};
	scene->camera.matrix = [self matrix_multiply:scene->camera.matrix by:temporary];
}

- (matrix_float3x3)matrix_multiply:(matrix_float3x3)lhs by:(matrix_float3x3)rhs {
	return (matrix_float3x3) {{
		{
			lhs.columns[0][0] * rhs.columns[0][0] +
			lhs.columns[0][1] * rhs.columns[1][0] +
			lhs.columns[0][2] * rhs.columns[2][0],
			
			lhs.columns[0][0] * rhs.columns[0][1] +
			lhs.columns[0][1] * rhs.columns[1][1] +
			lhs.columns[0][2] * rhs.columns[2][1],
			
			lhs.columns[0][0] * rhs.columns[0][2] +
			lhs.columns[0][1] * rhs.columns[1][2] +
			lhs.columns[0][2] * rhs.columns[2][2]
		},
		{
			lhs.columns[1][0] * rhs.columns[0][0] +
			lhs.columns[1][1] * rhs.columns[1][0] +
			lhs.columns[1][2] * rhs.columns[2][0],
			
			lhs.columns[1][0] * rhs.columns[0][1] +
			lhs.columns[1][1] * rhs.columns[1][1] +
			lhs.columns[1][2] * rhs.columns[2][1],
			
			lhs.columns[1][0] * rhs.columns[0][2] +
			lhs.columns[1][1] * rhs.columns[1][2] +
			lhs.columns[1][2] * rhs.columns[2][2]
		},
		{
			lhs.columns[2][0] * rhs.columns[0][0] +
			lhs.columns[2][1] * rhs.columns[1][0] +
			lhs.columns[2][2] * rhs.columns[2][0],
			
			lhs.columns[2][0] * rhs.columns[0][1] +
			lhs.columns[2][1] * rhs.columns[1][1] +
			lhs.columns[2][2] * rhs.columns[2][1],
			
			lhs.columns[2][0] * rhs.columns[0][2] +
			lhs.columns[2][1] * rhs.columns[1][2] +
			lhs.columns[2][2] * rhs.columns[2][2]
		}
	}};
}

// MARK: - Setup Shader

- (void)setupShader {
	commandQueue = [device newCommandQueue];
	library = [device newDefaultLibrary];
	raycastingPipeline = [self newRaycastingPipeline];
	raytracingPipeline = [self newRaytracingPipeline];
	copyPipeline = [self newCopyPipeline];
}

- (id<MTLComputePipelineState>)newRaycastingPipeline {
	MTLComputePipelineDescriptor *descriptor = [[MTLComputePipelineDescriptor alloc] init];
	descriptor.label = @"Raycasting";
	descriptor.computeFunction = [library newFunctionWithName:@"raycastingKernel"];
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
	descriptor.label = @"Copy";
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
	descriptor.textureType = MTLTextureType2D;
	descriptor.width = size.width;
	descriptor.height = size.height;
	descriptor.pixelFormat = MTLPixelFormatRGBA32Float;
	descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
	descriptor.storageMode = MTLStorageModePrivate;
	accumulationTargets[0] = [device newTextureWithDescriptor:descriptor];
	accumulationTargets[1] = [device newTextureWithDescriptor:descriptor];
	descriptor.pixelFormat = MTLPixelFormatR32Uint;
	descriptor.usage = MTLTextureUsageShaderRead;
	descriptor.storageMode = MTLStorageModeManaged;
	
	randomTexture = [device newTextureWithDescriptor:descriptor];
	uint32_t *randomValues = (uint32_t *)malloc(sizeof(uint32_t) * size.width * size.height);
	for (NSUInteger i = 0; i < size.width * size.height; i += 1) {
		randomValues[i] = rand() % (1024 * 1024);
	}
	[
		randomTexture
		replaceRegion:MTLRegionMake2D(0, 0, size.width, size.height)
		mipmapLevel:0
		withBytes:randomValues
		bytesPerRow:sizeof(uint32_t) * size.width
	];
	free(randomValues);
}

- (void)drawInMTKView:(nonnull MTKView *)view {
	[self updateScene];
	
	if (isRayCastring && scene->frame_index != 0) {
		return;
	}
	
	if (!isRayCastring && scene->frame_index > 6000) {
		return;
	}
	
	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
	
	NSUInteger width = (NSUInteger)view.frame.size.width;
	NSUInteger height = (NSUInteger)view.frame.size.height;
	MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
	MTLSize threadgroups = MTLSizeMake((width + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width, (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height, 1);
		
	if (isRayCastring) {
		id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
		[computeEncoder setBuffer:sceneBuffer offset:0 atIndex:0];
		[computeEncoder setBuffer:planeBuffer offset:0 atIndex:1];
		[computeEncoder setBuffer:sphereBuffer offset:0 atIndex:2];
		[computeEncoder setTexture:accumulationTargets[1] atIndex:0];
		[computeEncoder setComputePipelineState:raycastingPipeline];
		[computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];
		[computeEncoder endEncoding];
		std::swap(accumulationTargets[0], accumulationTargets[1]);
		
	} else {
		id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
		[computeEncoder setBuffer:sceneBuffer offset:0 atIndex:0];
		[computeEncoder setBuffer:planeBuffer offset:0 atIndex:1];
		[computeEncoder setBuffer:sphereBuffer offset:0 atIndex:2];
		[computeEncoder setTexture:randomTexture atIndex:0];
		[computeEncoder setTexture:accumulationTargets[0] atIndex:1];
		[computeEncoder setTexture:accumulationTargets[1] atIndex:2];
		[computeEncoder setComputePipelineState:raytracingPipeline];
		[computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];
		[computeEncoder endEncoding];
		std::swap(accumulationTargets[0], accumulationTargets[1]);
	}
	
	if (view.currentDrawable) {
		MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
		renderPassDescriptor.colorAttachments[0].texture = view.currentDrawable.texture;
		renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
		renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);
		id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
		[renderEncoder setRenderPipelineState:copyPipeline];
		[renderEncoder setFragmentTexture:accumulationTargets[0] atIndex:0];
		[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
		[renderEncoder endEncoding];
		[commandBuffer presentDrawable:view.currentDrawable];
	}
	
	[commandBuffer commit];
	scene->frame_index += 1;
}

@end
