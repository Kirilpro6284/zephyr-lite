#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/main.glsl"
#include "/include/post/tonemapping.glsl"
#include "/include/utility/packing.glsl"
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
        
        printVec4(lodProjMat_0);
        printLine();
        printVec4(lodProjMat_1);
        printLine();
        printVec4(lodProjMat_2);
        printLine();
        printVec4(lodProjMat_3);
        printLine(); printLine();

        printLine(); printLine();

        float depth = -8000.0;
        
        printInt(vxRenderDistance); printLine();
        printFloat((lodProjMat_2.z * depth + lodProjMat_3.z) / (lodProjMat_2.w * depth));
    
        endText(color.rgb);
    #endif
}