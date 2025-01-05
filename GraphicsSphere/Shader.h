//
//  Shader.h
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#include <simd/simd.h>

struct Camera {
	vector_float3 position;
	float width;
	float height;
	float focus;
};

struct Sphere {
	vector_float3 position;
	vector_float3 color;
	float radius;
};

struct Light {
	vector_float3 position;
	vector_float3 color;
};

struct Scene {
	struct Camera camera;
	struct Sphere sphere;
	struct Light light;
};
