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

struct HitSphereResult {
	float2 time;
	bool hit;
};

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

inline HitSphereResult hitSphere(ray ray, Sphere sphere) {
	float3 oc = ray.origin - sphere.position;
	float a = dot(ray.direction, ray.direction);
	float b = 2 * dot(oc, ray.direction);
	float c = dot(oc, oc) - sphere.radius * sphere.radius;
	float d = b * b - 4 * a * c;
	HitSphereResult result;
	if (d < 0) {
		result.hit = false;
	} else {
		float t1 = (-b - sqrt(d)) / (2 * a);
		float t2 = (-b + sqrt(d)) / (2 * a);
		result.hit = true;
		result.time = float2(t1, t2);
	}
	return result;
}

kernel void raytracing(uint2 tid [[thread_position_in_grid]], constant Scene & scene [[buffer(0)]]) {
	float2 pixel = (float2)tid;
	ray ray = getRay(scene.camera, pixel);
	HitSphereResult result = hitSphere(ray, scene.sphere);
	float3 color = result.hit ? scene.sphere.color : float3(0, 0, 0);
}
