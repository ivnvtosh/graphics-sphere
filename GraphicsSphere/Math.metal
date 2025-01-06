//
//  Math.metal
//  GraphicsSphere
//
//  Created by Anton Ivanov on 07.01.2025.
//

#include <metal_stdlib>

using namespace metal;

float3 get_reflected_vector(float3 direction, float3 normal) {
	return direction - dot(direction, normal) * 2 * normal;
}
