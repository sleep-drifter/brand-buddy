// HandshakeFluidKernels.metal
//
// Self-contained GPU stable-fluid background for the Handshake iOS login /
// home screen. Trimmed and rebranded from DesignerBuddy's "Stable Fluid"
// playground so it can be dropped into an app with no other context.
//
// Solver: Jos Stam, "Stable Fluids," SIGGRAPH 1999 (semi-Lagrangian advection
// + Jacobi pressure projection). Metal implementation inspired by TypeGPU —
// © 2025 Software Mansion — MIT License. https://github.com/software-mansion/TypeGPU
//
// All kernel/fragment names are prefixed `hsFluid` to avoid colliding with any
// shaders already in the host app's default Metal library. No assets required.

#include <metal_stdlib>
using namespace metal;

// ============================================================================
// Shared parameter blocks (mirror the Swift structs in HandshakeFluidBackground)
// ============================================================================

struct HSSimParams {
    float deltaTime;
    float viscosity;
    float vorticity;
};

struct HSBrushParams {
    int2   pos;
    float2 delta;
    float  radius;
    float  strength;
};

struct HSAmbientParams {
    float time;
    float deltaTime;
    float strength;
    float decay;
};

struct HSObstacleParams {
    float2 center;
    float  scale;
    float  slant;
};

struct HSCoolParams {
    float  glow;
    float  viewAspect;   // view width / height
    float  overscan;     // >1 zooms in slightly to hide the sim's static border
    float  markStrength; // 0..1 strength of the frosted "H" inset mark
    float3 anchorA;      // flow → (u=0, v=0)
    float3 anchorB;      // flow → (u=1, v=0)
    float3 anchorC;      // flow → (u=0, v=1)
    float3 anchorD;      // flow → (u=1, v=1)
    float2 obstacleCenter;
    float  obstacleScale;
    float  obstacleSlant;
    float  obstacleEnabled;
};

// ============================================================================
// Helpers
// ============================================================================

static inline int2 clampCoord(int2 coord, int2 bounds) {
    return clamp(coord, int2(0), bounds - 1);
}

// Cooperative halo load: a 16x16 threadgroup pulls an 18x18 tile (1-texel
// border) into shared memory so neighbour reads in the stencil kernels are
// cache-free.
static inline void loadTile4(
    threadgroup float4 tile[18][18],
    texture2d<float, access::read> src,
    uint2 ltid, uint2 lsize, uint2 gid, int2 bounds
) {
    const int2 origin = int2(gid) - int2(ltid) - 1;
    for (int j = int(ltid.y); j < 18; j += int(lsize.y)) {
        for (int i = int(ltid.x); i < 18; i += int(lsize.x)) {
            int2 gp = clampCoord(origin + int2(i, j), bounds);
            tile[j][i] = src.read(uint2(gp));
        }
    }
}

// Rounded-box signed distance (2D).
static inline float sdBox(float2 p, float2 b, float r) {
    float2 q = abs(p) - b + r;
    return length(max(q, float2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Handshake-style italic "H": two vertical strokes joined by a crossbar, then
// sheared for the italic lean. `p` is in normalized grid space relative to the
// mark's centre; `scale` is the stroke half-height.
static inline float sdHandshakeH(float2 p, float scale, float slant) {
    p.x += slant * p.y;                       // italic shear
    const float bw  = 0.26 * scale;           // stroke half-width
    const float bh  = 1.00 * scale;           // stroke half-height
    const float gap = 0.62 * scale;           // half-distance between strokes
    const float ch  = 0.24 * scale;           // crossbar half-height
    const float r   = 0.10 * scale;           // corner rounding

    float left  = sdBox(p - float2(-gap, 0.0), float2(bw, bh), r);
    float right = sdBox(p - float2( gap, 0.0), float2(bw, bh), r);
    float bar   = sdBox(p,                      float2(gap + bw, ch), r);
    return min(min(left, right), bar);
}

// ============================================================================
// Compute: clear a field to zero (run once at start-up on private textures)
// ============================================================================

kernel void hsFluidClear(
    texture2d<float, access::write> dst [[texture(0)]],
    uint2                           gid [[thread_position_in_grid]]
) {
    dst.write(float4(0.0), gid);
}

// ============================================================================
// Compute: touch brush — inject a soft velocity impulse under the finger
// ============================================================================

kernel void hsFluidBrush(
    texture2d<float, access::read>  src   [[texture(0)]],
    texture2d<float, access::write> dst   [[texture(1)]],
    constant HSBrushParams&         brush [[buffer(0)]],
    uint2                           gid   [[thread_position_in_grid]]
) {
    float2 vel = src.read(gid).xy;
    float dx = float(gid.x) - float(brush.pos.x);
    float dy = float(gid.y) - float(brush.pos.y);
    float distSq = dx * dx + dy * dy;
    float radiusSq = brush.radius * brush.radius;
    if (distSq < radiusSq) {
        float w = exp(-distSq / radiusSq);
        vel += brush.strength * w * brush.delta;
    }
    dst.write(float4(vel, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: ambient stirring — a handful of slow orbiting vortices keep the
// field alive with no user input, plus a gentle decay that bounds the total
// energy (so touch impulses and ambient forcing never blow up).
// ============================================================================

kernel void hsFluidAmbient(
    texture2d<float, access::read>  src [[texture(0)]],
    texture2d<float, access::write> dst [[texture(1)]],
    constant HSAmbientParams&       p   [[buffer(0)]],
    uint2                           gid [[thread_position_in_grid]]
) {
    float2 size = float2(src.get_width(), src.get_height());
    float2 uv = (float2(gid) + 0.5) / size;

    constexpr int N = 5;
    float2 centers[N] = {
        float2(0.35, 0.40), float2(0.65, 0.55), float2(0.50, 0.72),
        float2(0.42, 0.60), float2(0.60, 0.35),
    };
    float freqs[N] = { 0.13, 0.17, 0.11, 0.19, 0.15 };
    float radii[N] = { 0.14, 0.11, 0.16, 0.10, 0.13 };
    float phase[N] = { 0.0, 1.7, 3.1, 4.6, 5.5 };
    float spin[N]  = { 1.0, -1.0, 1.0, -1.0, 1.0 };
    const float sigma = 0.16;

    float2 force = float2(0.0);
    for (int i = 0; i < N; i++) {
        float ang = p.time * freqs[i] + phase[i];
        float2 c = centers[i] + radii[i] * float2(cos(ang), sin(ang * 1.3));
        float2 d = uv - c;
        float f = exp(-dot(d, d) / (sigma * sigma));
        force += spin[i] * f * float2(-d.y, d.x);   // rotational → survives projection
    }

    float2 vel = src.read(gid).xy;
    vel *= p.decay;
    vel += p.deltaTime * p.strength * force;
    dst.write(float4(vel, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: advect velocity (semi-Lagrangian, bilinear sampling)
// ============================================================================

kernel void hsFluidAdvect(
    texture2d<float, access::sample> src  [[texture(0)]],
    texture2d<float, access::write>  dst  [[texture(1)]],
    sampler                          samp [[sampler(0)]],
    constant HSSimParams&            p    [[buffer(0)]],
    uint2                            gid  [[thread_position_in_grid]]
) {
    uint w = src.get_width();
    uint h = src.get_height();

    if (gid.x == 0 || gid.y == 0 || gid.x >= w - 1 || gid.y >= h - 1) {
        dst.write(float4(0.0, 0.0, 0.0, 1.0), gid);   // no-slip walls
        return;
    }

    float2 vel = src.read(gid).xy;
    float2 prevPos = float2(gid) - p.deltaTime * vel;
    float2 clamped = clamp(prevPos, float2(-0.5), float2(float(w), float(h)) - 0.5);
    float2 uv = (clamped + 0.5) / float2(float(w), float(h));
    dst.write(src.sample(samp, uv), gid);
}

// ============================================================================
// Compute: diffusion (Jacobi iteration; only dispatched when viscosity > 0)
// ============================================================================

kernel void hsFluidDiffusion(
    texture2d<float, access::read>  src   [[texture(0)]],
    texture2d<float, access::write> dst   [[texture(1)]],
    constant HSSimParams&           p     [[buffer(0)]],
    uint2                           gid   [[thread_position_in_grid]],
    uint2                           ltid  [[thread_position_in_threadgroup]],
    uint2                           lsize [[threads_per_threadgroup]]
) {
    threadgroup float4 tile[18][18];
    int2 size = int2(src.get_width(), src.get_height());
    loadTile4(tile, src, ltid, lsize, gid, size);
    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (int(gid.x) >= size.x || int(gid.y) >= size.y) return;

    const uint lx = ltid.x + 1, ly = ltid.y + 1;
    float4 center = tile[ly][lx];
    float4 left   = tile[ly][lx - 1];
    float4 right  = tile[ly][lx + 1];
    float4 up     = tile[ly - 1][lx];
    float4 down   = tile[ly + 1][lx];

    float alpha = 1.0 / max(p.viscosity * p.deltaTime, 1e-6);
    float blend = 1.0 / (4.0 + alpha);
    dst.write(blend * (left + right + up + down + center * alpha), gid);
}

// ============================================================================
// Compute: curl of the velocity field (for vorticity confinement)
// ============================================================================

kernel void hsFluidCurl(
    texture2d<float, access::read>  vel   [[texture(0)]],
    texture2d<float, access::write> curl  [[texture(1)]],
    uint2                           gid   [[thread_position_in_grid]],
    uint2                           ltid  [[thread_position_in_threadgroup]],
    uint2                           lsize [[threads_per_threadgroup]]
) {
    threadgroup float4 tile[18][18];
    int2 size = int2(vel.get_width(), vel.get_height());
    loadTile4(tile, vel, ltid, lsize, gid, size);
    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (int(gid.x) >= size.x || int(gid.y) >= size.y) return;

    const uint lx = ltid.x + 1, ly = ltid.y + 1;
    float leftVy  = tile[ly][lx - 1].y;
    float rightVy = tile[ly][lx + 1].y;
    float upVx    = tile[ly - 1][lx].x;
    float downVx  = tile[ly + 1][lx].x;

    float c = 0.5 * ((rightVy - leftVy) - (downVx - upVx));
    curl.write(float4(c, 0.0, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: vorticity confinement — re-inject swirls smoothed away by the
// solver (Fedkiw et al.). Only dispatched when vorticity > 0.
// ============================================================================

kernel void hsFluidVorticity(
    texture2d<float, access::read>  vel   [[texture(0)]],
    texture2d<float, access::read>  curl  [[texture(1)]],
    texture2d<float, access::write> out   [[texture(2)]],
    constant HSSimParams&           p     [[buffer(0)]],
    uint2                           gid   [[thread_position_in_grid]],
    uint2                           ltid  [[thread_position_in_threadgroup]],
    uint2                           lsize [[threads_per_threadgroup]]
) {
    threadgroup float4 tile[18][18];
    int2 size = int2(vel.get_width(), vel.get_height());
    loadTile4(tile, curl, ltid, lsize, gid, size);
    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (int(gid.x) >= size.x || int(gid.y) >= size.y) return;

    const uint lx = ltid.x + 1, ly = ltid.y + 1;
    float2 grad = 0.5 * float2(
        abs(tile[ly][lx + 1].x) - abs(tile[ly][lx - 1].x),
        abs(tile[ly + 1][lx].x) - abs(tile[ly - 1][lx].x)
    );
    float2 n = grad / (length(grad) + 1e-5);
    float c = tile[ly][lx].x;
    float2 force = p.vorticity * c * float2(n.y, -n.x);
    float2 v = vel.read(gid).xy + p.deltaTime * force;
    out.write(float4(v, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: divergence of the velocity field
// ============================================================================

kernel void hsFluidDivergence(
    texture2d<float, access::read>  vel   [[texture(0)]],
    texture2d<float, access::write> div   [[texture(1)]],
    uint2                           gid   [[thread_position_in_grid]],
    uint2                           ltid  [[thread_position_in_threadgroup]],
    uint2                           lsize [[threads_per_threadgroup]]
) {
    threadgroup float4 tile[18][18];
    int2 size = int2(vel.get_width(), vel.get_height());
    loadTile4(tile, vel, ltid, lsize, gid, size);
    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (int(gid.x) >= size.x || int(gid.y) >= size.y) return;

    const uint lx = ltid.x + 1, ly = ltid.y + 1;
    float leftVx  = tile[ly][lx - 1].x;
    float rightVx = tile[ly][lx + 1].x;
    float upVy    = tile[ly - 1][lx].y;
    float downVy  = tile[ly + 1][lx].y;

    float d = 0.5 * (rightVx - leftVx + downVy - upVy);
    div.write(float4(d, 0.0, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: pressure solve (Jacobi iteration)
// ============================================================================

kernel void hsFluidPressure(
    texture2d<float, access::read>  x     [[texture(0)]],
    texture2d<float, access::read>  b     [[texture(1)]],
    texture2d<float, access::write> out   [[texture(2)]],
    uint2                           gid   [[thread_position_in_grid]],
    uint2                           ltid  [[thread_position_in_threadgroup]],
    uint2                           lsize [[threads_per_threadgroup]]
) {
    threadgroup float4 tile[18][18];
    int2 size = int2(x.get_width(), x.get_height());
    loadTile4(tile, x, ltid, lsize, gid, size);
    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (int(gid.x) >= size.x || int(gid.y) >= size.y) return;

    const uint lx = ltid.x + 1, ly = ltid.y + 1;
    float left  = tile[ly][lx - 1].x;
    float right = tile[ly][lx + 1].x;
    float up    = tile[ly - 1][lx].x;
    float down  = tile[ly + 1][lx].x;

    float divergence = b.read(gid).x;
    float pressure = 0.25 * (left + right + up + down - divergence);
    out.write(float4(pressure, 0.0, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: project — subtract the pressure gradient to make velocity
// divergence-free
// ============================================================================

kernel void hsFluidProject(
    texture2d<float, access::read>  vel      [[texture(0)]],
    texture2d<float, access::read>  pressure [[texture(1)]],
    texture2d<float, access::write> out      [[texture(2)]],
    uint2                           gid      [[thread_position_in_grid]],
    uint2                           ltid     [[thread_position_in_threadgroup]],
    uint2                           lsize    [[threads_per_threadgroup]]
) {
    threadgroup float4 pTile[18][18];
    int2 size = int2(vel.get_width(), vel.get_height());
    loadTile4(pTile, pressure, ltid, lsize, gid, size);
    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (int(gid.x) >= size.x || int(gid.y) >= size.y) return;

    const uint lx = ltid.x + 1, ly = ltid.y + 1;
    float leftP  = pTile[ly][lx - 1].x;
    float rightP = pTile[ly][lx + 1].x;
    float upP    = pTile[ly - 1][lx].x;
    float downP  = pTile[ly + 1][lx].x;

    float2 grad = float2(0.5 * (rightP - leftP), 0.5 * (downP - upP));
    float2 v = vel.read(gid).xy - grad;
    out.write(float4(v, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: obstacle — the fluid flows around a solid Handshake "H"
// ============================================================================

kernel void hsFluidObstacleH(
    texture2d<float, access::read>  src [[texture(0)]],
    texture2d<float, access::write> dst [[texture(1)]],
    constant HSObstacleParams&      ob  [[buffer(0)]],
    uint2                           gid [[thread_position_in_grid]]
) {
    float2 size = float2(src.get_width(), src.get_height());
    float2 p = (float2(gid) + 0.5) / size - ob.center;
    float sd = sdHandshakeH(p, ob.scale, ob.slant);

    float4 v = src.read(gid);
    v.xy *= smoothstep(0.0, 0.006, sd);   // zero velocity inside the mark
    dst.write(v, gid);
}

// ============================================================================
// Render: fullscreen triangle
// ============================================================================

struct HSVSOut {
    float4 position [[position]];
    float2 uv;
};

vertex HSVSOut hsFluidFullscreenVS(uint vid [[vertex_id]]) {
    float2 pos[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };
    float2 uv[3]  = { float2(0.0, 0.0),   float2(2.0, 0.0),  float2(0.0, 2.0)  };
    HSVSOut out;
    out.position = float4(pos[vid], 0.0, 1.0);
    out.uv = uv[vid];
    return out;
}

// ============================================================================
// Fragment: cool-tone visualization of the flow direction, with an
// aspect-fill remap (square sim → any screen, no stretch) and the frosted
// "H" inset mark composited on top.
// ============================================================================

// Flow direction bilinearly blends the four anchor colours.
static inline float3 hsCoolDirectionColor(float2 vel, constant HSCoolParams& p) {
    float u = clamp((vel.x + 1.0) * 0.5, 0.0, 1.0);
    float v = clamp((vel.y + 1.0) * 0.5, 0.0, 1.0);
    return mix(mix(p.anchorA, p.anchorB, u), mix(p.anchorC, p.anchorD, u), v);
}

fragment half4 hsFluidCoolFieldFS(
    HSVSOut                          in     [[stage_in]],
    texture2d<float, access::sample> tex    [[texture(0)]],
    sampler                          samp   [[sampler(0)]],
    constant HSCoolParams&           params [[buffer(0)]]
) {
    // Aspect-fill: centre-crop the square field so it covers any screen shape
    // without stretching the flow.
    float2 uv = in.uv;
    float a = params.viewAspect;
    if (a < 1.0) {
        uv.x = (uv.x - 0.5) * a + 0.5;
    } else {
        uv.y = (uv.y - 0.5) / a + 0.5;
    }
    // Slight zoom-in hides the 1-texel static border left by the no-slip walls.
    uv = (uv - 0.5) / max(params.overscan, 1.0) + 0.5;

    float2 vel = tex.sample(samp, uv).xy;
    float3 color = hsCoolDirectionColor(vel, params);
    float lift = clamp(length(vel) * params.glow, 0.0, 0.6);
    color = mix(color, float3(0.92, 0.97, 1.0), lift);

    // Frosted "H" inset mark, aligned to the compute obstacle (same sim coord).
    if (params.obstacleEnabled > 0.5) {
        float2 p = uv - params.obstacleCenter;
        float sd = sdHandshakeH(p, params.obstacleScale, params.obstacleSlant);
        float fill = 1.0 - smoothstep(0.0, 0.004, sd);
        float edge = 1.0 - smoothstep(0.0, 0.004, abs(sd) - 0.0015);
        float3 frosted = mix(color, float3(0.16, 0.22, 0.28), 0.6);
        color = mix(color, frosted, fill * params.markStrength);
        color = mix(color, float3(0.95, 0.98, 1.0), edge * 0.22 * params.markStrength);
    }

    return half4(half3(color), 1.0h);
}
