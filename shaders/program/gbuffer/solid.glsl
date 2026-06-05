
#include "/include/main.glsl"

// ----- Varying -----

flat varying float geometryId;

varying vec2 texcoord;
varying vec2 lightLevels;
varying vec3 vertexColor;
varying vec3 vertexNormal;
varying vec4 vertexTangent;

#ifdef fsh

// ----- Outputs -----

/* RENDERTARGETS: 9 */
layout (location = 0) out uvec4 encoded;

// ----- Uniforms -----

uniform float alphaTestRef = 0.1;

// ----- Includes -----

#include "/include/utility/encoding.glsl"
#include "/include/utility/colorMatrices.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/rng.glsl"

#include "/include/surface/material.glsl"
#include "/include/surface/tbn.glsl"

// ----- Functions -----

void main() {

    #if TEMPORAL_UPSAMPLING > 1
        if (any(greaterThan(gl_FragCoord.xy + 0.5, internalScreenSize))) {
            return;
        }
    #endif

    vec2 texSize = vec2(textureSize(gtexture, 0));
    vec2 atlasTexCoord = texSize * texcoord;
    float mipLevel = max(0.0, taauRenderScale * 0.5 * log2(max(lengthSquared(dFdx(atlasTexCoord)), lengthSquared(dFdy(atlasTexCoord)))));

    vec4 albedo = textureLod(gtexture, texcoord, mipLevel) * vec4(vertexColor, 1.0);

#ifdef HARDCODED_SPECULAR
    vec4 specularData = getHardcodedSpecular(albedo.rgb, uint(geometryId));
#else
    vec4 specularData = texture(specular, texcoord);
#endif

    mat3 tbnMatrix = tbnNormalTangent(vertexNormal, vertexTangent);

    vec4 normalData = texture(normals, texcoord);

    vec3 textureNormal = vec3(normalData.rg * 2.0 - 1.0, 1.0);
    textureNormal.xy *= step(vec2(rcp(128.0)), abs(textureNormal.xy));
    textureNormal.z = sqrt(max(0.0, 1.0 - dot(textureNormal.xy, textureNormal.xy)));

    encoded.r = packUnorm4x8(vec4(albedo.rgb, geometryId * rcp(255.0)));
    encoded.g = packUnorm4x8(vec4(octEncode(vertexNormal), lightLevels + rcp(255.0) * (getInterleavedGradientNoise(gl_FragCoord.xy) - 0.5)));
    encoded.b = packUnorm2x16(octEncode(tbnMatrix * textureNormal));
    encoded.a = packUnorm4x8(specularData);

    if (albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

// ----- Attributes -----

attribute vec4 at_tangent;
attribute vec2 mc_Entity;

// ----- Includes -----

#include "/include/utility/spaceConversion.glsl"

// ----- Functions -----

void main() {   
    vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

#ifdef STAGE_HAND
    viewPos = projectAndDivide(gbufferProjectionInverse, gl_Position.xyz / gl_Position.w);
#endif

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy += (gl_Position.xy + gl_Position.w) * (taauRenderScale - 1.0);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    lightLevels = clamp01((mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1 - (1.0 / 16.0)) * (16.0 / 14.0));
    vertexColor = gl_Color.rgb;
    vertexNormal = transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal;
    vertexTangent = vec4(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * at_tangent.xyz, at_tangent.w);

    geometryId = mc_Entity.x < 0.0 ? 255.0 : mc_Entity.x;
}

#endif