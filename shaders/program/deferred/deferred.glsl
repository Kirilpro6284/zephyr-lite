#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/lighting/floodfill.glsl"
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

    Material mat = applySpecularMap(specularData, pow(albedo.rgb, vec3(2.2)));

    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    vec3 playerPos = screenToPlayerPos(internalTexelSize * gl_FragCoord.xy, depth).xyz;

    if (depth == 0.0) {
        color = encodeRgbe8(pow(decodeRgbe8(texelFetch(colortex10, texel, 0)), vec3(2.2)) + getAtmosphereScattering(normalize(playerPos)));
        return;
    }
    
    float dither = getInterleavedGradientNoise(gl_FragCoord.xy);

    color = encodeRgbe8(mat.albedo * EMISSION_BRIGHTNESS * mat.emission + getSceneLighting(
        playerPos,
        normalize(playerPos - gbufferModelViewInverse[3].xyz),
        dither, 
        mat.roughness, 
        mat.sssAmount,
        geoNormal, 
        textureNormal, 
        mat.albedo, 
        mat.f0, 
        adjustLightLevels(normalData.zw)
    ));
}