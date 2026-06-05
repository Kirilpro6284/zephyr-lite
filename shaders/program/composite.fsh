
#include "/include/main.glsl"

// ----- Outputs -----

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 colorRgbe8;

// ----- Includes -----

#include "/include/utility/encoding.glsl"
#include "/include/utility/spaceConversion.glsl"

#include "/include/surface/bsdf.glsl"
#include "/include/surface/waterVolume.glsl"

#include "/include/atmospherics/atmosphere.glsl"

#include "/include/lighting/shadowMapping.glsl"

// ----- Functions -----

const float airFogRenderScale = 0.01 * AIR_FOG_RENDER_SCALE;

void main() {
    ivec2 texel = ivec2(gl_FragCoord.xy);

    float backDepth = texelFetch(lodDepthTex1, texel, 0).r;
    float frontDepth = texelFetch(lodDepthTex0, texel, 0).r;

    float dither = getInterleavedGradientNoise(gl_FragCoord.xy);

    vec3 directIrradiance = shadowLightBrightness * getAtmosphereTransmittance(shadowDir);

    vec2 coord = internalTexelSize * gl_FragCoord.xy;

    vec3 viewPos = screenToViewPos(coord, frontDepth);
    vec3 viewDir = normalize(mat3(gbufferModelViewInverse) * viewPos);

    vec4 waterMask = texelFetch(colortex8, texel, 0);
    vec3 waterNormal = octDecode(waterMask.rg);
    
    vec4 translucents = texelFetch(colortex1, texel, 0);
    
#ifdef VOXY
    vec4 voxyTranslucents = texelFetch(colortex16, texel, 0);

    //translucents = voxyTranslucents;

    translucents.rgb += voxyTranslucents.rgb * (1.0 - translucents.a);
    translucents.a += voxyTranslucents.a * (1.0 - translucents.a);
#endif

    vec3 color;
    float refractedDepth;

    if (waterMask.a > 0.5) {
        vec2 refractedCoord = clamp(coord + 0.2 * step(0.5, abs(waterNormal.y)) * rcp(viewDistance * waterMask.b) * gbufferProjScale.xy * waterNormal.xz, 0.5 * internalTexelSize, 1.0 - 0.5 * internalTexelSize);

        color = textureRgbe8(colortex7, refractedCoord, internalScreenSize);
        refractedDepth = texture(lodDepthTex1, refractedCoord).r;
    } else {
        color = decodeRgbe8(texelFetch(colortex7, texel, 0));
        refractedDepth = backDepth;
    }

    float mu = dot(viewDir, shadowDir);

    float depthToDist = length(vec3(gbufferProjScaleInv.xy * (coord * 2.0 - 1.0), 1.0));

    float currDist = depthToDist * -viewPos.z;
    float waterDist = depthToDist * viewDistance * waterMask.b;
    float backDist = depthToDist * linearizeDepth(refractedDepth);

    color = getWaterFog(color, directIrradiance, isEyeInWater == 1 ? (waterMask.a > 0.5 ? waterDist : currDist) : step(0.5, waterMask.a) * float(backDepth != 0.0) * max0(backDist - waterDist), mu);

    if (isEyeInWater == 1 && waterMask.a > 0.5) {
        translucents.rgb = getWaterFog(translucents.rgb, directIrradiance, currDist, mu);

        if (refract(viewDir, waterNormal, 1.3) == vec3(0.0)) {
            translucents.a = 1.0;
        } else {
            translucents = vec4(0.0);
        }
    }

    float linearDepth = linearizeDepth(frontDepth);

    vec2 fogCoord = airFogRenderScale * gl_FragCoord.xy - 0.5;
    ivec2 fogTexel = ivec2(fogCoord);

    vec4 fogData = vec4(0.0);
    float weights = 0.0;

    fogCoord = -fract(fogCoord);

    for (int x = 0; x <= 1; x++) {
        for (int y = 0; y <= 1; y++) {
            float depthSample = linearizeDepth(texelFetch(lodDepthTex0, ivec2((fogTexel + ivec2(x, y) + 0.5) * rcp(airFogRenderScale)), 0).r);

            float weight = bilinearWeight(fogCoord, vec2(x, y)) * max(eps, exp(-0.5 * abs(depthSample - linearDepth)));

            fogData += weight * texelFetch(colortex2, fogTexel + ivec2(x, y), 0);
            weights += weight;
        }
    }

    fogData *= rcp(weights);

    colorRgbe8 = encodeRgbe8(mix(color, translucents.rgb, translucents.a) * fogData.a + fogData.rgb);
}