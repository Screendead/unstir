// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Problems 1 to 10 (and 25's sketch), each composed round its layout: no knob, and no hub a clock on any rod would
/// wear, sits on the part the plate is named for. A ruled tint, section hatching, centre lines and lettered callouts,
/// the second ink on one small part so the clocks' vermilion still reads.
extension EscapementArt {
    /// The ruled tint, left out of the rings by the even-odd rule.
    private static func tint(_ plate: inout Plate, angle: Double, around rings: [[P]], gap: Double = 0.034) {
        plate.lines(hatch([Array(glass)] + rings, angle: angle, gap: gap), fine)
    }

    private static func strip(_ a: P, _ b: P, _ width: Double) -> [P] {
        let n = simd_normalize(P(-(b - a).y, (b - a).x)) * (width / 2)
        return [a + n, b + n, b - n, a - n, a + n]
    }

    private static func area(_ ring: [P]) -> Double {
        ring.indices.reduce(0) { sum, i in
            let a = ring[i], b = ring[(i + 1) % ring.count]
            return sum + (a.x * b.y - b.x * a.y) / 2
        }
    }

    /// An outline with holes as one outline for a non-zero fill: each hole runs the other way round, joined to the
    /// outline's start by a seam walked out and back.
    private static func solid(_ outline: [P], holes: [[P]]) -> [P] {
        var out = area(outline) < 0 ? Array(outline.reversed()) : outline
        let start = out[0]
        out.append(start)
        for hole in holes {
            let ring = area(hole) > 0 ? Array(hole.reversed()) : hole
            out += ring + [ring[0], start]
        }
        return out
    }

    /// A figure drawn over whatever lies under it: its outline filled with bone, its holes left open.
    private static func cut(_ plate: inout Plate, _ outline: [P], holes: [[P]] = []) {
        plate.fill(holes.isEmpty ? outline : solid(outline, holes: holes))
    }

    private static func deg(_ a: Double) -> Double { a * .pi / 180 }

    /// A wheel in elevation over whatever lies under it: crossings from `turn`, the rim `rim` wide inside the teeth, a
    /// hub of radius `hub`, and its windows open unless `blind`, for a small wheel over a busy ground.
    private static func crossed(_ plate: inout Plate, _ c: P, _ r: Double, teeth: Int, spokes: Int, turn: Double,
                                phase: Double = 0, rim width: Double? = nil, hub: Double? = nil, spoke: Double? = nil,
                                escape: Bool = false, blind: Bool = false) {
        let m = 2 * r / Double(teeth), root = escape ? 0.8 * r : r - 1.2 * m, band = escape ? root : root - 0.015
        let rim = band - (width ?? 0.09 * r), boss = hub ?? max(0.2 * r, 0.04)
        let outline = escape ? escapeWheel(c, r, teeth: teeth, phase: phase) : gear(c, r, teeth: teeth, phase: phase)
        let holes = windows(c, hub: boss, rim: rim, spokes: spokes, width: spoke ?? 0.07 * r + 0.006, phase: turn)
        cut(&plate, outline, holes: blind ? [] : holes)
        plate.line(outline, medium)
        if !escape { plate.line(arc(c, band), fine) }
        plate.lines(hatch([arc(c, band), arc(c, rim)], angle: phase + 0.9, gap: 0.016), fine)
        plate.lines(holes, fine)
        plate.lines(hatch([arc(c, boss), arc(c, 0.45 * boss)], angle: phase - 0.6, gap: 0.012), fine)
        plate.line(arc(c, 0.45 * boss), medium)
        plate.line([polar(c, 0.45 * boss, turn), polar(c, 0.45 * boss, turn + .pi)], fine)
    }

    /// A pinion's leaves over whatever lies under it, hatched in `ink`.
    private static func pinion(_ plate: inout Plate, _ c: P, _ r: Double, leaves: Int, phase: Double, ink: Ink = .black) {
        let outline = gear(c, r, teeth: leaves, phase: phase), arbor = max(0.3 * r, 0.022)
        cut(&plate, outline)
        plate.lines(hatch([outline, arc(c, arbor)], angle: 0.8, gap: 0.012), fine, ink)
        plate.line(outline, medium)
        plate.line(arc(c, arbor), medium)
    }

    /// The phase that sets a tooth of a wheel of `teeth`, or with `gap` the space between two, on the bearing `a`.
    private static func mesh(_ a: Double, teeth: Int, gap: Bool = false) -> Double {
        a - (gap ? 0 : .pi / Double(teeth))
    }

    /// A callout whose letter sits at `at`.
    private static func letter(_ plate: inout Plate, _ s: String, from a: P, at: P) {
        callout(&plate, s, from: a, to: at - simd_normalize(at - a) * 0.065)
    }

    /// Problem 1, tri: a going barrel with its cover off, the spring half run down round the arbor.
    static func mainspring() -> Plate {
        var plate = Plate()
        let c = P(0, 0.02), wall = 0.75, inside = 0.67, arbor = 0.085
        tint(&plate, angle: 0.45, around: [arc(c, wall)])
        plate.lines(hatch([arc(c, wall), arc(c, inside)], angle: -0.8, gap: 0.013), fine)
        plate.line(arc(c, wall), heavy)
        plate.line(arc(c, inside), medium)

        // The spring: close coils on the arbor and against the wall, open between.
        let turns = 6.0, steps = Int(turns * 72), from = arbor + 0.014, to = inside - 0.02
        let coil = (0...steps).map { i -> P in
            let u = Double(i) / Double(steps), f = u - 0.5 * sin(2 * .pi * u) / (2 * .pi)
            return polar(c, from + (to - from) * f, 2 * .pi * turns * u + 0.6)
        }
        plate.line(coil, 0.02)
        let end = coil[steps], hook = polar(c, inside, 2 * .pi * turns + 0.6 + 0.12)
        plate.line([end, hook], 0.02)
        plate.fill(arc(hook, 0.022), .black)

        // The arbor, its square for the key and the hook that takes the spring's eye.
        let square = (0...4).map { polar(c, 0.048, deg(45 + 90 * Double($0)) + 0.3) }
        cut(&plate, arc(c, arbor))
        plate.lines(hatch([arc(c, arbor), square], angle: 0.7, gap: 0.011), fine, .second)
        plate.line(arc(c, arbor), heavy)
        plate.line(square, medium)
        plate.line([polar(c, arbor, 0.6), coil[0], coil[6]], 0.02)

        letter(&plate, "A", from: polar(c, 0.40, deg(-32)), at: polar(c, 0.555, deg(-27)))
        letter(&plate, "B", from: polar(c, 0.06, deg(95)), at: c + P(-0.02, 0.44))
        letter(&plate, "C", from: polar(c, 0.71, deg(207)), at: polar(c, 0.90, deg(209)))
        return plate
    }

    /// Problem 2, tri: an anchor escapement and its pendulum mid-swing, the going weight beside it.
    static func pendulum() -> Plate {
        var plate = Plate(), figures = Plate()
        let pivot = P(-0.43, -0.74), centre = P(-0.43, -0.44), swing = deg(18.5), length = 1.3
        let down = P(sin(swing), cos(swing)), bob = pivot + length * down, bobRadius = 0.19
        var rings = wheel(&figures, centre, 0.2, teeth: 27, spokes: 5, phase: 0.2, escape: true)
        rings += wheel(&figures, P(0.27, -0.70), 0.115, teeth: 13, spokes: 3, phase: 0.4)
        rings += wheel(&figures, P(0.54, -0.50), 0.16, teeth: 23, spokes: 5, phase: 0.1)
        let weight = box(P(0.60, 0.0), P(0.75, 0.42))
        rings += [arc(bob, bobRadius), weight]
        tint(&plate, angle: 0.5, around: rings)
        plate.marks += figures.marks

        // The swing: its centre line and the degree arc under the bob.
        plate.lines(dashed([pivot, pivot + P(0, 1.62)], on: 0.05, off: 0.025), fine)
        let arcs = (from: deg(90 - 34), to: deg(90 + 3))
        for radius in [1.54, 1.58] { plate.line(arc(pivot, radius, from: arcs.from, to: arcs.to), fine) }
        for k in -1...17 {
            let a = deg(90 - 2 * Double(k))
            plate.line([polar(pivot, 1.54, a), polar(pivot, k % 5 == 0 ? 1.62 : 1.58, a)], fine)
        }

        // The anchor over the wheel, its pallets on the teeth.
        let left = centre + P(-0.17, -0.13), right = centre + P(0.17, -0.13), top = pivot + P(0, -0.06), crown = pivot + P(0, 0.035)
        let anchor = curve(left, pivot + P(-0.2, -0.09), top) + curve(top, pivot + P(0.2, -0.09), right)
            + curve(right + P(-0.04, 0), pivot + P(0.14, 0.0), crown) + curve(crown, pivot + P(-0.14, 0.0), left + P(0.04, 0))
            + [left]
        plate.fill(anchor)
        plate.lines(hatch([anchor], angle: -0.7, gap: 0.013), fine)
        plate.line(anchor, medium)

        // The rod over both, then the bob and its rating nut.
        let rod = strip(pivot, pivot + (length + 0.3) * down, 0.024)
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
        let nut = strip(pivot + (length + 0.22) * down, pivot + (length + 0.27) * down, 0.09)
        plate.fill(nut)
        plate.lines(hatch([nut], angle: swing, gap: 0.011), fine)
        plate.line(nut, medium)

        // The weight on its line from the barrel.
        plate.line([P(0.675, -0.50), P(0.675, 0.0)], fine)
        plate.lines(hatch([weight], angle: .pi / 2, gap: 0.017), fine)
        plate.lines(hatch([box(P(0.695, 0.0), P(0.75, 0.42))], angle: 0, gap: 0.014), fine)
        plate.line(weight, medium)
        plate.line(ellipse(P(0.675, 0.0), 0.075, 0.02), medium)
        plate.line(ellipse(P(0.675, 0.42), 0.075, 0.02, from: 0, to: .pi), medium)

        letter(&plate, "A", from: pivot + P(-0.13, -0.045), at: P(-0.74, -0.52))
        letter(&plate, "B", from: centre + P(-0.13, 0.1), at: P(-0.72, -0.14))
        letter(&plate, "C", from: bob + P(0.12, 0.1), at: P(0.40, 0.70))
        letter(&plate, "D", from: P(0.75, 0.2), at: P(0.88, 0.02))
        letter(&plate, "E", from: pivot + 0.5 * length * down, at: P(0.02, -0.03))
        return plate
    }

    /// Capitals set upright on `at`, their middle, narrowed to `narrow` of their width, then turned by `turn`.
    private static func numeral(_ s: String, at: P, height: Double, narrow: Double, turn: Double) -> [[P]] {
        let strokes = text(s, at: P(0, 0), height: height), xs = strokes.flatMap { $0.map(\.x) }
        let middle = P(((xs.min() ?? 0) + (xs.max() ?? 0)) / 2, height / 2)
        return strokes.map { turned($0.map { at + P(($0.x - middle.x) * narrow, $0.y - middle.y) }, by: turn, about: at) }
    }

    /// A hand as an outline from half-widths along its length, pointing along the bearing `a` from `c`.
    private static func hand(_ c: P, _ a: Double, _ profile: [(Double, Double)]) -> [P] {
        let along = P(cos(a), sin(a)), across = P(-sin(a), cos(a))
        let near = profile.map { c + $0.0 * along + $0.1 * across }, far = profile.reversed().map { c + $0.0 * along - $0.1 * across }
        return near + far + [near[0]]
    }

    /// Problem 3, quad: a dial at nine o'clock, so each hand lies between two knobs: chapter ring, minute track and
    /// the two winding holes.
    static func clockFace() -> Plate {
        var plate = Plate()
        let c = P(0, 0), holes = [P(-0.16, 0.27), P(0.16, 0.27)]
        tint(&plate, angle: 0.5, around: [arc(c, 0.95)])
        plate.lines(hatch([arc(c, 0.55)] + holes.map { arc($0, 0.05) }, angle: -0.45, gap: 0.027), fine)
        plate.line(arc(c, 0.95), heavy)
        for radius in [0.91, 0.86, 0.55] { plate.line(arc(c, radius), fine) }
        plate.line(arc(c, 0.58), medium)
        for k in 0..<60 {
            let a = deg(6 * Double(k))
            plate.line([polar(c, 0.86, a), polar(c, 0.91, a)], k % 5 == 0 ? 0.016 : fine)
        }
        for h in 1...12 {
            let a = deg(30 * Double(h))
            plate.lines(numeral(h == 4 ? "IIII" : roman(h), at: c + 0.72 * P(sin(a), -cos(a)), height: 0.17, narrow: 0.7, turn: a), 0.016)
        }
        for hole in holes {
            plate.line(arc(hole, 0.05), medium)
            plate.line((0...4).map { polar(hole, 0.03, deg(45 + 90 * Double($0))) }, fine)
        }

        // The minute hand on twelve in ink, the hour hand on nine in the second ink.
        let minute = hand(c, deg(-90), [(-0.12, 0.012), (-0.06, 0.03), (0, 0.022), (0.5, 0.012), (0.56, 0.04), (0.62, 0.045), (0.7, 0.02), (0.84, 0.0)])
        plate.fill(minute, .black)
        let hour = hand(c, deg(180), [(-0.09, 0.014), (0, 0.026), (0.26, 0.016), (0.3, 0.062), (0.36, 0.07), (0.42, 0.04), (0.5, 0.0)])
        plate.fill(hour)
        plate.lines(hatch([hour], angle: 0.9, gap: 0.009), fine, .second)
        plate.line(hour, medium, .second)
        cut(&plate, arc(c, 0.05))
        plate.line(arc(c, 0.05), heavy)
        plate.line(arc(c, 0.018), medium)

        letter(&plate, "A", from: P(0.012, -0.36), at: P(0.15, -0.2))
        letter(&plate, "B", from: P(-0.33, 0.02), at: P(-0.19, 0.12))
        letter(&plate, "C", from: P(0.16, 0.27) + P(0.035, -0.035), at: P(0.3, 0.1))
        return plate
    }

    /// Problem 4, quad: a wheel of 44 on four crossings, a knob in each window, driving a pinion of 8.
    static func cogwheel() -> Plate {
        var plate = Plate()
        let c = P(0, 0), r = 0.72, bearing = deg(-22), pr = r * 8 / 44, small = polar(c, r + pr, bearing)
        tint(&plate, angle: -0.6, around: [])
        crossed(&plate, c, r, teeth: 44, spokes: 4, turn: deg(8), phase: mesh(bearing, teeth: 44), rim: 0.055, hub: 0.15, spoke: 0.052)
        pinion(&plate, small, pr, leaves: 8, phase: mesh(bearing + .pi, teeth: 8, gap: true), ink: .second)

        // Pitch circles and the line of centres.
        plate.lines(dashed(arc(c, r), on: 0.07, off: 0.015), fine)
        plate.lines(dashed(arc(small, pr), on: 0.04, off: 0.015), fine)
        plate.lines(dashed([polar(c, 0.2, bearing + .pi), polar(c, 1.1, bearing)], on: 0.07, off: 0.02), fine)
        plate.lines(dashed([polar(c, 0.2, bearing + .pi / 2), polar(c, 0.2, bearing - .pi / 2)], on: 0.07, off: 0.02), fine)

        letter(&plate, "A", from: polar(c, 0.36, deg(98)), at: P(0.2, 0.2))
        letter(&plate, "B", from: small + P(-0.05, -0.1), at: P(0.6, -0.64))
        letter(&plate, "C", from: polar(c, 0.11, deg(215)), at: P(-0.2, -0.19))
        letter(&plate, "D", from: polar(c, 0.72, deg(133)), at: P(-0.62, 0.64))
        return plate
    }

    /// Problem 5, eye: a clock key laid corner to corner between the knobs, the ratchet and click it winds against,
    /// and the pipe's end with its square.
    static func windingKey() -> Plate {
        var plate = Plate()
        let end = P(-0.6, 0.6), along = P(1, -1) / 2.0.squareRoot(), across = P(1, 1) / 2.0.squareRoot()
        func at(_ u: Double, _ v: Double) -> P { end + u * along + v * across }
        func turning(_ u0: Double, _ u1: Double, _ w0: Double, _ w1: Double) -> [P] { [at(u0, w0), at(u1, w1), at(u1, -w1), at(u0, -w0), at(u0, w0)] }
        tint(&plate, angle: 0.15, around: [])

        // The bow: one piece, a pierced wing each side of the shank.
        var bow: [P] = [], piercings: [[P]] = []
        for side in [1.0, -1.0] {
            let wing = curve(at(1.33, side * 0.03), at(1.33, side * 0.27), at(1.5, side * 0.33), 14) + curve(at(1.5, side * 0.33), at(1.71, side * 0.38), at(1.69, side * 0.18), 14)
                + curve(at(1.69, side * 0.18), at(1.67, side * 0.04), at(1.55, 0), 14)
            bow += side > 0 ? wing : wing.reversed()
            piercings.append(ellipse(at(1.53, side * 0.18), 0.07, 0.085, turned: -.pi / 4 + side * 0.5))
        }
        bow.append(bow[0])
        cut(&plate, bow, holes: piercings)
        plate.lines(hatch([bow] + piercings, angle: 0.3, gap: 0.013), fine)
        plate.lines(hatch([bow] + piercings.map { $0.map { p in p + 0.02 * along } }, angle: -0.9, gap: 0.02).filter { simd_dot($0[0] - end, along) > 1.53 }, fine)
        plate.line(bow, heavy)
        plate.lines(piercings, medium)
        // The shank and its knop, the collars, then the pipe with its square hole in hidden lines.
        let shank = turning(0.55, 1.39, 0.045, 0.034)
        cut(&plate, shank)
        plate.lines(hatch([shank], angle: -.pi / 4, gap: 0.011).filter { simd_dot($0[0] - end, across) > 0.008 }, fine)
        plate.line(shank, medium)
        let knop = ellipse(at(0.9, 0), 0.07, 0.068, turned: -.pi / 4)
        cut(&plate, knop)
        plate.lines(hatch([knop], angle: .pi / 4, gap: 0.012), fine)
        plate.line(knop, medium)
        for (u0, u1, w) in [(0.46, 0.5, 0.098), (0.5, 0.535, 0.062), (0.535, 0.575, 0.086), (1.25, 1.29, 0.07), (0.82, 0.84, 0.056), (0.96, 0.98, 0.054)] {
            let collar = turning(u0, u1, w, w)
            cut(&plate, collar)
            plate.lines(hatch([collar], angle: .pi / 4, gap: 0.011), fine)
            plate.line(collar, medium)
        }
        let pipe = turning(0, 0.46, 0.075, 0.075)
        cut(&plate, pipe)
        plate.lines(hatch([pipe], angle: -.pi / 4, gap: 0.01).filter { simd_dot($0[0] - end, across) > 0.03 }, fine)
        plate.line(pipe, heavy)
        plate.lines(dashed([at(0, 0.036), at(0.33, 0.036), at(0.33, -0.036), at(0, -0.036)], on: 0.03, off: 0.018), fine)
        plate.lines(dashed([at(-0.08, 0), at(1.86, 0)], on: 0.07, off: 0.02), fine)

        // The turn of the key, an arrow round the shank.
        let sweep = ellipse(at(1.08, 0), 0.03, 0.12, from: deg(-150), to: deg(150), turned: -.pi / 4)
        plate.line(sweep, medium)
        let tip = sweep[sweep.count - 1], back = simd_normalize(sweep[sweep.count - 3] - tip)
        plate.fill([tip, tip + 0.05 * back + 0.022 * P(-back.y, back.x), tip + 0.05 * back - 0.022 * P(-back.y, back.x)], .black)

        // The barrel arbor's ratchet and its click, the square the key takes in the second ink.
        let ratchet = P(-0.47, -0.47), stud = P(-0.2, -0.72), tooth = polar(ratchet, 0.2, deg(-38))
        crossed(&plate, ratchet, 0.2, teeth: 18, spokes: 4, turn: 0.4, phase: 0.1, escape: true)
        let square = (0...4).map { polar(ratchet, 0.062, deg(45 + 90 * Double($0)) + 0.2) }
        cut(&plate, arc(ratchet, 0.075))
        plate.line(arc(ratchet, 0.075), medium)
        plate.fill(square, .second)
        let click = curve(stud + P(0.0, -0.03), stud + P(-0.1, 0.02), tooth) + curve(tooth, stud + P(-0.05, 0.1), stud + P(0.0, 0.03)) + [stud + P(0.0, -0.03)]
        cut(&plate, click)
        plate.lines(hatch([click], angle: 0.2, gap: 0.011), fine)
        plate.line(click, medium)
        cut(&plate, arc(stud, 0.03))
        plate.line(arc(stud, 0.03), medium)
        plate.line(curve(stud + P(0.03, 0.0), P(-0.06, -0.86), P(-0.36, -0.78)), fine)

        // The pipe's end, enlarged.
        let view = P(0.5, 0.5), hole = (0...4).map { polar(view, 0.085, deg(45 + 90 * Double($0)) + 0.2) }
        cut(&plate, arc(view, 0.16))
        plate.lines(hatch([arc(view, 0.16), hole], angle: 0.8, gap: 0.013), fine)
        plate.line(arc(view, 0.16), heavy)
        plate.line(hole, medium)
        plate.lines(dashed([view + P(-0.21, 0), view + P(0.21, 0)], on: 0.05, off: 0.02), fine)
        plate.lines(dashed([view + P(0, -0.21), view + P(0, 0.21)], on: 0.05, off: 0.02), fine)

        letter(&plate, "A", from: at(1.6, 0.3), at: P(0.86, -0.04))
        letter(&plate, "B", from: at(0.25, -0.075), at: P(-0.74, 0.3))
        letter(&plate, "C", from: ratchet + P(-0.12, 0.12), at: P(-0.74, -0.2))
        letter(&plate, "D", from: view + P(-0.1, 0.11), at: P(0.28, 0.78))
        return plate
    }

    /// Problem 6, hex: a going train, every arbor in a gap between three knobs: the great wheel behind, the centre
    /// wheel over it, the escape wheel in front, and its anchor in the second ink.
    static func clockwork() -> Plate {
        var plate = Plate()
        func gapAt(_ a: Double) -> P { polar(P(0, 0), 0.56 / 3.0.squareRoot(), deg(a)) }
        let great = gapAt(120), centre = gapAt(-60), scape = gapAt(180)
        let bearing = { (a: P, b: P) in atan2(b.y - a.y, b.x - a.x) }
        tint(&plate, angle: 0.35, around: [], gap: 0.04)

        crossed(&plate, great, 0.523, teeth: 64, spokes: 6, turn: deg(30), phase: mesh(bearing(great, centre), teeth: 64), rim: 0.045, hub: 0.1, spoke: 0.034)
        pinion(&plate, centre, 0.123, leaves: 15, phase: mesh(bearing(centre, great), teeth: 15, gap: true))
        crossed(&plate, centre, 0.501, teeth: 60, spokes: 6, turn: deg(30), phase: 0.02, rim: 0.045, hub: 0.085, spoke: 0.032)
        crossed(&plate, scape, 0.2, teeth: 15, spokes: 4, turn: 0.5, phase: 0.15, hub: 0.045, escape: true, blind: true)

        // The anchor out to the left, between two knobs, a pallet on the teeth each side.
        let out = P(-1, 0), side = P(0, 1), arbor = scape + 0.3 * out
        let high = scape + 0.13 * out - 0.17 * side, low = scape + 0.13 * out + 0.17 * side
        let anchor = curve(high, arbor - 0.2 * side + 0.07 * out, arbor + 0.05 * out) + curve(arbor + 0.05 * out, arbor + 0.2 * side + 0.07 * out, low)
            + curve(low - 0.045 * side, arbor + 0.12 * side - 0.04 * out, arbor - 0.04 * out) + curve(arbor - 0.04 * out, arbor - 0.12 * side - 0.04 * out, high + 0.045 * side)
            + [high]
        cut(&plate, anchor)
        plate.lines(hatch([anchor], angle: 0.9, gap: 0.011), fine, .second)
        plate.line(anchor, medium, .second)
        cut(&plate, arc(arbor, 0.028))
        plate.line(arc(arbor, 0.028), medium)

        letter(&plate, "A", from: great + polar(P(0, 0), 0.47, deg(100)), at: P(0.3, 0.78))
        letter(&plate, "B", from: centre + polar(P(0, 0), 0.45, deg(-30)), at: P(0.84, -0.22))
        letter(&plate, "C", from: scape + polar(P(0, 0), 0.15, deg(250)), at: P(-0.32, -0.72))
        letter(&plate, "D", from: arbor + P(-0.03, 0.1), at: P(-0.8, 0.3))
        return plate
    }

    /// Problem 7, quad: a clock stopped, its two weights hanging level and still inside the four knobs, in a pause
    /// mark's proportions.
    static func pause() -> Plate {
        var plate = Plate()
        let half = 0.1, top = -0.25, bottom = 0.27, sheave = 0.062
        let cases = [-0.16, 0.16].map { box(P($0 - half, top), P($0 + half, bottom)) }
        let pulleys = [-0.16, 0.16].map { P($0, top - 0.17) }
        tint(&plate, angle: 0.5, around: cases + pulleys.map { arc($0, sheave) })
        for (x, pulley) in zip([-0.16, 0.16], pulleys) {
            // A round case is ruled closer towards its edges.
            for k in -13...13 {
                let dx = half * sin(deg(6.6 * Double(k)))
                plate.line([P(x + dx, top), P(x + dx, bottom)], fine)
            }
            plate.line(box(P(x - half, top), P(x + half, bottom)), heavy)
            cut(&plate, ellipse(P(x, top), half, 0.022))
            plate.line(ellipse(P(x, top), half, 0.022), medium)
            plate.line(ellipse(P(x, bottom), half, 0.022, from: 0, to: .pi), heavy)
            // The pulley on its stirrup, the line up each side to the seat board.
            let stirrup = strip(P(x, top - 0.02), pulley, 0.03)
            plate.fill(stirrup)
            plate.line(stirrup, fine)
            plate.lines(hatch([arc(pulley, sheave), arc(pulley, 0.022)], angle: 0.9, gap: 0.012), fine)
            plate.line(arc(pulley, sheave), medium)
            plate.line(arc(pulley, sheave - 0.014), fine)
            plate.line(arc(pulley, 0.022), medium)
            for side in [-1.0, 1.0] { plate.line([pulley + P(side * sheave, 0), P(x + side * sheave, -1.05)], medium) }
        }
        // Level and at rest: a line under both, and the plumb line between them.
        plate.lines(dashed([P(-0.42, bottom + 0.06), P(0.42, bottom + 0.06)], on: 0.05, off: 0.025), fine)
        plate.lines(dashed([P(0, -0.95), P(0, 0.9)], on: 0.07, off: 0.02), fine)
        cut(&plate, [P(-0.03, 0.72), P(0.03, 0.72), P(0, 0.8), P(-0.03, 0.72)])
        plate.lines(hatch([[P(-0.03, 0.72), P(0.03, 0.72), P(0, 0.8)]], angle: 0.6, gap: 0.009), fine, .second)
        plate.line([P(-0.03, 0.72), P(0.03, 0.72), P(0, 0.8), P(-0.03, 0.72)], medium, .second)

        letter(&plate, "A", from: P(-0.26, 0.05), at: P(-0.7, 0.0))
        letter(&plate, "B", from: pulleys[1] + P(0.045, -0.03), at: P(0.62, -0.62))
        letter(&plate, "C", from: P(0.03, 0.75), at: P(0.3, 0.8))
        return plate
    }

    /// Problem 8, pent: an alarm clock, a bell in each gap beside the top knob, its alarm hand in the second ink, asleep.
    static func snooze() -> Plate {
        var plate = Plate(), figures = Plate()
        let c = P(0, 0.07), body = 0.38, dial = 0.31
        var rings = [arc(c, body)]

        // The bells on their posts, the hammer between them, and the feet.
        for side in [-1.0, 1.0] {
            let out = P(side * sin(deg(33)), -cos(deg(33))), across = P(out.y, -out.x) * side
            let seat = c + 0.9 * out * 0.5 + 0.07 * out, bearing = atan2(out.y, out.x)
            let dome = arc(seat, 0.15, from: bearing - .pi / 2, to: bearing + .pi / 2) + [seat - 0.15 * across * side]
            let lip = strip(seat - 0.165 * across, seat + 0.165 * across, 0.028), post = strip(c + body * out, seat, 0.032)
            let nut = arc(seat + 0.165 * out, 0.022)
            rings += [dome, lip, post, nut]
            figures.lines(hatch([post], angle: bearing, gap: 0.011), fine)
            figures.line(post, fine)
            figures.fill(dome)
            figures.lines(hatch([dome], angle: bearing + .pi / 2, gap: 0.03), fine)
            figures.lines(hatch([arc(seat, 0.15, from: bearing - .pi / 2, to: bearing - 0.3) + [seat]], angle: bearing + 0.9, gap: 0.012), fine)
            figures.line(dome, heavy)
            figures.fill(lip)
            figures.lines(hatch([lip], angle: bearing, gap: 0.01), fine)
            figures.line(lip, medium)
            figures.line(nut, medium)
        }
        let shaft = strip(P(0, c.y - body), P(0, -0.39), 0.022), head = box(P(-0.045, -0.44), P(0.045, -0.385))
        rings += [shaft, head]
        figures.line(shaft, fine)
        figures.lines(hatch([head], angle: 0.8, gap: 0.01), fine)
        figures.line(head, medium)
        for a in [70.0, 110.0] {
            let leg = strip(polar(c, body - 0.02, deg(a)), polar(c, 0.52, deg(a)), 0.04), foot = arc(polar(c, 0.535, deg(a)), 0.03)
            rings += [leg, foot]
            figures.lines(hatch([leg], angle: deg(a), gap: 0.011), fine)
            figures.line(leg, fine)
            figures.fill(foot)
            figures.line(foot, medium)
        }
        tint(&plate, angle: 0.4, around: rings)
        plate.marks += figures.marks

        // The case in section round the dial.
        cut(&plate, arc(c, body))
        plate.lines(hatch([arc(c, body), arc(c, 0.335)], angle: -0.7, gap: 0.012), fine)
        plate.line(arc(c, body), heavy)
        plate.line(arc(c, 0.335), medium)
        plate.line(arc(c, dial), fine)
        for k in 0..<60 {
            let a = deg(6 * Double(k))
            plate.line([polar(c, k % 5 == 0 ? 0.25 : 0.285, a), polar(c, dial, a)], k % 15 == 0 ? 0.016 : k % 5 == 0 ? medium : fine)
        }
        plate.lines(hatch([arc(c, 0.21)], angle: 0.9, gap: 0.03), fine)
        plate.line(arc(c, 0.21), fine)
        let alarm = hand(c, deg(35), [(-0.04, 0.008), (0.15, 0.008), (0.15, 0.024), (0.2, 0.0)])
        plate.fill(alarm, .second)
        plate.fill(hand(c, deg(120), [(-0.04, 0.014), (0, 0.02), (0.1, 0.014), (0.12, 0.03), (0.17, 0.0)]), .black)
        plate.fill(hand(c, deg(-90), [(-0.05, 0.01), (0, 0.016), (0.2, 0.008), (0.26, 0.0)]), .black)
        cut(&plate, arc(c, 0.028))
        plate.line(arc(c, 0.028), medium)

        // Asleep.
        for (at, height) in [(P(0.62, 0.3), 0.1), (P(0.8, 0.03), 0.13), (P(0.7, -0.4), 0.17)] {
            let z = [P(-0.32, -0.5), P(0.32, -0.5), P(-0.32, 0.5), P(0.32, 0.5)].map { at + $0 * height }
            cut(&plate, arc(at, 0.68 * height))
            plate.line(turned(z, by: -0.15, about: at), 0.14 * height)
        }

        letter(&plate, "A", from: P(-0.38, -0.44), at: P(-0.7, -0.5))
        letter(&plate, "B", from: polar(c, 0.36, deg(165)), at: P(-0.76, 0.22))
        letter(&plate, "C", from: polar(c, 0.5, deg(110)) + P(-0.02, 0), at: P(-0.3, 0.8))
        return plate
    }

    /// Half the hourglass's width at `y` from the waist, out to the caps at 0.64.
    private static func bulb(_ y: Double) -> Double {
        let t = min(abs(y) / 0.64, 1)
        return 0.03 + 0.33 * pow(sin(.pi * t), 0.7) + 0.1 * t * t
    }

    /// A glass of two bulbs as one ring about the waist at the origin, `half` its half-width at each height to `reach`.
    private static func glassware(reach: Double, _ half: (Double) -> Double) -> [P] {
        let ys = stride(from: -reach, through: reach, by: 0.01).map { $0 }
        return ys.map { P(half($0), $0) } + ys.reversed().map { P(-half($0), $0) } + [P(half(-reach), -reach)]
    }

    /// Sand lying in a glass from `top` down to `floor`, its surface heaped to a peak of `peak` at the middle (or
    /// dished, below zero).
    private static func sand(top: Double, floor: Double, peak: Double, _ half: (Double) -> Double) -> [P] {
        let ys = stride(from: top, through: floor, by: 0.01).map { $0 }
        let surface = stride(from: -1.0, through: 1.0, by: 0.05).map { u in
            P(u * half(top), top - peak * (1 + cos(.pi * min(abs(u) / 0.7, 1))) / 2)
        }
        return surface + ys.map { P(half($0), $0) } + ys.reversed().map { P(-half($0), $0) }
    }

    /// Problem 9, eye: a sand-glass in its turned frame, leaning, half run: a knob in the open each side of the waist.
    static func hourglass() -> Plate {
        var plate = Plate(), figure = Plate()
        let lean = deg(5), bulbs = glassware(reach: 0.64, bulb)
        func place(_ points: [P]) -> [P] { turned(points, by: lean) }
        let caps = [box(P(-0.585, -0.71), P(0.585, -0.64)), box(P(-0.585, 0.64), P(0.585, 0.71))]
        let pillars = [-0.52, 0.52].map { x -> [P] in
            let ys = stride(from: -0.64, through: 0.64, by: 0.01).map { $0 }
            func half(_ y: Double) -> Double { 0.014 + 0.016 * abs(sin(3 * .pi * (y + 0.64) / 1.28)) }
            return ys.map { P(x + half($0), $0) } + ys.reversed().map { P(x - half($0), $0) } + [P(x + half(-0.64), -0.64)]
        }
        tint(&plate, angle: -0.35, around: ([bulbs] + caps + pillars).map(place))

        for cap in caps {
            figure.lines(hatch([cap], angle: 0.04, gap: 0.013), fine)
            figure.line(cap, medium)
        }
        for pillar in pillars {
            figure.lines(hatch([pillar], angle: 1.1, gap: 0.012), fine)
            figure.line(pillar, medium)
        }
        // Sand above in ink, drawing down to the waist and falling in a thread; the heap below in the second ink.
        let upper = sand(top: -0.26, floor: 0, peak: -0.1, bulb)
        let lower = sand(top: 0.34, floor: 0.64, peak: 0.1) { min(bulb($0), 0.04 + ($0 - 0.34) * 1.6) }
        for (grains, ink) in [(upper, Ink.black), (lower, Ink.second)] {
            figure.lines(hatch([grains], angle: 0.5, gap: ink == .black ? 0.014 : 0.019), fine, ink)
            figure.lines(hatch([grains], angle: -0.9, gap: 0.03).flatMap { dashed($0, on: 0.02, off: 0.02) }, fine, ink)
            figure.line(grains + [grains[0]], fine, ink)
        }
        figure.line([P(0, 0), P(0, 0.25)], medium)
        // The glass: its empty parts lightly ruled, form lines down each bulb, the outline last.
        figure.lines(hatch([bulbs, upper + [upper[0]], lower + [lower[0]]], angle: -1.0, gap: 0.045).flatMap { dashed($0, on: 0.05, off: 0.025) }, fine)
        for f in [-0.9, 0.62, 0.84] {
            let ys = stride(from: -0.6, through: 0.6, by: 0.01).map { $0 }
            figure.lines(dashed(ys.map { P(f * bulb($0), $0) }, on: 0.09, off: 0.03), fine)
        }
        figure.line(bulbs, heavy)
        for mark in figure.marks { plate.marks.append(Mark(points: place(mark.points), width: mark.width, ink: mark.ink)) }

        letter(&plate, "A", from: place([P(0.12, -0.16)])[0], at: P(0.74, -0.42))
        letter(&plate, "B", from: place([P(0.03, 0.0)])[0], at: P(0.22, 0.04))
        letter(&plate, "C", from: place([P(-0.52, 0.3)])[0], at: P(-0.8, 0.36))
        letter(&plate, "D", from: place([P(0.22, 0.58)])[0], at: P(0.76, 0.42))
        return plate
    }

    /// An egg's outline about `c`, its point up.
    private static func egg(_ c: P, _ rx: Double, _ ry: Double, from a: Double = 0, to b: Double = 2 * .pi) -> [P] {
        (0...48).map { i in
            let u = a + (b - a) * Double(i) / 48
            return c + P(rx * cos(u) * (1 + 0.16 * sin(u)), ry * sin(u))
        }
    }

    /// Problem 10, pent: a three-minute glass down the middle between the knobs, an egg in its cup to one side and
    /// one opened to the other, its yolk in the second ink.
    static func eggTimer() -> Plate {
        var plate = Plate(), figure = Plate()
        let waist = P(0, 0.24), reach = 0.53
        func width(_ y: Double) -> Double {
            let t = min(abs(y) / reach, 1)
            return 0.02 + 0.15 * pow(sin(.pi * pow(t, 1.25)), 0.8)
        }
        func place(_ points: [P]) -> [P] { points.map { $0 + waist } }
        let bulbs = glassware(reach: reach, width)
        let caps = [box(P(-0.25, -reach - 0.07), P(0.25, -reach)), box(P(-0.25, reach), P(0.25, reach + 0.07))]
        let pillars = [-0.205, 0.205].map { box(P($0 - 0.013, -reach), P($0 + 0.013, reach)) }
        var rings = ([bulbs] + caps + pillars).map(place)

        for cap in caps {
            figure.lines(hatch([cap], angle: 0.04, gap: 0.013), fine)
            figure.line(cap, medium)
        }
        for pillar in pillars {
            figure.lines(hatch([pillar], angle: 0.9, gap: 0.012), fine)
            figure.line(pillar, medium)
        }
        let upper = sand(top: -0.13, floor: 0, peak: -0.05, width)
        let lower = sand(top: 0.3, floor: reach, peak: 0.1) { min(width($0), 0.03 + ($0 - 0.3) * 1.6) }
        for grains in [upper, lower] {
            figure.lines(hatch([grains], angle: 0.5, gap: 0.012), fine)
            figure.lines(hatch([grains], angle: -0.9, gap: 0.024).flatMap { dashed($0, on: 0.02, off: 0.02) }, fine)
            figure.line(grains + [grains[0]], fine)
        }
        figure.line([P(0, 0), P(0, 0.2)], medium)
        figure.lines(hatch([bulbs, upper + [upper[0]], lower + [lower[0]]], angle: -1.0, gap: 0.04).flatMap { dashed($0, on: 0.05, off: 0.025) }, fine)
        figure.line(bulbs, heavy)

        // An egg in its cup to one side; to the other one boiled and halved, its yolk in the second ink.
        var eggs = Plate()
        let c = P(-0.67, 0.1), rim = c.y + 0.1
        let shell = egg(c, 0.135, 0.18)
        let bowl = curve(P(c.x - 0.14, rim), P(c.x - 0.13, rim + 0.17), P(c.x - 0.025, rim + 0.17), 10)
            + [P(c.x - 0.025, rim + 0.24), P(c.x - 0.1, rim + 0.28), P(c.x + 0.1, rim + 0.28), P(c.x + 0.025, rim + 0.24)]
            + curve(P(c.x + 0.025, rim + 0.17), P(c.x + 0.13, rim + 0.17), P(c.x + 0.14, rim), 10) + [P(c.x - 0.14, rim)]
        rings += [shell, bowl]
        eggs.lines(hatch([shell, egg(c + P(-0.03, -0.02), 0.1, 0.15)], angle: 0.9, gap: 0.014), fine)
        eggs.line(shell, heavy)
        eggs.fill(bowl)
        eggs.lines(hatch([bowl], angle: -0.5, gap: 0.011), fine)
        eggs.line(bowl, medium)
        eggs.line(ellipse(P(c.x, rim), 0.14, 0.024, from: 0, to: .pi), medium)
        let half = P(0.68, 0.2), lean = 0.5
        let white = turned(egg(half, 0.15, 0.2), by: lean, about: half), yolk = arc(half + P(-0.012, 0.03), 0.075)
        rings += [white]
        eggs.line(turned(egg(half, 0.15, 0.2), by: lean, about: half).map { $0 + P(0.012, 0.02) }, medium)
        eggs.fill(white)
        eggs.line(white, heavy)
        eggs.lines(hatch([yolk], angle: 0.8, gap: 0.01), fine, .second)
        eggs.line(yolk, medium, .second)
        tint(&plate, angle: 0.25, around: rings)
        for mark in figure.marks { plate.marks.append(Mark(points: place(mark.points), width: mark.width, ink: mark.ink)) }
        plate.marks += eggs.marks

        letter(&plate, "A", from: waist + P(0.11, -0.3), at: P(0.42, -0.58))
        letter(&plate, "B", from: waist + P(-0.08, 0.42), at: P(-0.36, 0.82))
        letter(&plate, "C", from: P(-0.74, 0.0), at: P(-0.82, -0.3))
        letter(&plate, "D", from: half + P(0.07, -0.13), at: P(0.84, -0.22))
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
