#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/packing.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/utility/brdf.glsl"
#include "/include/lighting/shadowMapping.glsl"
#include "/include/lighting/floodfill.glsl"
#include "/include/lighting/lighting.glsl"
#include "/include/utility/spaceConversion.glsl"

uniform float alphaTestRef = 0.1;

#ifdef fsh

in vec2 texcoord;
in vec2 lightLevels;
in vec3 vertexNormal;
in vec3 vertexColor;

/* RENDERTARGETS: 1 */
layout (location = 0) out vec4 colortex1Out;

void main ()
{
    vec4 albedo = texture(gtexture, texcoord) * vec4(vertexColor, 1.0);
    
    vec3 playerPos = screenToPlayerPos(internalTexelSize * gl_FragCoord.xy, gl_FragCoord.z).xyz;

    albedo.rgb = pow(albedo.rgb, vec3(2.2));

    colortex1Out.rgb = EXPONENT_BIAS * getSceneLighting(
        playerPos, 
        blueNoise(gl_FragCoord.xy).rg, 
        0.2,
        0.5,
        vertexNormal,
        vertexNormal,
        albedo.rgb,
        vec3(1.0),
        lightLevels
    );
    colortex1Out.a = albedo.a;

    if (albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

out vec2 texcoord;
out vec2 lightLevels;
out vec3 vertexNormal;
out vec3 vertexColor;

void main ()
{
    gl_Position = ftransform();

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy = mix(-gl_Position.ww, gl_Position.xy, TAAU_RENDER_SCALE);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    lightLevels = mat4x2(gl_TextureMatrix[1]) * gl_MultiTexCoord1;
    vertexColor = gl_Color.rgb;
    vertexNormal = transpose(mat3(gbufferModelView)) * gl_NormalMatrix * gl_Normal;
}

#endif