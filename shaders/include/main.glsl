
#if !defined STAGE_VOXY
    #include "/include/uniforms.glsl"
#endif

#include "/include/config.glsl"

// ----- Macros -----

#ifdef fsh
    #define varying in
#endif

#ifdef vsh
    #define varying out
#endif

#define rcp(x) (1.0 / (x))
#define max0(x) max(x, 0.0)
#define min1(x) min(x, 1.0)
#define clamp01(x) clamp(x, 0.0, 1.0)
#define luminance(c) dot(c, ap1RgbY)
#define step0(x) step(0.0, x)
#define smoothstep01(x) smoothstep(0.0, 1.0, x)

#define acosSafe(x) acos(clamp(x, -1.0, 1.0))
#define log2Safe(x) log2(max(x, eps))
#define sqrtSafe(x) sqrt(max(x, 0.0))
#define rcpSafe(x) (1.0 / max(x, eps))

#if TEMPORAL_UPSAMPLING == 1
    #define taauRenderScale 1.0 
#elif TEMPORAL_UPSAMPLING == 2
    #define taauRenderScale 0.7071 
#elif TEMPORAL_UPSAMPLING == 3
    #define taauRenderScale 0.5773 
#elif TEMPORAL_UPSAMPLING == 4
    #define taauRenderScale 0.5 
#endif

// ----- Constants -----

const float eps = 1e-4;

const float phi1 = 1.6180340;
const float phi2 = 1.3247180;
const float phi3 = 1.2207441;

const float HALF_PI = 1.57079632;
const float PI = 3.14159265;
const float TWO_PI = 6.28318530;

const mat2 vogelPhase = mat2(
    cos(0.2451223 * TWO_PI), -sin(0.2451223 * TWO_PI), 
    sin(0.2451223 * TWO_PI), cos(0.2451223 * TWO_PI)
);

const vec3 shadowProjScale = vec3(rcp(shadowDistance), rcp(shadowDistance), rcp(-shadowDepthDist));
const vec3 shadowProjScaleInv = vec3(shadowDistance, shadowDistance, -shadowDepthDist);

// ----- Functions -----

mat2 rotate(float theta) {
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);

    return mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
}

vec3 clipAABB(vec3 origin, vec3 dir, vec3 boxMin, vec3 boxMax) {
    vec3 invDir = rcpSafe(dir);
    vec3 t2 = max((boxMin - origin) * invDir, (boxMax - origin) * invDir);

    return dir * min(min(t2.x, t2.y), t2.z);
}

float sqr(float x) {
    return x * x;
}

vec2 sqr(vec2 x) {
    return x * x;
}

vec3 sqr(vec3 x) {
    return x * x;
}

float lift(float x, float a) {
    return x / (a * abs(x) + 1.0 - a);
}

float liftInv(float x, float a) {
    return x * (1.0 - a) / (1.0 - abs(x) * a);
}

float invLength(vec2 v) {
	return inversesqrt(dot(v, v));
}

float invLength(vec3 v) {
	return inversesqrt(dot(v, v));
}

float invLength(vec4 v) {
	return inversesqrt(dot(v, v));
}

float lengthSquared(vec2 v) {
	return dot(v, v);
}

float lengthSquared(vec3 v) {
	return dot(v, v);
}

float lengthSquared(vec4 v) {
	return dot(v, v);
}

float distanceSquared(vec2 a, vec2 b) {
	return lengthSquared(a - b);
}

float distanceSquared(vec3 a, vec3 b) {
	return lengthSquared(a - b);
}

float distanceSquared(vec4 a, vec4 b) {
	return lengthSquared(a - b);
}

float signum(float v) {
	return v < 0.0 ? -1.0 : 1.0;
}

vec2 signum(vec2 v) {
	return vec2(signum(v.x), signum(v.y));
}

vec3 signum(vec3 v) {
	return vec3(signum(v.x), signum(v.y), signum(v.z));
}
