#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/lighting/lighting.glsl"
#include "/include/surface/material.glsl"

/* RENDERTARGETS: 3,12 */
layout (location = 0) out vec4 indirectIrradiance;
layout (location = 1) out vec4 temporalDepth;

void main () {
    ivec2 texel = ivec2(gl_FragCoord.xy);

    uvec4 materialData = getMaterialData(texel);

    vec4 normalData = unpackExp4x8(materialData.y);

    vec4 albedo = unpackUnorm4x8(materialData.x);
    vec2 lightLevels = adjustLightLevels(normalData.zw);
    vec3 textureNormal = octDecode(unpackExp2x16(materialData.z));
    vec4 specularData = unpackUnorm4x8(materialData.w);

    Material mat = applySpecularMap(specularData, pow(albedo.rgb, vec3(2.2)) * rgbToAp1Unlit);

    vec2 uv = internalTexelSize * gl_FragCoord.xy;
    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    if (depth == 0.0) {
        temporalDepth = vec4(65504.0, 0.0, 0.0, 1.0);
        indirectIrradiance = vec4(0.0);
        return;
    }

    vec3 viewPos = screenToViewPos(uv, depth);

    temporalDepth = vec4(-viewPos.z, 0.0, 0.0, 1.0);

    vec3 playerPos = viewToPlayerPos(viewPos);
    vec3 viewDir = normalize(playerPos - gbufferModelViewInverse[3].xyz);
    vec2 dither = getBlueNoise(gl_FragCoord.xy).rg;

    vec4 ao = getAmbientOcclusion(vec3(uv, depth), viewPos, mat3(gbufferModelView) * textureNormal, dither);
    vec3 radiance =  getBouncedSunlight(mat3(shadowModelView) * playerPos + shadowModelView[3].xyz, ao.xyz, dither);
         radiance += lightLevels.y * getFakeBouncedSunlight(ao.xyz);
         radiance *= shadowLightBrightness * vec3(1.0, 0.94, 0.85) * getTransmittance(shadowDir);
         radiance += lightLevels.y * getSkyIrradiance(ao.xyz);

    vec4 prevPos = lodProjMatPrev0 * gbufferPreviousModelView * vec4(playerPos + cameraVelocity, 1.0);
         prevPos.xyz /= prevPos.w;

    vec2 prevUv = (prevPos.xy + taa_offset_prev) * 0.5 + 0.5;

    if (saturate(prevUv) == prevUv) {
        vec4 prevData = texture(colortex3, prevUv);
        float prevDepth = texture(colortex12, prevUv).r;
    
        float alpha =  1.0 - INDIRECT_TEMPORAL_BLEND_WEIGHT;
              alpha *= float(!any(isnan(prevData)));
              alpha *= step(0.0, prevPos.w);
              alpha *= exp(-16.0 * abs(prevPos.w - prevDepth));

        indirectIrradiance = mix(vec4(radiance, ao.w), prevData, alpha);
    } else indirectIrradiance = vec4(radiance, ao.w);
}