#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/main.glsl"
#include "/include/post/tonemapping.glsl"
#include "/include/utility/packing.glsl"
#include "/include/text/text.glsl"
#include "/include/post/bloom.glsl"

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

    color.rgb = pow(tonemap(color.rgb * exposure), vec3(1.0 / 2.2)) + getBlueNoise(gl_FragCoord.xy) * rcp(255.0) - rcp(510.0);

    //color.rgb = hideGUI ? vec3(texelSize * gl_FragCoord.xy, playerLookVector.y * 0.5 + 0.5) : texture(depthtex2, mix(vec3(0.5 / 48.0), vec3(47.5 / 48.0), vec3(texelSize * gl_FragCoord.xy, playerLookVector.y * 0.5 + 0.5))).rgb;

    //color.rgb = texelFetch(colortex5, texel, 0).rgb;

    #ifdef ENABLE_TEXT_RENDERING
        #define FONT_SIZE 2 // [1 2 3 4 5 6 7 8]
        
        beginText(ivec2(gl_FragCoord.xy / FONT_SIZE), ivec2(20, screenSize.y / FONT_SIZE - 20));
        text.fgCol = vec4(vec3(1.0), 1.0);
        text.bgCol = vec4(vec3(0.0), 0.0);
        
        printVec2(internalScreenSize);

        printLine();

        printVec2(vec2(textureSize(colortex7, 0)));

        endText(color.rgb);
    #endif
}