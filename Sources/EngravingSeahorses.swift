// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: seahorses, a leafy sea dragon and a pipefish among giant kelp, bladder wrack and sea grass.
enum Seahorses {
    typealias Line = Engraving.Line
    private typealias E = Engraving
    private typealias P = SIMD2<Double>

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x5345_4148)
        var out: [Line] = []
        var hulls: [[P]] = []
        seahorse(&out, &hulls, at: SIMD2(-0.04, -0.52), scale: 1.15, tilt: 0.05, mirror: false)
        seahorse(&out, &hulls, at: SIMD2(0.5, -0.73), scale: 0.45, tilt: -0.1, mirror: true)
        for (c, scale, tilt, mirror) in [(SIMD2(0.1, -0.86), 0.16, 0.5, false), (SIMD2(0.77, -0.5), 0.13, 0.2, true),
                                         (SIMD2(-0.2, -0.86), 0.13, -0.4, false)] {
            seahorse(&out, &hulls, at: c, scale: scale, tilt: tilt, mirror: mirror, fry: true)
        }
        dragon(&out, &hulls, &rng)
        pipefish(&out, &hulls)
        var weed: [Line] = []
        var blades: [[P]] = []
        kelp(&weed, &blades, &rng, foot: SIMD2(-0.62, bed(-0.62)), length: 1.6, lean: 0.08, phase: 0.4, count: 10)
        kelp(&weed, &blades, &rng, foot: SIMD2(-0.34, bed(-0.34)), length: 1.45, lean: 0.42, phase: 2.1, count: 8)
        var fronds = rocks(&weed)
        wrack(&weed, &fronds, &rng)
        plankton(&weed, &rng, hulls)
        for line in weed { clip(&out, line.points, line.width, hulls) }
        // Sea grass and the bottom pass behind the rock and the wrack too.
        var ground: [Line] = []
        grass(&ground, &rng)
        seabed(&ground, &rng)
        for line in ground { clip(&out, line.points, line.width, hulls + fronds) }
        return out
    }()

    /// The sea floor's height at x.
    private static func bed(_ x: Double) -> Double { 0.79 + 0.025 * sin(4 * x + 1) }

    /// A path from `start`, `length` long, its heading (radians clockwise from up) `heading(t)` at fraction t.
    private static func walk(_ start: P, _ length: Double, _ n: Int = 120, _ heading: (Double) -> Double) -> [P] {
        var p = [start]
        for i in 1...n { p.append(p[i - 1] + length / Double(n) * E.dir(heading((Double(i) - 0.5) / Double(n)))) }
        return p
    }

    /// A Catmull-Rom curve through the points.
    private static func smooth(_ c: [P], _ per: Int = 12) -> [P] {
        var out = [c[0]]
        for i in 0..<(c.count - 1) {
            let p0 = c[max(i - 1, 0)], p1 = c[i], p2 = c[i + 1], p3 = c[min(i + 2, c.count - 1)]
            for k in 1...per {
                let t = Double(k) / Double(per), t2 = t * t, t3 = t2 * t
                let a = 2 * p1 + (p2 - p0) * t
                let b = (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3
                out.append(0.5 * (a + b))
            }
        }
        return out
    }

    /// Cosine interpolation through (x, y) knots.
    private static func table(_ k: [(Double, Double)], _ x: Double) -> Double {
        if x <= k[0].0 { return k[0].1 }
        for i in 1..<k.count where x <= k[i].0 {
            let f = (x - k[i - 1].0) / (k[i].0 - k[i - 1].0)
            return k[i - 1].1 + (k[i].1 - k[i - 1].1) * (1 - cos(.pi * f)) / 2
        }
        return k[k.count - 1].1
    }

    /// A spine's frame: arc-length fraction, unit tangent and the normal to the left of travel on screen.
    private struct Frame {
        var p: [P], s: [Double], t: [P], n: [P], length: Double
        init(_ p: [P]) {
            self.p = p
            var cum = [0.0]
            for i in 1..<p.count { cum.append(cum[i - 1] + simd_distance(p[i], p[i - 1])) }
            length = cum[cum.count - 1]
            s = cum.map { $0 / cum[cum.count - 1] }
            t = p.indices.map { simd_normalize(p[min($0 + 1, p.count - 1)] - p[max($0 - 1, 0)]) }
            n = t.map { SIMD2($0.y, -$0.x) }
        }
        func index(_ f: Double) -> Int { s.firstIndex { $0 >= f } ?? s.count - 1 }
    }

    private static func ellipse(_ c: P, _ u: P, _ a: Double, _ b: Double, _ m: Int = 18) -> [P] {
        let v = SIMD2(-u.y, u.x)
        return (0...m).map { k in
            let th = 2 * .pi * Double(k) / Double(m)
            return c + a * cos(th) * u + b * sin(th) * v
        }
    }

    /// A leaflet's outline from `base` along `u`: fuller on one side by `lean`, pointed at the tip.
    private static func leaflet(_ base: P, _ u: P, _ length: Double, _ lean: Double) -> [P] {
        let v = SIMD2(-u.y, u.x), m = 10
        let a = (0...m).map { i -> P in
            let s = Double(i) / Double(m)
            return base + length * s * u + (0.3 + lean) * length * sin(.pi * pow(s, 0.65)) * (0.7 + 0.3 * cos(6 * .pi * s)) * v
        }
        let b = (0..<m).reversed().map { i -> P in
            let s = Double(i) / Double(m)
            return base + length * s * u - (0.3 - lean) * length * sin(.pi * pow(s, 0.65)) * (0.7 + 0.3 * cos(6 * .pi * s + 1)) * v
        }
        return a + b
    }

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

    /// A polyline cut where it passes behind an animal.
    private static func clip(_ out: inout [Line], _ points: [P], _ width: Double, _ hulls: [[P]]) {
        // Each hull's bounds first: an unoptimised build otherwise spends seconds on the polygon test.
        let boxes = hulls.map { h in (h.reduce(h[0]) { simd_min($0, $1) }, h.reduce(h[0]) { simd_max($0, $1) }) }
        var run: [P] = []
        for p in points {
            if hulls.indices.contains(where: { k in
                all(p .>= boxes[k].0) && all(p .<= boxes[k].1) && inside(p, hulls[k])
            }) {
                if run.count > 1 { out.append(Line(points: run, width: width)) }
                run = []
            } else {
                run.append(p)
            }
        }
        if run.count > 1 { out.append(Line(points: run, width: width)) }
    }

    /// The bony rings and ridges of a pipefish's kind along a body: `back` and `belly` half-widths at each fraction,
    /// rings from `from` to `to`, a tubercle on each ring's back. Returns the outline's two edges.
    private static func plated(_ out: inout [Line], _ f: Frame, back: (Double) -> Double, belly: (Double) -> Double,
                               from: Double, to: Double, ring: Double, spike: Double, ridges: [Double]) -> ([P], [P]) {
        let backEdge = f.p.indices.map { f.p[$0] - back(f.s[$0]) * f.n[$0] }
        let bellyEdge = f.p.indices.map { f.p[$0] + belly(f.s[$0]) * f.n[$0] }
        var x = from
        var rings: [Int] = []
        while x < to {
            rings.append(f.index(x))
            x += max(0.012, ring * (back(x) + belly(x)) / f.length)
        }
        for i in rings {
            let a = backEdge[i], b = bellyEdge[i], w = simd_distance(a, b)
            out.append(Line(points: E.curve(a, (a + b) / 2 - 0.32 * w * f.t[i], b, 8), width: E.fine))
            let k = spike * pow(min(1, w / 0.09), 2.5) + 0.002
            out.append(Line(points: [a - 0.25 * k * f.t[i], a - k * f.n[i] + 0.3 * k * f.t[i], a + 0.25 * k * f.t[i]],
                            width: E.fine))
        }
        let lo = f.index(from), hi = f.index(to)
        for r in ridges {
            out.append(Line(points: (lo...hi).map { backEdge[$0] + r * (bellyEdge[$0] - backEdge[$0]) }, width: E.fine))
        }
        return (backEdge, bellyEdge)
    }

    /// A fin: rays from the base points out along their directions, their tips joined.
    private static func fin(_ out: inout [Line], _ bases: [P], _ dirs: [P], _ lengths: [Double]) {
        var tips: [P] = []
        for k in bases.indices {
            let tip = bases[k] + lengths[k] * dirs[k]
            tips.append(tip)
            out.append(Line(points: [bases[k], tip], width: E.fine))
        }
        out.append(Line(points: smooth(tips, 4), width: E.fine))
    }

    /// The seahorse, facing right, built about its eye and set at `at`.
    private static func seahorse(_ out: inout [Line], _ hulls: inout [[P]], at origin: P, scale: Double, tilt: Double,
                                 mirror: Bool, fry: Bool = false) {
        var local: [Line] = []
        let trunk = smooth([SIMD2(-0.085, 0.1), SIMD2(-0.1, 0.2), SIMD2(-0.085, 0.32), SIMD2(-0.035, 0.44),
                            SIMD2(-0.01, 0.55), SIMD2(-0.04, 0.66)], 16)
        let end = trunk[trunk.count - 1], d = simd_normalize(end - trunk[trunk.count - 2])
        let h0 = atan2(d.x, -d.y), tailLength = 0.74
        // The tail curls forward, belly inwards, tightening to its tip.
        let tail = walk(end, tailLength, 160) { t in h0 + 0.5 * t - 2 * .pi * 1.3 * pow(t, 2.4) }
        let f = Frame(trunk + tail.dropFirst())
        let cut = 1 - tailLength / f.length
        func back(_ s: Double) -> Double {
            s < cut ? 0.05 + 0.01 * sin(.pi * s / cut) : 0.047 * pow(1 - (s - cut) / (1 - cut), 0.85) + 0.004
        }
        func belly(_ s: Double) -> Double {
            s < cut ? 0.045 + 0.06 * exp(-pow((s / cut - 0.58) / 0.27, 2)) : back(s)
        }
        let (b, v) = plated(&local, f, back: back, belly: belly, from: 0.015, to: 0.995, ring: fry ? 1.3 : 0.42,
                            spike: fry ? 0 : 0.016, ridges: fry ? [] : [0.3])
        local.append(Line(points: b, width: fry ? E.fine : E.heavy))
        local.append(Line(points: v, width: fry ? E.fine : E.medium))
        // The head: crown, forehead, the snout's tube to its mouth, jaw and throat.
        let head = smooth([b[0], SIMD2(-0.155, 0.03), SIMD2(-0.13, -0.05), SIMD2(-0.085, -0.093), SIMD2(-0.03, -0.083),
                           SIMD2(0.03, -0.06), SIMD2(0.085, -0.033), SIMD2(0.15, -0.016), SIMD2(0.228, -0.011),
                           SIMD2(0.25, -0.015), SIMD2(0.262, -0.004), SIMD2(0.25, 0.008), SIMD2(0.228, 0.004),
                           SIMD2(0.15, 0.006), SIMD2(0.085, 0.026),
                           SIMD2(0.04, 0.062), SIMD2(0.0, 0.088), v[0]], 10)
        local.append(Line(points: head, width: fry ? E.fine : E.heavy))
        let eye = SIMD2(0.0, -0.028)
        local.append(Line(points: E.circle(eye, 0.024, 28), width: fry ? E.fine : E.medium))
        let rot = simd_double2x2(SIMD2(cos(tilt), sin(tilt)), SIMD2(-sin(tilt), cos(tilt)))
        func place(_ p: P) -> P { origin + scale * (rot * (mirror ? SIMD2(-p.x, p.y) : p)) }
        defer {
            for line in local { out.append(Line(points: line.points.map(place), width: line.width)) }
            hulls.append((b.reversed() + head + v).map(place))
        }
        guard !fry else { return }
        local.append(Line(points: [b[b.count - 1], v[v.count - 1]], width: E.fine))
        // A second ridge down the trunk, where the plates' corners meet.
        let hi = f.index(cut)
        local.append(Line(points: (0...hi).map { b[$0] + 0.68 * (v[$0] - b[$0]) }, width: E.fine))
        // The brood pouch's folds over the belly.
        for k in 0..<5 {
            let i = f.index(cut * (0.42 + 0.08 * Double(k)))
            let a = b[i] + 0.78 * (v[i] - b[i]), c = v[i] - 0.004 * f.n[i]
            local.append(Line(points: E.curve(a, (a + c) / 2 + 0.02 * f.t[i], c, 6), width: E.fine))
        }
        // The dorsal fin at the small of the back, its rays leaning tailwards.
        let rays = 17
        var bases: [P] = [], dirs: [P] = [], lens: [Double] = []
        for k in 0..<rays {
            let i = f.index(cut * 0.74 + cut * 0.3 * Double(k) / Double(rays - 1))
            bases.append(b[i])
            dirs.append(simd_normalize(-f.n[i] + 0.45 * f.t[i]))
            lens.append(0.012 + 0.07 * pow(sin(.pi * (Double(k) + 0.5) / Double(rays)), 0.6))
        }
        fin(&local, bases, dirs, lens)

        // Rings round the snout.
        for x in [0.13, 0.165, 0.2] {
            let top = x < 0.15 ? -0.033 + 0.26 * (x - 0.085) : -0.016 + 0.06 * (x - 0.15)
            let bottom = x < 0.15 ? 0.026 - 0.31 * (x - 0.085) : 0.006 - 0.025 * (x - 0.15)
            local.append(Line(points: [SIMD2(x, top + 0.003), SIMD2(x + 0.003, bottom - 0.003)], width: E.fine))
        }
        // The coronet: a crest of uneven blunt points, the tallest behind.
        var crown: [P] = [SIMD2(-0.125, -0.06)]
        for (x, h, len) in [(-0.112, -0.6, 0.022), (-0.097, -0.32, 0.036), (-0.08, -0.12, 0.04), (-0.062, 0.2, 0.028),
                            (-0.045, 0.5, 0.018)] {
            let base = SIMD2(x, -0.088 - 0.012 * cos(3 * (x + 0.075))), tip = base + len * E.dir(h)
            crown += [base, tip - 0.004 * E.dir(h + 1.5), tip + 0.004 * E.dir(h + 1.5)]
        }
        crown.append(SIMD2(-0.03, -0.083))
        local.append(Line(points: crown, width: E.medium))
        // The pupil, the brow spines, the gill cover's ridge behind it and its striations.
        local.append(Line(points: E.circle(eye + SIMD2(0.004, 0.002), 0.009, 14), width: E.fine))
        for (h, len) in [(-0.8, 0.018), (-0.2, 0.022), (0.5, 0.014), (2.6, 0.012)] {
            let a = eye + 0.026 * E.dir(h)
            local.append(Line(points: [a, a + len * E.dir(h + 0.3)], width: E.fine))
        }
        let gill = smooth([SIMD2(-0.06, -0.06), SIMD2(-0.088, 0.0), SIMD2(-0.075, 0.055), SIMD2(-0.035, 0.088)], 8)
        local.append(Line(points: gill, width: E.medium))
        for k in 1..<7 {
            let g = gill[k * gill.count / 7], a = eye + 0.55 * (g - eye)
            local.append(Line(points: [a, g + 0.15 * (eye - g)], width: E.fine))
        }
        // The pectoral fin behind the gill.
        fin(&local, (0..<8).map { SIMD2(-0.075, 0.05) + Double($0) * SIMD2(0.001, 0.005) },
            (0..<8).map { E.dir(5.0 - 0.13 * Double($0)) }, (0..<8).map { 0.022 + 0.016 * sin(.pi * (Double($0) + 0.5) / 8) })
    }

    /// A leafy appendage: a stalk forking into leaflets.
    private static func frond(_ out: inout [Line], _ rng: inout SplitMix64, _ root: P, _ u: P, _ size: Double) {
        let fork = root + 0.55 * size * u
        out.append(Line(points: E.curve(root, root + 0.3 * size * u + 0.05 * size * SIMD2(-u.y, u.x), fork, 6), width: E.fine))
        let count = size > 0.09 ? 4 : size > 0.05 ? 3 : 2
        let heading = atan2(u.x, -u.y)
        for k in 0..<count {
            let h = heading + 1.2 * (Double(k) / Double(count - 1) - 0.5) + Double.random(in: -0.15..<0.15, using: &rng)
            let len = size * Double.random(in: 0.5..<0.8, using: &rng), w = E.dir(h)
            let stem = fork + 0.15 * len * w
            out.append(Line(points: [fork, stem], width: E.fine))
            out.append(Line(points: leaflet(stem, w, len, Double.random(in: -0.1..<0.1, using: &rng)), width: E.fine))
            out.append(Line(points: [stem, stem + 0.75 * len * w], width: E.fine))
        }
    }

    /// The leafy sea dragon, upper right, facing left, its tail drooping.
    private static func dragon(_ out: inout [Line], _ hulls: inout [[P]], _ rng: inout SplitMix64) {
        let heading: [(Double, Double)] = [(0, 1.8), (0.18, 1.5), (0.35, 1.6), (0.55, 2.0), (0.78, 2.8), (1, 3.7)]
        let f = Frame(walk(SIMD2(0.2, -0.14), 0.82, 260) { table(heading, $0) })
        let widths: [(Double, Double)] = [(0, 0.006), (0.14, 0.01), (0.18, 0.024), (0.22, 0.031), (0.27, 0.022),
                                          (0.33, 0.03), (0.43, 0.054), (0.52, 0.05), (0.6, 0.032), (1, 0.005)]
        func w(_ s: Double) -> Double { table(widths, s) }
        let (b, v) = plated(&out, f, back: w, belly: w, from: 0.3, to: 0.99, ring: 0.55, spike: 0.016, ridges: [0.5])
        out.append(Line(points: b, width: E.medium))
        out.append(Line(points: v, width: E.medium))
        out.append(Line(points: [b[0], v[0]], width: E.fine))
        out.append(Line(points: [b[b.count - 1], v[v.count - 1]], width: E.fine))
        let ei = f.index(0.21), eye = f.p[ei] + 0.005 * f.n[ei]
        out.append(Line(points: E.circle(eye, 0.013, 18), width: E.medium))
        out.append(Line(points: E.circle(eye, 0.004, 8), width: E.fine))
        let gi = f.index(0.265)
        out.append(Line(points: E.curve(b[gi], f.p[gi] - 0.012 * f.t[gi], v[gi], 8), width: E.fine))
        // Leafy lobes along the back (left of travel is up, so the back is -n) and belly, more towards the tail.
        for (s, side, size) in [(0.23, 1.0, 0.07), (0.31, 1.0, 0.1), (0.41, 1.0, 0.15), (0.51, 1.0, 0.16),
                                (0.62, 1.0, 0.12), (0.74, 1.0, 0.1), (0.86, 1.0, 0.08), (0.95, 1.0, 0.06),
                                (0.1, 1.0, 0.04), (0.36, -1.0, 0.1), (0.47, -1.0, 0.14), (0.58, -1.0, 0.12),
                                (0.7, -1.0, 0.1), (0.82, -1.0, 0.08), (0.92, -1.0, 0.06), (0.2, -1.0, 0.05)] {
            let i = f.index(s), root = side < 0 ? b[i] : v[i]
            frond(&out, &rng, root, simd_normalize(side * f.n[i] + 0.45 * f.t[i]), size)
        }
        hulls.append(b + v.reversed())
    }

    /// The pipefish, in the open water right of the seahorse, snout to the upper right.
    private static func pipefish(_ out: inout [Line], _ hulls: inout [[P]]) {
        let f = Frame(walk(SIMD2(0.58, 0.22), 0.44, 200) { t in 4.45 + 0.2 * sin(2 * .pi * t * 0.9) })
        let widths: [(Double, Double)] = [(0, 0.004), (0.08, 0.006), (0.12, 0.016), (0.16, 0.017), (0.19, 0.014),
                                          (0.25, 0.018), (0.55, 0.016), (0.96, 0.005), (1, 0.004)]
        func w(_ s: Double) -> Double { table(widths, s) }
        let (b, v) = plated(&out, f, back: w, belly: w, from: 0.19, to: 0.97, ring: 0.9, spike: 0.008, ridges: [0.5])
        out.append(Line(points: b, width: E.medium))
        out.append(Line(points: v, width: E.medium))
        out.append(Line(points: [b[0], v[0]], width: E.fine))
        let ei = f.index(0.135)
        out.append(Line(points: E.circle(f.p[ei], 0.008, 14), width: E.medium))
        let gi = f.index(0.175)
        out.append(Line(points: E.curve(b[gi], f.p[gi] - 0.01 * f.t[gi], v[gi], 8), width: E.fine))
        // The dorsal fin, on the back (-n), and the caudal fan.
        let rays = 12
        let idx = (0..<rays).map { f.index(0.48 + 0.14 * Double($0) / Double(rays - 1)) }
        fin(&out, idx.map { b[$0] }, idx.map { simd_normalize(-f.n[$0] + 0.5 * f.t[$0]) },
            (0..<rays).map { 0.008 + 0.022 * sin(.pi * (Double($0) + 0.5) / Double(rays)) })
        let tip = f.p[f.p.count - 1], u = f.t[f.t.count - 1], h = atan2(u.x, -u.y)
        fin(&out, Array(repeating: tip, count: 7), (0..<7).map { E.dir(h + 0.9 * (Double($0) / 6 - 0.5)) },
            (0..<7).map { 0.03 + 0.008 * sin(.pi * Double($0) / 6) })
        hulls.append(b + v.reversed())
    }

    /// Giant kelp: a stipe from its holdfast, each blade borne on a gas bladder, alternate, ruffled and corrugated.
    /// Each blade hides those drawn after it, `blades` holding the outlines drawn so far.
    private static func kelp(_ out: inout [Line], _ blades: inout [[P]], _ rng: inout SplitMix64, foot: P, length: Double,
                             lean: Double, phase: Double, count: Int) {
        func heading(_ t: Double) -> Double { lean * t + 0.16 * sin(5 * t + phase) + 0.07 * sin(13 * t + 2 * phase) }
        let stipe = walk(foot, length, 200, heading)
        clip(&out, stipe, E.heavy, blades)
        for k in 0..<count {
            let t = 0.1 + 0.88 * Double(k) / Double(count), i = Int(t * 200), side = k % 2 == 0 ? 1.0 : -1.0
            let hb = heading(t) + side * Double.random(in: 0.6..<0.9, using: &rng), u = E.dir(hb)
            let base = stipe[i]
            var lines = [Line(points: [base, base + 0.018 * u], width: E.fine)]
            let bladder = ellipse(base + 0.042 * u, u, 0.026, 0.014)
            lines.append(Line(points: bladder, width: E.fine))
            lines.append(Line(points: E.arc(base + 0.042 * u, 0.008, from: hb - 2.4, to: hb - 1.2, 6), width: E.fine))
            let start = base + 0.068 * u, len = Double.random(in: 0.32..<0.48, using: &rng) * (1 - 0.3 * t)
            let curl = Double.random(in: 0.5..<0.9, using: &rng), wave = Double.random(in: 0.2..<0.4, using: &rng)
            let f = Frame(walk(start, len, 60) { s in hb - side * curl * pow(s, 1.2) + wave * sin(5 * s) })
            let width = Double.random(in: 0.026..<0.034, using: &rng), ph = Double.random(in: 0..<6, using: &rng)
            func half(_ s: Double) -> Double { width * pow(sin(.pi * min(s * 1.1, 1)), 0.5) * (1 - 0.35 * s) + 0.004 }
            let edges = [-1.0, 1.0].map { edge in
                f.p.indices.map { j in
                    let s = f.s[j], ruffle = 0.0035 * sin(110 * s + ph + edge) * sin(.pi * s)
                    return f.p[j] + edge * (half(s) + ruffle) * f.n[j]
                }
            }
            lines += edges.map { Line(points: $0, width: E.fine) }
            lines.append(Line(points: (3...(f.p.count - 6)).map { j in f.p[j] + 0.004 * sin(30 * f.s[j] + ph) * f.n[j] },
                              width: E.fine))
            lines.append(Line(points: [edges[0][0], edges[1][0]], width: E.fine))
            for line in lines { clip(&out, line.points, line.width, blades) }
            blades += [edges[0] + edges[1].reversed(), bladder]
        }
        // The holdfast: forking haptera gripping the bottom.
        for k in 0..<9 {
            let h = .pi + 1.5 * (Double(k) / 8 - 0.5) + Double.random(in: -0.1..<0.1, using: &rng)
            let len = Double.random(in: 0.05..<0.09, using: &rng), a = foot + SIMD2(0, -0.04)
            let mid = a + len * E.dir(h)
            out.append(Line(points: E.curve(a, a + 0.6 * len * E.dir(h - 0.3), mid, 8), width: E.fine))
            for split in [-0.5, 0.45] {
                out.append(Line(points: E.curve(mid, mid + 0.02 * E.dir(h + split), mid + 0.04 * E.dir(h + 1.6 * split), 6),
                                width: E.fine))
            }
        }
    }

    /// Bladder wrack: flat straps with a midrib, forking in two, swelling round a pair of bladders either side of the
    /// rib in each length, and ending in swollen, warty receptacles.
    private static func wrack(_ out: inout [Line], _ fronds: inout [[P]], _ rng: inout SplitMix64) {
        func branch(_ base: P, _ heading: Double, _ length: Double, _ width: Double, _ depth: Int) {
            let bend = Double.random(in: -0.4..<0.4, using: &rng)
            let f = Frame(walk(base, length, 40) { s in heading + bend * s })
            let bladders = depth > 0
            func half(_ s: Double) -> Double {
                width * (bladders ? 1 + 1.2 * exp(-pow((s - 0.5) / 0.2, 2)) : 1)
            }
            out.append(Line(points: f.p, width: E.fine))
            let edges = [-1.0, 1.0].map { edge in f.p.indices.map { f.p[$0] + edge * half(f.s[$0]) * f.n[$0] } }
            for edge in edges { out.append(Line(points: edge, width: E.fine)) }
            fronds.append(edges[0] + edges[1].reversed())
            if bladders {
                let i = f.index(0.5)
                for side in [-1.0, 1.0] {
                    let c = f.p[i] + side * 1.05 * width * f.n[i]
                    out.append(Line(points: ellipse(c, f.t[i], 0.2 * length, 0.85 * width, 22), width: E.fine))
                    out.append(Line(points: E.curve(c - 0.1 * length * f.t[i] + side * 0.4 * width * f.n[i],
                                                    c + side * 0.62 * width * f.n[i],
                                                    c + 0.1 * length * f.t[i] + side * 0.4 * width * f.n[i], 6), width: E.fine))
                }
            }
            let end = f.p[f.p.count - 1], u = f.t[f.t.count - 1], v = SIMD2(-u.y, u.x), h = atan2(u.x, -u.y)
            if depth == 0 {
                let pod = (0...28).map { k -> P in
                    let th = 2 * .pi * Double(k) / 28, along = 0.5 - 0.5 * cos(th)
                    return end + 0.065 * along * u + width * (1 + 0.7 * sin(.pi * pow(along, 0.6)) - 0.9 * along) * sin(th) * v
                }
                out.append(Line(points: pod, width: E.fine))
                fronds.append(pod)
                for k in 0..<7 {
                    let p = end + (0.012 + 0.007 * Double(k)) * u + (k % 2 == 0 ? 0.7 : -0.7) * width * v
                        * Double.random(in: 0.2..<1, using: &rng) * (1 - 0.1 * Double(k))
                    out.append(Line(points: E.circle(p, 0.003, 6), width: E.fine))
                }
                return
            }
            let spread = Double.random(in: 0.42..<0.6, using: &rng)
            branch(end - 0.4 * width * v, h - spread, length * 0.88, width * 0.92, depth - 1)
            branch(end + 0.4 * width * v, h + spread, length * 0.84, width * 0.92, depth - 1)
        }
        branch(SIMD2(0.54, 0.65), -0.2, 0.12, 0.022, 2)
        branch(SIMD2(0.76, 0.44), 0.2, 0.09, 0.02, 2)
    }

    /// The boulders the wrack holds to, lower right, nearest first, each shaded in crescents on its lower left; a
    /// nearer one hides a farther. Returns their outlines.
    private static func rocks(_ out: inout [Line]) -> [[P]] {
        let stones: [(P, Double, Double, Double)] = [(SIMD2(0.36, 0.88), 0.14, 0.09, 2.0), (SIMD2(0.58, 0.76), 0.18, 0.12, 1.1),
                                                    (SIMD2(0.78, 0.56), 0.16, 0.13, 0.3)]
        var outlines: [[P]] = []
        for (c, a, b, ph) in stones {
            func edge(_ th: Double, _ f: Double) -> P {
                c + f * (1 + 0.07 * sin(3 * th + ph) + 0.04 * sin(5 * th + 2 * ph)) * SIMD2(a * cos(th), b * sin(th))
            }
            let outline = (0...90).map { edge(2 * .pi * Double($0) / 90, 1) }
            var lines = [Line(points: outline, width: E.medium)]
            for k in 1..<9 {
                let f = 1 - 0.075 * Double(k), reach = 1.3 - 0.13 * Double(k)
                lines.append(Line(points: (0...40).map { edge(3 * .pi / 4 + reach * (2 * Double($0) / 40 - 1), f) }, width: E.fine))
            }
            for line in lines { clip(&out, line.points, line.width, outlines) }
            outlines.append(outline)
        }
        return outlines
    }

    /// Plankton adrift in the open water: copepods trailing their antennae, and small round larvae with a tail.
    private static func plankton(_ out: inout [Line], _ rng: inout SplitMix64, _ hulls: [[P]]) {
        var placed = 0
        while placed < 34 {
            let c = SIMD2(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<0.6, using: &rng))
            guard simd_length(c) < 0.93, !hulls.contains(where: { inside(c, $0) }) else { continue }
            placed += 1
            let a = Double.random(in: 0..<(2 * .pi), using: &rng), u = E.dir(a), v = SIMD2(-u.y, u.x)
            if placed % 3 == 0 {
                let r = Double.random(in: 0.006..<0.011, using: &rng)
                out.append(Line(points: E.circle(c, r, 10), width: E.fine))
                out.append(Line(points: E.curve(c - r * u, c - 2.5 * r * u + 1.2 * r * v, c - 4 * r * u - 0.5 * r * v, 6), width: E.fine))
                continue
            }
            let size = Double.random(in: 0.011..<0.017, using: &rng)
            out.append(Line(points: ellipse(c, u, size, 0.42 * size, 12), width: E.fine))
            out.append(Line(points: [c - size * u, c - 2.1 * size * u], width: E.fine))
            for side in [-1.0, 1.0] {
                let tail = c - 2.1 * size * u
                out.append(Line(points: [tail, tail - 0.5 * size * u + side * 0.35 * size * v], width: E.fine))
                let head = c + size * u
                out.append(Line(points: E.curve(head, head + 1.2 * size * u + side * 1.4 * size * v,
                                                head - 0.6 * size * u + side * 2.6 * size * v, 8), width: E.fine))
            }
        }
    }

    /// Sea grass: ribbon blades rising from the bottom and bending in the current, some twisting.
    private static func grass(_ out: inout [Line], _ rng: inout SplitMix64) {
        var x = -0.92
        while x < 0.5 {
            let height = Double.random(in: 0.16..<0.42, using: &rng)
            let h0 = Double.random(in: -0.25..<0.25, using: &rng), bend = Double.random(in: -1.0..<1.0, using: &rng)
            let f = Frame(walk(SIMD2(x, bed(x) + 0.03), height, 40) { s in h0 + bend * s * s })
            let wide = Double.random(in: 0.008..<0.013, using: &rng), twist = Double.random(in: 0..<2.5, using: &rng)
            let ph = Double.random(in: 0..<6, using: &rng)
            var left: [P] = [], right: [P] = []
            for j in f.p.indices {
                let s = f.s[j], half = wide * cos(twist * s * .pi + ph * 0.2) * (1 - pow(s, 4))
                left.append(f.p[j] + half * f.n[j])
                right.append(f.p[j] - half * f.n[j])
            }
            out.append(Line(points: left + [f.p[f.p.count - 1]] + right.reversed(), width: E.fine))
            x += Double.random(in: 0.035..<0.075, using: &rng)
        }
    }

    /// The bottom: ripple lines of sand and pebbles.
    private static func seabed(_ out: inout [Line], _ rng: inout SplitMix64) {
        for k in 0..<5 {
            let y0 = 0.025 + 0.045 * Double(k)
            out.append(Line(points: (0...60).map { i in
                let x = -1 + 2 * Double(i) / 60
                return SIMD2(x, bed(x) + y0 + 0.01 * sin(9 * x + 1.7 * Double(k)) + 0.006 * sin(17 * x))
            }, width: E.fine))
        }
        for _ in 0..<40 {
            let x = Double.random(in: -0.75..<0.4, using: &rng)
            let c = SIMD2(x, bed(x) + Double.random(in: 0.04..<0.22, using: &rng))
            let a = Double.random(in: 0.008..<0.02, using: &rng)
            out.append(Line(points: ellipse(c, E.dir(Double.random(in: 1.3..<1.8, using: &rng)), a, 0.55 * a, 12), width: E.fine))
        }
    }
}
