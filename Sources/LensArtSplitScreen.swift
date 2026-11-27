// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 50 to 55, the chapter Split screen.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let splitScreen: [Int: Halftone.Panel] = [50: owl]
}

// MARK: - 50: Owl

/// Level 50's name: a horned owl on a branch over still water at night, face on, and its reflection under it, rippled
/// and gone cool in the pond. Its eyes are over the upper cores and the reflection's over the lower (hex's four lenses
/// on this level), each a ruff of feathers round an iris, and in each pupil what the eye has caught: a mouse, a bat,
/// and in the water's eyes a frog and a dragonfly.
extension LensArt {
    static let owl: Halftone.Panel = {
        let eyes = [P(-0.485, -0.28), P(0.485, -0.28)], water = 0.0
        let iris = y(1), ruffA = y(0.45), ruffB = m(0.3)
        let body = m(0.6), sky = c(0.2), beakTone = y(0.75), branchTone = y(0.3)
        let beak = [P(-0.075, -0.19), P(0.075, -0.19), P(0.006, 0.0)]
        let tufts = [[P(-0.2, -0.7), P(-0.62, -0.62), P(-0.5, -0.95)], [P(0.2, -0.7), P(0.62, -0.62), P(0.46, -0.96)]]
        let brow = [P(-0.82, -0.56), P(-0.3, -0.66), P(0, -0.3), P(0.3, -0.66), P(0.82, -0.56), P(0.3, -0.58), P(0, -0.18), P(-0.3, -0.58)]
        let branch = bar(P(-1.05, -0.035), P(0.42, -0.005), 0.07)
        let feet = [P(-0.2, -0.045), P(0.16, -0.04)]
        let head = oval(P(0, -0.4), 0.9, 0.44, body)
        // The ruff's feathers, as the angles where each eye's tone changes, so a neighbour's twist slides a seam along.
        let seams: [[Double]] = [[10, 48, 70, 118, 150, 196, 222, 268, 300, 334], [-6, 30, 64, 96, 140, 172, 210, 250, 286, 318]]
        let fills = [fill(beak, beakTone)] + feet.map { oval($0, 0.075, 0.035, y(0.85)) } + [fill(branch, branchTone)]
            + tufts.map { fill($0, m(0.9)) } + [fill(brow, c(0.35))]

        // Lily pads on the pond, off the bottom rod's centre, each with its notch.
        let padAt = [(P(-0.3, 0.8), 0.15, 0.065, 70.0), (P(0.36, 0.64), 0.1, 0.045, 120.0), (P(0.12, 0.9), 0.08, 0.035, 300.0)]
        let pads = [disc(P(-0.24, 0.77), 0.03, m(0.85))] + padAt.map { oval($0.0, $0.1, $0.2, Tone(0.35, 0, 0.75)) }

        @Sendable func above(_ p: P) -> Tone {
            let k = p.x < 0 ? 0 : 1, d = p - eyes[k], r2 = simd_length_squared(d)
            if r2 < 0.1764 {
                if r2 < 0.0144 { return .zero }
                if r2 < 0.069696 { return iris }
                let r = r2.squareRoot(), a = (atan2(d.y, d.x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
                if r < 0.4 + 0.022 * cos(a * 12 * .pi / 180) {
                    var n = 0
                    for seam in seams[k] where seam < a { n += 1 }
                    return n % 2 == 0 ? ruffA : ruffB
                }
            }
            for f in fills where f.holds(p) { return f.tone }
            return head.holds(p) ? body : sky
        }

        var s: [Halftone.Stroke] = []
        // The head: outline, ear tufts, brow, beak, the ruffs' scalloped edges and their seams, and each eye's rim and
        // pupil with a catchlight.
        let crown = ellipse(P(0, -0.4), 0.9, 0.44, 96).filter { $0.y < water - 0.01 }
        s += runs(crown, bold) { !(abs($0.x) > 0.2 && abs($0.x) < 0.62 && $0.y < -0.6) }
        for t in tufts { s.append(stroke(t, bold)) }
        s.append(stroke(closed(brow), mid))
        s.append(stroke(closed(beak), bold))
        s.append(stroke([P(0, -0.17), P(0.004, -0.06)], hair))
        for (k, e) in eyes.enumerated() {
            s.append(stroke(closed((0..<96).map { i in
                let a = Double(i) * 3.75
                return polar(e, 0.4 + 0.022 * cos(a * 12 * .pi / 180), a)
            }), mid))
            for a in seams[k] { s.append(stroke([polar(e, 0.275, a), polar(e, 0.38, a + 6)], hair)) }
            s += runs(circle(e, 0.264, 64), bold) { simd_distance($0, polar(e, 0.264, k == 0 ? 130 : 50)) > 0.05 }
            s.append(stroke(circle(e, 0.12, 36), mid))
            s.append(stroke(arc(e, 0.2, 200, 250, 10), mid))
        }
        // The breast's feathers between the ruffs, and the feet on the branch.
        for (k, at) in [P(-0.16, -0.12), P(0.16, -0.12), P(-0.27, -0.04), P(0.28, -0.05), P(-0.06, -0.06)].enumerated() {
            let w = 0.04 + 0.006 * Double(k % 2)
            s.append(stroke([at + P(-w, -0.025), at, at + P(w, -0.025)], hair))
        }
        for f in feet {
            for dx in [-0.05, 0.0, 0.05] { s.append(stroke([f + P(dx * 0.6, -0.01), f + P(dx, 0.04)], mid)) }
        }
        s.append(stroke(closed(branch), mid))
        s.append(stroke(curve(P(-0.62, -0.03), P(-0.7, -0.1), P(-0.84, -0.12), 8), mid))
        // The night: stars, a few with rays.
        for (k, at) in [P(-0.08, -0.9), P(0.72, -0.58), P(-0.76, -0.58), P(0.3, -0.9), P(0.86, -0.3), P(-0.9, -0.22)].enumerated() {
            if k % 3 == 0 { s += glint(at, 0.04, hair) } else { s.append(stroke(circle(at, 0.008, 6), mid)) }
        }
        // The waterline, and the reflection's outlines broken by ripples, which run across the pond.
        s.append(stroke([P(-1, water), P(1, water)], mid))
        let ripple = { (p: P) in sin(p.y * 2 * .pi / 0.09) > -0.55 }
        let mirrored = { (line: [P]) in line.map { P($0.x, 2 * water - $0.y) } }
        s += runs(mirrored(crown), mid, keep: ripple)
        for e in eyes.map({ P($0.x, 2 * water - $0.y) }) {
            s += runs(circle(e, 0.264, 64), mid, keep: ripple)
            s.append(stroke(circle(e, 0.12, 36), hair))
        }
        s += runs(mirrored(span(beak[0], beak[2], 16) + span(beak[2], beak[1], 16)), hair, keep: ripple)
        for t in tufts { s += runs(mirrored(span(t[1], t[2], 16) + span(t[2], t[0], 16)), hair, keep: ripple) }
        for (k, yy) in stride(from: 0.08, through: 0.95, by: 0.12).enumerated() {
            let half = (1 - yy * yy).squareRoot()
            s += runs(span(P(-half, yy), P(half, yy), 60)) { p in
                sin((p.x + 0.13 * Double(k)) * 2 * .pi / 0.34) > -0.2 && eyes.allSatisfy { simd_distance(p, P($0.x, -$0.y)) > 0.14 }
            }
        }

        for (c, rx, ry, notch) in padAt {
            s += runs(ellipse(c, rx, ry, 40), mid) { simd_distance(P(($0.x - c.x) / rx, ($0.y - c.y) / ry), polar(P(0, 0), 1, notch)) > 0.3 }
            s.append(stroke([c, c + P(rx * cos(notch * .pi / 180), ry * sin(notch * .pi / 180))], hair))
        }
        s += (0..<6).map { k in stroke([P(-0.24, 0.77), polar(P(-0.24, 0.77), 0.05, -150 + 24 * Double(k))], mid) }

        // What each eye has caught, in its pupil: a mouse; a bat; in the water, a frog and a dragonfly.
        let mouse = eyes[0] + P(0.018, -0.04)
        s.append(stroke(ellipse(mouse, 0.03, 0.017, 20), 0.0036))
        s.append(stroke(circle(mouse + P(0.02, -0.018), 0.009, 10), 0.003))
        s.append(stroke(circle(mouse + P(0.024, -0.003), 0.0025, 6), 0.003))
        s.append(stroke(curve(mouse + P(-0.03, 0.004), mouse + P(-0.06, 0.03), mouse + P(-0.07, -0.01), 8), 0.0024))
        for dx in [-0.015, 0.012] { s.append(stroke([mouse + P(dx, 0.016), mouse + P(dx - 0.004, 0.026)], 0.0024)) }
        let bat = eyes[1] + P(-0.01, -0.045)
        for side in [-1.0, 1.0] {
            let w = { (x: Double, y: Double) in bat + P(side * x, y) }
            s.append(stroke(curve(w(0, 0), w(0.03, -0.03), w(0.07, -0.01), 8) + curve(w(0.07, -0.01), w(0.058, 0.006), w(0.05, 0.004), 4)
                + curve(w(0.05, 0.004), w(0.04, 0.016), w(0.028, 0.008), 4) + curve(w(0.028, 0.008), w(0.016, 0.018), w(0.008, 0.01), 4), 0.0034))
        }
        s.append(stroke([bat + P(-0.008, -0.004), bat + P(-0.006, -0.016), bat + P(0, -0.008), bat + P(0.006, -0.016), bat + P(0.008, -0.004)], 0.003))
        s.append(stroke(ellipse(bat + P(0, 0.004), 0.008, 0.012, 10), 0.003))
        let frog = P(-0.485, 0.28) + P(0.02, 0.04)
        s.append(stroke(arc(frog, 0.032, 190, 350, 14) + [frog + P(0.032, 0.0), frog + P(-0.032, 0.0)], 0.0036))
        for dx in [-0.018, 0.018] {
            s.append(stroke(circle(frog + P(dx, -0.026), 0.009, 10), 0.003))
            s.append(stroke(circle(frog + P(dx, -0.026), 0.002, 4), 0.003))
        }
        s.append(stroke(curve(frog + P(-0.02, -0.006), frog + P(0, 0.004), frog + P(0.02, -0.006), 6), 0.0024))
        for dx in [-1.0, 1.0] { s.append(stroke([frog + P(0.026 * dx, 0.0), frog + P(0.04 * dx, 0.02), frog + P(0.05 * dx, 0.018)], 0.0024)) }
        let fly = P(0.485, 0.28) + P(-0.03, 0.03)
        s.append(stroke([fly + P(-0.05, 0.03), fly + P(0.02, -0.012)], 0.0034))
        s.append(stroke(circle(fly + P(0.028, -0.017), 0.007, 8), 0.003))
        for (w, t) in [(0.05, -60.0), (0.046, -100), (0.044, 20), (0.04, 60)] {
            let root = fly + P(0.006, -0.004)
            s.append(stroke(ellipse(polar(root, w / 2, t - 30), w / 2, 0.008, degrees: t - 30, 14), 0.0024))
        }
        return Halftone.Panel(name: "owl", tones: { p in
            guard p.y > water else { return above(p) }
            for f in pads where f.holds(p) { return f.tone }
            // Under the waterline, the owl again, mirrored, shaken sideways by the ripples, and gone cool.
            let q = P(p.x + 0.01 * sin(p.y * 2 * .pi / 0.09), 2 * water - p.y), t = above(q)
            return Tone(min(0.3 * t.x + 0.35 * t.y + 0.9 * t.z, 1), 0.6 * t.y, 0)
        }, strokes: s)
    }()
}
