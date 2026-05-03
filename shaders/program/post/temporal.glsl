#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"
#include "/include/utility/colorMatrices.glsl"

/*
    const bool colortex1MipmapEnabled = true;
*/

/* RENDERTARGETS: 6,10 */
layout (location = 0) out vec4 history;
layout (location = 1) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    #if TEMPORAL_UPSAMPLING < 100 
        ivec2 srcTexel = ivec2(taauRenderScale * gl_FragCoord.xy);
        ivec2 dstTexel = ivec2(rcp(taauRenderScale) * (vec2(srcTexel) - internalScreenSize * taa_offset * 0.5 + 0.5));
    #else
        ivec2 srcTexel = texel;
        ivec2 dstTexel = srcTexel;
    #endif

    vec3 currData = decodeRgbe8(texelFetch(colortex7, srcTexel, 0));
    
    color = vec4(currData, 1.0);

    vec2 uv = texelSize * gl_FragCoord.xy;
    float depth = texelFetch(lodDepthTex1, srcTexel, 0).r;

    for (int i = 0; i < 4; i++) {
        depth = min(depth, texelFetch(lodDepthTex1, srcTexel + ivec2(i >> 1, i & 1) * 2 - 1, 0).r);
    }

    vec3 playerPos = screenToPlayerPos(uv, depth);
    vec4 prevPos = lodProjMatPrev0 * gbufferPreviousModelView * vec4(playerPos + step(0.08, dot(playerPos, playerPos)) * cameraVelocity, 1.0);

    vec2 prevUv = prevPos.xy / prevPos.w;
    prevUv = (prevUv + taa_offset) * 0.5 + 0.5;

    #if TEMPORAL_UPSAMPLING < 100
        bool isUnderSample = dstTexel != texel;
    #else
        bool isUnderSample = false;
    #endif

    if (floor(prevUv) == vec2(0.0) && prevPos.w > 0.0)
    {
        vec4 prevData = texCatmullRom(colortex6, prevUv, screenSize);

        if (!any(isnan(prevData)))
        {   
            vec3 colorMin = vec3(INFINITY);
            vec3 colorMax = vec3(-INFINITY);

            for (int x = -1; x <= 1; x++) 
                for (int y = -1; y <= 1; y++) {
                    vec3 sampleData = decodeRgbe8(texelFetch(colortex7, clamp(srcTexel + ivec2(x, y), ivec2(0), ivec2(internalScreenSize) - 1), 0));

                    colorMin = min(colorMin, sampleData);
                    colorMax = max(colorMax, sampleData);
                }

            prevData.rgb = clamp(prevData.rgb, colorMin, colorMax);
            prevData.w   = clamp(prevData.w, 1.0, TAA_TEMPORAL_W_CLAMP);

            const float offcenterRejection = 0.2;

            float alpha = rcp(prevData.w);
                  alpha = mix(1.0, alpha, exp(-offcenterRejection * (1.0 - (1.0 - 2.0 * abs(fract(prevUv.x * screenSize.x) - 0.5)) * (1.0 - 2.0 * abs(fract(prevUv.y * screenSize.y) - 0.5)))));

            history.rgb = exp(mix(log(prevData.rgb + 1e-3), log(currData.rgb + 1e-3), isUnderSample && prevData.w > 1.0 ? 0.0005 : alpha)) - 1e-3;
            history.w = prevData.w + (isUnderSample ? 0.0005 : 1.0);
        } else history = vec4(currData.rgb, TAA_TEMPORAL_W_CLAMP);
    } else history = vec4(currData.rgb, 1.0);

    color = encodeRgbe8(any(isnan(history)) ? currData.rgb : history.rgb);
    
    if (srcTexel == ivec2(0)) history.a = mix(texelFetch(colortex6, ivec2(0), 0).a, sqrt(max0(exp(textureLod(colortex1, vec2(0.5), 16.0).r) - 0.003)), ADAPTATION_SPEED);
}