#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/packing.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    vec3 currData = decodeRgbe8(texelFetch(colortex7, texel, 0));
    vec4 translucentData = texelFetch(colortex1, texel, 0);
    
    color = encodeRgbe8(mix(currData, translucentData.rgb, translucentData.a));
}