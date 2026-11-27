// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 14, Tourbillon: problems 79 to 84's plates, drawn with `Kit`. Every one is on hex with a two-card hub, so
/// the part each is named for keeps 0.195 clear of the middle and of the six rods at 0.56.
extension EscapementArt {
    /// A closed outline through `points`, each corner rounded by a quadratic.
    private static func smooth(_ points: [P], _ n: Int = 8) -> [P] {
        var out: [P] = []
        for i in points.indices {
            let a = (points[(i + points.count - 1) % points.count] + points[i]) / 2
            let b = (points[i] + points[(i + 1) % points.count]) / 2
            out += curve(a, points[i], b, n).dropLast()
        }
        return out + [out[0]]
    }

    /// A drop of water hanging point up, its belly at `c`.
    private static func drop(_ c: P, _ r: Double) -> [P] {
        let belly = arc(c, r, from: -0.25, to: .pi + 0.25)
        return [c + P(0, -2.3 * r)] + belly + [c + P(0, -2.3 * r)]
    }

    /// Problem 79, Water clock, hex, clocks 1-: a clepsydra. An urn hung from a beam drips through its cock into a
    /// basin whose float lifts a pointer up a column ruled with the hours; the falling drop in the second ink.
    static func plate79() -> Plate {
        var plate = Plate()
        let spoutX = -0.22, surface = 0.13, rodX = 0.04, arm = -0.23
        let beam = box(P(-0.5, -0.89), P(0.7, -0.8))
        let column = box(P(0.43, -0.8), P(0.63, 0.66))
        let urn = smooth([P(-0.52, -0.79), P(0.08, -0.79), P(0.02, -0.73), P(0.08, -0.6), P(-0.04, -0.47),
                          P(spoutX + 0.04, -0.44), P(spoutX - 0.04, -0.44), P(-0.4, -0.47), P(-0.52, -0.6), P(-0.46, -0.73)], 10)
        let basin = box(P(-0.5, -0.12), P(0.24, 0.71))

        Kit.ground(&plate, angle: -0.5, around: [beam, column, urn, basin])

        // The column: two rails, the hours between them rising from the foot as the water fills.
        Kit.cut(&plate, column)
        for x in [0.455, 0.605] { Kit.mass(&plate, box(P(x - 0.025, -0.8), P(x + 0.025, 0.66))) }
        for k in 1...12 {
            let y = 0.55 - Double(k - 1) * 0.112
            Kit.mass(&plate, box(P(0.48, y + 0.048), P(0.53, y + 0.062)))
            plate.lines(Kit.numeral(roman(k), at: P(0.545, y), height: 0.05, squeeze: 0.7), heavy)
        }
        Kit.mass(&plate, box(P(0.39, -0.8), P(0.67, -0.74)))
        Kit.mass(&plate, box(P(0.39, 0.62), P(0.67, 0.7)))

        // The beam, the urn's straps and the urn, fluted in ink and bone.
        Kit.mass(&plate, beam)
        plate.line([P(-0.48, -0.85), P(0.68, -0.85)], 0.012, .bone)
        for x in [-0.42, -0.02] { Kit.mass(&plate, box(P(x - 0.02, -0.8), P(x + 0.02, -0.74))) }
        Kit.cut(&plate, urn)
        let flutes = hatch([urn], angle: 0, gap: 0.09, shift: 0.3)
        for f in flutes where f.count == 2 {
            Kit.mass(&plate, Kit.band(f[0], f[1], 0.03))
        }
        plate.line(urn, 0.03)
        Kit.mass(&plate, box(P(-0.55, -0.81), P(0.11, -0.77)))
        // The cock, hatched in section, and its key.
        Kit.solid(&plate, box(P(spoutX - 0.035, -0.45), P(spoutX + 0.035, -0.38)), angle: 0.8, gap: 0.014, width: fine)
        Kit.mass(&plate, Kit.band(P(spoutX - 0.09, -0.415), P(spoutX + 0.09, -0.415), 0.022))
        Kit.mass(&plate, box(P(spoutX - 0.012, -0.38), P(spoutX + 0.012, -0.355)))

        // The basin's walls, its water in bold ripples and the float riding it.
        Kit.cut(&plate, basin)
        for k in 0..<5 {
            let y = surface + 0.01 + Double(k) * 0.12
            let wave = (0...40).map { i in P(-0.43 + 0.6 * Double(i) / 40, y + 0.008 * sin(Double(i) * 0.7 + Double(k))) }
            Kit.mass(&plate, Kit.ribbon(wave, k == 0 ? 0.04 : 0.03))
        }
        for r in [0.04, 0.075] { plate.line(ellipse(P(spoutX, surface - 0.005), r, 0.28 * r, from: .pi + 0.3, to: 2 * .pi - 0.3), medium) }
        Kit.mass(&plate, box(P(-0.5, -0.12), P(-0.43, 0.71)))
        Kit.mass(&plate, box(P(0.17, -0.12), P(0.24, 0.71)))
        Kit.mass(&plate, box(P(-0.5, 0.675), P(0.24, 0.71)))
        for x in [-0.465, 0.205] { plate.line([P(x, -0.1), P(x, 0.65)], heavy, .bone) }
        Kit.mass(&plate, box(P(-0.54, -0.15), P(-0.39, -0.11)))
        Kit.mass(&plate, box(P(0.13, -0.15), P(0.28, -0.11)))
        for x in [-0.465, 0.205] {
            Kit.mass(&plate, smooth([P(x - 0.07, 0.83), P(x - 0.04, 0.71), P(x + 0.04, 0.71), P(x + 0.07, 0.83)], 3))
        }
        Kit.mass(&plate, Kit.band(P(rodX, surface - 0.07), P(rodX, arm), 0.036))
        Kit.solid(&plate, smooth([P(-0.06, surface - 0.075), P(0.14, surface - 0.075), P(0.15, surface + 0.03), P(-0.07, surface + 0.03)], 4),
                  angle: 0.7, gap: 0.016, width: fine, edge: heavy)
        Kit.mass(&plate, Kit.band(P(rodX - 0.02, arm), P(0.37, arm), 0.04))
        Kit.mass(&plate, Kit.barb(P(0.47, arm), toward: 0, size: 0.1))
        plate.fill(arc(P(rodX, arm), 0.018))
        plate.line(arc(P(rodX, arm), 0.018), medium)

        plate.fill(drop(P(spoutX, -0.27), 0.024), .second)
        plate.line(drop(P(spoutX, -0.27), 0.024), fine)
        plate.lines(dashed([P(spoutX, -0.22), P(spoutX, surface - 0.04)], on: 0.03, off: 0.04), fine)

        callout(&plate, "A", from: P(-0.47, -0.62), to: P(-0.68, -0.44))
        callout(&plate, "B", from: P(-0.3, 0.4), to: P(-0.7, 0.5))
        callout(&plate, "C", from: P(0.12, surface - 0.03), to: P(0.3, 0.04))
        callout(&plate, "D", from: P(0.62, 0.2), to: P(0.8, 0.04))
        return plate
    }

    /// A flame's outline, its base at `c`, `h` tall, licking a little to the right.
    private static func flame(_ c: P, _ h: Double, _ w: Double) -> [P] {
        let tip = c + P(0.12 * w, -h)
        return curve(tip, c + P(0.9 * w, -0.35 * h), c + P(0.05 * w, 0.02 * h), 16)
            + curve(c + P(0.05 * w, 0.02 * h), c + P(-0.95 * w, -0.25 * h), tip, 16).dropFirst()
    }

    /// Problem 80, Candle clock, hex, clocks 1-: a tall candle in a pricket stick, banded in ink with the hours, burned
    /// past the third into the fourth, the burned length ghosted above it and its light thrown out in rays across the
    /// night; the flame in the second ink.
    static func plate80() -> Plate {
        var plate = Plate()
        let x = -0.2, half = 0.1, top = -0.22, foot = 0.56, wick = top - 0.03
        let light = P(x, top - 0.09)

        // The light, ink rays with a hairline down each bone one between.
        let n = 30
        for k in 0..<n {
            let a = 2 * .pi * Double(k) / Double(n) + 0.04
            let b = a + 0.68 * .pi / Double(n)
            plate.fill([polar(light, 0.16, a), polar(light, 2.2, a), polar(light, 2.2, b), polar(light, 0.16, b), polar(light, 0.16, a)], .black)
            plate.line([polar(light, 0.3, a + 1.34 * .pi / Double(n)), polar(light, 2.2, a + 1.34 * .pi / Double(n))], fine)
        }
        for r in [0.1, 0.13] { plate.line(arc(light, r), fine) }

        // The burned length, ghosted: the candle's first three hours.
        let gone = top - 3 * 0.085
        plate.fill(box(P(x - half, gone), P(x + half, top - 0.012)))
        plate.lines(dashed(box(P(x - half, gone), P(x + half, top - 0.012)), on: 0.025, off: 0.02), medium)
        for k in 1...2 {
            plate.lines(dashed([P(x - half, gone + Double(k) * 0.085), P(x + half, gone + Double(k) * 0.085)], on: 0.02, off: 0.02), fine)
        }

        // The candle: bone, its hours banded in ink and numbered, the fourth now burning; shaded down its right side.
        let body = [P(x - half, top + 0.01), P(x - 0.05, top - 0.012), P(x + 0.05, top - 0.012), P(x + half, top + 0.01),
                    P(x + half, foot), P(x - half, foot), P(x - half, top + 0.01)]
        Kit.cut(&plate, body, edge: 0.016)
        plate.lines(hatch([box(P(x + half - 0.045, top + 0.02), P(x + half, foot))], angle: .pi / 2, gap: 0.014), fine)
        for k in 1...9 {
            let y = top + Double(k) * 0.085
            Kit.mass(&plate, Kit.ribbon(curve(P(x - half, y - 0.01), P(x, y + 0.012), P(x + half, y - 0.01), 10), 0.022))
            plate.lines(Kit.numeral(roman(3 + k), at: P(x - 0.012, y - 0.047), height: 0.034, squeeze: 0.72), heavy)
        }
        // Wax run down its left side and pooled.
        let run = smooth([P(x - half - 0.01, top + 0.005), P(x - half + 0.03, top + 0.0), P(x - half + 0.02, top + 0.13),
                          P(x - half - 0.005, top + 0.17), P(x - half - 0.02, top + 0.1)], 5)
        Kit.cut(&plate, run, edge: heavy)

        // The wick.
        plate.line([P(x, top - 0.01), P(x + 0.006, wick), P(x + 0.014, wick - 0.012)], 0.012)

        // The pricket stick: pan, baluster, foot and a ring to carry it by.
        let pan = ellipse(P(x, foot + 0.03), 0.28, 0.055)
        plate.line(pan, 0.05, .bone)
        Kit.solid(&plate, pan, angle: 0.4, gap: 0.022, edge: 0.03)
        Kit.mass(&plate, Kit.ribbon(ellipse(P(x, foot + 0.03), 0.25, 0.04, from: 0.15, to: .pi - 0.15), 0.025))
        let stem = smooth([P(x - 0.04, foot + 0.07), P(x + 0.04, foot + 0.07), P(x + 0.09, foot + 0.15), P(x + 0.03, foot + 0.2),
                           P(x + 0.06, foot + 0.27), P(x - 0.06, foot + 0.27), P(x - 0.03, foot + 0.2), P(x - 0.09, foot + 0.15)], 6)
        plate.line(stem, 0.04, .bone)
        Kit.mass(&plate, stem)
        plate.line(curve(P(x + 0.05, foot + 0.11), P(x + 0.075, foot + 0.15), P(x + 0.035, foot + 0.19)), heavy, .bone)
        let base = ellipse(P(x, foot + 0.3), 0.24, 0.06)
        plate.line(base, 0.05, .bone)
        Kit.mass(&plate, base)
        plate.line(ellipse(P(x, foot + 0.3), 0.2, 0.035, from: 0.2, to: .pi - 0.2), heavy, .bone)
        let ring = P(x + 0.37, foot + 0.04)
        plate.line(arc(ring, 0.07), 0.07, .bone)
        plate.line(arc(ring, 0.07), 0.035)
        Kit.mass(&plate, Kit.band(P(x + 0.26, foot + 0.04), P(x + 0.31, foot + 0.04), 0.03))

        let tongue = flame(P(x + 0.01, wick + 0.01), 0.13, 0.045)
        plate.line(tongue, 0.03, .bone)
        plate.fill(tongue, .second)
        plate.line(tongue, fine)
        plate.fill(flame(P(x + 0.01, wick), 0.05, 0.016))

        callout(&plate, "A", from: P(x, gone + 0.03), to: P(-0.46, -0.66))
        callout(&plate, "B", from: P(x + 0.06, top + 0.25), to: P(0.26, 0.14))
        callout(&plate, "C", from: P(x - 0.25, foot + 0.04), to: P(-0.68, 0.44))
        callout(&plate, "D", from: P(x + 0.2, foot + 0.32), to: P(0.4, 0.8))
        return plate
    }

    /// Problem 81, Nocturnal, hex, clocks 1-.
    static func plate81() -> Plate? { nil }

    /// Problem 82, Astrolabe, hex, clocks 1-.
    static func plate82() -> Plate? { nil }

    /// Problem 83, Night watch, hex, clocks 1-.
    static func plate83() -> Plate? { nil }

    /// Problem 84, Small hours, hex, clocks 1-.
    static func plate84() -> Plate? { nil }
}
