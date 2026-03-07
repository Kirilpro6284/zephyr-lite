#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"

layout (location = 0) out vec4 color;

void main ()
{
    color = texelFetch(colortex1, ivec2(gl_FragCoord.xy), 0);
}