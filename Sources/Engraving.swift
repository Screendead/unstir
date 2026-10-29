// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Prism's engraving: fern fronds, a fiddlehead and the ground, as white polylines in tank units, y down. Every
/// channel samples the same white lines, so a channel stirred apart shows as its own colour's ghost and an aligned line
/// is white. Fronds curve and their pinnae alternate, so a 30° step of any core reads.
enum Fern {
    /// A polyline and its stroke, in tank units.
    struct Line {
        var points: [SIMD2<Double>]
        var width: Double
    }

    static let rachis = 0.006, midrib = 0.004, fine = 0.003

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

    /// The unit vector `heading` radians clockwise from up.
    private static func dir(_ heading: Double) -> SIMD2<Double> { SIMD2(sin(heading), -cos(heading)) }

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

    private static func circle(_ c: SIMD2<Double>, _ r: Double, _ n: Int) -> [SIMD2<Double>] {
        (0...n).map { c + r * SIMD2(cos(2 * .pi * Double($0) / Double(n)), sin(2 * .pi * Double($0) / Double(n))) }
    }

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
