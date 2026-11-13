// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// A lens's flow from radius u < a (its rigid core) for time t and rim sharpness e: Tank.lensFlow's copy.
static float lensFlow(float u, float t, float a, float e) {
    return a * pow(1.0 + (pow(a / u, e) - 1.0) * exp(-e * t), -1.0 / e);
}

// Entry e's inverse map at q: (rod centre x, y, disc radius, angle), as `twists` below lays it out. The entry comes
// already read, once for every point it moves, and a point past its disc is cleared by the squared distance, before
// the root and the divide: with the taps in step (tapsThrough) that takes about a third off the twist pass on the
// Mac's GPU (2026-11-12), and the gain is in this arrangement, not in less arithmetic, so time a change to it
// (scripts/twist-oracle.sh time).
static float2 unmap(float2 q, float4 e, float plateau, float swirlPlateau, float lensEdge) {
    float2 c = e.xy;
    float2 d = q - c;
    float z = e.z;
    // Past the disc by more than rounding, where the test below finds the same.
    if (dot(d, d) > z * z * 1.00001) return q;
    float s = length(d) / abs(z);
    // Outside the rod's disc the map is exactly the identity.
    if (s >= 1.0) return q;
    if (z < 0.0) {
        // A lens moves nothing outside its rigid core.
        return s < plateau && s > 1e-6 ? c + d * (lensFlow(s, -e.w, plateau, lensEdge) / s) : q;
    }
    // A knob turns its core and lets go towards its edge; the swirl holds the glass's edge and lets go towards its centre.
    float t = smoothstep(z >= 1.0 ? swirlPlateau : plateau, 1.0, s);
    float a = -e.w * (z >= 1.0 ? t : 1.0 - t);
    float cs = cos(a), sn = sin(a);
    return c + float2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
}

static float4 entry(device const float *twists, int i) {
    return float4(twists[4 * i], twists[4 * i + 1], twists[4 * i + 2], twists[4 * i + 3]);
}

// The top n entries' inverses, each on the points of the channels its mask (a Channels raw value) holds.
static void chains(int n, device const float *twists, device const float *masks, float plateau, float swirlPlateau,
                   float lensEdge, thread float2 &qr, thread float2 &qg, thread float2 &qb) {
    for (int i = n - 1; i >= 0; i--) {
        int m = int(masks[i]);
        float4 e = entry(twists, i);
        if (m & 1) qr = unmap(qr, e, plateau, swirlPlateau, lensEdge);
        if (m & 2) qg = unmap(qg, e, plateau, swirlPlateau, lensEdge);
        if (m & 4) qb = unmap(qb, e, plateau, swirlPlateau, lensEdge);
    }
}

// Whether every tap of the pixel at pos lies past the glass's edge, with room for rounding. Every disc lies within
// the glass (testEveryDiscLiesWithinTheGlass), so each entry would find such a pixel the identity, and none runs.
static bool pastTheGlass(float2 pos, float2 centre, float radius, float scale) {
    float2 pc = (pos - centre) / radius;
    float edge = 1.0 + 0.5 / (scale * radius);
    return dot(pc, pc) > edge * edge;
}

// A pixel's taps: p on the screen and q through the chain, both in tank units. Each a field of its own: an array
// here cost a frame of four entries a third more.
struct Taps {
    float2 p0, p1, p2, p3, q0, q1, q2, q3;
};

static float2 tapOnScreen(float2 pos, int j, float2 centre, float radius, float scale) {
    return (pos + (float2(j & 1, j >> 1) - 0.5) * 0.5 / scale - centre) / radius;
}

// The taps of the pixel at pos, a quarter device pixel off its centre, each turned back by the glass's turn and then
// through the top `entries` of the chain: in step, entry by entry, so each entry is read once for all of them. Past
// the four-tap budget (stride 3) only the diagonal pair, 0 and 3, runs.
static Taps tapsThrough(float2 pos, float2 centre, float radius, device const float *twists, int entries, int stride,
                        float plateau, float swirlPlateau, float lensEdge, float scale, float turn) {
    Taps taps;
    float ct = cos(turn), st = sin(turn);
    taps.p0 = tapOnScreen(pos, 0, centre, radius, scale);
    taps.p1 = tapOnScreen(pos, 1, centre, radius, scale);
    taps.p2 = tapOnScreen(pos, 2, centre, radius, scale);
    taps.p3 = tapOnScreen(pos, 3, centre, radius, scale);
    if (pastTheGlass(pos, centre, radius, scale)) entries = 0;
    float2 q0 = float2(taps.p0.x * ct + taps.p0.y * st, taps.p0.y * ct - taps.p0.x * st);
    float2 q1 = float2(taps.p1.x * ct + taps.p1.y * st, taps.p1.y * ct - taps.p1.x * st);
    float2 q2 = float2(taps.p2.x * ct + taps.p2.y * st, taps.p2.y * ct - taps.p2.x * st);
    float2 q3 = float2(taps.p3.x * ct + taps.p3.y * st, taps.p3.y * ct - taps.p3.x * st);
    for (int k = entries - 1; k >= 0; k--) {
        float4 e = entry(twists, k);
        q0 = unmap(q0, e, plateau, swirlPlateau, lensEdge);
        q3 = unmap(q3, e, plateau, swirlPlateau, lensEdge);
        if (stride == 1) {
            q1 = unmap(q1, e, plateau, swirlPlateau, lensEdge);
            q2 = unmap(q2, e, plateau, swirlPlateau, lensEdge);
        }
    }
    taps.q0 = q0;
    taps.q1 = q1;
    taps.q2 = q2;
    taps.q3 = q3;
    return taps;
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

// The stitchables' bodies, over any layer with a sample(float2) in points: SwiftUI's, or the GPU bench's texture.
template <typename L>
static half4 unstirBody(float2 pos, L layer, float2 centre, float radius, device const float *twists, int count, float n,
                        float fourTaps, float plateau, float swirlPlateau, float lensEdge, float scale, float haze,
                        float3 wave, float turn) {
    // Four taps a quarter device pixel off centre, each through the whole inverse chain (tapsThrough): the stretching
    // is in the map, so a filament thinner than a pixel keeps its light as coverage. Past fourTaps entries only the
    // diagonal pair runs: on an iPhone 13 Pro Max's glass, about 1137 px, a full stack of 36 and the drag over a live picture's fill
    // of 4, 41 entries' work in all, held 120 Hz with four taps (2026-11-04).
    int stride = n > fourTaps ? 3 : 1;
    Taps taps = tapsThrough(pos, centre, radius, twists, min(int(n), count / 4), stride, plateau, swirlPlateau, lensEdge,
                            scale, turn);
    float3 acc = lit(float3(layer.sample(centre + taps.q0 * radius).rgb), taps.p0, wave);
    if (stride == 1) {
        acc += lit(float3(layer.sample(centre + taps.q1 * radius).rgb), taps.p1, wave);
        acc += lit(float3(layer.sample(centre + taps.q2 * radius).rgb), taps.p2, wave);
    }
    acc += lit(float3(layer.sample(centre + taps.q3 * radius).rgb), taps.p3, wave);
    return finish(acc, stride, haze);
}

// A Prism tap's colour s, its channels sampled at qr, qg and qb (tank units): the swatch's channel alone, or the held
// rod's read drawn `hold` over the plain glass.
static float3 channelsRead(float3 s, float2 qr, float2 qg, float2 qb, int alone, float3 tint, float3 own, float hold) {
    if (alone != 0) return (alone == 1 ? s.r : alone == 2 ? s.g : s.b) * tint;
    if (hold > 0.0) {
        float m = max(s.r * own.r, max(s.g * own.g, s.b * own.b));
        // A dark colour's lines take some of the other channels, short of white as the tests measure it (0.6 of the
        // brightest): blue's 0.41 of red and green.
        float lift = saturate(0.55 - 1.2 * dot(own, float3(0.299, 0.587, 0.114)));
        // Another channel is drawn by how nearly it and a held one show the same point of the plate, lit or not:
        // nothing from 0.03 of the glass's radius apart, some 18 px of a 1200 px glass, whole within 0.003. That reads
        // the stack's maps, never the count: half a step off it moves a point at the cap's edge (0.12 off the rod's
        // centre, under its knob) 0.031.
        float rg = 1.0 - smoothstep(0.003, 0.03, distance(qr, qg));
        float gb = 1.0 - smoothstep(0.003, 0.03, distance(qg, qb));
        float br = 1.0 - smoothstep(0.003, 0.03, distance(qb, qr));
        float3 met = s * float3(max(own.g * rg, own.b * br), max(own.r * rg, own.b * gb), max(own.r * br, own.g * gb));
        s = mix(s, mix(max(met, lift * m), s, own), hold);
    }
    return s;
}

template <typename L>
static half4 unstirChannelsBody(float2 pos, L layer, float2 centre, float radius, device const float *twists, int count,
                                device const float *masks, int maskCount, float n, float cost, float fourTaps,
                                float plateau, float swirlPlateau, float lensEdge, float scale, float haze, float3 wave,
                                float turn, float isolate, float3 tint, float held, float hold) {
    int stride = cost > fourTaps ? 3 : 1;
    int entries = pastTheGlass(pos, centre, radius, scale) ? 0 : min(int(n), min(count / 4, maskCount));
    int alone = int(isolate);
    int h = int(held);
    float3 own = float3(h & 1, (h >> 1) & 1, (h >> 2) & 1);
    float ct = cos(turn), st = sin(turn);
    float3 acc = 0;
    for (int j = 0; j < 4; j += stride) {
        float2 p = (pos + (float2(j & 1, j >> 1) - 0.5) * 0.5 / scale - centre) / radius;
        float2 q = float2(p.x * ct + p.y * st, p.y * ct - p.x * st);
        float2 qr = q, qg = q, qb = q;
        chains(entries, twists, masks, plateau, swirlPlateau, lensEdge, qr, qg, qb);
        float3 s = float3(layer.sample(centre + qr * radius).r, layer.sample(centre + qg * radius).g,
                          layer.sample(centre + qb * radius).b);
        acc += lit(channelsRead(s, qr, qg, qb, alone, tint, own, hold), p, wave);
    }
    return finish(acc, stride, haze);
}

static float3 decoded(float3 c) {
    return select(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), c > 0.04045);
}

static float3 encoded(float3 c) {
    return select(12.92 * c, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, c > 0.0031308);
}

// The halftone's gamma-encoded colour at q of the clean panel, drawn from its geometry for a pixel whose footprint
// there is (jx, jy), tank units a device pixel along each screen axis: Halftone.Panel.light's copy, its dots from
// their radii and its white strokes from the distance to their edge, both in `atlas` as `fine` (Halftone.Detail.table)
// lays it out. `inset` is the five floats of the inset that holds q.
static float3 fineLight(float2 q, float2 jx, float2 jy, texture2d<half> atlas, device const float *fine,
                        device const float *inset) {
    constexpr sampler bilinear(filter::linear, address::clamp_to_edge, coord::pixel);
    float pitch = fine[0];
    int cells = int(fine[1]), side = 2 * cells + 1;
    float3 c = 0;
    for (int k = 0; k < 3; k++) {
        float cs = fine[8 + 2 * k], sn = fine[9 + 2 * k];
        float2 u = float2(q.x * cs + q.y * sn, q.y * cs - q.x * sn);
        float2 cell = round(u / pitch);
        float radius = pitch * fine[2] * float(atlas.read(uint2(k * side + cells + int(cell.x), cells + int(cell.y))).r);
        if (radius <= 0.0) continue;
        float2 d = u - cell * pitch;
        float dist = length(d);
        float2 dir = dist > 1e-9 ? d / dist : float2(1.0, 0.0);
        // The edge's normal back in the panel's frame, and how far a device pixel's step moves a point along it.
        float2 normal = float2(dir.x * cs - dir.y * sn, dir.x * sn + dir.y * cs);
        float aa = length(float2(dot(normal, jx), dot(normal, jy)));
        float cover = saturate((radius - dist) / max(aa, 1e-9) + 0.5);
        c += cover * decoded(float3(atlas.read(uint2(3 * side + 2 + k, 0)).rgb));
    }
    c = min(c, 1.0);
    float2 at = float2(inset[3], inset[4]) + (q - (float2(inset[0], inset[1]) - inset[2])) * fine[4];
    float e = atlas.sample(bilinear, at).r;
    // Which way the nearest edge lies, from the distance's slope over half a texel. Its length is 1, as a distance's
    // is: measured, it falls short along a hairline's middle, and the edge's ramp, a device pixel wide, would steepen.
    float2 slope = float2(atlas.sample(bilinear, at + float2(0.5, 0.0)).r - e, atlas.sample(bilinear, at + float2(0.0, 0.5)).r - e);
    float2 normal = dot(slope, slope) > 1e-12 ? normalize(slope) : float2(1.0, 0.0);
    float aa = length(float2(dot(normal, jx), dot(normal, jy)));
    float ink = saturate(0.5 - (e - 0.5) * 2.0 * fine[3] / max(aa, 1e-9));
    return encoded(c * (1.0 - ink) + ink);
}

// A Lens level's glass (`unstirLens`): `unstirBody`, and where a lens magnifies the panel, the panel drawn again from
// its geometry at the pixel's own size, since the layer holds one sample a device pixel of the clean panel. The
// detail's weight goes by the pixel's footprint on the panel, its longer axis in bake pixels: nothing at fine[7] or
// more, so wherever nothing magnifies both ways (the clean panel, a twist, a lens's squeezed rim band) this is
// `unstirBody` to the bit, and all of it by fine[6], so a lens zooming in crosses over as its dots first swell.
template <typename L>
static half4 unstirLensBody(float2 pos, L layer, float2 centre, float radius, device const float *twists, int count,
                            float n, float fourTaps, float plateau, float swirlPlateau, float lensEdge, float scale,
                            float haze, float3 wave, float turn, texture2d<half> atlas, device const float *fine,
                            int fineCount) {
    int stride = n > fourTaps ? 3 : 1;
    int entries = min(int(n), count / 4);
    float ct = cos(turn), st = sin(turn);
    float2 ps[4], qs[4];
    Taps taps = tapsThrough(pos, centre, radius, twists, entries, stride, plateau, swirlPlateau, lensEdge, scale, turn);
    ps[0] = taps.p0;
    ps[1] = taps.p1;
    ps[2] = taps.p2;
    ps[3] = taps.p3;
    qs[0] = taps.q0;
    qs[1] = taps.q1;
    qs[2] = taps.q2;
    qs[3] = taps.q3;
    float weight = 0.0;
    float3 detail = 0;
    float2 q = 0.5 * (qs[0] + qs[3]);
    for (int k = 16; k + 5 <= fineCount && fine[5] > 0.0; k += 5) {
        float2 off = abs(q - float2(fine[k], fine[k + 1]));
        float within = saturate((fine[k + 2] - max(off.x, off.y)) / (fine[14] * fine[k + 2]));
        if (within <= 0.0) continue;
        int side = 2 * int(fine[1]) + 1;
        // An atlas whose greys don't read as written (a colour match this was not built for) draws nothing.
        if (abs(float(atlas.read(uint2(3 * side, 0)).r) - 64.0 / 255.0) > 0.003
            || abs(float(atlas.read(uint2(3 * side + 1, 0)).r) - 192.0 / 255.0) > 0.003) break;
        if (stride != 1) {
            // Two taps lie on one diagonal: a third chain, only here, gives the footprint its other axis.
            float2 p = (pos + float2(0.25, -0.25) / scale - centre) / radius;
            float2 r = float2(p.x * ct + p.y * st, p.y * ct - p.x * st);
            for (int i = entries - 1; i >= 0; i--) r = unmap(r, entry(twists, i), plateau, swirlPlateau, lensEdge);
            qs[1] = r;
            qs[2] = qs[0] + qs[3] - r;
        }
        // Taps half a device pixel apart: the footprint's axes, in tank units a device pixel.
        float2 jx = qs[1] - qs[0] + qs[3] - qs[2], jy = qs[2] - qs[0] + qs[3] - qs[1];
        float sum = dot(jx, jx) + dot(jy, jy), det = jx.x * jy.y - jx.y * jy.x;
        float longer = sqrt(0.5 * (sum + sqrt(max(sum * sum - 4.0 * det * det, 0.0))));
        weight = fine[5] * within * (1.0 - smoothstep(fine[6], fine[7], longer * radius * scale));
        if (weight > 0.0) detail = fineLight(q, jx, jy, atlas, fine, fine + k);
        break;
    }
    float3 acc = 0;
    for (int j = 0; j < 4; j += stride) {
        if (weight <= 0.0) acc += lit(float3(layer.sample(centre + qs[j] * radius).rgb), ps[j], wave);
        else if (weight >= 1.0) acc += lit(detail, ps[j], wave);
        else acc += lit(mix(float3(layer.sample(centre + qs[j] * radius).rgb), detail, weight), ps[j], wave);
    }
    return finish(acc, stride, haze);
}

// The stored map (StirMap.swift): where each tap of the glass lands on the picture through the stack's bottom entries,
// worked out once when the stack changes. Taps sit a quarter pixel off each pixel's centre, a grid of two a pixel, so
// the map is an image two texels a device pixel, a texel a tap. A texel holds its tap's point on the layer in device
// pixels, 16 bits a coordinate over two bytes each (red and green, blue and alpha), `quant` steps a pixel: a multiple
// of 4, so a tap the stack leaves alone is stored exactly.
static float2 stored(texture2d<half> map, int2 at, float quant, int tile = 0) {
    int side = map.get_width();
    at = clamp(at, int2(0), int2(side - 1)) + int2(0, tile * side);
    float4 t = round(float4(map.read(uint2(at))) * 255.0);
    return float2(t.r + 256.0 * t.g, t.b + 256.0 * t.a) / quant;
}

static float4 storing(float2 pixel, float quant) {
    float2 v = clamp(round(pixel * quant), 0.0, 65535.0), high = floor(v / 256.0);
    return float4(v.x - 256.0 * high.x, high.x, v.y - 256.0 * high.y, high.y) / 255.0;
}

// The map's four texels of device pixel `pixel` in tile `tile`, through the `kept` entries given with the glass turned
// `rest`: its taps as a frame's are (tapsThrough), since a deep stir stretches the last bit of a tap's place into
// pixels of the picture. A Prism glass's tile is given only the entries of its channels' word, as `chains` runs them.
static void storeTaps(texture2d<float, access::write> map, uint2 pixel, float2 centre, float radius,
                      device const float *twists, int kept, float plateau, float swirlPlateau, float lensEdge,
                      float scale, float rest, float quant, int tile = 0) {
    Taps taps = tapsThrough((float2(pixel) + 0.5) / scale, centre, radius, twists, kept, 1, plateau, swirlPlateau,
                            lensEdge, scale, rest);
    uint2 at = 2 * pixel + uint2(0, tile * map.get_width());
    map.write(storing((centre + taps.q0 * radius) * scale, quant), at);
    map.write(storing((centre + taps.q1 * radius) * scale, quant), at + uint2(1, 0));
    map.write(storing((centre + taps.q2 * radius) * scale, quant), at + uint2(0, 1));
    map.write(storing((centre + taps.q3 * radius) * scale, quant), at + uint2(1, 1));
}

// Where x, a point of the glass the entries above the map have moved, or any point while the glass is turned off the
// map's turn (cr and sr its cosine and sine), lands on the layer, in device pixels: read between the map's four
// nearest texels where those lie as a straight map would put them, to `bend` pixels, and elsewhere the nearest texel's
// point whole. Deep in a stir the map folds within half a pixel, and a point between two of its points is not one of
// them: read between them everywhere, vortex 27's breath drew 0.4 of a level brighter (2026-11-12).
static float2 between(texture2d<half> map, float2 x, float2 centre, float radius, float scale, float cr, float sr,
                      float quant, float bend, int tile = 0) {
    // No disc reaches past the glass's edge (testEveryDiscLiesWithinTheGlass), so a point outside it is its own.
    if (dot(x, x) >= 1.0) return (centre + x * radius) * scale;
    // The point back on the screen as the map was drawn.
    float2 y = float2(x.x * cr - x.y * sr, x.y * cr + x.x * sr);
    float2 u = (centre + y * radius) * scale * 2.0 - 0.5, low = floor(u), f = u - low;
    float2 a = stored(map, int2(low), quant, tile), b = stored(map, int2(low) + int2(1, 0), quant, tile);
    float2 c = stored(map, int2(low) + int2(0, 1), quant, tile), d = stored(map, int2(low) + int2(1, 1), quant, tile);
    float2 cross = a + d - b - c;
    if (dot(cross, cross) > bend * bend) return f.y < 0.5 ? (f.x < 0.5 ? a : b) : (f.x < 0.5 ? c : d);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// `unstirBody` over a stored map of the bottom mapped.x entries, drawn with the glass turned mapped.y, at mapped.z
// steps a pixel. The entries above them (a rod in hand, a tick, the breath, a twist the map has yet to take in) run
// as they do there, and a tap none of them moves reads its own texel: the point `unstirBody` reaches, to the stored
// step. A tap they move, or any tap while the glass is turned off the map's turn or the layer lies off the screen's
// pixels, lands between texels (`between`). mapped.w is StirMap.Mode: 1 draws as said; 0 draws a pixel with any such
// tap through the whole chain instead, as `unstirBody` does, for holding the two against each other; 2 tints the
// pixels whose taps all read their own texel green, some yellow and none red.
template <typename L>
static half4 unstirMappedBody(float2 pos, L layer, float2 centre, float radius, device const float *twists, int count,
                              float n, float fourTaps, float plateau, float swirlPlateau, float lensEdge, float scale,
                              float haze, float3 wave, float turn, texture2d<half> map, float4 mapped, float bend) {
    int stride = n > fourTaps ? 3 : 1;
    int entries = min(int(n), count / 4), kept = min(int(mapped.x), entries), mode = int(mapped.w);
    float rest = mapped.y, quant = mapped.z;
    Taps still = tapsThrough(pos, centre, radius, twists, 0, stride, plateau, swirlPlateau, lensEdge, scale, turn);
    Taps taps = tapsThrough(pos, centre, radius, twists + 4 * kept, entries - kept, stride, plateau, swirlPlateau,
                            lensEdge, scale, turn);
    float2 at = (pos * scale - 0.5) * 2.0, whole = round(at);
    bool off = turn != rest || any(abs(at - whole) >= 0.02);
    bool m0 = off || any(taps.q0 != still.q0), m3 = off || any(taps.q3 != still.q3);
    bool m1 = stride == 1 && (off || any(taps.q1 != still.q1)), m2 = stride == 1 && (off || any(taps.q2 != still.q2));
    if (pastTheGlass(pos, centre, radius, scale) || (mode == 0 && (m0 || m1 || m2 || m3))) {
        return unstirBody(pos, layer, centre, radius, twists, count, n, fourTaps, plateau, swirlPlateau, lensEdge, scale,
                          haze, wave, turn);
    }
    float cr = cos(rest), sr = sin(rest);
    int2 own = int2(whole);
    float2 s0 = m0 ? between(map, taps.q0, centre, radius, scale, cr, sr, quant, bend) : stored(map, own, quant);
    float2 s3 = m3 ? between(map, taps.q3, centre, radius, scale, cr, sr, quant, bend) : stored(map, own + int2(1, 1), quant);
    float3 acc = lit(float3(layer.sample(s0 / scale).rgb), taps.p0, wave);
    if (stride == 1) {
        float2 s1 = m1 ? between(map, taps.q1, centre, radius, scale, cr, sr, quant, bend) : stored(map, own + int2(1, 0), quant);
        float2 s2 = m2 ? between(map, taps.q2, centre, radius, scale, cr, sr, quant, bend) : stored(map, own + int2(0, 1), quant);
        acc += lit(float3(layer.sample(s1 / scale).rgb), taps.p1, wave);
        acc += lit(float3(layer.sample(s2 / scale).rgb), taps.p2, wave);
    }
    acc += lit(float3(layer.sample(s3 / scale).rgb), taps.p3, wave);
    half4 colour = finish(acc, stride, haze);
    if (mode == 2) {
        int moved = int(m0) + int(m1) + int(m2) + int(m3);
        colour.rgb *= moved == 0 ? half3(0.3h, 1.0h, 0.3h) : moved < (stride == 1 ? 4 : 2) ? half3(1.0h, 1.0h, 0.3h) : half3(1.0h, 0.3h, 0.3h);
    }
    return colour;
}

// A Lens level's glass over a stored map: `unstirMappedBody`, but where a pixel's point on the panel may lie in a lens's
// inset, the chain as `unstirLensBody` runs it. The detail is drawn from the taps' differences, finer at x8 than the
// stored step, so whatever it might reach draws exactly as it does without a map. The point is the map's, which at a
// tap's own texel is the chain's within half a step and between texels, where a fold may take the nearest whole, is
// held `bend` pixels short of each inset: a point in a fold that far out is drawn from the layer, as `mix` draws it.
template <typename L>
static half4 unstirLensMappedBody(float2 pos, L layer, float2 centre, float radius, device const float *twists,
                                  int count, float n, float fourTaps, float plateau, float swirlPlateau, float lensEdge,
                                  float scale, float haze, float3 wave, float turn, texture2d<half> atlas,
                                  device const float *fine, int fineCount, texture2d<half> map, float4 mapped,
                                  float bend) {
    if (fine[5] > 0.0 && !pastTheGlass(pos, centre, radius, scale)) {
        int stride = n > fourTaps ? 3 : 1;
        int entries = min(int(n), count / 4), kept = min(int(mapped.x), entries);
        float rest = mapped.y, quant = mapped.z;
        Taps still = tapsThrough(pos, centre, radius, twists, 0, stride, plateau, swirlPlateau, lensEdge, scale, turn);
        Taps taps = tapsThrough(pos, centre, radius, twists + 4 * kept, entries - kept, stride, plateau, swirlPlateau,
                                lensEdge, scale, turn);
        float2 at = (pos * scale - 0.5) * 2.0, whole = round(at);
        bool off = turn != rest || any(abs(at - whole) >= 0.02);
        bool m0 = off || any(taps.q0 != still.q0), m3 = off || any(taps.q3 != still.q3);
        float cr = cos(rest), sr = sin(rest);
        float2 s0 = m0 ? between(map, taps.q0, centre, radius, scale, cr, sr, quant, bend) : stored(map, int2(whole), quant);
        float2 s3 = m3 ? between(map, taps.q3, centre, radius, scale, cr, sr, quant, bend)
                       : stored(map, int2(whole) + int2(1, 1), quant);
        float2 q = (0.5 * (s0 + s3) / scale - centre) / radius;
        float margin = ((m0 || m3) ? bend + 1.0 : 1.0) / (radius * scale);
        for (int k = 16; k + 5 <= fineCount; k += 5) {
            float2 d = abs(q - float2(fine[k], fine[k + 1]));
            if (max(d.x, d.y) < fine[k + 2] + margin) {
                half4 c = unstirLensBody(pos, layer, centre, radius, twists, count, n, fourTaps, plateau, swirlPlateau,
                                         lensEdge, scale, haze, wave, turn, atlas, fine, fineCount);
                if (int(mapped.w) == 2) c.rgb *= half3(0.3h, 0.3h, 1.0h);
                return c;
            }
        }
    }
    return unstirMappedBody(pos, layer, centre, radius, twists, count, n, fourTaps, plateau, swirlPlateau, lensEdge, scale,
                            haze, wave, turn, map, mapped, bend);
}

// Channel `bit`'s point on the layer, in device pixels, from x, its point through the entries above the map: the tile's
// own texel `texel` where none of them moved it and the glass lies on the map's turn and pixels (`still`), else between
// the tile's texels; with no tile (-1), through the channel's word of the bottom `kept` entries, run here.
static float2 channelPoint(texture2d<half> map, float2 x, bool still, int2 texel, int tile, int kept,
                           device const float *twists, device const float *masks, int bit, float2 centre, float radius,
                           float scale, float cr, float sr, float quant, float bend, float plateau, float swirlPlateau,
                           float lensEdge) {
    if (tile < 0) {
        for (int i = kept - 1; i >= 0; i--) {
            if (int(masks[i]) & bit) x = unmap(x, entry(twists, i), plateau, swirlPlateau, lensEdge);
        }
        return (centre + x * radius) * scale;
    }
    return still ? stored(map, texel, quant, tile) : between(map, x, centre, radius, scale, cr, sr, quant, bend, tile);
}

// Prism's glass over a stored map (`unstirChannelsBody`): the map holds a tile a chain, each the word of the bottom
// mapped.x entries of the channels that share it, and tiles gives each of red, green and blue its tile, -1 for one
// that has none. The entries above the map run through `chains` as they do there, and each channel then reads its own
// tile as `unstirMappedBody` reads the one map. mapped.w as there: 0 draws a pixel any of whose channels a tap moves
// through `unstirChannelsBody` whole, and 2 tints it by how many of its channels' points read their own texel.
template <typename L>
static half4 unstirChannelsMappedBody(float2 pos, L layer, float2 centre, float radius, device const float *twists,
                                      int count, device const float *masks, int maskCount, float n, float cost,
                                      float fourTaps, float plateau, float swirlPlateau, float lensEdge, float scale,
                                      float haze, float3 wave, float turn, float isolate, float3 tint, float held,
                                      float hold, texture2d<half> map, float4 mapped, float bend, float3 tiles) {
    if (pastTheGlass(pos, centre, radius, scale)) {
        return unstirChannelsBody(pos, layer, centre, radius, twists, count, masks, maskCount, n, cost, fourTaps, plateau,
                                  swirlPlateau, lensEdge, scale, haze, wave, turn, isolate, tint, held, hold);
    }
    int stride = cost > fourTaps ? 3 : 1;
    int entries = min(int(n), min(count / 4, maskCount)), kept = min(int(mapped.x), entries), mode = int(mapped.w);
    float rest = mapped.y, quant = mapped.z, cr = cos(rest), sr = sin(rest);
    int alone = int(isolate);
    int h = int(held);
    float3 own = float3(h & 1, (h >> 1) & 1, (h >> 2) & 1);
    int3 tile = int3(tiles);
    float ct = cos(turn), st = sin(turn);
    float2 at = (pos * scale - 0.5) * 2.0, whole = round(at);
    bool off = turn != rest || any(abs(at - whole) >= 0.02);
    float3 acc = 0;
    int moved = 0, points = 0;
    for (int j = 0; j < 4; j += stride) {
        float2 p = tapOnScreen(pos, j, centre, radius, scale);
        float2 q = float2(p.x * ct + p.y * st, p.y * ct - p.x * st);
        float2 qr = q, qg = q, qb = q;
        chains(entries - kept, twists + 4 * kept, masks + kept, plateau, swirlPlateau, lensEdge, qr, qg, qb);
        bool mr = tile.x >= 0 && (off || any(qr != q)), mg = tile.y >= 0 && (off || any(qg != q));
        bool mb = tile.z >= 0 && (off || any(qb != q));
        if (mode == 0 && (mr || mg || mb)) {
            return unstirChannelsBody(pos, layer, centre, radius, twists, count, masks, maskCount, n, cost, fourTaps,
                                      plateau, swirlPlateau, lensEdge, scale, haze, wave, turn, isolate, tint, held, hold);
        }
        moved += int(mr) + int(mg) + int(mb);
        points += int(tile.x >= 0) + int(tile.y >= 0) + int(tile.z >= 0);
        int2 texel = int2(whole) + int2(j & 1, j >> 1);
        float2 lr = channelPoint(map, qr, !mr, texel, tile.x, kept, twists, masks, 1, centre, radius, scale, cr, sr, quant,
                                  bend, plateau, swirlPlateau, lensEdge);
        float2 lg = channelPoint(map, qg, !mg, texel, tile.y, kept, twists, masks, 2, centre, radius, scale, cr, sr, quant,
                                 bend, plateau, swirlPlateau, lensEdge);
        float2 lb = channelPoint(map, qb, !mb, texel, tile.z, kept, twists, masks, 4, centre, radius, scale, cr, sr, quant,
                                 bend, plateau, swirlPlateau, lensEdge);
        float3 s = float3(layer.sample(lr / scale).r, layer.sample(lg / scale).g, layer.sample(lb / scale).b);
        acc += lit(channelsRead(s, (lr / scale - centre) / radius, (lg / scale - centre) / radius,
                                (lb / scale - centre) / radius, alone, tint, own, hold), p, wave);
    }
    half4 colour = finish(acc, stride, haze);
    if (mode == 2) {
        colour.rgb *= moved == 0 ? half3(0.3h, 1.0h, 0.3h) : moved < points ? half3(1.0h, 1.0h, 0.3h) : half3(1.0h, 0.3h, 0.3h);
    }
    return colour;
}

// twists: n entries of (rod centre x, y, disc radius, angle) in tank-normalized units, bottom of the stack first. A
// lens's entry has a negative radius and its flow's time (steps * Tank.lensRate) for the angle.
// Tank.profile / Tank.twist / Tank.lens in Twist.swift are the Swift copy the tests check; the tests reach lensFlow and
// chains here, and Prism's body over a texture (PrismTests), which has no Swift copy.
// plateau is a knob's, swirlPlateau a disc's of radius 1 or more (the swirl's, or the breath's through it).
// turn: the glass's clockwise turn about the centre. The stack names the glass's own rods, so the point turns back
// first. Swift has no copy of the turn: the seized-* harness shots pin its sign.
[[ stitchable ]] half4 unstir(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                              device const float *twists, int count, float n, float fourTaps, float plateau,
                              float swirlPlateau, float lensEdge, float scale, float haze, float3 wave, float turn) {
    return unstirBody(pos, layer, centre, radius, twists, count, n, fourTaps, plateau, swirlPlateau, lensEdge, scale,
                      haze, wave, turn);
}

// Prism's: each of red, green and blue sampled through its own word, the entries whose mask (masks[i], a Channels raw
// value) holds it. cost is the work in entries, against fourTaps as n is above. isolate, a single channel's raw value or
// 0, draws that channel alone in tint and hides the others: the held swatch, in its own colour, or white under
// Differentiate Without Colour, where it reads without telling colours apart. held is the mask of the rod in the
// player's hand (0 for none, never white), hold how far its read is drawn over the plain glass, 0 to 1: the channels
// it moves in their own colour, a dark one lifted, and each other channel only where it and a held one show nearly the
// same point of the plate, so the disc turns one colour off the count and white fades in as the turn nears it. A rod
// stirred twice goes white at the sum of its stirs, as the plain glass does. At hold 0 this is the plain glass to the
// bit (testAHeldRodsReadLeavesTheGlassAsItWasWhenLetGo).
[[ stitchable ]] half4 unstirChannels(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                                      device const float *twists, int count, device const float *masks, int maskCount,
                                      float n, float cost, float fourTaps, float plateau, float swirlPlateau,
                                      float lensEdge, float scale, float haze, float3 wave, float turn, float isolate,
                                      float3 tint, float held, float hold) {
    return unstirChannelsBody(pos, layer, centre, radius, twists, count, masks, maskCount, n, cost, fourTaps, plateau,
                              swirlPlateau, lensEdge, scale, haze, wave, turn, isolate, tint, held, hold);
}

// A Lens level's glass once its detail is baked: atlas and fine are Halftone.Detail's pixels and table.
[[ stitchable ]] half4 unstirLens(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                                  device const float *twists, int count, float n, float fourTaps, float plateau,
                                  float swirlPlateau, float lensEdge, float scale, float haze, float3 wave, float turn,
                                  texture2d<half> atlas, device const float *fine, int fineCount) {
    return unstirLensBody(pos, layer, centre, radius, twists, count, n, fourTaps, plateau, swirlPlateau, lensEdge, scale,
                          haze, wave, turn, atlas, fine, fineCount);
}

// A level's glass over a stored map of its committed stack (`unstirMappedBody`, StirMap.swift): map is StirMap's
// image, mapped its (entries held, turn, steps a pixel, StirMap.Mode) and bend StirMap.bend.
[[ stitchable ]] half4 unstirMapped(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                                    device const float *twists, int count, float n, float fourTaps, float plateau,
                                    float swirlPlateau, float lensEdge, float scale, float haze, float3 wave, float turn,
                                    texture2d<half> map, float4 mapped, float bend) {
    return unstirMappedBody(pos, layer, centre, radius, twists, count, n, fourTaps, plateau, swirlPlateau, lensEdge, scale,
                            haze, wave, turn, map, mapped, bend);
}

// A Lens level's glass over a stored map once its detail is baked (`unstirLensMappedBody`): `unstirLens`' arguments,
// then `unstirMapped`'s.
[[ stitchable ]] half4 unstirLensMapped(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                                        device const float *twists, int count, float n, float fourTaps, float plateau,
                                        float swirlPlateau, float lensEdge, float scale, float haze, float3 wave,
                                        float turn, texture2d<half> atlas, device const float *fine, int fineCount,
                                        texture2d<half> map, float4 mapped, float bend) {
    return unstirLensMappedBody(pos, layer, centre, radius, twists, count, n, fourTaps, plateau, swirlPlateau, lensEdge,
                                scale, haze, wave, turn, atlas, fine, fineCount, map, mapped, bend);
}

// Prism's glass over a stored map (`unstirChannelsMappedBody`): `unstirChannels`' arguments, then `unstirMapped`'s and
// each channel's tile, -1 for none.
[[ stitchable ]] half4 unstirChannelsMapped(float2 pos, SwiftUI::Layer layer, float2 centre, float radius,
                                            device const float *twists, int count, device const float *masks,
                                            int maskCount, float n, float cost, float fourTaps, float plateau,
                                            float swirlPlateau, float lensEdge, float scale, float haze, float3 wave,
                                            float turn, float isolate, float3 tint, float held, float hold,
                                            texture2d<half> map, float4 mapped, float bend, float3 tiles) {
    return unstirChannelsMappedBody(pos, layer, centre, radius, twists, count, masks, maskCount, n, cost, fourTaps,
                                    plateau, swirlPlateau, lensEdge, scale, haze, wave, turn, isolate, tint, held, hold,
                                    map, mapped, bend, tiles);
}

// The GPU bench (UNSTIR_GPUBENCH, GPUBench.swift): the stitchables' own bodies on a texture of the picture, one thread a
// device pixel, so the phone's GPU clock times exactly the shader the tank draws.
struct BenchLayer {
    texture2d<half> picture;
    float pixels;  // device pixels per point
    half4 sample(float2 p) const {
        constexpr sampler s(filter::linear, address::clamp_to_zero, coord::pixel);
        return picture.sample(s, p * pixels);
    }
};

struct BenchArgs {
    float radius, scale, n, fourTaps, cost, plateau, swirlPlateau, lensEdge, held, hold;
    float turn, haze, isolate, tintR, tintG, tintB, nudgeX, nudgeY;
    int count, maskCount, channels, fineCount;
};

kernel void benchUnstir(texture2d<half> picture [[texture(0)]], texture2d<half, access::write> out [[texture(1)]],
                        texture2d<half> atlas [[texture(2)]],
                        device const float *twists [[buffer(0)]], device const float *masks [[buffer(1)]],
                        constant BenchArgs &a [[buffer(2)]], device const float *fine [[buffer(3)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
    BenchLayer layer = { picture, a.scale };
    float2 pos = (float2(gid) + 0.5) / a.scale, centre = float2(a.radius) + float2(a.nudgeX, a.nudgeY) / a.scale;
    half4 c = a.fineCount != 0
        ? unstirLensBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                         a.lensEdge, a.scale, a.haze, float3(0, 0, -1), a.turn, atlas, fine, a.fineCount)
        : a.channels != 0
        ? unstirChannelsBody(pos, layer, centre, a.radius, twists, a.count, masks, a.maskCount, a.n, a.cost, a.fourTaps,
                             a.plateau, a.swirlPlateau, a.lensEdge, a.scale, a.haze, float3(0, 0, -1), a.turn, a.isolate,
                             float3(a.tintR, a.tintG, a.tintB), a.held, a.hold)
        : unstirBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                     a.lensEdge, a.scale, a.haze, float3(0, 0, -1), a.turn);
    out.write(c, gid);
}

// The stored map's kernels: the map itself, a thread a device pixel from row `row` down (StirMap draws it a strip at
// a time), and the oracle's bench's frame over it. MapArgs is StirMap.Args' layout.
struct MapArgs {
    float radius, scale, centreX, centreY, plateau, swirlPlateau, lensEdge, rest, quant, mode, bend, tileR, tileG, tileB;
    int kept, row, tile;
};

kernel void stirMap(texture2d<float, access::write> map [[texture(0)]], device const float *twists [[buffer(0)]],
                    constant MapArgs &m [[buffer(1)]], uint2 gid [[thread_position_in_grid]]) {
    uint2 pixel = gid + uint2(0, m.row);
    if (2 * pixel.x >= map.get_width() || 2 * pixel.y >= map.get_width()) return;
    storeTaps(map, pixel, float2(m.centreX, m.centreY), m.radius, twists, m.kept, m.plateau, m.swirlPlateau, m.lensEdge,
              m.scale, m.rest, m.quant, m.tile);
}

// The bench's frame over a stored map, a kernel a body, as each stitchable is its own function: one kernel holding all
// three ran the plain body some 5 to 14% slower on the Mac (2026-11-13).
kernel void benchMapped(texture2d<half> picture [[texture(0)]], texture2d<half, access::write> out [[texture(1)]],
                        texture2d<half> map [[texture(3)]], device const float *twists [[buffer(0)]],
                        constant BenchArgs &a [[buffer(2)]], constant MapArgs &m [[buffer(4)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
    BenchLayer layer = { picture, a.scale };
    float2 pos = (float2(gid) + 0.5) / a.scale, centre = float2(a.radius) + float2(a.nudgeX, a.nudgeY) / a.scale;
    out.write(unstirMappedBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                               a.lensEdge, a.scale, a.haze, float3(0, 0, -1), a.turn, map,
                               float4(m.kept, m.rest, m.quant, m.mode), m.bend), gid);
}

kernel void benchLensMapped(texture2d<half> picture [[texture(0)]], texture2d<half, access::write> out [[texture(1)]],
                            texture2d<half> atlas [[texture(2)]], texture2d<half> map [[texture(3)]],
                            device const float *twists [[buffer(0)]], constant BenchArgs &a [[buffer(2)]],
                            device const float *fine [[buffer(3)]], constant MapArgs &m [[buffer(4)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
    BenchLayer layer = { picture, a.scale };
    float2 pos = (float2(gid) + 0.5) / a.scale, centre = float2(a.radius) + float2(a.nudgeX, a.nudgeY) / a.scale;
    out.write(unstirLensMappedBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau,
                                   a.swirlPlateau, a.lensEdge, a.scale, a.haze, float3(0, 0, -1), a.turn, atlas, fine,
                                   a.fineCount, map, float4(m.kept, m.rest, m.quant, m.mode), m.bend), gid);
}

kernel void benchChannelsMapped(texture2d<half> picture [[texture(0)]], texture2d<half, access::write> out [[texture(1)]],
                                texture2d<half> map [[texture(3)]], device const float *twists [[buffer(0)]],
                                device const float *masks [[buffer(1)]], constant BenchArgs &a [[buffer(2)]],
                                constant MapArgs &m [[buffer(4)]], uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
    BenchLayer layer = { picture, a.scale };
    float2 pos = (float2(gid) + 0.5) / a.scale, centre = float2(a.radius) + float2(a.nudgeX, a.nudgeY) / a.scale;
    out.write(unstirChannelsMappedBody(pos, layer, centre, a.radius, twists, a.count, masks, a.maskCount, a.n, a.cost,
                                       a.fourTaps, a.plateau, a.swirlPlateau, a.lensEdge, a.scale, a.haze, float3(0, 0, -1),
                                       a.turn, a.isolate, float3(a.tintR, a.tintG, a.tintB), a.held, a.hold, map,
                                       float4(m.kept, m.rest, m.quant, m.mode), m.bend, float3(m.tileR, m.tileG, m.tileB)),
              gid);
}
