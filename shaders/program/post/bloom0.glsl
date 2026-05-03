#include "/include/main.glsl"
#include "/include/utility/textureSampling.glsl"

/* RENDERTARGETS: 5 */
layout (location = 0) out vec4 color;

void main ()
{
    color = vec4(textureRgbe8(colortex10, gl_FragCoord.xy / vec2(1920.0, 1080.0), screenSize), 1.0);
}