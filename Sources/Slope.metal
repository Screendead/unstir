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

// How far the overview lifts the rock at x (SlopeLay.lift).
static float slopeLift(float x) { return 22.0 * x / sqrt(x * x + 40000.0); }

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

// What the menu's ground may show beyond the slope (SlopeEggs, docs/architecture.md): each term is skipped while its
// number is 0, so a ground with none costs what it did.
struct SlopeEgg {
    // How far the night stands over the surface, the mirrored sky under the foot, still water, and a meteor night.
    float night, deep, calm, meteors;
    // The moon's terminator across its disc (1 new, -1 full) and its lit side (1 the trailing, -1 the leading).
    float2 moon;
    // The depth the mirrored sky starts at, and how far its lights have come out.
    float2 mirror;
    // A skimmed stone: seconds since it left the hand, where it first touched, its first hop (signed), its touches.
    float4 skim;
    // Gold in each tier's rock.
    float4 seam;
    // A spur of rock under the last ledge, for the unnumbered pebble: how far it reaches in from the leading edge, and
    // its top's depth.
    float2 nook;
};

// Points of light on a jittered grid at q, two sizes of cell: the night's stars. `pulse` is how far each one's light
// swells and falls on its own slow beat; `soft` gives each a little halo; `out` is how many have come out.
static float slopeStars(float2 q, float tm, float pulse, float soft, float out) {
    float s = 0.0;
    for (int j = 0; j < 2; j++) {
        float fj = float(j), cell = 27.0 + 19.0 * fj;
        float2 c = q / cell + fj * 13.7;
        float2 id = floor(c), f = fract(c) - 0.5;
        float2 jo = float2(slopeHash(id + 1.3), slopeHash(id + 5.9)) - 0.5;
        float r = length((f - jo * 0.8) * cell);
        float mag = 0.22 + 0.78 * pow(slopeHash(id + 2.2), 3.0);
        float beat = 1.0 - pulse * (0.5 + 0.5 * sin(tm * 1.6 * (0.5 + slopeHash(id)) + 6.28 * slopeHash(id + 4.0)));
        float lit = step(0.3, slopeHash(id + 9.1)) * smoothstep(0.0, 0.12, out - 0.88 * slopeHash(id + 7.7));
        // A halo ends inside its own cell, or the next cell would cut it square.
        float edge = (0.5 - max(abs(f.x), abs(f.y))) * cell;
        s += (smoothstep(1.0, 0.0, r / (0.62 + 0.8 * mag)) + soft * exp(-r / (1.1 + 1.5 * mag)) * 0.45 * smoothstep(0.0, 5.0, edge))
            * mag * beat * lit;
    }
    return s;
}

// The night over the surface, h points above it: stars, a little cloud of them, and the moon at its phase. `night` is
// how far the pull has brought it out.
static float3 slopeNight(float3 col, float2 pos, float h, float width, float tm, SlopeEgg egg) {
    float up = smoothstep(40.0, 190.0, h) * egg.night;
    col += float3(0.86, 0.9, 1.0) * slopeStars(float2(pos.x, h), tm, 0.3, 0.0, 1.0) * up;
    col += float3(0.05, 0.054, 0.085) * smoothstep(0.3, 0.9, slopeNoise(float2(pos.x * 0.005 - h * 0.004, (-h - pos.x * 0.7) * 0.011))) * up;
    float2 mv = float2(pos.x - 0.73 * width, 250.0 - h) / 15.0;
    float r = length(mv);
    if (r < 12.0) {
        float limb = sqrt(max(1.0 - mv.y * mv.y, 0.0));
        float lit = smoothstep(-0.07, 0.07, mv.x * egg.moon.y - egg.moon.x * limb);
        float3 face = float3(1.0, 0.965, 0.87) * (0.8 + 0.2 * slopeNoise(mv * 2.1 + 3.0)) * (1.0 - 0.16 * r * r);
        col = mix(col, mix(float3(0.05, 0.052, 0.075), face, lit), smoothstep(1.0, 0.92, r) * egg.night);
        col += float3(0.62, 0.64, 0.78) * exp(-max(r - 1.0, 0.0) * 0.5) * 0.10 * egg.night * (0.25 + 0.375 * (1.0 - egg.moon.x));
    }
    return col;
}

// The seam: gold in the rock of a tier at par, u ledges down it (0 to 27). A thread that wanders down the wall, swells,
// pinches out and comes back, with a few flecks beside it; x and depth are the rock's own, so it keeps its place in
// the rock from the overview to the dive. `run` is how many ledges a point of depth is, `open` the zoom eased.
static float3 slopeSeam(float x, float depth, float u, float tier, float run, float open, float tm) {
    // From far off it wanders slowly, no two bends alike; close to, smaller bends open out of it.
    float reach = mix(6.0, 24.0, open), q = 1.7 * u + 1.3 + tier, small = 0.4 * open;
    float2 p = float2(0.3 * u + 9.1 * tier, 4.2);
    float slow = 2.0 * slopeNoise(p) - 1.0, turn = (2.0 * slopeNoise(p + float2(0.015, 0.0)) - 1.0 - slow) / 0.05;
    float mid = mix(37.0, 46.0, open) + reach * ((1.0 - small) * 1.4 * slow + small * sin(q))
        + open * (2.2 * sin(depth * 0.043) + 1.1 * sin(depth * 0.117 + 2.0));
    float lean = reach * ((1.0 - small) * 1.4 * turn + small * 1.7 * cos(q)) * run
        + open * (0.095 * cos(depth * 0.043) + 0.129 * cos(depth * 0.117 + 2.0));
    float off = abs(x - mid) / sqrt(1.0 + lean * lean);
    // It runs out near either end of the tier, and pinches here and there between.
    float there = smoothstep(0.0, 1.5, u) * smoothstep(27.0, 25.0, u) * smoothstep(0.3, 0.5, slopeNoise(float2(u * 0.9 + tier * 7.3, 2.5)));
    float wide = mix(0.5, 1.0, open) * (0.45 + 1.1 * slopeNoise(float2(u * 2.3 + tier * 3.1, 8.5)));
    float core = (1.0 - smoothstep(wide * 0.5, wide + 0.6, off)) * there;
    float2 cell = float2(x, depth) / mix(3.0, 6.0, open), id = floor(cell);
    float fleck = step(0.86, slopeHash(id + tier)) * (1.0 - smoothstep(0.06, 0.2, length(fract(cell) - 0.5)))
        * exp(-off / mix(3.0, 9.0, open)) * there * (0.6 + 0.4 * sin(tm * 0.9 + 6.28 * slopeHash(id + 3.7)));
    return float3(1.0, 0.80, 0.36) * (core * (0.75 + 0.25 * sin(u * 5.0 + tm * 0.4)) + fleck * 0.8)
        + float3(0.9, 0.5, 0.12) * exp(-off / mix(1.6, 3.2, open)) * 0.22 * there;
}

// A skimmed stone's rings on the water line at x, seen from the side: each touch sends two bumps running apart. The
// touches' times and places are SlopeSkim's (its `first`, `beat` and `fall`): each hop is a fifth shorter than the last.
static float slopeRings(float x, float4 skim) {
    float s = 0.0, run = 0.0, amp = 3.4;
    for (int i = 0; i < 9; i++) {
        if (float(i) >= skim.w) break;
        float a = skim.x - 0.36 - 0.44 * run, f = abs(x - skim.y - skim.z * run) - 30.0 * a;
        if (a > 0.0) s += amp * exp(-a * 1.1) * cos(f * 0.14) * exp(-f * f / (170.0 + 700.0 * a));
        run += pow(0.8, float(i));
        amp *= 0.9;
    }
    return s;
}

// view: pixels to a point, the ground's clock in seconds, how much of the near silhouette shows, and of the motes.
// play: how far a level has taken the screen (the shelf draws aside and one terrace rises under the tank), a solved
// tank's glint, Prism's clear water, and the ground's light (1 its own; consent draws it at 0.35).
// lone: the lone terrace's light, and its rock.
// paper: how far the ground is Escapement's page, an engraving in ink on bone.
// upper: a second terrace over the lone one, a short lip of the same rock for a stone with a row of its own: the
// middle of its top on the screen, half its width, and how far it is there.
static float3 slopeGround(float2 pos, float2 size, float4 view, float4 play, float4 lone, float paper, float4 upper,
                          device const float *g, SlopeEgg egg) {
    float top = g[0], open = g[1], count = g[3], foot = g[4];
    float tm = view.y;
    float x = pos.x + 280.0 * play.x;
    // At the overview no ledge's top is straight: the whole shelf bows a few points, and lifts towards its lips
    // (SlopeLay.bow).
    float plain = top + pos.y;
    float depth = plain - (3.4 * sin(x * 0.021 + plain * 0.033) - slopeLift(x)) * (1.0 - open);
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
    float2 more = slopeMore(g, k);
    // Each ledge leans down from its back by what the overview lifts it, so its top lies level on the screen
    // (SlopeLay.crown).
    float level = depth - ledge.x;
    float f = level - (k < 0.0 ? 0.0 : (slopeLift(x) - slopeLift(more.x)) * (1.0 - open));
    float4 first = slopeLedge(g, 0.0), end = slopeLedge(g, count - 1.0);
    // Past the foot, in the last ledge's drops.
    float past = (depth - foot) / end.z;

    float m = g[7] < 0.0 ? g[8] : k < 0.0 ? more.y - 0.8 * (first.x - depth) / first.x
        : more.y + (k > count - 1.5 ? 1.0 : slopeMore(g, k + 1.0).y - more.y) * level / ledge.z;
    float3 wc = slopeWater(m);
    if (g[5] == 1.0) wc = mix(wc, float3(0.008, 0.006, 0.014), smoothstep(-0.5, 2.0, past));
    float surface = -top;
    // Still water lies flat, and light reaches further down it.
    float calm = egg.calm;
    float d = g[6] > 0.0 ? pos.y - (surface + (1.0 - calm) * (3.2 * sin(pos.x * 0.024 + tm * 1.1) + 1.8 * sin(pos.x * 0.063 - tm * 1.6 + 1.3))) : 1000.0;
    // A ring moves the water line, not the light over and under it.
    if (egg.skim.w > 0.0) d -= slopeRings(pos.x, egg.skim) * exp(-abs(d) / 9.0);
    float under = step(0.0, d);
    float sun = exp(-max(m + 2.8, 0.0) / (26.0 + 90.0 * calm)) * 0.75 + 0.25;
    float3 col;
    if (d < 0.0) {
        // The air: dusk, warm along the water.
        col = mix(float3(0.03, 0.028, 0.05), float3(0.60, 0.37, 0.21), exp(d / 62.0) * 0.8);
        col += float3(0.5, 0.3, 0.12) * exp(-length((pos - float2(60.0, surface)) * float2(0.006, 0.02))) * 0.22;
        if (egg.night > 0.0) col = slopeNight(col, pos, surface - pos.y, size.x, tm, egg);
    } else {
        col = wc;
        float sx = pos.x + d * 0.32 + tm * 4.0;
        float rays = slopeNoise(float2(sx * 0.016, 1.7)) * slopeNoise(float2(sx * 0.041 + 9.0, tm * 0.12));
        col += float3(0.85, 0.78, 0.55) * smoothstep(0.12, 0.55, rays) * exp(-max(m + 2.8, 0.0) / (8.0 + 44.0 * calm)) * 0.08 * (1.0 - 0.3 * calm);
        col += float3(0.55, 0.50, 0.30) * exp(-d / 46.0) * 0.16;
        col += float3(0.45, 0.30, 0.10) * exp(-length((pos - float2(40.0, surface)) * float2(0.004, 0.0046))) * 0.16;
        col += float3(1.0, 0.9, 0.72) * exp(-d / 1.3) * (0.5 + 0.3 * calm);
        if (egg.night > 0.0) {
            // The moon on the water: a bright stretch of the surface under it, and broken glints going down.
            float mx = pos.x - 0.73 * size.x;
            float a = exp(-d / 1.6) * slopeBell(mx / 44.0) * 0.45
                + slopeBell(mx / (13.0 + d * 0.22)) * exp(-d / 60.0) * (0.8 + 0.2 * sin(pos.x * 0.4 + tm * 3.0)) * 0.1;
            col += float3(1.0, 0.96, 0.86) * a * egg.night * 0.5 * (1.0 - egg.moon.x);
        }
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
        // In still water the far ridges come out of the haze.
        rc += wc * calm * (0.5 - 0.2 * fj) * exp(-max(pos.x - e, 0.0) / (26.0 + 30.0 * fj));
        col = mix(col, rc, smoothstep(-soft, soft, pos.x - e) * under * smoothstep(0.0, 40.0, d));
    }

    // The shelf.
    float e0, lean, sc = 1.0;
    float4 sp = slopeShape(ledge.w, g);
    if (k < 0.0) {
        // Over the first ledge the wall wanders up to the bank.
        float s = saturate(depth / max(first.x, 1.0)), b = sin(3.14159265 * s);
        e0 = more.x + (8.0 + 4.0 * sin(depth * 0.11 + 1.0)) * b * b + 14.0 * (1.0 - s) * (1.0 - s);
        lean = 0.0;
    } else {
        sc = slopeScale(ledge, sp, g);
        e0 = slopeEdge(g, k, f);
        lean = (slopeEdge(g, k, f + 0.5) - e0) / 0.5;
    }
    float din = e0 - x, across = din / sqrt(1.0 + lean * lean);
    float mask = slopeStep(across);
    // Over a leaning ledge's top the edge runs nearly level, and its softness would reach out past the lip as a line.
    if (f < 0.0) mask *= 1.0 - smoothstep(ledge.y - 1.0, ledge.y + 1.0, x);
    float below = 1.0, dry = 0.0;
    if (g[6] > 0.0) {
        // The bank's shoulder under the water line, and its dry top over it: drawn by the screen, as the stone on it is.
        // Under the water it falls away from the water line as gently as it came down to it, then steepens to the wall.
        mask = max(mask, smoothstep(-2.5, 2.5, 100.0 * exp(-pow(max(pos.y - surface, 0.0) / 90.0, 0.9)) - x));
        dry = pos.y - (surface - (26.0 * slopeBell(x / 80.0) - 6.0));
        below = slopeStep(dry);
    }
    float thick = sp.x * sc;
    // 1 on the wall under a lip, where its shadow falls, gone by the next ledge's top.
    float shade = exp(-max(din, 0.0) / (14.0 * sc + 1.0)) * smoothstep(thick * 0.45, thick, f)
        * (1.0 - smoothstep(thick, min(thick + 36.0 * sc + 2.0, ledge.z), f)) * step(0.0, k);
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
        // Over the first ledge the overview shows the back wall rising to the bank, lit along its edge.
        if (k < 0.0) tone = mix(tone, 0.62 + 0.22 * exp(-max(max(e0, 100.0 * exp(-pow(max(pos.y - surface, 0.0) / 90.0, 0.9))) - x, 0.0) / 9.0),
                                1.0 - open);
        tone *= 0.82 + 0.3 * sun;
        // Darker towards the heart of the rock in the dive; the overview's rock is one lit mass.
        tone *= mix(mix(0.64, 1.0, smoothstep(-20.0, 120.0, x)), 1.0, 1.0 - open);
        glint *= (0.7 + 0.6 * slopeNoise(float2(x * 0.06 + tm * 0.3, k * 3.1 + tm * 0.2))) * sun;
        // The rock turns from one stretch's to the next down the wall under the stretch's last ledge, never on a line.
        float rock = mix(ledge.w, slopeLedge(g, k + 1.0).w, smoothstep(0.55, 0.95, f / ledge.z));
        float3 rc = slopeSand(slopeRock(rock), slopeLit(rock), wc, tone, glint);
        rc = mix(rc, wc * 1.25, 0.2) * mix(1.0, 0.8, smoothstep(-2.8, 30.0, m));
        if (egg.seam.x + egg.seam.y + egg.seam.z + egg.seam.w > 0.0 && k >= g[7] && m < 109.0) {
            // A tier is three terraces of nine, and the water's depth counts its ledges evenly.
            float tier = floor((m - 1.0) / 27.0);
            if (egg.seam[int(tier)] > 0.0) {
                float run = (k > count - 1.5 ? 1.0 : slopeMore(g, k + 1.0).y - more.y) / ledge.z;
                rc += slopeSeam(x, depth, m - 1.0 - 27.0 * tier, tier, run, open, tm) * (0.5 + 0.5 * sun);
            }
        }
        // Out of the water the bank stands dark against the dusk, the last light along its top.
        rc = mix(rc, float3(0.19, 0.135, 0.115) * (0.8 + 0.5 * exp(min(d, 0.0) / 9.0))
                 + float3(0.66, 0.42, 0.22) * exp(-max(dry - 0.7, 0.0) / 2.6) * 0.8, 1.0 - under);
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

    if (egg.nook.x > 0.0 && fine > 0.0) {
        // Under the last ledge, where the rock has curved back off the screen, a spur of it comes in again: a bowed top,
        // a round nose, its underside cut back to the edge (SlopeEggs.nook seats a pebble on it).
        float u = saturate(x / egg.nook.x), over = depth - egg.nook.y - 3.0 * u * u;
        float thick = 22.0 * sqrt(max(1.0 - u * u * u * u, 0.0)) + 16.0 * (1.0 - u);
        float inside = min(min(over, thick - over), (egg.nook.x - x) * 0.6);
        float tone = mix(1.3, 0.5, smoothstep(0.0, 18.0, over)) * (0.82 + 0.3 * sun) * (0.96 + 0.08 * slopeNoise(float2(x, depth) * 0.11));
        float3 sc3 = slopeSand(slopeRock(end.w), slopeLit(end.w), wc, tone, (exp(-max(over, 0.0) / 2.6) * 0.5 + exp(-max(over, 0.0) / 9.0) * 0.16) * sun);
        col = mix(col, mix(sc3, wc * 1.25, 0.2) * 0.8, slopeStep(inside) * fine);
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
    // The second terrace: its top bows up a few points, its ends are rounded noses and its underside is cut back.
    float lipIn = 0.0, lipEdge = 0.0, lipLow = 0.0;
    if (upper.w > 0.0 && play.x > 0.0) {
        float u = (pos.x - upper.x) / max(upper.z, 1.0), a = min(abs(u), 1.0);
        float over = pos.y - (upper.y + 4.0 * u * u), deep = 17.0 * sqrt(1.0 - a * a * a * a) - 4.0 * u * u;
        float sides = (upper.z - abs(pos.x - upper.x)) * 0.5;
        float inside = min(min(over, deep - over), sides);
        lipIn = slopeStep(inside) * upper.w * play.x;
        lipLow = deep - over;
        lipEdge = (1.0 - smoothstep(0.5, 1.3, abs(inside))) * upper.w * play.x;
        if (paper < 1.0) {
            float tone = mix(1.3, 0.5, smoothstep(0.0, 16.0, over)) * (0.82 + 0.3 * sun) * (0.96 + 0.08 * slopeNoise(pos * 0.11));
            float3 lit = mix(slopeLit(lone.w), lone.rgb, 0.6);
            float3 lc = slopeSand(slopeRock(lone.w), lit, wc, tone,
                                  (exp(-max(over, 0.0) / 2.6) * 0.5 + exp(-max(over, 0.0) / 9.0) * 0.14) * (0.5 + 0.5 * sun + 0.5 * play.y));
            lc = mix(lc, wc * 1.25, 0.2) * mix(1.0, 0.8, smoothstep(-2.8, 30.0, m));
            col = mix(col, lc, lipIn);
        }
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
        col += float3(0.95, 0.9, 0.75) * b * (0.08 + fk * 0.06) * view.w * under * falling * (1.0 - 0.7 * calm);
    }
    if (falling < 1.0) {
        float2 q = float2(pos.x - tm * 3.0, pos.y + top * open * 0.8 + 6.0 * sin(pos.x * 0.011 + tm * 0.2)) / 150.0;
        float2 id = floor(q), fr = fract(q) - 0.5;
        float2 jo = float2(slopeHash(id + 1.7), slopeHash(id + 9.3)) - 0.5;
        float r = length((fr - jo * 0.6) * 150.0);
        col += float3(0.7, 0.72, 0.8) * smoothstep(2.4, 0.0, r) * step(0.5, slopeHash(id + 5.1)) * 0.2 * view.w * (1.0 - falling);
    }

    if (egg.deep > 0.0) {
        // Under the last water the sky's own stars stand upside down, cold, coming out one by one.
        float fall = top + pos.y - egg.mirror.x;
        col += (float3(0.7, 0.92, 0.98) * slopeStars(float2(pos.x, fall + 400.0), tm, 0.7, 1.0, egg.mirror.y)
                + float3(0.0, 0.016, 0.026) * smoothstep(0.0, 300.0, fall + 120.0)) * smoothstep(-150.0, 30.0, fall) * egg.deep;
    }

    // Prism's level: clear water, white light.
    col = mix(col, dot(col, float3(0.3, 0.5, 0.2)) * float3(0.92, 0.98, 1.12), play.z * 0.9);
    float2 v = (pos / size - 0.5) * float2(1.1, 0.5);
    col *= (1.0 - dot(v, v) * 0.5) * play.w;

    if (paper > 0.0) {
        // Escapement's page: the rock in ink on bone, an outline that thickens on its shaded side and hatching under
        // each lip, with no fills, no glows and no motes; the water is the bare page.
        float3 bone = float3(0.953, 0.918, 0.847), ink = float3(0.102, 0.102, 0.102);
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
        // The second terrace is drawn over the page: its outline, and a little hatching along its underside.
        line = max(line * (1.0 - lipIn), lipEdge);
        hatch = max(hatch * (1.0 - lipIn), lipIn * (1.0 - smoothstep(0.2, 0.5, abs(fract((pos.x + pos.y) / 5.0) - 0.5) * 2.0
                                                                       + lipLow / 9.0)));
        col = mix(col, mix(bone, ink, max(line, hatch * 0.8) * 0.9), paper);
    }
    return col;
}

// eggs: SlopeEggs.uniforms, a SlopeEgg's numbers in its own order.
[[ stitchable ]] half4 slope(float2 pos, half4 color, float2 size, float4 view, float4 play, float4 lone, float paper,
                             float4 upper, device const float *g, int count, device const float *eggs, int eggCount) {
    SlopeEgg egg = { eggs[0], eggs[1], eggs[2], eggs[3], float2(eggs[4], eggs[5]), float2(eggs[6], eggs[7]),
                     float4(eggs[8], eggs[9], eggs[10], eggs[11]), float4(eggs[12], eggs[13], eggs[14], eggs[15]),
                     float2(eggs[16], eggs[17]) };
    float3 col = slopeGround(pos, size, view, play, lone, paper, upper, g, egg);
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
