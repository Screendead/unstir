// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Prism's engravings: white polylines in tank units, y down, one plate a tray. Every channel samples the same white
/// lines, so a channel stirred apart shows as its own colour's ghost and an aligned line is white. Each plate fills the
/// glass and breaks every rotational symmetry a core could fall on (tooth counts and spokes prime to 12, no radial
/// figure left whole), so a 30° step of any core reads (`scripts/prism-plates.sh check`).
enum Engraving {
    /// A polyline and its stroke, in tank units.
    struct Line {
        var points: [SIMD2<Double>]
        var width: Double
    }

    enum Plate: String, CaseIterable {
        case fern, seeds, movement, cathedral, nautilus
    }

    static let heavy = 0.006, medium = 0.004, fine = 0.003

    static func lines(_ plate: Plate) -> [Line] {
        switch plate {
        case .fern: Fern.lines
        case .seeds: Seeds.lines
        case .movement: Movement.lines
        case .cathedral: Cathedral.lines
        case .nautilus: Nautilus.lines
        }
    }

    /// The unit vector `heading` radians clockwise from up.
    static func dir(_ heading: Double) -> SIMD2<Double> { SIMD2(sin(heading), -cos(heading)) }

    /// An arc about `c` from angle `a` to `b` (radians, from +x towards +y, so clockwise on screen), closed when whole.
    static func arc(_ c: SIMD2<Double>, _ r: Double, from a: Double = 0, to b: Double = 2 * .pi, _ n: Int? = nil) -> [SIMD2<Double>] {
        let m = n ?? max(8, Int(abs(b - a) * r * 400))
        return (0...m).map { c + r * SIMD2(cos(a + (b - a) * Double($0) / Double(m)), sin(a + (b - a) * Double($0) / Double(m))) }
    }

    static func circle(_ c: SIMD2<Double>, _ r: Double, _ n: Int) -> [SIMD2<Double>] { arc(c, r, n) }

    static func segment(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> [SIMD2<Double>] { [a, b] }

    /// Points of the quadratic from a through control c to b.
    static func curve(_ a: SIMD2<Double>, _ c: SIMD2<Double>, _ b: SIMD2<Double>, _ n: Int = 24) -> [SIMD2<Double>] {
        (0...n).map { i in
            let t = Double(i) / Double(n)
            return a * (1 - t) * (1 - t) + c * 2 * t * (1 - t) + b * t * t
        }
    }
}

/// Plate 1: fern fronds, a fiddlehead and the ground. Fronds curve and their pinnae alternate.
enum Fern {
    typealias Line = Engraving.Line
    static let rachis = Engraving.heavy, midrib = Engraving.medium, fine = Engraving.fine

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4645_524E)
        var out: [Line] = []
        frond(&out, &rng, base: SIMD2(-0.08, 1.02), heading: 0.22, length: 1.95, bend: -0.6, pinnae: 30, sori: true)
        frond(&out, &rng, base: SIMD2(-0.2, 1.02), heading: -0.7, length: 1.75, bend: 1.0, pinnae: 26, sori: false)
        frond(&out, &rng, base: SIMD2(0.12, 1.02), heading: 0.8, length: 1.6, bend: -1.05, pinnae: 24, sori: false)
        fiddlehead(&out, &rng)
        spores(&out, &rng)
        ground(&out, &rng)
        return out
    }()

    private static func dir(_ heading: Double) -> SIMD2<Double> { Engraving.dir(heading) }

    private static func frond(_ out: inout [Line], _ rng: inout SplitMix64, base: SIMD2<Double>, heading: Double,
                              length: Double, bend: Double, pinnae: Int, sori: Bool) {
        let steps = 160, ds = length / Double(steps)
        var spine = [base], headings = [heading]
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let h = heading + bend * pow(t, 1.6)
            spine.append(spine[i - 1] + ds * dir(h))
            headings.append(h)
        }
        out.append(Line(points: spine, width: rachis))
        for k in 0..<pinnae {
            let t = 0.1 + 0.86 * Double(k) / Double(pinnae)
            let i = Int(t * Double(steps)), side = k % 2 == 0 ? 1.0 : -1.0
            let size = length * 0.29 * pow(sin(.pi * min(t * 1.08, 1)), 0.75) * (1 - 0.5 * t) + 0.02
            pinna(&out, &rng, at: spine[i], heading: headings[i] + side * (1.2 - 0.45 * t), side: side, length: size,
                  sori: sori && k % 3 != 0)
        }
    }

    /// A pinna: its midrib curving towards the frond's tip, and lobed pinnules either side, alternating.
    private static func pinna(_ out: inout [Line], _ rng: inout SplitMix64, at start: SIMD2<Double>, heading: Double,
                              side: Double, length: Double, sori: Bool) {
        let n = 24
        var rib = [start], headings = [heading]
        for i in 1...n {
            let s = Double(i) / Double(n)
            let h = heading - side * 0.55 * s * s
            rib.append(rib[i - 1] + length / Double(n) * dir(h))
            headings.append(h)
        }
        out.append(Line(points: rib, width: midrib))
        let count = max(2, Int(length / 0.03))
        for j in 0..<count {
            let s = 0.12 + 0.82 * Double(j) / Double(count)
            let i = Int(s * Double(n)), lr = j % 2 == 0 ? 1.0 : -1.0
            let size = min(0.045, length * 0.2) * (1 - 0.6 * s) * .random(in: 0.85..<1.15, using: &rng)
            guard size > 0.006 else { continue }
            let h = headings[i] + lr * 0.95
            out.append(Line(points: lobe(rib[i], heading: h, length: size), width: fine))
            if sori, lr < 0, size > 0.014 {
                out.append(Line(points: circle(rib[i] + 0.55 * size * dir(h), 0.0045, 10), width: fine))
            }
        }
    }

    /// A leaf's outline from `base`: out along `heading` and back, fuller on its leading side.
    private static func lobe(_ base: SIMD2<Double>, heading: Double, length: Double) -> [SIMD2<Double>] {
        let u = dir(heading), v = SIMD2(-u.y, u.x)
        let m = 10
        let out = (0...m).map { i -> SIMD2<Double> in
            let s = Double(i) / Double(m)
            return base + length * s * u + 0.42 * length * sin(.pi * pow(s, 0.8)) * v
        }
        let back = (0..<m).reversed().map { i -> SIMD2<Double> in
            let s = Double(i) / Double(m)
            return base + length * s * u - 0.3 * length * sin(.pi * pow(s, 0.8)) * v
        }
        return out + back
    }

    private static func circle(_ c: SIMD2<Double>, _ r: Double, _ n: Int) -> [SIMD2<Double>] { Engraving.circle(c, r, n) }

    /// A crozier unrolling off a stem from the ground, scaled along its outer curl.
    private static func fiddlehead(_ out: inout [Line], _ rng: inout SplitMix64) {
        let centre = SIMD2(0.5, 0.36)
        // The curl winds in clockwise from its outer end, which the stem meets.
        let curl = (0...140).map { i -> SIMD2<Double> in
            let a = 4.2 * .pi * Double(i) / 140
            return centre + 0.15 * exp(-0.2 * a) * SIMD2(cos(a + 0.4), sin(a + 0.4))
        }
        let top = curl[0]
        var stem: [SIMD2<Double>] = []
        for i in 0...40 {
            let t = Double(i) / 40
            let p = SIMD2(0.66, 1.02) * (1 - t) * (1 - t) + SIMD2(0.78, 0.66) * 2 * t * (1 - t) + top * t * t
            stem.append(p)
        }
        out.append(Line(points: stem, width: rachis))
        out.append(Line(points: curl, width: midrib))
        for i in stride(from: 4, to: 90, by: 5) {
            let p = curl[i], d = simd_normalize(curl[i + 1] - curl[i - 1])
            let outward = simd_normalize(p - centre)
            let len = 0.03 * exp(-0.012 * Double(i)) * .random(in: 0.7..<1.2, using: &rng)
            out.append(Line(points: [p, p + len * simd_normalize(outward - 0.6 * d)], width: fine))
        }
    }

    /// Seeds drifting over the top half, each a husk trailing a bent tail.
    private static func spores(_ out: inout [Line], _ rng: inout SplitMix64) {
        var placed = 0
        while placed < 70 {
            let c = SIMD2(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<0.45, using: &rng))
            guard simd_length(c) < 0.95 else { continue }
            placed += 1
            let size = Double.random(in: 0.007..<0.016, using: &rng), a = Double.random(in: 0..<(2 * .pi), using: &rng)
            let u = SIMD2(cos(a), sin(a)), v = SIMD2(-u.y, u.x)
            out.append(Line(points: (0...12).map { i in
                let t = 2 * .pi * Double(i) / 12
                return c + size * cos(t) * u + 0.55 * size * sin(t) * v
            }, width: fine))
            let bend = Double.random(in: 0.4..<1.2, using: &rng)
            out.append(Line(points: (0...8).map { i in
                let t = Double(i) / 8
                return c - (size + 3 * size * t) * u + bend * 1.5 * size * t * t * v
            }, width: fine))
        }
    }

    /// The ground: uneven contour lines along the bottom and hatching under them.
    private static func ground(_ out: inout [Line], _ rng: inout SplitMix64) {
        for k in 0..<4 {
            let y0 = 0.8 + 0.055 * Double(k)
            out.append(Line(points: (0...60).map { i in
                let x = -1 + 2 * Double(i) / 60
                return SIMD2(x, y0 + 0.02 * sin(3.1 * x + Double(k)) + 0.012 * sin(7.3 * x - 2 * Double(k)))
            }, width: fine))
        }
        var x = -0.9
        while x < 0.9 {
            let y = 0.84 + .random(in: 0..<0.08, using: &rng)
            out.append(Line(points: [SIMD2(x, y), SIMD2(x - 0.035, y + 0.06)], width: fine))
            x += .random(in: 0.025..<0.05, using: &rng)
        }
    }
}

/// Plate 2: dandelion clocks on curving stems, half blown, their seeds adrift over toothed leaves and grass.
enum Seeds {
    typealias Line = Engraving.Line
    private typealias E = Engraving

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x5345_4544)
        var out: [Line] = []
        // (head, radius, stem foot, the blown side's heading and width): no head keeps every seed.
        let heads: [(SIMD2<Double>, Double, SIMD2<Double>, Double, Double)] = [
            (SIMD2(-0.3, -0.38), 0.3, SIMD2(-0.12, 1.02), 0.9, 1.4),
            (SIMD2(0.38, -0.08), 0.24, SIMD2(0.22, 1.02), -2.2, 1.1),
            (SIMD2(-0.62, 0.22), 0.17, SIMD2(-0.42, 1.02), 2.6, 0.9),
            (SIMD2(0.1, 0.36), 0.15, SIMD2(0.02, 1.02), -0.4, 2.2),
            (SIMD2(0.7, 0.42), 0.12, SIMD2(0.55, 1.02), 1.8, 1.0),
        ]
        for (c, r, foot, blown, gap) in heads { head(&out, &rng, c, r, foot: foot, blown: blown, gap: gap) }
        for _ in 0..<64 { drift(&out, &rng) }
        leaves(&out, &rng)
        return out
    }()

    /// A seed: its achene, a beak and the pappus's umbrella at `tip`, which points along `heading`.
    private static func seed(_ out: inout [Line], _ rng: inout SplitMix64, from base: SIMD2<Double>, heading: Double,
                             length: Double) {
        let u = E.dir(heading), v = SIMD2(-u.y, u.x)
        let achene = 0.18 * length, tip = base + length * u
        out.append(Line(points: [base - 0.004 * v, base + achene * u, base + 0.004 * v, base - 0.004 * v], width: E.fine))
        out.append(Line(points: [base + achene * u, tip], width: E.fine))
        let hairs = 5 + rng.below(3), spread = Double.random(in: 1.4..<2.0, using: &rng), size = 0.35 * length
        for k in 0..<hairs {
            let h = heading + spread * (Double(k) / Double(hairs - 1) - 0.5)
            out.append(Line(points: E.curve(tip, tip + 0.6 * size * E.dir(h), tip + size * E.dir(h) + 0.25 * size * u, 6),
                            width: E.fine))
        }
    }

    private static func head(_ out: inout [Line], _ rng: inout SplitMix64, _ c: SIMD2<Double>, _ r: Double,
                             foot: SIMD2<Double>, blown: Double, gap: Double) {
        // The stem bows towards one side and meets the receptacle from below.
        let bow = SIMD2((foot.x + c.x) / 2 + 0.35 * (c.x - foot.x) + 0.08, (foot.y + c.y) / 2)
        out.append(Line(points: E.curve(foot, bow, c + SIMD2(0, 0.02), 60), width: E.heavy))
        out.append(Line(points: E.circle(c, 0.025, 20), width: E.medium))
        // The receptacle's pits: a few dots off its centre.
        for _ in 0..<5 {
            let p = c + 0.014 * SIMD2(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng))
            out.append(Line(points: E.circle(p, 0.003, 6), width: E.fine))
        }
        let count = Int(150 * r)
        for k in 0..<count {
            let h = 2 * .pi * Double(k) / Double(count) + Double.random(in: -0.04..<0.04, using: &rng)
            var off = remainder(h - blown, 2 * .pi)
            off = abs(off)
            // The blown side: seeds gone but for stragglers, the others lifted on longer beaks.
            if off < 0.75 * gap, rng.below(6) != 0 { continue }
            let length = r * Double.random(in: 0.5..<1.05, using: &rng)
            seed(&out, &rng, from: c + 0.025 * E.dir(h), heading: h, length: length)
        }
        // The bract cup under it, sepals curled back.
        for k in 0..<7 {
            let h = .pi + 0.9 * (Double(k) / 6 - 0.5)
            let a = c + 0.025 * E.dir(h)
            out.append(Line(points: E.curve(a, a + 0.06 * E.dir(h), a + 0.05 * E.dir(h + (k < 3 ? 1.2 : -1.2)), 10),
                            width: E.fine))
        }
    }

    /// A seed loose in the air over the top of the glass.
    private static func drift(_ out: inout [Line], _ rng: inout SplitMix64) {
        var p: SIMD2<Double>
        repeat {
            p = SIMD2(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<0.6, using: &rng))
        } while simd_length(p) > 0.95
        seed(&out, &rng, from: p, heading: Double.random(in: -1.2..<1.2, using: &rng),
             length: Double.random(in: 0.08..<0.14, using: &rng))
    }

    /// Dandelion leaves, their teeth hooked back towards the root, and grass along the bottom.
    private static func leaves(_ out: inout [Line], _ rng: inout SplitMix64) {
        for (root, heading, length) in [(SIMD2(-0.1, 1.0), -1.05, 0.75), (SIMD2(0.05, 1.0), 1.15, 0.7),
                                        (SIMD2(-0.3, 1.0), -0.55, 0.5), (SIMD2(0.3, 1.0), 0.6, 0.5)] {
            let u = E.dir(heading), v = SIMD2(-u.y, u.x)
            out.append(Line(points: [root, root + length * u], width: E.medium))
            for side in [-1.0, 1.0] {
                // Each lobe swells out and ends in a tooth hooked back towards the root.
                let lobes = 5
                var edge: [SIMD2<Double>] = []
                for k in 0..<lobes {
                    let t0 = Double(k) / Double(lobes), t1 = (Double(k) + 1) / Double(lobes)
                    let w = 0.14 * length * sin(.pi * min((t0 + t1) / 2 * 1.1, 1)) + 0.015
                    edge += E.curve(root + length * t0 * u + side * 0.25 * w * v, root + length * (t0 + 0.3 * (t1 - t0)) * u + side * 1.2 * w * v,
                                    root + length * (t0 + 0.15 * (t1 - t0)) * u + side * w * v, 8)
                    edge += E.curve(root + length * (t0 + 0.15 * (t1 - t0)) * u + side * w * v, root + length * (t0 + 0.8 * (t1 - t0)) * u + side * 0.5 * w * v,
                                    root + length * t1 * u + side * 0.25 * w * v, 8).dropFirst()
                }
                edge.append(root + length * u)
                out.append(Line(points: edge, width: E.fine))
            }
        }
        var x = -0.98
        while x < 0.98 {
            let h = Double.random(in: 0.12..<0.3, using: &rng), lean = Double.random(in: -0.08..<0.08, using: &rng)
            let foot = SIMD2(x, 1.02)
            out.append(Line(points: E.curve(foot, foot + SIMD2(lean, -0.6 * h), foot + SIMD2(2.2 * lean, -h), 10), width: E.fine))
            x += Double.random(in: 0.02..<0.045, using: &rng)
        }
    }
}

/// Plate 3: a watch movement seen from the back: wheels with tooth counts and spokes prime to 12, the escape wheel and
/// pallet fork, the balance and its hairspring, bridges with their screws and jewels, over a plate of perlage.
enum Movement {
    typealias Line = Engraving.Line
    private typealias E = Engraving

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4D4F_5645)
        var out: [Line] = []
        perlage(&out)
        // (centre, tip radius, teeth, spokes, turn)
        let wheels: [(SIMD2<Double>, Double, Int, Int, Double)] = [
            (SIMD2(0.05, 0.1), 0.42, 79, 5, 0.2),
            (SIMD2(-0.55, -0.3), 0.3, 53, 5, 0.9),
            (SIMD2(-0.5, 0.52), 0.26, 43, 3, 0.4),
            (SIMD2(0.55, 0.55), 0.22, 37, 5, 1.3),
            (SIMD2(0.12, -0.62), 0.2, 31, 3, 2.1),
            (SIMD2(0.68, -0.05), 0.13, 19, 0, 0.5),
            (SIMD2(-0.15, -0.3), 0.1, 13, 0, 0.0),
        ]
        for (c, r, teeth, spokes, turn) in wheels { wheel(&out, c, r, teeth: teeth, spokes: spokes, turn: turn) }
        balance(&out, SIMD2(-0.15, 0.78) + SIMD2(0.6, -1.32), 0.0)
        escapement(&out, SIMD2(0.36, -0.3))
        bridges(&out, &rng)
        return out
    }()

    /// Overlapping circles in rows across the plate, the finish's swirls, each broken by a hatched quadrant.
    private static func perlage(_ out: inout [Line]) {
        let pitch = 0.13
        var y = -1.0, row = 0
        while y < 1.05 {
            var x = -1.0 + (row % 2 == 0 ? 0 : pitch / 2)
            while x < 1.05 {
                let c = SIMD2(x, y)
                if simd_length(c) < 1.04 {
                    out.append(Line(points: E.arc(c, 0.075, from: 0.3, to: 0.3 + 1.25 * .pi, 30), width: E.fine))
                }
                x += pitch
            }
            y += pitch * 0.87
            row += 1
        }
    }

    /// A wheel: its teeth, rim, crossings (spokes) and a hub with a slotted screw.
    private static func wheel(_ out: inout [Line], _ c: SIMD2<Double>, _ r: Double, teeth: Int, spokes: Int, turn: Double) {
        let depth = min(0.035, r * 0.12), w = 2 * .pi / Double(teeth)
        var rim: [SIMD2<Double>] = []
        for i in 0...teeth {
            let a = turn + w * Double(i)
            for (f, rr) in [(0.0, r - depth), (0.18, r - 0.3 * depth), (0.3, r), (0.5, r), (0.62, r - 0.3 * depth), (0.8, r - depth)] {
                rim.append(c + rr * SIMD2(cos(a + f * w), sin(a + f * w)))
            }
        }
        out.append(Line(points: rim, width: E.heavy))
        let inner = r - depth - 0.03
        out.append(Line(points: E.circle(c, inner, 120), width: E.heavy))
        let hub = max(0.03, r * 0.16)
        out.append(Line(points: E.circle(c, hub, 40), width: E.medium))
        for k in 0..<spokes {
            // Crossings swept a little, each a pair of curved edges.
            let a = turn + 2 * .pi * Double(k) / Double(spokes)
            for side in [-1.0, 1.0] {
                let a0 = a + side * 0.18 * 0.3 / max(hub, 0.03) * hub, a1 = a + 0.25 + side * 0.08
                let p0 = c + hub * SIMD2(cos(a0), sin(a0)), p1 = c + inner * SIMD2(cos(a1), sin(a1))
                let mid = c + 0.55 * inner * SIMD2(cos(a + 0.05), sin(a + 0.05))
                out.append(Line(points: E.curve(p0, mid + side * 0.02 * SIMD2(-sin(a), cos(a)), p1, 20), width: E.fine))
            }
        }
        if spokes == 0 {
            // A pinion's solid wheel: a ring of lightening holes, five of them.
            for k in 0..<5 {
                let a = turn + 2 * .pi * Double(k) / 5
                out.append(Line(points: E.circle(c + 0.55 * inner * SIMD2(cos(a), sin(a)), 0.18 * inner, 16), width: E.fine))
            }
        }
        screw(&out, c, hub * 0.6, turn: turn * 2.3)
    }

    private static func screw(_ out: inout [Line], _ c: SIMD2<Double>, _ r: Double, turn: Double) {
        out.append(Line(points: E.circle(c, r, 24), width: E.fine))
        let u = SIMD2(cos(turn), sin(turn)), v = SIMD2(-u.y, u.x)
        out.append(Line(points: [c - 0.85 * r * u + 0.18 * r * v, c + 0.85 * r * u + 0.18 * r * v], width: E.fine))
        out.append(Line(points: [c - 0.85 * r * u - 0.18 * r * v, c + 0.85 * r * u - 0.18 * r * v], width: E.fine))
    }

    /// The balance: a rim with timing screws, a cross arm and the hairspring's spiral from its stud.
    private static func balance(_ out: inout [Line], _ c: SIMD2<Double>, _ turn: Double) {
        let r = 0.27
        out.append(Line(points: E.circle(c, r, 160), width: E.heavy))
        out.append(Line(points: E.circle(c, r - 0.022, 160), width: E.fine))
        for k in 0..<11 {
            let a = turn + 2 * .pi * Double(k) / 11
            let p = c + (r + 0.014) * SIMD2(cos(a), sin(a))
            out.append(Line(points: E.circle(p, 0.012, 10), width: E.fine))
        }
        for a in [turn + 0.3, turn + 0.3 + .pi] {
            out.append(Line(points: [c + 0.03 * SIMD2(cos(a), sin(a)), c + (r - 0.022) * SIMD2(cos(a), sin(a))], width: E.medium))
        }
        // The spiral winds out 9 turns from the collet to the stud, off the arm's line.
        let spiral = (0...900).map { i -> SIMD2<Double> in
            let t = Double(i) / 900, a = turn + 1.1 + 2 * .pi * 9 * t
            return c + (0.035 + 0.16 * t) * SIMD2(cos(a), sin(a))
        }
        out.append(Line(points: spiral, width: E.fine))
        out.append(Line(points: E.circle(c, 0.03, 20), width: E.medium))
    }

    /// The escape wheel's hooked teeth, fifteen of them, and the pallet fork reaching across to the balance.
    private static func escapement(_ out: inout [Line], _ c: SIMD2<Double>) {
        let r = 0.15, n = 15
        var teeth: [SIMD2<Double>] = []
        for i in 0...n {
            let a = 2 * .pi * Double(i) / Double(n)
            teeth.append(c + 0.62 * r * SIMD2(cos(a), sin(a)))
            teeth.append(c + r * SIMD2(cos(a + 0.12), sin(a + 0.12)))
            teeth.append(c + 0.9 * r * SIMD2(cos(a + 0.2), sin(a + 0.2)))
            teeth.append(c + 0.62 * r * SIMD2(cos(a + 0.28), sin(a + 0.28)))
        }
        out.append(Line(points: teeth, width: E.medium))
        out.append(Line(points: E.circle(c, 0.04, 20), width: E.medium))
        let pivot = c + SIMD2(0.2, 0.12)
        out.append(Line(points: E.circle(pivot, 0.02, 14), width: E.medium))
        out.append(Line(points: [c + SIMD2(0.07, -0.13), pivot, c + SIMD2(0.16, 0.12)], width: E.medium))
        out.append(Line(points: [pivot, pivot + SIMD2(0.22, 0.12), pivot + SIMD2(0.25, 0.1)], width: E.medium))
    }

    /// Bridges over the train, each an outline with a bevel line inside, screws at its feet and jewels at its pivots.
    private static func bridges(_ out: inout [Line], _ rng: inout SplitMix64) {
        let shapes: [[SIMD2<Double>]] = [
            [SIMD2(-0.95, -0.05), SIMD2(-0.55, -0.12), SIMD2(-0.18, -0.4), SIMD2(0.12, -0.7), SIMD2(0.3, -0.85)],
            [SIMD2(-0.85, 0.55), SIMD2(-0.5, 0.45), SIMD2(0.05, 0.12), SIMD2(0.55, 0.5), SIMD2(0.85, 0.42)],
        ]
        for spine in shapes {
            for (offset, width) in [(0.06, E.medium), (0.045, E.fine)] {
                for side in [-1.0, 1.0] {
                    var edge: [SIMD2<Double>] = []
                    for i in 0..<(spine.count - 1) {
                        let a = spine[i], b = spine[i + 1], d = simd_normalize(b - a), n = SIMD2(-d.y, d.x)
                        for k in 0..<12 { edge.append(a + (b - a) * Double(k) / 12 + side * offset * n) }
                    }
                    out.append(Line(points: edge, width: width))
                }
            }
            for p in spine {
                screw(&out, p, 0.028, turn: Double.random(in: 0..<(2 * .pi), using: &rng))
                out.append(Line(points: E.circle(p, 0.04, 24), width: E.fine))
            }
        }
    }
}

/// Plate 4: a cathedral's west front in elevation: a portal of nested pointed arches, a rose window of seven lights,
/// two towers, the south one with its spire and the north one unfinished under scaffolding, over coursed stone.
enum Cathedral {
    typealias Line = Engraving.Line
    private typealias E = Engraving

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4341_5448)
        var out: [Line] = []
        courses(&out, &rng)
        nave(&out)
        tower(&out, x: -0.62, top: -0.55, spire: false)
        tower(&out, x: 0.62, top: -0.55, spire: true)
        scaffold(&out)
        sky(&out, &rng)
        return out
    }()

    /// A pointed arch over a span from x0 to x1, springing at y, its apex `rise` above.
    private static func pointed(_ x0: Double, _ x1: Double, spring y: Double, rise: Double) -> [SIMD2<Double>] {
        let mid = (x0 + x1) / 2, apex = SIMD2(mid, y - rise)
        return E.curve(SIMD2(x0, y), SIMD2(x0, y - rise * 0.7), apex, 16) + E.curve(apex, SIMD2(x1, y - rise * 0.7), SIMD2(x1, y), 16).dropFirst()
    }

    /// Coursed ashlar over the whole front: rows of blocks with staggered joints, and a hatched plinth.
    private static func courses(_ out: inout [Line], _ rng: inout SplitMix64) {
        var y = -0.3, row = 0
        while y < 1.02 {
            out.append(Line(points: [SIMD2(-1, y), SIMD2(1, y)], width: E.fine))
            var x = -1.0 + (row % 2 == 0 ? 0 : 0.035) + Double.random(in: 0..<0.02, using: &rng)
            while x < 1 {
                out.append(Line(points: [SIMD2(x, y), SIMD2(x, y + 0.045)], width: E.fine))
                x += Double.random(in: 0.06..<0.11, using: &rng)
            }
            y += 0.045
            row += 1
        }
        for k in 0..<40 {
            let x = -1 + 0.05 * Double(k)
            out.append(Line(points: [SIMD2(x, 0.92), SIMD2(x + 0.06, 1.02)], width: E.fine))
        }
    }

    /// The nave's front between the towers: the portal, a gallery of lancets and the rose under its gable.
    private static func nave(_ out: inout [Line]) {
        // The gable and the buttresses either side.
        out.append(Line(points: [SIMD2(-0.4, -0.22), SIMD2(0, -0.62), SIMD2(0.4, -0.22)], width: E.heavy))
        for x in [-0.4, 0.4] {
            out.append(Line(points: [SIMD2(x, 1.02), SIMD2(x, -0.22)], width: E.heavy))
            out.append(Line(points: [SIMD2(x - 0.04, 1.02), SIMD2(x - 0.04, -0.15)], width: E.fine))
        }
        // Five archivolts round the portal, a trumeau and its figure's niche.
        for k in 0..<5 {
            let inset = 0.035 * Double(k)
            out.append(Line(points: pointed(-0.26 + inset, 0.26 - inset, spring: 0.55, rise: 0.36 - 0.02 * Double(k)), width: k == 0 ? E.heavy : E.fine))
        }
        for x in [-0.26, 0.26, -0.12, 0.12] { out.append(Line(points: [SIMD2(x, 0.55), SIMD2(x, 0.98)], width: E.medium)) }
        out.append(Line(points: [SIMD2(0, 0.62), SIMD2(0, 0.98)], width: E.medium))
        out.append(Line(points: pointed(-0.04, 0.04, spring: 0.72, rise: 0.06) + [SIMD2(0.04, 0.9), SIMD2(-0.04, 0.9), SIMD2(-0.04, 0.72)], width: E.fine))
        // The tympanum: a mandorla, off centre to the left under the arch's apex.
        out.append(Line(points: E.curve(SIMD2(-0.05, 0.53), SIMD2(-0.16, 0.38), SIMD2(-0.05, 0.25), 20)
                        + E.curve(SIMD2(-0.05, 0.25), SIMD2(0.06, 0.38), SIMD2(-0.05, 0.53), 20), width: E.fine))
        // A gallery of seven lancets with trefoils over them.
        for k in 0..<7 {
            let x0 = -0.35 + 0.1 * Double(k)
            out.append(Line(points: pointed(x0, x0 + 0.07, spring: 0.12, rise: 0.06) + [SIMD2(x0 + 0.07, 0.17), SIMD2(x0, 0.17), SIMD2(x0, 0.12)], width: E.fine))
            out.append(Line(points: E.circle(SIMD2(x0 + 0.035, 0.035), 0.014, 12), width: E.fine))
        }
        out.append(Line(points: [SIMD2(-0.4, 0.2), SIMD2(0.4, 0.2)], width: E.medium))
        out.append(Line(points: [SIMD2(-0.4, -0.02), SIMD2(0.4, -0.02)], width: E.medium))
        rose(&out, SIMD2(0, -0.22), 0.17)
    }

    /// The rose: seven lights, each a pointed petal with a cusped circle at its head, round an oculus.
    private static func rose(_ out: inout [Line], _ c: SIMD2<Double>, _ r: Double) {
        out.append(Line(points: E.circle(c, r, 120), width: E.heavy))
        out.append(Line(points: E.circle(c, r * 0.92, 120), width: E.fine))
        out.append(Line(points: E.circle(c, r * 0.22, 40), width: E.medium))
        let n = 7
        for k in 0..<n {
            let a = -Double.pi / 2 + 0.2 + 2 * .pi * Double(k) / Double(n)
            let u = SIMD2(cos(a), sin(a)), v = SIMD2(-u.y, u.x)
            let w = 0.16 * r
            out.append(Line(points: [c + 0.22 * r * u + w * v, c + 0.9 * r * u + 0.6 * w * v], width: E.fine))
            out.append(Line(points: [c + 0.22 * r * u - w * v, c + 0.9 * r * u - 0.6 * w * v], width: E.fine))
            out.append(Line(points: E.circle(c + 0.64 * r * u, 0.14 * r, 16), width: E.fine))
            // A cusp on one side only, so each light leans the same way round.
            out.append(Line(points: E.curve(c + 0.5 * r * u + 0.13 * r * v, c + 0.58 * r * u + 0.3 * r * v, c + 0.75 * r * u + 0.13 * r * v, 8), width: E.fine))
        }
    }

    private static func tower(_ out: inout [Line], x: Double, top: Double, spire: Bool) {
        let half = 0.22
        for side in [-1.0, 1.0] { out.append(Line(points: [SIMD2(x + side * half, 1.02), SIMD2(x + side * half, top)], width: E.heavy)) }
        out.append(Line(points: [SIMD2(x - half - 0.02, top), SIMD2(x + half + 0.02, top)], width: E.heavy))
        // Stages: a string course each, a pair of lancets, and the belfry's louvres in the top one.
        for (k, y) in [0.4, -0.05, -0.32].enumerated() {
            out.append(Line(points: [SIMD2(x - half, y), SIMD2(x + half, y)], width: E.medium))
            for dx in [-0.09, 0.03] {
                let x0 = x + dx, rise = 0.12 - 0.02 * Double(k)
                let lancet = pointed(x0, x0 + 0.06, spring: y - 0.05, rise: 0.05) + [SIMD2(x0 + 0.06, y - 0.05 + rise), SIMD2(x0, y - 0.05 + rise), SIMD2(x0, y - 0.05)]
                out.append(Line(points: lancet, width: E.fine))
                if k == 2 { for j in 1..<5 { out.append(Line(points: [SIMD2(x0, y - 0.05 + 0.02 * Double(j)), SIMD2(x0 + 0.06, y - 0.03 + 0.02 * Double(j))], width: E.fine)) } }
            }
        }
        // Crenellations and the corner pinnacles.
        var crest: [SIMD2<Double>] = [SIMD2(x - half - 0.02, top)]
        for k in 0..<9 {
            let x0 = x - half - 0.02 + 0.049 * Double(k)
            crest += [SIMD2(x0, top - (k % 2 == 0 ? 0.035 : 0)), SIMD2(x0 + 0.049, top - (k % 2 == 0 ? 0.035 : 0))]
        }
        out.append(Line(points: crest, width: E.fine))
        for side in [-1.0, 1.0] {
            let px = x + side * half
            out.append(Line(points: [SIMD2(px - 0.02, top - 0.035), SIMD2(px, top - 0.14), SIMD2(px + 0.02, top - 0.035)], width: E.fine))
        }
        if spire {
            // The spire, offset nowhere: its lucarnes break the symmetry, one each side at different heights.
            let apex = SIMD2(x, -0.98)
            out.append(Line(points: [SIMD2(x - 0.16, top - 0.035), apex, SIMD2(x + 0.16, top - 0.035)], width: E.medium))
            for k in 1..<10 {
                let t = Double(k) / 10, y = top - 0.035 + (apex.y - top + 0.035) * t
                out.append(Line(points: [SIMD2(x - 0.16 * (1 - t), y), SIMD2(x + 0.16 * (1 - t), y + 0.012)], width: E.fine))
            }
            out.append(Line(points: [apex, apex + SIMD2(0, -0.04)], width: E.medium))
            out.append(Line(points: [apex + SIMD2(-0.02, -0.025), apex + SIMD2(0.02, -0.025)], width: E.medium))
            for (dx, y) in [(-0.07, -0.68), (0.05, -0.8)] {
                out.append(Line(points: pointed(x + dx - 0.02, x + dx + 0.02, spring: y, rise: 0.04) + [SIMD2(x + dx + 0.02, y + 0.03), SIMD2(x + dx - 0.02, y + 0.03), SIMD2(x + dx - 0.02, y)], width: E.fine))
            }
        }
    }

    /// The north tower's unfinished top: poles, ledgers and braces, and a hoist's jib leaning out over the nave.
    private static func scaffold(_ out: inout [Line]) {
        let x = -0.62, top = -0.55
        for dx in [-0.25, -0.12, 0.0, 0.13, 0.25] { out.append(Line(points: [SIMD2(x + dx, top + 0.1), SIMD2(x + dx, top - 0.38)], width: E.fine)) }
        for k in 0..<5 {
            let y = top - 0.08 * Double(k)
            out.append(Line(points: [SIMD2(x - 0.27, y), SIMD2(x + 0.27, y)], width: E.fine))
            let (a, b) = k % 2 == 0 ? (-0.25, 0.0) : (0.0, 0.25)
            out.append(Line(points: [SIMD2(x + a, y), SIMD2(x + b, y - 0.08)], width: E.fine))
        }
        let foot = SIMD2(x + 0.25, top - 0.38)
        out.append(Line(points: [foot, foot + SIMD2(0.36, -0.12)], width: E.medium))  // the jib
        out.append(Line(points: [foot + SIMD2(0, -0.1), foot + SIMD2(0.36, -0.12)], width: E.fine))
        out.append(Line(points: [foot + SIMD2(0.34, -0.115), foot + SIMD2(0.34, 0.06)], width: E.fine))
        out.append(Line(points: [foot + SIMD2(0.31, 0.06), foot + SIMD2(0.37, 0.06), foot + SIMD2(0.37, 0.1), foot + SIMD2(0.31, 0.1), foot + SIMD2(0.31, 0.06)], width: E.fine))
    }

    /// Hatched cloud banks and a few birds over the roofs.
    private static func sky(_ out: inout [Line], _ rng: inout SplitMix64) {
        for (cx, cy, w) in [(-0.05, -0.82, 0.3), (0.25, -0.42, 0.2), (0.88, -0.32, 0.16)] {
            for k in 0..<7 {
                let y = cy + 0.022 * Double(k), half = w * sin(.pi * (Double(k) + 0.5) / 7)
                out.append(Line(points: (0...16).map { i in
                    let x = cx - half + 2 * half * Double(i) / 16
                    return SIMD2(x, y + 0.006 * sin(9 * x + Double(k)))
                }, width: E.fine))
            }
        }
        for _ in 0..<14 {
            let p = SIMD2(Double.random(in: -0.8..<0.8, using: &rng), Double.random(in: (-0.9)..<(-0.35), using: &rng))
            let s = Double.random(in: 0.015..<0.03, using: &rng)
            out.append(Line(points: E.curve(p + SIMD2(-s, 0), p + SIMD2(-0.5 * s, -0.6 * s), p, 6)
                            + E.curve(p, p + SIMD2(0.6 * s, -0.7 * s), p + SIMD2(1.2 * s, -0.1 * s), 6), width: E.fine))
        }
    }
}

/// Plate 5: a nautilus shell cut through: its chambers' septa, the siphuncle threading them and the growth lines and
/// stripes of the outer whorl, over sea grass and drifting plankton.
enum Nautilus {
    typealias Line = Engraving.Line
    private typealias E = Engraving

    static let centre = SIMD2(0.08, 0.02)
    /// The shell's spiral: radius at angle a (radians, any number of turns), growing by `growth` a turn.
    static func spiral(_ a: Double) -> Double { 0.86 * exp(0.177 * (a - 2 * .pi * 2.5)) }
    static func point(_ a: Double, _ f: Double = 1) -> SIMD2<Double> {
        centre + f * spiral(a) * SIMD2(cos(a + 0.6), sin(a + 0.6))
    }

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4E41_5554)
        var out: [Line] = []
        water(&out, &rng)
        let end = 2 * .pi * 2.5
        out.append(Line(points: (0...900).map { point(end * Double($0) / 900) }, width: E.heavy))
        // The inner wall: the previous whorl's outline traced again, finer.
        out.append(Line(points: (0...700).map { point(0.5 + (end - 2 * .pi) * Double($0) / 700, 0.94) }, width: E.fine))
        // Septa, 31 of them over the last two and a half turns, each bowed back towards the shell's centre.
        let septa = 31
        var siphuncle: [SIMD2<Double>] = []
        for k in 0..<septa {
            let a = 1.4 + (end - 2 * .pi * 0.35 - 1.4) * Double(k) / Double(septa - 1)
            let outer = point(a), inner = point(a - 2 * .pi, 1)
            let mid = (outer + inner) / 2, n = simd_normalize(outer - inner)
            let back = SIMD2(n.y, -n.x)
            out.append(Line(points: E.curve(inner, mid + 0.22 * simd_distance(outer, inner) * back, outer, 18), width: E.medium))
            siphuncle.append(mid + 0.12 * simd_distance(outer, inner) * back)
        }
        out.append(Line(points: siphuncle, width: E.fine))
        // Growth lines over the body chamber, from the inner whorl's edge to the outer.
        let body0 = end - 2 * .pi * 0.35
        for k in 1..<40 {
            let a = body0 + (end - body0) * Double(k) / 40
            out.append(Line(points: (0...16).map { i in point(a - 0.06 * sin(.pi * Double(i) / 16), 0.36 + 0.64 * Double(i) / 16) }, width: E.fine))
        }
        // The aperture's lip and the hood.
        out.append(Line(points: [point(end), point(end - 2 * .pi, 1)], width: E.heavy))
        out.append(Line(points: E.curve(point(end), point(end) + SIMD2(-0.12, 0.08), point(end - 2 * .pi) + SIMD2(0.02, 0.06), 20), width: E.medium))
        // Tentacles curling out of the aperture, eleven of them.
        let mouth = (point(end) + point(end - 2 * .pi)) / 2
        for k in 0..<11 {
            let h = 3.6 + 0.12 * Double(k) + Double.random(in: -0.05..<0.05, using: &rng)
            let len = Double.random(in: 0.12..<0.24, using: &rng)
            let a = mouth + 0.02 * Double(k - 5) * SIMD2(0.4, 1)
            out.append(Line(points: E.curve(a, a + len * E.dir(h), a + len * E.dir(h + 0.8) + SIMD2(0, 0.05), 16), width: E.fine))
        }
        return out
    }()

    /// Sea grass up from the bottom, ripple lines and plankton, each a ring with a tail.
    private static func water(_ out: inout [Line], _ rng: inout SplitMix64) {
        // A young shell drifting high on the left, its spiral the other way about.
        let young = SIMD2(-0.45, -0.62)
        out.append(Line(points: (0...300).map { i in
            let a = 2 * .pi * 2.2 * Double(i) / 300
            return young + 0.2 * exp(0.177 * (a - 2 * .pi * 2.2)) * SIMD2(cos(-a), sin(-a))
        }, width: E.medium))
        let mouth0 = 2 * .pi * 2.2, lip = 0.2 * SIMD2(cos(-mouth0), sin(-mouth0))
        out.append(Line(points: [young + lip, young + exp(-0.177 * 2 * .pi) * lip], width: E.medium))
        for k in 0..<12 {
            let a = 2 * .pi * (0.6 + 1.4 * Double(k) / 12)
            let o = 0.2 * exp(0.177 * (a - 2 * .pi * 2.2)), n = o * exp(-0.177 * 2 * .pi)
            out.append(Line(points: [young + o * SIMD2(cos(-a), sin(-a)), young + n * SIMD2(cos(-a), sin(-a))], width: E.fine))
        }
        // Columns of bubbles rising.
        for (bx, by) in [(0.55, -0.35), (0.7, -0.6), (-0.8, 0.05)] {
            var y = by
            for k in 0..<7 {
                out.append(Line(points: E.circle(SIMD2(bx + 0.02 * sin(Double(k) * 1.3), y), 0.008 + 0.003 * Double(k), 12), width: E.fine))
                y -= 0.05 + 0.01 * Double(k)
            }
        }
        var x = -0.95
        while x < 0.95 {
            let h = Double.random(in: 0.2..<0.55, using: &rng), sway = Double.random(in: -0.2..<0.2, using: &rng)
            let foot = SIMD2(x, 1.02)
            out.append(Line(points: E.curve(foot, foot + SIMD2(sway, -0.5 * h), foot + SIMD2(-0.5 * sway, -h), 20), width: E.fine))
            x += Double.random(in: 0.05..<0.11, using: &rng)
        }
        for k in 0..<9 {
            let y = -0.9 + 0.2 * Double(k)
            out.append(Line(points: (0...40).map { i in
                let px = -1 + 2 * Double(i) / 40
                return SIMD2(px, y + 0.02 * sin(5 * px + Double(k) * 1.7))
            }, width: E.fine))
        }
        for _ in 0..<140 {
            let p = SIMD2(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng))
            guard simd_length(p) < 0.97 else { continue }
            let s = Double.random(in: 0.006..<0.014, using: &rng), a = Double.random(in: 0..<(2 * .pi), using: &rng)
            out.append(Line(points: E.circle(p, s, 10), width: E.fine))
            out.append(Line(points: E.curve(p + s * SIMD2(cos(a), sin(a)), p + 2.5 * s * SIMD2(cos(a + 0.5), sin(a + 0.5)), p + 3.5 * s * SIMD2(cos(a - 0.3), sin(a - 0.3)), 6), width: E.fine))
        }
    }
}
