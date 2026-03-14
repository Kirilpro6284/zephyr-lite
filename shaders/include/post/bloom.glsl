#if !defined INCLUDE_POST_BLOOM
#define INCLUDE_POST_BLOOM

#include "/include/utility/textureSampling.glsl"

uint getBloomTileIndex (vec2 uv) {
    float t = step(0.625, uv.y);

    return uint(t + 2.0 * max(t, -floor(log2(1.0 - uv.x) * 0.5 + (uv.y > 0.625 ? log2(1.25) : -log2(1.125)))) - 2.0);
}

vec2 getBloomCoord (vec2 uv, uint tileIndex) {
    float w = exp2(-float(tileIndex + 1));

    return (uv - vec2(1.0 - 2.0 * w, float(tileIndex % 2) * (1.0 - w))) * exp2(float(tileIndex + 1));
}

vec2 getBloomCoordInv (vec2 uv, uint tileIndex) {
    float w = exp2(-float(tileIndex + 1));

    return vec2(1.0 - 2.0 * w, float(tileIndex % 2) * (1.0 - w)) + uv * w;
}

const float bloomIntensity = 0.003;
const int bloomTiles = 7;

vec3 getBloom (vec2 uv) {
    vec3 result = vec3(0.0);

    for (int tile = 0; tile < bloomTiles; tile++) {
        result += texBicubic(colortex5, getBloomCoordInv(uv, tile), vec2(1920.0, 1080.0)).rgb;
    }

    return bloomIntensity * result;
}

#endif // INCLUDE_POST_BLOOM