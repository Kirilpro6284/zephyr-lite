#if !defined INCLUDE_SURFACE_MATERIAL
#define INCLUDE_SURFACE_MATERIAL

#include "/include/utility/colorMatrices.glsl"

struct Material {
    vec3 albedo;
    float roughness;
    vec3 f0;
    vec3 emissive;
    float sssAmount;
};

vec4 getHardcodedSpecular(vec3 albedo, uint geometryId) {
    vec4 specularData = vec4(smoothstep(0.0, 0.6, luminance(albedo)) * vec2(0.1, 0.15), 0.0, 0.0);

    if (geometryId == 4u || geometryId == 6u) {
        specularData.r = sqrt(dot(albedo, rgbToXyz[1]));
        specularData.g = 1.0;
    }

    if (geometryId == 3) specularData.g = 0.01;

    switch (geometryId) {
        case 1u: 
            specularData.b = 0.35;
            break;
        case 2u:
            specularData.b = 0.5;
            break;
        case 3u:
            specularData.b = 0.8;
            break;
        case 7u:
            specularData.b = 0.5;
            break;
    }
        
    if (geometryId >= 32u && geometryId < 64u) specularData.a = 0.04 + 0.96 * smoothstep(0.4, 1.0, dot(albedo, rgbToXyz[1])) * (254.0 / 255.0);

    return specularData;
}

Material getMaterial(vec4 specularData, vec3 albedo) {
    albedo = pow(albedo, vec3(2.2)) * rgbToAp1Unlit;

    Material material;

    material.roughness = clamp(ROUGHNESS_SCALE * sqr(1.0 - specularData.r), 0.02, 1.0);
    material.sssAmount = specularData.b > 64.5 / 255.0 ? (specularData.b * 255.0 / 191.0 - 64.0 / 191.0) : 0.0;
    material.emissive = EMISSIVE_SCALE * fract(specularData.a) * albedo;

    float metallic;

    if (specularData.g < 229.5 / 255.0) {
        material.f0 = mix(vec3(0.04), vec3(1.0), specularData.g);
        metallic = 0.0;
    } else {
        material.f0 = albedo;
        metallic = 1.0;
    }

    material.albedo = albedo * (1.0 - metallic);

    return material;
}

#endif // INCLUDE_SURFACE_MATERIAL