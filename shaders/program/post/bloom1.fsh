
#include "/include/main.glsl"

// ----- Outputs -----

/* RENDERTARGETS: 5 */
layout (location = 0) out vec4 color;

// ----- Includes -----

#include "/include/post/bloom.glsl"

// ----- Functions -----

/*
    const bool colortex5MipmapEnabled = true;
*/

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(1920.0, 1080.0);
    uint tileIndex = getBloomTileIndex(uv);

    color = vec4(textureLod(colortex5, getBloomCoord(uv, tileIndex), tileIndex).rgb, 1.0);
}