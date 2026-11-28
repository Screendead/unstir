// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: feathers laid out as a cabinet's specimens: a long quill cut to a nib, an ostrich plume, a wisp of down, a
/// vane pulled open at its barbs, a flight feather and a peacock's eyespot, with loose coverts strewn between them.
enum Feathers {
    typealias Line = Engraving.Line
    private typealias E = Engraving

    /// One feather: its shaft from `base` along `heading`, bending by `bend` towards the tip, a bare calamus for the
    /// first `calamus` of its length, then barbs either side out to `left` and `right` across the vane.
    struct Spec {
        var base: SIMD2<Double>
        var heading: Double
        var length: Double
        var bend = 0.0
        var calamus = 0.18
        var left = 0.06
        var right = 0.06
        /// The barbs' angle off the shaft, towards the tip.
        var angle = 0.75
        /// How far each barb turns along its length; positive sweeps it towards the tip.
        var curl = 0.25
        var spacing = 0.011
        /// Where along the vane (0 at its foot, 1 at the tip) the barbs part, and on which side (-1 left, 1 right).
        var splits: [(Double, Double)] = []
        /// Pulled open: the splits cut the vane into clumps, each clump's barbs stuck together at their ends.
        var clumped = false
        /// The downy share of the vane at its foot.
        var fluff = 0.12
        /// Wave along each barb, for loose plumes.
        var wave = 0.0
        /// How far each barb's end sags towards the bottom of the glass, as a share of its length.
        var hang = 0.0
        /// The vane's edge drawn through the barbs' ends and round the tip.
        var edge = false
        var nib = false
    }

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4645_4154)
        var out: [Line] = []
        // Quill: long and narrow across the middle, its calamus cut to a nib.
        feather(&out, &rng, Spec(base: SIMD2(0.4, 0.3), heading: -1.7, length: 1.24, bend: 0.12, calamus: 0.2,
                                 left: 0.055, right: 0.075, angle: 0.55, curl: 0.2, spacing: 0.024,
                                 splits: [(0.45, 1), (0.74, -1)], fluff: 0.08, edge: true, nib: true))
        // Plume: an ostrich's, arching over the top with long drooping barbs.
        feather(&out, &rng, Spec(base: SIMD2(-0.68, 0.14), heading: 0.1, length: 0.98, bend: 1.4, calamus: 0.06,
                                 left: 0.28, right: 0.32, angle: 0.9, curl: -0.2, spacing: 0.036,
                                 fluff: 0.0, wave: 0.025, hang: 0.35))
        // Flight feather: stiff and curved, its leading vane narrow and the trailing one broad.
        feather(&out, &rng, Spec(base: SIMD2(-0.12, 0.92), heading: -1.0, length: 0.66, bend: 0.3, calamus: 0.15,
                                 left: 0.13, right: 0.035, angle: 0.6, curl: 0.15, spacing: 0.02,
                                 fluff: 0.1, edge: true))
        // Barbs: a body feather pulled open, its vane split into clumps nearly to the shaft.
        feather(&out, &rng, Spec(base: SIMD2(-0.06, 0.14), heading: 0.55, length: 0.7, bend: -0.25, calamus: 0.12,
                                 left: 0.15, right: 0.14, angle: 0.85, curl: 0.3, spacing: 0.018,
                                 splits: [(0.22, -1), (0.42, -1), (0.6, -1), (0.8, -1), (0.32, 1), (0.54, 1), (0.74, 1)],
                                 clumped: true, fluff: 0.15))
        eyespot(&out, &rng)
        down(&out, &rng, at: SIMD2(0.14, 0.54), size: 0.3, heading: 2.3)
        strewn(&out, &rng)
        return out
    }()

    /// The shaft's points and headings, base to tip.
    private static func shaft(_ s: Spec, steps: Int = 160) -> ([SIMD2<Double>], [Double]) {
        let ds = s.length / Double(steps)
        var points = [s.base], headings = [s.heading]
        for i in 1...steps {
            let h = s.heading + s.bend * pow(Double(i) / Double(steps), 1.4)
            points.append(points[i - 1] + ds * E.dir(h))
            headings.append(h)
        }
        return (points, headings)
    }

    /// A barb from `start`, heading off at `h`, turning by `curl` over its length, waving and sagging if asked.
    private static func barb(_ start: SIMD2<Double>, _ h: Double, length: Double, curl: Double, side: Double,
                             wave: Double = 0, phase: Double = 0, hang: Double = 0, hook: Double = 0,
                             n: Int = 10) -> [SIMD2<Double>] {
        var p = start, pts = [start]
        for i in 1...n {
            let t = Double(i) / Double(n)
            let hh = h - side * curl * t * t - side * hook * pow(t, 5)
            p += length / Double(n) * E.dir(hh)
            pts.append(p + wave * sin(phase + (hang > 0 ? 5 : 9) * t) * t * SIMD2(-E.dir(hh).y, E.dir(hh).x)
                       + SIMD2(0, hang * length * t * t))
        }
        return pts
    }

    private static func feather(_ out: inout [Line], _ rng: inout SplitMix64, _ s: Spec) {
        let steps = 160
        let (spine, headings) = shaft(s, steps: steps)
        // The rachis tapers in three lengths and stops short of the tip, which the last barbs round off.
        let thirds = [0, steps / 3, 2 * steps / 3, steps * 24 / 25]
        for k in 0..<3 {
            out.append(Line(points: Array(spine[thirds[k]...thirds[k + 1]]), width: [E.heavy, E.medium, E.fine][k]))
        }
        if s.nib { nib(&out, spine[0], heading: s.heading) }
        let vane = s.length * (1 - s.calamus)
        let count = Int(vane / s.spacing)
        var edges: [[SIMD2<Double>]] = []
        for side in [-1.0, 1.0] {
            let width = side < 0 ? s.left : s.right
            var drawn: [(v: Double, pts: [SIMD2<Double>])] = []
            for j in 0..<count {
                let v = (Double(j) + Double.random(in: 0..<0.6, using: &rng)) / Double(count)
                let t = s.calamus + (1 - s.calamus) * v
                let i = min(steps, Int(t * Double(steps)))
                // The vane swells fast from its foot and rounds off at the tip.
                let profile = pow(min(1, v / 0.12), 0.6) * sqrt(max(0.04, 1 - pow(v, 3.5)))
                var angle = s.angle * (1 - 0.6 * pow(v, 2.5))
                if v < s.fluff {
                    // Downy barbs at the foot: loose, wavy, longer and splayed.
                    let len = width * 0.9 * .random(in: 0.7..<1.2, using: &rng) / sin(angle)
                    out.append(Line(points: barb(spine[i], headings[i] + side * (angle + .random(in: 0..<0.5, using: &rng)),
                                                 length: len, curl: -0.6, side: side, wave: 0.008,
                                                 phase: .random(in: 0..<6, using: &rng)), width: E.fine))
                    continue
                }
                if !s.clumped {
                    for (at, splitSide) in s.splits where splitSide == side {
                        let d = v - at, zone = 0.09
                        if abs(d) < zone { angle += (d < 0 ? 0.5 : -0.38) * (1 - abs(d) / zone) }
                    }
                }
                // A plume's barbs are each their own: longer or shorter, curling either way, their ends hooked.
                let loose = s.hang > 0
                angle = max(angle, 0.2)
                let len = width * max(profile, 0.05) / sin(angle)
                    * (loose ? .random(in: 0.7..<1.15, using: &rng) : .random(in: 0.94..<1.04, using: &rng))
                guard len > 0.006 else { continue }
                let curl = loose ? s.curl + .random(in: -0.5..<0.5, using: &rng) : s.curl
                let pts = barb(spine[i], headings[i] + side * angle, length: len, curl: curl, side: side,
                               wave: s.wave, phase: .random(in: 0..<6, using: &rng), hang: s.hang,
                               hook: loose ? .random(in: 0.6..<1.8, using: &rng) : 0, n: loose ? 24 : 10)
                drawn.append((v, pts))
                if loose, rng.below(2) == 0 {
                    // Its end frays into a second strand.
                    let k = pts.count / 2, d = pts[k] - pts[k - 1], n = simd_normalize(SIMD2(-d.y, d.x))
                    out.append(Line(points: pts[k...].enumerated().map { m, p in p + side * 0.0003 * Double(m * m) * n },
                                    width: E.fine))
                }
            }
            if s.clumped {
                let cuts = s.splits.filter { $0.1 == side }.map(\.0).sorted()
                let groups = Dictionary(grouping: drawn) { b in cuts.firstIndex { b.v < $0 } ?? cuts.count }
                for key in groups.keys.sorted() {
                    let group = groups[key]!, tip = group[group.count / 2].pts.last!
                    for b in group {
                        let root = b.pts[0], end = b.pts.last! + 0.65 * (tip - b.pts.last!)
                        let lead = simd_normalize(b.pts[1] - root) * 0.55 * simd_distance(root, end)
                        out.append(Line(points: E.curve(root, root + lead, end, 12), width: E.fine))
                    }
                }
            } else {
                for b in drawn { out.append(Line(points: b.pts, width: E.fine)) }
            }
            edges.append(drawn.map { $0.pts.last! })
        }
        if s.edge {
            out.append(Line(points: edges[0] + [spine[steps] + 0.01 * E.dir(headings[steps])] + edges[1].reversed(),
                            width: E.fine))
        }
    }

    /// Fine ticks off a barb, alternating sides, leaning towards its end.
    private static func barbules(_ out: inout [Line], _ pts: [SIMD2<Double>], spacing: Double, length: Double,
                                 lean: Double) {
        var travelled = 0.0, next = spacing, flip = 1.0
        for k in 1..<pts.count {
            let seg = pts[k] - pts[k - 1], l = simd_length(seg)
            guard l > 0 else { continue }
            travelled += l
            while travelled >= next {
                let u = seg / l, n = SIMD2(-u.y, u.x), p = pts[k] - (travelled - next) * u
                out.append(Line(points: [p, p + length * simd_normalize(u + lean * flip * n)], width: E.fine))
                flip = -flip
                next += spacing
            }
        }
    }

    /// The calamus cut obliquely to a pen's nib, with its slit.
    private static func nib(_ out: inout [Line], _ base: SIMD2<Double>, heading: Double) {
        let u = E.dir(heading), v = SIMD2(-u.y, u.x), half = 0.012
        let tip = base - 0.06 * u + 0.004 * v
        out.append(Line(points: [base + half * v, base + 0.08 * u + half * v], width: E.fine))
        out.append(Line(points: [base - half * v, base + 0.08 * u - half * v], width: E.fine))
        out.append(Line(points: E.curve(base + half * v, base - 0.03 * u + half * v, tip, 10)
                        + E.curve(tip, base - 0.02 * u - 0.6 * half * v, base - half * v, 10).dropFirst(), width: E.medium))
        out.append(Line(points: [tip + 0.004 * u, tip + 0.035 * u], width: E.fine))
    }

    /// A peacock's train feather: sparse, loose barbs up its shaft, then the eye: barbs packed to an oval edge, its
    /// rings nested off-centre and the heart notched towards the base, so no ring is a circle about any point.
    private static func eyespot(_ out: inout [Line], _ rng: inout SplitMix64) {
        let s = Spec(base: SIMD2(0.7, 0.84), heading: -0.14, length: 1.26, bend: 0.3, calamus: 0.05)
        let steps = 200
        let (spine, headings) = shaft(s, steps: steps)
        out.append(Line(points: Array(spine[0...110]), width: E.heavy))
        out.append(Line(points: Array(spine[110...steps]), width: E.medium))
        var t = 0.08
        while t < 0.6 {
            let i = Int(t * Double(steps))
            for side in [-1.0, 1.0] {
                let len = 0.12 + 0.1 * sin(.pi * t / 0.6) + .random(in: -0.02..<0.02, using: &rng)
                let pts = barb(spine[i], headings[i] + side * .random(in: 0.5..<0.8, using: &rng), length: len,
                               curl: -0.7, side: side, wave: 0.012, phase: .random(in: 0..<6, using: &rng), n: 16)
                out.append(Line(points: pts, width: E.fine))
                barbules(&out, pts, spacing: 0.026, length: 0.026, lean: 0.35)
            }
            t += .random(in: 0.036..<0.05, using: &rng)
        }
        let ci = Int(0.8 * Double(steps)), centre = spine[ci], h = headings[ci]
        let u = E.dir(h), v = SIMD2(-u.y, u.x)
        // Rings in the eye's own frame: `a` from the tip's direction, stretched along the shaft, slid back by `slide`.
        func radius(_ r: Double, notch: Double, _ a: Double) -> Double {
            r * (1 - notch * exp(-pow(remainder(a - .pi, 2 * .pi), 2) / 0.09)) * (1 + 0.08 * cos(a))
        }
        func ring(_ r: Double, slide: Double, notch: Double, n: Int = 140) -> [SIMD2<Double>] {
            (0...n).map { k in
                let a = 2 * .pi * Double(k) / Double(n)
                return centre - slide * u + radius(r, notch: notch, a) * (1.3 * cos(a) * u + sin(a) * v)
            }
        }
        func within(_ p: SIMD2<Double>, _ r: Double, slide: Double, notch: Double) -> Bool {
            let d = p - centre + slide * u, x = simd_dot(d, u) / 1.3, y = simd_dot(d, v)
            return x * x + y * y < pow(radius(r, notch: notch, atan2(y, x)), 2)
        }
        let edge = 0.25, heart = (0.05, 0.085, 0.4)
        // Barbs off the shaft through the eye, each run out to the edge and broken where it crosses the heart.
        let first = ci - Int(1.3 * edge / s.length * Double(steps)) - 4
        for side in [-1.0, 1.0] {
            var j = Double(first)
            while Int(j) <= steps {
                let i = Int(j), f = Double(i - first) / Double(steps - first)
                var hh = headings[i] + side * (1.15 - 0.95 * f), p = spine[i]
                let reach = edge * .random(in: 0.93..<1.06, using: &rng)
                var run: [SIMD2<Double>] = [p]
                for _ in 0..<200 {
                    hh -= side * 0.0035
                    p += 0.004 * E.dir(hh)
                    guard within(p, reach, slide: 0, notch: 0) else { break }
                    if within(p, heart.0, slide: heart.1, notch: heart.2) {
                        if run.count > 1 { out.append(Line(points: run, width: E.fine)) }
                        run = []
                    } else {
                        run.append(p)
                    }
                }
                if run.count > 1 { out.append(Line(points: run, width: E.fine)) }
                j += 4.4
            }
        }
        out.append(Line(points: ring(0.18, slide: 0.02, notch: 0.05), width: E.medium))
        out.append(Line(points: ring(0.125, slide: 0.05, notch: 0.15), width: E.medium))
        out.append(Line(points: ring(0.085, slide: 0.07, notch: 0.3), width: E.fine))
        out.append(Line(points: ring(heart.0, slide: heart.1, notch: heart.2), width: E.heavy))
        // Stipple in the bronze band between the outer rings.
        for _ in 0..<50 {
            let a = Double.random(in: 0..<(2 * .pi), using: &rng), r = Double.random(in: 0.14..<0.165, using: &rng)
            let p = centre - 0.035 * u + r * (1.3 * cos(a) * u + sin(a) * v)
            out.append(Line(points: E.circle(p, 0.0035, 6), width: E.fine))
        }
    }

    /// Coverts strewn over what the specimens leave black, each kept clear of the lines drawn.
    private static func strewn(_ out: inout [Line], _ rng: inout SplitMix64) {
        let cells = 48
        var taken = [Bool](repeating: false, count: cells * cells)
        func cell(_ p: SIMD2<Double>) -> Int? {
            let i = Int((p.x + 1) / 2 * Double(cells)), j = Int((p.y + 1) / 2 * Double(cells))
            return i >= 0 && j >= 0 && i < cells && j < cells ? j * cells + i : nil
        }
        func mark(_ from: Int) { for line in out[from...] { for p in line.points { if let c = cell(p) { taken[c] = true } } } }
        func clear(_ c: SIMD2<Double>, _ r: Double) -> Bool {
            let k = Int(ceil(r / (2 / Double(cells))))
            for dj in -k...k { for di in -k...k {
                let p = c + 2 / Double(cells) * SIMD2(Double(di), Double(dj))
                if simd_distance(p, c) <= r, let i = cell(p), taken[i] { return false }
            } }
            return true
        }
        mark(0)
        var placed = 0
        for _ in 0..<6000 where placed < 12 {
            let c = SIMD2(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng))
            let size = Double.random(in: 0.08..<0.18, using: &rng)
            guard simd_length(c) < 0.97 - 0.5 * size, clear(c, 1.25 * size) else { continue }
            placed += 1
            let from = out.count, heading = Double.random(in: -1.3..<2.3, using: &rng)
            let length = 1.9 * size, w = Double.random(in: 0.28..<0.4, using: &rng) * length
            feather(&out, &rng, Spec(base: c - 0.5 * length * E.dir(heading), heading: heading, length: length,
                                     bend: .random(in: -0.4..<0.4, using: &rng), calamus: 0.15, left: w,
                                     right: w * .random(in: 0.8..<1.1, using: &rng), angle: 0.8, curl: 0.3,
                                     spacing: 0.065 * length, fluff: 0.3))
            mark(from)
        }
    }

    /// A wisp of down: a short calamus and a stub of rachis, a spray of limp barbs off it splayed unevenly, curling
    /// either way, each fraying into finer strands.
    private static func down(_ out: inout [Line], _ rng: inout SplitMix64, at base: SIMD2<Double>, size: Double, heading: Double) {
        let u = E.dir(heading)
        let stub = E.curve(base, base + 0.3 * size * u, base + 0.45 * size * E.dir(heading + 0.5), 8)
        out.append(Line(points: Array(stub[0...3]), width: E.medium))
        out.append(Line(points: Array(stub[3...]), width: E.fine))
        let n = 22
        for k in 0..<n {
            let f = Double(k) / Double(n - 1), side: Double = k % 2 == 0 ? -1 : 1
            let foot = stub[3 + Int(f * 5)]
            let h = heading + 0.4 * f + side * (1.4 - 1.0 * f) + .random(in: -0.25..<0.25, using: &rng)
            let len = size * .random(in: 0.45..<1.0, using: &rng)
            let pts = barb(foot, h, length: len, curl: .random(in: -1.4..<1.0, using: &rng), side: side,
                           wave: 0.016, phase: .random(in: 0..<6, using: &rng), n: 20)
            out.append(Line(points: pts, width: E.fine))
            for _ in 0..<2 {
                let from = Int.random(in: 4..<12, using: &rng), lean = Double.random(in: -1..<1, using: &rng)
                let d = pts[from] - pts[from - 1], normal = simd_normalize(SIMD2(-d.y, d.x))
                out.append(Line(points: pts[from...].enumerated().map { m, p in
                    p + lean * 0.0009 * size / 0.3 * Double(m * m) * normal
                }, width: E.fine))
            }
        }
    }
}
