#if !defined INCLUDE_SURFACE_MATERIAL
#define INCLUDE_SURFACE_MATERIAL

struct Material {
    vec3 albedo;
    vec3 f0;
    float roughness;
    float sssAmount;
    float emission;
};

vec4 getHardcodedSpecular (vec3 albedo, uint blockId) {
    vec4 specularData = vec4(0.1, 0.1, 0.0, 0.0);

    if (blockId < 32) {
        if (blockId < 8) {
            if (blockId < 4) {
                if (blockId < 2) {
                    specularData.b = 0.35;
                } else {
                    if (blockId < 3) {
                        specularData.b = 0.5;
                    } else {
                        specularData.g = 0.01;
                        specularData.b = 0.8;
                    }
                }
            } else {
                if (blockId < 6) {
                    if (blockId < 5) {
                        specularData.r = sqrt(luminance(albedo));
                        specularData.g = 1.0;
                    } else {

                    }
                } else {
                    if (blockId < 7) {

                    } else {

                    }
                }
            }
        } else {
            if (blockId < 12) {
                if (blockId < 10) {
                    if (blockId < 9) {

                    } else {

                    }
                } else {
                    if (blockId < 11) {

                    } else {
    
                    }
                }
            } else {
                if (blockId < 14) {
                    if (blockId < 13) {

                    } else {

                    }
                } else {
                    if (blockId < 15) {

                    } else {

                    }
                }
            }
        }
    } else if (blockId < 64) {
        specularData.a = sqr(luminance(albedo)) * 254.0 / 255.0;
    }
    
    return specularData;
}

Material applySpecularMap (vec4 specularData, vec3 albedo) {
    Material mat;

    mat.roughness = pow(1.0 - specularData.r, 2.0);
    mat.sssAmount = specularData.b > 64.5 / 255.0 ? (specularData.b * 255.0 / 191.0 - 64.0 / 191.0) : 0.0;
    mat.emission = (specularData.a < 254.5 / 255.0 ? specularData.a * 255.0 / 254.0 : 0.0);

    int reflectanceValue = int(specularData.g * 255.0 + 0.5);
    float metallic;

    if (reflectanceValue < 230) {
        mat.f0 = mix(vec3(0.04), vec3(1.0), specularData.g);
        metallic = 0.0;
    } else {
        mat.f0 = albedo;
        metallic = 1.0;
    }

    mat.albedo = albedo * (1.0 - metallic);

    return mat;
}

#endif // INCLUDE_SURFACE_MATERIAL