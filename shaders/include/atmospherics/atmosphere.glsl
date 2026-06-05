#if !defined INCLUDE_ATMOSPHERICS_ATMOSPHERE
#define INCLUDE_ATMOSPHERICS_ATMOSPHERE

#include "/include/utility/textureSampling.glsl"
#include "/include/utility/colorMatrices.glsl"

#define ALTITUDE_BIAS 250.0

const float planetRadius = 6371000.0;
const float atmosphereHeight = 100000.0;

const vec3 betaR = pow(vec3(680.0, 530.0, 440.0), vec3(-4.0)) * 1e6 * rgbToAp1Unlit;
const vec3 betaM = 4.0 * vec3(1e-5) * rgbToAp1Unlit;
const vec3 betaO = 0.4 * vec3(1.9, 2.7, 0.1) * 1e-6 * rgbToAp1Unlit;

const vec2 isotropicPhase = vec2(6.0 * rcp(16.0 * PI), rcp(4.0 * PI));

vec3 getAtmosphereScattering(vec3 lightDir, vec3 rayDir) {
    float mu = dot(lightDir, rayDir);

    vec3 uv = vec3(acosSafe(mu), acosSafe(rayDir.y), acosSafe(lightDir.y)) / PI;

    uv.x = sqrt(uv.x);
    uv.yz = sign(uv.yz - 0.5) * sqrt(abs(uv.yz * 2.0 - 1.0)) * 0.5 + 0.5;

    uv.xy = clamp(uv.xy, rcp(256.0), 1.0 - rcp(256.0)) * rcp(8.0);

    uv.z = 64.0 * uv.z - 0.5;

    return mix(
        textureRgbe8(scattering, uv.xy + vec2(int(uv.z) % 8, int(uv.z) / 8) * rcp(8.0), vec2(1024.0)),
        textureRgbe8(scattering, uv.xy + vec2((int(uv.z) + 1) % 8, (int(uv.z) + 1) / 8) * rcp(8.0), vec2(1024.0)),
        fract(uv.z)
    );
}

vec3 getAtmosphereScattering(vec3 rayDir) {
    return getAtmosphereScattering(sunDir, rayDir) + NIGHT_BRIGHTNESS * getAtmosphereScattering(moonDir, rayDir);
}

vec3 getAtmosphereTransmittance(vec3 pos, vec3 rayDir) {
    float sqrLength = dot(pos, pos);
    float invLength = inversesqrt(sqrLength);

    float w = sqrt(1.0 - planetRadius * planetRadius * invLength * invLength);

    vec2 uv = vec2(0.0);

    uv.x = sqrt((sqrLength * invLength - planetRadius) / atmosphereHeight);
    uv.y = sqrt((dot(pos, rayDir) * invLength + w) / (1.0 + w));

    if (clamp01(uv) != uv) return vec3(0.0);

    return textureRgbe8(transmittance, (1.0 - rcp(32.0)) * clamp01(uv) + rcp(64.0), vec2(32.0));
}

vec3 getAtmosphereTransmittance(vec3 rayDir) {
    return getAtmosphereTransmittance(vec3(0.0, planetRadius + ALTITUDE_BIAS, 0.0), rayDir);
}

vec3 getSkyIrradiance(vec3 bentNormal) {
    vec2 uv = (1.0 - rcp(8.0)) * octEncode(bentNormal) + rcp(16.0);

    return SKYLIGHT_TINT * textureRgbe8(skyIrradianceTex, uv, vec2(8.0));
}

#endif // INCLUDE_ATMOSPHERICS_ATMOSPHERE