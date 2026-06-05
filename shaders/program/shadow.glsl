
#include "/include/main.glsl"

// ----- Varying -----

flat varying uint geometryId;

varying float skylight;
varying vec2 texcoord;
varying vec3 worldPos;
varying vec3 vertexColor;
varying vec3 vertexNormal;

#ifdef fsh

// ----- Outputs -----

/* RENDERTARGETS: 0,1 */
layout (location = 0) out vec4 shadowcolor0Out;
layout (location = 1) out vec4 shadowcolor1Out;

// ----- Uniforms -----

uniform float alphaTestRef = 0.1;

// ----- Includes -----

#include "/block.properties"

#include "/include/surface/material.glsl"
#include "/include/surface/waterVolume.glsl"

#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/voxelVolume.glsl"

// ----- Functions -----

void main () {
    vec4 albedo = texture(gtexture, texcoord);

    albedo.rgb = pow(albedo.rgb * vertexColor, vec3(2.2)) * rgbToAp1Unlit;

    if (renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT && albedo.a > 0.99) albedo.a = 0.99;
    
    if (geometryId == BLOCK_WATER) {
        vec3 waterNormal = getWaveNormal(worldPos);

        albedo = vec4(clamp01(exp(-waterExtinction * 2.0) * (1.0 + dot(waterNormal.xy, vec2(4.0)))), 0.0);
    }

    shadowcolor0Out = gl_FrontFacing ? albedo : vec4(0.0, 0.0, 0.0, 1.0);
    shadowcolor1Out = vec4(octEncode(vertexNormal), skylight, float(renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT));

    if (renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT && albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

// ----- Attributes -----

attribute vec4 at_midBlock;
attribute vec2 mc_Entity;

// ----- Includes -----

#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/voxelVolume.glsl"

// ----- Functions -----

void main () {
    vec3 shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 scenePos = mat3(shadowModelViewInverse) * shadowViewPos + shadowModelViewInverse[3].xyz;
   
    gl_Position = vec4(shadowProjScale * shadowViewPos, 1.0);

    gl_Position.xy = distortShadowPos(gl_Position.xy);

    geometryId = mc_Entity.x < 0.0 ? 255u : uint(mc_Entity.x);

    skylight = (mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1).g;
    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    worldPos = scenePos + cameraPosition;
    vertexColor = gl_Color.rgb;
    vertexNormal = gl_NormalMatrix * gl_Normal;

    #ifdef COLORED_LIGHTING
        if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) {
            ivec3 voxelPos = sceneToVoxelPos(scenePos + at_midBlock.xyz * rcp(64.0));

            if (inVoxelBounds(voxelPos)) {
                uint voxelData = geometryId & 255u;

                if (voxelData > 63u) voxelData = uint(renderStage == MC_RENDER_STAGE_TERRAIN_SOLID);

                imageStore(voxelBuffer, voxelPos, uvec4(voxelData, 0u, 0u, 1u));
            }
        }
    #endif
}

#endif