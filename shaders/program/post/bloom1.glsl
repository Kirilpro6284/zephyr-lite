#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/main.glsl"
#include "/include/post/bloom.glsl"

/*
    const bool colortex5MipmapEnabled = true;
*/

/* RENDERTARGETS: 5 */
layout (location = 0) out vec4 color;

void main ()
{
    vec2 uv = gl_FragCoord.xy / vec2(1920.0, 1080.0);
    uint tileIndex = getBloomTileIndex(uv);

    color = vec4(textureLod(colortex5, getBloomCoord(uv, tileIndex), tileIndex).rgb, 1.0);
}