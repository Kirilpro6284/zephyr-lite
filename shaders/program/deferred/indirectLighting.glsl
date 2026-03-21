#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/bsdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/lighting/lighting.glsl"
#include "/include/surface/material.glsl"

/* RENDERTARGETS: 3,12 */
layout (location = 0) out vec4 indirectIrradiance;
layout (location = 1) out vec4 temporalDepth;

void main () {
    ivec2 texel = ivec2(gl_FragCoord.xy * rcp(indirectRenderScale));

    vec2 uv = rcp(indirectRenderScale) * internalTexelSize * gl_FragCoord.xy;
    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    if (depth == 0.0 || saturate(uv) != uv) {
        temporalDepth = vec4(65504.0, 0.0, 0.0, 1.0);
        indirectIrradiance = vec4(0.0);
        return;
    }

    uvec4 materialData = getMaterialData(texel);

    vec4 normalData = unpackExp4x8(materialData.y);

    vec4 albedo = unpackUnorm4x8(materialData.x);
    vec2 lightLevels = adjustLightLevels(normalData.zw);
    vec3 geoNormal = octDecode(normalData.xy);
    vec3 textureNormal = octDecode(unpackExp2x16(materialData.z));
    vec4 specularData = unpackUnorm4x8(materialData.w);

    Material mat = applySpecularMap(specularData, pow(albedo.rgb, vec3(2.2)) * rgbToAp1Unlit);

    vec3 viewPos = screenToViewPos(uv, depth);
    vec3 viewNormal = mat3(gbufferModelView) * geoNormal;

    // Equivalent to vec2(dFdx(rcp(viewPos.z)), dFdy(rcp(viewPos.z)))
    vec2 depthDiff = -2.0 * vec2(lodProjMatInv_0.x, lodProjMatInv_1.y) * internalTexelSize * viewNormal.xy / dot(viewPos, viewNormal);

    viewPos += viewPos * (rcp(1.0 - viewPos.z * dot(depthDiff, vec2(texel) + 0.5 - gl_FragCoord.xy * rcp(indirectRenderScale))) - 1.0);

    vec3 playerPos = viewToPlayerPos(viewPos);
    vec3 viewDir = normalize(playerPos - gbufferModelViewInverse[3].xyz);
    vec2 dither = getBlueNoise(gl_FragCoord.xy).rg;

    temporalDepth = vec4(rcp(-viewPos.z), 0.0, 0.0, 1.0);

    vec4 ao = getAmbientOcclusion(vec3(uv, depth), viewPos, mat3(gbufferModelView) * textureNormal, dither);
    vec3 radiance =  getBouncedSunlight(mat3(shadowModelView) * playerPos + shadowModelView[3].xyz, textureNormal, dither);
         radiance += lightLevels.y * getFakeBouncedSunlight(ao.xyz);
         radiance *= shadowLightBrightness * getAtmosphereTransmittance(shadowDir);
         radiance += lightLevels.y * 0.4 * getSkyIrradiance(ao.xyz);

    vec4 prevPos = lodProjMatPrev0 * gbufferPreviousModelView * vec4(playerPos + step(0.08, dot(playerPos, playerPos)) * cameraVelocity, 1.0);
         prevPos.xyz /= prevPos.w;
    
    vec2 prevUv = (prevPos.xy + taa_offset_prev) * 0.5 + 0.5;

    if (saturate(prevUv) == prevUv) {
        const float depthStrictness = 30.0;

        vec2 coord = indirectRenderScale * internalScreenSize * min(prevUv, 1.0 - rcp(indirectRenderScale) * internalTexelSize) - 0.5;

        ivec2 sampleTexel = ivec2(coord);

        vec4 prevData = vec4(0.0);
        float prevDepth = 0.0;
        float weights = 0.0;

        coord = -fract(coord);

        for (int i = 0; i < 4; i++) {
            ivec2 offset = ivec2(i >> 1, i & 1);

            float sampleDepth = texelFetch(colortex12, sampleTexel + offset, 0).r + rcp(indirectRenderScale) * dot(depthDiff, coord + vec2(offset));
            float sampleWeight = bilinearWeight(coord, vec2(offset)) * max(0.00001, exp(-depthStrictness * abs(prevPos.w - rcp(sampleDepth))));

            prevData += sampleWeight * texelFetch(colortex3, sampleTexel + offset, 0);
            prevDepth += sampleWeight * sampleDepth;
            weights += sampleWeight;
        }

        weights = rcp(max(0.00001, weights));

        prevData *= weights;
        prevDepth *= weights;

        float alpha =  1.0 - INDIRECT_TEMPORAL_BLEND_WEIGHT;
              alpha *= float(!any(isnan(prevData)));
              alpha *= step(0.0, prevPos.w);
              alpha *= worldTimeErf;
              alpha *= exp(-depthStrictness * abs(prevPos.w - rcp(prevDepth)));

        indirectIrradiance = mix(vec4(radiance, ao.w), prevData, alpha);
    } else indirectIrradiance = vec4(radiance, ao.w);
}