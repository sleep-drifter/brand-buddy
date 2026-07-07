#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Tap-activated ripple: origin is the tap location, timeSinceTap grows from 0
// spread makes the ripple emanate from a disc of that radius rather than a point
[[ stitchable ]] float2 shaderRipple(
    float2 position,
    float timeSinceTap,
    float2 origin,
    float amplitude,
    float wavelength,
    float decay,
    float spread,
    float speed
) {
    float2 delta = position - origin;
    float dist = length(delta);
    if (dist < 0.001) return position;
    float effectiveDist = max(0.0, dist - spread);
    float temporal = exp(-timeSinceTap * 1.1);
    float wave = amplitude * sin(effectiveDist / wavelength - timeSinceTap * speed) * exp(-decay * effectiveDist) * temporal;
    return position + normalize(delta) * wave;
}

// Block pixelation
[[ stitchable ]] half4 shaderPixelate(
    float2 position,
    SwiftUI::Layer layer,
    float blockSize
) {
    float2 snapped = floor(position / blockSize) * blockSize + blockSize * 0.5;
    return layer.sample(snapped);
}

// RGB channel split with independent H and V offsets
[[ stitchable ]] half4 shaderChromatic(
    float2 position,
    SwiftUI::Layer layer,
    float hAmount,
    float vAmount
) {
    half4 r = layer.sample(position + float2(hAmount,  vAmount));
    half4 g = layer.sample(position);
    half4 b = layer.sample(position - float2(hAmount,  vAmount));
    return half4(r.r, g.g, b.b, g.a);
}

// Sine wave displacement, animated
[[ stitchable ]] float2 shaderWave(
    float2 position,
    float time,
    float amplitude,
    float frequency
) {
    return float2(
        position.x + amplitude * sin(position.y * frequency + time),
        position.y + amplitude * 0.4 * sin(position.x * frequency * 0.7 + time * 1.3)
    );
}

// Film grain: intensity, grain size, and chroma (0=monochrome, 1=per-channel color noise)
[[ stitchable ]] half4 shaderGrain(
    float2 position,
    half4 color,
    float time,
    float intensity,
    float grainSize,
    float chroma
) {
    float2 uv = floor(position / max(grainSize, 0.5)) + fract(time * 0.1) * 997.0;
    float nr = fract(sin(dot(uv,                      float2(127.1, 311.7))) * 43758.5453);
    float ng = fract(sin(dot(uv + float2(43.2, 0.0),  float2(127.1, 311.7))) * 43758.5453);
    float nb = fract(sin(dot(uv + float2(0.0,  17.9), float2(127.1, 311.7))) * 43758.5453);
    float nm = (nr + ng + nb) / 3.0;
    half hr = half((mix(nm, nr, chroma) - 0.5) * intensity);
    half hg = half((mix(nm, ng, chroma) - 0.5) * intensity);
    half hb = half((mix(nm, nb, chroma) - 0.5) * intensity);
    return half4(saturate(color.r + hr), saturate(color.g + hg), saturate(color.b + hb), color.a);
}

// Edge vignette darkening
[[ stitchable ]] half4 shaderVignette(
    float2 position,
    half4 color,
    float2 size,
    float radius,
    float softness
) {
    float2 uv = position / size;
    float dist = length((uv - 0.5) * 2.0);
    float vig = smoothstep(radius + softness, radius - softness, dist);
    return half4(color.rgb * half(vig), color.a);
}

// Twist/swirl distortion
[[ stitchable ]] float2 shaderSwirl(
    float2 position,
    float2 center,
    float angle,
    float radius
) {
    float2 delta = position - center;
    float dist = length(delta);
    float t = max(0.0, (radius - dist) / radius);
    float a = atan2(delta.y, delta.x) + angle * t * t;
    return center + dist * float2(cos(a), sin(a));
}

// 3D emboss using neighbor samples
[[ stitchable ]] half4 shaderEmboss(
    float2 position,
    SwiftUI::Layer layer,
    float strength
) {
    half4 tl = layer.sample(position - float2(strength));
    half4 br = layer.sample(position + float2(strength));
    half4 center = layer.sample(position);
    half4 diff = (br - tl) * 0.5 + 0.5;
    return half4(diff.r, diff.g, diff.b, center.a);
}

// Kaleidoscope: folds the image into N mirrored angular segments
[[ stitchable ]] float2 shaderKaleidoscope(
    float2 position,
    float2 center,
    float segments,
    float rotation
) {
    float2 delta = position - center;
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x) + rotation;
    float slice = M_PI_F * 2.0 / segments;
    angle = fmod(angle, slice);
    if (angle < 0.0) angle += slice;
    if (angle > slice * 0.5) angle = slice - angle;
    return center + dist * float2(cos(angle), sin(angle));
}

// Glitch: animated horizontal slice offsets with independent RGB channel split
[[ stitchable ]] half4 shaderGlitch(
    float2 position,
    SwiftUI::Layer layer,
    float time,
    float intensity,
    float blockSize,
    float speed,
    float channelSplit
) {
    float blockY = floor(position.y / max(blockSize, 1.0));
    float t = floor(time * max(speed, 0.5));
    float n1 = fract(sin(blockY * 127.1 + t * 311.7) * 43758.5453);
    float n2 = fract(sin(blockY * 311.7 + t * 127.1) * 43758.5453);
    float offsetX = n1 > (1.0 - intensity) ? (n2 - 0.5) * 60.0 * intensity : 0.0;
    half4 r = layer.sample(float2(position.x + offsetX + channelSplit, position.y));
    half4 g = layer.sample(float2(position.x + offsetX,                position.y));
    half4 b = layer.sample(float2(position.x + offsetX - channelSplit, position.y));
    return half4(r.r, g.g, b.b, g.a);
}

// CRT: scanlines, barrel curvature, vignette
[[ stitchable ]] half4 shaderCRT(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float scanlines,
    float curvature,
    float vignette
) {
    float2 uv = position / size;
    float2 c = uv - 0.5;
    float2 warped = c * (1.0 + curvature * dot(c, c));
    float2 sp = (warped + 0.5) * size;
    if (sp.x < 0.0 || sp.y < 0.0 || sp.x > size.x || sp.y > size.y) return half4(0, 0, 0, 1);
    half4 col = layer.sample(sp);
    float scan = sin(sp.y * M_PI_F) * 0.5 + 0.5;
    col.rgb *= half(1.0 - scanlines * (1.0 - scan));
    float vig = smoothstep(0.85, 0.2, length(c) * (1.0 + vignette * 0.8));
    col.rgb *= half(vig);
    return col;
}

// Edge detection: Sobel operator — bright edges on black; step controls kernel spread
[[ stitchable ]] half4 shaderEdgeDetect(
    float2 position,
    SwiftUI::Layer layer,
    float strength,
    float threshold,
    float step
) {
    float3 luma = float3(0.299, 0.587, 0.114);
    float s = max(step, 0.5);
    float tl = dot(float3(layer.sample(position + float2(-s,-s)).rgb), luma);
    float tc = dot(float3(layer.sample(position + float2( 0,-s)).rgb), luma);
    float tr = dot(float3(layer.sample(position + float2( s,-s)).rgb), luma);
    float ml = dot(float3(layer.sample(position + float2(-s, 0)).rgb), luma);
    float mr = dot(float3(layer.sample(position + float2( s, 0)).rgb), luma);
    float bl = dot(float3(layer.sample(position + float2(-s, s)).rgb), luma);
    float bc = dot(float3(layer.sample(position + float2( 0, s)).rgb), luma);
    float br = dot(float3(layer.sample(position + float2( s, s)).rgb), luma);
    float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
    float gy = -tl - 2.0*tc - tr + bl + 2.0*bc + br;
    float edge = smoothstep(threshold, threshold + 0.15, length(float2(gx, gy)) * strength);
    return half4(half3(edge), 1.0);
}

// Fisheye: barrel/bulge distortion — center expands, edges compress
[[ stitchable ]] float2 shaderFisheye(
    float2 position,
    float2 center,
    float strength,
    float radius
) {
    float2 delta = position - center;
    float dist = length(delta);
    if (dist < 0.001) return position;
    float t = clamp(dist / radius, 0.0, 1.0);
    float warp = 1.0 + strength * (1.0 - t * t);
    return center + normalize(delta) * dist / max(warp, 0.01);
}

// Smooth value noise — bilinear interpolation of hashed lattice points
float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = fract(sin(dot(i,               float2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(i + float2(1,0), float2(127.1, 311.7))) * 43758.5453);
    float c = fract(sin(dot(i + float2(0,1), float2(127.1, 311.7))) * 43758.5453);
    float d = fract(sin(dot(i + float2(1,1), float2(127.1, 311.7))) * 43758.5453);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Progressive blur: sharp at one edge, blurry at the other along a direction
[[ stitchable ]] half4 shaderProgressiveBlur(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float maxRadius,
    float angle,    // direction toward more blur, in radians (0 = top→bottom)
    float focus     // normalized 0–1: progress point where blur begins
) {
    float2 uv = position / size;
    float proj = dot(uv, float2(sin(angle), cos(angle)));
    float t = clamp((proj - focus) / max(1.0 - focus, 0.01), 0.0, 1.0);
    float radius = t * maxRadius;
    if (radius < 0.5) return layer.sample(position);
    half4 result = layer.sample(position);
    const int N = 12;
    for (int i = 0; i < N; i++) {
        float a = float(i) * (M_PI_F * 2.0 / float(N));
        result += layer.sample(position + float2(cos(a), sin(a)) * radius);
        result += layer.sample(position + float2(cos(a), sin(a)) * radius * 0.5);
    }
    return result / half(2 * N + 1);
}

// Dissolve: noise-threshold reveal with fire glow at the dissolving edge
[[ stitchable ]] half4 shaderDissolve(
    float2 position,
    half4 color,
    float threshold,
    float softness,
    float glow,
    float scale
) {
    float2 uv = position / 100.0 * max(scale, 0.1);
    float n = valueNoise(uv)       * 0.5
            + valueNoise(uv * 2.1) * 0.3
            + valueNoise(uv * 4.3) * 0.2;

    float soft = max(softness * 0.25, 0.008);
    float alpha = smoothstep(threshold - soft, threshold + soft, n);

    // Fire glow band just below the dissolve edge
    float glowBand = smoothstep(threshold - soft * 8.0, threshold, n)
                   * (1.0 - smoothstep(threshold, threshold + soft, n));
    float g = glowBand * glow;

    half4 result = color * half(alpha);
    result.r = saturate(result.r + half(g));
    result.g = saturate(result.g + half(g * 0.2));
    result.a = saturate(color.a * half(alpha) + half(g));
    return result;
}

// Zoom blur: radial motion blur toward/away from a center point
[[ stitchable ]] half4 shaderZoomBlur(
    float2 position,
    SwiftUI::Layer layer,
    float2 center,
    float strength
) {
    float2 dir = position - center;
    half4 result = half4(0);
    const int N = 16;
    for (int i = 0; i < N; i++) {
        float t = float(i) / float(N - 1);
        result += layer.sample(position - dir * strength * t);
    }
    return result / half(N);
}

// Hue rotation
[[ stitchable ]] half4 shaderHueRotate(
    float2 position,
    half4 color,
    float angle
) {
    float cosA = cos(angle);
    float sinA = sin(angle);
    float3x3 hue = float3x3(
        float3(0.213 + cosA * 0.787 - sinA * 0.213,
               0.213 - cosA * 0.213 + sinA * 0.143,
               0.213 - cosA * 0.213 - sinA * 0.787),
        float3(0.715 - cosA * 0.715 - sinA * 0.715,
               0.715 + cosA * 0.285 + sinA * 0.140,
               0.715 - cosA * 0.715 + sinA * 0.715),
        float3(0.072 - cosA * 0.072 + sinA * 0.928,
               0.072 - cosA * 0.072 - sinA * 0.283,
               0.072 + cosA * 0.928 + sinA * 0.072)
    );
    float3 rgb = hue * float3(color.r, color.g, color.b);
    return half4(half3(saturate(rgb)), color.a);
}

// Pure hue (0–1) to fully-saturated RGB
float3 hueToRGB(float h) {
    float r = abs(h * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(h * 6.0 - 2.0);
    float b = 2.0 - abs(h * 6.0 - 4.0);
    return clamp(float3(r, g, b), 0.0, 1.0);
}

// Holographic foil: a prismatic rainbow sheen that sweeps across the image,
// strongest over the brighter regions (like light catching a foil sticker)
[[ stitchable ]] half4 shaderHolographic(
    float2 position,
    half4 color,
    float time,
    float intensity,
    float scale,
    float speed
) {
    float3 base = float3(color.rgb);
    float luma = dot(base, float3(0.299, 0.587, 0.114));
    float sweep = (position.x + position.y) / max(scale, 1.0) + time * speed;
    float phase = sweep + luma * 6.2831;
    float3 rainbow = float3(
        0.5 + 0.5 * sin(phase),
        0.5 + 0.5 * sin(phase + 2.094),
        0.5 + 0.5 * sin(phase + 4.188)
    );
    float mask = smoothstep(0.15, 0.9, luma);
    float3 outc = base + rainbow * intensity * mask;
    return half4(half3(saturate(outc)), color.a);
}

// Duotone: remap luminance onto a two-colour gradient (shadow hue → highlight hue)
[[ stitchable ]] half4 shaderDuotone(
    float2 position,
    half4 color,
    float shadowHue,
    float highlightHue,
    float contrast
) {
    float luma = dot(float3(color.rgb), float3(0.299, 0.587, 0.114));
    luma = saturate((luma - 0.5) * (0.5 + contrast * 2.0) + 0.5);
    float3 lo = hueToRGB(shadowHue) * 0.85;
    float3 hi = hueToRGB(highlightHue);
    return half4(half3(mix(lo, hi, luma)), color.a);
}

// Halftone: newspaper-print dot screen. Dot radius grows as the area darkens;
// the grid can be rotated, and tint blends from full colour to monochrome ink.
[[ stitchable ]] half4 shaderHalftone(
    float2 position,
    half4 color,
    float cellSize,
    float angle,
    float tint
) {
    float s = max(cellSize, 2.0);
    float ca = cos(angle);
    float sa = sin(angle);
    float2 rot = float2(position.x * ca - position.y * sa,
                        position.x * sa + position.y * ca);
    float2 cell = fmod(fmod(rot, s) + s, s) - s * 0.5;
    float luma = dot(float3(color.rgb), float3(0.299, 0.587, 0.114));
    float radius = (1.0 - luma) * s * 0.72;
    float ink = smoothstep(radius + 1.0, radius - 1.0, length(cell));
    float3 dotColor = mix(float3(color.rgb), float3(0.0), tint);
    return half4(half3(mix(float3(1.0), dotColor, ink)), color.a);
}

// Solarize: invert each channel above a threshold (Sabattier effect), blended in
[[ stitchable ]] half4 shaderSolarize(
    float2 position,
    half4 color,
    float threshold,
    float amount
) {
    float3 c = float3(color.rgb);
    float3 solar = float3(
        c.r > threshold ? 1.0 - c.r : c.r,
        c.g > threshold ? 1.0 - c.g : c.g,
        c.b > threshold ? 1.0 - c.b : c.b
    );
    return half4(half3(saturate(mix(c, solar, amount))), color.a);
}

// Frosted glass: jittered ring blur with a slight brightness lift
[[ stitchable ]] half4 shaderFrosted(
    float2 position,
    SwiftUI::Layer layer,
    float radius,
    float brightness
) {
    float r = max(radius, 0.5);
    half4 result = half4(0);
    const int N = 12;
    for (int i = 0; i < N; i++) {
        float a = float(i) * (M_PI_F * 2.0 / float(N));
        float jitter = fract(sin(dot(position + float(i), float2(12.9898, 78.233))) * 43758.5453);
        float rr = r * (0.4 + 0.6 * jitter);
        result += layer.sample(position + float2(cos(a), sin(a)) * rr);
    }
    result /= half(N);
    result.rgb = saturate(result.rgb + half(brightness));
    return result;
}

// Refractive lens: a magnifying bubble centred on the tap point that eases to
// no distortion at its rim
[[ stitchable ]] float2 shaderRefractLens(
    float2 position,
    float2 center,
    float radius,
    float strength
) {
    float2 delta = position - center;
    float dist = length(delta);
    float r = max(radius, 1.0);
    if (dist >= r) return position;
    float t = dist / r;
    float falloff = 1.0 - smoothstep(0.0, 1.0, t);
    float mag = 1.0 - strength * falloff;
    return center + delta * mag;
}

// Color grade: procedural film "looks" selected by index, blended by amount.
// Each branch is an analytic tone/colour transform — an in-shader stand-in for a LUT.
[[ stitchable ]] half4 shaderColorGrade(
    float2 position,
    half4 color,
    float look,
    float amount
) {
    float3 c = float3(color.rgb);
    float luma = dot(c, float3(0.299, 0.587, 0.114));
    float3 g = c;
    int L = int(look + 0.5);
    if (L == 1) {                 // Teal-Orange
        float3 shadowTint = float3(0.0, 0.35, 0.45);
        float3 highTint   = float3(1.0, 0.65, 0.30);
        float3 tint = mix(shadowTint, highTint, smoothstep(0.2, 0.8, luma));
        g = mix(c, c * 0.6 + tint * 0.6, 0.6);
        g = (g - 0.5) * 1.12 + 0.5;
    } else if (L == 2) {          // Warm Vintage
        g = c * float3(1.08, 1.02, 0.88) + float3(0.06, 0.03, 0.0);
        g = (g - 0.5) * 0.9 + 0.5;
    } else if (L == 3) {          // Bleach Bypass
        float3 gray = float3(luma);
        g = mix(c, gray, 0.6) * gray * 2.0;
        g = (g - 0.5) * 1.3 + 0.5;
    } else if (L == 4) {          // Noir
        float3 gray = float3(luma);
        g = (gray - 0.5) * 1.35 + 0.5 + float3(0.0, 0.0, 0.04);
    } else if (L == 5) {          // Cross Process
        float3 tint = mix(float3(0.0, 0.30, 0.10), float3(1.0, 0.95, 0.40), luma);
        g = mix(c, tint, 0.35);
        g = (g - 0.5) * 1.2 + 0.5;
        g = mix(float3(luma), g, 1.3);
    } else if (L == 6) {          // Faded matte
        g = (c - 0.5) * 0.75 + 0.5;
        g = g * 0.9 + 0.08;
    }
    return half4(half3(saturate(mix(c, g, amount))), color.a);
}

// Topographic: posterize luminance into bands, drawing thin contour lines at each
// band boundary; tint blends grayscale steps toward a cool→warm elevation ramp.
[[ stitchable ]] half4 shaderTopographic(
    float2 position,
    half4 color,
    float levels,
    float lineWidth,
    float tint
) {
    float luma = dot(float3(color.rgb), float3(0.299, 0.587, 0.114));
    float lv = max(levels, 2.0);
    float scaled = luma * lv;
    float band = floor(scaled) / lv;
    float f = fract(scaled);
    float line = 1.0 - smoothstep(0.0, max(lineWidth, 0.001), min(f, 1.0 - f));
    float3 ramp = mix(float3(0.10, 0.15, 0.35), float3(0.95, 0.85, 0.50), band);
    float3 base = mix(float3(band), ramp, tint);
    return half4(half3(base * (1.0 - line)), color.a);
}

// Chroma gradient (generative): a grainy near-white field with orange & purple blobs
// warped by simplex noise. Applied via .colorEffect on an opaque fill — the incoming
// `color` is ignored; `size` normalizes `position`.
// Ports iShader's ChromaGradients (ShaderToy mtKfDG); simplex noise below is the
// Ashima / McEwan / Gustavson implementation (MIT / public domain).
static float3 cg_mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float4 cg_mod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float4 cg_permute(float4 x) { return cg_mod289(((x * 34.0) + 1.0) * x); }
static float4 cg_taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

static float cg_snoise(float3 v) {
    const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
    const float4 D = float4(0.0, 0.5, 1.0, 2.0);
    float3 i  = floor(v + dot(v, C.yyy));
    float3 x0 = v - i + dot(i, C.xxx);
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);
    float3 x1 = x0 - i1 + C.xxx;
    float3 x2 = x0 - i2 + C.yyy;
    float3 x3 = x0 - D.yyy;
    i = cg_mod289(i);
    float4 p = cg_permute(cg_permute(cg_permute(
                 i.z + float4(0.0, i1.z, i2.z, 1.0))
               + i.y + float4(0.0, i1.y, i2.y, 1.0))
               + i.x + float4(0.0, i1.x, i2.x, 1.0));
    float n_ = 1.0 / 7.0;
    float3 ns = n_ * D.wyz - D.xzx;
    float4 j = p - 49.0 * floor(p * ns.z * ns.z);
    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_);
    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);
    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);
    float4 s0 = floor(b0) * 2.0 + 1.0;
    float4 s1 = floor(b1) * 2.0 + 1.0;
    float4 sh = -step(h, float4(0.0));
    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);
    float4 norm = cg_taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
    float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// Two-octave noise warp
static float cg_warp(float2 u, float o, float time) {
    float t = (time + o) * 0.2;
    float n = cg_snoise(float3(u.x * 0.9 + t, u.y * 0.9 - t, t));
    return cg_snoise(float3(n * 0.2, n * 0.7, t * 0.1));
}

// Soft blob field (nested smoothstep)
static float cg_blob(float2 u, float n, float s, float z) {
    return smoothstep(smoothstep(0.1, s, length(u)), 0.0,
                      length(u * float2(z * 0.8, z) + n * 0.3) - 0.3);
}

[[ stitchable ]] half4 chromaGradientArt(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float grainAmt,
    float zoom,
    float3 colorA,
    float3 colorB,
    float3 bg,
    float saturation,
    float softness,
    float warp,
    float blobCount,
    float contrast
) {
    float2 uv = (position - 0.5 * size) / min(size.x, size.y);
    uv *= zoom;

    // Per-blob params; indices 0 and 1 reproduce the original two blobs exactly.
    const float os[4] = { 1.0, 3.0, 5.0, 7.0 };
    const float ws[4] = { 0.6, 0.5, 0.42, 0.35 };
    const float ss[4] = { 1.2, 1.5, 1.8, 2.1 };
    const float zs[4] = { 1.1, 1.4, 1.7, 2.0 };

    int count = clamp(int(blobCount + 0.5), 1, 4);
    float coverage = 0.0;
    float colorField = 0.0;
    for (int i = 0; i < 4; i++) {
        if (i >= count) { break; }
        float wv = cg_warp(uv * ws[i], os[i], time) * warp;
        float b = cg_blob(uv, wv, ss[i] * softness, zs[i]);
        coverage += b;
        colorField += (i % 2 == 0) ? b : -b;
    }

    float n = grainAmt * cg_snoise(float3(uv * 300.0, time * 0.2));

    // Gentle positional gradient so flat picker colours still read as organic.
    half3 cA = half3(colorA) * half(1.0 - 0.25 * uv.y);
    half3 cB = half3(colorB) * half(1.0 + 0.20 * uv.x);

    // clamp arg order kept verbatim from the source: min(0.9, x) and min(1, x).
    half3 blobColor = half3(n) + mix(cA, cB, half(clamp(-0.14, 0.9, colorField * contrast)));
    half3 bgColor = half3(bg) + half3(n * 0.1);
    half3 outc = mix(bgColor, blobColor, half(clamp(0.0, 1.0, coverage)));

    // Saturation around luma.
    half luma = dot(outc, half3(0.299, 0.587, 0.114));
    outc = mix(half3(luma), outc, half(saturation));

    return half4(outc, 1.0);
}

// Random metaball 2D (generative): a set of randomly-sized balls wander the frame
// on Lissajous paths. Each contributes an inverse-square field; where the summed
// field crosses `threshold` we fill a solid colour, so neighbouring balls fuse with
// smooth liquid bridges. `smoothing` softens the edge (and how eagerly balls merge).
// Applied via .colorEffect on an opaque fill — the incoming `color` is ignored;
// `size` normalizes `position`. Inspired by iShader's RandomMetaball.
static inline float mb_hash(float n) {
    return fract(sin(n * 12.9898) * 43758.5453);
}

static inline float3 mb_hsv2rgb(float3 c) {
    float3 rgb = clamp(abs(fmod(c.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
                       0.0, 1.0);
    return c.z * mix(float3(1.0), rgb, c.y);
}

[[ stitchable ]] half4 randomMetaball2D(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float ballCount,
    float ballSize,
    float speed,
    float smoothing,
    float hue
) {
    float2 uv = position / max(size, float2(1.0, 1.0));
    float aspect = size.x / max(size.y, 1.0);
    // Centered coords, x scaled by aspect so balls stay round.
    float2 p = float2((uv.x * 2.0 - 1.0) * aspect, uv.y * 2.0 - 1.0);
    float t = time * speed;

    const int MAX_BALLS = 16;
    int count = clamp(int(ballCount + 0.5), 1, MAX_BALLS);
    float radius = max(ballSize, 0.02);

    float field = 0.0;
    for (int i = 0; i < MAX_BALLS; i++) {
        if (i >= count) { break; }
        float fi = float(i);
        // Per-ball drift: Lissajous paths keep balls wandering but on-screen.
        float2 freq  = 0.25 + float2(mb_hash(fi * 3.3 + 1.0),
                                     mb_hash(fi * 4.1 + 2.0)) * 0.65;
        float2 phase = float2(mb_hash(fi * 5.5 + 3.0),
                              mb_hash(fi * 6.9 + 4.0)) * 6.28318;
        float2 amp   = float2(aspect, 1.0) * 0.78;
        float2 center = float2(sin(t * freq.x + phase.x),
                               sin(t * freq.y * 0.9 + phase.y)) * amp;
        // Per-ball radius variation, like the screenshots' mix of big + small.
        float r = radius * (0.45 + mb_hash(fi * 8.3 + 5.0) * 1.05);
        float2 d = p - center;
        field += (r * r) / (dot(d, d) + 1e-4);
    }

    float soft = max(smoothing, 0.001);
    float edge = smoothstep(1.0 - soft, 1.0 + soft, field);

    float3 ballColor = mb_hsv2rgb(float3(fract(hue), 0.85, 1.0));
    // Composite the balls over the incoming pixels (black for the standalone page,
    // lower layers when used as a stacked effect) so it composes instead of wiping.
    float3 col = mix(float3(color.rgb), ballColor, edge);
    return half4(half3(col), color.a);
}
