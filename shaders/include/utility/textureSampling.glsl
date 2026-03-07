#ifndef INCLUDE_TEXTURE_SAMPLING
    #define INCLUDE_TEXTURE_SAMPLING

    // The following code is licensed under the MIT license: https://gist.github.com/TheRealMJP/bc503b0b87b643d3505d41eab8b332ae

    /*
        MIT License

        Copyright (c) 2019 MJP

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    */

    // Samples a texture with Catmull-Rom filtering, using 9 texture fetches instead of 16.
    // See http://vec3.ca/bicubic-filtering-in-fewer-taps/ for more details
    vec4 texCatmullRom (in sampler2D linearSampler, in vec2 uv, in vec2 texSize)
    {
        // We're going to sample a a 4x4 grid of texels surrounding the target UV coordinate. We'll do this by rounding
        // down the sample location to get the exact center of our "starting" texel. The starting texel will be at
        // location [1, 1] in the grid, where [0, 0] is the top left corner.
        vec2 samplePos = uv * texSize;
        vec2 texPos1 = floor(samplePos - 0.5) + 0.5;

        // Compute the fractional offset from our starting texel to our original sample location, which we'll
        // feed into the Catmull-Rom spline function to get our filter weights.
        vec2 f = samplePos - texPos1;

        // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
        // These equations are pre-expanded based on our knowledge of where the texels will be located,
        // which lets us avoid having to evaluate a piece-wise function.
        vec2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
        vec2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
        vec2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
        vec2 w3 = f * f * (-0.5 + 0.5 * f);

        // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
        // simultaneously evaluate the middle 2 samples from the 4x4 grid.
        vec2 w12 = w1 + w2;
        vec2 offset12 = w2 / (w1 + w2);

        // Compute the final UV coordinates we'll use for sampling the texture
        vec2 texPos0 = texPos1 - 1;
        vec2 texPos3 = texPos1 + 2;
        vec2 texPos12 = texPos1 + offset12;

        texPos0 /= texSize;
        texPos3 /= texSize;
        texPos12 /= texSize;

        vec4 result = vec4(0.0);
        result += textureLod(linearSampler, vec2(texPos0.x, texPos0.y), 0.0) * w0.x * w0.y;
        result += textureLod(linearSampler, vec2(texPos12.x, texPos0.y), 0.0) * w12.x * w0.y;
        result += textureLod(linearSampler, vec2(texPos3.x, texPos0.y), 0.0) * w3.x * w0.y;

        result += textureLod(linearSampler, vec2(texPos0.x, texPos12.y), 0.0) * w0.x * w12.y;
        result += textureLod(linearSampler, vec2(texPos12.x, texPos12.y), 0.0) * w12.x * w12.y;
        result += textureLod(linearSampler, vec2(texPos3.x, texPos12.y), 0.0) * w3.x * w12.y;

        result += textureLod(linearSampler, vec2(texPos0.x, texPos3.y), 0.0) * w0.x * w3.y;
        result += textureLod(linearSampler, vec2(texPos12.x, texPos3.y), 0.0) * w12.x * w3.y;
        result += textureLod(linearSampler, vec2(texPos3.x, texPos3.y), 0.0) * w3.x * w3.y;

        return result;
    }

#endif