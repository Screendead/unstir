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

    /// Problem 80, Candle clock, hex, clocks 1-.
    static func plate80() -> Plate? { nil }

    /// Problem 81, Nocturnal, hex, clocks 1-.
    static func plate81() -> Plate? { nil }

    /// Problem 82, Astrolabe, hex, clocks 1-.
    static func plate82() -> Plate? { nil }

    /// Problem 83, Night watch, hex, clocks 1-.
    static func plate83() -> Plate? { nil }

    /// Problem 84, Small hours, hex, clocks 1-.
    static func plate84() -> Plate? { nil }
}
