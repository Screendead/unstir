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

// Nightmare+: the nightmare picture's cracked glass, alive, in linear light at p (tank units, y down); px is a device
// pixel in tank units. cells is Picture.cells: 22 x 22 cells 0.11 across from (-1.21, -1.21), each (seed x, y, breath
// phase, pane). Crack and pane glow breathe each on their own phase: a wave shared across the tank would show a turned
// disc which way it turned. The fastest thing at any point is a scan line sweeping past every 2 s.
static float3 cracks(float2 p, float px, device const packed_float4 *cells, float t) {
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
    for (int k = 0; k < 9; k++) {
        float2 m = s[k] - a;
        float l = length(m);
        if (l < 1e-6) continue;
        float e = dot(0.5 * (a + s[k]) - p, m) / l;
        if (e < e1) { e2 = e1; p2 = p1; e1 = e; p1 = ph[k]; } else if (e < e2) { e2 = e; p2 = ph[k]; }
    }
    const float3 blood = float3(1.0, 0.0061, 0.048), violet = float3(0.365, 0.030, 1.0);
    // The picture's neon(): a 0.0042 stroke under blooms of 0.004 at 0.8 and 0.012 at 0.25. Each crack's breath is
    // symmetric in its two cells, so it breathes as one line.
    float3 c = blood * saturate((0.0021 - e1) / px + 0.5);
    for (int k = 0; k < 2; k++) {
        float e = k == 0 ? e1 : e2, breath = 0.5 + 0.5 * sin(6.2832 * (t / 5.0 + pa + (k == 0 ? p1 : p2)));
        c += blood * (0.335 * exp(-e * e / 3.2e-5) + 0.035 * exp(-e * e / 2.88e-4)) * (0.35 + 0.9 * breath);
    }
    if (pane != 0) {
        // Scan lines 0.02 apart at the pane's own angle, dashed [0.03, 0.008, 0.012, 0.02], sweeping across it at 0.01/s
        // the way the pane's sign says.
        float angle = abs(pane);
        float2 r = p - a, d = float2(cos(angle), sin(angle));
        float across = dot(r, float2(-d.y, d.x)) + sign(pane) * 0.01 * t;
        float line = abs(fract(across / 0.02 + 0.5) - 0.5) * 0.02;
        float x = fract((dot(r, d) + angle / M_PI_F * 0.07) / 0.07) * 0.07;
        float dash = min(min(max(-x, x - 0.03), max(0.038 - x, x - 0.05)), 0.07 - x);
        float sd = max(line - 0.0015, dash);
        float haze = 0.24 * exp(-max(sd, 0.0) * max(sd, 0.0) / 3.2e-5) + 0.0225;
        c += violet * (saturate(-sd / px + 0.5) + haze * (0.35 + 0.9 * (0.5 + 0.5 * sin(6.2832 * (t / 5.0 + 2.0 * pa)))));
    }
    return c;
}

// The layer is gamma-encoded like the baked pictures, so the square root takes the field back out of linear light.
[[ stitchable ]] half4 nightmarePlus(float2 pos, float radius, float px, device const float *cells, int count, float t) {
    float2 p = pos / radius - 1.0;
    // The corners are clipped away: past the glass and the taps' reach, skip a fifth of the square.
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(cracks(p, px, (device const packed_float4 *)cells, t))), 1.0h);
}
