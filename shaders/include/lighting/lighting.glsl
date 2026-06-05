#if !defined INCLUDE_LIGHTING_LIGHTING
#define INCLUDE_LIGHTING_LIGHTING

#include "/include/atmospherics/atmosphere.glsl"

#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/voxelVolume.glsl"

#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/raymarching.glsl"

#include "/include/surface/material.glsl"
#include "/include/surface/bsdf.glsl"

vec3 getSubsurfaceScattering(vec3 albedo, float sssAmount, float mu, float sssDepth) {
    if (sssAmount < 0.001) return vec3(0.0);

    vec3 coeff = -SSS_ABSORPTION * exp(-2.0 * albedo) / sssAmount;

    vec3 s1 = 3.5 * exp(3.0 * coeff * sssDepth) * schlickPhase(mu, 0.5);
    vec3 s2 = 4.0 * sqrt(albedo) * inversesqrt(dot(vec3(0.333), albedo)) * exp(0.5 * coeff * sssDepth) * mix(schlickPhase(mu, 0.3), schlickPhase(-mu, 0.1), 0.3);

    return SSS_INTENSITY * TWO_PI * albedo * sssAmount * (s1 + s2);
}

float getMaxHorizonAngle(vec2 sliceDir, vec2 screenPos, vec3 viewPos, vec3 viewDir, vec2 stepSize, float dither) {
    vec2 stepDir = stepSize * sliceDir.xy;
    vec2 stepPos = screenPos + stepDir * dither;
    
    float maxTheta = -1.0;

    for (int i = 0; i < GTAO_HORIZON_STEPS; i++, stepPos += stepDir) {
        float sampleDepth = texelFetch(lodDepthTex1, ivec2(internalScreenSize * stepPos), 0).r;

        vec3 dirToSample = screenToViewPos(stepPos.xy, sampleDepth) - viewPos;

        float sqrLength = dot(dirToSample, dirToSample);
        float cosTheta = mix(dot(dirToSample, viewDir) * inversesqrt(sqrLength), -1.0, clamp01(sqrLength - 3.0 * GTAO_RADIUS));

        maxTheta = max(maxTheta, cosTheta);
    }

    return acosSafe(maxTheta);
}

vec4 getAmbientOcclusion(vec3 screenPos, vec3 viewPos, vec3 viewNormal, vec2 dither) {
    vec3 viewDir = normalize(-viewPos);
    vec2 stepSize = gbufferProjScale.xy * GTAO_RADIUS * rcp(GTAO_HORIZON_STEPS * max(0.25, -viewPos.z));

    float theta = TWO_PI * dither.x;

    vec3 sliceDir = vec3(cos(theta), sin(theta), 0.0);
    vec4 integratedData = vec4(0.0);

    for (int i = 0; i < GTAO_SLICES; i++) {
        float sliceAngle = PI * (i + dither.x) * rcp(GTAO_SLICES);
        vec3 sliceDir = vec3(cos(sliceAngle), sin(sliceAngle), 0.0);

        vec3 tangent = sliceDir - dot(sliceDir, viewDir) * viewDir;
        vec3 axis = cross(sliceDir, viewDir);
        vec3 projNormal = viewNormal - axis * dot(viewNormal, axis);

        float cosGamma = clamp01(dot(viewDir, projNormal) * inversesqrt(dot(projNormal, projNormal)));
        float gamma = sign(dot(tangent, projNormal)) * acos(cosGamma);

        vec2 horizonAngles = vec2(
            getMaxHorizonAngle(-sliceDir.xy, screenPos.xy, viewPos, viewDir, stepSize, dither.y),
            getMaxHorizonAngle( sliceDir.xy, screenPos.xy, viewPos, viewDir, stepSize, dither.y)
        );

        horizonAngles = gamma + clamp(vec2(-horizonAngles.x, horizonAngles.y) - gamma, -HALF_PI, HALF_PI);

        float bentAngle = 0.5 * (horizonAngles.x + horizonAngles.y);

        integratedData.xyz += viewDir * cos(bentAngle) + tangent * sin(bentAngle);
        integratedData.a += dot(vec2(0.25), cosGamma + 2.0 * horizonAngles * sin(gamma) - cos(2.0 * horizonAngles - gamma));
    }

    return vec4(normalize(mat3(gbufferModelViewInverse) * (normalize(integratedData.xyz) - 0.5 * viewDir + 0.1 * viewNormal)), integratedData.a * rcp(float(GTAO_SLICES)));
}

vec3 getBouncedSunlight(vec3 shadowViewPos, vec3 bentNormal, vec2 dither, float skylight) {
    vec3 shadowViewNormal = mat3(shadowModelView) * bentNormal;
    vec2 shadowClipPos = shadowProjScale.xy * shadowViewPos.xy;

    float theta = TWO_PI * dither.x;

    vec2 sampleState = shadowProjScale.xy * SUNLIGHT_GI_RANGE * vec2(cos(theta), sin(theta));
    vec3 irradiance = vec3(0.0);

    for (int i = 0; i < SUNLIGHT_GI_SAMPLES; i++) {
        float sampleDist = fract(0.4301597 * i + dither.y);
        sampleState *= vogelPhase;

        vec2 samplePos = shadowClipPos + sampleDist * sampleState;
        ivec2 sampleTexel = ivec2(float(shadowMapResolution) * (distortShadowPos(samplePos) * 0.5 + 0.5));

        vec3 dirToSample = shadowProjScaleInv * vec3(samplePos, texelFetch(shadowtex1, sampleTexel, 0).r * 2.0 - 1.0) - shadowViewPos;

        float sqrLength = dot(dirToSample, dirToSample);
        float invLength = inversesqrt(max(0.01, sqrLength));

        if (invLength > rcp(SUNLIGHT_GI_RANGE)) {
            vec4 albedoSample = texelFetch(shadowcolor0, sampleTexel, 0);
            vec3 geometrySample = texelFetch(shadowcolor1, sampleTexel, 0).rgb;

            vec3 radiance = albedoSample.rgb * (1.0 - albedoSample.a * step(albedoSample.a, 0.99)) * max0(dot(shadowViewNormal, dirToSample)) * max0(-dot(octDecode(geometrySample.rg), dirToSample)) * sqr(invLength * invLength);

            float attenuation = sampleDist * smoothstep(-SUNLIGHT_GI_RANGE, -0.75 * SUNLIGHT_GI_RANGE, -sqrLength * invLength) * exp(-6.0 * abs(geometrySample.b - skylight));

            irradiance += radiance * attenuation;
        }
    }

    return 2.0 * SUNLIGHT_GI_RANGE * SUNLIGHT_GI_RANGE * rcp(SUNLIGHT_GI_SAMPLES) * irradiance;
}

vec3 getFakeBouncedSunlight(vec3 bentNormal) {
    const vec3 albedo = vec3(0.01) * rgbToAp1Unlit;
    
    return clamp01(albedo * (dot(bentNormal, normalize(vec3(-shadowDir.x, 0.5 * shadowDir.y, -shadowDir.z))) * 0.5 + 0.5));
}

vec3 getSpecularReflections(vec2 coord, float depth, vec3 scenePos, vec3 reflectedDir, float dither, float skylight) {
    vec3 screenPos = vec3(coord, depth);

    vec3 rayEnd = sceneToScreenPos(scenePos + near * reflectedDir);
    vec3 rayDir = clipAABB(screenPos, rayEnd - screenPos, vec3(0.0, 0.0, -0.125), vec3(1.0));

    bool hit = raymarchIntersection(screenPos, rayDir, max(0.01, dither));

    if (!hit) return smoothstep(0.8, 1.0, skylight) * getAtmosphereScattering(reflectedDir);
    else {
        #ifdef STAGE_VOXY   
            return texelFetch(colortex6, ivec2(screenSize * screenPos.xy), 0).rgb;
        #else
            return decodeRgbe8(texelFetch(colortex7, ivec2(internalScreenSize * screenPos.xy), 0));
        #endif
    }
}

vec2 adjustLightLevels(vec2 lightLevels) {
    lightLevels.r = 2.0 * smoothstep(-1.0, 1.0, lightLevels.r) - 1.0;
    lightLevels.r *= lightLevels.r;
    lightLevels.r = 1.0 + (1.0 - lightLevels.r) / (-0.99 * (1.0 - lightLevels.r) - 0.01);
    lightLevels.g = 1.0 - pow(max0(1.0 - lightLevels.g), 0.7);
    lightLevels.g *= lightLevels.g;

    return lightLevels;
}

vec3 getSceneLighting (
    vec3 scenePos,
    vec3 viewDir,
    Material mat,
    vec3 indirectIrradiance,
    vec3 normal,
    vec3 textureNormal,
    vec2 lightLevels,
    float skylightFactor,
    float dither,
    float ao
) {
    vec3 shadowViewPos = mat3(shadowModelView) * mix(scenePos, floor(scenePos + cameraPositionFract + normal * 0.25) + 0.5 - cameraPositionFract, 0.2 * (1.0 - skylightFactor)) + shadowModelView[3].xyz;
    vec2 distortDiff = distortShadowPosDiff(shadowProjScale.xy * shadowViewPos.xy);

#ifdef SHADOW_VPS
    float blockerDepth = getBlockerDepth(shadowViewPos, distortDiff, dither);
#endif

    vec3 transmittance = shadowLightBrightness * SUNLIGHT_TINT * getAtmosphereTransmittance(shadowDir);

#ifdef COLORED_LIGHTING
    vec3 blocklight = getBlocklight(scenePos + textureNormal * 0.5);
#else
    vec3 blocklight = lightLevels.r * defaultColor;
#endif

    vec3 radiance = mat.emissive + mat.albedo * ao * (vec3(0.5, 0.7, 1.0) * 0.0005 + indirectIrradiance + blocklight);

    radiance += step(-0.0005, dot(shadowDir, normal)) * transmittance * getSurfaceBsdf(-viewDir, shadowDir, textureNormal, mat) * getShadow(shadowViewPos, normal, distortDiff, dither
        #ifdef SHADOW_VPS
            , blockerDepth * (skylightFactor * 0.9 + 0.1)
        #endif
    );

#ifdef SSS_ENABLED
    radiance += transmittance * getSubsurfaceScattering(mat.albedo, mat.sssAmount, dot(viewDir, shadowDir), blockerDepth);
#endif

    return radiance;
}

#endif // INCLUDE_LIGHTING_LIGHTING