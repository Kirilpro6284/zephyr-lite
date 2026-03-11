#if !defined INCLUDE_LIGHTING
#define INCLUDE_LIGHTING

vec3 getSubsurfaceScattering (vec3 albedo, float sssAmount, float mu, float sssDepth) {
    if (sssAmount < 0.001) return vec3(0.0);

    vec3 coeff = -SSS_ABSORPTION * exp(-0.75 * normalize(albedo)) / sssAmount;

    vec3 s1 = 0.5 * vec3(0.94, 1.0, 0.76) * (luminance(albedo) + 0.02) * exp(3.0 * coeff * sssDepth + 3.0) * schlickPhase(mu, 0.5);
    vec3 s2 = 8.0 * albedo * albedo * exp(0.5 * coeff * sssDepth + SSS_PHASE * mu);

    return getTransmittance(shadowDir) * SSS_INTENSITY * sssAmount * (s1 + s2);
}

vec2 adjustLightLevels (vec2 lightLevels) {
    lightLevels.y = 2.0 * lightLevels.y - lightLevels.y * lightLevels.y;
    lightLevels.y = pow(lightLevels.y, 8.0);

    return lightLevels;
}

vec3 getSceneLighting (
    vec3 playerPos,
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

    float shadowLightBrightness = sunDir.y < 0.0 ? NIGHT_BRIGHTNESS : 1.0;

    lighting += exp(-sssAmount) * shadowLightBrightness * getTransmittance(shadowDir) * evalCookBRDF(shadowDir, -normalize(playerPos), roughness, textureNormal, albedo.rgb, f0) * getShadow(shadowViewPos, geoNormal, dither
        #ifdef SHADOW_VPS
            , blockerDepth
        #endif
    );

    lighting += lightLevels.y * albedo.rgb * getAtmosphereScattering(vec3(0.0, 1.0, 0.0));
    lighting += shadowLightBrightness * getSubsurfaceScattering(albedo.rgb, sssAmount, dot(normalize(playerPos), shadowDir), blockerDepth);
    lighting += albedo.rgb * getBlocklight(playerPos + geoNormal * 0.5);

    return lighting;
}

#endif // INCLUDE_LIGHTING