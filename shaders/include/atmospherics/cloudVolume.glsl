#if !defined INCLUDE_ATMOSPHERICS_CLOUDVOLUME
#define INCLUDE_ATMOSPHERICS_CLOUDVOLUME

#include "/include/utility/geometry.glsl"

#include "/include/surface/bsdf.glsl"

#include "/include/atmospherics/atmosphere.glsl"

const float cloudAltitude = 1200.0;
const float cloudHeight = 600.0;

const float coverage = 0.4;

const vec2 windDirection0 = 40.0 * vec2(cos(0.3 * PI), sin(0.3 * PI));
const vec2 windDirection1 = 25.0 * vec2(cos(0.9 * PI), sin(0.9 * PI));

const float maxRayLength = 7500.0;

float getCloudVolumeDensity(vec3 worldPos) {
    float density = texture(noisetex0, fract((worldPos.xz + worldAge * windDirection0) * 0.00002)).b - (1.0 - coverage);

    if (density < 0.0) return density;

    float height = length(worldPos) - planetRadius;

    density *= smoothstep(cloudAltitude, cloudAltitude + cloudHeight * 0.4, height);

    density *= 1.0 - smoothstep(cloudAltitude + cloudHeight * 0.5, cloudAltitude + cloudHeight, height);

    worldPos.xz += worldAge * windDirection1;

    density += 0.12 * (texture(noisetex1, fract(worldPos * 0.002)).r - 1.0);
    density += 0.16 * (texture(noisetex1, fract(worldPos * 0.0008)).r - 1.0);
    density += 0.064 * (texture(noisetex1, fract(worldPos * 0.008)).r - 1.0);

    return 0.25 * density;
}

float getCloudVolumeTransmittance(vec3 rayPos, vec3 lightDir, float dither) {
    vec2 dists;
    
    raySphere(rayPos, lightDir, planetRadius + cloudAltitude + cloudHeight, dists);

    lightDir *= min(dists.y, 500.0) * rcp(CLOUDS_LIGHT_SCATTER_POINTS);
    rayPos += lightDir * dither;

    float stepSize = length(lightDir);
    float opticalDepth = 0.0;

    for (int i = 0; i < CLOUDS_LIGHT_SCATTER_POINTS; i++, rayPos += lightDir) {
        opticalDepth += stepSize * clamp01(getCloudVolumeDensity(rayPos));
    }

    return exp(-opticalDepth) + 0.2 * exp(-0.2 * opticalDepth);
}

vec4 raymarchCloudVolume(vec3 scenePos, vec3 rayDir, float terrainDist, float dither) {
    vec3 rayPos = scenePos + vec3(0.0, planetRadius + eyeAltitude * rcp(CLOUDS_SCALE), 0.0);

    vec4 dists;

    bool hit0 = raySphere(rayPos, rayDir, planetRadius + cloudAltitude, dists.xy);
    bool hit1 = raySphere(rayPos, rayDir, planetRadius + cloudAltitude + cloudHeight, dists.zw);

    if (!hit1) return vec4(0.0, 0.0, 1.0, 0.0);

    float sqrLength = lengthSquared(rayPos);

    terrainDist *= rcp(CLOUDS_SCALE);

    if (sqrLength < (planetRadius + cloudAltitude) * (planetRadius + cloudAltitude)) {
        if (terrainDist < dists.y || dists.y > 100000.0) return vec4(0.0, 0.0, 1.0, 0.0);

        scenePos += rayDir * dists.y;
        rayDir *= min(terrainDist, dists.w) - dists.y;
    } else if (sqrLength < (planetRadius + cloudAltitude + cloudHeight) * (planetRadius + cloudAltitude + cloudHeight)) {
        rayDir *= min(terrainDist, hit0 ? dists.x : dists.w);
    } else {
        if (terrainDist < dists.z) return vec4(0.0, 0.0, 1.0, 0.0);

        scenePos += rayDir * dists.z;
        rayDir *= min(terrainDist, hit0 ? dists.x : dists.w) - dists.z;
    }

    scenePos.xz += cameraPosition.xz * rcp(CLOUDS_SCALE);
    
    rayDir *= rcp(CLOUDS_VIEW_SCATTER_POINTS);
    rayPos = scenePos + rayDir * dither;

    float stepSize = length(rayDir);

    if (stepSize * CLOUDS_VIEW_SCATTER_POINTS > maxRayLength) {
        rayDir *= maxRayLength * rcp(stepSize * CLOUDS_VIEW_SCATTER_POINTS);
        stepSize = maxRayLength * rcp(CLOUDS_VIEW_SCATTER_POINTS);
    }

    float cosTheta = dot(rayDir, shadowDir) / stepSize;
    float directPhase = kleinNishinaPhase(cosTheta, 3600.0) + kleinNishinaPhase(cosTheta, 40.0) + 2.0 * schlickPhase(-cosTheta, 0.1);

    vec3 scattering = vec3(0.0, 0.0, 1.0);

    float distance = 0.0;
    float weights = 0.0;

    for (int i = 0; i < CLOUDS_VIEW_SCATTER_POINTS; i++, rayPos += rayDir) {
        vec3 offsetPos = rayPos + vec3(0.0, planetRadius + eyeAltitude * rcp(CLOUDS_SCALE), 0.0);

        float density = stepSize * getCloudVolumeDensity(offsetPos);

        if (density < eps) continue;

        float stepTransmittance = scattering.b * exp(-density);

        scattering.r += stepTransmittance * density * getCloudVolumeTransmittance(offsetPos, shadowDir, dither);
        scattering.g += stepTransmittance * density * exp(-density * density);
        scattering.b = stepTransmittance;

        float distanceWeight = stepTransmittance * density;

        distance += distanceWeight * stepSize * (i + dither);
        weights += distanceWeight;

        if (stepTransmittance < 0.05) {
            break;
        }
    }

    return vec4(scattering.r * directPhase, scattering.g, scattering.b, weights > eps ? distance / weights : 1e6);
}

#endif // INCLUDE_ATMOSPHERICS_CLOUDVOLUME