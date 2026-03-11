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
const ivec3 workGroups = ivec3(16, 16, 1);

void main ()
{
    vec2 uv = vec2(gl_GlobalInvocationID.xy) * rcp(127.0);

    vec3 rayDir; 
    
    rayDir.y = lift(max(uv.y, 0.0001) * 2.0 - 1.0, -2.0);

    float w = lift(uv.x * 2.0 - 1.0, 0.5) * HALF_PI + HALF_PI;

    rayDir.xz = vec2(cos(w), sin(w));
    rayDir.xz = sqrt(1.0 - rayDir.y * rayDir.y) * normalize(vec2(rayDir.x * sunDir.x - rayDir.z * sunDir.z, rayDir.x * sunDir.z + rayDir.z * sunDir.x));
    
    vec3 currPos = vec3(0.0, planetRadius + eyeAltitude + ALTITUDE_BIAS, 0.0);

    vec3 integratedData = evalScattering(currPos, rayDir, sunDir) + NIGHT_BRIGHTNESS * evalScattering(currPos, rayDir, moonDir);

    imageStore(imgScattering, SKY_VIEW_BOTTOM_LEFT + ivec2(gl_GlobalInvocationID.xy), encodeRgbe8(integratedData));
}