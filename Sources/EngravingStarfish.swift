// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: echinoderms on the sea floor after Haeckel: a starfish netted with ossicles and fringed with tube feet, a
/// brittle star's snaking arms, a sand dollar's petals, a feather star, a sea cucumber and a cushion star, seen from
/// above on rippled sand among shells. No two arms bend alike, so no figure is whole about a core's centre.
enum Starfish {
    typealias Line = Engraving.Line
    private typealias E = Engraving
    private typealias P = SIMD2<Double>

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x5354_4152)
        var sheet = Sheet()
        brittleStar(&sheet, &rng)
        seaStar(&sheet, &rng)
        featherStar(&sheet, &rng)
        sandDollar(&sheet, &rng)
        cushionStar(&sheet, &rng)
        seaCucumber(&sheet, &rng)
        shells(&sheet, &rng)
        sand(&sheet, &rng)
        return sheet.lines
    }()

    /// Lines laid front to back: each is cut where something already laid covers it, so a specimen drawn later lies
    /// under those drawn before.
    private struct Sheet {
        var lines: [Line] = []
        private var covers: [(poly: [P], lo: P, hi: P, margin: Double)] = []

        func covered(_ p: P, extra: Double = 0) -> Bool {
            for c in covers {
                let m = c.margin + extra
                guard p.x > c.lo.x - m, p.y > c.lo.y - m, p.x < c.hi.x + m, p.y < c.hi.y + m else { continue }
                if Starfish.inside(p, c.poly) || Starfish.near(p, c.poly, m) { return true }
            }
            return false
        }

        mutating func draw(_ points: [P], _ width: Double) {
            var run: [P] = []
            for p in points {
                if covered(p) {
                    if run.count > 1 { lines.append(Line(points: run, width: width)) }
                    run = []
                } else {
                    run.append(p)
                }
            }
            if run.count > 1 { lines.append(Line(points: run, width: width)) }
        }

        mutating func cover(_ poly: [P], margin: Double = 0.012) {
            let lo = poly.reduce(P(9, 9)) { simd_min($0, $1) }, hi = poly.reduce(P(-9, -9)) { simd_max($0, $1) }
            covers.append((poly, lo, hi, margin))
        }
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

    private static func near(_ p: P, _ poly: [P], _ d: Double) -> Bool {
        guard d > 0 else { return false }
        var j = poly.count - 1
        for i in poly.indices {
            let a = poly[j], ab = poly[i] - a
            let t = simd_clamp(simd_dot(p - a, ab) / max(simd_length_squared(ab), 1e-12), 0, 1)
            if simd_distance(p, a + t * ab) < d { return true }
            j = i
        }
        return false
    }

    /// A path from `start` setting out along `heading` (clockwise from up), turned by `turn(s)` at fraction s of its
    /// length: its points and the heading at each.
    private static func path(_ start: P, _ heading: Double, _ length: Double, _ n: Int,
                             _ turn: (Double) -> Double) -> (points: [P], headings: [Double]) {
        var points = [start], headings = [heading + turn(0)]
        for i in 1...n {
            let s = Double(i) / Double(n), h = heading + turn(s)
            points.append(points[i - 1] + length / Double(n) * E.dir(h))
            headings.append(h)
        }
        return (points, headings)
    }

    /// The unit vector a quarter turn clockwise of `heading`.
    private static func side(_ h: Double) -> P { E.dir(h + .pi / 2) }

    /// An ellipse about `c`: radius `r` across `axis`, `squash` times that along it.
    private static func ring(_ c: P, _ r: Double, _ squash: Double = 1, _ axis: Double = 0) -> [P] {
        let u = E.dir(axis), v = side(axis), n = max(8, Int(r * 900))
        return (0...n).map { i in
            let t = 2 * .pi * Double(i) / Double(n)
            return c + r * cos(t) * v + squash * r * sin(t) * u
        }
    }

    /// A tube foot: a stalk out from `p` along `h`, bending by `lean`, ending in its sucker.
    private static func foot(_ sheet: inout Sheet, _ p: P, _ h: Double, _ length: Double, lean: Double) {
        let tip = p + length * E.dir(h + lean)
        sheet.draw(E.curve(p, p + 0.6 * length * E.dir(h), tip, 6), E.fine)
        sheet.draw(E.circle(tip + 0.0045 * E.dir(h + lean), 0.0045, 10), E.fine)
    }

    // MARK: Starfish

    /// The common starfish from above: five arms that bend each their own way, the skeleton's ossicles netted in rows
    /// along them, tube feet fringing every arm and the madreporite off the disc's centre.
    private static func seaStar(_ sheet: inout Sheet, _ rng: inout SplitMix64) {
        let c = P(-0.25, -0.31), disc = 0.088
        // (length, bend at the tip, heading's offset)
        let arms: [(Double, Double, Double)] = [(0.43, -0.95, 0.05), (0.37, 1.2, -0.06), (0.45, 0.45, 0.08),
                                                (0.34, -1.5, -0.03), (0.4, 0.8, 0.0)]
        func w(_ s: Double) -> Double { 0.009 + 0.047 * pow(1 - s, 0.85) }
        var outline: [P] = []
        var headings: [Double] = []
        var spines: [([P], [Double])] = []
        for (k, arm) in arms.enumerated() {
            let h0 = 0.3 + 2 * .pi * Double(k) / 5 + arm.2
            headings.append(h0)
            spines.append(path(c + disc * E.dir(h0), h0, arm.0, 70) { arm.1 * pow($0, 1.7) })
        }
        for k in 0..<5 {
            let (pts, hs) = spines[k], n = pts.count - 1, arm = arms[k]
            let left = (0...n).map { pts[$0] - w(Double($0) / Double(n)) * side(hs[$0]) }
            let right = (0...n).map { pts[$0] + w(Double($0) / Double(n)) * side(hs[$0]) }
            let tip = (0...10).map { i -> P in
                let f = Double(i) / 10 * .pi
                return pts[n] + w(1) * (-cos(f) * side(hs[n]) + sin(f) * E.dir(hs[n]))
            }
            outline += left + tip + right.reversed()
            let next = (k + 1) % 5, hn = headings[next] + (next == 0 ? 2 * .pi : 0)
            let b = spines[next].0[0] - w(0) * side(spines[next].1[0])
            outline += E.curve(right[0], c + 0.95 * disc * E.dir((headings[k] + hn) / 2), b, 12).dropFirst()

            // Ossicles: a keel row down the arm and a row each side staggered against it, netted.
            var keel: [P] = [], flanks: [[P]] = [[], []]
            var s = 0.0
            while s < 0.93 {
                let i = Int(s * Double(n)), j = min(n, Int((s + 0.011 / arm.0) * Double(n)))
                let rk = 0.0068 * (1 - 0.55 * s) + 0.0015
                keel.append(pts[i])
                sheet.draw(E.circle(pts[i], rk, 12), E.fine)
                for (f, sign) in [(0, -1.0), (1, 1.0)] {
                    let q = pts[j] + sign * 0.56 * w(Double(j) / Double(n)) * side(hs[j])
                    flanks[f].append(q)
                    sheet.draw(E.circle(q, 0.75 * rk, 10), E.fine)
                }
                s += 0.028 / arm.0 * (1 - 0.3 * s)
            }
            for f in 0..<2 {
                for i in 0..<min(keel.count, flanks[f].count) {
                    for a in [keel[i], i + 1 < keel.count ? keel[i + 1] : keel[i]] {
                        let gap = simd_distance(a, flanks[f][i])
                        guard gap > 0.012 else { continue }
                        let d = (flanks[f][i] - a) / gap
                        sheet.draw([a + 0.006 * d, flanks[f][i] - 0.005 * d], E.fine)
                    }
                }
            }
            // Tube feet out from under both edges, longer towards the arm's base, each leaning its own way.
            for (edge, sign) in [(left, -1.0), (right, 1.0)] {
                var i = 7
                while i < n - 1 {
                    let f = Double(i) / Double(n)
                    let len = (0.024 - 0.012 * f) * .random(in: 0.7..<1.2, using: &rng)
                    foot(&sheet, edge[i], hs[i] + sign * .pi / 2, len, lean: -sign * Double.random(in: 0.1..<0.6, using: &rng))
                    i += max(1, Int(0.028 / arm.0 * Double(n) * .random(in: 0.8..<1.25, using: &rng)))
                }
            }
        }
        sheet.draw(outline + [outline[0]], E.heavy)
        // The disc: scattered ossicles, and the madreporite's sieve in one interradius.
        for _ in 0..<14 {
            let p = c + Double.random(in: 0..<0.75, using: &rng) * disc * E.dir(Double.random(in: 0..<(2 * .pi), using: &rng))
            sheet.draw(E.circle(p, Double.random(in: 0.003..<0.006, using: &rng), 10), E.fine)
        }
        let mad = c + 0.62 * disc * E.dir(headings[1] + 0.7)
        sheet.draw(E.circle(mad, 0.016, 20), E.medium)
        for k in 0..<5 {
            let y = -0.011 + 0.0055 * Double(k), x = sqrt(max(0, 0.014 * 0.014 - y * y))
            sheet.draw(E.curve(mad + P(-x, y), mad + P(0, y + 0.003 * (k % 2 == 0 ? 1 : -1)), mad + P(x, y), 6), E.fine)
        }
        sheet.cover(outline, margin: 0.03)
    }

    // MARK: Brittle star

    /// A brittle star: a small scaled disc, a pair of radial shields at each arm's root, and five long thin arms
    /// snaking off, jointed and set with spines.
    private static func brittleStar(_ sheet: inout Sheet, _ rng: inout SplitMix64) {
        let c = P(0.2, 0.13), r = 0.058, h0 = 1.2
        // (length, amplitude, waves, phase, drift)
        let arms: [(Double, Double, Double, Double, Double)] = [(0.6, 0.9, 1.3, 0.4, 0.5), (0.55, 0.7, 1.6, 2.1, -0.9),
                                                                (0.62, 1.0, 1.1, 4.0, 0.3), (0.5, 0.8, 1.8, 1.0, -0.2),
                                                                (0.42, 0.5, 1.2, 5.2, -0.3)]
        var covers: [[P]] = []
        for (k, arm) in arms.enumerated() {
            let h = h0 + 2 * .pi * Double(k) / 5 + Double.random(in: -0.12..<0.12, using: &rng)
            let (pts, hs) = path(c + 0.8 * r * E.dir(h), h, arm.0, 140) { s in
                arm.1 * (sin(2 * .pi * arm.2 * s + arm.3) - sin(arm.3)) * sqrt(s) + arm.4 * s * s
            }
            let n = pts.count - 1
            func w(_ i: Int) -> Double { 0.003 + 0.0115 * pow(1 - Double(i) / Double(n), 0.7) }
            let left = (0...n).map { pts[$0] - w($0) * side(hs[$0]) }, right = (0...n).map { pts[$0] + w($0) * side(hs[$0]) }
            sheet.draw(left, E.medium)
            sheet.draw(right, E.medium)
            sheet.draw(E.curve(left[n], pts[n] + 0.008 * E.dir(hs[n]), right[n], 6), E.medium)
            var i = 2, joint = 0
            while i < n - 2 {
                let f = Double(i) / Double(n)
                // Joints bow towards the tip; spines splay from each, two a side at every third.
                sheet.draw(E.curve(left[i], pts[i] + 0.5 * w(i) * E.dir(hs[i]), right[i], 6), E.fine)
                for sign in [-1.0, 1.0] {
                    let base = sign < 0 ? left[i] : right[i]
                    for m in 0..<(joint % 3 == 0 ? 2 : 1) {
                        let a = hs[i] + sign * (.pi / 2 - 0.75 - 0.25 * Double(m))
                        let len = (0.016 - 0.009 * f) * (m == 0 ? 1 : 0.7)
                        sheet.draw([base, base + len * E.dir(a)], E.fine)
                    }
                }
                joint += 1
                i += max(2, Int((0.02 - 0.009 * f) / arm.0 * Double(n)))
            }
            covers.append(left + right.reversed())
        }
        // The disc, swelling between the arms.
        let disc = (0...90).map { i -> P in
            let t = 2 * .pi * Double(i) / 90
            return c + r * (1 + 0.09 * cos(5 * (t - h0) + .pi)) * E.dir(t)
        }
        sheet.draw(disc, E.heavy)
        for k in 0..<5 {
            let h = h0 + 2 * .pi * Double(k) / 5
            for sign in [-1.0, 1.0] {
                sheet.draw(ring(c + 0.66 * r * E.dir(h + sign * 0.27), 0.27 * r, 0.42, h + sign * 0.27 + .pi / 2 + sign * 0.2), E.fine)
            }
        }
        sheet.draw(E.circle(c + P(0.006, -0.004), 0.011, 14), E.fine)
        var scales = 0
        while scales < 18 {
            let p = c + P(Double.random(in: -0.8..<0.8, using: &rng), Double.random(in: -0.8..<0.8, using: &rng)) * r
            guard simd_distance(p, c) < 0.8 * r, simd_distance(p, c) > 0.2 * r else { continue }
            scales += 1
            sheet.draw(E.circle(p, Double.random(in: 0.003..<0.0055, using: &rng), 8), E.fine)
        }
        sheet.cover(disc, margin: 0.014)
        for poly in covers { sheet.cover(poly, margin: 0.02) }
    }

    // MARK: Feather star

    /// A feather star: ten arms in pairs off a small calyx, each plumed with alternating pinnules and curling its own
    /// way at the tip, and hooked cirri showing between the pairs.
    private static func featherStar(_ sheet: inout Sheet, _ rng: inout SplitMix64) {
        let c = P(0.5, -0.53), a0 = -0.25
        var covers: [[P]] = []
        for k in 0..<5 {
            for pair in [-1.0, 1.0] {
                let h = a0 + 2 * .pi * Double(k) / 5 + pair * 0.21 + Double.random(in: -0.08..<0.08, using: &rng)
                let len = Double.random(in: 0.28..<0.38, using: &rng)
                let curl = (rng.below(2) == 0 ? -1.0 : 1.0) * Double.random(in: 0.5..<2.6, using: &rng)
                let sweep = Double.random(in: -0.35..<0.35, using: &rng)
                let (pts, hs) = path(c + 0.03 * E.dir(h), h, len, 90) { s in sweep * s + curl * pow(s, 3) }
                let n = pts.count - 1
                sheet.draw(pts, E.medium)
                var i = 3, alt = rng.below(2) == 0 ? -1.0 : 1.0
                while i < n {
                    let f = Double(i) / Double(n)
                    let pl = 0.042 * (1 - 0.6 * f) * (f < 0.12 ? 1.25 : 1) * .random(in: 0.85..<1.1, using: &rng)
                    let a = hs[i] + alt * (.pi / 2 - 0.62), tip = pts[i] + pl * E.dir(a)
                    sheet.draw(E.curve(pts[i], pts[i] + 0.55 * pl * E.dir(a), tip + 0.2 * pl * E.dir(hs[i]), 6), E.fine)
                    alt = -alt
                    i += max(1, Int(0.0125 / len * Double(n)))
                }
                var band: ([P], [P]) = ([], [])
                for j in stride(from: 0, through: n, by: 6) {
                    let wd = 0.036 * (1 - 0.6 * Double(j) / Double(n)) + 0.004
                    band.0.append(pts[j] - wd * side(hs[j]))
                    band.1.append(pts[j] + wd * side(hs[j]) + 0.01 * E.dir(hs[j]))
                }
                covers.append(band.0 + band.1.reversed())
            }
        }
        // The calyx's disc: its mouth off centre, the ambulacral grooves out to each pair, and the anal cone.
        let disc = E.circle(c, 0.036, 30), mouth = c + P(-0.008, 0.005)
        for k in 0..<5 {
            let h = a0 + 2 * .pi * Double(k) / 5
            sheet.draw(E.curve(mouth, mouth + 0.016 * E.dir(h + 0.3), c + 0.034 * E.dir(h), 6), E.fine)
        }
        sheet.draw(E.circle(mouth, 0.006, 10), E.fine)
        sheet.draw(E.circle(c + 0.02 * E.dir(a0 + 0.63 + 2 * .pi * 2 / 5), 0.0065, 10), E.fine)
        sheet.draw(disc, E.medium)
        sheet.cover(disc, margin: 0.004)
        for poly in covers { sheet.cover(poly, margin: 0.004) }
        // Cirri from under the calyx, jointed, hooked at the end.
        for k in 0..<7 {
            let h = a0 + 2 * .pi * (Double(k) + 0.5) / 7 + Double.random(in: -0.15..<0.15, using: &rng)
            let len = Double.random(in: 0.07..<0.1, using: &rng), hook = Double.random(in: 1.6..<2.6, using: &rng)
            let (pts, hs) = path(c + 0.03 * E.dir(h), h, len, 30) { hook * pow($0, 2.2) }
            sheet.draw(pts, E.medium)
            for i in stride(from: 4, to: 30, by: 4) {
                sheet.draw([pts[i] - 0.004 * side(hs[i]), pts[i] + 0.004 * side(hs[i])], E.fine)
            }
        }
        sheet.cover(E.circle(c, 0.13, 40), margin: 0)
    }

    // MARK: Sand dollar

    /// A sand dollar: a flattened disc, its five petals of paired pore rows off an apical disc set forward, the
    /// lunules through the test and its felt of fine spines.
    private static func sandDollar(_ sheet: inout Sheet, _ rng: inout SplitMix64) {
        let c = P(0.6, 0.5), r = 0.17, front = -0.55
        func edge(_ t: Double) -> Double {
            1 + 0.035 * cos(t - front) - 0.05 * exp(-pow(remainder(t - front - .pi, 2 * .pi) / 0.18, 2))
        }
        let outline = (0...160).map { c + r * edge(2 * .pi * Double($0) / 160) * E.dir(2 * .pi * Double($0) / 160) }
        sheet.draw(outline, E.heavy)
        sheet.draw((0...150).map { c + 0.955 * r * edge(2 * .pi * Double($0) / 150) * E.dir(2 * .pi * Double($0) / 150) }, E.fine)
        let apex = c + 0.08 * r * E.dir(front)
        sheet.draw(E.circle(apex, 0.05 * r, 14), E.medium)
        for k in 0..<5 {
            let h = front + 2 * .pi * Double(k) / 5
            let len = r * (k == 0 ? 0.6 : (k == 2 || k == 3 ? 0.66 : 0.58)), wide = 0.23 * len
            let u = E.dir(h), v = side(h), base = apex + 0.06 * r * u
            for sign in [-1.0, 1.0] {
                // Each petal's two pore rows: an outer and inner line, closing towards its open tip, pores across.
                func at(_ t: Double, _ f: Double) -> P { base + len * t * u + sign * f * wide * sin(.pi * pow(t, 0.85)) * v }
                sheet.draw((0...30).map { at(Double($0) / 30 * 0.94, 1) }, E.fine)
                sheet.draw((0...30).map { at(Double($0) / 30 * 0.9, 0.55) }, E.fine)
                for j in 1..<12 {
                    let t = Double(j) / 12 * 0.88
                    sheet.draw([at(t, 0.62), at(t + 0.012, 0.95)], E.fine)
                }
            }
            // A lunule through each ambulacrum but the front one.
            if k > 0 { stadium(&sheet, c + 0.79 * r * E.dir(h + 0.04), h + 0.04, (k == 1 || k == 4 ? 0.16 : 0.18) * r, 0.04 * r) }
        }
        stadium(&sheet, c + 0.66 * r * E.dir(front + .pi), front + .pi, 0.26 * r, 0.045 * r)
        var spines = 0
        while spines < 120 {
            let p = c + P(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng)) * r
            guard simd_distance(p, c) < 0.92 * r else { continue }
            spines += 1
            sheet.draw([p, p + 0.004 * E.dir(Double.random(in: 0..<(2 * .pi), using: &rng))], E.fine)
        }
        sheet.cover(outline, margin: 0.012)
    }

    private static func stadium(_ sheet: inout Sheet, _ c: P, _ h: Double, _ length: Double, _ half: Double) {
        let u = E.dir(h), v = side(h)
        let top = (0...8).map { i -> P in
            let f = Double(i) / 8 * .pi
            return c + (length / 2) * u - half * cos(f) * v + half * sin(f) * u
        }
        let bottom = (0...8).map { i -> P in
            let f = Double(i) / 8 * .pi
            return c - (length / 2) * u + half * cos(f) * v - half * sin(f) * u
        }
        sheet.draw(top + bottom + [top[0]], E.medium)
    }

    // MARK: Cushion star

    /// A cushion star: a puffed pentagon with short blunt arms, beaded marginal plates, rows of tubercles down each
    /// arm, granules between and hatching where it swells away from the light.
    private static func cushionStar(_ sheet: inout Sheet, _ rng: inout SplitMix64) {
        let c = P(-0.62, 0.11), R = 0.205, a0 = 0.45
        let arms = (0..<5).map { k in
            (a0 + 2 * .pi * Double(k) / 5 + Double.random(in: -0.1..<0.1, using: &rng), Double.random(in: 0.3..<0.42, using: &rng))
        }
        func radius(_ t: Double) -> Double {
            0.64 * R + R * arms.reduce(0) { $0 + $1.1 * exp(-pow(remainder(t - $1.0, 2 * .pi) / 0.36, 2)) }
        }
        let n = 200
        let outline = (0...n).map { c + radius(2 * .pi * Double($0) / Double(n)) * E.dir(2 * .pi * Double($0) / Double(n)) }
        sheet.draw(outline, E.heavy)
        // Marginal plates: a bead row just inside the edge.
        var t = 0.0
        while t < 2 * .pi - 0.02 {
            let rr = radius(t)
            sheet.draw(E.circle(c + (rr - 0.013) * E.dir(t), 0.0068, 10), E.fine)
            t += 0.0165 / rr
        }
        // Tubercles down each arm's midline.
        var placed: [P] = []
        for (h, _) in arms {
            var d = 0.03
            while d < radius(h) - 0.035 {
                let p = c + d * E.dir(h + 0.05 * sin(d * 40))
                placed.append(p)
                sheet.draw(E.circle(p, 0.0075, 12), E.fine)
                sheet.draw(E.circle(p, 0.0025, 6), E.fine)
                d += 0.023
            }
        }
        // Granules over the rest, kept apart, and the madreporite.
        for _ in 0..<1500 {
            let a = Double.random(in: 0..<(2 * .pi), using: &rng), d = sqrt(Double.random(in: 0..<1, using: &rng)) * (radius(a) - 0.03)
            let p = c + d * E.dir(a)
            guard !placed.contains(where: { simd_distance($0, p) < 0.019 }) else { continue }
            placed.append(p)
            sheet.draw(E.circle(p, Double.random(in: 0.0035..<0.0055, using: &rng), 8), E.fine)
        }
        sheet.draw(E.circle(c + 0.25 * R * E.dir(arms[3].0 + 0.6), 0.013, 16), E.medium)
        // Shade where the body falls away from a light at the upper left.
        let light = simd_normalize(P(-0.6, -0.8))
        var s = 0.0
        while s < 2 * .pi {
            let p = c + radius(s) * E.dir(s), q = c + radius(s + 0.01) * E.dir(s + 0.01)
            let along = simd_normalize(q - p), inward = P(-along.y, along.x)
            let dark = simd_dot(inward, light)
            if dark > 0.2 {
                let len = 0.045 * dark * .random(in: 0.7..<1.1, using: &rng)
                sheet.draw([p + 0.024 * inward, p + (0.024 + len) * inward + 0.25 * len * along], E.fine)
            }
            s += 0.0095 / radius(s)
        }
        sheet.cover(outline, margin: 0.012)
    }

    // MARK: Sea cucumber

    /// A sea cucumber lying on the sand: a plump warty body bowing across the floor, blunt at both ends, its papillae
    /// in rows along the back, tube feet along its sole and a ring of branched tentacles round its mouth.
    private static func seaCucumber(_ sheet: inout Sheet, _ rng: inout SplitMix64) {
        let tail = P(-0.64, 0.52), len = 0.7
        let (pts, hs) = path(tail, 1.98, len, 160) { s in -0.5 * s + 0.3 * sin(.pi * s) * (1 - s) + 0.15 * s * s }
        let n = pts.count - 1
        func w(_ i: Int) -> Double {
            let s = Double(i) / Double(n)
            return 0.074 * pow(sin(.pi * (0.015 + 0.97 * s)), 0.3) * (1 + 0.07 * sin(2 * .pi * 1.6 * s + 0.8))
        }
        func at(_ i: Int, _ f: Double) -> P { pts[i] + f * w(i) * side(hs[i]) }
        let left = (0...n).map { at($0, -1) }, right = (0...n).map { at($0, 1) }
        func cap(_ i: Int, _ forward: Double) -> [P] {
            (0...16).map { k in
                let f = Double(k) / 16 * .pi
                return pts[i] + w(i) * (-forward * cos(f) * side(hs[i]) + forward * 0.9 * sin(f) * E.dir(hs[i]))
            }
        }
        let outline = cap(0, -1) + left + cap(n, 1) + right.reversed()
        // The crown: ten short tentacles in a ring round the mouth, each branching twice.
        let mouth = pts[n] + 0.55 * w(n) * E.dir(hs[n])
        for k in 0..<10 {
            let a = hs[n] + 2.2 * (Double(k) / 9 - 0.5) * 2 + Double.random(in: -0.08..<0.08, using: &rng)
            tentacle(&sheet, &rng, mouth + 0.012 * E.dir(a), a, Double.random(in: 0.045..<0.06, using: &rng), 2)
        }
        sheet.draw(E.circle(mouth, 0.012, 14), E.medium)
        sheet.draw(outline + [outline[0]], E.heavy)
        // The back's ambulacra: two bands along the body, warts set in rows down them and scattered between.
        for f in [-0.42, 0.4] {
            sheet.draw((6...(n - 6)).map { at($0, f + 0.06 * sin(Double($0) * 0.05)) }, E.fine)
        }
        var i = 10
        while i < n - 8 {
            for f in [-0.42, 0.4] where rng.below(5) != 0 {
                let p = at(i, f + Double.random(in: -0.12..<0.12, using: &rng)), rr = Double.random(in: 0.0065..<0.011, using: &rng)
                sheet.draw(E.circle(p, rr, 14), E.fine)
                sheet.draw(E.circle(p + 0.3 * rr * E.dir(hs[i] - 0.6), 0.35 * rr, 8), E.fine)
            }
            if rng.below(2) == 0 {
                sheet.draw(E.circle(at(i + 3, Double.random(in: -0.15..<0.15, using: &rng)), Double.random(in: 0.004..<0.007, using: &rng), 10), E.fine)
            }
            i += Int.random(in: 6...9, using: &rng)
        }
        // Tube feet in rows along both edges of the sole.
        for (edge, sign) in [(left, -1.0), (right, 1.0)] {
            var j = 8
            while j < n - 6 {
                foot(&sheet, edge[j], hs[j] + sign * .pi / 2, Double.random(in: 0.012..<0.019, using: &rng),
                     lean: Double.random(in: -0.4..<0.4, using: &rng))
                j += Int.random(in: 3...5, using: &rng)
            }
        }
        sheet.cover(outline, margin: 0.03)
    }

    private static func tentacle(_ sheet: inout Sheet, _ rng: inout SplitMix64, _ p: P, _ h: Double, _ len: Double, _ depth: Int) {
        let bend = Double.random(in: -0.5..<0.5, using: &rng)
        let (pts, hs) = path(p, h, len, 8) { bend * $0 }
        sheet.draw(pts, depth == 2 ? E.medium : E.fine)
        guard depth > 0 else { return }
        let count = depth == 2 ? 3 : 2
        for m in 0..<count {
            let spread = count == 3 ? Double(m - 1) * 0.6 : (m == 0 ? -0.45 : 0.45)
            tentacle(&sheet, &rng, pts[8], hs[8] + spread + Double.random(in: -0.15..<0.15, using: &rng),
                     len * Double.random(in: 0.45..<0.6, using: &rng), depth - 1)
        }
    }

    // MARK: The floor

    /// Cockles and a few turret shells dropped where the specimens leave room, and pebbles.
    private static func shells(_ sheet: inout Sheet, _ rng: inout SplitMix64) {
        let spots: [(P, Double, Double, Bool)] = [(P(-0.02, -0.72), 0.045, 0.4, true), (P(-0.6, -0.58), 0.035, 2.1, false),
                                                  (P(0.82, -0.08), 0.04, -0.7, true), (P(-0.12, 0.42), 0.03, 1.2, true),
                                                  (P(0.38, 0.84), 0.04, 2.3, false), (P(-0.88, -0.12), 0.03, 3.6, true),
                                                  (P(0.05, -0.2), 0.026, -1.9, false)]
        for (p, size, h, cockle) in spots {
            if cockle {
                // A cockle: its fan of ribs out from the hinge, and two growth lines across them.
                let hinge = p - 0.8 * size * E.dir(h)
                func rim(_ t: Double, _ g: Double = 1) -> P { hinge + g * size * (1.55 - 0.25 * t * t) * E.dir(h + t) }
                let outline = (0...40).map { rim(-1.2 + 2.4 * Double($0) / 40) }
                sheet.draw([hinge] + outline + [hinge], E.medium)
                for k in 1..<11 {
                    let t = -1.2 + 2.4 * Double(k) / 11
                    sheet.draw(E.curve(hinge + 0.1 * size * E.dir(h + t), hinge + 0.8 * size * E.dir(h + 0.8 * t), rim(t, 0.96), 8), E.fine)
                }
                for g in [0.45, 0.8] {
                    sheet.draw((0...20).map { rim(-1.1 + 2.2 * Double($0) / 20, g) }, E.fine)
                }
                sheet.cover(outline + [hinge], margin: 0.012)
            } else {
                // A turret shell: whorls stacked to its spire, and its aperture.
                let u = E.dir(h), v = side(h), long = 3.2 * size
                func half(_ t: Double) -> Double { size * 0.45 * (1 - t) * (0.72 + 0.28 * sin(.pi * (7 * t).truncatingRemainder(dividingBy: 1))) }
                func edge(_ sign: Double) -> [P] {
                    (0...70).map { p + (Double($0) / 70 - 0.4) * long * u + sign * half(Double($0) / 70) * v }
                }
                sheet.draw(ring(p - 0.32 * long * u + 0.05 * size * v, 0.3 * size, 0.7, h), E.medium)
                for k in 1..<7 {
                    let t = Double(k) / 7, a = p + (t - 0.4) * long * u
                    sheet.draw(E.curve(a - half(t) * v, a - 0.03 * long * u, a + half(t + 0.02) * v + 0.02 * long * u, 8), E.fine)
                }
                sheet.draw(edge(-1), E.medium)
                sheet.draw(edge(1), E.medium)
                sheet.cover(edge(-1) + edge(1).reversed(), margin: 0.012)
            }
        }
        for _ in 0..<30 {
            let p = P(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng))
            guard simd_length(p) < 0.96, !sheet.covered(p, extra: 0.03) else { continue }
            let poly = ring(p, Double.random(in: 0.006..<0.016, using: &rng), Double.random(in: 0.55..<0.85, using: &rng),
                            Double.random(in: 0..<(2 * .pi), using: &rng))
            sheet.draw(poly, E.fine)
            sheet.cover(poly, margin: 0.008)
        }
    }

    /// Sand ripples across the whole floor, crests wandering and broken, under everything.
    private static func sand(_ sheet: inout Sheet, _ rng: inout SplitMix64) {
        let tilt = 0.21, u = P(cos(tilt), sin(tilt)), v = P(-sin(tilt), cos(tilt))
        var y = -1.05, k = 0
        while y < 1.05 {
            let ph = Double.random(in: 0..<(2 * .pi), using: &rng), ph2 = Double.random(in: 0..<(2 * .pi), using: &rng)
            var x = -1.1 + Double.random(in: 0..<0.2, using: &rng)
            while x < 1.1 {
                let run = Double.random(in: 0.25..<0.8, using: &rng), m = Int(run * 110)
                let pts = (0...m).map { i -> P in
                    let px = x + run * Double(i) / Double(m)
                    return px * u + (y + 0.014 * sin(7.3 * px + ph) + 0.007 * sin(17.1 * px + ph2)) * v
                }.filter { simd_length($0) < 1.01 }
                if pts.count > 1 { sheet.draw(pts, E.fine) }
                x += run + Double.random(in: 0.05..<0.18, using: &rng)
            }
            y += 0.135 + 0.02 * sin(Double(k) * 1.9)
            k += 1
        }
    }
}
