// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate 6: leaves pressed for a herbarium: oak, maple, ginkgo, holly and ivy with their venation, a skeleton leaf
/// worn down to its lattice, and acorns, keys and berries between them.
enum Leaves {
    typealias Line = Engraving.Line
    private typealias E = Engraving
    private typealias P = SIMD2<Double>

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4C45_4146)
        // Bottom to top: each specimen's blade hides what lies under it.
        var layers: [(lines: [Line], hull: [P])] = []
        var drawn: [Line] = []
        var hull = oak(&drawn, &rng, Blade(base: P(-0.22, 0.3), heading: -0.62, length: 0.9, bend: 0.06))
        layers.append((drawn, hull)); drawn = []
        hull = ginkgo(&drawn, &rng, Palm(j: P(-0.2, -0.5), heading: -0.25, r: 0.42))
        layers.append((drawn, hull)); drawn = []
        hull = maple(&drawn, Palm(j: P(0.5, -0.16), heading: 0.44, r: 0.43))
        layers.append((drawn, hull)); drawn = []
        hull = holly(&drawn, Blade(base: P(0.32, 0.2), heading: 2.4, length: 0.56, bend: 0.06))
        layers.append((drawn, hull)); drawn = []
        hull = ivy(&drawn, &rng, Palm(j: P(-0.34, 0.5), heading: -2.3, r: 0.36), petiole: P(-0.02, 0.84))
        layers.append((drawn, hull)); drawn = []
        hull = skeleton(&drawn, &rng, Blade(base: P(0.06, 0.6), heading: 0.09, length: 0.98, bend: -0.05))
        layers.append((drawn, hull)); drawn = []
        vine(&drawn, &rng, from: P(-0.02, 0.84))
        acorns(&drawn, at: P(-0.6, -0.5), heading: -1.0, size: 0.095)
        keys(&drawn, &rng, at: P(0.4, -0.6), heading: -0.2, length: 0.23)
        berries(&drawn, &rng, at: P(0.76, 0.08), heading: 2.0)
        keys(&drawn, &rng, at: P(-0.87, 0.22), heading: -0.12, length: 0.24, spread: nil)
        layers.append((drawn, []))
        var out: [Line] = []
        for (i, layer) in layers.enumerated() {
            let above = layers.dropFirst(i + 1).map(\.hull).filter { !$0.isEmpty }
            for line in layer.lines { visible(&out, line, under: above) }
        }
        return out
    }()

    /// The parts of a line no hull covers.
    private static func visible(_ out: inout [Line], _ line: Line, under hulls: [[P]]) {
        let boxes = hulls.map { h in (h.reduce(h[0]) { simd_min($0, $1) }, h.reduce(h[0]) { simd_max($0, $1) }) }
        let lo = line.points.reduce(line.points[0]) { simd_min($0, $1) }, hi = line.points.reduce(line.points[0]) { simd_max($0, $1) }
        let near = hulls.indices.filter { all(boxes[$0].0 .<= hi) && all(lo .<= boxes[$0].1) }.map { hulls[$0] }
        guard !near.isEmpty else { out.append(line); return }
        var dense: [P] = [line.points[0]]
        for (a, b) in zip(line.points, line.points.dropFirst()) { dense += segment(a, b, step: 0.003).dropFirst() }
        var run: [P] = []
        for p in dense {
            if near.contains(where: { inside(p, $0) }) {
                if run.count > 1 { out.append(Line(points: run, width: line.width)) }
                run = []
            } else {
                run.append(p)
            }
        }
        if run.count > 1 { out.append(Line(points: run, width: line.width)) }
    }

    /// A pinnate leaf's frame: `at(s, x)` is `s` of the way up the midrib and `x` to its right, both in lengths, the
    /// midrib bowing right by `bend` at the tip.
    private struct Blade {
        var base: P, heading: Double, length: Double, bend: Double
        var u: P { E.dir(heading) }
        var v: P { P(-u.y, u.x) }
        func at(_ s: Double, _ x: Double) -> P { base + length * (s * u + (bend * s * s + x) * v) }
        func local(_ p: P) -> (s: Double, x: Double) {
            let d = (p - base) / length, s = simd_dot(d, u)
            return (s, simd_dot(d, v) - bend * s * s)
        }
    }

    /// A palmate leaf's frame: `at(a, f)` is `a` radians clockwise of its heading and `f` radii out from the junction.
    private struct Palm {
        var j: P, heading: Double, r: Double
        func at(_ a: Double, _ f: Double) -> P { j + r * f * E.dir(heading + a) }
    }

    private static func outline(_ b: Blade, left: (Double) -> Double, right: (Double) -> Double, _ n: Int = 120) -> [P] {
        (0...n).map { b.at(Double($0) / Double(n), -left(Double($0) / Double(n))) }
            + (0..<n).reversed().map { b.at(Double($0) / Double(n), right(Double($0) / Double(n))) }
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

    /// The parts of a polyline inside a polygon.
    private static func clipped(_ out: inout [Line], _ points: [P], _ poly: [P], _ width: Double) {
        var run: [P] = []
        for p in points {
            if inside(p, poly) {
                run.append(p)
            } else {
                if run.count > 1 { out.append(Line(points: run, width: width)) }
                run = []
            }
        }
        if run.count > 1 { out.append(Line(points: run, width: width)) }
    }

    /// Points from a to b at steps no longer than `step`.
    private static func segment(_ a: P, _ b: P, step: Double = 0.004) -> [P] {
        let n = max(1, Int(simd_distance(a, b) / step))
        return (0...n).map { a + (b - a) * Double($0) / Double(n) }
    }

    /// An edge from a to b, travelled clockwise round its leaf, cut into teeth over `span` of it that lean towards `b`
    /// when `lean` is over a half. Each tooth's tip goes into `tips`.
    private static func toothed(_ a: P, _ b: P, teeth: Int, span: ClosedRange<Double>, depth: Double, lean: Double,
                                swell: Double, tips: inout [P]) -> [P] {
        let d = b - a, n = P(d.y, -d.x) / simd_length(d)
        func line(_ t: Double) -> P { a + t * d + swell * simd_length(d) * sin(.pi * t) * n }
        var points = [a, line(span.lowerBound)]
        let step = (span.upperBound - span.lowerBound) / Double(teeth)
        for k in 0..<teeth {
            let t0 = span.lowerBound + Double(k) * step, t1 = t0 + step
            let t = t0 + lean * step, size = depth * simd_length(d) / Double(teeth) * (0.5 + 0.8 * sin(.pi * t))
            let tip = line(t) + size * n
            tips.append(tip)
            points += [tip, line(t1)]
        }
        return points + [b]
    }

    /// A gentle outward curve from a to b, travelled clockwise.
    private static func bulge(_ a: P, _ b: P, _ amount: Double, _ n: Int = 18) -> [P] {
        let d = b - a, nrm = P(d.y, -d.x) / simd_length(d)
        return E.curve(a, (a + b) / 2 + amount * simd_length(d) * nrm, b, n)
    }

    /// A leaf with nothing left but its veins: the midrib, looping secondaries and the areoles between, as the cells of
    /// a Voronoi net over scattered sites.
    private static func skeleton(_ out: inout [Line], _ rng: inout SplitMix64, _ b: Blade) -> [P] {
        func half(_ s: Double) -> Double { 0.25 * pow(sin(.pi * pow(min(max(s, 0), 1), 0.72)), 0.85) }
        let poly = outline(b, left: { half($0) * 0.97 }, right: half)
        out.append(Line(points: poly + [poly[0]], width: E.medium))
        out.append(Line(points: (0...60).map { b.at(-0.16 + 1.16 * Double($0) / 60, 0) }, width: E.heavy))
        // Secondaries, alternate, each arching up to meet the one above near the margin.
        for side in [-1.0, 1.0] {
            let count = side < 0 ? 9 : 10
            var loops: [P] = []
            for k in 0..<count {
                let s = 0.06 + 0.84 * (Double(k) + (side < 0 ? 0.5 : 0)) / Double(count)
                let reach = s + 0.13, w = half(reach) * 0.86
                let vein = E.curve(b.at(s, 0), b.at(s + 0.06, side * 0.55 * w), b.at(reach, side * w), 16)
                out.append(Line(points: vein, width: E.medium))
                loops.append(vein.last!)
            }
            for (p, q) in zip(loops, loops.dropFirst()) {
                let mid = b.local((p + q) / 2)
                out.append(Line(points: E.curve(p, b.at(mid.s, mid.x + side * 0.03), q, 10), width: E.fine))
            }
        }
        let spacing = 0.039
        var sites: [P] = []
        for _ in 0..<9000 where sites.count < 400 {
            let s = Double.random(in: 0..<1, using: &rng), x = Double.random(in: -0.3..<0.3, using: &rng)
            guard abs(x) < half(s) else { continue }
            let p = b.at(s, x)
            guard !sites.contains(where: { simd_distance($0, p) < spacing }) else { continue }
            sites.append(p)
        }
        // Each cell wall: the bisector of two sites, cut back wherever a third site is nearer.
        for i in sites.indices {
            for j in sites.indices where j > i && simd_distance(sites[i], sites[j]) < 2.6 * spacing {
                let a = sites[i], c = sites[j], m = (a + c) / 2, d = simd_normalize(c - a), w = P(-d.y, d.x)
                var lo = -2 * spacing, hi = 2 * spacing
                for k in sites.indices where k != i && k != j && simd_distance(sites[k], m) < 4 * spacing {
                    let g = sites[k] - a, lim = simd_length_squared(sites[k]) - simd_length_squared(a)
                    let wg = 2 * simd_dot(w, g), mg = 2 * simd_dot(m, g)
                    if abs(wg) < 1e-12 {
                        if mg > lim { hi = lo - 1 }
                    } else if wg > 0 {
                        hi = min(hi, (lim - mg) / wg)
                    } else {
                        lo = max(lo, (lim - mg) / wg)
                    }
                    if hi <= lo { break }
                }
                guard hi - lo > 0.002 else { continue }
                clipped(&out, segment(m + lo * w, m + hi * w, step: 0.006), poly, E.fine)
            }
        }
        return poly
    }

    /// An oak leaf: rounded lobes cut by deep sinuses, unequal either side, a vein to each lobe and its branches.
    private static func oak(_ out: inout [Line], _ rng: inout SplitMix64, _ b: Blade) -> [P] {
        func env(_ s: Double) -> Double { 0.3 * pow(sin(.pi * pow(min(max(s, 0), 1), 1.5)), 0.7) + 0.01 }
        let lobes: [(n: Double, ph: Double)] = [(4.6, 0.12), (4.2, 0.4)]
        func lobe(_ s: Double, _ k: Int) -> Double { 0.32 + 0.68 * pow(abs(sin(.pi * (lobes[k].n * s + lobes[k].ph))), 0.45) }
        let poly = outline(b, left: { env($0) * lobe($0, 0) }, right: { env($0) * lobe($0, 1) }, 200)
        out.append(Line(points: poly + [poly[0]], width: E.medium))
        out.append(Line(points: (0...60).map { b.at(-0.14 + 1.1 * Double($0) / 60, 0) }, width: E.heavy))
        for (k, side) in [(0, -1.0), (1, 1.0)] {
            var veins: [[P]] = []
            var i = 0
            while true {
                let s = (Double(i) + 0.5 - lobes[k].ph) / lobes[k].n
                i += 1
                guard s < 0.93 else { break }
                guard s > 0.06 else { continue }
                let w = env(s) * lobe(s, k)
                let vein = E.curve(b.at(s - 0.08, 0), b.at(s - 0.03, side * 0.45 * w), b.at(s, side * 0.9 * w), 16)
                out.append(Line(points: vein, width: E.fine))
                veins.append(vein)
                // The shaded half takes the hatching; the lit half shows branches into each lobe's shoulders.
                guard side > 0 else { continue }
                for (f, ds) in [(0.45, -0.05), (0.62, 0.045)] {
                    let p = vein[Int(f * 16)], ts = s + ds * Double.random(in: 0.8..<1.2, using: &rng)
                    out.append(Line(points: E.curve(p, (p + b.at(ts, side * 0.6 * env(ts) * lobe(ts, k))) / 2 + 0.01 * b.u,
                                                    b.at(ts, side * 0.8 * env(ts) * lobe(ts, k)), 8), width: E.fine))
                }
            }
            guard side > 0 else { continue }
            for (lower, upper) in zip(veins, veins.dropFirst()) {
                let f = Double.random(in: 0.2..<0.35, using: &rng), a = lower[Int(f * 16)], c = upper[Int(f * 10)]
                out.append(Line(points: E.curve(a, (a + c) / 2 + 0.02 * b.u + 0.01 * b.v, c, 8), width: E.fine))
            }
        }
        // The engraver's shade: strokes along the veins over the half of the blade turned from the light.
        var s = 0.04
        while s < 0.94 {
            let w = env(s + 0.05) * lobe(s + 0.05, 0)
            clipped(&out, segment(b.at(s, -0.012), b.at(s + 0.05, -Double.random(in: 0.5..<0.7, using: &rng) * w), step: 0.004),
                    poly, E.fine)
            s += 0.022
        }
        return poly
    }

    /// A maple leaf: five toothed lobes, a main vein to each tip and a vein to each tooth.
    private static func maple(_ out: inout [Line], _ p: Palm) -> [P] {
        let tips: [(a: Double, f: Double)] = [(-1.95, 0.5), (-0.98, 0.84), (0.04, 1.0), (1.02, 0.8), (2.0, 0.46)]
        let sinus: [Double] = [0.36, 0.42, 0.4, 0.33]
        var edge: [P] = [p.at(.pi + 0.02, 0.05), p.at(-2.6, 0.16)]
        var targets: [(lobe: Int, tip: P)] = []
        for k in tips.indices {
            let tip = p.at(tips[k].a, tips[k].f)
            var found: [P] = []
            edge += toothed(edge.last!, tip, teeth: k == 0 ? 3 : 4, span: 0.12...0.8, depth: 0.36, lean: 0.7, swell: 0.08,
                             tips: &found).dropFirst()
            let next = k + 1 < tips.count ? p.at((tips[k].a + tips[k + 1].a) / 2, sinus[k]) : p.at(2.62, 0.15)
            edge += toothed(tip, next, teeth: k == tips.count - 1 ? 3 : 4, span: 0.2...0.88, depth: 0.36, lean: 0.3, swell: 0.08,
                             tips: &found).dropFirst()
            targets += found.map { (k, $0) }
        }
        edge.append(p.at(.pi - 0.02, 0.05))
        out.append(Line(points: edge, width: E.medium))
        out.append(Line(points: E.curve(p.j, p.at(.pi + 0.15, 0.5), p.at(.pi + 0.05, 1.05), 20), width: E.heavy))
        for t in tips {
            out.append(Line(points: E.curve(p.j, p.at(t.a - 0.04, t.f * 0.5), p.at(t.a, t.f * 0.97), 24), width: E.medium))
        }
        for (k, tooth) in targets {
            let axis = E.dir(p.heading + tips[k].a), along = max(0.15, simd_dot(tooth - p.j, axis) / p.r * 0.72)
            let from = p.j + p.r * along * axis
            out.append(Line(points: E.curve(from, (from + tooth) / 2 + 0.02 * p.r * axis, from + 0.96 * (tooth - from), 10),
                            width: E.fine))
        }
        return edge
    }

    /// A ginkgo fan: a wedge on a long petiole, its outer edge waved and notched in the middle, its veins forking in
    /// pairs from the base out to the edge.
    private static func ginkgo(_ out: inout [Line], _ rng: inout SplitMix64, _ p: Palm) -> [P] {
        let left = -1.18, right = 1.3
        func rim(_ a: Double) -> Double {
            (1 + 0.025 * sin(11 * a + 1) + 0.015 * sin(23 * a)) * (1 - 0.28 * exp(-pow((a - 0.1) / 0.06, 2)))
        }
        let edge = (0...160).map { i -> P in
            let a = left + (right - left) * Double(i) / 160
            return p.at(a, rim(a))
        }
        let base = p.at(.pi, 0.02)
        let hull = E.curve(base, p.at(left + 0.25, 0.3), edge.first!, 20) + edge.dropFirst()
            + E.curve(edge.last!, p.at(right - 0.25, 0.3), base, 20).dropFirst()
        out.append(Line(points: hull, width: E.medium))
        out.append(Line(points: E.curve(base, p.at(.pi + 0.2, 0.55), p.at(.pi + 0.05, 1.1), 24), width: E.heavy))
        // Two veins from the petiole, each forking at its own radius, six times over.
        func fork(_ a: Double, _ lo: Double, _ hi: Double, _ r: Double, _ depth: Int) {
            let mid = (lo + hi) / 2
            let next = depth == 6 ? rim(mid) * 0.98 : r + (0.94 - r) * Double.random(in: 0.2..<0.32, using: &rng)
            out.append(Line(points: (0...12).map { i in
                let t = Double(i) / 12
                return p.at(a + (mid - a) * sqrt(t), r + (next - r) * t)
            }, width: E.fine))
            guard depth < 6 else { return }
            let cut = lo + (hi - lo) * Double.random(in: 0.42..<0.58, using: &rng)
            fork(mid, lo, cut, next, depth + 1)
            fork(mid, cut, hi, next, depth + 1)
        }
        fork(0.06, left + 0.05, 0.1, 0.03, 1)
        fork(0.06, 0.1, right - 0.05, 0.03, 1)
        return hull
    }

    /// A holly leaf: spines unequal either side, a thick margin drawn double, and veins looping towards each spine.
    private static func holly(_ out: inout [Line], _ b: Blade) -> [P] {
        func env(_ s: Double) -> Double { 0.26 * pow(sin(.pi * pow(min(max(s, 0), 1), 0.85)), 0.75) }
        var hull: [P] = []
        for (side, spines) in [(-1.0, [0.1, 0.25, 0.41, 0.57, 0.72, 0.86]), (1.0, [0.16, 0.33, 0.5, 0.67, 0.83])] {
            var edge = [b.at(0, 0)], inner: [P] = []
            for s in spines + [1.06] {
                let tip = s > 1 ? b.at(s, 0) : b.at(s + 0.03, side * (env(s) * 1.18 + 0.02))
                let prev = edge.last!, ms = (b.local(prev).s + min(s, 1)) / 2
                edge += E.curve(prev, b.at(ms, side * env(ms) * 0.62), tip, 12).dropFirst()
                inner += E.curve(prev, b.at(ms, side * env(ms) * 0.55), tip, 12).dropFirst().dropLast(3)
            }
            out.append(Line(points: edge, width: E.medium))
            out.append(Line(points: inner, width: E.fine))
            hull = side < 0 ? edge : hull + edge.reversed()
            for (k, s) in spines.enumerated() {
                let to = b.at(s - 0.01, side * env(s) * 0.7)
                out.append(Line(points: E.curve(b.at(s - 0.06, 0), b.at(s - 0.05, side * env(s) * 0.4), to, 12), width: E.fine))
                if k + 1 < spines.count {
                    let s2 = spines[k + 1]
                    out.append(Line(points: E.curve(to, b.at((s + s2) / 2, side * env(s) * 0.82), b.at(s2 - 0.04, side * env(s2) * 0.62), 10),
                                    width: E.fine))
                }
            }
        }
        out.append(Line(points: (0...50).map { b.at(-0.12 + 1.12 * Double($0) / 50, 0) }, width: E.heavy))
        var s = 0.03
        while s < 0.95 {
            clipped(&out, segment(b.at(s, 0.012), b.at(s + 0.07, 0.75 * env(s + 0.07)), step: 0.004), hull, E.fine)
            s += 0.027
        }
        return hull
    }

    /// An ivy leaf: five triangular lobes, shallow sinuses and a heart-shaped base, its veins fanning from the petiole.
    @discardableResult
    private static func ivy(_ out: inout [Line], _ rng: inout SplitMix64, _ p: Palm, petiole: P? = nil) -> [P] {
        let tips: [(a: Double, f: Double)] = [(-2.15, 0.56), (-1.08, 0.8), (0.03, 1.0), (1.12, 0.74), (2.2, 0.52)]
        let sinus: [Double] = [0.52, 0.6, 0.58, 0.5]
        var edge: [P] = [p.at(-2.95, 0.14)]
        var mids: [(lobe: Int, at: P)] = []
        for k in tips.indices {
            let tip = p.at(tips[k].a, tips[k].f)
            let up = bulge(edge.last!, tip, 0.1)
            edge += up.dropFirst()
            mids.append((k, up[up.count / 2]))
            let next = k + 1 < tips.count ? p.at((tips[k].a + tips[k + 1].a) / 2, sinus[k]) : p.at(2.95, 0.14)
            let down = bulge(tip, next, 0.1)
            edge += down.dropFirst()
            mids.append((k, down[down.count / 2]))
        }
        edge += E.curve(edge.last!, p.at(.pi, 0.02), edge[0], 10).dropFirst()
        out.append(Line(points: edge, width: E.medium))
        let foot = p.at(.pi, 0.02)
        out.append(Line(points: E.curve(foot, petiole.map { foot + 0.7 * simd_distance(foot, $0) * simd_normalize(foot - p.j) }
                                        ?? p.at(.pi - 0.3, 0.6), petiole ?? p.at(.pi - 0.1, 1.2), 30), width: E.heavy))
        for t in tips {
            out.append(Line(points: E.curve(p.j, p.at(t.a + 0.05, t.f * 0.5), p.at(t.a, t.f * 0.95), 24), width: E.medium))
            var f = 0.12
            while f < t.f * 0.9 {
                let from = p.at(t.a + 0.05 * sin(.pi * f / t.f), f) , to = p.at(t.a - 0.5 * (1 - f / t.f) - 0.12, f + 0.12 * p.r)
                clipped(&out, segment(from + 0.008 * simd_normalize(to - from), to, step: 0.004), edge, E.fine)
                f += 0.055
            }
        }
        for (k, m) in mids {
            let axis = E.dir(p.heading + tips[k].a)
            let from = p.j + p.r * tips[k].f * Double.random(in: 0.3..<0.45, using: &rng) * axis
            out.append(Line(points: E.curve(from, (from + m) / 2 + 0.05 * p.r * axis, from + 0.94 * (m - from), 12), width: E.fine))
        }
        return edge
    }

    /// An ivy stem along the bottom, aerial rootlets under it, a young leaf and a head of berries at its end.
    private static func vine(_ out: inout [Line], _ rng: inout SplitMix64, from start: P) {
        let stem = E.curve(start, P(0.24, 0.95), P(0.47, 0.78), 60)
        out.append(Line(points: stem, width: E.heavy))
        for i in stride(from: 3, to: stem.count - 6, by: 3) {
            let p = stem[i], d = simd_normalize(stem[i + 1] - stem[i - 1]), down = P(-d.y, d.x)
            for _ in 0..<2 {
                let len = Double.random(in: 0.015..<0.035, using: &rng), lean = Double.random(in: -0.6..<0.6, using: &rng)
                out.append(Line(points: E.curve(p, p + 0.5 * len * down, p + len * simd_normalize(down + lean * d), 5), width: E.fine))
            }
        }
        ivy(&out, &rng, Palm(j: stem[30] + P(-0.01, -0.13), heading: -0.3, r: 0.12), petiole: stem[30])
        let head = stem.last! + P(0.05, -0.02)
        out.append(Line(points: E.curve(stem[stem.count - 4], stem.last! + P(0.02, 0.0), head, 8), width: E.medium))
        for k in 0..<7 {
            let h = 0.1 + 2.2 * Double(k) / 6 + Double.random(in: -0.1..<0.1, using: &rng)
            let len = Double.random(in: 0.045..<0.06, using: &rng), c = head + len * E.dir(h)
            out.append(Line(points: [head, c - 0.017 * E.dir(h)], width: E.fine))
            out.append(Line(points: E.circle(c, 0.017, 18), width: E.fine))
            out.append(Line(points: E.circle(c + 0.008 * E.dir(h), 0.004, 8), width: E.fine))
        }
    }

    /// Two acorns on a forked stalk, their cups scaled in rows.
    private static func acorns(_ out: inout [Line], at fork: P, heading: Double, size: Double) {
        out.append(Line(points: E.curve(fork, fork - 0.4 * size * E.dir(heading + 0.3), fork - 0.9 * size * E.dir(heading - 0.1), 12),
                        width: E.medium))
        for (spread, reach) in [(-0.5, 0.45), (0.45, 1.15)] {
            let h = heading + spread, u = E.dir(h), v = P(-u.y, u.x)
            let cup = fork + reach * size * u
            out.append(Line(points: E.curve(fork, fork + 0.5 * reach * size * E.dir(h - 0.3 * spread), cup, 10), width: E.medium))
            // The bowl hangs back from its rim towards the stalk.
            let rim = cup + 0.4 * size * u, half = 0.4 * size, depth = 0.4 * size
            func bowl(_ t: Double, _ f: Double) -> P { rim + f * (half * cos(t) * v - depth * sin(t) * u) }
            out.append(Line(points: (0...24).map { bowl(.pi * Double($0) / 24, 1) }, width: E.medium))
            out.append(Line(points: E.curve(rim - half * v, rim + 0.06 * size * u, rim + half * v, 12), width: E.medium))
            for row in 0..<3 {
                let f = 0.78 - 0.24 * Double(row), count = 7 - 2 * row
                for k in 0..<count {
                    let t = .pi * (Double(k) + (row % 2 == 0 ? 0.5 : 0.8)) / Double(count)
                    let c = bowl(t, f)
                    out.append(Line(points: E.curve(c - 0.06 * size * v, c - 0.07 * size * u, c + 0.06 * size * v, 6), width: E.fine))
                }
            }
            // The nut, from the rim to its point, and a line down one side for its sheen.
            let nut = rim + 0.36 * size * u, a = 0.66 * size, b = 0.34 * size, t0 = asin(-0.36 / 0.66)
            func shell(_ t: Double, _ f: Double) -> P { nut + f * b * cos(t) * v + a * sin(t) * (1 + 0.12 * pow(max(sin(t), 0), 6)) * u }
            out.append(Line(points: (0...40).map { shell(t0 + (.pi - 2 * t0) * Double($0) / 40, 1) }, width: E.medium))
            out.append(Line(points: [shell(.pi / 2, 1), shell(.pi / 2, 1) + 0.08 * size * u], width: E.medium))
            out.append(Line(points: (0...12).map { shell(0.05 + 1.1 * Double($0) / 12, 0.62) }, width: E.fine))
        }
    }

    /// Maple keys: winged seeds joined at their nutlets (one alone when `spread` is nil), each wing veined from its seed.
    private static func keys(_ out: inout [Line], _ rng: inout SplitMix64, at join: P, heading: Double, length: Double,
                             spread: Double? = 0.62) {
        for side in spread == nil ? [1.0] : [-1.0, 1.0] {
            let h = heading + side * (spread ?? 0), u = E.dir(h), v = side * P(-u.y, u.x)
            let seed = join + 0.1 * length * u
            out.append(Line(points: (0...24).map { i in
                let t = 2 * .pi * Double(i) / 24
                return seed + 0.12 * length * cos(t) * u + 0.085 * length * sin(t) * v
            }, width: E.medium))
            func wing(_ t: Double) -> Double { 0.27 * pow(sin(.pi * pow(t, 1.6)), 0.7) + 0.06 * (1 - t) }
            let lead: [P] = (0...30).map { (i: Int) -> P in
                let t: Double = Double(i) / 30
                let ahead: P = (0.12 + 0.88 * t) * u
                let side: P = (0.03 * sin(.pi * t)) * v
                return seed + length * (ahead - side)
            }
            let trail: [P] = (0...30).map { (i: Int) -> P in
                let t: Double = Double(i) / 30
                let ahead: P = (0.12 + 0.88 * t) * u
                let side: P = wing(t) * v
                return seed + length * (ahead + side)
            }
            out.append(Line(points: lead + trail.reversed(), width: E.medium))
            for k in 0..<7 {
                let t = 0.35 + 0.09 * Double(k) + Double.random(in: -0.02..<0.02, using: &rng)
                let end = seed + length * ((0.12 + 0.88 * t) * u + 0.92 * wing(t) * v)
                out.append(Line(points: E.curve(seed + 0.12 * length * u, seed + length * (0.5 * t * u + 0.02 * v), end, 12), width: E.fine))
            }
        }
        out.append(Line(points: E.curve(join, join - 0.15 * length * E.dir(heading - 0.4), join - 0.3 * length * E.dir(heading - 0.2), 8),
                        width: E.fine))
    }

    /// Holly berries on short stalks from one node, each with its shine and the scar at its tip.
    private static func berries(_ out: inout [Line], _ rng: inout SplitMix64, at node: P, heading: Double) {
        for (spread, reach, r) in [(-0.7, 0.06, 0.034), (0.2, 0.09, 0.038), (1.05, 0.055, 0.032), (2.0, 0.075, 0.03)] {
            let h = heading + spread + Double.random(in: -0.1..<0.1, using: &rng), u = E.dir(h), c = node + (reach + r) * u
            out.append(Line(points: E.curve(node, node + 0.5 * reach * E.dir(h - 0.3), c - r * u, 6), width: E.fine))
            out.append(Line(points: E.circle(c, r, 28), width: E.medium))
            out.append(Line(points: E.arc(c, 0.62 * r, from: -2.6, to: -1.4, 10), width: E.fine))
            let tip = c + 0.5 * r * u
            for k in 0..<5 {
                out.append(Line(points: [tip, tip + 0.22 * r * E.dir(h + 0.3 + 2 * .pi * Double(k) / 5)], width: E.fine))
            }
        }
    }
}
