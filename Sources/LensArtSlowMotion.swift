// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 56 to 61, the chapter Slow motion.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let slowMotion: [Int: Halftone.Panel] = [56: rosewindow]

    /// Hex's rods' centres, by rod.
    private static let hexes: [P] = [P(0, 0)] + (0..<6).map { polar(P(0, 0), 0.56, -90 + 60 * Double($0)) }

    /// A circle as `pieces` strokes: a whole circle's box covers its disc, and the bake tests every stroke whose box
    /// holds a pixel.
    private static func hoop(_ c: P, _ r: Double, _ width: Double, pieces: Int = 6, from: Double = 0) -> [Halftone.Stroke] {
        (0..<pieces).map { k in
            let a = from + 360 * Double(k) / Double(pieces)
            return stroke(arc(c, r, a, a + 360 / Double(pieces), max(4, 72 / pieces)), width)
        }
    }

    /// The angle of p about c in degrees, 0 at three o'clock and clockwise on screen, from 0 to 360.
    private static func bearing(_ p: P, _ c: P) -> Double {
        let a = atan2(p.y - c.y, p.x - c.x) * 180 / .pi
        return a < 0 ? a + 360 : a
    }
}

// MARK: - 56: Rose window

/// Level 56's name: a wheel of seven roundels in stone tracery, its outer ring of petals in blue, ruby and gold. The hub
/// and three of the ring (hex's four lenses on this level) are plain glass, each in a frame of gold and dark cusps, and
/// each shows the emblem painted on it: a dove with an olive sprig at the hub, a key in the lower right, a chalice at the
/// foot and a fleur-de-lis in the upper left. The other three roundels, which twist, hold the sun, the moon and a star,
/// and a rose, each set off its centre.
extension LensArt {
    static let rosewindow: Halftone.Panel = {
        let rods = hexes, core = 0.236, frame = 0.292
        let glass: [Tone?] = [y(0.85), nil, nil, m(0.85), c(0.7), nil, m(0.85)]
        let stone = Tone(0.05, 0.04, 0.08), gold = y(0.9), ruby = m(0.8), blue = c(0.8), night = c(0.42)
        // The twisting roundels' pictures, each off its centre.
        let sun = rods[1] + P(0.06, -0.05), moon = rods[2] + P(-0.05, 0.03), rose = rods[5] + P(0.04, -0.05)
        let rays = star(sun, 0.19, points: 12, inner: 0.55, degrees: -80)
        let comet = star(rods[2] + P(0.13, -0.1), 0.065, points: 5, inner: 0.42, degrees: -60)
        let stem = bar(rose + P(-0.04, 0.12), rose + P(-0.1, 0.22), 0.035), leaf = rose + P(0.02, 0.19)
        let bloom = [disc(rose, 0.05, gold)] + (0..<5).map { disc(polar(rose, 0.075, 72 * Double($0) - 90), 0.075, ruby) }
        // Each roundel's picture by rod, the plain ones empty.
        let pictures: [[Fill]] = [[], [disc(sun, 0.1, gold), fill(rays, y(0.55))],
                                  [fill(comet, gold), disc(moon + P(0.06, -0.04), 0.115, night), disc(moon, 0.14, gold)], [], [],
                                  bloom + [fill(stem, c(0.75)), oval(leaf, 0.06, 0.03, c(0.75))], []]
        let grounds: [Tone] = [.zero, blue, night, .zero, .zero, y(0.55), .zero]
        // Six lancet petals out between the ring's roundels, each the overlap of two discs.
        let petals = (0..<6).map { j -> (P, P) in
            let u = polar(P(0, 0), 1, 60 * Double(j)), n = P(-u.y, u.x), at = u * 0.76
            return (at + n * 0.1714, at - n * 0.1714)
        }
        let hearts = (0..<6).map { polar(P(0, 0), 0.74, 60 * Double($0)) }
        let knots = (0..<6).map { polar(P(0, 0), 0.323, 60 * Double($0)) }

        var s: [Halftone.Stroke] = []
        // The tracery: each roundel's two rings and its frame's cusps, the petals and their trefoils, and the scalloped rim.
        for (k, c) in rods.enumerated() {
            s += hoop(c, frame + 0.004, bold, from: 15 * Double(k))
            s += hoop(c, core, mid, from: 15 * Double(k))
        }
        for (j, (a, b)) in petals.enumerated() {
            let u = polar(P(0, 0), 1, 60 * Double(j)), angle = 60 * Double(j)
            s.append(stroke(arc(a, 0.2414, angle - 135, angle - 45, 14), bold))
            s.append(stroke(arc(b, 0.2414, angle + 45, angle + 135, 14), bold))
            for t in 0..<3 { s.append(stroke(circle(u * 0.74 + polar(P(0, 0), 0.03, angle + 120 * Double(t)), 0.03, 12), hair)) }
            s.append(stroke(circle(knots[j], 0.032, 12), hair))
        }
        s += hoop(P(0, 0), 0.97, bold, pieces: 12) + hoop(P(0, 0), 0.88, mid, pieces: 12)
        for j in 0..<24 {
            let a = 15 * Double(j)
            s.append(stroke([polar(P(0, 0), 0.88, a), polar(P(0, 0), 0.97, a)], mid))
            s.append(stroke(arc(polar(P(0, 0), 0.88, a + 7.5), 0.045, a + 7.5 - 80, a + 7.5 + 80, 8), hair))
        }
        // The twisting roundels: the sun and its rays, the moon and a star, a rose; and the leads between their pieces.
        s.append(stroke(circle(sun, 0.1, 28), mid))
        s.append(stroke(rays, hair))
        for a in [130.0, 200, 250] { s.append(stroke([polar(sun, 0.1, a), polar(rods[1], core, a + 10)], hair)) }
        s.append(stroke(arc(moon, 0.14, 60, 330, 24) + arc(moon + P(0.06, -0.04), 0.115, 300, 90, 20), mid))
        s.append(stroke(comet, mid))
        for a in [150.0, 230, 300] { s.append(stroke([polar(rods[2], 0.12, a), polar(rods[2], core, a - 20)], hair)) }
        for k in 0..<5 { s.append(stroke(arc(polar(rose, 0.075, 72 * Double(k) - 90), 0.075, 72 * Double(k) - 170, 72 * Double(k) - 10, 12), mid)) }
        s.append(stroke(circle(rose, 0.05, 16), hair))
        s.append(stroke(closed(stem), mid))
        s.append(stroke(ellipse(leaf, 0.06, 0.03, 20), mid))
        for a in [20.0, 200, 250] { s.append(stroke([polar(rods[5], 0.18, a), polar(rods[5], core, a)], hair)) }

        // The emblems on the plain roundels. At the hub, a dove with a sprig in its beak.
        let dove = rods[0] + P(0.024, -0.03), dq = 0.8
        s.append(stroke(ellipse(dove, 0.024, 0.0104, degrees: -12, 20), 0.0036))
        s.append(stroke(circle(dove + dq * P(0.034, -0.014), 0.0075, 10), 0.0034))
        s.append(stroke([dove + dq * P(0.042, -0.016), dove + dq * P(0.054, -0.012), dove + dq * P(0.042, -0.01)], 0.0024))
        s.append(stroke([dove + dq * P(-0.006, -0.008), dove + dq * P(-0.03, -0.05), dove + dq * P(-0.012, -0.034), dove + dq * P(0.004, -0.046), dove + dq * P(0.008, -0.012)], 0.003))
        s.append(stroke([dove + dq * P(-0.028, 0.004), dove + dq * P(-0.06, 0.018), dove + dq * P(-0.056, -0.004), dove + dq * P(-0.03, -0.004)], 0.003))
        s.append(stroke([dove + dq * P(0.052, -0.012), dove + dq * P(0.07, 0.004)], 0.002))
        for t in [0.3, 0.65, 1.0] { s.append(stroke(ellipse(dove + dq * P(0.052 + 0.018 * t, -0.012 + 0.016 * t + 0.004), 0.005, 0.0022, degrees: 40, 8), 0.0018)) }
        // A key, its bow, shaft and wards.
        let key = rods[3] + P(-0.004, -0.03)
        s.append(stroke(circle(key + P(-0.04, 0), 0.014, 14), 0.004))
        s.append(stroke(circle(key + P(-0.04, 0), 0.005, 8), 0.002))
        s.append(stroke([key + P(-0.026, 0), key + P(0.05, 0)], 0.004))
        s.append(stroke([key + P(0.05, 0), key + P(0.05, 0.022), key + P(0.04, 0.022), key + P(0.04, 0.012), key + P(0.03, 0.012), key + P(0.03, 0.02)], 0.003))
        // A chalice, a host over it.
        let cup = rods[4] + P(0.04, -0.024)
        s.append(stroke([cup + P(-0.03, -0.02)] + arc(cup + P(0, -0.02), 0.03, 180, 0, 12).dropFirst() + [cup + P(-0.03, -0.02)], 0.0036))
        s.append(stroke([cup + P(0, 0.01), cup + P(0, 0.036)], 0.0036))
        s.append(stroke(ellipse(cup + P(0, 0.022), 0.006, 0.004, 8), 0.0024))
        s.append(stroke([cup + P(-0.022, 0.044), cup + P(-0.012, 0.036), cup + P(0.012, 0.036), cup + P(0.022, 0.044), cup + P(-0.022, 0.044)], 0.003))
        s.append(stroke(circle(cup + P(0, -0.034), 0.009, 12), 0.003))
        s.append(stroke([cup + P(0, -0.04), cup + P(0, -0.028)], 0.0016))
        s.append(stroke([cup + P(-0.006, -0.034), cup + P(0.006, -0.034)], 0.0016))
        // A fleur-de-lis.
        let lily = rods[6] + P(0.036, -0.02), lq = 0.75
        s.append(stroke(closed([lily + lq * P(0, -0.05)] + curve(lily + lq * P(0, -0.05), lily + lq * P(0.024, -0.022), lily + lq * P(0.004, 0.004), 8).dropFirst()
            + curve(lily + lq * P(-0.004, 0.004), lily + lq * P(-0.024, -0.022), lily + lq * P(0, -0.05), 8).dropFirst()), 0.0034))
        for side in [-1.0, 1.0] {
            s.append(stroke(curve(lily + lq * P(side * 0.006, 0.004), lily + lq * P(side * 0.05, -0.006), lily + lq * P(side * 0.04, -0.036), 10)
                + curve(lily + lq * P(side * 0.04, -0.036), lily + lq * P(side * 0.026, -0.03), lily + lq * P(side * 0.03, -0.018), 4).dropFirst(), 0.003))
            s.append(stroke(curve(lily + lq * P(side * 0.004, 0.014), lily + lq * P(side * 0.02, 0.02), lily + lq * P(side * 0.018, 0.036), 6), 0.003))
        }
        s.append(stroke(closed(rect(lily.x - 0.015, lily.y + 0.003, lily.x + 0.015, lily.y + 0.0105)), 0.003))

        return Halftone.Panel(name: "rosewindow", tones: { p in
            // The roundels: glass or a picture inside, their frames' cusps round it, the first that holds the point.
            for k in 0..<7 {
                let d = simd_distance(p, rods[k])
                guard d < frame else { continue }
                if d >= core { return Int(bearing(p, rods[k]) / 30) % 2 == 1 ? stone : k == 0 || k == 5 ? blue : gold }
                if let t = glass[k] { return t }
                for f in pictures[k] where f.holds(p) { return f.tone }
                return grounds[k]
            }
            let r = simd_length(p)
            if r > 0.97 { return stone }
            if r > 0.88 { return Int(bearing(p, P(0, 0)) / 15) % 2 == 0 ? blue : ruby }
            if r > 0.5 {
                for (j, (a, b)) in petals.enumerated() where simd_distance(p, a) < 0.2414 && simd_distance(p, b) < 0.2414 {
                    return simd_distance(p, hearts[j]) < 0.06 ? gold : j % 2 == 0 ? ruby : blue
                }
                return stone
            }
            for k in knots where simd_distance(p, k) < 0.032 { return gold }
            return stone
        }, strokes: s)
    }()
}
