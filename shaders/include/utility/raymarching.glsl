#if !defined INCLUDE_UTILITY_RAYMARCHING
#define INCLUDE_UTILITY_RAYMARCHING

bool traceScreenSpaceRay (inout vec3 rayPos, in vec3 rayDir, float dither) {
    rayDir *= rcp(SSR_PRIMARY_STEP_COUNT);
    rayPos += rayDir * dither;

    bool hit = false;

    for (int i = 0; i < SSR_PRIMARY_STEP_COUNT; i++, rayPos += rayDir) 
    {
        float sampleDepth = texture(lodDepthTex1, rayPos.xy * taauRenderScale).r;

        if (sampleDepth < rayPos.z && abs(rayPos.z - sampleDepth) < max(abs(rayDir.z) * 2.0, abs(rayPos.z) * 0.15)) {
            hit = true;
            break;
        }
    }

    if (!hit) return false;

    for (int i = 0; i < SSR_REFINEMENT_STEP_COUNT; i++) 
    {
        rayDir *= 0.5;

        float sampleDepth = texture(lodDepthTex1, rayPos.xy * taauRenderScale).r;

        if (sampleDepth < rayPos.z) {
            rayPos -= rayDir;
        } else {
            rayPos += rayDir;
        }
    }

    return true;
}

#endif // INCLUDE_UTILITY_RAYMARCHING