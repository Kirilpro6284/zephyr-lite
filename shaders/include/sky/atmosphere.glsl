#ifndef INCLUDE_ATMOSPHERE
    #define INCLUDE_ATMOSPHERE

    #define SKY_RAYLEIGH_R 1.0
    #define SKY_RAYLEIGH_G 1.0
    #define SKY_RAYLEIGH_B 1.25

    #define SKY_MIE 4.0
    #define SKY_OZONE 0.75

    #define USE_KLEIN_NISHINA_PHASE

    #define SCATTER_POINTS 64

    #define ALTITUDE_BIAS 512.0

    #define SKY_TRANSMITTANCE_BOTTOM_LEFT ivec2(160, 128)
    #define SKY_MS_BOTTOM_LEFT ivec2(128, 128)
    #define SKY_VIEW_BOTTOM_LEFT ivec2(0, 128)

    #define SKY_TRANSMITTANCE_RES ivec2(32, 32)
    #define SKY_MS_RES ivec2(32, 32)
    #define SKY_VIEW_RES ivec2(128, 128)

    const float planetRadius = 6371000.0;
    const float atmosphereHeight = 100000.0;

    const vec2 scaleHeights = vec2(8000.0, 1250.0);
    const vec2 invScaleHeights = rcp(scaleHeights);

    const vec3 betaR = vec3(SKY_RAYLEIGH_R, SKY_RAYLEIGH_G, SKY_RAYLEIGH_B) * pow(vec3(680.0, 530.0, 440.0), vec3(-4.0)) * 1e6;
    const vec3 betaM = SKY_MIE * vec3(1e-5);
    
    const vec3 alphaR = betaR;
    const vec3 alphaM = 0.6 * SKY_MIE * vec3(1e-5);
    const vec3 alphaO = SKY_OZONE * vec3(1.9, 2.7, 0.1) * 1e-6;
    
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

        dstNear = max0(dstNear);

        return vec2(dstNear, dstFar - dstNear);
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
    vec3 getTransmittance (vec3 pos, vec3 lightDir) 
    {
        float sqrLength = dot(pos, pos);
        float invLength = inversesqrt(sqrLength);

        float w = sqrt(1.0 - planetRadius * planetRadius * invLength * invLength);

        vec2 uv = vec2(0.0);

        uv.x = liftInv((sqrLength * invLength - planetRadius) / atmosphereHeight, -3.0);
        uv.y = liftInv((dot(pos, lightDir) * invLength + w) / (1.0 + w), -16.0);

        if (saturate(uv) != uv) return vec3(0.0);

        uv = rcp(256.0) * mix(vec2(SKY_TRANSMITTANCE_BOTTOM_LEFT) + 0.5, vec2(SKY_TRANSMITTANCE_BOTTOM_LEFT + SKY_TRANSMITTANCE_RES) - 0.5, uv);

        return sqr(texture(scattering, uv).rgb);
    }

    vec3 getTransmittance (vec3 lightDir) 
    {
        return getTransmittance(vec3(0.0, planetRadius + eyeAltitude + ALTITUDE_BIAS, 0.0), lightDir);
    }

    vec3 getMultipleScattering (vec3 rayPos, vec3 lightDir, float rayHeight)
    {
        vec2 uv = vec2(rcp(atmosphereHeight) * (rayHeight - planetRadius), dot(rayPos, lightDir) * inversesqrt(dot(rayPos, rayPos)) * 0.5 + 0.5);

        uv.x = liftInv(uv.x, -2.0);
        uv.y = liftInv(uv.y * 2.0 - 1.0, -1.5) * 0.5 + 0.5;

        uv = rcp(256.0) * mix(vec2(SKY_MS_BOTTOM_LEFT) + 0.5, vec2(SKY_MS_BOTTOM_LEFT + SKY_MS_RES) - 0.5, saturate(uv));

        return texture(scattering, uv).rgb;
    }

    vec3 getAtmosphereScattering (vec3 rayDir)
    {
        vec2 uv = vec2(0.0);

        uv.y = liftInv(rayDir.y, -2.0) * 0.5 + 0.5;

        float w = dot(sunDir.xz, sunDir.xz) * dot(rayDir.xz, rayDir.xz);

        uv.x = w > 0.0001 ? -liftInv(asin(clamp(inversesqrt(w) * dot(sunDir.xz, rayDir.xz), -1.0, 1.0)) * rcp(HALF_PI), 0.5) * 0.5 + 0.5 : 0.0;

        uv = rcp(256.0) * mix(vec2(SKY_VIEW_BOTTOM_LEFT) + 0.5, vec2(SKY_VIEW_BOTTOM_LEFT + SKY_VIEW_RES) - 0.5, saturate(uv));

        return texture(scattering, uv).rgb;
    }

    float rayleighPhase (float cosTheta)
    {
        return (1.0 + cosTheta * cosTheta) * 3.0 / (16.0 * PI);
    }

    float schlickPhase (float cosTheta, float k)
    {
        return (1.0 - k * k) / (4.0 * PI * sqr(1.0 - k * cosTheta));
    }

    float kleinNishinaPhase (float cosTheta, float e) 
    {
        return e / (TWO_PI * (e * (1.0 - cosTheta) + 1.0) * log(e * 2.0 + 1.0));
    }

    vec3 evalScattering (vec3 rayOrigin, vec3 rayDir, vec3 lightDir)
    {
        float viewZenith = rayDir.y;
        
        #ifndef SKY_MS
            if (rayDir.y < 0.0) rayDir = normalize(vec3(rayDir.x, 0.0, rayDir.z));
        #endif

        float stepSize = rcp(SCATTER_POINTS) * min(raySphere(rayOrigin, rayDir, planetRadius).x, raySphere(rayOrigin, rayDir, planetRadius + atmosphereHeight).y);

        vec3 rayStep = rayDir * stepSize;
        vec3 rayPos = rayOrigin + rayStep * 0.5;

        vec3 opticalDepth = vec3(0.0);
        vec3 integratedData = vec3(0.0);
        
        #ifdef SKY_MS
            float mu = dot(rayDir, lightDir);
        #else
            float mu = (1.0 - sqr(1.0 - min1(viewZenith + 1.0))) * dot(rayDir, lightDir);
        #endif

        #ifdef USE_KLEIN_NISHINA_PHASE
            vec2 phase = vec2(rayleighPhase(mu), kleinNishinaPhase(mu, 3000.0));
        #else
            vec2 phase = vec2(rayleighPhase(mu), schlickPhase(mu, 0.98));
        #endif

        for (int i = 0; i < SCATTER_POINTS; i++, rayPos += rayStep) {
            float rayHeight = length(rayPos);

            vec3 density = stepSize * getDensityAtHeight(rayHeight);
            opticalDepth += min1(float(i) + 0.5) * (alphaR * density.x + alphaM * density.y + alphaO * density.z);

            integratedData += exp(-opticalDepth) * (
                (raySphere(rayPos, lightDir, planetRadius).x == INFINITY ? getTransmittance(rayPos, lightDir) * (betaR * phase.x * density.x + betaM * phase.y * density.y) : vec3(0.0)) 
              + getMultipleScattering(rayPos, lightDir, rayHeight) * (betaR * isotropicPhase.x * density.x + betaM * isotropicPhase.y * density.y)
            );
        }

        return integratedData;
    }
#endif

#endif