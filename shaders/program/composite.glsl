#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    vec3 currData = texelFetch(colortex7, texel, 0).rgb;
    vec4 translucentData = texelFetch(colortex1, texel, 0);
    
    color = vec4(mix(currData, translucentData.rgb, translucentData.a), 1.0);
}