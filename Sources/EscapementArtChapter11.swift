// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 11, Gear Train: problems 61 to 66's plates, drawn with `Kit`.
extension EscapementArt {
    /// Problem 61, Pinion, hex, clocks 1+,2+: a long pinion in elevation between the movement's two plates cut in
    /// section, its six leaves in bold ink along the lane at three o'clock and its end face turned to show them, its arbor carrying a wheel seen nearly
    /// edge on, each pivot running in a jewel set in its chaton; the right-hand jewel in the second ink.
    static func plate61() -> Plate {
        var plate = Plate()
        let r = 0.086, x0 = 0.2, x1 = 0.72, shaft = 0.05
        let inner = 0.8, jewel = 0.885
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
                let c = P(s * 0.9, y)
                Kit.cut(&plate, box(c - P(0.05, 0.028), c + P(0.05, 0.028)), edge: heavy)
                plate.line([c - P(0.05, 0), c + P(0.05, 0)], heavy)
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
        let rimOut = ellipse(P(-0.42, 0), 0.1, 0.66), rimIn = ellipse(P(-0.42, 0), 0.084, 0.61)
        plate.fill(rimOut, .black)
        plate.fill(rimIn)
        plate.lines(hatch([rimIn], angle: 0.35, gap: Kit.groundGap), Kit.groundWidth)
        for k in 0..<4 {
            let a = Double(k) * .pi / 2 + .pi / 4
            let tip = P(-0.42 + 0.084 * cos(a), 0.61 * sin(a))
            Kit.mass(&plate, Kit.band(P(-0.42, 0), tip, 0.026))
        }
        for k in 0..<40 {
            let a = Double(k) * 2 * .pi / 40
            guard cos(a) < 0.2 else { continue }
            let foot = P(-0.42 + 0.1 * cos(a), 0.66 * sin(a)), d = simd_normalize(P(0.1 * cos(a) / 0.01, 0.66 * sin(a) / 0.4356))
            Kit.mass(&plate, Kit.band(foot - d * 0.005, foot + d * 0.024, 0.02))
        }
        plate.line(rimOut, medium)
        
        // The wheel's collet on the arbor, in section.
        let collet = box(P(-0.5, -0.075), P(-0.36, 0.075))
        Kit.solid(&plate, collet, angle: 0.8, gap: 0.014)

        // The arbor, from jewel to jewel, its pivots drawn down to points.
        let arbor = [P(-0.76, -shaft / 2), P(x0, -shaft / 2), P(x0, shaft / 2), P(-0.76, shaft / 2), P(-0.76, -shaft / 2)]
        Kit.mass(&plate, arbor)
        Kit.mass(&plate, box(P(x1, -shaft / 2), P(0.76, shaft / 2)))
        plate.line([P(-0.75, -0.01), P(x0 - 0.01, -0.01)], fine, .bone)
        plate.line([P(x1 + 0.01, -0.01), P(0.75, -0.01)], fine, .bone)
        Kit.mass(&plate, box(P(-0.36, -0.04), P(-0.33, 0.04)))
        for s in [-1.0, 1.0] {
            let shoulder = P(s * 0.76, 0), point = P(s * jewel, 0)
            Kit.mass(&plate, [shoulder + P(0, -shaft / 2), point + P(0, -0.009), point + P(0, 0.009), shoulder + P(0, shaft / 2),
                              shoulder + P(0, -shaft / 2)])
        }

        // The jewels: each a stone set in a chaton cut into the plate, the arbor's pivot point in its hole.
        for s in [-1.0, 1.0] {
            let c = P(s * jewel, 0)
            let chaton = [c + P(-0.075, -0.13), c + P(0.075, -0.13), c + P(0.075, 0.13), c + P(-0.075, 0.13), c + P(-0.075, -0.13)]
            Kit.cut(&plate, chaton, edge: heavy)
            plate.line(Array(chaton[0...1]).map { $0 + P(0, 0.018) }, medium)
            plate.line(Array(chaton[2...3]).map { $0 - P(0, 0.018) }, medium)
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

        // The pinion: six leaves along the arbor, each face in ink, the spaces between them bone, and the end face turned
        // a little toward the eye to show their profile.
        let leaves = 6, tooth = 0.36
        Kit.cut(&plate, pinion)
        for k in 0..<leaves {
            let a = atan2(sin(Double(k) * 2 * .pi / Double(leaves)), cos(Double(k) * 2 * .pi / Double(leaves)))
            guard cos(a) > 0 else { continue }
            let y0 = r * sin(max(a - tooth, -.pi / 2)), y1 = r * sin(min(a + tooth, .pi / 2))
            Kit.mass(&plate, box(P(x0, min(y0, y1)), P(x1, max(y0, y1))))
        }
        for s in [-1.0, 1.0] {
            Kit.mass(&plate, box(P(x0, s * r - 0.012), P(x1, s * r)))
        }
        plate.line([P(x0 + 0.02, -0.012), P(x1 - 0.06, -0.012)], fine, .bone)
        plate.line(pinion, medium)
        Kit.mass(&plate, box(P(x0 - 0.03, -0.06), P(x0, 0.06)))
        let end = P(x1, 0), rx = 0.065
        var face: [P] = []
        for i in 0...120 {
            let a = Double(i) * 2 * .pi / 120
            let lobe = 0.5 + 0.5 * cos(Double(leaves) * a)
            let rad = 0.5 + 0.5 * pow(lobe, 0.35)
            face.append(end + P(rx * rad * cos(a), r * rad * sin(a)))
        }
        plate.fill(ellipse(end, rx, r), .black)
        Kit.cut(&plate, face, edge: heavy)
        Kit.mass(&plate, ellipse(end, 0.018, 0.026))
        plate.line(ellipse(end, rx, r, from: -.pi / 2, to: .pi / 2), medium)

        callout(&plate, "A", from: P(0.46, -0.06), to: P(0.32, -0.52))
        callout(&plate, "B", from: P(jewel, 0.07), to: P(0.66, 0.56))
        callout(&plate, "C", from: P(-0.41, 0.64), to: P(-0.3, 0.74))
        callout(&plate, "D", from: P(-jewel, -0.02), to: P(-0.68, -0.52))
        return plate
    }

    /// Problem 62, Arbor, pent, clocks 0+,1-: a watchmaker's turns held by its tail in the bench vice, the arbor
    /// between the runners' centres in the clear middle, the bow drawn back with its string once round the ferrule;
    /// the arbor's right-hand pivot point in the second ink.
    static func plate62() -> Plate {
        var plate = Plate()
        let axis = 0.0, bar = 0.33
        let poppets = [-1.0, 1.0].map { s in
            [P(s * 0.4, bar), P(s * 0.4, -0.08), P(s * 0.45, -0.13), P(s * 0.6, -0.13), P(s * 0.62, -0.1), P(s * 0.66, bar), P(s * 0.4, bar)]
        }
        let frame = box(P(-1.1, bar), P(1.1, bar + 0.09))
        let tail = box(P(-0.06, bar + 0.09), P(0.06, 1.1))
        let jaws = [-1.0, 1.0].map { s in box(P(s * 0.06, 0.58), P(s * 0.3, 1.1)) }
        // The bow: a cane bent by its string, its handle pulled out to the right.
        let tip = P(-0.86, -0.46), heel = P(0.74, -0.52)
        let cane = curve(tip, P(-0.05, -0.98), heel, 48)
        let stick = Kit.ribbon(cane, 0.05)
        let handle = [heel + P(-0.02, -0.06), heel + P(0.3, -0.07), heel + P(0.34, 0), heel + P(0.3, 0.07), heel + P(-0.02, 0.06),
                      heel + P(-0.02, -0.06)]
        let ferrule = P(-0.15, axis), fr = 0.09

        Kit.ground(&plate, angle: -0.4, around: poppets + jaws + [frame, tail, stick, handle])

        // The vice's jaws gripping the turns' tail, their chops serrated.
        for (k, jaw) in jaws.enumerated() {
            let s = k == 0 ? -1.0 : 1.0
            Kit.cut(&plate, jaw, edge: heavy)
            plate.lines(hatch([jaw], angle: .pi / 2, gap: 0.03), medium)
            Kit.mass(&plate, box(P(s * 0.24, 0.58), P(s * 0.3, 1.1)))
            Kit.mass(&plate, box(P(s * 0.3, 0.5), P(s * 0.06, 0.58)))
            plate.line([P(s * 0.08, 0.52), P(s * 0.28, 0.52)], fine, .bone)
            var chops: [P] = []
            for y in stride(from: 0.6, to: 1.08, by: 0.04) { chops += [P(s * 0.06, y), P(s * 0.095, y + 0.02)] }
            Kit.mass(&plate, [P(s * 0.06, 0.58)] + chops + [P(s * 0.06, 1.1), P(s * 0.06, 0.58)])
        }
        Kit.mass(&plate, tail)
        plate.line([P(-0.035, bar + 0.1), P(-0.035, 1)], fine, .bone)

        // The frame bar and its heads, each head's runner bored through and its binding screw on top.
        Kit.mass(&plate, frame)
        plate.line([P(-1, bar + 0.02), P(1, bar + 0.02)], fine, .bone)
        for (k, head) in poppets.enumerated() {
            let s = k == 0 ? -1.0 : 1.0
            Kit.cut(&plate, head, edge: heavy)
            plate.lines(hatch([head], angle: .pi / 2, gap: 0.03), medium)
            Kit.mass(&plate, [P(s * 0.6, -0.13), P(s * 0.62, -0.1), P(s * 0.66, bar), P(s * 0.6, bar), P(s * 0.6, -0.13)])
            Kit.solid(&plate, box(P(s * 0.46, bar - 0.11), P(s * 0.56, bar - 0.04)), angle: 0.8, gap: 0.012)
            let screw = box(P(s * 0.48, -0.23), P(s * 0.58, -0.13))
            Kit.solid(&plate, screw, angle: 0, gap: 0.016)
            Kit.mass(&plate, box(P(s * 0.515, -0.13), P(s * 0.545, -0.1)))
            // The runner: a steel rod through the head, its centre turned to a point at the arbor's pivot.
            let inner = s * 0.335, outer = s * 1.1
            Kit.mass(&plate, [P(inner + s * 0.05, axis - 0.026), P(outer, axis - 0.026), P(outer, axis + 0.026),
                              P(inner + s * 0.05, axis + 0.026), P(inner + s * 0.05, axis - 0.026)])
            plate.line([P(inner + s * 0.06, axis - 0.01), P(s * 1, axis - 0.01)], fine, .bone)
            Kit.solid(&plate, [P(inner + s * 0.05, axis - 0.026), P(inner + s * 0.05, axis + 0.026), P(inner, axis + 0.008),
                               P(inner, axis - 0.008), P(inner + s * 0.05, axis - 0.026)], angle: 0.6, gap: 0.01)
            for x in stride(from: 0.74, to: 0.95, by: 0.04) {
                Kit.solid(&plate, box(P(s * x, axis - 0.042), P(s * (x + 0.022), axis + 0.042)), angle: 0.9, gap: 0.01)
            }
        }

        // The arbor between the centres: its pivots, the ferrule the string drives, its pinion, the seat for its wheel.
        Kit.mass(&plate, box(P(-0.29, axis - 0.026), P(0.29, axis + 0.026)))
        plate.line([P(-0.28, axis - 0.01), P(0.28, axis - 0.01)], fine, .bone)
        let leaves = box(P(-0.01, axis - 0.06), P(0.12, axis + 0.06))
        plate.fill(leaves, .black)
        for y in [-0.04, -0.012, 0.016, 0.042] {
            Kit.cut(&plate, box(P(0.0, axis + y - 0.008), P(0.11, axis + y + 0.008)), edge: fine)
        }
        plate.line(leaves, medium)
        let seat = [P(0.17, axis - 0.1), P(0.2, axis - 0.1), P(0.2, axis - 0.05), P(0.24, axis - 0.04), P(0.24, axis + 0.04),
                    P(0.2, axis + 0.05), P(0.2, axis + 0.1), P(0.17, axis + 0.1), P(0.17, axis - 0.1)]
        Kit.solid(&plate, seat, angle: 0.8, gap: 0.012)
        let pulley = [ferrule + P(-0.05, -fr), ferrule + P(0.05, -fr), ferrule + P(0.028, 0), ferrule + P(0.05, fr),
                      ferrule + P(-0.05, fr), ferrule + P(-0.028, 0), ferrule + P(-0.05, -fr)]
        Kit.solid(&plate, pulley, angle: 0.8, gap: 0.012)
        for s in [-1.0, 1.0] {
            let point = [P(s * 0.28, axis - 0.026), P(s * 0.335, axis), P(s * 0.28, axis + 0.026), P(s * 0.28, axis - 0.026)]
            if s > 0 {
                plate.fill(point, .second)
                plate.line(point, fine, .second)
            } else {
                Kit.mass(&plate, point)
            }
        }

        // The bow's string, from the cane's tip once round the ferrule and back to the handle.
        let over = ferrule + P(-0.035, -fr + 0.01), under = ferrule + P(0.035, fr - 0.01)
        plate.line([tip + P(0.01, 0.02), ferrule + P(-0.04, -fr + 0.004)], heavy)
        plate.line([over, under], heavy)
        plate.line([ferrule + P(0.04, -fr + 0.004), heel + P(0, 0.03)], heavy)
        Kit.mass(&plate, stick)
        plate.line(Array(cane[4...44]), fine, .bone)
        Kit.mass(&plate, handle)
        for x in [0.06, 0.14, 0.22] {
            plate.line([heel + P(x, -0.064), heel + P(x, 0.064)], medium, .bone)
        }
        Kit.mass(&plate, Kit.band(tip + P(-0.03, -0.03), tip + P(0.04, 0.05), 0.05))

        callout(&plate, "A", from: P(0.05, axis - 0.05), to: P(0.12, -0.21))
        callout(&plate, "B", from: ferrule + P(0.01, 0.05), to: P(-0.07, 0.2))
        callout(&plate, "C", from: cane[30], to: P(0.42, -0.6))
        callout(&plate, "D", from: P(-0.9, axis), to: P(-0.86, -0.2))
        return plate
    }

    /// Problem 63, Third wheel, hex, clocks 1-,2-: a Victorian tricycle in side view on its road, the two great
    /// wheels one behind the other, the small third wheel trailing in the clear lane at five o'clock, its backbone,
    /// chain, handlebar and sprung seat; the lamp on the steering head in the second ink.
    static func plate63() -> Plate {
        var plate = Plate()
        let road = 0.885
        let wheel = 0.66, near = P(-0.25, road - wheel), far = near + P(-0.15, -0.06), third = P(0.4, road - 0.19)
        let head = P(-0.24, -0.5), fork = P(0.33, 0.45), saddle = P(0.16, -0.36)
        let spine = curve(near + P(0.03, -0.04), P(0.05, 0.12), fork, 30)
        let stem = Kit.ribbon([near, head], 0.036)

        Kit.ground(&plate, angle: 0.5, around: [arc(near, wheel), arc(third, 0.19), box(P(-1.1, road), P(1.1, 1.1))])

        // The far great wheel, behind: its tyre and spokes seen through the near wheel.
        spoked(&plate, far, wheel, tyre: 0.03, spokes: 10, spoke: 0.012, phase: 0.13)
        // The road, and the near great wheel on it.
        Kit.mass(&plate, box(P(-1.1, road), P(1.1, road + 0.05)))
        plate.lines(hatch([box(P(-1.1, road + 0.05), P(1.1, 1.1))], angle: 0, gap: 0.03), medium)
        spoked(&plate, near, wheel, tyre: 0.052, spokes: 10, spoke: 0.028, phase: -0.445)
        // The axle across to the far wheel's hub, seen through the near wheel's spokes.
        Kit.mass(&plate, Kit.band(near, far, 0.042))
        Kit.mass(&plate, arc(far, 0.05))
        plate.line([near + P(-0.01, -0.012), far + P(0.02, -0.012)], fine, .bone)

        // The chain from the crank's wheel under the seat to the great wheels' axle.
        let crank = P(0.12, 0.34)
        plate.line([crank + P(0, -0.07), near + P(0, -0.05)], heavy)
        plate.line([crank + P(0, 0.07), near + P(0, 0.05)], heavy)
        Kit.solid(&plate, arc(crank, 0.075), angle: 0.8, gap: 0.014)
        Kit.mass(&plate, arc(crank, 0.025))
        Kit.mass(&plate, Kit.band(crank, crank + P(0.1, -0.13), 0.034))
        Kit.mass(&plate, box(crank + P(0.06, -0.16), crank + P(0.15, -0.12)))
        Kit.mass(&plate, Kit.band(crank, crank + P(-0.1, 0.13), 0.034))

        // The backbone from the axle back to the third wheel's fork, the steering head and its handlebar.
        Kit.mass(&plate, Kit.ribbon(spine, 0.046))
        plate.line(Array(spine[2...27]).map { $0 + P(0, -0.012) }, fine, .bone)
        Kit.mass(&plate, stem)
        Kit.mass(&plate, Kit.ribbon(curve(head, head + P(0.2, -0.1), head + P(0.3, 0.04), 16), 0.03))
        Kit.mass(&plate, ellipse(head + P(0.31, 0.08), 0.05, 0.024, turned: 1.3))
        Kit.mass(&plate, arc(near, 0.07))
        plate.fill(arc(near, 0.03))
        plate.line(arc(near, 0.03), medium)

        // The seat on its pillar, sprung on two coils.
        Kit.mass(&plate, Kit.band(P(0.12, 0.24), saddle + P(0, 0.08), 0.036))
        for dx in [-0.05, 0.05] {
            var coil: [P] = []
            for i in 0...40 {
                let t = Double(i) / 40
                coil.append(saddle + P(dx + 0.022 * sin(t * 8 * .pi), 0.08 - 0.07 * t))
            }
            plate.line(coil, medium)
        }
        let seat = [saddle + P(-0.15, -0.02), saddle + P(-0.12, -0.07), saddle + P(0.02, -0.06), saddle + P(0.13, -0.11),
                    saddle + P(0.16, -0.07), saddle + P(0.12, 0.01), saddle + P(-0.15, 0.01), saddle + P(-0.15, -0.02)]
        Kit.mass(&plate, seat)
        plate.line([saddle + P(-0.12, -0.035), saddle + P(0.1, -0.06)], fine, .bone)
        Kit.mass(&plate, box(saddle + P(-0.12, 0.01), saddle + P(0.1, 0.03)))

        // The third wheel trailing in its fork.
        Kit.mass(&plate, Kit.band(fork, third, 0.04))
        spoked(&plate, third, 0.19, tyre: 0.045, spokes: 8, spoke: 0.026, phase: 0.2)
        Kit.mass(&plate, Kit.band(fork + P(-0.02, -0.02), fork + P(0.05, -0.02), 0.06))

        // The lamp on the steering head: its body, chimney and lens.
        let lamp = head + P(-0.1, -0.16)
        Kit.mass(&plate, Kit.band(head + P(-0.01, -0.02), lamp + P(0.03, 0.06), 0.022))
        let body = box(lamp + P(-0.045, -0.06), lamp + P(0.045, 0.06))
        plate.fill(body, .second)
        plate.line(body, medium)
        Kit.mass(&plate, [lamp + P(-0.03, -0.06), lamp + P(-0.015, -0.1), lamp + P(0.015, -0.1), lamp + P(0.03, -0.06),
                          lamp + P(-0.03, -0.06)])
        Kit.cut(&plate, arc(lamp + P(-0.045, 0), 0.032), edge: heavy)
        plate.line(arc(lamp + P(-0.045, 0), 0.016), medium)

        callout(&plate, "A", from: third + P(0.06, 0.06), to: P(0.66, 0.5))
        callout(&plate, "B", from: lamp + P(0.04, -0.03), to: P(-0.2, -0.83))
        callout(&plate, "C", from: saddle + P(0.13, -0.09), to: P(0.4, -0.64))
        callout(&plate, "D", from: polar(near, wheel - 0.03, -2.75), to: P(-0.62, -0.62))
        return plate
    }

    /// A spoked wheel in side view: a tyre of ink, its rim's line in bone, straight spokes to a hub.
    private static func spoked(_ plate: inout Plate, _ c: P, _ r: Double, tyre: Double, spokes: Int, spoke: Double,
                               phase: Double) {
        plate.fill(arc(c, r), .black)
        plate.fill(arc(c, r - tyre))
        plate.lines(hatch([arc(c, r - tyre)], angle: 0.5, gap: Kit.groundGap), Kit.groundWidth)
        for k in 0..<spokes {
            let a = phase + Double(k) * 2 * .pi / Double(spokes)
            Kit.mass(&plate, Kit.band(polar(c, 0.04, a), polar(c, r - tyre + 0.005, a), spoke))
        }
        plate.line(arc(c, r), medium)
        plate.line(arc(c, r - 0.35 * tyre), fine, .bone)
        plate.line(arc(c, r - tyre), medium)
        Kit.mass(&plate, arc(c, max(0.045, 0.1 * r)))
    }

    /// Problem 64, Barrel, hex, clocks 1+,2-: a cask on its side on a cradle of two chocks, its staves bone between
    /// heavy seams with the one in shadow in ink, four iron hoops set in the lanes clear of every hub, its head turned
    /// to show its boards; the tap in the head in the second ink.
    static func plate64() -> Plate {
        var plate = Plate()
        let end = 0.78, belly = 0.5, waist = 0.4
        func half(_ x: Double) -> Double { waist + (belly - waist) * (1 - (x / end) * (x / end)) }
        let xs = stride(from: -end, through: end, by: 0.02).map { $0 }
        func seam(_ theta: Double) -> [P] { xs.map { P($0, half($0) * sin(theta)) } }
        let outline = seam(-.pi / 2) + seam(.pi / 2).reversed() + [P(-end, -waist)]
        let head = ellipse(P(end, 0), 0.11, waist)
        let chocks = [-1.0, 1.0].map { s -> [P] in
            let a = s * 0.42, w = 0.17
            let top = stride(from: a - w, through: a + w, by: 0.02).map { P($0, half($0) - 0.01) }
            return top + [P(a + w + 0.03, 0.93), P(a - w - 0.03, 0.93), top[0]]
        }

        Kit.ground(&plate, angle: -0.5, around: [outline, head] + chocks)

        // The floor under the cradle.
        Kit.mass(&plate, box(P(-1.1, 0.93), P(1.1, 0.98)))
        plate.lines(hatch([box(P(-1.1, 0.98), P(1.1, 1.1))], angle: 0, gap: 0.03), medium)

        // The staves: bone between heavy seams, the one in shadow underneath in ink.
        let seams = (0...12).map { -Double.pi / 2 + Double($0) * .pi / 12 }
        Kit.cut(&plate, outline, edge: heavy)
        for k in 0..<12 {
            let ring = seam(seams[k]) + seam(seams[k + 1]).reversed() + [seam(seams[k])[0]]
            if k == 11 {
                Kit.mass(&plate, ring)
                plate.line(seam((seams[k] + seams[k + 1]) / 2), fine, .bone)
            } else if k % 2 == 1 {
                plate.lines(hatch([ring], angle: 0.08, gap: 0.036), fine)
            }
        }
        for theta in seams.dropFirst().dropLast() { plate.line(seam(theta), heavy) }

        // The head, turned to the eye: its chime in ink, its boards, the tap low in it.
        plate.fill(head, .black)
        let boards = ellipse(P(end + 0.012, 0), 0.085, waist - 0.035)
        Kit.cut(&plate, boards)
        for y in stride(from: -0.27, through: 0.27, by: 0.09) {
            let dx = 0.085 * sqrt(max(0, 1 - y * y / ((waist - 0.035) * (waist - 0.035))))
            plate.line([P(end + 0.012 - dx, y), P(end + 0.012 + dx, y)], medium)
        }
        plate.line(head, heavy)

        // The hoops: iron bands round the belly and the chimes, each with its rivets.
        for x in [-0.745, -0.243, 0.243, 0.745] {
            let w = 0.056, h0 = half(x - w / 2), h1 = half(x + w / 2)
            let hoop = [P(x - w / 2, -h0 - 0.012), P(x + w / 2, -h1 - 0.012), P(x + w / 2, h1 + 0.012), P(x - w / 2, h0 + 0.012),
                        P(x - w / 2, -h0 - 0.012)]
            Kit.mass(&plate, hoop)
            plate.line([P(x - w / 2 + 0.012, -h0 + 0.01), P(x - w / 2 + 0.012, h0 - 0.01)], fine, .bone)
            for theta in [-1.0, -0.2, 0.6] {
                plate.fill(arc(P(x + 0.008, half(x) * sin(theta)), 0.011), .bone)
            }
        }

        // The cradle: two chocks hollowed to the belly, their grain in bone.
        for chock in chocks {
            Kit.mass(&plate, chock)
            let a = chock[0].x + 0.17
            for dx in [-0.08, 0.0, 0.08] {
                plate.line([P(a + dx, half(a + dx) + 0.05), P(a + dx * 1.15, 0.9)], fine, .bone)
            }
        }

        // The tap: a spigot through the head, its key turned across.
        let spigot = P(end + 0.04, 0.2)
        let tap = [spigot + P(-0.04, -0.03), spigot + P(0.1, -0.025), spigot + P(0.12, 0.0), spigot + P(0.12, 0.06),
                   spigot + P(0.09, 0.06), spigot + P(0.09, 0.02), spigot + P(-0.04, 0.03), spigot + P(-0.04, -0.03)]
        plate.fill(tap, .second)
        plate.line(tap, medium)
        let key = [spigot + P(0.02, -0.03), spigot + P(0.02, -0.1), spigot + P(0.06, -0.12), spigot + P(0.07, -0.1),
                   spigot + P(0.05, -0.03), spigot + P(0.02, -0.03)]
        plate.fill(key, .second)
        plate.line(key, medium)

        callout(&plate, "A", from: P(-0.243, -0.3), to: P(-0.3, -0.62))
        callout(&plate, "B", from: spigot + P(0.11, 0.05), to: P(0.66, 0.6))
        callout(&plate, "C", from: P(0.1, half(0.1) * sin(-1.05)), to: P(0.3, -0.62))
        callout(&plate, "D", from: P(-0.5, 0.75), to: P(-0.75, 0.55))
        return plate
    }

    /// Problem 65, Motion work, hex, clocks 1-,2-: the motion work set out along a dashed axis from eleven to five,
    /// the cannon pinion in the lane at eleven, the hour wheel on the centre with its rim outside the hub's reach, the
    /// minute wheel in the lane at five; the minute wheel's pinion in the second ink.
    static func plate65() -> Plate {
        var plate = Plate()
        let o = Kit.origin, cannon = polar(o, 0.72, Kit.clock(11)), minute = polar(o, 0.72, Kit.clock(5))
        let hourR = 0.42, minuteR = 0.205, cannonR = 0.13
        let hour = gear(o, hourR, teeth: 48, phase: 0.02), small = gear(minute, minuteR, teeth: 30, phase: 0.1)
        let leaves = gear(cannon, cannonR, teeth: 10, phase: 0.2)

        Kit.ground(&plate, angle: 0.3, around: [hour, small, leaves])

        bold(&plate, o, hourR, outline: hour, rim: 0.09, hub: 0.07, crossings: 4, crossing: 0.034, phase: Kit.clock(0.5))
        // The hour wheel's pipe, which rides over the cannon pinion's.
        plate.line(arc(o, 0.115), heavy)
        plate.line(arc(o, 0.135), fine)

        bold(&plate, minute, minuteR, outline: small, rim: 0.042, hub: 0.075, crossings: 4, crossing: 0.024, phase: 0.4)
        // The minute wheel's pinion, cut on its arbor.
        let pinion = gear(minute, 0.062, teeth: 6, phase: 0.3)
        plate.fill(pinion, .second)
        plate.line(pinion, medium)
        plate.fill(arc(minute, 0.018))
        plate.line(arc(minute, 0.018), medium)

        // The cannon pinion end on: its leaves in ink, its pipe bored for the centre arbor.
        Kit.mass(&plate, leaves)
        Kit.cut(&plate, arc(cannon, 0.068), edge: heavy)
        plate.lines(hatch([arc(cannon, 0.068), arc(cannon, 0.03)], angle: 0.8, gap: 0.012), fine)
        Kit.mass(&plate, arc(cannon, 0.03))
        plate.fill(box(cannon - P(0.012, 0.012), cannon + P(0.012, 0.012)))

        // The axis the parts are set out along: a chain line over them all, an arrow at each end showing how they go
        // together.
        let line = [polar(o, 0.93, Kit.clock(11)), polar(o, 0.93, Kit.clock(5))]
        for run in dashed(line, on: 0.06, off: 0.035) where simd_distance(run[0], minute) > 0.07 {
            plate.line(run, 0.028, .bone)
            plate.line(run, heavy)
        }
        for clock in [11.0, 5.0] {
            let tip = polar(o, 0.97, Kit.clock(clock))
            plate.fill(arc(tip - 0.03 * P(cos(Kit.clock(clock)), sin(Kit.clock(clock))), 0.05))
            Kit.mass(&plate, Kit.barb(tip, toward: Kit.clock(clock), size: 0.07))
        }

        callout(&plate, "A", from: polar(cannon, 0.1, Kit.clock(2)), to: polar(o, 0.72, Kit.clock(1)) + P(-0.05, 0))
        callout(&plate, "B", from: polar(o, 0.4, Kit.clock(8.6)), to: polar(o, 0.72, Kit.clock(9)))
        callout(&plate, "C", from: polar(minute, 0.19, Kit.clock(2.5)), to: polar(o, 0.74, Kit.clock(3)))
        callout(&plate, "D", from: polar(minute, 0.04, Kit.clock(8)), to: polar(o, 0.72, Kit.clock(7)))
        return plate
    }

    /// A wheel face on cut bold: a rim of solid ink inside its teeth, crossings of ink to a hub, the windows ruled as the
    /// ground.
    private static func bold(_ plate: inout Plate, _ c: P, _ r: Double, outline: [P], rim: Double, hub: Double,
                             crossings: Int, crossing: Double, phase: Double, angle: Double = 0.3) {
        let root = r - 2.4 * r / Double(outline.count / 5)
        Kit.mass(&plate, outline)
        plate.line(arc(c, root - 0.012), fine, .bone)
        let holes = windows(c, hub: hub + 0.01, rim: root - rim, spokes: crossings, width: crossing, phase: phase)
        for hole in holes {
            Kit.cut(&plate, hole)
            plate.lines(hatch([hole], angle: angle, gap: Kit.groundGap), Kit.groundWidth)
        }
        Kit.cut(&plate, arc(c, hub))
        plate.line(arc(c, hub - 0.012), fine)
        plate.lines(hatch([arc(c, hub - 0.012)], angle: phase + 0.8, gap: 0.014), fine)
    }

    /// Problem 66, Centre wheel, hex, clocks 1+,2+: a large four-crossed centre wheel seen from a little above, off the
    /// hub to the lower left with the hubs at four and eight in its windows, its heavy rim and teeth in ink, its pinion
    /// and arbor rising in the clear column left of the hub through a bridge across the top; the arbor's square end in the second ink.
    static func plate66() -> Plate {
        var plate = Plate()
        let x = -0.243, c = P(x, 0.42), rx = 0.6, ry = 0.3
        func seen(_ q: [P]) -> [P] { q.map { P(c.x + rx * $0.x, c.y + ry * $0.y) } }
        let outline = seen(gear(Kit.origin, 1, teeth: 72, phase: 0.01))
        let root = 1 - 2.4 / 72
        let holes = windows(Kit.origin, hub: 0.24, rim: root - 0.13, spokes: 4, width: 0.1, phase: 0.25).map(seen)
        let bridgeY = -0.62
        let bridge = Kit.band(P(-1.1, bridgeY), P(x, bridgeY), 0.12)
        let arm = Kit.ribbon(curve(P(x, bridgeY), P(-0.1, -0.7), P(0.06, -0.84), 12) + [P(0.7, -0.88)], 0.08)
        let base = box(P(-1.1, 0.82), P(1.1, 1.1))

        Kit.ground(&plate, angle: 0.4, around: [outline, bridge, arm, arc(P(x, bridgeY), 0.1), base])

        // The pillar plate under the wheel, and the arbor's lower pivot standing in it.
        Kit.mass(&plate, base)
        plate.line([P(-1, 0.845), P(1, 0.845)], fine, .bone)
        Kit.mass(&plate, box(P(x - 0.022, c.y + ry - 0.02), P(x + 0.022, 0.82)))
        Kit.cut(&plate, box(P(x - 0.06, 0.8), P(x + 0.06, 0.84)), edge: heavy)

        // The wheel: teeth and a heavy rim in ink, a bone line round the rim, the crossings left in ink between ruled windows.
        Kit.mass(&plate, outline)
        plate.line(seen(arc(Kit.origin, root - 0.04)), medium, .bone)
        for hole in holes {
            Kit.cut(&plate, hole)
            plate.lines(hatch([hole], angle: 0.4, gap: Kit.groundGap), Kit.groundWidth)
        }
        let collet = seen(arc(Kit.origin, 0.2))
        Kit.cut(&plate, collet, edge: heavy)
        plate.lines(hatch([collet], angle: 0.9, gap: 0.014), fine)

        // The pinion on the arbor above the wheel, its leaves upright in ink, and the arbor on up to the bridge.
        let pinion = box(P(x - 0.05, 0.2), P(x + 0.05, c.y - 0.02))
        Kit.mass(&plate, pinion)
        for dx in [-0.026, 0.0, 0.026] {
            plate.line([P(x + dx, 0.215), P(x + dx, c.y - 0.035)], medium, .bone)
        }
        Kit.mass(&plate, ellipse(P(x, 0.2), 0.05, 0.016))
        Kit.mass(&plate, box(P(x - 0.022, bridgeY), P(x + 0.022, 0.2)))
        plate.line([P(x - 0.008, bridgeY + 0.1), P(x - 0.008, 0.19)], fine, .bone)
        Kit.mass(&plate, ellipse(P(x, c.y - 0.02), 0.07, 0.022))

        // The bridge over it, screwed to the plate, a jewel where the arbor passes.
        Kit.mass(&plate, bridge)
        Kit.mass(&plate, arm)
        Kit.mass(&plate, arc(P(x, bridgeY), 0.1))
        plate.line([P(-1, bridgeY - 0.042), P(x - 0.05, bridgeY - 0.042)], fine, .bone)
        plate.line(curve(P(-0.14, -0.71), P(-0.1, -0.73), P(0.06, -0.855), 10) + [P(0.62, -0.893)], fine, .bone)
        for screw in [P(-0.62, bridgeY), P(0.36, -0.86)] {
            Kit.cut(&plate, arc(screw, 0.032), edge: heavy)
            plate.line([screw + P(-0.024, -0.016), screw + P(0.024, 0.016)], heavy)
        }
        Kit.cut(&plate, arc(P(x, bridgeY), 0.045), edge: heavy)
        plate.line(arc(P(x, bridgeY), 0.026), medium)

        // The arbor's top above the bridge, filed square for the key.
        Kit.mass(&plate, box(P(x - 0.018, bridgeY - 0.13), P(x + 0.018, bridgeY - 0.045)))
        let square = box(P(x - 0.034, bridgeY - 0.2), P(x + 0.034, bridgeY - 0.13))
        plate.fill(square, .second)
        plate.line(square, medium)
        plate.line([P(x - 0.034, bridgeY - 0.2), P(x - 0.018, bridgeY - 0.185), P(x + 0.018, bridgeY - 0.185), P(x + 0.034, bridgeY - 0.2)], fine)

        callout(&plate, "A", from: P(c.x + 0.97 * rx * cos(0.3), c.y + 0.97 * ry * sin(0.3)), to: P(0.4, 0.66))
        callout(&plate, "B", from: P(x + 0.05, 0.3), to: P(0.22, 0.1))
        callout(&plate, "C", from: P(-0.75, bridgeY + 0.05), to: P(-0.76, -0.38))
        callout(&plate, "D", from: P(x - 0.034, bridgeY - 0.17), to: P(-0.42, -0.82))
        return plate
    }
}
