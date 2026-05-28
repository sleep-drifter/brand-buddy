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
