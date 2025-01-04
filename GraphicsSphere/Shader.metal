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

kernel void raytracing(uint2 tid [[thread_position_in_grid]], constant Scene & scene [[buffer(0)]]) {
}
