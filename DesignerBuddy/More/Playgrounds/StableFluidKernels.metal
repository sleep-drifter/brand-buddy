// Stable-fluid GPU solver ported from Koshimizu-Takehito's my-toybox.
// Attribution: Jos Stam, "Stable Fluids," SIGGRAPH 1999.
// Metal impl inspired by TypeGPU — © 2025 Software Mansion — MIT License
//   https://github.com/software-mansion/TypeGPU

#include <metal_stdlib>
using namespace metal;

// ============================================================================
// Shared types
// ============================================================================

struct SimParams {
    float deltaTime;
    float viscosity;
};

struct BrushParams {
    int2   pos;
    float2 delta;
    float  radius;
    float  forceScale;
    float  inkAmount;
};

// ============================================================================
// Helpers
// ============================================================================

static inline int2 clampCoord(int2 coord, int2 bounds) {
    return clamp(coord, int2(0), bounds - 1);
}

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

// ============================================================================
// Compute: Brush – generate force and ink from touch input
// ============================================================================

kernel void fluidBrush(
    texture2d<float, access::write> forceDst [[texture(0)]],
    texture2d<float, access::write> inkDst   [[texture(1)]],
    constant BrushParams&           brush    [[buffer(0)]],
    uint2                           gid      [[thread_position_in_grid]]
) {
    float dx = float(gid.x) - float(brush.pos.x);
    float dy = float(gid.y) - float(brush.pos.y);
    float distSq = dx * dx + dy * dy;
    float radiusSq = brush.radius * brush.radius;

    float2 forceVec = float2(0.0);
    float  ink = 0.0;

    if (distSq < radiusSq) {
        float w = exp(-distSq / radiusSq);
        forceVec = brush.forceScale * w * brush.delta;
        ink = brush.inkAmount * w;
    }

    forceDst.write(float4(forceVec, 0.0, 1.0), gid);
    inkDst.write(float4(ink, 0.0, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: Add ink to density field
// ============================================================================

kernel void fluidAddInk(
    texture2d<float, access::read>  src [[texture(0)]],
    texture2d<float, access::read>  add [[texture(1)]],
    texture2d<float, access::write> dst [[texture(2)]],
    uint2                           gid [[thread_position_in_grid]]
) {
    float srcVal = src.read(gid).x;
    float addVal = add.read(gid).x;
    dst.write(float4(srcVal + addVal, 0.0, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: Add forces to velocity field
// ============================================================================

kernel void fluidAddForces(
    texture2d<float, access::read>  src   [[texture(0)]],
    texture2d<float, access::read>  force [[texture(1)]],
    texture2d<float, access::write> dst   [[texture(2)]],
    constant SimParams&             p     [[buffer(0)]],
    uint2                           gid   [[thread_position_in_grid]]
) {
    float2 vel = src.read(gid).xy;
    float2 f   = force.read(gid).xy;
    float2 out = vel + p.deltaTime * f;
    dst.write(float4(out, 0.0, 1.0), gid);
}

// ============================================================================
// Compute: Advect velocity (Semi-Lagrangian with bilinear sampling)
// ============================================================================

kernel void fluidAdvect(
    texture2d<half, access::sample> src    [[texture(0)]],
    texture2d<float, access::write> dst    [[texture(1)]],
    sampler                         samp   [[sampler(0)]],
    constant SimParams&             p      [[buffer(0)]],
    uint2                           gid    [[thread_position_in_grid]]
) {
    uint w = src.get_width();
    uint h = src.get_height();

    if (gid.x <= 0 || gid.y <= 0 || gid.x >= w - 1 || gid.y >= h - 1) {
        dst.write(float4(0.0, 0.0, 0.0, 1.0), gid);
        return;
    }

    float2 vel = float2(src.read(gid).xy);
    float2 prevPos = float2(gid) - p.deltaTime * vel;
    float2 clamped = clamp(prevPos, float2(-0.5), float2(float(w), float(h)) - 0.5);
    float2 uv = (clamped + 0.5) / float2(float(w), float(h));
    float4 sampled = float4(src.sample(samp, uv));
    dst.write(sampled, gid);
}

// ============================================================================
// Compute: Diffusion (Jacobi iteration)
// ============================================================================

kernel void fluidDiffusion(
    texture2d<float, access::read>  src  [[texture(0)]],
    texture2d<float, access::write> dst  [[texture(1)]],
    constant SimParams&             p    [[buffer(0)]],
    uint2                           gid  [[thread_position_in_grid]],
    uint2                           ltid [[thread_position_in_threadgroup]],
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
    float4 result = blend * (left + right + up + down + center * alpha);
    dst.write(result, gid);
}

// ============================================================================
// Compute: Divergence of velocity field
// ============================================================================

kernel void fluidDivergence(
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
// Compute: Pressure solve (Jacobi iteration)
// ============================================================================

kernel void fluidPressure(
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
// Compute: Project – subtract pressure gradient from velocity
// ============================================================================

kernel void fluidProject(
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
// Compute: Advect ink density using velocity field
// ============================================================================

kernel void fluidAdvectInk(
    texture2d<float, access::read>  vel  [[texture(0)]],
    texture2d<half, access::sample> src  [[texture(1)]],
    texture2d<float, access::write> dst  [[texture(2)]],
    sampler                         samp [[sampler(0)]],
    constant SimParams&             p    [[buffer(0)]],
    uint2                           gid  [[thread_position_in_grid]]
) {
    uint w = src.get_width();
    uint h = src.get_height();

    float2 v = vel.read(gid).xy;
    float2 prevPos = float2(gid) - p.deltaTime * v;
    float2 clamped = clamp(prevPos, float2(-0.5), float2(float(w), float(h)) - 0.5);
    float2 uv = (clamped + 0.5) / float2(float(w), float(h));
    float4 sampled = float4(src.sample(samp, uv));
    dst.write(sampled, gid);
}

// ============================================================================
// Render: Fullscreen triangle
// ============================================================================

struct FluidVSOut {
    float4 position [[position]];
    float2 uv;
};

vertex FluidVSOut fluidFullscreenVS(uint vid [[vertex_id]]) {
    float2 pos[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0),
    };
    float2 uv[3] = {
        float2(0.0, 0.0),
        float2(2.0, 0.0),
        float2(0.0, 2.0),
    };
    FluidVSOut out;
    out.position = float4(pos[vid], 0.0, 1.0);
    out.uv = uv[vid];
    return out;
}

// ============================================================================
// Fragment: Ink visualization
// ============================================================================

fragment half4 fluidInkFS(
    FluidVSOut                      in   [[stage_in]],
    texture2d<half, access::sample> tex  [[texture(0)]],
    sampler                         samp [[sampler(0)]]
) {
    half d = tex.sample(samp, in.uv).x;
    return half4(d, d * 0.8h, d * 0.5h, 1.0h);
}

// ============================================================================
// Fragment: Velocity visualization
// ============================================================================

fragment half4 fluidVelocityFS(
    FluidVSOut                      in   [[stage_in]],
    texture2d<half, access::sample> tex  [[texture(0)]],
    sampler                         samp [[sampler(0)]]
) {
    half2 vel = tex.sample(samp, in.uv).xy;
    half mag = length(vel);
    return half4((vel.x + 1.0h) * 0.5h, (vel.y + 1.0h) * 0.5h, mag * 0.4h, 1.0h);
}

// ============================================================================
// Fragment: Cool-tone visualization (velocity field or ink dye)
// ============================================================================

struct CoolParams {
    float glow;     // how strongly speed lifts the color toward icy white
    float exposure; // ink density gain (ink source only)
};

// Flow direction bilinearly blends four cool anchor colors:
// green / cyan on the left-right axis, iOS blue / light violet on top.
static inline float3 coolDirectionColor(float2 vel) {
    const float3 green  = float3(0.204, 0.780, 0.349); // systemGreen
    const float3 cyan   = float3(0.200, 0.830, 0.930);
    const float3 blue   = float3(0.000, 0.478, 1.000); // systemBlue
    const float3 violet = float3(0.720, 0.620, 0.980);

    float u = clamp((vel.x + 1.0) * 0.5, 0.0, 1.0);
    float v = clamp((vel.y + 1.0) * 0.5, 0.0, 1.0);
    return mix(mix(green, cyan, u), mix(blue, violet, u), v);
}

// Same direction encoding as fluidVelocityFS, but mapped into the cool
// anchors instead of raw RGB. The whole field stays colored.
fragment half4 fluidVelocityCoolFS(
    FluidVSOut                      in     [[stage_in]],
    texture2d<half, access::sample> tex    [[texture(0)]],
    sampler                         samp   [[sampler(0)]],
    constant CoolParams&            params [[buffer(0)]]
) {
    float2 vel = float2(tex.sample(samp, in.uv).xy);
    float3 color = coolDirectionColor(vel);
    float lift = clamp(length(vel) * params.glow, 0.0, 0.6);
    color = mix(color, float3(0.92, 0.97, 1.0), lift);
    return half4(half3(color), 1.0h);
}

// Ink-driven variant: hue still comes from flow direction, but brightness
// comes from dye density, so trails glow in cool tones on black.
fragment half4 fluidInkCoolFS(
    FluidVSOut                      in     [[stage_in]],
    texture2d<half, access::sample> velTex [[texture(0)]],
    texture2d<half, access::sample> inkTex [[texture(1)]],
    sampler                         samp   [[sampler(0)]],
    constant CoolParams&            params [[buffer(0)]]
) {
    float2 vel = float2(velTex.sample(samp, in.uv).xy);
    float d = float(inkTex.sample(samp, in.uv).x);
    float density = 1.0 - exp(-max(d, 0.0) * params.exposure);

    float3 color = coolDirectionColor(vel) * density;
    float lift = clamp(length(vel) * params.glow, 0.0, 0.6) * density;
    color = mix(color, float3(0.92, 0.97, 1.0), lift);
    return half4(half3(color), 1.0h);
}

// ============================================================================
// Fragment: Image distortion via ink density gradient (aspect fit / fill)
// ============================================================================

constant bool kUseAspectFill [[function_constant(0)]];

struct ImageParams {
    float pixelStep;
    float imageAspect;
};

fragment half4 fluidImageFS(
    FluidVSOut                       in     [[stage_in]],
    texture2d<half, access::sample>  inkTex [[texture(0)]],
    texture2d<float, access::sample> bgTex  [[texture(1)]],
    sampler                          samp   [[sampler(0)]],
    constant ImageParams&            params [[buffer(0)]]
) {
    float ps = params.pixelStep;
    half left  = inkTex.sample(samp, float2(in.uv.x - ps, in.uv.y)).x;
    half right = inkTex.sample(samp, float2(in.uv.x + ps, in.uv.y)).x;
    half up    = inkTex.sample(samp, float2(in.uv.x, in.uv.y + ps)).x;
    half down  = inkTex.sample(samp, float2(in.uv.x, in.uv.y - ps)).x;

    float2 grad = float2(float(right - left), float(up - down));
    float strength = 0.8;
    float2 distorted = in.uv + grad * float2(strength, -strength);

    float aspect = params.imageAspect;
    float2 bgUV;
    if (kUseAspectFill) {
        if (aspect > 1.0) {
            bgUV = float2(0.5 + (distorted.x - 0.5) / aspect, distorted.y);
        } else {
            bgUV = float2(distorted.x, 0.5 + (distorted.y - 0.5) * aspect);
        }
    } else {
        if (aspect > 1.0) {
            float h = 1.0 / aspect;
            float off = (1.0 - h) * 0.5;
            bgUV = float2(distorted.x, (distorted.y - off) / h);
        } else {
            float w = aspect;
            float off = (1.0 - w) * 0.5;
            bgUV = float2((distorted.x - off) / w, distorted.y);
        }
    }
    bgUV.y = 1.0 - bgUV.y;

    if (bgUV.x < 0.0 || bgUV.x > 1.0 || bgUV.y < 0.0 || bgUV.y > 1.0) {
        return half4(0.0h, 0.0h, 0.0h, 1.0h);
    }

    half4 color = half4(bgTex.sample(samp, bgUV));
    return half4(color.rgb, 1.0h);
}
