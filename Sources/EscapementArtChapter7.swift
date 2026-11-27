// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 7, Chronograph: problems 37 to 42's plates, drawn with `Kit`.
extension EscapementArt {
    /// A ring from radius `r0` to `r1` about `c`, as one outline.
    private static func annulus(_ c: P, _ r0: Double, _ r1: Double, from a: Double = 0, to b: Double = 2 * .pi) -> [P] {
        let outer = arc(c, r1, from: a, to: b), inner = arc(c, r0, from: b, to: a)
        return outer + inner + [outer[0]]
    }

    /// An outline symmetric about its axis, from the upper half's profile (along, across), laid from `c` toward `a`.
    private static func profile(_ half: [(Double, Double)], at c: P, toward a: Double) -> [P] {
        let upper = half.map { P($0.0, $0.1) }
        let ring = upper + upper.reversed().map { P($0.x, -$0.y) } + [upper[0]]
        return turned(ring, by: a).map { $0 + c }
    }

    /// Any outline in local coordinates, turned to `a` and moved to `c`.
    private static func placed(_ points: [(Double, Double)], at c: P, turn a: Double = 0, scale k: Double = 1) -> [P] {
        turned(points.map { P($0.0 * k, $0.1 * k) }, by: a).map { $0 + c }
    }

    /// Problem 37, Second hand, pent, clocks 0+,2+: a long counterpoised seconds hand, its needle at nine seconds and
    /// its lollipop tail across the middle, over a bone railway-track ring with twelve bold five-second wedges, in a
    /// heavy bezel; the lollipop's disc in the second ink. The middle is clear of every pent hub, and the hand lies
    /// between them.
    static func plate37() -> Plate {
        var plate = Plate()
        let o = Kit.origin, a = -0.2 * .pi
        let track = (inner: 0.66, outer: 0.925)
        let needle = profile([(-0.26, 0.021), (-0.05, 0.028), (0.09, 0.035), (0.5, 0.021), (0.8, 0.009), (0.9, 0)],
                             at: o, toward: a)
        let pop = polar(o, 0.33, a + .pi)

        Kit.ground(&plate, angle: 0.35, around: [arc(o, track.outer), arc(o, track.inner)])
        // The bezel, heavy, with its coin edge.
        Kit.mass(&plate, annulus(o, track.outer, 1.06))
        for k in 0..<120 {
            let t = Double(k) * .pi / 60
            plate.line([polar(o, 0.985, t), polar(o, 1.06, t)], medium, .bone)
        }
        plate.line(arc(o, 0.955), fine, .bone)
        // The railway track: two rails and a tie a second.
        Kit.mass(&plate, annulus(o, track.inner - 0.035, track.inner))
        plate.line(arc(o, 0.84), heavy)
        plate.line(arc(o, 0.89), heavy)
        for k in 0..<60 {
            let t = Double(k) * .pi / 30
            plate.line([polar(o, 0.84, t), polar(o, 0.89, t)], k % 5 == 0 ? heavy : medium)
        }
        // The five-second wedges, the minute's doubled.
        for k in 0..<12 {
            let t = Kit.clock(Double(k)), w = k == 0 ? 0.075 : 0.05
            let wedge = [polar(o, 0.915, t - w / 0.915), polar(o, 0.915, t + w / 0.915), polar(o, 0.69, t),
                         polar(o, 0.915, t - w / 0.915)]
            Kit.mass(&plate, wedge)
            plate.line([polar(o, 0.88, t), polar(o, 0.76, t)], fine, .bone)
        }
        // Where the needle has swept from, dotted along the rails.
        plate.lines(dashed(arc(o, 0.78, from: a - 0.55, to: a - 0.08), on: 0.012, off: 0.018), medium)
        plate.line(Kit.barb(polar(o, 0.78, a - 0.06), toward: a + .pi / 2, size: 0.04), medium)

        // The hand, cut clear of the ground by a bone halo, then solid.
        plate.line(needle, 0.024, .bone)
        plate.line(arc(pop, 0.085), 0.024, .bone)
        Kit.mass(&plate, needle)
        plate.line([polar(o, 0.1, a), polar(o, 0.66, a)], fine, .bone)
        plate.line([polar(o, 0.1, a + .pi), polar(o, 0.24, a + .pi)], fine, .bone)
        Kit.mass(&plate, arc(pop, 0.082))
        plate.fill(arc(pop, 0.058), .second)
        plate.line(arc(pop, 0.058), fine, .bone)
        plate.line(arc(pop, 0.038), fine)
        // The arbor: a domed cap and its pin.
        Kit.mass(&plate, arc(o, 0.07))
        plate.line(arc(o, 0.05), medium, .bone)
        plate.fill(arc(o, 0.022))
        plate.line(arc(o, 0.022), medium)

        callout(&plate, "A", from: pop + P(-0.04, 0.035), to: P(-0.6, 0.12))
        callout(&plate, "B", from: polar(o, 0.865, Kit.clock(6.6)), to: polar(o, 0.6, Kit.clock(6)))
        callout(&plate, "C", from: polar(o, 0.74, Kit.clock(3)), to: P(0.42, 0.12))
        callout(&plate, "D", from: polar(o, 0.8, a), to: P(0.24, -0.38))
        return plate
    }

    /// Problem 38, Pushpiece, hex, clocks 1+,3+.
    static func plate38() -> Plate? { nil }

    /// Problem 39, Lap time, hex, clocks 1+,2+.
    static func plate39() -> Plate? { nil }

    /// Problem 40, Split second, hex, clocks 1+,3+.
    static func plate40() -> Plate? { nil }

    /// Problem 41, Flyback, hex, clocks 1+,2+.
    static func plate41() -> Plate? { nil }

    /// Problem 42, Tachymeter, hex, clocks 1+,3+.
    static func plate42() -> Plate? { nil }
}
