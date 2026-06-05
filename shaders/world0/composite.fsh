#version 430 compatibility

#include "/include/main.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/surface/bsdf.glsl"
#include "/include/surface/waterVolume.glsl"
#include "/include/atmospherics/atmosphere.glsl"
#include "/include/lighting/shadowMapping.glsl"

/* RENDERTARGETS: 2 */
layout (location = 0) out vec4 fogData;

// ----- Functions -----

const float airFogRenderScale = 0.01 * AIR_FOG_RENDER_SCALE;

vec4 raymarchAirFog(vec3 scenePos, float dither) {
    vec3 directIrradiance = shadowLightBrightness * getAtmosphereTransmittance(shadowDir);
    vec3 skyIrradiance = (eyeBrightnessSmooth.y / 240.0) * getSkyIrradiance(vec3(0.0, 1.0, 0.0));

    vec3 rayPos = gbufferModelViewInverse[3].xyz;
    vec3 rayDir = scenePos - rayPos;

    float upperPlane = -(rayPos.y + eyeAltitude - 128.0) / rayDir.y;

    if (rayPos.y + eyeAltitude < 128.0) {
        if (rayDir.y > 0.0 && upperPlane < 1.0) {
            rayDir *= upperPlane;
        }
    } else {
        if (rayDir.y < 0.0) {
            if (upperPlane < 1.0) {
                rayPos += rayDir * upperPlane;
                rayDir *= 1.0 - upperPlane;
            } else {
                return vec4(0.0, 0.0, 0.0, 1.0);
            }
        }
    }

    rayDir *= rcp(AIR_FOG_SCATTER_POINTS);

    float stepSize = length(rayDir);

    if (stepSize > viewDistance * rcp(AIR_FOG_SCATTER_POINTS)) {
        rayDir *= viewDistance / (stepSize * AIR_FOG_SCATTER_POINTS);
        stepSize = viewDistance * rcp(AIR_FOG_SCATTER_POINTS);
    }

    rayPos += rayDir * dither;

    vec3 shadowRayPos = shadowProjScale * (mat3(shadowModelView) * rayPos + shadowModelView[3].xyz);
    vec3 shadowRayDir = shadowProjScale * (mat3(shadowModelView) * rayDir);

    vec4 scattering = vec4(0.0, 0.0, 0.0, 1.0);

    float phase = kleinNishinaPhase(dot(rayDir, shadowDir) / stepSize, 2400.0) + 0.25;
    float fogDensity = shadowDir.x * shadowDir.x * abs(shadowDir.x) * 0.002 + 0.0005;

    for (int i = 0; i < AIR_FOG_SCATTER_POINTS; i++, rayPos += rayDir, shadowRayPos += shadowRayDir) {
        float density = stepSize * fogDensity * exp(-0.1 * max0(rayPos.y + eyeAltitude - 63.0));

        scattering.a *= exp(-min1(float(i) + dither) * density);
        scattering.rgb += scattering.a * density * (phase * directIrradiance * texture(shadowtex0HW, vec3(distortShadowPos(shadowRayPos.xy), shadowRayPos.z) * 0.5 + 0.5) + (eyeBrightnessSmooth.y / 240.0) * skyIrradiance);
    }

    return scattering;
}

void main() {
    ivec2 texel = ivec2(rcp(airFogRenderScale) * gl_FragCoord.xy);
    vec2 coord = internalTexelSize * rcp(airFogRenderScale) * gl_FragCoord.xy;

    if (clamp01(coord) != coord) {
        fogData = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    float depth = texelFetch(lodDepthTex0, texel, 0).r;

    float dither = getInterleavedGradientNoise(gl_FragCoord.xy);

    vec3 scenePos = screenToScenePos(coord, depth);

    fogData = raymarchAirFog(scenePos, dither);
}