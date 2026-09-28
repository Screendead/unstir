#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static uint hash(uint x) {
    x ^= x >> 16; x *= 0x7feb352du; x ^= x >> 15; x *= 0x846ca68bu; x ^= x >> 16;
    return x;
}

// The twin's: how inflamed the node at q is, 0 for 72% of nodes and 0.65-1 for the rest. A hash of its position, which
// its jitter (several periods of the fract) makes random.
static float heat(float2 q) {
    float x = fract(dot(q, float2(97.31, 71.17)));
    return x > 0.72 ? 0.65 + 1.25 * (x - 0.72) : 0.0;
}

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

// How far the twin's lines swell (x) and brighten (y) at beat b: 1 on average, the beat's mean being 0.12. The swell
// peaks at 1.70, so a spur's knob and its half-pixel fringe end inside the 0.0125 its edge is drawn to, on screens down
// to the SE's.
static float2 throb(float b) { return 1.0 + float2(0.8, 1.3) * (b - 0.12); }

// A glow that ends at 0.0125: a tight core over a wider skirt.
static float glow(float d) {
    float q = saturate(1.0 - d * d * 6400.0), q3 = q * q * q;
    return q3 * (0.2 + 0.25 * q3);
}

// One dendrite from a to b, bowed to one side, whole or a spur that stops partway in a knob. Adds its line (max) and
// glow (sum) to ink; ipx is one over a pixel. The twin's swell by up to 1.6 where inflamed (hot), and its spurs' knobs
// are 0.013 across, not 0.011; the heartbeat swells both by grow.
static void edge(float2 p, float2 a, float2 b, uint code, float hot, float grow, bool plus, float ipx,
                 thread float2 &ink) {
    float level = float(code & 7u), bow = (level - 3.0) * 0.06;
    float2 ab = b - a, r = p - a;
    float l2 = dot(ab, ab), u = dot(r, ab) / l2, il = rsqrt(l2), len = l2 * il;
    // Most pixels are beyond the bowed curve's glow.
    float s = (ab.x * r.y - ab.y * r.x) * il, v = saturate(u);
    if (abs(s - bow * len * 4.0 * v * (1.0 - v)) > 0.0125 || abs(u - 0.5) * len > 0.5 * len + 0.0125) return;
    // A spur reaches 42-63% of the way from one end (its bow level picks how far); tu is its tip.
    uint spur = code >> 3;
    float reach = 0.42 + 0.035 * level;
    float lo = spur == 2u ? 1.0 - reach : 0.0, hi = spur == 1u ? reach : 1.0, tu = spur == 1u ? hi : (spur == 2u ? lo : -9.0);
    // Distance across is taken off the chord's normal, not the curve's: up to a fifth too far where a full bow meets
    // a node, which only thins the line there a little.
    float uc = clamp(u, lo, hi), mid = 4.0 * uc * (1.0 - uc);
    float d = length(float2((u - uc) * len, s - bow * len * mid));
    // Thicker at the nodes, thinner midway. A spur narrows to a neck and ends in a knob at its tip.
    float x = (uc - tu) * len, w = (0.0029 - 0.0011 * mid) * (0.65 + 0.35 * saturate(abs(x) * 70.0));
    if (plus) w *= 1.0 + 0.6 * hot;
    w = max(w * grow, sqrt(max((plus ? 4.2e-5 : 3.0e-5) * grow * grow - x * x, 0.0)));
    ink = float2(max(ink.x, saturate((w - d) * ipx + 0.5)), ink.y + glow(d));
}

// The twin's firing front: it misfires, stalling 0.018-0.038 out for 0.9 s, swelling as the signal backs up behind it,
// then running back into the node at the same speed, head first. Over the stall (jam 0 to 1) the pulse turns round;
// the swelling (press) subsides over the first 0.5 s back. Returns how far out the front is.
static float misfire(uint h, float t, thread float &jam, thread float &press) {
    float rate = float(1u + ((h >> 19) & 1u)), since = fract(rate * t * (1.0 / 12.0) + float(h >> 20) * (1.0 / 4096.0)) * (12.0 / rate);
    // Distances: run is how far the front would be had it not stalled, back how far it has come back (0.0315 is 0.9 s).
    float stall = 0.018 + 0.02 * float((h >> 10) & 255u) * (1.0 / 255.0), run = since * 0.035, back = run - stall - 0.0315;
    jam = saturate((run - stall) * (1.0 / 0.0315));
    press = jam * saturate(1.0 - back * (1.0 / 0.0175));
    return min(run, stall) - max(back, 0.0);
}

// The search: p's nearest node among the 9 around it on the lattice (returned), at a with flags f, and the squared
// distances to it and to the second nearest of the 9.
static int2 nearest(float2 p, device const packed_float3 *cells, thread float2 &a, thread float &f, thread float &da,
                    thread float &db) {
    const float wide = 0.1, high = 0.0866025, left = -1.2, top = -1.1258;
    const int n = 24, rows = 26;
    int j0 = int(floor((p.y - top) / high)) - 1, ia = 0, ja = 0;
    a = 0;
    f = 0;
    da = 1e9;
    db = 1e9;
    for (int r = 0; r < 3; r++) {
        int j = clamp(j0 + r, 0, rows - 1), i0 = int(floor((p.x - left) / wide - 0.5 * float(j & 1))) - 1;
        for (int c = 0; c < 3; c++) {
            int i = clamp(i0 + c, 0, n - 1);
            float3 cell = float3(cells[j * n + i]);
            float d2 = distance_squared(p, cell.xy);
            if (d2 < da) { db = da; da = d2; a = cell.xy; f = cell.z; ia = i; ja = j; } else { db = min(db, d2); }
        }
    }
    return int2(ia, ja);
}

// The dendrites of the node at lattice place at and position a, at p, added to ink. All six neighbours' loads go out
// together, edge or not (cheaper than branching); the edges run after.
static void dendrites(float2 p, device const packed_float3 *cells, int2 at, float2 a, uint flags, float hot, float grow,
                      bool plus, float ipx, thread float2 &ink) {
    const int n = 24, rows = 26;
    int odd = at.y & 1;
    const int2 step[6] = {int2(1, 0), int2(odd, 1), int2(odd - 1, 1), int2(-1, 0), int2(odd - 1, -1), int2(odd, -1)};
    float3 nb[6];
    for (int dir = 0; dir < 6; dir++) {
        int2 cb = clamp(at + step[dir], int2(0), int2(n - 1, rows - 1));
        nb[dir] = float3(cells[cb.y * n + cb.x]);
    }
    for (int dir = 0; dir < 6; dir++) {
        if ((flags & (1u << dir)) == 0u) continue;
        bool own = dir < 3;
        uint code = ((own ? flags : uint(nb[dir].z)) >> (8u + 5u * uint(own ? dir : dir - 3))) & 31u;
        edge(p, own ? a : nb[dir].xy, own ? nb[dir].xy : a, code, hot, grow, plus, ipx, ink);
    }
}

// Neurons, in linear light at p: somas and junctions scattered with no lattice order, joined by bowed, tapering
// dendrites; now and then a node fires and pulses run out along all its dendrites at once. cells is Picture.nodes, 3
// floats each (x, y, flags), on a lookup lattice of 26 rows 0.0866 apart from y = -1.1258 and 24 cells 0.1 wide from
// x = -1.2, odd rows shifted half a cell right. Flag bits 0-5 are edges toward the lattice neighbours right, down-right,
// down-left, left, up-left, up-right; bit 6 a soma; bit 7 a knob; bits 8-22 the owned edges' codes (right, down-right,
// down-left), 5 bits each: bow level 0-6 (3 straight), then 0 whole, 1 a spur from the owner, 2 a spur from the far end.
// p draws only its nearest node (among the 9 it searches) and that node's edges: the data keeps every edge's line and
// glow (0.0125) inside the region where that search finds one of its ends, and every soma (0.0225; 0.026 in the twin)
// inside its own.
// plus draws the twin, mostly dead: a sallow dun web where over a quarter of the nodes are inflamed, burning scarlet
// along swollen dendrites that fade into the dead web by their regions' borders; somas dark blisters in inflamed
// membranes; only inflamed nodes fire, and they misfire. Its lines swell by pulse.x and all of it brightens by pulse.y,
// its glow never widening, so the clearances above hold.
template <bool plus>
static float3 field(float2 p, float px, device const packed_float3 *cells, float t, float2 pulse) {
    float2 a;
    float fa, da, db;
    int2 at = nearest(p, cells, a, fa, da, db);
    uint flags = uint(fa), node = uint(at.y * 24 + at.x), h = hash(node * 4u + 7u);
    float ipx = 1.0 / px, d = sqrt(da);
    // The twin's inflammation fills an inflamed node's region and dies out toward its border, where the distance to the
    // second nearest node comes down to d. A node outside the 9 searched is at least 0.068 away, so capping that
    // distance there makes this the same whichever 9 are searched.
    float hn = plus ? heat(a) : 0.0, hot = hn * saturate((min(sqrt(db), 0.068) - d) * 40.0);
    // The node fires once or twice a period on its own phase: a front leaves it at 0.035 a second. In the twin only an
    // inflamed node fires, and -1 is a quiet one.
    float jam = 0.0, press = 0.0, front = -1.0;
    if (!plus) {
        float rate = float(1u + ((h >> 19) & 1u));
        front = fract(rate * t * (1.0 / 12.0) + float(h >> 20) * (1.0 / 4096.0)) * (12.0 / rate) * 0.035;
    } else if (hn > 0.0) {
        front = misfire(h, t, jam, press);
    }
    float3 c = 0;
    float2 ink = 0;
    float open = 1.0;
    if (flags & 64u) {
        // A soma: a dim body inside a bright membrane, breathing once or twice a period on its own phase and flaring
        // as it fires. The twin's is swollen by a third, a near-black blister bloodied only toward its thicker membrane,
        // with no dendrite inside it.
        float rs = plus ? 0.0105 + 0.0035 * float(h & 255u) / 255.0 : 0.0075 + 0.003 * float(h & 255u) / 255.0;
        float breath = 0.5 + 0.5 * sin(6.2832 * (float((h >> 8) & 1023u) / 1024.0 + float(1u + ((h >> 18) & 1u)) * t / 12.0));
        breath += 1.2 * saturate(front * 60.0) * saturate(1.0 - front * 25.0);
        float e = max(d - rs, 0.0), q = saturate(1.0 - e * e * 6944.0), q3 = q * q * q;
        float membrane = plus ? 0.0026 * pulse.x : 0.0018;
        float body = saturate((rs - d) * ipx + 0.5), rim = saturate((membrane - abs(d - rs)) * ipx + 0.5);
        if (plus) {
            body *= d * d / (rs * rs);
            open = saturate((d - rs + membrane) * ipx + 0.5);
            c += float3(1.0, 0.012, 0.02) * (rim + (0.02 + 0.05 * breath) * body + q3 * (0.059 + 0.254 * q3 * q3) * (0.15 + 1.35 * breath));
        } else {
            c += float3(1.0, 0.0061, 0.048) * (rim + (0.1 + 0.25 * breath) * body + q3 * (0.07 + 0.3 * q3 * q3) * (0.15 + 1.35 * breath));
        }
    } else if (flags & 128u) {
        // A knob: where a single dendrite ends at a node.
        ink = float2(saturate(((plus ? 0.0065 * pulse.x : 0.0055) - d) * ipx + 0.5), glow(d));
    }
    dendrites(p, cells, at, a, flags, hot, pulse.x, plus, ipx, ink);
    // The firing front: a bright head with a tail back toward the node, fading in over its first 0.3 s. It dies out
    // before the border with the next node's region (half the gap to the second nearest is at most the distance to that
    // border), and by 0.065 from the node, nearer than any node outside the 9 searched can be (0.068), so neither a
    // border nor a change in which 9 are searched cuts it. The twin's tail lengthens and its head brightens as it
    // stalls, and trails outward as it runs back.
    float comet = 0.0;
    if (!plus || front > 0.0) {
        float behind = front - d, tail = 30.0 / (1.0 + 1.5 * jam);
        comet = behind < 0.0 ? saturate(1.0 + behind * 150.0) : saturate(1.0 - behind * tail);
        if (plus) comet = mix(comet, behind > 0.0 ? saturate(1.0 - behind * 150.0) : saturate(1.0 + behind * tail), jam);
        comet *= comet * (1.0 + 0.6 * press) * saturate(front * 100.0) * saturate((sqrt(db) - d) * 60.0 - 0.15) * saturate((0.065 - d) * 200.0);
    }
    // Where several dendrites meet, their summed glow is capped so a firing junction stays magenta (red in the twin),
    // not white. The twin's dead stretches barely glow; only inflamed ones carry the pulse, which stains them ember.
    float lit = min(ink.y, 0.9);
    if (!plus) {
        return c + float3(0.127, 0.087, 1.0) * (ink.x + lit) + float3(1.0, 0.0241, 0.672) * (comet * (1.5 * ink.x + 2.5 * min(lit, 0.5)));
    }
    float3 dead = float3(0.28, 0.18, 0.042) * (ink.x + 0.51 * lit);
    float3 sore = float3(1.0, 0.02, 0.035) * (ink.x + 1.19 * lit) * (1.0 - 0.6 * min(comet, 1.0))
                + float3(1.0, 0.13, 0.012) * (comet * (1.5 * ink.x + 2.12 * min(lit, 0.5)));
    return (c + open * mix(dead, sore, hot)) * pulse.y;
}

[[ stitchable ]] half4 neurons(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    return half4(half3(sqrt(field<false>(p, px, (device const packed_float3 *)data, t, 1.0))), 1.0h);
}

[[ stitchable ]] half4 neuronsPlus(float2 pos, float radius, float px, device const float *data, int count, float t) {
    float2 p = pos / radius - 1.0;
    if (length_squared(p) > 1.01) return half4(0.0h, 0.0h, 0.0h, 1.0h);
    float2 pulse = throb(heartbeat(p, t, data + count - 33 * 33));
    return half4(half3(sqrt(field<true>(p, px, (device const packed_float3 *)data, t, pulse))), 1.0h);
}
