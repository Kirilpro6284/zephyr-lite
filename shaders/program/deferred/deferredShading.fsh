
#include "/include/main.glsl"

// ----- Outputs -----

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

// ----- Includes -----

#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/rng.glsl"

#include "/include/surface/bsdf.glsl"
#include "/include/surface/material.glsl"

#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/lighting.glsl"

#include "/include/atmospherics/atmosphere.glsl"

// ----- Functions -----

const float indirectRenderScale = 0.01 * INDIRECT_RENDER_SCALE;

const float depthStrictness = 8.0;
const float normalStrictness = 16.0;

void main () {
    ivec2 texel = ivec2(gl_FragCoord.xy);
    vec2 coord = internalTexelSize * gl_FragCoord.xy;

    if (clamp01(coord) != coord) {
        color = vec4(0.0);
        return;
    }

    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    vec3 viewPos = screenToViewPos(coord, depth);
    vec3 scenePos = viewToScenePos(viewPos);
    vec3 viewDir = normalize(scenePos - gbufferModelViewInverse[3].xyz);

    if (depth == 0.0) {
        color = encodeRgbe8(pow(decodeRgbe8(texelFetch(colortex10, texel, 0)), vec3(2.2)) * rgbToAp1 + getAtmosphereScattering(viewDir));
        return;
    }

    uvec4 encoded = texelFetch(colortex9, texel, 0);

    vec4 albedo = unpackUnorm4x8(encoded.r);
    vec3 normal = octDecode(unpackUnorm2x8(encoded.g));
    vec3 textureNormal = octDecode(unpackUnorm2x16(encoded.b));
    vec4 specularData = unpackUnorm4x8(encoded.a);
    vec2 lmcoord = unpackUnorm2x8(encoded.g >> 16u);
    vec2 lightLevels = adjustLightLevels(lmcoord);

    vec3 viewNormal = mat3(gbufferModelView) * normal;

    Material mat = getMaterial(specularData, albedo.rgb);

#ifdef INDIRECT_LIGHTING
    vec2 viewCoord = indirectRenderScale * gl_FragCoord.xy - 0.5;
    ivec2 sampleTexel = ivec2(viewCoord);

    vec4 indirectIrradiance = vec4(0.0);
    float weights = 0.0;

    viewCoord = -fract(viewCoord);

    for (int x = 0; x <= 1; x++) {
        for (int y = 0; y <= 1; y++) {
            vec2 geometrySample = unpackUnorm2x16(texelFetch(colortex12, sampleTexel + ivec2(x, y), 0).r);

            vec3 sampleViewPos = viewDistance * geometrySample.r * geometrySample.r * vec3(gbufferProjScalePrevInv.xy * (rcp(indirectRenderScale) * internalTexelSize * (2 * sampleTexel + 1) - 1.0 - taa_offset_prev), -1.0);
            vec3 sampleNormal = octDecode(unpackUnorm2x8(uint(geometrySample.g * 65535.0 + 0.5)));

            float sampleWeight = bilinearWeight(viewCoord, vec2(x, y)) * max(0.001, exp(-(depthStrictness * abs(dot(sampleViewPos - viewPos, viewNormal)) + normalStrictness * acosSafe(dot(sampleNormal, textureNormal)))));

            indirectIrradiance += sampleWeight * texelFetch(colortex1, sampleTexel + ivec2(x, y), 0);
            weights += sampleWeight;
        }
    }

    indirectIrradiance *= rcpSafe(weights);
#else
    vec4 indirectIrradiance = vec4(lightLevels.g * 0.4 * getSkyIrradiance(textureNormal), 1.0);
#endif

    color = encodeRgbe8(getSceneLighting(
        scenePos,
        viewDir,
        mat,
        indirectIrradiance.rgb,
        normal,
        textureNormal,
        lightLevels,
        smoothstep(0.2, 0.4, lmcoord.y),
        getInterleavedGradientNoise(gl_FragCoord.xy),
        indirectIrradiance.a
    ));
}