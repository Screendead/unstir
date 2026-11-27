// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 6, Long Count: problems 31 to 36's plates, drawn with `Kit`.
extension EscapementArt {
    /// Problem 31, Hairspring, pent, clocks 0+: a hairspring lifted from the movement in watchmaker's tweezers, its
    /// coils hanging below as a cone seen from above, the near half of each turn heavy over the far, its collet a ring
    /// at the bottom; the bridge plate it came out of in the corner, striped. The stud pin at the spring's outer end,
    /// in the tweezers' tips, is in the second ink.
    static func plate31() -> Plate {
        var plate = Plate()
        let tip = P(0, -0.3), up = simd_normalize(P(0.74, -0.67)), across = P(-up.y, up.x)
        let length = 1.5
        // Each blade by its distance from the tips: half its width, and how far its middle stands off the axis.
        func blade(_ side: Double) -> [P] {
            let steps = (0...60).map { length * Double($0) / 60 }
            func half(_ s: Double) -> Double { 0.012 + 0.06 * min(1, pow(s / 0.5, 0.7)) }
            func off(_ s: Double) -> Double { 0.026 + 0.04 * min(1, s / 0.9) + half(s) }
            let outer = steps.map { tip + up * $0 + across * (side * (off($0) + half($0))) }
            let inner = steps.map { tip + up * $0 + across * (side * (off($0) - half($0))) }
            return [tip + across * (side * 0.026)] + outer + inner.reversed() + [tip + across * (side * 0.026)]
        }
        let blades = [blade(1), blade(-1)]

        // The spring seen flat as it hangs from its outer end: three and a half turns, each turn's middle a little
        // lower than the last, so the turns crowd under the stud and open out below.
        let centre = P(0, 0.055), outer = 0.335, inner = 0.1, turns = 3.5, sag = 0.07, n = 700
        let coil = (0...n).map { i -> P in
            let t = Double(i) / Double(n)
            return polar(centre + P(0, sag * t), outer - (outer - inner) * t, -.pi / 2 + 2 * .pi * turns * t)
        }
        let collet = centre + P(0, sag)
        // The bridge the spring was lifted from, cropped by the glass at seven o'clock.
        let bridgeCentre = P(-1.2, 1.17), bridge = arc(bridgeCentre, 1.0)
        Kit.ground(&plate, angle: 0.38, around: [bridge])
        Kit.mass(&plate, bridge)
        plate.lines(hatch([arc(bridgeCentre, 0.93)], angle: -0.75, gap: 0.1), 0.045, .bone)
        plate.line(arc(bridgeCentre, 0.955), medium, .bone)
        let seat = P(-0.63, 0.68)
        plate.fill(arc(seat, 0.2))
        plate.line(arc(seat, 0.2), heavy)
        plate.lines(hatch([arc(seat, 0.2), arc(seat, 0.085)], angle: 0.9, gap: 0.03), fine)
        Kit.mass(&plate, arc(seat, 0.085))
        plate.fill(arc(seat, 0.03))
        plate.line(arc(seat, 0.03), medium)
        for c in [P(-0.88, 0.42), P(-0.38, 0.86)] {
            plate.fill(arc(c, 0.048))
            plate.line(arc(c, 0.048), medium)
            plate.line(arc(c, 0.036), fine)
            Kit.mass(&plate, Kit.band(c + P(-0.042, 0.02), c + P(0.042, -0.02), 0.018))
        }

        // The spring on a margin of bone, so it stands off the ground and crosses nothing.
        plate.fill(Kit.ribbon(coil, 0.07))
        plate.fill(Kit.ribbon(coil, 0.042), .black)
        // The collet: a ring on the arbor, split where the spring's inner end is pinned.
        Kit.mass(&plate, arc(collet, 0.072))
        plate.fill(arc(collet, 0.036))
        plate.line(arc(collet, 0.036), medium)
        plate.line(arc(collet, 0.056), fine, .bone)
        plate.fill(Kit.band(polar(collet, 0.03, 2.3), polar(collet, 0.08, 2.3), 0.014))
        plate.fill(arc(polar(collet, 0.052, -0.6), 0.011))

        // The tweezers, each blade's highlight and its grip.
        for (k, b) in blades.enumerated() {
            plate.fill(b, .black)
            plate.line(b, medium)
            let side = k == 0 ? 1.0 : -1.0
            plate.line([0.22, 1.5].map { tip + up * $0 + across * (side * (0.085 + 0.03 * $0)) }, fine, .bone)
            for s in stride(from: 0.62, through: 0.92, by: 0.05) {
                let c = tip + up * s + across * (side * 0.134)
                plate.line([c - across * 0.05 - up * 0.015, c + across * 0.05 + up * 0.015], 0.012, .bone)
            }
        }
        // The stud: a block on the spring's end, its pin hole, held between the tips.
        let stud = [tip + across * 0.025 - up * 0.028, tip + across * 0.025 + up * 0.03, tip - across * 0.025 + up * 0.03,
                    tip - across * 0.025 - up * 0.028, tip + across * 0.025 - up * 0.028]
        plate.fill(stud, .second)
        plate.line(stud, medium)
        plate.fill(arc(tip + up * 0.004, 0.009))
        
        callout(&plate, "A", from: tip + up * 0.55 + across * 0.07, to: P(0.15, -0.86))
        callout(&plate, "B", from: P(-0.265, 0.09), to: P(-0.48, 0.2))
        callout(&plate, "C", from: collet + P(0.05, 0.05), to: P(0.06, 0.64))
        callout(&plate, "D", from: tip - across * 0.02, to: P(-0.24, -0.4))
        return plate
    }

    /// Problem 32, Balance wheel, hex, clocks 1+.
    static func plate32() -> Plate? { nil }

    /// Problem 33, Escape wheel, pent, clocks 0+.
    static func plate33() -> Plate? { nil }

    /// Problem 34, Pallet fork, hex, clocks 1+.
    static func plate34() -> Plate? { nil }

    /// Problem 35, Click spring, pent, clocks 0+.
    static func plate35() -> Plate? { nil }

    /// Problem 36, Crown wheel, hex, clocks 1+.
    static func plate36() -> Plate? { nil }
}
