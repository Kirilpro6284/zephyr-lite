layout (location = 0) out vec4 colortex1Out;

void voxy_emitFragment (VoxyFragmentParameters parameters)
{
    vec3 albedo = parameters.sampledColour.rgb * parameters.tinting.rgb;
    
    colortex1Out = vec4(albedo, 1.0);
}