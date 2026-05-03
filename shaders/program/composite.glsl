#include "/include/main.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/lighting/shadowMapping.glsl"

/* RENDERTARGETS: 7 */
layout (location = 0) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    float depth = texelFetch(lodDepthTex1, texel, 0).r;
    float dither = getInterleavedGradientNoise(gl_FragCoord.xy);

    vec3 directIrradiance = shadowLightBrightness * getAtmosphereTransmittance(shadowDir);
    vec3 skyIrradiance = getSkyIrradiance(vec3(0.0, 1.0, 0.0));

    vec3 rayPos = gbufferModelViewInverse[3].xyz;
    vec3 rayDir = mat3(gbufferModelViewInverse) * screenToViewPos(internalTexelSize * gl_FragCoord.xy, depth);
         rayDir *= rcp(AIR_FOG_SCATTER_POINTS);

    float stepSize = length(rayDir);

    if (stepSize > far * rcp(AIR_FOG_SCATTER_POINTS)) {
        rayDir *= far / (stepSize * AIR_FOG_SCATTER_POINTS);
        stepSize = far * rcp(AIR_FOG_SCATTER_POINTS);
    } 

    rayPos += rayDir * dither;

    vec3 transmittance = vec3(1.0);
    vec3 scattering = vec3(0.0);

    float phase = kleinNishinaPhase(dot(rayDir, shadowDir) / stepSize, 2400.0) + 0.25;
    float fogDensity = smoothstep(0.0, 1.0, abs(shadowDir.x)) * 0.002 + 0.0005;

    for (int i = 0; i < AIR_FOG_SCATTER_POINTS; i++, rayPos += rayDir) {
        float density = stepSize * fogDensity * exp(-0.1 * max0(rayPos.y + eyeAltitude - 63.0));

        transmittance *= exp(-min1(float(i) + 0.5) * density);

        vec3 shadowPos = shadowProjScale * (shadowModelView * vec4(rayPos, 1.0)).xyz;
             shadowPos.xy = distortShadowPos(shadowPos.xy);

        scattering += transmittance * density * (phase * directIrradiance * texture(shadowtex1HW, shadowPos * 0.5 + 0.5) + (eyeBrightnessSmooth.y / 240.0) * skyIrradiance);
    }

    vec3 currData = decodeRgbe8(texelFetch(colortex7, texel, 0));
    vec4 translucentData = texelFetch(colortex1, texel, 0);
    
    color = encodeRgbe8(mix(currData, translucentData.rgb, translucentData.a) * transmittance + scattering);
}