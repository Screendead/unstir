// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 32 to 37, the chapter Long take.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let longTake: [Int: Halftone.Panel] = [32: operaGlasses, 33: pinceNez, 34: lorgnette, 35: readingGlasses,
                                                  36: divingMask, 37: contactLens]
}

// MARK: Drawing

extension LensArt {
    /// A tone at a point inside a box, or nil where the layer leaves the point to the ones under it.
    fileprivate struct Layer: Sendable {
        var lo: P, hi: P
        var tone: @Sendable (P) -> Tone?

        init(_ lo: P, _ hi: P, tone: @escaping @Sendable (P) -> Tone?) {
            self.lo = lo
            self.hi = hi
            self.tone = tone
        }
    }

    fileprivate static func layer(_ f: Fill) -> Layer { Layer(f.lo, f.hi) { f.holds($0) ? f.tone : nil } }

    /// A ring between r0 and r1 about c cut into n equal segments, toned in turn from `tones`, the first from `phase`
    /// degrees: a frame that changes along its length.
    fileprivate static func segments(_ c: P, _ r0: Double, _ r1: Double, _ n: Int, _ tones: [Tone], phase: Double = 0) -> Layer {
        Layer(c - P(r1, r1), c + P(r1, r1)) { p in
            let d = p - c, l2 = simd_length_squared(d)
            guard l2 < r1 * r1, l2 >= r0 * r0 else { return nil }
            let a = (atan2(d.y, d.x) * 180 / .pi - phase + 720).truncatingRemainder(dividingBy: 360)
            return tones[Int(a / 360 * Double(n)) % tones.count]
        }
    }

    /// Layers over a ground, the first that holds a point giving its tone. The tank is cut into a grid, each cell
    /// listing the layers whose boxes reach it, so a point asks only those: the bake asks every point's tones once
    /// for each ink.
    fileprivate static func layered(_ name: String, _ layers: [Layer], strokes: [Halftone.Stroke],
                                     ground: @escaping @Sendable (P) -> Tone) -> Halftone.Panel {
        let n = 32, cell = 2.0 / Double(n)
        let grid: [[Layer]] = (0..<n * n).map { k in
            let lo = P(Double(k % n), Double(k / n)) * cell - 1, hi = lo + cell
            return layers.filter { $0.lo.x <= hi.x && $0.lo.y <= hi.y && $0.hi.x >= lo.x && $0.hi.y >= lo.y }
        }
        return Halftone.Panel(name: name, tones: { (p: P) -> Tone in
            let i = min(max(Int((p.x + 1) / cell), 0), n - 1), j = min(max(Int((p.y + 1) / cell), 0), n - 1)
            for l in grid[j * n + i] { if let t = l.tone(p) { return t } }
            return ground(p)
        }, strokes: strokes)
    }

    /// A circle as four quarter arcs, so each stroke's box stays small and the bake tests fewer segments a pixel.
    fileprivate static func rim(_ c: P, _ r: Double, _ width: Double = mid, _ n: Int = 12) -> [Halftone.Stroke] {
        (0..<4).map { stroke(arc(c, r, 90 * Double($0), 90 * Double($0) + 90, n), width) }
    }

    /// Strokes cut into pieces of n segments, so a long curve's box does not cover the whole of what it bends round,
    /// as the bake tests every segment of a stroke whose box holds the pixel.
    fileprivate static func pieces(_ strokes: [Halftone.Stroke], _ n: Int = 8) -> [Halftone.Stroke] {
        strokes.flatMap { s in
            stride(from: 0, to: s.points.count - 1, by: n).map { Halftone.Stroke(points: Array(s.points[$0...min($0 + n, s.points.count - 1)]), width: s.width) }
        }
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
        layers.append(Layer(spot - P(0.37, 0.37), spot + P(0.37, 0.37)) { p in
            // The spot's edge in tapering rays, long and short by turns.
            let d = p - spot, l = simd_length(d)
            guard l >= 0.264, l < 0.37 else { return nil }
            let a = (atan2(d.y, d.x) * 180 / .pi + 367).truncatingRemainder(dividingBy: 360) / 15
            let k = Int(a), off = abs(a - Double(k) - 0.5) * 2, reach = k % 2 == 0 ? 0.1 : 0.05
            return off < 1 - (l - 0.264) / reach ? y(0.6) : nil
        })
        layers += [layer(disc(wheel, 0.08, m(0.8))), layer(fill(tassel, y(0.9))), layer(disc(tieBack, 0.04, y(0.9))), layer(fill(valance, m(0.7)))]
        layers += [-0.55, -0.35, 0.35, 0.55, 0.75].map { layer(fill(arc(P($0, stage), 0.04, 180, 360, 8), y(0.9))) }
        layers.append(layer(fill(bar(barrels[0].2, barrels[1].2, 0.06), gilt)))
        for (a, ra, b, rb) in barrels {
            layers.append(layer(fill(bar(a + (b - a) * 0.78, a + (b - a) * 0.9, 2 * rb + 0.08), gilt)))
            layers.append(layer(fill(body(a, ra, b, rb), y(0.42))))
        }
        let folds = SIMD2(cos(0.25), sin(0.25))
        let drapeFill = fill(drape, .zero)
        layers.append(Layer(drapeFill.lo, drapeFill.hi) { p in
            guard drapeFill.holds(p) else { return nil }
            // The drape's folds: broad stripes leaning with the swag.
            let k = Int(((simd_dot(p, folds) + 2) / 0.1).rounded(.down))
            return k % 2 == 0 ? m(0.68) : m(0.36)
        })

        var s: [Halftone.Stroke] = []
        // The valance's scallops and fringe, the drape's edge and folds, the tie-back and its tassel.
        s += runs(Array(valance.dropLast(3)), mid) { simd_distance($0, far) > 0.33 }
        for k in 0..<24 where simd_distance(P(-1 + Double(k) / 12, -0.78), far) > 0.34 { s.append(stroke([P(-1 + Double(k) / 12, -0.8), P(-1 + Double(k) / 12, -0.75)], hair)) }
        s += pieces(runs(Array(drape.prefix(30)), bold) { simd_distance($0, far) > 0.33 })
        for k in 0..<6 {
            let x = -0.94 + 0.12 * Double(k)
            s += pieces(runs(curve(P(x + 0.1, -0.84), P(x + 0.02, -0.3), P(-0.7 + 0.01 * Double(k), 0.28), 24), hair) { simd_distance($0, far) > 0.33 })
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
        let domino: [[P]] = [curve(mask + P(-0.04, -0.008), mask + P(-0.02, -0.024), mask + P(0, -0.008), 8),
            curve(mask + P(0, -0.008), mask + P(0.02, -0.024), mask + P(0.04, -0.008), 8),
            curve(mask + P(0.04, -0.008), mask + P(0.03, 0.02), mask + P(0.008, 0.01), 8),
            curve(mask + P(0.008, 0.01), mask + P(0, 0.004), mask + P(-0.008, 0.01), 4),
            curve(mask + P(-0.008, 0.01), mask + P(-0.03, 0.02), mask + P(-0.04, -0.008), 8)]
        s.append(stroke(closed(Array(domino.joined())), 0.0034))
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
        s += pieces(runs(ellipse(P(0, -0.02), 0.62, 0.8, 96), bold) { $0.y > -0.7 && simd_distance($0, left) > 0.3 && simd_distance($0, right) > 0.3 })
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
        let pleats: [[P]] = (0..<9).map { (k: Int) -> [P] in
            let a0: Double = -150 + 12 * Double(k)
            return [fanPivot] + arc(fanPivot, 0.42, a0, a0 + 12, 4)
        }

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
        s += pieces([stroke(arc(fanPivot, 0.42, -150, -42, 24), mid)])
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

// MARK: - 35: Reading glasses

/// Level 35's name: a pair of browline reading glasses, folded and set down at bedtime on a closed storybook on the
/// bedside table, their glasses over the lower left and lower right cores (hex's two lenses on this level), a lamp,
/// an alarm clock and a glass of water at the back against the dark wall: through the left glass the first word of
/// the title, "Once", through the right the castle stamped on the cover. The lamp, the clock, the glass, the book's
/// edges, its gilt title plate and its marker are the broad shapes the five twisting rods turn.
extension LensArt {
    static let readingGlasses: Halftone.Panel = {
        let left = P(-0.485, 0.28), right = P(0.485, 0.28)
        let glass = c(0.5), cloth = m(0.72), gilt = y(0.88), wood = y(0.34), table = -0.3
        let book = turned(rect(-0.9, -0.12, 0.9, 0.8), about: P(0, 0.34), -3)
        let leaves = turned(rect(-0.88, 0.8, 0.88, 0.86), about: P(0, 0.34), -3)
        let title = turned(rect(-0.26, -0.04, 0.2, 0.07), about: P(0, 0.34), -3)
        let marker = bar(P(0.12, -0.08), P(0.2, -0.24), 0.05)
        let bridge = curve(polar(left, 0.3, -20), P(0, 0.1), polar(right, 0.3, 200), 12)
        let temples = [bar(polar(left, 0.3, 150), P(-0.1, 0.5), 0.032), bar(polar(right, 0.3, 30), P(0.1, 0.5), 0.032)]
        let shade = [P(-0.02, -1.05), P(0.36, -1.05), P(0.46, -0.7), P(-0.12, -0.7)], stem = bar(P(0.17, -0.7), P(0.17, -0.36), 0.05)
        let clock = P(-0.56, -0.42), tumbler = [P(0.46, -0.66), P(0.72, -0.66), P(0.69, -0.24), P(0.49, -0.24)]
        let water = [P(0.468, -0.52), P(0.712, -0.52), P(0.69, -0.24), P(0.49, -0.24)]
        let emblem = P(0.62, 0.6)

        var layers: [Layer] = [layer(disc(left, 0.264, glass)), layer(disc(right, 0.264, glass))]
        // Browline frames: a brow of tortoiseshell over the top of each glass, flecked unevenly, a gilt wire below.
        for c in [left, right] {
            layers.append(Layer(c - P(0.345, 0.345), c + P(0.345, 0.345)) { p in
                let d = p - c, l = simd_length(d)
                guard l >= 0.264, l < 0.345 else { return nil }
                if d.y > 0.02 { return l < 0.288 ? gilt : nil }
                let k = Int((atan2(d.y, d.x) * 180 / .pi + 400) / 9)
                return k % 4 == 1 || k % 7 == 3 ? Tone(0, 0.5, 0.65) : .zero
            })
        }
        layers.append(layer(fill(ribbon(bridge, 0.04, 0.04), .zero)))
        layers += temples.map { layer(fill($0, .zero)) }
        layers += [layer(fill(title, gilt)), layer(fill(star(emblem, 0.09, degrees: -80), gilt)), layer(fill(marker, y(0.9))),
                   layer(fill(book, cloth)), layer(fill(leaves, y(0.2))),
                   layer(disc(clock + P(0, 0.005), 0.13, Tone(0.3, 0.3, 0.3))), layer(disc(clock, 0.17, m(0.75))),
                   layer(disc(clock + P(-0.12, -0.15), 0.06, gilt)), layer(disc(clock + P(0.12, -0.15), 0.06, gilt)),
                   layer(fill(water, c(0.6))), layer(fill(tumbler, c(0.3))),
                   layer(fill(shade, gilt)), layer(fill(stem, m(0.6))), layer(oval(P(0.17, -0.35), 0.14, 0.045, m(0.6))),
                   layer(disc(P(0.17, -0.86), 0.5, c(0.3)))]

        var s: [Halftone.Stroke] = []
        // The table's edge and its grain; the lamp, the clock at ten to twelve, the glass and its water line.
        s.append(stroke([P(-1, table), P(1, table)], mid))
        for k in 0..<5 {
            let yy = table + 0.06 + 0.15 * Double(k) + 0.02 * Double(k % 2)
            s += runs(span(P(-1, yy), P(1, yy + 0.02), 40), hair) { !inside($0, book) && !inside($0, leaves) }
        }
        s.append(stroke(closed(shade), bold))
        for x in [0.06, 0.2, 0.32] { s.append(stroke([P(x, -1.0), P(x + 0.05 * (x - 0.17) / 0.17, -0.72)], hair)) }
        s.append(stroke(closed(stem), mid))
        s.append(stroke(ellipse(P(0.17, -0.35), 0.14, 0.045, 20), mid))
        s += rim(clock, 0.17, bold, 6)
        s += rim(clock + P(0, 0.005), 0.13, mid, 6)
        for k in 0..<12 { s.append(stroke([polar(clock, 0.1, 30 * Double(k)), polar(clock, 0.12, 30 * Double(k))], hair)) }
        s.append(stroke([clock, polar(clock, 0.09, -100)], bold))
        s.append(stroke([clock, polar(clock, 0.06, -60)], bold))
        for x in [-0.12, 0.12] { s += rim(clock + P(x, -0.15), 0.06, mid, 4) }
        s.append(stroke([clock + P(-0.1, 0.15), clock + P(-0.14, 0.2)], mid))
        s.append(stroke([clock + P(0.1, 0.15), clock + P(0.14, 0.2)], mid))
        s.append(stroke(closed(tumbler), mid))
        s.append(stroke([water[0], water[1]], hair))
        s.append(stroke(arc(P(0.62, -0.52), 0.05, 200, 320, 6), hair))
        // The book: its cover, the leaves' edge, a gilt rule round the cover, the title plate, the star, the marker.
        s.append(stroke(closed(book), bold))
        s.append(stroke(closed(leaves), mid))
        for k in 1..<8 { s.append(stroke([leaves[0] + (leaves[1] - leaves[0]) * (Double(k) / 8) + P(0, 0.015), leaves[0] + (leaves[1] - leaves[0]) * (Double(k) / 8 + 0.04) + P(0, 0.045)], hair)) }
        s += runs(span(turned([P(-0.84, -0.06)], about: P(0, 0.34), -3)[0], turned([P(0.84, -0.06)], about: P(0, 0.34), -3)[0], 40), hair) { simd_distance($0, left) > 0.35 && simd_distance($0, right) > 0.35 }
        s += runs(span(turned([P(-0.84, 0.74)], about: P(0, 0.34), -3)[0], turned([P(0.84, 0.74)], about: P(0, 0.34), -3)[0], 40), hair) { simd_distance($0, left) > 0.35 && simd_distance($0, right) > 0.35 }
        s.append(stroke(closed(title), mid))
        for k in 0..<4 { s.append(stroke([title[0] + P(0.06 + 0.1 * Double(k), 0.045), title[0] + P(0.12 + 0.1 * Double(k), 0.04)], mid)) }
        s.append(stroke(star(emblem, 0.09, degrees: -80), mid))
        s.append(stroke(closed(marker), hair))
        // The glasses: the frames, the bridge, the temples folded behind, a glint on each glass.
        for c in [left, right] {
            s += runs(circle(c, 0.345, 48), bold) { $0.y < c.y + 0.02 }
            s += rim(c, 0.264, mid)
            s.append(stroke(arc(c, 0.2, 200, 240, 10), mid))
            s.append(stroke(arc(c, 0.15, 205, 225, 6), hair))
        }
        s += runs(circle(left, 0.288, 40), mid) { $0.y > left.y + 0.02 }
        s += runs(circle(right, 0.288, 40), mid) { $0.y > right.y + 0.02 }
        s.append(stroke(closed(ribbon(bridge, 0.04, 0.04)), hair))
        for t in temples { s += runs(closed(t), hair) { simd_distance($0, left) > 0.345 && simd_distance($0, right) > 0.345 } }
        // Through the left glass: "Once", the first word of the title.
        let word = left + P(-0.002, -0.026)
        s.append(stroke(ellipse(word + P(-0.03, -0.012), 0.009, 0.013, 14), 0.0034))
        s.append(stroke([word + P(-0.014, 0), word + P(-0.014, -0.016)] + arc(word + P(-0.007, -0.01), 0.007, 180, 360, 6) + [word + P(0, 0)], 0.003))
        s.append(stroke(arc(word + P(0.013, -0.007), 0.007, 40, 320, 10), 0.003))
        s.append(stroke([word + P(0.024, -0.007), word + P(0.038, -0.007)] + arc(word + P(0.031, -0.007), 0.007, 0, -320, 10), 0.003))
        for x in [-0.03, 0.0, 0.03] { s.append(stroke([word + P(x - 0.012, -0.036), word + P(x + 0.008, -0.036)], 0.0016)) }
        // Through the right glass: the castle stamped on the cover, two towers and a flag, the gate and the hill.
        let keep = right + P(0.006, -0.028)
        s.append(stroke(closed([keep + P(-0.018, 0.006), keep + P(-0.018, -0.016), keep + P(0.022, -0.016), keep + P(0.022, 0.006)]), 0.003))
        for x in [-0.03, 0.022] {
            s.append(stroke([keep + P(x, 0.006), keep + P(x, -0.036), keep + P(x + 0.004, -0.036), keep + P(x + 0.004, -0.032),
                             keep + P(x + 0.008, -0.032), keep + P(x + 0.008, -0.036), keep + P(x + 0.012, -0.036), keep + P(x + 0.012, 0.006)], 0.0026))
        }
        s.append(stroke(arc(keep + P(0.002, 0.006), 0.007, 180, 360, 6), 0.0026))
        s.append(stroke([keep + P(-0.024, -0.036), keep + P(-0.024, -0.054)], 0.002))
        s.append(stroke(closed([keep + P(-0.024, -0.054), keep + P(-0.008, -0.049), keep + P(-0.024, -0.044)]), 0.002))
        s.append(stroke(curve(keep + P(-0.05, 0.01), keep + P(0, -0.0), keep + P(0.05, 0.012), 10), 0.002))
        return layered("readingglasses", layers, strokes: s) { p in p.y > table ? wood : c(0.14) }
    }()
}

// MARK: - 36: Diving mask

/// Level 36's name: a diver coming down head first through shafts of light, her yellow-skirted mask over the top core
/// and, on the sand below, an old lost mask over the bottom core (eye's two lenses on this level), an octopus moved in.
/// Through her glass her eyes, wide and looking down at it; through the old glass, the octopus's eye and a curled arm.
/// Her arms, the kelp, a shoal of yellow fish and the octopus's arms reaching out are the broad shapes the two
/// twisting rods turn, over the light's bands.
extension LensArt {
    static let divingMask: Halftone.Panel = {
        let top = P(0, -0.56), low = P(0, 0.56)
        let skin = m(0.4), skirt = y(0.85)
        let sand = curve(P(-1.05, 0.62), P(0, 0.46), P(1.05, 0.66), 24) + [P(1.05, 1.05), P(-1.05, 1.05)]
        let arms = [bar(P(-0.26, -0.5), P(-0.6, 0.0), 0.15), bar(P(0.26, -0.5), P(0.6, -0.06), 0.15)]
        let hands = [P(-0.64, 0.07), P(0.64, 0.0)]
        let snorkel = bar(P(-0.34, -0.42), P(-0.38, -1.05), 0.065), mouthpiece = bar(P(-0.34, -0.42), P(-0.17, -0.27), 0.06)
        let kelp = ribbon((0...20).map { k -> P in
            let t = Double(k) / 20
            return P(-0.86 + 0.08 * sin(t * 9), 0.95 - 1.4 * t)
        }, 0.16, 0.05)
        let tentacles = [ribbon(curve(P(-0.26, 0.48), P(-0.56, 0.5), P(-0.56, 0.3), 16) + curve(P(-0.56, 0.3), P(-0.55, 0.22), P(-0.47, 0.24), 6), 0.08, 0.02),
                         ribbon(curve(P(0.27, 0.62), P(0.5, 0.78), P(0.58, 0.6), 16) + curve(P(0.58, 0.6), P(0.6, 0.52), P(0.52, 0.53), 6), 0.07, 0.02)]
        let fish: [(P, Double)] = [(P(0.56, 0.2), 1), (P(0.76, 0.28), 0.9), (P(0.62, 0.36), 1.1), (P(0.82, 0.12), 0.8), (P(0.44, 0.3), 0.85)]

        var layers: [Layer] = [layer(disc(top, 0.264, skin)), layer(disc(low, 0.264, m(0.55)))]
        layers.append(Layer(top - P(0.4, 0.4), top + P(0.4, 0.4)) { p in
            // Her mask's skirt: the nose pocket bulging below, a clip either side where the strap meets it.
            let d = p - top, l = simd_length(d)
            guard l >= 0.264, l < 0.4 else { return nil }
            let a = atan2(d.y, d.x) * 180 / .pi
            if abs(a - 90) < 22 { return l < 0.38 ? skirt : nil }
            if abs(a) < 9 || abs(abs(a) - 180) < 9 { return l < 0.36 ? m(0.8) : nil }
            return l < 0.33 ? skirt : nil
        })
        // The old mask's skirt, rubber with dark seams.
        layers.append(segments(low, 0.264, 0.33, 16, [c(0.75), c(0.75), c(0.75), .zero], phase: 6))
        layers += tentacles.map { layer(fill($0, m(0.6))) }
        layers += [layer(fill(mouthpiece, m(0.8))), layer(fill(snorkel, m(0.8)))]
        layers += hands.map { layer(disc($0, 0.085, skirt)) }
        layers += [P(-0.26, -0.5), P(0.26, -0.5)].enumerated().map { k, s0 in layer(fill(bar(s0 + (k == 0 ? P(-0.04, 0.02) : P(0.04, 0.02)), (k == 0 ? P(-0.6, 0.0) : P(0.6, -0.06)) + (k == 0 ? P(-0.04, 0.02) : P(0.04, 0.02)), 0.035), y(0.85))) }
        layers += arms.map { layer(fill($0, .zero)) } + [layer(oval(top + P(0, -0.1), 0.34, 0.4, .zero))]
        for (at, k) in fish {
            layers.append(layer(oval(at, 0.06 * k, 0.026 * k, y(0.9))))
            layers.append(layer(fill([at + P(0.05, 0) * k, at + P(0.1, -0.03) * k, at + P(0.1, 0.03) * k], y(0.9))))
        }
        layers += [layer(fill(kelp, Tone(0.4, 0, 0.75))), layer(fill(bar(P(0.98, 1.0), P(0.95, 0.4), 0.2), Tone(0.4, 0, 0.75))),
                   layer(fill(sand, y(0.5)))]

        var s: [Halftone.Stroke] = []
        // The sand's ripples, the kelp's midrib, the fish, bubbles rising.
        for k in 0..<4 {
            let yy = 0.7 + 0.08 * Double(k)
            s += pieces(runs(curve(P(-1, yy), P(0, yy - 0.12), P(1, yy + 0.04), 40), hair) { p in simd_distance(p, low) > 0.34 && !tentacles.contains { inside(p, $0) } })
        }
        s += runs(Array(sand.prefix(25)), mid) { simd_distance($0, low) > 0.33 }
        s += pieces([stroke(closed(kelp), mid)])
        s.append(stroke((0...20).map { k -> P in
            let t = Double(k) / 20
            return P(-0.86 + 0.08 * sin(t * 9), 0.95 - 1.4 * t)
        }, hair))
        for (at, k) in fish {
            s.append(stroke(ellipse(at, 0.06 * k, 0.026 * k, 16), mid))
            s.append(stroke(closed([at + P(0.05, 0) * k, at + P(0.1, -0.03) * k, at + P(0.1, 0.03) * k]), hair))
            s.append(stroke(circle(at + P(-0.035, -0.004) * k, 0.006, 6), hair))
        }
        for (k, at) in [P(-0.4, -1.0), P(-0.42, -0.86), P(-0.36, -0.74), P(0.12, 0.34), P(0.18, 0.22), P(0.14, 0.1)].enumerated() {
            s += rim(at, 0.018 + 0.006 * Double(k % 3), hair, 3)
        }
        // The diver: hood, arms and gloves, snorkel; the mask's skirt, its strap and clips.
        s += pieces(runs(ellipse(top + P(0, -0.1), 0.34, 0.4, 48), mid) { simd_distance($0, top) > 0.4 })
        for a in arms {
            s.append(stroke([a[0], a[1]], mid))
            s.append(stroke([a[3], a[2]], mid))
        }
        for h in hands {
            s += rim(h, 0.085, mid, 4)
            for t in [200.0, 230, 260] { s.append(stroke([polar(h, 0.04, t), polar(h, 0.085, t)], hair)) }
        }
        s.append(stroke(closed(snorkel), mid))
        s.append(stroke(closed(mouthpiece), hair))
        s += rim(top, 0.264, mid)
        s += runs(circle(top, 0.33, 48), bold) { abs(atan2($0.y - top.y, $0.x - top.x) * 180 / .pi - 90) > 22 }
        s.append(stroke(arc(top, 0.38, 68, 112, 8), bold))
        s.append(stroke(arc(top, 0.2, 200, 240, 10), mid))
        s.append(stroke(arc(top, 0.15, 205, 225, 6), hair))
        // The old mask: its skirt, a broken strap, the octopus's arms and their suckers.
        s += rim(low, 0.264, mid)
        s += rim(low, 0.33, bold)
        s.append(stroke(closed(bar(polar(low, 0.33, -10), P(0.7, 0.44), 0.05)), mid))
        for t in tentacles {
            s.append(stroke(closed(t), mid))
            for k in stride(from: 2, to: 20, by: 3) { s.append(stroke(circle((t[k] + t[t.count - 1 - k]) / 2, 0.008, 6), hair)) }
        }
        // Through her glass: her eyes, wide, looking down at the octopus, brows up.
        let face = top + P(0.004, -0.032)
        for x in [-0.022, 0.022] {
            s.append(stroke(ellipse(face + P(x, 0), 0.014, 0.009, 16), 0.004))
            s.append(stroke(circle(face + P(x, 0.0045), 0.0035, 8), 0.0042))
            s.append(stroke(arc(face + P(x, -0.002), 0.017, 215, 325, 8), 0.0032))
        }
        s.append(stroke(curve(face + P(-0.006, 0.012), face + P(0, 0.02), face + P(0.006, 0.012), 6), 0.0022))
        // Through the old glass: the octopus's eye, its bar of a pupil, and an arm curled, suckers in a row.
        let octo = low + P(0.016, -0.026)
        s.append(stroke(ellipse(octo, 0.02, 0.014, 18), 0.0036))
        s.append(stroke([octo + P(-0.01, 0.001), octo + P(0.01, 0.001)], 0.0044))
        s.append(stroke(arc(octo + P(0, -0.004), 0.026, 200, 340, 10), 0.0024))
        let curl = spiral(low + P(-0.03, 0.012), 0.004, grow: 0.0012, turn: -24, 18)
        s.append(stroke(curl, 0.003))
        for k in stride(from: 6, to: 18, by: 3) { s.append(stroke(circle(curl[k] + simd_normalize(curl[k] - (low + P(-0.03, 0.012))) * 0.006, 0.0022, 6), 0.0016)) }
        return layered("divingmask", layers, strokes: s) { p in
            // Shafts of light slanting down through the water.
            Int((simd_dot(p, P(0.94, 0.34)) + 3) / 0.2) % 2 == 0 ? c(0.55) : c(0.36)
        }
    }()
}

// MARK: - 37: Contact lens

/// Level 37's name: a contact lens balanced on a fingertip over the top core, and its case open on the bathroom shelf
/// below, its two wells over the lower left and lower right cores (hex's three lenses on this level), marked L and R,
/// their caps beside them, a bar of soap on the tiles. Through the lens on the finger, the fingerprint's loops; in the L
/// well, the top of an eye chart; in the R well, an eye. The finger, the case's edges, its caps and the soap, over pink
/// tiles in two tones, are the broad shapes the four twisting rods turn.
extension LensArt {
    static let contactLens: Halftone.Panel = {
        let tip = P(0, -0.56), l = P(-0.485, 0.28), r = P(0.485, 0.28)
        let skin = Tone(0, 0.32, 0.56), tint = c(0.55), plastic = y(0.75)
        let finger = bar(tip, P(1.15, -0.98), 0.62), middle = bar(P(0.6, -0.36), P(1.2, -0.62), 0.3)
        let caseBody = bar(l, r, 0.72)
        let caps = [P(-0.22, 0.83), P(0.26, 0.85)]
        let soap = squircle(P(-0.62, -0.36), 0.17, 0.09, degrees: -20, 32)

        var layers: [Layer] = [layer(disc(tip, 0.264, tint)), layer(disc(l, 0.264, tint)), layer(disc(r, 0.264, tint))]
        // The lens's edge catching the light by turns; the wells' threads, cyan for L and magenta for R.
        layers.append(segments(tip, 0.264, 0.3, 22, [c(0.85), Tone(0.3, 0.3, 0.6), c(0.85), skin], phase: 8))
        layers.append(segments(l, 0.264, 0.33, 24, [c(0.85), c(0.85), .zero], phase: 3))
        layers.append(segments(r, 0.264, 0.33, 24, [m(0.85), m(0.85), .zero], phase: 9))
        layers += [layer(disc(tip, 0.31, skin)), layer(fill(finger, skin)), layer(disc(P(0.6, -0.36), 0.15, Tone(0, 0.42, 0.5))), layer(fill(middle, Tone(0, 0.42, 0.5))),
                   layer(disc(caps[0], 0.11, c(0.75))), layer(disc(caps[1], 0.11, m(0.75))),
                   layer(disc(l, 0.36, plastic)), layer(disc(r, 0.36, plastic)), layer(fill(caseBody, plastic)),
                   layer(fill(soap, c(0.45)))]

        var s: [Halftone.Stroke] = []
        // The tiles' grout, kept off everything on them, and a few drops of water.
        func clear(_ p: P) -> Bool {
            simd_distance(p, tip) > 0.31 && !inside(p, finger) && !inside(p, middle) && simd_distance(p, P(0.6, -0.36)) > 0.15 && !inside(p, caseBody) && simd_distance(p, l) > 0.36
                && simd_distance(p, r) > 0.36 && !inside(p, soap) && caps.allSatisfy { simd_distance(p, $0) > 0.11 }
        }
        for k in 0..<9 {
            let v = -0.97 + 0.24 * Double(k) + 0.05
            s += runs(span(P(v, -1), P(v, 1), 80), hair, keep: clear)
            s += runs(span(P(-1, v + 0.04), P(1, v + 0.04), 80), hair, keep: clear)
        }
        for at in [P(0.3, 0.02), P(-0.18, -0.12), P(0.7, -0.08), P(-0.8, 0.0)] {
            s.append(stroke(closed(arc(at, 0.022, 0, 180, 8) + [at + P(0, -0.04)]), mid))
        }
        // The finger: its edge, the crease of its last joint, the whorl of its print round the lens.
        s.append(stroke([finger[0], finger[1]], bold))
        s.append(stroke([finger[3], finger[2]], bold))
        s += runs(circle(tip, 0.31, 48), bold) { !inside($0, finger) }
        s += runs(arc(P(0.6, -0.36), 0.15, 90, 270, 16) + [middle[2]], bold) { !inside($0, finger) }
        s += runs(span(middle[0], middle[1], 20), bold) { !inside($0, finger) }
        let along = simd_normalize(P(1.15, -0.98) - tip), across = P(-along.y, along.x)
        for d in [0.5, 0.55] { s.append(stroke(curve(tip + along * d + across * 0.28, tip + along * (d - 0.04), tip + along * d - across * 0.28, 10), mid)) }
        for k in 0..<3 { s += pieces(runs(arc(tip, 0.36 + 0.035 * Double(k), 60, 300, 30), hair) { inside($0, finger) || simd_distance($0, tip) < 0.31 }) }
        // The lens's edge.
        s += rim(tip, 0.3, mid)
        s += rim(tip, 0.264, hair)
        s.append(stroke(arc(tip, 0.2, 200, 240, 10), mid))
        // The case: its outline, the wells' rims, L and R, the caps knurled; the soap's edge and a bubble.
        s.append(stroke(arc(l, 0.36, 90, 270, 24) + arc(r, 0.36, -90, 90, 24) + [l + P(0, 0.36)], bold))
        for c in [l, r] {
            s += rim(c, 0.33, mid)
            s += rim(c, 0.264, mid)
            s.append(stroke(arc(c, 0.2, 200, 240, 10), mid))
        }
        s.append(stroke([P(-0.2, 0.34), P(-0.2, 0.46), P(-0.13, 0.46)], bold))
        s.append(stroke([P(0.13, 0.46), P(0.13, 0.34)] + arc(P(0.15, 0.37), 0.03, -90, 90, 8) + [P(0.13, 0.4), P(0.2, 0.46)], bold))
        for c in caps {
            s += rim(c, 0.11, bold, 6)
            for k in 0..<12 { s.append(stroke([polar(c, 0.08, 30 * Double(k)), polar(c, 0.1, 30 * Double(k))], hair)) }
        }
        s.append(stroke(closed(soap), mid))
        s.append(stroke(turned(ellipse(P(-0.62, -0.36), 0.1, 0.04, 20), about: P(-0.62, -0.36), -20), hair))
        for at in [P(-0.84, -0.52), P(-0.4, -0.5)] { s += rim(at, 0.025, hair, 3) }
        // Through the lens on the finger: the print's loops, open to one side.
        let print = tip + P(0.012, -0.03)
        for k in 0..<4 {
            let rr = 0.006 + 0.0075 * Double(k)
            let reach: Double = rr * cos(Double.pi / 6) + 0.014
            let tail: P = print + P(reach, rr * 0.5 + 0.026)
            s.append(stroke(arc(print, rr, 150, 390, 12) + [tail], 0.0022))
        }
        // In the L well: an eye chart's E, and F and P under it.
        let chart = l + P(0.004, -0.024)
        s.append(stroke([chart + P(0.016, -0.05), chart + P(-0.006, -0.05), chart + P(-0.006, -0.022), chart + P(0.016, -0.022)], 0.0036))
        s.append(stroke([chart + P(-0.006, -0.036), chart + P(0.012, -0.036)], 0.0036))
        s.append(stroke([chart + P(-0.006, 0.006), chart + P(-0.006, -0.012), chart + P(0.004, -0.012)], 0.0026))
        s.append(stroke([chart + P(-0.006, -0.003), chart + P(0.002, -0.003)], 0.0026))
        s.append(stroke([chart + P(0.012, 0.006), chart + P(0.012, -0.012)] + arc(chart + P(0.015, -0.0075), 0.0045, -90, 90, 6) + [chart + P(0.012, -0.003)], 0.0026))
        // In the R well: an eye, its iris and pupil, a gleam, lashes on the upper lid.
        let eye = r + P(0.01, -0.036)
        let lid = curve(eye + P(-0.036, 0.006), eye + P(0, -0.03), eye + P(0.036, 0.006), 12)
        s.append(stroke(lid + curve(eye + P(0.036, 0.006), eye + P(0, 0.028), eye + P(-0.036, 0.006), 12), 0.0032))
        s.append(stroke(circle(eye + P(0, 0.002), 0.011, 14), 0.003))
        s.append(stroke(circle(eye + P(0, 0.002), 0.004, 8), 0.0044))
        s.append(stroke(circle(eye + P(0.005, -0.004), 0.0015, 4), 0.0016))
        for k in stride(from: 2, to: 12, by: 2) { s.append(stroke([lid[k], lid[k] + simd_normalize(lid[k] - eye - P(0, 0.02)) * 0.01], 0.0018)) }
        return layered("contactlens", layers, strokes: s) { p in
            // Pink tiles in two tones, set off the hub's centre.
            let i = Int((p.x + 2.05) / 0.24), j = Int((p.y + 2.01) / 0.24)
            return (i + j) % 2 == 0 ? m(0.36) : m(0.2)
        }
    }()
}
