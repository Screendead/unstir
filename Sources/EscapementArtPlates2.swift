// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Problems 11 to 20's plates, each composed round every rod of its layout: whichever rods are clocks, no knob or hub
/// (0.16 of the glass) sits on the part that names the plate.
extension EscapementArt {
    private static let deg = Double.pi / 180

    /// The ruled tint over the whole glass; figures are filled bone over it.
    private static func ruled(_ plate: inout Plate, angle: Double, gap: Double = 0.034) {
        plate.lines(hatch([Array(glass)], angle: angle, gap: gap), fine)
    }

    private static func bar(_ a: P, _ b: P, _ width: Double) -> [P] {
        let n = simd_normalize(P(-(b - a).y, (b - a).x)) * (width / 2)
        return [a + n, b + n, b - n, a - n, a + n]
    }

    /// A closed figure cut out of what lies under it and outlined.
    private static func cut(_ plate: inout Plate, _ ring: [P], _ width: Double = medium) {
        plate.fill(ring)
        plate.line(ring + [ring[0]], width)
    }

    private static func shaded(_ plate: inout Plate, _ ring: [P], angle: Double, gap: Double = 0.014, _ ink: Ink = .black,
                               outline: Double = medium) {
        plate.fill(ring)
        plate.lines(hatch([ring], angle: angle, gap: gap), fine, ink)
        plate.line(ring + [ring[0]], outline)
    }

    /// A Roman numeral centred on `c`, its head turned `turn` from upright and its width scaled by `squeeze`.
    private static func numeral(_ n: Int, at c: P, height: Double, turn: Double = 0, squeeze: Double = 1) -> [[P]] {
        let s = roman(n), width = s.reduce(0.0) { $0 + ($1 == "I" ? 0.62 : 0.86) * height } - 0.26 * height
        return text(s, at: P(-width / 2, -height / 2), height: height).map { stroke in
            turned(stroke.map { P($0.x * squeeze, $0.y) }, by: turn).map { $0 + c }
        }
    }

    /// Ticks across a ring about `c`: `count` to the turn from `from`, each from the radius `inner` gives its index.
    private static func ticks(_ c: P, count: Int, outer: Double, from a0: Double = -.pi / 2, sweep: Double = 2 * .pi,
                              inner: (Int) -> Double) -> [[P]] {
        (0..<count).map { k in
            let a = a0 + sweep * Double(k) / Double(count)
            return [polar(c, inner(k), a), polar(c, outer, a)]
        }
    }

    /// An arrowhead at `tip` flying along `heading`.
    private static func barb(_ tip: P, heading: Double, size: Double) -> [P] {
        [tip, polar(tip, size, heading + .pi - 0.42), polar(tip, 0.6 * size, heading + .pi), polar(tip, size, heading + .pi + 0.42), tip]
    }

    /// A polyline with its corners cut `rounds` times, its ends kept.
    private static func eased(_ points: [P], _ rounds: Int = 2) -> [P] {
        var pts = points
        for _ in 0..<rounds {
            var out = [pts[0]]
            for i in 0..<(pts.count - 1) { out += [0.75 * pts[i] + 0.25 * pts[i + 1], 0.25 * pts[i] + 0.75 * pts[i + 1]] }
            pts = out + [pts[pts.count - 1]]
        }
        return pts
    }

    /// A closed outline symmetric about an axis from `o` along `heading`: `profile` is (distance along, half-width).
    private static func blade(_ o: P, heading: Double, _ profile: [(Double, Double)]) -> [P] {
        let d = polar(P(0, 0), 1, heading), n = P(-d.y, d.x), half = eased(profile.map { P($0.0, $0.1) })
        return half.map { o + $0.x * d + $0.y * n } + half.reversed().map { o + $0.x * d - $0.y * n }
    }

    /// A path's two sides `width` apart, closed.
    private static func ribbon(_ points: [P], _ width: Double) -> [P] {
        var left: [P] = [], right: [P] = []
        for i in points.indices {
            let a = points[max(i - 1, 0)], b = points[min(i + 1, points.count - 1)]
            let n = simd_normalize(P(-(b - a).y, (b - a).x)) * (width / 2)
            left.append(points[i] + n)
            right.append(points[i] - n)
        }
        return left + right.reversed() + [left[0]]
    }

    /// A ribbon along a path ending in a barbed head `head` long.
    private static func arrow(_ points: [P], width: Double, head: Double) -> [P] {
        let tip = points[points.count - 1], back = simd_normalize(points[points.count - 2] - tip)
        let body = points.filter { simd_distance($0, tip) > head } + [tip + head * back]
        let n = P(-back.y, back.x) * (0.62 * head), sides = ribbon(body, width), m = body.count
        return Array(sides[0..<m]) + [tip + head * back - n, tip, tip + head * back + n] + Array(sides[m..<(2 * m)]) + [sides[0]]
    }

    /// Problem 11, pent: a pocket stopwatch leaning right, its crown and pusher between two rods and its dial's track
    /// outside all five, the sweep hand stopped in a gap and the minute counter under the crown.
    static func plate11() -> Plate {
        var plate = Plate()
        let lean = 36 * deg, at = -0.05 * P(sin(lean), -cos(lean)), o = P(0, 0)
        func place(_ points: [P]) -> [P] { turned(points, by: lean).map { 0.94 * $0 + at } }
        ruled(&plate, angle: 0.5)

        // The pendant and crown, and the pusher at its side, behind the case.
        shaded(&plate, place(turned(box(P(-0.04, -0.91), P(0.04, -0.76)), by: 45 * deg)), angle: lean + 45 * deg + .pi / 2, gap: 0.013)
        cut(&plate, place(box(P(-0.05, -0.88), P(0.05, -0.76))))
        shaded(&plate, place(box(P(-0.095, -0.985), P(0.095, -0.875))), angle: lean + .pi / 2, gap: 0.016, outline: heavy)

        // The case in section hatching and the dial inside it.
        let sub = P(0, -0.34)
        plate.fill(place(arc(o, 0.80)))
        plate.lines(hatch([place(arc(o, 0.80)), place(arc(o, 0.735))], angle: 0.95, gap: 0.014), fine)
        plate.line(place(arc(o, 0.80)), heavy)
        plate.line(place(arc(o, 0.735)), medium)
        plate.line(place(arc(o, 0.72)), fine)
        plate.line(place(arc(o, 0.64)), fine)
        plate.lines(hatch([place(arc(o, 0.64)), place(arc(sub, 0.15))], angle: -1.0, gap: 0.045).flatMap { dashed($0, on: 0.05, off: 0.025) }, fine)
        // Fifths of a second, seconds and fives.
        plate.lines(ticks(o, count: 300, outer: 0.72) { $0 % 5 == 0 ? 0.64 : 0.69 }.map(place), fine)
        plate.lines(ticks(o, count: 12, outer: 0.72) { _ in 0.60 }.map(place), heavy)
        plate.lines(dashed(place([P(0, -0.60), P(0, 0.60)]), on: 0.07, off: 0.02), fine)
        plate.lines(dashed(place([P(-0.60, 0), P(0.60, 0)]), on: 0.07, off: 0.02), fine)

        // The minute counter.
        cut(&plate, place(arc(sub, 0.15)))
        plate.line(place(arc(sub, 0.118)), fine)
        plate.lines(ticks(sub, count: 30, outer: 0.15) { $0 % 5 == 0 ? 0.095 : 0.118 }.map(place), fine)
        plate.line(place([sub, polar(sub, 0.105, -20 * deg)]), medium)
        cut(&plate, place(arc(sub, 0.016)))

        // The sweep hand, stopped, with its counterpoise.
        let d = polar(o, 1, 126 * deg), n = P(-d.y, d.x)
        let needle = [-0.2 * d + 0.009 * n, 0.018 * n, 0.69 * d + 0.004 * n, 0.69 * d - 0.004 * n, -0.018 * n, -0.2 * d - 0.009 * n]
        plate.fill(place(needle), .second)
        plate.fill(place(arc(-0.15 * d, 0.04)), .second)
        cut(&plate, place(arc(o, 0.042)))
        plate.line(place(arc(o, 0.014)), medium)

        callout(&plate, "A", from: place([P(0.095, -0.93)])[0], to: P(0.74, -0.47))
        callout(&plate, "B", from: place([sub + P(-0.1, 0.06)])[0], to: P(-0.12, -0.2))
        callout(&plate, "C", from: place([0.36 * d])[0], to: P(-0.1, 0.27))
        callout(&plate, "D", from: place([turned([P(0.04, -0.86)], by: 45 * deg)[0]])[0], to: P(0.85, 0.08))
        return plate
    }

    /// Problem 12, hex: a longcase clock run down. The pendulum hangs plumb on its centre line in one gap between the
    /// rods, the weight at the bottom of its fall in another, and a spider has spun its web from one to the other.
    static func plate12() -> Plate {
        var plate = Plate(), movement = Plate()
        let x = 0.2425, cord = -0.1975
        var rings = wheel(&movement, P(-0.2, -1.03), 0.2, teeth: 30, spokes: 4, phase: 0.2)
        rings += wheel(&movement, P(0.3, -1.05), 0.17, teeth: 24, spokes: 4, phase: 0.5)
        plate.lines(hatch([Array(glass)] + rings, angle: -0.45, gap: 0.034), fine)
        plate.marks += movement.marks

        // The case: its sides in section, and the seatboard the movement stands on.
        for side in [-1.0, 1.0] { shaded(&plate, box(P(side * 0.80, -0.7), P(side * 0.88, 0.7)), angle: side * 0.8, gap: 0.013, outline: heavy) }
        shaded(&plate, box(P(-0.62, -0.845), P(0.62, -0.775)), angle: 0.03, gap: 0.012, outline: heavy)

        // Webs, their spokes run out to whatever they reach: one hung between the weight's line and the pendulum, one
        // between the weight's line and the case.
        func web(_ hub: P, left: Double, right: Double, top: Double, floor: Double, seed: Int, turns: Int) {
            let count = 12
            let spokes: [(a: Double, reach: Double)] = (0..<count).map { k in
                let a = (Double(k) * 30 + 8 + 12 * rnd(seed, k)) * deg, c = cos(a), s = sin(a)
                return (a, min(((c > 0 ? right : left) - hub.x) / c, ((s > 0 ? floor : top) - hub.y) / s))
            }
            plate.line(curve(P(left, floor + 0.03), P(hub.x, floor - 0.035), P(right, floor - 0.02)), fine)
            plate.line(curve(P(left, top + 0.02), P(hub.x, top + 0.04), P(right, top - 0.03)), fine)
            for spoke in spokes { plate.line([hub, polar(hub, spoke.reach, spoke.a)], fine) }
            for j in 1...turns {
                let r = 0.026 + 0.021 * Double(j)
                for k in 0..<count where rnd(seed + 1, j * count + k) > 0.07 {
                    let p = spokes[k], q = spokes[(k + 1) % count], qa = q.a + (k == count - 1 ? 2 * .pi : 0)
                    guard r < p.reach, r < q.reach else { continue }
                    plate.line(curve(polar(hub, r, p.a), polar(hub, 0.9 * r, (p.a + qa) / 2), polar(hub, r, qa), 5), fine)
                }
            }
        }
        let hub = P(0, -0.28)
        web(hub, left: cord, right: x - 0.011, top: -0.775, floor: -0.085, seed: 12, turns: 15)
        web(P(-0.6, 0.0), left: -0.80, right: -x - 0.045, top: -0.2, floor: 0.2, seed: 31, turns: 8)
        // Threads hung in the case's corner.
        for (k, end) in [P(0.80, -0.42), P(0.80, -0.56), P(0.52, -0.775)].enumerated() {
            plate.line(curve(P(0.35 + 0.1 * Double(k), -0.775), P(0.56, -0.6 + 0.04 * Double(k)), end, 10), fine)
        }

        // The pendulum, plumb: suspension, rod, bob and rating nut on one centre line, the beat scale's zero under it.
        cut(&plate, box(P(x - 0.055, -0.775), P(x + 0.055, -0.725)))
        plate.line([P(x, -0.725), P(x, -0.66)], heavy)
        cut(&plate, bar(P(x, -0.66), P(x, 0.56), 0.022), fine)
        let bob = P(x, 0.655), radius = 0.135
        plate.fill(arc(bob, radius))
        plate.lines(hatch([arc(bob, radius)], angle: 0.8, gap: 0.016), fine)
        plate.lines(hatch([arc(bob, radius, from: -0.5, to: -0.5 + .pi)], angle: -0.75, gap: 0.022), fine)
        plate.line(arc(bob, radius), heavy)
        plate.line(arc(bob, radius - 0.03), fine)
        shaded(&plate, box(P(x - 0.045, 0.795), P(x + 0.045, 0.84)), angle: 0, gap: 0.011)
        plate.line([P(x, 0.84), P(x, 0.875)], medium)
        plate.lines(dashed([P(x, -0.97), P(x, -0.845)], on: 0.05, off: 0.025) + dashed([P(x, 0.875), P(x, 0.97)], on: 0.03, off: 0.015), fine)
        plate.line([P(x - 0.09, 0.9), P(x + 0.09, 0.9)], fine)
        for k in -4...4 { plate.line([P(x + 0.02 * Double(k), 0.9), P(x + 0.02 * Double(k), k == 0 ? 0.95 : 0.925)], k == 0 ? medium : fine) }

        // The weight at the bottom of its fall, on a doubled line round its pulley.
        let w = -x
        plate.lines([[P(cord, -0.775), P(cord, 0.42)], [P(2 * w - cord, -0.775), P(2 * w - cord, 0.42)]], fine)
        cut(&plate, arc(P(w, 0.42), 0.046))
        plate.line(arc(P(w, 0.42), 0.014), medium)
        plate.line([P(w, 0.466), P(w, 0.52)], heavy)
        let weight = box(P(w - 0.075, 0.52), P(w + 0.075, 0.83))
        plate.fill(weight)
        plate.lines(hatch([weight], angle: .pi / 2, gap: 0.017), fine)
        plate.lines(hatch([box(P(w + 0.02, 0.52), P(w + 0.075, 0.83))], angle: 0, gap: 0.014), fine)
        plate.line(weight, medium)
        plate.line(ellipse(P(w, 0.52), 0.075, 0.02), medium)
        plate.line(ellipse(P(w, 0.83), 0.075, 0.02, from: 0, to: .pi), medium)

        // The spider at the web's hub.
        for side in [-1.0, 1.0] {
            for i in 0..<4 {
                let a = (-58 + 38 * Double(i)) * deg
                plate.line([hub, hub + P(side * 0.05 * cos(a), 0.05 * sin(a) - 0.014), hub + P(side * 0.085 * cos(1.1 * a), 0.095 * sin(1.1 * a))], fine, .second)
            }
        }
        plate.fill(ellipse(hub + P(0, 0.02), 0.026, 0.032), .second)
        plate.fill(arc(hub + P(0, -0.02), 0.016), .second)

        callout(&plate, "A", from: bob + P(0.09, -0.06), to: P(0.55, 0.6))
        callout(&plate, "B", from: P(0.1, -0.37), to: P(0.5, -0.62))
        callout(&plate, "C", from: P(w - 0.075, 0.64), to: P(-0.56, 0.62))
        callout(&plate, "D", from: P(x + 0.011, 0.04), to: P(0.585, 0.0))
        return plate
    }

    /// Problem 13, quad: two dials the same, driven from one wheel between them by a rod from below. Each dial sits
    /// outside a pair of rods and the wheel inside all four.
    static func plate13() -> Plate {
        var plate = Plate(), works = Plate()
        let rings = wheel(&works, P(0, 0), 0.2, teeth: 28, spokes: 4, phase: 0.12, rimInk: .second)
        plate.lines(hatch([Array(glass)] + rings, angle: 0.6, gap: 0.034), fine)
        plate.marks += works.marks
        plate.lines(dashed([P(-1, 0), P(1, 0)], on: 0.07, off: 0.02) + dashed([P(0, -0.9), P(0, 0.2)], on: 0.07, off: 0.02), fine)

        // The rod from the movement below, its coupling and the pinions that take the turn out to each dial.
        cut(&plate, bar(P(0, 0.21), P(0, 1.02), 0.036), fine)
        shaded(&plate, box(P(-0.045, 0.56), P(0.045, 0.66)), angle: 0, gap: 0.012)
        shaded(&plate, [P(-0.03, 0.27), P(-0.07, 0.21), P(0.07, 0.21), P(0.03, 0.27)], angle: .pi / 2, gap: 0.012)
        for side in [-1.0, 1.0] {
            let c = P(side * 0.265, 0)
            shaded(&plate, gear(c, 0.062, teeth: 9, phase: 0.2), angle: 0.9, gap: 0.012)
            cut(&plate, arc(c, 0.022))
        }

        // The same in plan: the two dials edge on, back to back, and the box of bevels between them.
        cut(&plate, bar(P(-0.22, -0.62), P(0.22, -0.62), 0.022), fine)
        for side in [-1.0, 1.0] { shaded(&plate, box(P(side * 0.22, -0.73), P(side * 0.255, -0.51)), angle: side * 0.8, gap: 0.011, outline: heavy) }
        cut(&plate, box(P(-0.055, -0.675), P(0.055, -0.565)))
        plate.lines([[P(-0.055, -0.675), P(0.055, -0.565)], [P(0.055, -0.675), P(-0.055, -0.565)]], fine)
        cut(&plate, arc(P(0, -0.62), 0.022))

        let radius = 0.31
        for side in [-1.0, 1.0] {
            let c = P(side * 0.66, 0)
            plate.fill(arc(c, radius))
            plate.lines(hatch([arc(c, radius), arc(c, 0.285)], angle: side * 0.9, gap: 0.012), fine)
            plate.line(arc(c, radius), heavy)
            plate.line(arc(c, 0.285), medium)
            plate.lines([arc(c, 0.27), arc(c, 0.253), arc(c, 0.158)], fine)
            plate.lines(ticks(c, count: 60, outer: 0.27) { $0 % 5 == 0 ? 0.243 : 0.253 }, fine)
            for h in 1...12 {
                let a = Double(h) * 30 * deg - .pi / 2
                plate.lines(numeral(h, at: polar(c, 0.205, a), height: 0.056, turn: a + .pi / 2, squeeze: 0.55), fine)
            }
            plate.lines(hatch([arc(c, 0.158)], angle: -1.0, gap: 0.032).flatMap { dashed($0, on: 0.04, off: 0.02) }, fine)
            // Nine minutes past ten on both.
            plate.fill(blade(c, heading: 214.5 * deg, [(-0.035, 0), (-0.02, 0.012), (0.06, 0.012), (0.085, 0.03), (0.11, 0.022), (0.15, 0)]), .black)
            plate.fill(blade(c, heading: -36 * deg, [(-0.045, 0), (-0.03, 0.009), (0.12, 0.008), (0.16, 0.02), (0.2, 0.012), (0.25, 0)]), .black)
            cut(&plate, arc(c, 0.02))
        }

        callout(&plate, "A", from: P(-0.62, -0.3), to: P(-0.6, -0.4))
        callout(&plate, "B", from: P(0.62, 0.3), to: P(0.6, 0.4))
        callout(&plate, "C", from: P(-0.09, 0.12), to: P(-0.13, 0.4))
        callout(&plate, "D", from: P(0.018, 0.78), to: P(0.17, 0.66))
        return plate
    }

    /// The chapter ring's band about `o` between two radii and two headings, cut out of the tint.
    private static func band(_ plate: inout Plate, _ o: P, _ inner: Double, _ outer: Double, from a: Double, to b: Double) {
        plate.fill(arc(o, outer, from: a, to: b) + arc(o, inner, from: b, to: a))
        plate.line(arc(o, outer, from: a, to: b), medium)
        plate.line(arc(o, inner, from: a, to: b), medium)
    }

    /// Problem 14, quad: the hour hand, a spade, from its boss at the foot of the plate up between the rods to twelve,
    /// with the minute hand in outline only.
    static func plate14() -> Plate {
        var plate = Plate(), works = Plate()
        let o = P(0, 0.78), up = -Double.pi / 2
        let rings = wheel(&works, o, 0.3, teeth: 40, spokes: 4, phase: 0.2)
        plate.lines(hatch([Array(glass)] + rings, angle: 0.4, gap: 0.034), fine)
        plate.marks += works.marks

        // The dial: hours in the chapter ring, the minutes outside it.
        band(&plate, o, 1.38, 1.62, from: up - 0.9, to: up + 0.9)
        plate.line(arc(o, 1.355, from: up - 0.9, to: up + 0.9), fine)
        plate.line(arc(o, 1.66, from: up - 0.9, to: up + 0.9), fine)
        for h in [11, 12, 1] {
            let a = up + Double(h) * 30 * deg
            plate.lines(numeral(h, at: polar(o, 1.5, a), height: 0.15, turn: a - up, squeeze: 0.7), heavy)
        }
        for r in [0.5, 0.52] { plate.line(arc(o, r), fine) }
        plate.lines(dashed([o + P(0, 0.2), P(0, -0.98)], on: 0.07, off: 0.02), fine)

        // The minute hand, four and a half minutes on, in outline.
        let minute = blade(o, heading: up + 27 * deg, [(-0.2, 0), (-0.17, 0.03), (0, 0.035), (0.9, 0.022), (1.2, 0.02), (1.24, 0.05), (1.32, 0.075), (1.44, 0.045), (1.58, 0.008), (1.6, 0)])
        plate.lines(dashed(minute + [minute[0]], on: 0.035, off: 0.022), fine)

        // The hour hand: stem, then the spade in the second ink.
        let stem = blade(o, heading: up, [(-0.17, 0), (-0.15, 0.03), (-0.06, 0.04), (0, 0.05), (0.3, 0.036), (0.8, 0.024), (0.88, 0.022)])
        let spade = blade(o, heading: up, [(0.88, 0.022), (0.9, 0.07), (0.96, 0.14), (1.05, 0.155), (1.15, 0.12), (1.25, 0.06), (1.34, 0.014), (1.36, 0)])
        shaded(&plate, stem, angle: 0.5, gap: 0.012)
        plate.fill(spade)
        plate.lines(hatch([spade], angle: 0.75, gap: 0.014), fine, .second)
        plate.line(spade + [spade[0]], heavy)
        plate.line([o + P(0, -0.93), o + P(0, -1.3)], fine)
        plate.fill(arc(o, 0.11))
        plate.lines(hatch([arc(o, 0.11), arc(o, 0.07)], angle: -0.6, gap: 0.012), fine)
        plate.line(arc(o, 0.11), heavy)
        plate.line(arc(o, 0.07), fine)
        plate.line(turned(box(P(-0.03, -0.03), P(0.03, 0.03)), by: 0.3).map { $0 + o }, medium)

        callout(&plate, "A", from: P(0.1, -0.24), to: P(0.5, -0.03))
        callout(&plate, "B", from: P(-0.03, 0.3), to: P(-0.5, 0.02))
        callout(&plate, "C", from: o + P(0.09, -0.04), to: P(0.4, 0.72))
        return plate
    }

    /// Problem 15, pent: the minute hand, long and slight, from its boss at the foot of the plate between the rods to
    /// the minute track at three minutes past, the hour hand in outline beside it.
    static func plate15() -> Plate {
        var plate = Plate(), works = Plate()
        let o = P(0, 0.80), up = -Double.pi / 2, heading = up + 18 * deg
        let rings = wheel(&works, o + P(0.335, 0), 0.2, teeth: 30, spokes: 4, phase: 0.35)
        plate.lines(hatch([Array(glass)] + rings, angle: -0.4, gap: 0.034), fine)
        plate.marks += works.marks

        // The minute track, every minute cut and the fives across it.
        band(&plate, o, 1.54, 1.70, from: up - 0.8, to: up + 0.8)
        plate.line(arc(o, 1.585, from: up - 0.8, to: up + 0.8), fine)
        plate.lines(ticks(o, count: 60, outer: 1.70) { _ in 1.585 }, fine)
        plate.lines(ticks(o, count: 12, outer: 1.70) { _ in 1.54 }, heavy)
        plate.line(arc(o, 1.505, from: up - 0.8, to: up + 0.8), fine)
        for r in [0.5, 0.52] { plate.line(arc(o, r), fine) }

        // The hour hand in outline, then the minute hand over it, its lance in the second ink.
        let hour = blade(o, heading: up + 1.5 * deg, [(-0.17, 0), (-0.15, 0.03), (0, 0.05), (0.72, 0.024), (0.76, 0.07), (0.82, 0.135), (0.9, 0.14), (1.0, 0.1), (1.1, 0.045), (1.18, 0.012), (1.2, 0)])
        plate.lines(dashed(hour + [hour[0]], on: 0.035, off: 0.022), fine)
        plate.lines(dashed([o, polar(o, 1.76, heading)], on: 0.07, off: 0.02), fine)
        let stem = blade(o, heading: heading, [(-0.22, 0), (-0.2, 0.035), (-0.1, 0.04), (0, 0.04), (0.5, 0.03), (1.0, 0.021), (1.14, 0.019)])
        let lance = blade(o, heading: heading, [(1.14, 0.019), (1.16, 0.045), (1.23, 0.08), (1.33, 0.072), (1.45, 0.04), (1.57, 0.012), (1.63, 0)])
        shaded(&plate, stem, angle: heading + 0.5, gap: 0.012)
        plate.fill(lance)
        plate.lines(hatch([lance], angle: heading - 0.8, gap: 0.014), fine, .second)
        plate.line(lance + [lance[0]], heavy)
        shaded(&plate, gear(o, 0.125, teeth: 18, phase: 0.1), angle: 0.9, gap: 0.013)
        cut(&plate, arc(o, 0.085), heavy)
        plate.line(arc(o, 0.055), fine)
        plate.line(turned(box(P(-0.024, -0.024), P(0.024, 0.024)), by: 0.3).map { $0 + o }, medium)

        callout(&plate, "A", from: polar(o, 0.62, heading) + P(0.02, 0.005), to: P(0.62, 0.18))
        callout(&plate, "B", from: P(-0.1, -0.08), to: P(-0.5, 0.12))
        callout(&plate, "C", from: P(-0.35, -0.745), to: P(-0.3, -0.44))
        callout(&plate, "D", from: o + P(0.3, -0.1), to: P(0.62, 0.55))
        return plate
    }

    /// Problem 16, hex: a metronome with its door off, its pendulum in the gap between two columns of rods, a few
    /// degrees into its beat, with the ends of the swing in outline and the weight in the second ink.
    static func plate16() -> Plate {
        var plate = Plate()
        let ax = -0.2425, top = -0.87, base = 0.70
        func half(_ y: Double) -> Double { 0.10 + 0.32 * (y - top) / (base - top) }
        ruled(&plate, angle: 0.55)

        // The case: feet, cap, and the walls in section.
        for side in [-1.0, 1.0] { shaded(&plate, box(P(ax + side * 0.33 - 0.05, base), P(ax + side * 0.33 + 0.05, base + 0.045)), angle: 0.8, gap: 0.011) }
        shaded(&plate, box(P(ax - 0.07, top - 0.05), P(ax + 0.07, top)), angle: 0, gap: 0.011)
        let outer = [P(ax - half(top), top), P(ax + half(top), top), P(ax + half(base), base), P(ax - half(base), base)]
        let inner = [P(ax - half(top) + 0.03, top + 0.04), P(ax + half(top) - 0.03, top + 0.04),
                     P(ax + half(base) - 0.05, base - 0.04), P(ax - half(base) + 0.05, base - 0.04)]
        plate.fill(outer)
        plate.lines(hatch([outer, inner], angle: 0.85, gap: 0.013), fine)
        plate.line(outer + [outer[0]], heavy)
        plate.line(inner + [inner[0]], medium)
        plate.lines(hatch([inner], angle: -1.0, gap: 0.045).flatMap { dashed($0, on: 0.05, off: 0.025) }, fine)

        // The works under the shelf: escape wheel, the wheel that drives it and the key at the side.
        shaded(&plate, box(P(ax - half(0.27) + 0.045, 0.27), P(ax + half(0.27) - 0.045, 0.3)), angle: 0, gap: 0.01)
        let escape = P(ax + 0.02, 0.5), driver = P(ax - 0.165, 0.52)
        cut(&plate, gear(driver, 0.085, teeth: 14, phase: 0.2))
        plate.lines(hatch([arc(driver, 0.06), arc(driver, 0.025)], angle: 0.6, gap: 0.012), fine)
        plate.lines([arc(driver, 0.06), arc(driver, 0.025)], fine)
        cut(&plate, escapeWheel(escape, 0.1, teeth: 15, phase: 0.1))
        plate.lines([arc(escape, 0.07), arc(escape, 0.02)], fine)
        plate.lines(hatch([arc(escape, 0.07), arc(escape, 0.02)], angle: -0.6, gap: 0.014), fine)
        let keyAt = P(ax - half(0.5), 0.5)
        cut(&plate, bar(keyAt, keyAt + P(-0.08, 0), 0.024), fine)
        shaded(&plate, ellipse(keyAt + P(-0.12, 0), 0.04, 0.075), angle: 0.8, gap: 0.012)
        plate.line(ellipse(keyAt + P(-0.12, 0), 0.018, 0.045), fine)

        // The scale behind the pendulum.
        func scale(_ y: Double) -> Double { 0.045 + 0.02 * (y + 0.78) }
        let plateTop = -0.78, plateFoot = 0.2
        cut(&plate, [P(ax - scale(plateTop), plateTop), P(ax + scale(plateTop), plateTop), P(ax + scale(plateFoot), plateFoot), P(ax - scale(plateFoot), plateFoot)], fine)
        for (k, y) in stride(from: plateTop + 0.02, to: plateFoot, by: 0.024).enumerated() {
            let reach = k % 4 == 0 ? 0.03 : 0.016
            plate.lines([[P(ax - scale(y), y), P(ax - scale(y) + reach, y)], [P(ax + scale(y), y), P(ax + scale(y) - reach, y)]], fine)
        }

        // The pendulum on its pivot: the ends of its swing in outline, then the rod and its sliding weight.
        let pivot = P(ax, 0.235)
        func swung(_ points: [P], _ a: Double) -> [P] { turned(points, by: a, about: pivot) }
        let rod = bar(pivot + P(0, 0.03), pivot + P(0, -1.03), 0.016)
        let weight = [P(-0.075, -0.675), P(0.075, -0.675), P(0.052, -0.565), P(-0.052, -0.565), P(-0.075, -0.675)].map { $0 + pivot }
        for a in [-24 * deg, 24 * deg] {
            plate.lines(dashed(swung([pivot, pivot + P(0, -1.03)], a), on: 0.03, off: 0.03), fine)
            plate.lines(dashed(swung(weight, a), on: 0.03, off: 0.02), fine)
        }
        plate.lines(dashed(arc(pivot, 1.03, from: -.pi / 2 - 24 * deg, to: -.pi / 2 + 24 * deg), on: 0.02, off: 0.03), fine)
        let beat = 4 * deg
        cut(&plate, swung(rod, beat), fine)
        plate.fill(swung(weight, beat))
        plate.lines(hatch([swung(weight, beat)], angle: beat + 0.8, gap: 0.013), fine, .second)
        plate.line(swung(weight, beat), heavy)
        cut(&plate, arc(pivot, 0.03))
        plate.line(arc(pivot, 0.011), medium)

        callout(&plate, "A", from: swung([pivot + P(0.06, -0.62)], beat)[0], to: P(0.15, -0.31))
        callout(&plate, "B", from: P(ax - 0.05, 0.0), to: P(-0.59, 0.0))
        callout(&plate, "C", from: pivot + P(0.025, 0.005), to: P(0.16, 0.27))
        callout(&plate, "D", from: swung([pivot + P(0.075, -0.64)], 24 * deg)[0], to: P(0.42, -0.62))
        return plate
    }

    /// Problem 17, pent: a clock's bell on its standard inside the ring of rods, the smaller bells of the nest in
    /// outline within it, the hammer drawn back in one gap between rods and the sound going out through two more.
    static func plate17() -> Plate {
        var plate = Plate()
        ruled(&plate, angle: -0.5)
        let profile = eased([P(0, -0.33), P(0.07, -0.33), P(0.115, -0.3), P(0.135, -0.22), P(0.155, -0.08), P(0.185, 0.05), P(0.24, 0.16),
                             P(0.32, 0.23), P(0.375, 0.265), P(0.37, 0.3)])
        func width(_ y: Double) -> Double {
            guard let i = profile.indices.dropLast().first(where: { profile[$0].y <= y && y <= profile[$0 + 1].y && profile[$0 + 1].y > profile[$0].y }) else { return 0.37 }
            let a = profile[i], b = profile[i + 1]
            return a.x + (b.x - a.x) * (y - a.y) / (b.y - a.y)
        }

        // The standard, from its foot at the edge of the plate to the nut on the bell's crown.
        let arm = eased([P(0, -0.33), P(-0.02, -0.4), P(-0.16, -0.41), P(-0.33, -0.47), P(-0.52, -0.66)], 3)
        shaded(&plate, turned(box(P(-0.09, -0.055), P(0.09, 0.055)), by: 0.8).map { $0 + P(-0.56, -0.7) }, angle: 0.2, gap: 0.012, outline: heavy)
        shaded(&plate, ribbon(arm, 0.04), angle: 1.2, gap: 0.012)
        shaded(&plate, box(P(-0.04, -0.375), P(0.04, -0.33)), angle: .pi / 2, gap: 0.011)

        // The bell: turned bands, the shaded side, and the nest's smaller bells in outline.
        let mouth = ellipse(P(0, 0.3), 0.37, 0.045, from: 0, to: .pi)
        let outline = profile + mouth + profile.reversed().map { P(-$0.x, $0.y) }
        plate.fill(outline)
        let shade = profile + profile.reversed().map { P(0.55 * $0.x, $0.y) }
        plate.lines(hatch([shade], angle: 1.0, gap: 0.014), fine)
        plate.lines(hatch([profile.map { P(-$0.x, $0.y) } + profile.reversed().map { P(-0.82 * $0.x, $0.y) }], angle: 1.0, gap: 0.02), fine)
        for y in [-0.27, -0.25, -0.05, 0.13, 0.15, 0.235] { plate.line(ellipse(P(0, y), width(y), 0.022, from: 0, to: .pi), fine) }
        for scale in [0.74, 0.5] {
            let small = (profile + mouth + profile.reversed().map { P(-$0.x, $0.y) }).map { P($0.x * scale, -0.3 + ($0.y + 0.3) * scale + 0.04) }
            plate.lines(dashed(small, on: 0.03, off: 0.02), fine)
        }
        plate.line(ellipse(P(0, 0.3), 0.37, 0.045, from: .pi, to: 2 * .pi), fine)
        plate.line(outline + [outline[0]], heavy)
        plate.lines(dashed([P(0, -0.3), P(0, 0.44)], on: 0.07, off: 0.02), fine)

        // The hammer, about to fall on the sound bow.
        let pivot = P(-0.87, 0.125), head = P(-0.475, 0.212)
        plate.line(curve(P(-0.93, 0.3), P(-0.78, 0.3), P(-0.62, 0.2)), medium)
        cut(&plate, bar(pivot, head, 0.024), fine)
        let block = turned(box(P(-0.04, -0.07), P(0.04, 0.07)), by: 0.21).map { $0 + head }
        plate.fill(block)
        plate.lines(hatch([block], angle: 0.21, gap: 0.012), fine, .second)
        plate.line(block, heavy)
        cut(&plate, arc(pivot, 0.035))
        plate.line(arc(pivot, 0.012), medium)
        for a in [-0.35, 0.0, 0.35] { plate.line([polar(P(-0.4, 0.25), 0.035, .pi + a), polar(P(-0.4, 0.25), 0.065, .pi + a)], fine) }

        // The sound, out through the gap to the right.
        for (k, r) in [0.48, 0.55, 0.62, 0.69].enumerated() {
            let reach = (13.0 - 1.5 * Double(k)) * deg
            plate.line(arc(P(0, 0.02), r, from: 18 * deg - reach, to: 18 * deg + reach), k < 2 ? medium : fine)
        }

        // The pin barrel that lifts the hammers' tails in their order, a track of pins to a bell, and its wheel edge on.
        cut(&plate, bar(P(-0.36, 0.735), P(0.36, 0.735), 0.03), fine)
        let barrel = box(P(-0.25, 0.64), P(0.25, 0.83))
        plate.fill(barrel)
        plate.lines(hatch([box(P(-0.25, 0.775), P(0.25, 0.83))], angle: 0, gap: 0.011) + hatch([box(P(-0.25, 0.64), P(0.25, 0.662))], angle: 0, gap: 0.011), fine)
        plate.line(barrel, heavy)
        for track in 0..<8 {
            let x = -0.21 + 0.06 * Double(track)
            plate.lines(dashed([P(x, 0.64), P(x, 0.83)], on: 0.012, off: 0.03), fine)
            for pin in 0..<3 { plate.line(arc(P(x, 0.66 + 0.15 * rnd(17, 3 * track + pin)), 0.008), heavy) }
        }
        shaded(&plate, box(P(0.27, 0.655), P(0.305, 0.815)), angle: 0, gap: 0.016, outline: heavy)

        callout(&plate, "A", from: P(0.17, -0.06), to: P(0.3, -0.42))
        callout(&plate, "B", from: head + P(-0.01, 0.07), to: P(-0.58, 0.44))
        callout(&plate, "C", from: P(-0.3, -0.465), to: P(-0.22, -0.72))
        return plate
    }

    private static let mapleHalf: [(Double, Double)] = [
        (0, -1), (0.1, -0.74), (0.26, -0.82), (0.22, -0.52), (0.52, -0.66), (0.44, -0.44), (0.86, -0.42), (0.62, -0.22), (0.7, -0.08),
        (0.36, -0.02), (0.5, 0.22), (0.2, 0.14), (0.06, 0.3), (0, 0.26),
    ]

    /// A maple leaf `size` from stalk to tip, its tip turned `turn` from up, hatched and veined in `ink`.
    private static func leaf(_ plate: inout Plate, at c: P, size: Double, turn: Double, _ ink: Ink = .black) {
        func place(_ points: [P]) -> [P] { turned(points.map { $0 * size }, by: turn).map { $0 + c } }
        let right = mapleHalf.map { P($0.0, $0.1) }, outline = place(right + right.reversed().map { P(-$0.x, $0.y) })
        plate.fill(outline)
        plate.lines(hatch([outline], angle: turn + 0.7, gap: 0.016), fine, ink)
        for tip in [P(0, -1), P(0.86, -0.42), P(-0.86, -0.42), P(0.5, 0.22), P(-0.5, 0.22)] { plate.line(place([P(0, 0.26), 0.92 * tip]), fine, ink) }
        plate.line(outline + [outline[0]], medium)
        plate.line(place(curve(P(0, 0.26), P(0, 0.5), P(0.1, 0.7), 6)), medium)
    }

    /// Problem 18, hex: a cuckoo clock hung in the gap between two columns of rods, its door, dial, pendulum and cones
    /// each between them, the bird drawn large beside it in the second ink, and the two pipes that give its call.
    static func plate18() -> Plate {
        var plate = Plate()
        let ax = 0.2425
        ruled(&plate, angle: 0.5)

        // The call: a bellows over each pipe, one longer than the other.
        for (x, top, foot) in [(-0.66, -0.02, 0.52), (-0.24, 0.26, 0.7)] {
            let pipe = box(P(x - 0.035, top), P(x + 0.035, foot))
            shaded(&plate, pipe, angle: .pi / 2, gap: 0.014)
            cut(&plate, box(P(x - 0.035, top + 0.07), P(x + 0.035, top + 0.095)), fine)
            let bellows = [P(x - 0.075, top), P(x + 0.075, top), P(x + 0.075, top - 0.025), P(x - 0.075, top - 0.11)]
            cut(&plate, bellows)
            for k in 1...3 { plate.line([P(x + 0.075, top - 0.006 * Double(k)), P(x - 0.075, top - 0.028 * Double(k))], fine) }
        }

        // Chains and cones, the pendulum and its leaf.
        for (x, y) in [(0.11, 0.83), (0.375, 0.62)] {
            plate.lines(dashed([P(x, 0.4), P(x, y - 0.085)], on: 0.018, off: 0.01), heavy)
            let cone = ellipse(P(x, y), 0.048, 0.088)
            plate.fill(cone)
            plate.lines(hatch([cone], angle: 0.9, gap: 0.02) + hatch([cone], angle: -0.9, gap: 0.02), fine)
            plate.line(cone, medium)
        }
        cut(&plate, bar(P(ax, 0.4), P(ax, 0.6), 0.014), fine)
        leaf(&plate, at: P(ax, 0.655), size: 0.085, turn: .pi)

        // The case: boards, gable and roof.
        let body = box(P(ax - 0.36, -0.52), P(ax + 0.36, 0.4)), gable = [P(ax - 0.36, -0.52), P(ax, -0.84), P(ax + 0.36, -0.52)]
        plate.fill(body)
        plate.lines(hatch([body], angle: .pi / 2, gap: 0.06), fine)
        plate.line(body, heavy)
        plate.fill(gable)
        plate.lines(hatch([gable], angle: 0, gap: 0.04), fine)
        plate.line(gable + [gable[0]], medium)
        for side in [-1.0, 1.0] {
            let board = bar(P(ax, -0.9), P(ax + side * 0.5, -0.48), 0.075)
            shaded(&plate, board, angle: side * 0.7 + .pi / 2, gap: 0.028, outline: heavy)
        }
        shaded(&plate, box(P(ax - 0.4, 0.4), P(ax + 0.4, 0.435)), angle: 0.8, gap: 0.011)

        // The door under the gable, the bird at it, and the ring that sends the eye to it drawn large.
        let door = [P(ax - 0.065, -0.44), P(ax - 0.065, -0.56)] + arc(P(ax, -0.56), 0.065, from: .pi, to: 2 * .pi) + [P(ax + 0.065, -0.44)]
        plate.fill(door)
        plate.lines(hatch([door], angle: 0.8, gap: 0.009) + hatch([door], angle: -0.8, gap: 0.009), fine)
        plate.line(door + [door[0]], medium)
        plate.fill(arc(P(ax + 0.01, -0.5), 0.03), .second)
        plate.fill([P(ax + 0.03, -0.515), P(ax + 0.085, -0.5), P(ax + 0.03, -0.49)], .second)
        plate.line([P(ax - 0.065, -0.44), P(ax + 0.1, -0.44)], heavy)

        // The dial, at three.
        let dial = P(ax, -0.02)
        cut(&plate, arc(dial, 0.17), heavy)
        plate.lines([arc(dial, 0.155), arc(dial, 0.115)], fine)
        plate.lines(ticks(dial, count: 12, outer: 0.155) { _ in 0.115 }, medium)
        plate.fill(blade(dial, heading: -.pi / 2, [(-0.03, 0), (-0.02, 0.01), (0.07, 0.012), (0.1, 0.02), (0.135, 0)]), .black)
        plate.fill(blade(dial, heading: 0, [(-0.03, 0), (-0.02, 0.012), (0.04, 0.014), (0.065, 0.026), (0.095, 0)]), .black)
        cut(&plate, arc(dial, 0.016))

        // The bird, large: on its perch at the open door, calling.
        let at = P(-0.46, -0.66), ring = arc(at, 0.25)
        plate.line(arc(P(ax, -0.5), 0.105), fine)
        plate.line([P(ax, -0.5) + 0.105 * simd_normalize(at - P(ax, -0.5)), at + 0.25 * simd_normalize(P(ax, -0.5) - at)], fine)
        plate.fill(ring)
        plate.lines(hatch([ring], angle: -1.0, gap: 0.045).flatMap { dashed($0, on: 0.05, off: 0.025) }, fine)
        func bird(_ points: [P]) -> [P] { points.map { $0 + at } }
        shaded(&plate, bird(box(P(-0.24, 0.11), P(0.05, 0.135))), angle: 0, gap: 0.01)
        plate.lines([bird([P(-0.06, 0.07), P(-0.07, 0.11)]), bird([P(-0.01, 0.075), P(-0.015, 0.11)])], medium)
        let tail = bird([P(-0.1, 0.0), P(-0.225, -0.035), P(-0.215, 0.03), P(-0.1, 0.07)])
        let body2 = bird(ellipse(P(-0.035, 0.015), 0.115, 0.068, turned: -0.35))
        let head = bird(arc(P(0.075, -0.07), 0.052))
        for part in [tail, body2, head] {
            plate.fill(part)
            plate.lines(hatch([part], angle: 0.6, gap: 0.013), fine, .second)
            plate.line(part + [part[0]], medium)
        }
        plate.lines([bird(ellipse(P(-0.05, 0.02), 0.075, 0.035, from: -0.4, to: 3.4, turned: -0.3)), bird([P(-0.11, 0.035), P(-0.02, 0.0)]),
                     bird([P(-0.1, 0.05), P(-0.01, 0.02)])], medium)
        for beak in [[P(0.118, -0.095), P(0.205, -0.1), P(0.125, -0.07)], [P(0.122, -0.06), P(0.19, -0.035), P(0.11, -0.04)]] {
            cut(&plate, bird(beak))
        }
        plate.fill(bird(arc(P(0.085, -0.082), 0.009)), .black)
        for r in [0.045, 0.075] { plate.line(arc(at + P(0.17, -0.07), r, from: -0.6, to: 0.5), fine) }
        plate.line(ring, heavy)

        callout(&plate, "A", from: P(-0.66, 0.5), to: P(-0.6, 0.62))
        callout(&plate, "B", from: P(0.423, 0.62), to: P(0.6, 0.6))
        callout(&plate, "C", from: P(ax + 0.36, -0.6), to: P(0.72, -0.31))
        return plate
    }

    /// A ratchet's outline that turns anticlockwise only: each tooth a long rise and a sheer fall.
    private static func ratchet(_ c: P, root: Double, tip: Double, teeth: Int, phase: Double) -> [P] {
        let tau = 2 * Double.pi / Double(teeth)
        let out = (0..<teeth).flatMap { k in [polar(c, root, phase + Double(k) * tau), polar(c, tip, phase + (Double(k) + 0.94) * tau)] }
        return out + [out[0]]
    }

    /// Problem 19, tri: winding back up. The crank on the barrel's square turned anticlockwise, the ratchet and click
    /// that let it, the great wheel they ride on, and the weight coming up on its line.
    static func plate19() -> Plate {
        var plate = Plate(), works = Plate()
        let o = P(0, 0)
        let rings = wheel(&works, o, 0.6, teeth: 64, spokes: 4, phase: 0.55)
        plate.lines(hatch([Array(glass)] + rings, angle: 0.5, gap: 0.034), fine)

        // The weight on its line, behind the wheel, and the way it is going.
        plate.line([P(0.19, 0), P(0.19, 0.66)], medium)
        let weight = box(P(0.115, 0.66), P(0.265, 0.9))
        plate.fill(weight)
        plate.lines(hatch([weight], angle: .pi / 2, gap: 0.017), fine)
        plate.lines(hatch([box(P(0.21, 0.66), P(0.265, 0.9))], angle: 0, gap: 0.014), fine)
        plate.line(weight, medium)
        plate.line(ellipse(P(0.19, 0.66), 0.075, 0.02), medium)
        plate.fill(arrow([P(0.02, 0.9), P(0.02, 0.68)], width: 0.022, head: 0.07), .black)
        plate.fill(arc(o, 0.6))
        plate.lines(hatch(Array(rings.dropFirst()), angle: 0.5, gap: 0.034), fine)
        plate.marks += works.marks

        // The ratchet on the barrel's arbor, the click that holds it and the click's spring.
        let teeth = ratchet(o, root: 0.2, tip: 0.25, teeth: 16, phase: -70 * deg)
        plate.fill(teeth)
        plate.lines(hatch([teeth, arc(o, 0.13)], angle: 0.5, gap: 0.013), fine)
        plate.line(teeth, medium)
        plate.line(arc(o, 0.13), fine)
        let stud = P(0.346, -0.2), nose = polar(o, 0.207, -67 * deg)
        plate.line(curve(P(0.52, -0.02), P(0.56, -0.34), P(0.21, -0.245)), medium)
        cut(&plate, arc(P(0.52, -0.02), 0.022))
        let click = blade(stud, heading: atan2(nose.y - stud.y, nose.x - stud.x), [(-0.04, 0), (-0.03, 0.03), (0.02, 0.036), (0.2, 0.02), (simd_distance(stud, nose), 0.004)])
        shaded(&plate, click, angle: 1.2, gap: 0.011, outline: heavy)
        plate.line(arc(stud, 0.014), medium)

        // The crank: where it was a moment ago in outline, then the arm and its handle, and the turn it is given.
        let arm: [(Double, Double)] = [(-0.08, 0), (-0.07, 0.05), (0, 0.062), (0.3, 0.042), (0.58, 0.034), (0.66, 0.05), (0.72, 0.035), (0.735, 0)]
        let was = blade(o, heading: 240 * deg, arm)
        plate.lines(dashed(was + [was[0]], on: 0.035, off: 0.022), fine)
        plate.lines(dashed(arc(polar(o, 0.66, 240 * deg), 0.07), on: 0.03, off: 0.02), fine)
        shaded(&plate, blade(o, heading: 205 * deg, arm), angle: 205 * deg + 0.6, gap: 0.013, outline: heavy)
        cut(&plate, arc(o, 0.075), heavy)
        plate.line(turned(box(P(-0.034, -0.034), P(0.034, 0.034)), by: 0.3), medium)
        let grip = arc(polar(o, 0.66, 205 * deg), 0.072)
        plate.fill(grip)
        plate.lines(hatch([grip, arc(polar(o, 0.66, 205 * deg), 0.03)], angle: 0.8, gap: 0.012), fine, .second)
        plate.line(grip, heavy)
        plate.line(arc(polar(o, 0.66, 205 * deg), 0.03), medium)
        let turn = arrow(arc(o, 0.86, from: 192 * deg, to: 118 * deg), width: 0.05, head: 0.14)
        shaded(&plate, turn, angle: 0.2, gap: 0.011, outline: heavy)

        callout(&plate, "A", from: polar(o, 0.66, 205 * deg) + P(0.05, -0.05), to: P(-0.38, -0.62))
        callout(&plate, "B", from: P(-0.06, 0.2), to: P(-0.1, 0.42))
        callout(&plate, "C", from: stud + P(0.02, -0.02), to: P(0.56, -0.42))
        callout(&plate, "D", from: P(0.265, 0.78), to: P(0.48, 0.66))
        return plate
    }

    /// Problem 20, quad: the hour put back in autumn. The hour hand at three and where it stood at four in outline, the
    /// turn back between them, and leaves coming down across the dial, one in the second ink.
    static func plate20() -> Plate {
        var plate = Plate()
        let o = P(0, 0), up = -Double.pi / 2
        ruled(&plate, angle: 0.3)

        band(&plate, o, 0.7, 0.9, from: 0, to: 2 * .pi)
        plate.lines([arc(o, 0.68), arc(o, 0.955)], fine)
        plate.lines(ticks(o, count: 60, outer: 0.955) { _ in 0.9 }, fine)
        plate.lines(ticks(o, count: 12, outer: 0.955) { _ in 0.9 }, heavy)
        for h in 1...12 {
            let a = up + Double(h) * 30 * deg
            plate.lines(numeral(h, at: polar(o, 0.8, a), height: 0.13, turn: a - up, squeeze: 0.7), heavy)
        }

        // Four o'clock in outline, three o'clock in ink, and the hour between taken back.
        let spade: [(Double, Double)] = [(-0.13, 0), (-0.11, 0.03), (0, 0.042), (0.26, 0.024), (0.29, 0.06), (0.34, 0.108), (0.41, 0.112), (0.48, 0.06), (0.54, 0.012), (0.56, 0)]
        let was = blade(o, heading: 30 * deg, spade)
        plate.lines(dashed(was + [was[0]], on: 0.035, off: 0.022), fine)
        shaded(&plate, blade(o, heading: up, [(-0.15, 0), (-0.13, 0.025), (0, 0.035), (0.3, 0.028), (0.5, 0.022), (0.66, 0.006), (0.68, 0)]), angle: 0.3, gap: 0.012)
        shaded(&plate, blade(o, heading: 0, spade), angle: 0.9, gap: 0.012, outline: heavy)
        cut(&plate, arc(o, 0.06), heavy)
        plate.line(arc(o, 0.022), medium)
        plate.fill(arrow(arc(o, 0.63, from: 31 * deg, to: 3 * deg), width: 0.034, head: 0.1), .black)

        // Leaves, each with the way it came.
        for (k, (c, size, turn)) in [(P(-0.5, 0.02), 0.17, 0.5), (P(-0.12, 0.62), 0.14, -0.9), (P(-0.2, -0.6), 0.11, 2.3), (P(-0.19, 0.21), 0.085, 1.4)].enumerated() {
            let from = c + P(0.05, -1.25 * size - 0.1)
            plate.lines(dashed(curve(from, c + P(-0.09, -1.5 * size), c + P(-0.02, -1.15 * size), 8), on: 0.03, off: 0.02), fine)
            leaf(&plate, at: c, size: size, turn: turn, k == 0 ? .second : .black)
        }

        callout(&plate, "A", from: P(0.2, -0.03), to: P(0.13, -0.42))
        callout(&plate, "B", from: P(0.31, 0.25), to: P(0.16, 0.5))
        return plate
    }
}
