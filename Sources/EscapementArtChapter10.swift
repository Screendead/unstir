// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 10, Countdown: problems 55 to 60's plates, drawn with `Kit`. Not drawn yet: each falls back to
/// the shared plate.
extension EscapementArt {
    /// A lump with a ragged edge about `c`, the same on every run for its seed.
    private static func lump(_ c: P, _ r: Double, seed: Int, squash: Double = 0.7) -> [P] {
        let n = 9
        let ring = (0..<n).map { k -> P in
            let a = 2 * .pi * Double(k) / Double(n), s = r * (0.75 + 0.45 * rnd(seed, k))
            return c + P(s * cos(a), squash * s * sin(a))
        }
        return ring + [ring[0]]
    }

    /// Problem 55, Curfew, hex, clocks 1-: the couvre-feu, the hood set over the hearth's fire at nightfall, a bold
    /// ribbed dome with a ring handle and a pierced band, on the hearthstone under the mantel beam, bellows hung on
    /// the left and the poker against the right jamb; the embers' glow in the second ink, through the band's middle
    /// piercings and under the lip.
    static func plate55() -> Plate {
        var plate = Plate()
        let base = 0.8, rx = 0.76, ry = 0.88
        func half(_ y: Double) -> Double { rx * sqrt(max(0, 1 - pow((base - y) / ry, 2))) }
        let dome = ellipse(P(0, base), rx, ry, from: .pi, to: 2 * .pi) + [P(-rx, base)]
        let lip = box(P(-rx - 0.05, base - 0.035), P(rx + 0.05, base + 0.035))
        let floor = box(P(-1.1, base + 0.035), P(1.1, 1.1))
        let beam = box(P(-1.1, -0.68), P(1.1, -0.5))
        let jambs = [box(P(-1.1, -0.5), P(-0.84, base + 0.035)), box(P(0.84, -0.5), P(1.1, base + 0.035))]
        let bellows = [P(-0.7, -0.4), P(-0.6, -0.33), P(-0.56, -0.12), P(-0.62, 0.1), P(-0.7, 0.16), P(-0.78, 0.1),
                       P(-0.84, -0.12), P(-0.8, -0.33), P(-0.7, -0.4)]
        let nozzle = Kit.band(P(-0.7, 0.14), P(-0.7, 0.3), 0.045)
        let poker = Kit.band(P(0.79, base), P(0.66, -0.34), 0.05)
        let grip = arc(P(0.655, -0.39), 0.055)
        let handle = Kit.ribbon(curve(P(-0.16, -0.05), P(0, -0.46), P(0.16, -0.05)), 0.055)
        Kit.ground(&plate, angle: 0.5, around: [box(P(-1.1, -1.1), P(1.1, -0.68)), dome, lip, floor, beam, bellows, nozzle, poker, grip, handle] + jambs)

        // The mantel beam, its grain in bone, and the jambs' stones in courses.
        plate.fill(beam)
        plate.line(beam, 0.04)
        plate.line((0...40).map { i in
            let x = -1.1 + 2.2 * Double(i) / 40
            return P(x, -0.59 + 0.018 * sin(x * 7))
        }, 0.03)
        for x in [-0.62, 0.62] { Kit.mass(&plate, arc(P(x, -0.59), 0.03)) }
        // The chimney breast's stones over it, in courses.
        for (row, y) in stride(from: -0.68, to: -1.1, by: -0.13).enumerated() {
            for x in stride(from: -1.26 + Double(row % 2) * 0.14, to: 1.1, by: 0.28) {
                let stone = box(P(x, y), P(x + 0.28, y - 0.13))
                plate.fill(stone)
                plate.line(stone, 0.04)
            }
        }
        for jamb in jambs {
            let x0 = jamb[0].x, x1 = jamb[1].x
            for (k, y) in stride(from: -0.5, to: base, by: 0.22).enumerated() {
                let stone = box(P(x0, y), P(x1, min(y + 0.22, base + 0.035)))
                if k % 2 == 0 { Kit.mass(&plate, stone) } else { Kit.solid(&plate, stone, angle: -0.8, gap: 0.025) }
            }
        }

        // The bellows on its nail, and the poker leaning on the jamb.
        plate.line([P(-0.7, -0.5), P(-0.7, -0.4)], heavy)
        Kit.mass(&plate, bellows)
        plate.line([P(-0.7, -0.33), P(-0.62, -0.1), P(-0.7, 0.1), P(-0.78, -0.1), P(-0.7, -0.33)], 0.012, .bone)
        plate.fill(arc(P(-0.7, -0.1), 0.03))
        for p in [P(-0.7, -0.37), P(-0.63, -0.3), P(-0.59, -0.12), P(-0.64, 0.07), P(-0.76, 0.07), P(-0.81, -0.12),
                  P(-0.77, -0.3)] {
            plate.fill(arc(p, 0.014))
        }
        plate.line(arc(P(-0.7, -0.1), 0.03), medium)
        Kit.mass(&plate, nozzle)
        Kit.mass(&plate, poker)
        plate.line(arc(P(0.655, -0.39), 0.055), 0.026)

        // The hearthstone, its joints in bone.
        Kit.mass(&plate, floor)
        plate.lines([[P(-0.42, base + 0.035), P(-0.5, 1.1)], [P(0.4, base + 0.035), P(0.48, 1.1)],
                     [P(-1.1, 0.95), P(1.1, 0.95)]], 0.014, .bone)

        // The embers spilt from under the lip.
        let embers = [(P(-0.22, 0.875), 0.04), (P(-0.1, 0.89), 0.035), (P(0.04, 0.88), 0.045), (P(0.17, 0.885), 0.035),
                      (P(0.28, 0.87), 0.03)]
        for (k, (c, r)) in embers.enumerated() {
            let ember = lump(c, 1.3 * r, seed: 55 + k)
            plate.fill(ember, .second)
            plate.line(ember, medium)
        }

        // The dome in gores, ink and bone in turn, girdled, and pierced near the foot.
        let top = base - 0.999 * ry
        let edges = [-1.0, -0.88, -0.64, -0.52, -0.28, -0.14, 0.14, 0.28, 0.52, 0.64, 0.88, 1.0]
        plate.fill(dome)
        func gore(_ a: Double, _ b: Double) -> [P] {
            let up = stride(from: 0.58, through: top, by: -0.02).map { P(a * half($0), $0) }
            return up + stride(from: top, through: 0.58, by: 0.02).map { P(b * half($0), $0) } + [up[0]]
        }
        for k in 0..<(edges.count - 1) {
            let m = (edges[k] + edges[k + 1]) / 2
            if k % 2 == 0 {
                Kit.mass(&plate, gore(edges[k], edges[k + 1]))
            } else {
                for y in stride(from: 0.02, through: 0.54, by: 0.08) where abs(m * half(y)) < half(y) - 0.04 {
                    plate.fill(arc(P(m * half(y), y), 0.022), .black)
                }
            }
        }
        plate.line(dome, 0.02)
        let girdle = stride(from: -1.0, through: 1.0, by: 0.05).map { P($0 * half(0.36), 0.36) }
        Kit.cut(&plate, Kit.ribbon(girdle, 0.05))
        for x in stride(from: -0.6, through: 0.6, by: 0.08) { plate.fill(arc(P(x, 0.36), 0.012), .black) }
        let pierced = (stride(from: 0.58, through: base, by: 0.01).map { P(-half($0), $0) }
            + stride(from: base, through: 0.58, by: -0.01).map { P(half($0), $0) })
        Kit.cut(&plate, pierced + [pierced[0]])
        for x in stride(from: -0.6, through: 0.61, by: 0.1) {
            let hole = arc(P(x, 0.65), 0.03)
            plate.fill(hole, abs(x) > 0.15 && abs(x) < 0.35 ? .second : .black)
            plate.line(hole, medium)
            if x < 0.6 { plate.fill([P(x + 0.05, 0.62), P(x + 0.065, 0.65), P(x + 0.05, 0.68), P(x + 0.035, 0.65), P(x + 0.05, 0.62)], .black) }
        }

        // The lip and the ring handle.
        Kit.mass(&plate, lip)
        plate.line([P(-rx - 0.03, base), P(rx + 0.03, base)], 0.012, .bone)
        Kit.mass(&plate, handle)
        plate.line(curve(P(-0.16, -0.05), P(0, -0.46), P(0.16, -0.05)), 0.01, .bone)
        for x in [-0.16, 0.16] {
            plate.fill(arc(P(x, -0.05), 0.04), .black)
            plate.line(arc(P(x, -0.05), 0.016), medium, .bone)
        }

        callout(&plate, "A", from: P(0.09, -0.24), to: P(0.24, -0.4))
        callout(&plate, "B", from: P(-0.5, 0.65), to: P(-0.3, 0.47))
        callout(&plate, "C", from: P(-0.66, -0.2), to: P(-0.3, -0.38))
        callout(&plate, "D", from: P(0.71, 0.05), to: P(0.6, 0.0))
        return plate
    }

    /// Problem 56, Last orders, hex, clocks 1-,2-.
    static func plate56() -> Plate? { nil }

    /// Problem 57, Deadline, hex, clocks 1-,3-.
    static func plate57() -> Plate? { nil }

    /// Problem 58, Final hour, hex, clocks 1-.
    static func plate58() -> Plate? { nil }

    /// Problem 59, Time's up, hex, clocks 1-,2-.
    static func plate59() -> Plate? { nil }

    /// Problem 60, Zero hour, hex, clocks 1-.
    static func plate60() -> Plate? { nil }
}
