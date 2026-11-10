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
