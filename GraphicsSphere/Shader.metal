//
//  Shader.metal
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#include "Shader.h"

#include <metal_stdlib>

using namespace metal;
using namespace raytracing;

inline ray getRay(Camera camera, float2 pixel) {
	float3 direction;
	direction.x = camera.focus;
	direction.y = pixel.x - camera.width / 2.0f;
	direction.z = pixel.y - camera.height / 2.0f;
	ray ray;
	ray.origin = camera.position;
	ray.direction = normalize(direction);
	return ray;
}

kernel void raytracing(uint2 tid [[thread_position_in_grid]], constant Scene & scene [[buffer(0)]]) {
	float2 pixel = (float2)tid;
	ray ray = getRay(scene.camera, pixel);
}
