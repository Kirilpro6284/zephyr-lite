#ifndef INCLUDE_SHADOW_MAPPING
    #define INCLUDE_SHADOW_MAPPING

    #define SHADOW_MAP_BIAS 4.0
	const float c = exp(SHADOW_MAP_BIAS) - 1.0;
	
	vec2 distortShadowPos (vec2 pos) 
    {
		return sign(pos) * log(c * abs(pos) + 1.0) / log(c + 1.0);
	}

	vec2 distortShadowPosDiff (vec2 pos) 
    {
		return c / ((c * abs(pos) + 1.0) * log(c + 1.0));
	}

	vec2 distortShadowPosInv (vec2 pos) 
    {
		return sign(pos) * (exp(abs(pos) * log(c + 1.0)) - 1.0) / c;
	}

    float getBlockerDepth (vec3 shadowViewPos, vec2 dither)
    {
        float blockerDepth = 0.0;

        mat2 factor = rotate(0.2451223 * TWO_PI);
        vec2 state = vec2(sin(dither.x * TWO_PI), cos(dither.x * TWO_PI));

        for (int i = 0; i < SHADOW_BLOCKER_SAMPLES; i++) 
        {
            float sampleDist = SHADOW_BLOCKER_RADIUS * sqrt(fract(0.4301597 * i + dither.y));
            state *= factor;

            blockerDepth += clamp(shadowProjScaleInv.z * (texture(shadowtex0, distortShadowPos(shadowProjScale.xy * (shadowViewPos.xy + sampleDist * state)) * 0.5 + 0.5).r * 2.0 - 1.0) - shadowViewPos.z, 0.0, SHADOW_MAX_BLOCKER_DEPTH);
        }

        return blockerDepth * rcp(SHADOW_BLOCKER_SAMPLES);
    }

    vec3 getShadow (vec3 shadowViewPos, vec3 normal, vec2 dither
        #ifdef SHADOW_VPS
            , float blockerDepth
        #endif
    ) {
        vec2 distortDiff = distortShadowPosDiff(shadowProjScale.xy * shadowViewPos.xy);

        vec3 shadowPos = shadowProjScale * (shadowViewPos + mat3(shadowModelView) * normal * (SHADOW_BIAS + shadowDistance * rcp(min(distortDiff.x, distortDiff.y) * float(shadowMapResolution))));

        float shadowGradient = smoothstep(-1.0, -0.99, -abs(shadowPos.x))
                             * smoothstep(-1.0, -0.99, -abs(shadowPos.y))
                             * smoothstep(-1.0, -0.99, -abs(shadowPos.z));

        vec2 shadowDistortPos = distortShadowPos(shadowPos.xy);

        vec3 shadowViewNormal = mat3(shadowModelView) * normal;

        float penumbraSize = blockerDepth * SHADOW_SOFTNESS;

        #ifdef SHADOW_VPS
            float kernelRadius = shadowProjScale.x * max(100.0 / float(shadowMapResolution), penumbraSize);
        #else
            float kernelRadius = shadowProjScale.x * SHADOW_SOFTNESS * 2.0;
        #endif

        float shadowSharpening = clamp(100.0 / (penumbraSize * shadowMapResolution), 1.0, 3.0);

        vec4 integratedData = vec4(0.0);

        mat2 factor = rotate(0.2451223 * TWO_PI);
        vec2 state = vec2(sin(dither.x * TWO_PI), cos(dither.x * TWO_PI));

        for (int i = 0; i < SHADOW_SAMPLES; i++)
        {
            float sampleDist = kernelRadius * sqrt(fract(0.4301597 * i + dither.y));
            state *= factor;

            vec2 offset = distortDiff * sampleDist * state;
            float depthBias = -max0(0.5 * shadowProjScale.z * shadowProjScaleInv.x * dot(offset, shadowViewNormal.xy) / shadowViewNormal.z);

            integratedData.w += texture(shadowtex1HW, vec3(shadowDistortPos + offset, shadowPos.z + depthBias) * 0.5 + 0.5).r;
        }

        integratedData.w = saturate(mix(0.5, integratedData.w * rcp(float(SHADOW_SAMPLES)), shadowSharpening));

        #ifdef COLORED_SHADOWS
            state = vec2(sin(dither.x * TWO_PI), cos(dither.x * TWO_PI));
            float kernelSum = 0.0;

            for (int i = 0; i < SHADOW_SAMPLES; i++)
            {
                float sampleDist = kernelRadius * sqrt(fract(0.4301597 * i + dither.y));
                state *= factor;

                vec2 offset = distortDiff * sampleDist * state;
                float depthBias = -max0(0.5 * shadowProjScale.z * shadowProjScaleInv.x * dot(offset, shadowViewNormal.xy) / shadowViewNormal.z);

                ivec2 sampleTexel = ivec2(float(shadowMapResolution) * ((shadowDistortPos + offset) * 0.5 + 0.5));

                vec4 sampleColor = texelFetch(shadowcolor0, sampleTexel, 0);
                float sampleDepth = step((shadowPos.z + depthBias) * 0.5 + 0.5, texelFetch(shadowtex0, sampleTexel, 0).x);

                if (sampleColor.a > 0.99 && sampleDepth == 0.0) continue;
                
                integratedData.rgb += mix(sampleColor.rgb * (1.0 - sampleColor.a), vec3(1.0), sampleDepth);
                kernelSum += 1.0;
            }

            return shadowGradient * (kernelSum < 0.5 ? integratedData.www : (rcp(kernelSum) * integratedData.rgb * integratedData.w)) + (1.0 - shadowGradient);
        #else
            return shadowGradient * integratedData.www + (1.0 - shadowGradient);
        #endif
    }

#endif