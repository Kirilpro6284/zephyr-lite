
#include "/include/main.glsl"

// ----- Outputs -----

/* RENDERTARGETS: 1 */
layout (location = 0) out vec4 indirectIrradiance;

// ----- Includes -----

#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/encoding.glsl"

#include "/include/surface/bsdf.glsl"
#include "/include/surface/material.glsl"

#include "/include/atmospherics/atmosphere.glsl"

#include "/include/lighting/lighting.glsl"

// ----- Functions -----

const float indirectRenderScale = 0.01 * INDIRECT_RENDER_SCALE;

const float depthStrictness = 8.0;
const float normalStrictness = 16.0;

void main () {
    ivec2 srcTexel = ivec2(gl_FragCoord.xy);
    ivec2 texel = ivec2(gl_FragCoord.xy * rcp(indirectRenderScale));

    vec2 coord = internalTexelSize * (texel + 0.5);
    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    if (depth == 0.0 || clamp01(coord) != coord) {
        indirectIrradiance = vec4(0.0);
        return;
    }

    vec3 viewPos = screenToViewPos(coord, depth);

    uvec4 encoded = texelFetch(colortex9, texel, 0);

    vec3 normal = octDecode(unpackUnorm2x8(encoded.g));
    vec3 textureNormal = octDecode(unpackUnorm2x16(encoded.b));
    
    vec3 viewNormal = mat3(gbufferModelView) * normal;

    vec4 filteredData = vec4(0.0);

    coord[FILTER_PASS] = coord[FILTER_PASS] - FILTER_RADIUS * internalTexelSize[FILTER_PASS];

    for (int i = -FILTER_RADIUS; i <= FILTER_RADIUS; i++, coord[FILTER_PASS] += internalTexelSize[FILTER_PASS]) {
        
        #if FILTER_PASS == 0
            ivec2 sampleTexel = srcTexel + ivec2(i, 0);
        #else
            ivec2 sampleTexel = srcTexel + ivec2(0, i);
        #endif

            vec2 geometrySample = unpackUnorm2x16(texelFetch(colortex12, sampleTexel, 0).r);

            vec3 sampleViewPos = viewDistance * geometrySample.r * geometrySample.r * vec3(gbufferProjScaleInv.xy * (coord * 2.0 - 1.0 - taa_offset_prev), -1.0);
            vec3 sampleNormal = octDecode(unpackUnorm2x8(uint(geometrySample.g * 65535.0 + 0.5)));

            float sampleWeight  = rcp(FILTER_RADIUS * 5.0) * i * i;
                  sampleWeight += depthStrictness * abs(dot(sampleViewPos - viewPos, viewNormal));
                  sampleWeight += normalStrictness * acosSafe(dot(sampleNormal, textureNormal));
                  sampleWeight  = max(eps, exp(-sampleWeight));

            filteredData.a += sampleWeight;

        #if FILTER_PASS == 0
            filteredData.rgb += sampleWeight * texelFetch(colortex3, sampleTexel, 0).rgb;
        #else
            filteredData.rgb += sampleWeight * texelFetch(colortex1, sampleTexel, 0).rgb;
        #endif
    }

#if FILTER_PASS == 0
    indirectIrradiance = filteredData * rcp(filteredData.a);
#else
    indirectIrradiance = vec4(filteredData.rgb * rcp(filteredData.a), texelFetch(colortex3, srcTexel, 0).a);
#endif
}