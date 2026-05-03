#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/colorMatrices.glsl"

/* RENDERTARGETS: 1 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    color = vec4(log(0.003 + luminance(texelFetch(colortex6, texel, 0).rgb)), 0.0, 0.0, 1.0);
}