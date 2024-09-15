//
//  ShaderTypes.h
//  MetalTestMac
//
//  Created by John Brewer on 6/27/19.
//  Copyright © 2019 Jera Design LLC. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex)
{
    BufferIndexMeshPositions = 0,
    BufferIndexMeshGenerics  = 1,
    BufferIndexUniforms      = 2
};

typedef NS_ENUM(NSInteger, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeNormal  = 1,
};

typedef NS_ENUM(NSInteger, TextureIndex)
{
    TextureIndexColor    = 0,
    TextureIndex3D       = 1
};

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 worldToObject;
    vector_float3 worldSpaceCameraPos;
} Uniforms;

typedef struct
{
    Uniforms uniforms[2];
} UniformsArray;

#endif /* ShaderTypes_h */

