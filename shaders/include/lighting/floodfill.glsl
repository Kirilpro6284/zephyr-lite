#ifndef INCLUDE_LIGHTING_FLOODFILL
    #define INCLUDE_LIGHTING_FLOODFILL

    const float blocklightFill = 0.95;
    const float centerWeight = 0.2;

    const vec3[16] tintColors = vec3[16] (
        vec3(0.9, 0.9, 0.9), // White
        vec3(1.0, 0.8, 0.4), // Orange
        vec3(1.0, 0.5, 0.9), // Magenta
        vec3(0.7, 0.8, 1.0), // Light blue
        vec3(1.0, 0.9, 0.5), // Yellow
        vec3(0.6, 1.0, 0.5), // Lime
        vec3(1.0, 0.5, 0.4), // Pink
        vec3(0.4, 0.4, 0.4), // Gray
        vec3(0.7, 0.7, 0.7), // Light gray
        vec3(0.5, 0.9, 1.0), // Cyan
        vec3(0.9, 0.4, 1.0), // Purple
        vec3(0.3, 0.4, 1.0), // Blue
        vec3(1.0, 0.5, 0.3), // Brown
        vec3(0.3, 0.5, 0.1), // Green
        vec3(1.0, 0.2, 0.1), // Red
        vec3(0.1, 0.1, 0.1) // Black
    );

    const vec3[32] lightColors = vec3[32] (
        vec3(0.95, 0.9, 1.0), // Sea lantern
        vec3(1.0, 0.72, 0.6), // Glowstone, ochre froglight
        vec3(1.0, 0.12, 0.03) * 0.2, // Redstone
        vec3(1.0, 0.65, 0.5), // Torch, campfire, lantern
        vec3(1.0, 0.4, 0.2), // Shroomlight, lava
        vec3(0.15, 0.4, 0.8) * 0.04, // Soul torch, campfire, lantern
        vec3(0.5, 0.7, 0.6), // Copper torch, lantern, verdant froglight
        vec3(0.5, 0.7, 0.6) * 0.5, // Exposed copper lantern
        vec3(0.5, 0.7, 0.6) * 0.25, // Weathered copper lantern
        vec3(0.5, 0.7, 0.6) * 0.125, // Oxidized copper lantern
        vec3(0.7, 0.6, 0.8), // Pearlescent froglight
        vec3(0.8, 0.7, 0.68), // End rod
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0),
        vec3(0.0)
    );

    ivec3 playerToVoxelPos (vec3 playerPos) {
        return ivec3(floor(cameraPositionFract + playerPos)) + halfVoxelVolumeSize;
    }

    bool inVoxelBounds (ivec3 voxelPos) {
        return clamp(voxelPos, ivec3(0), voxelVolumeSize - 1) == voxelPos;
    }

    vec4 getVoxelData (ivec3 voxelPos) {
        uint voxelData = texelFetch(voxelSampler, voxelPos, 0).r;

        if (voxelData == 0u) return vec4(1.0, 1.0, 1.0, 0.0);
        else if (voxelData > 15u && voxelData < 32u) return vec4(tintColors[voxelData & 15u], 0.0);
        else if (voxelData > 31u && voxelData < 64u) return vec4(lightColors[voxelData & 31u], 1.0);
        else return vec4(0.0);
    }

    vec3 spreadLight (ivec3 voxelPos) {
        ivec3 pingpong = ivec3(0, 0, voxelVolumeSize.z * (frameCounter & 1));

        vec3 centerLight = texelFetch(lightSampler, voxelPos + pingpong, 0).rgb;
        vec3 gatheredLight = vec3(0.0);

        for (int i = 0; i < 6; i++) {
            ivec3 offset = ivec3(equal(ivec3(i % 3), ivec3(0, 1, 2))) * (i > 2 ? -1 : 1);

            gatheredLight += texelFetch(lightSampler, clamp(voxelPos + offset, ivec3(0), voxelVolumeSize - 1) + pingpong, 0).rgb;
        }

        return mix(blocklightFill * gatheredLight * rcp(6.0), centerLight, centerWeight);
    }

    vec3 getLighting (vec3 playerPos)
    {
        ivec3 voxelPos = playerToVoxelPos(playerPos);

        if (!inVoxelBounds(voxelPos)) return vec3(0.0);
        else return texture(lightSampler, rcp(vec3(128.0, 128.0, 256.0)) * vec3(cameraPositionFract + playerPos + halfVoxelVolumeSize + ivec3(0, 0, voxelVolumeSize.z * ((frameCounter & 1) ^ 1)))).rgb;
    }

#endif