#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/main.glsl"
#include "/include/utility/spaceConversion.glsl"
#include "/include/utility/textureSampling.glsl"
#include "/include/utility/packing.glsl"

/* RENDERTARGETS: 6,10 */
layout (location = 0) out vec4 history;
layout (location = 1) out vec4 color;

void main ()
{
    ivec2 texel = ivec2(gl_FragCoord.xy);

    #if TEMPORAL_UPSAMPLING < 100 
        ivec2 srcTexel = ivec2(TAAU_RENDER_SCALE * gl_FragCoord.xy);
        ivec2 dstTexel = ivec2((vec2(srcTexel) - internalScreenSize * taa_offset * 0.5 + 0.5) / TAAU_RENDER_SCALE);
    #else
        ivec2 srcTexel = texel;
        ivec2 dstTexel = srcTexel;
    #endif

    vec3 currData = decodeRgbe8(texelFetch(colortex7, srcTexel, 0));
    
    color = vec4(currData, 1.0);

    vec2 uv = texelSize * gl_FragCoord.xy;
    float depth = texelFetch(depthtex1, srcTexel, 0).r;

    vec3 playerPos = screenToPlayerPos(uv, depth).xyz;

    vec4 prevPos = gbufferPreviousProjection * gbufferPreviousModelView * vec4(playerPos.xyz + float(depth < 1.0) * step(0.05, dot(playerPos.xyz, playerPos.xyz)) * cameraVelocity, 1.0);

    vec3 prevUv = prevPos.xyz / prevPos.w;
    prevUv = vec3(prevUv.xy + taa_offset, prevUv.z) * 0.5 + 0.5;

    #if TEMPORAL_UPSAMPLING < 100
        bool isUnderSample = dstTexel != texel;
    #else
        bool isUnderSample = false;
    #endif

    if (floor(prevUv.xy) == vec2(0.0) && prevPos.w > 0.0)
    {
        vec4 prevData = texCatmullRom(colortex6, prevUv.xy, screenSize);

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

            float alpha = rcp(prevData.w);

            history.rgb = mix(prevData.rgb, currData.rgb, isUnderSample && prevData.w > 1.0 ? 0.0005 : alpha);
            history.w = prevData.w + (isUnderSample ? 0.0005 : 1.0);
        } else history = vec4(currData.rgb, TAA_TEMPORAL_W_CLAMP);
    } else history = vec4(currData.rgb, 1.0);

    color = any(isnan(history)) ? vec4(0.0) : encodeRgbe8(history.rgb);
}