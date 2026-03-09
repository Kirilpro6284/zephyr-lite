#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/main.glsl"
#include "/include/post/tonemapping.glsl"

//#define ENABLE_TEXT_RENDERING

#ifdef ENABLE_TEXT_RENDERING
    #include "/include/text/text.glsl"
#endif

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

    #ifdef ENABLE_TEXT_RENDERING
        #define FONT_SIZE 2 // [1 2 3 4 5 6 7 8]
        
        beginText(ivec2(gl_FragCoord.xy / FONT_SIZE), ivec2(20, screenSize.y / FONT_SIZE - 20));
        text.fgCol = vec4(vec3(1.0), 1.0);
        text.bgCol = vec4(vec3(0.0), 0.0);
        
        printFloat(exp(-1.0 / frameTime));
        
        endText(color.rgb);
    #endif
}