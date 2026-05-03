#include "/include/main.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/floodfill.glsl"

uniform float alphaTestRef = 0.1;

#ifdef fsh

#ifdef SUNLIGHT_GI_LEAK_FIX
    in float skylight;
#else
    const float skylight = 0.0;
#endif
in vec2 texcoord;
in vec3 vertexColor;
in vec3 vertexNormal;

/* RENDERTARGETS: 0,1 */
layout (location = 0) out vec4 shadowcolor0Out;
layout (location = 1) out vec4 shadowcolor1Out;

void main () {
    vec4 albedo = texture(gtexture, texcoord);

    albedo.rgb = pow(albedo.rgb * vertexColor, vec3(2.2)) * rgbToAp1Unlit;

    if (renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT && albedo.a > 0.99) albedo.a = 0.99;

    shadowcolor0Out = gl_FrontFacing ? albedo : vec4(0.0, 0.0, 0.0, 1.0);
    shadowcolor1Out = vec4(octEncode(vertexNormal), skylight, float(renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT));

    if (renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT && albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

attribute vec4 at_midBlock;
attribute vec2 mc_Entity;

#ifdef SUNLIGHT_GI_LEAK_FIX
    out float skylight;
#endif
out vec2 texcoord;
out vec3 vertexColor;
out vec3 vertexNormal;

void main () {
    vec3 shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
   
    gl_Position = vec4(shadowProjScale * shadowViewPos, 1.0);

    gl_Position.xy = distortShadowPos(gl_Position.xy);

#ifdef SUNLIGHT_GI_LEAK_FIX
    skylight = (mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1).g;
#endif
    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    vertexColor = gl_Color.rgb;
    vertexNormal = gl_NormalMatrix * gl_Normal;

    #ifdef COLORED_LIGHTING
        if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) {
            vec3 playerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
            ivec3 voxelPos = playerToVoxelPos(playerPos + at_midBlock.xyz * rcp(64.0));

            if (inVoxelBounds(voxelPos)) {
                uint voxelData = (uint(mc_Entity.x) - 10000u) & 255u;

                if (voxelData < 16u || voxelData > 63u) voxelData = uint(renderStage == MC_RENDER_STAGE_TERRAIN_SOLID);

                imageStore(voxelBuffer, voxelPos, uvec4(voxelData, 0u, 0u, 1u));
            }
        }
    #endif
}

#endif