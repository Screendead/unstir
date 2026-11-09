// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Lens's prototype panels, drawn the test panel's way (`Halftone.Panel`: tones in three dot screens under white
/// strokes) for Jack's call on what Lens ships with. Only the harness shows them (`UNSTIR_PANEL`); every level still
/// draws the test panel. Each puts its clue in the core of its level's lens, in hairline white finer than the screen,
/// since a tone region under one pitch prints no dot, and off the core's centre, which the lens's knob covers.
enum LensArt {
    typealias P = SIMD2<Double>

    static let panels: [Halftone.Panel] = [switch02, keyhole, closeup]

    static let bold = 0.008, mid = 0.005, hair = 0.0025

    // MARK: Drawing

    static func stroke(_ points: [P], _ width: Double = mid) -> Halftone.Stroke { Halftone.Stroke(points: points, width: width) }

    static func closed(_ points: [P]) -> [P] { points + [points[0]] }

    /// An arc from a0 to a1 degrees, 0 at three o'clock and clockwise on screen, as y runs down.
    static func arc(_ c: P, _ r: Double, _ a0: Double, _ a1: Double, _ n: Int = 32) -> [P] {
        (0...n).map { i in
            let a = (a0 + (a1 - a0) * Double(i) / Double(n)) * .pi / 180
            return c + r * P(cos(a), sin(a))
        }
    }

    static func circle(_ c: P, _ r: Double, _ n: Int = 48) -> [P] { arc(c, r, 0, 360, n) }

    static func ellipse(_ c: P, _ rx: Double, _ ry: Double, degrees: Double = 0, _ n: Int = 48) -> [P] {
        let t = degrees * .pi / 180
        return (0...n).map { i in
            let a = 2 * .pi * Double(i) / Double(n), e = P(rx * cos(a), ry * sin(a))
            return c + P(e.x * cos(t) - e.y * sin(t), e.x * sin(t) + e.y * cos(t))
        }
    }

    /// A quadratic Bézier from a to b pulled towards c.
    static func curve(_ a: P, _ c: P, _ b: P, _ n: Int = 24) -> [P] {
        (0...n).map { i in
            let t = Double(i) / Double(n)
            return (1 - t) * (1 - t) * a + 2 * (1 - t) * t * c + t * t * b
        }
    }

    /// A star of `points` points, its first ray at `degrees`.
    static func star(_ c: P, _ r: Double, points: Int = 5, inner: Double = 0.4, degrees: Double = -90) -> [P] {
        closed((0..<2 * points).map { i in
            let a = (degrees + 180 * Double(i) / Double(points)) * .pi / 180
            return c + (i % 2 == 0 ? r : r * inner) * P(cos(a), sin(a))
        })
    }

    /// A glint: four long rays and four short.
    static func glint(_ c: P, _ r: Double, _ width: Double = mid) -> [Halftone.Stroke] {
        (0..<8).map { k in
            let a = Double(k) * .pi / 4, l = k % 2 == 0 ? r : r * 0.45
            return stroke([c + 0.12 * r * P(cos(a), sin(a)), c + l * P(cos(a), sin(a))], width)
        }
    }

    static func inside(_ p: P, _ polygon: [P]) -> Bool { Halftone.inside(p, polygon) }

    static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> [P] {
        [P(x0, y0), P(x1, y0), P(x1, y1), P(x0, y1)]
    }

    static func distance(_ p: P, _ line: [P]) -> Double {
        var d = Double.infinity
        for j in 1..<line.count {
            let a = line[j - 1], ab = line[j] - a, h = min(max(simd_dot(p - a, ab) / simd_length_squared(ab), 0), 1)
            d = min(d, simd_distance(p, a + h * ab))
        }
        return d
    }

    /// Tones as (cyan, magenta, yellow).
    static func c(_ t: Double) -> SIMD3<Double> { SIMD3(t, 0, 0) }
    static func m(_ t: Double) -> SIMD3<Double> { SIMD3(0, t, 0) }
    static func y(_ t: Double) -> SIMD3<Double> { SIMD3(0, 0, t) }
}

// MARK: - A: The Switch, panel 2

/// "The Switch" panel 2 (`docs/lens-design.md` section 1): the blue diamond on its velvet stand in the gallery's case,
/// and on one facet, in the top core (tri's lens), the tiny star its forger scratched. Level 2 deals the lens +1, so the
/// star opens the level at x2.
extension LensArt {
    static let switch02: Halftone.Panel = {
        let table = (y: -0.62, x: 0.14), girdle = (y: -0.49, under: -0.47, x: 0.31), culet = P(0, -0.14)
        let crown = [P(-table.x, table.y), P(table.x, table.y), P(girdle.x, girdle.y), P(-girdle.x, girdle.y)]
        let diamond = [P(-table.x, table.y), P(table.x, table.y), P(girdle.x, girdle.y), P(girdle.x, girdle.under), culet,
                       P(-girdle.x, girdle.under), P(-girdle.x, girdle.y)]
        // The crown's facets: a zigzag between table and girdle.
        let zig: [P] = [P(-0.31, girdle.y), P(-0.14, table.y), P(-0.2, girdle.y), P(-0.07, table.y), P(-0.07, girdle.y),
                        P(0, table.y), P(0.07, girdle.y), P(0.07, table.y), P(0.2, girdle.y), P(0.14, table.y),
                        P(0.31, girdle.y)]
        let crownFacets = (0..<zig.count - 2).map { [zig[$0], zig[$0 + 1], zig[$0 + 2]] }
        let crownTones: [SIMD3<Double>] = [c(0.8), c(0.35), c(0.9), c(0.5), c(0.75), c(0.3), c(0.6), c(0.25), c(0.55)]
        let pavilionX = [-0.31, -0.2, -0.07, 0.07, 0.2, 0.31]
        let pavilion = (0..<5).map { [P(pavilionX[$0], girdle.under), P(pavilionX[$0 + 1], girdle.under), culet] }
        let pavilionTones: [SIMD3<Double>] = [c(0.7), c(0.4), c(0.6), m(0.45), c(0.3)]
        let cushion = ellipse(P(0, 0.06), 0.27, 0.075)
        let plinth = rect(-0.32, 0.1, 0.32, 1.1)
        let spot = [P(-0.08, -1.1), P(0.08, -1.1), P(0.56, 0.12), P(-0.56, 0.12)]
        let painting = rect(0.66, -0.62, 1.2, 0.02)
        let rope = curve(P(-0.76, 0.2), P(-0.56, 0.4), P(-0.33, 0.27))

        let tones: @Sendable (P) -> SIMD3<Double> = { p in
            if inside(p, diamond) {
                if inside(p, crown) {
                    for (k, f) in crownFacets.enumerated() where inside(p, f) { return crownTones[k] }
                    return c(0.5)
                }
                for (k, f) in pavilion.enumerated() where inside(p, f) { return pavilionTones[k] }
                return c(0.85)
            }
            if inside(p, cushion) { return m(p.x < -0.06 ? 0.7 : 0.5) }
            if inside(p, rect(-0.1, 0.38, 0.1, 0.46)) { return y(0.6) }
            if inside(p, plinth) { return m(p.x < -0.12 ? 0.5 : 0.28) }
            if distance(p, rope) < 0.022 { return m(0.75) }
            if inside(p, painting) { return inside(p, rect(0.7, -0.58, 1.2, -0.02)) ? (p.y < -0.25 ? c(0.3) : y(0.35)) : y(0.6) }
            if p.y > 0.8 { return c(0.16) }
            if inside(p, spot) { return y(0.13) }
            return .zero
        }

        var s: [Halftone.Stroke] = []
        s.append(stroke(closed(diamond), bold))
        s.append(stroke([P(-girdle.x, girdle.y), P(girdle.x, girdle.y)], mid))
        s.append(stroke(zig, hair))
        for x in pavilionX.dropFirst().dropLast() { s.append(stroke([P(x, girdle.under), culet], hair)) }
        s.append(stroke([P(-0.135, girdle.under), P(-0.03, -0.25)], hair))
        s.append(stroke([P(0.135, girdle.under), P(0.03, -0.25)], hair))
        // The clue: the forger's star on the magenta facet, near the lens's centre but clear of its knob.
        s.append(stroke(star(P(0.088, -0.37), 0.013, degrees: -80), 0.002))
        s += glint(P(-0.24, -0.67), 0.07)
        s += glint(P(0.26, -0.36), 0.035, hair)
        // The mount, the cushion's tuft, the plinth and its plaque.
        s.append(stroke([culet, P(-0.035, 0.0)], mid))
        s.append(stroke([culet, P(0.035, 0.0)], mid))
        s.append(stroke(cushion, mid))
        s.append(stroke(curve(P(-0.2, 0.05), P(-0.1, 0.1), P(-0.02, 0.07)), hair))
        s.append(stroke(curve(P(0.05, 0.1), P(0.14, 0.08), P(0.21, 0.03)), hair))
        s.append(stroke(closed(plinth), bold))
        s.append(stroke([P(-0.32, 0.2), P(0.32, 0.2)], mid))
        s.append(stroke([P(-0.12, 0.2), P(-0.12, 1.1)], hair))
        s.append(stroke(closed(rect(-0.1, 0.38, 0.1, 0.46)), mid))
        s.append(stroke(closed([P(0, 0.395), P(0.03, 0.42), P(0, 0.445), P(-0.03, 0.42)]), hair))
        for x in [-0.08, 0.08] { s.append(stroke(circle(P(x, 0.42), 0.008, 12), hair)) }
        // The case: its glass, its base and two streaks of reflection, top left.
        s.append(stroke([P(-0.6, 0.1), P(-0.6, -0.9), P(0.6, -0.9), P(0.6, 0.1)], mid))
        s.append(stroke([P(-0.66, 0.1), P(0.66, 0.1)], bold))
        s.append(stroke([P(-0.53, -0.48), P(-0.38, -0.8)], hair))
        s.append(stroke([P(-0.48, -0.4), P(-0.39, -0.6)], hair))
        // The stanchion and its rope, bottom left; a painting's corner on the wall, right.
        s.append(stroke([P(-0.78, 0.22), P(-0.78, 0.86)], bold))
        s.append(stroke(circle(P(-0.78, 0.19), 0.03, 16), mid))
        s.append(stroke(ellipse(P(-0.78, 0.87), 0.08, 0.02), mid))
        s.append(stroke(closed(painting), bold))
        s.append(stroke(closed(rect(0.7, -0.58, 1.2, -0.02)), hair))
        s.append(stroke([P(0.7, -0.25), P(0.8, -0.36), P(0.9, -0.28), P(1.0, -0.42), P(1.2, -0.3)], hair))
        // The floor's boards running away.
        s.append(stroke([P(-1, 0.8), P(1, 0.8)], mid))
        for k in 0..<7 { s.append(stroke([P(-0.6 + 0.2 * Double(k), 0.8), P(-1.5 + 0.5 * Double(k), 1.0)], hair)) }
        return Halftone.Panel(name: "switch02", tones: tones, strokes: s)
    }()
}

// MARK: - B: Keyhole

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

// MARK: - C: Close-up, one panel for the chapter

/// The chapter's one panel, under all six of Close-up's levels: a desk under the lamp, each object where one of the
/// chapter's lenses falls, each holding a clue. Tri's top core (levels 1 to 3) and eye's small top (5) hold the stamp,
/// tri's lower right (4) the pocket watch, eye's big left (6) the fingerprint on a card.
extension LensArt {
    static let closeup: Halftone.Panel = {
        let stamp = P(0, -0.47), z = 1.35
        let watch = P(0.36, 0.22), card = closed([P(-0.8, -0.32), P(-0.06, -0.4), P(0.0, 0.3), P(-0.74, 0.38)])
        let print = P(-0.4, 0.0)
        let lamp = [P(-1.2, -1.2), P(-0.3, -1.2), P(0.9, 1.2), P(-1.2, 1.2)]

        let tones: @Sendable (P) -> SIMD3<Double> = { p in
            let d = (p - stamp) / z
            if abs(d.x) < 0.12, abs(d.y) < 0.15 {
                if abs(d.x) < 0.095, abs(d.y) < 0.125 {
                    return d.y > 0.04 ? c(0.55) : d.y > -0.02 ? m(0.5) : y(0.4)
                }
                return y(0.12)
            }
            let w = simd_distance(p, watch)
            if w < 0.2 { return w > 0.175 ? y(0.7) : y(0.18) }
            if simd_distance(p, watch + P(0, -0.24)) < 0.04 { return y(0.7) }
            if inside(p, card) { return simd_distance(p, print) < 0.2 ? m(0.2) : SIMD3(0, 0, 0.1) }
            if inside(p, lamp) { return y(0.1) }
            return c(0.14)
        }

        var s: [Halftone.Stroke] = []
        // The stamp: perforations, a frame, and a ship on its sea; a hairline mark on the sail is the clue.
        s.append(stroke(closed(rect(stamp.x - z * 0.095, stamp.y - z * 0.125, stamp.x + z * 0.095, stamp.y + z * 0.125)), mid))
        for k in 0..<9 {
            let t = -0.11 + 0.0275 * Double(k)
            for q in [P(t, -0.15), P(t, 0.15)] { s.append(stroke(circle(stamp + z * q, 0.01, 10), hair)) }
        }
        for k in 0..<11 {
            let t = -0.135 + 0.027 * Double(k)
            for q in [P(-0.12, t), P(0.12, t)] { s.append(stroke(circle(stamp + z * q, 0.01, 10), hair)) }
        }
        s.append(stroke(curve(stamp + z * P(-0.07, 0.06), stamp + z * P(0, 0.09), stamp + z * P(0.07, 0.06), 16), mid))
        s.append(stroke([stamp + z * P(-0.06, 0.06), stamp + z * P(0.05, 0.06)], mid))
        s.append(stroke([stamp + z * P(-0.005, 0.06), stamp + z * P(-0.005, -0.08)], mid))
        s.append(stroke(closed([stamp + z * P(0.0, -0.075), stamp + z * P(0.055, 0.035), stamp + z * P(0.0, 0.035)]), hair))
        s.append(stroke(closed([stamp + z * P(-0.01, -0.06), stamp + z * P(-0.05, 0.04), stamp + z * P(-0.01, 0.04)]), hair))
        s.append(stroke(star(stamp + z * P(0.017, 0.005), 0.007), 0.0014))
        for k in 0..<3 {
            let yy = 0.09 + 0.012 * Double(k)
            s.append(stroke(curve(stamp + z * P(-0.08, yy), stamp + z * P(-0.04, yy - 0.01), stamp + z * P(0.0, yy), 8), hair))
        }
        // The pocket watch: rim, crown, ticks, hands at ten to two, and a maker's mark under XII.
        s.append(stroke(circle(watch, 0.2, 64), bold))
        s.append(stroke(circle(watch, 0.175, 64), hair))
        s.append(stroke(closed(rect(watch.x - 0.025, watch.y - 0.27, watch.x + 0.025, watch.y - 0.205)), mid))
        s.append(stroke(circle(watch + P(0, -0.29), 0.03, 20), mid))
        for k in 0..<12 {
            let a = Double(k) * .pi / 6, u = P(sin(a), -cos(a))
            s.append(stroke([watch + 0.15 * u, watch + (k % 3 == 0 ? 0.12 : 0.138) * u], k % 3 == 0 ? mid : hair))
        }
        let hour = P(sin(-1.0), -cos(-1.0)), minute = P(sin(1.05), -cos(1.05))
        s.append(stroke([watch - 0.02 * hour, watch + 0.08 * hour], bold))
        s.append(stroke([watch - 0.02 * minute, watch + 0.125 * minute], mid))
        s.append(stroke(circle(watch, 0.012, 12), mid))
        s.append(stroke(circle(watch + P(0, 0.065), 0.03, 20), hair))
        s.append(stroke([watch + P(0, 0.065), watch + P(0.018, 0.045)], hair))
        s.append(stroke(star(watch + P(0, -0.07), 0.008), 0.0014))
        // The card and its fingerprint: whorls that open to one side.
        s.append(stroke(card, mid))
        for k in 0..<10 {
            let r = 0.022 + 0.016 * Double(k)
            s.append(stroke(ellipse(print, r * 0.82, r, degrees: 12, 40).dropLast(6 + k % 3).map { $0 }, hair))
        }
        s.append(stroke(curve(print + P(-0.02, 0.03), print + P(0.0, 0.0), print + P(0.03, 0.02), 10), hair))
        // The lamp's edge and a pencil, top right.
        s.append(stroke([P(-0.3, -1.2), P(0.9, 1.2)], hair))
        s.append(stroke(closed([P(0.3, -0.75), P(0.86, -0.38), P(0.83, -0.33), P(0.27, -0.7)]), mid))
        s.append(stroke(closed([P(0.86, -0.38), P(0.93, -0.36), P(0.83, -0.33)]), mid))
        s.append(stroke([P(0.38, -0.69), P(0.35, -0.64)], hair))
        return Halftone.Panel(name: "closeup", tones: tones, strokes: s)
    }()
}
