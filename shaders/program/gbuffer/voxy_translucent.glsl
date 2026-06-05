
#include "/include/main.glsl"

// ----- Outputs -----

layout (location = 0) out vec4 fragColor;
layout (location = 1) out vec4 waterMask;

// ----- Includes -----

#include "/block.properties"

#include "/include/lighting/lighting.glsl"

#include "/include/atmospherics/atmosphere.glsl"

#include "/include/surface/material.glsl"
#include "/include/surface/waterVolume.glsl"
#include "/include/surface/tbn.glsl"

#include "/include/utility/rng.glsl"

// ----- Functions -----

/*
    struct VoxyFragmentParameters {
        vec4 sampledColour;
        vec2 tile;
        vec2 uv;
        uint face;
        uint modelId;
        vec2 lightMap;
        vec4 tinting;
        uint customId;//Same as iris's modelId
    };
*/

void voxy_emitFragment(VoxyFragmentParameters parameters) {

    #if TEMPORAL_UPSAMPLING > 1
        if (any(greaterThan(gl_FragCoord.xy + 0.5, internalScreenSize))) {
            return;
        }
    #endif

    if (texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r < 1.0) {
        discard;
    }

    vec4 albedo = parameters.sampledColour * parameters.tinting;

    if (parameters.customId == BLOCK_WATER) {
        albedo = vec4(eps);
    } else {
        albedo.rgb = pow(albedo.rgb, vec3(2.2)) * rgbToAp1Unlit;
    }

    Material material = Material(
        albedo.rgb,
        0.3,
        vec3(0.2),
        vec3(0.0),
        0.5
    );

    vec3 vertexNormal = vec3(uint((parameters.face>>1)==2), uint((parameters.face>>1)==0), uint((parameters.face>>1)==1)) * (float(int(parameters.face)&1)*2-1);

    float reversedDepth = gl_FragCoord.z * 2.0 - 1.0;
          reversedDepth = (reversedDepth * vxProjInv[2].z + vxProjInv[3].z) / (reversedDepth * vxProjInv[2].w + vxProjInv[3].w);
          reversedDepth = 0.5 * (reversedDepth * gbufferProjScale.z + gbufferProjScale.w) / reversedDepth;

    float dither = getInterleavedGradientNoise(gl_FragCoord.xy);

    vec2 coord = internalTexelSize * gl_FragCoord.xy;

    vec3 viewPos = screenToViewPos(coord, reversedDepth);
    vec3 scenePos = viewToScenePos(viewPos);
    vec3 viewDir = normalize(scenePos - gbufferModelViewInverse[3].xyz);

    vec3 textureNormal = normalize(parameters.customId == BLOCK_WATER ? tbnNormal(vertexNormal) * getWaveNormal(scenePos + cameraPosition) : vertexNormal);
    vec2 lightLevels = adjustLightLevels(parameters.lightMap);

    vec3 reflectedDir = reflect(viewDir, textureNormal);

    fragColor.rgb = getSceneLighting(
        scenePos, 
        viewDir,
        material,
        lightLevels.g * 0.4 * getSkyIrradiance(vertexNormal),
        vertexNormal,
        textureNormal,
        lightLevels,
        smoothstep(0.2, 0.4, parameters.lightMap.y),
        dither,
        1.0
    );
    
    float fresnel = getSchlickFresnel(material.f0.g, max0(dot(reflectedDir, textureNormal)));

    fragColor.a = mix(albedo.a, 1.0, fresnel);
    fragColor.rgb *= fragColor.a * (1.0 - fresnel);

    fragColor.rgb += getSpecularReflections(
        coord, 
        reversedDepth, 
        scenePos,
        -viewPos.z,
        reflectedDir, 
        dither, 
        parameters.lightMap.y
    );

    if (parameters.customId == BLOCK_WATER) {
        waterMask.rg = octEncode(textureNormal);
        waterMask.b = -viewPos.z * rcp(viewDistance);
        waterMask.a = 1.0;
    } else {
        waterMask = vec4(0.0);
    }

    fragColor.rgb *= fragColor.a;
}