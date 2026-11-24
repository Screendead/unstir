// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The dusk sky over the slope, a tier each: star trails over the dunes, a star chart, an astrolabe's plate and an
// aurora. Each reads Picture.gradients, two tables, and repeats every 20 s.

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

// How far q is from the line from a to b, less `trim` cut off each end.
static float segment(float2 q, float2 a, float2 b, float trim) {
    float2 ab = b - a;
    float len = max(length(ab), 1e-4), along = clamp(dot(q - a, ab) / len, min(trim, 0.5 * len), max(len - trim, 0.5 * len));
    return distance(q, a + ab * (along / len));
}

// Star trails, in linear light at p: an hour's exposure about a pole up and to the right, each star an arc of its own
// length, weight and tint, cooler overhead and gold toward the dunes, whose crests catch the dusk still behind them. The glow, the dunes and the pole's side say
// which way is up in any core. A slow light runs along the trails.
static float3 startrails(float2 p, float px, device const float2 *g, float t) {
    const float tau = 6.2831853, ring = 0.024;
    const float2 pole = float2(0.35, -0.55);
    uint s = salt(g);
    float3 dune = noised(float2(1.4 * p.x + 3.3, 0.5), g);
    float horizon = 0.60 + 0.05 * dune.x, above = horizon - p.y;
    float3 c = mix(float3(0.018, 0.125, 0.165) * 0.16, float3(0.075, 0.30, 0.31) * 0.3, smoothstep(1.6, 0.05, above));
    c += float3(1.0, 0.56, 0.30) * 0.11 * exp(-max(above, 0.0) / 0.22) + float3(1.0, 0.82, 0.55) * 0.10 * exp(-max(above, 0.0) / 0.07);
    float2 q = p - pole;
    float r = length(q), turn = atan2(q.y, q.x) / tau;
    float n = floor(r / ring);
    float2 h = hash(int2(int(n), 7), s), h2 = hash(int2(int(n), 19), s);
    float d = abs(r - (n + 0.5 + 0.5 * (h.x - 0.5)) * ring);
    float arcs = 2.0 + floor(4.0 * h.y);
    float along = (turn + h2.x) * arcs, m = floor(along), f = along - m;
    m -= arcs * floor(m / arcs);
    float2 a = hash(int2(int(n), int(m) + 64), s ^ 0x9Du), b = hash(int2(int(n), int(m) + 64), s ^ 0x3Bu);
    float len = 0.45 + 0.47 * a.x, e = (f - (1.0 - len) * a.y) / len, reach = len / arcs * tau * r;
    float mag = b.x * b.x;
    const float3 tints[4] = { float3(0.86, 0.9, 1.0), float3(1.0, 0.965, 0.87), float3(1.0, 0.82, 0.55), float3(0.55, 0.92, 0.86) };
    float3 ink = mix(mix(tints[int(4.0 * b.y)], float3(0.70, 0.9, 1.0), 0.75 * smoothstep(0.3, 1.6, above)),
                     float3(1.0, 0.78, 0.48), 0.9 * smoothstep(1.25, 0.0, above));
    float wave = 0.5 + 0.5 * cos(tau * (e - a.y - t / 10.0)), lift = 0.6 + 0.4 * wave * wave;
    float hw = min(0.0011 + 0.0012 * mag, 0.1 * ring);
    float ends = smoothstep(0.0, 0.012, min(e, 1.0 - e) * reach) * step(0.0, e) * step(e, 1.0);
    float sky = saturate(above / px + 0.5);
    c += ink * (saturate((hw - d) / px + 0.5) * (0.42 + 0.58 * mag) + 0.07 * mag * exp(-d * d / 3.0e-5)) * ends * lift * sky;
    float3 lie = noised(float2(1.1, 2.4) * p + float2(4.7, 1.9), g + 64);
    float w = (p.y + 0.06 * lie.x) / 0.036, gl = length(float2(0.066 * lie.y, 1.0 + 0.144 * lie.z)) / 0.036;
    float k = floor(w + 0.5), dl = abs(w - k) / gl, depth = max(-above, 0.0);
    float crest = saturate((min(0.0014, 0.2 / gl) - dl) / px + 0.5) * smoothstep(0.004, 0.02, depth);
    float glint = 0.5 + 0.5 * cos(tau * (k / 7.0 + 0.8 * p.x - t / 10.0));
    float3 ground = float3(0.50, 0.36, 0.27) * (0.05 + 0.10 * exp(-depth / 0.12)) * (0.9 + 0.5 * lie.x)
                  + float3(1.0, 0.82, 0.55) * crest * (0.34 + 0.4 * exp(-depth / 0.15)) * (0.65 + 0.35 * glint);
    c = mix(ground, c, sky);
    c += float3(1.0, 0.9, 0.7) * 0.8 * saturate((0.0022 - abs(above)) / px + 0.5);
    return c;
}

// A chart's star in cell c from its hash, in cells: it keeps a quarter of a cell from its cell's edge.
static float2 star(int2 c, float2 h) { return float2(c) + 0.25 + 0.5 * h; }

// A star chart, in linear light at p: a star to a cell, of a few magnitudes, some joined to the next along, down or
// aslant into figures (only even cells start a slanting line, so no two cross), over the chart's grid of declination
// circles and hour lines, every fourth heavier, about a pole far off the glass, with the Milky Way a faint band
// behind. A star's light stays in its own cell. Stars twinkle; light crosses the figures.
static float3 starchart(float2 p, float px, device const float2 *g, float t) {
    const float pitch = 0.115, tau = 6.2831853;
    uint s = salt(g);
    float3 cloud = noised(1.3 * p + float2(2.9, 6.1), g);
    float way = dot(p, float2(0.5, 0.866)) + 0.1 + 0.28 * cloud.x;
    float3 c = float3(0.105, 0.03, 0.155) * 0.4
             + float3(0.30, 0.165, 0.32) * (0.03 + 0.2 * exp(-way * way / 0.07) * (0.75 + 0.6 * cloud.y));
    float2 w = p - float2(-1.2, -2.4);
    float rr = length(w), dec = rr / 0.042, ra = atan2(w.y, w.x) * 264.0 / tau;
    float nd = floor(dec + 0.5), na = floor(ra + 0.5);
    float dd = abs(dec - nd) * 0.042, da = abs(ra - na) * tau / 264.0 * rr;
    bool bd = nd - 4.0 * floor(nd / 4.0) < 0.5, ba = na - 4.0 * floor(na / 4.0) < 0.5;
    c += float3(0.72, 0.45, 1.0) * (saturate(((bd ? 0.0015 : 0.001) - dd) / px + 0.5) * (bd ? 0.42 : 0.2)
                + saturate(((ba ? 0.0015 : 0.001) - da) / px + 0.5) * (ba ? 0.42 : 0.2));
    float2 q = p / pitch;
    int2 base = int2(floor(q));
    float2 h = hash(base, s), hl = hash(base + int2(-1, 0), s), hr = hash(base + int2(1, 0), s);
    float2 hu = hash(base + int2(0, -1), s), hd = hash(base + int2(0, 1), s);
    float2 at = star(base, h), l = star(base + int2(-1, 0), hl), r = star(base + int2(1, 0), hr);
    float2 u = star(base + int2(0, -1), hu), d = star(base + int2(0, 1), hd);
    const float across = 0.27, down = 0.24, slant = 0.3, trim = 0.12;
    float dline = 1e9;
    if (fract(h.x * 7.0) < across) dline = min(dline, segment(q, at, r, trim));
    if (fract(hl.x * 7.0) < across) dline = min(dline, segment(q, l, at, trim));
    if (fract(h.y * 7.0) < down) dline = min(dline, segment(q, at, d, trim));
    if (fract(hu.y * 7.0) < down) dline = min(dline, segment(q, u, at, trim));
    if (((base.x + base.y) & 1) == 0) {
        float2 hb = hash(base + int2(-1, -1), s), hf = hash(base + int2(-1, 1), s);
        if (fract(h.x * 13.0) < slant) dline = min(dline, segment(q, at, star(base + int2(1, 1), hash(base + int2(1, 1), s)), trim));
        if (fract(h.y * 13.0) < slant) dline = min(dline, segment(q, at, star(base + int2(1, -1), hash(base + int2(1, -1), s)), trim));
        if (fract(hb.x * 13.0) < slant) dline = min(dline, segment(q, star(base + int2(-1, -1), hb), at, trim));
        if (fract(hf.y * 13.0) < slant) dline = min(dline, segment(q, star(base + int2(-1, 1), hf), at, trim));
    } else {
        if (fract(hl.x * 13.0) < slant) dline = min(dline, segment(q, l, d, trim));
        if (fract(hu.x * 13.0) < slant) dline = min(dline, segment(q, u, r, trim));
        if (fract(hl.y * 13.0) < slant) dline = min(dline, segment(q, l, u, trim));
        if (fract(hd.y * 13.0) < slant) dline = min(dline, segment(q, d, r, trim));
    }
    const float3 rose = float3(1.0, 0.62, 0.86), cream = float3(1.0, 0.965, 0.87);
    float m = fract(h.x * 7.31 + h.y * 3.7), mag = m * m, phase = fract(h.y * 11.0), size = 0.0034 + 0.0056 * mag;
    float ds = distance(q, at) * pitch;
    float twinkle = 0.78 + 0.22 * sin(tau * (phase + t * (2.0 + floor(3.0 * mag + 3.0 * phase)) / 20.0));
    float3 hue = mix(float3(0.86, 0.9, 1.0), mix(cream, rose, phase), 0.7 * fract(phase * 5.3));
    float3 stars = hue * twinkle * (saturate((size - ds) / px + 0.5) * (0.75 + 0.45 * mag) + (0.1 + 0.3 * mag) * exp(-ds * ds / (4.0 * size * size)));
    dline *= pitch;
    float wave = 0.5 + 0.5 * cos(tau * (1.4 * dot(p, float2(0.8, 0.6)) - t / 10.0)), lift = 0.6 + 0.4 * wave * wave;
    c += mix(rose, cream, 0.45) * (saturate((0.0015 - dline) / px + 0.5) * 0.85 + 0.08 * exp(-dline * dline / 4.0e-5)) * lift;
    c += stars;
    return c;
}

// One family of an astrolabe plate's lines: v the coordinate, rate its change per tank unit, base the step between
// lines where they stand `fine` apart. Where they stand wider the step halves, the new lines fading in, so the lines
// keep `fine` to twice `fine` apart across the plate. Returns (the line's cover, 1 on a line of every fourth base step).
static float2 graduated(float v, float rate, float base, float fine, float lowest, float px) {
    float lod = max(log2(base / rate / fine), lowest), j = floor(lod), f = lod - j;
    float gap = 0.5 * base * exp2(-j), x = v / gap, n = floor(x + 0.5), room = gap / rate;
    float d = abs(x - n) * room;
    bool odd = n - 2.0 * floor(0.5 * n) > 0.5;
    float major = n * gap / (4.0 * base);
    bool bold = abs(major - floor(major + 0.5)) < 0.01;
    float line = saturate((min(bold ? 0.0019 : 0.0012, 0.2 * room) - d) / px + 0.5);
    return float2(line * (odd ? smoothstep(0.1, 0.9, f) : 1.0) * smoothstep(0.004, 0.011, room), bold ? 1.0 : 0.0);
}

// The cover of the ticks of a scale `count` to the turn at `turn` round a circle, a tank-unit radius r out.
static float ticks(float turn, float count, float r, float px) {
    float x = turn * count, d = abs(x - floor(x + 0.5)) / count * 6.2831853 * r;
    return saturate((0.001 - d) / px + 0.5);
}

// An astrolabe's plate, in linear light at p: the sky in stereographic projection about a pole low on the left, cut
// for the level's own latitude, its rete turned the level's own way. The
// almucantars close about the zenith and the azimuth arcs fan from it, the horizon heavy; the equator carries a scale
// of degrees, the tropics run plain, and the ecliptic's band crosses them, graduated. Light climbs the almucantars
// and a glint goes once round the ecliptic.
static float3 plate(float2 p, float px, device const float2 *g, float t) {
    const float tau = 6.2831853, k = 1.05;
    float2 own = hash(int2(3, 11), salt(g));
    float lat = 0.63 + 0.23 * own.x, sinLat = sin(lat), cosLat = cos(lat);
    const float2 pole = float2(-0.52, 0.74), up = float2(0.2873, -0.9578);
    float2 w = p - pole, u = float2(up.y * w.x - up.x * w.y, dot(w, up)) / -k;
    u.y = -u.y;
    float uu = dot(u, u);
    float3 x = float3(2.0 * u, 1.0 - uu) / (1.0 + uu);
    float conf = 2.0 / (k * (1.0 + uu));
    float sa = clamp(x.y * cosLat + x.z * sinLat, -0.9999, 0.9999), alt = asin(sa), ca = sqrt(1.0 - sa * sa);
    float az = atan2(x.x, x.z * cosLat - x.y * sinLat);
    float3 warp = noised(1.2 * p + float2(6.2, 2.5), g);
    float day = smoothstep(-0.02, 0.02, alt);
    const float3 silver = float3(0.8, 0.84, 0.9), blue = float3(0.55, 0.76, 1.0), deep = float3(0.30, 0.50, 1.0);
    float3 c = float3(0.02, 0.04, 0.15) * 0.4 + float3(0.12, 0.185, 0.36) * (0.012 + 0.045 * day) * (1.0 + 0.6 * warp.x);
    float wave = 0.5 + 0.5 * cos(tau * (alt / 0.6 - t / 10.0)), lift = 0.6 + 0.4 * wave * wave;
    float2 al = graduated(alt, conf, tau / 72.0, 0.024, -1.0, px), zl = graduated(az, conf / ca, tau / 64.0, 0.05, -3.0, px);
    float under = 0.6 + 0.4 * day;
    c += mix(blue, silver, al.y) * al.x * (0.34 + 0.5 * al.y) * lift * under;
    c += mix(deep, blue, 0.5 + 0.5 * zl.y) * zl.x * (0.24 + 0.22 * zl.y) * under;
    float dh = abs(alt) / conf;
    c += silver * (saturate((0.0024 - dh) / px + 0.5) + 0.1 * exp(-dh * dh / 6.0e-5));
    float rho = length(w), turn = atan2(w.y, w.x) / tau;
    float de = rho - k, dt = min(abs(rho - 1.5253 * k), abs(rho - 0.6556 * k));
    float scale = ticks(turn, 360.0, rho, px) * step(0.0, de) * step(de, 0.014)
                + ticks(turn, 72.0, rho, px) * step(0.0, de) * step(de, 0.024) + ticks(turn, 36.0, rho, px) * step(0.0, de) * step(de, 0.034);
    c += silver * (0.9 * saturate((0.0018 - abs(de)) / px + 0.5) + 0.6 * saturate((0.0014 - dt) / px + 0.5) + 0.6 * min(scale, 1.0));
    float2 we = p - (pole + 0.4567 * float2(cos(tau * own.y), sin(tau * own.y)));
    float re = length(we), te = atan2(we.y, we.x) / tau, band = 1.145 - re;
    float inside = step(0.0, band) * step(band, 0.06);
    float marks = ticks(te, 360.0, re, px) * step(band, 0.018) + ticks(te, 72.0, re, px) * step(band, 0.03) + ticks(te, 36.0, re, px) * step(band, 0.042) + ticks(te, 12.0, re, px);
    float run = fract(te - t / 20.0) - 0.5, glint = 1.0 + 1.6 * exp(-run * run / 0.004);
    const float3 cream = float3(1.0, 0.965, 0.87);
    c = mix(c, c * 0.25 + float3(0.12, 0.185, 0.36) * 0.1, inside);
    c += cream * glint * (0.85 * saturate((0.0018 - min(abs(band), abs(band - 0.06))) / px + 0.5) + 0.65 * min(marks, 1.0) * inside);
    return c;
}

// An aurora, in linear light at p: three curtains of fine rays hung one behind another, red as the high ones are,
// each ray its own height and weight, pale along the curtain's lower hem and fading upward, over small stars. The
// rays lean to a point far above the glass. A slow beat of light runs along the curtains.
static float3 curtains(float2 p, float px, device const float2 *g, float t) {
    const float tau = 6.2831853, gap = 0.0058;
    const float2 zenith = float2(0.3, -3.6);
    uint s = salt(g);
    float2 q = p - zenith;
    float r = length(q), a = atan2(q.x, q.y);
    float3 sway = noised(float2(1.4 * p.x, 0.6 * p.y) + float2(0.9, 4.4), g);
    float x = (a + 0.012 * sway.x) / gap, n = floor(x + 0.5), d = abs(x - n) * gap * r;
    float2 h = hash(int2(int(n), 7), s);
    const float3 ember = float3(1.0, 0.46, 0.26), core = float3(1.0, 0.93, 0.8), high = float3(0.9, 0.2, 0.25);
    float pulse = 0.5 + 0.5 * cos(tau * (a * 9.0 + 0.4 * sway.x - t / 10.0)), beat = 0.55 + 0.45 * pulse * pulse;
    float light = 0.0, hem = 0.0;
    for (int k = 0; k < 3; k++) {
        float3 fold = noised(float2(1.7 * p.x + 3.1 * float(k), 0.37 * float(k) + 1.3), g + 64);
        float2 hk = hash(int2(int(n), k), s ^ 0x4Du);
        float below = p.y - (-0.42 + 0.62 * float(k) + 0.3 * fold.x + 0.22 * hk.x * hk.x);
        float body = exp(min(below, 0.0) / (0.16 + 0.3 * hk.y)) * smoothstep(0.012, 0.0, below);
        light = max(light, body * (0.45 + 0.55 * hk.y));
        hem = max(hem, body * exp(min(below, 0.0) / 0.035));
    }
    float hw = min(0.0009 + 0.0011 * h.x, 0.2 * gap * r);
    float line = saturate((hw - d) / px + 0.5);
    float3 c = mix(mix(high, ember, saturate(2.0 * light)), core, hem) * line * (0.17 + 2.4 * light * light * beat * (0.35 + 0.65 * h.y));
    c += ember * 0.3 * light * light * beat * exp(-d * d / 4.0e-5) + core * 0.5 * hem * hem * line;
    c += float3(0.10, 0.016, 0.024) * 0.4 + mix(high, ember, 0.4) * (0.006 + 0.11 * light * light * beat);
    float2 cell = floor(p / 0.075), hs = hash(int2(cell), s ^ 0x77u);
    float ds = distance(p, (cell + 0.25 + 0.5 * hs) * 0.075), size = 0.0012 + 0.0026 * hs.x * hs.x * hs.x;
    float twinkle = 0.7 + 0.3 * sin(tau * (hs.y + t * (2.0 + floor(3.0 * hs.x)) / 20.0));
    c += mix(float3(0.86, 0.9, 1.0), core, hs.y) * twinkle * (0.25 + 0.75 * hs.x * hs.x) * (1.0 - 0.7 * light)
       * (saturate((size - ds) / px + 0.5) + 0.25 * exp(-ds * ds / (5.0 * size * size)));
    return c;
}

[[ stitchable ]] half4 trails(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(startrails(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 constellations(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(starchart(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 armillary(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(plate(p, px, (device const float2 *)data, t))), 1.0h);
}

[[ stitchable ]] half4 aurora(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(curtains(p, px, (device const float2 *)data, t))), 1.0h);
}
