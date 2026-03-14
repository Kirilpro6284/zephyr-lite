#include "/include/uniforms.glsl"
#include "/include/config.glsl"
#include "/include/constants.glsl"
#include "/include/main.glsl"

/* RENDERTARGETS: 5 */
layout (location = 0) out vec4 color;

void main ()
{
	ivec2 texel = ivec2(gl_FragCoord.xy);

	vec4 result = vec4(0.0);

	for (int x = -3; x <= 3; x++) {
		result += vec4(texelFetch(colortex5, texel + ivec2(x, 0), 0).rgb, 1.0) * exp(-0.25 * x * x);
	}

	color.rgb = result.rgb / result.w;
}