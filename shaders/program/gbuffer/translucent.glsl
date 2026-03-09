#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/packing.glsl"

uniform float alphaTestRef = 0.1;

#ifdef fsh

in vec2 texcoord;
in vec3 vertexColor;

/* RENDERTARGETS: 1 */
layout (location = 0) out vec4 colortex1Out;

void main ()
{
    vec4 albedo = texture(gtexture, texcoord) * vec4(vertexColor, 1.0);
    
    colortex1Out = vec4(pow(albedo.rgb, vec3(2.2)), albedo.a);

    if (albedo.a < alphaTestRef) discard;
}

#endif

#ifdef vsh

out vec2 texcoord;
out vec3 vertexColor;

void main ()
{
    gl_Position = ftransform();

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy = mix(-gl_Position.ww, gl_Position.xy, TAAU_RENDER_SCALE);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    vertexColor = gl_Color.rgb;
}

#endif