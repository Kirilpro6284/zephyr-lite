#ifndef INCLUDE_SHADOW_MAPPING
    #define INCLUDE_SHADOW_MAPPING

    #define SHADOW_DISTORTION_FUNCTION 0 // [0 1]

    #if SHADOW_DISTORTION_FUNCTION == 0
        // https://discord.com/channels/237199950235041794/525510804494221312/1379718853872848896

        #define SHADOW_MAP_BIAS 3.6
        const float c = exp(SHADOW_MAP_BIAS) - 1.0;
        
        vec2 distortShadowPos (vec2 pos) 
        {
            return sign(pos) * log2(c * abs(pos) + 1.0) / log2(c + 1.0);
        }

        vec2 distortShadowPosDiff (vec2 pos) 
        {
            return c / ((c * abs(pos) + 1.0) * log(c + 1.0));
        }
    /*
        vec2 distortShadowPosInv (vec2 pos) 
        {
            return sign(pos) * (exp(abs(pos) * log(c + 1.0)) - 1.0) / c;
        }
    */
    #else
        #define SHADOW_MAP_BIAS 0.85

        vec2 distortShadowPos (vec2 pos) 
        {
            return pos / (SHADOW_MAP_BIAS * abs(pos) + 1.0 - SHADOW_MAP_BIAS);
        }

        vec2 distortShadowPosDiff (vec2 pos)
        {
            return (1.0 - SHADOW_MAP_BIAS) / sqr(SHADOW_MAP_BIAS * abs(pos) + 1.0 - SHADOW_MAP_BIAS);
        }
    #endif

    float getBlockerDepth (vec3 shadowViewPos, float dither) {
        float blockerDepth = 0.0;
        
        vec2 state = vec2(cos(dither * TWO_PI), sin(dither * TWO_PI));

        for (int i = 0; i < SHADOW_BLOCKER_SAMPLES; i++) 
        {
            float sampleDist = SHADOW_BLOCKER_RADIUS * sqrt(fract(0.4301597 * i + 0.5));
            state *= vogelPhase;

            blockerDepth += clamp(shadowProjScaleInv.z * (texture(shadowtex0, distortShadowPos(shadowProjScale.xy * (shadowViewPos.xy + sampleDist * state)) * 0.5 + 0.5).r * 2.0 - 1.0) - shadowViewPos.z, 0.0, SHADOW_MAX_BLOCKER_DEPTH);
        }

        return blockerDepth * rcp(SHADOW_BLOCKER_SAMPLES);
    }

    vec3 getShadow (vec3 shadowViewPos, vec3 normal, float dither
        #ifdef SHADOW_VPS
            , float blockerDepth
        #endif
    ) {
        vec2 vogelState = vec2(cos(dither * TWO_PI), sin(dither * TWO_PI));
        vec2 distortDiff = distortShadowPosDiff(shadowProjScale.xy * shadowViewPos.xy);

        float biasAmount = shadowDistance * rcp(min(distortDiff.x, distortDiff.y) * float(shadowMapResolution));

        vec3 shadowPos = shadowProjScale * (shadowViewPos + mat3(shadowModelView) * normal * (SHADOW_BIAS + biasAmount));
        vec3 shadowDistortPos = vec3(distortShadowPos(shadowPos.xy), shadowPos.z) * 0.5 + 0.5;

        #ifdef SHADOW_VPS
            float penumbraSize = blockerDepth * SHADOW_SOFTNESS;
            float kernelRadius = shadowProjScale.x * max(SHADOW_SMOOTHING * biasAmount, penumbraSize);
        #else
            float penumbraSize = 2.0 * SHADOW_SOFTNESS;
            float kernelRadius = shadowProjScale.x * penumbraSize;
        #endif

        distortDiff *= 0.5;

        vec4 integratedData = vec4(0.0);
        vec2 sampleState = kernelRadius * vogelState;

        for (int i = 0; i < SHADOW_SAMPLES; i++) {
            float sampleDist = sqrt(fract(0.4301597 * i + 0.5));
            sampleState *= vogelPhase;

            integratedData.w += texture(shadowtex1HW, vec3(shadowDistortPos.xy + distortDiff * sampleDist * sampleState, shadowDistortPos.z)).r;
        }

        integratedData.w = clamp01(mix(0.5, integratedData.w * rcp(float(SHADOW_SAMPLES)), clamp(SHADOW_SMOOTHING * biasAmount / penumbraSize, 1.0, 1.0 + SHADOW_SMOOTHING)));

        float shadowGradient = smoothstep(-1.0, -0.99, -abs(shadowPos.x))
                             * smoothstep(-1.0, -0.99, -abs(shadowPos.y));

        #ifdef COLORED_SHADOWS
            sampleState = kernelRadius * vogelState;
            float kernelSum = 0.0;

            for (int i = 0; i < SHADOW_SAMPLES; i++) {
                float sampleDist = sqrt(fract(0.4301597 * i + 0.5));
                sampleState *= vogelPhase;

                ivec2 sampleTexel = ivec2(float(shadowMapResolution) * (shadowDistortPos.xy + distortDiff * sampleDist * sampleState));

                vec4 sampleColor = texelFetch(shadowcolor0, sampleTexel, 0);
                float visibility = step(shadowPos.z * 0.5 + 0.5, texelFetch(shadowtex0, sampleTexel, 0).x);

                if (sampleColor.a > 0.99 && visibility == 0.0) continue;
                
                integratedData.rgb += mix(sampleColor.rgb * (1.0 - sampleColor.a), vec3(1.0), visibility);
                kernelSum++;
            }

            if (kernelSum > 0.5) integratedData.rgb *= rcp(kernelSum);
            else integratedData.rgb = vec3(1.0);

            return shadowGradient * integratedData.rgb * integratedData.w + (1.0 - shadowGradient);
        #else
            return shadowGradient * vec3(integratedData.w) + (1.0 - shadowGradient);
        #endif
    }

#endif