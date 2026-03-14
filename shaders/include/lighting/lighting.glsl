#if !defined INCLUDE_LIGHTING
#define INCLUDE_LIGHTING

#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/raymarching.glsl"

vec3 getSubsurfaceScattering (vec3 albedo, float sssAmount, float mu, float sssDepth) {
    if (sssAmount < 0.001) return vec3(0.0);

    vec3 coeff = -SSS_ABSORPTION * exp(-2.0 * albedo) / sssAmount;

    vec3 s1 = 3.5 * exp(3.0 * coeff * sssDepth) * schlickPhase(mu, 0.5);
    vec3 s2 = 4.0 * sqrt(albedo) * inversesqrt(dot(vec3(0.333), albedo)) * exp(0.5 * coeff * sssDepth) * mix(schlickPhase(mu, 0.3), schlickPhase(-mu, 0.1), 0.3);

    return getTransmittance(shadowDir) * SSS_INTENSITY * TWO_PI * albedo * sssAmount * (s1 + s2);
}

vec3 getScreenSpaceReflections (vec3 screenPos, vec3 playerPos, vec3 reflectedDir, float dither, float skylight) {
    vec3 rayEnd = playerToScreenPos(playerPos + near * reflectedDir);
    vec3 rayDir = clipAABB(screenPos, rayEnd - screenPos, vec3(0.0, 0.0, -2.0), vec3(1.0, 1.0, 0.25));

    bool hit = traceScreenSpaceRay(screenPos, rayDir, max(0.01, dither));

    if (!hit) return smoothstep(0.8, 1.0, skylight) * getAtmosphereScattering(reflectedDir);
    else return textureRgbe8(colortex7, screenPos.xy, internalScreenSize);
}

vec2 adjustLightLevels (vec2 lightLevels) {
    lightLevels.y = 2.0 * lightLevels.y - lightLevels.y * lightLevels.y;
    lightLevels.y = pow(lightLevels.y, 8.0);

    return lightLevels;
}

vec3 getSceneLighting (
    vec3 playerPos,
    vec3 viewDir,
    float dither,
    float roughness, 
    float sssAmount,
    vec3 geoNormal,
    vec3 textureNormal, 
    vec3 albedo, 
    vec3 f0,
    vec2 lightLevels
) {
    vec3 shadowViewPos = (shadowModelView * vec4(playerPos, 1.0)).xyz;

    #ifdef SHADOW_VPS
        float blockerDepth = getBlockerDepth(shadowViewPos, dither);
    #endif

    vec3 lighting = vec3(0.0);

    float shadowLightBrightness = (sunDir.y < 0.0 ? NIGHT_BRIGHTNESS : 1.0);

    lighting += shadowLightBrightness * getTransmittance(shadowDir) * evalCookBRDF(shadowDir, -viewDir, roughness, textureNormal, albedo.rgb, f0) * getShadow(shadowViewPos, geoNormal, dither
        #ifdef SHADOW_VPS
            , blockerDepth
        #endif
    );

    lighting += lightLevels.y * albedo.rgb * getAtmosphereScattering(vec3(0.0, 1.0, 0.0));
    lighting += shadowLightBrightness * getSubsurfaceScattering(albedo.rgb, sssAmount, dot(viewDir, shadowDir), blockerDepth);
    lighting += albedo.rgb * getBlocklight(playerPos + geoNormal * 0.5);

    return lighting;
}

#endif // INCLUDE_LIGHTING