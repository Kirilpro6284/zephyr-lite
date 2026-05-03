#include "/include/main.glsl"
#include "/include/sky/atmosphere.glsl"

#ifdef fsh

in vec2 texcoord;
in vec3 playerPos;
in vec3 vertexColor;

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 colortex10Out;

void main ()
{
    #if TEMPORAL_UPSAMPLING < 100
        if (any(greaterThan(gl_FragCoord.xy + 0.5, internalScreenSize))) {
            return;
        }
    #endif

    vec4 albedo;
    vec3 viewDir = normalize(playerPos);

    if (renderStage == MC_RENDER_STAGE_SUN) {
        albedo = vec4(vec3(40.0) * step(0.9998, dot(viewDir, sunDir)), 1.0);
    } else {
        albedo = texture(gtexture, texcoord);
    }

    if (renderStage == MC_RENDER_STAGE_MOON) albedo.rgb = vec3(luminance(albedo.rgb));

    albedo.rgb *= vertexColor * pow(getAtmosphereTransmittance(viewDir), vec3(1.0 / 2.2));

    colortex10Out = encodeRgbe8(albedo.rgb);

    if (albedo.a < 0.1) discard;
}

#endif

#ifdef vsh

out vec2 texcoord;
out vec3 playerPos;
out vec3 vertexColor;

void main ()
{   
    vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy = mix(-gl_Position.ww, gl_Position.xy, taauRenderScale);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vertexColor = gl_Color.rgb * (renderStage == MC_RENDER_STAGE_SUN ? (smoothstep(-0.04, 0.01, sunDir.y) * 0.9 + 0.1) : 1.0);
}

#endif