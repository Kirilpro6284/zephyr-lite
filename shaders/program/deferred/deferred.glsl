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

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    color.a = 1.0;

    uvec4 materialData = getMaterialData(texel);

    vec4 normalData = unpackExp4x8(materialData.y);

    vec4 albedo = unpackUnorm4x8(materialData.x);
    vec3 geoNormal = octDecode(normalData.xy);
    vec3 textureNormal = octDecode(unpackExp2x16(materialData.z));
    vec4 specularData = unpackUnorm4x8(materialData.w);

    uint blockId = uint(albedo.a * 255.0 + 0.5);

    albedo.rgb = pow(albedo.rgb, vec3(2.2));

    vec3 f0; float roughness; float emission;

    applySpecularMap(specularData, albedo.rgb, f0, roughness, emission);

    float depth = texelFetch(colortex11, texel, 0).r;

    vec3 playerPos = screenToPlayerPos(internalTexelSize * gl_FragCoord.xy, depth).xyz;

    if (depth == 1.0) {
        color.rgb = EXPONENT_BIAS * getAtmosphereScattering(normalize(playerPos));
        return;
    }
    
    vec2 dither = blueNoise(gl_FragCoord.xy).rg;

    color = vec4(EXPONENT_BIAS * getSceneLighting(
        playerPos, 
        dither, 
        roughness, 
        blockId == 4 ? 1.0 : 0.0,
        geoNormal, 
        textureNormal, 
        albedo.rgb, 
        f0, 
        adjustLightLevels(normalData.zw)
    ), 1.0);
}