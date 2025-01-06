//
//  Shader.h
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#include <simd/simd.h>

struct material {
	vector_float3 color;
	int light;
	float glow_intensity;
	int mirror;
	int transparent;
};

struct camera {
	vector_float3 position;
	matrix_float3x3 matrix;
	vector_float2 size;
	float focus;
};

struct scene {
	struct camera camera;
	vector_float3 background_color;
	int frame_index;
	int number_planes;
	int number_spheres;
};

struct plane {
	vector_float3 position;
	struct material material;
	vector_float3 normal;
};

struct sphere {
	vector_float3 position;
	struct material material;
	float radius;
};
