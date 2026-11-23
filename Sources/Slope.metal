// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The slope's ground (docs/slope.md): one pass for everything outside the tank. Water by depth under a dusk sky and a
// swaying surface, two hazy far ridges, the shelf of rock in overhung ledges, each stretch its own rock, an
// out-of-focus near silhouette and sinking motes. Layers slide at their own rates as the camera moves, and that is
// all the depth there is. Nothing here stirs.
//
// g is SlopeLay.uniforms: the column depth at the screen's top, the zoom eased (0 the overview, 1 the dive), a
// ledge's pitch at that zoom, the ledge count, the foot's depth and kind (0 wall, 1 the drop-off, 2 a floor), whether
// air stands over the column, the ledge the water's colour counts from (under 0: still water, at g[8] ledges'
// depth) and the dive's pitch; each rock's ledge shape (thickness, undercut, nose, ripple); then every ledge's top,
// lip, drop to the next, rock, where the rock over it meets its top, and the water's depth in ledges there. The rock's profile is built from those ledges alone, so a pebble Swift seats on one
// (SlopeLay.seat) sits on the drawn rock at every zoom.

constant int slopeShapes = 16, slopeLedges = 36;

static float slopeHash(float2 p) {
    float3 q = fract(float3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

static float slopeNoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(slopeHash(i), slopeHash(i + float2(1, 0)), f.x),
               mix(slopeHash(i + float2(0, 1)), slopeHash(i + float2(1, 1)), f.x), f.y);
}

static float slopeBell(float x) { return exp(-x * x); }
static float slopeStep(float x) { return smoothstep(-0.7, 0.7, x); }

constant int slopeStride = 6;

// Ledge k's top, lip, drop and rock, k held inside the column.
static float4 slopeLedge(device const float *g, float k) {
    int i = slopeLedges + slopeStride * int(clamp(k, 0.0, g[3] - 1.0));
    return float4(g[i], g[i + 1], g[i + 2], g[i + 3]);
}

// Where the rock over ledge k meets its top, and the water's depth in ledges there.
static float2 slopeMore(device const float *g, float k) {
    int i = slopeLedges + slopeStride * int(clamp(k, 0.0, g[3] - 1.0));
    return float2(g[i + 4], g[i + 5]);
}

static float4 slopeShape(float rock, device const float *g) {
    int t = slopeShapes + 4 * int(rock);
    return float4(g[t], g[t + 1], g[t + 2], g[t + 3]);
}

// How much of its dive's size a ledge's shape has (SlopeLay.scale): at the overview the lips are 1.3 pt apart, and
// their thickness, undercut and nose shrink with them, so nine merge into one terrace's top.
static float slopeScale(float4 ledge, float4 shape, device const float *g) {
    return min(0.75 * min(ledge.z, g[2]) / shape.x, 1.0);
}

// The rock's edge in x, f under ledge k's top: out to the lip round its nose, back under it by the undercut and away
// to where the next ledge begins. Where that is a long way back, under a terrace's last ledge, the underside thins
// towards the nose as an eave does. Under the column's last ledge the foot decides: the wall goes on, or at the
// drop-off the rock curves back off the screen within the ledge's own drop.
static float slopeEdge(device const float *g, float k, float f) {
    float4 ledge = slopeLedge(g, k), sp = slopeShape(ledge.w, g);
    float sc = slopeScale(ledge, sp, g), thick = sp.x * sc, tip = ledge.y, back = slopeMore(g, k).x;
    float e = tip - sp.y * sc * smoothstep(0.0, 1.0, pow(saturate(f / thick), sp.z));
    float s = saturate((f - thick) / max(ledge.z - thick, 0.01));
    float b = sin(3.14159265 * s);
    bool last = k > g[3] - 1.5;
    float next = !last ? slopeMore(g, k + 1.0).x : g[5] == 1.0 ? -60.0 : tip - 0.85 * sp.y * sc;
    float ease = mix(s * s * (3.0 - 2.0 * s), pow(s, 0.6), smoothstep(50.0, 140.0, tip - next));
    e = mix(e, next, ease) + (4.0 + (sp.w + 1.0) * sin(f * 0.19 + k)) * b * b * sc;
    float n = max(1.0 - f / (10.0 * sc), 0.0);
    return e - (tip - back) * n * n * n;
}

// The water's colour by depth in ledges from plughole's first: sunlit green shallows, then each tier's own dark.
static float3 slopeWater(float m) {
    float3 c = mix(float3(0.075, 0.30, 0.31), float3(0.018, 0.125, 0.165), smoothstep(-2.8, 11.0, m));
    c = mix(c, float3(0.105, 0.03, 0.155), smoothstep(24.0, 31.0, m));
    c = mix(c, float3(0.02, 0.04, 0.15), smoothstep(51.0, 58.0, m));
    return mix(c, float3(0.10, 0.016, 0.024), smoothstep(78.0, 85.0, m));
}

static float3 slopeRock(float r) {
    float3 c = mix(float3(0.50, 0.36, 0.27), float3(0.30, 0.165, 0.32), saturate(r));
    c = mix(c, float3(0.12, 0.185, 0.36), saturate(r - 1.0));
    c = mix(c, float3(0.23, 0.075, 0.07), saturate(r - 2.0));
    return mix(c, float3(0.34, 0.35, 0.41), saturate(r - 3.0));
}

static float3 slopeLit(float r) {
    float3 c = mix(float3(1.0, 0.82, 0.55), float3(1.0, 0.62, 0.86), saturate(r));
    c = mix(c, float3(0.55, 0.76, 1.0), saturate(r - 1.0));
    c = mix(c, float3(1.0, 0.46, 0.26), saturate(r - 2.0));
    return mix(c, float3(0.8, 0.84, 0.9), saturate(r - 3.0));
}

// Rock by how lit it is: its shadows take the water's colour, its lit faces its own.
static float3 slopeSand(float3 rock, float3 lit, float3 water, float tone, float glint) {
    return mix(mix(rock * 0.5, water * 2.4, 0.42), rock * 1.36 + lit * 0.05, smoothstep(0.4, 1.3, tone)) + lit * glint;
}

// view: pixels to a point, the ground's clock in seconds, how much of the near silhouette shows, and of the motes.
// play: how far a level has taken the screen (the shelf draws aside and one terrace rises under the tank), a solved
// tank's glint, Prism's clear water, and the ground's light (1 its own; consent draws it at 0.35).
// lone: the lone terrace's light, and its rock.
// paper: how far the ground is Escapement's page, an engraving in ink on bone.
static float3 slopeGround(float2 pos, float2 size, float4 view, float4 play, float4 lone, float paper, device const float *g) {
    float top = g[0], open = g[1], count = g[3], foot = g[4];
    float tm = view.y;
    float x = pos.x + 280.0 * play.x;
    // At the overview no ledge's top is straight: the whole shelf bows a few points (SlopeLay.bow).
    float plain = top + pos.y;
    float depth = plain - (3.4 * sin(x * 0.021 + plain * 0.033) + 0.03 * (x - 60.0)) * (1.0 - open);
    // Grain and banding are the dive's: they would shimmer as the depth opens.
    float fine = smoothstep(0.7, 1.0, open);

    // Which ledge's row this is: the last whose top is at or over this depth.
    float lo = -1.0, hi = count - 1.0;
    for (int i = 0; i < 8; i++) {
        if (lo >= hi) break;
        float mid = ceil((lo + hi) * 0.5);
        if (g[slopeLedges + slopeStride * int(mid)] <= depth) lo = mid; else hi = mid - 1.0;
    }
    float k = lo;
    float4 ledge = slopeLedge(g, k);
    float f = depth - ledge.x;
    float4 first = slopeLedge(g, 0.0), end = slopeLedge(g, count - 1.0);
    // Past the foot, in the last ledge's drops.
    float past = (depth - foot) / end.z;

    float2 more = slopeMore(g, k);
    float m = g[7] < 0.0 ? g[8] : k < 0.0 ? more.y - 0.8 * (first.x - depth) / first.x
        : more.y + (k > count - 1.5 ? 1.0 : slopeMore(g, k + 1.0).y - more.y) * f / ledge.z;
    float3 wc = slopeWater(m);
    if (g[5] == 1.0) wc = mix(wc, float3(0.008, 0.006, 0.014), smoothstep(-0.5, 2.0, past));
    float surface = -top;
    float d = g[6] > 0.0 ? pos.y - (surface + 3.2 * sin(pos.x * 0.024 + tm * 1.1) + 1.8 * sin(pos.x * 0.063 - tm * 1.6 + 1.3)) : 1000.0;
    float under = step(0.0, d);
    float sun = exp(-max(m + 2.8, 0.0) / 26.0) * 0.75 + 0.25;
    float3 col;
    if (d < 0.0) {
        // The air: dusk, warm along the water.
        col = mix(float3(0.03, 0.028, 0.05), float3(0.60, 0.37, 0.21), exp(d / 62.0) * 0.8);
        col += float3(0.5, 0.3, 0.12) * exp(-length((pos - float2(60.0, surface)) * float2(0.006, 0.02))) * 0.22;
    } else {
        col = wc;
        float sx = pos.x + d * 0.32 + tm * 4.0;
        float rays = slopeNoise(float2(sx * 0.016, 1.7)) * slopeNoise(float2(sx * 0.041 + 9.0, tm * 0.12));
        col += float3(0.85, 0.78, 0.55) * smoothstep(0.12, 0.55, rays) * exp(-max(m + 2.8, 0.0) / 8.0) * 0.10;
        col += float3(0.55, 0.50, 0.30) * exp(-d / 46.0) * 0.16;
        col += float3(0.45, 0.30, 0.10) * exp(-length((pos - float2(40.0, surface)) * float2(0.004, 0.0046))) * 0.16;
        col += float3(1.0, 0.9, 0.72) * exp(-d / 1.3) * 0.5;
    }

    // Two far ridges, each moving slower than the shelf, and both ending at the drop-off. Haze takes them towards the
    // water's own colour: the further one is the fainter, and neither is ever lighter than the water.
    float taper = g[5] == 1.0 ? smoothstep(-1.2, 0.6, past) : 0.0;
    for (int j = 0; j < 2; j++) {
        float fj = float(j);
        float yy = pos.y * mix(1.5, 1.0, open) + top * open * (0.3 + 0.28 * fj) + 300.0 * fj;
        float e = size.x - 122.0 + 72.0 * fj + (38.0 - 12.0 * fj) * sin(yy * (0.0057 + 0.0031 * fj) + 1.7 * fj + 0.4)
            + 13.0 * sin(yy * 0.0173 + 4.0 * fj) + 4.5 * sin(yy * 0.061 + fj) + 260.0 * taper * taper;
        float soft = 2.6 - 1.4 * fj;
        float3 rc = wc * (0.80 - 0.22 * fj);
        // Light from above catches the ridge's shoulder where there is light to catch.
        rc += wc * 0.5 * sun * sun * exp(-max(pos.x - e, 0.0) / (10.0 + 8.0 * fj)) * (0.5 + 0.5 * sin(yy * 0.061 + fj + 1.6)) * (0.6 - 0.25 * fj);
        col = mix(col, rc, smoothstep(-soft, soft, pos.x - e) * under * smoothstep(0.0, 40.0, d));
    }

    // The shelf.
    float e0, lean, sc = 1.0;
    float4 sp = slopeShape(ledge.w, g);
    if (k < 0.0) {
        // Over the first ledge the wall wanders up to the bank.
        e0 = more.x + 5.0 * sin(depth * 0.045 + 1.0);
        lean = 0.0;
    } else {
        sc = slopeScale(ledge, sp, g);
        e0 = slopeEdge(g, k, f);
        lean = (slopeEdge(g, k, f + 0.5) - e0) / 0.5;
    }
    float din = e0 - x, across = din / sqrt(1.0 + lean * lean);
    float mask = slopeStep(across);
    float below = 1.0;
    if (g[6] > 0.0) {
        // The bank's shoulder under the water line, and its dry top over it: drawn by the screen, as the stone on it is.
        mask = max(mask, slopeStep(84.0 * slopeBell((pos.y - surface) / 66.0) - x));
        below = slopeStep(pos.y - (surface - (26.0 * slopeBell(x / 80.0) - 6.0)));
    }
    float thick = sp.x * sc;
    // 1 on the wall under a lip, where its shadow falls.
    float shade = exp(-max(din, 0.0) / (14.0 * sc + 1.0)) * smoothstep(thick * 0.45, thick, f) * (1.0 - smoothstep(thick, thick + 36.0 * sc + 2.0, f))
        * step(0.0, k);
    if (mask * below > 0.001 && paper < 1.0) {
        float tip = ledge.y, back = more.x;
        float tone = f < thick * 1.15 ? mix(1.32, 0.56, smoothstep(0.0, thick * 1.15, f))
            : mix(0.56, 0.82, smoothstep(thick, ledge.z - 10.0 * sc, f));
        float nose = smoothstep(back - 2.0, back + 26.0 * sc + 1.0, x) * (1.0 - smoothstep(thick * 0.9, thick * 1.6, f)) * step(0.0, k);
        tone = mix(0.76, tone, nose);
        tone *= 1.0 - 0.38 * shade;
        // Soft bands that bow with the slope and a little grain.
        float u = depth / g[9];
        tone *= 1.0 + fine * (0.05 * sin((u + x * x * 0.00002) * 9.4) + 0.035 * sin((u - x * 0.004) * 23.0));
        tone *= 1.0 + fine * 0.08 * (slopeNoise(float2(x, depth) * 0.11) - 0.5);
        // The ledge's top catches the light: a bright line along it and a glow under that, dappled by the water.
        float crown = 10.0 * sc * (1.0 - pow(saturate((tip - x) / max(tip - back, 1.0)), 1.0 / 3.0));
        float sunk = max(f - crown, 0.0);
        float glint = (exp(-sunk / max(2.6 * sc, 0.9)) * 0.62 + exp(-sunk / max(13.0 * sc, 2.0)) * 0.2)
            * smoothstep(back - 1.0, back + 9.0 * sc, x) * step(f, thick) * step(0.0, k);
        // As the depth closes, a terrace's ledges merge into one top, and the rock under it shades from that top down
        // to its underside: how far this point lies under the line through the lips above it.
        if (open < 1.0) {
            float4 above = slopeLedge(g, k - 1.0);
            float run = tip - above.y;
            // A terrace's first ledge has no lip over it: its own top is the line.
            bool head = k < 0.5 || above.z > 1.5 * g[2];
            float drop = k < 0.0 ? 1000.0 : f + (head || run < 0.5 ? 0.0 : max(tip - x, 0.0) * above.z / run);
            float far = 1.0 - open;
            tone = mix(tone, mix(1.3, 0.5, pow(saturate(drop / 34.0), 0.7)), far);
            glint = mix(glint, exp(-drop / 2.4) * 0.6 + exp(-drop / 9.0) * 0.16, far);
        }
        tone *= 0.82 + 0.3 * sun;
        // Darker towards the heart of the rock.
        tone *= mix(0.64, 1.0, smoothstep(-20.0, 120.0, x));
        glint *= (0.7 + 0.6 * slopeNoise(float2(x * 0.06 + tm * 0.3, k * 3.1 + tm * 0.2))) * sun;
        // The rock turns from one stretch's to the next down the wall under the stretch's last ledge, never on a line.
        float rock = mix(ledge.w, slopeLedge(g, k + 1.0).w, smoothstep(0.55, 0.95, f / ledge.z));
        float3 rc = slopeSand(slopeRock(rock), slopeLit(rock), wc, tone, glint);
        rc = mix(rc, wc * 1.25, 0.2) * mix(1.0, 0.8, smoothstep(-2.8, 30.0, m));
        rc = mix(rc, float3(0.50, 0.36, 0.24) * (0.75 + 0.5 * exp(min(d, 0.0) / 9.0)), 1.0 - under);
        col = mix(col, rc, mask * below);
    }
    // A hollow's floor: sand across the foot.
    if (g[5] == 2.0) {
        float dd = depth - (foot + 8.0 * sin(pos.x * 0.012 + 0.5));
        float3 rock = slopeRock(end.w), lit = slopeLit(end.w);
        float tone = mix(1.25, 0.5, smoothstep(0.0, 70.0, dd)) * (0.82 + 0.3 * sun);
        float3 fc = slopeSand(rock, lit, wc, tone, (exp(-max(dd, 0.0) / 2.6) * 0.4 + exp(-max(dd, 0.0) / 14.0) * 0.12) * sun);
        col = mix(col, mix(fc, wc * 1.25, 0.2), slopeStep(dd));
    }

    // A near silhouette, out of focus, moving faster than the shelf.
    if (view.z > 0.0) {
        float yy = pos.y + top * 1.55;
        float e = size.x + 6.0 - 40.0 * pow(max(sin(yy * 0.0047 + 0.9), 0.0), 3.0) - 5.0 * sin(yy * 0.019);
        col = mix(col, wc * 0.34, smoothstep(-9.0, 9.0, pos.x - e) * 0.92 * view.z * smoothstep(0.0, 70.0, d) * (1.0 - taper));
    }
    float terrace = pos.y - (size.y + 70.0 - 124.0 * play.x + 8.0 * sin(pos.x * 0.0085 + 1.2) - 3.0 * sin(pos.x * 0.021 + 0.4));
    if (play.x > 0.0 && paper < 1.0) {
        // One terrace under the tank (SlopeLay.terrace), in the level's rock and its light.
        float tone = mix(1.3, 0.5, smoothstep(0.0, 64.0, terrace)) * (0.82 + 0.3 * sun) * (0.96 + 0.08 * slopeNoise(pos * 0.11));
        tone *= 1.0 + 0.05 * sin((terrace + pos.x * pos.x * 0.0004) * 0.12);
        float3 lit = mix(slopeLit(lone.w), lone.rgb, 0.6);
        float3 tc = slopeSand(slopeRock(lone.w), lit, wc, tone,
                              (exp(-max(terrace, 0.0) / 2.6) * 0.5 + exp(-max(terrace, 0.0) / 14.0) * 0.16) * (0.5 + 0.5 * sun + 0.5 * play.y));
        tc = mix(tc, wc * 1.25, 0.2) * mix(1.0, 0.8, smoothstep(-2.8, 30.0, m));
        col = mix(col, tc, slopeStep(terrace));
    }
    // A solved tank catches the light.
    col += lone.rgb * play.y * slopeBell((pos.x - 0.57 * size.x + (pos.y - 0.47 * size.y) * 0.3) / 170.0) * exp(-pos.y / 900.0) * 0.085;

    // Sinking motes, three layers; past the drop-off they thin to none, and a few large slow ones drift sideways.
    float falling = g[5] == 1.0 ? 1.0 - smoothstep(-1.5, 0.8, past) : 1.0;
    for (int j = 0; j < 3; j++) {
        float fk = float(j), cell = 46.0 + fk * 22.0;
        float2 q = float2(pos.x + fk * 37.0 - tm * 1.2, pos.y + top * open * (0.35 + fk * 0.3) - tm * (4.0 + fk * 3.0)) / cell;
        float2 id = floor(q), fr = fract(q) - 0.5;
        float2 jo = float2(slopeHash(id), slopeHash(id + 7.1)) - 0.5;
        float r = length((fr - jo * 0.7) * cell);
        float b = smoothstep(0.7 + fk * 0.5, 0.0, r) * step(0.55, slopeHash(id + 3.3));
        col += float3(0.95, 0.9, 0.75) * b * (0.08 + fk * 0.06) * view.w * under * falling;
    }
    if (falling < 1.0) {
        float2 q = float2(pos.x - tm * 3.0, pos.y + top * open * 0.8 + 6.0 * sin(pos.x * 0.011 + tm * 0.2)) / 150.0;
        float2 id = floor(q), fr = fract(q) - 0.5;
        float2 jo = float2(slopeHash(id + 1.7), slopeHash(id + 9.3)) - 0.5;
        float r = length((fr - jo * 0.6) * 150.0);
        col += float3(0.7, 0.72, 0.8) * smoothstep(2.4, 0.0, r) * step(0.5, slopeHash(id + 5.1)) * 0.2 * view.w * (1.0 - falling);
    }

    // Prism's level: clear water, white light.
    col = mix(col, dot(col, float3(0.3, 0.5, 0.2)) * float3(0.92, 0.98, 1.12), play.z * 0.9);
    float2 v = (pos / size - 0.5) * float2(1.1, 0.5);
    col *= (1.0 - dot(v, v) * 0.5) * play.w;

    if (paper > 0.0) {
        // Escapement's page: the rock in ink on bone, an outline that thickens on its shaded side and hatching under
        // each lip, with no fills, no glows and no motes; the water is the bare page.
        float3 bone = float3(0.914, 0.886, 0.816), ink = float3(0.094, 0.086, 0.110);
        float shaded = smoothstep(thick * 0.5, thick, f) * step(0.0, k);
        float line = (1.0 - smoothstep(0.5 + 0.9 * shaded, 1.3 + 0.9 * shaded, abs(across))) * below;
        float hatch = shade * mask * below * (1.0 - smoothstep(0.25, 0.6, abs(fract((pos.x + depth) / 5.0) - 0.5) * 2.0 + (1.0 - shade) * 0.6));
        if (g[6] > 0.0) line = max(line, 1.0 - smoothstep(0.4, 1.0, abs(d)));
        if (play.x > 0.0) {
            line = max(line * (1.0 - slopeStep(terrace)), 1.0 - smoothstep(0.6, 1.4, abs(terrace)));
            hatch *= 1.0 - slopeStep(terrace);
            hatch = max(hatch, smoothstep(2.0, 5.0, terrace) * (1.0 - smoothstep(5.0, 22.0, terrace))
                        * (1.0 - smoothstep(0.2, 0.5, abs(fract((pos.x + pos.y) / 5.0) - 0.5) * 2.0 + terrace / 30.0)));
        }
        col = mix(col, mix(bone, ink, max(line, hatch * 0.8) * 0.9), paper);
    }
    return col;
}

[[ stitchable ]] half4 slope(float2 pos, half4 color, float2 size, float4 view, float4 play, float4 lone, float paper,
                             device const float *g, int count) {
    float3 col = slopeGround(pos, size, view, play, lone, paper, g);
    // The dark water's steps are under one part in 255 apart: a triangular dither of one part, fixed to the pixel,
    // keeps them from banding and never crawls.
    float2 pixel = floor(pos * view.x);
    float n = slopeHash(pixel) + slopeHash(pixel + 61.7) - 1.0;
    return half4(half3(saturate(col + n / 255.0)), 1.0h);
}

// The inside of a hollow (8.2): still dark water between two jambs of pale stone, a floor near the foot, a ledge that
// juts from the leading jamb, and the cover's light falling from `source` in three soft beams of the pack's colours.
[[ stitchable ]] half4 slopeHollow(float2 pos, half4 color, float2 size, float4 view, float2 source,
                                   float3 beam0, float3 beam1, float3 beam2) {
    float2 p = pos * float2(440.0 / size.x, 1.0);
    float h = size.y;
    float3 c = float3(0.02, 0.024, 0.036) + float3(0.03, 0.035, 0.05) * (1.0 - pos.y / h);
    float2 v = pos - source;
    float ang = atan2(v.x, v.y);
    float fall = smoothstep(0.0, 40.0, v.y) * exp(-length(v) / 520.0);
    c += (beam0 * slopeBell((ang + 0.19) / 0.085) + beam1 * slopeBell(ang / 0.085) + beam2 * slopeBell((ang - 0.19) / 0.085)) * fall * 0.17;
    float low = smoothstep(h - 316.0, h, pos.y);
    float jl = 20.0 + 12.0 * sin(pos.y * 0.011 + 1.0) + 5.0 * sin(pos.y * 0.029) + 26.0 * low;
    float jr = 440.0 - (22.0 + 12.0 * sin(pos.y * 0.0093 + 3.0) + 5.0 * sin(pos.y * 0.031 + 1.0)) - 26.0 * low;
    float fl = h - 114.0 + 8.0 * sin(p.x * 0.012 + 0.5);
    float xr = 118.0 - p.x, f = pos.y - (h - 234.0) - 2.5 * sin(p.x * 0.05 + 1.0);
    float top = 4.0 * pow(1.0 - smoothstep(0.0, 26.0, xr), 2.0);
    float bot = top + 30.0 * pow(saturate(xr / 96.0), 1.5);
    float ledge = slopeStep(f - top) * slopeStep(bot - f) * slopeStep(xr);
    float lit = 0.55 + 0.9 * exp(-length(v) / 380.0);
    float3 stone = float3(0.105, 0.108, 0.125);
    float3 rc = stone * 0.8 * lit;
    rc = mix(rc, stone * 0.6 * lit, max(slopeStep(jl * 0.5 - p.x), slopeStep(p.x - (440.0 - (440.0 - jr) * 0.5))));
    rc += stone * exp(-max(min(jl - p.x, p.x - jr), 0.0) / 10.0) * 0.25 * step(pos.y, fl);
    float3 fc = stone * mix(1.25, 0.55, saturate((pos.y - fl) / 70.0))
        + float3(0.8, 0.84, 0.9) * (exp(-max(pos.y - fl, 0.0) / 2.6) * 0.22 + exp(-max(pos.y - fl, 0.0) / 14.0) * 0.07);
    rc = mix(rc, fc, slopeStep(pos.y - fl));
    float3 lc = stone * mix(1.5, 0.7, saturate((f - top) / max(bot - top, 1.0))) + float3(0.8, 0.84, 0.9) * exp(-max(f - top, 0.0) / 2.4) * 0.3;
    rc = mix(rc, lc, ledge);
    c = mix(c, rc, max(max(slopeStep(jl - p.x), slopeStep(p.x - jr)), max(slopeStep(pos.y - fl), ledge)));
    float2 e = (pos / size - 0.5) * float2(1.1, 0.5);
    c *= 1.0 - dot(e, e) * 0.5;
    float2 pixel = floor(pos * view.x);
    float n = slopeHash(pixel) + slopeHash(pixel + 61.7) - 1.0;
    return half4(half3(saturate(c + n / 255.0)), 1.0h);
}
