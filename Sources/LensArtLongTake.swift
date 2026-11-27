// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 32 to 37, the chapter Long take.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let longTake: [Int: Halftone.Panel] = [32: operaGlasses, 33: pinceNez, 34: lorgnette]
}

// MARK: Drawing

extension LensArt {
    /// A tone at a point, or nil where the layer leaves the point to the ones under it.
    fileprivate typealias Layer = @Sendable (P) -> Tone?

    fileprivate static func layer(_ f: Fill) -> Layer { { f.holds($0) ? f.tone : nil } }

    /// A ring between r0 and r1 about c cut into n equal segments, toned in turn from `tones`, the first from `phase`
    /// degrees: a frame that changes along its length.
    fileprivate static func segments(_ c: P, _ r0: Double, _ r1: Double, _ n: Int, _ tones: [Tone], phase: Double = 0) -> Layer {
        { p in
            let d = p - c, l2 = simd_length_squared(d)
            guard l2 < r1 * r1, l2 >= r0 * r0 else { return nil }
            let a = (atan2(d.y, d.x) * 180 / .pi - phase + 720).truncatingRemainder(dividingBy: 360)
            return tones[Int(a / 360 * Double(n)) % tones.count]
        }
    }

    /// Layers over a ground, the first that holds a point giving its tone.
    fileprivate static func layered(_ name: String, _ layers: [Layer], strokes: [Halftone.Stroke],
                                     ground: @escaping @Sendable (P) -> Tone) -> Halftone.Panel {
        // Long lines are cut into short runs, each with its own small box, as the bake tests every segment of a stroke
        // whose box holds the pixel.
        let short = strokes.flatMap { s in
            stride(from: 0, to: s.points.count - 1, by: 6).map { Halftone.Stroke(points: Array(s.points[$0...min($0 + 6, s.points.count - 1)]), width: s.width) }
        }
        return Halftone.Panel(name: name, tones: { p in
            for l in layers { if let t = l(p) { return t } }
            return ground(p)
        }, strokes: short)
    }

    /// A circle as four quarter arcs, so each stroke's box stays small and the bake tests fewer segments a pixel.
    fileprivate static func rim(_ c: P, _ r: Double, _ width: Double = mid, _ n: Int = 12) -> [Halftone.Stroke] {
        (0..<4).map { stroke(arc(c, r, 90 * Double($0), 90 * Double($0) + 90, n), width) }
    }

    /// Points turned `degrees` about c, clockwise on screen.
    fileprivate static func turned(_ points: [P], about c: P, _ degrees: Double) -> [P] {
        let t = degrees * .pi / 180
        return points.map { p in
            let d = p - c
            return c + P(d.x * cos(t) - d.y * sin(t), d.x * sin(t) + d.y * cos(t))
        }
    }

    /// A band along a line, `w0` wide at its start tapering to `w1` at its end, as a polygon.
    fileprivate static func ribbon(_ line: [P], _ w0: Double, _ w1: Double) -> [P] {
        var left: [P] = [], right: [P] = []
        for (k, p) in line.enumerated() {
            let a = line[max(k - 1, 0)], b = line[min(k + 1, line.count - 1)], u = simd_normalize(b - a), n = P(-u.y, u.x)
            let w = (w0 + (w1 - w0) * Double(k) / Double(line.count - 1)) / 2
            left.append(p + n * w)
            right.append(p - n * w)
        }
        return left + right.reversed()
    }
}

// MARK: - 32: Opera glasses

/// Level 32's name: a pair of opera glasses in gilt and mother of pearl, held up in a dark theatre, the near glass over
/// the right core and the far one over the top (two of eye's three lenses on this level), and the follow spot's pool of
/// light on the boards below over the bottom core (the third): through the near glass the diva mid-aria, a note in the
/// air; through the far one a masked dancer's domino mask on its stick; in the spot, a rose thrown to the stage. The
/// velvet curtain swagged across the left rod, its folds broad stripes, is what that rod's twist turns.
extension LensArt {
    static let operaGlasses: Halftone.Panel = {
        let near = P(0.4, 0), far = P(0, -0.56), spot = P(0, 0.56), stage = 0.36
        let glass = c(0.55), gilt = y(0.85), pearl = Tone(0.32, 0.28, 0.42), shell = Tone(0.18, 0.42, 0.3)
        let wheel = (near + far) / 2 + P(0.28, -0.14)
        let tieBack = P(-0.66, 0.3)
        let drape = curve(P(0.08, -1.05), P(-0.06, -0.2), tieBack, 20) + curve(tieBack, P(-0.62, 0.42), P(-0.72, stage + 0.04), 8)
            + [P(-1.05, stage + 0.04), P(-1.05, -1.05)]
        let tassel = [tieBack + P(-0.03, 0), tieBack + P(0.03, 0), tieBack + P(0.06, 0.16), tieBack + P(-0.06, 0.16)]
        let valance = (0...12).flatMap { k -> [P] in
            let x = -1.0 + Double(k) / 6
            return [P(x, -0.84), P(x + 1.0 / 12, -0.78)]
        } + [P(1.05, -0.84), P(1.05, -1.05), P(-1.05, -1.05)]

        // Each barrel runs back from its objective to the eyepiece end, up and to the right, tapering.
        let barrels = [(near, 0.41, near + P(0.3, -0.16), 0.28), (far, 0.32, far + P(0.25, -0.12), 0.22)]
        func body(_ a: P, _ ra: Double, _ b: P, _ rb: Double) -> [P] {
            let u = simd_normalize(b - a), n = P(-u.y, u.x)
            return [a + n * ra, b + n * rb] + arc(b, rb, atan2(n.y, n.x) * 180 / .pi, atan2(n.y, n.x) * 180 / .pi - 180, 16) + [a - n * ra]
        }
        var layers: [Layer] = [layer(disc(near, 0.348, glass)), layer(disc(far, 0.264, glass)), layer(disc(spot, 0.264, y(0.9)))]
        // The frames: gilt bands inlaid with pearl, and the spot's edge flaring in rays, each breaking along its length.
        layers.append(segments(near, 0.348, 0.41, 18, [gilt, pearl, gilt, shell], phase: 7))
        layers.append(segments(far, 0.264, 0.32, 14, [gilt, pearl, gilt, shell], phase: 3))
        layers.append { p in
            // The spot's edge in tapering rays, long and short by turns.
            let d = p - spot, l = simd_length(d)
            guard l >= 0.264, l < 0.37 else { return nil }
            let a = (atan2(d.y, d.x) * 180 / .pi + 367).truncatingRemainder(dividingBy: 360) / 15
            let k = Int(a), off = abs(a - Double(k) - 0.5) * 2, reach = k % 2 == 0 ? 0.1 : 0.05
            return off < 1 - (l - 0.264) / reach ? y(0.6) : nil
        }
        layers += [layer(disc(wheel, 0.08, m(0.8))), layer(fill(tassel, y(0.9))), layer(disc(tieBack, 0.04, y(0.9))), layer(fill(valance, m(0.7)))]
        layers += [-0.55, -0.35, 0.35, 0.55, 0.75].map { layer(fill(arc(P($0, stage), 0.04, 180, 360, 8), y(0.9))) }
        layers.append(layer(fill(bar(barrels[0].2, barrels[1].2, 0.06), gilt)))
        for (a, ra, b, rb) in barrels {
            layers.append(layer(fill(bar(a + (b - a) * 0.78, a + (b - a) * 0.9, 2 * rb + 0.08), gilt)))
            layers.append(layer(fill(body(a, ra, b, rb), y(0.42))))
        }
        let folds = SIMD2(cos(0.25), sin(0.25))
        let drapeFill = fill(drape, .zero)
        layers.append { p in
            guard drapeFill.holds(p) else { return nil }
            // The drape's folds: broad stripes leaning with the swag.
            let k = Int(((simd_dot(p, folds) + 2) / 0.1).rounded(.down))
            return k % 2 == 0 ? m(0.68) : m(0.36)
        }

        var s: [Halftone.Stroke] = []
        // The valance's scallops and fringe, the drape's edge and folds, the tie-back and its tassel.
        s.append(stroke(Array(valance.dropLast(3)), mid))
        for k in 0..<24 { s.append(stroke([P(-1 + Double(k) / 12, -0.8), P(-1 + Double(k) / 12, -0.75)], hair)) }
        s += runs(Array(drape.prefix(30)), bold) { simd_distance($0, far) > 0.33 }
        for k in 0..<6 {
            let x = -0.94 + 0.12 * Double(k)
            s += runs(curve(P(x + 0.1, -0.84), P(x + 0.02, -0.3), P(-0.7 + 0.01 * Double(k), 0.28), 24), hair) { simd_distance($0, far) > 0.33 }
        }
        s.append(stroke(closed(tassel), mid))
        for k in 1..<6 { s.append(stroke([tieBack + P(-0.06 + 0.02 * Double(k), 0.06), tieBack + P(-0.07 + 0.025 * Double(k), 0.16)], hair)) }
        s += rim(tieBack, 0.04, mid, 4)
        // The boards and the footlights.
        s += runs(span(P(-1, stage), P(1, stage), 60), mid) { simd_distance($0, spot) > 0.34 }
        for (k, yy) in [0.5, 0.66, 0.84].enumerated() {
            s += runs(span(P(-1, yy), P(1, yy), 60), hair) { simd_distance($0, spot) > 0.34 }
            for j in 0..<4 {
                let x = -0.9 + 0.5 * Double(j) + 0.17 * Double(k)
                if abs(x - spot.x) > 0.36 { s.append(stroke([P(x, yy), P(x, yy + 0.12)], hair)) }
            }
        }
        for x in [-0.55, -0.35, 0.35, 0.55, 0.75] { s.append(stroke(arc(P(x, stage), 0.04, 180, 360, 8), mid)) }
        // The glasses: both frames, the pearl of each barrel's side, the focus wheel knurled, and a glint on each glass.
        for (a, ra, b, rb) in barrels {
            let shape = body(a, ra, b, rb)
            s += runs(shape, bold) { simd_distance($0, a) > ra + 0.004 }
            for t in [0.78, 0.9] {
                let q = bar(a + (b - a) * t, a + (b - a) * t + simd_normalize(b - a) * 0.001, 2 * (ra + (rb - ra) * t))
                s += runs(span(q[0], q[3], 20), hair) { simd_distance($0, a) > ra }
            }
        }
        for (c, r, outer) in [(near, 0.348, 0.41), (far, 0.264, 0.32)] {
            s += rim(c, outer, bold)
            s += rim(c, r, mid)
            s.append(stroke(arc(c, r * 0.78, 200, 245, 10), mid))
            s.append(stroke(arc(c, r * 0.66, 210, 230, 6), hair))
        }
        s += rim(wheel, 0.08, bold, 6)
        s += rim(wheel, 0.025, mid, 3)
        for k in 0..<16 { s.append(stroke([polar(wheel, 0.045, 22.5 * Double(k)), polar(wheel, 0.075, 22.5 * Double(k))], hair)) }
        // The spot's beam coming down from the gallery.
        s.append(stroke([P(-0.3, -0.2), spot + P(-0.25, -0.12)], hair))
        s.append(stroke([P(-0.15, -0.25), spot + P(0.24, -0.14)], hair))

        // Through the near glass: the diva, hair up, mouth open, an arm flung out, and a note.
        let diva = near + P(0.012, -0.022)
        s.append(stroke(circle(diva + P(0, -0.026), 0.009, 12), 0.003))
        s.append(stroke(circle(diva + P(-0.004, -0.04), 0.005, 8), 0.003))
        s.append(stroke(circle(diva + P(0.008, -0.023), 0.0022, 6), 0.0024))
        s.append(stroke([diva + P(-0.004, -0.016), diva + P(-0.02, 0.04), diva + P(0.026, 0.04), diva + P(0.006, -0.016)], 0.003))
        s.append(stroke([diva + P(0.004, -0.008), diva + P(0.03, -0.022), diva + P(0.036, -0.034)], 0.0024))
        s.append(stroke([diva + P(-0.006, -0.006), diva + P(-0.022, 0.012)], 0.0024))
        s.append(stroke(circle(diva + P(0.04, -0.05), 0.0045, 8), 0.0036))
        s.append(stroke([diva + P(0.0445, -0.05), diva + P(0.0445, -0.075), diva + P(0.054, -0.068)], 0.0024))
        // Through the far glass: a domino mask on its stick, a ribbon trailing.
        let mask = far + P(0.012, -0.024)
        s.append(stroke(closed(curve(mask + P(-0.04, -0.008), mask + P(-0.02, -0.024), mask + P(0, -0.008), 8)
            + curve(mask + P(0, -0.008), mask + P(0.02, -0.024), mask + P(0.04, -0.008), 8)
            + curve(mask + P(0.04, -0.008), mask + P(0.03, 0.02), mask + P(0.008, 0.01), 8)
            + curve(mask + P(0.008, 0.01), mask + P(0, 0.004), mask + P(-0.008, 0.01), 4)
            + curve(mask + P(-0.008, 0.01), mask + P(-0.03, 0.02), mask + P(-0.04, -0.008), 8)), 0.0034))
        for x in [-0.018, 0.018] { s.append(stroke(ellipse(mask + P(x, -0.002), 0.008, 0.005, degrees: x < 0 ? 12 : -12, 12), 0.0026)) }
        s.append(stroke([mask + P(0.038, 0.002), mask + P(0.05, 0.05)], 0.003))
        s.append(stroke(curve(mask + P(-0.04, -0.008), mask + P(-0.06, 0.0), mask + P(-0.05, 0.03), 6), 0.002))
        s.append(stroke(curve(mask + P(-0.04, -0.006), mask + P(-0.07, 0.012), mask + P(-0.064, 0.04), 6), 0.002))
        // In the spot: a rose, its bloom, stem, leaves and a thorn.
        let rose = spot + P(0.016, -0.024)
        s.append(stroke(spiral(rose, 0.002, grow: 0.00035, turn: 30, 40), 0.0026))
        s.append(stroke(circle(rose, 0.016, 14), 0.0032))
        s.append(stroke(curve(rose + P(-0.01, 0.014), rose + P(-0.02, 0.04), rose + P(-0.05, 0.06), 10), 0.003))
        s.append(stroke(closed(curve(rose + P(-0.02, 0.034), rose + P(-0.002, 0.03), rose + P(0.004, 0.048), 6)
            + curve(rose + P(0.004, 0.048), rose + P(-0.014, 0.05), rose + P(-0.02, 0.034), 6)), 0.0022))
        s.append(stroke(closed(curve(rose + P(-0.036, 0.05), rose + P(-0.05, 0.036), rose + P(-0.062, 0.042), 6)
            + curve(rose + P(-0.062, 0.042), rose + P(-0.052, 0.056), rose + P(-0.036, 0.05), 6)), 0.0022))
        s.append(stroke([rose + P(-0.027, 0.046), rose + P(-0.022, 0.054)], 0.002))
        return layered("operaglasses", layers, strokes: s) { p in p.y > stage ? m(0.4) : Tone(0.1, 0.12, 0) }
    }()
}

// MARK: - 33: Pince-nez

/// Level 33's name: a whiskered gentleman in a tilted top hat, his pince-nez clipped on his nose, its two glasses over
/// the upper left and upper right cores (hex's two lenses on this level), joined by the spring over his nose and
/// chained to his lapel; he is a naturalist, and through the left glass is a butterfly, through the right a beetle.
/// His hat, brows, handlebar moustache, sideburns and cravat are the broad shapes the five twisting rods turn, the
/// moustache and the nose's shadow off the hub's centre.
extension LensArt {
    static let pinceNez: Halftone.Panel = {
        let left = P(-0.485, -0.28), right = P(0.485, -0.28)
        let skin = Tone(0, 0.32, 0.58), whisker = Tone(0, 0.62, 0.2), glass = c(0.5), gilt = y(0.95)
        let pivot = P(0, -0.72), tilt = -8.0
        let crown = turned([P(-0.4, -1.2), P(0.4, -1.2), P(0.38, -0.74), P(-0.38, -0.74)], about: pivot, tilt)
        let band = turned([P(-0.385, -0.86), P(0.385, -0.86), P(0.38, -0.74), P(-0.38, -0.74)], about: pivot, tilt)
        let brim = turned(ellipse(P(0, -0.72), 0.6, 0.065, 40), about: pivot, tilt)
        let half: [P] = [P(0, 0.15), P(-0.1, 0.12), P(-0.22, 0.16), P(-0.33, 0.17), P(-0.42, 0.12), P(-0.47, 0.03), P(-0.44, 0.14),
                         P(-0.38, 0.22), P(-0.26, 0.27), P(-0.12, 0.26), P(0, 0.22)]
        // The right curl rides higher than the left, so the moustache is no mirror about the hub.
        let other = half.reversed().map { P(-$0.x, $0.y - ($0.x < -0.3 ? 0.05 : 0)) }
        let moustache = half + other
        let shadow = [P(-0.04, -0.25), P(-0.07, 0.0), P(-0.12, 0.08), P(-0.05, 0.13), P(0, 0.11), P(0, -0.25)]
        let nose = [P(-0.04, -0.25), P(-0.07, 0.0), P(-0.12, 0.08), P(-0.05, 0.13), P(0.05, 0.13), P(0.11, 0.08), P(0.07, 0.0), P(0.04, -0.25)]
        let goatee = [P(-0.09, 0.4), P(0.08, 0.4), P(0.02, 0.66), P(-0.01, 0.66)]
        let burns = [-1.0, 1.0].map { x in [P(0.5 * x, -0.42), P(0.6 * x, -0.42), P(0.63 * x, 0.12), P(0.5 * x, 0.2), P(0.48 * x, 0.0)] }
        let brows = [left, right].map { turned(ellipse($0 + P(0, -0.34), 0.17, 0.045, 20), about: $0 + P(0, -0.34), $0.x < 0 ? 6 : -10) }
        let collars = [-1.0, 1.0].map { x in [P(0.04 * x, 0.78), P(0.36 * x, 0.68), P(0.3 * x, 0.96), P(0.06 * x, 0.88)] }
        let bow = [P(-0.2, 0.8), P(0, 0.88), P(0.2, 0.78), P(0.22, 0.98), P(0, 0.92), P(-0.18, 1.0)]
        let chain = curve(polar(left, 0.3, 160), P(-0.95, 0.1), P(-0.34, 0.8), 30)

        var layers: [Layer] = [layer(disc(left, 0.264, glass)), layer(disc(right, 0.264, glass))]
        // Each frame a gilt wire broken in dashes, a stud on its outer side.
        for (c, phase) in [(left, 4.0), (right, 11.0)] {
            layers.append(segments(c, 0.264, 0.3, 30, [gilt, gilt, .zero], phase: phase))
        }
        layers += [layer(disc(polar(left, 0.31, 180), 0.03, gilt)), layer(disc(polar(right, 0.31, 0), 0.03, gilt))]
        layers += stride(from: 0, to: 31, by: 3).map { layer(disc(chain[$0], 0.016, gilt)) }
        layers += brows.map { layer(fill($0, whisker)) }
        layers += [layer(fill(bow, m(0.85))), layer(fill(collars[0], Tone(0.4, 0.4, 0.4))), layer(fill(collars[1], Tone(0.4, 0.4, 0.4))),
                   layer(fill(moustache, whisker)), layer(fill(shadow, Tone(0, 0.52, 0.5))), layer(fill(nose, skin)),
                   layer(fill(goatee, whisker)), layer(fill(band, m(0.8))), layer(fill(crown, c(0.3))), layer(fill(brim, c(0.3)))]
        layers += burns.map { layer(fill($0, whisker)) }
        layers += [layer(oval(P(-0.62, -0.12), 0.08, 0.13, skin)), layer(oval(P(0.62, -0.12), 0.08, 0.13, skin)),
                   layer(oval(P(0, -0.02), 0.62, 0.8, skin)), layer(fill(rect(-1, 0.78, 1, 1), .zero))]

        var s: [Halftone.Stroke] = []
        // The hat: crown, band, brim; the face, ears, brows, nose, moustache, goatee; collar and cravat.
        s.append(stroke([crown[3], crown[0]], bold))
        s.append(stroke([crown[1], crown[2]], bold))
        s.append(stroke([band[0], band[1]], mid))
        s.append(stroke(brim, bold))
        s += runs(ellipse(P(0, -0.02), 0.62, 0.8, 96), bold) { $0.y > -0.7 && simd_distance($0, left) > 0.3 && simd_distance($0, right) > 0.3 }
        for x in [-0.62, 0.62] { s += runs(ellipse(P(x, -0.12), 0.08, 0.13, 24), mid) { abs($0.x) > 0.58 } }
        for b in brows {
            for k in 0..<7 { s.append(stroke([b[2 + 2 * k], b[2 + 2 * k] + P(0.012, -0.03)], hair)) }
        }
        s.append(stroke(Array(nose.dropFirst().dropLast()), mid))
        for x in [-0.06, 0.06] { s.append(stroke(circle(P(x, 0.1), 0.018, 8), hair)) }
        s.append(stroke(closed(moustache), bold))
        for k in 0..<6 {
            let x = 0.04 + 0.06 * Double(k)
            s.append(stroke([P(-x, 0.16 + 0.01 * Double(k)), P(-x - 0.05, 0.23)], hair))
            s.append(stroke([P(x, 0.16 + 0.006 * Double(k)), P(x + 0.05, 0.22 - 0.008 * Double(k))], hair))
        }
        s.append(stroke(closed(goatee), mid))
        s.append(stroke(arc(P(0, 0.36), 0.06, 20, 160, 8), mid))
        for b in burns { s += runs(span(b[1], b[2], 30) + span(b[2], b[3], 8), mid) { simd_distance($0, left) > 0.3 && simd_distance($0, right) > 0.3 } }
        for c in collars { s.append(stroke(closed(c), mid)) }
        s.append(stroke(closed(bow), mid))
        s.append(stroke(circle(P(0, 0.88), 0.035, 10), mid))
        // The pince-nez: the frames, their studs, the spring over the nose and its pads, the chain to the lapel.
        for c in [left, right] {
            s += rim(c, 0.3, bold)
            s += rim(c, 0.264, mid)
            s.append(stroke(arc(c, 0.2, 200, 240, 10), mid))
            s.append(stroke(arc(c, 0.15, 205, 225, 6), hair))
        }
        s.append(stroke(curve(polar(left, 0.3, -10), P(0, -0.5), polar(right, 0.3, 190), 20), bold))
        s.append(stroke(curve(polar(left, 0.3, -2), P(0, -0.44), polar(right, 0.3, 182), 20), hair))
        for x in [-0.07, 0.07] { s.append(stroke(ellipse(P(x, -0.24), 0.02, 0.035, 10), mid)) }
        for k in stride(from: 0, to: 31, by: 3) { s.append(stroke(circle(chain[k], 0.016, 8), hair)) }
        // Through the left glass: a butterfly, its four wings, body and feelers.
        let fly = left + P(0.014, -0.026)
        s.append(stroke([fly + P(0, -0.016), fly + P(0, 0.016)], 0.0042))
        for side in [-1.0, 1.0] {
            s.append(stroke(ellipse(fly + P(side * 0.018, -0.009), 0.017, 0.012, degrees: side * -30, 16), 0.003))
            s.append(stroke(ellipse(fly + P(side * 0.013, 0.01), 0.01, 0.008, degrees: side * 30, 12), 0.003))
            s.append(stroke(curve(fly + P(0, -0.016), fly + P(side * 0.004, -0.03), fly + P(side * 0.014, -0.036), 6), 0.002))
            s.append(stroke(circle(fly + P(side * 0.017, -0.009), 0.004, 6), 0.002))
        }
        // Through the right glass: a beetle, its wing cases parted by a seam, its head, six legs and feelers.
        let bug = right + P(0.012, -0.028)
        s.append(stroke(ellipse(bug, 0.015, 0.02, 20), 0.0036))
        s.append(stroke([bug + P(0, -0.012), bug + P(0, 0.02)], 0.002))
        s.append(stroke([bug + P(-0.015, -0.01), bug + P(0.015, -0.01)], 0.002))
        s.append(stroke(circle(bug + P(0, -0.027), 0.007, 10), 0.0034))
        for side in [-1.0, 1.0] {
            for (k, yy) in [-0.006, 0.004, 0.014].enumerated() {
                s.append(stroke([bug + P(side * 0.014, yy), bug + P(side * 0.026, yy - 0.006 + 0.006 * Double(k)), bug + P(side * 0.03, yy + 0.004 * Double(k))], 0.0018))
            }
            s.append(stroke([bug + P(side * 0.004, -0.033), bug + P(side * 0.012, -0.046)], 0.0018))
            s.append(stroke(circle(bug + P(side * 0.007, 0.006), 0.003, 6), 0.002))
        }
        return layered("pincenez", layers, strokes: s) { p in
            // A dark wall papered in broad gilt stripes.
            (p.x + 2).truncatingRemainder(dividingBy: 0.15) < 0.065 ? y(0.4) : .zero
        }
    }()
}

// MARK: - 34: Lorgnette

/// Level 34's name: a lorgnette, its two glasses joined in gilt beaded with jet, held up on its long gilt handle in a
/// lady's blue satin glove against rose silk, her painted fan open above; the near glass is over the left core and the
/// far one over the bottom (eye's two lenses on this level), and what she has spotted with such disdain is a mouse
/// through the one and its wedge of cheese through the other. The glove, the handle and the fan's pleats are the broad
/// shapes the two twisting rods turn.
extension LensArt {
    static let lorgnette: Halftone.Panel = {
        let a = P(-0.4, 0), b = P(0, 0.56), knot = a + (b - a) * 0.594
        let glass = c(0.5), gilt = y(0.9), satin = c(0.6)
        let hinge = polar(a, 0.41, -40), end = P(0.74, -0.54), grip = hinge + (end - hinge) * 0.55
        let handle = bar(hinge, end, 0.065)
        let arm = bar(grip + P(0.04, 0.06), P(1.05, 0.2), 0.17)
        let fist = turned(squircle(grip + P(0.03, 0.03), 0.14, 0.1, 32), about: grip + P(0.03, 0.03), 25)
        let cuff = bar(grip + P(0.2, 0.16), grip + P(0.26, 0.21), 0.24)
        let fanPivot = P(-0.2, -0.44)
        let pleats = (0..<9).map { k in [fanPivot] + arc(fanPivot, 0.42, -150 + 12 * Double(k), -138 + 12 * Double(k), 4) }

        var layers: [Layer] = [layer(disc(a, 0.348, glass)), layer(disc(b, 0.264, glass))]
        // The frames: gilt beaded with jet and a garnet, unevenly, so each reads its way round.
        layers.append(segments(a, 0.348, 0.41, 26, [gilt, gilt, m(0.8), gilt, .zero], phase: 5))
        layers.append(segments(b, 0.264, 0.315, 20, [gilt, gilt, m(0.8), gilt, .zero], phase: 9))
        layers += [layer(disc(knot, 0.05, m(0.85))), layer(disc(end, 0.055, gilt)), layer(fill(fist, satin)), layer(fill(handle, gilt)), layer(fill(cuff, m(0.8))),
                   layer(fill(arm, satin))]
        for (k, p) in pleats.enumerated() { layers.append(layer(fill(p, k % 2 == 0 ? m(0.75) : y(0.75)))) }
        layers.append(layer(fill(rect(-1, 0.64, 1, 1), y(0.38))))

        var s: [Halftone.Stroke] = []
        // The wall's silk stripes and the floor's boards.
        for k in 0..<14 {
            let x = -0.97 + 0.14 * Double(k)
            s += runs(span(P(x, -1), P(x, 0.64), 60)) { p in simd_distance(p, a) > 0.42 && simd_distance(p, b) > 0.33 && !inside(p, handle) && !inside(p, arm) && simd_distance(p, fanPivot) > 0.43 }
        }
        s += runs(span(P(-1, 0.64), P(1, 0.64), 60), mid) { simd_distance($0, b) > 0.33 }
        for (k, yy) in [0.76, 0.9].enumerated() {
            s += runs(span(P(-1, yy), P(1, yy), 60), hair) { simd_distance($0, b) > 0.33 }
            for j in 0..<4 {
                let x = -0.85 + 0.45 * Double(j) + 0.2 * Double(k)
                if simd_distance(P(x, yy + 0.07), b) > 0.36 { s.append(stroke([P(x, yy), P(x, yy + 0.14)], hair)) }
            }
        }
        // The fan: its pleats, guards and rivet, and a sprig painted across it.
        for p in pleats { s.append(stroke([p[0], p[1]], hair)) }
        s.append(stroke(arc(fanPivot, 0.42, -150, -42, 24), mid))
        s.append(stroke([fanPivot, polar(fanPivot, 0.44, -150)], mid))
        s.append(stroke([fanPivot, polar(fanPivot, 0.44, -42)], mid))
        s.append(stroke(arc(fanPivot, 0.14, -150, -42, 12), hair))
        s += rim(fanPivot, 0.02, mid, 3)
        s.append(stroke(curve(polar(fanPivot, 0.22, -140), polar(fanPivot, 0.36, -100), polar(fanPivot, 0.26, -55), 16), mid))
        for t in [-125.0, -100, -75] { s.append(stroke(circle(polar(fanPivot, 0.31, t), 0.02, 8), hair)) }
        // The handle twisted, its finial, and the glove's fingers round it and the seam up its arm.
        s.append(stroke(closed(handle), mid))
        for k in 1..<14 {
            let q = hinge + (end - hinge) * (Double(k) / 14)
            s.append(stroke([q + P(-0.02, -0.03), q + P(0.02, 0.03)], hair))
        }
        s += rim(end, 0.055, mid, 4)
        s.append(stroke(closed(fist), bold))
        s.append(stroke(closed(cuff), mid))
        for k in 0..<6 { s.append(stroke([cuff[0] + (cuff[1] - cuff[0]) * 0.5 + (cuff[3] - cuff[0]) * (Double(k) / 5), cuff[0] + (cuff[1] - cuff[0]) * 1.1 + (cuff[3] - cuff[0]) * (Double(k) / 5)], hair)) }
        for k in 0..<4 { s.append(stroke(curve(grip + P(-0.07 + 0.045 * Double(k), -0.06), grip + P(-0.03 + 0.045 * Double(k), 0.03), grip + P(-0.05 + 0.045 * Double(k), 0.09), 6), mid)) }
        s.append(stroke(curve(grip + P(-0.1, 0.0), grip + P(-0.06, -0.08), grip + P(0.02, -0.1), 6), mid))
        s.append(stroke([arm[0], arm[1]], bold))
        s.append(stroke([arm[3], arm[2]], bold))
        s.append(stroke(span(grip + P(0.1, 0.1), P(1.0, 0.2), 8), hair))
        // The lorgnette: both frames, the bow knotting them, and a glint on each glass.
        for (c, r, outer) in [(a, 0.348, 0.41), (b, 0.264, 0.315)] {
            s += rim(c, outer, bold)
            s += rim(c, r, mid)
            s.append(stroke(arc(c, r * 0.78, 200, 245, 10), mid))
            s.append(stroke(arc(c, r * 0.66, 210, 230, 6), hair))
        }
        s += rim(knot, 0.05, mid, 4)
        s.append(stroke(closed([knot + P(-0.05, 0.02), knot + P(-0.12, -0.02), knot + P(-0.1, 0.07)]), mid))
        // Through the near glass: a mouse, nose up, whiskers and a long tail.
        let mouse = a + P(0.014, -0.028)
        s.append(stroke(closed(curve(mouse + P(-0.024, 0.008), mouse + P(-0.02, -0.02), mouse + P(0.012, -0.012), 10)
            + [mouse + P(0.03, -0.002), mouse + P(0.012, 0.01)]), 0.0034))
        s.append(stroke(circle(mouse + P(0.006, -0.016), 0.007, 10), 0.003))
        s.append(stroke(circle(mouse + P(0.017, -0.006), 0.0022, 6), 0.003))
        for t in [-20.0, 0, 20] { s.append(stroke([mouse + P(0.03, -0.002), polar(mouse + P(0.03, -0.002), 0.016, t)], 0.0014)) }
        s.append(stroke(curve(mouse + P(-0.024, 0.006), mouse + P(-0.05, 0.03), mouse + P(-0.06, -0.01), 10), 0.0024))
        for x in [-0.012, 0.006] { s.append(stroke([mouse + P(x, 0.008), mouse + P(x + 0.002, 0.014)], 0.002)) }
        // Through the far glass: a wedge of cheese, its holes, and a crumb.
        let cheese = b + P(0.006, -0.03)
        s.append(stroke(closed([cheese + P(-0.032, 0.0), cheese + P(0.028, 0.0), cheese + P(0.028, 0.016), cheese + P(-0.032, 0.016)]), 0.0032))
        s.append(stroke([cheese + P(-0.032, 0.0), cheese + P(0.036, -0.022), cheese + P(0.028, 0.0)], 0.0032))
        s.append(stroke([cheese + P(0.036, -0.022), cheese + P(0.036, -0.006), cheese + P(0.028, 0.016)], 0.0024))
        for (at, r) in [(P(-0.018, 0.008), 0.004), (P(0.004, 0.009), 0.0028), (P(0.016, -0.008), 0.0025)] { s.append(stroke(circle(cheese + at, r, 8), 0.002)) }
        s.append(stroke(circle(cheese + P(-0.046, 0.012), 0.003, 6), 0.0024))
        return layered("lorgnette", layers, strokes: s) { p in
            // Rose silk on the wall in broad stripes of two tones.
            (p.x + 2.04).truncatingRemainder(dividingBy: 0.28) < 0.14 ? m(0.42) : m(0.24)
        }
    }()
}
