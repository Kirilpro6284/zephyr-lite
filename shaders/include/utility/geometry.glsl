#if !defined INCLUDE_UTILITY_GEOMETRY
#define INCLUDE_UTILITY_GEOMETRY

bool raySphere(vec3 rayPos, vec3 rayDir, float radius, out vec2 t) {
    float d = sqr(dot(rayPos, rayDir)) - dot(rayPos, rayPos) + radius * radius;

    if (d < 0.0) return false;

    d = sqrt(d);

    float cosTheta = dot(rayPos, rayDir);
    float invDet = rcp(-dot(rayDir, rayDir));

    float dstNear = (cosTheta + d) * invDet;
    float dstFar  = (cosTheta - d) * invDet;

    if (dstFar < 0.0) return false;

    t.x = dstNear;
    t.y = dstFar;

    return true;
}

#endif // INCLUDE_UTILITY_GEOMETRY