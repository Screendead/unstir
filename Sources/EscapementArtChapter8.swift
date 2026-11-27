// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 8, Retrograde: problems 43 to 48's plates, drawn with `Kit`. Not drawn yet: each falls back to
/// the shared plate.
extension EscapementArt {
    /// A closed outline through the points, rounded by Catmull-Rom.
    private static func smooth(_ points: [P], steps: Int = 6) -> [P] {
        let n = points.count
        var out: [P] = []
        for i in 0..<n {
            let p0 = points[(i + n - 1) % n], p1 = points[i], p2 = points[(i + 1) % n], p3 = points[(i + 2) % n]
            for s in 0..<steps {
                let t = Double(s) / Double(steps), t2 = t * t, t3 = t2 * t
                out.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3))
            }
        }
        return out + [out[0]]
    }

    /// An open path through the points, rounded by Catmull-Rom.
    private static func smoothed(_ points: [P], steps: Int = 6) -> [P] {
        let ends = [2 * points[0] - points[1]] + points + [2 * points[points.count - 1] - points[points.count - 2]]
        var out: [P] = []
        for i in 1..<(ends.count - 2) {
            let p0 = ends[i - 1], p1 = ends[i], p2 = ends[i + 1], p3 = ends[i + 2]
            for s in 0..<steps {
                let t = Double(s) / Double(steps), t2 = t * t, t3 = t2 * t
                out.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3))
            }
        }
        return out + [points[points.count - 1]]
    }

    private static func placed(_ points: [(Double, Double)], at c: P, scale: Double = 1) -> [P] {
        points.map { c + scale * P($0.0, $0.1) }
    }

    /// A five-petalled blossom about `c`.
    private static func blossom(_ c: P, _ r: Double, turn: Double = 0) -> [P] {
        (0...100).map { i in
            let a = turn + 2 * .pi * Double(i) / 100
            return polar(c, r * (0.62 + 0.38 * abs(cos(2.5 * (a - turn)))), a)
        }
    }

    /// Problem 43, Spring forward, pent, clocks 0+,1-: a hare in mid-leap over an hour hand laid flat, a sprig of
    /// blossom at the hand's tip, a forward arrow cut in the meadow under it, and the top of the dial's chapter ring
    /// round the rim; one blossom in the second ink.
    static func plate43() -> Plate {
        var plate = Plate()
        let o = Kit.origin
        let hare = smooth(placed([
            (0.5, -0.02), (0.47, 0.02), (0.4, 0.05), (0.33, 0.08), (0.36, 0.13), (0.48, 0.2), (0.6, 0.24), (0.58, 0.28),
            (0.46, 0.255), (0.3, 0.19), (0.18, 0.16), (0.0, 0.165), (-0.16, 0.15), (-0.3, 0.22), (-0.5, 0.275),
            (-0.72, 0.3), (-0.73, 0.265), (-0.55, 0.225), (-0.43, 0.17), (-0.47, 0.11), (-0.54, 0.07), (-0.55, 0.01),
            (-0.49, -0.015), (-0.4, -0.05), (-0.24, -0.11), (-0.04, -0.125), (0.16, -0.1), (0.28, -0.08), (0.37, -0.1),
            (0.44, -0.075),
        ], at: P(0.02, -0.1), scale: 0.75), steps: 5)
        let ears = [(P(0.31, -0.085), P(0.02, -0.3), 0.05), (P(0.35, -0.095), P(0.1, -0.33), 0.055)].map { base, tip, w -> [P] in
            let d = simd_normalize(tip - base), n = P(-d.y, d.x) * w
            return smooth([base, (base * 0.55 + tip * 0.45) + n, tip, (base * 0.5 + tip * 0.5) - n * 0.6], steps: 6)
                .map { P(0.02, -0.1) + 0.75 * $0 }
        }
        let hand = Kit.hand(P(-0.82, 0.25), toward: 0, length: 1.46, width: 0.1, tail: 0.1)
        let meadow = smoothed([P(-1.1, 0.7), P(-0.6, 0.76), P(-0.25, 0.64), P(0.15, 0.62), P(0.55, 0.74), P(1.1, 0.66)])
            + [P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.7)]
        let ring = arc(o, 1.08, from: Kit.clock(9.45), to: Kit.clock(14.55)) + arc(o, 0.86, from: Kit.clock(14.55), to: Kit.clock(9.45))
            + [polar(o, 1.08, Kit.clock(9.45))]

        Kit.ground(&plate, angle: -0.42, around: [hare, hand] + ears)
        // The chapter ring over the top, its hours cut in bone.
        Kit.mass(&plate, ring)
        for k in 10...14 {
            let a = Kit.clock(Double(k))
            plate.lines(Kit.numeral(roman((k - 1) % 12 + 1), at: polar(o, 0.935, a), height: 0.085, turn: a + .pi / 2, squeeze: 0.8),
                        0.016, .bone)
        }
        for k in stride(from: 9.6, through: 14.4, by: 0.2) where abs(k - k.rounded()) > 0.01 {
            plate.line([polar(o, 0.865, Kit.clock(k)), polar(o, 0.885, Kit.clock(k))], medium, .bone)
        }

        // The meadow, its grass cut in bone and the arrow forward.
        Kit.mass(&plate, meadow)
        for k in 0..<34 {
            let x = -0.95 + Double(k) * 0.058, top = meadow.min { abs($0.x - x) < abs($1.x - x) }!.y
            let lean = 0.03 * (rnd(43, k) - 0.3)
            plate.line([P(x, top + 0.07), P(x + lean, top + 0.012)], heavy, .bone)
        }
        let shaft = Kit.band(P(-0.3, 0.83), P(0.2, 0.83), 0.06)
        plate.fill(shaft)
        plate.fill(Kit.barb(P(0.34, 0.83), toward: 0, size: 0.15))

        // The hand laid flat, its arbor bored.
        Kit.mass(&plate, hand)
        plate.fill(arc(P(-0.82, 0.25), 0.045))
        plate.line(arc(P(-0.82, 0.25), 0.045), medium)
        plate.fill(arc(P(-0.82, 0.25), 0.016), .black)
        plate.line([P(-0.7, 0.25), P(0.22, 0.25)], fine, .bone)
        // A Breguet hand's hollow moon near the tip.
        Kit.mass(&plate, arc(P(0.34, 0.25), 0.075))
        Kit.cut(&plate, arc(P(0.34, 0.25), 0.042))

        // The sprig from the hand's tip, its blossoms bone and one in the second ink.
        let twig = smoothed([P(0.62, 0.25), P(0.72, 0.19), P(0.8, 0.06), P(0.86, -0.04), P(0.93, -0.12)])
        plate.line(twig, 0.016)
        plate.line(smoothed([P(0.79, 0.09), P(0.88, 0.1), P(0.95, 0.06)]), heavy)
        for (c, r, t) in [(P(0.95, 0.05), 0.045, 0.2), (P(0.93, -0.14), 0.05, 0.6), (P(0.73, 0.15), 0.04, 1.0)] {
            plate.fill(blossom(c, r, turn: t))
            plate.line(blossom(c, r, turn: t), medium)
            plate.fill(arc(c, 0.01), .black)
        }
        let red = P(0.83, -0.01)
        plate.fill(blossom(red, 0.048, turn: 0.9), .second)
        plate.line(blossom(red, 0.048, turn: 0.9), medium)
        plate.fill(arc(red, 0.011), .black)
        for (a, b) in [(P(0.86, -0.06), P(0.79, -0.09)), (P(0.76, 0.14), P(0.68, 0.1))] {
            Kit.mass(&plate, smooth([a, (a + b) / 2 + P(0, -0.02), b, (a + b) / 2 + P(0, 0.02)], steps: 4))
        }

        // The leap's path, dotted, and the hare.
        let at = { (x: Double, y: Double) in P(0.02, -0.1) + 0.75 * P(x, y) }
        plate.lines(dashed(curve(P(-0.98, 0.17), P(-0.8, 0.05), at(-0.72, 0.25)), on: 0.03, off: 0.028), heavy)
        plate.lines(dashed(curve(at(0.6, 0.27), P(0.6, 0.1), P(0.72, 0.17)), on: 0.03, off: 0.028), heavy)
        for ear in ears { Kit.mass(&plate, ear) }
        plate.line(ears[1], medium, .bone)
        Kit.mass(&plate, hare)
        plate.fill(arc(at(0.4, -0.035), 0.016))
        plate.fill(arc(at(0.405, -0.035), 0.007), .black)
        plate.line(smoothed([at(-0.24, -0.07), at(-0.37, 0.0), at(-0.37, 0.12), at(-0.25, 0.165)]), medium, .bone)
        plate.line(smoothed([at(0.27, 0.0), at(0.3, 0.09), at(0.42, 0.18)]), medium, .bone)
        plate.line([at(0.5, -0.01), at(0.56, -0.03)], fine)
        for k in 0..<8 {
            let p = at(-0.2 + 0.06 * Double(k), -0.085 + 0.004 * Double(k))
            plate.line([p, p + P(-0.03, 0.025)], fine, .bone)
        }

        callout(&plate, "A", from: P(-0.1, -0.08), to: P(-0.3, -0.5))
        callout(&plate, "B", from: P(-0.82, 0.25), to: P(-0.72, 0.5))
        callout(&plate, "C", from: red, to: P(0.68, -0.48))
        callout(&plate, "D", from: P(0.0, 0.83), to: P(0.0, 0.55))
        return plate
    }

    /// Problem 44, Recoil, hex, clocks 1+,3-.
    static func plate44() -> Plate? { nil }

    /// Problem 45, Backlash, hex, clocks 1+,2-.
    static func plate45() -> Plate? { nil }

    /// Problem 46, Ebb tide, pent, clocks 0+,1-.
    static func plate46() -> Plate? { nil }

    /// Problem 47, Turnback, hex, clocks 1+,3-.
    static func plate47() -> Plate? { nil }

    /// Problem 48, Tide clock, hex, clocks 1+,2-.
    static func plate48() -> Plate? { nil }
}
