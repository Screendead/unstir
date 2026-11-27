// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 56 to 61, the chapter Slow motion.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let slowMotion: [Int: Halftone.Panel] = [56: rosewindow, 57: oculus, 58: stainedglass, 59: skylight, 60: frostedglass,
                                                    61: bullseye]

    /// Hex's rods' centres, by rod.
    private static let hexes: [P] = [P(0, 0)] + (0..<6).map { polar(P(0, 0), 0.56, -90 + 60 * Double($0)) }

    /// A circle as `pieces` strokes: a whole circle's box covers its disc, and the bake tests every stroke whose box
    /// holds a pixel.
    private static func hoop(_ c: P, _ r: Double, _ width: Double, pieces: Int = 6, from: Double = 0) -> [Halftone.Stroke] {
        (0..<pieces).map { k in
            let a = from + 360 * Double(k) / Double(pieces)
            return stroke(arc(c, r, a, a + 360 / Double(pieces), max(4, Int(r * 160) / pieces)), width)
        }
    }

    /// A line with each segment cut in six, for `runs` to cut it close to where something lies over it.
    private static func fine(_ line: [P]) -> [P] {
        zip(line, line.dropFirst()).flatMap { a, b in (0..<6).map { a + (b - a) * (Double($0) / 6) } } + [line.last!]
    }

    /// A long stroke as short ones of `every` segments: the bake tests every point of each stroke whose box holds a
    /// pixel, and a long slant's box holds most of the glass.
    private static func chop(_ s: Halftone.Stroke, every: Int = 6) -> [Halftone.Stroke] {
        stride(from: 0, to: s.points.count - 1, by: every).map { k in
            stroke(Array(s.points[k...min(k + every, s.points.count - 1)]), s.width)
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
/// and three of the ring (hex's four lenses on this level) are plain glass, each in a frame of cusps, coloured and dark
/// by turns, and each shows the emblem painted on it: a dove with an olive sprig at the hub, a key in the lower right, a
/// chalice at the foot and a fleur-de-lis in the upper left. The other three roundels, which twist, hold the sun, the
/// moon and a star, and a rose, each set off its centre.
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
                s += runs(closed(arc(P(0, 0), r1, a0, a1, 3) + arc(P(0, 0), r0, a1, a0, 3)), hair) { !open($0) }
                let mid0 = r0 + 0.25 * (r1 - r0), mid1 = r1 - 0.25 * (r1 - r0), w = 0.22 * (a1 - a0)
                s += runs(closed(arc(P(0, 0), mid1, a0 + w, a1 - w, 2) + arc(P(0, 0), mid0, a1 - w, a0 + w, 2)), hair) { !open($0) }
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

// MARK: - 58: Stained glass

/// Level 58's name: a leaded window close to, its panes cut irregular, coloured to a scene: the sun low in the upper
/// left in a glow of gold and orange, blue sky, magenta hills, a river winding down through green and gold meadow, all
/// inside a border of alternating panes. Four clear roundels are leaded into it (hex's four lenses on this level), each
/// ringed with coloured jewels, and through each the world outside: a bell in its tower at the top, a church's spire in
/// the upper right, an umbrella in the lower right and a bicycle at the foot.
extension LensArt {
    static let stainedglass: Halftone.Panel = {
        let rods = hexes, lenses = [1, 2, 3, 4], clear = 0.2, frame = 0.264
        let holes = lenses.map { rods[$0] }, jewels = [m(0.9), y(0.95), c(0.9), y(0.95), m(0.9), c(0.9), y(0.95), m(0.9), c(0.9), y(0.95)]
        // The panes: a grid of corners, each nudged, each cell cut into two panes along one diagonal or the other.
        let n = 14, size = 0.16, origin = -1.12
        func hash(_ i: Int, _ j: Int, _ k: Int) -> Double {
            let v = sin(Double(i) * 127.1 + Double(j) * 311.7 + Double(k) * 74.7) * 43758.5453
            return v - v.rounded(.down)
        }
        let corners: [[P]] = (0...n).map { j in
            (0...n).map { i in P(origin + size * Double(i), origin + size * Double(j)) + 0.042 * P(hash(i, j, 1) * 2 - 1, hash(i, j, 2) * 2 - 1) }
        }
        func scene(_ q: P, _ v: Double) -> Tone {
            let sun = P(-0.5, -0.45), ds = simd_distance(q, sun)
            if ds < 0.2 { return y(0.95) }
            let horizon = 0.05 + 0.12 * sin(q.x * 2.2 + 0.6)
            if q.y < horizon {
                if ds < 0.4 { return v < 0.5 ? y(0.6) : Tone(0, 0.45, 0.85) }
                return c(0.4 + 0.45 * v)
            }
            let depth = q.y - horizon, centre = 0.12 - 0.4 * depth + 0.1 * sin(q.y * 5), width = 0.05 + 0.16 * depth
            if abs(q.x - centre) < width { return c(0.92) }
            if depth < 0.24 { return m(0.5 + 0.4 * v) }
            return v < 0.5 ? Tone(0.55, 0, 0.6) : y(0.5 + 0.35 * v)
        }
        // Each cell's two panes as triangles, and each pane's tone.
        let panes: [(P, P, P, Tone)] = (0..<n * n).flatMap { cell -> [(P, P, P, Tone)] in
            let i = cell % n, j = cell / n
            let a = corners[j][i], b = corners[j][i + 1], c = corners[j + 1][i + 1], d = corners[j + 1][i]
            let cut = hash(i, j, 3) < 0.5 ? [(a, b, c), (a, c, d)] : [(a, b, d), (b, c, d)]
            return cut.enumerated().map { k, t in (t.0, t.1, t.2, scene((t.0 + t.1 + t.2) / 3, hash(i, j, 4 + k))) }
        }
        func lead(_ p: P) -> Bool { simd_length(p) < 0.925 && holes.allSatisfy { simd_distance(p, $0) > frame + 0.006 } }

        var s: [Halftone.Stroke] = []
        // The leads: every row and column of corners, every diagonal, cut at the roundels and the border.
        for j in 0...n { s += runs(fine(corners[j]), mid, keep: lead).flatMap { chop($0, every: 12) } }
        for i in 0...n { s += runs(fine((0...n).map { corners[$0][i] }), mid, keep: lead).flatMap { chop($0, every: 12) } }
        for j in 0..<n {
            for i in 0..<n {
                let a = corners[j][i], b = corners[j][i + 1], c = corners[j + 1][i + 1], d = corners[j + 1][i]
                let cut = hash(i, j, 3) < 0.5 ? [a, c] : [b, d]
                s += lead(cut[0]) && lead(cut[1]) && lead((cut[0] + cut[1]) / 2) ? [stroke(cut, mid)] : runs(fine(cut), mid, keep: lead)
            }
        }
        // The border's panes, and the sun's face of rays painted on its glass.
        s += hoop(P(0, 0), 0.925, bold, pieces: 12)
        for k in 0..<36 { s.append(stroke([polar(P(0, 0), 0.925, 10 * Double(k)), polar(P(0, 0), 1, 10 * Double(k))], mid)) }
        // The roundels: their rims and the leads between the jewels.
        for c in holes {
            s += hoop(c, frame, bold) + hoop(c, clear, mid)
            for k in 0..<10 { s.append(stroke([polar(c, clear, 36 * Double(k) + 18), polar(c, frame, 36 * Double(k) + 18)], hair)) }
        }

        // Through the top: a bell hung in its tower's arch, its rope down.
        let bell = rods[1] + P(0.026, -0.032)
        let side: [P] = [P(0.024, 0.014), P(0.016, 0.006), P(0.014, -0.012), P(0.01, -0.02), P(0, -0.024)]
        s.append(stroke(closed(side + side.reversed().dropFirst().map { P(-$0.x, $0.y) }).map { bell + $0 }, 0.0036))
        s.append(stroke(circle(bell + P(0, 0.02), 0.005, 8), 0.003))
        s.append(stroke(arc(bell + P(0, -0.012), 0.036, 180, 360, 16), 0.003))
        s.append(stroke([bell + P(-0.036, -0.012), bell + P(-0.036, 0.03)], 0.003))
        s.append(stroke([bell + P(0.036, -0.012), bell + P(0.036, 0.03)], 0.003))
        s.append(stroke([bell + P(-0.012, 0.014), bell + P(-0.018, 0.04)], 0.0018))
        // In the upper right: a church's spire, a cross on it and a clock on its tower.
        let spire = rods[2] + P(0.03, -0.024)
        s.append(stroke(closed(rect(spire.x - 0.012, spire.y - 0.004, spire.x + 0.012, spire.y + 0.04)), 0.0034))
        s.append(stroke(closed([spire + P(-0.014, -0.004), spire + P(0, -0.05), spire + P(0.014, -0.004)]), 0.0032))
        s.append(stroke([spire + P(0, -0.05), spire + P(0, -0.066)], 0.0024))
        s.append(stroke([spire + P(-0.006, -0.06), spire + P(0.006, -0.06)], 0.0024))
        s.append(stroke(circle(spire + P(0, 0.01), 0.006, 10), 0.0024))
        s.append(stroke([spire + P(0, 0.01), spire + P(0.003, 0.006)], 0.0014))
        s.append(stroke(arc(spire + P(0, 0.04), 0.006, 180, 360, 6), 0.0024))
        // In the lower right: an umbrella, its ribs scalloped.
        let brolly = rods[3] + P(0.03, -0.03)
        s.append(stroke(arc(brolly, 0.032, 180, 360, 16), 0.0036))
        for k in 0..<4 { s.append(stroke(arc(brolly + P(-0.024 + 0.016 * Double(k), 0), 0.008, 180, 360, 6), 0.0024)) }
        s.append(stroke([brolly + P(0, -0.032), brolly + P(0, 0.03)], 0.003))
        s.append(stroke(arc(brolly + P(0.006, 0.03), 0.006, 180, 0, 6), 0.003))
        s.append(stroke([brolly + P(0, -0.032), brolly + P(0, -0.04)], 0.003))
        // At the foot: a bicycle.
        let bike = rods[4] + P(0.002, -0.044)
        for x in [-0.024, 0.024] { s.append(stroke(circle(bike + P(x, 0), 0.016, 16), 0.003)) }
        s.append(stroke([bike + P(-0.024, 0), bike + P(-0.004, 0), bike + P(0.014, -0.02), bike + P(-0.012, -0.02), bike + P(-0.024, 0)], 0.0026))
        s.append(stroke([bike + P(-0.004, 0), bike + P(-0.014, -0.028)], 0.0026))
        s.append(stroke([bike + P(0.024, 0), bike + P(0.012, -0.03), bike + P(0.02, -0.032)], 0.0026))
        s.append(stroke([bike + P(-0.02, -0.03), bike + P(-0.008, -0.03)], 0.003))

        return Halftone.Panel(name: "stainedglass", tones: { p in
            for h in holes {
                let d = simd_distance(p, h)
                guard d < frame else { continue }
                if d < clear { return c(0.3) }
                return jewels[Int(bearing(p, h) / 36) % 10]
            }
            let r = simd_length(p)
            if r > 0.925 { return Int(bearing(p, P(0, 0)) / 10) % 2 == 0 ? m(0.8) : c(0.7) }
            let i = Int(((p.x - origin) / size).rounded(.down)), j = Int(((p.y - origin) / size).rounded(.down))
            for (dj, di) in [(0, 0), (0, -1), (0, 1), (-1, 0), (1, 0), (-1, -1), (-1, 1), (1, -1), (1, 1)] {
                let ii = i + di, jj = j + dj
                guard ii >= 0, jj >= 0, ii < n, jj < n else { continue }
                for k in 0..<2 {
                    let t = panes[2 * (jj * n + ii) + k]
                    let e0 = (t.1 - t.0).x * (p - t.0).y - (t.1 - t.0).y * (p - t.0).x
                    let e1 = (t.2 - t.1).x * (p - t.1).y - (t.2 - t.1).y * (p - t.1).x
                    let e2 = (t.0 - t.2).x * (p - t.2).y - (t.0 - t.2).y * (p - t.2).x
                    if (e0 >= 0 && e1 >= 0 && e2 >= 0) || (e0 <= 0 && e1 <= 0 && e2 <= 0) { return t.3 }
                }
            }
            return .zero
        }, strokes: s)
    }()
}

// MARK: - 59: Skylight

/// Level 59's name: looking straight up through a skylight at night, its shaft's four walls round the edge, one lit,
/// and its glazing bars crossing off the middle; through the glass the full moon in the upper right with a cloud over
/// it and a long cloud lower down. Five raindrops sit on the glass (hex's five lenses on this level), each a bright bead
/// with a rim of light and shadow by turns, and through each, bent small, something of the night: a cat peering over the
/// edge at the top, a bat in the lower right, Cassiopeia's W at the foot, a chimney pot smoking in the lower left and
/// a falling leaf in the upper left.
extension LensArt {
    static let skylight: Halftone.Panel = {
        let rods = hexes, lenses = [1, 3, 4, 5, 6], bead = 0.2, frame = 0.264
        let holes = lenses.map { rods[$0] }
        let sky = c(0.4), cloud = Tone(0.3, 0.26, 0.3), bar = Tone(0.04, 0.03, 0.06)
        let rim: [Tone] = [m(0.85), y(0.9), Tone(0.45, 0.4, 0.9), y(0.9), bar, m(0.75), bar, y(0.8)]
        let moon = rods[2] + P(0.08, -0.07)
        let clouds = [oval(moon + P(-0.02, 0.1), 0.16, 0.045, cloud), oval(moon + P(0.08, 0.13), 0.1, 0.04, cloud),
                      oval(P(-0.25, 0.3), 0.3, 0.06, cloud), oval(P(-0.05, 0.36), 0.2, 0.05, cloud)]
        // The shaft: a square opening a little off the middle, its walls seen end on round the edge.
        let shaft = P(0.05, -0.04), opening = 0.8
        let walls = [y(0.75), m(0.35), y(0.35), m(0.6)]
        // The glazing bars, off the middle so a quarter turn of the hub shows.
        let column = -0.13, row = 0.12, half = 0.035

        var s: [Halftone.Stroke] = []
        func glass(_ p: P) -> Bool { holes.allSatisfy { simd_distance(p, $0) > frame + 0.006 } }
        // The shaft's inner edge and the corners' mitres.
        let edge = [shaft + P(-opening, -opening), shaft + P(opening, -opening), shaft + P(opening, opening), shaft + P(-opening, opening)]
        s += runs(fine(closed(edge)), bold) { simd_length($0) < 1 && glass($0) }.flatMap { chop($0) }
        for k in 0..<4 { s += runs(span(edge[k], edge[k] + simd_normalize(edge[k] - shaft) * 0.6, 12), mid) { simd_length($0) < 1 } }
        // The bars' edges, cut at the beads.
        for x in [column - half, column + half] { s += runs(span(P(x, -1), P(x, 1), 60), mid, keep: glass) }
        for yy in [row - half, row + half] { s += runs(span(P(-1, yy), P(1, yy), 60), mid, keep: glass) }
        // The moon, its seas, the clouds' edges, and the stars.
        s.append(stroke(circle(moon, 0.15, 36), mid))
        for (at, r) in [(P(-0.05, -0.04), 0.035), (P(0.04, 0.02), 0.05), (P(-0.02, 0.07), 0.025)] { s.append(stroke(circle(moon + at, r, 14), hair)) }
        for f in clouds {
            s += runs(fine(ellipse(f.centre, f.radii!.x, f.radii!.y, 28)), hair, keep: glass)
        }
        for at in [P(-0.2, -0.3), P(0.2, -0.1), P(-0.7, 0.0), P(0.7, 0.5), P(0.3, 0.62), P(-0.3, 0.74), P(0.1, -0.86), P(-0.12, 0.0)] {
            s += glint(at, 0.035, hair)
        }
        // The beads: their rims, a highlight in each, and the run each has left below it.
        for c in holes {
            s += hoop(c, frame, bold, pieces: 4) + hoop(c, bead, hair, pieces: 4)
            s.append(stroke(arc(c, 0.17, 200, 250, 10), mid))
        }

        // Through the top: a cat peering down over the edge, ears up, eyes slit.
        let cat = rods[1] + P(0.024, -0.034)
        s.append(stroke(closed(arc(cat, 0.024, -20, 200, 18) + [cat + P(-0.02, -0.02), cat + P(-0.016, -0.04), cat + P(-0.006, -0.024),
                                                                cat + P(0.006, -0.024), cat + P(0.016, -0.04), cat + P(0.02, -0.02)]), 0.0034))
        for x in [-0.009, 0.009] { s.append(stroke(ellipse(cat + P(x, -0.006), 0.0035, 0.0065, 8), 0.0026)) }
        s.append(stroke([cat + P(-0.003, 0.006), cat + P(0.003, 0.006), cat + P(0, 0.01), cat + P(-0.003, 0.006)], 0.002))
        for side in [-1.0, 1.0] {
            for dy in [0.006, 0.012] { s.append(stroke([cat + P(side * 0.008, 0.01), cat + P(side * 0.038, dy)], 0.0014)) }
        }
        // In the lower right: a bat.
        let bat = rods[3] + P(0.026, -0.03)
        let wing: [P] = [P(0.004, -0.004), P(0.02, -0.014), P(0.046, -0.012), P(0.038, 0.0), P(0.03, 0.002), P(0.024, 0.012), P(0.014, 0.006), P(0.004, 0.01)]
        s.append(stroke(closed(wing.map { bat + $0 } + wing.reversed().map { bat + P(-$0.x, $0.y) }), 0.003))
        s.append(stroke(ellipse(bat + P(0, 0.004), 0.006, 0.01, 10), 0.003))
        for x in [-0.004, 0.004] { s.append(stroke([bat + P(x, -0.004), bat + P(x * 1.6, -0.012)], 0.002)) }
        // At the foot: Cassiopeia's W.
        let w = rods[4] + P(0.0, -0.04)
        let stars = [P(-0.04, -0.012), P(-0.02, 0.012), P(0.0, -0.004), P(0.022, 0.014), P(0.042, -0.014)].map { w + $0 }
        s.append(stroke(stars, 0.0016))
        for (k, at) in stars.enumerated() { s += glint(at, k == 2 ? 0.012 : 0.009, 0.002) }
        // In the lower left: a chimney pot and its smoke.
        let pot = rods[5] + P(0.03, -0.02)
        s.append(stroke(closed([pot + P(-0.012, 0.02), pot + P(-0.008, -0.01), pot + P(0.008, -0.01), pot + P(0.012, 0.02)]), 0.0034))
        s.append(stroke(closed(rect(pot.x - 0.012, pot.y - 0.016, pot.x + 0.012, pot.y - 0.01)), 0.003))
        s.append(stroke([pot + P(-0.03, 0.02), pot + P(0.03, 0.02)], 0.003))
        s.append(stroke(curve(pot + P(0, -0.02), pot + P(-0.02, -0.03), pot + P(-0.006, -0.04), 8) + curve(pot + P(-0.006, -0.04), pot + P(0.01, -0.05), pot + P(-0.012, -0.062), 8).dropFirst(), 0.003))
        // In the upper left: a falling leaf, its veins and stalk.
        let leaf = rods[6] + P(0.026, -0.03), lie = P(cos(-0.6), sin(-0.6)), cross = P(-lie.y, lie.x)
        let blade = (0...20).map { k -> P in
            let t = Double(k) / 20 * 2 * .pi
            return leaf + lie * (0.03 * cos(t)) + cross * (0.016 * sin(t) * (1 + 0.25 * cos(3 * t)))
        }
        s.append(stroke(blade, 0.0032))
        s.append(stroke([leaf - lie * 0.044, leaf + lie * 0.03], 0.002))
        for t in [-0.016, 0.0, 0.016] {
            for side in [-1.0, 1.0] { s.append(stroke([leaf + lie * t, leaf + lie * (t + 0.01) + cross * (side * 0.012)], 0.0014)) }
        }

        return Halftone.Panel(name: "skylight", tones: { p in
            for h in holes {
                let d = simd_distance(p, h)
                guard d < frame else { continue }
                return d < bead ? c(0.85) : rim[Int(bearing(p, h) / 45) % 8]
            }
            let q = p - shaft
            if max(abs(q.x), abs(q.y)) > opening {
                return walls[abs(q.x) > abs(q.y) ? (q.x > 0 ? 0 : 1) : (q.y > 0 ? 2 : 3)]
            }
            if abs(p.x - column) < half || abs(p.y - row) < half { return bar }
            if simd_distance(p, moon) < 0.15 {
                for f in clouds.prefix(2) where f.holds(p) { return f.tone }
                return y(0.9)
            }
            for f in clouds where f.holds(p) { return f.tone }
            return sky
        }, strokes: s)
    }()
}

// MARK: - 60: Frosted glass

/// Level 60's name: a window pane blue with frost, ferns of ice growing in from the edge and blooms of it thick and
/// thin, a heart and a smiling face drawn in it by a finger, and the sash's wood down the left with a glazing bar off it.
/// Five holes are wiped clear (hex's five lenses on this level), each ringed by its smeared edge, thick frost and wet
/// streaks by turns, and through each the snowy dusk outside: a snowman at the middle, a street lamp at the top, a fir
/// tree with its star in the upper right, a sledge in the lower right and a snowflake at the foot.
extension LensArt {
    static let frostedglass: Halftone.Panel = {
        let rods = hexes, lenses = [0, 1, 2, 3, 4], wiped = 0.205, frame = 0.264
        let holes = lenses.map { rods[$0] }
        let night = m(0.7), frost = c(0.35), thick = c(0.62), thin = c(0.14), wet = y(0.6)
        let ice = Tone(0.45, 0.4, 0.45), smear = [ice, m(0.95), ice, wet, ice, m(0.95), wet, ice, night, ice, wet, m(0.95)]
        // Blooms of the frost, thick and thin, as (centre, radii, thick).
        let blooms: [Fill] = [(P(-0.7, -0.62), P(0.22, 0.16), true), (P(-0.3, 0.05), P(0.12, 0.2), false), (P(-0.72, 0.55), P(0.2, 0.14), false),
                              (P(-0.25, 0.62), P(0.16, 0.12), true), (P(-0.52, -0.05), P(0.1, 0.08), true), (P(0.72, 0.0), P(0.18, 0.24), true),
                              (P(0.3, -0.82), P(0.2, 0.1), true), (P(0.4, 0.84), P(0.24, 0.1), false), (P(-0.05, -0.86), P(0.2, 0.1), false),
                              (P(0.8, -0.6), P(0.14, 0.2), false), (P(0.82, 0.6), P(0.14, 0.18), true)]
            .map { oval($0.0, $0.1.x, $0.1.y, $0.2 ? thick : thin) }
        // The finger's drawings, each a band the width of a fingertip.
        let finger = 0.034
        let heartAt = rods[6] + P(0.06, -0.03)
        let heart = (0...40).map { k -> P in
            let t = Double(k) / 40 * 2 * .pi
            return heartAt + 0.0105 * P(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)))
        }
        // The window's sash bar down the left and a glazing bar across to the middle, so its twisting rods turn wood too.
        let sash = -0.8, rail = 0.02, wood = y(0.55)
        let face = rods[5] + P(0.05, 0.04), smile = arc(face, 0.085, 20, 160, 16)
        let eyes = [face + P(-0.05, -0.05), face + P(0.05, -0.05)]
        let lo = heart.reduce(heart[0], simd_min) - P(finger, finger), hi = heart.reduce(heart[0], simd_max) + P(finger, finger)

        var s: [Halftone.Stroke] = []
        func clear(_ p: P) -> Bool {
            abs(p.x - sash) > 0.05 && (abs(p.y - rail) > 0.045 || p.x > -0.3) && holes.allSatisfy { simd_distance(p, $0) > frame + 0.006 } && distance(p, heart) > finger + 0.004
                && abs(simd_distance(p, face) - 0.15) > finger + 0.004
        }
        // The frost's ferns: fronds growing in from the edge, each a stem and its side shoots, cut where the frost is gone.
        for (k, root) in [P(-0.95, -0.2), P(-0.7, 0.7), P(0.2, 0.97), P(0.9, 0.4), P(0.92, -0.3), P(0.4, -0.9), P(-0.4, -0.9), P(-0.95, 0.3),
                          P(0.7, 0.7), P(-0.2, 0.97), P(0.75, -0.65), P(-0.65, -0.75)].enumerated() {
            let inward = simd_normalize(-root), bend = Double(k % 2 == 0 ? 1 : -1) * 0.35
            let stem = curve(root, root + inward * 0.3 + P(-inward.y, inward.x) * (bend * 0.3), root + inward * 0.6 + P(-inward.y, inward.x) * (bend * 0.1), 12)
            s += runs(stem, mid, keep: clear)
            for j in stride(from: 2, to: 12, by: 2) {
                let a = stem[j], dir = simd_normalize(stem[j + 1] - stem[j]), len = 0.15 * (1 - Double(j) / 14)
                for side in [-1.0, 1.0] {
                    let tip = a + (dir * 0.5 + P(-dir.y, dir.x) * side) * len
                    s += runs([a, (a + tip) / 2, tip], mid, keep: clear)
                }
            }
        }
        // The sash's and the rail's edges.
        for x in [sash - 0.045, sash + 0.045] { s.append(stroke([P(x, -1), P(x, 1)], mid)) }
        for yy in [rail - 0.04, rail + 0.04] {
            s.append(stroke([P(-1, yy), P(sash - 0.045, yy)], mid))
            s.append(stroke([P(sash + 0.045, yy), P(-0.3, yy)], mid))
        }
        // The finger's strokes' edges.
        s.append(stroke(heart, hair))
        s += hoop(face, 0.15 + finger, hair) + hoop(face, 0.15 - finger, hair)
        s.append(stroke(smile, mid))
        for e in eyes { s.append(stroke(circle(e, 0.022, 10), hair)) }
        // The holes: each smeared edge, the wipe's arcs, and a drip run down from each.
        for c in holes {
            s += hoop(c, frame, mid, pieces: 4) + hoop(c, wiped, hair, pieces: 4)
            for a in [30.0, 150, 250] { s.append(stroke(arc(c, 0.235, a, a + 40, 8), hair)) }
            s.append(stroke([polar(c, frame, 100), polar(c, frame + 0.12, 100)], mid))
        }

        // At the middle: a snowman, hat and scarf, arms of twigs.
        let man = rods[0] + P(0.034, -0.034)
        s.append(stroke(circle(man + P(0, 0.018), 0.014, 16), 0.0034))
        s.append(stroke(circle(man + P(0, -0.006), 0.01, 14), 0.0034))
        s.append(stroke(closed(rect(man.x - 0.008, man.y - 0.03, man.x + 0.008, man.y - 0.016)), 0.003))
        s.append(stroke([man + P(-0.013, -0.016), man + P(0.013, -0.016)], 0.003))
        s.append(stroke([man + P(0.002, -0.006), man + P(0.012, -0.004)], 0.0024))
        s.append(stroke([man + P(-0.012, 0.01), man + P(-0.032, -0.004), man + P(-0.038, -0.002)], 0.002))
        s.append(stroke([man + P(0.012, 0.01), man + P(0.03, -0.006), man + P(0.034, -0.012)], 0.002))
        // At the top: a street lamp, its glass lit and the snow falling through its light.
        let lamp = rods[1] + P(0.03, -0.036)
        s.append(stroke([lamp + P(0, 0.006), lamp + P(0, 0.06)], 0.0034))
        s.append(stroke([lamp + P(-0.008, 0.06), lamp + P(0.008, 0.06)], 0.003))
        s.append(stroke(closed([lamp + P(-0.008, 0.006), lamp + P(-0.012, -0.012), lamp + P(0.012, -0.012), lamp + P(0.008, 0.006)]), 0.003))
        s.append(stroke([lamp + P(-0.014, -0.012), lamp + P(0, -0.02), lamp + P(0.014, -0.012)], 0.003))
        for at in [P(-0.03, -0.02), P(-0.024, 0.01), P(0.026, -0.024), P(0.03, 0.012), P(-0.034, 0.034), P(0.022, 0.04)] {
            s.append(stroke(circle(lamp + at, 0.0025, 6), 0.0024))
        }
        // In the upper right: a fir tree in three tiers, a star on top.
        let fir = rods[2] + P(0.026, -0.036)
        var outline: [P] = []
        for (k, (y0, w)) in [(-0.02, 0.012), (0.0, 0.02), (0.022, 0.028)].enumerated() {
            outline += [fir + P(w, y0 + 0.004), fir + P(w * 0.4, y0 - 0.006 - 0.004 * Double(k))]
        }
        s.append(stroke(closed([fir + P(0, -0.034)] + outline.dropLast() + [fir + P(0.028, 0.026), fir + P(-0.028, 0.026)]
            + outline.dropLast().reversed().map { fir + P(-($0 - fir).x, ($0 - fir).y) }), 0.003))
        s.append(stroke(closed(rect(fir.x - 0.004, fir.y + 0.026, fir.x + 0.004, fir.y + 0.036)), 0.0026))
        s.append(stroke(star(fir + P(0, -0.04), 0.008), 0.0018))
        // In the lower right: a sledge, its runners curled up in front, and its rope.
        let sled = rods[3] + P(0.004, -0.04)
        s.append(stroke([sled + P(-0.036, 0.012), sled + P(0.03, 0.012)] + arc(sled + P(0.03, 0.002), 0.01, 90, -90, 8).dropFirst(), 0.0032))
        s.append(stroke(closed(rect(sled.x - 0.032, sled.y - 0.008, sled.x + 0.026, sled.y - 0.002)), 0.003))
        for x in [-0.024, 0.0, 0.02] { s.append(stroke([sled + P(x, -0.002), sled + P(x, 0.012)], 0.0024)) }
        s.append(stroke(curve(sled + P(0.03, -0.008), sled + P(0.05, -0.02), sled + P(0.044, -0.04), 8), 0.0016))
        // At the foot: a snowflake, six arms and their branches.
        let flake = rods[4] + P(0.03, -0.03)
        for k in 0..<6 {
            let a = 60 * Double(k) + 15
            s.append(stroke([flake, polar(flake, 0.026, a)], 0.0026))
            for t in [0.012, 0.019] {
                s.append(stroke([polar(flake, t, a), polar(polar(flake, t, a), 0.008, a - 45)], 0.0018))
                s.append(stroke([polar(flake, t, a), polar(polar(flake, t, a), 0.008, a + 45)], 0.0018))
            }
        }

        return Halftone.Panel(name: "frostedglass", tones: { p in
            for c in holes {
                let d = simd_distance(p, c)
                guard d < frame else { continue }
                return d < wiped ? night : smear[Int(bearing(p, c) / 30) % 12]
            }
            if p.x > lo.x, p.y > lo.y, p.x < hi.x, p.y < hi.y, distance(p, heart) < finger { return night }
            if abs(simd_distance(p, face) - 0.15) < finger { return night }
            for e in eyes where simd_distance(p, e) < 0.022 { return night }
            if simd_distance(p, face) < 0.11, distance(p, smile) < 0.012 { return wet }
            if abs(p.x - sash) < 0.045 || (abs(p.y - rail) < 0.04 && p.x < -0.3) { return wood }
            // The frost in blooms, thin in places and thick in others.
            for f in blooms where f.holds(p) { return f.tone }
            return frost
        }, strokes: s)
    }()
}

// MARK: - 61: Bullseye pane

/// Level 61's name: an old casement leaded in diamond quarries of green, blue, rose and smoke glass, its iron latch
/// off the middle and its wooden frame round the edge. Four bullseyes are set in it (hex's four lenses on this level),
/// the thick middles of crown glass, amber, each swirled round its rim, and through each, small and bent, the tavern
/// inside: a candle in the upper right, a tankard in the lower right, a clay pipe smoking in the lower left and the
/// ace of hearts in the upper left.
extension LensArt {
    static let bullseye: Halftone.Panel = {
        let rods = hexes, lenses = [2, 3, 5, 6], glass = 0.2, frame = 0.264
        let holes = lenses.map { rods[$0] }
        let amber = y(0.75), swirl = [y(0.95), Tone(0.04, 0.04, 0.08), Tone(0, 0.6, 0.9), Tone(0.04, 0.04, 0.08)]
        let quarries = [Tone(0.55, 0, 0.6), c(0.8), m(0.65), Tone(0.38, 0.32, 0.42), c(0.25), Tone(0.3, 0.5, 0)]
        let wood = Tone(0, 0.3, 0.35), iron = Tone(0.03, 0.03, 0.05)
        // The leads run at 60 and 120 degrees, `spacing` apart, so the quarries stand tall.
        let spacing = 0.17, normals = [P(-sin(.pi / 3), cos(.pi / 3)), P(-sin(2 * .pi / 3), cos(2 * .pi / 3))]
        let latch = bar(P(0.07, 0.06), P(0.3, 0.06), 0.06), keeper = rect(0.3, 0.0, 0.34, 0.12), knob = P(0.07, 0.06)
        let hash: @Sendable (Int, Int) -> Int = { i, j in
            let v = sin(Double(i) * 17.31 + Double(j) * 41.77) * 43758.5453
            return Int((v - v.rounded(.down)) * 6)
        }

        var s: [Halftone.Stroke] = []
        func open(_ p: P) -> Bool { simd_length(p) < 0.9 && holes.allSatisfy { simd_distance(p, $0) > frame + 0.006 } }
        // The leads, each cut short so the bake tests few of them a pixel.
        for n in normals {
            let along = P(n.y, -n.x)
            for k in -7...7 {
                let line = span(n * (spacing * Double(k)) - along * 1.1, n * (spacing * Double(k)) + along * 1.1, 66)
                for piece in runs(line, mid, keep: open) { s += chop(piece) }
            }
        }
        // The frame, the latch and its keeper.
        s += hoop(P(0, 0), 0.9, bold, pieces: 12)
        s.append(stroke(closed(latch), mid))
        s.append(stroke(circle(knob, 0.045, 16), mid))
        s.append(stroke(closed(keeper), mid))
        // The bullseyes: rim, swirl and the ripples of the spun glass.
        for c in holes {
            s += hoop(c, frame, bold, pieces: 4) + hoop(c, glass, hair, pieces: 4)
            s.append(stroke(spiral(c, 0.205, grow: 0.0006, turn: 12, 90), hair))
            for r in [0.115, 0.16] { s += hoop(c, r, hair, pieces: 4, from: 20) }
        }

        // In the upper right: a candle in its stick, lit.
        let candle = rods[2] + P(0.028, -0.026)
        s.append(stroke(closed(rect(candle.x - 0.006, candle.y - 0.01, candle.x + 0.006, candle.y + 0.026)), 0.003))
        s.append(stroke(closed([candle + P(0, -0.04), candle + P(0.006, -0.026), candle + P(0, -0.016), candle + P(-0.006, -0.026)]), 0.0026))
        s.append(stroke([candle + P(0, -0.016), candle + P(0, -0.01)], 0.0016))
        s.append(stroke(ellipse(candle + P(0, 0.028), 0.018, 0.005, 14), 0.003))
        s.append(stroke(arc(candle + P(0.024, 0.02), 0.008, -90, 90, 8), 0.0024))
        for a in [-150.0, -90, -30] { s.append(stroke([polar(candle + P(0, -0.026), 0.016, a), polar(candle + P(0, -0.026), 0.024, a)], 0.0016)) }
        // In the lower right: a tankard, its lid up and its handle.
        let mug = rods[3] + P(0.026, -0.03)
        s.append(stroke(closed(rect(mug.x - 0.016, mug.y - 0.016, mug.x + 0.016, mug.y + 0.024)), 0.0034))
        s.append(stroke(arc(mug + P(0.016, 0.004), 0.012, -70, 70, 8), 0.003))
        s.append(stroke([mug + P(-0.016, -0.016), mug + P(-0.006, -0.034), mug + P(0.016, -0.03)], 0.003))
        for x in [-0.008, 0.0, 0.008] { s.append(stroke([mug + P(x, -0.01), mug + P(x, 0.018)], 0.0014)) }
        s.append(stroke(curve(mug + P(-0.016, -0.016), mug + P(-0.02, -0.024), mug + P(-0.012, -0.024), 5), 0.0024))
        // In the lower left: a clay pipe and its smoke.
        let pipe = rods[5] + P(0.022, -0.026)
        s.append(stroke(closed([pipe + P(0.004, -0.018), pipe + P(0.028, -0.018), pipe + P(0.024, 0.008), pipe + P(0.016, 0.012), pipe + P(0.008, 0.008)]), 0.004))
        s.append(stroke([pipe + P(0.006, -0.012), pipe + P(0.026, -0.012)], 0.0016))
        s.append(stroke(curve(pipe + P(0.008, 0.004), pipe + P(-0.02, 0.014), pipe + P(-0.05, 0.004), 10), 0.0036))
        s.append(stroke(curve(pipe + P(0.016, -0.022), pipe + P(0.004, -0.032), pipe + P(0.016, -0.04), 8)
            + curve(pipe + P(0.016, -0.04), pipe + P(0.028, -0.048), pipe + P(0.016, -0.056), 8).dropFirst(), 0.0026))
        // In the upper left: the ace of hearts.
        let card = rods[6] + P(0.03, -0.03)
        s.append(stroke(closed(squircle(card, 0.018, 0.026, 32)), 0.003))
        s.append(stroke(closed(arc(card + P(-0.005, -0.002), 0.005, 150, 360, 6) + arc(card + P(0.005, -0.002), 0.005, 180, 390, 6) + [card + P(0, 0.01)]), 0.0026))
        s.append(stroke([card + P(-0.012, -0.018), card + P(-0.009, -0.024), card + P(-0.006, -0.018)], 0.0016))
        s.append(stroke([card + P(0.006, 0.018), card + P(0.009, 0.024), card + P(0.012, 0.018)], 0.0016))

        return Halftone.Panel(name: "bullseye", tones: { p in
            for c in holes {
                let d = simd_distance(p, c)
                guard d < frame else { continue }
                if d < glass { return amber }
                // The crown glass's swirl: bands that wind outwards as they go round.
                let t = (d - glass) / (frame - glass) * 0.5 + bearing(p, c) / 90
                return swirl[Int(t * 2) % 4]
            }
            if simd_length(p) > 0.9 { return wood }
            if simd_distance(p, knob) < 0.045 || inside(p, latch) || inside(p, keeper) { return iron }
            let i = Int((simd_dot(p, normals[0]) / spacing).rounded(.down)), j = Int((simd_dot(p, normals[1]) / spacing).rounded(.down))
            return quarries[hash(i, j)]
        }, strokes: s)
    }()
}
