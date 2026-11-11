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

// The stitchables' bodies, over any layer with a sample(float2) in points: SwiftUI's, or the GPU bench's texture.
template <typename L>
static half4 unstirBody(float2 pos, L layer, float2 centre, float radius, device const float *twists, int count, float n,
                        float fourTaps, float plateau, float swirlPlateau, float lensEdge, float scale, float haze,
                        float3 wave, float turn) {
    // Four taps a quarter device pixel off centre, each through the whole inverse chain: the stretching is in the
    // map, so a filament thinner than a pixel keeps its light as coverage. Past fourTaps entries only the diagonal pair
    // runs: on an iPhone 13 Pro Max's glass, about 1137 px, a full stack of 36 and the drag over a live picture's fill
    // of 4, 41 entries' work in all, held 120 Hz with four taps (2026-11-04).
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

template <typename L>
static half4 unstirChannelsBody(float2 pos, L layer, float2 centre, float radius, device const float *twists, int count,
                                device const float *masks, int maskCount, float n, float cost, float fourTaps,
                                float plateau, float swirlPlateau, float lensEdge, float scale, float haze, float3 wave,
                                float turn, float isolate, float3 tint, float held, float hold) {
    int stride = cost > fourTaps ? 3 : 1;
    int alone = int(isolate);
    int h = int(held);
    float3 own = float3(h & 1, (h >> 1) & 1, (h >> 2) & 1);
    float ct = cos(turn), st = sin(turn);
    float3 acc = 0;
    for (int j = 0; j < 4; j += stride) {
        float2 p = (pos + (float2(j & 1, j >> 1) - 0.5) * 0.5 / scale - centre) / radius;
        float2 q = float2(p.x * ct + p.y * st, p.y * ct - p.x * st);
        float2 qr = q, qg = q, qb = q;
        chains(min(int(n), min(count / 4, maskCount)), twists, masks, plateau, swirlPlateau, lensEdge, qr, qg, qb);
        float3 s = float3(layer.sample(centre + qr * radius).r, layer.sample(centre + qg * radius).g,
                          layer.sample(centre + qb * radius).b);
        if (alone != 0) s = (alone == 1 ? s.r : alone == 2 ? s.g : s.b) * tint;
        else if (hold > 0.0) {
            float m = max(s.r * own.r, max(s.g * own.g, s.b * own.b));
            // A dark colour's lines take some of the other channels, short of white as the tests measure it (0.6 of
            // the brightest): blue's 0.41 of red and green.
            float lift = saturate(0.55 - 1.2 * dot(own, float3(0.299, 0.587, 0.114)));
            // Another channel is drawn by how nearly it and a held one show the same point of the plate, lit or not:
            // nothing from 0.03 of the glass's radius apart, some 18 px of a 1200 px glass, whole within 0.003. That
            // reads the stack's maps, never the count: half a step off it moves a point at the cap's edge (0.12 off
            // the rod's centre, under its knob) 0.031.
            float rg = 1.0 - smoothstep(0.003, 0.03, distance(qr, qg));
            float gb = 1.0 - smoothstep(0.003, 0.03, distance(qg, qb));
            float br = 1.0 - smoothstep(0.003, 0.03, distance(qb, qr));
            float3 met = s * float3(max(own.g * rg, own.b * br), max(own.r * rg, own.b * gb), max(own.r * br, own.g * gb));
            s = mix(s, mix(max(met, lift * m), s, own), hold);
        }
        acc += lit(s, p, wave);
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
    for (int j = 0; j < 4; j += stride) {
        float2 p = (pos + (float2(j & 1, j >> 1) - 0.5) * 0.5 / scale - centre) / radius;
        float2 q = float2(p.x * ct + p.y * st, p.y * ct - p.x * st);
        for (int i = entries - 1; i >= 0; i--) q = unmap(q, twists + 4 * i, plateau, swirlPlateau, lensEdge);
        ps[j] = p;
        qs[j] = q;
    }
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
            for (int i = entries - 1; i >= 0; i--) r = unmap(r, twists + 4 * i, plateau, swirlPlateau, lensEdge);
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
    int count, maskCount, channels, fineCount;
};

kernel void benchUnstir(texture2d<half> picture [[texture(0)]], texture2d<half, access::write> out [[texture(1)]],
                        texture2d<half> atlas [[texture(2)]],
                        device const float *twists [[buffer(0)]], device const float *masks [[buffer(1)]],
                        constant BenchArgs &a [[buffer(2)]], device const float *fine [[buffer(3)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
    BenchLayer layer = { picture, a.scale };
    float2 pos = (float2(gid) + 0.5) / a.scale, centre = float2(a.radius);
    half4 c = a.fineCount != 0
        ? unstirLensBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                         a.lensEdge, a.scale, 0.0, float3(0, 0, -1), 0.0, atlas, fine, a.fineCount)
        : a.channels != 0
        ? unstirChannelsBody(pos, layer, centre, a.radius, twists, a.count, masks, a.maskCount, a.n, a.cost, a.fourTaps,
                             a.plateau, a.swirlPlateau, a.lensEdge, a.scale, 0.0, float3(0, 0, -1), 0.0, 0.0, float3(1), a.held,
                             a.hold)
        : unstirBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                     a.lensEdge, a.scale, 0.0, float3(0, 0, -1), 0.0);
    out.write(c, gid);
}
