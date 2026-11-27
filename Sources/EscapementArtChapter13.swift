// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 13, Fusee: problems 73 to 78's plates, drawn with `Kit`. Each keeps its subject clear of a two-card hub
/// (0.195) round every rod of its layout.
extension EscapementArt {
    private typealias K = Kit

    /// A point `p` of a level circle about `c`, radius 1 in its own units, seen from above at a slant that squashes its
    /// depth by `k`.
    private static func level(_ c: P, _ r: Double, _ k: Double, _ p: P) -> P { c + P(r * p.x, r * k * p.y) }

    /// Rows from y0 to y1, closer toward y0, the horizon: a floor or lawn in perspective.
    private static func receding(from y0: Double, to y1: Double, rows: Int) -> [Double] {
        (0...rows).map { i in
            let t = Double(i) / Double(rows)
            return y0 + (y1 - y0) * pow(t, 1.5)
        }
    }

    /// The pieces of the level line at `y` inside a ring.
    private static func across(_ ring: [P], at y: Double) -> [[P]] {
        var xs: [Double] = []
        for i in 0..<(ring.count - 1) {
            let a = ring[i], b = ring[i + 1]
            if (a.y <= y) != (b.y <= y) { xs.append(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x)) }
        }
        xs.sort()
        return stride(from: 0, to: xs.count - 1, by: 2).map { [P(xs[$0], y), P(xs[$0 + 1], y)] }
    }

    // MARK: 73 Sundial

    /// The glass below the line y = `at`, as one outline.
    private static func cap(below at: Double) -> [P] {
        let a = asin(at / 1.06)
        let rim = arc(.zero, 1.06, from: a, to: .pi - a)
        return rim + [rim[0]]
    }

    /// Problem 73, Sundial, pent, clocks 0+: a garden sundial on a baluster pedestal before a clipped hedge, its dial
    /// plate seen from above with the hour lines fanned from the gnomon's root, and the gnomon's shadow lying across
    /// to the hour, the pedestal's own shadow on the lawn; that hour's numeral in the second ink.
    static func plate73() -> Plate {
        var plate = Plate()
        let c = P(0, -0.12), R = 0.33, k = 0.56
        func on(_ p: P) -> P { level(c, R, k, p) }
        // The dial's north, back and to the right; east a quarter turn clockwise of it.
        let phi = 0.45, north = P(sin(phi), -cos(phi)), east = P(cos(phi), sin(phi))
        let root = -0.4 * north
        func hourLine(_ h: Double) -> P {
            let a = (h - 12) * .pi / 12, t = atan2(0.78 * sin(a), cos(a))
            return north * cos(t) + east * sin(t)
        }
        /// Where the ray from the root meets the circle of radius `r` about the dial's centre.
        func reach(_ d: P, _ r: Double) -> P {
            let b = simd_dot(root, d), q = simd_dot(root, root) - r * r
            return root + d * (-b + sqrt(b * b - q))
        }
        func round(_ r: Double) -> [P] { (0...96).map { on(polar(.zero, r, 2 * .pi * Double($0) / 96)) } }
        let dial = round(1), thickness = dial.map { $0 + P(0, 0.05) }
        let slab = Array(dial[0...48]) + Array(thickness[0...48].reversed()) + [dial[0]]

        // The baluster's half-width down from under the dial to its foot on the lawn at y = 0.8.
        let ground = 0.8
        let profile: [(Double, Double)] = [(0.035, 0.2), (0.075, 0.2), (0.075, 0.15), (0.1, 0.15)]
            + (0...24).map { i -> (Double, Double) in
                let t = Double(i) / 24, y = 0.1 + 0.52 * t
                return (y, 0.075 + 0.07 * pow(sin(.pi * pow(t, 0.8)), 1.5))
            }
            + [(0.62, 0.11), (0.65, 0.11), (0.65, 0.2), (0.72, 0.2), (0.72, 0.3), (ground, 0.3)]
        let column = profile.map { P($0.1, $0.0) } + profile.reversed().map { P(-$0.1, $0.0) } + [P(profile[0].1, profile[0].0)]
        let lit = profile.map { P(-0.3 * $0.1, $0.0) } + profile.reversed().map { P(-0.78 * $0.1, $0.0) } + [P(-0.3 * profile[0].1, profile[0].0)]
        // Its shadow laid on the lawn by an afternoon sun from the left.
        let shadow = column.map { p in P(p.x + 0.85 * (ground - p.y) + 0.02, ground - 0.34 * (ground - p.y)) }

        let horizon = 0.25, hedgeLine = 0.0
        var hedgeTop: [P] = []
        for i in 0...44 {
            let x = -1.1 + 2.2 * Double(i) / 44
            hedgeTop.append(P(x, hedgeLine - 0.03 * abs(sin(Double(i) * .pi / 4))))
        }
        let hedge = hedgeTop + [P(1.1, horizon), P(-1.1, horizon), hedgeTop[0]]

        // Two clipped yews standing out of the hedge at either side.
        let yews = [-0.91, 0.91].map { x -> [P] in
            let side: [P] = (0...16).map { i in
                let t = Double(i) / 16
                return P(x - 0.13 * sin(.pi / 2 * t) * (1 - 0.15 * t), -0.6 + 0.62 * t)
            }
            return side + side.reversed().map { P(2 * x - $0.x, $0.y) } + [side[0]]
        }
        K.ground(&plate, angle: 0.35, around: [cap(below: hedgeLine - 0.035)] + yews)
        for (n, yew) in yews.enumerated() {
            K.mass(&plate, yew)
            let x = n == 0 ? -0.91 : 0.91
            for row in 0..<15 {
                let y = -0.55 + 0.04 * Double(row), half = 0.13 * sin(.pi / 2 * min(1, (y + 0.6) / 0.62)) - 0.025
                for i in stride(from: -half, through: half, by: 0.05) {
                    plate.line(arc(P(x + i + (row % 2 == 0 ? 0 : 0.025), y), 0.016, from: 0.2, to: .pi - 0.2), medium, .bone)
                }
            }
        }
        // The lawn ruled level, its rows closing toward the hedge.
        let rows = receding(from: horizon, to: 1.1, rows: 13).dropFirst()
        for y in rows { plate.line([P(-1.1, y), P(1.1, y)], K.groundWidth + 0.005 * y) }
        // The hedge in ink, clipped in courses of bone leaves.
        K.mass(&plate, hedge)
        for row in 0..<7 {
            let y = hedgeLine + 0.03 + 0.034 * Double(row)
            for i in 0..<46 {
                let x = -1.08 + 0.048 * Double(i) + (row % 2 == 0 ? 0 : 0.024) + 0.01 * rnd(73, row * 40 + i)
                plate.line(arc(P(x, y), 0.016, from: 0.2, to: .pi - 0.2), medium, .bone)
            }
        }
        plate.line([P(-1.1, horizon), P(1.1, horizon)], heavy)
        K.mass(&plate, shadow)
        // Bone between the lawn's rows breaks the shadow.
        let rowList = Array(rows)
        for i in 1..<rowList.count where rowList[i] > 0.45 {
            plate.lines(across(shadow, at: (rowList[i] + rowList[i - 1]) / 2), heavy, .bone)
        }

        // The pedestal in ink, lit down its left.
        K.mass(&plate, column)
        plate.fill(lit)
        plate.lines(hatch([lit], angle: 1.25, gap: 0.03), fine)
        plate.line(lit, fine)
        // The flutes and reflected light down its shadowed side.
        for f in [0.22, 0.5, 0.8] {
            plate.line(profile.filter { $0.0 > 0.11 && $0.0 < 0.61 }.map { P(f * $0.1, $0.0) }, f == 0.8 ? heavy : medium, .bone)
        }
        for (y, w) in [(0.075, 0.2), (0.1, 0.15), (0.65, 0.2), (0.72, 0.3)] {
            plate.line([P(-w, y), P(w, y)], heavy, .bone)
        }

        // The dial: its edge in ink, the plate in bone, the chapter ring and hour lines.
        K.mass(&plate, slab)
        plate.lines(hatch([slab], angle: 0, gap: 0.016).filter { $0[0].x < -0.18 }, fine, .bone)
        plate.fill(dial)
        plate.line(dial, 0.016)
        plate.line(round(0.92), medium)
        plate.line(round(0.64), medium)
        for h in stride(from: 6.0, through: 18.0, by: 0.5) {
            let d = hourLine(h), whole = h == h.rounded()
            plate.line([on(whole ? root : reach(d, 0.64)), on(reach(d, 0.92))], whole ? heavy : medium)
        }
        // The gnomon's shadow from the root along the third hour after noon.
        let shadowAt = 15, d = hourLine(Double(shadowAt)), across = P(-d.y, d.x)
        let tip = reach(d, 0.62)
        K.mass(&plate, [on(root + across * 0.03), on(tip + across * 0.13), on(tip - across * 0.06), on(root - across * 0.03), on(root + across * 0.03)])
        // The chapters on the ring, read from the root.
        for h in 6...18 {
            let p = on(reach(hourLine(Double(h)), 0.78))
            let n = h > 12 ? h - 12 : h
            if h == shadowAt {
                plate.fill(arc(p, 0.04))
                plate.lines(K.numeral(roman(n), at: p, height: 0.055, squeeze: 0.8), 0.014, .second)
            } else {
                plate.lines(K.numeral(roman(n), at: p, height: 0.048, squeeze: 0.66), medium)
            }
        }
        // The gnomon: a triangular plate standing on the noon line, its style rising north.
        let foot = on(root + 0.04 * north), heel = on(root + 0.95 * north), top = heel + P(0, -0.16)
        let side = P(0.024, 0.006)
        K.mass(&plate, [foot, heel, heel + side, top + side, top, foot])
        plate.line([foot + P(0.006, -0.006), top + P(0.004, 0.012)], medium, .bone)
        plate.line([top + P(0.012, 0.03), heel + P(0.012, -0.012)], fine, .bone)

        callout(&plate, "A", from: on(P(-0.5, 0.45)), to: P(-0.5, 0.2))
        callout(&plate, "B", from: top + P(0.006, 0.04), to: P(0.22, -0.38))
        callout(&plate, "C", from: P(0.0, 0.4), to: P(-0.2, 0.86))
        callout(&plate, "D", from: P(0.62, 0.66), to: P(0.66, 0.36))
        return plate
    }

    /// Problem 74, Gnomon, hex, clocks 1+.
    static func plate74() -> Plate? { nil }

    /// Problem 75, Noon mark, pent, clocks 0+.
    static func plate75() -> Plate? { nil }

    /// Problem 76, Meridian, hex, clocks 1+.
    static func plate76() -> Plate? { nil }

    /// Problem 77, Solar time, pent, clocks 0+.
    static func plate77() -> Plate? { nil }

    /// Problem 78, Analemma, hex, clocks 1+.
    static func plate78() -> Plate? { nil }
}
