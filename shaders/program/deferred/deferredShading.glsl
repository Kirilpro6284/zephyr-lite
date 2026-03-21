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

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main () {
    ivec2 texel = ivec2(gl_FragCoord.xy);

    color.a = 1.0;

    uvec4 materialData = getMaterialData(texel);

    vec4 normalData = unpackExp4x8(materialData.y);

    vec4 albedo = unpackUnorm4x8(materialData.x);
    vec3 geoNormal = octDecode(normalData.xy);
    vec3 textureNormal = octDecode(unpackExp2x16(materialData.z));
    vec4 specularData = unpackUnorm4x8(materialData.w);
    vec2 lightLevels = adjustLightLevels(normalData.zw);

    Material mat = applySpecularMap(specularData, pow(albedo.rgb, vec3(2.2)) * rgbToAp1Unlit);

    vec2 uv = internalTexelSize * gl_FragCoord.xy;
    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    vec3 viewPos = screenToViewPos(uv, depth);
    vec3 playerPos = viewToPlayerPos(viewPos);
    vec3 viewDir = normalize(playerPos - gbufferModelViewInverse[3].xyz);

    if (depth == 0.0) {
        color = encodeRgbe8(pow(decodeRgbe8(texelFetch(colortex10, texel, 0)), vec3(2.2)) * rgbToAp1 + getAtmosphereScattering(viewDir));
        return;
    }

    #ifdef INDIRECT_LIGHTING
        vec2 coord = indirectRenderScale * gl_FragCoord.xy - 0.5;

        ivec2 sampleTexel = ivec2(coord);

        vec4 indirectIrradiance = vec4(0.0);
        float weights = 0.0;

        coord = -fract(coord);

        for (int i = 0; i < 4; i++) {
            ivec2 offset = ivec2(i >> 1, i & 1);

            float sampleDepth = rcp(texelFetch(colortex12, sampleTexel + offset, 0).r);
            float sampleWeight = bilinearWeight(coord, vec2(offset)) * max(0.001, exp(-20.0 * abs(sampleDepth + viewPos.z)));

            indirectIrradiance += sampleWeight * texelFetch(colortex3, sampleTexel + offset, 0);
            weights += sampleWeight;
        }

        indirectIrradiance /= max(0.001, weights);
    #else
        vec4 indirectIrradiance = vec4(lightLevels.y * 0.4 * getSkyIrradiance(textureNormal), 1.0);
    #endif

    color = encodeRgbe8(getSceneLighting(
        playerPos,
        viewDir,
        mat,
        indirectIrradiance.rgb,
        geoNormal,
        textureNormal,
        lightLevels,
        smoothstep(0.2, 0.4, normalData.w),
        getInterleavedGradientNoise(gl_FragCoord.xy),
        indirectIrradiance.w
    ));


   // vec3 viewNormal = mat3(gbufferModelView) * geoNormal;

   // color = encodeRgbe8(vec3(uv.x < 0.5 ? (vec2(dFdx(rcp(viewPos.z)), dFdy(rcp(viewPos.z)))) : (-2.0 * vec2(lodProjMatInv_0.x, lodProjMatInv_1.y) * internalTexelSize * viewNormal.xy / dot(viewPos, viewNormal)), 0.0));

}