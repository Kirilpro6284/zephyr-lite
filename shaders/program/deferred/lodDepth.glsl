#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/sky/atmosphere.glsl"

/* RENDERTARGETS: 11 */
layout (location = 0) out vec4 combinedDepth;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex1, texel, 0).r;

    #ifdef VOXY
        if (depth == 1.0) depth = -texelFetch(vxDepthTexOpaque, texel, 0).r;
    #endif

    combinedDepth = vec4(depth == -1.0 ? 1.0 : depth, 0.0, 0.0, 1.0);
}