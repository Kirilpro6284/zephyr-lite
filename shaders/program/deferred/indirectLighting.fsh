
#include "/include/main.glsl"

// ----- Outputs ----- 

/* RENDERTARGETS: 3,12 */
layout (location = 0) out vec4 indirectIrradiance;
layout (location = 1) out uint temporalData;

// ----- Includes -----

#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/rng.glsl"

#include "/include/surface/bsdf.glsl"
#include "/include/surface/material.glsl"

#include "/include/atmospherics/atmosphere.glsl"

#include "/include/lighting/lighting.glsl"

// ----- Functions -----

const float indirectRenderScale = 0.01 * INDIRECT_RENDER_SCALE;

const float depthStrictness = 16.0;
const float normalStrictness = 2.0;

void main () {
    ivec2 texel = ivec2(gl_FragCoord.xy * rcp(indirectRenderScale));

    vec2 coord = rcp(indirectRenderScale) * internalTexelSize * gl_FragCoord.xy;
    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    if (depth == 0.0 || clamp01(coord) != coord) {
        temporalData = 0u;
        indirectIrradiance = vec4(0.0);
        return;
    }

    vec3 directIrradiance = shadowLightBrightness * getAtmosphereTransmittance(shadowDir);

    uvec4 encoded = texelFetch(colortex9, texel, 0);

    vec4 albedo = unpackUnorm4x8(encoded.r);
    vec2 lmcoord = unpackUnorm2x8(encoded.g >> 16u);
    vec2 lightLevels = adjustLightLevels(lmcoord);
    vec3 normal = octDecode(unpackUnorm2x8(encoded.g));
    vec3 textureNormal = octDecode(unpackUnorm2x16(encoded.b));
    vec4 specularData = unpackUnorm4x8(encoded.a);

    Material mat = getMaterial(specularData, albedo.rgb);

    vec3 viewPos = screenToViewPos(coord, depth);
    vec3 viewNormal = mat3(gbufferModelView) * normal;

    vec3 scenePos = viewToScenePos(viewPos);
    vec3 viewDir = normalize(scenePos - gbufferModelViewInverse[3].xyz);
    vec2 dither = R2(frameCounter % 64, texelFetch(noisetex0, ivec2(gl_FragCoord.xy) % 256, 0).rg);

    temporalData = packUnorm2x16(vec2(sqrt(linearizeDepth(depth) * rcp(viewDistance)), packUnorm2x8(octEncode(textureNormal)) * rcp(65535.0)));

#if GTAO_SLICES > 0
    vec4 ambient = getAmbientOcclusion(vec3(coord, depth), viewPos, mat3(gbufferModelView) * textureNormal, dither);
#else
    vec4 ambient = vec4(textureNormal, 1.0);
#endif

    vec3 irradiance = vec3(0.0);

#if SUNLIGHT_GI_SAMPLES > 0
    irradiance += directIrradiance * getBouncedSunlight(mat3(shadowModelView) * scenePos + shadowModelView[3].xyz, textureNormal, dither, lmcoord.y);
#endif

    irradiance += directIrradiance * lightLevels.g * getFakeBouncedSunlight(ambient.xyz);
    irradiance += lightLevels.g * 0.4 * getSkyIrradiance(ambient.xyz);

    vec3 prevViewNormal = mat3(gbufferPreviousModelView) * normal;
    vec3 prevViewPos = mat3(gbufferPreviousModelView) * (scenePos + step(0.08, dot(scenePos, scenePos)) * cameraVelocity) + gbufferPreviousModelView[3].xyz;
    vec2 prevUv = (gbufferProjScalePrev.xy * prevViewPos.xy / -prevViewPos.z + taa_offset_prev) * 0.5 + 0.5;

    if (clamp01(prevUv) == prevUv) {
        vec2 coord = indirectRenderScale * internalScreenSize * min(prevUv, 1.0 - rcp(indirectRenderScale) * internalTexelSize) - 0.5;

        ivec2 sampleTexel = ivec2(coord);

        vec4 irradiancePrevious = vec4(0.0);
        float depthPrevious = 0.0;
        float weights = 0.0;

        coord = -fract(coord);

        for (int x = 0; x <= 1; x++) {
            for (int y = 0; y <= 1; y++) {
                vec2 geometrySample = unpackUnorm2x16(texelFetch(colortex12, sampleTexel + ivec2(x, y), 0).r);

                vec3 sampleViewPos = viewDistance * geometrySample.r * geometrySample.r * vec3(gbufferProjScalePrevInv.xy * (rcp(indirectRenderScale) * internalTexelSize * (2 * sampleTexel + 2 * ivec2(x, y) + 1) - 1.0 - taa_offset_prev), -1.0);
                vec3 sampleNormal = octDecode(unpackUnorm2x8(uint(geometrySample.g * 65535.0 + 0.5)));

                float geometryDiff = depthStrictness * abs(dot(sampleViewPos - prevViewPos, prevViewNormal)) + normalStrictness * acosSafe(dot(sampleNormal, textureNormal));

                float sampleWeight = bilinearWeight(coord, vec2(x, y)) * max(0.001, exp(-geometryDiff));

                irradiancePrevious += sampleWeight * texelFetch(colortex3, sampleTexel + ivec2(x, y), 0);
                depthPrevious += sampleWeight * geometryDiff;
                weights += sampleWeight;
            }
        }

        weights = rcpSafe(weights);

        irradiancePrevious *= weights;
        depthPrevious *= weights;

        if (any(isnan(irradiancePrevious))) irradiancePrevious = vec4(0.0, 0.0, 0.0, 1.0);

        float alpha = (1.0 - rcp(INDIRECT_HISTORY_LIMIT)) * step0(-prevViewPos.z) * worldTimeErf * exp(-depthPrevious);

        indirectIrradiance = mix(vec4(irradiance, ambient.a), irradiancePrevious, alpha);
    } else indirectIrradiance = vec4(irradiance, ambient.a);
}