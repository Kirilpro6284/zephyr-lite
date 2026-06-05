
#include "/include/main.glsl"
#include "/include/constants.glsl"

// ----- Outputs -----

layout (location = 0) out vec4 color;

// ----- Includes -----

#include "/include/utility/colorMatrices.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/rng.glsl"

#include "/include/atmospherics/atmosphere.glsl"

#include "/include/post/tonemapping.glsl"
#include "/include/post/bloom.glsl"

#include "/include/text/text.glsl"

// ----- Functions -----

void main() {
    ivec2 texel = ivec2(gl_FragCoord.xy);

    //color.rgb = octDecode(texelFetch(colortex8, texel, 0).rg) * 0.5 + 0.5;

    color.rgb = decodeRgbe8(texelFetch(colortex10, texel, 0));
    color.a = 1.0;

    #ifdef DYNAMIC_EXPOSURE
        float exposure = 1.0 / texelFetch(colortex6, ivec2(0), 0).a;
    #else
        float exposure = MANUAL_EXPOSURE;
    #endif

    color.rgb = pow(tonemap(color.rgb * exposure) * ap1ToRgb, vec3(1.0 / 2.2)) + R1(frameCounter % 64, texelFetch(noisetex0, ivec2(gl_FragCoord.xy) % 256, 0).r) * rcp(255.0) - rcp(510.0);

    #ifdef ENABLE_TEXT_RENDERING
        #define FONT_SIZE 2 // [1 2 3 4 5 6 7 8]
        
        beginText(ivec2(gl_FragCoord.xy / FONT_SIZE), ivec2(20, screenSize.y / FONT_SIZE - 20));
        text.fgCol = vec4(vec3(1.0), 1.0);
        text.bgCol = vec4(vec3(0.0), 0.0);
        
        printVec3(decodeRgbe8(vec4(0.7, 0.8, 0.91, 130.0 / 255.0)));

        printLine();

        printFloat(viewDistance);

        endText(color.rgb);
    #endif
}