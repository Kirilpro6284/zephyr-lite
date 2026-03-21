#if !defined INCLUDE_BSDF
#define INCLUDE_BSDF

float rayleighPhase (float cosTheta)
{
    return (1.0 + cosTheta * cosTheta) * 3.0 / (16.0 * PI);
}

float schlickPhase (float cosTheta, float k)
{
    return (1.0 - k * k) / (4.0 * PI * sqr(1.0 - k * cosTheta));
}

float kleinNishinaPhase (float cosTheta, float e) 
{
    return e / (TWO_PI * (e * (1.0 - cosTheta) + 1.0) * log(e * 2.0 + 1.0));
}

vec3 getSchlickFresnel (vec3 F0, float theta)
{  
    return F0 + (1.0 - F0) * pow(1.0 - theta, 5.0);
}

float ggx (float NdotH, float NdotV, float NdotL, float roughness)
{   
    float alpha = sqr(roughness);
    float alpha2 = sqr(alpha);

    float k = 0.5 * alpha;

    float lowerTerm = NdotH * NdotH * (alpha2 - 1.0) + 1.0;
    float normalDistributionFunctionGGX = alpha2 * rcp(PI * lowerTerm * lowerTerm);

    return normalDistributionFunctionGGX * (NdotL * NdotV) / (mix(k, 1.0, NdotL) * mix(k, 1.0, NdotV) * (4.0 * NdotV));
}

vec3 evalCookBRDF (
    vec3 w0, 
    vec3 w1, 
    float roughness, 
    vec3 normal, 
    vec3 albedo, 
    vec3 reflectance
) {
    vec3 H = normalize(w0 + w1);

    // dot products
    float VdotL = clamp(dot(w0, w1), 0.001, 1.0);
    float NdotV = clamp(dot(normal, w1), 0.001, 1.0);
    float NdotL = clamp(dot(normal, w0), 0.001, 1.0);
    float NdotH = clamp(dot(normal, H), 0.001, 1.0);
    float VdotH = clamp(dot(w1, H), 0.001, 1.0);

    const float diffuseBackScattering = 0.3;

    return mix(
        NdotL * albedo * schlickPhase(VdotL, diffuseBackScattering) * 4.0 * PI, 
        vec3(ggx(NdotH, NdotV, NdotL, roughness)), 
        getSchlickFresnel(reflectance, VdotH)
    );
}

#endif // INCLUDE_BSDF