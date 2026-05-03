#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/bsdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/floodfill.glsl"

layout (local_size_x = 8, local_size_y = 8) in;

#if VOXELIZATION_DISTANCE == 64
    const ivec3 workGroups = ivec3(16, 16, 128);
#elif VOXELIZATION_DISTANCE == 128
    const ivec3 workGroups = ivec3(32, 32, 256);
#elif VOXELIZATION_DISTANCE == 192
    const ivec3 workGroups = ivec3(48, 48, 384);
#elif VOXELIZATION_DISTANCE == 256
    const ivec3 workGroups = ivec3(64, 64, 512);
#endif

void main ()
{
    ivec3 voxel = ivec3(gl_GlobalInvocationID.xyz);

    vec4 voxelData = getVoxelData(voxel);

    vec3 light = mix(voxelData.rgb * spreadLight(clamp(voxel + cameraPositionInt - previousCameraPositionInt, ivec3(0), voxelVolumeSize - 1)), voxelData.rgb, voxelData.a);

    imageStore(lightBuffer, voxel + ivec3(0, 0, voxelVolumeSize.z * ((frameCounter & 1) ^ 1)), encodeRgbe8(light));
}