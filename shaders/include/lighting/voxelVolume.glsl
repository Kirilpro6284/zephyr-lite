#if !defined INCLUDE_LIGHTING_VOXELVOLUME
#define INCLUDE_LIGHTING_VOXELVOLUME

#include "/include/utility/textureSampling.glsl"
#include "/include/utility/colorMatrices.glsl"

const vec3 defaultColor = vec3(1.0, 0.55, 0.3) * 0.4 * rgbToAp1;

const float blocklightFill = 1.0;
const float centerWeight = 0.2;

const ivec3 voxelVolumeSize = ivec3(2 * VOXEL_DISTANCE);
const ivec3 halfVoxelVolumeSize = ivec3(VOXEL_DISTANCE);

const vec3[16] tintColors = vec3[16] (
    vec3(0.9, 0.9, 0.9) * rgbToAp1Unlit, // White
    vec3(1.0, 0.6, 0.2) * rgbToAp1Unlit, // Orange
    vec3(1.0, 0.5, 0.9) * rgbToAp1Unlit, // Magenta
    vec3(0.7, 0.8, 1.0) * rgbToAp1Unlit, // Light blue
    vec3(1.0, 0.9, 0.2) * rgbToAp1Unlit, // Yellow
    vec3(0.6, 1.0, 0.5) * rgbToAp1Unlit, // Lime
    vec3(1.0, 0.5, 0.4) * rgbToAp1Unlit, // Pink
    vec3(0.4, 0.4, 0.4) * rgbToAp1Unlit, // Gray
    vec3(0.7, 0.7, 0.7) * rgbToAp1Unlit, // Light gray
    vec3(0.5, 0.9, 1.0) * rgbToAp1Unlit, // Cyan
    vec3(0.9, 0.4, 1.0) * rgbToAp1Unlit, // Purple
    vec3(0.3, 0.4, 1.0) * rgbToAp1Unlit, // Blue
    vec3(1.0, 0.5, 0.3) * rgbToAp1Unlit, // Brown
    vec3(0.3, 0.5, 0.1) * rgbToAp1Unlit, // Green
    vec3(1.0, 0.2, 0.1) * rgbToAp1Unlit, // Red
    vec3(0.1, 0.1, 0.1) * rgbToAp1Unlit  // Black
);

const vec3[32] lightColors = vec3[32] (
    vec3(0.93, 0.88, 1.0) * rgbToAp1, // Sea lantern
    vec3(1.0, 0.72, 0.6) * rgbToAp1, // Glowstone, ochre froglight, redstone lamp
    vec3(1.0, 0.07, 0.03) * 0.2 * rgbToAp1, // Redstone
    vec3(1.0, 0.65, 0.5) * rgbToAp1, // Torch, campfire, lantern
    vec3(1.0, 0.4, 0.2) * rgbToAp1, // Shroomlight, lava, fire
    vec3(0.15, 0.4, 0.8) * 0.04 * rgbToAp1, // Soul torch, campfire, lantern, fire
    vec3(0.5, 0.7, 0.6) * rgbToAp1, // Copper torch, lantern, verdant froglight
    vec3(0.5, 0.7, 0.6) * 0.5 * rgbToAp1, // Exposed copper lantern
    vec3(0.5, 0.7, 0.6) * 0.25 * rgbToAp1, // Weathered copper lantern
    vec3(0.5, 0.7, 0.6) * 0.125 * rgbToAp1, // Oxidized copper lantern
    vec3(0.7, 0.6, 0.8) * rgbToAp1, // Pearlescent froglight
    vec3(0.8, 0.7, 0.68) * rgbToAp1, // End rod
    vec3(0.7, 0.2, 0.9) * 0.02 * rgbToAp1, // Crying obsidian
    vec3(0.9, 0.3, 0.1) * 0.03 * rgbToAp1, // Magma block
    vec3(0.9, 0.3, 0.1) * rgbToAp1, // Copper bulb
    vec3(0.9, 0.3, 0.1) * 0.5 * rgbToAp1, // Exposed copper bulb
    vec3(0.9, 0.3, 0.1) * 0.25 * rgbToAp1, // Weathered copper bulb
    vec3(0.9, 0.3, 0.1) * 0.125 * rgbToAp1, // Oxidized copper bulb
    vec3(0.5, 0.7, 1.0) * 0.02 * rgbToAp1, // Glow lichen
    vec3(0.8, 0.35, 1.0) * 0.5 * rgbToAp1, // Amethyst cluster
    vec3(0.8, 0.35, 1.0) * 0.25 * rgbToAp1, // Large amethyst bud
    vec3(0.8, 0.35, 1.0) * 0.125 * rgbToAp1, // Medium amethyst bud
    vec3(0.8, 0.35, 1.0) * 0.0625 * rgbToAp1, // Small amethyst bud
    vec3(0.9, 0.3, 0.1) * 0.1 * rgbToAp1, // Brewing stand
    vec3(0.75, 0.9, 1.0) * rgbToAp1, // Beacon
    vec3(0.18, 0.04, 0.4) * rgbToAp1, // Nether portal
    vec3(0.0),
    vec3(0.0),
    vec3(0.0),
    vec3(0.0),
    vec3(0.0),
    vec3(0.0)
);

ivec3 sceneToVoxelPos(vec3 scenePos) {
    return ivec3(floor(cameraPositionFract + scenePos)) + halfVoxelVolumeSize;
}

bool inVoxelBounds(ivec3 voxelPos) {
    return clamp(voxelPos, ivec3(0), voxelVolumeSize - 1) == voxelPos;
}
#ifdef COLORED_LIGHTING
    vec4 getVoxelData(ivec3 voxelPos) {
        uint voxelData = texelFetch(voxelSampler, voxelPos, 0).r;

        if (voxelData == 0u || (voxelData > 1u && voxelData < 6u)) return vec4(1.0, 1.0, 1.0, 0.0);
        else if (voxelData > 15u && voxelData < 32u) return vec4(clamp01(tintColors[voxelData % 16]), 0.0);
        else if (voxelData > 31u && voxelData < 64u) return vec4(lightColors[voxelData % 32], 1.0);
        else return vec4(0.0);
    }

    vec3 spreadLight(ivec3 voxelPos) {
        int framemod2 = frameCounter % 2;

        vec3 centerLight = decodeRgbe8(texelFetch(lightSampler, ivec3(voxelPos.xy, voxelPos.z + voxelVolumeSize.z * framemod2), 0));
        vec3 gatheredLight = vec3(0.0);

        for (int i = 0; i < 6; i++) {
            ivec3 samplePos = voxelPos + ivec3(equal(ivec3(i % 3), ivec3(0, 1, 2))) * (i > 2 ? -1 : 1);

            gatheredLight += float(inVoxelBounds(samplePos)) * decodeRgbe8(texelFetch(lightSampler, samplePos + ivec3(0, 0, voxelVolumeSize.z * framemod2), 0));
        }

        return mix(blocklightFill * gatheredLight * rcp(6.0), centerLight, centerWeight);
    }

    vec3 getBlocklight(vec3 scenePos) {   
        ivec3 voxelPos = sceneToVoxelPos(scenePos);

        if (!inVoxelBounds(voxelPos)) return vec3(0.0);
        else {
            scenePos += cameraPositionFract + halfVoxelVolumeSize;
            scenePos = clamp(scenePos, vec3(0.5), voxelVolumeSize - 0.5);

            return textureRgbe8(lightSampler, rcp(vec3(voxelVolumeSize.xy, voxelVolumeSize.z * 2.0)) * vec3(scenePos.xy, scenePos.z + voxelVolumeSize.z * ((frameCounter & 1) ^ 1)), vec3(voxelVolumeSize.xy, voxelVolumeSize.z * 2.0));
        }
    }
#endif

#endif // INCLUDE_LIGHTING_VOXELVOLUME