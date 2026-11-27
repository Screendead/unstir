// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 6, Long Count: problems 31 to 36's plates, drawn with `Kit`.
extension EscapementArt {
    /// Problem 31, Hairspring, pent, clocks 0+: a hairspring lifted from the movement in watchmaker's tweezers, seen
    /// flat as it hangs, its turns crowding downward round the collet, a ring at its middle; the bridge it came out of
    /// in the corner, striped. The stud pin at the spring's outer end,
    /// in the tweezers' tips, is in the second ink.
    static func plate31() -> Plate {
        var plate = Plate()
        let tip = P(0, -0.3), up: P = simd_normalize(P(0.74, -0.67)), across: P = P(-up.y, up.x)
        let blades: [[P]] = [plate31Blade(tip, up, across, 1), plate31Blade(tip, up, across, -1)]

        // The spring seen flat as it hangs from its outer end: three turns, each turn's middle a little
        // lower than the last, so the turns crowd under the stud and open out below.
        let centre = P(0, 0.055), outer = 0.335, inner = 0.1, turns = 3.0, sag = 0.045, n = 700
        let coil: [P] = (0...n).map { (i: Int) -> P in
            let t: Double = Double(i) / Double(n)
            return polar(centre + P(0, sag * t), outer - (outer - inner) * t, -.pi / 2 + 2 * .pi * turns * t)
        }
        let collet: P = centre + P(0, sag)
        plate31Bridge(&plate)
        plate31Spring(&plate, coil, collet)
        plate31Tweezers(&plate, blades, tip, up, across)

        callout(&plate, "A", from: tip + up * 0.55 + across * 0.07, to: P(0.15, -0.86))
        callout(&plate, "B", from: P(-0.265, 0.09), to: P(-0.48, 0.2))
        callout(&plate, "C", from: collet + P(0.05, 0.05), to: P(0.06, 0.64))
        callout(&plate, "D", from: tip - across * 0.02, to: P(-0.24, -0.4))
        return plate
    }
    // Each blade by its distance from the tips: half its width, and how far its middle stands off the axis.
    private static func plate31Half(_ s: Double) -> Double { 0.012 + 0.06 * min(1, pow(s / 0.5, 0.7)) }
    private static func plate31Off(_ s: Double) -> Double { 0.026 + 0.04 * min(1, s / 0.9) + plate31Half(s) }
    private static func plate31Blade(_ tip: P, _ up: P, _ across: P, _ side: Double) -> [P] {
        let length = 1.5
        let steps: [Double] = (0...60).map { (i: Int) -> Double in length * Double(i) / 60 }
        let outer: [P] = steps.map { (s: Double) -> P in tip + up * s + across * (side * (plate31Off(s) + plate31Half(s))) }
        let inner: [P] = steps.map { (s: Double) -> P in tip + up * s + across * (side * (plate31Off(s) - plate31Half(s))) }
        let root: P = tip + across * (side * 0.026)
        return [root] + outer + inner.reversed() + [root]
    }
    private static func plate31Bridge(_ plate: inout Plate) {
        // The bridge the spring was lifted from, cropped by the glass at seven o'clock.
        let bridgeCentre = P(-1.2, 1.17), bridge: [P] = arc(bridgeCentre, 1.0)
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
    }
    private static func plate31Spring(_ plate: inout Plate, _ coil: [P], _ collet: P) {
        // The spring on a margin of bone, so it stands off the ground and crosses nothing.
        plate.fill(Kit.ribbon(coil, 0.074))
        plate.fill(Kit.ribbon(coil, 0.05), .black)
        // The collet: a ring on the arbor, split where the spring's inner end is pinned.
        Kit.mass(&plate, arc(collet, 0.072))
        plate.fill(arc(collet, 0.036))
        plate.line(arc(collet, 0.036), medium)
        plate.line(arc(collet, 0.056), fine, .bone)
        plate.fill(Kit.band(polar(collet, 0.03, 2.3), polar(collet, 0.08, 2.3), 0.014))
        plate.fill(arc(polar(collet, 0.052, -0.6), 0.011))
    }
    private static func plate31Tweezers(_ plate: inout Plate, _ blades: [[P]], _ tip: P, _ up: P, _ across: P) {
        // The tweezers, each blade's highlight and its grip.
        for (k, b) in blades.enumerated() {
            plate.fill(b, .black)
            plate.line(b, medium)
            let side = k == 0 ? 1.0 : -1.0
            let edge: [P] = [0.22, 1.5].map { (s: Double) -> P in tip + up * s + across * (side * (0.085 + 0.03 * s)) }
            plate.line(edge, fine, .bone)
            for s in stride(from: 0.62, through: 0.92, by: 0.05) {
                let c: P = tip + up * s + across * (side * 0.134)
                let lo: P = c - across * 0.05 - up * 0.015, hi: P = c + across * 0.05 + up * 0.015
                plate.line([lo, hi], 0.012, .bone)
            }
        }
        // The stud: a block on the spring's end, its pin hole, held between the tips.
        let a: P = tip + across * 0.025 - up * 0.028, b: P = tip + across * 0.025 + up * 0.03
        let c: P = tip - across * 0.025 + up * 0.03, d: P = tip - across * 0.025 - up * 0.028
        let stud: [P] = [a, b, c, d, a]
        plate.fill(stud, .second)
        plate.line(stud, medium)
        plate.fill(arc(tip + up * 0.004, 0.009))
    }

    /// Problem 32, Balance wheel, hex, clocks 1+: a split bimetallic balance seen flat, off the hub to the left, its
    /// rim brass outside in ink and steel inside in bone, each half fixed to one arm and cut free beside the other, timing screws
    /// round it, the double roller and its impulse pin at the staff. One timing screw, at nine o'clock, is in the
    /// second ink.
    static func plate32() -> Plate {
        var plate = Plate()
        let c = plate32C, outer = plate32Outer, rim = plate32Rim
        Kit.ground(&plate, angle: -0.42)
        plate32Screwed(&plate)
        plate32RimDrawn(&plate)
        plate32Arms(&plate)
        plate32Roller(&plate)
        let jewel: P = plate32Inset(&plate)

        callout(&plate, "A", from: polar(c, outer - 0.01, 0.6), to: P(0.25, 0.72))
        callout(&plate, "B", from: polar(c, rim, Double.pi / 2 - 0.2), to: P(-0.26, 0.82))
        callout(&plate, "C", from: jewel + P(0.03, 0.02), to: P(0.86, 0.36))
        callout(&plate, "D", from: polar(c, outer + 0.034, .pi), to: P(-0.6, -0.02))
        return plate
    }
    // The rim threads between the rods: those at the hub, eight and ten o'clock inside it, twelve and six outside.
    private static let plate32C: P = P(-0.3, 0)
    private static let plate32Rim: Double = 0.48
    private static let plate32Brass: Double = 0.062
    private static let plate32Steel: Double = 0.03
    private static let plate32Outer: Double = plate32Rim + plate32Brass / 2 + plate32Steel / 2
    private static let plate32Inner: Double = plate32Rim - plate32Brass / 2 - plate32Steel / 2
    private static let plate32Middle: Double = plate32Inner + plate32Steel
    private static func plate32Sector(_ a: Double, _ b: Double, _ r0: Double, _ r1: Double) -> [P] {
        let o: [P] = arc(plate32C, r1, from: a, to: b), i: [P] = arc(plate32C, r0, from: b, to: a)
        return o + i + [o[0]]
    }
    private static func plate32Screwed(_ plate: inout Plate) {
        let c = plate32C, outer = plate32Outer
        // The screws stand off the rim wherever no rod's hub reaches.
        let screws: [Double] = stride(from: -180.0, to: 180.0, by: 20).compactMap { (d: Double) -> Double? in
            let a: Double = d * .pi / 180
            return [-61.8, 61.8].contains { (m: Double) -> Bool in abs(d - m) < 25 } || [90.0, -90.0].contains(d) ? nil : a
        }
        // The screws: a bold head, its slot across, its thread into the rim.
        for a in screws {
            let at: P = polar(c, outer + 0.034, a), ink: Ink = abs(a - .pi) < 0.01 || abs(a + .pi) < 0.01 ? .second : .black
            plate.fill(Kit.band(polar(c, outer - 0.01, a), at, 0.03), ink)
            plate.fill(arc(at, 0.036), ink)
            plate.line(arc(at, 0.036), medium)
            plate.line([polar(at, 0.03, a + .pi / 2), polar(at, 0.03, a - .pi / 2)], 0.012, .bone)
        }
    }
    private static func plate32RimDrawn(_ plate: inout Plate) {
        let c = plate32C, outer = plate32Outer, inner = plate32Inner, middle = plate32Middle
        // Each half runs from its arm, clockwise, to a cut just short of the other arm.
        let halves: [(from: Double, to: Double)] = [(from: -Double.pi / 2, to: Double.pi / 2 - 0.2), (from: Double.pi / 2, to: 3 * Double.pi / 2 - 0.2)]
        // The rim, brass outside in ink, steel inside in bone, each half cut free.
        for h in halves {
            Kit.mass(&plate, plate32Sector(h.from, h.to, middle, outer))
            Kit.cut(&plate, plate32Sector(h.from, h.to, inner, middle))
            plate.line([polar(c, inner, h.to), polar(c, outer, h.to)], heavy)
        }
        // The rim's spare screw holes, between the screws.
        for k in 0..<36 where k != 8 && k != 26 && k != 17 && k != 35 {
            let at: P = polar(c, (middle + outer) / 2, (Double(k) + 0.5) * .pi / 18)
            plate.fill(arc(at, 0.022))
        }
    }
    private static func plate32Arms(_ plate: inout Plate) {
        let c = plate32C, outer = plate32Outer, inner = plate32Inner
        let arms: [[P]] = [Double.pi / 2, -Double.pi / 2].map { (a: Double) -> [P] in
            let p0: P = polar(c, 0.1, a - 0.34), p1: P = polar(c, inner - 0.05, a - 0.066), p2: P = polar(c, outer, a - 0.11)
            let p3: P = polar(c, outer, a + 0.11), p4: P = polar(c, inner - 0.05, a + 0.066), p5: P = polar(c, 0.1, a + 0.34)
            return [p0, p1, p2, p3, p4, p5, p0]
        }
        // The arms and the boss they spring from, a bone line down each.
        for arm in arms { Kit.mass(&plate, arm) }
        Kit.mass(&plate, arc(c, 0.118))
        for a in [Double.pi / 2, -Double.pi / 2] { plate.line([polar(c, 0.14, a), polar(c, inner - 0.04, a)], fine, .bone) }
    }
    private static func plate32Roller(_ plate: inout Plate) {
        let c = plate32C
        // The double roller: the table with its impulse pin, the safety roller under it with its crescent.
        plate.fill(arc(c, 0.098))
        plate.line(arc(c, 0.098), heavy)
        plate.lines(hatch([arc(c, 0.098), arc(c, 0.058)], angle: 0.4, gap: 0.016), fine)
        plate.line(arc(c, 0.058), medium)
        Kit.mass(&plate, arc(c, 0.028))
        plate.fill(arc(c, 0.01))
        let pin: P = polar(c, 0.075, 0)
        let a: P = pin + P(-0.016, -0.018), b: P = pin + P(0.02, -0.018), d: P = pin + P(0.02, 0.018), e: P = pin + P(-0.016, 0.018)
        Kit.mass(&plate, [a, b, d, e, a])
        let notch: [P] = arc(polar(c, 0.098, 0), 0.03, from: .pi / 2, to: 3 * .pi / 2)
        plate.line(notch, medium)
    }
    private static func plate32Inset(_ plate: inout Plate) -> P {
        let c = plate32C
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
        let jewel: P = polar(inset, 0.1, 0)
        let round: [P] = arc(jewel + P(0.018, 0), 0.026, from: -.pi / 2, to: .pi / 2)
        let ruby: [P] = [jewel + P(-0.024, -0.026), jewel + P(0.018, -0.026)] + round + [jewel + P(-0.024, 0.026), jewel + P(-0.024, -0.026)]
        Kit.cut(&plate, ruby)
        plate.line([jewel + P(-0.012, -0.016), jewel + P(-0.012, 0.016)], fine)
        let crescent: [P] = arc(polar(inset, 0.074, 0), 0.034, from: .pi / 2, to: 3 * .pi / 2)
        plate.fill(crescent + [crescent[0]], .black)
        plate.line(arc(inset, 0.2), 0.026)
        plate.line(arc(inset, 0.172), fine)
        return jewel
    }

    /// Problem 33, Escape wheel, pent, clocks 0+: a Swiss club-tooth escape wheel of fifteen teeth, so large its arbor
    /// sits low on the left and its raked teeth sweep across the middle in solid ink, the ground
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

    /// Problem 34, Pallet fork, hex, clocks 1+: the lever escapement's pallet fork in elevation, standing on a line of
    /// centres between the middle rods and the right-hand ones: the lever up to its horns, notch and guard pin, the
    /// anchor's arms down to its two pallet jewels, and the escape wheel's teeth in an arc under them. The entry pallet
    /// jewel, on the left, is in the second ink.
    static func plate34() -> Plate {
        var plate = Plate()
        let x = plate34X, arbor = plate34Arbor, top = plate34Top, depth = plate34Depth, span = plate34Span
        let wheel = plate34Wheel, teethTip = plate34TeethTip, phase = plate34Phase, tau = plate34Tau
        Kit.ground(&plate, angle: -0.55)
        plate34Toothed(&plate)
        plate34Anchor(&plate)
        // The guard pin, standing in the notch's floor.
        let pin = P(x, top - 0.06 + depth)
        let g0: P = pin + P(-0.011, 0.0), g1: P = pin + P(-0.011, -0.07), g2: P = pin + P(0, -0.085)
        let g3: P = pin + P(0.011, -0.07), g4: P = pin + P(0.011, 0)
        Kit.mass(&plate, [g0, g1, g2, g3, g4, g0])

        Kit.solid(&plate, plate34Entry, angle: 0.5, gap: 0.012, ink: .second, width: fine, edge: heavy)
        Kit.solid(&plate, plate34Exit, angle: 0.5, gap: 0.012, width: fine, edge: heavy)
        plate34Fork(&plate)

        callout(&plate, "A", from: P(x - 0.11, top - 0.04), to: P(-0.18, -0.86))
        callout(&plate, "B", from: pin + P(0, -0.05), to: P(0.6, -0.72))
        callout(&plate, "C", from: polar(arbor, 0.9, span.to + 0.06), to: P(-0.62, 0.62))
        callout(&plate, "D", from: polar(wheel, 0.9 * teethTip, phase + 3.3 * tau), to: P(0.84, 0.28))
        return plate
    }
    private static let plate34X: Double = 0.24
    private static let plate34Arbor: P = P(plate34X, 0.0)
    private static let plate34Wheel: P = P(plate34X, 1.45)
    private static let plate34TeethTip: Double = 0.84
    private static let plate34Teeth: Int = 21
    private static let plate34Tau: Double = 2 * Double.pi / Double(plate34Teeth)
    private static let plate34Top: Double = -0.74
    private static let plate34Notch: Double = 0.034
    private static let plate34Depth: Double = 0.085
    private static let plate34Span: (from: Double, to: Double) = (from: Kit.clock(4.9), to: Kit.clock(7.1))
    private static let plate34Inner: Double = 0.71
    private static let plate34Outer: Double = 0.83
    private static let plate34Entry: [P] = plate34Jewel(plate34Span.to + 0.06, lean: 0)
    private static let plate34Exit: [P] = plate34Jewel(plate34Span.from - 0.06, lean: 0)
    // The escape wheel's rim and teeth under the pallets, phased so a tooth's face lies on each jewel.
    private static let plate34Phase: Double = atan2(plate34Entry[1].y - plate34Wheel.y, plate34Entry[1].x - plate34Wheel.x) - 0.6 * plate34Tau
    // The jewels, set in slots at each end of the crescent and standing out below it.
    private static func plate34Jewel(_ a: Double, lean: Double) -> [P] {
        let d = P(cos(a), sin(a)), n = P(-d.y, d.x)
        let base: P = plate34Arbor + d * (plate34Inner + 0.02), tip: P = plate34Arbor + d * 0.97
        let t1: P = tip + n * 0.03 + d.x * lean * n, t2: P = tip - n * 0.03 - d * 0.03
        return [base + n * 0.03, t1, t2, base - n * 0.03, base + n * 0.03]
    }
    private static func plate34Toothed(_ plate: inout Plate) {
        let wheel = plate34Wheel, teethTip = plate34TeethTip, teeth = plate34Teeth, tau = plate34Tau, phase = plate34Phase
        var outline: [P] = []
        for k in stride(from: teeth, to: 0, by: -1) {
            let a: Double = phase + Double(k) * tau
            let q0: P = polar(wheel, 0.78 * teethTip, a), q1: P = polar(wheel, teethTip, a + 0.18 * tau)
            let q2: P = polar(wheel, 0.97 * teethTip, a - 0.02 * tau), q3: P = polar(wheel, 0.86 * teethTip, a - 0.1 * tau)
            let q4: P = polar(wheel, 0.78 * teethTip, a - 0.4 * tau)
            outline += [q0, q1, q2, q3, q4]
        }
        outline.append(outline[0])
        Kit.mass(&plate, outline)
        plate.line(arc(wheel, 0.72 * teethTip), medium, .bone)
        for k in 0..<teeth {
            let a: Double = phase + Double(k) * tau
            plate.line([polar(wheel, 0.92 * teethTip, a + 0.1 * tau), polar(wheel, 0.9 * teethTip, a - 0.06 * tau)], medium, .bone)
        }
    }
    private static func plate34Lever() -> [P] {
        let x = plate34X, top = plate34Top, notch = plate34Notch, depth = plate34Depth
        // The lever: from the arbor up to the fork, narrowing; the fork's horns flare either side of the notch.
        let leftEdge: [P] = [P(x - 0.082, 0.0), P(x - 0.056, top + 0.06)]
        let horn: [P] = curve(P(x - 0.056, top + 0.06), P(x - 0.07, top + 0.01), P(x - 0.145, top - 0.07), 10)
        let tail: [P] = [P(x - 0.11, top - 0.105), P(x - notch, top - 0.06), P(x - notch, top - 0.06 + depth)]
        let fork: [P] = leftEdge + horn.dropFirst() + tail
        let mirrored: [P] = fork.reversed().map { (p: P) -> P in P(2 * x - p.x, p.y) }
        return fork + mirrored + [fork[0]]
    }
    private static func plate34Anchor(_ plate: inout Plate) {
        let x = plate34X, arbor = plate34Arbor, top = plate34Top, span = plate34Span
        let inner = plate34Inner, outer = plate34Outer
        let lever: [P] = plate34Lever()
        // The anchor: a crescent about the arbor, from seven o'clock round to five, its middle webbed to the arbor.
        let crescent: [P] = arc(arbor, outer, from: span.from, to: span.to) + arc(arbor, inner, from: span.to, to: span.from)
        let web: [P] = [polar(arbor, 0.05, 0.4), polar(arbor, inner + 0.01, .pi / 2 - 0.1), polar(arbor, inner + 0.01, .pi / 2 + 0.1),
                        polar(arbor, 0.05, .pi - 0.4)]
        // The web's lightening slot.
        let slotA: [P] = curve(P(x, 0.14), P(x - 0.06, 0.38), P(x, 0.6), 12)
        let slot: [P] = slotA + curve(P(x, 0.6), P(x + 0.06, 0.38), P(x, 0.14), 12)
        Kit.mass(&plate, web + [web[0]])
        Kit.solid(&plate, crescent + [crescent[0]], angle: 0.9, gap: 0.028, width: medium, edge: 0.014)
        Kit.mass(&plate, lever)
        // The lever's polish in bone down its middle, the arbor's collet in section, the screws pinning the anchor.
        plate.line([P(x, -0.1), P(x, top + 0.07)], fine, .bone)
        plate.fill(arc(arbor, 0.07))
        plate.lines(hatch([arc(arbor, 0.07), arc(arbor, 0.025)], angle: 0.7, gap: 0.016), fine)
        plate.line(arc(arbor, 0.07), heavy)
        Kit.mass(&plate, arc(arbor, 0.025))
        Kit.cut(&plate, slot, edge: heavy)
        plate.lines(hatch([slot], angle: 0.9, gap: 0.03), fine)
        let screws: [P] = [polar(arbor, (inner + outer) / 2, span.from + 0.2), polar(arbor, (inner + outer) / 2, span.to - 0.2)]
        for p in screws {
            plate.fill(arc(p, 0.03))
            plate.line(arc(p, 0.03), medium)
            plate.line([p + P(-0.024, 0.012), p + P(0.024, -0.012)], 0.01)
        }
    }
    private static func plate34Fork(_ plate: inout Plate) {
        // The fork again, edge on, to the left: the lever's blade, the staff and its pivots, the pallets' stones hanging
        // from the anchor, the guard pin standing up at the fork's end.
        let staff = -0.4, end = -0.92
        let panelA: [P] = curve(P(-0.96, -0.2), P(-0.6, -0.24), P(-0.22, -0.2), 12)
        let panel: [P] = panelA + curve(P(-0.22, 0.19), P(-0.6, 0.23), P(-0.96, 0.19), 12)
        Kit.cut(&plate, panel + [panel[0]])
        let blade: [P] = [P(end, -0.045), P(-0.27, -0.045), P(-0.27, 0.05), P(staff - 0.05, 0.05), P(staff - 0.12, 0.03), P(end, 0.03), P(end, -0.045)]
        Kit.mass(&plate, blade)
        Kit.mass(&plate, Kit.band(P(staff, -0.1), P(staff, 0.11), 0.034))
        for (y0, y1) in [(-0.135, -0.1), (0.11, 0.145)] { Kit.mass(&plate, Kit.band(P(staff, y0), P(staff, y1), 0.014)) }
        let stone: [P] = [P(staff - 0.04, -0.075), P(staff + 0.04, -0.075), P(staff + 0.04, -0.03), P(staff - 0.04, -0.03), P(staff - 0.04, -0.075)]
        Kit.solid(&plate, stone, angle: 0.7, gap: 0.014, width: fine)
        Kit.solid(&plate, box(P(-0.35, 0.05), P(-0.285, 0.13)), angle: 0.5, gap: 0.012, width: fine, edge: heavy)
        Kit.mass(&plate, Kit.band(P(end + 0.07, -0.04), P(end + 0.07, -0.1), 0.022))
        plate.line([P(end + 0.02, -0.01), P(-0.29, -0.01)], medium, .bone)
        for ax in [end, -0.27] { plate.line([P(ax, -0.13), P(ax, -0.19)], fine) }
        plate.lines(dashed([P(end, -0.16), P(-0.27, -0.16)], on: 0.02, off: 0.012), fine)
    }

    /// Problem 35, Click spring, pent, clocks 0+: the crown wheel's ratchet on the barrel bridge, a big ink plate whose
    /// arms run out between the rods to its screws; off it, at one o'clock, the click on its screw and the click spring,
    /// a long hairpin blade bent round two screws, bearing on the click's tail. The click's tip, in the tooth, is in the
    /// second ink.
    static func plate35() -> Plate {
        var plate = Plate()
        let o = Kit.origin, pivot = plate35Pivot, d = plate35D, n = plate35N, leg = plate35Leg
        let bridge: [P] = plate35Bridge()
        let ratchet: [P] = plate35Ratchet()

        Kit.ground(&plate, angle: 0.6)
        Kit.mass(&plate, bridge)
        plate35Bolts(&plate)
        plate35Wheel(&plate, ratchet)
        plate35Spring(&plate)
        plate35Click(&plate)

        callout(&plate, "A", from: polar(o, 0.37, 3.3), to: P(-0.74, 0.12))
        callout(&plate, "B", from: pivot - d * 0.06 + n * 0.03, to: P(0.06, -0.86))
        callout(&plate, "C", from: plate35At(0.74, leg), to: P(0.84, -0.08))
        callout(&plate, "D", from: polar(o, 0.7, .pi / 2) + P(0.06, 0), to: P(0.2, 0.74))
        return plate
    }
    private static let plate35Lane: Double = -54.0 * .pi / 180
    private static let plate35Middle: Double = 0.445
    private static let plate35Arms: [Double] = [18.0, 90.0, 162.0, 234.0].map { (a: Double) -> Double in a * .pi / 180 }
    private static let plate35Teeth: Int = 30
    private static let plate35Tau: Double = 2 * Double.pi / Double(plate35Teeth)
    private static let plate35Root: Double = 0.335
    private static let plate35Tip: Double = 0.395
    private static let plate35Nose: P = polar(Kit.origin, 0.345, plate35Lane - 0.2)
    private static let plate35Face: Double = plate35Lane - 0.2 - 0.25 * plate35Tau
    private static let plate35U: P = P(cos(plate35Lane), sin(plate35Lane))
    private static let plate35V: P = P(-plate35U.y, plate35U.x)
    private static let plate35Leg: Double = 0.072
    // The click spring in the lane between twelve and two: an eye round the near screw, a leg out, a bend round
    // the far screw, and a leg back to bear on the click's tail.
    private static func plate35At(_ r: Double, _ s: Double) -> P { plate35U * r + plate35V * s }
    private static let plate35Near: P = plate35At(0.6, -0.075)
    private static let plate35Far: P = plate35At(0.88, 0)
    private static let plate35Pivot: P = plate35At(0.5, 0.0)
    private static let plate35D: P = simd_normalize(plate35Pivot - plate35Nose)
    private static let plate35N: P = P(-plate35D.y, plate35D.x)
    // The bridge: a round middle under the ratchet, and an arm out along each lane but the click's.
    private static func plate35Bridge() -> [P] {
        let o = Kit.origin, lane = plate35Lane, middle = plate35Middle, arms = plate35Arms
        var bridge: [P] = []
        for (k, a) in arms.enumerated() {
            let next: Double = k + 1 < arms.count ? arms[k + 1] : arms[0] + 2 * .pi
            let half = 0.085, end = 0.84
            let last: Bool = k + 1 == arms.count
            let reach: Double = middle + 0.1
            bridge += [polar(o, reach, a - asin(half / reach))]
            let side: P = P(cos(a - .pi / 2), sin(a - .pi / 2)) * half
            bridge += [polar(o, end, a) + side]
            bridge += arc(polar(o, end, a), half, from: a - .pi / 2, to: a + .pi / 2)
            bridge += [polar(o, reach, a + asin(half / reach))]
            let from: Double = a + asin(half / middle) + 0.12
            let to: Double = last ? lane + 2 * .pi - 0.3 : next - asin(half / middle) - 0.12
            bridge += arc(o, middle, from: from, to: to)
            if last {
                bridge += [polar(o, 0.42, lane + 2 * .pi - 0.2), polar(o, 0.42, lane + 2 * .pi + 0.2)]
                bridge += arc(o, middle, from: lane + 2 * .pi + 0.3, to: arms[0] + 2 * .pi - asin(0.085 / middle) - 0.12)
            }
        }
        bridge.append(bridge[0])
        return bridge
    }
    // The ratchet: 30 teeth, each face radial and its back sloping down against the turn.
    private static func plate35Ratchet() -> [P] {
        let o = Kit.origin, root = plate35Root, tip = plate35Tip, tau = plate35Tau, face = plate35Face
        let teeth: [P] = (0..<plate35Teeth).flatMap { (k: Int) -> [P] in
            let a: Double = face + Double(k) * tau
            return [polar(o, root, a), polar(o, tip, a + tau)]
        }
        return teeth + [polar(o, root, face)]
    }
    private static func plate35Bolts(_ plate: inout Plate) {
        let o = Kit.origin, lane = plate35Lane, middle = plate35Middle, arms = plate35Arms
        plate.line(arc(o, middle - 0.03, from: arms[0] + 0.35, to: lane + 2 * .pi - 0.35), fine, .bone)
        for a in arms {
            for side in [-1.0, 1.0] {
                let off: P = P(-sin(a), cos(a)) * (side * 0.058)
                plate.line([polar(o, middle + 0.02, a) + off, polar(o, 0.78, a) + off], medium, .bone)
            }
            let c: P = polar(o, 0.84, a)
            plate.fill(arc(c, 0.055))
            plate.line(arc(c, 0.055), heavy)
            plate.line(arc(c, 0.042), fine)
            Kit.mass(&plate, Kit.band(polar(c, 0.048, a + 0.7), polar(c, 0.048, a + 0.7 + .pi), 0.02))
        }
    }
    private static func plate35Wheel(_ plate: inout Plate, _ ratchet: [P]) {
        let o = Kit.origin, root = plate35Root
        // The ratchet in bone, its teeth outlined heavy, its face snailed, the arbor's square and the screw over it.
        plate.fill(ratchet)
        plate.line(ratchet, 0.014)
        plate.line(arc(o, root - 0.03), medium)
        for r in stride(from: 0.135, through: 0.28, by: 0.036) { plate.line(arc(o, r), medium) }
        plate.fill(arc(o, 0.1))
        plate.line(arc(o, 0.1), heavy)
        Kit.mass(&plate, turned(box(P(-0.048, -0.048), P(0.048, 0.048)), by: 0.3))
        plate.fill(arc(o, 0.032))
        plate.line(arc(o, 0.032), medium)
    }
    private static func plate35Spring(_ plate: inout Plate) {
        let u = plate35U, v = plate35V, near = plate35Near, far = plate35Far, leg = plate35Leg
        var spring: [P] = [plate35At(0.6, -0.075 + 0.0) + u * 0.04, plate35At(0.88, -leg)]
        spring += (1...24).map { (i: Int) -> P in
            let t: Double = Double(i) / 24 * .pi
            return far - v * (leg * cos(t)) + u * (leg * sin(t))
        }
        spring += [plate35At(0.62, leg)]
        plate.fill(Kit.ribbon(spring, 0.084))
        Kit.mass(&plate, Kit.ribbon(spring, 0.052))
        plate.line(Array(spring.dropFirst().dropLast()), fine, .bone)
        plate.fill(arc(near, 0.072))
        Kit.mass(&plate, arc(near, 0.062))
    }
    private static func plate35Click(_ plate: inout Plate) {
        let nose = plate35Nose, pivot = plate35Pivot, d = plate35D, n = plate35N
        // The click on its screw, its nose in a tooth and its tail under the spring, edged in bone off the bridge.
        let c0: P = nose + d * 0.07 + n * 0.042, c1: P = pivot + n * 0.062, c2: P = pivot + d * 0.09 + n * 0.05
        let c3: P = pivot + d * 0.135 + n * 0.02, c4: P = pivot + d * 0.12 - n * 0.035
        let c5: P = pivot - n * 0.06, c6: P = nose + d * 0.06 - n * 0.018
        let click: [P] = [nose, c0, c1, c2, c3, c4, c5, c6, nose]
        plate.line(click, 0.03, .bone)
        Kit.mass(&plate, click)
        let tipInk: [P] = [nose, nose + d * 0.06 + n * 0.038, nose + d * 0.055 - n * 0.016, nose]
        plate.fill(tipInk, .second)
        plate.line(tipInk, medium)
        for c in [plate35Near, plate35Far, pivot] {
            plate.fill(arc(c, 0.036))
            plate.line(arc(c, 0.036), heavy)
            plate.line([polar(c, 0.028, 0.5), polar(c, 0.028, 0.5 + .pi)], 0.012)
        }
    }

    /// Problem 36, Crown wheel, hex, clocks 1+: a contrate wheel seen from above and in front, its teeth standing up
    /// off the rim like a crown's points round a face of spokes and windows, its staff going down; a lantern pinion,
    /// seen end on over the back teeth, is driven by them, its arbor running out toward the eye. The pinion's pivot is
    /// in the second ink.
    static func plate36() -> Plate {
        var plate = Plate()
        let rim = plate36Rim, rear = plate36OnAxis(plate36Radius + 0.075), pivot = plate36OnAxis(plate36Radius - 0.36)
        Kit.ground(&plate, angle: -0.3)
        plate36Face(&plate)
        plate36Hub(&plate)
        plate36Toothed(&plate)
        plate36Pinion(&plate)

        callout(&plate, "A", from: plate36Tooth(5).ring[2], to: P(0.2, 0.86))
        callout(&plate, "B", from: plate36Seen(0.4 * cos(0.94 + .pi / 4), 0.4 * sin(0.94 + .pi / 4), rim), to: P(0.86, 0.0))
        callout(&plate, "C", from: rear + P(0.08, -0.04), to: P(0.2, -0.86))
        callout(&plate, "D", from: pivot + P(0, 0.04), to: P(-0.82, -0.52))
        return plate
    }
    private static let plate36Centre: P = P(-0.24, 0.12)
    private static let plate36Radius: Double = 0.72
    private static let plate36Rim: Double = 0.04
    private static let plate36Crown: Double = 0.2
    private static let plate36Elevation: Double = 25.0 * .pi / 180
    private static let plate36Teeth: Int = 18
    private static let plate36Tau: Double = 2 * Double.pi / Double(plate36Teeth)
    private static let plate36Azimuth: Double = -93.0 * .pi / 180
    private static let plate36Rp: Double = 0.125
    private static let plate36Height: Double = plate36Crown + plate36Rp - 0.045
    // The wheel's own frame: x across, y toward the eye, z up its axis.
    private static func plate36Seen(_ x: Double, _ y: Double, _ z: Double) -> P {
        plate36Centre + P(x, y * sin(plate36Elevation) - z * cos(plate36Elevation))
    }
    private static func plate36Round(_ r: Double, _ z: Double, from a: Double = 0, to b: Double = 2 * .pi, steps: Int = 120) -> [P] {
        (0...steps).map { (i: Int) -> P in
            let t: Double = a + (b - a) * Double(i) / Double(steps)
            return plate36Seen(r * cos(t), r * sin(t), z)
        }
    }
    private static func plate36Tooth(_ k: Int) -> (ring: [P], depth: Double) {
        let radius = plate36Radius, rim = plate36Rim, crown = plate36Crown
        let a: Double = 0.12 + Double(k) * plate36Tau, w: Double = 0.3 * plate36Tau
        let foot: [P] = [plate36Seen(radius * cos(a - w), radius * sin(a - w), rim), plate36Seen(radius * cos(a + w), radius * sin(a + w), rim)]
        let point: [P] = [plate36Seen(radius * cos(a + 0.2 * w), radius * sin(a + 0.2 * w), crown),
                          plate36Seen(radius * cos(a - 0.2 * w), radius * sin(a - 0.2 * w), crown)]
        return (foot + [point[0], point[1], foot[0]], sin(a))
    }
    private static func plate36OnAxis(_ r: Double) -> P { plate36Seen(r * cos(plate36Azimuth), r * sin(plate36Azimuth), plate36Height) }
    private static func plate36EndPlate(_ c: P) -> [P] { ellipse(c, plate36Rp, plate36Rp * cos(plate36Elevation) + 0.012) }
    // The windows between four spokes, laid out flat on the face and seen.
    private static func plate36Spokes() -> [[P]] {
        let rim = plate36Rim
        return (0..<4).map { (k: Int) -> [P] in
            let a: Double = 0.94 + Double(k) * .pi / 2, b: Double = a + .pi / 2, gap = 0.036
            let outer: [P] = (0...30).map { (i: Int) -> P in
                let t: Double = a + gap / 0.62 + (b - a - 2 * gap / 0.62) * Double(i) / 30
                return plate36Seen(0.62 * cos(t), 0.62 * sin(t), rim)
            }
            let inner: [P] = (0...10).map { (i: Int) -> P in
                let t: Double = b - gap / 0.16 - (b - a - 2 * gap / 0.16) * Double(i) / 10
                return plate36Seen(0.16 * cos(t), 0.16 * sin(t), rim)
            }
            return outer + inner + [outer[0]]
        }
    }
    private static func plate36Face(_ plate: inout Plate) {
        let radius = plate36Radius, rim = plate36Rim
        let face: [P] = plate36Round(radius, rim)
        let band: [P] = plate36Round(radius, rim, from: 0, to: .pi) + plate36Round(radius, 0, from: .pi, to: 0)
        let well: [P] = plate36Round(0.9 * radius, rim)
        let spokes: [[P]] = plate36Spokes()
        // The staff below the wheel, then the rim's outside and the face.
        Kit.mass(&plate, Kit.band(plate36Seen(0, 0, -0.05), plate36Seen(0, 0, -1.0), 0.07))
        Kit.mass(&plate, band)
        Kit.mass(&plate, face)
        for hole in spokes {
            plate.fill(hole)
            plate.lines(hatch([hole], angle: -0.3, gap: Kit.groundGap), Kit.groundWidth)
            plate.line(hole, heavy)
        }
        plate.line(well, medium, .bone)
    }
    private static func plate36Hub(_ plate: inout Plate) {
        let rim = plate36Rim
        plate.fill(plate36Round(0.09, rim))
        plate.lines(hatch([plate36Round(0.09, rim)], angle: 0.6, gap: 0.016), fine)
        plate.line(plate36Round(0.09, rim), heavy)
        Kit.mass(&plate, plate36Round(0.035, rim))
    }
    private static func plate36Toothed(_ plate: inout Plate) {
        // The teeth, back to front, each edged in bone so it stands off the ones behind.
        let all: [(ring: [P], depth: Double)] = (0..<plate36Teeth).map(plate36Tooth)
        let sorted: [(ring: [P], depth: Double)] = all.sorted(by: { (p: (ring: [P], depth: Double), q: (ring: [P], depth: Double)) -> Bool in p.depth < q.depth })
        for t in sorted {
            plate.line(t.ring, 0.016, .bone)
            Kit.mass(&plate, t.ring)
            if t.depth > 0 { plate.line([t.ring[0], t.ring[1]], fine, .bone) }
        }
        plate.line(plate36Round(plate36Radius, 0, from: 0, to: .pi), 0.014)
    }
    private static func plate36Pinion(_ plate: inout Plate) {
        let radius = plate36Radius, elevation = plate36Elevation
        let rear: P = plate36OnAxis(radius + 0.075), front: P = plate36OnAxis(radius - 0.075), pivot: P = plate36OnAxis(radius - 0.36)
        // The pinion: its rear plate, the trundles between, the front plate, the arbor out to its pivot.
        Kit.mass(&plate, Kit.band(plate36OnAxis(radius + 0.16), pivot, 0.034))
        Kit.cut(&plate, plate36EndPlate(rear), edge: heavy)
        plate.line(ellipse(rear, 0.07, 0.07 * cos(elevation)), medium)
        for k in 0..<8 {
            let a: Double = Double(k) * .pi / 4 + 0.2
            let off: P = P(0.094 * cos(a), 0.094 * sin(a) * cos(elevation))
            Kit.mass(&plate, Kit.band(rear + off, front + off, 0.024))
        }
        plate.fill(plate36EndPlate(front))
        plate.lines(hatch([plate36EndPlate(front), ellipse(front, 0.07, 0.07 * cos(elevation))], angle: 0.9, gap: 0.02), fine)
        plate.line(plate36EndPlate(front), heavy)
        plate.line(ellipse(front, 0.07, 0.07 * cos(elevation)), medium)
        for k in 0..<8 {
            let a: Double = Double(k) * .pi / 4 + 0.2
            Kit.mass(&plate, arc(front + P(0.094 * cos(a), 0.094 * sin(a) * cos(elevation)), 0.016))
        }
        Kit.mass(&plate, Kit.band(front, pivot, 0.034))
        let cone: [P] = [pivot + P(-0.03, -0.02), pivot + P(0.03, -0.02), pivot + P(0, 0.065), pivot + P(-0.03, -0.02)]
        plate.fill(cone, .second)
        plate.line(cone, medium)
    }
}
