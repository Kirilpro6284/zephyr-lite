#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/sky/atmosphere.glsl"

layout (local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(8, 8, 1);

shared vec3 skyIrradiance[8][8];

#define SKY_IRRADIANCE_SAMPLES 16

void main ()
{
    vec2 uv = vec2(gl_WorkGroupID.xy) * rcp(7.0);
    uint state = gl_LocalInvocationID.x + 64 * gl_LocalInvocationID.y;

    vec3 rayDir = octDecode(uv);
    vec3 irradiance = vec3(0.0);
    
    for (int i = 0; i < SKY_IRRADIANCE_SAMPLES; i++) {
        irradiance += getAtmosphereScattering(normalize(rayDir + randomDir(state)));
    }

    irradiance *= rcp(SKY_IRRADIANCE_SAMPLES);

    skyIrradiance[gl_LocalInvocationID.x][gl_LocalInvocationID.y] = irradiance;

    barrier();

    if (gl_LocalInvocationID.x < 4 && gl_LocalInvocationID.y < 4) {
        irradiance = 0.25 * (
            skyIrradiance[gl_LocalInvocationID.x * 2    ][gl_LocalInvocationID.y * 2    ] +
            skyIrradiance[gl_LocalInvocationID.x * 2 + 1][gl_LocalInvocationID.y * 2    ] +
            skyIrradiance[gl_LocalInvocationID.x * 2    ][gl_LocalInvocationID.y * 2 + 1] +
            skyIrradiance[gl_LocalInvocationID.x * 2 + 1][gl_LocalInvocationID.y * 2 + 1]
        );
    }

    barrier();

    if (gl_LocalInvocationID.x < 4 && gl_LocalInvocationID.y < 4) {
        skyIrradiance[gl_LocalInvocationID.x][gl_LocalInvocationID.y] = irradiance;
    }

    barrier();

    if (gl_LocalInvocationID.x < 2 && gl_LocalInvocationID.y < 2) {
        irradiance = 0.25 * (
            skyIrradiance[gl_LocalInvocationID.x * 2    ][gl_LocalInvocationID.y * 2    ] +
            skyIrradiance[gl_LocalInvocationID.x * 2 + 1][gl_LocalInvocationID.y * 2    ] +
            skyIrradiance[gl_LocalInvocationID.x * 2    ][gl_LocalInvocationID.y * 2 + 1] +
            skyIrradiance[gl_LocalInvocationID.x * 2 + 1][gl_LocalInvocationID.y * 2 + 1]
        );
    }

    barrier();

    if (gl_LocalInvocationID.x < 2 && gl_LocalInvocationID.y < 2) {
        skyIrradiance[gl_LocalInvocationID.x][gl_LocalInvocationID.y] = irradiance;
    }

    barrier();

    if (gl_LocalInvocationID.xy == uvec2(0u)) {
        irradiance = 0.25 * (
            skyIrradiance[0][0] +
            skyIrradiance[1][0] +
            skyIrradiance[0][1] +
            skyIrradiance[1][1]
        );

        imageStore(imgScattering, SKY_IRRADIANCE_BOTTOM_LEFT + ivec2(gl_WorkGroupID.xy), encodeRgbe8(irradiance));
    }
}