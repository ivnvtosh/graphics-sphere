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

struct HitPlaneResult {
	float time;
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

inline HitPlaneResult hitPlane(ray ray, Plane plane) {
	float denominator = dot(ray.direction, plane.normal);
	HitPlaneResult result;
	if (abs(denominator) < 0.0001f) {
		result.hit = false;
	} else {
		result.hit = true;
		result.time = dot(plane.position - ray.origin, plane.normal) / denominator;
	}
	return result;
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
		result.hit = true;
		result.time[0] = (-b - sqrt(d)) / (2 * a);
		result.time[1] = (-b + sqrt(d)) / (2 * a);
	}
	return result;
}

inline float3 getColor(constant Scene& scene, ray ray, HitPlaneResult result) {
	float3 point = ray.origin + ray.direction * result.time;
	float3 lightDirection = normalize(scene.light.position - point);
	
	struct ray new_ray;
	new_ray.origin = point;
	new_ray.direction = lightDirection;
	HitSphereResult hitSphereResult = hitSphere(new_ray, scene.sphere);
	if (hitSphereResult.hit && hitSphereResult.time[0] > 0) {
		return scene.background_color;
	}
	
	float intensity = dot(scene.plane.normal, lightDirection);
	return scene.plane.color * intensity;
}

inline float3 getColor(constant Scene& scene, ray ray, HitSphereResult result) {
	float3 point = ray.origin + ray.direction * result.time[0];
	float3 sphereNormal = normalize(point - scene.sphere.position);
	float3 lightDirection = normalize(scene.light.position - point);
	float intensity = dot(sphereNormal, lightDirection);
	return scene.sphere.color * intensity;
}

kernel void raytracingKernel(uint2 tid [[thread_position_in_grid]], constant Scene& scene [[buffer(0)]], texture2d<float, access::write> texture [[texture(0)]]) {
	float2 pixel = (float2)tid;
	ray ray = getRay(scene.camera, pixel);
	HitPlaneResult hitPlaneResult = hitPlane(ray, scene.plane);
	HitSphereResult hitSphereResult = hitSphere(ray, scene.sphere);
	float3 color;
	if (hitPlaneResult.hit && hitSphereResult.hit) {
		if (hitPlaneResult.time < hitSphereResult.time[0] && hitPlaneResult.time > 0) {
			color = getColor(scene, ray, hitPlaneResult);
		} else {
			color = getColor(scene, ray, hitSphereResult);
		}
	} else if (hitPlaneResult.hit && hitPlaneResult.time > 0) {
		color = getColor(scene, ray, hitPlaneResult);
	} else if (hitSphereResult.hit && hitSphereResult.time[0] > 0) {
		color = getColor(scene, ray, hitSphereResult);
	} else {
		color = scene.background_color;
	}
	
	texture.write(float4(color, 1.0f), tid);
}

constant float2 quadVertices[] = {
	float2(-1, -1),
	float2(-1,  1),
	float2( 1,  1),
	float2(-1, -1),
	float2( 1,  1),
	float2( 1, -1)
};

struct CopyVertexOut {
	float4 position [[position]];
	float2 uv;
};

vertex CopyVertexOut copyVertex(unsigned short vid [[vertex_id]]) {
	float2 position = quadVertices[vid];
	CopyVertexOut out;
	out.position = float4(position, 0, 1);
	out.uv = position * 0.5f + 0.5f;
	return out;
}

fragment float4 copyFragment(CopyVertexOut in [[stage_in]], texture2d<float> tex) {
	constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
	float3 color = tex.sample(sam, in.uv).xyz;
	color = color / (1.0f + color);
	return float4(color, 1.0f);
}
