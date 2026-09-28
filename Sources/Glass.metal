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

// Nightmare's cracked glass, alive, in linear light at p (tank units, y down); px is a device pixel in tank units.
// cells is Picture.cells: 22 x 22 cells 0.11 across from (-1.21, -1.21), each (seed x, y, breath phase, pane). Crack
// and pane glow breathe each on their own phase: a wave shared across the tank would show a turned disc which way it
// turned. The fastest thing at any point is a scan line sweeping past every 2 s.
// plus draws the twin: crimson and bile, a crazing net in every pane, and scan lines that stutter or die. Its lines
// swell by pulse.x and it all brightens by pulse.y.
template <bool plus>
static float3 cracks(float2 p, float px, device const packed_float4 *cells, float t, float2 pulse) {
    const float pitch = 0.11;
    int2 g = int2(floor((p + 1.21) / pitch));
    float2 s[9];
    float ph[9];
    float2 a = 0;
    float pa = 0, pane = 0, d1 = 1e9;
    for (int k = 0; k < 9; k++) {
        int2 c = clamp(g + int2(k % 3 - 1, k / 3 - 1), 0, 21);
        float4 cell = cells[c.y * 22 + c.x];
        s[k] = cell.xy;
        ph[k] = cell.z;
        float d = distance_squared(p, s[k]);
        if (d < d1) { d1 = d; a = s[k]; pa = ph[k]; pane = cell.w; }
    }
    // The two nearest borders: bisectors with neighbours. Glowing both, as a blur would, keeps the glow smooth where they meet.
    float e1 = 1e9, e2 = 1e9, p1 = 0, p2 = 0;
    int k1 = 0, k2 = 0;
    for (int k = 0; k < 9; k++) {
        float2 m = s[k] - a;
        float l = length(m);
        if (l < 1e-6) continue;
        float e = dot(0.5 * (a + s[k]) - p, m) / l;
        if (e < e1) { e2 = e1; p2 = p1; k2 = k1; e1 = e; p1 = ph[k]; k1 = k; } else if (e < e2) { e2 = e; p2 = ph[k]; k2 = k; }
    }
    // The twin re-reads the two borders' cells: keeping their normals in the loop, or indexing s by k1, costs about 0.3x
    // the whole background on a Mac.
    float2 n1 = 0, n2 = 0;
    if (plus) {
        int2 c1 = clamp(g + int2(k1 % 3 - 1, k1 / 3 - 1), 0, 21), c2 = clamp(g + int2(k2 % 3 - 1, k2 / 3 - 1), 0, 21);
        float4 b1 = cells[c1.y * 22 + c1.x], b2 = cells[c2.y * 22 + c2.x];
        p1 = b1.z;
        p2 = b2.z;
        n1 = normalize(b1.xy - a);
        n2 = normalize(b2.xy - a);
    }
    // The twin's are all low in blue, so summed glows stay off white.
    const float3 core = plus ? float3(1.0, 0.0, 0.03) : float3(1.0, 0.0061, 0.048);
    const float3 glow = plus ? float3(0.72, 0.0, 0.051) : core;
    const float3 scan = plus ? float3(0.62, 0.40, 0.0) : float3(0.365, 0.030, 1.0);
    // The picture's neon(): a 0.0042 stroke under blooms of 0.004 at 0.8 and 0.012 at 0.25. Each crack's breath is
    // symmetric in its two cells, so it breathes as one line.
    float3 c = core * saturate((0.0021 * pulse.x - e1) / px + 0.5);
    for (int k = 0; k < 2; k++) {
        float e = k == 0 ? e1 : e2, breath = 0.5 + 0.5 * sin(6.2832 * (t / 5.0 + pa + (k == 0 ? p1 : p2)));
        c += glow * (0.335 * exp(-e * e / 3.2e-5) + 0.035 * exp(-e * e / 2.88e-4)) * (0.35 + 0.9 * breath);
    }
    if (plus) {
        // Crazing: a hairline where the two nearest borders are equidistant (the cell's medial axis), from every corner
        // inward to meet the others, so it never ends in the open. Each cell's strength is hashed from its breath phase.
        float sk = (e2 - e1) / max(length(n1 - n2), 1e-3);
        c += float3(0.5, 0.0, 0.03) * (0.3 + 0.7 * fract(pa * 17.0)) * saturate((0.0007 * pulse.x - sk) / px + 0.5);
    }
    if (pane != 0) {
        // Scan lines 0.02 apart at the pane's own angle, dashed [0.03, 0.008, 0.012, 0.02], sweeping across it at
        // 0.01/s the way the pane's sign says. In the twin a third sweep so, a third stutter once a second, with the
        // heartbeat, at 0.4 of the speed (the lurch peaks at the old speed; over the twin's 60 s wrap they move 12
        // whole spacings), and a third are dead: still and dim.
        float angle = abs(pane);
        float fate = plus ? fract(pa * 23.0 + angle * 3.0) : 1.0;
        float ts = fate < 0.33 ? 0.0 : fate < 0.66 ? 0.4 * (floor(t) + smoothstep(0.0, 0.6, fract(t))) : t;
        float live = fate < 0.33 ? 0.3 : 1.0;
        float2 r = p - a, d = float2(cos(angle), sin(angle));
        float across = dot(r, float2(-d.y, d.x)) + sign(pane) * 0.01 * ts;
        float line = abs(fract(across / 0.02 + 0.5) - 0.5) * 0.02;
        float x = fract((dot(r, d) + angle / M_PI_F * 0.07) / 0.07) * 0.07;
        float dash = min(min(max(-x, x - 0.03), max(0.038 - x, x - 0.05)), 0.07 - x);
        float sd = max(line - 0.0015 * pulse.x, dash);
        float haze = 0.24 * exp(-max(sd, 0.0) * max(sd, 0.0) / 3.2e-5) + 0.0225;
        c += scan * live * (saturate(-sd / px + 0.5) + haze * (plus ? 0.85 : 1.0) * (0.35 + 0.9 * (0.5 + 0.5 * sin(6.2832 * (t / 5.0 + 2.0 * pa)))));
    }
    return c * pulse.y;
}

// The layer is gamma-encoded like the baked pictures, so the square root takes the field back out of linear light.
// The corners are clipped away: past the glass and the taps' reach, skip a fifth of the square.
[[ stitchable ]] half4 glass(float2 pos, float radius, float px, device const float *cells, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(cracks<false>(p, px, (device const packed_float4 *)cells, t, 1.0))), 1.0h);
}

[[ stitchable ]] half4 glassPlus(float2 pos, float radius, float px, device const float *cells, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    float2 pulse = throb(heartbeat(p, t, cells + count - 33 * 33));
    return half4(half3(sqrt(cracks<true>(p, px, (device const packed_float4 *)cells, t, pulse))), 1.0h);
}
