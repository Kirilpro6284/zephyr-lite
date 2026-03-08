#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/main.glsl"
#include "/include/post/tonemapping.glsl"

layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    color = rcp(EXPONENT_BIAS) * texelFetch(colortex10, texel, 0);

    #ifdef DYNAMIC_EXPOSURE
        float exposure = 0.1 / renderState.averageLuminance;
    #else
        float exposure = MANUAL_EXPOSURE;
    #endif

    color.rgb = tonemap(color.rgb, exposure) + blueNoise(gl_FragCoord.xy) * rcp(255.0) - rcp(510.0);
    color.a = 1.0;
}