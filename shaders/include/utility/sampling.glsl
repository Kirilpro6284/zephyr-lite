#if !defined INCLUDE_UTILITY_SAMPLING
#define INCLUDE_UTILITY_SAMPLING

vec2 getVogelDiskSample(inout vec2 state, int i) {
    state *= vogelPhase;

    return sqrt(fract(rcp(phi2 * phi2) * i + 0.5)) * state;
}

vec2 getVogelDiskSample(inout vec2 state, int i, float offset) {
    state *= vogelPhase;

    return sqrt(fract(rcp(phi2 * phi2) * i + offset)) * state;
}

#endif // INCLUDE_UTILITY_SAMPLING