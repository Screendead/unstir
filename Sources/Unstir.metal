// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// twists: n entries of (rod centre x, y, disc radius, angle) in tank-normalized units, bottom of the stack first.
// Tank.profile / Tank.twist in Twist.swift are the Swift copy the tests check; the tests do not reach this shader.
[[ stitchable ]] half4 unstir(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                              device const float *twists, int count, float n, float fourTaps, float plateau,
                              float scale, float haze, float3 wave) {
    // Four taps a quarter device pixel off centre, each through the whole inverse chain: the stretching is in the
    // map, so a filament thinner than a pixel keeps its light as coverage. Past fourTaps entries only the diagonal pair
    // runs: on an iPhone 13 Pro Max, hex's hub and a neighbour alternating hold 120 Hz at 31 entries with four taps, not 32.
    int stride = n > fourTaps ? 3 : 1;
    float3 acc = 0;
    for (int j = 0; j < 4; j += stride) {
        float2 q = (pos + (float2(j & 1, j >> 1) - 0.5) * 0.5 / scale - centre) / radius;
        for (int i = min(int(n), count / 4) - 1; i >= 0; i--) {
            float2 c = float2(twists[4 * i], twists[4 * i + 1]);
            float2 d = q - c;
            float s = length(d) / twists[4 * i + 2];
            // Outside the rod's disc the map is exactly the identity.
            if (s >= 1.0) continue;
            float a = -twists[4 * i + 3] * (1.0 - smoothstep(plateau, 1.0, s));
            float cs = cos(a), sn = sin(a);
            q = c + float2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
        }
        float3 s = float3(layer.sample(centre + q * radius).rgb);
        // wave = (x, y, radius) in tank units, radius < 0 when off; it only brightens what is already lit.
        float e = (length(q - wave.xy) - wave.z) / 0.1;
        float w = wave.z < 0.0 ? 0.0 : 2.5 * exp(-e * e);
        // The layer is gamma-encoded (a 50% grey samples as 0.50), so squared is near linear light and a filament a
        // quarter of a pixel wide keeps its brightness.
        float3 s2 = s * s;
        // The white term scales with the pixel's own brightest channel: saturated lines flare white too, black stays black.
        acc += s2 * (1.0 + w) + 0.5 * w * max(s2.r, max(s2.g, s2.b));
    }
    float3 c = sqrt(acc / (stride == 1 ? 4.0 : 2.0));
    return half4(half3(mix(c, float3(dot(c, float3(0.299, 0.587, 0.114))), haze)), 1.0h);
}


