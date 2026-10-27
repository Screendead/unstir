// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

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

// One set of cords at p: the contours of a noise field, step apart in value. Returns (distance from the nearest
// cord's centre, its half width, its index). A cord narrows where its neighbours crowd it, so cords never merge.
static float3 cord(float3 f, float step, float width) {
    float s = f.x / step, n = floor(s + 0.5), gl = max(length(f.yz), 1e-4);
    return float3(abs(s - n) * step / gl, min(width, 0.3 * step / gl), n);
}

// A cord's light across it, x from -1 to 1 at its edges: lit along its middle, the same both sides, so no light
// direction says which way is up; and a twist of the strands along it, read from the other set's field.
static float3 strand(float3 dye, float x, float along, float t) {
    float body = sqrt(saturate(1.0 - x * x));
    float twist = 0.75 + 0.25 * cos(6.2831853 * (along * 3.0 + x * 0.8));
    float sheen = pow(body, 6.0) * (0.35 + 0.65 * pow(0.5 + 0.5 * cos(6.2831853 * (along * 0.25 - t / 10.0)), 4.0));
    return dye * body * twist * 0.8 + float3(1.0, 0.95, 0.85) * sheen * 0.35;
}

// Cords, in linear light at p: two sets of cords, each the contours of its own field (data is Picture.gradients, two
// tables), woven: where two cross, one lies over and the other under by the parity of their indices summed, so along
// any cord the crossings alternate over and under. The lower cord is shadowed where the upper passes. A glint creeps
// along every cord.
static float3 loom(float2 p, float px, device const float2 *g, float t) {
    const float step = 0.085, width = 0.0085;
    float3 fa = noised(1.6 * p + float2(4.3, 1.9), g), fb = noised(1.6 * p + float2(0.7, 6.1), g + 64);
    fa.yz *= 1.6; fb.yz *= 1.6;
    float3 a = cord(fa, step, width), b = cord(fb, step, width);
    float sa = fa.x / step, sb = fb.x / step;
    bool aOver = fmod(abs(a.z + b.z), 2.0) < 0.5;
    // Two dyes, a cool set and a warm, each in three shades.
    const float3 dyesA[3] = { float3(0.02, 0.5, 0.75), float3(0.04, 0.72, 0.68), float3(0.25, 0.85, 0.95) };
    const float3 dyesB[3] = { float3(0.95, 0.22, 0.06), float3(1.0, 0.5, 0.08), float3(0.75, 0.12, 0.08) };
    float3 dyeA = dyesA[int(fmod(abs(a.z), 3.0))], dyeB = dyesB[int(fmod(abs(b.z), 3.0))];
    float xa = a.x / a.y, xb = b.x / b.y;
    float3 ca = strand(dyeA, xa, sb, t) * saturate((a.y - a.x) / px + 0.5);
    float3 cb = strand(dyeB, xb, sa, t) * saturate((b.y - b.x) / px + 0.5);
    // The upper cord's cast shadow on the lower: a dark margin just past its edge.
    float shadeA = 1.0 - 0.85 * saturate(1.0 - (b.x - b.y) / (1.2 * b.y));
    float shadeB = 1.0 - 0.85 * saturate(1.0 - (a.x - a.y) / (1.2 * a.y));
    float coverA = saturate((a.y - a.x) / px + 0.5), coverB = saturate((b.y - b.x) / px + 0.5);
    float3 c = aOver ? ca + cb * shadeB * (1.0 - coverA) : cb + ca * shadeA * (1.0 - coverB);
    // A faint halo of loose fibre round every cord.
    c += (dyeA * exp(-a.x * a.x / 1.2e-4) + dyeB * exp(-b.x * b.x / 1.2e-4)) * 0.02;
    return c;
}

[[ stitchable ]] half4 cords(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(loom(p, px, (device const float2 *)data, t))), 1.0h);
}
