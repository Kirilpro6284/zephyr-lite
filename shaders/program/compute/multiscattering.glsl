#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"

#define SKY_MS

#include "/include/sky/atmosphere.glsl"

layout (local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(4, 4, 1);

#define MULTIPLE_SCATTERING_SAMPLES 256

void main ()
{
    if (frameCounter > 128) return;

    ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
    uint state = gl_GlobalInvocationID.x + 32u * gl_GlobalInvocationID.y + 32u * 32u * (frameCounter & 127u);

    vec2 uv = vec2(gl_GlobalInvocationID.xy) * rcp(31.0);

    vec3 rayPos = vec3(0.0, planetRadius + atmosphereHeight * clamp(lift(uv.x, -2.0), 0.002, 0.998), 0.0);

    float lightDot = lift(uv.y * 2.0 - 1.0, -1.5);
    vec3 lightDir = vec3(sqrt(1.0 - lightDot * lightDot), lightDot, 0.0);

    vec3 prevData = decodeRgbe8(texelFetch(scattering, SKY_MS_BOTTOM_LEFT + texel, 0));
    vec3 integratedData = vec3(0.0);

    for (int i = 0; i < MULTIPLE_SCATTERING_SAMPLES; i++) {
        integratedData += evalAtmosphereScattering(rayPos, randomDir(state), lightDir);
    }
    
    integratedData *= 4.0 * PI * rcp(MULTIPLE_SCATTERING_SAMPLES);

    if (any(isnan(integratedData))) integratedData = vec3(0.0);

    imageStore(imgScattering, SKY_MS_BOTTOM_LEFT + texel, encodeRgbe8(mix(prevData, integratedData, rcp(frameCounter))));
}