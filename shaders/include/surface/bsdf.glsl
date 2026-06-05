#if !defined INCLUDE_SURFACE_BSDF
#define INCLUDE_SURFACE_BSDF

#include "/include/surface/material.glsl"

float rayleighPhase(float cosTheta) {
    return (1.0 + cosTheta * cosTheta) * 3.0 / (16.0 * PI);
}

float schlickPhase(float cosTheta, float k) {
    return (1.0 - k * k) / (4.0 * PI * sqr(1.0 - k * cosTheta));
}

float kleinNishinaPhase(float cosTheta, float e) {
    return e / (TWO_PI * (e * (1.0 - cosTheta) + 1.0) * log(e * 2.0 + 1.0));
}

vec3 getSchlickFresnel(vec3 f0, float theta) {  
    return f0 + (1.0 - f0) * pow(1.0 - theta, 5.0);
}

float getSchlickFresnel(float f0, float theta) {
    return f0 + (1.0 - f0) * pow(1.0 - theta, 5.0);
}

float G_Smith(float NdotV, float alpha) {
    return 2.0 * NdotV / (NdotV + sqrt(alpha * alpha + (1.0 - alpha * alpha) * NdotV * NdotV));
}

float D_GGX(float NdotH, float alpha) {
    float alpha2 = alpha * alpha;
    
    return alpha2 / (PI * sqr(NdotH * NdotH * (alpha2 - 1.0) + 1.0));
}

vec3 phongDiffuse(float NdotL, vec3 albedo) {
    return NdotL * albedo;
}

vec3 getSurfaceBsdf(
    vec3 viewDir,
    vec3 lightDir,
    vec3 normal,
    Material material
) {
    float alpha = material.roughness * material.roughness;

    vec3 halfway = normalize(lightDir + viewDir);

    float NdotV = clamp(dot(viewDir, normal), eps, 1.0);
    float NdotL = clamp(dot(lightDir, normal), eps, 1.0);
    float NdotH = clamp(dot(halfway, normal), eps, 1.0);
    float VdotH = clamp(dot(viewDir, halfway), eps, 1.0);

    vec3 reflectance = getSchlickFresnel(material.f0, VdotH);

	vec3 diffuse = phongDiffuse(NdotL, material.albedo);
	vec3 specular = vec3(G_Smith(NdotV, alpha) * G_Smith(NdotL, alpha) * D_GGX(NdotH, alpha) * rcpSafe(4.0 * NdotV));

    return diffuse * (1.0 - reflectance) + specular * reflectance;
}

#endif // INCLUDE_SURFACE_BSDF