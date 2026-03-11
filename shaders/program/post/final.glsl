#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/main.glsl"
#include "/include/post/tonemapping.glsl"
#include "/include/utility/packing.glsl"

//#define ENABLE_TEXT_RENDERING

#include "/include/text/text.glsl"

layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    color.rgb = decodeRgbe8(texelFetch(colortex10, texel, 0));
    color.a = 1.0;

    #ifdef DYNAMIC_EXPOSURE
        float exposure = 0.1 / renderState.averageLuminance;
    #else
        float exposure = MANUAL_EXPOSURE;
    #endif

    color.rgb = tonemap(color.rgb, exposure) + getBlueNoise(gl_FragCoord.xy) * rcp(255.0) - rcp(510.0);

    //color.rgb = hideGUI ? vec3(texelSize * gl_FragCoord.xy, playerLookVector.y * 0.5 + 0.5) : texture(depthtex2, mix(vec3(0.5 / 48.0), vec3(47.5 / 48.0), vec3(texelSize * gl_FragCoord.xy, playerLookVector.y * 0.5 + 0.5))).rgb;

    #ifdef ENABLE_TEXT_RENDERING
        #define FONT_SIZE 2 // [1 2 3 4 5 6 7 8]
        
        beginText(ivec2(gl_FragCoord.xy / FONT_SIZE), ivec2(20, screenSize.y / FONT_SIZE - 20));
        text.fgCol = vec4(vec3(1.0), 1.0);
        text.bgCol = vec4(vec3(0.0), 0.0);
        
        printVec3(decodeRgbe8(rcp(255.0) * floor(0.5 + 255.0 * encodeRgbe8(vec3(3.0, 0.5, 0.1)))));
        
        endText(color.rgb);
    #endif
}