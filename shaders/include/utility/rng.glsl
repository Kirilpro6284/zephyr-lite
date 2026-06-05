#if !defined INCLUDE_UTILITY_RNG
#define INCLUDE_UTILITY_RNG

float getInterleavedGradientNoise (vec2 coord) { 
    return fract(fract(dot(floor(coord), vec2(3.5557133, 0.3092692))) + 0.6180339 * float(frameCounter & 127)); 
}

float R1(uint v) {
    return fract(rcp(phi1) * v + 0.5);
}

float R1(uint v, float offset) {
    return fract(rcp(phi1) * v + offset);
}

vec2 R2(uint v) {
    return fract(rcp(vec2(phi2, phi2 * phi2)) * v + 0.5);
}

vec2 R2(uint v, vec2 offset) {
    return fract(rcp(vec2(phi2, phi2 * phi2)) * v + offset);
}

vec3 R3(uint v) {
    return fract(rcp(vec3(phi3, phi3 * phi3, phi3 * phi3 * phi3)) * v + 0.5);
}

vec3 R3(uint v, vec3 offset) {
    return fract(rcp(vec3(phi2, phi2 * phi2, phi3 * phi3 * phi3)) * v + offset);
}

// Adapted from https://www.youtube.com/watch?v=Qz0KTGYJtUk&t=674s

uint randomInt (inout uint state) {
    state = state * 747796405u + 2891336453u;
    uint result = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (result >> 22u) ^ result;
}

float randomValue (inout uint state) {
    return clamp(randomInt(state) * rcp(4294967295.0), 0.0, 16777215.0 / 16777216.0);
}

float normalDist (inout uint state) {
    return sqrt(-log2(randomValue(state))) * cos(TWO_PI * randomValue(state));
}

vec3 randomDir (inout uint state) {	
    return normalize(vec3(normalDist(state), normalDist(state), normalDist(state)));
}

#endif // INCLUDE_UTILITY_RNG