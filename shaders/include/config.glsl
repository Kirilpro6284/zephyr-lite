#ifndef INCLUDE_CONFIG
    #define INCLUDE_CONFIG

    const int shadowMapResolution = 3072;
    const float shadowDistance = 192.0;
    const float shadowDepthDist = 256.0;

    const float sunPathRotation = -50.0;

    #define COLORED_SHADOWS

    #define SHADOW_DISTORTION 0.95
    #define SHADOW_BIAS 0.02

    #define SHADOW_MAX_BLOCKER_DEPTH 40.0
    #define SHADOW_SOFTNESS 0.01
    #define MIN_SHADOW_SOFTNESS 0.02
    #define SHADOW_BLOCKER_RADIUS 0.5
    #define SHADOW_BLOCKER_SAMPLES 4
    #define SHADOW_SAMPLES 8

    #define TAA
    #define TEMPORAL_UPSAMPLING 100 // [25 33 50 66 75 83 100]

    #define TAA_TEMPORAL_W_CLAMP 8.0
    #define TAA_JITTER_SCALE 1.0 // [0.0 1.0]

    #define GLOBAL_ILLUMINATION

    #ifdef TAA
    #endif

#endif