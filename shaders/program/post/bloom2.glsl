#include "/include/main.glsl"

/* RENDERTARGETS: 5 */
layout (location = 0) out vec4 color;

void main ()
{
	ivec2 texel = ivec2(gl_FragCoord.xy);

	vec3 result = vec3(0.0);

	for (int x = -3; x <= 3; x++) {
		result += texelFetch(colortex5, texel + ivec2(x, 0), 0).rgb * exp(-0.25 * x * x);
	}

	const float kernelSum = rcp(exp(-2.25) + exp(-1.0) + exp(-0.25) + exp(0.0) + exp(-0.25) + exp(-1.0) + exp(-2.25));

	color.rgb = result * kernelSum;
}