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

struct hit_result {
	float time;
	float3 normal;
	struct material material;
	float out_time;
};

float3 refract(float3 normal, float3 incident, float n1, float n2) {
	float n = n1 / n2;
	float cos_i = -dot(normal, incident);
	float sin_t2 = n * n * (1.0 - cos_i * cos_i);
	float3 refracted;
	if (sin_t2 > 1.0) {
		refracted.x = -1;
	} else {
		float cos_t = sqrt(1.0 - sin_t2);
		refracted = n * incident + (n * cos_t - cos_t) * normal;
	}
	return refracted;
}

inline float fogAttenuation(float dist, float density) {
  return exp(-density * dist);
}

float3 get_reflected_vector(float3 direction, float3 normal);

inline ray get_ray(camera camera, float2 pixel) {
	ray ray;
	ray.origin = camera.position;
	ray.direction = normalize(float3(camera.focus, pixel - camera.size / 2.0f) * camera.matrix);
	return ray;
}

inline hit_result hit_plane(ray ray, plane plane) {
	float denominator = dot(ray.direction, plane.normal);
	hit_result result;
	if (abs(denominator) < 0.0001f) {
		result.time = -1;
	} else {
		result.time = dot(plane.position - ray.origin, plane.normal) / denominator;
		result.normal = plane.normal;
		result.material = plane.material;
		result.out_time = -1;
	}
	return result;
}

inline hit_result hit_sphere(ray ray, sphere sphere) {
	float3 oc = ray.origin - sphere.position;
	float a = dot(ray.direction, ray.direction);
	float b = 2 * dot(oc, ray.direction);
	float c = dot(oc, oc) - sphere.radius * sphere.radius;
	float d = b * b - 4 * a * c;
	hit_result result;
	if (d < 0) {
		result.time = -1;
	} else {
		result.time = (-b - sqrt(d)) / (2 * a);
		result.normal = normalize(ray.origin + (ray.direction * result.time) - sphere.position);
		result.material = sphere.material;
		result.out_time = (-b + sqrt(d)) / (2 * a);
	}
	return result;
}

constant unsigned int primes[] = {
	2,   3,  5,  7,
	11, 13, 17, 19,
	23, 29, 31, 37,
	41, 43, 47, 53,
	59, 61, 67, 71,
	73, 79, 83, 89
};

float halton(unsigned int i, unsigned int d) {
	unsigned int b = primes[d];

	float f = 1.0f;
	float invB = 1.0f / b;

	float r = 0;

	while (i > 0) {
		f = f * invB;
		r = r + f * (i % b);
		i = i / b;
	}

	return r;
}

inline float3 get_random_unit_vector_on_hemisphere(float3 normal, float2 u) {
	float phi = 2.0f * M_PI_F * u.x;

	float cos_phi;
	float sin_phi = sincos(phi, cos_phi);

	float cos_theta = sqrt(u.y);
	float sin_theta = sqrt(1.0f - cos_theta * cos_theta);

	float3 result;
	float length;
	float dot;
	
	result = float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
	
	length = sqrt(result.x * result.x + result.y * result.y + result.z * result.z);
	
	result.x /= length;
	result.y /= length;
	result.z /= length;
	
	dot = result.x * normal.x + result.y * normal.y + result.z * normal.z;
	
	if (dot < 0) {
		result.x = -result.x;
		result.y = -result.y;
		result.z = -result.z;
	}
	
	return result;
}

inline hit_result hit(constant scene& scene, constant struct plane* planes, constant struct sphere* spheres, ray ray) {
	hit_result hit_result;
	
	hit_result.time = -1;
	
	for (int index = 0; index < scene.number_planes; index += 1) {
		struct hit_result hit_plane_result = hit_plane(ray, planes[index]);
		if (hit_plane_result.time > 0 && (hit_result.time == -1 || hit_plane_result.time < hit_result.time)) {
			hit_result = hit_plane_result;
		}
	}
	
	for (int index = 0; index < scene.number_spheres; index += 1) {
		struct hit_result hit_sphere_result = hit_sphere(ray, spheres[index]);
		if (hit_sphere_result.time > 0 && (hit_result.time == -1 || hit_sphere_result.time < hit_result.time)) {
			hit_result = hit_sphere_result;
		}
	}
	
	return hit_result;
}

inline float3 hit(constant scene& scene, constant struct plane* planes, constant struct sphere* spheres, float2 pixel, unsigned int offset) {
	float3 color = scene.background_color;
	
	ray ray = get_ray(scene.camera, pixel);
	
	for (int bounce = 0; bounce < 6; bounce += 1) {
		hit_result hit_result = hit(scene, planes, spheres, ray);
		
		if (hit_result.time == -1) {
			break;
		}
		
		if (hit_result.material.light) {
			color = hit_result.material.color * hit_result.material.glow_intensity;
			break;
		}
		
		if (hit_result.material.mirror) {
			color *= hit_result.material.color;
			ray.origin = ray.origin + ray.direction * (hit_result.time - 0.001);
			ray.direction = get_reflected_vector(ray.direction, hit_result.normal);
			continue;
		}
		
		if (hit_result.material.transparent) {
			color *= hit_result.material.color;
			ray.origin = ray.origin + ray.direction * (hit_result.time + 0.001);
			ray.direction = refract(hit_result.normal, ray.direction, hit_result.time < hit_result.out_time ? 0.75 : 1, hit_result.time < hit_result.out_time ? 1 : 0.75);
			continue;
		}
		
		float2 random = float2(halton(offset + scene.frame_index, 2 + bounce * 5 + 3), halton(offset + scene.frame_index, 2 + bounce * 5 + 4));
		ray.origin = ray.origin + ray.direction * (hit_result.time - 0.001);
		ray.direction = get_random_unit_vector_on_hemisphere(hit_result.normal, random);
		color *= hit_result.material.color;
		float3 fogAttenuationFactor = fogAttenuation(hit_result.time, 0.01f);
		color = mix(color, scene.background_color, 1.0f - fogAttenuationFactor);
	}
	
	return color;
}

kernel void raytracingKernel(uint2 tid [[thread_position_in_grid]], constant scene& scene [[buffer(0)]], constant struct plane* planes [[buffer(1)]], constant struct sphere* spheres [[buffer(2)]], texture2d<unsigned int> randomTex [[texture(0)]], texture2d<float> prevTex [[texture(1)]], texture2d<float, access::write> dstTex [[texture(2)]]) {
	
	float2 pixel = (float2)tid;
	unsigned int offset = randomTex.read(tid).x;
	
	if (scene.frame_index > 1) {
		float2 r = float2(halton(offset + scene.frame_index, 0), halton(offset + scene.frame_index, 1));
		pixel += r;
	}
	
	float3 color = hit(scene, planes, spheres, pixel, offset);
	
	if (scene.frame_index > 1) {
		float3 prevColor = prevTex.read(tid).xyz;
		prevColor *= scene.frame_index;
		color += prevColor;
		color /= scene.frame_index + 1;
	}
	
	dstTex.write(float4(color, 1.0f), tid);
}

kernel void raycastingKernel(uint2 tid [[thread_position_in_grid]], constant scene& scene [[buffer(0)]], constant struct plane* planes [[buffer(1)]], constant struct sphere* spheres [[buffer(2)]], texture2d<float, access::write> dstTex [[texture(0)]]) {
	
	float2 pixel = (float2)tid;
	
	ray ray = get_ray(scene.camera, pixel);
	
	hit_result hit_result = hit(scene, planes, spheres, ray);
	
	float3 color;
	
	if (hit_result.time == -1) {
		color = float3(0.2, 0.2, 0.2);
	} else {
		color = hit_result.material.color;
	}
	
	dstTex.write(float4(color, 1.0f), tid);
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
	color = max(color, float3(0, 0, 0));
	color = min(color, float3(1, 1, 1));
	return float4(color, 1.0f);
}
