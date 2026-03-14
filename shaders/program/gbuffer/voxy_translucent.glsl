layout (location = 0) out vec4 colortex1Out;

void voxy_emitFragment (VoxyFragmentParameters parameters)
{
    #if TEMPORAL_UPSAMPLING < 100
        if (any(greaterThan(gl_FragCoord.xy + 0.5, internalScreenSize))) {
            return;
        }
    #endif

    vec3 albedo = parameters.sampledColour.rgb * parameters.tinting.rgb;
    
    colortex1Out = vec4(albedo, 1.0);
}