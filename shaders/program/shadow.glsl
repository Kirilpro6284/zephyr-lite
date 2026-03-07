#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/packing.glsl"
#include "/include/lighting/shadowMapping.glsl"

uniform float alphaTestRef = 0.1;

#ifdef fsh

in float geometryId;
in vec2 texcoord;
//in vec2 lightLevels;
in vec3 vertexColor;
in vec3 vertexNormal;

layout (location = 0) out vec4 shadowcolor0Out;
layout (location = 1) out vec4 shadowcolor1Out;

void main ()
{
    vec4 albedo = texture(gtexture, texcoord) * vec4(vertexColor, 1.0);
   
    shadowcolor0Out = albedo;
    shadowcolor1Out = vec4(0.0);

    if (albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

attribute vec2 mc_Entity;

out float geometryId;
out vec2 texcoord;
//out vec2 lightLevels;
out vec3 vertexColor;
out vec3 vertexNormal;

void main ()
{
    gl_Position = vec4(shadowProjScale, 1.0) * (gl_ModelViewMatrix * gl_Vertex);

    gl_Position.xy = distortShadowPos(gl_Position.xy);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    //lightLevels = mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1;
    vertexColor = gl_Color.rgb;
    vertexNormal = transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal;

    geometryId = mc_Entity.x;
}

#endif