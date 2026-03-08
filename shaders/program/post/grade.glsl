#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"

/* RENDERTARGETS: 1 */
layout (location = 0) out vec4 color;

vec3 getPurkinjeShift (vec3 color)
{
    float purkinje = dot(color, vec3(0.027, 0.523, 1.386));

    return mix(color, vec3(0.4, 0.65, 1.2) * purkinje, exp(-rcp(PURKINJE_AMOUNT) * 4000.0 * purkinje));
}

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    #ifdef PURKINJE_EFFECT    
        color = vec4(getPurkinjeShift(texelFetch(colortex1, texel, 0).rgb), 1.0);
    #else
        color = texelFetch(colortex1, texel, 0);
    #endif
}