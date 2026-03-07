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

    float getShadowBias (vec2 shadowClipPos) 
    {
        vec2 rate = distortShadowPosDiff(shadowClipPos);
        return shadowDistance / (min(rate.x, rate.y) * float(shadowMapResolution));
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

    vec3 getShadow (vec3 shadowViewPos, vec3 normal, vec2 dither, float blockerDepth)
    {
        float biasAmount = getShadowBias(shadowProjScale.xy * shadowViewPos.xy);

        vec3 shadowPos = shadowProjScale * (shadowViewPos + mat3(shadowModelView) * normal * (biasAmount * 1.3 + 0.02));
        vec3 shadowViewNormal = mat3(shadowModelView) * normal;

        float kernelRadius = shadowProjScale.x * max(20.0 / float(shadowMapResolution), blockerDepth * SHADOW_SOFTNESS);

       //float shadowSharpening = 

        vec4 integratedData = vec4(0.0);

        mat2 factor = rotate(0.2451223 * TWO_PI);
        vec2 state = vec2(sin(dither.x * TWO_PI), cos(dither.x * TWO_PI));

        for (int i = 0; i < SHADOW_SAMPLES; i++)
        {
            float sampleDist = kernelRadius * sqrt(fract(0.4301597 * i + dither.y));
            state *= factor;

            vec2 offset = sampleDist * state;
            float depthBias = -max0(0.5 * shadowProjScale.z * shadowProjScaleInv.x * dot(offset, shadowViewNormal.xy) / shadowViewNormal.z);

            integratedData.w += texture(shadowtex1HW, vec3(distortShadowPos(shadowPos.xy + offset), shadowPos.z + depthBias) * 0.5 + 0.5).r;
        }

        #ifdef COLORED_SHADOWS
            state = vec2(sin(dither.x * TWO_PI), cos(dither.x * TWO_PI));
            float kernelSum = 0.0;

            for (int i = 0; i < SHADOW_SAMPLES; i++)
            {
                float sampleDist = kernelRadius * sqrt(fract(0.4301597 * i + dither.y));
                state *= factor;

                vec2 offset = sampleDist * state;
                float depthBias = -max0(0.5 * shadowProjScale.z * shadowProjScaleInv.x * dot(offset, shadowViewNormal.xy) / shadowViewNormal.z);

                vec2 sampleUv = distortShadowPos(shadowPos.xy + offset) * 0.5 + 0.5;

                vec4 sampleColor = texture(shadowcolor0, sampleUv);
                float sampleDepth = step((shadowPos.z + depthBias) * 0.5 + 0.5, texture(shadowtex0, sampleUv).x);

                if (sampleColor.a > 0.99 && sampleDepth == 0.0) continue;

                integratedData.rgb += mix(sampleColor.rgb * (1.0 - sampleColor.a), vec3(1.0), sampleDepth);
                kernelSum += 1.0;
            }

            return kernelSum < 0.5 ? integratedData.www * rcp(float(SHADOW_SAMPLES)) : (integratedData.rgb * integratedData.w * rcp(float(SHADOW_SAMPLES) * kernelSum));
        #else
            return integratedData.www * rcp(float(SHADOW_SAMPLES));
        #endif
    }

#endif