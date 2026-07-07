#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Signed-distance-field playground shaders, ported from Koshimizu-Takehito's
// my-toybox (CircleSDF1 / CircleSDF2 / SmoothMin). Each is a `.colorEffect`
// stitchable function: SwiftUI supplies `position` + `color`, and we take the
// view's bounding rect (`box` = origin.xy, size.zw) plus time / smoothing.
// Helpers are `static` (file-local) to avoid clashing with other .metal files.

// Smooth minimum of two SDFs — softens the seam so blended circles fuse.
static inline float sdf_smoothMin(float a, float b, float k) {
    float h = clamp(0.5 - 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(a, b, h) - k * h * (1.0 - h);
}

static inline float sdf_circle(float2 p, float2 center, float radius) {
    return length(p - center) - radius;
}

// Map pixel position into aspect-corrected [-1, 1] space.
static inline float2 sdf_norm(float2 position, float4 box) {
    float2 p = -1.0 + 2.0 * (position + box.xy) / box.zw;
    if (box.z < box.w) {
        p.y = p.y * box.w / box.z;
    } else {
        p.x = p.x * box.z / box.w;
    }
    return p;
}

// MARK: - Circle SDF 1 — two circles blended by a fixed smooth-min, animated.

[[ stitchable ]] half4 circleSDF1(float2 position, half4 color, float4 box, float sec) {
    float2 pos = sdf_norm(position, box);
    float tx = 0.5 * (1.0 + sin(2.0 * sec)) / 2.0;
    float ty = 0.8 * sin(sec);
    float sd1 = sdf_circle(pos, float2(tx, ty), 0.3);
    float sd2 = sdf_circle(pos, float2(-tx, -ty), 0.3);
    float sd3 = sdf_smoothMin(sd1, sd2, 0.3);
    if (sd3 < 0.0) {
        return half4(0.1, 0.5, 1.0, 1.0);
    }
    return half4(1.0, 1.0, 1.0, 1.0);
}

// MARK: - Circle SDF 2 — interactive time + smoothing, with iso-line stripes.

[[ stitchable ]] half4 circleSDF2(float2 position, half4 color, float4 box, float sec, float k) {
    float2 pos = sdf_norm(position, box);
    float tx = 0.5 * (1.0 + sin(2.0 * sec)) / 2.0;
    float ty = sin(sec);
    float sd1 = sdf_circle(pos, float2(tx, ty), k);
    float sd2 = sdf_circle(pos, float2(-tx, -ty), k);
    float sd3 = sdf_smoothMin(sd1, sd2, k);
    if (sd3 < 0.0) {
        float value = 20.0 * abs(sd3);
        if (abs(value - floor(value)) < 0.2) {
            return half4(1.0, 1.0, 1.0, 1.0);   // white iso-line
        }
        return half4(0.0, 0.5, 1.0, 1.0);       // cyan fill
    }
    return half4(1.0, 1.0, 1.0, 1.0);
}

// MARK: - SmoothMin 2D — visualizes the blend field with distance-tinted colour.

static inline half3 sdf_fieldColor(float sd1, float sd2, float sd3) {
    float t = atan(sd3) / M_PI_F + 0.5;
    if (sd3 < 0.0) {
        half3 color1 = 1.0 - (abs(sd1) / 0.4) * (1.0 - half3(1.0, 0.0, 1.0));
        half3 color2 = 1.0 - (abs(sd2) / 0.4) * (1.0 - half3(0.0, 1.0, 1.0));
        return mix(color1, color2, half(t));
    }
    return mix(half3(0.0, 0.0, 1.0), half3(0.5, 1.0, 1.0), half(t));
}

[[ stitchable ]] half4 smoothMin2D(float2 position, half4 color, float4 box, float sec, float k) {
    float2 pos = sdf_norm(position, box);
    float tx = 0.5 * (1.0 + sin(2.0 * sec)) / 2.0;
    float ty = 0.8 * sin(sec);
    float sd1 = sdf_circle(pos, float2(tx, ty), 0.3);
    float sd2 = sdf_circle(pos, float2(-tx, -ty), 0.3);
    float sd3 = sdf_smoothMin(sd1, sd2, k);
    return half4(sdf_fieldColor(sd1, sd2, sd3), 1.0);
}

// MARK: - Implicit Equation — f(x,y) = sin(a(x²+y²)) − cos(b·xy), drawn as a
// contour of the sampled gradient layer. Ported from my-toybox (ImplicitEquation).
// This is a .layerEffect (samples the source layer), not a .colorEffect.

[[ stitchable ]] half4 implicitEquation(float2 position, SwiftUI::Layer layer,
                                        float a, float b, float iso, float zoom,
                                        float funcType, float levels, float thickness,
                                        float phase, float4 rect) {
    float2 uv = (position - rect.zw / 2.0) / (min(rect.z, rect.w) / 2.0);
    uv /= zoom;
    float x = uv.x;
    float y = uv.y;
    float r2 = x * x + y * y;

    // Function family (0 reproduces the original waves function when phase == 0).
    int fn = int(funcType + 0.5);
    float f;
    if (fn == 1) {                        // Grid
        f = sin(a * x * 4.0 + phase) + sin(b * y * 4.0);
    } else if (fn == 2) {                 // Spiral
        float th = atan2(y, x);
        f = sin(a * sqrt(r2) * 6.0 - b * th * 3.0 + phase);
    } else if (fn == 3) {                 // Petals
        float th = atan2(y, x);
        f = sqrt(r2) - 0.5 - 0.25 * sin(b * th * 5.0 + a + phase);
    } else {                              // Waves (original)
        f = sin(a * r2 + phase) - cos(b * x * y);
    }

    float aa = fwidth(f) * 2.0;
    int lv = clamp(int(levels + 0.5), 1, 6);
    float spacing = 0.35;
    float line = 0.0;
    for (int k = 0; k < 6; k++) {
        if (k >= lv) { break; }
        float isoK = iso + (float(k) - 0.5 * float(lv - 1)) * spacing;
        line = max(line, smoothstep(thickness + aa, thickness - aa, abs(f - isoK)));
    }
    half intensity = half(line);
    if (sign(f - iso) < 0.0) {
        intensity = 1.0 - intensity;
    }
    half4 color = layer.sample(position);
    return half4(intensity * color.r, intensity * color.g, intensity * color.b, 1.0);
}

// MARK: - Flow Distortion — curl-noise advection of a sampled image with a touch
// of chromatic aberration. .layerEffect. Ported from my-toybox (FlowDistortion).

static inline float flow_noise(float2 p, float time) {
    return sin(p.x * 10.0) * sin(p.y * 10.0 + time * 0.5) * 0.5 + 0.5;
}

static inline float2 flow_curlNoise(float2 p, float time, float noiseScale) {
    constexpr float eps = 0.001;
    float n1 = flow_noise(p + float2(eps, 0.0), time);
    float n2 = flow_noise(p - float2(eps, 0.0), time);
    float n3 = flow_noise(p + float2(0.0, eps), time);
    float n4 = flow_noise(p - float2(0.0, eps), time);
    float curlX = (n3 - n4) / (2.0 * eps);
    float curlY = (n2 - n1) / (2.0 * eps);
    return float2(curlY, -curlX) * noiseScale;
}

[[ stitchable ]] half4 flowDistortion(float2 position, SwiftUI::Layer layer,
                                      float time, float distortionStrength,
                                      float damping, float noiseScale,
                                      float steps, float aberration, float tiles, float4 rect) {
    float2 uv = position / rect.zw;
    float2 aspect = rect.zw / min(rect.z, rect.w);
    uv = (uv - 0.5) * aspect + 0.5;
    float2 gridUv = fract(uv * max(tiles, 1.0));

    float2 offset = float2(0.0);
    int stepCount = clamp(int(steps + 0.5), 1, 12);
    for (int i = 0; i < 12; ++i) {
        if (i >= stepCount) { break; }
        float2 flow = flow_curlNoise(uv + offset - time * 0.1, time, noiseScale) * distortionStrength;
        offset -= flow;
        offset *= damping;
    }

    float2 distortedPosition = (gridUv + offset) * rect.zw;
    half4 color = layer.sample(distortedPosition);

    float aberStrength = length(offset) * aberration;
    float2 dir = normalize(offset);
    float2 rOffset = dir * aberStrength * rect.zw;
    color.r = layer.sample(distortedPosition + rOffset).r;
    color.b = layer.sample(distortedPosition - rOffset).b;
    return color;
}
