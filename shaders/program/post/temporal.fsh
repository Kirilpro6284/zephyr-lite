#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/encoding.glsl"
#include "/include/utility/colorMatrices.glsl"

/*
    const bool colortex1MipmapEnabled = true;
*/

/* RENDERTARGETS: 6 */
layout (location = 0) out vec4 colorHistory;

void main() {
    ivec2 texel = ivec2(gl_FragCoord.xy);

#if TEMPORAL_UPSAMPLING > 1 
    ivec2 srcTexel = ivec2(taauRenderScale * gl_FragCoord.xy);
    ivec2 dstTexel = ivec2(rcp(taauRenderScale) * (vec2(srcTexel) - 0.5 * internalScreenSize * taa_offset + 0.5));
#else
    #define srcTexel texel
    #define dstTexel texel
#endif

    vec3 color = decodeRgbe8(texelFetch(colortex7, srcTexel, 0));

    vec3 colorMin = vec3(65504.0);
	vec3 colorMax = vec3(0.0);

	float depthMin = 0.0;
	float depthMax = 1.0;

	for (int x = srcTexel.x - 1; x <= srcTexel.x + 1; x++) {
		for (int y = srcTexel.y - 1; y <= srcTexel.y + 1; y++) {
            ivec2 sampleTexel = clamp(ivec2(x, y), ivec2(0), ivec2(internalScreenSize) - 1);

			vec3 colorSample = decodeRgbe8(texelFetch(colortex7, sampleTexel, 0));
			float depthSample = texelFetch(lodDepthTex1, sampleTexel, 0).r;

			colorMin = min(colorSample, colorMin);
			colorMax = max(colorSample, colorMax);

			// The min/max are swapped because of reversed-z
			depthMin = max(depthSample, depthMin);
			depthMax = min(depthSample, depthMax);
		}
	}

	colorHistory.a = linearizeDepth(depthMax);

    vec2 coord = texelSize * gl_FragCoord.xy;

    vec3 scenePos = screenToScenePos(coord, depthMin);
    vec3 prevViewPos = mat3(gbufferPreviousModelView) * (scenePos + step(0.08, dot(scenePos, scenePos)) * float(depthMin != 0.0) * cameraVelocity) + gbufferPreviousModelView[3].xyz;
    vec2 prevCoord = (gbufferProjScalePrev.xy * prevViewPos.xy / -prevViewPos.z + taa_offset) * 0.5 + 0.5;

#if TEMPORAL_UPSAMPLING > 1
    bool isUnderSample = dstTexel != texel;
#else
    bool isUnderSample = false;
#endif

    if (clamp01(prevCoord) == prevCoord && prevViewPos.z < 0.0) {
        vec3 colorPrevious = texCatmullRom(colortex6, prevCoord, screenSize).rgb;
        float depthPrevious = texture(colortex6, prevCoord).a;

        if (any(isnan(colorPrevious))) colorPrevious = color.rgb;
   
        colorPrevious.rgb = clamp(colorPrevious.rgb, colorMin, colorMax);

        const float offcenterRejection = 0.25;

        float alpha = mix(1.0, rcp(TAA_HISTORY_LIMIT), exp(-offcenterRejection * (1.0 - (1.0 - 2.0 * abs(fract(prevCoord.x * screenSize.x) - 0.5)) * (1.0 - 2.0 * abs(fract(prevCoord.y * screenSize.y) - 0.5)))));

        if (depthMin == 0.0 ? depthPrevious > 64.0 : -prevViewPos.z - depthPrevious < TAA_DEPTH_REJECTION * -prevViewPos.z) {
            if (isUnderSample && depthPrevious > eps) {
                color.rgb = colorPrevious.rgb;
            }

            colorHistory.rgb = exp(mix(log(colorPrevious.rgb + 1e-3), log(color.rgb + 1e-3), alpha)) - 1e-3;
        } else colorHistory.rgb = vec3(-1.0);
    } else colorHistory.rgb = vec3(-1.0);

    if (srcTexel == ivec2(0)) colorHistory.a = mix(texelFetch(colortex6, ivec2(0), 0).a, sqrt(max0(exp(textureLod(colortex1, vec2(0.5), 16.0).r) - 0.003)), ADAPTATION_SPEED);
}