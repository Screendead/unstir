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
        case .cathedral: Radiolaria.lines
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

/// Plate 3: medusae after Haeckel: bells of every size seen a little from above, their radial canals and scalloped
/// margins, trailing tentacles and twisting oral arms in long lines through black water. The bells are tilted ellipses
/// with canal counts prime to 12, so no figure is whole about a core's centre.
enum Movement {
    typealias Line = Engraving.Line
    private typealias E = Engraving

    /// A bell: its margin's centre, half-width, dome height, axis heading, tilt towards the viewer, canals, tentacles,
    /// their length, oral arms and the current's pull on everything trailing.
    private struct Bell {
        var c: SIMD2<Double>, w: Double, h: Double, heading: Double, tilt: Double
        var canals: Int, tentacles: Int, length: Double, arms: Int, drift: SIMD2<Double>
    }

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4D45_4455)
        var out: [Line] = []
        let bells = [
            Bell(c: SIMD2(-0.2, -0.34), w: 0.34, h: 0.32, heading: -0.1, tilt: 0.34, canals: 17, tentacles: 24,
                 length: 1.0, arms: 4, drift: SIMD2(-0.05, 0)),
            Bell(c: SIMD2(0.52, -0.06), w: 0.19, h: 0.19, heading: 0.22, tilt: 0.4, canals: 13, tentacles: 15,
                 length: 0.75, arms: 2, drift: SIMD2(0.08, 0)),
            Bell(c: SIMD2(0.5, -0.64), w: 0.1, h: 0.1, heading: 0.3, tilt: 0.4, canals: 11, tentacles: 9,
                 length: 0.36, arms: 0, drift: SIMD2(0.04, 0)),
            Bell(c: SIMD2(-0.66, 0.34), w: 0.11, h: 0.11, heading: -0.35, tilt: 0.38, canals: 11, tentacles: 10,
                 length: 0.42, arms: 1, drift: SIMD2(-0.04, 0)),
            Bell(c: SIMD2(0.24, 0.56), w: 0.08, h: 0.08, heading: 0.15, tilt: 0.4, canals: 7, tentacles: 8,
                 length: 0.3, arms: 0, drift: SIMD2(0.03, 0)),
        ]
        for bell in bells { medusa(&out, &rng, bell) }
        // The smallest adrift, a few tentacles each.
        for (c, heading) in [(SIMD2(-0.56, -0.76), -0.5), (SIMD2(0.12, -0.86), 0.2), (SIMD2(0.86, -0.44), 0.6),
                             (SIMD2(-0.84, -0.2), -0.3), (SIMD2(0.8, 0.36), 0.35), (SIMD2(-0.26, 0.78), -0.2)] {
            let w = Double.random(in: 0.03..<0.055, using: &rng)
            medusa(&out, &rng, Bell(c: c, w: w, h: w, heading: heading, tilt: 0.4, canals: 5, tentacles: 4,
                                    length: 3.2 * w, arms: 0, drift: .zero))
        }
        return out
    }()

    /// The bell's surface at azimuth `phi` (0 to the right, front at π/2) and `t` from the apex (0) to the margin (1).
    private static func surface(_ b: Bell, _ phi: Double, _ t: Double, flare: Double = 1) -> SIMD2<Double> {
        let u = E.dir(b.heading), v = SIMD2(-u.y, u.x)
        let rho = flare * b.w * sin(t * .pi / 2), z = b.h * pow(cos(t * .pi / 2), 0.9)
        return b.c + rho * cos(phi) * v + (z * cos(b.tilt) - rho * sin(phi) * sin(b.tilt)) * u
    }

    /// The bell's outline on screen: the dome's two edges and the margin's near half.
    private static func silhouette(_ b: Bell) -> [SIMD2<Double>] {
        let left = (0...40).map { surface(b, .pi, 1 - Double($0) / 40) }
        let right = (0...40).map { surface(b, 0, Double($0) / 40) }
        let front = (0...40).map { surface(b, Double($0) / 40 * .pi, 1) }
        return left + right + front
    }

    private static func inside(_ p: SIMD2<Double>, _ poly: [SIMD2<Double>]) -> Bool {
        var odd = false
        var j = poly.count - 1
        for i in poly.indices {
            let a = poly[i], b = poly[j]
            if (a.y > p.y) != (b.y > p.y), p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { odd.toggle() }
            j = i
        }
        return odd
    }

    /// A polyline cut where it passes behind the bell.
    private static func outside(_ out: inout [Line], _ points: [SIMD2<Double>], _ hull: [SIMD2<Double>], _ width: Double) {
        var run: [SIMD2<Double>] = []
        for p in points {
            if inside(p, hull) {
                if run.count > 1 { out.append(Line(points: run, width: width)) }
                run = []
            } else {
                run.append(p)
            }
        }
        if run.count > 1 { out.append(Line(points: run, width: width)) }
    }

    private static func medusa(_ out: inout [Line], _ rng: inout SplitMix64, _ b: Bell) {
        let u = E.dir(b.heading), v = SIMD2(-u.y, u.x)
        let hull = silhouette(b)
        // The dome's edges over the apex, heavy; the margin's near half scalloped into lappets, the far half seen
        // through the bell, fine.
        out.append(Line(points: (0...80).map { i in
            let s = Double(i) / 80
            return s < 0.5 ? surface(b, .pi, 1 - 2 * s) : surface(b, 0, 2 * s - 1)
        }, width: E.heavy))
        let lappets = 2 * b.canals
        out.append(Line(points: (0...(lappets * 8)).map { i in
            let phi = Double(i) / Double(lappets * 8) * .pi
            let bump = 1 + 0.05 * abs(sin(Double(lappets) * phi / 2))
            return surface(b, phi, 1, flare: bump)
        }, width: E.medium))
        if b.w > 0.06 {
            out.append(Line(points: (0...60).map { surface(b, .pi + Double($0) / 60 * .pi, 1) }, width: E.fine))
        }
        // Radial canals on the near face, from the stomach out to the margin.
        let phase = Double.random(in: 0..<(2 * .pi), using: &rng)
        for k in 0..<b.canals {
            let phi = phase + 2 * .pi * Double(k) / Double(b.canals)
            guard sin(phi) > 0.08 else { continue }
            guard b.w > 0.15 else {
                out.append(Line(points: (0...30).map { surface(b, phi, 0.18 + 0.8 * Double($0) / 30) }, width: E.fine))
                continue
            }
            // On the larger bells each canal forks two thirds of the way out.
            let fork = 0.62, half = .pi / Double(b.canals) * 0.45
            out.append(Line(points: (0...20).map { surface(b, phi, 0.18 + (fork - 0.18) * Double($0) / 20) }, width: E.fine))
            for side in [-1.0, 1.0] {
                out.append(Line(points: (0...16).map { i in
                    let f = Double(i) / 16
                    return surface(b, phi + side * half * sin(f * .pi / 2), fork + (0.98 - fork) * f)
                }, width: E.fine))
            }
        }
        // Tentacles from all round the margin, trailing and fanning.
        for k in 0..<b.tentacles {
            let phi = 2 * .pi * (Double(k) + Double.random(in: -0.3..<0.3, using: &rng)) / Double(b.tentacles)
            let root = surface(b, phi, 1)
            let len = b.length * Double.random(in: 0.55..<1.05, using: &rng)
            let fan = 0.14 * cos(phi), amp = b.w * Double.random(in: 0.04..<0.12, using: &rng)
            let freq = Double.random(in: 1.2..<2.4, using: &rng), ph = Double.random(in: 0..<(2 * .pi), using: &rng)
            let points = (0...90).map { i -> SIMD2<Double> in
                let s = Double(i) / 90
                return root - len * s * u + fan * len * s * v + amp * s * sin(2 * .pi * freq * s + ph) * v + s * s * len * b.drift
            }
            outside(&out, points, hull, E.fine)
        }
        // Oral arms from the mouth: long ribbons twisting as they hang, so their edges cross at each half turn.
        for k in 0..<b.arms {
            let off = b.arms == 1 ? 0 : Double(k) / Double(b.arms - 1) - 0.5
            let len = 0.85 * b.length * Double.random(in: 0.85..<1.1, using: &rng)
            let ph = Double.random(in: 0..<(2 * .pi), using: &rng), half = 0.16 * b.w
            let turns = Double.random(in: 2.2..<3.2, using: &rng)
            func centre(_ s: Double) -> SIMD2<Double> {
                b.c - len * s * u + 0.45 * off * b.w * (1 + 1.2 * s) * v + 0.05 * s * sin(4 * s + ph) * v + s * s * len * b.drift
            }
            for side in [-1.0, 1.0] {
                let points = (0...200).map { i -> SIMD2<Double> in
                    let s = Double(i) / 200
                    let d = simd_normalize(centre(min(s + 0.01, 1)) - centre(max(s - 0.01, 0))), n = SIMD2(-d.y, d.x)
                    let wd = half * (1 - 0.7 * s) * sin(2 * .pi * turns * s + ph)
                    return centre(s) + side * wd * n
                }
                outside(&out, points, hull, E.medium)
            }
        }
    }
}

/// Plate 4: radiolarians after Haeckel's plates: latticed spheres haloed in fine spicules and a few long spines, and
/// latticed cones under apical horns on three feet, at many sizes, with small ones drifting in the black between.
enum Radiolaria {
    typealias Line = Engraving.Line
    private typealias E = Engraving

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x5241_4449)
        var out: [Line] = []
        // (centre, radius, spines, pore): one great sphere and three lesser.
        let spheres: [(SIMD2<Double>, Double, Int, Double)] = [
            (SIMD2(-0.24, -0.28), 0.3, 17, 0.034),
            (SIMD2(0.42, -0.36), 0.16, 13, 0.024),
            (SIMD2(-0.46, 0.4), 0.15, 11, 0.022),
            (SIMD2(0.1, 0.16), 0.085, 9, 0.015),
        ]
        for (c, r, n, pore) in spheres { sphere(&out, &rng, c, r, spines: n, pore: pore) }
        cone(&out, SIMD2(0.32, 0.12), length: 0.46, axis: 2.72, width: 0.12, rings: 3, pore: 0.015)
        cone(&out, SIMD2(-0.04, 0.5), length: 0.26, axis: 3.78, width: 0.085, rings: 3, pore: 0.011)
        // Keep-clear discs round each specimen, so the drifters leave black about them.
        let taken = spheres.map { ($0.0, $0.1 * 2) } + [(SIMD2(0.42, 0.38), 0.3), (SIMD2(0.26, 0.0), 0.1),
                                                         (SIMD2(-0.14, 0.66), 0.24), (SIMD2(0.0, 0.42), 0.12)]
        var drifters: [SIMD2<Double>] = []
        for _ in 0..<4000 where drifters.count < 20 {
            let p = SIMD2(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng))
            guard simd_length(p) < 0.93, !taken.contains(where: { simd_distance($0.0, p) < $0.1 }),
                  !drifters.contains(where: { simd_distance($0, p) < 0.2 }) else { continue }
            drifters.append(p)
            if drifters.count % 5 == 0 {
                sphere(&out, &rng, p, Double.random(in: 0.035..<0.05, using: &rng), spines: 7, pore: 0.011)
            } else {
                sphere(&out, &rng, p, Double.random(in: 0.01..<0.022, using: &rng), spines: 3, pore: 0)
            }
        }
        return out
    }()

    /// A latticed sphere: its rim and a halo of fine spicules round it, a pore for every point of a Fibonacci net on
    /// the near side (foreshortened towards the rim) and tapering spines all round. Without pores it is a drifter's
    /// plain capsule.
    private static func sphere(_ out: inout [Line], _ rng: inout SplitMix64, _ c: SIMD2<Double>, _ r: Double, spines: Int,
                               pore: Double) {
        out.append(Line(points: E.circle(c, r, max(40, Int(r * 600))), width: E.medium))
        let tilt = Double.random(in: 0..<(2 * .pi), using: &rng), golden = Double.pi * (3 - sqrt(5))
        let halo = Int(160 * r) + 10
        for k in 0..<halo {
            let a = tilt + 2 * .pi * (Double(k) + Double.random(in: -0.35..<0.35, using: &rng)) / Double(halo)
            let reach = r * (pore > 0 ? Double.random(in: 1.12..<1.55, using: &rng) : Double.random(in: 1.4..<2.4, using: &rng))
            out.append(Line(points: [c + 1.02 * r * E.dir(a), c + reach * E.dir(a)], width: E.fine))
        }
        if pore > 0 {
            out.append(Line(points: E.circle(c, 0.965 * r, max(40, Int(r * 600))), width: E.fine))
            let spacing = pore * 2.25, count = max(12, Int(4 * .pi * r * r / (spacing * spacing * 0.87)))
            for i in 0..<count {
                let y = 1 - 2 * (Double(i) + 0.5) / Double(count), w = sqrt(1 - y * y), a = golden * Double(i) + tilt
                let p = SIMD3(w * cos(a), y, w * sin(a))
                guard p.z > 0.2 else { continue }
                let at = c + r * SIMD2(p.x, p.y), flat = SIMD2(p.x, p.y)
                let u = simd_length(flat) > 1e-6 ? simd_normalize(flat) : SIMD2(1, 0), v = SIMD2(-u.y, u.x)
                let rho = pore * (0.75 + 0.25 * p.z)
                out.append(Line(points: (0...16).map { k in
                    let t = 2 * .pi * Double(k) / 16
                    return at + rho * cos(t) * v + rho * p.z * sin(t) * u
                }, width: E.fine))
            }
        }
        for i in 0..<spines {
            let y = 1 - 2 * (Double(i) + 0.5) / Double(spines), w = sqrt(1 - y * y), a = golden * Double(i) * 1.7 + tilt
            let d = SIMD3(w * cos(a), y, w * sin(a)), flat = SIMD2(d.x, d.y), len = simd_length(flat)
            guard len > 0.25 else { continue }
            let reach = r * (i % 5 == 2 ? Double.random(in: 1.15..<1.5, using: &rng) : Double.random(in: 0.5..<0.95, using: &rng))
            // Only what clears the outline shows, so no spine crosses the lattice.
            let t0 = r / len
            guard (r + reach) > t0 + 0.01 else { continue }
            let v = SIMD2(-flat.y, flat.x) / len, base = c + t0 * flat, tip = c + (r + reach) * flat
            let half = min(0.008, 0.05 * r) * (d.z >= 0 ? 1 : 0.7)
            out.append(Line(points: [base + half * v, tip, base - half * v], width: E.fine))
        }
    }

    /// A nassellarian: a domed cephalis under a long apical horn, then a bell of chambers that swell between their
    /// joints, latticed with pores, the mouth hung with three curved feet of different lengths.
    private static func cone(_ out: inout [Line], _ top: SIMD2<Double>, length: Double, axis: Double, width: Double,
                             rings: Int, pore: Double) {
        let u = E.dir(axis), v = SIMD2(-u.y, u.x), heading = atan2(u.y, u.x)
        let head = 0.3 * width, neck = 1.59 * head / length, throat = 0.81 * head
        let dome = top + head * u
        out.append(Line(points: E.arc(dome, head, from: heading + .pi - 2.2, to: heading + .pi + 2.2, 40), width: E.medium))
        var joints = [neck]
        for k in 1...rings { joints.append(neck + (1 - neck) * pow(Double(k) / Double(rings), 0.8)) }
        func radius(_ s: Double) -> Double {
            let t = (s - neck) / (1 - neck), base = throat + (width - throat) * pow(max(t, 0), 0.6)
            let j = max(0, (joints.lastIndex { $0 <= s } ?? 0)), next = j + 1 < joints.count ? joints[j + 1] : 1
            let local = next > joints[j] ? (s - joints[j]) / (next - joints[j]) : 0
            return base * (0.95 + 0.05 * sin(.pi * local))
        }
        let n = 120
        for side in [-1.0, 1.0] {
            out.append(Line(points: (0...n).map { i in
                let s = neck + (1 - neck) * Double(i) / Double(n)
                return top + length * s * u + side * radius(s) * v
            }, width: E.medium))
        }
        for s in joints {
            let r = radius(s), centre = top + length * s * u
            out.append(Line(points: (0...40).map { k in
                let a = 2 * .pi * Double(k) / 40
                return centre + r * cos(a) * v + 0.18 * r * sin(a) * u
            }, width: s == joints.last ? E.medium : E.fine))
        }
        // Pores in a quincunx over the near face, spaced evenly round the bell so they crowd towards its sides.
        var row = 0
        var s = neck + 2.2 * pore / length
        while s < 1 - 1.6 * pore / length {
            let r = radius(s), centre = top + length * s * u
            let step = 2.9 * pore / r, stagger = row % 2 == 0 ? 0.5 : 0
            var a = -Double.pi / 2 + 0.4 + step * stagger
            while a < .pi / 2 - 0.4 {
                let x = sin(a), c = centre + x * r * v + 0.18 * r * cos(a) * u
                out.append(Line(points: (0...10).map { k in
                    let t = 2 * .pi * Double(k) / 10
                    return c + pore * cos(a) * cos(t) * v + pore * sin(t) * u
                }, width: E.fine))
                a += step
            }
            s += 2.7 * pore / length
            row += 1
        }
        // The apical horn, bending a little, and the feet.
        let horn = 0.42 * length
        out.append(Line(points: E.curve(top + 0.006 * v, top - 0.5 * horn * u, top - horn * u + 0.12 * horn * v, 12)
                        + E.curve(top - horn * u + 0.12 * horn * v, top - 0.5 * horn * u + 0.004 * v, top - 0.006 * v, 12).dropFirst(), width: E.fine))
        let mouth = radius(1)
        for (x, splay, reach) in [(-0.92, -0.45, 0.36), (0.12, 0.08, 0.48), (0.9, 0.5, 0.3)] {
            let base = top + length * u + x * mouth * v + 0.18 * mouth * sqrt(1 - x * x) * u
            let tip = base + reach * length * simd_normalize(u + splay * v), bend = 0.25 * reach * length * splay * v
            out.append(Line(points: E.curve(base + 0.007 * v, (base + tip) / 2 + bend, tip, 10)
                            + E.curve(tip, (base + tip) / 2 + bend, base - 0.007 * v, 10).dropFirst(), width: E.fine))
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
