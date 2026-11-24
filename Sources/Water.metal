// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Light on the slope's water, a tier each: sand ripples under caustics, the dusk surface's glitter, rain rings, and
// the caustic web in ember light. Each reads Picture.gradients, two tables, and repeats every 20 s.

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

// Sand ripples on a shallow floor, in linear light at p: crests lying level across the glass, each a pale line with
// its lit face falling away below it to a fine line at its foot. They come in sets of five that open out and
// brighten downward, set after set, so a core turned half round shows it; the whole floor warms toward the bottom.
// A net of caustic light drifts over it: two families of lines, the zero contours of two mixes of two fields, the
// mix turning once a period. The pixel on a crest takes its share of the lit face below it.
static float3 sand(float2 p, float px, device const float2 *g, float t) {
    const float tau = 6.2831853, open = 0.5;
    float3 warp = noised(float2(1.1, 2.3) * p + float2(4.3, 1.9), g);
    float3 la = noised(1.5 * p + float2(0.7, 5.3), g + 64), lb = noised(1.5 * p + float2(6.2, 2.6), g);
    float y = p.y + 1.15, v = saturate(0.5 * p.y + 0.5);
    float sets = (38.0 * y - 3.7 * y * y + 1.7 * warp.x) / 5.0, k = floor(sets), fs = sets - k;
    float b = 5.0 * (k + fs + open * fs * (1.0 - fs));
    float2 grad = float2(1.7 * 1.1 * warp.y, 38.0 - 7.4 * y + 1.7 * 2.3 * warp.z) * (1.0 + open * (1.0 - 2.0 * fs));
    float gl = max(length(grad), 1.0), room = 1.0 / gl;
    float f = b - floor(b), crest = min(f, 1.0 - f) / gl, foot = abs(f - 0.36) / gl;
    float n = floor(b + 0.5), place = (n - 5.0 * floor(n / 5.0)) / 4.0, rise = 0.6 + 0.4 * place;
    float turn = tau * t / 20.0, co = cos(turn), si = sin(turn);
    float c1 = la.x * co + lb.x * si, c2 = lb.x * co - la.x * si;
    float light = max(exp(-c1 * c1 / 0.0035), exp(-c2 * c2 / 0.0035));
    float lift = (0.48 + 0.52 * light) * (0.7 + 0.3 * v);
    const float3 cool = float3(0.42, 0.90, 0.84), warm = float3(1.0, 0.80, 0.50), grain = float3(0.50, 0.36, 0.27);
    float3 ink = mix(cool, warm, smoothstep(0.1, 0.9, v));
    float line = saturate((min(0.0011 + 0.0010 * place, 0.2 * room) - crest) / px + 0.5) * rise;
    float fine = saturate((min(0.0009, 0.07 * room) - foot) / px + 0.5);
    float under = saturate((f < 0.5 ? crest : -crest) / px + 0.5), face = saturate(1.0 - (f < 0.5 ? f : 0.0) / 0.36);
    float3 c = ink * (line * 0.95 + fine * 0.25) * lift;
    c += mix(ink, 1.5 * grain, 0.75) * under * face * face * (0.3 + 0.7 * fs) * (0.10 + 0.22 * light) * (0.6 + 0.4 * v);
    c += mix(float3(0.018, 0.125, 0.165), float3(0.075, 0.30, 0.31), light) * 0.11;
    return c;
}

// The dusk surface, in linear light at p: level glints scattered in rows that crowd toward the top, long and gold
// on the glitter path, short and rose out to the rim, each row's own faint hairline under them, over water streaked
// with the sky's last colour. Each glint twinkles a whole number of times a period. A row's cells are sized from the
// row, not from p, so a glint's ends stay square to it.
static float3 dusk(float2 p, float px, device const float2 *g, float t) {
    const float tau = 6.2831853;
    uint s = salt(g);
    float3 swell = noised(float2(0.9, 2.1) * p + float2(6.1, 2.7), g);
    float3 streak = noised(float2(1.3, 3.9) * p + float2(1.4, 5.5), g + 64);
    float y = p.y + 1.15 + 0.035 * swell.x, v = saturate(0.5 * p.y + 0.5);
    float b = 52.1 * y - 7.0 * y * y, db = 52.1 - 14.0 * y;
    float row = floor(b + 0.5), dy = (b - row) / db, room = 1.0 / db;
    float2 rr = hash(int2(int(row), 7), s);
    float level = saturate((52.1 - sqrt(52.1 * 52.1 - 28.0 * row)) / 28.0 - 0.075);
    float w = (0.028 + 0.04 * level) * (0.8 + 0.4 * rr.y);
    float x = p.x + 41.0 * rr.x, cell = floor(x / w);
    float centre = 0.14 + 0.12 * sin(2.4 * p.y + float(s & 7u)) + 0.3 * swell.x;
    float wide = 0.15 + 0.17 * v;
    float path = exp(-(p.x - centre) * (p.x - centre) / (wide * wide));
    float glint = 0.0, halo = 0.0;
    for (int i = -1; i <= 1; i++) {
        int2 id = int2(int(cell) + i, int(row));
        float2 h = hash(id, s ^ 0x1Du), h2 = hash(id, s ^ 0xB3u);
        float cx = (cell + float(i) + 0.5 + 0.4 * (h.x - 0.5)) * w;
        float reach = w * (0.10 + (0.17 + 0.15 * path) * h.y);
        float hw = min(0.0013 + 0.0011 * path * h.y, 0.2 * room);
        float off = abs(x - cx) / reach, up = dy - 0.56 * (h2.y - 0.5) * room;
        float d = length(float2(max(off - 1.0, 0.0) * reach, up)), lens = saturate(1.0 - off * off);
        float twinkle = 0.5 + 0.5 * cos(tau * (h2.x + (1.0 + floor(3.0 * h2.y)) * t / 20.0));
        float bright = (0.35 + 0.65 * twinkle * twinkle) * (0.55 + 0.45 * h.y);
        glint = max(glint, saturate((hw * lens - abs(up)) / px + 0.5) * smoothstep(0.0, 0.2, lens) * bright);
        halo = max(halo, exp(-d * d / 2.5e-5) * bright);
    }
    const float3 rose = float3(1.0, 0.62, 0.86), gold = float3(1.0, 0.86, 0.62);
    float3 ink = mix(rose, gold, smoothstep(0.1, 0.7, path));
    float strength = 0.72 + 0.7 * path;
    float3 c = ink * (glint + halo * 0.12 * path) * strength;
    float lull = smoothstep(-0.05, 0.3, streak.x + 0.5 * swell.x);
    c += rose * saturate((min(0.0011, 0.2 * room) - abs(dy)) / px + 0.5) * (0.16 + 0.3 * lull);
    c += float3(0.105, 0.03, 0.155) * (0.22 + 0.3 * streak.x) + float3(0.30, 0.165, 0.32) * 0.07 * path;
    return c;
}

// Rain rings, in linear light at p: a drop to a cell, each with fine rings around it out to its reach, at most a
// cell's width so the 3 x 3 search finds every drop that reaches p. The rings stand still; a wave of light runs out
// along each drop's twice a period. The grid's corner is on the glass's centre, so no drop is.
static float3 rain(float2 p, float px, device const float2 *g, float t) {
    const float pitch = 0.36, gap = 0.021, tau = 6.2831853;
    uint s = salt(g);
    float3 depth = noised(1.3 * p + float2(2.9, 4.4), g);
    int2 base = int2(floor(p / pitch));
    const float3 blue = float3(0.55, 0.76, 1.0), pale = float3(0.86, 0.93, 1.0);
    float3 c = 0.0;
    float cover = 0.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            int2 id = base + int2(i, j);
            float2 r = hash(id, s), r2 = fract(37.0 * r + 11.0 * r.yx);
            float2 at = (float2(id) + 0.5 + 0.7 * (r - 0.5)) * pitch;
            float reach = pitch * (0.72 + 0.28 * r2.x);
            float d = distance(p, at);
            if (d >= reach) continue;
            float ring = d / gap, n = floor(ring + 0.5), dl = abs(ring - n) * gap;
            float fade = smoothstep(0.0, 0.3, 1.0 - d / reach) * step(0.5, n);
            float wave = 0.5 + 0.5 * cos(tau * (1.5 * d / reach - t / 10.0 - r2.y));
            float bright = fade * (0.22 + 0.78 * wave * wave);
            c += mix(blue, pale, r.x * wave) * saturate((0.0013 - dl) / px + 0.5) * bright * 0.8;
            cover += fade;
        }
    }
    c += float3(0.02, 0.04, 0.15) * (0.32 + 0.3 * depth.x) + float3(0.12, 0.185, 0.36) * 0.022 * cover;
    return c;
}

// One family of the web's strands, the contours of f `step` apart, f shifted by `shift`: (distance from the nearest,
// the room between two).
static float2 strand(float3 f, float step, float shift) {
    float v = (f.x + shift) / step, gl = max(length(f.yz), 1e-4);
    return float2(abs(v - floor(v + 0.5)) * step / gl, step / gl);
}

// The caustic web, in linear light at p: light the swell gathers into curved strands that cross and part, the
// contours of two fields laid over each other, heavy ones and fine, brightest where two meet. The strands breathe a
// little as the swell passes, and a beat of brightness crosses them.
static float3 web(float2 p, float px, device const float2 *g, float t) {
    const float tau = 6.2831853;
    float3 swell = noised(0.9 * p + float2(2.2, 5.1), g + 64);
    float3 a = noised(3.1 * p + float2(3.9, 0.8), g), b = noised(3.1 * p + float2(7.3, 4.6), g + 64);
    float3 fa = noised(5.9 * p + float2(1.1, 6.6), g + 64), fb = noised(5.9 * p + float2(5.2, 0.4), g);
    a.yz *= 3.1; b.yz *= 3.1; fa.yz *= 5.9; fb.yz *= 5.9;
    float breath = 0.035 * sin(tau * t / 20.0), other = 0.035 * cos(tau * t / 20.0);
    float2 ha = strand(a, 0.42, breath), hb = strand(b, 0.42, other);
    float2 la = strand(fa, 0.46, 0.4 * other), lb = strand(fb, 0.46, 0.4 * breath);
    float wave = 0.5 + 0.5 * cos(tau * (0.9 * p.y + 0.5 * p.x + 1.2 * swell.x - t / 10.0)), beat = 0.45 + 0.55 * wave * wave;
    const float3 ember = float3(1.0, 0.46, 0.26), core = float3(1.0, 0.84, 0.6), deep = float3(0.9, 0.3, 0.3);
    float wa = saturate((min(0.0026, 0.2 * ha.y) - ha.x) / px + 0.5), wb = saturate((min(0.0026, 0.2 * hb.y) - hb.x) / px + 0.5);
    float meet = exp(-ha.x * hb.x / 4.0e-4);
    float3 c = mix(ember, core, 0.25 + 0.75 * meet) * max(wa, wb) * (0.45 + 0.55 * meet) * beat;
    c += ember * (exp(-ha.x * ha.x / 2.0e-4) + exp(-hb.x * hb.x / 2.0e-4)) * (0.07 + 0.25 * meet) * beat;
    float fine = max(saturate((min(0.0011, 0.2 * la.y) - la.x) / px + 0.5), saturate((min(0.0011, 0.2 * lb.y) - lb.x) / px + 0.5));
    c += mix(deep, ember, beat) * fine * (0.22 + 0.3 * beat);
    c += float3(0.10, 0.016, 0.024) * (0.22 + 0.2 * swell.x) + float3(0.23, 0.075, 0.07) * 0.05 * meet;
    return c;
}

[[ stitchable ]] half4 ripples(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(sand(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 glitter(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(dusk(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 rings(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(rain(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 caustics(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(web(p, px, (device const float2 *)data, t))), 1.0h);
}
