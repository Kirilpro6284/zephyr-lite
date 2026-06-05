#if !defined INCLUDE_UTILITY_TBN
#define INCLUDE_UTILITY_TBN

mat3 tbnNormalTangent(vec3 normal, vec4 tangent) {
    return mat3(tangent.xyz, cross(tangent.xyz, normal) * sign(tangent.w), normal);
}

mat3 tbnNormal(vec3 normal) {
    return tbnNormalTangent(normal, vec4(normalize(cross(normal, abs(normal.y) > abs(normal.z) ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0))), 1.0));
}

#endif // INCLUDE_UTILITY_TBN