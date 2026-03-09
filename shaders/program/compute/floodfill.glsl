#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/floodfill.glsl"

layout (local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(16, 16, 128);

void main ()
{
    ivec3 voxel = ivec3(gl_GlobalInvocationID.xyz);

    vec4 voxelData = getVoxelData(voxel);

    vec3 light = mix(voxelData.rgb * spreadLight(voxel + cameraPositionInt - previousCameraPositionInt), voxelData.rgb, voxelData.a);

    imageStore(lightBuffer, voxel + ivec3(0, 0, voxelVolumeSize.z * ((frameCounter & 1) ^ 1)), vec4(light, 1.0));
}