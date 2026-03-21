#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/packing.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/utility/bsdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/floodfill.glsl"
#include "/include/lighting/lighting.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/raymarching.glsl"

uniform float alphaTestRef = 0.1;

#ifdef fsh

noperspective in float reversedDepth;

in vec2 texcoord;
in vec2 lmcoord;
in vec3 vertexNormal;
in vec3 vertexColor;

/* RENDERTARGETS: 1 */
layout (location = 0) out vec4 fragColor;

void main ()
{
    #if TEMPORAL_UPSAMPLING < 100
        if (any(greaterThan(gl_FragCoord.xy + 0.5, internalScreenSize))) {
            return;
        }
    #endif

    vec4 albedo = texture(gtexture, texcoord) * vec4(vertexColor, 1.0);

    albedo.rgb = pow(albedo.rgb, vec3(2.2)) * rgbToAp1Unlit;

    Material mat = Material(
        albedo.rgb,
        vec3(0.4),
        0.2,
        0.5,
        0.0
    );

    vec2 lightLevels = adjustLightLevels(lmcoord);
    float dither = getInterleavedGradientNoise(gl_FragCoord.xy);

    vec3 screenPos = vec3(internalTexelSize * gl_FragCoord.xy, reversedDepth);

    vec3 playerPos = screenToPlayerPos(screenPos.xy, screenPos.z).xyz;
    vec3 viewDir = normalize(playerPos - gbufferModelViewInverse[3].xyz);

    vec3 reflectedDir = reflect(viewDir, vertexNormal);

    fragColor.rgb = getSceneLighting(
        playerPos, 
        viewDir,
        mat,
        lightLevels.y * 0.4 * getSkyIrradiance(vertexNormal),
        vertexNormal,
        vertexNormal,
        lightLevels,
        smoothstep(0.2, 0.4, lmcoord.y),
        dither,
        1.0
    );

    fragColor.rgb = mix(fragColor.rgb, getSpecularReflections(screenPos, playerPos, reflectedDir, dither, lightLevels.y), getSchlickFresnel(vec3(0.4), dot(reflectedDir, vertexNormal)));
    fragColor.a = albedo.a;

    if (albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

noperspective out float reversedDepth;

out vec2 texcoord;
out vec2 lmcoord;
out vec3 vertexNormal;
out vec3 vertexColor;

void main ()
{
    vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef STAGE_HAND
        viewPos = projectAndDivide(gbufferProjectionInverse, gl_Position.xyz / gl_Position.w);
    #endif

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy = mix(-gl_Position.ww, gl_Position.xy, taauRenderScale);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    lmcoord = mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1;
    vertexColor = gl_Color.rgb;
    vertexNormal = transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal;
    
    reversedDepth = (lodProjMat_2.z * viewPos.z + lodProjMat_3.z) / (lodProjMat_2.w * viewPos.z);
}

#endif