#ifndef INCLUDE_MAIN
    #define INCLUDE_MAIN

    #define rcp(x) (1.0 / (x))

    #define INFINITY exp2(128.0)
    #define EXPONENT_BIAS 128.0
    
    #if TEMPORAL_UPSAMPLING == 100
        #define TAAU_RENDER_SCALE 1.0
    #elif TEMPORAL_UPSAMPLING == 83
        #define TAAU_RENDER_SCALE 0.83
    #elif TEMPORAL_UPSAMPLING == 75
        #define TAAU_RENDER_SCALE 0.75
    #elif TEMPORAL_UPSAMPLING == 66
        #define TAAU_RENDER_SCALE 0.66
    #elif TEMPORAL_UPSAMPLING == 50
        #define TAAU_RENDER_SCALE 0.50
    #elif TEMPORAL_UPSAMPLING == 33
        #define TAAU_RENDER_SCALE 0.33
    #elif TEMPORAL_UPSAMPLING == 25
        #define TAAU_RENDER_SCALE 0.25
    #endif

    const vec3 shadowProjScale = vec3(rcp(shadowDistance), rcp(shadowDistance), -rcp(shadowDepthDist));
    const vec3 shadowProjScaleInv = vec3(shadowDistance, shadowDistance, -shadowDepthDist);

    // https://twitter.com/Stubbesaurus/status/937994790553227264

    vec2 octEncode (in vec3 n) 
    {
        n.xyz /= abs(n.x) + abs(n.y) + abs(n.z);
        float t = max(0.0, -n.y);
        n.x += (n.x > 0.0) ? t : -t;
        n.z += (n.z > 0.0) ? t : -t;
        return n.xz * 0.5 + 0.5;
    }

    vec3 octDecode (in vec2 f)
    {
        f = f * 2.0 - 1.0;
 
        vec3 n = vec3(f.x, 1.0 - abs(f.x) - abs(f.y), f.y);
        float t = max(0.0, -n.y);
        n.x += n.x >= 0.0 ? -t : t;
        n.z += n.z >= 0.0 ? -t : t;
        return normalize(n);
    }
    
#ifndef STAGE_VOXY_OPAQUE 
    uvec4 getMaterialData (ivec2 texel)
    {
        return uvec4(
            texelFetch(colortex8, texel, 0).rg,
            texelFetch(colortex9, texel, 0).rg
        );
    }

    // https://discordapp.com/channels/237199950235041794/525510804494221312/1416364500591837216
    vec3 blueNoise (vec2 coord) 
    {
        return texelFetch(
            noisetex,
            ivec3(ivec2(coord) % 128, frameCounter % 64),
            0
        ).rgb;
    }

    // R2 sequence from
    // https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/

    vec3 blueNoise (vec2 coord, int i) 
    {
        const float g = 1.324717;

        return blueNoise(coord + 128.0 * fract(0.5 + i * (1.0 / vec2(g, g * g))));
    }
#endif

#endif