#ifndef INCLUDE_ATMOSPHERE
    #define INCLUDE_ATMOSPHERE

    #include "/include/utility/textureSampling.glsl"
    #include "/include/utility/colorMatrices.glsl"
    #include "/include/utility/bsdf.glsl"

    #define SKY_RAYLEIGH_R 1.0
    #define SKY_RAYLEIGH_G 1.0
    #define SKY_RAYLEIGH_B 1.0

    #define SKY_MIE 4.0
    #define SKY_OZONE 0.4

    #define USE_KLEIN_NISHINA_PHASE

    #define SCATTER_POINTS 64

    #define ALTITUDE_BIAS 250.0

    #define SKY_TRANSMITTANCE_BOTTOM_LEFT ivec2(160, 224)
    #define SKY_IRRADIANCE_BOTTOM_LEFT ivec2(128, 216)
    #define SKY_MS_BOTTOM_LEFT ivec2(128, 224)
    #define SKY_VIEW_BOTTOM_LEFT ivec2(0, 128)

    #define SKY_TRANSMITTANCE_RES ivec2(32, 32)
    #define SKY_IRRADIANCE_RES ivec2(8, 8)
    #define SKY_MS_RES ivec2(32, 32)
    #define SKY_VIEW_RES ivec2(128, 128)

    const float planetRadius = 6371000.0;
    const float atmosphereHeight = 100000.0;

    const vec2 scaleHeights = vec2(8000.0, 1250.0);
    const vec2 invScaleHeights = rcp(scaleHeights);

    const vec3 betaR = vec3(SKY_RAYLEIGH_R, SKY_RAYLEIGH_G, SKY_RAYLEIGH_B) * pow(vec3(680.0, 530.0, 440.0), vec3(-4.0)) * 1e6 * rgbToAp1Unlit;
    const vec3 betaM = SKY_MIE * vec3(1e-5) * rgbToAp1Unlit;
    const vec3 betaO = SKY_OZONE * vec3(1.9, 2.7, 0.1) * 1e-6 * rgbToAp1Unlit;
    
    const vec2 isotropicPhase = vec2(6.0 * rcp(16.0 * PI), rcp(4.0 * PI));

    vec2 raySphere (vec3 rayOrigin, vec3 rayDir, float radius) 
    {
        float d = sqr(dot(rayOrigin, rayDir)) - dot(rayOrigin, rayOrigin) + radius * radius;

        if (d < 0) return vec2(INFINITY);

        d = sqrt(d);

        float cosTheta = dot(rayOrigin, rayDir);
        float invDet = -rcp(dot(rayDir, rayDir));

        float dstNear = (cosTheta + d) * invDet;
        float dstFar  = (cosTheta - d) * invDet;

        if (dstFar < 0.0) return vec2(INFINITY);

        return vec2(max0(dstNear), dstFar);
    }

    vec3 getDensityAtHeight (float height) 
    {
        return vec3(exp((planetRadius - height) * invScaleHeights), max0(min((height - planetRadius - 15000.0) / 10000.0, (40000.0 + planetRadius - height) / 15000.0)));
    }

    vec3 getDensityAtPoint (vec3 pos)
    {
        return getDensityAtHeight(length(pos));
    }

#ifndef STAGE_SETUP
    vec3 getAtmosphereTransmittance (vec3 pos, vec3 lightDir) 
    {
        float sqrLength = dot(pos, pos);
        float invLength = inversesqrt(sqrLength);

        float w = sqrt(1.0 - planetRadius * planetRadius * invLength * invLength);

        vec2 uv = vec2(0.0);

        uv.x = liftInv((sqrLength * invLength - planetRadius) / atmosphereHeight, -3.0);
        uv.y = liftInv((dot(pos, lightDir) * invLength + w) / (1.0 + w), -16.0);

        if (uv.y < 0.0) return vec3(0.0);

        uv = rcp(256.0) * mix(vec2(SKY_TRANSMITTANCE_BOTTOM_LEFT) + 0.5, vec2(SKY_TRANSMITTANCE_BOTTOM_LEFT + SKY_TRANSMITTANCE_RES) - 0.5, saturate(uv));

        return textureRgbe8(scattering, uv, vec2(256.0));
    }

    vec3 getAtmosphereTransmittance (vec3 lightDir) 
    {
        return getAtmosphereTransmittance(vec3(0.0, planetRadius + ALTITUDE_BIAS, 0.0), lightDir);
    }

    vec3 getMultipleScattering (vec3 rayPos, vec3 lightDir, float rayHeight)
    {
        vec2 uv = vec2(rcp(atmosphereHeight) * (rayHeight - planetRadius), dot(rayPos, lightDir) * inversesqrt(dot(rayPos, rayPos)) * 0.5 + 0.5);

        uv.x = liftInv(uv.x, -2.0);
        uv.y = liftInv(uv.y * 2.0 - 1.0, -1.5) * 0.5 + 0.5;

        uv = rcp(256.0) * mix(vec2(SKY_MS_BOTTOM_LEFT) + 0.5, vec2(SKY_MS_BOTTOM_LEFT + SKY_MS_RES) - 0.5, saturate(uv));

        return textureRgbe8(scattering, uv, vec2(256.0));
    }

    vec3 getAtmosphereScattering (vec3 rayDir)
    {
        vec2 uv = vec2(0.0);

        uv.y = liftInv(rayDir.y, -2.0) * 0.5 + 0.5;

        float w = dot(sunDir.xz, sunDir.xz) * dot(rayDir.xz, rayDir.xz);

        uv.x = w > 0.0001 ? -liftInv(asin(clamp(inversesqrt(w) * dot(sunDir.xz, rayDir.xz), -1.0, 1.0)) * rcp(HALF_PI), 0.5) * 0.5 + 0.5 : 0.0;

        uv = rcp(256.0) * mix(vec2(SKY_VIEW_BOTTOM_LEFT) + 0.5, vec2(SKY_VIEW_BOTTOM_LEFT + SKY_VIEW_RES) - 0.5, saturate(uv));

        return textureRgbe8(scattering, uv, vec2(256.0));
    }

    vec3 getSkyIrradiance (vec3 bentNormal) {
        vec2 uv = rcp(256.0) * mix(vec2(SKY_IRRADIANCE_BOTTOM_LEFT) + 0.5, vec2(SKY_IRRADIANCE_BOTTOM_LEFT + SKY_IRRADIANCE_RES) - 0.5, octEncode(bentNormal));

        return SKYLIGHT_TINT * textureRgbe8(scattering, uv, vec2(256.0));
    }

    vec3 evalAtmosphereScattering (vec3 rayOrigin, vec3 rayDir, vec3 lightDir)
    {
        float mu = dot(rayDir, lightDir);
        
        #ifndef SKY_MS
            if (rayDir.y < 0.0) rayDir = normalize(vec3(rayDir.x, 0.0, rayDir.z));
        #endif

        float stepSize = rcp(SCATTER_POINTS) * min(raySphere(rayOrigin, rayDir, planetRadius).x, raySphere(rayOrigin, rayDir, planetRadius + atmosphereHeight).y);

        vec3 rayStep = rayDir * stepSize;
        vec3 rayPos = rayOrigin + rayStep * 0.5;

        vec3 opticalDepth = vec3(0.0);
        vec3 integratedData = vec3(0.0);
        
        #ifdef USE_KLEIN_NISHINA_PHASE
            vec2 phase = vec2(rayleighPhase(mu), kleinNishinaPhase(mu, 3000.0));
        #else
            vec2 phase = vec2(rayleighPhase(mu), schlickPhase(mu, 0.98));
        #endif

        for (int i = 0; i < SCATTER_POINTS; i++, rayPos += rayStep) {
            float rayHeight = length(rayPos);

            vec3 density = stepSize * getDensityAtHeight(rayHeight);
            opticalDepth += -min1(float(i) + 0.5) * (betaR * density.x + betaM * density.y + betaO * density.z);

            integratedData += exp(opticalDepth) * (
                getAtmosphereTransmittance(rayPos, lightDir) * (betaR * phase.x * density.x + betaM * phase.y * density.y) 
              + getMultipleScattering(rayPos, lightDir, rayHeight) * (betaR * isotropicPhase.x * density.x + betaM * isotropicPhase.y * density.y)
            );
        }

        return integratedData;
    }
#endif

#endif