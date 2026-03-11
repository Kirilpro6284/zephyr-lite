#if !defined INCLUDE_UTILITY_PACKING
#define INCLUDE_UTILITY_PACKING

    // Packing functions which can store 0.5 exactly

    uint packExp4x8 (vec4 t) {
        uvec4 result = uvec4(clamp(t * 254.0 + 0.5, 0.0, 254.0));
        return (result.x << 24u) | (result.y << 16u) | (result.z << 8u) | (result.w);
    }

    vec4 unpackExp4x8 (uint t) {
        return (uvec4(t >> 24u, t >> 16u, t >> 8u, t) & 255u) * rcp(254.0);
    }

    uint packExp2x16 (vec2 t) {
        uvec2 result = uvec2(clamp(t * 65534.0 + 0.5, 0.0, 65534.0));
        return (result.x << 16u) | (result.y);
    }

    vec2 unpackExp2x16 (uint t) {
        return (uvec2(t >> 16u, t) & 65535u) * rcp(65534.0);
    }

    vec4 encodeRgbe8 (vec3 data) {
        float exponent = ceil(log2(max(max(data.r, data.g), max(data.b, 1e-38))));

        return vec4(data * exp2(-exponent), rcp(255.0) * (exponent + 126.0));
    }

    vec3 decodeRgbe8 (vec4 data) {
        return data.rgb * exp2(data.a * 255.0 - 126.0);
    }

#endif // INCLUDE_UTILITY_PACKING