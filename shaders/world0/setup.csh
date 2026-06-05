#version 430 compatibility

#include "/include/main.glsl"

layout (local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(8, 8, 64);

// ----- Outputs -----

layout (r8) uniform image3D noiseimg1;

// ----- Includes -----

#include "/include/utility/rng.glsl"

// ----- Functions -----

float worley(vec3 uv, int octave) {
    vec3 coord = uv * octave;
    ivec3 origin = ivec3(floor(coord + 0.5));

    float minDist = 10.0;

    for (int x = origin.x - 2; x < origin.x + 2; x++) {
        for (int y = origin.y - 2; y < origin.y + 2; y++) {
            for (int z = origin.z - 2; z < origin.z + 2; z++) {
                uint state = (x % octave) + octave * (y % octave) + octave * octave * (z % octave) + 25771 * octave;

                minDist = min(minDist, distanceSquared(coord, vec3(x + randomValue(state), y + randomValue(state), z + randomValue(state))));
            }
        }
    }

    return exp(-2.5 * minDist);
}

void main() {
    vec3 uv = (vec3(gl_GlobalInvocationID.xyz) + 0.5) * rcp(64.0);

    float result = 0.0;

    for (int i = 2; i < 7; i++) {
        result += exp2(-i) * worley(uv, 1 << i);
    }

    imageStore(noiseimg1, ivec3(gl_GlobalInvocationID.xyz), vec4(result * 2.0, 0.0, 0.0, 1.0));
}