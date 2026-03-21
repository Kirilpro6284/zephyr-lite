#ifndef INCLUDE_CONFIG
    #define INCLUDE_CONFIG

    const int shadowMapResolution = 2048; // [1024 2048 3072 4096 6144 8192]
    const float shadowDistance = 192.0; // [32.0 48.0 64.0 80.0 96.0 112.0 128.0 144.0 160.0 176.0 192.0 208.0 224.0 240.0 256.0]
    const float shadowDepthDist = 256.0;

    const float sunPathRotation = -40.0; // [-45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0]

    #define COLORED_LIGHTING
    #define VOXELIZATION_DISTANCE 64 // [64 128 192 256]

    #define EMISSION_BRIGHTNESS 2.5 

    #define COLORED_SHADOWS
    #define SHADOW_VPS

    #define DYNAMIC_EXPOSURE
    #define ADAPTATION_SPEED 0.03
    #define MANUAL_EXPOSURE 10.0

    #define SHADOW_BIAS 0.03

    #define SHADOW_MAX_BLOCKER_DEPTH 40.0
    #define SHADOW_SOFTNESS 0.015 // [0.005 0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.045 0.05]
    #define SHADOW_BLOCKER_RADIUS 0.5
    #define SHADOW_BLOCKER_SAMPLES 8
    #define SHADOW_SAMPLES 8 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]
    #define SHADOW_SMOOTHING 2.5

    #define SS_REFLECTIONS
    #define SSR_PRIMARY_STEP_COUNT 8
    #define SSR_REFINEMENT_STEP_COUNT 5

    #define SUNLIGHT_TINT_R 0.60
    #define SUNLIGHT_TINT_G 0.60
    #define SUNLIGHT_TINT_B 0.60

    #define SKYLIGHT_TINT_R 0.50
    #define SKYLIGHT_TINT_G 0.52
    #define SKYLIGHT_TINT_B 0.60

    #define SUNLIGHT_TINT vec3(SUNLIGHT_TINT_R, SUNLIGHT_TINT_G, SUNLIGHT_TINT_B)
    #define SKYLIGHT_TINT vec3(SKYLIGHT_TINT_R, SKYLIGHT_TINT_G, SKYLIGHT_TINT_B)

    #define NIGHT_BRIGHTNESS 0.005 // [0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.010]

    #define INDIRECT_LIGHTING
    #define INDIRECT_RENDER_SCALE 70
    #define INDIRECT_TEMPORAL_BLEND_WEIGHT 0.03

    #define GTAO_RADIUS 0.5
    #define GTAO_SLICES 1
    #define GTAO_HORIZON_STEPS 4

    #define SUNLIGHT_GI_SAMPLES 8
    #define SUNLIGHT_GI_RANGE 4.0

    #define SSS_ENABLED
    #define SSS_INTENSITY 0.5  // [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 27.0 28.0 29.0 30.0 31.0 32.0 33.0 34.0 35.0 36.0 37.0 38.0 39.0 40.0]
    #define SSS_ABSORPTION 15.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0 12.5 13.0 13.5 14.0 14.5 15.0 15.5 16.0]

    #define tonemap acesFilmic // [agx lottes neutral acesFilmic reinhard2 exponential tonemap_none tonyMcMapface]

    #define TAA
    #define TEMPORAL_UPSAMPLING 1 // [1 2 3 4]

    #define TAA_TEMPORAL_W_CLAMP 8.0
    #define TAA_JITTER_SCALE 1.0 // [0.0 1.0]

    #define PURKINJE_EFFECT
    #define PURKINJE_AMOUNT 1.0 // [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

    //#define ENABLE_TEXT_RENDERING

    #ifdef TAA
    #endif

    #ifdef PURKINJE_EFFECT
    #endif

    #ifdef COLORED_LIGHTING
    #endif

    #ifdef INDIRECT_LIGHTING
    #endif

#endif