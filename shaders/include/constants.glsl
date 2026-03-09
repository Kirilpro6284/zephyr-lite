#ifndef INCLUDE_CONSTANTS
    #define INCLUDE_CONSTANTS

    const float ambientOcclusionLevel = 0.0;
    const float shadowIntervalSize = 4.0;

    const bool shadowtex0Nearest = false;
    const bool shadowtex1Nearest = false;
    const bool shadowcolor0Nearest = true;
    const bool shadowcolor1Nearest = true;

    const bool shadowHardwareFiltering = true;

    /*  
        const int colortex1Format = RGBA16F; // translucent objects (translucent -> composite)
        const int colortex6Format = RGBA16F; // TAA history (temporal)
        const int colortex7Format = R11F_G11F_B10F; // scene
        const int colortex8Format = RG32UI; // gbuffer data 0: albedo (8:8:8), blockId (8), geoNormal (8:8), lightLevels (8:8) (solid -> deferred)
        const int colortex9Format = RG32UI; // gbuffer data 1: textureNormal (16:16), specularMap (8:8:8:8) (solid -> deferred)
        const int colortex10Format = R11F_G11F_B10F; // post-processing data (temporal -> post)
        const int colortex11Format = R32F; // combined lod depth buffer

        const bool colortex1Clear = true;
        const bool colortex6Clear = false;
        const bool colortex7Clear = true;
        const bool colortex8Clear = false;
        const bool colortex9Clear = false;

        const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
        const vec4 colortex7ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
    */

#endif