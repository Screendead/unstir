// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: a reef after Haeckel's corals: a sea fan's net, a sea pen, staghorn, an anemone, a brain coral's meanders
/// and an organ-pipe coral's tiers, on a sandy floor with plankton drifting above.
enum Reef {
    typealias Line = Engraving.Line
    private typealias E = Engraving
    private typealias P = SIMD2<Double>

    static let lines: [Line] = {
        // Each specimen draws from its own stream, so redrawing one leaves the others as they were.
        func rng(_ k: UInt64) -> SplitMix64 { SplitMix64(state: 0x5245_4546_0000 + k) }
        var r = (0..<8).map { rng(UInt64($0)) }
        // Front to back: each specimen hides what lies behind it.
        var out = Sheet()
        organPipe(&out, &r[0], base: P(0.27, 0.78))
        anemone(&out, &r[1], foot: P(-0.02, 0.74))
        staghorn(&out, &r[2], base: P(0.56, 0.77))
        brain(&out, &r[3], c: P(-0.47, 0.6), r: 0.28)
        seaPen(&out, &r[4], base: P(-0.54, 0.34), heading: -0.06, length: 0.94)
        floor(&out, &r[5])
        seaFan(&out, &r[6], root: P(0.16, 0.74), holdfast: P(0.19, 0.38), axis: -0.04, reach: 1.25)
        drift(&out, &r[7])
        return out.lines
    }()

    /// The lines drawn so far and the outlines of what is in front, which hide every later line passing behind them.
    private struct Sheet {
        var lines: [Line] = []
        private var cover: [(lo: P, hi: P, poly: [P])] = []

        mutating func hide(_ poly: [P]) {
            cover.append((poly.reduce(poly[0], simd_min), poly.reduce(poly[0], simd_max), poly))
        }

        func covered(_ p: P) -> Bool {
            cover.contains { c in
                guard all(p .>= c.lo), all(p .<= c.hi) else { return false }
                var odd = false, j = c.poly.count - 1
                for i in c.poly.indices {
                    let a = c.poly[i], b = c.poly[j]
                    if (a.y > p.y) != (b.y > p.y), p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { odd.toggle() }
                    j = i
                }
                return odd
            }
        }

        mutating func append(_ line: Line) {
            guard !cover.isEmpty else { lines.append(line); return }
            var run: [P] = []
            func flush() {
                if run.count > 1 { lines.append(Line(points: run, width: line.width)) }
                run = []
            }
            for (i, q) in line.points.enumerated() {
                let steps = i == 0 ? 1 : max(1, Int(simd_distance(line.points[i - 1], q) / 0.004))
                for k in 1...steps {
                    let p = i == 0 ? q : line.points[i - 1] + Double(k) / Double(steps) * (q - line.points[i - 1])
                    if covered(p) { flush() } else { run.append(p) }
                }
            }
            flush()
        }
    }

    /// A spine from `from`, its heading turning by `bend` times the square of the way along.
    private static func spine(_ from: P, _ heading: Double, _ length: Double, bend: Double, _ n: Int) -> ([P], [Double]) {
        var points = [from], headings = [heading]
        for i in 1...n {
            let s = Double(i) / Double(n), h = heading + bend * s * s
            points.append(points[i - 1] + length / Double(n) * E.dir(h))
            headings.append(h)
        }
        return (points, headings)
    }


    /// A gorgonian: a trunk fanning out in forks, each fork taking half its parent's share of the fan, the twigs
    /// joined by cross-links into a net, the fan's edge scalloped.
    private static func seaFan(_ out: inout Sheet, _ rng: inout SplitMix64, root: P, holdfast: P, axis: Double, reach: Double) {
        let spacing = 0.034
        func edge(_ a: Double) -> Double { reach * (1 - 0.22 * a * a) + 0.03 * sin(7 * a + 1) }
        var twigs: [[P]] = []
        func grow(_ from: P, _ lo: Double, _ hi: Double, _ depth: Int) {
            let d = from - holdfast, r0 = simd_length(d)
            let a0 = atan2(d.x, -d.y) - axis, a = (lo + hi) / 2 + Double.random(in: -0.15..<0.15, using: &rng) * (hi - lo)
            let r1 = min(edge(a), max(r0 + 0.05, 2.2 * spacing / (hi - lo)) * Double.random(in: 0.9..<1.15, using: &rng))
            let wiggle = Double.random(in: 0..<(2 * .pi), using: &rng)
            let n = max(4, Int((r1 - r0) / 0.006))
            let points = (0...n).map { i -> P in
                let s = Double(i) / Double(n), rr = r0 + (r1 - r0) * s
                let ease = min(1, (rr - r0) / min(0.06, r1 - r0))
                let ang = a0 + (a - a0) * ease * ease * (3 - 2 * ease) + 0.006 * sin(26 * rr + wiggle) / max(rr, 0.1)
                return holdfast + rr * E.dir(ang + axis)
            }
            out.append(Line(points: points, width: depth < 2 ? E.medium : E.fine))
            if depth >= 1 { twigs.append(points) }
            // Polyps budding along the outer twigs, alternately either side.
            if depth >= 3 {
                var i = Int.random(in: 2..<6, using: &rng), side = 1.0
                while i < points.count - 1 {
                    let t = simd_normalize(points[i + 1] - points[i - 1]), nrm = side * P(-t.y, t.x)
                    out.append(Line(points: E.circle(points[i] + 0.007 * nrm, 0.0035, 8), width: E.fine))
                    i += Int.random(in: 4..<8, using: &rng)
                    side = -side
                }
            }
            guard r1 < edge(a) - 0.01 else { return }
            let mid = lo + (hi - lo) * Double.random(in: 0.4..<0.6, using: &rng)
            grow(points.last!, lo, mid, depth + 1)
            grow(points.last!, mid, hi, depth + 1)
        }
        // The stem down to the sand behind the front specimens, and the holdfast's roots spreading over it.
        out.append(Line(points: E.curve(root, (root + holdfast) / 2 + P(0.03, 0), holdfast, 30), width: E.heavy))
        for h in [3.6, 4.3, 2.0, 2.6] {
            out.append(Line(points: E.curve(root, root + 0.04 * E.dir(h), root + 0.08 * E.dir(h + (h > 3 ? 0.5 : -0.5)) + P(0, 0.02), 10), width: E.medium))
        }
        let trunk = (0...20).map { holdfast + 0.1 * Double($0) / 20 * E.dir(axis + 0.15 * sin(Double($0) / 7)) }
        out.append(Line(points: trunk, width: E.heavy))
        grow(trunk.last!, -1.05, 0.9, 0)
        // Cross-links: from points along each twig to the nearest point of another close by.
        for (i, twig) in twigs.enumerated() {
            var k = Int.random(in: 1..<6, using: &rng)
            while k < twig.count {
                let p = twig[k]
                k += Int.random(in: 6..<11, using: &rng)
                var best: P?, bestD = 0.05
                for (j, other) in twigs.enumerated() where j > i {
                    for q in other {
                        let d = simd_distance(p, q)
                        if d < bestD, d > 0.008 { bestD = d; best = q }
                    }
                }
                guard let q = best else { continue }
                let jog = P(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng))
                out.append(Line(points: E.curve(p, (p + q) / 2 + 0.25 * bestD * jog, q, 6), width: E.fine))
            }
        }
    }


    /// A sea pen rising from behind the brain coral: a stalk, then leaves of polyps either side, curving towards the tip.
    private static func seaPen(_ out: inout Sheet, _ rng: inout SplitMix64, base: P, heading: Double, length: Double) {
        let n = 120
        let (points, hs) = spine(base, heading, length, bend: -0.35, n)
        out.append(Line(points: points, width: E.heavy))
        let leaves = 17
        for k in 0..<leaves {
            let t = 0.3 + 0.66 * Double(k) / Double(leaves)
            let i = Int(t * Double(n))
            let size = 0.15 * pow(sin(.pi * min(1, (t - 0.25) / 0.78)), 0.8) + 0.02
            for side in [-1.0, 1.0] {
                leaf(&out, at: points[i], heading: hs[i] + side * 1.25, side: side,
                     length: size * Double.random(in: 0.9..<1.1, using: &rng))
            }
        }
    }

    /// A polyp leaf: a crescent bending towards the pen's tip, its outer edge fringed with polyps.
    private static func leaf(_ out: inout Sheet, at start: P, heading: Double, side: Double, length: Double) {
        let n = 14
        var top = [start], bottom = [start], edge: [(P, P)] = []
        for i in 1...n {
            let s = Double(i) / Double(n)
            let c = start + length * s * E.dir(heading - side * 0.45 * s)
            let w = 0.22 * length * sin(.pi * pow(s, 0.7)), nrm = E.dir(heading - side * 0.9 * s - side * .pi / 2)
            top.append(c + w * nrm)
            bottom.append(c - 0.4 * w * nrm)
            edge.append((c + w * nrm, nrm))
        }
        out.append(Line(points: top + bottom.reversed(), width: E.fine))
        out.hide(top + bottom.reversed())
        for (k, (p, nrm)) in edge.enumerated() where k % 3 == 1 && k < n - 1 {
            let tip = p + 0.012 * nrm
            out.append(Line(points: [p, tip], width: E.fine))
            out.append(Line(points: E.circle(tip + 0.003 * nrm, 0.003, 8), width: E.fine))
        }
    }


    /// Staghorn: antler-like branches drawn as tubes forking up from the sand, each fork behind its parent.
    private static func staghorn(_ out: inout Sheet, _ rng: inout SplitMix64, base: P) {
        func limb(_ from: P, _ heading: Double, _ length: Double, _ r0: Double, _ depth: Int) {
            let n = max(10, Int(length * 120))
            let (points, hs) = spine(from, heading, length, bend: Double.random(in: -0.35..<0.35, using: &rng), n)
            let r1 = r0 * 0.7
            tube(&out, &rng, points, hs, r0, r1)
            guard depth < 3 else { return }
            let forks: [Double] = depth == 0 ? [0.45, 0.75] : [0.6]
            for (j, f) in forks.enumerated() {
                let i = Int(f * Double(n)), side: Double = (j + depth) % 2 == 0 ? 1 : -1
                limb(points[i], hs[i] + side * Double.random(in: 0.45..<0.8, using: &rng),
                     length * Double.random(in: 0.5..<0.7, using: &rng), r0 * 0.7, depth + 1)
            }
            limb(points[n], hs[n] + Double.random(in: -0.25..<0.25, using: &rng), length * 0.55, r1, depth + 1)
        }
        limb(base, 0.08, 0.38, 0.04, 0)
        limb(base + P(0.05, 0), 0.42, 0.26, 0.034, 1)
    }

    /// A tube along a spine, tapering from r0 to r1, capped round, set with corallites; it hides the limbs behind it.
    private static func tube(_ out: inout Sheet, _ rng: inout SplitMix64, _ spine: [P], _ hs: [Double], _ r0: Double, _ r1: Double) {
        let n = spine.count - 1
        func r(_ i: Int) -> Double { r0 + (r1 - r0) * Double(i) / Double(n) }
        func nrm(_ i: Int) -> P { E.dir(hs[i] + .pi / 2) }
        out.append(Line(points: (0...n).map { spine[$0] + r($0) * nrm($0) }, width: E.medium))
        out.append(Line(points: (0...n).map { spine[$0] - r($0) * nrm($0) }, width: E.medium))
        let a = atan2(nrm(n).y, nrm(n).x)
        out.append(Line(points: E.arc(spine[n], r1, from: a, to: a - .pi, 16), width: E.medium))
        out.append(Line(points: E.circle(spine[n], 0.35 * r1, 10), width: E.fine))
        // Radial corallites standing off both flanks, angled towards the tip, and pits on the near face.
        var i = Int.random(in: 2..<5, using: &rng), side = 1.0
        while i < n - 2 {
            let t = E.dir(hs[i]), out0 = side * nrm(i), d = simd_normalize(out0 + 0.8 * t)
            let foot = spine[i] + r(i) * out0, w = 0.0045, len = 0.012
            let e = P(-d.y, d.x), ang = atan2(e.y, e.x)
            out.append(Line(points: [foot + w * e, foot + w * e + len * d] + E.arc(foot + len * d, w, from: ang, to: ang + side * .pi, 6)
                            + [foot - w * e], width: E.fine))
            i += Int.random(in: 3..<6, using: &rng)
            side = -side
        }
        for i in stride(from: 4, to: n - 2, by: 5) {
            let c = spine[i] + Double.random(in: -0.5..<0.5, using: &rng) * r(i) * nrm(i), u = E.dir(hs[i])
            out.append(Line(points: (0...8).map { k in
                let t = 2 * .pi * Double(k) / 8
                return c + 0.005 * cos(t) * u + 0.0035 * sin(t) * P(-u.y, u.x)
            }, width: E.fine))
        }
        let left = (0...n).map { spine[$0] + r($0) * nrm($0) }, right = (0...n).map { spine[$0] - r($0) * nrm($0) }
        out.hide(left + E.arc(spine[n], r1, from: a, to: a - .pi, 16) + right.reversed())
    }


    /// A brain coral's dome: the meanders are level sets of a field of waves on the sphere, so the grooves bunch
    /// towards the rim as the dome turns away.
    private static func brain(_ out: inout Sheet, _ rng: inout SplitMix64, c: P, r: Double) {
        let cut = 0.55 * r
        let waves: [(SIMD3<Double>, Double)] = (0..<11).map { _ in
            let z = Double.random(in: -1..<1, using: &rng), a = Double.random(in: 0..<(2 * .pi), using: &rng)
            let w = sqrt(1 - z * z)
            return (SIMD3(w * cos(a), w * sin(a), z), Double.random(in: 0..<(2 * .pi), using: &rng))
        }
        let freq = 2 * .pi / 0.08
        func field(_ p: P) -> Double? {
            let d = p - c
            guard simd_length(d) < r * 0.985, d.y < cut - 0.01 else { return nil }
            let q = SIMD3(d.x, d.y, sqrt(max(0, r * r - simd_length_squared(d))))
            return waves.reduce(0) { $0 + cos(freq * simd_dot($1.0, q) + $1.1) }
        }
        // Each ridge is the band where the field is near zero: its two walls drawn, and the valleys between hatched
        // with septa running away from the walls, left out near the rim where the walls crowd.
        for level in [0.75, -0.75] {
            for wall in contour(field, centre: c, half: r, level: level) {
                out.append(Line(points: wall, width: E.fine))
                for k in stride(from: 2, to: wall.count - 1, by: 5) {
                    let p = wall[k], t = simd_normalize(wall[k + 1] - wall[k - 1])
                    guard simd_distance(p, c) < 0.82 * r else { continue }
                    var n = P(-t.y, t.x)
                    guard let ahead = field(p + 0.003 * n), field(p + 0.016 * n) != nil, field(p - 0.016 * n) != nil else { continue }
                    if (ahead - level) * level < 0 { n = -n }
                    out.append(Line(points: [p + 0.002 * n, p + 0.015 * n], width: E.fine))
                }
            }
        }
        let a0 = asin(cut / r)
        out.append(Line(points: E.arc(c, r, from: a0, to: .pi - a0 - 2 * .pi, 160), width: E.heavy))
        let foot = c + P(0, cut), half = r * cos(a0)
        out.append(Line(points: (0...40).map { i in
            let x = -1.08 + 2.16 * Double(i) / 40
            return foot + P(x * half, 0.03 * (1 - x * x) + 0.005 * sin(9 * x))
        }, width: E.medium))
        out.hide(E.arc(c, r, from: a0, to: .pi - a0 - 2 * .pi, 160))
    }

    /// Marching squares over the square about `centre`, chained into polylines.
    private static func contour(_ f: (P) -> Double?, centre: P, half: Double, level: Double) -> [[P]] {
        let n = Int(half * 2 / 0.004), h = 2 * half / Double(n)
        func pt(_ i: Int, _ j: Int) -> P { centre + P(-half + Double(i) * h, -half + Double(j) * h) }
        let grid = (0...n).map { j in (0...n).map { i in f(pt(i, j)).map { $0 - level } } }
        // An edge is keyed by its lower grid corner and direction: 0 runs along x, 1 along y.
        func key(_ i: Int, _ j: Int, _ d: Int) -> Int { (j * (n + 1) + i) * 2 + d }
        var position: [Int: P] = [:], links: [Int: [Int]] = [:]
        func cross(_ i0: Int, _ j0: Int, _ i1: Int, _ j1: Int, _ d: Int) -> Int {
            let k = key(i0, j0, d)
            if position[k] == nil, let a = grid[j0][i0], let b = grid[j1][i1] {
                position[k] = pt(i0, j0) + a / (a - b) * (pt(i1, j1) - pt(i0, j0))
            }
            return k
        }
        for j in 0..<n {
            for i in 0..<n {
                guard let v0 = grid[j][i], let v1 = grid[j][i + 1], let v2 = grid[j + 1][i + 1], let v3 = grid[j + 1][i] else { continue }
                var edges: [Int] = []
                if (v0 > 0) != (v1 > 0) { edges.append(cross(i, j, i + 1, j, 0)) }
                if (v1 > 0) != (v2 > 0) { edges.append(cross(i + 1, j, i + 1, j + 1, 1)) }
                if (v3 > 0) != (v2 > 0) { edges.append(cross(i, j + 1, i + 1, j + 1, 0)) }
                if (v0 > 0) != (v3 > 0) { edges.append(cross(i, j, i, j + 1, 1)) }
                let pairs = edges.count == 2 ? [(edges[0], edges[1])] : edges.count == 4 ? [(edges[0], edges[1]), (edges[2], edges[3])] : []
                for (a, b) in pairs {
                    links[a, default: []].append(b)
                    links[b, default: []].append(a)
                }
            }
        }
        // Open chains first, from their ends, then the closed loops.
        var seen = Set<Int>(), lines: [[P]] = []
        for s in links.keys.sorted(by: { (links[$0]!.count, $0) < (links[$1]!.count, $1) }) where !seen.contains(s) {
            var chain = [s], cur = s
            seen.insert(s)
            while let next = links[cur]?.first(where: { !seen.contains($0) }) {
                seen.insert(next)
                chain.append(next)
                cur = next
            }
            if chain.count > 2, links[cur]?.contains(s) == true { chain.append(s) }
            guard chain.count > 3 else { continue }
            lines.append(chain.map { position[$0]! })
        }
        return lines
    }


    /// Organ-pipe coral: a bundle of upright tubes tied by flat platforms in tiers, a few polyps open at the mouths.
    private static func organPipe(_ out: inout Sheet, _ rng: inout SplitMix64, base: P) {
        let tubes = 9, r = 0.014, mid = Double(tubes - 1) / 2
        var xs: [Double] = [], tops: [Double] = []
        for k in 0..<tubes {
            xs.append(base.x + (Double(k) - mid) * 0.036 + Double.random(in: -0.004..<0.004, using: &rng))
            tops.append(base.y - 0.13 - 0.2 * (1 - abs(Double(k) - mid) / Double(tubes)) - Double.random(in: 0..<0.07, using: &rng))
        }
        func at(_ k: Int, _ y: Double) -> Double { xs[k] + 0.06 * (Double(k) - mid) / Double(tubes) * (base.y - y) }
        for k in 0..<tubes {
            let top = tops[k]
            for side in [-1.0, 1.0] {
                out.append(Line(points: (0...16).map { i in
                    let y = base.y - (base.y - top) * Double(i) / 16
                    return P(at(k, y) + side * r, y)
                }, width: E.medium))
            }
            out.append(Line(points: (0...16).map { i in
                let t = 2 * .pi * Double(i) / 16
                return P(at(k, top) + r * cos(t), top + 0.35 * r * sin(t))
            }, width: E.fine))
            var y = base.y - 0.02
            while y > top + 0.02 {
                out.append(Line(points: E.curve(P(at(k, y) - r, y), P(at(k, y), y + 0.008), P(at(k, y) + r, y), 6), width: E.fine))
                y -= Double.random(in: 0.045..<0.065, using: &rng)
            }
            guard k % 3 == 1 else { continue }
            // An open polyp: seven tentacles, each fringed with pinnules.
            let mouth = P(at(k, top), top)
            for t in 0..<7 {
                let h = -1.1 + 2.2 * Double(t) / 6 + Double.random(in: -0.08..<0.08, using: &rng)
                let len = Double.random(in: 0.022..<0.032, using: &rng)
                out.append(Line(points: E.curve(mouth, mouth + 0.6 * len * E.dir(h * 0.7), mouth + len * E.dir(h), 6), width: E.fine))
                for s in [0.45, 0.7, 0.9] {
                    let p = mouth + s * len * E.dir(h)
                    out.append(Line(points: [p + 0.006 * E.dir(h + 0.9), p, p + 0.006 * E.dir(h - 0.9)], width: E.fine))
                }
            }
        }
        for y in [base.y - 0.06, base.y - 0.15, base.y - 0.24] {
            for k in 0..<(tubes - 1) where tops[k] < y - 0.01 && tops[k + 1] < y - 0.01 {
                let a = at(k, y) + r, b = at(k + 1, y) - r
                out.append(Line(points: [P(a, y), P(b, y)], width: E.medium))
                out.append(Line(points: [P(a, y + 0.009), P(b, y + 0.009)], width: E.fine))
                out.hide([P(a, y), P(b, y), P(b, y + 0.009), P(a, y + 0.009)])
            }
        }
        for k in 0..<tubes {
            out.hide([P(at(k, base.y) - r, base.y), P(at(k, tops[k]) - r, tops[k]), P(at(k, tops[k]) + r, tops[k]),
                      P(at(k, base.y) + r, base.y)])
        }
    }


    /// A sea anemone: a ribbed column on its foot, the oral disc tilted to the viewer and two rings of tentacles
    /// curling out from it, the near ones in front of the disc and the far ones behind.
    private static func anemone(_ out: inout Sheet, _ rng: inout SplitMix64, foot: P) {
        let height = 0.2, w = 0.075, disc = foot - P(0, height), dw = 0.13, tilt = 0.32
        // Each tentacle's outline, how near it is (the sine of its azimuth) and whether it is of the inner ring.
        var tentacles: [(outline: [P], near: Double, inner: Bool)] = []
        for (count, ring, reach) in [(17, 1.0, 0.23), (11, 0.58, 0.17)] {
            for k in 0..<count {
                let a = 2 * .pi * (Double(k) + Double.random(in: -0.25..<0.25, using: &rng)) / Double(count) + 0.37
                let root = disc + ring * dw * P(cos(a), tilt * sin(a))
                let len = reach * Double.random(in: 0.75..<1.1, using: &rng)
                let h0 = 1.35 * cos(a) + 0.25 * sin(a) * (cos(a) >= 0 ? 1 : -1)
                let curl = Double.random(in: 0.5..<1.1, using: &rng) * (cos(a) >= 0 ? 1 : -1)
                let m = 30, (points, hs) = spine(root, h0, len, bend: curl, m)
                let base = 0.017 * (ring == 1 ? 1 : 0.8), tip = 0.45 * base
                func half(_ i: Int) -> Double { base + (tip - base) * Double(i) / Double(m) }
                let left = (0...m).map { points[$0] + half($0) * E.dir(hs[$0] - .pi / 2) }
                let right = (0...m).map { points[$0] + half($0) * E.dir(hs[$0] + .pi / 2) }
                let a1 = atan2(E.dir(hs[m] - .pi / 2).y, E.dir(hs[m] - .pi / 2).x)
                tentacles.append((left + E.arc(points[m], tip, from: a1, to: a1 + .pi, 8) + right.reversed(), sin(a), ring < 1))
            }
        }
        tentacles.sort { $0.near > $1.near }
        func draw(_ t: (outline: [P], near: Double, inner: Bool)) {
            out.append(Line(points: t.outline, width: t.near > 0 ? E.medium : E.fine))
            out.hide(t.outline)
            // A groove down the tentacle's middle, on the near ones.
            if t.near > 0.3 {
                let m = t.outline.count
                let mid = (0..<(m / 2 - 6)).map { (t.outline[$0] + t.outline[m - 1 - $0]) / 2 }
                out.append(Line(points: Array(mid.dropFirst(3)), width: E.fine))
            }
        }
        for t in tentacles where t.near > 0 && !t.inner { draw(t) }
        for t in tentacles where t.inner { draw(t) }
        func halfWidth(_ s: Double) -> Double { w * (1.05 - 0.15 * sin(.pi * s)) + (dw - w) * pow(s, 3) }
        let rim = E.circle(.zero, dw, 60).map { disc + $0 * P(1, tilt) }
        out.append(Line(points: rim, width: E.medium))
        out.append(Line(points: E.circle(.zero, 0.024, 20).map { disc + $0 * P(1, 0.8 * tilt) }, width: E.fine))
        for k in 0..<13 {
            let a = 2 * .pi * Double(k) / 13 + 0.2
            out.append(Line(points: [disc + 0.032 * P(cos(a), tilt * sin(a)), disc + 0.07 * P(cos(a), tilt * sin(a))], width: E.fine))
        }
        out.hide(rim)
        let sides = [-1.0, 1.0].map { side in (0...30).map { i in foot + P(side * halfWidth(Double(i) / 30), -height * Double(i) / 30) } }
        for line in sides { out.append(Line(points: line, width: E.medium)) }
        out.append(Line(points: E.arc(.zero, w * 1.05, from: 0, to: .pi, 30).map { foot + $0 * P(1, 0.3) }, width: E.medium))
        for k in 1..<7 {
            let f = -1 + 2 * Double(k) / 7
            out.append(Line(points: (0...20).map { i in
                let s = Double(i) / 20
                return foot + P(f * halfWidth(s), -height * s + 0.15 * halfWidth(s) * sqrt(1 - f * f))
            }, width: E.fine))
        }
        out.hide(sides[0] + sides[1].reversed())
        for t in tentacles where t.near <= 0 && !t.inner { draw(t) }
    }


    /// The sand: wavy lines and stipple below them.
    private static func floor(_ out: inout Sheet, _ rng: inout SplitMix64) {
        for (k, y0) in [0.76, 0.82, 0.88].enumerated() {
            out.append(Line(points: (0...80).map { i in
                let x = -1 + 2 * Double(i) / 80
                return P(x, y0 + 0.012 * sin(7 * x + Double(k) * 2.1) + 0.006 * sin(17 * x + Double(k)))
            }, width: k == 0 ? E.medium : E.fine))
        }
        for _ in 0..<160 {
            let p = P(Double.random(in: -1..<1, using: &rng), Double.random(in: 0.78..<1, using: &rng))
            guard simd_length(p) < 0.97 else { continue }
            out.append(Line(points: E.circle(p, Double.random(in: 0.002..<0.005, using: &rng), 6), width: E.fine))
        }
    }

    /// Plankton drifting in the water, each a ring with a tail.
    private static func drift(_ out: inout Sheet, _ rng: inout SplitMix64) {
        for _ in 0..<60 {
            let p = P(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<0.7, using: &rng))
            guard simd_length(p) < 0.96 else { continue }
            let s = Double.random(in: 0.005..<0.012, using: &rng), a = Double.random(in: 0..<(2 * .pi), using: &rng)
            out.append(Line(points: E.circle(p, s, 10), width: E.fine))
            out.append(Line(points: E.curve(p + s * P(cos(a), sin(a)), p + 2.5 * s * P(cos(a + 0.5), sin(a + 0.5)),
                                            p + 3.5 * s * P(cos(a - 0.3), sin(a - 0.3)), 6), width: E.fine))
        }
    }
}
