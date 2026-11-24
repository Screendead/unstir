// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The slope's rock, cut and polished, a tier each: sandstone's beds, agate's bands, a thin section of slate between
// polarisers, and basalt's columns seen end on. Each reads Picture.gradients, two tables, and repeats every 20 s.

// Gradient noise at p and its gradient (x the value, yz the gradient), from an 8 x 8 table of unit gradients, tiled.
static float3 noised(float2 p, device const float2 *g) {
    float2 i = floor(p), f = p - i;
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0), du = 30.0 * f * f * (f * (f - 2.0) + 1.0);
    int2 c = int2(i) & 7, c1 = (c + 1) & 7;
    float2 ga = g[c.y * 8 + c.x], gb = g[c.y * 8 + c1.x], gc = g[c1.y * 8 + c.x], gd = g[c1.y * 8 + c1.x];
    float va = dot(ga, f), vb = dot(gb, f - float2(1, 0)), vc = dot(gc, f - float2(0, 1)), vd = dot(gd, f - 1.0);
    float k = va - vb - vc + vd;
    float v = va + u.x * (vb - va) + u.y * (vc - va) + u.x * u.y * k;
    float2 grad = ga + u.x * (gb - ga) + u.y * (gc - ga) + u.x * u.y * (ga - gb - gc + gd)
                + du * (u.yx * k + float2(vb - va, vc - va));
    return float3(v, grad);
}

// A level's own number from its tables, to salt `hash`.
static uint salt(device const float2 *g) { return uint(abs(g[0].x) * 65535.0) * 77u + uint(abs(g[1].y) * 65535.0); }

// Two random numbers in 0..<1 for a cell.
static float2 hash(int2 c, uint s) {
    uint h = uint(c.x) * 0x9E3779B1u ^ uint(c.y) * 0x85EBCA77u ^ s;
    h ^= h >> 15; h *= 0x2C1B3C6Du; h ^= h >> 12; h *= 0x297A2D39u; h ^= h >> 15;
    return float2(h & 0xFFFFu, h >> 16) / 65536.0;
}

// The nearest two of the seeds scattered one to a unit cell: (distance to the nearest, distance to the line midway
// to the second, the nearest's cell). Jitter stays within 0.35 of a cell's middle, so the 3 x 3 search finds both.
static float4 grains(float2 q, uint s) {
    int2 base = int2(floor(q));
    float2 near = 0.0, next = 0.0;
    float dn = 1e9, dx = 1e9;
    int2 cell = base;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            int2 c = base + int2(i, j);
            float2 at = float2(c) + 0.5 + 0.7 * (hash(c, s) - 0.5);
            float d = distance_squared(q, at);
            if (d < dn) { dx = dn; next = near; dn = d; near = at; cell = c; }
            else if (d < dx) { dx = d; next = at; }
        }
    }
    float edge = dot(q - 0.5 * (near + next), normalize(near - next));
    return float4(sqrt(dn), edge, float2(cell));
}

// Sandstone, in linear light at p: beds lying level across the glass, each a set of fine laminae, cross-bedded: they
// dip one way or the other within their bed. Each bed is graded, bright under its top and fading down it, and the
// beds thicken and redden downward, so a core turned half round shows it.
// A slow light passes down the beds.
static float3 sandstone(float2 p, float px, device const float2 *g, float t) {
    const float tau = 6.2831853;
    float3 warp = noised(0.8 * p + float2(2.3, 7.1), g);
    float3 fine = noised(float2(3.1, 9.0) * p + 4.7, g + 64);
    float y = p.y + 0.09 * warp.x + 0.012 * fine.x + 1.15;
    float b = 8.2 * y - 1.25 * y * y, db = 8.2 - 2.5 * y;
    float k = floor(b), f = b - k;
    float2 r = hash(int2(int(k), 3), salt(g));
    // The laminae of this bed: level, or dipping either way, set by set.
    float count = 4.0 + floor(4.0 * r.x), dip = r.y < 0.25 ? 0.0 : (r.y < 0.62 ? 1.0 : -1.0) * (5.0 + 8.0 * r.x);
    float lam = f * count + dip * (p.x + 0.25 * warp.x) * db * 0.12;
    float gl = length(float2(dip * db * 0.12, count * db));
    float n = floor(lam + 0.5), dl = abs(lam - n) / gl;
    // The bed's own top and bottom cut its laminae off.
    float dbed = min(f, 1.0 - f) / db;
    float v = saturate(0.5 * p.y + 0.5);
    float3 ink = mix(mix(float3(1.0, 0.90, 0.64), float3(1.0, 0.60, 0.27), smoothstep(0.0, 0.55, v)),
                     float3(0.90, 0.27, 0.20), smoothstep(0.5, 1.0, v));
    float wave = 0.5 + 0.5 * cos(tau * (k / 9.0 - t / 10.0)), lift = 0.55 + 0.45 * wave * wave;
    float room = 1.0 / gl, hw = min(0.0016, 0.22 * room);
    float line = saturate((hw - dl) / px + 0.5) * smoothstep(0.0, 0.012, dbed);
    float parting = saturate((0.0034 - dbed) / px + 0.5);
    float graded = 1.0 - f;
    float3 c = ink * (0.75 * line + 0.07 * exp(-dl * dl / 3.0e-5)) * lift * (0.35 + 0.85 * graded);
    c += mix(ink, float3(1.0, 0.96, 0.86), 0.5) * (parting + 0.14 * exp(-dbed * dbed / 8.0e-5)) * lift;
    // The rock between: a grain of sand in every bed, bed by bed a little lighter or darker.
    float2 bed = hash(int2(int(k), 11), salt(g));
    c += mix(float3(0.50, 0.33, 0.20), float3(0.42, 0.13, 0.10), v) * (0.05 + 0.17 * bed.x * bed.x) * (0.8 + 0.5 * fine.x) * (0.3 + 1.6 * graded * graded);
    return c;
}

// Agate, in linear light at p: the bands a cavity lays down wall inward, the contours of two octaves of noise on a
// slope steeper than the noise, so they run one way across the glass and never close into an eye, which a stir
// would look like, in rhythm: a packet of fine pale lines, then a quiet band of colour, each band its own. Light crosses the bands.
static float3 bands(float2 p, float px, device const float2 *g, float t) {
    const float step = 0.022, tau = 6.2831853;
    float3 a = noised(1.05 * p + float2(5.2, 1.4), g), b = noised(2.9 * p + float2(0.6, 3.3), g + 64);
    const float2 lie = float2(0.55, 0.95);
    float v = dot(p, lie) + 0.5 * a.x + 0.15 * b.x;
    float2 grad = lie + 0.5 * 1.05 * a.yz + 0.15 * 2.9 * b.yz;
    float s = v / step, n = floor(s + 0.5), gl = max(length(grad), 1e-4);
    float d = abs(s - n) * step / gl, room = step / gl;
    // Six lines to a packet: the first heavy, three fine, two left out for the quiet band.
    float slot = n - 6.0 * floor(n / 6.0), pack = floor(n / 6.0);
    float2 r = hash(int2(int(pack), 5), salt(g));
    float weight = slot < 0.5 ? 1.0 : slot < 3.5 ? 0.5 : 0.0;
    float hw = min(slot < 0.5 ? 0.0026 : 0.0013, 0.2 * room);
    const float3 dyes[4] = { float3(1.0, 0.62, 0.86), float3(0.72, 0.45, 1.0), float3(1.0, 0.80, 0.70), float3(0.55, 0.34, 0.75) };
    float3 dye = dyes[int(4.0 * r.x)], ink = slot < 0.5 ? mix(dye, float3(1.0, 0.95, 0.9), 0.6) : dye;
    float wave = 0.5 + 0.5 * cos(tau * (n / 18.0 - t / 10.0)), lift = 0.5 + 0.5 * wave * wave;
    float line = saturate((hw - d) / px + 0.5);
    float3 c = ink * weight * (line * 0.85 + 0.09 * exp(-d * d / 4.0e-5)) * lift;
    // The quiet band's colour, and the stone's body under it all.
    float quiet = smoothstep(3.3, 3.9, s - 6.0 * pack + 0.5) * smoothstep(5.6, 5.0, s - 6.0 * pack + 0.5);
    c += dye * float3(0.30, 0.165, 0.32) * (0.07 + 0.42 * quiet * (0.3 + 0.7 * r.y));
    return c;
}

// A thin section of slate between crossed polarisers, in linear light at p: grains, each ruled with twin lamellae
// its own way. The polarisers turn a quarter turn a period: each grain's two sets of lamellae brighten and dim in
// turn, once.
static float3 section(float2 p, float px, device const float2 *g, float t) {
    const float pitch = 0.2, tau = 6.2831853;
    uint s = salt(g);
    float3 warp = noised(2.0 * p + float2(1.7, 6.4), g);
    float2 q = (p + 0.035 * warp.yz) / pitch;
    float4 grain = grains(q, s);
    int2 cell = int2(grain.zw);
    float2 r = hash(cell, s ^ 0x51u), r2 = hash(cell, s ^ 0xA7u);
    float angle = 3.14159265 * r.x, spacing = 0.011 + 0.008 * r.y;
    float along = dot(p, float2(cos(angle), sin(angle))) / spacing;
    float n = floor(along + 0.5), d = abs(along - n) * spacing;
    bool odd = n - 2.0 * floor(0.5 * n) > 0.5;
    // Extinction: a twin dims four times a turn of the stage, its neighbour a little later.
    float phase = 2.0 * (angle + (odd ? 0.6 : 0.0)) - 0.5 * tau * t / 20.0;
    float lit = sin(phase) * sin(phase);
    const float3 tints[4] = { float3(0.55, 0.76, 1.0), float3(0.80, 0.86, 0.95), float3(0.40, 0.58, 1.0), float3(1.0, 0.88, 0.66) };
    float3 tint = tints[int(4.0 * r2.x)];
    float edge = grain.y * pitch;
    float hw = odd ? 0.0022 : 0.0012;
    float line = saturate((hw - d) / px + 0.5) * smoothstep(0.0005, 0.004, edge);
    float3 c = tint * line * (0.25 + 0.75 * lit) * 0.9;
    c += tint * float3(0.12, 0.185, 0.36) * (0.04 + 0.13 * lit) * smoothstep(0.0, 0.004, edge);
    return c;
}

// Basalt's columns end on, in linear light at p: the joints between them glow, and each column keeps the rings it
// cooled in, fainter toward its heart. A beat of heat runs through the joints.
static float3 basalt(float2 p, float px, device const float2 *g, float t) {
    const float pitch = 0.17, tau = 6.2831853;
    uint s = salt(g);
    float3 warp = noised(1.6 * p + float2(3.9, 0.8), g);
    float4 col = grains((p + 0.03 * warp.yz) / pitch, s);
    float edge = col.y * pitch;
    float2 r = hash(int2(col.zw), s ^ 0x33u);
    float heat = 0.5 + 0.5 * cos(tau * (1.4 * warp.x + r.x * 0.15 - t / 5.0)), beat = 0.45 + 0.55 * heat * heat * heat;
    const float3 ember = float3(1.0, 0.46, 0.26), core = float3(1.0, 0.86, 0.6);
    float joint = saturate((0.0022 - edge) / px + 0.5);
    float3 c = mix(ember, core, 0.5 * beat) * joint * beat + ember * 0.30 * exp(-edge * edge / 1.2e-4) * beat;
    // Cooling rings: the joint's outline again and again inward, every 0.012.
    float ring = edge / 0.012, n = floor(ring + 0.5), d = abs(ring - n) * 0.012;
    float fade = exp(-n / 2.6) * step(0.5, n);
    c += mix(ember, float3(0.9, 0.3, 0.3), 0.5) * saturate((0.0011 - d) / px + 0.5) * fade * (0.5 + 0.4 * r.y);
    c += float3(0.23, 0.075, 0.07) * (0.10 + 0.14 * r.y) * (0.8 + 0.4 * warp.x);
    return c;
}

[[ stitchable ]] half4 strata(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(sandstone(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 agate(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(bands(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 lamellae(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(section(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 columns(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(basalt(p, px, (device const float2 *)data, t))), 1.0h);
}
