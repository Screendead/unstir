// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: the kraken's arms curling across the glass round an argonaut, a squid, a cuttlefish, a vampire squid and an octopus.
enum Octopus {
    typealias Line = Engraving.Line
    private typealias E = Engraving
    private typealias P = SIMD2<Double>

    /// An arm's centreline from root to tip, and the side (+1 right, -1 left, along the arm) its suckers face.
    private struct Reach {
        var points: [P], inner: Double
    }

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4B52_414B)
        var out: [Line] = []
        water(&out, &rng)
        kraken(&out, &rng)
        vampire(&out, at: P(0.1, -0.72), size: 0.17)
        argonaut(&out, &rng, at: P(0.58, -0.3), size: 0.31, heading: 2.6)
        cuttlefish(&out, &rng, at: P(0.4, 0.3), heading: 1.95, length: 0.42)
        squid(&out, &rng, at: P(-0.52, 0.52), heading: -0.42, length: 0.52)
        let crown = P(0.3, 0.64), small = 0.2
        octopus(&out, &rng, crown: crown, axis: 0.35, size: small, arms: [
            swing(crown + P(-0.03, 0.01), -2.0, 0.42, 1.2, 0.3, 6), swing(crown + P(-0.02, 0.02), -2.7, 0.36, -0.9, -0.3, -7),
            swing(crown + P(0, 0.02), 3.1, 0.3, 1.0, 0.2, 6), swing(crown + P(0.01, 0.02), 2.6, 0.26, -1.3, 0.4, -5),
            swing(crown + P(0.02, 0.01), 2.05, 0.4, 0.8, -0.3, 7), swing(crown + P(0.03, 0), 1.55, 0.3, -1.5, 0.2, -6),
            swing(crown + P(-0.03, 0), -1.45, 0.24, 1.8, 0, 5), swing(crown + P(0.03, -0.01), 1.0, 0.2, -1.6, 0, 5),
        ], width: 0.085 * small, heavy: E.medium)
        return out
    }()

    private static func inside(_ p: P, _ poly: [P]) -> Bool {
        var odd = false
        var j = poly.count - 1
        for i in poly.indices {
            let a = poly[i], b = poly[j]
            if (a.y > p.y) != (b.y > p.y), p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { odd.toggle() }
            j = i
        }
        return odd
    }

    /// Cuts every line already drawn where it passes behind `hull`, so what is drawn next sits in front.
    private static func cover(_ out: inout [Line], _ hull: [P]) {
        let lo = hull.reduce(P(.infinity, .infinity)) { simd_min($0, $1) }
        let hi = hull.reduce(-P(.infinity, .infinity)) { simd_max($0, $1) }
        func near(_ p: P) -> Bool { p.x >= lo.x && p.y >= lo.y && p.x <= hi.x && p.y <= hi.y }
        var kept: [Line] = []
        kept.reserveCapacity(out.count)
        for line in out {
            guard line.points.contains(where: near) else { kept.append(line); continue }
            var run: [P] = []
            for p in line.points {
                if near(p), inside(p, hull) {
                    if run.count > 1 { kept.append(Line(points: run, width: line.width)) }
                    run = []
                } else {
                    run.append(p)
                }
            }
            if run.count > 1 { kept.append(Line(points: run, width: line.width)) }
        }
        out = kept
    }

    /// The right-hand normal of a heading on screen (y down).
    private static func right(_ heading: Double) -> P { let d = E.dir(heading); return P(-d.y, d.x) }

    private static func heading(_ d: P) -> Double { atan2(d.x, -d.y) }

    /// An arm swung from `root` by heading: a steady bend over its length, a sway along it and a curl winding its tip
    /// (radians, positive clockwise on screen).
    private static func swing(_ root: P, _ h0: Double, _ length: Double, _ bend: Double, _ wave: Double, _ curl: Double) -> Reach {
        let n = max(80, Int(length * 300))
        var pts = [root]
        for i in 1...n {
            let s = Double(i) / Double(n)
            pts.append(pts[i - 1] + length / Double(n) * E.dir(h0 + bend * s + wave * sin(1.6 * .pi * s) + curl * pow(s, 5)))
        }
        return Reach(points: pts, inner: curl >= 0 ? 1 : -1)
    }

    /// An arm laid through `way` (a Catmull-Rom spline), then wound `curl` radians over its last `tip` units.
    private static func reach(_ way: [P], curl: Double, tip: Double) -> Reach {
        let ext = [2 * way[0] - way[1]] + way + [2 * way[way.count - 1] - way[way.count - 2]]
        var pts: [P] = [way[0]]
        for k in 1..<(ext.count - 2) {
            let p0 = ext[k - 1], p1 = ext[k], p2 = ext[k + 1], p3 = ext[k + 2]
            let m = max(8, Int(simd_distance(p1, p2) * 300))
            for i in 1...m {
                let t = Double(i) / Double(m), t2 = t * t, t3 = t2 * t
                let c1: P = (p2 - p0) * t
                let c2: P = (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
                let c3: P = (3 * p1 - p0 - 3 * p2 + p3) * t3
                let a: P = 2 * p1 + c1 + c2 + c3
                pts.append(0.5 * a)
            }
        }
        let h = heading(pts[pts.count - 1] - pts[pts.count - 2])
        let m = max(40, Int(tip * 400))
        for i in 1...m {
            let s = Double(i) / Double(m)
            pts.append(pts[pts.count - 1] + tip / Double(m) * E.dir(h + curl * s * s))
        }
        return Reach(points: pts, inner: curl >= 0 ? 1 : -1)
    }

    /// A tapering arm in front of what came before: both edges, wrinkles across its back and a row of suckers along
    /// the side its tip curls towards.
    private static func arm(_ out: inout [Line], _ rng: inout SplitMix64, _ a: Reach, width: Double, edge: Double,
                            suckers: Bool = true) {
        let c = a.points, n = c.count - 1
        var along = [0.0]
        for i in 1...n { along.append(along[i - 1] + simd_distance(c[i], c[i - 1])) }
        let total = along[n]
        let hs = (0...n).map { heading(c[min($0 + 1, n)] - c[max($0 - 1, 0)]) }
        func w(_ i: Int) -> Double { width * (0.07 + 0.93 * pow(1 - along[i] / total, 1.1)) }
        let inner = a.inner
        let l = (0...n).map { c[$0] - inner * w($0) * right(hs[$0]) }
        let r = (0...n).map { c[$0] + inner * w($0) * right(hs[$0]) }
        cover(&out, l + [c[n]] + r.reversed())
        out.append(Line(points: l + [c[n] + 0.5 * w(n) * E.dir(hs[n])] + r.reversed(), width: edge))
        var next = width > 0.016 ? 0.02 : .infinity
        for i in 1...n where along[i] > next && along[i] < 0.78 * total {
            let wd = w(i), o = -inner * right(hs[i])
            out.append(Line(points: E.curve(c[i] + 0.95 * wd * o, c[i] + 0.55 * wd * o + 0.25 * wd * E.dir(hs[i]),
                                            c[i] + 0.15 * wd * o, 6), width: E.fine))
            next = along[i] + max(0.014, 1.2 * wd) * Double.random(in: 0.8..<1.2, using: &rng)
        }
        guard suckers else { return }
        next = 0.012
        for i in 1...n where along[i] > next && along[i] < 0.9 * total {
            let wd = w(i), rad = 0.36 * wd
            guard rad > 0.003 else { break }
            let p = c[i] + inner * 0.5 * wd * right(hs[i])
            out.append(Line(points: E.circle(p, rad, max(10, Int(rad * 900))), width: E.fine))
            if rad > 0.009 { out.append(Line(points: E.circle(p, 0.45 * rad, 10), width: E.fine)) }
            next = along[i] + 2.6 * rad
        }
    }

    /// An octopus: its arms behind, then head and mantle over their roots. `axis` points from the crown to the
    /// mantle's top.
    private static func octopus(_ out: inout [Line], _ rng: inout SplitMix64, crown: P, axis: Double, size s: Double,
                                arms: [Reach], width: Double, heavy: Double) {
        for a in arms { arm(&out, &rng, a, width: width, edge: s > 0.3 ? E.medium : E.fine) }
        let u = E.dir(axis), v = right(axis)
        // The body in its frame: y along the axis from the crown (0) to the mantle's top, x across; half-widths of the
        // head with its eyes and of the mantle's bag, which leans to one side.
        let top = 1.08
        func half(_ y: Double, _ side: Double) -> Double {
            let eye = (side > 0 ? 0.065 : 0.05) * exp(-pow((y - 0.2) / 0.07, 2))
            let head = y < 0.4 ? 0.19 + 0.03 * y + eye : 0
            let t = (y - 0.66) / 0.42
            let bag = abs(t) < 1 ? 0.34 * pow(1 - t * t, 0.55) * (1 + 0.08 * side * t) : 0
            return max(head, bag)
        }
        func lean(_ y: Double) -> Double { 0.12 * max(0, y - 0.35) * (y - 0.35) }
        func at(_ x: Double, _ y: Double) -> P { crown + s * ((x + lean(y)) * v + y * u) }
        let m = 140
        let leftSide = (0...m).map { i -> P in let y = top * Double(i) / Double(m); return at(-half(y, -1), y) }
        let rightSide = (0...m).reversed().map { i -> P in let y = top * Double(i) / Double(m); return at(half(y, 1), y) }
        let hull = leftSide + rightSide
        cover(&out, hull)
        out.append(Line(points: hull, width: heavy))
        // The mantle shaded in the engraver's way: contours round the bag, closer and longer towards the shadowed
        // side, and lines down that side's edge.
        for k in 0..<10 {
            let y = 0.47 + 0.058 * Double(k), h = half(y, 1)
            let x0 = h * (k % 2 == 0 ? -0.15 : 0.12) + h * 0.04 * Double(k)
            out.append(Line(points: (0...36).map { i -> P in
                let x = x0 + (0.97 * h - x0) * Double(i) / 36
                return at(x, y - 0.08 * sqrt(max(0, 1 - x * x / (h * h))))
            }, width: E.fine))
        }
        for f in [0.9, 0.8, -0.82] {
            let side = f > 0 ? 1.0 : -1.0
            out.append(Line(points: (0...50).map { i -> P in
                let y = 0.5 + 0.48 * Double(i) / 50
                return at(f * half(y, side), y)
            }, width: E.fine))
        }
        out.append(Line(points: (0...30).map { i -> P in
            let x = (-0.92 + 1.84 * Double(i) / 30) * half(0.42, 1)
            return at(x, 0.42 + 0.03 * cos(x * 5))
        }, width: E.fine))
        // Eyes: the near one large under its brow, its pupil a bar, the far one a lidded bulge.
        let eye = at(0.17, 0.2)
        out.append(Line(points: E.circle(eye, 0.07 * s, 36), width: E.medium))
        out.append(Line(points: E.circle(eye, 0.04 * s, 24), width: E.fine))
        out.append(Line(points: [eye - 0.03 * s * v + 0.008 * s * u, eye + 0.03 * s * v - 0.006 * s * u], width: E.medium))
        out.append(Line(points: E.curve(at(0.05, 0.28), at(0.17, 0.37), at(0.3, 0.27), 14), width: E.fine))
        let far = at(-0.2, 0.21)
        out.append(Line(points: E.arc(far, 0.04 * s, from: axis + 0.4, to: axis + 0.4 + .pi, 14), width: E.fine))
        out.append(Line(points: E.curve(at(-0.26, 0.14), at(-0.17, 0.29), at(-0.1, 0.17), 12), width: E.fine))
        for k in 0..<3 {
            let y = 0.31 + 0.03 * Double(k)
            out.append(Line(points: E.curve(at(-0.08, y), at(0, y + 0.03), at(0.06, y - 0.01), 10), width: E.fine))
        }
        // The siphon from under the near eye.
        out.append(Line(points: E.curve(at(0.16, 0.08), at(0.28, 0.02), at(0.31, -0.07), 10), width: E.fine))
        out.append(Line(points: E.curve(at(0.1, 0.06), at(0.21, -0.02), at(0.25, -0.09), 10), width: E.fine))
    }

    /// The great octopus, its mantle high on the left and its arms out to the rim between the others.
    private static func kraken(_ out: inout [Line], _ rng: inout SplitMix64) {
        let arms = [
            reach([P(-0.3, -0.06), P(-0.55, -0.02), P(-0.72, -0.18), P(-0.8, -0.38)], curl: 7, tip: 0.2),
            reach([P(-0.14, -0.12), P(-0.04, -0.36), P(-0.16, -0.6), P(-0.3, -0.76)], curl: 6.5, tip: 0.18),
            reach([P(-0.26, -0.02), P(-0.42, 0.14), P(-0.36, 0.3), P(-0.2, 0.36)], curl: -7, tip: 0.16),
            reach([P(-0.1, -0.1), P(0.12, -0.24), P(0.3, -0.5), P(0.38, -0.74)], curl: -7.5, tip: 0.22),
            reach([P(-0.18, 0.0), P(-0.12, 0.28), P(-0.2, 0.52), P(-0.08, 0.74)], curl: -7, tip: 0.2),
            reach([P(-0.12, -0.02), P(0.08, 0.14), P(0.12, 0.36), P(-0.02, 0.48)], curl: 7.5, tip: 0.18),
            reach([P(-0.08, -0.06), P(0.2, -0.04), P(0.46, 0.06), P(0.78, -0.04)], curl: -8, tip: 0.24),
            reach([P(-0.22, -0.04), P(-0.3, 0.18), P(-0.4, 0.24)], curl: -7, tip: 0.14),
        ]
        octopus(&out, &rng, crown: P(-0.2, -0.08), axis: -0.62, size: 0.55, arms: arms, width: 0.042, heavy: E.heavy)
    }

    /// The paper nautilus: one fast-opening whorl, ribbed and knobbed along its keel, the animal's arms reaching from its
    /// mouth.
    private static func argonaut(_ out: inout [Line], _ rng: inout SplitMix64, at c: P, size: Double, heading: Double) {
        let end = 2 * .pi * 1.4, k = 0.24
        func point(_ a: Double, _ f: Double = 1) -> P {
            c + f * size * exp(k * (a - end)) * P(cos(a + heading), sin(a + heading))
        }
        let lip = point(end), throat = point(end - 2 * .pi)
        let mouth = 0.55 * lip + 0.45 * throat
        let out0 = heading + end + .pi / 2
        for j in 0..<6 {
            let h = Self.heading(lip - throat) + 0.6 + 0.26 * Double(j) + Double.random(in: -0.08..<0.08, using: &rng)
            arm(&out, &rng, swing(mouth + 0.012 * Double(j - 3) * E.dir(out0), h, size * Double.random(in: 0.7..<1.1, using: &rng),
                                  Double.random(in: -0.8..<0.8, using: &rng), 0.2, j % 2 == 0 ? 5 : -6), width: 0.011, edge: E.fine)
        }
        cover(&out, (0...300).map { point(end - 2 * .pi + 2 * .pi * Double($0) / 300) })
        out.append(Line(points: (0...400).map { point(0.2 + (end - 0.2) * Double($0) / 400) }, width: E.medium))
        out.append(Line(points: E.curve(lip, mouth + 0.1 * size * E.dir(out0), throat, 16), width: E.medium))
        out.append(Line(points: (0...300).map { point(2.0 + (end - 2.0) * Double($0) / 300, 0.92) }, width: E.fine))
        // Ribs sweeping from the inner whorl to the keel, every third forking, a knob either side of the keel.
        let ribs = 34
        for j in 0..<ribs {
            let a = end - 2 * .pi + 0.25 + (2 * .pi - 0.45) * Double(j) / Double(ribs - 1)
            let o = point(a, 0.92), base = point(a - 2 * .pi, 1.02)
            let d = simd_distance(o, base), t = simd_normalize(o - base), n = P(-t.y, t.x)
            let rib = E.curve(base, (base + o) / 2 + 0.12 * d * n, o, 16)
            out.append(Line(points: rib, width: E.fine))
            if j % 3 == 1 {
                out.append(Line(points: E.curve(rib[9], rib[12] - 0.05 * d * n, point(a + 0.06, 0.92), 8), width: E.fine))
            }
            let r = 0.003 + 0.005 * exp(k * (a - end))
            out.append(Line(points: E.circle(point(a, j % 2 == 0 ? 0.96 : 1.0) + (j % 2 == 0 ? 0 : r) * simd_normalize(point(a) - c), r, 8),
                            width: E.fine))
        }
        let eye = mouth + 0.12 * size * simd_normalize(lip - throat) - 0.06 * size * E.dir(out0)
        out.append(Line(points: E.circle(eye, 0.016, 16), width: E.medium))
        out.append(Line(points: E.circle(eye, 0.006, 10), width: E.fine))
    }

    /// A squid, tail first: the long mantle and its tail fins, the head, eight arms and the two tentacles trailing
    /// with their clubs. `heading` points from the head to the tail.
    private static func squid(_ out: inout [Line], _ rng: inout SplitMix64, at head: P, heading: Double, length: Double) {
        let u = E.dir(heading), v = right(heading)
        func at(_ x: Double, _ y: Double) -> P { head + length * (x * v + y * u) }
        for j in 0..<8 {
            arm(&out, &rng, swing(at(-0.06 + 0.017 * Double(j), -0.06), heading + .pi + 0.06 * Double(j - 4)
                                  + Double.random(in: -0.05..<0.05, using: &rng), length * Double.random(in: 0.28..<0.4, using: &rng),
                                  Double.random(in: -0.4..<0.4, using: &rng), 0.15, j % 2 == 0 ? 2.5 : -3), width: 0.01,
                edge: E.fine, suckers: false)
        }
        for (x, bend, curl) in [(-0.03, -1.1, 2.4), (0.03, -1.4, -1.8)] {
            let a = swing(at(x, -0.06), heading + .pi + 0.15 + 4 * x, length * 0.9, bend, 0.15, curl)
            let c = a.points, n = c.count - 1, club = Int(Double(n) * 0.85)
            let hs = (0...n).map { Self.heading(c[min($0 + 1, n)] - c[max($0 - 1, 0)]) }
            out.append(Line(points: Array(c[0...club]), width: E.medium))
            let clubTop: [P] = (club...n).map { (i: Int) -> P in
                let w: Double = 0.013 * sin(.pi * Double(i - club) / Double(n - club))
                return c[i] + w * right(hs[i])
            }
            let clubBottom: [P] = (club...n).reversed().map { (i: Int) -> P in
                let w: Double = 0.006 * sin(.pi * Double(i - club) / Double(n - club))
                return c[i] - w * right(hs[i])
            }
            out.append(Line(points: clubTop + clubBottom, width: E.medium))
            for i in stride(from: club + 3, to: n - 2, by: 4) {
                out.append(Line(points: E.circle(c[i] + 0.004 * right(hs[i]), 0.0028, 8), width: E.fine))
            }
        }
        func half(_ y: Double) -> Double { y < 0.1 ? 0.075 : 0.088 * pow(max(0, 1 - (y - 0.1) / 0.9), 0.65) + 0.004 }
        let m = 80
        let l = (0...m).map { at(-half(Double($0) / Double(m)), Double($0) / Double(m)) }
        let r = (0...m).reversed().map { at(half(Double($0) / Double(m)), Double($0) / Double(m)) }
        let finL = E.curve(at(-0.03, 0.56), at(-0.24, 0.84), at(-0.01, 1.05), 24)
        let finR = E.curve(at(0.01, 1.05), at(0.22, 0.82), at(0.03, 0.58), 24)
        cover(&out, l + r)
        cover(&out, finL)
        cover(&out, finR)
        out.append(Line(points: finL, width: E.medium))
        out.append(Line(points: finR, width: E.medium))
        for f in [0.8, 0.6] {
            out.append(Line(points: E.curve(at(-0.03, 0.6), at(-0.24 * f, 0.84), at(-0.01, 1.0), 16), width: E.fine))
            out.append(Line(points: E.curve(at(0.01, 1.0), at(0.22 * f, 0.82), at(0.03, 0.62), 16), width: E.fine))
        }
        let mantle = Array(l.dropFirst(8)) + Array(r.dropLast(8))
        cover(&out, mantle)
        out.append(Line(points: mantle, width: E.medium))
        out.append(Line(points: [at(-0.08, 0.1), at(-0.04, 0.13), at(0, 0.11), at(0.04, 0.13), at(0.08, 0.1)], width: E.fine))
        out.append(Line(points: (0...40).map { at(-0.02 + 0.01 * sin(Double($0) / 6), 0.14 + 0.8 * Double($0) / 40) }, width: E.fine))
        for f in [0.6, 0.78] {
            out.append(Line(points: (0...40).map { i -> P in let y = 0.14 + 0.76 * Double(i) / 40; return at(f * half(y), y) },
                            width: E.fine))
        }
        for _ in 0..<30 {
            let y = Double.random(in: 0.15..<0.85, using: &rng), x = Double.random(in: -0.8..<0.4, using: &rng) * half(y)
            out.append(Line(points: E.circle(at(x, y), Double.random(in: 0.0025..<0.0045, using: &rng), 8), width: E.fine))
        }
        cover(&out, [at(-0.07, 0.1), at(-0.085, 0.02), at(-0.05, -0.07), at(0.05, -0.07), at(0.085, 0.02), at(0.07, 0.1)])
        out.append(Line(points: E.curve(at(-0.07, 0.1), at(-0.1, 0.0), at(-0.045, -0.07), 12), width: E.medium))
        out.append(Line(points: E.curve(at(0.07, 0.1), at(0.1, 0.0), at(0.045, -0.07), 12), width: E.medium))
        out.append(Line(points: E.circle(at(0.02, 0.02), 0.022, 20), width: E.medium))
        out.append(Line(points: E.circle(at(0.025, 0.025), 0.009, 12), width: E.fine))
    }

    /// A cuttlefish in profile: its humped mantle skirted by the rippling fin, banded on the back, the big head with
    /// its W-shaped pupil and the arms bunched forward. `heading` points from the head to the tail.
    private static func cuttlefish(_ out: inout [Line], _ rng: inout SplitMix64, at head: P, heading: Double, length: Double) {
        let u = E.dir(heading), v = right(heading)
        // x < 0 is the back.
        func at(_ x: Double, _ y: Double) -> P { head + length * (x * v + y * u) }
        // Arms drooping together in a cone from the blunt front of the head.
        let point = at(0.1, -0.5)
        for j in 0..<6 {
            let root = at(-0.13 + 0.05 * Double(j), -0.2)
            let d = point - root
            arm(&out, &rng, swing(root, Self.heading(d) + 0.05 * Double(j - 3), simd_length(d) * Double.random(in: 0.8..<1.0, using: &rng),
                                  0.2 * Double(3 - j) / 3, 0.05, j % 2 == 0 ? 1.5 : -1.5), width: 0.026, edge: E.fine, suckers: false)
        }
        func back(_ y: Double) -> Double { 0.3 * pow(max(0, sin(.pi * (0.2 + 0.8 * min(1, y)))), 0.62) }
        func belly(_ y: Double) -> Double { 0.19 * pow(max(0, sin(.pi * (0.2 + 0.8 * min(1, y)))), 0.5) }
        let m = 140
        let ys = (0...m).map { 0.02 + 0.98 * Double($0) / Double(m) }
        let skirtB = ys.map { y in at(-back(y) - 0.05 * sin(.pi * y) - 0.012 * sin(y * 80), y) }
        let skirtF = ys.reversed().map { y in at(belly(y) + 0.08 * sin(.pi * y) + 0.014 * sin(y * 70 + 1), y) }
        cover(&out, skirtB + skirtF)
        out.append(Line(points: skirtB, width: E.fine))
        out.append(Line(points: skirtF, width: E.fine))
        for (i, y) in ys.enumerated() where i % 3 == 1 && y > 0.06 && y < 0.96 {
            out.append(Line(points: [at(-back(y) - 0.004, y), at(-back(y) - 0.045 * sin(.pi * y), y + 0.008)], width: E.fine))
            out.append(Line(points: [at(belly(y) + 0.004, y), at(belly(y) + 0.072 * sin(.pi * y), y + 0.01)], width: E.fine))
        }
        out.append(Line(points: ys.map { at(-back($0), $0) } + ys.reversed().map { at(belly($0), $0) }, width: E.medium))
        // Bands over the back, broken like the living pattern.
        for k in 0..<11 {
            let y = 0.12 + 0.072 * Double(k)
            out.append(Line(points: (0...16).map { i -> P in
                let x = -back(y) * (0.92 - 0.6 * Double(i) / 16)
                return at(x, y + 0.02 * sin(Double(i) * 0.3 + Double(k)))
            }, width: E.fine))
        }
        // The head, set apart by its collar, with the big eye.
        let headHull = (0...40).map { i -> P in
            let t = Double.pi * Double(i) / 40, c = cos(t), sn = sin(t)
            return at(-0.19 * copysign(pow(abs(c), 0.6), c) + 0.01, 0.06 - 0.26 * pow(sn, 0.6))
        }
        cover(&out, headHull)
        out.append(Line(points: headHull, width: E.medium))
        out.append(Line(points: E.curve(at(-0.18, 0.07), at(0, 0.13), at(0.2, 0.06), 14), width: E.fine))
        let eye = at(-0.05, -0.07)
        out.append(Line(points: E.circle(eye, 0.032, 22), width: E.medium))
        out.append(Line(points: E.arc(eye, 0.045, from: heading - 2.2, to: heading - 0.6, 12), width: E.fine))
        let w = length * 0.075
        out.append(Line(points: [(-1.0, -0.5), (-0.5, 0.5), (0, -0.1), (0.5, 0.5), (1.0, -0.5)].map { eye + 0.8 * w * P($0.0, $0.1) },
                        width: E.fine))
    }

    /// The vampire squid: its cloak of web between eight uneven arms, the hem scalloped, the ear fins and great eyes.
    private static func vampire(_ out: inout [Line], at c: P, size s: Double) {
        let headings = [1.5, 1.95, 2.3, 2.72, 3.12, 3.5, 3.98, 4.6]
        var hem: [P] = [], tips: [Reach] = []
        for (j, h) in headings.enumerated() {
            let a = swing(c + 0.18 * s * E.dir(h), h + 0.1, s * (1.15 + 0.3 * sin(Double(j) * 2.1)), 0.35, 0.1, j % 2 == 0 ? 2.2 : -1.8)
            tips.append(a)
            hem.append(a.points[Int(Double(a.points.count - 1) * 0.78)])
        }
        var cloak: [P] = []
        for k in 1..<hem.count {
            let mid = (hem[k - 1] + hem[k]) / 2
            cloak += E.curve(hem[k - 1], c + 0.84 * (mid - c), hem[k], 14)
        }
        out.append(Line(points: cloak, width: E.medium))
        for f in [0.72, 0.5] {
            var fold: [P] = []
            for k in 1..<hem.count {
                let a = c + f * (hem[k - 1] - c), b = c + f * (hem[k] - c)
                fold += E.curve(a, c + 0.86 * ((a + b) / 2 - c), b, 10)
            }
            out.append(Line(points: fold, width: E.fine))
        }
        for (j, a) in tips.enumerated() {
            let p = a.points, n = p.count - 1
            out.append(Line(points: p, width: E.fine))
            for i in stride(from: n / 6, to: n * 9 / 10, by: n / 9) {
                let h = heading(p[i + 1] - p[i - 1])
                out.append(Line(points: [p[i], p[i] + 0.1 * s * (j % 2 == 0 ? 1 : -1) * right(h)], width: E.fine))
            }
        }
        let body = (0...60).map { i -> P in
            let t = Double.pi * Double(i) / 60
            return c + s * P(-0.52 * cos(t) + 0.04 * sin(2 * t), -1.0 * sin(t) + 0.12)
        }
        let fins = [-1.0, 1.0].map { side -> [P] in
            let base = c + s * P(side * 0.42, -0.62)
            return E.curve(base + s * P(-side * 0.04, -0.14), base + s * P(side * 0.4, -0.5), base + s * P(side * 0.3, -0.1), 12)
                + E.curve(base + s * P(side * 0.3, -0.1), base + s * P(side * 0.2, 0.08), base + s * P(-side * 0.02, 0.12), 8)
        }
        for f in fins { cover(&out, f) }
        for f in fins { out.append(Line(points: f, width: E.fine)) }
        cover(&out, body)
        out.append(Line(points: body, width: E.medium))
        for side in [-1.0, 1.0] {
            let eye = c + s * P(side * 0.24, -0.12)
            out.append(Line(points: E.circle(eye, 0.16 * s * (side > 0 ? 1 : 0.82), 20), width: E.fine))
            out.append(Line(points: E.circle(eye + s * P(side * 0.03, 0.02), 0.07 * s, 12), width: E.fine))
        }
    }

    /// Ripples across the water and a scatter of bubbles.
    private static func water(_ out: inout [Line], _ rng: inout SplitMix64) {
        for k in 0..<10 {
            let y = -0.92 + 0.2 * Double(k)
            out.append(Line(points: (0...300).map { i in
                let px = -1 + 2 * Double(i) / 300
                return P(px, y + 0.025 * sin(4 * px + Double(k) * 2.3))
            }, width: E.fine))
        }
        for _ in 0..<80 {
            let p = P(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng))
            guard simd_length(p) < 0.97 else { continue }
            out.append(Line(points: E.circle(p, Double.random(in: 0.005..<0.012, using: &rng), 10), width: E.fine))
        }
    }
}
