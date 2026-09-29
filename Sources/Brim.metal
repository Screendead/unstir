// Copyright © 2026 Jack Lusher. All rights reserved.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Endless's brim, filled into a ring from the glass's edge outward, so it shades no pixel of the glass. Lengths are in
// the approved mockup's pixels (Brim.unit to the glass's radius), so its constants carry over; y is down, and phi runs
// from six o'clock (0) up either side to twelve (180). The output is premultiplied over the bezel: `keep` is how much
// of the steel shows through, and light with no alpha adds, which is how the glow lands on the black.
constant float R_PIC = 480.0;
constant float R_OUT = 501.6;
constant float R_MID = (R_PIC + R_OUT) / 2;
constant float HALF_W = (R_OUT - R_PIC) / 2;
constant float PI = 3.14159265;

// Bezel.chrome's stops, clockwise from three o'clock.
constant float CHROME_AT[7] = {0, 0.139, 0.333, 0.486, 0.653, 0.833, 1};
constant float3 CHROME[7] = {float3(42, 46, 55) / 255, float3(140, 148, 166) / 255, float3(40, 44, 52) / 255,
                             float3(90, 98, 114) / 255, float3(22, 24, 30) / 255, float3(174, 182, 198) / 255,
                             float3(42, 46, 55) / 255};

static float sstep(float a, float b, float x) {
    float t = saturate((x - a) / (b - a));
    return t * t * (3 - 2 * t);
}

static float sq(float x) { return x * x; }

// A logistic stand-in for the normal CDF: Metal has no erf.
static float cdf(float x) { return 1 / (1 + exp(-1.702 * x)); }

static float3 chrome(float th) {
    float f = fract(th / (2 * PI));
    for (int i = 0; i < 6; i++) {
        if (f <= CHROME_AT[i + 1]) return mix(CHROME[i], CHROME[i + 1], (f - CHROME_AT[i]) / (CHROME_AT[i + 1] - CHROME_AT[i]));
    }
    return CHROME[6];
}

// A colour round the rim, 3 floats per angle, the first at three o'clock, clockwise.
static float3 around(device const float *p, int count, float th) {
    int n = count / 3;
    float f = fract(th / (2 * PI)) * n;
    int i0 = int(f) % n, i1 = (i0 + 1) % n;
    float w = f - floor(f);
    return mix(float3(p[3 * i0], p[3 * i0 + 1], p[3 * i0 + 2]), float3(p[3 * i1], p[3 * i1 + 1], p[3 * i1 + 2]), w);
}

// The glow off the liquid, scaled to the approved film's balance of bloom to band.
constant float BLOOM = 0.76;
// Degrees from twelve where the spill's runs come to rest, just past three and nine o'clock.
constant float HEAD = 104;

// A notch's colour running on past the rim `tau` seconds into its spread, `outD` off the bezel: a surge of light that
// pushes out onto the black and settles into the bloom.
static float surge(float tau, float outD) {
    float sw = max(tau - 0.3, 0.0);
    return tau > 0.3 ? exp(-sw / 0.35) * exp(-outD / (4 + 30 * (1 - exp(-sw / 0.25)))) : 0;
}

// Light from a line `width` wide seen `d` off it, blurred as the mockup's glow was (two gaussians, 5.6 and 22).
static float lineGlow(float d, float width) {
    return width * (0.8 * exp(-sq(d / 5.6) / 2) / (5.6 * 2.5066) + 0.65 * exp(-sq(d / 22) / 2) / (22 * 2.5066));
}

// s is Brim.Frame.floats: 0 t, 1 surface y, 2 tan(tilt), 3 bob, 4-5 tremble left and right, 6 warn, 7 ripple, 8 the
// surface's y as the newest notch began, 9 seconds into that notch's spread, 10 the wet film's y, 11 its strength,
// 12 kick, 13 pulse, 14 fullness, 15 seconds since the fronts met at the brim (negative before), 16 flash, 17 brim pin
// brightness, 18 soak, 19 reach past the bezel, 20 degrees per tick, 21-22 as 8-9 for the notch before the newest,
// 23 how lit the jug is (0 empty).
[[ stitchable ]] half4 brim(float2 pos, float2 centre, float radius, device const float *s, int ns,
                            device const float *hue, int nh, device const float *lines, int nl) {
    float2 P = (pos - centre) * (R_PIC / radius);
    float r = length(P);
    if (r < R_PIC || r > R_OUT + s[19]) return half4(0);
    float dx = P.x, dy = P.y, t = s[0];
    float side = dx >= 0 ? 1 : -1;
    float phi = atan2(abs(dx), dy) * 180 / PI;
    float th = atan2(dy, dx);
    float u = (r - R_MID) / HALF_W, uc = clamp(u, -1.0, 1.0);
    float band = sstep(R_PIC + 0.6, R_PIC + 1.6, r) * (1 - sstep(R_OUT - 1.2, R_OUT - 0.2, r));
    bool inBand = r < R_OUT - 0.2;
    float arc = phi * PI / 180 * R_MID;
    float stepDeg = s[20];
    int room = int(round(180 / stepDeg));
    float tb = s[15];
    bool spilled = tb >= 0;
    float warn = s[6], kick = s[12], pulse = s[13], lit = s[23];
    float3 steel = chrome(th);
    float steelLum = (steel.r + steel.g + steel.b) / 3;
    float spec = saturate((steelLum - 0.0889) / 0.6353);
    float3 h = around(hue, nh, th);

    // The surface: a level chord across the rim, bobbing, sloshing, trembling as room runs out.
    float ys = s[1] + s[2] * dx + s[3];
    if (!spilled) {
        ys += s[7] * (0.6 * sin(dx / 23 + 2.1 * t) + 0.35 * sin(dx / 9 - 3.3 * t + 0.7));
        if (warn > 0) {
            ys += side > 0 ? s[5] : s[4];
            ys += warn * 0.9 * sin(dx / 3.1 + 53 * t) * sin(u * 2.3 + 31 * t);
        }
    }
    float men = 3.4 * uc * uc;
    float depth = dy - ys + men;
    float under = sstep(-0.9, 0.9, depth);

    // The spread: where a notch's pour has come up, the colour runs outward across the channel. Each of the last two
    // notches keeps its own time over the arc it wetted, so a push landing mid-spread leaves the one before running.
    float oldD = dy - s[8] + men, oldD2 = dy - s[21] + men;
    float tau = oldD <= 0 ? s[9] : oldD2 <= 0 ? s[22] : 1e3;
    float xs = saturate(tau / 0.4);
    float uf = -1.3 + 2.6 * xs * (2 - xs);
    float gate = sstep(-0.3, 0.3, uf - u);
    float fill = under * band * gate;

    // The liquid: the picture's own colour, glossy in its channel.
    float shimmer = 0.5 + 0.5 * sin(arc / 31 - 1.7 * t + 2.0 * sin(arc / 97 + 0.6 * t + side));
    float3 strk = around(lines, nl, th - side * 0.035 * sin(0.4 * t + arc / 211));
    float3 body = h * (0.40 + 0.12 * shimmer) + h * steelLum * 0.95 + strk * 0.10;
    body += h * 0.3 * exp(-max(depth, 0.0) / 2.2);
    body *= 1 - 0.45 * exp(-sq((uc + 1) / 0.3));
    body += exp(-sq((uc - 0.42) / 0.2)) * (0.08 + 0.3 * spec) * (0.55 + 0.45 * h);
    body *= 1 - 0.4 * exp(-sq((depth - 3.4) / 1.3));
    float alpha = 0.94 * fill;
    float3 C = body * alpha;
    float keep = 1 - alpha;

    // A wet film where the liquid stood a moment ago.
    if (s[11] > 0.01) {
        float wet = sstep(-0.9, 0.9, dy - s[10] + men) * band * (1 - fill) * s[11];
        C = C * (1 - 0.35 * wet) + h * 0.3 * wet;
        keep *= 1 - 0.35 * wet;
    }

    // The meniscus's glint, and the front's riding outward across the channel.
    float flick = 1 + 0.5 * warn * (0.5 + 0.5 * sin(2 * PI * 11.7 * t));
    float glint = exp(-sq(depth / 1.7)) * band * gate * (0.95 + 0.6 * spec) * (spilled ? 0.6 : 1.0);
    float3 glCol = (0.85 + 0.45 * h) * glint * flick * 1.15;
    float fg = exp(-sq((u - uf) / 0.16)) * under * band * (xs < 1 ? 1 - 0.6 * xs : 0.0);
    float3 fgCol = (0.6 + 0.7 * h) * fg;
    C += glCol + fgCol;
    float ahead = depth < 0 ? exp(depth / 3) * band * 0.16 : 0;
    float3 glow = body * alpha * (0.4 + 0.3 * kick) + glCol * 0.9 + fgCol * 1.2 + h * ahead * lit;

    // The liquid's light blurred out past the bezel, read off the channel's middle on this pixel's radius: the fill's
    // end and the glint soften with the distance, as a blur would.
    float outD = max(r - R_OUT, 0.0);
    // Off the bezel the line between old and newly wetted blurs with the distance, as the glow's blur spread it.
    float blur = 2 + 0.5 * outD;
    float fresh = 1 - sstep(-blur, blur, oldD);
    float fresh2 = (1 - sstep(-blur, blur, oldD2)) * (1 - fresh);
    float xf = saturate(s[9] / 0.4), uff = -1.3 + 2.6 * xf * (2 - xf);
    float xf2 = saturate(s[22] / 0.4), uff2 = -1.3 + 2.6 * xf2 * (2 - xf2);
    float reachedOff = 1 - fresh * (1 - sstep(-0.3, 0.3, uff - 1.0)) - fresh2 * (1 - sstep(-0.3, 0.3, uff2 - 1.0));
    if (outD > 0) {
        float soft = 6 + 0.5 * outD;
        float ym = s[1] + s[2] * dx * R_MID / r + s[3];
        float dm = dy * R_MID / r - ym;
        float gm = 1 - fresh * (1 - sstep(-0.3, 0.3, uff)) - fresh2 * (1 - sstep(-0.3, 0.3, uff2));
        float fm = sstep(-0.9 - soft, 0.9 + soft, dm) * gm;
        float3 bm = h * (0.52 + steelLum * 0.95);
        float gl = exp(-sq(dm / (1.7 + soft))) * 1.7 / (1.7 + soft) * gm * (spilled ? 0.6 : 1.0) * flick;
        float rho = r - R_PIC, w = R_OUT - R_PIC;
        float k = 0.8 * (cdf((w - rho) / 5.6) - cdf(-rho / 5.6)) + 0.65 * (cdf((w - rho) / 22) - cdf(-rho / 22));
        glow += k * lit * BLOOM * (bm * 0.94 * fm * (0.4 + 0.3 * kick) + (0.85 + 0.45 * h) * gl * 0.9);
    }

    // Engraved ticks: grooves in bare steel, liquid-filled lines below the surface, lit marks past the bezel.
    int kt = clamp(int(round(phi / stepDeg)), 1, room - 1);
    float along = abs(phi - kt * stepDeg) * PI / 180 * r;
    float tick = (1 - sstep(1.3, 2.7, along)) * sstep(R_PIC + 2.0, R_PIC + 3.5, r) * (1 - sstep(R_OUT + 14.8, R_OUT + 16, r));
    float litPoke = sstep(-2.0, 2.0, R_OUT * cos(kt * stepDeg * PI / 180) - ys + 2.4);
    if (inBand) {
        float m = mix(1 - 0.72 * tick, 1 - tick, fill);
        C = C * m + fill * tick * (0.3 + 0.75 * h);
        keep *= m;
    } else {
        C = C * (1 - tick) + tick * mix(float3(0.70, 0.73, 0.79), 0.25 + 0.95 * h, litPoke);
        keep *= 1 - tick;
    }
    if (r > R_OUT - 2 && r < R_OUT + 40) {
        float beyond = max(r - (R_OUT + 16), 0.0);
        glow += h * 0.8 * litPoke * lineGlow(length(float2(along, beyond)), 4) * sstep(R_OUT - 2, R_OUT + 2, r);
    }

    // The filled arc blooms outward onto the black, stronger and further as the room runs out; the empty arc never
    // glows. Each notch's colour runs on past the rim as a surge that settles into the bloom.
    float fullness = s[14];
    float gain = 0.06 + 0.16 * fullness + 0.10 * kick + warn * (0.03 + 0.14 * pulse * pulse);
    float reach = 6 + 10 * fullness + 4 * warn * pulse;
    float outside = sstep(R_OUT - 1, R_OUT + 0.5, r);
    float soft = 3 + 0.4 * outD;
    float underSoft = sstep(-0.9 - soft, 0.9 + soft, depth);
    float bloom = 0.55 * exp(-outD / (reach + 3)) + 0.45 * exp(-outD / (reach + 16));
    glow += h * bloom * 1.3 * BLOOM * gain * lit * underSoft * reachedOff * outside;
    glow += h * 0.75 * outside * underSoft * (fresh * surge(s[9], outD) + fresh2 * surge(s[22], outD));

    // Over the brim: a crest swells over the lip at twelve where the fronts meet and breaks, and the liquid pours
    // down the outside of the rim either way, a wave that thins behind a swollen bead at each head. The heads slow
    // past three and nine o'clock, where drops fall from them onto the black, and what ran over soaks away. It is
    // dressed as the mockup's sheet: the rim's colour kept darker than the rim, the picture's lines running with the
    // flow, a dark seam against the steel and a glint only on its lip, so the rim keeps its edge.
    if (spilled) {
        float psi = 180 - phi;
        float tp = tb - 0.30;
        float soak = s[18];
        float head = tp > 0 ? HEAD * (1 - exp(-tp / 0.45)) : 0;
        float passed = psi < HEAD - 0.1 ? tp + 0.45 * log(1 - psi / HEAD) : -1;
        float wave = passed > 0 ? (26 * (1 - 0.45 * psi / HEAD) * exp(-passed / 1.2) + 7 * exp(-passed / 2.5)) : 0;
        wave *= sstep(0.0, 0.1, passed) * (1 + 0.15 * sin(psi * 0.3 - tp * 8));
        float crest = 36 * sstep(0.0, 0.3, tb) * (tp > 0 ? 0.4 + 0.6 * exp(-tp / 0.3) : 1.0) * exp(-sq(psi / 14));
        float sheetD = R_OUT + max(wave, crest) - r;
        float bR = tp > 0 ? (9 + 3 * exp(-tp / 0.6)) * sstep(0.0, 0.12, tp) * (1 - 0.4 * sstep(1.0, 1.9, tp)) : 0;
        float pb = (head - 0.6 * bR / R_OUT * 180 / PI) * PI / 180;
        float2 bc = float2(side * sin(pb), -cos(pb)) * (R_OUT + 0.6 * bR);
        float bead = bR - length(P - bc), inBead = sstep(-0.9, 0.9, bead);
        float sedge = max(sheetD, bead);
        float ov = sstep(-0.9, 0.9, sedge) * outside * soak;
        float thick = saturate(sedge / 16);
        float3 flow = around(lines, nl, th - side * 0.6 * head * PI / 180);
        float3 sheet = h * (0.28 + 0.24 * thick) + flow * 0.4 * exp(-outD / 45);
        sheet *= (1 - 0.5 * exp(-sq((sheetD - 3.2) / 1.5))) * (1 - 0.6 * exp(-outD / 1.6));
        // The bead is a drop of the rim's own liquid: rounder and brighter than the sheet, darker at its edge, and lit
        // from above.
        float2 bu = normalize(bc);
        float2 spot = bc + (0.4 * bu + float2(0, -0.25)) * bR;
        float3 bShine = (0.25 + 0.8 * h) * exp(-length_squared(P - spot) / sq(0.35 * bR));
        sheet = mix(sheet, h * (0.5 + 0.12 * shimmer) * (0.6 + 0.4 * sstep(0.0, 0.6 * bR, bead)) + bShine, inBead);
        C = C * (1 - 0.94 * ov) + sheet * 0.94 * ov;
        keep *= 1 - 0.94 * ov;
        float3 lip = (0.25 + 0.8 * h) * exp(-sq(sheetD / 1.3)) * (1 - inBead) * outside * soak * (0.35 + 0.65 * spec);
        C += lip;
        glow += lip * 0.8 + bShine * inBead * ov * 0.8;
        float rimEdge = exp(-sq((r - R_OUT) / 2.5));
        glow += (0.5 + 0.7 * h) * rimEdge * (passed >= 0 ? exp(-passed / 0.25) : 0) * 0.6;
        // Drops fall from this side's head once it has slowed: each leaves with the run's pace, and gravity takes it.
        for (int k = 0; k < 2; k++) {
            float td = 1.0 + 0.45 * k, since = tp - td;
            if (since <= 0 || since > 0.75) continue;
            float pa = HEAD * (1 - exp(-td / 0.45)) * PI / 180;
            float2 away = float2(side * sin(pa), -cos(pa)), down = float2(side * cos(pa), sin(pa));
            float2 v0 = down * 50 + away * 25;
            float2 v = v0 + float2(0, 800 * since);
            float2 at = away * (R_OUT + 6) + v0 * since + float2(0, 400 * since * since);
            float2 tail = at - v * 0.012, e = P - at, f = tail - at;
            float rd = 5.5 * (1 - 0.3 * since);
            float dd = length(e - f * saturate(dot(e, f) / max(dot(f, f), 1e-4))) - rd;
            float drop = sstep(0.9, -0.9, dd) * (1 - sstep(0.45, 0.75, since)) * outside;
            float3 shine = (0.25 + 0.8 * h) * exp(-length_squared(e + float2(0.35, 0.45) * rd) / sq(0.7 * rd));
            C = C * (1 - 0.94 * drop) + (h * 0.45 + shine) * 0.94 * drop;
            keep *= 1 - 0.94 * drop;
            glow += shine * drop * 0.8;
        }
    }

    // The glow lands before the brim pin, so the pin stays on top of a spill; half of it is kept off the steel, and
    // none reaches the glass.
    float onSteel = 1 - sstep(R_OUT - 0.5, R_OUT + 0.5, r);
    C += glow * (1 - 0.6 * onSteel);

    // The brim pin: brighter than the rest, pulsing as the room runs out.
    float3 white = float3(1.0, 0.97, 0.92);
    float bdist = (180 - phi) * PI / 180 * r;
    float capY = -(R_OUT + 34);
    float pin = (1 - sstep(3.1, 4.5, bdist)) * sstep(R_PIC + 1.0, R_PIC + 2.5, r) * (1 - sstep(R_OUT + 32.8, R_OUT + 34, r));
    pin = max(pin, 1 - sstep(6.6, 8.0, length(float2(dx, dy - capY))));
    float toPin = length(float2(dx, clamp(dy, capY, -R_OUT) - dy));
    float bri = s[17];
    C = C * (1 - pin) + pin * min(white * bri, 1.6);
    keep *= 1 - pin;
    float pinLight = bri * (0.7 + 1.1 * warn * pulse);
    C += white * (dy < -R_OUT + 4 ? 1 - 0.6 * onSteel : 0)
         * (pinLight * lineGlow(toPin, 7.6) + exp(-toPin / 6) * warn * (0.25 + 0.6 * pulse * pulse) * 0.6);

    // Faded out before the ring's outer edge, so the glow never ends in a step.
    float fade = 1 - sstep(R_OUT + s[19] - 24, R_OUT + s[19], r);
    C *= fade;
    keep = 1 - (1 - keep) * fade;
    return half4(half3(C), half(1 - keep));
}

// The most taps the murk takes along a pixel's footprint.
constant float TAPS = 48;

// After the spill: the picture as the tank left it, stirred together by `stirs` (x, y, disc radius, turn per stir, in
// tank units, oldest first). Unlike a rod's twist, each shears all the way in, so no core is left unmixed. A pixel's
// footprint is carried back through the stirs with it (each is area-preserving, so it becomes a long thin sliver) and
// sampled along its length in linear light, so lines the stir draws finer than a pixel mix their colours instead of
// glittering.
[[ stitchable ]] half4 murk(float2 pos, SwiftUI::Layer layer, float2 centre, float radius, device const float *stirs,
                            int count, float scale) {
    float2 p = (pos - centre) / radius;
    float2x2 J = float2x2(1.0);
    for (int i = count / 4 - 1; i >= 0; i--) {
        float2 c = float2(stirs[4 * i], stirs[4 * i + 1]);
        float2 d = p - c;
        float rr = sq(stirs[4 * i + 2]), s2 = dot(d, d) / rr;
        if (s2 >= 1.0) continue;
        float turn = stirs[4 * i + 3], a = -turn * (1 - s2);
        float cs = cos(a), sn = sin(a);
        float2x2 R = float2x2(float2(cs, sn), float2(-sn, cs));
        float2 q = R * d;
        // d(c + R(a) d)/dd = R + (dR/da d) (da/dd)ᵀ, where dR/da d is q turned a quarter and da/dd = 2 turn d / rr.
        float2 g = 2 * turn / rr * d;
        J = (R + float2x2(float2(-q.y, q.x) * g.x, float2(-q.y, q.x) * g.y)) * J;
        p = c + q;
    }
    // The footprint's long axis: the larger singular value of J, and where it sends the screen's pixel.
    float a2 = length_squared(J[0]) + length_squared(J[1]);
    float det = J[0].x * J[1].y - J[1].x * J[0].y;
    float big = sqrt(max(0.5 * (a2 + sqrt(max(a2 * a2 - 4 * det * det, 0.0))), 1e-6));
    float2x2 JtJ = transpose(J) * J;
    float2 v = abs(JtJ[1].x) > 1e-6 ? normalize(float2(JtJ[1].x, big * big - JtJ[0].x))
        : (JtJ[0].x >= JtJ[1].y ? float2(1, 0) : float2(0, 1));
    float2 along = J * v / (scale * radius);
    // Past TAPS a tap stands for more than a pixel of the picture, so each is jittered within its share of the sliver:
    // fine grain rather than the moiré of evenly spaced taps.
    int n = int(clamp(ceil(big), 1.0, TAPS));
    float jitter = big > TAPS ? fract(sin(dot(pos, float2(12.9898, 78.233))) * 43758.5453) - 0.5 : 0.0;
    float3 acc = 0;
    for (int j = 0; j < n; j++) {
        float3 c = float3(layer.sample(centre + (p + along * ((j + 0.5 + jitter) / n - 0.5)) * radius).rgb);
        acc += c * c;
    }
    return half4(half3(sqrt(acc / n)), 1.0h);
}
