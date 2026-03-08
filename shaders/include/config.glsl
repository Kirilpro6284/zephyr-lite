#ifndef INCLUDE_CONFIG
    #define INCLUDE_CONFIG

    const int shadowMapResolution = 2048; // [1024 2048 3072 4096 6144 8192]
    const float shadowDistance = 192.0; // [32.0 48.0 64.0 80.0 96.0 112.0 128.0 144.0 160.0 176.0 192.0 208.0 224.0 240.0 256.0]
    const float shadowDepthDist = 256.0;

    const float sunPathRotation = -50.0; // [-50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0]

    #define COLORED_SHADOWS
    #define SHADOW_VPS

    #define SHADOW_DISTORTION 0.95
    #define SHADOW_BIAS 0.03

    #define SHADOW_MAX_BLOCKER_DEPTH 30.0
    #define SHADOW_SOFTNESS 0.02 // [0.005 0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.045 0.05]
    #define MIN_SHADOW_SOFTNESS 0.02
    #define SHADOW_BLOCKER_RADIUS 1.0
    #define SHADOW_BLOCKER_SAMPLES 4
    #define SHADOW_SAMPLES 6 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]

    #define NIGHT_BRIGHTNESS 0.005 // [0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.010]

    #define TONEMAP_OPERATOR 5 // [0 1 2 3 4 5]

    #define TAA
    #define TEMPORAL_UPSAMPLING 100 // [25 33 50 66 75 83 100]

    #define TAA_TEMPORAL_W_CLAMP 8.0
    #define TAA_JITTER_SCALE 1.0 // [0.0 1.0]

    //#define GLOBAL_ILLUMINATION

    #ifdef TAA
    #endif

#endif