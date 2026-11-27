// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: beetles as an entomologist's plate: a stag beetle, a longhorn, a jewel beetle, a scarab, a weevil and a
/// ladybird, each with its sculpted elytra, pronotum, legs and antennae, at different angles and sizes, with a grub, a
/// loose wing case and small beetles between them.
enum Beetles {
    typealias Line = Engraving.Line
    private typealias E = Engraving
    private typealias P = SIMD2<Double>

    /// A specimen's own units: x across the body, y from head to tail with the elytra's base at 0 and their apex at 1,
    /// scaled by `s` and turned `a` clockwise about `c`.
    private struct Frame {
        var c: P, a: Double, s: Double
        func callAsFunction(_ p: P) -> P { c + s * P(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a)) }
        func map(_ ps: [P]) -> [P] { ps.map { self($0) } }
    }

    /// Strokes for a specimen's outline, body and sculpture, and how much of the sculpture its size can hold.
    private struct Pen { var outline: Double, body: Double, fine: Double, detail: Double }
    private static let big = Pen(outline: E.heavy, body: E.medium, fine: E.fine, detail: 1)
    private static let mid = Pen(outline: E.medium, body: E.fine, fine: E.fine, detail: 0.7)
    private static let small = Pen(outline: E.fine, body: E.fine, fine: E.fine, detail: 0.4)

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4245_4554)
        var out: [Line] = []
        stag(&out, &rng, Frame(c: P(-0.3, -0.16), a: -0.42, s: 0.33), big)
        longhorn(&out, &rng, Frame(c: P(0.4, -0.4), a: 0.5, s: 0.3), big)
        jewel(&out, &rng, Frame(c: P(0.52, 0.16), a: 2.3, s: 0.28), big)
        scarab(&out, &rng, Frame(c: P(0.02, 0.48), a: 3.5, s: 0.25), big)
        weevil(&out, &rng, Frame(c: P(-0.58, 0.2), a: -2.3, s: 0.2), big)
        ladybird(&out, &rng, Frame(c: P(0.5, 0.68), a: 0.9, s: 0.17), big)
        grub(&out, Frame(c: P(-0.3, 0.8), a: 0.3, s: 0.1), mid)
        weevil(&out, &rng, Frame(c: P(-0.8, -0.3), a: 0.4, s: 0.1), small)
        jewel(&out, &rng, Frame(c: P(-0.5, -0.74), a: -0.9, s: 0.09), small)
        wingCase(&out, Frame(c: P(0.84, -0.1), a: -0.2, s: 0.24), mid)
        carabid(&out, &rng, Frame(c: P(0.0, -0.56), a: 0.5, s: 0.16), mid)
        for (c, a, size) in [(P(-0.22, -0.86), 1.3, 0.08), (P(0.1, 0.1), -0.8, 0.08), (P(-0.86, 0.04), 2.6, 0.07),
                             (P(0.88, 0.32), -2.4, 0.07), (P(-0.6, 0.72), 0.7, 0.08), (P(0.12, 0.88), -1.9, 0.07)] {
            carabid(&out, &rng, Frame(c: c, a: a, s: size), small)
        }
        return out
    }()

    /// Both elytra from the outer edge's half-width `w` at t (base 0, apex 1), a hair apart at the suture.
    private static func elytra(_ out: inout [Line], _ f: Frame, _ pen: Pen, sides: [Double] = [1, -1],
                               _ w: (Double) -> Double) {
        for side in sides {
            var pts = [P(side * gap, 0)]
            for i in 0...80 {
                let t = Double(i) / 80
                pts.append(P(side * (gap + w(t)), t))
            }
            pts.append(P(side * gap, 1))
            pts.append(P(side * gap, 0))
            out.append(Line(points: f.map(pts), width: pen.outline))
        }
    }

    private static let gap = 0.006

    /// A line along an elytron at `frac` of its width, from t0 to t1.
    private static func stria(_ w: (Double) -> Double, _ side: Double, _ frac: Double, _ t0: Double, _ t1: Double,
                              _ n: Int = 40) -> [P] {
        (0...n).map { i in
            let t = t0 + (t1 - t0) * Double(i) / Double(n)
            return P(side * (gap + frac * w(t)), t)
        }
    }

    private static func dot(_ p: P, _ r: Double) -> [P] { E.circle(p, r, 6) }

    /// The pronotum, its base at 0 and its front at -length, half-width `w` at s (base 0, front 1), with the scutellum.
    private static func pronotum(_ out: inout [Line], _ f: Frame, _ pen: Pen, length: Double, _ w: (Double) -> Double) {
        let base = -0.012
        var pts: [P] = []
        for i in 0...40 { pts.append(P(w(Double(i) / 40), base - length * Double(i) / 40)) }
        pts += E.curve(P(w(1), base - length), P(0, base - length + 0.06 * length), P(-w(1), base - length), 16).dropFirst()
        for i in (0...40).reversed() { pts.append(P(-w(Double(i) / 40), base - length * Double(i) / 40)) }
        pts += E.curve(P(-w(0), base), P(0, base + 0.03), P(w(0), base), 16).dropFirst()
        out.append(Line(points: f.map(pts), width: pen.outline))
        out.append(Line(points: f.map([P(-0.035, 0.004), P(0, 0.07), P(0.035, 0.004)]), width: pen.fine))
    }

    /// A limb's closed outline from a to b, half-widths wa and wb, swelling by `bulge` midway, with `teeth` on one edge.
    private static func limb(_ a: P, _ b: P, _ wa: Double, _ wb: Double, bulge: Double = 0, teeth: Int = 0,
                             toothSide: Double = 1) -> [P] {
        let d = simd_normalize(b - a), n = P(-d.y, d.x), m = 14
        func half(_ t: Double, _ s: Double) -> Double {
            var h = wa + (wb - wa) * t + bulge * sin(.pi * t)
            if teeth > 0, s == toothSide, t > 0.4 {
                let k = (t - 0.4) / 0.6 * Double(teeth)
                h += 1.3 * wb * pow(k - floor(k), 2)
            }
            return h
        }
        let left = (0...m).map { i -> P in let t = Double(i) / Double(m); return a + t * (b - a) + half(t, 1) * n }
        let right = (0...m).reversed().map { i -> P in let t = Double(i) / Double(m); return a + t * (b - a) - half(t, -1) * n }
        return left + right + [left[0]]
    }

    private static func toward(_ angle: Double) -> P { P(cos(angle), sin(angle)) }

    /// A leg on each side from `root` (on the right): femur, tibia and a tarsus of beads ending in two claws. Angles are
    /// in the specimen's units from +x, positive towards the tail.
    private static func legs(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, _ pen: Pen, root: P,
                             angles: (Double, Double, Double), lengths: (Double, Double, Double), femur: Double,
                             tibia: Double, bulge: Double = 0, teeth: Int = 0, tarsi: Int = 4) {
        for side in [1.0, -1.0] {
            func d(_ a: Double) -> P { let v = toward(a); return P(side * v.x, v.y) }
            let hip = P(side * root.x, root.y)
            let j0 = Double.random(in: -0.12..<0.12, using: &rng), j1 = Double.random(in: -0.12..<0.12, using: &rng)
            let j2 = Double.random(in: -0.12..<0.12, using: &rng)
            let knee = hip + lengths.0 * d(angles.0 + j0)
            let ankle = knee + lengths.1 * d(angles.1 + j1)
            out.append(Line(points: f.map(limb(hip, knee, 0.55 * femur, 0.4 * femur, bulge: 0.5 * femur + bulge)), width: pen.body))
            out.append(Line(points: f.map(limb(knee, ankle, 0.35 * femur, tibia, bulge: 0.2 * tibia, teeth: teeth, toothSide: -side)), width: pen.body))
            let shin = simd_normalize(ankle - knee)
            for c in [-0.45, 0.45] {
                let spur = P(shin.x * cos(c) - shin.y * sin(c), shin.x * sin(c) + shin.y * cos(c))
                out.append(Line(points: f.map([ankle, ankle + 1.6 * tibia * spur]), width: pen.fine))
            }
            var at = ankle
            let ta = angles.2 + j2, seg = lengths.2 / Double(tarsi)
            for k in 0..<tarsi {
                let next = at + seg * d(ta + 0.05 * Double(k))
                let wd = 0.5 * tibia * (k == tarsi - 1 ? 0.7 : 1)
                out.append(Line(points: f.map(limb(at, next, 0.35 * wd, 0.6 * wd, bulge: 0.35 * wd)), width: pen.fine))
                at = next
            }
            for c in [-0.45, 0.45] {
                let tip = at + 0.4 * seg * d(ta + c)
                out.append(Line(points: f.map(E.curve(at, at + 0.25 * seg * d(ta + 0.3 * c), tip, 6)), width: pen.fine))
            }
        }
    }

    /// Joints of an antenna or snout from `root`, setting off at `heading` (from +x, towards the tail positive) and
    /// turning by `bend` over each segment.
    private static func path(_ root: P, heading: Double, bend: Double, _ lengths: [Double]) -> [P] {
        var at = root, h = heading
        var joints = [root]
        for l in lengths {
            at += l * toward(h)
            joints.append(at)
            h += bend
        }
        return joints
    }

    private static func mirrored(_ ps: [P]) -> [P] { ps.map { P(-$0.x, $0.y) } }

    /// The compound eye: an oval with an arc of shine inside it.
    private static func eye(_ out: inout [Line], _ f: Frame, _ pen: Pen, _ c: P, _ r: Double) {
        for side in [1.0, -1.0] {
            let at = P(side * c.x, c.y)
            out.append(Line(points: f.map(E.arc(at, r, from: 0, to: 2 * .pi, 18)), width: pen.body))
            if pen.detail > 0.6 {
                out.append(Line(points: f.map(E.arc(at, 0.55 * r, from: 2.4, to: 4.2, 8)), width: pen.fine))
            }
        }
    }

    /// Stag beetle: parallel shining elytra, a broad head and great antler mandibles, toothed within and forked at the
    /// tip, and elbowed antennae ending in a comb.
    private static func stag(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, _ pen: Pen) {
        let w: (Double) -> Double = { t in t < 0.72 ? 0.34 + 0.02 * sin(t / 0.72 * .pi) : 0.34 * sqrt(max(0, 1 - pow((t - 0.72) / 0.28, 2))) }
        elytra(&out, f, pen, w)
        for side in [1.0, -1.0] {
            // Lines following the curve of each wing case, broken where the shine stands along the shoulder.
            out.append(Line(points: f.map(stria(w, side, 0.94, 0.02, 0.97, 60)), width: pen.fine))
            for k in 1...7 {
                let frac = Double(k) / 8, glint = side > 0 ? 0.5 : 0.62
                let t1 = 0.95 - 0.08 * frac
                if abs(frac - glint) < 0.12 {
                    out.append(Line(points: f.map(stria(w, side, frac, 0.62 + 0.2 * abs(frac - glint), t1)), width: pen.fine))
                } else {
                    out.append(Line(points: f.map(stria(w, side, frac, 0.03, t1, 50)), width: pen.fine))
                }
            }
        }
        let P0 = 0.4
        pronotum(&out, f, pen, length: P0) { s in 0.36 + 0.05 * sin(.pi * s) - 0.05 * s * s }
        out.append(Line(points: f.map([P(0, -0.05), P(0, -P0 + 0.05)]), width: pen.fine))
        for side in [1.0, -1.0] {
            out.append(Line(points: f.map(E.curve(P(side * 0.3, -0.06), P(side * 0.34, -0.2), P(side * 0.28, -0.34), 12)), width: pen.fine))
        }
        // The head, broader than the pronotum's front, its temples swelling behind the eyes.
        let h0 = -P0 - 0.03, h1 = h0 - 0.28
        var right: [P] = E.curve(P(0.24, h0), P(0.5, h0 - 0.01), P(0.46, h0 - 0.16), 12)
        right += E.curve(P(0.46, h0 - 0.16), P(0.44, h1 + 0.02), P(0.24, h1), 12).dropFirst()
        right += E.curve(P(0.24, h1), P(0.12, h1 + 0.04), P(0, h1 + 0.03), 10).dropFirst()
        let head = right + mirrored(right.reversed()).dropFirst()
        out.append(Line(points: f.map(head), width: pen.outline))
        out.append(Line(points: f.map(E.curve(P(-0.3, h0 - 0.12), P(0, h0 - 0.2), P(0.3, h0 - 0.12), 16)), width: pen.fine))
        eye(&out, f, pen, P(0.43, h0 - 0.24), 0.045)
        // Mandibles: each bowing out and in again, a tooth standing in from it past halfway, the tip forked in two.
        for side in [1.0, -1.0] {
            let a = P(side * 0.16, h1 + 0.01), c = P(side * 0.5, h1 - 0.42), b = P(side * 0.2, h1 - 0.8)
            let n = 48
            let centre = E.curve(a, c, b, n)
            func normal(_ i: Int) -> P {
                let d = simd_normalize(centre[min(i + 1, n)] - centre[max(i - 1, 0)])
                return P(-d.y, d.x) * side
            }
            let hw = (0...n).map { 0.062 * (1 - Double($0) / Double(n)) + 0.016 }
            let outer = (0...n).map { centre[$0] + hw[$0] * normal($0) }
            let inner = (0...n).map { i -> P in
                let tooth = 0.075 * max(0, 1 - abs(Double(i - 30)) / 4) + 0.035 * max(0, 1 - abs(Double(i - 40)) / 2.5)
                return centre[i] - (hw[i] + tooth) * normal(i)
            }
            let along = simd_normalize(centre[n] - centre[n - 3])
            let prongA = centre[n] + 0.09 * simd_normalize(along + 0.5 * normal(n))
            let prongB = centre[n] + 0.07 * simd_normalize(along - 0.9 * normal(n))
            let notch = centre[n] + 0.01 * along
            out.append(Line(points: f.map(outer + [prongA, notch, prongB] + inner.reversed()), width: pen.outline))
            out.append(Line(points: f.map((4...36).map { centre[$0] + 0.4 * hw[$0] * normal($0) }), width: pen.fine))
        }
        // Elbowed antennae: a long scape, then the funicle, then four comb leaves.
        for side in [1.0, -1.0] {
            let j = path(P(0.36, h1 + 0.1), heading: -0.6, bend: 0, [0.3])
            let fun = path(j[1], heading: -1.75, bend: -0.12, [0.05, 0.05, 0.05, 0.05, 0.05])
            let all = j + fun.dropFirst()
            let m = all.map { P(side * $0.x, $0.y) }
            out.append(Line(points: f.map(limb(m[0], m[1], 0.016, 0.022)), width: pen.body))
            for k in 1..<(m.count - 1) {
                out.append(Line(points: f.map(limb(m[k], m[k + 1], 0.01, 0.016, bulge: 0.004)), width: pen.body))
            }
            let tip = m.last!, along = simd_normalize(tip - m[m.count - 2])
            for k in 0..<4 {
                let base = tip + 0.036 * Double(k) * along
                let leaf = base + 0.075 * simd_normalize(P(side, -0.35)) + 0.012 * along
                out.append(Line(points: f.map(limb(base, leaf, 0.006, 0.01, bulge: 0.004)), width: pen.fine))
            }
        }
        legs(&out, &rng, f, pen, root: P(0.34, -0.16), angles: (-0.35, -0.95, -1.25), lengths: (0.36, 0.42, 0.26),
             femur: 0.04, tibia: 0.03)
        legs(&out, &rng, f, pen, root: P(0.34, 0.12), angles: (0.15, 0.55, 0.9), lengths: (0.38, 0.4, 0.28),
             femur: 0.04, tibia: 0.028)
        legs(&out, &rng, f, pen, root: P(0.34, 0.3), angles: (0.65, 1.15, 1.3), lengths: (0.42, 0.44, 0.3),
             femur: 0.04, tibia: 0.028)
    }

    /// Longhorn: a narrow body, a spined pronotum wrinkled across, elytra barred with hatched bands and punctured, and
    /// antennae half again the body's length, each segment banded at its base.
    private static func longhorn(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, _ pen: Pen) {
        let w: (Double) -> Double = { t in
            if t < 0.07 { return 0.19 + 0.06 * sin(t / 0.07 * .pi / 2) }
            if t < 0.85 { return 0.25 * (1 - 0.3 * (t - 0.07)) }
            return 0.25 * 0.766 * sqrt(max(0, 1 - pow((t - 0.85) / 0.15, 2)))
        }
        elytra(&out, f, pen, w)
        let bands = [(0.24, 0.38), (0.58, 0.71)]
        for side in [1.0, -1.0] {
            // Two dark bars across each wing case, hatched between wavy edges, and rows of punctures between them.
            func edge(_ t: Double, _ x: Double) -> Double { t + 0.016 * sin(x * 38 + 3 * t + side) }
            for (t0, t1) in bands {
                for tt in [t0, t1] {
                    out.append(Line(points: f.map((0...14).map { i in
                        let x = 0.015 + (w(tt) - 0.02) * Double(i) / 14
                        return P(side * (gap + x), edge(tt, x))
                    }), width: pen.fine))
                }
                var x = 0.03
                while x < w(t0) - 0.02 {
                    out.append(Line(points: f.map([P(side * (gap + x), edge(t0, x)), P(side * (gap + x - 0.02), edge(t1, x - 0.02))]), width: pen.fine))
                    x += 0.026
                }
            }
            guard pen.detail > 0.6 else { continue }
            for k in 1...3 {
                let frac = Double(k) / 4
                var t = 0.06
                while t < 0.86 {
                    if !bands.contains(where: { t > $0.0 - 0.04 && t < $0.1 + 0.04 }) {
                        out.append(Line(points: f.map(dot(P(side * (gap + frac * w(t)), t), 0.007)), width: pen.fine))
                    }
                    t += 0.05
                }
            }
        }
        let P0 = 0.32
        pronotum(&out, f, pen, length: P0) { s in 0.15 + 0.012 * sin(.pi * s) + 0.08 * max(0, 1 - abs(s - 0.45) / 0.14) }
        for k in 1...5 {
            let y = -0.02 - P0 * Double(k) / 6.5
            out.append(Line(points: f.map(E.curve(P(-0.12, y), P(0, y - 0.03), P(0.12, y), 10)), width: pen.fine))
        }
        let h0 = -P0 - 0.02, h1 = h0 - 0.17
        var head: [P] = E.curve(P(0.13, h0), P(0.17, h0 - 0.08), P(0.1, h1), 10)
        head += E.curve(P(0.1, h1), P(0, h1 - 0.03), P(-0.1, h1), 10).dropFirst()
        head += E.curve(P(-0.1, h1), P(-0.17, h0 - 0.08), P(-0.13, h0), 10).dropFirst()
        out.append(Line(points: f.map(head), width: pen.outline))
        out.append(Line(points: f.map([P(0, h0 - 0.01), P(0, h1 + 0.03)]), width: pen.fine))
        for side in [1.0, -1.0] {
            out.append(Line(points: f.map(E.arc(P(side * 0.12, h0 - 0.08), 0.045, from: side > 0 ? -1.6 : 1.4, to: side > 0 ? 1.8 : 4.9, 12)), width: pen.body))
        }
        // The antennae: eleven segments sweeping out and back past the elytra's tips.
        for side in [1.0, -1.0] {
            let lengths = [0.13, 0.05] + (0..<9).map { 0.26 * (1 - 0.03 * Double($0)) }
            let j = path(P(0.1, h1 + 0.05), heading: -1.25, bend: side > 0 ? 0.3 : 0.26, lengths)
            let m = j.map { P(side * $0.x, $0.y) }
            for k in 0..<(m.count - 1) {
                let wd = max(0.01, 0.024 - 0.0014 * Double(k))
                out.append(Line(points: f.map(limb(m[k], m[k + 1], wd, 0.8 * wd, bulge: k == 0 ? 0.01 : 0)), width: pen.body))
                guard k >= 2 else { continue }
                let a = m[k], b = m[k + 1], d = simd_normalize(b - a), nrm = P(-d.y, d.x)
                for q in 0..<4 {
                    let c = a + (0.06 + 0.12 * Double(q)) * simd_length(b - a) * d
                    out.append(Line(points: f.map([c + wd * nrm, c - wd * nrm]), width: pen.fine))
                }
            }
        }
        legs(&out, &rng, f, pen, root: P(0.14, -0.18), angles: (-0.5, -1.0, -1.3), lengths: (0.3, 0.3, 0.2),
             femur: 0.03, tibia: 0.018)
        legs(&out, &rng, f, pen, root: P(0.22, 0.08), angles: (0.1, 0.7, 1.0), lengths: (0.34, 0.34, 0.2),
             femur: 0.03, tibia: 0.018)
        legs(&out, &rng, f, pen, root: P(0.2, 0.26), angles: (0.75, 1.25, 1.35), lengths: (0.46, 0.48, 0.24),
             femur: 0.03, tibia: 0.018, bulge: 0.012)
    }

    /// Jewel beetle: a bullet's taper to a serrated apex, the elytra ribbed with costae between punctured striae, a
    /// strigose pronotum, great eyes and short serrate antennae.
    private static func jewel(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, _ pen: Pen) {
        let w: (Double) -> Double = { t in
            let body = t < 0.25 ? 0.28 + 0.02 * sin(t / 0.25 * .pi / 2) : 0.3 * pow(max(0, 1 - (t - 0.25) / 0.75), 0.7)
            return body + (t > 0.72 && t < 0.98 ? 0.008 * abs(sin(t * 70)) : 0)
        }
        elytra(&out, f, pen, w)
        let n = max(3, Int(8 * pen.detail))
        for side in [1.0, -1.0] {
            for k in 1...n {
                let frac = Double(k) / Double(n + 1), t1 = k % 2 == 1 ? 0.9 - 0.2 * frac : 0.72 - 0.15 * frac
                if k % 2 == 1 {
                    out.append(Line(points: f.map(stria(w, side, frac - 0.025, 0.03, t1)), width: pen.fine))
                    out.append(Line(points: f.map(stria(w, side, frac + 0.025, 0.03, t1)), width: pen.fine))
                } else if pen.detail > 0.6 {
                    var t = 0.04
                    while t < t1 {
                        out.append(Line(points: f.map(dot(P(side * (gap + frac * w(t)), t), 0.006)), width: pen.fine))
                        t += 0.045
                    }
                } else {
                    out.append(Line(points: f.map(stria(w, side, frac, 0.03, t1)), width: pen.fine))
                }
            }
            // An impressed spot near the shoulder and another before the apex.
            out.append(Line(points: f.map(E.arc(P(side * (gap + 0.17), 0.36), 0.04, from: 0, to: 2 * .pi, 14)), width: pen.fine))
            out.append(Line(points: f.map(E.arc(P(side * (gap + 0.1), 0.68), 0.03, from: 0, to: 2 * .pi, 12)), width: pen.fine))
        }
        let P0 = 0.3
        pronotum(&out, f, pen, length: P0) { s in 0.3 * (1 - 0.3 * s) - 0.04 * pow(s, 4) }
        let rows = Int(7 * pen.detail + 1)
        for k in 1...rows {
            let y = -0.02 - P0 * Double(k) / Double(rows + 1)
            let half = 0.3 * (1 - 0.3 * (-y / P0)) - 0.03
            out.append(Line(points: f.map((0...16).map { i in
                let x = -half + 2 * half * Double(i) / 16
                return P(x, y - 0.03 * (1 - x * x / (half * half)))
            }), width: pen.fine))
        }
        let h0 = -P0 - 0.015, h1 = h0 - 0.1
        let brow = E.curve(P(0.2, h0), P(0.17, h1 - 0.02), P(0, h1), 10) + E.curve(P(0, h1), P(-0.17, h1 - 0.02), P(-0.2, h0), 10).dropFirst()
        out.append(Line(points: f.map(brow), width: pen.outline))
        eye(&out, f, pen, P(0.165, h0 - 0.035), 0.05)
        for side in [1.0, -1.0] {
            let j = path(P(0.08, h1 + 0.01), heading: -1.95, bend: -0.06, [Double](repeating: 0.038, count: 10))
            let m = j.map { P(side * $0.x, $0.y) }
            for k in 0..<(m.count - 1) {
                let d = simd_normalize(m[k + 1] - m[k]), nrm = P(-d.y, d.x) * -side
                let tooth = m[k + 1] + (k < 2 ? 0.008 : 0.02) * nrm
                out.append(Line(points: f.map([m[k], tooth, m[k + 1]]), width: pen.fine))
            }
        }
        legs(&out, &rng, f, pen, root: P(0.24, -0.16), angles: (-0.6, -1.1, -1.3), lengths: (0.2, 0.2, 0.14),
             femur: 0.03, tibia: 0.018)
        legs(&out, &rng, f, pen, root: P(0.28, 0.1), angles: (0.2, 0.7, 1.0), lengths: (0.2, 0.22, 0.14),
             femur: 0.03, tibia: 0.018)
        legs(&out, &rng, f, pen, root: P(0.26, 0.3), angles: (0.7, 1.2, 1.3), lengths: (0.26, 0.26, 0.16),
             femur: 0.03, tibia: 0.018)
    }

    /// Scarab: a broad rounded body with faint striae, a granulate pronotum, the clypeus fanned into six teeth, a
    /// lamellate club and digging fore tibiae toothed along their outer edge.
    private static func scarab(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, _ pen: Pen) {
        let w: (Double) -> Double = { t in t < 0.55 ? 0.46 + 0.04 * sin(t / 0.55 * .pi / 2) : 0.5 * sqrt(max(0, 1 - pow((t - 0.55) / 0.45, 2))) }
        elytra(&out, f, pen, w)
        let n = max(3, Int(6 * pen.detail))
        for side in [1.0, -1.0] {
            for k in 1...n {
                let frac = Double(k) / Double(n + 1)
                out.append(Line(points: f.map(stria(w, side, frac, 0.04, 0.93 - 0.1 * frac)), width: pen.fine))
            }
            out.append(Line(points: f.map(stria(w, side, 0.95, 0.04, 0.9)), width: pen.fine))
        }
        let P0 = 0.46
        let pw: (Double) -> Double = { s in 0.5 - 0.06 * s - 0.2 * pow(s, 3) }
        pronotum(&out, f, pen, length: P0, pw)
        // Granules in staggered rows, finer towards the margins.
        for row in 0..<9 {
            let s = 0.08 + 0.84 * Double(row) / 8, span = pw(s) - 0.05
            let count = Int(span / 0.045)
            for i in 0...count {
                let x = -span + 2 * span * (Double(i) + (row % 2 == 0 ? 0.25 : 0.75)) / Double(count + 1)
                let j = P(Double.random(in: -0.008..<0.008, using: &rng), Double.random(in: -0.008..<0.008, using: &rng))
                out.append(Line(points: f.map(dot(P(x, -0.012 - P0 * s) + j, 0.009 * (1 - 0.5 * abs(x) / span))), width: pen.fine))
            }
        }
        // The clypeus: a half disc whose front edge breaks into six teeth.
        let c = P(0, -P0 - 0.02)
        let fan = (0...72).map { i -> P in
            let a = .pi + .pi * Double(i) / 72
            let u = 6 * (a - .pi) / .pi, tooth = pow(1 - abs(2 * (u - floor(u)) - 1), 2)
            return c + (0.29 + 0.06 * tooth) * P(cos(a), 0.9 * sin(a))
        }
        out.append(Line(points: f.map(fan), width: pen.outline))
        out.append(Line(points: f.map(E.curve(P(-0.18, -P0 - 0.12), P(0, -P0 - 0.2), P(0.18, -P0 - 0.12), 12)), width: pen.fine))
        for side in [1.0, -1.0] {
            // The lamellate club: a short stalk and three leaves.
            let j = path(P(0.26, -P0 - 0.1), heading: -0.5, bend: -0.1, [0.06, 0.05, 0.04])
            let m = j.map { P(side * $0.x, $0.y) }
            out.append(Line(points: f.map(m), width: pen.body))
            for k in 0..<3 {
                let a = -0.9 + 0.35 * Double(k)
                let base = m.last!, tip = base + 0.09 * P(side * cos(a), sin(a))
                out.append(Line(points: f.map(limb(base, tip, 0.006, 0.018)), width: pen.fine))
            }
        }
        legs(&out, &rng, f, pen, root: P(0.42, -0.2), angles: (-0.4, -0.95, -1.3), lengths: (0.22, 0.32, 0.1),
             femur: 0.045, tibia: 0.05, teeth: 3, tarsi: 3)
        legs(&out, &rng, f, pen, root: P(0.46, 0.14), angles: (0.2, 0.6, 0.9), lengths: (0.3, 0.36, 0.24),
             femur: 0.04, tibia: 0.03)
        legs(&out, &rng, f, pen, root: P(0.42, 0.34), angles: (0.75, 1.2, 1.35), lengths: (0.34, 0.44, 0.26),
             femur: 0.04, tibia: 0.03)
    }

    /// Weevil: a pear-shaped body, its striae rows of punctures, a long curved snout with elbowed antennae from its
    /// middle, and clubbed femora.
    private static func weevil(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, _ pen: Pen) {
        let w: (Double) -> Double = { t in 0.42 * pow(max(0, sin(.pi * (0.15 + 0.85 * t))), 0.7) }
        elytra(&out, f, pen, w)
        let n = max(2, Int(5 * pen.detail))
        for side in [1.0, -1.0] {
            for k in 1...n {
                let frac = Double(k) / Double(n + 1), t1 = 0.92 - 0.08 * frac
                out.append(Line(points: f.map(stria(w, side, frac, 0.03, t1)), width: pen.fine))
                guard pen.detail > 0.6 else { continue }
                var t = 0.05
                while t < t1 - 0.03 {
                    out.append(Line(points: f.map(dot(P(side * (gap + (frac + 0.5 / Double(n + 1)) * w(t)), t), 0.007)), width: pen.fine))
                    t += 0.06
                }
            }
        }
        let P0 = 0.4
        let pw: (Double) -> Double = { s in 0.27 * sin(.pi * (0.25 + 0.6 * s)) + 0.02 }
        pronotum(&out, f, pen, length: P0, pw)
        for _ in 0..<Int(30 * pen.detail) {
            let s = Double.random(in: 0.1..<0.9, using: &rng), x = Double.random(in: -0.75..<0.75, using: &rng) * pw(s)
            out.append(Line(points: f.map(dot(P(x, -0.012 - P0 * s), 0.008)), width: pen.fine))
        }
        let h0 = -P0 - 0.01
        out.append(Line(points: f.map(E.arc(P(0, h0 - 0.06), 0.13, from: .pi * 1.05, to: .pi * 1.95, 20)), width: pen.outline))
        eye(&out, f, pen, P(0.09, h0 - 0.1), 0.035)
        // The rostrum, curving a little to one side, and its mouthparts.
        let r0 = P(0, h0 - 0.17), rc = P(0.08, h0 - 0.55), r1 = P(0.2, h0 - 0.95)
        let spine = E.curve(r0, rc, r1, 30)
        var left: [P] = [], right: [P] = []
        for i in 0...30 {
            let d = simd_normalize(spine[min(i + 1, 30)] - spine[max(i - 1, 0)]), nrm = P(-d.y, d.x)
            let hw = 0.055 - 0.015 * Double(i) / 30 + (i > 26 ? 0.01 : 0)
            left.append(spine[i] + hw * nrm)
            right.append(spine[i] - hw * nrm)
        }
        out.append(Line(points: f.map(left), width: pen.outline))
        out.append(Line(points: f.map(right), width: pen.outline))
        out.append(Line(points: f.map([left.last!, r1 + 0.03 * simd_normalize(r1 - spine[28]), right.last!]), width: pen.body))
        // Elbowed antennae from the snout's middle: a scape along it, a funicle out and an oval club.
        for side in [1.0, -1.0] {
            let base = spine[13] + side * P(0.05, 0.0)
            let elbow = base + 0.26 * simd_normalize(spine[22] - spine[13]) + side * P(0.03, 0)
            out.append(Line(points: f.map(limb(base, elbow, 0.012, 0.016)), width: pen.body))
            let fun = path(elbow, heading: side > 0 ? -0.2 : .pi + 0.4, bend: side > 0 ? -0.08 : 0.08, [Double](repeating: 0.045, count: 6))
            out.append(Line(points: f.map(fun), width: pen.body))
            let tip = fun.last!, d = simd_normalize(tip - fun[fun.count - 2])
            out.append(Line(points: f.map(limb(tip, tip + 0.11 * d, 0.012, 0.012, bulge: 0.03)), width: pen.body))
            for q in [0.35, 0.6] {
                let c = tip + 0.11 * q * d, nrm = P(-d.y, d.x)
                out.append(Line(points: f.map([c + 0.03 * nrm, c - 0.03 * nrm]), width: pen.fine))
            }
        }
        legs(&out, &rng, f, pen, root: P(0.2, -0.24), angles: (-0.5, -1.2, -1.3), lengths: (0.3, 0.3, 0.2),
             femur: 0.03, tibia: 0.022, bulge: 0.03)
        legs(&out, &rng, f, pen, root: P(0.34, 0.12), angles: (0.1, 0.6, 0.9), lengths: (0.3, 0.3, 0.2),
             femur: 0.03, tibia: 0.022, bulge: 0.03)
        legs(&out, &rng, f, pen, root: P(0.32, 0.36), angles: (0.7, 1.2, 1.35), lengths: (0.34, 0.34, 0.22),
             femur: 0.03, tibia: 0.022, bulge: 0.035)
    }

    /// Ladybird: a domed round body shaded in lines that follow the dome, broken round seven black spots, a small
    /// pronotum with pale corners and short legs just showing.
    private static func ladybird(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, _ pen: Pen) {
        let w: (Double) -> Double = { t in 0.62 * sqrt(max(0, 1 - pow((t - 0.4) / 0.6, 2))) }
        legs(&out, &rng, f, pen, root: P(0.3, -0.1), angles: (-0.6, -1.0, -1.2), lengths: (0.22, 0.2, 0.12),
             femur: 0.035, tibia: 0.025, tarsi: 3)
        legs(&out, &rng, f, pen, root: P(0.45, 0.2), angles: (0.1, 0.4, 0.7), lengths: (0.26, 0.2, 0.12),
             femur: 0.035, tibia: 0.025, tarsi: 3)
        legs(&out, &rng, f, pen, root: P(0.4, 0.5), angles: (0.7, 1.0, 1.2), lengths: (0.26, 0.2, 0.12),
             femur: 0.035, tibia: 0.025, tarsi: 3)
        elytra(&out, f, pen, w)
        let spots: [(P, Double)] = [(P(gap, 0.06), 0.1), (P(-gap, 0.06), 0.1), (P(0.3, 0.2), 0.11), (P(0.35, 0.52), 0.15),
                                    (P(0.2, 0.82), 0.1), (P(-0.29, 0.21), 0.11), (P(-0.36, 0.5), 0.14), (P(-0.21, 0.8), 0.1)]
        for (c, r) in spots {
            out.append(Line(points: f.map(E.arc(c, r, from: 0, to: 2 * .pi, 24)), width: pen.body))
        }
        let n = Int(10 * pen.detail)
        for side in [1.0, -1.0] {
            for k in 1...n {
                let frac = Double(k) / Double(n + 1)
                var run: [P] = []
                for p in stria(w, side, frac, 0.02, 0.97 - 0.05 * frac, 60) {
                    if spots.contains(where: { simd_distance($0.0, p) < $0.1 + 0.02 }) {
                        if run.count > 1 { out.append(Line(points: f.map(run), width: pen.fine)) }
                        run = []
                    } else {
                        run.append(p)
                    }
                }
                if run.count > 1 { out.append(Line(points: f.map(run), width: pen.fine)) }
            }
        }
        let P0 = 0.26
        pronotum(&out, f, pen, length: P0) { s in 0.44 * (1 - 0.45 * s * s) }
        for side in [1.0, -1.0] {
            out.append(Line(points: f.map(E.curve(P(side * 0.4, -0.04), P(side * 0.18, -0.12), P(side * 0.3, -0.24), 12)), width: pen.fine))
        }
        let h0 = -P0 - 0.01
        out.append(Line(points: f.map(E.arc(P(0, h0), 0.17, from: .pi * 1.08, to: .pi * 1.92, 16)), width: pen.outline))
        eye(&out, f, pen, P(0.12, h0 - 0.06), 0.035)
        for side in [1.0, -1.0] {
            let j = path(P(0.13, h0 - 0.12), heading: -1.0, bend: -0.1, [0.04, 0.04, 0.04, 0.04])
            out.append(Line(points: f.map(j.map { P(side * $0.x, $0.y) }), width: pen.fine))
        }
    }

    /// Ground beetle, the small ones between: a heart-shaped pronotum, striate elytra, threadlike antennae and long legs.
    private static func carabid(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, _ pen: Pen) {
        let w: (Double) -> Double = { t in t < 0.7 ? 0.3 + 0.03 * sin(t / 0.7 * .pi) : 0.3 * sqrt(max(0, 1 - pow((t - 0.7) / 0.3, 2))) }
        elytra(&out, f, pen, w)
        let n = max(2, Int(7 * pen.detail))
        for side in [1.0, -1.0] {
            for k in 1...n {
                let frac = Double(k) / Double(n + 1)
                out.append(Line(points: f.map(stria(w, side, frac, 0.04, 0.92 - 0.1 * frac)), width: pen.fine))
            }
        }
        let P0 = 0.36
        pronotum(&out, f, pen, length: P0) { s in 0.17 + 0.12 * sin(.pi * pow(s, 0.7)) * (1 - 0.3 * s) }
        out.append(Line(points: f.map([P(0, -0.06), P(0, -P0 + 0.04)]), width: pen.fine))
        let h0 = -P0 - 0.02, h1 = h0 - 0.2
        let headLine = E.curve(P(0.13, h0), P(0.2, h0 - 0.1), P(0.1, h1), 10) + E.curve(P(0.1, h1), P(0, h1 - 0.03), P(-0.1, h1), 8).dropFirst()
            + E.curve(P(-0.1, h1), P(-0.2, h0 - 0.1), P(-0.13, h0), 10).dropFirst()
        out.append(Line(points: f.map(headLine), width: pen.outline))
        for side in [1.0, -1.0] {
            out.append(Line(points: f.map(E.curve(P(side * 0.06, h1), P(side * 0.12, h1 - 0.1), P(side * 0.01, h1 - 0.14), 8)), width: pen.body))
            let j = path(P(0.13, h1 + 0.04), heading: -1.15, bend: 0.1, [Double](repeating: 0.075, count: 9))
            out.append(Line(points: f.map(j.map { P(side * $0.x, $0.y) }), width: pen.fine))
        }
        legs(&out, &rng, f, pen, root: P(0.2, -0.2), angles: (-0.5, -1.0, -1.3), lengths: (0.3, 0.32, 0.22),
             femur: 0.035, tibia: 0.022)
        legs(&out, &rng, f, pen, root: P(0.3, 0.1), angles: (0.15, 0.6, 0.9), lengths: (0.32, 0.36, 0.24),
             femur: 0.035, tibia: 0.022)
        legs(&out, &rng, f, pen, root: P(0.3, 0.28), angles: (0.7, 1.15, 1.3), lengths: (0.38, 0.42, 0.26),
             femur: 0.035, tibia: 0.022)
    }

    /// A loose wing case, its inner face to the suture, striate and punctured.
    private static func wingCase(_ out: inout [Line], _ f: Frame, _ pen: Pen) {
        let w: (Double) -> Double = { t in t < 0.6 ? 0.36 + 0.04 * sin(t / 0.6 * .pi / 2) : 0.4 * sqrt(max(0, 1 - pow((t - 0.6) / 0.4, 2))) }
        elytra(&out, f, pen, sides: [1], w)
        for k in 1...5 {
            let frac = Double(k) / 6, t1 = 0.93 - 0.1 * frac
            out.append(Line(points: f.map(stria(w, 1, frac, 0.03, t1)), width: pen.fine))
            guard k % 2 == 0 else { continue }
            var t = 0.08
            while t < t1 - 0.06 {
                out.append(Line(points: f.map(dot(P(gap + (frac + 1.0 / 16) * w(t), t), 0.01)), width: pen.fine))
                t += 0.09
            }
        }
        out.append(Line(points: f.map(E.curve(P(gap + 0.38, 0.02), P(gap + 0.34, 0.1), P(gap + 0.4, 0.2), 8)), width: pen.body))
    }

    /// A grub curled in a C, fat towards its tail, ringed with segments and spiracles, its head capsule and three pairs
    /// of small legs at the narrow end.
    private static func grub(_ out: inout [Line], _ f: Frame, _ pen: Pen) {
        let a0 = -1.9, a1 = 2.5, n = 90
        func at(_ t: Double) -> P { let a = a0 + (a1 - a0) * t; return P(cos(a), sin(a)) }
        func thick(_ t: Double) -> Double {
            let th = 0.2 + 0.26 * pow(t, 0.7)
            return t > 0.9 ? th * sqrt(max(0, 1 - pow((t - 0.9) / 0.1, 2))) : th
        }
        let outer = (0...n).map { i -> P in let t = Double(i) / Double(n); return at(t) * (1 + thick(t)) }
        let inner = (0...n).map { i -> P in let t = Double(i) / Double(n); return at(t) * (1 - thick(t)) }
        out.append(Line(points: f.map(outer + inner.reversed() + [outer[0]]), width: pen.outline))
        for k in 1..<13 {
            let t = 0.04 + 0.86 * Double(k) / 13, c = at(t), th = thick(t)
            out.append(Line(points: f.map(E.curve(c * (1 - th), c + 0.04 * P(-c.y, c.x), c * (1 + th), 8)), width: pen.fine))
            if k < 12 {
                let s = at(t + 0.03) * (1 + 0.55 * thick(t + 0.03))
                out.append(Line(points: f.map(E.circle(s, 0.025, 8)), width: pen.fine))
            }
        }
        let tangent = simd_normalize(at(0) - at(0.02))
        let head = at(0) + 0.17 * tangent
        out.append(Line(points: f.map(E.circle(head, 0.2, 28)), width: pen.outline))
        out.append(Line(points: f.map(E.curve(head - 0.12 * P(-tangent.y, tangent.x), head + 0.05 * tangent, head + 0.12 * P(-tangent.y, tangent.x), 10)), width: pen.fine))
        for s in [-1.0, 1.0] {
            let side = P(-tangent.y, tangent.x) * s, root = head + 0.17 * tangent + 0.07 * side
            out.append(Line(points: f.map(E.curve(root, root + 0.12 * tangent, root + 0.1 * tangent - 0.08 * side, 8)), width: pen.body))
        }
        for k in 0..<3 {
            let t = 0.05 + 0.065 * Double(k), c = at(t) * (1 - thick(t)), inward = -at(t), along = simd_normalize(at(t + 0.01) - at(t))
            let knee = c + 0.16 * simd_normalize(inward + 0.4 * along), foot = knee + 0.14 * simd_normalize(inward - 0.6 * along)
            out.append(Line(points: f.map([c, knee, foot]), width: pen.body))
        }
    }
}
