//
//  Shaders.metal
//  MetalTestMac
//
//  Created by John Brewer on 6/27/19.
//  Copyright © 2019 Jera Design LLC. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float4 position [[attribute(VertexAttributePosition)]];
    float4 normal [[attribute(VertexAttributeNormal)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float3 viewDirection;
    float3 oPos;
} VertexToFragment;

vertex VertexToFragment vertexShader(Vertex in [[stage_in]],
                               ushort amp_id [[amplification_id]],
                               constant UniformsArray & uniformsArray [[ buffer(BufferIndexUniforms) ]])
{
    Uniforms uniforms = uniformsArray.uniforms[amp_id];
    VertexToFragment out;
    
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * in.position;
    out.oPos = float3(in.position) + 0.5;
    // o.viewDirection = v.vertex - mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
    out.viewDirection = float3(in.position - uniforms.worldToObject *
                               float4(uniforms.worldSpaceCameraPos, 1));
    return out;
}

// Fragment Shader

#define STEPS 1024
#define STEP_SIZE 0.0075
#define RADIUS 0.5
#define EPSILON 0.01

float4 raymarchHit(float3 oPos, float3 direction, texture3d<float> texture3D [[ texture(TextureIndex3D) ]], sampler texture3DSampler)
{
    float3 position = oPos;
    float4 color = float4(0, 0, 0, 0);
    for (int i = 0; i < STEPS; i++) // failsafe only -- loop should exit via distance check below
    {
        if (distance(position, float3(0.5, 0.5, 0.5)) > RADIUS + EPSILON) {
            //            if (color[3] == 0) {
            ////            return float4(oPos[0], oPos[1], oPos[2], 1);
            //                return float4(direction[0]/2 + 0.5, direction[1]/2 + 0.5, direction[2]/2 + 0.5, 1);
            ////            return float4(position[0], position[1], position[2], 1);
            ////                float steps = (float) i / STEPS;
            ////                return float4(steps, steps, steps, 1);
            //            }
            return color;
            // break;
            // return fixed4(1,1,1,1); // debug -- show missing pixels as white
        }
        float4 voxelColor = texture3D.sample(texture3DSampler, position);
        if (voxelColor[0] > color[0]) {
            color = voxelColor;
        }
        position += direction * STEP_SIZE;
    }
    
    return float4(0.5, 0.5, 0.5, 1);
}

fragment float4 fragmentShader(VertexToFragment in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                               texture3d<float> texture3D   [[ texture(TextureIndex3D) ]])
{
    constexpr sampler texture3DSampler(mip_filter::linear,
                                       mag_filter::linear,
                                       min_filter::linear);
    
    return raymarchHit(in.oPos, normalize(in.viewDirection), texture3D, texture3DSampler);
}
