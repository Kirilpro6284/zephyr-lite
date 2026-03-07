#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/lighting/shadowMapping.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    uvec4 materialData = getMaterialData(texel);

    vec4 albedo = unpackUnorm4x8(materialData.x);
    vec3 normal = octDecode(unpackExp4x8(materialData.y).xy);

    float depth = texelFetch(depthtex1, texel, 0).r;

    if (depth == 1.0) return;

    vec3 playerPos = screenToPlayerPos(internalTexelSize * gl_FragCoord.xy, depth).xyz;
    vec2 dither = blueNoise(gl_FragCoord.xy).rg;

    color = vec4(albedo.rgb * getShadow(playerPos, normal, dither), 1.0);
}