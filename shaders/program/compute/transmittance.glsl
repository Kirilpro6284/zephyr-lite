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
const ivec3 workGroups = ivec3(4, 4, 1);

void main ()
{
    vec2 uv = vec2(gl_GlobalInvocationID.xy) * rcp(31.0);

    uv.x = lift(uv.x, -3.0);
    uv.y = lift(uv.y, -16.0);

    float height = planetRadius + clamp(uv.x, 0.005, 0.995) * atmosphereHeight;
    vec3 dir = vec3(0.0, mix(-sqrt(1.0 - sqr(planetRadius / height)), 1.0, uv.y), 0.0);
    dir.x = sqrt(1.0 - dir.y * dir.y);

    float stepSize = rcp(128.0) * raySphere(vec3(0.0, height, 0.0), dir, planetRadius + atmosphereHeight).y;
    vec3 rayPos = vec3(0.0, height, 0.0) + 0.5 * stepSize * dir;

    vec3 opticalDepth = vec3(0.0);

    for (int i = 0; i < 128; i++, rayPos += stepSize * dir) {
        opticalDepth += getDensityAtPoint(rayPos);
    } 

    imageStore(imgScattering, SKY_TRANSMITTANCE_BOTTOM_LEFT + ivec2(gl_GlobalInvocationID.xy), encodeRgbe8(exp(-stepSize * (betaR * opticalDepth.x + betaM * opticalDepth.y + betaO * opticalDepth.z))));
}