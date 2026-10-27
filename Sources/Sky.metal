// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The ephemeris, in linear light at p: an orbit chart. data is Picture.ephemeris: 9 x 9 cells 0.32 across from
// (-1.44, -1.44), a star each with up to three orbits, 7 float4s a star. Each orbit is a hairline ellipse with the star
// at a focus, its planet a bright bead trailing light back along it; orbits of neighbouring stars cross. Every orbit
// lies at a random tilt, so a turned disc looks as plausible as the chart; only its seam bends the ellipses. A star
// whose furthest orbit is out of reach, and an orbit p is far outside, are skipped: most of the nine are.
static float3 chart(float2 p, float px, device const float4 *stars, float t) {
    const float pitch = 0.32, origin = -1.44, tau = 6.2831853, margin = 0.008;
    const int n = 9;
    int2 g = int2(floor((p - origin) / pitch));
    float3 c = 0;
    // The early-out beyond the tank keeps g within 1...7, so the search needs no clamp.
    for (int k = 0; k < 9; k++) {
        int base = 7 * ((g.y + k / 3 - 1) * n + g.x + k % 3 - 1);
        float4 s = stars[base];
        float2 r = p - s.xy;
        float d2 = dot(r, r);
        if (d2 > (s.w + margin) * (s.w + margin)) continue;
        // The star: a point with a soft halo, amber to white-blue by its temperature, twinkling on its own phase. Its
        // orbits take a little of its colour, so each system reads as one.
        float3 hue = mix(float3(1.0, 0.55, 0.18), float3(0.55, 0.75, 1.0), s.z);
        float3 ink = mix(float3(1.0, 0.72, 0.32), hue, 0.45);
        if (d2 < 0.0036) {
            float tw = 0.75 + 0.25 * sin(tau * (fract(s.z * 37.0) + t / 5.0));
            c += hue * tw * (1.6 * saturate((0.0034 - sqrt(d2)) / px + 0.5) + 0.25 * exp(-d2 / 6e-5) + 0.04 * exp(-d2 / 6e-4));
        }
        for (int o = 0; o < 3; o++) {
            float4 e = stars[base + 1 + 2 * o], f = stars[base + 2 + 2 * o];
            if (e.z <= 0.0) break;
            float2 q = p - e.xy;
            // Outside its circumcircle or inside its incircle, p is off the orbit.
            float2 ab = float2(e.z, abs(e.w));
            float qq = dot(q, q);
            if (qq > (ab.x + margin) * (ab.x + margin) || qq < (ab.y - margin) * (ab.y - margin)) continue;
            // In the ellipse's frame, then scaled to a circle: a distance off the ellipse good to first order.
            float2 u = float2(dot(q, f.xy), f.x * q.y - f.y * q.x), w = u / ab;
            float lw = length(w);
            float d = abs(lw - 1.0) / max(length(w / (ab * max(lw, 1e-4))), 1e-4);
            if (d > margin) continue;
            // How far round from the planet p lies, back the way it came: cos and sin of the angle between them.
            float2 m = w / max(lw, 1e-4);
            float cd = dot(m, f.zw), sd = (f.z * m.y - f.w * m.x) * sign(e.w);
            float tr = saturate(0.5 + 0.5 * cd), tr2 = tr * tr, trail = tr2 * tr2 * tr2 * saturate(-4.0 * sd);
            float glow = 0.4 + 0.6 * fract(e.x * 53.0 + e.y * 31.0);
            // Its haze falls to nothing well inside the margin, so skipping beyond it leaves no edge.
            float h = saturate(1.0 - d * d / 1.6e-5), haze = h * h * h;
            float line = saturate((0.0015 - d) / px + 0.5);
            // The outermost orbit is dashed, as a chart marks the furthest of a system.
            if (o == 2) line *= step(0.35, fract(atan2(m.y, m.x) * floor(e.z * 120.0) / tau));
            c += ink * (line * (0.7 - 0.15 * float(o)) + 0.08 * haze) * glow
               + float3(1.0, 0.85, 0.6) * trail * (line * 0.9 + 0.12 * haze);
            // The planet itself, a bead on the line.
            float2 bead = ab * f.zw - u;
            float b2 = dot(bead, bead);
            float bh = saturate(1.0 - b2 / 1.6e-4);
            c += float3(0.7, 0.95, 1.0) * (saturate((0.0028 - sqrt(b2)) / px + 0.5) + 0.06 * bh * bh * bh);
        }
    }
    return c;
}

[[ stitchable ]] half4 ephemeris(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(chart(p, px, (device const float4 *)data, t))), 1.0h);
}
