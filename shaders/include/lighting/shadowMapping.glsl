#ifndef INCLUDE_SHADOW_MAPPING
    #define INCLUDE_SHADOW_MAPPING

    #define SHADOW_MAP_BIAS 4.0
	const float c = exp(SHADOW_MAP_BIAS) - 1.0;
	
	vec2 distort (vec2 pos) 
    {
		return sign(pos) * log(c * abs(pos) + 1.0) / log(c + 1.0);
	}

	vec2 distortDiff (vec2 pos) 
    {
		return c / ((c * abs(pos) + 1.0) * log(c + 1.0));
	}

	vec2 distortInv (vec2 pos) 
    {
		return sign(pos) * (exp(abs(pos) * log(c + 1.0)) - 1.0) / c;
	}

    float getBiasFactor (vec2 shadowClipPos) 
    {
        vec2 distortBiasFactor = distortDiff(shadowClipPos);
        return SHADOW_BIAS + 1.4 * shadowDistance / (min(distortBiasFactor.x, distortBiasFactor.y) * float(shadowMapResolution));
    }
	
    vec3 getShadowBias (vec2 shadowClipPos, vec3 normal) 
    {
        return normal * getBiasFactor(shadowClipPos);
    }

    vec3 getShadow (vec3 playerPos, vec3 normal, vec2 dither)
    {
        vec3 shadowViewPos = (shadowModelView * vec4(playerPos, 1.0)).xyz; 

        float biasAmount = getBiasFactor(shadowProjScale.xy * shadowViewPos.xy);

        vec3 shadowPos = shadowProjScale * (shadowViewPos + mat3(shadowModelView) * normal * biasAmount);

        shadowPos.xy = distort(shadowPos.xy);

        shadowPos = shadowPos * 0.5 + 0.5;

        


        return vec3(texture(shadowtex0, shadowPos.xyz).r);
    }

#endif