// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The inside of a hollow (docs/slope.md, 8.2): still dark water between two jambs of pale stone, a ledge that juts
// from the leading jamb at depth `parts.x`, a floor at `parts.y`, and the cover's light falling from `source` in three
// soft beams of the pack's colours. It is Slope.metal's slopeHollow with the ledge and the floor set free, since the
// inside is as tall as its words and scrolls, and with Escapement's page (8.6): at `parts.z` the same rock engraved in
// ink on bone, an outline that thickens on its shaded side and hatching under each lip, no fills, no light.
// SlopePack.swift's HollowGround holds the same floor and ledge, for what rests on them.

static float packHash(float2 p) {
    float3 q = fract(float3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

static float packBell(float x) { return exp(-x * x); }
static float packStep(float x) { return smoothstep(-0.7, 0.7, x); }
static float packHatch(float2 p, float fade) {
    return 1.0 - smoothstep(0.25, 0.6, abs(fract((p.x + p.y) / 5.0) - 0.5) * 2.0 + fade);
}

[[ stitchable ]] half4 slopeInside(float2 pos, half4 color, float2 size, float scale, float4 parts, float2 source,
                                   float3 beam0, float3 beam1, float3 beam2) {
    float2 p = float2(pos.x * 440.0 / size.x, pos.y);
    float h = size.y, ledgeY = parts.x, floorY = parts.y, paper = parts.z;
    float3 c = float3(0.02, 0.024, 0.036) + float3(0.03, 0.035, 0.05) * (1.0 - pos.y / h);
    float2 v = pos - source;
    float ang = atan2(v.x, v.y);
    float fall = smoothstep(0.0, 40.0, v.y) * exp(-length(v) / 520.0);
    c += (beam0 * packBell((ang + 0.19) / 0.085) + beam1 * packBell(ang / 0.085) + beam2 * packBell((ang - 0.19) / 0.085)) * fall * 0.17;
    // The jambs close in toward the floor.
    float low = smoothstep(floorY - 202.0, floorY + 114.0, pos.y);
    // The leading jamb stands back at the top, where the way back is written.
    float jl = (20.0 + 12.0 * sin(pos.y * 0.011 + 1.0) + 5.0 * sin(pos.y * 0.029)) * mix(0.4, 1.0, smoothstep(70.0, 230.0, pos.y)) + 26.0 * low;
    float jr = 440.0 - (22.0 + 12.0 * sin(pos.y * 0.0093 + 3.0) + 5.0 * sin(pos.y * 0.031 + 1.0)) - 26.0 * low;
    float fl = floorY + 8.0 * sin(p.x * 0.012 + 0.5);
    float xr = 118.0 - p.x, f = pos.y - ledgeY - 2.5 * sin(p.x * 0.05 + 1.0);
    float top = 4.0 * pow(1.0 - smoothstep(0.0, 26.0, xr), 2.0);
    float bot = top + 30.0 * pow(saturate(xr / 96.0), 1.5);
    float ledge = packStep(f - top) * packStep(bot - f) * packStep(xr);
    float lit = 0.55 + 0.9 * exp(-length(v) / 380.0);
    float3 stone = float3(0.105, 0.108, 0.125);
    float3 rc = stone * 0.8 * lit;
    rc = mix(rc, stone * 0.6 * lit, max(packStep(jl * 0.5 - p.x), packStep(p.x - (440.0 - (440.0 - jr) * 0.5))));
    rc += stone * exp(-max(min(jl - p.x, p.x - jr), 0.0) / 10.0) * 0.25 * step(pos.y, fl);
    float under = max(pos.y - fl, 0.0);
    float3 fc = stone * mix(1.25, 0.55, saturate(under / 70.0)) + float3(0.8, 0.84, 0.9) * (exp(-under / 2.6) * 0.22 + exp(-under / 14.0) * 0.07);
    rc = mix(rc, fc, packStep(pos.y - fl));
    float3 lc = stone * mix(1.5, 0.7, saturate((f - top) / max(bot - top, 1.0))) + float3(0.8, 0.84, 0.9) * exp(-max(f - top, 0.0) / 2.4) * 0.3;
    rc = mix(rc, lc, ledge);
    float rock = max(max(packStep(jl - p.x), packStep(p.x - jr)), max(packStep(pos.y - fl), ledge));
    c = mix(c, rc, rock);
    float2 e = (pos / size - 0.5) * float2(1.1, 0.5);
    c *= 1.0 - dot(e, e) * 0.5;
    if (paper > 0.0) {
        float3 bone = float3(0.953, 0.918, 0.847), ink = float3(0.102, 0.102, 0.102);
        float above = 1.0 - packStep(pos.y - fl);
        // The leading jamb faces away from the sun: a heavy line and deep hatching. The trailing one is lit.
        float dl = p.x - jl, dr = jr - p.x;
        float line = (1.0 - smoothstep(0.9, 1.9, abs(dl))) * above;
        line = max(line, (1.0 - smoothstep(0.4, 1.1, abs(dr))) * above);
        float hatch = packStep(-dl) * above * packHatch(p, saturate(-dl / 26.0) * 0.75);
        hatch = max(hatch, packStep(-dr) * above * packHatch(float2(-p.x, p.y), 0.45 + saturate(-dr / 9.0) * 0.5) * 0.7);
        // The floor: its lit top a fine line, short strokes under it.
        line = max(line, (1.0 - smoothstep(0.4, 1.1, abs(pos.y - fl))) * packStep(dl) * packStep(dr));
        hatch = max(hatch, packStep(pos.y - fl) * packStep(dl) * packStep(dr) * packHatch(p, 0.25 + saturate(under / 20.0)) * 0.8);
        // The ledge: a fine top, a heavy underside, hatched toward it.
        float out = packStep(dl + 1.0) * packStep(xr);
        line = max(line, (1.0 - smoothstep(0.4, 1.1, abs(f - top))) * out * packStep(bot - f + 1.0));
        line = max(line, (1.0 - smoothstep(0.9, 1.9, abs(f - bot))) * out * packStep(f - top + 1.0));
        hatch = max(hatch, ledge * packStep(dl) * packHatch(p, saturate((bot - f) / max(bot - top, 1.0)) * 0.9));
        c = mix(c, mix(bone, ink, max(line, hatch * 0.8) * 0.9), paper);
    }
    float2 pixel = floor(pos * scale);
    float n = packHash(pixel) + packHash(pixel + 61.7) - 1.0;
    return half4(half3(saturate(c + n / 255.0)), 1.0h);
}
