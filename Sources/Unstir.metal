// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// A lens's flow from radius u < a (its rigid core) for time t and rim sharpness e: Tank.lensFlow's copy.
static float lensFlow(float u, float t, float a, float e) {
    return a * pow(1.0 + (pow(a / u, e) - 1.0) * exp(-e * t), -1.0 / e);
}

// Entry e's inverse map at q: (rod centre x, y, disc radius, angle), as `twists` below lays it out.
static float2 unmap(float2 q, device const float *e, float plateau, float swirlPlateau, float lensEdge) {
    float2 c = float2(e[0], e[1]);
    float2 d = q - c;
    float z = e[2];
    float s = length(d) / abs(z);
    // Outside the rod's disc the map is exactly the identity.
    if (s >= 1.0) return q;
    if (z < 0.0) {
        // A lens moves nothing outside its rigid core.
        return s < plateau && s > 1e-6 ? c + d * (lensFlow(s, -e[3], plateau, lensEdge) / s) : q;
    }
    // A knob turns its core and lets go towards its edge; the swirl holds the glass's edge and lets go towards its centre.
    float t = smoothstep(z >= 1.0 ? swirlPlateau : plateau, 1.0, s);
    float a = -e[3] * (z >= 1.0 ? t : 1.0 - t);
    float cs = cos(a), sn = sin(a);
    return c + float2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
}

// The top n entries' inverses, each on the points of the channels its mask (a Channels raw value) holds.
static void chains(int n, device const float *twists, device const float *masks, float plateau, float swirlPlateau,
                   float lensEdge, thread float2 &qr, thread float2 &qg, thread float2 &qb) {
    for (int i = n - 1; i >= 0; i--) {
        int m = int(masks[i]);
        device const float *e = twists + 4 * i;
        if (m & 1) qr = unmap(qr, e, plateau, swirlPlateau, lensEdge);
        if (m & 2) qg = unmap(qg, e, plateau, swirlPlateau, lensEdge);
        if (m & 4) qb = unmap(qb, e, plateau, swirlPlateau, lensEdge);
    }
}

// A tap's light: s the sampled colour, p the tap in tank units on the screen.
// wave = (x, y, radius) in tank units on the screen, radius < 0 when off; it only brightens what is already lit.
static float3 lit(float3 s, float2 p, float3 wave) {
    float e = (length(p - wave.xy) - wave.z) / 0.1;
    float w = wave.z < 0.0 ? 0.0 : 2.5 * exp(-e * e);
    // The layer is gamma-encoded (a 50% grey samples as 0.50), so squared is near linear light and a filament a
    // quarter of a pixel wide keeps its brightness.
    float3 s2 = s * s;
    // The white term scales with the pixel's own brightest channel: saturated lines flare white too, black stays black.
    return s2 * (1.0 + w) + 0.5 * w * max(s2.r, max(s2.g, s2.b));
}

static half4 finish(float3 acc, int stride, float haze) {
    float3 c = sqrt(acc / (stride == 1 ? 4.0 : 2.0));
    return half4(half3(mix(c, float3(dot(c, float3(0.299, 0.587, 0.114))), haze)), 1.0h);
}

// twists: n entries of (rod centre x, y, disc radius, angle) in tank-normalized units, bottom of the stack first. A
// lens's entry has a negative radius and its flow's time (steps * Tank.lensRate) for the angle.
// Tank.profile / Tank.twist / Tank.lens in Twist.swift are the Swift copy the tests check; the tests reach only
// lensFlow and chains here.
// plateau is a knob's, swirlPlateau a disc's of radius 1 or more (the swirl's, or the breath's through it).
// turn: the glass's clockwise turn about the centre. The stack names the glass's own rods, so the point turns back
// first. Swift has no copy of the turn: the seized-* harness shots pin its sign.
[[ stitchable ]] half4 unstir(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                              device const float *twists, int count, float n, float fourTaps, float plateau,
                              float swirlPlateau, float lensEdge, float scale, float haze, float3 wave, float turn) {
    // Four taps a quarter device pixel off centre, each through the whole inverse chain: the stretching is in the
    // map, so a filament thinner than a pixel keeps its light as coverage. Past fourTaps entries only the diagonal pair
    // runs: on an iPhone 13 Pro Max, hex's hub and a neighbour alternating hold 120 Hz at 31 entries with four taps, not 32.
    int stride = n > fourTaps ? 3 : 1;
    float ct = cos(turn), st = sin(turn);
    float3 acc = 0;
    for (int j = 0; j < 4; j += stride) {
        float2 p = (pos + (float2(j & 1, j >> 1) - 0.5) * 0.5 / scale - centre) / radius;
        float2 q = float2(p.x * ct + p.y * st, p.y * ct - p.x * st);
        for (int i = min(int(n), count / 4) - 1; i >= 0; i--) q = unmap(q, twists + 4 * i, plateau, swirlPlateau, lensEdge);
        acc += lit(float3(layer.sample(centre + q * radius).rgb), p, wave);
    }
    return finish(acc, stride, haze);
}

// Prism's: each of red, green and blue sampled through its own word, the entries whose mask (masks[i], a Channels raw
// value) holds it. cost is the work in entries, against fourTaps as n is above.
[[ stitchable ]] half4 unstirChannels(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                                      device const float *twists, int count, device const float *masks, int maskCount,
                                      float n, float cost, float fourTaps, float plateau, float swirlPlateau,
                                      float lensEdge, float scale, float haze, float3 wave, float turn) {
    int stride = cost > fourTaps ? 3 : 1;
    float ct = cos(turn), st = sin(turn);
    float3 acc = 0;
    for (int j = 0; j < 4; j += stride) {
        float2 p = (pos + (float2(j & 1, j >> 1) - 0.5) * 0.5 / scale - centre) / radius;
        float2 q = float2(p.x * ct + p.y * st, p.y * ct - p.x * st);
        float2 qr = q, qg = q, qb = q;
        chains(min(int(n), min(count / 4, maskCount)), twists, masks, plateau, swirlPlateau, lensEdge, qr, qg, qb);
        float3 s = float3(layer.sample(centre + qr * radius).r, layer.sample(centre + qg * radius).g,
                          layer.sample(centre + qb * radius).b);
        acc += lit(s, p, wave);
    }
    return finish(acc, stride, haze);
}


