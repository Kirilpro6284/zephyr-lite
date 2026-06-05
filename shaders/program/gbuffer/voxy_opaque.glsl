
#include "/include/main.glsl"

// ----- Outputs -----

layout (location = 0) out uvec4 encoded;

// ----- Includes -----

#include "/include/utility/encoding.glsl"

// ----- Functions -----

/*
    struct VoxyFragmentParameters {
        vec4 sampledColour;
        vec2 tile;
        vec2 uv;
        uint face;
        uint modelId;
        vec2 lightMap;
        vec4 tinting;
        uint customId;//Same as iris's modelId
    };
*/

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    
    #if TEMPORAL_UPSAMPLING > 1
        if (any(greaterThan(gl_FragCoord.xy + 0.5, internalScreenSize))) {
            return;
        }
    #endif

    vec3 albedo = parameters.sampledColour.rgb * parameters.tinting.rgb;
    vec3 normal = vec3(uint((parameters.face>>1)==2), uint((parameters.face>>1)==0), uint((parameters.face>>1)==1)) * (float(int(parameters.face)&1)*2-1);

    encoded.r = packUnorm4x8(vec4(albedo.rgb, parameters.customId * rcp(255.0)));
    encoded.g = packUnorm4x8(vec4(octEncode(normal), clamp01((parameters.lightMap - (1.0 / 16.0)) * (16.0 / 14.0))));
    encoded.b = packUnorm2x16(octEncode(normal));
    encoded.a = 0u;
}