#include "/include/uniforms.glsl"
#include "/include/main.glsl"
#include "/include/config.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    uvec4 materialData = getMaterialData(texel);

    color = vec4(unpackUnorm4x8(materialData.x).rgb, 1.0);
}