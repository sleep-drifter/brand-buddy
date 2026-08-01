# Flow Distortion — Shader Build Spec

A handoff spec for an agent implementing the **Flow Distortion** effect. Self-contained:
everything needed to build it is in this file. Reference implementation is SwiftUI +
Metal (source below, verbatim); a GLSL/WebGL translation is included for web targets.

Origin: ported from Koshimizu-Takehito's `my-toybox` (`FlowDistortion`), then extended
with a photo source and adjustable step count / speed / aberration / tiling.

---

## 1. What the effect does

An input image is displaced ("advected") by a time-varying **curl-noise flow field**.
Each fragment walks backwards through the field for N iterations, accumulating a UV
offset that gets damped a little on every step, then samples the image at the displaced
coordinate. The R and B channels are sampled with a small extra offset along the flow
direction, producing chromatic-aberration fringing on the high-motion edges.

The result reads as a rubbery, taffy-like pull across the image that breathes over time —
edges bulge and recover, straight lines bow, and colored fringes appear where the pull is
strongest.

Two things shape the character of the look, and both matter for a faithful port:

- **The noise is not real noise.** It is a separable product of sines
  (`sin(10x) · sin(10y + t/2)`), so the flow field is a *regular lattice of vortices*,
  not an organic turbulent field. The distortion therefore repeats on a grid and looks
  deliberate rather than cloudy. Do not substitute Perlin/simplex noise without
  understanding that it changes the effect's identity.
- **Tiling is part of the effect.** UVs are wrapped with `fract(uv * tiles)`, so the
  preview shows a `tiles × tiles` grid where *each cell contains the whole image*, each
  cell distorted differently because the flow lookup uses the un-wrapped UV.

## 2. Reference screenshot settings

The attached example was captured at these values (not the defaults — a high-step,
low-damping, heavy-pull configuration):

| Parameter   | Value |
| ----------- | ----- |
| Strength    | 0.030 |
| Damping     | 0.33  |
| Noise Scale | 3.00  |
| Speed       | 1.00  |
| Flow Steps  | 11    |
| Tiles       | 3     |

Source image in that capture is a screenshot fed back into the effect, tiled 3×3.

> Open question, flagged so nobody chases it: the reference screenshot shows hard
> diagonal grey wedges forming an X across the grid. That is not something the math
> above obviously produces — it may come from the source photo itself, or from sampling
> outside the layer bounds (the Metal host passes `maxSampleOffset: .zero`). Treat it as
> incidental to the capture, not a requirement. If you want to guarantee it never
> happens in your port, clamp or wrap the final sample coordinate (see §6).

## 3. Parameters

| Name         | Range        | Default | Step | Role |
| ------------ | ------------ | ------- | ---- | ---- |
| `strength`   | 0.01 … 0.03  | 0.021   | —    | Per-step flow displacement scale. Small numbers: the field's derivative is already large. |
| `damping`    | 0.10 … 1.00  | 0.95    | —    | Offset is multiplied by this after every step. Low = each step's contribution decays fast, so recent steps dominate; high = offsets compound into long smears. |
| `noiseScale` | 1.0 … 3.0    | 2.0     | —    | Multiplies the curl vector. Bigger = more violent field. |
| `speed`      | 0.2 … 3.0    | 1.0     | —    | Applied on the **host** side as a multiplier on elapsed time, not inside the shader. |
| `steps`      | 1 … 12       | 5       | 1    | Advection iterations. Clamped to 12 in-shader; the loop must be bounded by a literal for GPU unrolling. |
| `aberration` | 0.0 … 0.05   | 0.01    | —    | Chromatic split magnitude, scaled by `length(offset)` so it only appears where the image is actually moving. |
| `tiles`      | 1 … 6        | 3       | 1    | `fract` tiling factor. 1 = single un-tiled image. |

Plus an **image source** — the harness offers a photo picker with a bundled fallback
image, and a **Reset** button restoring the defaults above.

Rough magnitude check, useful when your port looks wrong: the analytic derivative of the
noise reaches ~5, so one step's displacement is roughly `5 · noiseScale · strength` ≈
0.45 UV units at max settings. That is why `strength` tops out at 0.03 and why damping is
load-bearing — without it, a few steps would push samples clean off the image.

## 4. Algorithm (implementation-independent)

```
uv        = fragmentPosition / resolution
aspect    = resolution / min(resolution.x, resolution.y)
uv        = (uv - 0.5) * aspect + 0.5          // aspect-correct about the center
gridUv    = fract(uv * max(tiles, 1))          // wrapped sampling coord

offset = (0, 0)
repeat clamp(steps, 1, 12) times:
    flow   = curlNoise(uv + offset - time * 0.1, time, noiseScale) * strength
    offset = offset - flow
    offset = offset * damping

samplePos = gridUv + offset
color     = sample(image, samplePos)

aberAmount = length(offset) * aberration
dir        = normalize(offset)
color.r    = sample(image, samplePos + dir * aberAmount).r
color.b    = sample(image, samplePos - dir * aberAmount).b
output color                                    // .g and .a from the center sample
```

Where:

```
noise(p, t)     = sin(p.x * 10) * sin(p.y * 10 + t * 0.5) * 0.5 + 0.5

curlNoise(p, t, scale):                          // eps = 0.001
    n1 = noise(p + (eps, 0), t);  n2 = noise(p - (eps, 0), t)
    n3 = noise(p + (0, eps), t);  n4 = noise(p - (0, eps), t)
    curlX = (n3 - n4) / (2 * eps)                // ∂noise/∂y
    curlY = (n2 - n1) / (2 * eps)                // -∂noise/∂x
    return (curlY, -curlX) * scale
```

Details that are easy to get wrong:

- The flow is looked up at `uv + offset`, the **un-wrapped, aspect-corrected** UV — not
  at `gridUv`. This is what makes each tile distort differently.
- `time * 0.1` is a **scalar subtracted from both UV components**, i.e. the field drifts
  diagonally. Broadcast it; don't subtract it from `.x` only.
- Aberration offsets are applied in the same coordinate space as `samplePos`. In Metal
  that space is pixels (hence the `* rect.zw`); in normalized-UV samplers it is just
  `dir * aberAmount`.
- `.g` and alpha come from the un-offset center sample.

## 5. Reference implementation (SwiftUI + Metal)

### 5.1 Metal kernel

`DesignerBuddy/More/Playgrounds/SDFShaders.metal`

```metal
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
```

### 5.2 SwiftUI host

`DesignerBuddy/More/Playgrounds/FlowDistortionView.swift` — the render path and shader
binding are the parts that matter; the slider rows are ordinary chrome.

```swift
struct FlowDistortionView: View {
    private let startDate = Date()

    @State private var distortionStrength: Double = 0.021
    @State private var damping: Double = 0.95
    @State private var noiseScale: Double = 2.0
    @State private var speed: Double = 1.0
    @State private var steps: Double = 5
    @State private var aberration: Double = 0.01
    @State private var tiles: Double = 3

    @State private var photoItem: PhotosPickerItem?
    @State private var uiImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSince(startDate) * speed
                    sourceImage
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .layerEffect(shader(time: time), maxSampleOffset: .zero)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

                controls
            }
            .padding(16)
        }
        .navigationTitle("Flow Distortion")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sourceImage: Image {
        if let uiImage { return Image(uiImage: uiImage) }
        return Image("PreviewBackground")
    }

    private func shader(time: TimeInterval) -> Shader {
        ShaderLibrary.flowDistortion(
            .float(Float(time)),
            .float(Float(distortionStrength)),
            .float(Float(damping)),
            .float(Float(noiseScale)),
            .float(Float(steps.rounded())),
            .float(Float(aberration)),
            .float(Float(tiles.rounded())),
            .boundingRect
        )
    }
}
```

Host-side notes:

- `TimelineView(.animation)` drives per-frame redraw; `speed` multiplies elapsed seconds
  before the value reaches the shader.
- `.layerEffect(_, maxSampleOffset: .zero)` — the effect samples the layer itself, so it
  must be `layerEffect`, not `colorEffect` or `distortionEffect`.
- `.boundingRect` supplies the `float4 rect` argument (x, y, width, height in pixels).
- The preview is locked to a square (`aspectRatio(1, .fit)`), which is why the
  aspect-correction line is nearly a no-op in the reference app — a non-square target
  will exercise it, so keep it.
- Argument order in `ShaderLibrary.flowDistortion(...)` must match the kernel signature
  exactly; SwiftUI does not type-check it for you and mismatches fail at draw time.

## 6. Porting to WebGL / GLSL

Direct translation. Assumes a full-screen quad, a normalized-UV texture sampler, and a
`requestAnimationFrame` loop feeding `uTime` already multiplied by `speed`.

```glsl
precision highp float;

uniform sampler2D uImage;
uniform vec2  uResolution;
uniform float uTime;        // elapsed seconds * speed
uniform float uStrength;    // 0.01 .. 0.03
uniform float uDamping;     // 0.10 .. 1.00
uniform float uNoiseScale;  // 1.0 .. 3.0
uniform int   uSteps;       // 1 .. 12
uniform float uAberration;  // 0.0 .. 0.05
uniform float uTiles;       // 1 .. 6

float flowNoise(vec2 p, float t) {
    return sin(p.x * 10.0) * sin(p.y * 10.0 + t * 0.5) * 0.5 + 0.5;
}

vec2 curlNoise(vec2 p, float t, float scale) {
    const float eps = 0.001;
    float n1 = flowNoise(p + vec2(eps, 0.0), t);
    float n2 = flowNoise(p - vec2(eps, 0.0), t);
    float n3 = flowNoise(p + vec2(0.0, eps), t);
    float n4 = flowNoise(p - vec2(0.0, eps), t);
    float curlX = (n3 - n4) / (2.0 * eps);
    float curlY = (n2 - n1) / (2.0 * eps);
    return vec2(curlY, -curlX) * scale;
}

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;
    uv.y = 1.0 - uv.y;                      // Metal/UIKit origin is top-left
    vec2 aspect = uResolution / min(uResolution.x, uResolution.y);
    uv = (uv - 0.5) * aspect + 0.5;
    vec2 gridUv = fract(uv * max(uTiles, 1.0));

    vec2 offset = vec2(0.0);
    for (int i = 0; i < 12; ++i) {          // literal bound, required for unrolling
        if (i >= uSteps) { break; }
        vec2 flow = curlNoise(uv + offset - uTime * 0.1, uTime, uNoiseScale) * uStrength;
        offset -= flow;
        offset *= uDamping;
    }

    vec2 p = gridUv + offset;
    vec4 color = texture2D(uImage, p);

    float aber = length(offset) * uAberration;
    vec2 dir = length(offset) > 1e-6 ? normalize(offset) : vec2(0.0);
    vec2 ro = dir * aber;
    color.r = texture2D(uImage, p + ro).r;
    color.b = texture2D(uImage, p - ro).b;

    gl_FragColor = color;
}
```

Port-specific decisions you have to make deliberately:

1. **Y flip.** Metal's `position` has a top-left origin. Without the flip the vortex
   lattice drifts the other way and the field is mirrored. Cosmetic, but it won't match
   the reference.
2. **Sample coordinates leave `[0,1]`.** `gridUv + offset` routinely goes out of range.
   Metal's `layer.sample` is a clamped/undefined read outside the layer; in WebGL your
   texture wrap mode decides the look. `CLAMP_TO_EDGE` gives smeared edges,
   `REPEAT` gives seamless wrap-around. Pick one intentionally — this is the single
   biggest source of visual divergence between ports.
3. **`normalize(offset)` divides by zero** when the accumulated offset is exactly zero
   (reachable at `strength = 0`, or with pathological damping). The Metal original does
   not guard it; the GLSL above does. Keep the guard.
4. **Non-power-of-two textures** need `CLAMP_TO_EDGE` + no mipmaps in WebGL1, which
   conflicts with choosing `REPEAT` in point 2. Upload to a POT-sized canvas first if you
   want wrap.
5. **`uSteps` as an `int` uniform** — comparing a loop counter against a `float` uniform
   is a portability hazard on older drivers.

## 7. Acceptance checks

- At defaults, a still image visibly breathes: edges bulge and recover on a ~2s cycle,
  straight lines bow, nothing tears or strobes.
- `strength = 0.01`, `steps = 1` is nearly identity — a faint shimmer only. If it is
  already heavily warped, `strength` or `noiseScale` is being applied twice.
- `tiles = 1` shows exactly one un-tiled copy of the image, still distorting.
- `tiles = 3` shows a 3×3 grid where every cell contains the *whole* image, each cell
  warped differently. Identical cells means the flow is being looked up at `gridUv`
  instead of `uv`.
- `aberration = 0` produces no color fringing; at `0.05` fringes appear only in
  high-motion regions, never in still areas.
- `damping = 0.1` gives a tight local wobble regardless of step count; `damping = 1.0`
  at high step counts gives long compounding smears.
- `speed = 0.2` vs `3.0` changes only the rate, never the shape of the distortion.
- Steady 60fps at the max configuration (`steps = 12`) — 12 iterations × 4 noise taps ×
  3 texture samples per fragment is the worst case and should still be cheap.
