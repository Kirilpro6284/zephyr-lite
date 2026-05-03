#if !defined INCLUDE_CONSTANTS
#define INCLUDE_CONSTANTS

const float ambientOcclusionLevel = 0.0;
const float shadowIntervalSize = 4.0;

const bool shadowtex0Nearest = false;
const bool shadowtex1Nearest = false;
const bool shadowcolor0Nearest = true;
const bool shadowcolor1Nearest = true;

const bool shadowHardwareFiltering = true;

const float voxelDistance = 32.0;

/*  
    const int colortex1Format = RGBA16F; // translucent objects (translucent -> composite), average luminance (composite -> temporal)
    const int colortex3Format = RGBA16F; // indirect lighting history
    const int colortex5Format = R11F_G11F_B10F; // bloom tiles
    const int colortex6Format = RGBA16F; // TAA history (temporal)
    const int colortex7Format = RGBA8; // scene color 
    const int colortex8Format = RG32UI; // gbuffer data 0: albedo (8:8:8), blockId (8), geoNormal (8:8), lightLevels (8:8) (solid -> deferred)
    const int colortex9Format = RG32UI; // gbuffer data 1: textureNormal (16:16), specularMap (8:8:8:8) (solid -> deferred)
    const int colortex10Format = RGBA8; // sun & moon geometry (skytextured -> deferred), post-processing data (temporal -> post)
    const int colortex11Format = R32F; // reversed-z depth buffer
    const int colortex12Format = R32F; // previous frame depth buffer

    const bool colortex1Clear = false;
    const bool colortex3Clear = false;
    const bool colortex6Clear = false;
    const bool colortex7Clear = true;
    const bool colortex8Clear = false;
    const bool colortex9Clear = false;
    const bool colortex10Clear = true;
    const bool colortex11Clear = true;
    const bool colortex12Clear = false;

    const vec4 colortex7ClearColor  = vec4(0.0, 0.0, 0.0, 0.0);
    const vec4 colortex10ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
    const vec4 colortex11ClearColor = vec4(0.0, 0.0, 0.0, 0.0);

    const int shadowcolor0Format = RGBA8;
*/

#ifdef SUNLIGHT_GI_LEAK_FIX
    /*
        const int shadowcolor1Format = RGB8;
    */
#else
    /*
        const int shadowcolor1Format = RG8;
    */
#endif

#endif // INCLUDE_CONSTANTS