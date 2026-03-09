#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/packing.glsl"

uniform float alphaTestRef = 0.1;

#ifdef fsh

flat in uint geometryId;

in vec2 texcoord;
in vec2 lightLevels;
in vec3 vertexColor;
in vec3 vertexNormal;
in vec4 vertexTangent;

/* RENDERTARGETS: 8,9 */
layout (location = 0) out uvec4 colortex8Out;
layout (location = 1) out uvec4 colortex9Out;

void main ()
{
    vec4 albedo = texture(gtexture, texcoord) * vec4(vertexColor, 1.0);
    vec4 specularData = texture(specular, texcoord);

    mat3 tbnMatrix = tbnNormalTangent(vertexNormal, vertexTangent);

    vec4 normalData = texture(normals, texcoord);

    vec3 textureNormal = vec3(normalData.rg * 2.0 - 1.0, 1.0);
    textureNormal.z = sqrt(max(0.0, 1.0 - dot(textureNormal.xy, textureNormal.xy)));

    colortex8Out.x = packUnorm4x8(vec4(albedo.rgb, 0.0)) | ((geometryId & 255u) << 24u);
    colortex8Out.y = packExp4x8(vec4(octEncode(vertexNormal), lightLevels));
    colortex9Out.x = packExp2x16(octEncode(tbnMatrix * textureNormal));
    colortex9Out.y = packUnorm4x8(specularData);

    if (albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

attribute vec4 at_tangent;
attribute vec2 mc_Entity;

flat out uint geometryId;

out vec2 texcoord;
out vec2 lightLevels;
out vec3 vertexColor;
out vec3 vertexNormal;
out vec4 vertexTangent;

void main ()
{
    gl_Position = ftransform();

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy = mix(-gl_Position.ww, gl_Position.xy, TAAU_RENDER_SCALE);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    lightLevels = mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1;
    vertexColor = gl_Color.rgb;
    vertexNormal = transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal;
    vertexTangent = vec4(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * at_tangent.xyz, at_tangent.w);

    geometryId = uint(mc_Entity.x);
}

#endif