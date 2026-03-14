#ifndef INCLUDE_SPACE_CONVERSION
    #define INCLUDE_SPACE_CONVERSION

    vec4 projectAndDivide (mat4 matrix, vec3 position) 
    {
        vec4 homogeneousPos = matrix * vec4(position, 1.0);
        return vec4(homogeneousPos.xyz / homogeneousPos.w, homogeneousPos.w);
    }

    vec4 screenToPlayerPos (vec2 uv, float depth)
    {   
        vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
        vec4 homogeneousPos = gbufferModelViewInverse * lodProjMatInv0 * vec4(ndc.xy - taa_offset, ndc.z, 1.0);

        return vec4(homogeneousPos.xyz / homogeneousPos.w, homogeneousPos.w);
    }

    vec3 playerToScreenPos (vec3 playerPos)
    {   
        vec4 homogeneousPos = lodProjMat0 * gbufferModelView * vec4(playerPos, 1.0);
        vec3 ndc = homogeneousPos.xyz / abs(homogeneousPos.w);

        return vec3((ndc.xy + taa_offset) * 0.5 + 0.5, ndc.z);
    }

#endif