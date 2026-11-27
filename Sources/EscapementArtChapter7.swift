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

    /// Problem 38, Pushpiece, hex, clocks 1+,3+: a chronograph's case band, a heavy ring, on its bracelet, its knurled
    /// crown at three and two pushpieces in the lanes either side, a fingertip in solid ink pressing the upper one home;
    /// the pressed pushpiece's cap in the second ink. Crown, pushpieces and finger keep clear of every hex hub.
    static func plate38() -> Plate {
        var plate = Plate()
        let o = Kit.origin, band = (inner: 0.41, outer: 0.55), push = 55.0 * .pi / 180
        let strapHalf = 0.18
        func strap(_ s: Double) -> [P] {
            let a0 = asin(strapHalf / 1.06)
            let rim = arc(o, 1.06, from: s * (.pi / 2) - a0, to: s * (.pi / 2) + a0)
            return [P(s * strapHalf, s * 0.42)] + (s > 0 ? rim : rim) + [P(-s * strapHalf, s * 0.42), P(s * strapHalf, s * 0.42)]
        }

        Kit.ground(&plate, angle: 0.6, around: [arc(o, band.outer), strap(-1), strap(1)])
        // The bracelet: solid outer links and cut centre links, row by row out to the rim.
        for s in [-1.0, 1.0] {
            plate.fill(strap(s))
            for y0 in stride(from: 0.555, to: 1.06, by: 0.105) {
                let y1 = y0 + 0.07
                for x in [-strapHalf, 0.085] {
                    Kit.mass(&plate, box(P(x, s * y0), P(x + 0.095, s * y1)))
                }
                Kit.cut(&plate, box(P(-0.06, s * (y0 + 0.004)), P(0.06, s * (y1 - 0.004))), edge: heavy)
                plate.line([P(-0.035, s * (y0 + 0.025)), P(0.035, s * (y0 + 0.025))], medium)
            }
        }

        // The pushpieces: a stem, a tube and a cap, the upper pressed home.
        for (k, s) in [-1.0, 1.0].enumerated() {
            let t = s * push, pressed = k == 0, at = pressed ? -0.045 : 0.0
            Kit.mass(&plate, Kit.band(polar(o, band.outer - 0.02, t), polar(o, 0.65 + at, t), 0.06))
            Kit.mass(&plate, Kit.band(polar(o, 0.62 + at, t), polar(o, 0.77 + at, t), 0.13))
            for d in [-0.035, 0.035] {
                let side = polar(o, d, t + .pi / 2) - o
                plate.line([polar(o, 0.645 + at, t) + side, polar(o, 0.745 + at, t) + side], 0.012, .bone)
            }
            let cap = profile([(0, 0.08), (0.04, 0.08), (0.065, 0.055), (0.072, 0)], at: polar(o, 0.77 + at, t), toward: t)
            if pressed {
                plate.fill(cap, .second)
                plate.line(cap, medium)
            } else {
                Kit.mass(&plate, cap)
            }
        }
        // The crown at three: its stem, a knurled body and a bone face.
        Kit.mass(&plate, Kit.band(P(band.outer - 0.02, 0), P(0.62, 0), 0.06))
        let crown = profile([(0, 0.11), (0.15, 0.11), (0.17, 0.095), (0.175, 0)], at: P(0.6, 0), toward: 0)
        Kit.mass(&plate, crown)
        for y in stride(from: -0.075, through: 0.076, by: 0.03) {
            plate.line([P(0.615, y), P(0.755, y)], 0.011, .bone)
        }
        plate.line([P(0.773, -0.08), P(0.773, 0.08)], medium, .bone)

        // The case band, heavy, its bevel and bezel in bone.
        Kit.mass(&plate, annulus(o, band.inner, band.outer))
        plate.line(arc(o, band.outer - 0.035), medium, .bone)
        plate.line(arc(o, band.inner + 0.03), 0.014, .bone)
        for k in 0..<60 {
            let t = Double(k) * .pi / 30 + 0.04
            plate.line([polar(o, band.outer - 0.05, t), polar(o, band.outer, t)], 0.018, .bone)
        }
        // The dial: bold batons, the hands and the chronograph's needle at its start.
        plate.fill(arc(o, band.inner))
        plate.line(arc(o, band.inner - 0.02), medium)
        for k in 0..<12 {
            let t = Kit.clock(Double(k))
            Kit.mass(&plate, Kit.band(polar(o, 0.26, t), polar(o, 0.36, t), k % 3 == 0 ? 0.05 : 0.032))
        }
        Kit.mass(&plate, Kit.hand(o, toward: Kit.clock(10.2), length: 0.24, width: 0.05, tail: 0.05))
        Kit.mass(&plate, Kit.hand(o, toward: Kit.clock(2.0), length: 0.34, width: 0.04, tail: 0.06))
        plate.line([polar(o, 0.1, Kit.clock(6)), polar(o, 0.37, Kit.clock(0))], medium)

        // The fingertip, pressing in from the rim along the lane: solid ink, its nail and creases in bone.
        let f = -push, tip = polar(o, 0.79, -push)
        let finger = placed(arc(P(0.12, 0), 0.12, from: .pi / 2, to: 1.5 * .pi).map { ($0.x, $0.y) }
                            + [(0.75, -0.14), (0.75, 0.14), (0.12, 0.12)], at: tip, turn: f)
        plate.line(finger, 0.024, .bone)
        Kit.mass(&plate, finger)
        plate.line(placed(ellipse(P(0.17, -0.07), 0.12, 0.038).map { ($0.x, $0.y) }, at: tip, turn: f), heavy, .bone)
        plate.line(placed(arc(P(0.29, -0.07), 0.04, from: 0.6 * .pi, to: 1.4 * .pi).map { ($0.x, $0.y) }, at: tip, turn: f),
                   medium, .bone)
        for x in [0.44, 0.48] {
            plate.line(placed(curve(P(x, 0.14), P(x - 0.025, 0.1), P(x, 0.06), 6).map { ($0.x, $0.y) }, at: tip, turn: f),
                       medium, .bone)
        }

        callout(&plate, "A", from: P(0.72, 0.1), to: P(0.86, 0.26))
        callout(&plate, "B", from: polar(o, 0.66, -push + 0.04), to: P(0.82, -0.36))
        callout(&plate, "C", from: polar(o, 0.8, push + 0.05), to: P(0.66, 0.66))
        callout(&plate, "D", from: polar(o, 0.5, .pi + 0.08), to: P(-0.78, 0.02))
        return plate
    }

    /// Problem 39, Lap time, hex, clocks 1+,2+.
    static func plate39() -> Plate? { nil }

    /// Problem 40, Split second, hex, clocks 1+,3+.
    static func plate40() -> Plate? { nil }

    /// Problem 41, Flyback, hex, clocks 1+,2+.
    static func plate41() -> Plate? { nil }

    /// Problem 42, Tachymeter, hex, clocks 1+,3+.
    static func plate42() -> Plate? { nil }
}
