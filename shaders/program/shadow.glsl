#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/floodfill.glsl"

uniform float alphaTestRef = 0.1;

#ifdef fsh

in vec2 texcoord;
in vec3 vertexColor;
in vec3 vertexNormal;

/* RENDERTARGETS: 0,1 */
layout (location = 0) out vec4 shadowcolor0Out;
layout (location = 1) out vec4 shadowcolor1Out;

void main () {
    vec4 albedo = texture(gtexture, texcoord);

    albedo.rgb *= vertexColor;

    shadowcolor0Out = albedo;
    shadowcolor1Out = vec4(0.0);

    if (renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT && albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

attribute vec4 at_midBlock;
attribute vec2 mc_Entity;

out vec2 texcoord;
out vec3 vertexColor;
out vec3 vertexNormal;

void main () {
    vec3 shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
   
    gl_Position = vec4(shadowProjScale * shadowViewPos, 1.0);

    gl_Position.xy = distortShadowPos(gl_Position.xy);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    vertexColor = gl_Color.rgb;
    vertexNormal = transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal;

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