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

    /// Problem 32, Balance wheel, hex, clocks 1+: a split bimetallic balance seen flat, off the hub to the left, its
    /// rim brass outside and steel inside, each half fixed to one arm and cut free beside the other, timing screws
    /// round it, the double roller and its impulse pin at the staff. One timing screw, at nine o'clock, is in the
    /// second ink.
    static func plate32() -> Plate {
        var plate = Plate()
        // The rim threads between the rods: those at the hub, eight and ten o'clock inside it, twelve and six outside.
        let c = P(-0.3, 0), rim = 0.48, brass = 0.062, steel = 0.03
        let outer = rim + brass / 2 + steel / 2, inner = rim - brass / 2 - steel / 2, middle = inner + steel
        // Each half runs from its arm, clockwise, to a cut just short of the other arm.
        let halves = [(from: -Double.pi / 2, to: Double.pi / 2 - 0.2), (from: Double.pi / 2, to: 3 * Double.pi / 2 - 0.2)]
        func sector(_ a: Double, _ b: Double, _ r0: Double, _ r1: Double) -> [P] {
            let o = arc(c, r1, from: a, to: b), i = arc(c, r0, from: b, to: a)
            return o + i + [o[0]]
        }
        let arms = [Double.pi / 2, -Double.pi / 2].map { a -> [P] in
            [polar(c, 0.1, a - 0.34), polar(c, inner - 0.05, a - 0.066), polar(c, outer, a - 0.11), polar(c, outer, a + 0.11),
             polar(c, inner - 0.05, a + 0.066), polar(c, 0.1, a + 0.34), polar(c, 0.1, a - 0.34)]
        }
        // The screws stand off the rim wherever no rod's hub reaches.
        let screws = stride(from: -180.0, to: 180.0, by: 20).compactMap { d -> Double? in
            let a = d * .pi / 180
            return [-61.8, 61.8].contains { abs(d - $0) < 25 } || [90.0, -90.0].contains(d) ? nil : a
        }
        Kit.ground(&plate, angle: -0.42)
        
        // The screws: a bold head, its slot across, its thread into the rim.
        for a in screws {
            let at = polar(c, outer + 0.034, a), ink: Ink = abs(a - .pi) < 0.01 || abs(a + .pi) < 0.01 ? .second : .black
            plate.fill(Kit.band(polar(c, outer - 0.01, a), at, 0.03), ink)
            plate.fill(arc(at, 0.036), ink)
            plate.line(arc(at, 0.036), medium)
            plate.line([polar(at, 0.03, a + .pi / 2), polar(at, 0.03, a - .pi / 2)], 0.012, .bone)
        }
        // The rim, brass outside in ink, steel inside in section, each half cut free.
        for h in halves {
            Kit.mass(&plate, sector(h.from, h.to, middle, outer))
            Kit.cut(&plate, sector(h.from, h.to, inner, middle))
            plate.line([polar(c, inner, h.to), polar(c, outer, h.to)], heavy)
        }
        // The rim's spare screw holes, between the screws.
        for k in 0..<36 where k != 8 && k != 26 && k != 17 && k != 35 {
            let at = polar(c, (middle + outer) / 2, (Double(k) + 0.5) * .pi / 18)
            plate.fill(arc(at, 0.022))
        }
        // The arms and the boss they spring from, a bone line down each.
        for arm in arms { Kit.mass(&plate, arm) }
        Kit.mass(&plate, arc(c, 0.118))
        for a in [Double.pi / 2, -Double.pi / 2] { plate.line([polar(c, 0.14, a), polar(c, inner - 0.04, a)], fine, .bone) }

        // The double roller: the table with its impulse pin, the safety roller under it with its crescent.
        plate.fill(arc(c, 0.098))
        plate.line(arc(c, 0.098), heavy)
        plate.lines(hatch([arc(c, 0.098), arc(c, 0.058)], angle: 0.4, gap: 0.016), fine)
        plate.line(arc(c, 0.058), medium)
        Kit.mass(&plate, arc(c, 0.028))
        plate.fill(arc(c, 0.01))
        let pin = polar(c, 0.075, 0)
        Kit.mass(&plate, [pin + P(-0.016, -0.018), pin + P(0.02, -0.018), pin + P(0.02, 0.018), pin + P(-0.016, 0.018), pin + P(-0.016, -0.018)])
        let notch = arc(polar(c, 0.098, 0), 0.03, from: .pi / 2, to: 3 * .pi / 2)
        plate.line(notch, medium)

        // The roller again, twice the size, in a ring at three o'clock.
        let inset = P(0.775, 0), table = 0.135
        plate.lines(dashed([polar(c, 0.1, 0), polar(inset, 0.2, .pi)], on: 0.03, off: 0.018), medium)
        plate.fill(arc(inset, 0.2))
        Kit.mass(&plate, arc(inset, table))
        plate.line(arc(inset, 0.115), fine, .bone)
        plate.fill(arc(inset, 0.074))
        plate.lines(hatch([arc(inset, 0.074), arc(inset, 0.03)], angle: 0.4, gap: 0.016), fine)
        plate.line(arc(inset, 0.074), medium)
        Kit.mass(&plate, arc(inset, 0.03))
        plate.fill(arc(inset, 0.011))
        let jewel = polar(inset, 0.1, 0)
        let ruby = [jewel + P(-0.024, -0.026), jewel + P(0.018, -0.026)] + arc(jewel + P(0.018, 0), 0.026, from: -.pi / 2, to: .pi / 2)
            + [jewel + P(-0.024, 0.026), jewel + P(-0.024, -0.026)]
        Kit.cut(&plate, ruby)
        plate.line([jewel + P(-0.012, -0.016), jewel + P(-0.012, 0.016)], fine)
        let crescent = arc(polar(inset, 0.074, 0), 0.034, from: .pi / 2, to: 3 * .pi / 2)
        plate.fill(crescent + [crescent[0]], .black)
        plate.line(arc(inset, 0.2), 0.026)
        plate.line(arc(inset, 0.172), fine)

        callout(&plate, "A", from: polar(c, outer - 0.01, 0.6), to: P(0.25, 0.72))
        callout(&plate, "B", from: polar(c, rim, Double.pi / 2 - 0.2), to: P(-0.26, 0.82))
        callout(&plate, "C", from: jewel + P(0.03, 0.02), to: P(0.86, 0.36))
        callout(&plate, "D", from: polar(c, outer + 0.034, .pi), to: P(-0.6, -0.02))
        return plate
    }

    /// Problem 33, Escape wheel, pent, clocks 0+: a Swiss club-tooth escape wheel of fifteen teeth, so large its arbor
    /// low on the left and its raked teeth sweep across the middle in solid ink, the ground
    /// showing through its spokes' windows; the pallet stone resting on the one locking tooth, whose face is in the
    /// second ink.
    static func plate33() -> Plate {
        var plate = Plate()
        let w = P(-0.7, 0.4), r = 1.25, teeth = 15, tau = 2 * Double.pi / Double(teeth)
        // The phase puts one tooth's locking corner a little right of the glass's middle.
        let phase = atan2(-0.39 - w.y, 0.28 - w.x) - 0.2 * tau
        func tooth(_ k: Int) -> [P] {
            let a = phase + Double(k) * tau
            let face = [polar(w, 0.7 * r, a), polar(w, 0.86 * r, a + 0.1 * tau), polar(w, r, a + 0.2 * tau)]
            let club = [polar(w, 0.985 * r, a + 0.02 * tau), polar(w, 0.95 * r, a - 0.06 * tau)]
            let back = curve(polar(w, 0.95 * r, a - 0.06 * tau), polar(w, 0.8 * r, a - 0.02 * tau), polar(w, 0.7 * r, a - 0.28 * tau), 8)
            return face + club + Array(back.dropFirst())
        }
        // Round the wheel against the turn, so each tooth's back runs down to the next one's face.
        var outline = stride(from: teeth, to: 0, by: -1).flatMap { tooth($0) }
        outline.append(outline[0])
        let rimInner = 0.645 * r, hub = 0.12
        let holes = windows(w, hub: hub + 0.03, rim: rimInner, spokes: 4, width: 0.05, phase: phase + 0.9)

        Kit.ground(&plate, angle: 0.3)
        Kit.mass(&plate, outline)
        for hole in holes {
            plate.fill(hole)
            plate.lines(hatch([hole], angle: 0.3, gap: Kit.groundGap), Kit.groundWidth)
            plate.line(hole, heavy)
        }
        // The rim's chamfer and the spokes' crossing in bone, the collet in section, the arbor.
        plate.line(arc(w, rimInner + 0.02), medium, .bone)
        plate.fill(arc(w, hub))
        plate.lines(hatch([arc(w, hub), arc(w, 0.06)], angle: -0.8, gap: 0.024), fine)
        plate.line(arc(w, hub), heavy)
        Kit.mass(&plate, arc(w, 0.06))
        // Each tooth's club cut off from its neck by a bone line.
        for k in 0..<teeth {
            let a = phase + Double(k) * tau
            plate.line([polar(w, 0.925 * r, a + 0.15 * tau), polar(w, 0.92 * r, a - 0.04 * tau)], medium, .bone)
        }

        // The locking tooth: its face, and the pallet stone resting on it.
        let a = phase
        let face = [polar(w, 0.88 * r, a + 0.11 * tau), polar(w, r, a + 0.2 * tau)]
        let along = simd_normalize(face[1] - face[0]), out = P(along.y, -along.x)
        let lit = [face[0], face[1], face[1] + out * 0.024, face[0] + out * 0.024, face[0]]
        plate.fill(lit, .second)
        plate.line(lit, medium)
        let stone = [face[1] + out * 0.024 - along * 0.07, face[1] + out * 0.024 + along * 0.11,
                     face[1] + out * 0.1 + along * 0.11, face[1] + out * 0.1 - along * 0.07]
        Kit.cut(&plate, stone + [stone[0]], edge: heavy)
        plate.lines(hatch([stone + [stone[0]]], angle: atan2(along.y, along.x) + 0.8, gap: 0.016), fine)

        callout(&plate, "A", from: polar(w, 0.9 * r, phase + 1.05 * tau), to: P(0.8, 0.04))
        callout(&plate, "B", from: lit[2], to: P(0.42, -0.64))
        callout(&plate, "C", from: polar(w, 0.45, phase + 0.9 - 0.5 * .pi / 2), to: P(-0.84, -0.3))
        callout(&plate, "D", from: polar(w, hub - 0.025, 0.6), to: P(-0.34, 0.8))
        return plate
    }

    /// Problem 34, Pallet fork, hex, clocks 1+.
    static func plate34() -> Plate? { nil }

    /// Problem 35, Click spring, pent, clocks 0+.
    static func plate35() -> Plate? { nil }

    /// Problem 36, Crown wheel, hex, clocks 1+.
    static func plate36() -> Plate? { nil }
}
