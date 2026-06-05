
#include "/include/main.glsl"

// ----- Varying -----

noperspective varying float reversedDepth;

flat varying uint geometryId;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 vertexNormal;
varying vec3 vertexColor;

#ifdef fsh

// ----- Outputs -----

/* RENDERTARGETS: 1,8 */
layout (location = 0) out vec4 fragColor;
layout (location = 1) out vec4 waterMask;

// ----- Uniforms -----

uniform float alphaTestRef = 0.1;

// ----- Includes -----

#include "/block.properties"

#include "/include/lighting/lighting.glsl"

#include "/include/atmospherics/atmosphere.glsl"

#include "/include/surface/material.glsl"
#include "/include/surface/waterVolume.glsl"
#include "/include/surface/tbn.glsl"

#include "/include/utility/rng.glsl"

// ----- Functions -----

void main() {

    #if TEMPORAL_UPSAMPLING > 1
        if (any(greaterThan(gl_FragCoord.xy + 0.5, internalScreenSize))) {
            return;
        }
    #endif

    vec4 albedo = texture(gtexture, texcoord) * vec4(vertexColor, 1.0);

    if (geometryId == BLOCK_WATER) {
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

    float dither = getInterleavedGradientNoise(gl_FragCoord.xy);

    vec2 coord = internalTexelSize * gl_FragCoord.xy;

    vec3 viewPos = screenToViewPos(coord, reversedDepth).xyz;
    vec3 scenePos = viewToScenePos(viewPos);
    vec3 viewDir = normalize(scenePos - gbufferModelViewInverse[3].xyz);

    vec3 textureNormal = normalize(geometryId == BLOCK_WATER ? tbnNormal(vertexNormal) * getWaveNormal(scenePos + cameraPosition) : vertexNormal);
    vec2 lightLevels = adjustLightLevels(lmcoord);

    vec3 reflectedDir = reflect(viewDir, textureNormal);

    fragColor.rgb = getSceneLighting(
        scenePos, 
        viewDir,
        material,
        lightLevels.g * 0.4 * getSkyIrradiance(vertexNormal),
        vertexNormal,
        textureNormal,
        lightLevels,
        smoothstep(0.2, 0.4, lmcoord.y),
        dither,
        1.0
    );

    float fresnel = getSchlickFresnel(material.f0.g, max0(dot(reflectedDir, textureNormal)));

    fragColor.a = mix(albedo.a, 1.0, fresnel);
    fragColor.rgb *= fragColor.a * (1.0 - fresnel);

    fragColor.rgb += (isEyeInWater == 1 ? 1.0 : fragColor.a * fresnel) * getSpecularReflections(
        coord, 
        reversedDepth, 
        scenePos,
        -viewPos.z,
        reflectedDir,
        dither, 
        lmcoord.y
    );

    if (geometryId == BLOCK_WATER) {
        waterMask.rg = octEncode(textureNormal);
        waterMask.b = -viewPos.z * rcp(viewDistance);
        waterMask.a = 1.0;
    } else {
        waterMask = vec4(0.0);
    }

    if (albedo.a < alphaTestRef && geometryId != BLOCK_WATER) discard;
}

#endif

#ifdef vsh

// ----- Attributes -----

attribute vec2 mc_Entity;

// ----- Includes -----

#include "/include/utility/spaceConversion.glsl"

// ----- Functions -----

void main ()
{
    vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

#ifdef STAGE_HAND
    viewPos = projectAndDivide(gbufferProjectionInverse, gl_Position.xyz / gl_Position.w);
#endif

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy += (gl_Position.xy + gl_Position.w) * (taauRenderScale - 1.0);

    geometryId = mc_Entity.x < 0.0 ? 255u : uint(mc_Entity.x);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    lmcoord = mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1;
    vertexColor = gl_Color.rgb;
    vertexNormal = transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal;
    
    reversedDepth = 0.5 * (gbufferProjScale.z * viewPos.z + gbufferProjScale.w) / viewPos.z;
}

#endif