#include "/include/main.glsl"

/* RENDERTARGETS: 5 */
layout (location = 0) out vec4 color;

void main ()
{
	ivec2 texel = ivec2(gl_FragCoord.xy);

	vec3 result = vec3(0.0);

	for (int y = -3; y <= 3; y++) {
		result += texelFetch(colortex5, texel + ivec2(0, y), 0).rgb * exp(-0.25 * y * y);
	}

	const float kernelSum = rcp(exp(-2.25) + exp(-1.0) + exp(-0.25) + exp(0.0) + exp(-0.25) + exp(-1.0) + exp(-2.25));

	color.rgb = result * kernelSum;
}