// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 1 to 6, the first chapter.

// MARK: - 1: Keyhole

/// Level 1's name, drawn: a door's lock plate, its keyhole in the top core (tri's lens), and through the keyhole an eye
/// looking back. Level 1 deals the lens +2, so the eye opens the level at x4, above the knob, which covers the core's
/// centre.
extension LensArt {
    static let keyhole: Halftone.Panel = {
        let plate = closed(arc(P(0, -0.7), 0.13, 180, 360, 24) + [P(0.13, -0.12)] + arc(P(0, -0.12), 0.13, 0, 180, 24)
            + [P(-0.13, -0.7)])
        let hole = P(0, -0.475)
        let opening = closed(arc(hole, 0.036, 120, 420, 36) + [hole + P(0.032, 0.11), hole + P(-0.032, 0.11)])
        let lever = closed([P(0.04, -0.69), P(0.46, -0.72), P(0.5, -0.69), P(0.46, -0.64), P(0.04, -0.63)])
        let door = rect(-0.82, -1.2, 0.82, 1.2)
        let panels = [rect(-0.7, -1.1, -0.2, -0.05), rect(0.2, -1.1, 0.7, -0.05), rect(-0.7, 0.08, -0.2, 1.1),
                      rect(0.2, 0.08, 0.7, 1.1)]
        let key = P(-0.45, 0.42)

        let tones: @Sendable (P) -> SIMD3<Double> = { p in
            if inside(p, opening) { return .zero }
            if inside(p, lever) { return y(p.y < -0.67 ? 0.85 : 0.5) }
            if simd_distance(p, P(0, -0.66)) < 0.065 { return y(0.8) }
            if inside(p, plate) { return p.x > 0.05 ? SIMD3(0, 0.22, 0.55) : y(0.65) }
            if distance(p, [key, key + P(0, 0.06)]) < 0.02 || simd_distance(p, key + P(0, 0.12)) < 0.05 { return y(0.6) }
            if inside(p, door) {
                for r in panels where inside(p, r) { return y(0.2) }
                return y(0.32)
            }
            return m(0.3)
        }

        var s: [Halftone.Stroke] = []
        // The door: its edges, raised panels and their bevels, and grain.
        s.append(stroke([P(-0.82, -1.2), P(-0.82, 1.2)], bold))
        s.append(stroke([P(0.82, -1.2), P(0.82, 1.2)], bold))
        for r in panels {
            s.append(stroke(closed(r), mid))
            let inset = rect(r[0].x + 0.05, r[0].y + 0.05, r[2].x - 0.05, r[2].y - 0.05)
            s.append(stroke(closed(inset), hair))
            for k in 0..<4 { s.append(stroke([r[k], inset[k]], hair)) }
        }
        for k in 0..<9 {
            let x = -0.66 + 0.15 * Double(k) + (k > 4 ? 0.12 : 0)
            guard abs(x) > 0.17 else { continue }
            s.append(stroke(curve(P(x, 0.14), P(x + 0.015 * Double(k % 3 - 1), 0.6), P(x - 0.01, 1.05), 16), hair))
        }
        // The lock plate, its screws (turned apart), the lever and its rose.
        s.append(stroke(plate, bold))
        s.append(stroke(closed(arc(P(0, -0.7), 0.105, 180, 360, 24) + [P(0.105, -0.12)] + arc(P(0, -0.12), 0.105, 0, 180, 24)
            + [P(-0.105, -0.7)]), hair))
        for (c, a) in [(P(0, -0.78), 20.0), (P(0, -0.18), 75.0)] {
            s.append(stroke(circle(c, 0.018, 16), mid))
            let u = P(cos(a * .pi / 180), sin(a * .pi / 180))
            s.append(stroke([c - 0.014 * u, c + 0.014 * u], mid))
        }
        s.append(stroke(circle(P(0, -0.66), 0.065, 32), bold))
        s.append(stroke(closed(lever), bold))
        s.append(stroke([P(0.12, -0.665), P(0.44, -0.69)], hair))
        // The keyhole, and through it the eye looking back: lid, lashes, iris rings and a catchlight, in hairline.
        s.append(stroke(opening, mid))
        let eye = hole + P(0.002, 0.002)
        s.append(stroke(curve(eye + P(-0.026, 0), eye + P(0, -0.024), eye + P(0.026, 0.002), 16), 0.0016))
        s.append(stroke(curve(eye + P(-0.026, 0), eye + P(0, 0.02), eye + P(0.026, 0.002), 16), 0.0016))
        for (k, r) in [0.0105, 0.0075].enumerated() {
            s.append(stroke(circle(eye + P(0.004, 0.0), r, 20), k == 0 ? 0.0016 : 0.0012))
        }
        s.append(stroke(circle(eye + P(0.004, 0), 0.0035, 12), 0.003))
        s.append(stroke(circle(eye + P(0.007, -0.004), 0.0012, 8), 0.0014))
        for k in 0..<5 {
            let x = -0.018 + 0.009 * Double(k), top = eye + P(x, -0.012 - 0.004 * (1 - abs(x) / 0.026) * 2)
            s.append(stroke([top, top + P(0.002 * Double(k - 2), -0.006)], 0.0012))
        }
        s.append(stroke(curve(eye + P(-0.03, -0.017), eye + P(-0.005, -0.028), eye + P(0.024, -0.019), 12), 0.0014))
        // A key on a nail, bottom left, that doesn't fit.
        s.append(stroke(circle(key + P(0, -0.04), 0.01, 10), mid))
        s.append(stroke([key + P(0, -0.03), key], hair))
        s.append(stroke(circle(key + P(0, 0.12), 0.05, 32), mid))
        s.append(stroke(circle(key + P(0, 0.12), 0.022, 20), hair))
        s.append(stroke([key + P(0, 0.17), key + P(0, 0.42)], bold))
        s.append(stroke([key + P(0, 0.36), key + P(0.06, 0.36), key + P(0.06, 0.4)], mid))
        s.append(stroke([key + P(0, 0.3), key + P(0.045, 0.3)], mid))
        return Halftone.Panel(name: "keyhole", tones: tones, strokes: s)
    }()
}

// MARK: - 2: Peephole

/// Level 2's name: a front door, its peephole in the top core (tri's lens), and in the peephole's glass the caller on
/// the step, hat on and flowers in hand, bowed as the glass bows him. Level 2 deals the lens +1, so the caller opens the
/// level at x2, above the knob.
extension LensArt {
    static let peephole: Halftone.Panel = {
        let eye = P(0, -0.52)
        let panels = [rect(-0.6, -1.1, -0.17, -0.02), rect(0.17, -1.1, 0.6, -0.02), rect(-0.6, 0.5, -0.07, 1.1),
                      rect(0.07, 0.5, 0.6, 1.1)]
        let slot = rect(-0.26, 0.2, 0.26, 0.32), knob = P(0.5, 0.1), knocker = P(0, -0.2)
        let chain = curve(P(0.72, -0.2), P(0.56, 0.02), P(0.38, -0.14), 20)
        var fills = [disc(eye, 0.062, .zero), disc(eye, 0.1, y(0.8)), disc(knob, 0.06, y(0.85)), disc(knob, 0.09, y(0.5)),
                     fill(rect(-0.2, 0.26, 0.2, 0.3), .zero), fill(slot, y(0.75)), disc(knocker + P(0, -0.07), 0.04, y(0.8)),
                     disc(knocker + P(0, 0.075), 0.028, y(0.8)), fill(rect(0.3, -0.19, 0.44, -0.1), y(0.7)),
                     fill(rect(-0.75, 0.83, 0.75, 1.1), c(0.45))]
        fills += panels.map { fill($0, m(0.2)) }
        fills.append(fill(rect(-0.72, -1.1, 0.72, 0.83), m(0.36)))

        var s: [Halftone.Stroke] = []
        // The door, its four panels and their bevels, and the bricks either side.
        for x in [-0.72, 0.72] { s.append(stroke([P(x, -1.1), P(x, 0.83)], bold)) }
        for r in panels {
            s.append(stroke(closed(r), mid))
            let inset = rect(r[0].x + 0.045, r[0].y + 0.045, r[2].x - 0.045, r[2].y - 0.045)
            s.append(stroke(closed(inset), hair))
            for k in 0..<4 { s.append(stroke([r[k], inset[k]], hair)) }
        }
        for k in 0..<9 {
            let yy = -0.62 + 0.16 * Double(k)
            for side in [-1.0, 1.0] {
                s.append(stroke([P(side * 0.72, yy), P(side * 1.0, yy)], hair))
                s.append(stroke([P(side * (k % 2 == 0 ? 0.84 : 0.92), yy), P(side * (k % 2 == 0 ? 0.84 : 0.92), yy + 0.16)], hair))
            }
        }
        // The peephole: its brass ring, the glass, and the caller, bowed by it: head, bowler, shoulders, a bunch of
        // flowers held up, and the path running away behind.
        s.append(stroke(circle(eye, 0.1, 40), bold))
        s.append(stroke(circle(eye, 0.062, 32), mid))
        let head = eye + P(-0.006, -0.016)
        s.append(stroke(circle(head, 0.015, 16), 0.002))
        s.append(stroke(arc(head + P(0, -0.008), 0.016, 180, 360, 10), 0.002))
        s.append(stroke([head + P(-0.027, -0.008), head + P(0.027, -0.008)], 0.002))
        s.append(stroke(curve(head + P(-0.04, 0.062), head + P(-0.03, 0.018), head + P(0, 0.016), 10)
            + curve(head + P(0, 0.016), head + P(0.03, 0.018), head + P(0.04, 0.062), 10), 0.002))
        s.append(stroke([head + P(-0.006, -0.002), head + P(-0.004, -0.002)], 0.002))
        s.append(stroke([head + P(0.004, -0.002), head + P(0.006, -0.002)], 0.002))
        s.append(stroke(arc(head + P(0, 0.002), 0.007, 30, 150, 6), 0.0014))
        let bunch = head + P(0.034, 0.012)
        s.append(stroke([bunch + P(-0.004, 0.036), bunch], 0.0016))
        for k in 0..<3 { s.append(stroke(star(bunch + P(0.009 * Double(k - 1), -0.004 - (k == 1 ? 0.007 : 0)), 0.006), 0.0012)) }
        s.append(stroke(curve(eye + P(-0.058, -0.012), eye + P(-0.03, -0.026), eye + P(-0.024, -0.03), 6), 0.0012))
        s.append(stroke(curve(eye + P(0.058, -0.012), eye + P(0.04, -0.022), eye + P(0.03, -0.028), 6), 0.0012))
        // The knocker: a ring hung from a boss, over its strike plate.
        s.append(stroke(circle(knocker + P(0, -0.07), 0.04, 20), mid))
        s.append(stroke(arc(knocker, 0.075, -60, 240, 32), bold))
        s.append(stroke(circle(knocker + P(0, 0.075), 0.028, 16), mid))
        // The letter slot and its flap, the knob on its rose, and the chain, off its catch.
        s.append(stroke(closed(slot), bold))
        s.append(stroke(closed(rect(-0.2, 0.26, 0.2, 0.3)), hair))
        for x in [-0.235, 0.235] { s.append(stroke(circle(P(x, 0.26), 0.008, 8), hair)) }
        s.append(stroke(circle(knob, 0.09, 32), mid))
        s.append(stroke(circle(knob, 0.06, 28), bold))
        s.append(stroke(arc(knob, 0.04, 200, 280, 8), hair))
        s.append(stroke(closed(rect(0.3, -0.19, 0.44, -0.1)), mid))
        s.append(stroke([P(0.33, -0.145), P(0.41, -0.145)], hair))
        s.append(stroke(chain, mid))
        for k in stride(from: 2, to: 20, by: 3) { s.append(stroke(circle(chain[k], 0.012, 8), hair)) }
        s.append(stroke(circle(P(0.72, -0.2), 0.018, 10), mid))
        // The mat.
        s.append(stroke([P(-0.75, 0.83), P(0.75, 0.83)], bold))
        for k in 0..<9 { s.append(stroke([P(-0.6 + 0.15 * Double(k), 0.86), P(-0.66 + 0.165 * Double(k), 1.0)], hair)) }
        return panel("peephole", fills: fills, strokes: s) { p in abs(p.x) > 0.72 ? c(0.22) : .zero }
    }()
}

// MARK: - 3: Magnifying glass

/// Level 3's name: a magnifying glass laid on a fingerprint card, its glass over the top core (tri's lens), and under
/// it, among the print's ridges, an ant. Level 3 deals the lens +3, so the ant opens the level at
/// x8, beside the knob.
extension LensArt {
    static let magnifier: Halftone.Panel = {
        let glass = P(0, -0.42), grip = 52.0
        let card = [P(-0.86, -0.78), P(0.62, -0.96), P(0.7, -0.02), P(-0.78, 0.16)]
        let print = P(-0.02, -0.46)
        let pad = [P(-0.72, 0.32), P(-0.22, 0.26), P(-0.18, 0.6), P(-0.68, 0.66)]
        let ink = [P(-0.66, 0.37), P(-0.27, 0.32), P(-0.24, 0.55), P(-0.63, 0.6)]
        let handle = bar(polar(glass, 0.5, grip), polar(glass, 1.2, grip), 0.11)
        let ferrule = bar(polar(glass, 0.4, grip), polar(glass, 0.5, grip), 0.085)
        let lamp = [P(-1.2, -1.2), P(0.25, -1.2), P(1.2, 0.5), P(1.2, 1.2), P(-1.2, 1.2)]
        let fills = [fill(handle, m(0.6)), fill(ferrule, y(0.8)), oval(print, 0.21, 0.25, m(0.24)), disc(glass, 0.36, c(0.12)),
                     disc(glass, 0.4, y(0.8)), fill(ink, m(0.75)), fill(pad, y(0.55)), oval(P(0.3, 0.72), 0.1, 0.12, m(0.22)),
                     fill(card, y(0.1)), fill(lamp, y(0.2))]

        var s: [Halftone.Stroke] = []
        // The ant, off with a crumb: three beads, six legs, two feelers, drawn bold enough for x8.
        let ant = glass + P(0.024, -0.024), along = P(cos(-0.5), sin(-0.5)), up = P(sin(-0.5), -cos(-0.5))
        // The card and its print: whorls that open to one side and part round the ant, and a second, smudged, off the card.
        s.append(stroke(closed(card), mid))
        for k in 0..<12 {
            let r = 0.016 + 0.017 * Double(k)
            s += runs(ellipse(print, r * 0.84, r, degrees: 14, 44).dropLast(5 + k % 4).map { $0 }) { simd_distance($0, ant) > 0.034 }
        }
        for k in 0..<5 {
            let r = 0.03 + 0.02 * Double(k)
            s.append(stroke(ellipse(P(0.3, 0.72), r * 0.8, r, degrees: -30, 30).dropLast(8 + 2 * (k % 3)).map { $0 }, hair))
        }
        for (k, r) in [0.006, 0.0035, 0.005].enumerated() {
            s.append(stroke(circle(ant + along * (0.0125 * Double(k - 1)), r, 10), 0.005))
        }
        for k in 0..<3 {
            let root = ant + along * (0.007 * Double(k - 1))
            for side in [-1.0, 1.0] {
                s.append(stroke([root, root + up * (side * 0.012) + along * (0.007 * Double(k - 1)),
                                 root + up * (side * 0.02) + along * (0.013 * Double(k - 1) - 0.004)], 0.0024))
            }
        }
        let face = ant + along * 0.02
        s.append(stroke([face, face + along * 0.009 + up * 0.009], 0.002))
        s.append(stroke([face, face + along * 0.012 - up * 0.004], 0.002))
        // The glass: its rim inside and out, a streak of light, the ferrule and the handle's turned end.
        s.append(stroke(circle(glass, 0.4, 72), bold))
        s.append(stroke(circle(glass, 0.36, 72), mid))
        s.append(stroke(arc(glass, 0.31, 200, 250, 12), mid))
        s.append(stroke(arc(glass, 0.31, 258, 268, 4), mid))
        s.append(stroke(closed(ferrule), mid))
        s.append(stroke(closed(handle), bold))
        for t in [0.6, 0.64, 1.1] { s.append(stroke(bar(polar(glass, t, grip), polar(glass, t + 0.001, grip), 0.11).prefix(2) + [], hair)) }
        // The ink pad in its tin, a thumb's dab on it, and the lamp's edge.
        s.append(stroke(closed(pad), bold))
        s.append(stroke(closed(ink), mid))
        s.append(stroke(ellipse(P(-0.45, 0.46), 0.06, 0.08, degrees: 10, 20), hair))
        s.append(stroke(ellipse(P(-0.45, 0.46), 0.03, 0.045, degrees: 10, 16), hair))
        s.append(stroke([P(0.25, -1.2), P(1.2, 0.5)], hair))
        return panel("magnifier", fills: fills, strokes: s) { _ in c(0.14) }
    }()
}

// MARK: - 4: Monocle

/// Level 4's name: a gentleman close up, top hat down to moustache, his monocle over the lower right core (tri's lens
/// on this level), and behind its glass his eye, the pupil a heart. Level 4 deals the lens +2 then +1.
extension LensArt {
    static let monocle: Halftone.Panel = {
        let glass = P(0.3637, 0.21), other = P(-0.3637, 0.21), eye = glass + P(-0.005, -0.012)
        let crown = rect(-0.62, -1.2, 0.62, -0.5), band = rect(-0.62, -0.66, 0.62, -0.5)
        let whisker = [curve(P(0, 0.7), P(-0.3, 0.86), P(-0.62, 0.62), 16) + curve(P(-0.62, 0.62), P(-0.36, 0.7), P(0, 0.62), 16),
                       curve(P(0, 0.7), P(0.3, 0.86), P(0.62, 0.62), 16) + curve(P(0.62, 0.62), P(0.36, 0.7), P(0, 0.62), 16)]
        // A heavy brow and a flushed cheek on the bare side, so the left rod's twist shows without the eye's lines.
        let brow = bar(P(-0.6, 0.0), P(-0.2, -0.09), 0.07)
        let fills = [disc(glass, 0.265, c(0.1)), disc(glass, 0.305, y(0.85)), fill(whisker[0], m(0.75)), fill(whisker[1], m(0.75)),
                     fill(band, m(0.7)), fill(crown, c(0.5)), oval(P(0, -0.46), 0.98, 0.1, c(0.75)),
                     fill(brow, m(0.75)), disc(P(-0.52, 0.45), 0.11, Tone(0, 0.5, 0.3)),
                     oval(P(0, 0.3), 0.8, 1.0, y(0.3))]

        var s: [Halftone.Stroke] = []
        // The hat: crown, band and its buckle, and the brim's two edges.
        s.append(stroke([P(-0.62, -1.2), P(-0.62, -0.5)], bold))
        s.append(stroke([P(0.62, -1.2), P(0.62, -0.5)], bold))
        s.append(stroke([P(-0.62, -0.66), P(0.62, -0.66)], mid))
        s.append(stroke(closed(rect(-0.3, -0.64, -0.16, -0.52)), mid))
        s.append(stroke([P(-0.23, -0.64), P(-0.23, -0.52)], hair))
        s.append(stroke(ellipse(P(0, -0.46), 0.98, 0.1), bold))
        // The face: its sides, the bare eye and both brows, one raised, the nose and the moustache.
        s.append(stroke(squash(arc(P(0, 0.3), 0.8, 150, 208, 16), about: 0.3, by: 1.25), mid))
        s.append(stroke(squash(arc(P(0, 0.3), 0.8, -28, 30, 16), about: 0.3, by: 1.25), mid))
        s.append(stroke(curve(other + P(-0.13, 0.01), other + P(0, -0.1), other + P(0.13, 0.02), 16), mid))
        s.append(stroke(curve(other + P(-0.13, 0.01), other + P(0, 0.08), other + P(0.13, 0.02), 16), hair))
        s.append(stroke(circle(other + P(0.01, -0.005), 0.045, 20), mid))
        s.append(stroke(circle(other + P(0.01, -0.005), 0.014, 10), 0.012))
        s.append(stroke(curve(other + P(-0.2, -0.12), other + P(-0.02, -0.2), other + P(0.17, -0.1), 12), bold))
        s.append(stroke(curve(glass + P(-0.2, -0.33), glass + P(0, -0.44), glass + P(0.22, -0.36), 12), bold))
        s.append(stroke(curve(P(-0.05, 0.12), P(-0.1, 0.42), P(-0.1, 0.5), 10) + curve(P(-0.1, 0.5), P(0, 0.6), P(0.1, 0.5), 10), mid))
        s.append(stroke(arc(P(-0.05, 0.5), 0.03, 200, 340, 6), hair))
        for w in whisker { s.append(stroke(closed(w), mid)) }
        for k in 0..<4 {
            let x = 0.1 + 0.11 * Double(k)
            for side in [-1.0, 1.0] { s.append(stroke(curve(P(side * x, 0.66), P(side * (x + 0.06), 0.73), P(side * (x + 0.1), 0.66), 6), hair)) }
        }
        // The monocle: rim, a streak on the glass, and its cord down to the waistcoat.
        s.append(stroke(circle(glass, 0.305, 64), bold))
        s.append(stroke(circle(glass, 0.265, 64), mid))
        s.append(stroke(arc(glass, 0.225, 195, 240, 10), mid))
        s.append(stroke(curve(polar(glass, 0.305, 60), P(0.86, 0.7), P(0.62, 1.0), 20), mid))
        // The eye behind it, larger than the other: lids, lashes, the iris and, for a pupil, a heart.
        s.append(stroke(curve(eye + P(-0.15, 0.02), eye + P(0, -0.13), eye + P(0.15, 0.03), 20), mid))
        s.append(stroke(curve(eye + P(-0.15, 0.02), eye + P(0, 0.1), eye + P(0.15, 0.03), 20), hair))
        for k in 0..<5 {
            let x = -0.09 + 0.045 * Double(k), top = eye + P(x, -0.052 + 0.5 * x * x * 12)
            s.append(stroke([top, top + P(0.012 * Double(k - 2), -0.03)], hair))
        }
        s.append(stroke(circle(eye, 0.058, 28), 0.003))
        for k in 0..<10 { s.append(stroke([polar(eye, 0.044, 36 * Double(k) + 8), polar(eye, 0.055, 36 * Double(k) + 8)], 0.0016)) }
        let heart = eye + P(0.016, -0.014)
        s.append(stroke(closed(arc(heart + P(-0.008, -0.004), 0.008, 150, 360, 8) + arc(heart + P(0.008, -0.004), 0.008, 180, 390, 8)
            + [heart + P(0, 0.016)]), 0.0042))
        return panel("monocle", fills: fills, strokes: s) { _ in m(0.26) }
    }()
}

// MARK: - 5: Goggles

/// Level 5's name: a skier face on, the goggles' one wide lens over the top core (eye's small lens on this level), and
/// mirrored in it the mountain, the sun and a skier coming down. Level 5 deals the lens +2, so the run opens at x4.
extension LensArt {
    static let goggles: Halftone.Panel = {
        let lens = P(0, -0.56)
        let peaks = [P(-0.43, -0.5), P(-0.32, -0.62), P(-0.2, -0.5), P(0.04, -0.72), P(0.26, -0.48), P(0.36, -0.56), P(0.44, -0.5),
                     P(0.3, -0.4), P(0.16, -0.36), P(0, -0.44), P(-0.16, -0.36), P(-0.3, -0.4)]
        let scarf = [P(-0.5, 0.5), P(0.5, 0.42), P(0.54, 0.66), P(-0.52, 0.76)]
        // The lens's outline, dipped over the nose.
        func visor(_ rx: Double, _ ry: Double) -> [P] {
            ellipse(lens, rx, ry, 64).map { $0.y > lens.y && abs($0.x) < 0.16 ? P($0.x, $0.y - 0.09 * (1 - abs($0.x) / 0.16)) : $0 }
        }
        var fills = [fill(peaks, m(0.4)), fill(visor(0.47, 0.215), c(0.55)), fill(visor(0.53, 0.275), .zero),
                     fill(rect(-1, -0.66, -0.5, -0.46), y(0.7)), fill(rect(0.5, -0.66, 1, -0.46), y(0.7))]
        for k in 0..<5 {
            let x = -0.5 + 0.2 * Double(k), top = 0.5 - 0.016 * Double(k), foot = 0.74 - 0.02 * Double(k)
            let stripe: [P] = [P(x, top), P(x + 0.2, top - 0.016), P(x + 0.23, foot - 0.02), P(x + 0.03, foot)]
            fills.append(fill(stripe, k % 2 == 0 ? m(0.7) : y(0.6)))
        }
        fills += [fill(scarf, y(0.6)), fill([P(0.14, 0.6), P(0.36, 0.58), P(0.5, 1.1), P(0.2, 1.1)], m(0.7)),
                  disc(P(-0.25, 0.1), 0.07, m(0.5)), disc(P(0.25, 0.1), 0.07, m(0.5)), oval(P(0, 0.06), 0.44, 0.52, y(0.3)),
                  disc(P(0, -0.32), 0.74, m(0.5)),
                  fill([P(-1.1, 1.2), P(-0.62, 0.62), P(0.62, 0.62), P(1.1, 1.2)], c(0.6))]

        var s: [Halftone.Stroke] = []
        // The helmet, its vents, the strap either side and the face in its opening.
        s.append(stroke(arc(P(0, -0.32), 0.74, 150, 390, 64), bold))
        for k in 0..<3 { s.append(stroke(bar(P(-0.16 + 0.16 * Double(k), -0.98), P(-0.16 + 0.16 * Double(k), -0.88), 0.05), hair)) }
        for side in [-1.0, 1.0] {
            s.append(stroke([P(side * 0.5, -0.66), P(side * 1, -0.66)], mid))
            s.append(stroke([P(side * 0.5, -0.46), P(side * 1, -0.46)], mid))
            s.append(stroke(closed(rect(min(side * 0.6, side * 0.68), -0.62, max(side * 0.6, side * 0.68), -0.5)), hair))
        }
        s.append(stroke(squash(arc(P(0, 0.06), 0.44, 20, 160, 24), about: 0.06, by: 1.18), mid))
        s.append(stroke(curve(P(-0.03, -0.22), P(-0.07, -0.02), P(-0.06, 0.04), 8) + curve(P(-0.06, 0.04), P(0, 0.1), P(0.06, 0.04), 8), mid))
        s.append(stroke(curve(P(-0.16, 0.22), P(0.02, 0.36), P(0.2, 0.2), 12), mid))
        s.append(stroke([P(0.2, 0.2), P(0.23, 0.17)], hair))
        // The goggles: frame and lens, a streak, and the mountain in it: ridge, snow line, sun, and the skier's track.
        s.append(stroke(visor(0.53, 0.275), bold))
        s.append(stroke(visor(0.47, 0.215), mid))
        for x in [-0.3, -0.2, 0.2, 0.3] { s.append(stroke([P(x, -0.79 + 0.1 * abs(x)), P(x, -0.755 + 0.1 * abs(x))], mid)) }
        s.append(stroke(Array(peaks[0...6]), mid))
        s.append(stroke([P(-0.37, -0.55), P(-0.33, -0.57), P(-0.3, -0.54), P(-0.26, -0.57)], hair))
        s.append(stroke([P(-0.05, -0.63), P(0.0, -0.66), P(0.03, -0.62), P(0.07, -0.66), P(0.12, -0.63)], hair))
        s.append(stroke(circle(P(-0.17, -0.67), 0.03, 14), hair))
        for k in 0..<8 { s.append(stroke([polar(P(-0.17, -0.67), 0.04, 45 * Double(k)), polar(P(-0.17, -0.67), 0.055, 45 * Double(k))], hair)) }
        let track = curve(P(0.045, -0.7), P(0.11, -0.64), P(0.04, -0.6), 10) + curve(P(0.04, -0.6), P(-0.03, -0.56), P(0.03, -0.52), 10)
        s.append(stroke(track, 0.0016))
        let skier = P(0.036, -0.515)
        s.append(stroke(circle(skier + P(0.002, -0.022), 0.005, 8), 0.003))
        s.append(stroke([skier + P(0.002, -0.016), skier + P(-0.003, -0.006), skier + P(0.005, 0.002)], 0.0024))
        s.append(stroke([skier + P(-0.012, 0.0), skier + P(0.02, 0.008)], 0.0024))
        s.append(stroke([skier + P(0.0, -0.012), skier + P(0.014, -0.006), skier + P(0.018, 0.006)], 0.0016))
        s.append(stroke([skier + P(0.0, -0.012), skier + P(-0.012, -0.008), skier + P(-0.016, 0.004)], 0.0016))
        // The scarf, its stripes and its end, and the jacket's collar and zip.
        s.append(stroke(closed(scarf), bold))
        for k in 1..<5 {
            let x = -0.5 + 0.2 * Double(k)
            s.append(stroke([P(x, 0.5 - 0.016 * Double(k)), P(x + 0.03, 0.74 - 0.02 * Double(k))], hair))
        }
        s.append(stroke(closed([P(0.14, 0.6), P(0.36, 0.58), P(0.5, 1.1), P(0.2, 1.1)]), mid))
        for k in 0..<4 {
            let x = 0.2 + 0.03 * Double(k), yy = 0.76 + 0.09 * Double(k)
            s.append(stroke([P(x, yy), P(x + 0.2, yy - 0.02)], hair))
        }
        s.append(stroke([P(-0.62, 0.62), P(-1.1, 1.2)], bold))
        s.append(stroke([P(0.62, 0.62), P(1.1, 1.2)], bold))
        s.append(stroke([P(-0.06, 0.74), P(-0.1, 1.1)], mid))
        // Snow.
        for (k, at) in [P(-0.86, -0.2), P(-0.72, 0.2), P(0.84, -0.1), P(0.76, 0.34), P(-0.9, 0.42), P(0.9, -0.34)].enumerated() {
            for j in 0..<3 { s.append(stroke([polar(at, 0.035, 60 * Double(j) + 20 * Double(k)), polar(at, -0.035, 60 * Double(j) + 20 * Double(k))], hair)) }
        }
        return panel("goggles", fills: fills, strokes: s) { _ in c(0.16) }
    }()
}

// MARK: - 6: Spyglass

/// Level 6's name: a pirate, spyglass up and aimed at us, its big end over the left core (eye's big lens on this
/// level), and in the glass the ship he has sighted, a cross on her flag. Level 6 deals the lens +2 then +1.
extension LensArt {
    static let spyglass: Halftone.Panel = {
        let rings: [(c: P, r: Double)] = [(P(-0.4, 0), 0.31), (P(-0.04, -0.07), 0.2), (P(0.2, -0.12), 0.135), (P(0.36, -0.15), 0.09)]
        let glass = rings[0].c
        func tube(_ k: Int) -> [P] {
            let a = rings[k], b = rings[k + 1], u = simd_normalize(b.c - a.c), n = P(-u.y, u.x)
            return [a.c + n * a.r * 0.82, b.c + n * b.r, b.c - n * b.r, a.c - n * a.r * 0.82]
        }
        let hat = [P(-0.2, -0.4), P(0.1, -0.56), P(0.42, -0.9), P(0.74, -0.56), P(1.02, -0.42), P(0.8, -0.34), P(0.42, -0.46),
                   P(0.04, -0.32)]
        let patch = [P(0.52, -0.2), P(0.74, -0.24), P(0.76, -0.06), P(0.64, 0.02), P(0.52, -0.06)]
        let beard = [P(0.06, 0.16), P(0.16, 0.34), P(0.24, 0.26), P(0.32, 0.46), P(0.42, 0.3), P(0.52, 0.48), P(0.6, 0.28),
                     P(0.7, 0.4), P(0.78, 0.12), P(0.42, 0.2)]
        let coat = [P(-0.3, 1.2), P(-0.1, 0.56), P(0.2, 0.4), P(0.7, 0.42), P(1.1, 0.7), P(1.1, 1.2)]
        var fills = [disc(glass, 0.26, c(0.22)), disc(glass, 0.31, y(0.85))]
        for k in 0..<3 { fills += [fill(tube(k), y(k == 1 ? 0.35 : 0.5)), disc(rings[k + 1].c, rings[k + 1].r, y(0.8))] }
        fills += [fill(hat, m(0.75)), fill(patch, m(0.8)), fill(beard, m(0.45)), disc(P(0.42, -0.1), 0.42, y(0.3)),
                  fill([P(0.2, 0.4), P(0.42, 0.9), P(0.62, 0.42)], y(0.2)), fill(coat, c(0.6))]

        var s: [Halftone.Stroke] = []
        // The hat with its badge, the head, the patch on its strap, an earring, the beard and the coat.
        s.append(stroke(closed(hat), bold))
        s.append(stroke(circle(P(0.42, -0.64), 0.06, 20), mid))
        s.append(stroke([P(0.37, -0.69), P(0.47, -0.59)], hair))
        s.append(stroke([P(0.47, -0.69), P(0.37, -0.59)], hair))
        s.append(stroke(arc(P(0.42, -0.1), 0.42, -40, 60, 24), mid))
        s.append(stroke(closed(patch), mid))
        s.append(stroke([P(0.2, -0.36), P(0.52, -0.2)], hair))
        s.append(stroke([P(0.76, -0.2), P(0.83, -0.22)], hair))
        s.append(stroke(circle(P(0.86, 0.02), 0.04, 14), mid))
        s.append(stroke(closed(beard), mid))
        s.append(stroke(curve(P(0.36, 0.1), P(0.5, 0.2), P(0.66, 0.06), 10), mid))
        s.append(stroke([P(-0.1, 0.56), P(0.2, 0.4), P(0.42, 0.9), P(0.62, 0.42), P(0.7, 0.42), P(1.1, 0.7)], bold))
        s.append(stroke([P(-0.1, 0.56), P(-0.3, 1.2)], bold))
        for k in 0..<3 { s.append(stroke(circle(P(0.12 + 0.07 * Double(k), 0.7 + 0.14 * Double(k)), 0.03, 12), mid)) }
        // The spyglass: three draws and the eyepiece, each ring whole over the tube behind it, and the fingers round it.
        for k in (0..<3).reversed() {
            let t = tube(k)
            s.append(stroke([t[0], t[1]], bold))
            s.append(stroke([t[3], t[2]], bold))
            s += runs(circle(rings[k + 1].c, rings[k + 1].r, 40), mid) { simd_distance($0, rings[k].c) > rings[k].r }
        }
        for k in 0..<4 {
            let at = P(0.03 + 0.055 * Double(k), 0.12 - 0.012 * Double(k))
            s.append(stroke(ellipse(at, 0.03, 0.06, degrees: -12, 16), mid))
        }
        s.append(stroke(circle(glass, 0.31, 64), bold))
        s.append(stroke(circle(glass, 0.26, 64), mid))
        s.append(stroke(arc(glass, 0.22, 190, 235, 10), mid))
        // In the glass: the sea, and the ship: hull, mast, two sails and the flag with its cross.
        let ship = glass + P(0.012, -0.012)
        s.append(stroke(curve(glass + P(-0.25, 0.05), glass + P(-0.12, 0.02), glass + P(-0.045, 0.05), 8), hair))
        s.append(stroke(curve(glass + P(0.07, 0.05), glass + P(0.16, 0.02), glass + P(0.25, 0.05), 8), hair))
        s.append(stroke(curve(glass + P(-0.2, 0.12), glass + P(-0.08, 0.09), glass + P(0.03, 0.12), 8), hair))
        s.append(stroke(closed([ship + P(-0.03, 0.03), ship + P(0.036, 0.03), ship + P(0.028, 0.046), ship + P(-0.022, 0.046)]), 0.003))
        s.append(stroke([ship + P(0.002, 0.03), ship + P(0.002, -0.045)], 0.003))
        s.append(stroke(closed([ship + P(0.006, -0.03), ship + P(0.03, 0.02), ship + P(0.006, 0.02)]), 0.002))
        s.append(stroke(closed([ship + P(-0.003, -0.02), ship + P(-0.024, 0.02), ship + P(-0.003, 0.02)]), 0.002))
        let flag = rect(ship.x + 0.002, ship.y - 0.045, ship.x + 0.03, ship.y - 0.028)
        s.append(stroke(closed(flag), 0.002))
        s.append(stroke([flag[0], flag[2]], 0.0014))
        s.append(stroke([flag[1], flag[3]], 0.0014))
        // A gull and a cloud.
        s.append(stroke(curve(P(-0.72, -0.6), P(-0.66, -0.68), P(-0.6, -0.6), 8) + curve(P(-0.6, -0.6), P(-0.54, -0.68), P(-0.48, -0.6), 8), mid))
        s.append(stroke(arc(P(-0.3, -0.72), 0.07, 180, 360, 10) + arc(P(-0.18, -0.72), 0.05, 200, 360, 8), hair))
        s.append(stroke([P(-0.4, -0.72), P(-0.1, -0.72)], hair))
        return panel("spyglass", fills: fills, strokes: s) { p in p.y > 0.62 && p.x < -0.2 ? c(0.5) : c(0.2) }
    }()
}
