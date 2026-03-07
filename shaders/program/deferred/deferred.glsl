#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    uvec4 materialData = getMaterialData(texel);

    vec4 albedo = unpackUnorm4x8(materialData.x);
    vec3 normal = octDecode(unpackExp4x8(materialData.y).xy);
    vec4 specularData = unpackUnorm4x8(materialData.w);

    vec3 f0; float roughness; float emission;

    applySpecularMap(specularData, albedo.rgb, f0, roughness, emission);

    float depth = texelFetch(depthtex1, texel, 0).r;

    if (depth == 1.0) return;

    vec3 playerPos = screenToPlayerPos(internalTexelSize * gl_FragCoord.xy, depth).xyz;
    vec2 dither = blueNoise(gl_FragCoord.xy).rg;

    vec3 shadowViewPos = (shadowModelView * vec4(playerPos, 1.0)).xyz;

    float blockerDepth = getBlockerDepth(shadowViewPos, dither);

    color = vec4(evalCookBRDF(shadowDir, -normalize(playerPos), roughness, normal, albedo.rgb, f0) * getShadow(shadowViewPos, normal, dither, blockerDepth) + albedo.rgb * 0.2, 1.0);
}