// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Direction A's plates for problems 21 to 30, pent and hex. Each is composed round every rod of its layout, as any
/// may carry a clock: on pent the middle out to 0.40 and the rim past 0.72 are clear of a clock's hub, on hex the band
/// from 0.16 to 0.40, the rim past 0.72 and the six lanes along the odd hours between them.
extension EscapementArt {
    private static let origin = P(0, 0)

    /// The ruled tint, left out of the rings by the even-odd rule.
    private static func ruling(_ plate: inout Plate, angle: Double, around rings: [[P]], gap: Double = 0.034) {
        plate.lines(hatch([Array(glass)] + rings, angle: angle, gap: gap), fine)
    }

    private static func band(_ a: P, _ b: P, _ width: Double) -> [P] {
        let n = simd_normalize(P(-(b - a).y, (b - a).x)) * (width / 2)
        return [a + n, b + n, b - n, a - n, a + n]
    }

    /// A part cut from the ground: bone under it, section hatching, then its edge.
    private static func solid(_ plate: inout Plate, _ ring: [P], angle: Double, gap: Double = 0.014, ink: Ink = .black,
                              edge: Double = medium) {
        plate.fill(ring)
        plate.lines(hatch([ring], angle: angle, gap: gap), fine, ink)
        plate.line(ring, edge)
    }

    /// The direction of hour `h` on a dial, twelve up.
    private static func clock(_ h: Double) -> Double { -.pi / 2 + h * .pi / 6 }

    /// A Roman numeral centred on `c`, its head turned to `turn` from upright, its width squeezed.
    private static func numeral(_ s: String, at c: P, height h: Double, turn: Double = 0, squeeze: Double = 1) -> [[P]] {
        guard let first = s.first, let last = s.last else { return [] }
        let advance = s.reduce(0.0) { $0 + ($1 == "I" ? 0.62 : 0.86) * h }
        let left = first == "I" ? 0.12 * h : 0, right = advance - (last == "I" ? 0.14 : 0.26) * h
        let mid = P((left + right) / 2, h / 2)
        return text(s, at: P(0, 0), height: h).map { stroke in
            turned(stroke.map { P(($0.x - mid.x) * squeeze, $0.y - mid.y) }, by: turn).map { $0 + c }
        }
    }

    /// A hand's outline from its arbor at `c`: a sword, or a spade for the hours, with a tail behind the arbor.
    private static func hand(_ c: P, toward a: Double, length l: Double, width w: Double, spade: Bool = false,
                             tail: Double = 0) -> [P] {
        let upper: [(Double, Double)] = spade
            ? [(-tail, 0.5 * w), (0.56 * l, 0.5 * w), (0.6 * l, 1.25 * w), (0.68 * l, 1.7 * w), (0.78 * l, 1.45 * w), (0.9 * l, 0.65 * w), (l, 0)]
            : [(-tail, 0.4 * w), (0.08 * l, 0.6 * w), (0.8 * l, 0.42 * w), (l, 0)]
        let half = upper.map { P($0.0, $0.1) }
        let ring = half + half.dropLast().reversed().map { P($0.x, -$0.y) } + [half[0]]
        return turned(ring, by: a).map { $0 + c }
    }

    /// A dial about `c`: minute track, Roman chapters read from the centre, and its middle ruled.
    private static func face(_ c: P, _ r: Double, numerals: Bool = true, rule: Double = 0.03) -> Plate {
        var plate = Plate()
        plate.fill(arc(c, r))
        plate.lines(hatch([arc(c, 0.64 * r)], angle: 0, gap: rule), fine)
        for k in 0..<60 {
            let a = Double(k) * .pi / 30
            plate.line([polar(c, k % 5 == 0 ? 0.9 * r : 0.94 * r, a), polar(c, r, a)], fine)
        }
        if numerals {
            for k in 1...12 {
                plate.lines(numeral(roman(k), at: polar(c, 0.78 * r, clock(Double(k))), height: 0.2 * r, turn: clock(Double(k)) + .pi / 2, squeeze: 0.72), medium)
            }
        }
        plate.line(arc(c, 0.64 * r), fine)
        plate.line(arc(c, 0.94 * r), fine)
        plate.line(arc(c, r), heavy)
        return plate
    }

    /// The hands of a dial at `hours` and `minutes`, the hour hand under.
    private static func hands(_ plate: inout Plate, _ c: P, _ r: Double, hours: Double, minutes: Double, ink: Ink = .black) {
        let hour = hand(c, toward: clock(hours + minutes / 60), length: 0.56 * r, width: 0.09 * r, spade: true, tail: 0.1 * r)
        let minute = hand(c, toward: clock(minutes / 5), length: 0.9 * r, width: 0.085 * r, tail: 0.16 * r)
        solid(&plate, hour, angle: 0.9, gap: 0.011, ink: ink)
        solid(&plate, minute, angle: 0.9, gap: 0.011, ink: ink)
        plate.fill(arc(c, 0.07 * r))
        plate.line(arc(c, 0.07 * r), medium)
    }

    private static func mirrored(_ marks: [Mark], about x: Double) -> [Mark] {
        marks.map { Mark(points: $0.points.map { P(2 * x - $0.x, $0.y) }, width: $0.width, ink: $0.ink) }
    }

    /// A strip `width` wide along a path, as one outline.
    private static func ribbon(_ path: [P], _ width: Double) -> [P] {
        var left: [P] = [], right: [P] = []
        for i in path.indices {
            let d = path[min(i + 1, path.count - 1)] - path[max(i - 1, 0)]
            let n = simd_normalize(P(-d.y, d.x)) * (width / 2)
            left.append(path[i] + n)
            right.append(path[i] - n)
        }
        return left + right.reversed() + [left[0]]
    }

    /// A strip along a path that crosses itself, laid down a short length at a time so each loop lies over the last.
    private static func strand(_ plate: inout Plate, _ path: [P], _ width: Double, ink: Ink = .black) {
        for from in stride(from: 0, to: path.count - 1, by: 6) {
            let piece = ribbon(Array(path[max(from - 1, 0)...min(from + 7, path.count - 1)]), width), half = piece.count / 2
            plate.fill(piece)
            plate.line(Array(piece[0..<half]), medium, ink)
            plate.line(Array(piece[half..<(piece.count - 1)]), medium, ink)
        }
    }

    /// An arrow's barbed head, its tip at `tip`, flying toward `a`.
    private static func barb(_ tip: P, toward a: Double, size: Double) -> [P] {
        [tip, polar(tip, size, a + .pi - 0.42), polar(tip, 0.6 * size, a + .pi), polar(tip, size, a + .pi + 0.42), tip]
    }

    // MARK: 21 Mirror dial

    /// Problem 21, pent: a dial in a hand-glass, its chapters and hands the wrong way round, and the dial itself beside it.
    static func plate21() -> Plate {
        var plate = Plate()
        let glassRadius = 0.385, frame = 0.47, image = P(0.03, 0.025), dial = P(-0.43, -0.585)
        let ys = stride(from: 0.462, through: 1.08, by: 0.01).map { $0 }
        func half(_ y: Double) -> Double { 0.03 + 0.04 * pow(abs(sin(.pi * (y - 0.47) / 0.2)), 0.8) }
        let handle = ys.map { P(half($0), $0) } + ys.reversed().map { P(-half($0), $0) } + [P(half(0.462), 0.462)]
        ruling(&plate, angle: 0.45, around: [arc(origin, frame), handle, arc(dial, 0.215)])

        // The sight lines from the dial to its image.
        let across = simd_normalize(P(dial.y, -dial.x))
        for side in [-1.0, 1.0] {
            plate.lines(dashed([dial + side * 0.215 * across, image + side * 0.3 * across], on: 0.045, off: 0.02), fine)
        }

        // The frame, beaded, and its turned handle.
        plate.fill(arc(origin, frame))
        plate.lines(hatch([arc(origin, frame), arc(origin, glassRadius)], angle: -0.8, gap: 0.012), fine)
        for k in 0..<30 {
            let bead = arc(polar(origin, (frame + glassRadius) / 2, Double(k) * .pi / 15), 0.024)
            plate.fill(bead)
            plate.line(bead, fine)
        }
        plate.line(arc(origin, frame), heavy)
        plate.line(arc(origin, glassRadius), medium)
        plate.fill(handle)
        plate.lines(hatch([handle], angle: 0, gap: 0.014), fine)
        plate.lines(hatch([handle.map { P(max($0.x, 0.012), $0.y) }], angle: .pi / 2, gap: 0.014), fine)
        plate.line(handle, medium)

        // The glass, and the dial's image in it.
        plate.lines(hatch([arc(origin, glassRadius), arc(image, 0.3)], angle: -.pi / 4, gap: 0.02), fine)
        var seen = face(image, 0.3)
        hands(&seen, image, 0.3, hours: 10, minutes: 9, ink: .second)
        plate.marks += mirrored(seen.marks, about: image.x)
        for (from, to) in [(P(-0.2, 0.3), P(0.02, 0.08)), (P(-0.13, 0.31), P(0.05, 0.13)), (P(0.14, -0.1), P(0.3, -0.26))] {
            plate.line([from, to], fine)
        }

        var true_ = face(dial, 0.215, rule: 0.024)
        hands(&true_, dial, 0.215, hours: 10, minutes: 9)
        plate.marks += true_.marks

        callout(&plate, "A", from: dial + P(-0.17, 0.1), to: P(-0.8, -0.32))
        callout(&plate, "B", from: image + P(0.2, -0.14), to: P(0.52, -0.62))
        callout(&plate, "C", from: polar(origin, 0.43, 2.85), to: P(-0.76, 0.26))
        callout(&plate, "D", from: P(0.05, 0.84), to: P(0.34, 0.84))
        return plate
    }

    // MARK: 22 Anticlockwise

    /// Problem 22, hex: a hand going the wrong way round, where it stood two hours and four hours ago dashed behind it.
    static func plate22() -> Plate {
        var plate = Plate()
        let from = clock(5), to = clock(9.35) - 2 * .pi
        let head = to - 0.2
        let arrow = arc(origin, 0.925, from: from, to: to) + [polar(origin, 0.975, to), polar(origin, 0.895, head), polar(origin, 0.815, to)]
            + arc(origin, 0.865, from: to, to: from) + [polar(origin, 0.925, from)]
        let batons = (0..<12).map { k in band(polar(origin, 0.755, clock(Double(k))), polar(origin, 0.84, clock(Double(k))), k % 3 == 0 ? 0.05 : 0.03) }
        let now = hand(origin, toward: clock(9), length: 0.7, width: 0.05, spade: true, tail: 0.24)
        let ghosts = [1.0, 11.0].map { hand(origin, toward: clock($0), length: 0.7, width: 0.05, spade: true, tail: 0.24) }
        ruling(&plate, angle: 0.3, around: [arrow, now] + batons)

        for r in [0.72, 0.745] { plate.line(arc(origin, r), fine) }
        for k in 0..<60 { plate.line([polar(origin, 0.72, Double(k) * .pi / 30), polar(origin, 0.745, Double(k) * .pi / 30)], fine) }
        for baton in batons { solid(&plate, baton, angle: 0.9, gap: 0.009) }
        plate.line(arc(origin, 0.985), medium)

        // Where the hand stood, and the steps between.
        for (k, ghost) in ghosts.enumerated() {
            plate.fill(ghost)
            plate.lines(hatch([ghost], angle: 0.3, gap: 0.034).flatMap { dashed($0, on: 0.012, off: 0.012) }, fine)
            plate.lines(dashed(ghost, on: k == 0 ? 0.02 : 0.04, off: 0.018), medium)
        }
        for h in [1.0, 11.0] {
            let a = clock(h) - 0.22, b = clock(h - 2) + 0.3
            plate.line(arc(origin, 0.33, from: a, to: b), heavy)
            plate.fill(barb(polar(origin, 0.33, b - 0.1), toward: b - .pi / 2, size: 0.095), .black)
        }
        solid(&plate, now, angle: 0.9, gap: 0.012, ink: .second)
        let boss = arc(origin, 0.11)
        solid(&plate, boss, angle: -0.7, gap: 0.012)

        // The arrow round the rim.
        plate.lines(hatch([arrow], angle: 1.2, gap: 0.013), fine)
        plate.line(arrow, medium)

        callout(&plate, "A", from: polar(origin, 0.52, clock(9)) + P(0, 0.03), to: polar(origin, 0.84, clock(8)) + P(0.06, -0.02))
        callout(&plate, "B", from: polar(origin, 0.44, clock(1)) + P(0.03, 0.02), to: P(0.76, -0.1))
        callout(&plate, "C", from: polar(origin, 0.865, clock(4.4)), to: polar(origin, 0.66, clock(5)) + P(-0.02, 0.0))
        return plate
    }

    // MARK: 23 Overwound

    /// Problem 23, pent: a going barrel with its lid off, the spring wound dead on the arbor, its outer end torn from the
    /// hook and out through the wall; the ratchet and click that held it, and the key.
    static func plate23() -> Plate {
        var plate = Plate(), figures = Plate()
        let wall = 0.345, inner = 0.322, breach = (from: -0.2, to: 0.46)
        let ratchet = P(-0.43, -0.585)
        let barrel = gear(origin, 0.385, teeth: 46, phase: 0.03)

        // The spring: eleven turns tight, a loose one, then out through the wall and curling free.
        let tight = (0...1100).map { i -> P in
            let turns = Double(i) / 100
            return polar(origin, 0.058 + 0.0128 * turns, 2 * .pi * turns)
        }
        // The loose turn runs from where the tight coil ends, at three o'clock, once round to the breach.
        var free: [P] = (0...80).map { i in
            let t = Double(i) / 80
            return polar(origin, 0.199 + 0.165 * pow(t, 1.5), t * (2 * .pi + 0.13))
        }
        // Free of the barrel it runs up the rim in loops, as a spring let go does.
        let out = free[free.count - 1], along = 32 * Double.pi / 180
        // It ends on the outside of its last loop, past the edge of twelve's disc, where a clock's dashes never run.
        func loop(_ t: Double) -> P { polar(polar(origin, 0.8 + 0.04 * t, along - 1.5 * t), 0.1, 2.1 - 11.5 * .pi * t) }
        free += curve(out, P(0.52, 0.36), loop(0), 20).dropFirst()
        free += (1...340).map { loop(Double($0) / 340) }
        let strip = ribbon(free, 0.024), tail = Array(free.suffix(34))

        var rings = wheel(&figures, ratchet, 0.17, teeth: 15, spokes: 4, phase: 0.1, escape: true)
        let key = (bow: P(-0.2, 0.79), end: P(0.26, 0.79))
        let shaft = band(key.bow + P(0.1, 0), key.end, 0.04)
        rings += [barrel, strip, arc(key.bow, 0.1), shaft]
        ruling(&plate, angle: -0.5, around: rings)
        plate.marks += figures.marks

        // The click on the ratchet, and its spring.
        let pivot = polar(ratchet, 0.29, -1.05), tooth = polar(ratchet, 0.165, -0.3)
        let click = [pivot + P(-0.03, -0.02), pivot + P(0.035, -0.025), tooth + P(0.014, -0.004), tooth + P(-0.01, 0.01), pivot + P(-0.03, 0.03), pivot + P(-0.03, -0.02)]
        solid(&plate, click, angle: 0.4, gap: 0.011)
        plate.line(arc(pivot, 0.016), medium)
        plate.line(curve(pivot + P(-0.03, 0.0), ratchet + P(-0.1, -0.36), polar(ratchet, 0.24, -2.3)), medium)
        plate.line(arc(ratchet, 0.235, from: 1.2, to: 3.3), medium)
        plate.fill(barb(polar(ratchet, 0.235, 3.42), toward: 3.42 + .pi / 2, size: 0.075), .black)

        // The barrel: its teeth, the wall broken open, the floor lightly ruled.
        plate.fill(barrel)
        plate.lines(hatch([barrel, arc(origin, wall)], angle: 0.9, gap: 0.012), fine)
        plate.line(barrel, medium)
        plate.lines(hatch([arc(origin, inner), arc(origin, 0.2)], angle: 0.2, gap: 0.03).flatMap { dashed($0, on: 0.05, off: 0.02) }, fine)
        for r in [wall, inner] { plate.line(arc(origin, r, from: breach.to, to: 2 * .pi + breach.from), medium) }
        let gap = arc(origin, 0.41, from: breach.from, to: breach.to) + arc(origin, inner, from: breach.to, to: breach.from)
        plate.fill(gap)
        for edge in [breach.from, breach.to] {
            plate.line([polar(origin, inner, edge), polar(origin, 0.345, edge + 0.05), polar(origin, 0.365, edge - 0.04), polar(origin, 0.405, edge + 0.02)], medium)
        }
        plate.line(tight, medium)
        plate.fill(arc(origin, 0.058))
        plate.line(arc(origin, 0.058), heavy)
        plate.line(box(P(-0.026, -0.026), P(0.026, 0.026)), medium)

        // The spring's free end, the torn eye last.
        strand(&plate, Array(free.dropLast(33)), 0.024)
        strand(&plate, tail, 0.024, ink: .second)
        plate.lines(hatch([ribbon(tail, 0.024)], angle: 0.9, gap: 0.008), fine, .second)

        // The key.
        solid(&plate, shaft, angle: 0, gap: 0.01)
        plate.fill(arc(key.bow, 0.1))
        plate.lines(hatch([arc(key.bow, 0.1), arc(key.bow, 0.055)], angle: 0.8, gap: 0.011), fine)
        plate.line(arc(key.bow, 0.1), medium)
        plate.line(arc(key.bow, 0.055), medium)
        solid(&plate, box(key.end + P(-0.07, -0.032), key.end + P(0, 0.032)), angle: .pi / 2, gap: 0.009)

        callout(&plate, "A", from: polar(origin, 0.13, 2.4), to: P(-0.72, 0.2))
        callout(&plate, "B", from: free[free.count - 60] + P(0.0, -0.01), to: P(0.8, -0.34))
        callout(&plate, "C", from: ratchet + P(0.08, 0.1), to: P(-0.8, -0.26))
        callout(&plate, "D", from: polar(origin, 0.37, 2.0), to: P(-0.52, 0.66))
        return plate
    }

    // MARK: 24 Reverse

    /// Problem 24, hex: a watch turned over. Its movement fills the glass: striped bridges, the winding wheels, the
    /// balance under its cock; the side it is usually seen from is drawn small beside it.
    static func plate24() -> Plate {
        var plate = Plate(), wheels = Plate()
        let edge = 0.9
        func at(_ r: Double, _ h: Double) -> P { polar(origin, r, clock(h)) }
        let ratchet = at(0.71, 1), crown = P(0.085, -0.79), balance = at(0.7, 7), escape = at(0.81, 5.72), front = at(0.745, 11)
        let third = at(0.75, 9)
        var holes: [[P]] = []
        for (c, r, teeth) in [(ratchet, 0.215, 34), (crown, 0.105, 16)] {
            let outline = gear(c, r, teeth: teeth, phase: 0.1)
            holes.append(outline)
            wheels.line(outline, medium)
            wheels.line(arc(c, 0.8 * r), fine)
            for k in 0..<(2 * teeth) { wheels.line([polar(c, (k % 2 == 0 ? 0.3 : 0.5) * r, Double(k) * .pi / Double(teeth)), polar(c, 0.8 * r, Double(k) * .pi / Double(teeth))], fine) }
            wheels.fill(arc(c, 0.3 * r))
            wheels.line(arc(c, 0.3 * r), heavy)
            wheels.line(band(polar(c, 0.3 * r, 0.6), polar(c, 0.3 * r, 0.6 + .pi), 0.06 * r + 0.004), fine)
        }

        // The bridges, striped, over a plate hatched close.
        let top = arc(origin, edge, from: -165 * .pi / 180, to: -12 * .pi / 180)
            + curve(polar(origin, edge, -12 * .pi / 180), P(0.5, 0.06), P(0.13, -0.17)).dropFirst()
            + curve(P(0.13, -0.17), P(-0.3, -0.46), polar(origin, edge, -165 * .pi / 180)).dropFirst()
        let train = arc(origin, edge, from: 9 * .pi / 180, to: 70 * .pi / 180)
            + curve(polar(origin, edge, 70 * .pi / 180), P(0.06, 0.44), P(0.2, 0.17)).dropFirst()
            + curve(P(0.2, 0.17), P(0.42, -0.02), polar(origin, edge, 9 * .pi / 180)).dropFirst()
        let cockFoot = arc(origin, 0.885, from: clock(7.75), to: clock(8.75)) + arc(origin, 0.72, from: clock(8.75), to: clock(7.75)) + [polar(origin, 0.885, clock(7.75))]
        let arm = band(at(0.8, 8.1), balance, 0.085)
        let thirdRings = wheel(&wheels, third, 0.17, teeth: 30, spokes: 5, phase: 0.2)
        plate.lines(hatch([arc(origin, edge), top, train, arc(balance, 0.2), arc(escape, 0.1)] + thirdRings, angle: -1.0, gap: 0.017), fine)
        plate.lines(hatch([top, arc(front, 0.2)] + holes, angle: 0.52, gap: 0.03), fine)
        plate.lines(hatch([train], angle: 0.52, gap: 0.03, shift: 0.5), fine)
        plate.line(top + [top[0]], heavy)
        plate.line(train + [train[0]], heavy)
        plate.marks += wheels.marks

        // The case in section round it.
        plate.lines(hatch([Array(glass), arc(origin, 0.93)], angle: 0.9, gap: 0.012), fine)
        for r in [edge, 0.93] { plate.line(arc(origin, r), medium) }

        // Jewels at the pivots and screws in the bridges.
        for jewel in [at(0.33, 3), at(0.5, 5), at(0.33, 1), escape] {
            plate.fill(arc(jewel, 0.052))
            plate.line(arc(jewel, 0.052), medium)
            plate.line(arc(jewel, 0.03), heavy)
            plate.line(arc(jewel, 0.008), medium)
        }
        for (k, screw) in [at(0.8, 9.9), at(0.8, 2.25), at(0.78, 3.5), at(0.33, 5), at(0.82, 4.5), at(0.5, 9)].enumerated() {
            plate.fill(arc(screw, 0.04))
            plate.line(arc(screw, 0.04), heavy)
            plate.line(band(polar(screw, 0.04, Double(k) * 1.1), polar(screw, 0.04, Double(k) * 1.1 + .pi), 0.012), fine)
        }

        // The escape wheel and the balance: its rim and arms, the spring, then the cock over it.
        plate.line(escapeWheel(escape, 0.09, teeth: 15), medium)
        plate.fill(arc(balance, 0.2))
        plate.lines(hatch([arc(balance, 0.19), arc(balance, 0.158)], angle: 0.3, gap: 0.011), fine)
        for r in [0.19, 0.158] { plate.line(arc(balance, r), medium) }
        for k in 0..<3 {
            let spoke = band(polar(balance, 0.03, 0.5 + Double(k) * 2 * .pi / 3), polar(balance, 0.158, 0.5 + Double(k) * 2 * .pi / 3), 0.028)
            plate.line(spoke, fine)
        }
        for k in 0..<14 { plate.line(arc(polar(balance, 0.2, Double(k) * .pi / 7), 0.011), medium) }
        let spring = (0...300).map { i -> P in
            let turns = Double(i) / 60
            return polar(balance, 0.028 + 0.0195 * turns, 2 * .pi * turns + 1)
        }
        plate.line(spring, medium, .second)
        solid(&plate, arm, angle: -0.4, gap: 0.013)
        solid(&plate, cockFoot, angle: -0.4, gap: 0.013)
        solid(&plate, arc(balance, 0.062), angle: -0.4, gap: 0.013)
        plate.fill(arc(balance, 0.03))
        plate.line(arc(balance, 0.03), heavy)
        for screw in [at(0.8, 7.95), at(0.8, 8.55)] {
            plate.fill(arc(screw, 0.034))
            plate.line(arc(screw, 0.034), heavy)
            plate.line([screw + P(-0.024, 0.024), screw + P(0.024, -0.024)], medium)
        }

        // The side it is seen from, and the turn between.
        plate.fill(arc(front, 0.2))
        let dial = front + P(0, 0.035)
        var small = face(dial, 0.115, numerals: false, rule: 0.02)
        hands(&small, dial, 0.115, hours: 10, minutes: 9)
        plate.line(band(dial + P(0, -0.115), dial + P(0, -0.15), 0.04), medium)
        plate.line(arc(dial + P(0, -0.178), 0.03), heavy)
        plate.line(arc(dial, 0.135), medium)
        plate.marks += small.marks
        plate.line(arc(front, 0.2), heavy)
        let turn = curve(front + P(0.075, 0.2), P(-0.31, -0.25), P(-0.17, -0.27))
        plate.fill(ribbon(turn + [P(-0.1, -0.27)], 0.07))
        plate.line(turn, heavy)
        plate.fill(barb(P(-0.1, -0.272), toward: 0, size: 0.1), .black)

        callout(&plate, "A", from: balance + P(0.1, 0.13), to: at(0.86, 6.35))
        callout(&plate, "B", from: ratchet + P(0.12, 0.1), to: at(0.8, 2.9))
        callout(&plate, "C", from: at(0.62, 4.4), to: at(0.36, 7) + P(0.05, -0.03))
        return plate
    }

    // MARK: 26 Calendar

    /// The seven planets' signs, Sun to Saturn, as an almanac heads the days of the week.
    private static func daySign(_ k: Int, at c: P, size s: Double) -> [[P]] {
        func at(_ x: Double, _ y: Double) -> P { c + P(x, y) * s }
        switch k {
        case 0: return [arc(c, 0.8 * s), arc(c, 0.12 * s)]
        case 1: return [arc(at(-0.2, 0), 0.85 * s, from: 0.87, to: 2 * .pi - 0.87) + arc(at(0.44, 0), 0.66 * s, from: .pi + 1.42, to: .pi - 1.42)]
        case 2: return [arc(at(-0.2, 0.25), 0.55 * s), [at(0.2, -0.15), at(0.8, -0.8)], [at(0.35, -0.8), at(0.8, -0.8), at(0.8, -0.35)]]
        case 3: return [arc(at(0, -0.1), 0.42 * s), arc(at(0, -0.92), 0.4 * s, from: 0, to: .pi), [at(0, 0.32), at(0, 1)], [at(-0.3, 0.68), at(0.3, 0.68)]]
        case 4: return [[at(-0.7, -0.55), at(-0.35, -0.85), at(0, -0.6), at(-0.1, -0.2), at(-0.7, 0.35), at(0.7, 0.35)], [at(0.35, -0.2), at(0.35, 0.95)]]
        case 5: return [arc(at(0, -0.35), 0.48 * s), [at(0, 0.13), at(0, 1)], [at(-0.35, 0.58), at(0.35, 0.58)]]
        default: return [[at(-0.3, -0.95), at(-0.3, 0.55)], [at(-0.65, -0.6), at(0.05, -0.6)],
                         [at(-0.3, 0.0), at(0.05, -0.25), at(0.4, -0.05), at(0.4, 0.4), at(0.2, 0.75), at(0.45, 0.95)]]
        }
    }

    /// Problem 26, pent: an almanac's leaf, the month ruled in weeks under the planets' signs, one day marked.
    static func plate26() -> Plate {
        var plate = Plate(), leaf = Plate()
        let w = 0.2, h = 0.2, head = 0.15, left = -0.7, top = -0.575, lean = -4 * Double.pi / 180
        let bottom = top + head + 5 * h, first = 2, marked = 16
        func place(_ points: [P]) -> [P] { turned(points, by: lean) }
        func cell(_ i: Int) -> (a: P, b: P) {
            let a = P(left + Double(i % 7) * w, top + head + Double(i / 7) * h)
            return (a, a + P(w, h))
        }
        let sheet = box(P(left, top), P(left + 7 * w, bottom)), border = box(P(left - 0.035, top - 0.035), P(left + 7 * w + 0.035, bottom + 0.035))
        ruling(&plate, angle: 0.6, around: [place(border)])

        leaf.lines(hatch([border, sheet], angle: 0.8, gap: 0.011), fine)
        leaf.line(border, heavy)
        leaf.line(sheet, medium)
        // The signs' row, ruled behind each.
        for k in 0..<7 {
            let c = P(left + (Double(k) + 0.5) * w, top + head / 2)
            leaf.lines(hatch([box(P(c.x - w / 2, top), P(c.x + w / 2, top + head)), arc(c, 0.062)], angle: .pi / 2, gap: 0.014), fine)
            leaf.lines(daySign(k, at: c, size: 0.04), medium)
        }
        for i in 0..<35 {
            let day = i - first + 1, box = box(cell(i).a, cell(i).b), mid = (cell(i).a + cell(i).b) * 0.5
            if day < 1 || day > 31 {
                leaf.lines(hatch([box], angle: -0.8, gap: 0.016), fine)
                continue
            }
            if day == marked {
                leaf.lines(hatch([box], angle: 0.8, gap: 0.013), fine, .second)
                leaf.fill(arc(mid, 0.078))
                leaf.line(arc(mid, 0.078), medium, .second)
            }
            let wide = roman(day).reduce(0.0) { $0 + ($1 == "I" ? 0.62 : 0.86) * 0.07 }
            leaf.lines(numeral(roman(day), at: mid, height: 0.07, squeeze: min(0.72, 0.158 / wide)), 0.009)
        }
        // The table's rules, doubled, a heavier one under the signs.
        for k in 1..<7 {
            let x = left + Double(k) * w
            for d in [-0.006, 0.006] { leaf.line([P(x + d, top), P(x + d, bottom)], fine) }
        }
        for k in 1..<5 {
            let y = top + head + Double(k) * h
            for d in [-0.006, 0.006] { leaf.line([P(left, y + d), P(left + 7 * w, y + d)], fine) }
        }
        leaf.line([P(left, top + head), P(left + 7 * w, top + head)], heavy)
        leaf.line([P(left, top + head + 0.014), P(left + 7 * w, top + head + 0.014)], fine)
        plate.fill(place(border))
        for mark in leaf.marks { plate.marks.append(Mark(points: place(mark.points), width: mark.width, ink: mark.ink)) }

        callout(&plate, "A", from: place([P(-0.4, top + 0.02)])[0], to: P(-0.42, -0.76))
        callout(&plate, "B", from: place([P(0.07, 0.11)])[0], to: P(0.3, 0.78))
        callout(&plate, "C", from: place([P(left + 7 * w + 0.02, 0.3)])[0], to: P(0.84, 0.36))
        return plate
    }

    // MARK: 27 Time zones

    /// Problem 27, pent: a globe ruled in its twenty-four hours inside an hour ring, and five dials round it, one
    /// minute and five different hours.
    static func plate27() -> Plate {
        var plate = Plate()
        let radius = 0.33, tilt = 22 * Double.pi / 180, lean = 20 * Double.pi / 180
        /// A point of the globe on the page, and whether it faces the reader.
        func globe(_ lat: Double, _ lon: Double) -> (p: P, seen: Bool) {
            let x = cos(lat) * sin(lon), y = -sin(lat), z = cos(lat) * cos(lon)
            let y1 = y * cos(tilt) + z * sin(tilt), z1 = -y * sin(tilt) + z * cos(tilt)
            return (P(x * cos(lean) - y1 * sin(lean), x * sin(lean) + y1 * cos(lean)) * radius, z1 > 0)
        }
        func seen(_ points: [(p: P, seen: Bool)]) -> [[P]] {
            var out: [[P]] = [], run: [P] = []
            for point in points {
                if point.seen { run.append(point.p) } else if run.count > 1 { out.append(run); run = [] } else { run = [] }
            }
            if run.count > 1 { out.append(run) }
            return out
        }
        let dials = (0..<5).map { polar(origin, 0.735, (-54 + 72 * Double($0)) * .pi / 180) }
        ruling(&plate, angle: -0.25, around: [arc(origin, 0.4)] + dials.map { arc($0, 0.195) })

        // The hour ring, its night half filled.
        plate.fill(arc(origin, 0.4))
        for k in 0..<24 where k % 2 == 0 {
            let a = Double(k) * .pi / 12
            let block = arc(origin, 0.4, from: a, to: a + .pi / 12) + arc(origin, 0.362, from: a + .pi / 12, to: a)
            plate.lines(hatch([block], angle: a + 0.13, gap: 0.009), fine)
        }
        for r in [0.4, 0.362] { plate.line(arc(origin, r), medium) }

        // The globe: a meridian an hour, parallels, one hour's gore in the second ink.
        let lats = stride(from: -90.0, through: 90.0, by: 3).map { $0 * .pi / 180 }
        let gore = lats.map { globe($0, 0.0).p } + lats.reversed().map { globe($0, 15 * .pi / 180).p }
        plate.lines(hatch([gore], angle: 0.5, gap: 0.011), fine, .second)
        for k in 0..<24 {
            let lon = Double(k) * 15 * .pi / 180
            plate.lines(seen(lats.map { globe($0, lon) }), k % 6 == 0 ? medium : fine)
        }
        for lat in [-60.0, -30, 0, 30, 60] {
            let ring = stride(from: 0.0, through: 360.0, by: 4).map { globe(lat * .pi / 180, $0 * .pi / 180) }
            plate.lines(seen(ring), lat == 0 ? heavy : fine)
        }
        plate.line(arc(origin, radius), heavy)
        let pole = simd_normalize(globe(.pi / 2, 0).p)
        for side in [-1.0, 1.0] {
            plate.line([side * radius * pole, side * 0.362 * pole], heavy)
        }

        // The dials, each tied to the ring.
        for (k, dial) in dials.enumerated() {
            var small = face(dial, 0.195, rule: 0.022)
            hands(&small, dial, 0.195, hours: [2.0, 5, 8, 10, 12][k], minutes: 0)
            plate.marks += small.marks
            let inward = simd_normalize(dial)
            plate.line([dial - 0.195 * inward, 0.4 * inward], medium)
            plate.line(arc(0.4 * inward, 0.012), heavy)
        }

        callout(&plate, "A", from: globe(0.5, 0.13).p, to: P(-0.25, 0.8))
        callout(&plate, "B", from: dials[1] + P(-0.05, 0.19), to: P(0.56, 0.62))
        return plate
    }

    // MARK: 28 Leap year

    /// Problem 28, hex: a perpetual calendar's cam of forty-eight months, a step a month and the deepest each February;
    /// the fourth year's is shallower, the feeler rides in it, and the date in the window is the twenty-ninth.
    static func plate28() -> Plate {
        var plate = Plate(), figures = Plate()
        let days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31], step = 2 * Double.pi / 48
        let start = clock(1) - 37.5 * step
        func depth(_ month: Int) -> Double {
            let d = month == 37 ? 29 : days[month % 12]
            return d == 31 ? 0.392 : d == 30 ? 0.368 : d == 29 ? 0.338 : 0.312
        }
        var cam: [P] = []
        for m in 0..<48 { cam += arc(origin, depth(m), from: start + Double(m) * step, to: start + Double(m + 1) * step) }
        cam.append(cam[0])

        let window = box(P(0.565, -0.092), P(0.948, 0.092))
        let pivot = polar(origin, 0.79, clock(10.9)), reach = clock(1)
        let arm = ribbon(arc(origin, 0.79, from: clock(10.9) - 2 * .pi, to: reach + 0.02), 0.07)
        let beak = [polar(origin, 0.82, reach - 0.055), polar(origin, 0.82, reach + 0.06), polar(origin, 0.47, reach + 0.035), polar(origin, 0.343, reach), polar(origin, 0.47, reach - 0.035), polar(origin, 0.82, reach - 0.055)]
        let dateWheel = P(-0.735, 0.0)
        var rings = wheel(&figures, dateWheel, 0.125, teeth: 12, spokes: 4, phase: 0.26)
        // The date ring: thirty-one teeth inside the rim, a day each.
        var ring: [P] = []
        for k in 0..<31 {
            let a = Double(k) * 2 * .pi / 31
            ring += [polar(origin, 0.925, a), polar(origin, 0.875, a + 0.5 * .pi / 31), polar(origin, 0.925, a + 1.4 * .pi / 31)]
        }
        ring.append(ring[0])
        rings += [cam, window, arm, beak, arc(pivot, 0.06)]
        plate.lines(hatch([ring] + rings, angle: 0.75, gap: 0.034), fine)
        plate.lines(hatch([Array(glass), ring], angle: -0.75, gap: 0.011), fine)
        plate.line(ring, medium)
        plate.marks += figures.marks

        // The cam: its face ruled, the years lettered, the fourth cross-hatched.
        plate.fill(cam)
        let years = (0..<4).map { start + Double($0) * .pi / 2 }
        let fourth = arc(origin, 0.3, from: years[3], to: years[3] + .pi / 2) + [origin]
        let labels = (0..<4).map { polar(origin, 0.232, years[$0] + .pi / 4) }
        plate.lines(hatch([arc(origin, 0.3)] + labels.map { arc($0, 0.062) }, angle: 0.2, gap: 0.024), fine)
        plate.lines(hatch([fourth, arc(labels[3], 0.062)], angle: 1.3, gap: 0.016), fine)
        for (k, label) in labels.enumerated() {
            plate.line(arc(label, 0.062), fine)
            plate.lines(numeral(roman(k + 1), at: label, height: 0.07, squeeze: 0.8), 0.009)
        }
        for year in years { plate.line([polar(origin, 0.05, year), polar(origin, 0.392, year)], medium) }
        for m in 0..<48 { plate.line([polar(origin, 0.3, start + Double(m) * step), polar(origin, min(depth(m), depth((m + 47) % 48)), start + Double(m) * step)], fine) }
        plate.line(arc(origin, 0.3), medium)
        plate.line(cam, heavy)

        // The feeler: its arm over the top, its beak in the notch.
        solid(&plate, arm, angle: 1.3, gap: 0.009)
        solid(&plate, beak, angle: 1.3, gap: 0.009)
        plate.fill(arc(pivot, 0.06))
        plate.line(arc(pivot, 0.06), heavy)
        plate.line(arc(pivot, 0.03), medium)
        plate.line([pivot + P(-0.02, 0.02), pivot + P(0.02, -0.02)], medium)

        // The date's window.
        plate.fill(window)
        plate.line(window, heavy)
        plate.line(box(P(0.585, -0.072), P(0.928, 0.072)), fine)
        plate.lines(numeral("XXIX", at: P(0.7565, 0), height: 0.098, squeeze: 0.86), 0.014, .second)

        callout(&plate, "A", from: polar(origin, 0.36, clock(7)), to: polar(origin, 0.66, clock(7)))
        callout(&plate, "B", from: polar(origin, 0.6, reach) + P(0.02, 0.012), to: polar(origin, 0.33, clock(3)) + P(0.03, -0.1))
        callout(&plate, "C", from: P(0.76, 0.092), to: P(0.74, 0.3))
        callout(&plate, "D", from: dateWheel + P(-0.03, -0.09), to: P(-0.7, -0.27))
        return plate
    }

    // MARK: 29 Eleventh hour

    /// Problem 29, hex: a one-handed dial as wide as the glass, every chapter clear of the rods, the hand on eleven.
    static func plate29() -> Plate {
        var plate = Plate()
        let pointer = hand(origin, toward: clock(11), length: 0.72, width: 0.06, spade: true, tail: 0.3)
        let counter = arc(polar(origin, 0.335, clock(5)), 0.06)
        let boss = (0...180).map { i -> P in
            let a = Double(i) * .pi / 90
            return polar(origin, 0.215 + 0.04 * cos(7 * a), a)
        }
        plate.lines(hatch([arc(origin, 0.705), boss, pointer, counter], angle: 0.5, gap: 0.034), fine)

        // The quarters inside the chapters, the minutes outside.
        for k in 0..<48 { plate.line([polar(origin, 0.705, Double(k) * .pi / 24), polar(origin, k % 4 == 0 ? 0.75 : 0.735, Double(k) * .pi / 24)], fine) }
        for k in 0..<60 { plate.line([polar(origin, 0.958, Double(k) * .pi / 30), polar(origin, 1.0, Double(k) * .pi / 30)], k % 5 == 0 ? medium : fine) }
        for r in [0.705, 0.735, 0.75, 0.958] { plate.line(arc(origin, r), r == 0.75 || r == 0.958 ? medium : fine) }
        for k in 1...12 {
            let a = clock(Double(k))
            plate.lines(numeral(roman(k), at: polar(origin, 0.854, a), height: 0.15, turn: a + .pi / 2, squeeze: 0.82), 0.016, k == 11 ? .second : .black)
            let half = polar(origin, 0.854, a + .pi / 12)
            plate.fill(turned([P(0, -0.05), P(0.022, 0), P(0, 0.05), P(-0.022, 0), P(0, -0.05)], by: a + .pi / 12 + .pi / 2).map { $0 + half }, .black)
        }

        // The hand: a boss of seven petals, the spade on eleven, its counterweight behind.
        solid(&plate, boss, angle: -0.9, gap: 0.012)
        solid(&plate, pointer, angle: 0.9, gap: 0.012)
        solid(&plate, counter, angle: 0.9, gap: 0.012)
        plate.line(arc(origin, 0.05), heavy)

        callout(&plate, "A", from: polar(origin, 0.5, clock(11)) + P(-0.03, 0.03), to: P(-0.335, -0.09))
        callout(&plate, "B", from: polar(origin, 0.74, clock(3)), to: polar(origin, 0.41, clock(3)))
        return plate
    }

    // MARK: 30 Midnight

    private static func spark(_ c: P, _ r: Double, turn: Double) -> [P] {
        (0...10).map { polar(c, $0 % 2 == 0 ? r : 0.42 * r, turn + .pi * Double($0) / 5) }
    }

    /// Problem 30, hex, the last: both hands on twelve, on the one line up the glass that no rod stands on. The dial's
    /// middle is engine-turned, rays stand for the ruled ground, and the night has a moon and twelve stars.
    static func plate30() -> Plate {
        var plate = Plate()
        let c = P(0.2425, 0.14), radius = 0.66, moon = P(-0.755, -0.02), moonRadius = 0.17
        let stars: [P] = [P(-0.3, -0.88), P(0.02, -0.9), P(0.31, -0.83), P(0.6, -0.69), P(-0.57, -0.66), P(-0.8, -0.4), P(-0.31, -0.55),
                          P(-0.92, 0.25), P(-0.72, 0.49), P(-0.5, 0.73), P(-0.21, 0.89), P(-0.44, 0.53)]
        let sparks = stars.enumerated().map { spark($1, 0.034 + 0.02 * rnd(30, $0), turn: rnd(30, 40 + $0)) }

        // The rays, broken round the moon and the stars.
        func clear(_ p: P) -> Bool {
            simd_length(p) < 1.06 && simd_distance(p, moon) > moonRadius + 0.025 && !stars.contains { simd_distance(p, $0) < 0.062 }
        }
        for k in 0..<300 {
            let a = Double(k) * .pi / 150, from = k % 2 == 0 ? radius + 0.03 : k % 4 == 1 ? 0.84 : 1.02
            var run: [P] = []
            for r in stride(from: from, through: 2.0, by: 0.012) {
                let p = polar(c, r, a)
                if clear(p) { run.append(p) } else {
                    if run.count > 1 { plate.line([run[0], run[run.count - 1]], fine) }
                    run = []
                }
            }
            if run.count > 1 { plate.line([run[0], run[run.count - 1]], fine) }
        }
        for s in sparks { plate.line(s, medium) }
        let crescent = arc(moon, moonRadius, from: 0.87, to: 2 * .pi - 0.87)
            + arc(moon + P(0.75 * moonRadius, 0), 0.773 * moonRadius, from: .pi + 1.436, to: .pi - 1.436)
        plate.lines(hatch([crescent], angle: 0.9, gap: 0.012), fine)
        plate.line(crescent + [crescent[0]], medium)

        // The dial: bezel, minutes, chapters, and its middle turned in waves.
        plate.fill(arc(c, radius))
        plate.lines(hatch([arc(c, radius), arc(c, 0.955 * radius)], angle: 0.9, gap: 0.009), fine)
        for k in 0..<60 { plate.line([polar(c, (k % 5 == 0 ? 0.885 : 0.91) * radius, Double(k) * .pi / 30), polar(c, 0.955 * radius, Double(k) * .pi / 30)], fine) }
        for k in 1...12 {
            let a = clock(Double(k))
            plate.lines(numeral(roman(k), at: polar(c, 0.77 * radius, a), height: 0.115, turn: a + .pi / 2, squeeze: 0.75), 0.012)
        }
        for j in 0..<13 {
            let wave = (0...240).map { i -> P in
                let a = Double(i) * .pi / 120
                return polar(c, 0.05 + 0.03 * Double(j) + 0.007 * sin(16 * a + Double(j) * .pi), a)
            }
            plate.line(wave, fine)
        }
        for r in [radius, 0.955 * radius, 0.66 * radius, 0.64 * radius] { plate.line(arc(c, r), r == radius ? heavy : medium) }

        // The hands, together.
        let hour = hand(c, toward: clock(0), length: 0.4, width: 0.06, spade: true, tail: 0.07)
        let minute = hand(c, toward: clock(0), length: 0.6, width: 0.055, tail: 0.12)
        solid(&plate, hour, angle: 0.9, gap: 0.011, ink: .second, edge: heavy)
        solid(&plate, minute, angle: -0.9, gap: 0.011, ink: .second, edge: heavy)
        plate.fill(arc(c, 0.045))
        plate.line(arc(c, 0.045), heavy)
        plate.line(arc(c, 0.015), medium)

        callout(&plate, "A", from: c + P(0.02, -0.5), to: P(0.42, -0.78))
        callout(&plate, "B", from: moon + P(-0.05, 0.14), to: P(-0.8, 0.26))
        return plate
    }
}
