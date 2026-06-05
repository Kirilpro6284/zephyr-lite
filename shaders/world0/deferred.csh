#version 430 compatibility

#include "/include/main.glsl"

layout (local_size_x = 8, local_size_y = 8) in;
const vec2 workGroupsRender = vec2(taauRenderScale, taauRenderScale);

// ----- Outputs -----

layout (r32f) uniform image2D lodDepthImg1;

// ----- Functions -----

void main() {

#ifdef VOXY
    float backDepth = texelFetch(vxDepthTexOpaque, ivec2(gl_GlobalInvocationID.xy), 0).r;
#else
    #define backDepth 1.0
#endif

	float frontDepth = texelFetch(depthtex1, ivec2(gl_GlobalInvocationID.xy), 0).r;

    float depth;

	if (backDepth == 1.0 && frontDepth == 1.0) {
		depth = 0.0;
	} else {
        if (frontDepth == 1.0) {
            #ifdef VOXY
                depth = backDepth * 2.0 - 1.0;
	            depth = -rcp(depth * vxProjInv[2].w + vxProjInv[3].w);
            #endif
        } else {
            depth = frontDepth * 2.0 - 1.0;
	        depth = -rcp(depth * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
        }

        depth = -(depth * gbufferProjScale.z + gbufferProjScale.w) / depth;
	}

	imageStore(lodDepthImg1, ivec2(gl_GlobalInvocationID.xy), vec4(depth * -0.5, 0.0, 0.0, 1.0));
}