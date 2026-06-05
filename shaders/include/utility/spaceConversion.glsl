#ifndef INCLUDE_SPACE_CONVERSION
    #define INCLUDE_SPACE_CONVERSION

    vec3 projectAndDivide(mat4 matrix, vec3 position) {
        vec4 homogeneousPos = matrix * vec4(position, 1.0);
        return homogeneousPos.xyz / homogeneousPos.w;
    }

    float linearizeDepthNdc(float depth) {
        return rcp(gbufferProjScaleInv.z * depth + gbufferProjScaleInv.w);
    }

    float linearizeDepth(float depth) {
        return linearizeDepthNdc(depth * -2.0);
    }

    vec3 screenToViewPos(vec2 uv, float depth) {
        vec3 ndc = vec3(uv * 2.0 - 1.0, depth * -2.0);
        
        ndc.xy -= taa_offset;

        return vec3(gbufferProjScaleInv.xy * ndc.xy, -1.0) / (gbufferProjScaleInv.z * ndc.z + gbufferProjScaleInv.w);
    }

    vec3 viewToScenePos(vec3 viewPos) {
        return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
    }

    vec3 sceneToViewPos(vec3 scenePos) {
        return mat3(gbufferModelView) * scenePos + gbufferModelView[3].xyz;
    }

    vec3 screenToScenePos(vec2 uv, float depth) {   
        return viewToScenePos(screenToViewPos(uv, depth));
    }

    vec3 viewToScreenPos(vec3 viewPos) {
        viewPos.z = min(-eps, viewPos.z);

        vec3 ndc = vec3(gbufferProjScale.xy * viewPos.xy, gbufferProjScale.z * viewPos.z + gbufferProjScale.w) / abs(viewPos.z);

        ndc.xy += taa_offset;

        return vec3(ndc.xy * 0.5 + 0.5, ndc.z * -0.5);
    }

    vec3 sceneToScreenPos(vec3 scenePos) {   
        vec3 viewPos = (gbufferModelView * vec4(scenePos, 1.0)).xyz;

        return viewToScreenPos(viewPos);
    }

#endif