#if !defined INCLUDE_UTILITY_PACKING
#define INCLUDE_UTILITY_PACKING

vec2 octEncode(vec3 normal) {
	normal /= abs(normal.x) + abs(normal.y) + abs(normal.z);

	return (normal.xy + step(normal.z, 0.0) * signum(normal.xy) * (1.0 - abs(normal.x) - abs(normal.y))) * 0.5 + 0.5;
}

vec3 octDecode(vec2 encodedNormal) {
	vec3 normal;

	normal.xy = encodedNormal * 2.0 - 1.0;
	normal.z = 1.0 - abs(normal.x) - abs(normal.y);
	normal.xy += sign(normal.xy) * min(0.0, 1.0 - abs(normal.x) - abs(normal.y));
	
	return normalize(normal);
}

uint packUnorm2x8(vec2 v) {
	return uint(v.y * 255.0 + 0.5) * 256u + uint(v.x * 255.0 + 0.5);
}

vec2 unpackUnorm2x8(uint v) {
	return vec2(v & 255u, (v >> 8u) & 255u) * rcp(255.0);
}

vec4 encodeRgbe8(vec3 data) {
    float exponent = ceil(log2(max(max(data.r, data.g), max(data.b, 5.877472e-39))));

    return vec4(data * exp2(-exponent), (exponent + 127.0) * rcp(255.0));
}

vec3 decodeRgbe8(vec4 data) {
    return data.rgb * uintBitsToFloat(uint(data.a * 255.5) << 23u);
}

#endif // INCLUDE_UTILITY_PACKING