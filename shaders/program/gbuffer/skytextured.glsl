
#include "/include/main.glsl"

varying vec2 texcoord;
varying vec3 scenePos;
varying vec3 vertexColor;

#ifdef fsh

// ----- Outputs -----

/* RENDERTARGETS: 10 */
layout (location = 0) out vec4 color;

// ----- Includes -----

#include "/include/utility/colorMatrices.glsl"

#include "/include/atmospherics/atmosphere.glsl"

// ----- Functions -----

void main() {

    #if TEMPORAL_UPSAMPLING > 1
        if (any(greaterThan(gl_FragCoord.xy + 0.5, internalScreenSize))) {
            return;
        }
    #endif

    vec4 albedo;
    vec3 viewDir = normalize(scenePos);

    if (renderStage == MC_RENDER_STAGE_SUN) {
        albedo = vec4(vec3(40.0) * step(0.9998, dot(viewDir, sunDir)), 1.0);
    } else {
        albedo = texture(gtexture, texcoord);
    }

    if (renderStage == MC_RENDER_STAGE_MOON) albedo.rgb = vec3(luminance(albedo.rgb));

    albedo.rgb *= vertexColor * pow(getAtmosphereTransmittance(viewDir), vec3(1.0 / 2.2));

    color = encodeRgbe8(albedo.rgb);

    if (albedo.a < 0.1) discard;
}

#endif

#ifdef vsh

// ----- Functions -----

void main() {   
    vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    gl_Position.xy += gl_Position.w * taa_offset;
    gl_Position.xy += (gl_Position.xy + gl_Position.w) * (taauRenderScale - 1.0);

    texcoord = mat4x2(gl_TextureMatrix[0]) * gl_MultiTexCoord0;
    scenePos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vertexColor = gl_Color.rgb * (renderStage == MC_RENDER_STAGE_SUN ? (smoothstep(-0.04, 0.01, sunDir.y) * 0.9 + 0.1) : 1.0);
}

#endif