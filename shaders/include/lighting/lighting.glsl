#if !defined INCLUDE_LIGHTING
#define INCLUDE_LIGHTING

#include "/include/lighting/floodfill.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/raymarching.glsl"
#include "/include/surface/material.glsl"

vec3 getSubsurfaceScattering (vec3 albedo, float sssAmount, float mu, float sssDepth) {
    if (sssAmount < 0.001) return vec3(0.0);

    vec3 coeff = -SSS_ABSORPTION * exp(-2.0 * albedo) / sssAmount;

    vec3 s1 = 3.5 * exp(3.0 * coeff * sssDepth) * schlickPhase(mu, 0.5);
    vec3 s2 = 4.0 * sqrt(albedo) * inversesqrt(dot(vec3(0.333), albedo)) * exp(0.5 * coeff * sssDepth) * mix(schlickPhase(mu, 0.3), schlickPhase(-mu, 0.1), 0.3);

    return SSS_INTENSITY * TWO_PI * albedo * sssAmount * (s1 + s2);
}

float getMaxHorizonAngle (vec2 sliceDir, vec2 screenPos, vec3 viewPos, vec3 viewDir, vec2 stepSize, float dither) {
    vec2 stepDir = stepSize * sliceDir.xy;
    vec2 stepPos = screenPos + stepDir * dither;
    
    float maxTheta = -1.0;

    for (int i = 0; i < GTAO_HORIZON_STEPS; i++, stepPos += stepDir) {
        float sampleDepth = texelFetch(lodDepthTex1, ivec2(internalScreenSize * stepPos), 0).r;

        vec3 sampleVec = projectAndDivide(lodProjMatInv0, vec3(stepPos.xy * 2.0 - 1.0, sampleDepth)) - viewPos;
        float lengthSqu = dot(sampleVec, sampleVec);

        float cosTheta = dot(sampleVec, viewDir) * inversesqrt(lengthSqu);
              cosTheta = mix(cosTheta, -1.0, saturate(lengthSqu - 1.5));

        maxTheta = max(maxTheta, cosTheta);
    }

    return acos(clamp(maxTheta, -1.0, 1.0));
}

vec4 getAmbientOcclusion (vec3 screenPos, vec3 viewPos, vec3 viewNormal, vec2 dither) {
    vec3 viewDir = normalize(-viewPos);
    vec2 stepSize = vec2(lodProjMat_0.x, lodProjMat_1.y) * GTAO_RADIUS * rcp(-GTAO_HORIZON_STEPS * viewPos.z);

    vec3 sliceDir = vec3(cos(TWO_PI * dither.x), sin(TWO_PI * dither.x), 0.0);
    vec4 integratedData = vec4(0.0);

    for (int i = 0; i < GTAO_SLICES; i++) {
        sliceDir.xy *= vogelPhase;

        vec3 tangent = sliceDir - dot(sliceDir, viewDir) * viewDir;
		vec3 axis = cross(sliceDir, viewDir);
		vec3 projNormal = viewNormal - axis * dot(viewNormal, axis);

		float cosGamma = saturate(dot(viewDir, projNormal) * inversesqrt(dot(projNormal, projNormal)));
		float gamma = sign(dot(tangent, projNormal)) * acos(cosGamma);

        vec2 horizonAngles = vec2(
            getMaxHorizonAngle(-sliceDir.xy, screenPos.xy, viewPos, viewDir, stepSize, dither.y),
            getMaxHorizonAngle( sliceDir.xy, screenPos.xy, viewPos, viewDir, stepSize, dither.y)
        );

        horizonAngles = gamma + clamp(vec2(-1.0, 1.0) * horizonAngles - gamma, -HALF_PI, HALF_PI);

        float bentAngle = 0.5 * (horizonAngles.x + horizonAngles.y);

        integratedData.xyz += projNormal * cos(bentAngle) + tangent * sin(bentAngle);
        integratedData.w   += dot(vec2(0.25), cosGamma + 2.0 * horizonAngles * sin(gamma) - cos(2.0 * horizonAngles - gamma));
    }

    const float aoIntensity = 0.8;

    return vec4(normalize(mat3(gbufferModelViewInverse) * integratedData.xyz), mix(1.0, integratedData.w * rcp(float(GTAO_SLICES)), aoIntensity));
}

vec3 getBouncedSunlight (vec3 shadowViewPos, vec3 bentNormal, vec2 dither) {
    vec3 shadowViewNormal = mat3(shadowModelView) * bentNormal;
    vec2 shadowClipPos = shadowProjScale.xy * shadowViewPos.xy;

    vec2 sampleState = shadowProjScale.x * SUNLIGHT_GI_RANGE * vec2(cos(dither.x * TWO_PI), sin(dither.x * TWO_PI));
    vec3 integratedData = vec3(0.0);

    for (int i = 0; i < SUNLIGHT_GI_SAMPLES; i++) {
        float sampleDist = fract(0.4301597 * i + dither.y);
        sampleState *= vogelPhase;

        vec2 sampleClipPos = shadowClipPos + sampleDist * sampleState;
        ivec2 sampleTexel = ivec2(float(shadowMapResolution) * (distortShadowPos(sampleClipPos) * 0.5 + 0.5));

        vec3 sampleViewVec = shadowProjScaleInv * vec3(sampleClipPos, texelFetch(shadowtex1, sampleTexel, 0).r * 2.0 - 1.0) - shadowViewPos;

        float sqrLength = dot(sampleViewVec, sampleViewVec);
        float invLength = inversesqrt(max(0.01, sqrLength));

        if (invLength > rcp(SUNLIGHT_GI_RANGE)) {
            vec3 radiance =  sampleDist * texelFetch(shadowcolor0, sampleTexel, 0).rgb;
                 radiance *= smoothstep(-SUNLIGHT_GI_RANGE, -0.75 * SUNLIGHT_GI_RANGE, -sqrLength * invLength);
                 radiance *= max0(dot(shadowViewNormal, sampleViewVec));
                 radiance *= max0(-dot(octDecode(texelFetch(shadowcolor1, sampleTexel, 0).rg), sampleViewVec));
                 radiance *= sqr(invLength * invLength);

            integratedData += radiance;
        }
    }

    return 2.0 * SUNLIGHT_GI_RANGE * SUNLIGHT_GI_RANGE * rcp(SUNLIGHT_GI_SAMPLES) * integratedData;
}

vec3 getFakeBouncedSunlight (vec3 bentNormal) {
    const vec3 albedo = vec3(0.005) * rgbToAp1Unlit;
    
    return albedo * (saturate(0.5 - bentNormal.x * shadowDir.x) + saturate(0.5 - bentNormal.y * shadowDir.y) + saturate(0.5 - bentNormal.z * shadowDir.z));
}

vec3 getSpecularReflections (vec3 screenPos, vec3 playerPos, vec3 reflectedDir, float dither, float skylight) {
    vec3 rayEnd = playerToScreenPos(playerPos + near * reflectedDir);
    vec3 rayDir = clipAABB(screenPos, rayEnd - screenPos, vec3(0.0, 0.0, -2.0), vec3(1.0, 1.0, 0.25));

    bool hit = traceScreenSpaceRay(screenPos, rayDir, max(0.01, dither));

    if (!hit) return smoothstep(0.8, 1.0, skylight) * getAtmosphereScattering(reflectedDir);
    else return textureRgbe8(colortex7, screenPos.xy, internalScreenSize);
}

vec2 adjustLightLevels (vec2 lightLevels) {
    lightLevels.y = 1.0 - pow(1.0 - lightLevels.y, 1.5);
    lightLevels.y = pow(lightLevels.y, 5.0);

    return lightLevels;
}

vec3 getSceneLighting (
    vec3 playerPos,
    vec3 viewDir,
    Material mat,
    vec3 indirectIrradiance,
    vec3 geoNormal,
    vec3 textureNormal,
    vec2 lightLevels,
    float dither,
    float ao
) {
    vec3 shadowViewPos = mat3(shadowModelView) * playerPos + shadowModelView[3].xyz;

    #ifdef SHADOW_VPS
        float blockerDepth = getBlockerDepth(shadowViewPos, dither);
    #endif

    vec3 transmittance = shadowLightBrightness * vec3(1.0, 0.94, 0.85) * getTransmittance(shadowDir);

    vec3 radiance = mat.albedo * (mat.emission + ao * (indirectIrradiance + getBlocklight(playerPos + textureNormal * 0.5)));

    radiance += transmittance * evalCookBRDF(shadowDir, -viewDir, mat.roughness, textureNormal, mat.albedo, mat.f0) * getShadow(shadowViewPos, geoNormal, dither
        #ifdef SHADOW_VPS
            , blockerDepth
        #endif
    );

    radiance += transmittance * getSubsurfaceScattering(mat.albedo, mat.sssAmount, dot(viewDir, shadowDir), blockerDepth);

    return radiance;
}

#endif // INCLUDE_LIGHTING