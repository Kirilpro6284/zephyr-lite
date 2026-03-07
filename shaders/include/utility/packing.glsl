#ifndef INCLUDE_PACKING
    #define INCLUDE_PACKING

    // Explicit packing that can store 0.5 exactly

    uint packExp4x8 (vec4 t) 
    {
        uvec4 result = uvec4(clamp(t * 254.0 + 0.5, 0.0, 254.0));
        return (result.x << 24u) | (result.y << 16u) | (result.z << 8u) | (result.w);
    }

    vec4 unpackExp4x8 (uint t) 
    {
        return (uvec4(t >> 24u, t >> 16u, t >> 8u, t) & 255u) * rcp(254.0);
    }

    uint packExp2x16 (vec2 t) 
    {
        uvec2 result = uvec2(clamp(t * 65534.0 + 0.5, 0.0, 65534.0));
        return (result.x << 16u) | (result.y);
    }

    vec2 unpackExp2x16 (uint t) 
    {
        return (uvec2(t >> 16u, t) & 65535u) * rcp(65534.0);
    }

#endif