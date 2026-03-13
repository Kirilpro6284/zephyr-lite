#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/packing.glsl"

layout (location = 0) out uvec4 colortex8Out;
layout (location = 1) out uvec4 colortex9Out;

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

void voxy_emitFragment (VoxyFragmentParameters parameters)
{
    vec3 albedo = parameters.sampledColour.rgb * parameters.tinting.rgb;
    vec3 normal = vec3(uint((parameters.face>>1)==2), uint((parameters.face>>1)==0), uint((parameters.face>>1)==1)) * (float(int(parameters.face)&1)*2-1);

    float geometryId = parameters.customId - 10000u;
    vec4 specularData = vec4(0.0);

    colortex8Out.x = packUnorm4x8(vec4(albedo.rgb, geometryId * rcp(255.0)));
    colortex8Out.y = packExp4x8(vec4(octEncode(normal), parameters.lightMap));
    colortex9Out.x = packExp2x16(octEncode(normal));
    colortex9Out.y = packUnorm4x8(specularData);
}