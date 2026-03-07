#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/packing.glsl"

uniform float alphaTestRef = 0.1;

#ifdef fsh

in float geometryId;
in vec2 texcoord;
in vec2 lightLevels;
in vec3 vertexColor;
in vec3 vertexNormal;

/* RENDERTARGETS: 8,9 */
layout (location = 0) out uvec4 colortex8Out;
layout (location = 1) out uvec4 colortex9Out;

void main ()
{
    vec4 albedo = texture(gtexture, texcoord) * vec4(vertexColor, 1.0);
    vec4 specularData = texture(specular, texcoord);

    colortex8Out.x = packUnorm4x8(vec4(albedo.rgb, geometryId * rcp(255.0)));
    colortex8Out.y = packExp4x8(vec4(octEncode(vertexNormal), lightLevels));
    colortex9Out.x = packExp2x16(octEncode(vertexNormal));
    colortex9Out.y = packUnorm4x8(specularData);

    if (albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

attribute vec2 mc_Entity;

out float geometryId;
out vec2 texcoord;
out vec2 lightLevels;
out vec3 vertexColor;
out vec3 vertexNormal;

void main ()
{
    gl_Position = ftransform();

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy = mix(-gl_Position.ww, gl_Position.xy, TAAU_RENDER_SCALE);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    lightLevels = mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1;
    vertexColor = gl_Color.rgb;
    vertexNormal = transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal;

    geometryId = mc_Entity.x;
}

#endif