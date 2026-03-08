#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/sky/atmosphere.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

#define SSS_ENABLED
#define SSS_INTENSITY 0.2  // [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 27.0 28.0 29.0 30.0 31.0 32.0 33.0 34.0 35.0 36.0 37.0 38.0 39.0 40.0]
#define SSS_ABSORPTION 16.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0 12.5 13.0 13.5 14.0 14.5 15.0 15.5 16.0]
#define SSS_PHASE 0.25     // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

vec3 getSubsurfaceScattering (vec3 albedo, float sssAmount, float mu, float sssDepth)
{
    if (sssAmount < 0.001) return vec3(0.0);

    vec3 coeff = -SSS_ABSORPTION * exp(-0.75 * normalize(albedo)) / sssAmount;

    vec3 s1 = 1.5 * vec3(0.94, 1.0, 0.76) * (luminance(albedo) + 0.02) * exp(3.0 * coeff * sssDepth + 3.0) * schlickPhase(mu, 0.5);
    vec3 s2 = 8.0 * albedo * albedo * exp(0.5 * coeff * sssDepth + SSS_PHASE * mu);

    return getTransmittance(shadowDir) * SSS_INTENSITY * sssAmount * (s1 + s2);
}

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    color.a = 1.0;

    uvec4 materialData = getMaterialData(texel);

    vec4 normalData = unpackExp4x8(materialData.y);

    vec4 albedo = unpackUnorm4x8(materialData.x);
    vec3 normal = octDecode(normalData.xy);
    vec4 specularData = unpackUnorm4x8(materialData.w);

    uint blockId = uint(albedo.a * 255.0 + 0.5);

    albedo.rgb = pow(albedo.rgb, vec3(2.2));

    vec3 f0; float roughness; float emission;

    applySpecularMap(specularData, albedo.rgb, f0, roughness, emission);

    float depth = texelFetch(colortex11, texel, 0).r;

    vec3 playerPos = screenToPlayerPos(internalTexelSize * gl_FragCoord.xy, depth).xyz;

    if (depth == 1.0) {
        color.rgb = EXPONENT_BIAS * getAtmosphereScattering(normalize(playerPos));
        return;
    }
    
    vec2 dither = blueNoise(gl_FragCoord.xy).rg;

    vec3 shadowViewPos = (shadowModelView * vec4(playerPos, 1.0)).xyz;

    #ifdef SHADOW_VPS
        float blockerDepth = getBlockerDepth(shadowViewPos, dither);
    #endif

    vec3 lighting = vec3(0.0);

    float shadowLightBrightness = sunDir.y < 0.0 ? NIGHT_BRIGHTNESS : 1.0;

    lighting += shadowLightBrightness * getTransmittance(shadowDir) * evalCookBRDF(shadowDir, -normalize(playerPos), roughness, normal, albedo.rgb, f0) * getShadow(shadowViewPos, normal, dither
        #ifdef SHADOW_VPS
            , blockerDepth
        #endif
    );

    lighting += normalData.w * normalData.w * albedo.rgb * getAtmosphereScattering(vec3(0.0, 1.0, 0.0));

    if (blockId == 4) lighting += shadowLightBrightness * getSubsurfaceScattering(albedo.rgb, 1.0, dot(normalize(playerPos), shadowDir), blockerDepth);

    color = vec4(EXPONENT_BIAS * lighting, 1.0);
}