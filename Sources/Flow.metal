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

// Isobars, in linear light at p: a pressure chart, the contours of two octaves of gradient noise (data is
// Picture.gradients, two tables), so its lines run long and close on themselves, with no direction of their own. Every
// fifth is drawn heavier. A wave of light runs across the levels from high pressure to low, so it moves with the
// picture and a turned disc carries it. Lines are spaced by the field's own gradient, so crowded isobars are tight.
static float3 pressure(float2 p, float px, device const float2 *g, float t) {
    const float step = 0.025, tau = 6.2831853;
    float3 a = noised(1.15 * p + float2(3.1, 5.7), g), b = noised(2.7 * p + float2(1.3, 2.2), g + 64);
    float v = a.x + 0.32 * b.x;
    float2 grad = 1.15 * a.yz + 0.32 * 2.7 * b.yz;
    float s = v / step, n = floor(s + 0.5), gl = max(length(grad), 1e-4);
    float d = abs(s - n) * step / gl;
    bool bold = n - 5.0 * floor(n / 5.0) < 0.5;
    float wave = 0.5 + 0.5 * cos(tau * (n / 14.0 - t / 10.0)), lift = 0.45 + 0.55 * wave * wave * wave;
    // The spacing between lines in tank units: a line never draws wider than a fifth of it, so crowds stay apart.
    float room = step / gl, hw = min(bold ? 0.0024 : 0.0013, 0.2 * room);
    const float3 ice = float3(0.16, 0.62, 1.0), pale = float3(0.75, 0.92, 1.0);
    const float3 warm = float3(1.0, 0.36, 0.05), cool = float3(0.18, 0.05, 0.9);
    float3 ink = bold ? pale : ice;
    float line = saturate((hw - d) / px + 0.5);
    float glow = exp(-d * d / (bold ? 6.0e-5 : 2.5e-5));
    float3 c = ink * (line * (bold ? 0.9 : 0.55) + glow * (bold ? 0.12 : 0.05)) * lift;
    // A faint wash between the lines: warm where pressure is high, cool where it is low.
    c += mix(cool, warm, smoothstep(-0.35, 0.35, v)) * (0.006 + 0.01 * smoothstep(0.15, 0.5, abs(v)));
    return c;
}

[[ stitchable ]] half4 isobars(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(pressure(p, px, (device const float2 *)data, t))), 1.0h);
}
