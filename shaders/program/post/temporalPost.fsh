
#include "/include/main.glsl"

// ----- Outputs -----

/* RENDERTARGETS: 6,10 */
layout (location = 0) out vec4 colorHistory;
layout (location = 1) out vec4 colorRgbe8;

// ----- Includes -----

#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/colorMatrices.glsl"

// ----- Functions -----

void main() {
    ivec2 texel = ivec2(gl_FragCoord.xy);

    colorHistory = texelFetch(colortex6, texel, 0);

    bool disocclusion = false;

#if TEMPORAL_UPSAMPLING == 1
    int radius = 1;
#else
    int radius = 2;
#endif

    for (int x = texel.x - radius; x <= texel.x + radius; x++) {
        for (int y = texel.y - radius; y <= texel.y + radius; y++) {
            if (texelFetch(colortex6, ivec2(x, y), 0).r < 0.0) {
                disocclusion = true;
                break;
            }
        }
    }

    if (disocclusion) {
        colorHistory.rgb = textureRgbe8(colortex7, texelSize * gl_FragCoord.xy, internalScreenSize);
    }

    colorRgbe8 = encodeRgbe8(colorHistory.rgb);
}