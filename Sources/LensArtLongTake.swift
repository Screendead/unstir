// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 32 to 37, the chapter Long take.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let longTake: [Int: Halftone.Panel] = [32: operaGlasses]
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
