#if !defined INCLUDE_SURFACE_WATERVOLUME
#define INCLUDE_SURFACE_WATERVOLUME

#include "/include/utility/rng.glsl"
#include "/include/surface/bsdf.glsl"

Material waterMaterial = Material(
    vec3(eps),
    0.0,
    vec3(0.04),
    vec3(0.0),
    0.0
);

const vec3 waterExtinction = 2.0 * vec3(0.21, 0.10, 0.07);

const float waveFrequency = 0.7;
const float waveSpeed = 1.8;
const float waveHeight = 0.3;
const float waveTurbulence = 1.5;

float hash(vec2 uv) {
    ivec2 texel = ivec2(uv);

    float result = 0.0;

    for (int x = 0; x <= 1; x++) {
        for (int y = 0; y <= 1; y++) {
            ivec2 sampleCoord = (texel + ivec2(x, y)) & 65535;

            uint state = uint(sampleCoord.x) + 65536u * uint(sampleCoord.y);

            result += randomValue(state) * smoothstep01(1.0 - abs(uv.x - floor(uv.x + x))) * smoothstep01(1.0 - abs(uv.y - floor(uv.y + y)));
        }
    }

    return result;
}

float fbm(vec2 coord) {
    float result = 0.0;

    for (int i = 0; i < 3; i++) {
        result += exp2(-float(i)) * hash(coord * waveFrequency * exp2(float(i) * 0.7));
    }
    
    return result * 0.5;
}

float getWaveHeight(vec3 worldPos) {
    vec3 uv = vec3(worldPos.xz + vec2(0.3, 0.4) * worldPos.y, mod(frameTimeCounter * waveSpeed, 4096.0));

    float f1 = fbm(mat3x2(0.5, 0.6, 0.2, -0.9, 0.5, 0.6) * uv);
    float f2 = fbm(mat3x2(0.3, 0.8, -0.6, 0.9, -1.0, 0.1) * uv);

    return exp(-2.0 * (f1 + f2));
}

vec3 getWaveNormal(vec3 worldPos) {
    vec3 offsetPos = vec3(worldPos.x + waveTurbulence * rcpSafe(waveFrequency) * getWaveHeight(worldPos), worldPos.yz);

    float centerHeight = getWaveHeight(offsetPos);

    float dfdx = getWaveHeight(vec3(offsetPos.x + 0.005, offsetPos.yz));
    float dfdz = getWaveHeight(vec3(offsetPos.xy, offsetPos.z + 0.005));

    return normalize(vec3(rcp(0.005) * (vec2(dfdx, dfdz) - centerHeight), rcpSafe(waveHeight)));
}

vec3 getWaterFog(vec3 color, vec3 directIrradiance, float dist, float mu) {
    return color * exp(-waterExtinction * dist) + directIrradiance * (eyeBrightnessSmooth.y / 240.0) * kleinNishinaPhase(mu, 100.0) * (1.0 - exp(-0.04 * dist)) * exp(-waterExtinction * 4.0);
}

#endif // INCLUDE_SURFACE_WATERVOLUME