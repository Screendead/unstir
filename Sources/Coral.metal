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

static float line(float d, float px, float hw) { return saturate((hw - d) / px + 0.5); }

// Brain coral, in linear light at p: a labyrinth from a sum of oriented wave kernels. Its walls are where the sum's real
// part crosses zero; fainter grooves where the imaginary part does run between them, at crest and valley floor alike, so
// no line ever ends. cells is Picture.kernels: one kernel per cell of a 15 x 15 grid 0.16 across from (-1.2, -1.2), 6
// floats each. A kernel reaches 1.1 cells and its centre stays 0.15 cells inside its own cell, so the 3 x 3 search sees
// every kernel that touches p.
// plus draws the twin, diseased: bled to raspberry, with ochre lesions in inflamed blood halos and grooves gone dull,
// its lines swelling by pulse.x and all of it brightening by pulse.y.
template <bool plus>
static float3 field(float2 p, float px, device const float *cells, float t, float2 pulse) {
    const float pitch = 0.16, origin = -1.2, r2 = (1.1 * 0.16) * (1.1 * 0.16);
    int2 g = int2(floor((p - origin) / pitch));
    float re = 0, im = 0, wsum = 0, glow = 0, sick = 0;
    float2 gre = 0, gim = 0;
    for (int k = 0; k < 9; k++) {
        int2 c = clamp(g + int2(k % 3 - 1, k / 3 - 1), 0, 14);
        device const float *e = cells + 6 * (c.y * 15 + c.x);
        float2 r = p - float2(e[0], e[1]);
        float q = 1.0 - dot(r, r) / r2;
        if (q <= 0.0) continue;
        float w = q * q * q;
        float2 kv = float2(e[2], e[3]), gw = (-6.0 / r2) * q * q * r;
        float cs, sn = sincos(dot(kv, r) + e[4], cs);
        re += w * cs;
        im += w * sn;
        gre += gw * cs - (w * sn) * kv;
        gim += gw * sn + (w * cs) * kv;
        wsum += w;
        glow += w * e[5];
        // The twin's lesions: one kernel in six, chosen by hashing its fixed centre, so a lesion never pops.
        if (plus) sick += fract(e[0] * 97.3) < 0.167 ? w : 0.0;
    }
    float fade = smoothstep(0.02, 0.12, wsum), inv = 1.0 / max(wsum, 1e-4);
    float breath = glow * inv;
    float d = abs(re) / (length(gre) + 1e-6), d2 = d * d;
    float di = abs(im) / (length(gim) + 1e-6), di2 = di * di;
    if (!plus) {
        // Walls hot pink, #FF2BD6 dim to #FF4FA0 bright; violet only in the wide bloom. Every term is low in green, so
        // summed glows stay pink and never reach white.
        const float3 magenta = float3(1.0, 0.024, 0.672), hot = float3(1.0, 0.078, 0.352), violet = float3(0.365, 0.030, 1.0);
        float3 c = mix(magenta, hot, breath) * (line(d, px, 0.0021) + 0.335 * (0.35 + 0.9 * breath) * exp(-d2 / 3.2e-5));
        c += magenta * (0.45 * line(di, px, 0.0013) + 0.06 * exp(-di2 / 1.6e-5));
        c += violet * (0.05 * (0.5 + 0.8 * breath) * exp(-d2 / 2.88e-4));
        return c * fade;
    }
    const float3 rasp = float3(1.0, 0.01, 0.2), ochre = float3(0.75, 0.33, 0.01), blood = float3(0.35, 0.0, 0.03);
    // Where diseased kernels dominate, the walls swell and turn ochre and stay lit, so no wall ends in a lesion; an
    // inflamed blood halo rims it, its edge breathing with the local glow.
    float s = (sick + 0.25 * (glow - 0.5 * wsum)) * inv, inside = smoothstep(0.45, 0.8, s), m = (s - 0.4) / 0.12;
    float halo = saturate(1.0 - m * m);
    float3 wall = mix(rasp, ochre, inside);
    float3 c = wall * (line(d, px, (0.0021 + 0.001 * inside) * pulse.x)
                       + 0.254 * (0.35 + 0.9 * breath + 0.4 * inside) * exp(-d2 / 3.2e-5));
    c += wall * (0.4 * line(di, px, 0.0013 * pulse.x));
    c += blood * (0.059 * (0.5 + 0.8 * breath) * exp(-d2 / 2.88e-4) + 0.085 * halo * halo);
    return c * fade * pulse.y;
}

[[ stitchable ]] half4 coral(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(field<false>(p, px, data, t, 1.0))), 1.0h);
}

[[ stitchable ]] half4 coralPlus(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    float2 pulse = throb(heartbeat(p, t, data + count - 33 * 33));
    return half4(half3(sqrt(field<true>(p, px, data, t, pulse))), 1.0h);
}
