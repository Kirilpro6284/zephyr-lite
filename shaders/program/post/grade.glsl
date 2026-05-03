#include "/include/main.glsl"
#include "/include/utility/packing.glsl"
#include "/include/post/bloom.glsl"
#include "/include/utility/colorMatrices.glsl"

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 color;

const vec3 rodResponse = vec3(0.014, 0.270, 0.716) * rgbToAp1Unlit;
const vec3 purkinjeTint = vec3(0.4, 0.65, 1.0) * rgbToAp1Unlit;

vec3 getPurkinjeShift (vec3 color)
{
    float purkinje = dot(color, rodResponse);

    return mix(color, purkinjeTint * purkinje, exp(-rcp(PURKINJE_AMOUNT) * 1500.0 * purkinje));
}

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);
    vec2 uv = texelSize * gl_FragCoord.xy;

    vec3 currData = decodeRgbe8(texelFetch(colortex10, texel, 0));

    currData += getBloom(uv);

    #ifdef PURKINJE_EFFECT    
        currData = getPurkinjeShift(currData).rgb;
    #endif

    color = encodeRgbe8(currData);
}