#ifndef INCLUDE_MAIN
    #define INCLUDE_MAIN

    #define rcp(x) (1.0 / (x))

    #define rcp(x)       (1.0 / (x))
    #define max0(x)      max(x, 0.0)
    #define min1(x)      min(x, 1.0)
    #define saturate(x)  clamp(x, 0.0, 1.0)
    #define HALF_PI      1.57079632
    #define PI           3.14159265
    #define TWO_PI       6.28318530
    #define INFINITY     exp2(128.0)
    #define luminance(c) dot(c, vec3(0.2126, 0.7152, 0.0722))
    #define torad(x)     (0.01745329 * x)
    #define hermite(x)   smoothstep(0.0, 1.0, x)

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

    const ivec3 voxelVolumeSize = ivec3(128, 128, 128);
    const ivec3 halfVoxelVolumeSize = ivec3(64, 64, 64);

    void applySpecularMap (vec4 specularData, inout vec3 albedo, out vec3 f0, out float roughness, out float emission) 
    {
        roughness = pow(1.0 - specularData.r, 2.0);
        emission = (specularData.a < 254.5 / 255.0 ? specularData.a * 255.0 / 254.0 : 0.0);

        int reflectanceValue = int(specularData.g * 255.0 + 0.5);
        float metallic;

        if (reflectanceValue < 230) {
            f0 = mix(vec3(0.04), vec3(1.0), specularData.g);
            metallic = 0.0;
        } else {
            f0 = albedo;
            metallic = 1.0;
        }

        albedo *= (1.0 - metallic);
    }

    mat2 rotate (float theta)
    {
        float cosTheta = cos(theta);
        float sinTheta = sin(theta);

        return mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
    }

    float sqr (float x)
    {
        return x * x;
    }

    vec2 sqr (vec2 x)
    {
        return x * x;
    }

    vec3 sqr (vec3 x)
    {
        return x * x;
    }

    float lift (float x, float a)
    {
        return x / (a * abs(x) + 1.0 - a);
    }
	
	float liftInv (float x, float a)
    {
        return x * (1.0 - a) / (1.0 - abs(x) * a);
    }

    // Adapted from https://www.youtube.com/watch?v=Qz0KTGYJtUk&t=674s

    uint randomInt (inout uint state)
    {
        state = state * 747796405u + 2891336453u;
        uint result = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
        return (result >> 22u) ^ result;
    }

    float randomValue (inout uint state) 
    {
        return randomInt(state) * (1.0 / 4294967296.0);
    }

    float normalDist (inout uint state)
    {
        return sqrt(-log2(randomValue(state))) * cos(TWO_PI * randomValue(state));
    }

    vec3 randomDir (inout uint state)
    {	
        return normalize(vec3(normalDist(state), normalDist(state), normalDist(state)));
    }

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

    mat3 tbnNormalTangent (vec3 normal, vec4 tangent) 
    {
        return mat3(tangent.xyz, cross(tangent.xyz, normal) * sign(tangent.w), normal);
    }

    mat3 tbnNormal (vec3 normal) 
    {
        return tbnNormalTangent(normal, vec4(normalize(cross(normal, abs(normal.y) > abs(normal.z) ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0))), 1.0));
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