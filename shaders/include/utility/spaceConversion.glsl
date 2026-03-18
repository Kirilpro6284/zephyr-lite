#ifndef INCLUDE_SPACE_CONVERSION
    #define INCLUDE_SPACE_CONVERSION

    vec3 projectAndDivide (mat4 matrix, vec3 position) 
    {
        vec4 homogeneousPos = matrix * vec4(position, 1.0);
        return homogeneousPos.xyz / homogeneousPos.w;
    }

    vec3 screenToViewPos (vec2 uv, float depth) {
        vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
        
        return projectAndDivide(lodProjMatInv0, vec3(ndc.xy - taa_offset, ndc.z));
    }

    vec3 viewToPlayerPos (vec3 viewPos) {
        return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
    }

    vec3 playerToViewPos (vec3 playerPos) {
        return mat3(gbufferModelView) * playerPos + gbufferModelView[3].xyz;
    }

    vec3 screenToPlayerPos (vec2 uv, float depth)
    {   
        return viewToPlayerPos(screenToViewPos(uv, depth));
    }

    vec3 playerToScreenPos (vec3 playerPos)
    {   
        vec4 homogeneousPos = lodProjMat0 * gbufferModelView * vec4(playerPos, 1.0);
        vec3 ndc = homogeneousPos.xyz / abs(homogeneousPos.w);

        return vec3((ndc.xy + taa_offset) * 0.5 + 0.5, ndc.z);
    }

#endif