// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The slope's ground: one pass for everything outside the tank. Water by depth under a dusk sky and a wavy surface,
// two hazy far ridges, the shelf of rock in overhung ledges, each tier's own, an out-of-focus near silhouette and
// sinking motes. Layers slide at different speeds as the camera moves, and that is all the depth there is. Nothing
// here stirs.
//
// g is Slope.Frame.uniforms: the world point at the screen's corner, the zoom (points to a world unit), the ledges'
// pitch, the first ledge's depth, the lips' line from the screen's edge in the dive, the ledge count and how far the
// flights stand out as stairs (1 in the overview); each tier's ledge shape (thickness, undercut, nose, ripple); then
// every ledge's lip in world x. The rock's profile is built from those lips alone, so a pebble Swift seats on a lip
// (Slope.Frame.seat) sits on the drawn rock at every zoom.

constant int slopeShapes = 16, slopeTips = 32;

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

static float slopeTier(device const float *g, float k) { return clamp(floor((k - g[8]) / g[9]), 0.0, 3.0); }

static float slopeTip(device const float *g, float k) {
    return g[slopeTips + int(clamp(k, 0.0, g[6] - 1.0))];
}

static float4 slopeShape(device const float *g, float k) {
    int t = slopeShapes + 4 * int(slopeTier(g, clamp(k, 0.0, g[6] - 1.0)));
    return float4(g[t], g[t + 1], g[t + 2], g[t + 3]);
}

// Where the rock under ledge k - 1 meets ledge k's top (Slope.Frame.back).
static float slopeBack(device const float *g, float k) {
    return min(slopeTip(g, k - 1.0), slopeTip(g, k)) - 0.85 * slopeShape(g, k - 1.0).y;
}

// The rock's edge in world x, f under ledge k's top: out to the lip round its nose, back under it by the undercut and
// away to where the next ledge begins. Under the brink it only falls back.
static float slopeEdge(device const float *g, float k, float f) {
    float pitch = g[3];
    float4 sp = slopeShape(g, k);
    float tip = slopeTip(g, k), back = slopeBack(g, k);
    float e = tip - sp.y * smoothstep(0.0, 1.0, pow(saturate(f / sp.x), sp.z));
    float s = saturate((f - sp.x) / (pitch - sp.x));
    float b = sin(3.14159265 * s);
    // A long way back, the underside thins towards the nose as an eave does; a short way, it eases both ends.
    float next = slopeBack(g, k + 1.0);
    float ease = mix(s * s * (3.0 - 2.0 * s), pow(s, 0.6), smoothstep(80.0, 400.0, tip - next));
    e = mix(e, next, ease) + 4.0 * b * b + (sp.w + 1.0) * sin(f * 0.19 + k) * b * b;
    if (k > g[6] - 1.5) {
        float q = max(f - sp.x * 0.6, 0.0);
        e -= 3.2 * q * q / (q + 90.0);
    }
    float n = max(1.0 - f / 10.0, 0.0);
    return e - (tip - back) * n * n * n;
}

// The water's colour by depth in ledges: sunlit green shallows, then each tier's own dark, then the open deep.
static float3 slopeWater(device const float *g, float u) {
    // t is 0 through the shallows and plughole, and turns to each next tier's across its two bare ledges.
    float t = (u - g[8] - 1.0) / g[9];
    float3 c = mix(float3(0.075, 0.30, 0.31), float3(0.018, 0.125, 0.165), smoothstep(-0.8, g[8] + 10.0, u));
    c = mix(c, float3(0.105, 0.03, 0.155), smoothstep(0.88, 1.12, t));
    c = mix(c, float3(0.02, 0.04, 0.15), smoothstep(1.88, 2.12, t));
    c = mix(c, float3(0.10, 0.016, 0.024), smoothstep(2.88, 3.12, t));
    return mix(c, float3(0.008, 0.006, 0.014), smoothstep(g[6] - 1.0, g[6] + 10.0, u));
}

static float3 slopeRock(float t) {
    float3 c = mix(float3(0.50, 0.36, 0.27), float3(0.30, 0.165, 0.32), saturate(t));
    c = mix(c, float3(0.12, 0.185, 0.36), saturate(t - 1.0));
    return mix(c, float3(0.23, 0.075, 0.07), saturate(t - 2.0));
}

static float3 slopeLit(float t) {
    float3 c = mix(float3(1.0, 0.82, 0.55), float3(1.0, 0.62, 0.86), saturate(t));
    c = mix(c, float3(0.55, 0.76, 1.0), saturate(t - 1.0));
    return mix(c, float3(1.0, 0.46, 0.26), saturate(t - 2.0));
}

// Rock by how lit it is: its shadows take the water's colour, its lit faces the tier's own.
static float3 slopeSand(float3 rock, float3 lit, float3 water, float tone, float glint) {
    return mix(mix(rock * 0.5, water * 2.4, 0.42), rock * 1.36 + lit * 0.05, smoothstep(0.4, 1.3, tone)) + lit * glint;
}

// view: pixels to a point, the ground's clock in seconds, how much of the near silhouette shows, and of the motes.
// play: how far a level has taken the screen (the shelf draws aside and a terrace rises under the tank), a solved
// tank's glint, Prism's clear water, unused.
static float3 slopeGround(float2 pos, float2 size, float4 view, float4 play, device const float *g) {
    float2 origin = float2(g[0], g[1]);
    float zoom = g[2], pitch = g[3], top = g[4], stairs = g[7];
    float tm = view.y;
    float2 w = origin + pos / zoom;
    float px = 1.0 / zoom;
    float centre = origin.y + 0.5 * size.y / zoom;
    // Fine grain and banding are for the dive: they would shimmer through a zoom.
    float fine = smoothstep(0.3, 0.8, zoom);

    float u = (w.y - top) / pitch;
    float fathoms = max(w.y / pitch, 0.0);
    float3 wc = slopeWater(g, u);
    float surface = -origin.y * zoom;
    float d = pos.y - (surface + 3.2 * sin(pos.x * 0.024 + tm * 1.1) + 1.8 * sin(pos.x * 0.063 - tm * 1.6 + 1.3));
    float under = step(0.0, d);
    float sun = exp(-fathoms / 38.0) * 0.75 + 0.25;
    float3 col;
    if (d < 0.0) {
        // The air: dusk, warm along the water.
        float glow = exp(d / 62.0);
        col = mix(float3(0.03, 0.028, 0.05), float3(0.60, 0.37, 0.21), glow * 0.8);
        col += float3(0.5, 0.3, 0.12) * exp(-length((pos - float2(60.0, surface)) * float2(0.006, 0.02))) * 0.22;
    } else {
        col = wc;
        float sx = pos.x + d * 0.32 + tm * 4.0;
        float rays = slopeNoise(float2(sx * 0.016, 1.7)) * slopeNoise(float2(sx * 0.041 + 9.0, tm * 0.12));
        col += float3(0.85, 0.78, 0.55) * smoothstep(0.12, 0.55, rays) * exp(-fathoms / 14.0) * 0.10;
        col += float3(0.55, 0.50, 0.30) * exp(-d / 46.0) * 0.16;
        col += float3(0.45, 0.30, 0.10) * exp(-length((pos - float2(40.0, surface)) * float2(0.004, 0.0046))) * 0.16;
        col += float3(1.0, 0.9, 0.72) * exp(-d / 1.3) * 0.5;
    }

    // Two far ridges, each moving slower than the shelf and shrinking less as the camera draws back. Haze takes them
    // towards the water's own colour: the further one is the fainter, and neither is ever lighter than the water.
    float far = pow(zoom, 0.15);
    for (int j = 0; j < 2; j++) {
        float fj = float(j);
        float yy = (pos.y - 0.5 * size.y) / far + centre * (0.3 + 0.28 * fj) + 300.0 * fj;
        float e = size.x - 122.0 + 72.0 * fj + (38.0 - 12.0 * fj) * sin(yy * (0.0057 + 0.0031 * fj) + 1.7 * fj + 0.4)
            + 13.0 * sin(yy * 0.0173 + 4.0 * fj) + 4.5 * sin(yy * 0.061 + fj);
        float soft = 2.6 - 1.4 * fj;
        float inside = smoothstep(-soft, soft, pos.x - e);
        float3 rc = wc * (0.80 - 0.22 * fj);
        // Light from above catches the ridge's shoulder where there is light to catch.
        rc += wc * 0.5 * sun * sun * exp(-max(pos.x - e, 0.0) / (10.0 + 8.0 * fj)) * (0.5 + 0.5 * sin(yy * 0.061 + fj + 1.6)) * (0.6 - 0.25 * fj);
        col = mix(col, rc, inside * under * smoothstep(0.0, 40.0, d));
    }

    // The shelf.
    float slide = 280.0 * play.x / zoom;
    float x = w.x + slide;
    float k = min(floor(u), g[6] - 1.0), f = (u - k) * pitch;
    float4 sp = slopeShape(g, k);
    float h = max(0.6, 0.5 * px);
    float e0 = slopeEdge(g, k, f), lean = (slopeEdge(g, k, f + h) - e0) / h;
    // The bank's shoulder under the water line, and its dry top above it: drawn by the screen, as the stone on it is.
    float swell = origin.x + 84.0 * slopeBell((pos.y - surface) / 66.0) / zoom;
    e0 = max(e0, swell);
    float din = e0 - x;
    float mask = smoothstep(-0.7, 0.7, din * zoom / sqrt(1.0 + lean * lean));
    float below = smoothstep(-0.7, 0.7, pos.y - (surface - (26.0 * slopeBell((pos.x + slide * zoom) / 80.0) - 6.0)));
    if (mask * below > 0.001) {
        float tip = slopeTip(g, k), back = slopeBack(g, k), thick = sp.x;
        float tone = f < thick * 1.15 ? mix(1.32, 0.56, smoothstep(0.0, thick * 1.15, f))
            : mix(0.56, 0.82, smoothstep(thick, pitch - 10.0, f));
        float nose = smoothstep(back - 2.0, back + 26.0, x) * (1.0 - smoothstep(thick * 0.9, thick * 1.6, f));
        tone = mix(0.76, tone, nose);
        // The wall under a lip lies in its shadow.
        tone *= 1.0 - 0.38 * exp(-max(din, 0.0) / (14.0 + 2.0 * px)) * smoothstep(thick * 0.45, thick, f) * (1.0 - smoothstep(thick, thick + 36.0, f));
        // In the overview a terrace's top takes the light a little way down into the rock, and the recess under it
        // loses it: measured from a line run smoothly through the lips, so no ledge's row shows in the shading.
        if (stairs > 0.0) {
            float a0 = slopeTip(g, k - 1.0), a1 = slopeTip(g, k), a2 = slopeTip(g, k + 1.0), a3 = slopeTip(g, k + 2.0);
            float s = saturate(f / pitch), sm = s * s * (3.0 - 2.0 * s);
            float rise = mix(a2 - a0, a3 - a1, sm) * 0.5 / pitch;
            float deep = max(mix(a1, a2, sm) - x, 0.0) * zoom;
            tone += stairs * (0.5 * smoothstep(0.0, 0.2, rise) * exp(-deep / max(rise, 0.05) / 9.0)
                              - 0.2 * (1.0 - smoothstep(-0.5, 0.7, rise)) * exp(-deep / 16.0));
        }
        tone *= 0.82 + 0.3 * sun;
        // Soft bands that bow with the slope and a little grain, darker towards the heart of the rock.
        float bx = pos.x + slide * zoom;
        tone *= 1.0 + fine * (0.05 * sin((u + bx * bx * 0.00002) * 9.4) + 0.035 * sin((u - bx * 0.004) * 23.0));
        tone *= 1.0 + fine * 0.08 * (slopeNoise(float2(x, w.y) * 0.11) - 0.5);
        tone *= mix(0.64, 1.0, smoothstep(-20.0, 120.0, bx));
        // The ledge's top catches the light: a bright line along it and a glow under that, dappled by the water.
        float crown = 10.0 * (1.0 - pow(saturate((tip - x) / max(tip - back, 1.0)), 1.0 / 3.0));
        float below0 = max(f - crown, 0.0);
        float glint = (exp(-below0 / max(2.6, 0.8 * px)) * 0.62 + exp(-below0 / max(13.0, 2.5 * px)) * 0.2)
            * smoothstep(back - 1.0, back + 9.0, x) * step(f, thick);
        glint *= (0.7 + 0.6 * slopeNoise(float2(bx * 0.06 + tm * 0.3, k * 3.1 + tm * 0.2))) * sun;
        // The rock's colour turns from one tier's to the next across the bare ledges between them, never on a line.
        float t = clamp((u - g[8] - 1.0) / g[9], 0.0, 3.0);
        float tier = smoothstep(0.93, 1.07, t) + smoothstep(1.93, 2.07, t) + smoothstep(2.93, 3.07, t);
        float3 rc = slopeSand(slopeRock(tier), slopeLit(tier), wc, tone, glint);
        rc = mix(rc, wc * 1.25, 0.2) * mix(1.0, 0.8, smoothstep(0.0, 34.0, fathoms));
        rc = mix(rc, float3(0.50, 0.36, 0.24) * (0.75 + 0.5 * exp(min(d, 0.0) / 9.0)), 1.0 - under);
        col = mix(col, rc, mask * below);
    }

    // A near silhouette, out of focus, moving faster than the shelf.
    if (view.z > 0.0) {
        float yy = pos.y - 0.5 * size.y + centre * 1.55;
        float e = size.x + 6.0 - 40.0 * pow(max(sin(yy * 0.0047 + 0.9), 0.0), 3.0) - 5.0 * sin(yy * 0.019);
        col = mix(col, wc * 0.34, smoothstep(-9.0, 9.0, pos.x - e) * 0.92 * view.z * smoothstep(0.0, 70.0, d));
    }
    if (play.x > 0.0) {
        // One terrace under the tank (Slope.terrace).
        float dd = pos.y - (size.y + 70.0 - 124.0 * play.x + 8.0 * sin(pos.x * 0.0085 + 1.2) - 3.0 * sin(pos.x * 0.021 + 0.4));
        float tone = mix(1.3, 0.5, smoothstep(0.0, 64.0, dd)) * (0.82 + 0.3 * sun) * (0.96 + 0.08 * slopeNoise(pos * 0.11));
        tone *= 1.0 + 0.05 * sin((dd + pos.x * pos.x * 0.0004) * 0.12);
        float3 sc = slopeSand(slopeRock(0.0), slopeLit(0.0), wc, tone,
                              (exp(-max(dd, 0.0) / 2.6) * 0.5 + exp(-max(dd, 0.0) / 14.0) * 0.16) * (0.5 + 0.5 * sun + 0.5 * play.y));
        sc = mix(sc, wc * 1.25, 0.2) * mix(1.0, 0.8, smoothstep(0.0, 34.0, fathoms));
        col = mix(col, sc, smoothstep(-0.7, 0.7, dd));
    }
    // A solved tank catches the light.
    col += float3(1.0, 0.86, 0.6) * play.y * slopeBell((pos.x - 0.57 * size.x + (pos.y - 0.47 * size.y) * 0.3) / 170.0)
        * exp(-pos.y / 900.0) * 0.085;

    // Sinking motes, three layers.
    for (int j = 0; j < 3; j++) {
        float fk = float(j), cell = 46.0 + fk * 22.0;
        float2 q = float2(pos.x + fk * 37.0 - tm * 1.2, pos.y + centre * zoom * (0.35 + fk * 0.3) - tm * (4.0 + fk * 3.0)) / cell;
        float2 id = floor(q), fr = fract(q) - 0.5;
        float2 jo = float2(slopeHash(id), slopeHash(id + 7.1)) - 0.5;
        float r = length((fr - jo * 0.7) * cell);
        float b = smoothstep(0.7 + fk * 0.5, 0.0, r) * step(0.55, slopeHash(id + 3.3));
        col += float3(0.95, 0.9, 0.75) * b * (0.08 + fk * 0.06) * view.w * under * (1.0 - smoothstep(g[6] - 40.0, g[6] + 12.0, u));
    }

    // Prism's level: clear water, white light.
    col = mix(col, dot(col, float3(0.3, 0.5, 0.2)) * float3(0.92, 0.98, 1.12), play.z * 0.9);
    float2 v = (pos / size - 0.5) * float2(1.1, 0.5);
    return col * (1.0 - dot(v, v) * 0.5);
}

[[ stitchable ]] half4 slope(float2 pos, half4 color, float2 size, float4 view, float4 play, device const float *g, int count) {
    float3 col = slopeGround(pos, size, view, play, g);
    // The dark water's steps are under one part in 255 apart: a triangular dither of one part, fixed to the pixel,
    // keeps them from banding and never crawls.
    float2 pixel = floor(pos * view.x);
    float n = slopeHash(pixel) + slopeHash(pixel + 61.7) - 1.0;
    return half4(half3(saturate(col + n / 255.0)), 1.0h);
}
