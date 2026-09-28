// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The twins' heartbeat at p (tank units), t seconds into its minute: a 1 s lub-dub, 1 at the lub, reaching p late by
// Picture.delays, a 33 x 33 grid from (-1.1, -1.1) to (1.1, 1.1) after the picture's own floats. p is a point of the
// picture, so the beat is stirred with it and shows how far a disc turned, which probing finds anyway.
static float heartbeat(float2 p, float t, device const float *delays) {
    float2 g = clamp((p + 1.1) * (32.0 / 2.2), 0.0, 31.999), i = floor(g), f = g - i;
    int k = int(i.y) * 33 + int(i.x);
    float x = fract(t - mix(mix(delays[k], delays[k + 1], f.x), mix(delays[k + 33], delays[k + 34], f.x), f.y));
    // The lub measured the short way round, since its tail reaches back past 0.
    float a = (x - 0.06 - round(x - 0.06)) / 0.04, b = (x - 0.30) / 0.05;
    return exp(-a * a) + 0.55 * exp(-b * b);
}

// How far the twin's lines swell (x) and brighten (y) at beat b: 1 on average, the beat's mean being 0.12.
static float2 throb(float b) { return 1.0 + float2(1.0, 1.3) * (b - 0.12); }

// Marbling, in linear light at p: rings of one ink around drops. Each drop's ring coordinate counts rings out from it,
// crowded to one side, less an offset (see Picture.drops); v is a soft minimum of them over the nine nearest drops, so
// near a drop rings nest off-centre and they join a neighbour's through a rounded neck. Rings sit at integer v. cells
// holds 10 x 10 drops 0.26 apart from (-1.3, -1.3), two float4s each.
// plus draws the twin: blood in black oil, crowded harder, clotting dark where it crowds, and every ring bleeding
// outward with a thin-film sheen, the rings swelling by pulse.x and all of it brightening by pulse.y.
template <bool plus>
static float3 rings(float2 p, float px, device const packed_float4 *cells, float t, float2 pulse) {
    const float pitch = 0.26, origin = -1.3, soft = 0.5, reach = 0.0973, fade = 1.0 / (0.0973 - 0.0576);
    const int n = 10;
    float push = plus ? 1.35 : 1.0;
    int2 g = int2(floor((p - origin) / pitch));
    // Soft minimum of the nine drops' ring coordinates, with its gradient; the same weights blend the drops' glows.
    // The nearest drop is under 1.14 cells and 20 rings away, so the unshifted weights stay inside float range. A drop
    // outside the 3 x 3 search is at least 1.2 cells away, so every weight fades to 0 from 0.24 to 0.312 (1.2 cells): a
    // push or a wide spacing would otherwise let such a drop matter, and the rings would break at cell edges.
    const float k2 = 1.442695 / soft;
    float sum = 0, br = 0;
    float2 grad = 0;
    // The early-out beyond the tank keeps g within 1...8, so the search needs no clamp.
    int base = 2 * (g.y * n + g.x);
    for (int k = 0; k < 9; k++) {
        int i = base + 2 * ((k / 3 - 1) * n + k % 3 - 1);
        float4 a = cells[i], m = cells[i + 1];
        float2 r = p - a.xy;
        float d2 = max(dot(r, r), 1e-12), ri = rsqrt(d2);
        float w = exp2((a.z - m.x * d2 * ri - push * dot(m.yz, r)) * k2) * saturate((reach - d2) * fade);
        sum += w; grad += w * (m.x * ri * r + push * m.yz); br += w * a.w;
    }
    float v = -log2(sum) / k2;
    float wi = 1.0 / sum;
    grad *= wi; br *= wi;
    float n0 = floor(v + 0.5), s = v - n0;
    float g2 = dot(grad, grad), gr = rsqrt(g2), dist = abs(s) * min(gr, 1.0);
    bool odd = n0 - 2.0 * floor(n0 * 0.5) > 0.5;
    // The twin's blood clots dark where a drop's rings crowd (over 30 rings per unit; 16 to 54 occur).
    float3 ink = plus ? float3(1.0, 0.012, 0.03) * (1.0 - 0.5 * saturate((g2 * gr - 30.0) / 15.0)) : float3(0.028, 0.6, 0.021);
    // Ring 0 would be a centre dot. Fading by v rather than by ring index keeps ring 1's glow from stepping at v = 0.5.
    float on = saturate(2.0 * v - 0.4);
    float3 col = ink * (odd ? 0.8 : 1.0) * on;
    float hw = plus ? (odd ? 0.0018 : 0.0029) * pulse.x : (odd ? 0.0016 : 0.0026);
    float3 c = col * saturate((hw - dist) / px + 0.5);
    // The glow is the bloom to the 9th power: a third of its width.
    float bloom = exp(-dist * dist / 2.88e-4), b3 = bloom * bloom * bloom, glow = b3 * b3 * b3;
    float3 light = col * (0.3 * glow + 0.03 * bloom);
    if (plus) {
        // Each ring bleeds outward into the oil, gone by halfway to the next, with a thin-film sheen, rust to olive,
        // whose colour turns every few rings. It shares the blood's low blue.
        float bleed = bloom * saturate(12.0 * s) * (1.0 - 2.0 * s) * on;
        float3 film = mix(float3(0.42, 0.1, 0.004), float3(0.16, 0.24, 0.004), abs(2.0 * fract(0.3 * v + 0.25 * br) - 1.0));
        light += film * (0.5 * bleed);
    }
    c += light * (0.35 + 0.9 * br) * (plus ? 0.85 : 1.0);
    return c * pulse.y;
}

[[ stitchable ]] half4 marbling(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(rings<false>(p, px, (device const packed_float4 *)data, t, 1.0))), 1.0h);
}

[[ stitchable ]] half4 marblingPlus(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    float2 pulse = throb(heartbeat(p, t, data + count - 33 * 33));
    return half4(half3(sqrt(rings<true>(p, px, (device const packed_float4 *)data, t, pulse))), 1.0h);
}
