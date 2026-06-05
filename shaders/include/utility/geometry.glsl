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

bool rayBox(vec3 rayPos, vec3 rayDir, vec3 boxMin, vec3 boxMax, out vec2 t) {
    vec3 invDir = rcp(rayDir);

    vec3 tMin = (boxMin - rayPos) * invDir;
    vec3 tMax = (boxMax - rayPos) * invDir;

    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);

    t.x = max(max(t1.x, t1.y), t1.z);
    t.y = min(min(t2.x, t2.y), t2.z);

    return t.y < t.x;
}

#endif // INCLUDE_UTILITY_GEOMETRY