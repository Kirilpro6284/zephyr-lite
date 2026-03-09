#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"

/*
    const bool colortex10MipmapEnabled = true;
*/

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 color;

const vec3 rodResponse = vec3(0.014, 0.270, 0.716);
const vec3 purkinjeTint = vec3(1.0, 1.625, 2.5);

vec3 getPurkinjeShift (vec3 color)
{
    float purkinje = dot(color, rodResponse);

    return mix(color, purkinjeTint * purkinje, exp(-rcp(PURKINJE_AMOUNT) * 3000.0 * purkinje));
}

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    vec3 currData = rcp(EXPONENT_BIAS) * texelFetch(colortex10, texel, 0).rgb;

    if (texel == ivec2(0)) renderState.averageLuminance = mix(renderState.averageLuminance, clamp(luminance(rcp(EXPONENT_BIAS) * textureLod(colortex10, vec2(0.5), 16.0).rgb), 0.002, 0.02), 0.02);

    #ifdef PURKINJE_EFFECT    
        currData = getPurkinjeShift(currData).rgb;
    #endif

    color = vec4(EXPONENT_BIAS * currData, 1.0);
}