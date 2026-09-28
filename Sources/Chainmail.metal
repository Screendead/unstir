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

static float weight(uint code) { return (code & (1u << 18)) != 0u ? 0.0028 : 0.0018; }

// A link's brightness at r from its centre: a dim shine turning around it once or twice a period, its own way, and a
// glow breath.
static float2 light(uint code, float2 r, float t) {
    float dir = (code & 4u) != 0u ? 1.0 : -1.0;
    float turns = (code & 8u) != 0u ? 2.0 : 1.0;
    float ph = float((code >> 4) & 127u) / 128.0, br = float((code >> 11) & 127u) / 128.0;
    float a = atan2(r.y, r.x) / 6.2832;
    float shine = 0.5 + 0.5 * cos(6.2832 * (a - dir * turns * t / 20.0 - ph));
    float breath = 0.5 + 0.5 * sin(6.2832 * (t / 5.0 + br));
    return float2(0.8 + 0.2 * shine * shine, 0.35 + 0.8 * breath);
}

// One link's light at p, a from its ring: ember #FF7A1A or blood #FF1438 by its dye blot. Only one link lights a pixel
// away from tangencies, so strokes and glows never sum toward yellow-white.
static float3 link(float4 cell, float2 p, float a, float px, float t) {
    uint code = uint(cell.w);
    float2 l = light(code, p - cell.xy, t);
    float3 colour = (code & 1u) != 0u ? float3(1.0, 0.0061, 0.048) : float3(1.0, 0.229, 0.0104);
    return colour * l.x * (saturate((weight(code) - a) / px + 0.5) + (0.3 * exp(-a * a / 3.2e-5) + 0.02 * exp(-a * a / 2.0e-4)) * l.y);
}

// The twin's: 1 for the one link in six that still burns, picked by the breath-phase bits so burning links scatter
// independently of the dye blots; 0 for a corroded one.
static float hot(uint code) { return ((code >> 11) & 127u) < 22u ? 1.0 : 0.0; }

// The twin's wire at u turns around a link: x its half-width, y the arc length to its nearest barb (4 to 7 around the
// ring). A burning link keeps the clean wire. A corroded one swells 0.0018, with lumps two or three times around the ring
// and a knot at each barb, so it is never thinner than a burning one. The heartbeat swells either by grow.
static float2 wire(float4 cell, float u, float grow) {
    uint code = uint(cell.w);
    float m = float(4u + ((code >> 19) & 3u));
    float s = abs(fract(u * m + float((code >> 4) & 127u) / 128.0) - 0.5) * 6.2832 * cell.z / m;
    float v = abs(fract(float(2u + ((code >> 2) & 1u)) * u + float((code >> 21) & 7u) / 8.0) - 0.5) * 2.0;
    float swell = 0.0018 + 0.0022 * v * v * (3.0 - 2.0 * v) + 0.0012 * saturate(1.0 - s / 0.008);
    return float2((weight(code) + (1.0 - hot(code)) * swell) * grow, s);
}

// A barb's coverage at s along the wire from it and a from the ring: an X of two tapered spikes crossing the wire at 60
// degrees, reaching 0.015 out on both sides, grow times as thick. ipx is 1 / px.
static float barb(float s, float a, float ipx, float grow) {
    float along = 0.5 * s + 0.866 * a, across = abs(0.866 * s - 0.5 * a);
    float w = (0.003 - 0.0018 * saturate(along / 0.017)) * grow;
    return saturate((w - across) * ipx + 0.5) * saturate((0.017 - along) * ipx + 0.5);
}

// The twin's link at a from its ring, with its wire w there: a burning one bare crimson wire with a wide glow, a
// corroded one dark rust (two shades, by dye blot), barbed, faintly glowing. fade takes the barbs out where a third link
// nears. The heartbeat swells its barbs by pulse.x and brightens it by pulse.y. Branch-free: most SIMD groups hold both
// kinds of link.
static float3 rust(float4 cell, float a, float ipx, float2 w, float fade, float2 pulse) {
    uint code = uint(cell.w);
    float h = hot(code);
    float cover = max(saturate((w.x - a) * ipx + 0.5), (1.0 - h) * fade * barb(w.y, a, ipx, pulse.x));
    float3 core = mix((code & 1u) != 0u ? float3(0.42, 0.021, 0.034) : float3(0.52, 0.056, 0.022), float3(1.0, 0.0061, 0.048), h);
    // The wide glow is exp(-a^2 / 1.6e-4); its sixth power is the near one, exp(-a^2 / 2.7e-5).
    float wide = exp(-a * a / 1.6e-4), near = wide * wide;
    near *= near * near;
    return core * pulse.y * (cover + mix(0.136, 0.51, h) * near + 0.085 * h * wide);
}

// Chainmail, in linear light at p: links scattered at random, each interlocked with every link it crosses. Of two
// crossing links, the one whose crossing lies to the left of the line from its centre to the other's passes over, so at
// a pair's two crossings the links take turns (a rule a rotation keeps, so a turned core shows nothing). cells is
// Picture.links: 18 x 18 cells 0.14 across from (-1.26, -1.26), each (centre x, y, radius, code).
// The twin: most links corroded to thick, pitted, barbed rust, a scattered few still burning crimson, all
// swelling by pulse.x and brightening by pulse.y. Its glow never widens, so the 0.045 below holds.
template <bool twin>
static float3 links(float2 p, float px, device const packed_float4 *cells, float t, float2 pulse) {
    const float pitch = 0.14, origin = -1.26;
    const int n = 18;
    int2 g = int2(floor((p - origin) / pitch));
    // The two links nearest p by distance to the ring, and the third distance.
    float a1 = 1e9, a2 = 1e9, a3 = 1e9;
    int i1 = 0, i2 = 0;
    for (int k = 0; k < 9; k++) {
        int2 c = clamp(g + int2(k % 3 - 1, k / 3 - 1), 0, n - 1);
        int i = c.y * n + c.x;
        float4 cell = cells[i];
        float a = abs(distance(p, cell.xy) - cell.z);
        if (a < a1) { a3 = a2; a2 = a1; i2 = i1; a1 = a; i1 = i; }
        else if (a < a2) { a3 = a2; a2 = a; i2 = i; }
        else a3 = min(a3, a);
    }
    // Past 0.045 from a ring its glow is under a quarter of an 8-bit step.
    if (a1 > 0.045) return 0.0;
    float4 e1 = cells[i1];
    // The twin works out each wire before the crossing, so the pass-under gap clears a swollen wire.
    float ipx = 1.0 / px;
    float2 w1 = twin ? wire(e1, atan2(p.y - e1.y, p.x - e1.x) * 0.15915, pulse.x) : 0.0;
    float3 c = twin ? rust(e1, a1, ipx, w1, 1.0, pulse) : link(e1, p, a1, px, t);
    if (a2 > 0.045) return c;
    // Near the line between the centres (links almost tangent) neither is cut, so which passes over never jumps.
    float4 e2 = cells[i2];
    float2 w2 = twin ? wire(e2, atan2(p.y - e2.y, p.x - e2.x) * 0.15915, pulse.x) : 0.0;
    float2 m = e2.xy - e1.xy;
    float side = (m.x * (p.y - e1.y) - m.y * (p.x - e1.x)) / max(length(m), 1e-5);
    bool oneOver = side > 0.0;
    float aTop = oneOver ? a1 : a2;
    float hwTop = twin ? (oneOver ? w1.x : w2.x) : weight(uint(oneOver ? e1.w : e2.w));
    // The low link fades out over 0.01 as it nears the top one, so it passes under rather than being cut. The pair
    // drawn changes where a third link is as near as the second, so the gap fades out there instead of snapping.
    float third = smoothstep(0.0, 0.006, a3 - a2);
    float keep = 1.0 - smoothstep(0.004, 0.012, abs(side)) * (1.0 - smoothstep(hwTop + 0.003, hwTop + 0.013, aTop)) * third;
    float3 d = twin ? rust(e2, a2, ipx, w2, third, pulse) : link(e2, p, a2, px, t);
    return oneOver ? c + keep * d : keep * c + d;
}

[[ stitchable ]] half4 chainmail(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(links<false>(p, px, (device const packed_float4 *)data, t, 1.0))), 1.0h);
}

[[ stitchable ]] half4 chainmailTwin(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    float2 pulse = throb(heartbeat(p, t, data + count - 33 * 33));
    return half4(half3(sqrt(links<true>(p, px, (device const packed_float4 *)data, t, pulse))), 1.0h);
}
