#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/bsdf.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/lighting/lighting.glsl"
#include "/include/surface/material.glsl"

/* RENDERTARGETS: 1 */
layout (location = 0) out vec4 indirectIrradiance;

const float depthStrictness = 8.0;
const float normalStrictness = 16.0;

float depthWeight (float depth0, float depth1) {
    return depthStrictness * abs(depth0 + depth1);
}

float normalWeight (vec3 n0, vec3 n1) {
    return normalStrictness * clamp01(-0.5 * dot(n0, n1) + 0.5);
}

void main () {
    ivec2 srcTexel = ivec2(gl_FragCoord.xy);
    ivec2 texel = ivec2(gl_FragCoord.xy * rcp(indirectRenderScale));

    vec2 uv = internalTexelSize * (texel + 0.5);
    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    if (depth == 0.0 || clamp01(uv) != uv) {
        indirectIrradiance = vec4(0.0);
        return;
    }

    vec3 viewPos = screenToViewPos(uv, depth);
    vec3 normal = octDecode(unpackExp2x16(texelFetch(colortex9, texel, 0).r));
    
    vec4 filteredData = vec4(0.0);
    float weights = 0.0;

    for (int i = -FILTER_RADIUS; i <= FILTER_RADIUS; i++) {
        #if FILTER_PASS == 0
            ivec2 sampleTexel = srcTexel + ivec2(i, 0);

            float sampleWeight  = rcp(FILTER_RADIUS * 5.0) * i * i;
                  sampleWeight += depthWeight(rcp(texelFetch(colortex12, sampleTexel, 0).r), viewPos.z);
                  sampleWeight += normalWeight(octDecode(unpackExp2x16(texelFetch(colortex9, ivec2(rcp(indirectRenderScale) * (gl_FragCoord.xy + vec2(i, 0))), 0).r)), normal);
                  sampleWeight  = max(0.0001, exp(-sampleWeight));

            weights += sampleWeight;
            filteredData += sampleWeight * texelFetch(colortex3, sampleTexel, 0);
        #else
            ivec2 sampleTexel = srcTexel + ivec2(0, i);

            float sampleWeight  = rcp(FILTER_RADIUS * 5.0) * i * i;
                  sampleWeight += depthWeight(rcp(texelFetch(colortex12, sampleTexel, 0).r), viewPos.z);
                  sampleWeight += normalWeight(octDecode(unpackExp2x16(texelFetch(colortex9, ivec2(rcp(indirectRenderScale) * (gl_FragCoord.xy + vec2(0, i))), 0).r)), normal);
                  sampleWeight  = max(0.0001, exp(-sampleWeight));

            weights += sampleWeight;
            filteredData += sampleWeight * texelFetch(colortex1, sampleTexel, 0);
        #endif
    }

    indirectIrradiance = filteredData * rcp(weights);
}