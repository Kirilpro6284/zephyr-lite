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

    Material mat = applySpecularMap(specularData, pow(albedo.rgb, vec3(2.2)) * rgbToAp1Unlit);

    vec2 uv = internalTexelSize * gl_FragCoord.xy;
    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    vec3 playerPos = screenToPlayerPos(uv, depth).xyz;

    if (depth == 0.0) {
        color = encodeRgbe8(pow(decodeRgbe8(texelFetch(colortex10, texel, 0)), vec3(2.2)) * rgbToAp1 + getAtmosphereScattering(normalize(playerPos)));
        return;
    }

    vec3 viewDir = normalize(playerPos - gbufferModelViewInverse[3].xyz);
    vec4 indirectIrradiance = texelFetch(colortex3, texel, 0);

    color = encodeRgbe8(getSceneLighting(
        playerPos,
        viewDir,
        mat,
        indirectIrradiance.rgb,
        geoNormal,
        textureNormal,
        adjustLightLevels(normalData.zw),
        getInterleavedGradientNoise(gl_FragCoord.xy),
        indirectIrradiance.w
    ));
}