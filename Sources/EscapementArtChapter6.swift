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

        // The spring seen flat as it hangs from its outer end: three turns, each turn's middle a little
        // lower than the last, so the turns crowd under the stud and open out below.
        let centre = P(0, 0.055), outer = 0.335, inner = 0.1, turns = 3.0, sag = 0.045, n = 700
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
        plate.fill(Kit.ribbon(coil, 0.074))
        plate.fill(Kit.ribbon(coil, 0.05), .black)
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
    /// rim brass outside in ink and steel inside in bone, each half fixed to one arm and cut free beside the other, timing screws
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
        // The rim, brass outside in ink, steel inside in bone, each half cut free.
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
        let x = 0.24, arbor = P(x, 0.0), wheel = P(x, 1.45), teethTip = 0.84, teeth = 21
        let tau = 2 * Double.pi / Double(teeth)

        // The lever: from the arbor up to the fork, narrowing; the fork's horns flare either side of the notch.
        let top = -0.74, notch = 0.034, depth = 0.085
        let leftEdge = [P(x - 0.082, 0.0), P(x - 0.056, top + 0.06)]
        let horn = curve(P(x - 0.056, top + 0.06), P(x - 0.07, top + 0.01), P(x - 0.145, top - 0.07), 10)
        let fork = leftEdge + horn.dropFirst()
            + [P(x - 0.11, top - 0.105), P(x - notch, top - 0.06), P(x - notch, top - 0.06 + depth)]
        let lever = fork + fork.reversed().map { P(2 * x - $0.x, $0.y) } + [fork[0]]

        // The anchor: a crescent about the arbor, from seven o'clock round to five, its middle webbed to the arbor.
        let span = (from: Kit.clock(4.9), to: Kit.clock(7.1)), inner = 0.71, outer = 0.83
        let crescent = arc(arbor, outer, from: span.from, to: span.to) + arc(arbor, inner, from: span.to, to: span.from)
        let web = [polar(arbor, 0.05, 0.4), polar(arbor, inner + 0.01, .pi / 2 - 0.1), polar(arbor, inner + 0.01, .pi / 2 + 0.1),
                   polar(arbor, 0.05, .pi - 0.4)]
        // The web's lightening slot.
        let slot = curve(P(x, 0.14), P(x - 0.06, 0.38), P(x, 0.6), 12) + curve(P(x, 0.6), P(x + 0.06, 0.38), P(x, 0.14), 12)
        // The jewels, set in slots at each end of the crescent and standing out below it.
        func jewel(_ a: Double, lean: Double) -> [P] {
            let d = P(cos(a), sin(a)), n = P(-d.y, d.x), base = arbor + d * (inner + 0.02), tip = arbor + d * 0.97
            return [base + n * 0.03, tip + n * 0.03 + d.x * lean * n, tip - n * 0.03 - d * 0.03, base - n * 0.03, base + n * 0.03]
        }
        let entry = jewel(span.to + 0.06, lean: 0), exit = jewel(span.from - 0.06, lean: 0)

        // The escape wheel's rim and teeth under the pallets, phased so a tooth's face lies on each jewel.
        let phase = atan2(entry[1].y - wheel.y, entry[1].x - wheel.x) - 0.6 * tau
        var outline: [P] = []
        for k in stride(from: teeth, to: 0, by: -1) {
            let a = phase + Double(k) * tau
            outline += [polar(wheel, 0.78 * teethTip, a), polar(wheel, teethTip, a + 0.18 * tau), polar(wheel, 0.97 * teethTip, a - 0.02 * tau),
                        polar(wheel, 0.86 * teethTip, a - 0.1 * tau), polar(wheel, 0.78 * teethTip, a - 0.4 * tau)]
        }
        outline.append(outline[0])

        Kit.ground(&plate, angle: -0.55)
        Kit.mass(&plate, outline)
        plate.line(arc(wheel, 0.72 * teethTip), medium, .bone)
        for k in 0..<teeth {
            let a = phase + Double(k) * tau
            plate.line([polar(wheel, 0.92 * teethTip, a + 0.1 * tau), polar(wheel, 0.9 * teethTip, a - 0.06 * tau)], medium, .bone)
        }

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
        for p in [polar(arbor, (inner + outer) / 2, span.from + 0.2), polar(arbor, (inner + outer) / 2, span.to - 0.2)] {
            plate.fill(arc(p, 0.03))
            plate.line(arc(p, 0.03), medium)
            plate.line([p + P(-0.024, 0.012), p + P(0.024, -0.012)], 0.01)
        }
        // The guard pin, standing in the notch's floor.
        let pin = P(x, top - 0.06 + depth)
        Kit.mass(&plate, [pin + P(-0.011, 0.0), pin + P(-0.011, -0.07), pin + P(0, -0.085), pin + P(0.011, -0.07), pin + P(0.011, 0), pin + P(-0.011, 0)])

        Kit.solid(&plate, entry, angle: 0.5, gap: 0.012, ink: .second, width: fine, edge: heavy)
        Kit.solid(&plate, exit, angle: 0.5, gap: 0.012, width: fine, edge: heavy)

        // The fork again, edge on, to the left: the lever's blade, the staff and its pivots, the pallets' stones hanging
        // from the anchor, the guard pin standing up at the fork's end.
        let staff = -0.4, end = -0.92
        let panel = curve(P(-0.96, -0.2), P(-0.6, -0.24), P(-0.22, -0.2), 12) + curve(P(-0.22, 0.19), P(-0.6, 0.23), P(-0.96, 0.19), 12)
        Kit.cut(&plate, panel + [panel[0]])
        Kit.mass(&plate, [P(end, -0.045), P(-0.27, -0.045), P(-0.27, 0.05), P(staff - 0.05, 0.05), P(staff - 0.12, 0.03), P(end, 0.03), P(end, -0.045)])
        Kit.mass(&plate, Kit.band(P(staff, -0.1), P(staff, 0.11), 0.034))
        for (y0, y1) in [(-0.135, -0.1), (0.11, 0.145)] { Kit.mass(&plate, Kit.band(P(staff, y0), P(staff, y1), 0.014)) }
        Kit.solid(&plate, [P(staff - 0.04, -0.075), P(staff + 0.04, -0.075), P(staff + 0.04, -0.03), P(staff - 0.04, -0.03), P(staff - 0.04, -0.075)],
                  angle: 0.7, gap: 0.014, width: fine)
        Kit.solid(&plate, box(P(-0.35, 0.05), P(-0.285, 0.13)), angle: 0.5, gap: 0.012, width: fine, edge: heavy)
        Kit.mass(&plate, Kit.band(P(end + 0.07, -0.04), P(end + 0.07, -0.1), 0.022))
        plate.line([P(end + 0.02, -0.01), P(-0.29, -0.01)], medium, .bone)
        for ax in [end, -0.27] { plate.line([P(ax, -0.13), P(ax, -0.19)], fine) }
        plate.lines(dashed([P(end, -0.16), P(-0.27, -0.16)], on: 0.02, off: 0.012), fine)

        callout(&plate, "A", from: P(x - 0.11, top - 0.04), to: P(-0.18, -0.86))
        callout(&plate, "B", from: pin + P(0, -0.05), to: P(0.6, -0.72))
        callout(&plate, "C", from: polar(arbor, 0.9, span.to + 0.06), to: P(-0.62, 0.62))
        callout(&plate, "D", from: polar(wheel, 0.9 * teethTip, phase + 3.3 * tau), to: P(0.84, 0.28))
        return plate
    }

    /// Problem 35, Click spring, pent, clocks 0+: the crown wheel's ratchet on the barrel bridge, a big ink plate whose
    /// arms run out between the rods to its screws; off it, at one o'clock, the click on its screw and the click spring,
    /// a long hairpin blade bent round two screws, bearing on the click's tail. The click's tip, in the tooth, is in the
    /// second ink.
    static func plate35() -> Plate {
        var plate = Plate()
        let o = Kit.origin, lane = -54.0 * .pi / 180
        // The bridge: a round middle under the ratchet, and an arm out along each lane but the click's.
        let middle = 0.445, arms = [18.0, 90.0, 162.0, 234.0].map { $0 * .pi / 180 }
        var bridge: [P] = []
        for (k, a) in arms.enumerated() {
            let next = k + 1 < arms.count ? arms[k + 1] : arms[0] + 2 * .pi
            let half = 0.085, end = 0.84
            bridge += [polar(o, middle + 0.1, a - asin(half / (middle + 0.1)))]
            bridge += [polar(o, end, a) + P(cos(a - .pi / 2), sin(a - .pi / 2)) * half]
            bridge += arc(polar(o, end, a), half, from: a - .pi / 2, to: a + .pi / 2)
            bridge += [polar(o, middle + 0.1, a + asin(half / (middle + 0.1)))]
            let from = a + asin(half / middle) + 0.12, to = k + 1 < arms.count ? next - asin(half / middle) - 0.12 : lane + 2 * .pi - 0.3
            bridge += arc(o, middle, from: from, to: to)
            if k + 1 == arms.count {
                bridge += [polar(o, 0.42, lane + 2 * .pi - 0.2), polar(o, 0.42, lane + 2 * .pi + 0.2)]
                bridge += arc(o, middle, from: lane + 2 * .pi + 0.3, to: arms[0] + 2 * .pi - asin(0.085 / middle) - 0.12)
            }
        }
        bridge.append(bridge[0])
        // The ratchet: 30 teeth, each face radial and its back sloping down against the turn.
        let teeth = 30, tau = 2 * Double.pi / Double(teeth), root = 0.335, tip = 0.395
        let nose = polar(o, 0.345, lane - 0.2), face = lane - 0.2 - 0.25 * tau
        let ratchet = (0..<teeth).flatMap { k -> [P] in
            let a = face + Double(k) * tau
            return [polar(o, root, a), polar(o, tip, a + tau)]
        } + [polar(o, root, face)]

        Kit.ground(&plate, angle: 0.6)
        Kit.mass(&plate, bridge)
        plate.line(arc(o, middle - 0.03, from: arms[0] + 0.35, to: lane + 2 * .pi - 0.35), fine, .bone)
        for a in arms {
            for side in [-1.0, 1.0] {
                let off = P(-sin(a), cos(a)) * (side * 0.058)
                plate.line([polar(o, middle + 0.02, a) + off, polar(o, 0.78, a) + off], medium, .bone)
            }
            let c = polar(o, 0.84, a)
            plate.fill(arc(c, 0.055))
            plate.line(arc(c, 0.055), heavy)
            plate.line(arc(c, 0.042), fine)
            Kit.mass(&plate, Kit.band(polar(c, 0.048, a + 0.7), polar(c, 0.048, a + 0.7 + .pi), 0.02))
        }

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

        // The click spring in the lane between twelve and two: an eye round the near screw, a leg out, a bend round
        // the far screw, and a leg back to bear on the click's tail.
        let u = P(cos(lane), sin(lane)), v = P(-u.y, u.x)
        func at(_ r: Double, _ s: Double) -> P { u * r + v * s }
        let near = at(0.6, -0.075), far = at(0.88, 0), leg = 0.072
        var spring = [at(0.6, -0.075 + 0.0) + u * 0.04, at(0.88, -leg)]
        spring += (1...24).map { i -> P in
            let t = Double(i) / 24 * .pi
            return far - v * (leg * cos(t)) + u * (leg * sin(t))
        }
        spring += [at(0.62, leg)]
        plate.fill(Kit.ribbon(spring, 0.084))
        Kit.mass(&plate, Kit.ribbon(spring, 0.052))
        plate.line(Array(spring.dropFirst().dropLast()), fine, .bone)
        plate.fill(arc(near, 0.072))
        Kit.mass(&plate, arc(near, 0.062))

        // The click on its screw, its nose in a tooth and its tail under the spring, edged in bone off the bridge.
        let pivot = at(0.5, 0.0), d = simd_normalize(pivot - nose), n = P(-d.y, d.x)
        let click = [nose, nose + d * 0.07 + n * 0.042, pivot + n * 0.062, pivot + d * 0.09 + n * 0.05, pivot + d * 0.135 + n * 0.02,
                     pivot + d * 0.12 - n * 0.035, pivot - n * 0.06, nose + d * 0.06 - n * 0.018, nose]
        plate.line(click, 0.03, .bone)
        Kit.mass(&plate, click)
        let tipInk = [nose, nose + d * 0.06 + n * 0.038, nose + d * 0.055 - n * 0.016, nose]
        plate.fill(tipInk, .second)
        plate.line(tipInk, medium)
        for c in [near, far, pivot] {
            plate.fill(arc(c, 0.036))
            plate.line(arc(c, 0.036), heavy)
            plate.line([polar(c, 0.028, 0.5), polar(c, 0.028, 0.5 + .pi)], 0.012)
        }

        callout(&plate, "A", from: polar(o, 0.37, 3.3), to: P(-0.74, 0.12))
        callout(&plate, "B", from: pivot - d * 0.06 + n * 0.03, to: P(0.06, -0.86))
        callout(&plate, "C", from: at(0.74, leg), to: P(0.84, -0.08))
        callout(&plate, "D", from: polar(o, 0.7, .pi / 2) + P(0.06, 0), to: P(0.2, 0.74))
        return plate
    }

    /// Problem 36, Crown wheel, hex, clocks 1+: a contrate wheel seen from above and in front, its teeth standing up
    /// off the rim like a crown's points round a face of spokes and windows, its staff going down; a lantern pinion,
    /// seen end on over the back teeth, is driven by them, its arbor running out toward the eye. The pinion's pivot is
    /// in the second ink.
    static func plate36() -> Plate {
        var plate = Plate()
        let centre = P(-0.24, 0.12), radius = 0.72, rim = 0.04, crown = 0.2, elevation = 25.0 * .pi / 180
        // The wheel's own frame: x across, y toward the eye, z up its axis.
        func seen(_ x: Double, _ y: Double, _ z: Double) -> P { centre + P(x, y * sin(elevation) - z * cos(elevation)) }
        func round(_ r: Double, _ z: Double, from a: Double = 0, to b: Double = 2 * .pi, steps: Int = 120) -> [P] {
            (0...steps).map { i in
                let t = a + (b - a) * Double(i) / Double(steps)
                return seen(r * cos(t), r * sin(t), z)
            }
        }
        let teeth = 18, tau = 2 * Double.pi / Double(teeth)
        func tooth(_ k: Int) -> (ring: [P], depth: Double) {
            let a = 0.12 + Double(k) * tau, w = 0.3 * tau
            let foot = [seen(radius * cos(a - w), radius * sin(a - w), rim), seen(radius * cos(a + w), radius * sin(a + w), rim)]
            let point = [seen(radius * cos(a + 0.2 * w), radius * sin(a + 0.2 * w), crown),
                         seen(radius * cos(a - 0.2 * w), radius * sin(a - 0.2 * w), crown)]
            return (foot + [point[0], point[1], foot[0]], sin(a))
        }
        let face = round(radius, rim)
        let band = round(radius, rim, from: 0, to: .pi) + round(radius, 0, from: .pi, to: 0)
        let well = round(0.9 * radius, rim)
        // The windows between four spokes, laid out flat on the face and seen.
        let spokes = (0..<4).map { k -> [P] in
            let a = 0.94 + Double(k) * .pi / 2, b = a + .pi / 2, gap = 0.036
            let outer = (0...30).map { i -> P in
                let t = a + gap / 0.62 + (b - a - 2 * gap / 0.62) * Double(i) / 30
                return seen(0.62 * cos(t), 0.62 * sin(t), rim)
            }
            let inner = (0...10).map { i -> P in
                let t = b - gap / 0.16 - (b - a - 2 * gap / 0.16) * Double(i) / 10
                return seen(0.16 * cos(t), 0.16 * sin(t), rim)
            }
            return outer + inner + [outer[0]]
        }

        // The lantern pinion over the back teeth, its axis running toward the wheel's middle and on to the eye.
        let azimuth = -93.0 * .pi / 180, rp = 0.125, height = crown + rp - 0.045
        func onAxis(_ r: Double) -> P { seen(r * cos(azimuth), r * sin(azimuth), height) }
        let rear = onAxis(radius + 0.075), front = onAxis(radius - 0.075), pivot = onAxis(radius - 0.36)
        func endPlate(_ c: P) -> [P] { ellipse(c, rp, rp * cos(elevation) + 0.012) }

        Kit.ground(&plate, angle: -0.3)
        // The staff below the wheel, then the rim's outside and the face.
        Kit.mass(&plate, Kit.band(seen(0, 0, -0.05), seen(0, 0, -1.0), 0.07))
        Kit.mass(&plate, band)
        Kit.mass(&plate, face)
        for hole in spokes {
            plate.fill(hole)
            plate.lines(hatch([hole], angle: -0.3, gap: Kit.groundGap), Kit.groundWidth)
            plate.line(hole, heavy)
        }
        plate.line(well, medium, .bone)
        plate.fill(round(0.09, rim))
        plate.lines(hatch([round(0.09, rim)], angle: 0.6, gap: 0.016), fine)
        plate.line(round(0.09, rim), heavy)
        Kit.mass(&plate, round(0.035, rim))
        // The teeth, back to front, each edged in bone so it stands off the ones behind.
        for t in (0..<teeth).map(tooth).sorted(by: { $0.depth < $1.depth }) {
            plate.line(t.ring, 0.016, .bone)
            Kit.mass(&plate, t.ring)
            if t.depth > 0 { plate.line([t.ring[0], t.ring[1]], fine, .bone) }
        }
        plate.line(round(radius, 0, from: 0, to: .pi), 0.014)

        // The pinion: its rear plate, the trundles between, the front plate, the arbor out to its pivot.
        Kit.mass(&plate, Kit.band(onAxis(radius + 0.16), pivot, 0.034))
        Kit.cut(&plate, endPlate(rear), edge: heavy)
        plate.line(ellipse(rear, 0.07, 0.07 * cos(elevation)), medium)
        for k in 0..<8 {
            let a = Double(k) * .pi / 4 + 0.2, off = P(0.094 * cos(a), 0.094 * sin(a) * cos(elevation))
            Kit.mass(&plate, Kit.band(rear + off, front + off, 0.024))
        }
        plate.fill(endPlate(front))
        plate.lines(hatch([endPlate(front), ellipse(front, 0.07, 0.07 * cos(elevation))], angle: 0.9, gap: 0.02), fine)
        plate.line(endPlate(front), heavy)
        plate.line(ellipse(front, 0.07, 0.07 * cos(elevation)), medium)
        for k in 0..<8 {
            let a = Double(k) * .pi / 4 + 0.2
            Kit.mass(&plate, arc(front + P(0.094 * cos(a), 0.094 * sin(a) * cos(elevation)), 0.016))
        }
        Kit.mass(&plate, Kit.band(front, pivot, 0.034))
        let cone = [pivot + P(-0.03, -0.02), pivot + P(0.03, -0.02), pivot + P(0, 0.065), pivot + P(-0.03, -0.02)]
        plate.fill(cone, .second)
        plate.line(cone, medium)

        callout(&plate, "A", from: tooth(5).ring[2], to: P(0.2, 0.86))
        callout(&plate, "B", from: seen(0.4 * cos(0.94 + .pi / 4), 0.4 * sin(0.94 + .pi / 4), rim), to: P(0.86, 0.0))
        callout(&plate, "C", from: rear + P(0.08, -0.04), to: P(0.2, -0.86))
        callout(&plate, "D", from: pivot + P(0, 0.04), to: P(-0.82, -0.52))
        return plate
    }
}
