#include <metal_stdlib>
using namespace metal;

// Shadertoy classics, ported to Metal for the Shaders playground.
//
// Licensing — NOTE: unlike the MIT-licensed effects elsewhere in this app,
// three of these carry Creative Commons BY-NC-SA 3.0 (attribution required,
// NonCommercial use only, derivatives stay under the same license):
//
//   "Seascape"       (c) Alexander Alekseev aka TDM, 2014
//                    https://www.shadertoy.com/view/Ms2SD1 — CC BY-NC-SA 3.0
//   "Protean Clouds" (c) nimitz (@stormoid), 2019
//                    https://www.shadertoy.com/view/3l23Rh — CC BY-NC-SA 3.0
//   "Plasma Globe"   (c) nimitz (@stormoid), 2014
//                    https://www.shadertoy.com/view/XsjXRm — CC BY-NC-SA 3.0
//   "Star Nest"      (c) Pablo Roman Andrioli aka Kali
//                    https://www.shadertoy.com/view/XlfGRj — MIT License
//
// Adaptations for this app: SwiftUI stitchable signatures; Shadertoy's
// bottom-up fragCoord flipped to SwiftUI's top-down position; the mouse
// uniform replaced by the playground's tap point; Plasma Globe's texture
// noise replaced with procedural hash noise; a few constants exposed as
// slider parameters. Algorithms are otherwise faithful to the originals.

// GLSL-style mod: unlike fmod, the result takes the sign of the divisor,
// which the Star Nest tiling fold depends on.
static float3 st_mod3(float3 x, float y) {
    return x - y * floor(x / y);
}

// MARK: - Star Nest (Kali, MIT)

// Volumetric fractal starfield: a Kaliset iterated over ray-march slices,
// colored by distance. Tap the preview to steer the camera.
[[ stitchable ]] half4 shaderStarNest(float2 position, half4 color, float2 size, float time,
                                      float speed, float zoom, float formuparam,
                                      float brightness, float saturation, float2 center) {
    const int iterations = 17;
    const int volsteps = 18;
    const float stepsize = 0.1;
    const float tile = 0.85;
    const float darkmatter = 0.3;
    const float distfading = 0.76;

    float2 uv = position / size - 0.5;
    uv.y *= -size.y / size.x;
    float3 dir = float3(uv * zoom, 1.0);
    float t = time * speed + 0.25;

    float a1 = 0.5 + center.x / size.x * 2.0;
    float a2 = 0.8 + center.y / size.y * 2.0;
    float2x2 rot1 = float2x2(float2(cos(a1), sin(a1)), float2(-sin(a1), cos(a1)));
    float2x2 rot2 = float2x2(float2(cos(a2), sin(a2)), float2(-sin(a2), cos(a2)));
    dir.xz = dir.xz * rot1;
    dir.xy = dir.xy * rot2;

    float3 from = float3(1.0, 0.5, 0.5);
    from += float3(t * 2.0, t, -2.0);
    from.xz = from.xz * rot1;
    from.xy = from.xy * rot2;

    float s = 0.1;
    float fade = 1.0;
    float3 v = float3(0.0);
    for (int r = 0; r < volsteps; r++) {
        float3 p = from + s * dir * 0.5;
        p = abs(float3(tile) - st_mod3(p, tile * 2.0));  // tiling fold
        float pa = 0.0;
        float a = 0.0;
        for (int i = 0; i < iterations; i++) {
            p = abs(p) / dot(p, p) - formuparam;  // the magic formula
            a += abs(length(p) - pa);             // absolute sum of average change
            pa = length(p);
        }
        float dm = max(0.0, darkmatter - a * a * 0.001);
        a *= a * a;                               // add contrast
        if (r > 3) { fade *= 1.0 - dm; }          // dark matter, don't render near
        v += fade;
        v += float3(s, s * s, s * s * s * s) * a * brightness * fade;
        fade *= distfading;
        s += stepsize;
    }
    v = mix(float3(length(v)), v, saturation);
    return half4(half3(v * 0.01), 1.0h) * color.a;
}

// MARK: - Seascape (TDM, CC BY-NC-SA 3.0)

static float sc_hash(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

static float sc_noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * mix(mix(sc_hash(i + float2(0.0, 0.0)),
                                sc_hash(i + float2(1.0, 0.0)), u.x),
                            mix(sc_hash(i + float2(0.0, 1.0)),
                                sc_hash(i + float2(1.0, 1.0)), u.x), u.y);
}

static float sc_diffuse(float3 n, float3 l, float p) {
    return pow(dot(n, l) * 0.4 + 0.6, p);
}

static float sc_specular(float3 n, float3 l, float3 e, float s) {
    float nrm = (s + 8.0) / (3.141592 * 8.0);
    return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;
}

static float3 sc_skyColor(float3 e) {
    e.y = max(e.y, 0.0);
    return float3(pow(1.0 - e.y, 2.0), 1.0 - e.y, 0.6 + (1.0 - e.y) * 0.4);
}

static float sc_octave(float2 uv, float choppy) {
    uv += sc_noise(uv);
    float2 wv = 1.0 - abs(sin(uv));
    float2 swv = abs(cos(uv));
    wv = mix(wv, swv, wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

static float sc_map(float3 p, float seaTime, float seaHeight, float seaChoppy, int iter) {
    float freq = 0.16;
    float amp = seaHeight;
    float choppy = seaChoppy;
    float2 uv = p.xz;
    uv.x *= 0.75;
    const float2x2 octave_m = float2x2(float2(1.6, 1.2), float2(-1.2, 1.6));

    float d;
    float h = 0.0;
    for (int i = 0; i < iter; i++) {
        d = sc_octave((uv + seaTime) * freq, choppy);
        d += sc_octave((uv - seaTime) * freq, choppy);
        h += d * amp;
        uv = uv * octave_m;
        freq *= 1.9;
        amp *= 0.22;
        choppy = mix(choppy, 1.0, 0.2);
    }
    return p.y - h;
}

static float3 sc_seaColor(float3 p, float3 n, float3 l, float3 eye, float3 dist, float seaHeight) {
    const float3 SEA_BASE = float3(0.1, 0.19, 0.22);
    const float3 SEA_WATER_COLOR = float3(0.8, 0.9, 0.6);

    float fresnel = clamp(1.0 - dot(n, -eye), 0.0, 1.0);
    fresnel = pow(fresnel, 3.0) * 0.65;

    float3 reflected = sc_skyColor(reflect(eye, n));
    float3 refracted = SEA_BASE + sc_diffuse(n, l, 80.0) * SEA_WATER_COLOR * 0.12;

    float3 col = mix(refracted, reflected, fresnel);

    float atten = max(1.0 - dot(dist, dist) * 0.001, 0.0);
    col += SEA_WATER_COLOR * (p.y - seaHeight) * 0.18 * atten;

    col += float3(sc_specular(n, l, eye, 60.0));
    return col;
}

static float3 sc_normal(float3 p, float eps, float seaTime, float seaHeight, float seaChoppy) {
    float3 n;
    n.y = sc_map(p, seaTime, seaHeight, seaChoppy, 5);
    n.x = sc_map(float3(p.x + eps, p.y, p.z), seaTime, seaHeight, seaChoppy, 5) - n.y;
    n.z = sc_map(float3(p.x, p.y, p.z + eps), seaTime, seaHeight, seaChoppy, 5) - n.y;
    n.y = eps;
    return normalize(n);
}

static float sc_tracing(float3 ori, float3 dir, thread float3 &p,
                        float seaTime, float seaHeight, float seaChoppy) {
    float tm = 0.0;
    float tx = 1000.0;
    p = ori + dir * tx;
    float hx = sc_map(p, seaTime, seaHeight, seaChoppy, 3);
    if (hx > 0.0) { return tx; }
    float hm = sc_map(ori + dir * tm, seaTime, seaHeight, seaChoppy, 3);
    float tmid = 0.0;
    for (int i = 0; i < 8; i++) {
        tmid = mix(tm, tx, hm / (hm - hx));
        p = ori + dir * tmid;
        float hmid = sc_map(p, seaTime, seaHeight, seaChoppy, 3);
        if (hmid < 0.0) {
            tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
    }
    return tmid;
}

static float3x3 sc_fromEuler(float3 ang) {
    float2 a1 = float2(sin(ang.x), cos(ang.x));
    float2 a2 = float2(sin(ang.y), cos(ang.y));
    float2 a3 = float2(sin(ang.z), cos(ang.z));
    return float3x3(
        float3(a1.y * a3.y + a1.x * a2.x * a3.x, a1.y * a2.x * a3.x + a3.y * a1.x, -a2.y * a3.x),
        float3(-a2.y * a1.x, a1.y * a2.y, a2.x),
        float3(a3.y * a1.x * a2.x + a1.y * a3.x, a1.x * a3.x - a1.y * a3.y * a2.x, a2.y * a3.y)
    );
}

// Fully procedural animated ocean: fbm heightfield traced by bisection,
// shaded with fresnel sky reflection and depth-tinted water.
[[ stitchable ]] half4 shaderSeascape(float2 position, half4 color, float2 size, float time,
                                      float speed, float waveHeight, float choppy, float pitch) {
    float2 uv = position / size;
    uv = uv * 2.0 - 1.0;
    uv.y = -uv.y;
    uv.x *= size.x / size.y;

    float t = time * speed * 0.3;
    float seaTime = 1.0 + time * speed * 0.8;
    float epsNrm = 0.1 / size.x;

    // ray
    float3 ang = float3(sin(t * 3.0) * 0.1, sin(t) * 0.2 + pitch, t);
    float3 ori = float3(0.0, 3.5, t * 5.0);
    float3 dir = normalize(float3(uv, -2.0));
    dir.z += length(uv) * 0.15;
    dir = normalize(dir) * sc_fromEuler(ang);

    // tracing
    float3 p;
    sc_tracing(ori, dir, p, seaTime, waveHeight, choppy);
    float3 dist = p - ori;
    float3 n = sc_normal(p, dot(dist, dist) * epsNrm, seaTime, waveHeight, choppy);
    float3 light = normalize(float3(0.0, 1.0, 0.8));

    // color
    float3 col = mix(
        sc_skyColor(dir),
        sc_seaColor(p, n, light, dir, dist, waveHeight),
        pow(smoothstep(0.0, -0.05, dir.y), 0.3));

    return half4(half3(pow(col, float3(0.75))), 1.0h) * color.a;
}

// MARK: - Protean Clouds (nimitz, CC BY-NC-SA 3.0)

static float2x2 pc_rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return float2x2(float2(c, s), float2(-s, c));
}

// nimitz's grid-deformation matrix, premultiplied by 1.93.
constant float3x3 pc_m3 = float3x3(
    float3(0.6434234, 1.0814562, -1.3860681),
    float3(-1.6962191, 0.6301643, -0.2957339),
    float3(0.2926266, 1.3432028, 1.1838427));

static float pc_mag2(float2 p) { return dot(p, p); }

static float pc_linstep(float mn, float mx, float x) {
    return clamp((x - mn) / (mx - mn), 0.0, 1.0);
}

static float2 pc_disp(float t) {
    return float2(sin(t * 0.22), cos(t * 0.175));
}

static float2 pc_map(float3 p, float time, float prm1, float densityOff) {
    float3 p2 = p;
    p2.xy -= pc_disp(p.z);
    p.xy = p.xy * pc_rot(sin(p.z + time) * (0.1 + prm1 * 0.05) + time * 0.09);
    float cl = pc_mag2(p2.xy);
    float d = 0.0;
    p *= 0.61;
    float z = 1.0;
    float trk = 1.0;
    float dspAmp = 0.1 + prm1 * 0.2;
    for (int i = 0; i < 5; i++) {
        p += sin(p.zxy * 0.75 * trk + time * trk * 0.8) * dspAmp;
        d -= abs(dot(cos(p), sin(p.yzx)) * z);
        z *= 0.57;
        trk *= 1.4;
        p = p * pc_m3;
    }
    d = abs(d + prm1 * 3.0) + prm1 * 0.3 - 2.5 + densityOff;
    return float2(d + cl * 0.2 + 0.25, cl);
}

static float4 pc_render(float3 ro, float3 rd, float time, float prm1, float densityOff, int steps) {
    float4 rez = float4(0.0);
    const float ldst = 8.0;
    float t = 1.5;
    float fogT = 0.0;
    for (int i = 0; i < steps; i++) {
        if (rez.a > 0.99) { break; }

        float3 pos = ro + t * rd;
        float2 mpv = pc_map(pos, time, prm1, densityOff);
        float den = clamp(mpv.x - 0.3, 0.0, 1.0) * 1.12;
        float dn = clamp(mpv.x + 2.0, 0.0, 3.0);

        float4 col = float4(0.0);
        if (mpv.x > 0.6) {
            col = float4(sin(float3(5.0, 0.4, 0.2) + mpv.y * 0.1 + sin(pos.z * 0.4) * 0.5 + 1.8) * 0.5 + 0.5, 0.08);
            col *= den * den * den;
            col.rgb *= pc_linstep(4.0, -2.5, mpv.x) * 2.3;
            float dif = clamp((den - pc_map(pos + 0.8, time, prm1, densityOff).x) / 9.0, 0.001, 1.0);
            dif += clamp((den - pc_map(pos + 0.35, time, prm1, densityOff).x) / 2.5, 0.001, 1.0);
            col.xyz *= den * (float3(0.005, 0.045, 0.075) + 1.5 * float3(0.033, 0.07, 0.03) * dif);
        }

        float fogC = exp(t * 0.2 - 2.2);
        col += float4(0.06, 0.11, 0.11, 0.1) * clamp(fogC - fogT, 0.0, 1.0);
        fogT = fogC;
        rez = rez + col * (1.0 - rez.a);
        t += clamp(0.5 - dn * dn * 0.05, 0.09, 0.3);
    }
    return clamp(rez, 0.0, 1.0);
}

static float pc_getsat(float3 c) {
    float mi = min(min(c.x, c.y), c.z);
    float ma = max(max(c.x, c.y), c.z);
    return (ma - mi) / (ma + 1e-7);
}

// Saturation-preserving color interpolation.
static float3 pc_iLerp(float3 a, float3 b, float x) {
    float3 ic = mix(a, b, x) + float3(1e-6, 0.0, 0.0);
    float sd = abs(pc_getsat(ic) - mix(pc_getsat(a), pc_getsat(b), x));
    float3 dir = normalize(float3(2.0 * ic.x - ic.y - ic.z,
                                  2.0 * ic.y - ic.x - ic.z,
                                  2.0 * ic.z - ic.y - ic.x));
    float lgt = dot(float3(1.0), ic);
    float ff = dot(dir, normalize(ic));
    ic += 1.5 * dir * sd * ff * lgt;
    return clamp(ic, 0.0, 1.0);
}

// Volumetric flythrough of a deformed-grid noise field, with dynamic step
// marching and saturation-aware color mixing.
[[ stitchable ]] half4 shaderProteanClouds(float2 position, half4 color, float2 size, float time,
                                           float speed, float densityOff, float stepsF) {
    float2 q = position / size;
    float2 p = (position - 0.5 * size) / size.y;
    p.y = -p.y;

    float t = time * speed;
    float3 ro = float3(0.0, 0.0, t);
    ro += float3(sin(t) * 0.5, 0.0, 0.0);

    float dspAmp = 0.85;
    ro.xy += pc_disp(ro.z) * dspAmp;
    float tgtDst = 3.5;

    float3 target = normalize(ro - float3(pc_disp(t + tgtDst) * dspAmp, t + tgtDst));
    float3 rightdir = normalize(cross(target, float3(0.0, 1.0, 0.0)));
    float3 updir = normalize(cross(rightdir, target));
    rightdir = normalize(cross(updir, target));
    float3 rd = normalize(p.x * rightdir + p.y * updir - target);
    rd.xy = rd.xy * pc_rot(-pc_disp(t + 3.5).x * 0.2);

    float prm1 = smoothstep(-0.4, 0.4, sin(t * 0.3));
    float4 scn = pc_render(ro, rd, t, prm1, densityOff, int(stepsF));

    float3 col = scn.rgb;
    col = pc_iLerp(col.bgr, col.rgb, clamp(1.0 - prm1, 0.05, 1.0));
    col = pow(col, float3(0.55, 0.65, 0.6)) * float3(1.0, 0.97, 0.9);
    col *= pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.12) * 0.7 + 0.3;

    return half4(half3(col), 1.0h) * color.a;
}

// MARK: - Plasma Globe (nimitz, CC BY-NC-SA 3.0)

static float2x2 pg_mm2(float a) {
    float c = cos(a);
    float s = sin(a);
    return float2x2(float2(c, -s), float2(s, c));
}

static float pg_hash(float n) {
    return fract(sin(n) * 43758.5453);
}

// Procedural stand-ins for the original's noise texture (iChannel0).
static float pg_noise1(float x) {
    float i = floor(x);
    float f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(pg_hash(i), pg_hash(i + 1.0), f);
}

static float pg_noise3(float3 x) {
    float3 p = floor(x);
    float3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    return mix(mix(mix(pg_hash(n), pg_hash(n + 1.0), f.x),
                   mix(pg_hash(n + 57.0), pg_hash(n + 58.0), f.x), f.y),
               mix(mix(pg_hash(n + 113.0), pg_hash(n + 114.0), f.x),
                   mix(pg_hash(n + 170.0), pg_hash(n + 171.0), f.x), f.y), f.z);
}

constant float3x3 pg_m3 = float3x3(
    float3(0.00, 0.80, 0.60),
    float3(-0.80, 0.36, -0.48),
    float3(-0.60, -0.48, 0.64));

static float pg_flow(float3 p, float t, float time) {
    float z = 2.0;
    float rz = 0.0;
    float3 bp = p;
    for (float i = 1.0; i < 5.0; i++) {
        p += time * 0.1;
        rz += (sin(pg_noise3(p + t * 0.8) * 6.0) * 0.5 + 0.5) / z;
        p = mix(bp, p, 0.6);
        z *= 2.0;
        p *= 2.01;
        p = p * pg_m3;
    }
    return rz;
}

static float pg_sins(float x, float time) {
    float rz = 0.0;
    float z = 2.0;
    for (float i = 0.0; i < 3.0; i++) {
        rz += abs(fract(x * 1.4) - 0.5) / z;
        x *= 1.3;
        z *= 1.15;
        x -= time * 0.65 * z;
    }
    return rz;
}

static float pg_segm(float3 p, float3 a, float3 b) {
    float3 pa = p - a;
    float3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) * 0.5;
}

static float3 pg_path(float i, float d, float time) {
    float3 en = float3(0.0, 0.0, 1.0);
    float sns2 = pg_sins(d + i * 0.5, time) * 0.22;
    float sns = pg_sins(d + i * 0.6, time) * 0.21;
    en.xz = pg_mm2((pg_hash(i * 10.569) - 0.5) * 6.2 + sns2) * en.xz;
    en.xy = pg_mm2((pg_hash(i * 4.732) - 0.5) * 6.2 + sns) * en.xy;
    return en;
}

static float2 pg_map(float3 p, float i, float time) {
    float lp = length(p);
    float3 bg = float3(0.0);
    float3 en = pg_path(i, lp, time);

    float ins = smoothstep(0.11, 0.46, lp);
    float outs = 0.15 + smoothstep(0.0, 0.15, abs(lp - 1.0));
    p *= ins * outs;
    float id = ins * outs;

    float rz = pg_segm(p, bg, en) - 0.011;
    return float2(rz, id);
}

static float pg_march(float3 ro, float3 rd, float startf, float maxd, float j, float time) {
    float precis = 0.001;
    float h = 0.5;
    float d = startf;
    for (int i = 0; i < 35; i++) {
        if (abs(h) < precis || d > maxd) { break; }
        d += h * 1.2;
        h = pg_map(ro + rd * d, j, time).x;
    }
    return d;
}

static float3 pg_vmarch(float3 ro, float3 rd, float j, float3 orig, float time) {
    float3 p = ro;
    float2 r = float2(0.0);
    float3 sum = float3(0.0);
    for (int i = 0; i < 19; i++) {
        r = pg_map(p, j, time);
        p += rd * 0.03;
        float lp = length(p);

        float3 col = sin(float3(1.05, 2.5, 1.52) * 3.94 + r.y) * 0.85 + 0.4;
        col *= smoothstep(0.0, 0.015, -r.x);
        col *= smoothstep(0.04, 0.2, abs(lp - 1.1));
        col *= smoothstep(0.1, 0.34, lp);
        sum += abs(col) * 5.0
            * (1.2 - pg_noise1((lp * 2.0 + j * 13.0 + time * 5.0) * 0.35) * 1.1)
            / (log(distance(p, orig) - 2.0) + 0.75);
    }
    return sum;
}

// Both collision distances of a unit sphere at the origin.
static float2 pg_iSphere2(float3 ro, float3 rd) {
    float3 oc = ro;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - 1.0;
    float h = b * b - c;
    if (h < 0.0) { return float2(-1.0); }
    return float2(-b - sqrt(h), -b + sqrt(h));
}

// A glass sphere full of volumetric lightning: ray-marched plasma bolts
// plus flow-noise glow on the sphere surface. Tap the preview to spin it.
[[ stitchable ]] half4 shaderPlasmaGlobe(float2 position, half4 color, float2 size, float time,
                                         float speed, float raysF, float2 center) {
    float t = time * speed;

    float2 p = position / size - 0.5;
    p.y = -p.y;
    p.x *= size.x / size.y;
    float2 um = center / size - 0.5;

    // camera
    float3 ro = float3(0.0, 0.0, 5.0);
    float3 rd = normalize(float3(p * 0.7, -1.5));
    float2x2 mx = pg_mm2(t * 0.4 + um.x * 6.0);
    float2x2 my = pg_mm2(t * 0.3 + um.y * 6.0);
    ro.xz = ro.xz * mx;
    rd.xz = rd.xz * mx;
    ro.xy = ro.xy * my;
    rd.xy = rd.xy * my;

    float3 bro = ro;
    float3 brd = rd;

    float3 col = float3(0.0125, 0.0, 0.025);
    float rays = clamp(raysF, 1.0, 25.0);
    for (float j = 1.0; j < rays + 1.0; j++) {
        ro = bro;
        rd = brd;
        float2x2 mm = pg_mm2((t * 0.1 + ((j + 1.0) * 5.1)) * j * 0.25);
        ro.xy = ro.xy * mm;
        rd.xy = rd.xy * mm;
        ro.xz = ro.xz * mm;
        rd.xz = rd.xz * mm;
        float rz = pg_march(ro, rd, 2.5, 6.0, j, t);
        if (rz >= 6.0) { continue; }
        float3 pos = ro + rz * rd;
        col = max(col, pg_vmarch(pos, rd, j, bro, t));
    }

    ro = bro;
    rd = brd;
    float2 sph = pg_iSphere2(ro, rd);

    if (sph.x > 0.0) {
        float3 pos = ro + rd * sph.x;
        float3 pos2 = ro + rd * sph.y;
        float3 rf = reflect(rd, pos);
        float3 rf2 = reflect(rd, pos2);
        float nz = -log(abs(pg_flow(rf * 1.2, t, t) - 0.01));
        float nz2 = -log(abs(pg_flow(rf2 * 1.2, -t, t) - 0.01));
        col += (0.1 * nz * nz * float3(0.12, 0.12, 0.5)
                + 0.05 * nz2 * nz2 * float3(0.55, 0.2, 0.55)) * 0.8;
    }

    return half4(half3(col * 1.3), 1.0h) * color.a;
}
