// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 11, Gear Train: problems 61 to 66's plates, drawn with `Kit`.
extension EscapementArt {
    /// Problem 61, Pinion, hex, clocks 1+,2+: a long pinion in elevation between the movement's two plates cut in
    /// section, its leaves fluted in bold ink along the lane at three o'clock, its arbor carrying a wheel seen nearly
    /// edge on, each pivot running in a jewel set in its chaton; the right-hand jewel in the second ink.
    static func plate61() -> Plate {
        var plate = Plate()
        let r = 0.084, x0 = 0.205, x1 = 0.665, shaft = 0.046
        let inner = 0.775
        // The movement's plates in section, cut by the glass, and the pillars that hold them apart.
        let plates = [-1.0, 1.0].map { s in [P(s * inner, -1.2), P(s * 1.2, -1.2), P(s * 1.2, 1.2), P(s * inner, 1.2), P(s * inner, -1.2)] }
        let pillars = [-1.0, 1.0].map { s in Kit.band(P(-inner, s * 0.84), P(inner, s * 0.84), 0.07) }
        let pinion = box(P(x0, -r), P(x1, r))
        let wheel = ellipse(P(-0.42, 0), 0.1, 0.66)

        Kit.ground(&plate, angle: 0.35, around: plates + pillars + [pinion, wheel])

        for slab in plates {
            Kit.mass(&plate, slab)
            let s = slab[0].x < 0 ? -1.0 : 1.0
            plate.line([P(s * (inner + 0.022), -1), P(s * (inner + 0.022), 1)], fine, .bone)
            // A screw through each plate into its pillar's end.
            for y in [-0.47, 0.47] {
                let c = P(s * 0.86, y)
                Kit.cut(&plate, box(c - P(0.05, 0.028), c + P(0.05, 0.028)))
                plate.lines(hatch([box(c - P(0.05, 0.028), c + P(0.05, 0.028))], angle: 0.8, gap: 0.012), fine)
                plate.line([c - P(0.05, 0), c + P(0.05, 0)], medium)
            }
        }
        for pillar in pillars {
            Kit.mass(&plate, pillar)
            plate.line([pillar[0] + P(0, 0.016), pillar[1] + P(0, 0.016)], fine, .bone)
            let y = (pillar[0].y + pillar[3].y) / 2
            for x in [-0.42, -0.36, 0.0, 0.36, 0.42] {
                let collar = box(P(x - 0.018, y - 0.058), P(x + 0.018, y + 0.058))
                Kit.solid(&plate, collar, angle: 0.8, gap: 0.012)
            }
        }

        // The wheel the arbor carries, turned almost edge on: a heavy rim, its teeth, four crossings.
        let rimOut = ellipse(P(-0.42, 0), 0.1, 0.66), rimIn = ellipse(P(-0.42, 0), 0.082, 0.58)
        plate.fill(rimOut, .black)
        plate.fill(rimIn)
        plate.lines(hatch([rimIn], angle: 0.35, gap: Kit.groundGap), Kit.groundWidth)
        for k in 0..<4 {
            let a = Double(k) * .pi / 2 + .pi / 4
            let tip = P(-0.42 + 0.082 * cos(a), 0.58 * sin(a))
            Kit.mass(&plate, Kit.band(P(-0.42, 0), tip, 0.036))
        }
        for k in 0..<40 {
            let a = Double(k) * 2 * .pi / 40
            guard cos(a) < 0.2 else { continue }
            let foot = P(-0.42 + 0.1 * cos(a), 0.66 * sin(a)), d = simd_normalize(P(0.1 * cos(a) / 0.01, 0.66 * sin(a) / 0.4356))
            Kit.mass(&plate, Kit.band(foot - d * 0.005, foot + d * 0.028, 0.024))
        }
        plate.line(rimOut, medium)
        plate.line(ellipse(P(-0.42, 0), 0.093, 0.62, from: .pi / 2, to: 1.5 * .pi), fine, .bone)
        // The wheel's collet on the arbor, in section.
        let collet = box(P(-0.5, -0.075), P(-0.36, 0.075))
        Kit.solid(&plate, collet, angle: 0.8, gap: 0.014)

        // The arbor, from jewel to jewel, its pivots drawn down to points.
        let arbor = [P(-0.73, -shaft / 2), P(x0, -shaft / 2), P(x0, shaft / 2), P(-0.73, shaft / 2), P(-0.73, -shaft / 2)]
        Kit.mass(&plate, arbor)
        Kit.mass(&plate, box(P(x1, -shaft / 2), P(0.73, shaft / 2)))
        plate.line([P(-0.72, -0.009), P(x0 - 0.01, -0.009)], fine, .bone)
        plate.line([P(x1 + 0.01, -0.009), P(0.72, -0.009)], fine, .bone)
        Kit.mass(&plate, box(P(-0.36, -0.04), P(-0.33, 0.04)))
        for s in [-1.0, 1.0] {
            let shoulder = P(s * 0.73, 0), point = P(s * 0.865, 0)
            Kit.mass(&plate, [shoulder + P(0, -shaft / 2), point + P(0, -0.009), point + P(0, 0.009), shoulder + P(0, shaft / 2),
                              shoulder + P(0, -shaft / 2)])
        }

        // The jewels: each a stone set in a chaton cut into the plate, the arbor's pivot point in its hole.
        for s in [-1.0, 1.0] {
            let c = P(s * 0.865, 0)
            let chaton = box(c - P(0.07, 0.13), c + P(0.07, 0.13))
            Kit.solid(&plate, chaton, angle: -0.8, gap: 0.012)
            let stone = [c + P(-0.035, -0.085), c + P(0.035, -0.085), c + P(0.05, 0), c + P(0.035, 0.085), c + P(-0.035, 0.085),
                         c + P(-0.05, 0), c + P(-0.035, -0.085)]
            if s > 0 {
                plate.fill(stone, .second)
                plate.lines(hatch([stone], angle: 0.6, gap: 0.016), fine, .bone)
                plate.line(stone, medium)
            } else {
                Kit.cut(&plate, stone)
                plate.lines(hatch([stone], angle: 0.6, gap: 0.016), fine)
            }
            plate.fill(arc(c, 0.012), .bone)
            plate.line(arc(c, 0.012), fine)
        }

        // The pinion: its leaves fluted along the arbor, the spaces between them in ink, an end face showing their profile.
        plate.fill(pinion, .black)
        let leaves = 8, tooth = 0.2
        for k in 0..<leaves {
            let phi = 0.18 + Double(k) * 2 * .pi / Double(leaves)
            let a = atan2(sin(phi), cos(phi))
            guard cos(a) > 0 else { continue }
            let y0 = r * sin(max(a - tooth, -.pi / 2)), y1 = r * sin(min(a + tooth, .pi / 2))
            let face = box(P(x0 + 0.018, min(y0, y1)), P(x1 - 0.018, max(y0, y1)))
            Kit.cut(&plate, face)
            if sin(a) > 0.2 {
                plate.lines(hatch([face], angle: 0, gap: 0.011), fine)
            }
        }
        plate.line(pinion, medium)
        // The end face, turned a little toward the eye: the leaves' profile, the spaces between them in ink.
        Kit.cut(&plate, ellipse(P(x0, 0), 0.02, r))
        let end = P(x1, 0)
        plate.fill(ellipse(end, 0.048, r + 0.004), .black)
        var face: [P] = []
        for i in 0...96 {
            let a = Double(i) * 2 * .pi / 96
            let lobe = 0.5 + 0.5 * cos(Double(leaves) * (a - 0.18))
            let rad = 0.58 + 0.42 * pow(lobe, 0.45)
            face.append(end + P(0.048 * rad * cos(a), r * rad * sin(a)))
        }
        Kit.cut(&plate, face)
        plate.lines(hatch([face, ellipse(end, 0.016, 0.03)], angle: 1.2, gap: 0.01), fine)
        Kit.mass(&plate, ellipse(end, 0.012, 0.024))

        callout(&plate, "A", from: P(0.44, -0.05), to: P(0.31, -0.5))
        callout(&plate, "B", from: P(0.865, 0.06), to: P(0.66, 0.62))
        callout(&plate, "C", from: P(-0.43, 0.62), to: P(-0.22, 0.86))
        callout(&plate, "D", from: P(-0.81, 0), to: P(-0.62, -0.66))
        return plate
    }

    /// Problem 62, Arbor, pent, clocks 0+,1-.
    static func plate62() -> Plate? { nil }

    /// Problem 63, Third wheel, hex, clocks 1-,2-.
    static func plate63() -> Plate? { nil }

    /// Problem 64, Barrel, hex, clocks 1+,2-.
    static func plate64() -> Plate? { nil }

    /// Problem 65, Motion work, hex, clocks 1-,2-.
    static func plate65() -> Plate? { nil }

    /// Problem 66, Centre wheel, hex, clocks 1+,2+.
    static func plate66() -> Plate? { nil }
}
