// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 56 to 61, the chapter Slow motion.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let slowMotion: [Int: Halftone.Panel] = [56: rosewindow, 57: oculus]

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

// MARK: - 57: Oculus

/// Level 57's name: looking up into a coffered dome, the great oculus open to the sky a little off the middle, the sun
/// in it, and its disc of sunlight fallen on the coffers in the lower right, the dome lit on that side and dim on the
/// far one. Five lesser oculi pierce the dome round it (hex's five lenses on this level), each in a ring of stone
/// blocks lit on the sun's side, its keystone and the block facing the middle dark, and through each something passes
/// in the sky: a swallow at the top, a kite in the upper right, a hot-air balloon at the foot, an aeroplane in the lower
/// left and a butterfly in the upper left. The coffers nearest the middle are ten, so a quarter turn of the hub, half a
/// coffer out of step, sets rib where coffer was round each oculus's inner side.
extension LensArt {
    static let oculus: Halftone.Panel = {
        let rods = hexes, lenses = [1, 2, 4, 5, 6], glass = 0.15, frame = 0.264
        let sky = c(0.85), dark = Tone(0.06, 0.04, 0.1)
        let eye = P(0.04, -0.05), opening = 0.2, rim = 0.235, sun = eye + P(-0.09, -0.08)
        let patch = rods[3] + P(0.11, 0.02)
        // The coffers' rings: inner and outer radius, how many round, and the share of each turn that is coffer.
        let rings: [(Double, Double, Int, Double)] = [(0.24, 0.43, 10, 0.5), (0.47, 0.64, 18, 0.7), (0.68, 0.8, 24, 0.72), (0.84, 0.93, 30, 0.74)]
        let holes = lenses.map { rods[$0] }
        // Each ring's block that faces the middle, dark as its keystone is.
        let inward = holes.map { ((bearing(P(0, 0), $0) / 30).rounded() * 30).truncatingRemainder(dividingBy: 360) }

        var s: [Halftone.Stroke] = []
        // The coffers, each stepped, cut where an opening lies over it.
        func open(_ p: P) -> Bool {
            holes.contains { simd_distance(p, $0) < frame + 0.006 } || simd_distance(p, eye) < rim + 0.006
        }
        for (r0, r1, n, share) in rings {
            for j in 0..<n {
                let a0 = 360 * (Double(j) + 0.5 - share / 2) / Double(n), a1 = 360 * (Double(j) + 0.5 + share / 2) / Double(n)
                s += runs(closed(sector(P(0, 0), r0, r1, a0, a1)), hair) { !open($0) }
                let mid0 = r0 + 0.25 * (r1 - r0), mid1 = r1 - 0.25 * (r1 - r0), w = 0.22 * (a1 - a0)
                s += runs(closed(sector(P(0, 0), mid0, mid1, a0 + w, a1 - w)), hair) { !open($0) }
            }
        }
        s += hoop(P(0, 0), 0.95, bold, pieces: 12)
        // The great oculus, its bronze ring, and the sun in it.
        s += hoop(eye, rim, bold) + hoop(eye, opening, mid)
        s.append(stroke(circle(sun, 0.05, 16), mid))
        // The lesser oculi: each ring of stone blocks and its joints.
        for c in holes {
            s += hoop(c, frame, bold) + hoop(c, glass, mid)
            for j in 0..<12 { s.append(stroke([polar(c, glass, 30 * Double(j) + 15), polar(c, frame, 30 * Double(j) + 15)], hair)) }
        }

        // Through the top: a swallow, wings swept and tail forked.
        let swallow = rods[1] + P(0.026, -0.034)
        let bird: [P] = [P(0, -0.024), P(0.006, -0.014), P(0.03, -0.012), P(0.052, 0.006), P(0.026, 0.0), P(0.008, 0.006), P(0.006, 0.018),
                         P(0.018, 0.044), P(0, 0.024), P(-0.018, 0.044), P(-0.006, 0.018), P(-0.008, 0.006), P(-0.026, 0), P(-0.052, 0.006),
                         P(-0.03, -0.012), P(-0.006, -0.014)]
        s.append(stroke(closed(bird.map { swallow + $0 }), 0.0034))
        s.append(stroke(circle(swallow + P(0, -0.014), 0.003, 6), 0.002))
        // In the upper right: a kite, its spars, its tail of bows and its string.
        let kite = rods[2] + P(0.024, -0.034)
        let corners = [kite + P(0, -0.03), kite + P(0.02, -0.006), kite + P(0, 0.034), kite + P(-0.02, -0.006)]
        s.append(stroke(closed(corners), 0.0036))
        s.append(stroke([corners[0], corners[2]], 0.002))
        s.append(stroke([corners[1], corners[3]], 0.002))
        s.append(stroke(curve(corners[2], kite + P(0.02, 0.05), kite + P(0.0, 0.07), 8), 0.002))
        for t in [0.3, 0.7] {
            let b = kite + P(0.012 - 0.012 * t, 0.04 + 0.03 * t)
            s.append(stroke([b + P(-0.006, -0.004), b + P(0.006, 0.004), b + P(0.006, -0.004), b + P(-0.006, 0.004), b + P(-0.006, -0.004)], 0.0018))
        }
        s.append(stroke(curve(corners[1], kite + P(-0.04, 0.02), kite + P(-0.06, 0.07), 10), 0.0014))
        // At the foot: a hot-air balloon, its gores, the basket hung under.
        let balloon = rods[4] + P(-0.028, -0.034)
        s.append(stroke(closed(arc(balloon, 0.026, 150, 390, 18) + [balloon + P(0.008, 0.036), balloon + P(-0.008, 0.036)]), 0.0036))
        s.append(stroke(curve(balloon + P(0, -0.026), balloon + P(-0.014, 0.0), balloon + P(-0.006, 0.036), 8), 0.0018))
        s.append(stroke(curve(balloon + P(0, -0.026), balloon + P(0.014, 0.0), balloon + P(0.006, 0.036), 8), 0.0018))
        s.append(stroke(closed(rect(balloon.x - 0.007, balloon.y + 0.046, balloon.x + 0.007, balloon.y + 0.056)), 0.003))
        for x in [-0.007, 0.007] { s.append(stroke([balloon + P(x * 1.1, 0.036), balloon + P(x, 0.046)], 0.0014)) }
        // In the lower left: an aeroplane seen from below, heading up and right, and its trail.
        let plane = rods[5] + P(0.036, -0.036), heading = -30.0 * .pi / 180
        let half: [P] = [P(0.035, 0), P(0.03, 0.004), P(0.008, 0.004), P(-0.006, 0.032), P(-0.012, 0.032), P(-0.012, 0.004),
                         P(-0.028, 0.003), P(-0.034, 0.014), P(-0.038, 0.014), P(-0.036, 0)]
        let hull = (half + half.reversed().dropFirst().dropLast().map { P($0.x, -$0.y) }).map { q -> P in
            let k = 0.85 * q
            return plane + P(k.x * cos(heading) - k.y * sin(heading), k.x * sin(heading) + k.y * cos(heading))
        }
        s.append(stroke(closed(hull), 0.0034))
        let tail = plane + 0.85 * P(-0.04 * cos(heading), -0.04 * sin(heading)), back = P(-cos(heading), -sin(heading))
        for side in [-1.0, 1.0] {
            let off = P(-back.y, back.x) * (0.006 * side)
            s += dashes(tail + off + back * 0.004, tail + off + back * 0.05, 3, 0.002)
        }
        // In the upper left: a butterfly, four wings, body and feelers.
        let fly = rods[6] + P(0.028, -0.028)
        for side in [-1.0, 1.0] {
            s.append(stroke(closed([fly, fly + P(side * 0.026, -0.03), fly + P(side * 0.04, -0.016), fly + P(side * 0.034, -0.002)]), 0.0034))
            s.append(stroke(closed([fly + P(0, 0.004), fly + P(side * 0.028, 0.008), fly + P(side * 0.026, 0.026), fly + P(side * 0.01, 0.022)]), 0.003))
            s.append(stroke(curve(fly + P(0, -0.018), fly + P(side * 0.004, -0.03), fly + P(side * 0.014, -0.036), 5), 0.0016))
        }
        s.append(stroke([fly + P(0, -0.018), fly + P(0, 0.022)], 0.004))

        return Halftone.Panel(name: "oculus", tones: { p in
            for (k, c) in holes.enumerated() {
                let d = simd_distance(p, c)
                guard d < frame else { continue }
                if d < glass { return sky }
                // A block: lit as it faces the sun's side, the keystone at the top dark.
                let a = bearing(p, c), block = (a / 30 + 0.5).rounded(.down) * 30
                if block == 270 || block == inward[k] { return dark }
                let face = 0.5 + 0.5 * cos((block - 40) * .pi / 180)
                return Tone(0.3 + 0.35 * face, 0.28 + 0.3 * face, 0)
            }
            let e = simd_distance(p, eye)
            if e < opening { return simd_distance(p, sun) < 0.05 ? y(0.95) : sky }
            if e < rim { return y(0.8) }
            let r = simd_length(p)
            if r > 0.95 { return dark }
            // The dome is lit from the oculus on the side the sun falls, and dims round to the far side; where the sun's
            // disc lands, all of it is turned up to gold.
            let a = bearing(p, P(0, 0)), lit = r < 0.45 ? 0.85 : 0.5 + 0.5 * cos((a - 40) * .pi / 180)
            var tone = y(0.2 + 0.4 * lit)
            for (r0, r1, n, share) in rings where r > r0 && r < r1 {
                let t = a / 360 * Double(n), f = t - t.rounded(.down)
                guard abs(f - 0.5) < share / 2 else { break }
                let inner = r > r0 + 0.25 * (r1 - r0) && r < r1 - 0.25 * (r1 - r0) && abs(f - 0.5) < share * 0.28
                tone = m(inner ? 0.5 + 0.4 * lit : 0.3 + 0.35 * lit)
            }
            guard simd_distance(p, patch) < 0.21 else { return tone }
            return tone.y > 0 ? y(0.95) : Tone(0.4, 0.35, 1)
        }, strokes: s)
    }()
}
