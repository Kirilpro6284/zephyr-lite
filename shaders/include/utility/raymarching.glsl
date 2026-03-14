#if !defined INCLUDE_UTILITY_RAYMARCHING
#define INCLUDE_UTILITY_RAYMARCHING

bool traceScreenSpaceRay (inout vec3 rayPos, in vec3 rayDir, float dither) {
    rayDir *= rcp(SSR_PRIMARY_STEP_COUNT);
    rayPos += rayDir * dither;

    bool hit = false;

    for (int i = 0; i < SSR_PRIMARY_STEP_COUNT; i++, rayPos += rayDir) 
    {
        float sampleDepth = texture(lodDepthTex1, rayPos.xy).r;

        if (sampleDepth < rayPos.z && abs(rayPos.z - sampleDepth) < max(abs(rayDir.z) * 2.0, abs(rayPos.z) * 0.15)) {
            rayPos -= rayDir;
            hit = true;
            break;
        }
    }

    if (!hit) return false;

    rayDir *= rcp(SSR_REFINEMENT_STEP_COUNT - 1);
    rayPos += rayDir * dither;

    for (int i = 0; i < SSR_REFINEMENT_STEP_COUNT; i++, rayPos += rayDir) 
    {
        float sampleDepth = texture(lodDepthTex1, rayPos.xy).r;

        if (sampleDepth < rayPos.z) {
            return true;
        }
    }

    return false;
}

#endif // INCLUDE_UTILITY_RAYMARCHING