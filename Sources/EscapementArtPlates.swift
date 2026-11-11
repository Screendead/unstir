// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Direction A: a plate a problem, drawn as its name in a horology manual's hand: the part in elevation on a ruled
/// tint, section hatching, centre lines and lettered callouts, the second ink kept to one part so the clocks' vermilion
/// still reads. No round figure sits on one of its layout's rods.
extension EscapementArt {
    /// The ruled tint, left out of the rings by the even-odd rule.
    private static func tint(_ plate: inout Plate, angle: Double, around rings: [[P]], gap: Double = 0.034) {
        plate.lines(hatch([Array(glass)] + rings, angle: angle, gap: gap), fine)
    }

    private static func strip(_ a: P, _ b: P, _ width: Double) -> [P] {
        let n = simd_normalize(P(-(b - a).y, (b - a).x)) * (width / 2)
        return [a + n, b + n, b - n, a - n, a + n]
    }

    /// Problem 2, tri: an anchor escapement and its pendulum mid-swing, the going weight beside it.
    static func pendulum() -> Plate {
        var plate = Plate(), figures = Plate()
        let pivot = P(-0.22, -0.80), centre = P(-0.22, -0.47), swing = 13 * Double.pi / 180
        let down = P(sin(swing), cos(swing)), bob = pivot + 1.18 * down, bobRadius = 0.19
        var rings = wheel(&figures, centre, 0.24, teeth: 29, spokes: 5, phase: 0.2, escape: true)
        rings += wheel(&figures, P(0.19, -0.66), 0.125, teeth: 13, spokes: 3, phase: 0.4)
        rings += wheel(&figures, P(0.50, -0.50), 0.16, teeth: 23, spokes: 5, phase: 0.1, rimInk: .second)
        let weight = box(P(0.585, 0.02), P(0.735, 0.44))
        rings += [arc(bob, bobRadius), weight]
        tint(&plate, angle: 0.5, around: rings)
        plate.marks += figures.marks

        // The swing: its centre line, the far end of the swing and the degree arc under the bob.
        plate.lines(dashed([pivot, pivot + P(0, 1.5)], on: 0.05, off: 0.025), fine)
        let far = P(-sin(swing), cos(swing))
        plate.lines(dashed([pivot, pivot + 1.0 * far], on: 0.03, off: 0.03), fine)
        plate.lines(dashed(arc(pivot + 1.18 * far, bobRadius), on: 0.03, off: 0.03), fine)
        for radius in [1.51, 1.55] { plate.line(arc(pivot, radius, from: .pi / 2 - 0.4, to: .pi / 2 + 0.4), fine) }
        for k in -11...11 {
            let a = .pi / 2 + Double(k) * 2 * .pi / 180
            plate.line([polar(pivot, 1.51, a), polar(pivot, k % 5 == 0 ? 1.59 : 1.55, a)], fine)
        }

        // The anchor over the wheel, its pallets on the teeth.
        let left = centre + P(-0.2, -0.155), right = centre + P(0.2, -0.155)
        let anchor = curve(left, P(-0.44, -0.84), pivot + P(0, -0.06)) + curve(pivot + P(0, -0.06), P(0.0, -0.84), right)
            + curve(right + P(-0.045, 0.0), P(-0.06, -0.74), pivot + P(0, 0.035)) + curve(pivot + P(0, 0.035), P(-0.38, -0.74), left + P(0.045, 0.0))
            + [left]
        plate.fill(anchor)
        plate.lines(hatch([anchor], angle: -0.7, gap: 0.013), fine)
        plate.line(anchor, medium)

        // The rod over both, then the bob and its rating nut.
        let rod = strip(pivot, pivot + 1.5 * down, 0.024)
        plate.fill(rod)
        plate.line(rod, fine)
        plate.fill(arc(pivot, 0.035))
        plate.line(arc(pivot, 0.035), medium)
        plate.line(arc(pivot, 0.012), medium)
        plate.fill(arc(bob, bobRadius))
        plate.lines(hatch([arc(bob, bobRadius)], angle: 0.8, gap: 0.016), fine, .second)
        plate.lines(hatch([arc(bob, bobRadius, from: -0.5, to: -0.5 + .pi)], angle: -0.75, gap: 0.022), fine, .second)
        plate.line(arc(bob, bobRadius), heavy)
        plate.line(arc(bob, bobRadius - 0.03), fine)
        let nut = strip(pivot + 1.41 * down, pivot + 1.46 * down, 0.09)
        plate.fill(nut)
        plate.lines(hatch([nut], angle: swing, gap: 0.011), fine)
        plate.line(nut, medium)

        // The weight on its line from the barrel.
        plate.line([P(0.66, -0.50), P(0.66, 0.02)], fine)
        plate.lines(hatch([weight], angle: .pi / 2, gap: 0.017), fine)
        plate.lines(hatch([box(P(0.68, 0.02), P(0.735, 0.44))], angle: 0, gap: 0.014), fine)
        plate.line(weight, medium)
        plate.line(ellipse(P(0.66, 0.02), 0.075, 0.02), medium)
        plate.line(ellipse(P(0.66, 0.44), 0.075, 0.02, from: 0, to: .pi), medium)

        callout(&plate, "A", from: P(-0.38, -0.745), to: P(-0.56, -0.66))
        callout(&plate, "B", from: centre + P(-0.15, 0.12), to: P(-0.64, -0.22))
        callout(&plate, "C", from: bob + P(0.11, 0.1), to: P(0.38, 0.6))
        callout(&plate, "D", from: P(0.735, 0.2), to: P(0.83, 0.1))
        callout(&plate, "E", from: pivot + 0.62 * down, to: P(-0.46, 0.0))
        return plate
    }

    /// Problem 4, quad: a wheel of 37 driving a pinion of 11, a third wheel off the plate and a tooth enlarged.
    static func cogwheel() -> Plate {
        var plate = Plate(), figures = Plate()
        let centre = P(-0.2, 0.14), r = 0.6
        let pinion = polar(centre, r * (1 + 11.0 / 37), -20 * .pi / 180), pr = r * 11 / 37
        let third = polar(centre, r * (1 + 17.0 / 37), 70 * .pi / 180), idler = polar(pinion, pr * (1 + 13.0 / 11), -75 * .pi / 180)
        let inset = P(-0.6, -0.62), insetRadius = 0.23
        var rings = wheel(&figures, centre, r, teeth: 37, spokes: 5, phase: 0.05)
        rings += wheel(&figures, pinion, pr, teeth: 11, spokes: 1, phase: 0.33, rimInk: .second)
        rings += wheel(&figures, third, r * 17 / 37, teeth: 17, spokes: 5, phase: 0.2)
        rings += wheel(&figures, idler, pr * 13 / 11, teeth: 13, spokes: 3, phase: 0.1)
        rings.append(arc(inset, insetRadius))
        tint(&plate, angle: -0.6, around: rings)
        plate.marks += figures.marks

        // Pitch circles and the line of centres.
        for (c, radius) in [(centre, r), (pinion, pr), (third, r * 17 / 37), (idler, pr * 13 / 11)] {
            plate.lines(dashed(arc(c, radius), on: 0.07, off: 0.015), fine)
        }
        plate.lines(dashed([centre + (centre - pinion) * 0.25, pinion + (pinion - centre) * 0.5], on: 0.07, off: 0.02), fine)
        plate.lines(dashed([centre + P(0, -0.2), centre + P(0, 0.2)], on: 0.07, off: 0.02), fine)

        // The inset: two teeth of the wheel at five times, in section.
        let from = polar(centre, r, -150 * .pi / 180)
        plate.line(arc(from, 0.07), fine)
        plate.line([from + simd_normalize(inset - from) * 0.07, inset - simd_normalize(inset - from) * insetRadius], fine)
        let base = inset + P(0, 0.07)
        var rack: [P] = [base + P(-0.21, 0.0)]
        for k in 0..<2 {
            let x = -0.17 + 0.19 * Double(k)
            rack += [P(x, 0), P(x + 0.03, -0.13), P(x + 0.09, -0.13), P(x + 0.12, 0)].map { base + $0 }
        }
        rack += [base + P(0.2, 0), base + P(0.17, 0.11), base + P(-0.17, 0.11), base + P(-0.21, 0.0)]
        plate.lines(hatch([rack], angle: 0.8, gap: 0.014), fine, .second)
        plate.line(rack, medium)
        plate.lines(dashed([base + P(-0.2, -0.06), base + P(0.2, -0.06)], on: 0.05, off: 0.02), fine)
        plate.line(arc(inset, insetRadius), heavy)

        callout(&plate, "A", from: polar(centre, r - 0.05, 2.6), to: P(-0.84, 0.44))
        callout(&plate, "B", from: pinion + P(0.06, 0.06), to: P(0.74, 0.16))
        callout(&plate, "C", from: centre + P(0.05, 0.03), to: centre + P(0.2, 0.26))
        callout(&plate, "D", from: idler + P(0.05, -0.1), to: P(0.4, -0.8))
        return plate
    }

    /// Half the glass's width at `y` from the waist, out to the caps at 0.66.
    static func bulb(_ y: Double) -> Double {
        let t = min(abs(y) / 0.66, 1)
        return 0.03 + 0.3 * pow(sin(.pi * t), 0.7) + 0.1 * t * t
    }

    /// The hourglass's glass as one ring, about the waist at the origin.
    static let bulbs: [P] = {
        let ys = stride(from: -0.66, through: 0.66, by: 0.01).map { $0 }
        return ys.map { P(bulb($0), $0) } + ys.reversed().map { P(-bulb($0), $0) } + [P(bulb(-0.66), -0.66)]
    }()

    /// Problem 9, eye: a sand-glass in its turned frame, leaning, half run.
    static func hourglass() -> Plate {
        var plate = Plate(), glassware = Plate()
        let at = P(-0.08, 0.02), lean = 5 * Double.pi / 180
        func place(_ points: [P]) -> [P] { turned(points.map { $0 + at }, by: lean, about: at) }
        let caps = [box(P(-0.47, -0.75), P(0.47, -0.66)), box(P(-0.47, 0.66), P(0.47, 0.75))]
        let pillars = [-0.41, 0.41].map { x -> [P] in
            let ys = stride(from: -0.66, through: 0.66, by: 0.01).map { $0 }
            func half(_ y: Double) -> Double { 0.02 + 0.022 * abs(sin(3 * .pi * (y + 0.66) / 1.32)) }
            return ys.map { P(x + half($0), $0) } + ys.reversed().map { P(x - half($0), $0) } + [P(x + half(-0.66), -0.66)]
        }
        tint(&plate, angle: -0.35, around: ([bulbs] + caps + pillars).map(place))

        for cap in caps {
            glassware.lines(hatch([cap], angle: 0.04, gap: 0.013), fine)
            glassware.line(cap, medium)
        }
        for pillar in pillars {
            glassware.lines(hatch([pillar], angle: 1.1, gap: 0.014), fine)
            glassware.line(pillar, medium)
        }
        // Sand above, drawing down to the waist, and the heap below.
        let above = stride(from: -0.34, through: 0.0, by: 0.01).map { $0 }
        let surface = stride(from: -1.0, through: 1.0, by: 0.05).map { u in P(u * bulb(-0.34), -0.34 + 0.07 * (1 + cos(.pi * min(abs(u) / 0.6, 1)))) }
        let upper = surface + above.map { P(bulb($0), $0) } + above.reversed().map { P(-bulb($0), $0) }
        let below = stride(from: 0.3, through: 0.66, by: 0.01).map { $0 }
        func heap(_ y: Double) -> Double { min(bulb(y), (y - 0.3) / 0.5) }
        let lower = below.map { P(heap($0), $0) } + below.reversed().map { P(-heap($0), $0) }
        for sand in [upper, lower] {
            glassware.lines(hatch([sand], angle: 0.5, gap: 0.014), fine, .second)
            glassware.lines(hatch([sand], angle: -0.9, gap: 0.03).flatMap { dashed($0, on: 0.02, off: 0.02) }, fine, .second)
            glassware.line(sand + [sand[0]], fine, .second)
        }
        glassware.line([P(0, 0), P(0, 0.3)], medium, .second)
        // The glass: its empty parts lightly ruled, form lines down each bulb, the outline last.
        glassware.lines(hatch([bulbs, upper + [upper[0]], lower + [lower[0]]], angle: -1.0, gap: 0.045).flatMap { dashed($0, on: 0.05, off: 0.025) }, fine)
        for f in [-0.9, 0.62, 0.84] {
            let ys = stride(from: -0.62, through: 0.62, by: 0.01).map { $0 }
            glassware.lines(dashed(ys.map { P(f * bulb($0), $0) }, on: 0.09, off: 0.03), fine)
        }
        glassware.line(bulbs, heavy)
        glassware.line([P(-0.1, -0.66), P(0.1, -0.66)], heavy)
        for mark in glassware.marks { plate.marks.append(Mark(points: place(mark.points), width: mark.width, ink: mark.ink)) }

        callout(&plate, "A", from: place([P(0.1, -0.2)])[0], to: P(0.62, -0.5))
        callout(&plate, "B", from: place([P(0.03, 0.0)])[0], to: P(0.6, -0.06))
        callout(&plate, "C", from: place([P(-0.41, 0.3)])[0], to: P(-0.72, 0.42))
        callout(&plate, "D", from: place([P(0.2, 0.52)])[0], to: P(0.62, 0.5))
        return plate
    }

    /// A moon's dark side, the share `lit` of its disc lit from the right.
    static func darkSide(_ c: P, _ r: Double, lit: Double) -> [P] {
        let limb = arc(c, r, from: -.pi / 2, to: -3 * .pi / 2)
        let terminator = stride(from: 90.0, through: -90.0, by: -5).map { u in
            c + P(r * (1 - 2 * lit) * cos(u * .pi / 180), r * sin(u * .pi / 180))
        }
        return limb + terminator
    }

    static func star(_ c: P, _ r: Double, turn: Double) -> [P] {
        (0...10).map { polar(c, $0 % 2 == 0 ? r : 0.42 * r, turn + .pi * Double($0) / 5) }
    }

    /// Problem 25, hex: the moon through five phases over a night sky, the lunation's scale above and the waxing moon
    /// large below.
    static func moonPhase() -> Plate {
        var plate = Plate()
        let sweep = P(0, 0.95), moon = P(-0.06, 0.4), radius = 0.43
        let phases = (-2...2).map { k in (c: polar(sweep, 1.45, -.pi / 2 + Double(k) * 14 * .pi / 180), lit: Double(k + 2) / 4) }
        let stars = (0..<70).compactMap { k -> [P]? in
            let c = P(1.9 * rnd(25, 2 * k) - 0.95, 1.9 * rnd(25, 2 * k + 1) - 0.95)
            guard simd_distance(c, moon) > radius + 0.07, abs(simd_distance(c, sweep) - 1.5) > 0.22, simd_length(c) < 0.93 else { return nil }
            return star(c, 0.028 + 0.02 * rnd(25, 100 + k), turn: rnd(25, 200 + k))
        }
        plate.lines(hatch([Array(glass), arc(moon, radius)] + phases.map { arc($0.c, 0.115) } + stars, angle: 0.1, gap: 0.03), fine)
        for s in stars { plate.line(s, fine, .second) }

        // The lunation's scale: 29 days and a half, numbered by fives.
        for r in [1.62, 1.66] { plate.line(arc(sweep, r, from: -.pi / 2 - 0.62, to: -.pi / 2 + 0.62), fine) }
        for k in 0...59 {
            let a = -.pi / 2 - 0.59 + 1.18 * Double(k) / 59
            plate.line([polar(sweep, 1.62, a), polar(sweep, k % 10 == 0 ? 1.71 : k % 2 == 0 ? 1.66 : 1.64, a)], fine)
        }
        for phase in phases {
            if phase.lit < 1 {
                let dark = darkSide(phase.c, 0.115, lit: phase.lit)
                plate.lines(hatch([dark], angle: 0.9, gap: 0.013), fine)
                plate.lines(hatch([dark], angle: -0.6, gap: 0.018), fine)
            }
            plate.line(arc(phase.c + P(0.05, -0.02), 0.02), fine)
            plate.line(arc(phase.c + P(0.07, 0.05), 0.012), fine)
            plate.line(arc(phase.c, 0.115), medium)
        }

        // The moon: its dark limb cross-hatched, seas in the second ink, craters each with its shadow.
        let dark = darkSide(moon, radius, lit: 0.78)
        plate.lines(hatch([dark], angle: 1.0, gap: 0.014), fine)
        plate.lines(hatch([dark], angle: -0.5, gap: 0.02), fine)
        plate.line(Array(dark.suffix(37)), fine)
        let seas = [ellipse(moon + P(0.02, -0.18), 0.15, 0.09, turned: 0.4), ellipse(moon + P(0.2, 0.02), 0.1, 0.14, turned: -0.3),
                    ellipse(moon + P(-0.04, 0.16), 0.13, 0.07, turned: 0.2), ellipse(moon + P(0.16, 0.26), 0.07, 0.05, turned: 0.9)]
        for sea in seas {
            plate.lines(hatch([sea], angle: 0.35, gap: 0.015), fine, .second)
            plate.line(sea, fine, .second)
        }
        var craters: [[P]] = []
        for k in 0..<40 where craters.count < 11 {
            let c = moon + P((1.6 * rnd(7, 2 * k) - 0.62) * radius, (1.8 * rnd(7, 2 * k + 1) - 0.9) * radius), r = 0.018 + 0.03 * rnd(7, 80 + k)
            guard simd_distance(c, moon) < radius - r - 0.03, c.x - moon.x > -0.5 * radius * sqrt(max(0, 1 - pow((c.y - moon.y) / radius, 2))) + r else { continue }
            craters.append(arc(c, r))
            plate.fill(arc(c, r))
            plate.line(arc(c, r), fine)
            plate.line(arc(c, r, from: 2.0, to: 4.4), heavy)
            plate.line(arc(c, 0.35 * r), fine)
        }
        plate.lines(hatch([arc(moon, radius), dark] + seas + craters, angle: -0.2, gap: 0.04).flatMap { dashed($0, on: 0.04, off: 0.02) }, fine)
        plate.line(arc(moon, radius), heavy)

        callout(&plate, "A", from: moon + P(-0.33, -0.12), to: P(-0.66, 0.02))
        callout(&plate, "B", from: moon + P(0.22, 0.02), to: P(0.62, 0.3))
        callout(&plate, "C", from: polar(sweep, 1.62, -.pi / 2 + 0.45), to: P(0.82, -0.3))
        return plate
    }
}
