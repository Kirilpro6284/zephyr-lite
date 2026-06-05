#if !defined INCLUDE_UTILITY_RAYMARCHING
#define INCLUDE_UTILITY_RAYMARCHING

bool raymarchIntersection(inout vec3 rayPos, vec3 rayDir, float dither) {
    rayDir *= rcp(SSR_PRIMARY_STEP_COUNT);
    rayPos += rayDir * dither;

    bool hit = false;

    float depthTolerance = max(rayPos.z * 0.4, abs(rayDir.z));

    for (int i = 0; i < SSR_PRIMARY_STEP_COUNT; i++, rayPos += rayDir) {
        float sampleDepth = texelFetch(lodDepthTex1, ivec2(internalScreenSize * rayPos.xy), 0).r;

        if (sampleDepth > max0(rayPos.z) && abs(rayPos.z - sampleDepth) < depthTolerance) {
            hit = true;
            break;
        }
    }

    if (!hit) return false;

    for (int i = 0; i < SSR_REFINEMENT_STEP_COUNT; i++) {
        rayDir *= 0.5;

        float sampleDepth = texelFetch(lodDepthTex1, ivec2(internalScreenSize * rayPos.xy), 0).r;

        if (sampleDepth > rayPos.z) {
            rayPos -= rayDir;
        } else {
            rayPos += rayDir;
        }
    }

    float finalDepth = texelFetch(lodDepthTex1, ivec2(internalScreenSize * rayPos.xy), 0).r;

    return abs(rayPos.z - finalDepth) < depthTolerance;
}

#endif // INCLUDE_UTILITY_RAYMARCHING