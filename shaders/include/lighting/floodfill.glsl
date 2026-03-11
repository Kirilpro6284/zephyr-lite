#ifndef INCLUDE_LIGHTING_FLOODFILL
    #define INCLUDE_LIGHTING_FLOODFILL

    #include "/include/utility/textureSampling.glsl"

    const float blocklightFill = 0.95;
    const float centerWeight = 0.2;

    const vec3[16] tintColors = vec3[16] (
        vec3(0.9, 0.9, 0.9), // White
        vec3(1.0, 0.6, 0.2), // Orange
        vec3(1.0, 0.5, 0.9), // Magenta
        vec3(0.7, 0.8, 1.0), // Light blue
        vec3(1.0, 0.9, 0.2), // Yellow
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
        vec3(0.1, 0.1, 0.1)  // Black
    );

    const vec3[32] lightColors = vec3[32] (
        vec3(0.95, 0.9, 1.0), // Sea lantern
        vec3(1.0, 0.72, 0.6), // Glowstone, ochre froglight, redstone lamp
        vec3(1.0, 0.12, 0.03) * 0.2, // Redstone
        vec3(1.0, 0.65, 0.5), // Torch, campfire, lantern
        vec3(1.0, 0.4, 0.2), // Shroomlight, lava, fire
        vec3(0.15, 0.4, 0.8) * 0.04, // Soul torch, campfire, lantern, fire
        vec3(0.5, 0.7, 0.6), // Copper torch, lantern, verdant froglight
        vec3(0.5, 0.7, 0.6) * 0.5, // Exposed copper lantern
        vec3(0.5, 0.7, 0.6) * 0.25, // Weathered copper lantern
        vec3(0.5, 0.7, 0.6) * 0.125, // Oxidized copper lantern
        vec3(0.7, 0.6, 0.8), // Pearlescent froglight
        vec3(0.8, 0.7, 0.68), // End rod
        vec3(0.7, 0.2, 0.9) * 0.02, // Crying obsidian
        vec3(0.9, 0.3, 0.1) * 0.03, // Magma block
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

        vec3 centerLight = decodeRgbe8(texelFetch(lightSampler, voxelPos + pingpong, 0));
        vec3 gatheredLight = vec3(0.0);

        for (int i = 0; i < 6; i++) {
            ivec3 offset = ivec3(equal(ivec3(i % 3), ivec3(0, 1, 2))) * (i > 2 ? -1 : 1);

            gatheredLight += decodeRgbe8(texelFetch(lightSampler, clamp(voxelPos + offset, ivec3(0), voxelVolumeSize - 1) + pingpong, 0));
        }

        return mix(blocklightFill * gatheredLight * rcp(6.0), centerLight, centerWeight);
    }

    vec3 getBlocklight (vec3 playerPos)
    {   
        #ifdef COLORED_LIGHTING
            ivec3 voxelPos = playerToVoxelPos(playerPos);

            if (!inVoxelBounds(voxelPos)) return vec3(0.0);
            else return textureRgbe8(lightSampler, rcp(vec3(voxelVolumeSize) * vec3(1.0, 1.0, 2.0)) * vec3(clamp(cameraPositionFract + playerPos + halfVoxelVolumeSize, vec3(0.5), vec3(voxelVolumeSize) - 0.5) + ivec3(0, 0, voxelVolumeSize.z * ((frameCounter & 1) ^ 1))), vec3(1.0, 1.0, 2.0) * vec3(voxelVolumeSize));
        #else
            return vec3(0.0);
        #endif
    }

#endif