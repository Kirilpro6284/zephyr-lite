#version 430 compatibility

#include "/include/main.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 colorRgbe8;

// ----- Includes -----

#include "/include/atmospherics/cloudVolume.glsl"

#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/rng.glsl"

// ----- Functions -----

void main () {
    ivec2 texel = ivec2(gl_FragCoord.xy);

    vec2 coord = internalTexelSize * gl_FragCoord.xy;

    float dither = R1(frameCounter % 64, texelFetch(noisetex0, texel % 256, 0).r);

    vec3 directIrradiance = shadowLightBrightness * getAtmosphereTransmittance(vec3(0.0, planetRadius + ALTITUDE_BIAS + cloudAltitude, 0.0), shadowDir);
    vec3 skyIrradiance = rcp(SKYLIGHT_TINT) * getSkyIrradiance(vec3(0.0, 1.0, 0.0));

    float depth = texelFetch(lodDepthTex1, texel, 0).r;

    vec3 viewPos = screenToViewPos(coord, depth);
    vec3 scenePos = viewToScenePos(viewPos);

    vec3 rayPos = gbufferModelViewInverse[3].xyz;
    vec3 rayDir = scenePos - rayPos;

    vec3 color = decodeRgbe8(texelFetch(colortex7, texel, 0));
    
    float sqrLength = dot(viewPos, viewPos);
    float invLength = inversesqrt(sqrLength);

    vec4 cloudData = raymarchCloudVolume(rayPos, rayDir * invLength, depth == 0.0 ? 1e6 : sqrLength * invLength, dither);

    vec3 cloudScattering = directIrradiance * cloudData.r + skyIrradiance * cloudData.g;

    colorRgbe8 = encodeRgbe8(color * cloudData.b + cloudScattering);
}