#version 430 compatibility

#include "/include/main.glsl"

// ----- Outputs -----

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 colorRgbe8;

// ----- Includes -----

#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/raymarching.glsl"
#include "/include/utility/rng.glsl"

#include "/include/surface/bsdf.glsl"
#include "/include/surface/material.glsl"

#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/voxelVolume.glsl"
#include "/include/lighting/lighting.glsl"

#include "/include/atmospherics/atmosphere.glsl"

// ----- Functions -----

void main () {
    ivec2 texel = ivec2(gl_FragCoord.xy);

    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    vec3 color = decodeRgbe8(texelFetch(colortex7, texel, 0));

    if (depth == 0.0) {
        colorRgbe8 = encodeRgbe8(color);
        return;
    }

    float dither = getInterleavedGradientNoise(gl_FragCoord.xy);

    vec2 coord = internalTexelSize * gl_FragCoord.xy;

    vec3 viewPos = screenToViewPos(coord, depth);
    vec3 scenePos = viewToScenePos(viewPos);
    vec3 viewDir = normalize(scenePos - gbufferModelViewInverse[3].xyz);

    uvec4 encoded = texelFetch(colortex9, texel, 0);

    vec4 albedo = unpackUnorm4x8(encoded.r);
    vec2 lightLevels = unpackUnorm2x8(encoded.g >> 16u);
    vec3 normal = octDecode(unpackUnorm2x8(encoded.g));
    vec3 textureNormal = octDecode(unpackUnorm2x16(encoded.b));
    vec4 specularData = unpackUnorm4x8(encoded.a);

    scenePos += normal * 0.03;

    Material mat = getMaterial(specularData, albedo.rgb);

    vec3 reflectedDir = reflect(viewDir, textureNormal);

    vec3 screenPos = sceneToScreenPos(scenePos);

    if (mat.roughness < 0.25) color = mix(color, getSpecularReflections(screenPos.xy, screenPos.z, scenePos, reflectedDir, dither, lightLevels.y), getSchlickFresnel(mat.f0, dot(reflectedDir, textureNormal)));

    colorRgbe8 = encodeRgbe8(color);
}