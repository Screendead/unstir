// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 9, Triple Calendar: problems 49 to 54's plates, drawn with `Kit`.
extension EscapementArt {
    /// Problem 49, Weekday, hex, clocks 1+,3+,5+: a calendar's seven-toothed day star, each day's segment in its own
    /// bold shading and numeral, under a bridge whose window shows the fourth day, held by a jumper and its spring; the
    /// window's frame in the second ink.
    static func plate49() -> Plate {
        var plate = Plate()
        let o = Kit.origin, root = 0.47, tip = 0.72, arbor = 0.07
        let tau = 2 * Double.pi / 7, shown = Kit.clock(1)
        // Day k's segment is centred on `shown + (k - 3) * tau`, so the fourth sits under the window.
        func middle(_ k: Int) -> Double { shown + Double(k - 3) * tau }
        func edge(_ a: Double) -> Double {
            let u = (a - (shown - 3.5 * tau)) / tau, f = u - floor(u)
            return root + (tip - root) * pow(1 - abs(2 * f - 1), 1.4)
        }
        func outline(_ a: Double, _ b: Double) -> [P] {
            let m = 90
            return (0...m).map { i in let t = a + (b - a) * Double(i) / Double(m); return polar(o, edge(t), t) }
        }
        let star = outline(middle(0) - tau / 2, middle(0) - tau / 2 + 2 * .pi)
        func segment(_ k: Int) -> [P] {
            let a = middle(k) - tau / 2, b = middle(k) + tau / 2
            return outline(a, b) + arc(o, arbor, from: b, to: a) + [polar(o, edge(a), a)]
        }

        // The bridge over the wheel, cut along one o'clock, with the window through it.
        let window = 0.5, wide = 0.065, deep = 0.075
        let across = P(-sin(shown), cos(shown)), out = P(cos(shown), sin(shown))
        func at(_ r: Double, _ s: Double) -> P { r * out + s * across }
        let bridge = [at(0.29, -0.11), at(1.1, -0.11), at(1.1, 0.11), at(0.29, 0.11), at(0.29, -0.11)]
        let hole = [at(window - deep, -wide), at(window + deep, -wide), at(window + deep, wide), at(window - deep, wide),
                    at(window - deep, -wide)]

        // The jumper: a lever pivoted near six, its beak in the root between two teeth past five, a spring at its back.
        let rootAngle = middle(6) - tau / 2
        let beak = polar(o, root + 0.01, rootAngle), pivot = polar(o, 0.8, Kit.clock(4.35))
        let along = simd_normalize(beak - pivot), side = P(-along.y, along.x)
        let jumper = [pivot + 0.035 * side, beak - 0.11 * along + 0.03 * side, polar(o, root + 0.13, rootAngle - 0.17),
                      beak, polar(o, root + 0.13, rootAngle + 0.17), beak - 0.11 * along - 0.03 * side,
                      pivot - 0.035 * side, pivot - 0.035 * side - 0.04 * along, pivot + 0.035 * side - 0.04 * along,
                      pivot + 0.035 * side]
        let springPin = polar(o, 0.84, Kit.clock(6.3))
        let spring = curve(springPin, polar(o, 0.8, Kit.clock(5.5)), beak - 0.12 * along - 0.04 * side, 30)

        Kit.ground(&plate, angle: -0.5, around: [star, bridge, jumper])

        // Each day's segment, shaded its own way.
        for k in 0..<7 {
            let seg = segment(k), a = middle(k) - tau / 2, b = middle(k) + tau / 2
            func inside(_ p: P) -> Bool {
                let r = simd_length(p)
                var t = atan2(p.y, p.x)
                while t < a { t += 2 * .pi }
                while t > a + 2 * .pi { t -= 2 * .pi }
                return t < b && r > arbor + 0.02 && r < edge(t) - 0.02
            }
            func clipped(_ path: [P], _ width: Double, _ ink: Ink = .black) {
                var run: [P] = []
                for p in path {
                    if inside(p) { run.append(p) } else { if run.count > 1 { plate.line(run, width, ink) }; run = [] }
                }
                if run.count > 1 { plate.line(run, width, ink) }
            }
            let n = P(cos(middle(k)), sin(middle(k))), d = P(-n.y, n.x)
            plate.fill(seg)
            switch k {
            case 0:
                for r in stride(from: 0.0, to: tip, by: 0.12) {
                    clipped(stride(from: -0.6, through: 0.6, by: 0.01).map { t in (r + 0.7 * abs(t)) * n + t * d }, Kit.boldest)
                }
            case 1:
                plate.fill(seg, .black)
                for x in stride(from: -0.7, through: 0.7, by: 0.1) {
                    for y in stride(from: 0.1, through: tip, by: 0.1) {
                        let p = y * n + (x + (Int(y * 10) % 2 == 0 ? 0.05 : 0)) * d
                        if inside(p) { plate.fill(arc(p, 0.036)) }
                    }
                }
            case 2:
                for r in stride(from: 0.16, to: tip, by: 0.11) { clipped(arc(o, r, from: a, to: b), Kit.boldest) }
            case 3:
                break
            case 4:
                plate.lines(hatch([seg], angle: middle(k) - 0.75, gap: 0.17), Kit.boldest)
                plate.lines(hatch([seg], angle: middle(k) + 0.75, gap: 0.17), Kit.boldest)
            case 5:
                for i in stride(from: 0, to: 14, by: 2) {
                    let u = a + (b - a) * (Double(i) + 0.5) / 14, v = a + (b - a) * (Double(i) + 1.5) / 14
                    plate.fill(outline(u, v) + [polar(o, 0.17, v), polar(o, 0.17, u), polar(o, edge(u), u)], .black)
                }
            default:
                plate.lines(hatch([seg], angle: middle(k), gap: 0.115), Kit.boldest)
            }
            plate.line(seg, medium)
            // Its numeral on a bone cartouche, read from the arbor.
            let c = polar(o, 0.28, middle(k))
            if k != 3 {
                plate.fill(arc(c, 0.062))
                plate.line(arc(c, 0.062), medium)
                plate.lines(Kit.numeral(roman(k + 1), at: c, height: 0.062, turn: middle(k) + .pi / 2, squeeze: 0.75), 0.011)
            }
        }
        plate.line(star, heavy)
        plate.fill(arc(o, 0.17))
        plate.line(arc(o, 0.17), medium)
        let square = turned(box(P(-0.04, -0.04), P(0.04, 0.04)), by: 0.3)
        plate.lines(hatch([arc(o, 0.15), square], angle: 0.6, gap: 0.04), medium)
        Kit.mass(&plate, square)

        // The rim of the movement's plate, bold, with its seven screws.
        Kit.mass(&plate, arc(o, 1.06) + arc(o, 0.9).reversed())
        plate.line(arc(o, 0.925), fine, .bone)
        for k in 0..<7 {
            let screw = polar(o, 0.96, middle(k) + tau / 2)
            plate.fill(arc(screw, 0.028))
            plate.line([screw - 0.022 * P(cos(middle(k)), sin(middle(k))), screw + 0.022 * P(cos(middle(k)), sin(middle(k)))], medium)
        }

        // The bridge, ink, its screws and bevel in bone, and the day in the window.
        Kit.mass(&plate, bridge)
        plate.line([at(0.31, -0.09), at(1.1, -0.09)], fine, .bone)
        plate.line([at(0.31, 0.09), at(1.1, 0.09)], fine, .bone)
        for r in [0.32, 0.7] {
            plate.fill(arc(at(r, 0), 0.032))
            plate.line(arc(at(r, 0), 0.032), medium)
            plate.line([at(r, -0.026), at(r, 0.026)], medium)
        }
        plate.fill(hole)
        plate.lines(hatch([hole], angle: shown + 0.3, gap: 0.02), fine)
        let day = at(window, 0)
        plate.fill(box(day - P(0.06, 0.045), day + P(0.06, 0.045)))
        plate.lines(Kit.numeral("IV", at: day, height: 0.075), 0.014)
        let frame = [at(window - deep - 0.025, -wide - 0.025), at(window + deep + 0.025, -wide - 0.025),
                     at(window + deep + 0.025, wide + 0.025), at(window - deep - 0.025, wide + 0.025),
                     at(window - deep - 0.025, -wide - 0.025)]
        plate.fill(frame + hole.reversed(), .second)
        plate.line(frame, fine)
        plate.line(hole, medium)

        // The jumper and its spring.
        Kit.mass(&plate, jumper)
        plate.fill(arc(pivot, 0.03))
        plate.line(arc(pivot, 0.03), medium)
        plate.line([pivot - P(0.02, 0.02), pivot + P(0.02, 0.02)], medium)
        Kit.mass(&plate, Kit.ribbon(spring, 0.028))
        plate.fill(arc(springPin, 0.026))
        plate.line(arc(springPin, 0.026), medium)

        callout(&plate, "A", from: polar(o, 0.62, middle(2)), to: polar(o, 0.78, Kit.clock(11.05)))
        callout(&plate, "B", from: spring[18], to: polar(o, 0.8, Kit.clock(7)))
        callout(&plate, "C", from: at(window + deep + 0.02, wide + 0.02), to: polar(o, 0.76, Kit.clock(2.95)))
        return plate
    }

    /// Problem 50, Fortnight, hex, clocks 1+,2+,3+: a tally stick along three and nine o'clock, cut with two bundles
    /// of seven notches either side of the hub, the knife that cut them below and a candle stub and shavings above; the
    /// last notch in the second ink.
    static func plate50() -> Plate {
        var plate = Plate()
        let left = -1.0, right = 1.0, top = -0.13, mid = -0.03, bottom = 0.15, neck = 0.86

        // The stick: its top face bone, its side in shadow, its right end whittled to a grip.
        let stick = [P(left, top), P(neck, top), P(right, -0.07), P(right, 0.1), P(neck, bottom), P(left, bottom), P(left, top)]
        let side = [P(left, mid), P(neck, mid), P(right, -0.01), P(right, 0.1), P(neck, bottom), P(left, bottom), P(left, mid)]

        // The knife below, its edge up.
        let kc = P(0.0, 0.69), kd = simd_normalize(P(1, -0.14)), kn = P(-kd.y, kd.x)
        func k(_ u: Double, _ v: Double) -> P { kc + u * kd + v * kn }
        let handle = [k(-0.64, -0.06), k(-0.12, -0.07), k(-0.12, 0.07), k(-0.64, 0.06), k(-0.69, 0.0), k(-0.64, -0.06)]
        let bolster = [k(-0.12, -0.075), k(-0.05, -0.075), k(-0.05, 0.075), k(-0.12, 0.075), k(-0.12, -0.075)]
        let blade = [k(-0.05, -0.06), k(0.36, -0.07), k(0.56, -0.045), k(0.64, 0.04), k(0.36, 0.05), k(-0.05, 0.055),
                     k(-0.05, -0.06)]

        // The candle stub in its saucer, above the stick past one o'clock.
        let cc = P(0.43, -0.47), body = 0.1, height = 0.2
        let saucer = ellipse(cc, 0.24, 0.07)
        let candle = [cc + P(-body, 0), cc + P(-body, -height), cc + P(-0.04, -height - 0.018), cc + P(0.03, -height + 0.012),
                      cc + P(body, -height), cc + P(body, 0), cc + P(-body, 0)]
        let flameBase = cc + P(0, -height - 0.035)
        let flame = curve(flameBase + P(-0.055, 0), flameBase + P(-0.07, -0.11), flameBase + P(0.01, -0.23), 14)
            + curve(flameBase + P(0.01, -0.23), flameBase + P(0.07, -0.11), flameBase + P(0.055, 0), 14)
            + curve(flameBase + P(0.055, 0), flameBase + P(0, 0.05), flameBase + P(-0.055, 0), 8)

        // Two shavings curled off by the knife, above the stick past eleven.
        let curls = [(P(-0.38, -0.66), 0.17, 0.2), (P(-0.72, -0.46), 0.1, 2.0)].map { (c, r, t) in
            (0...80).map { i -> P in
                let u = Double(i) / 80
                return polar(c, r * (1 - 0.65 * u), t + u * 4.4)
            }
        }

        Kit.ground(&plate, angle: 0.5, around: [stick, handle, bolster, blade, saucer, candle, flame]
                   + curls.map { Kit.ribbon($0, 0.07) })

        // The stick, its grain and its squared end.
        Kit.cut(&plate, stick, edge: heavy)
        plate.line([P(left, -0.08), P(-0.25, -0.085)], medium)
        plate.line([P(0.2, -0.09), P(neck, -0.085)], medium)
        Kit.mass(&plate, side)
        for (y, a, b) in [(0.03, left, -0.1), (0.1, -0.7, 0.4), (0.04, -0.3, neck), (0.105, 0.3, neck)] {
            plate.line(curve(P(a, y), P((a + b) / 2, y + 0.015), P(b, y), 16), 0.026, .bone)
        }

        // Fourteen notches in two bundles of seven, either side of the hub, each a V cut through the top face into the
        // side; every seventh cut deeper.
        let pitch = 0.09
        let notches: [Double] = (0..<14).map { (i: Int) -> Double in
            let from: Double = i < 7 ? -0.88 : 0.25
            return from + Double(i < 7 ? i : i - 7) * pitch
        }
        for (i, x) in notches.enumerated() {
            let ink: Ink = i == 13 ? .second : .black, w = 0.034
            let face = [P(x - w, top), P(x + w, top), P(x + 0.01, mid), P(x - 0.01, mid), P(x - w, top)]
            plate.fill(face, ink)
            plate.line(face, medium)
            let deep = i % 7 == 6 ? 0.1 : 0.065
            plate.fill([P(x - 0.022, mid), P(x + 0.022, mid), P(x, mid + deep), P(x - 0.022, mid)], i == 13 ? .second : .bone)
        }

        // The knife: ink handle with bone rivets, steel bolster, the blade's bevel in ink along its edge.
        Kit.mass(&plate, handle)
        plate.line([k(-0.62, -0.035), k(-0.14, -0.042)], fine, .bone)
        for u in [-0.54, -0.37, -0.2] {
            plate.fill(arc(k(u, 0.01), 0.022))
            plate.line(arc(k(u, 0.01), 0.022), fine)
        }
        Kit.solid(&plate, bolster, angle: 1.4, gap: 0.016, width: fine)
        Kit.cut(&plate, blade, edge: heavy)
        Kit.mass(&plate, [k(-0.05, -0.06), k(0.36, -0.07), k(0.56, -0.045), k(0.55, -0.01), k(0.34, -0.015), k(-0.05, -0.012),
                          k(-0.05, -0.06)])
        plate.line([k(-0.02, 0.02), k(0.36, 0.025)], medium)

        // The candle, shadowed on its right, a drip down its left, its flame with a bone heart.
        Kit.cut(&plate, saucer, edge: heavy)
        Kit.mass(&plate, ellipse(cc + P(0, 0.035), 0.22, 0.04, from: 0.15, to: .pi - 0.15) + [cc + P(-0.2, 0.05)])
        Kit.mass(&plate, Kit.ribbon(curve(cc + P(0.24, 0), cc + P(0.36, -0.02), cc + P(0.34, 0.07), 10), 0.035))
        Kit.mass(&plate, ellipse(cc, 0.15, 0.035))
        Kit.cut(&plate, candle, edge: heavy)
        Kit.mass(&plate, [cc + P(0.035, 0), cc + P(0.035, -height + 0.009), cc + P(body, -height), cc + P(body, 0),
                          cc + P(0.035, 0)])
        plate.lines(hatch([[cc + P(-0.01, 0), cc + P(-0.01, -height + 0.01), cc + P(0.035, -height + 0.008), cc + P(0.035, 0),
                            cc + P(-0.01, 0)]], angle: .pi / 2, gap: 0.016), fine)
        Kit.mass(&plate, Kit.ribbon(curve(cc + P(-0.07, -height), cc + P(-0.085, -height + 0.07), cc + P(-0.07, -height + 0.12), 8), 0.028))
        plate.line([cc + P(0, -height - 0.005), flameBase], heavy)
        Kit.mass(&plate, flame)
        plate.fill(ellipse(flameBase + P(0, -0.05), 0.018, 0.045))

        // The shavings, their outer face bone and their inner face ink.
        for curl in curls {
            Kit.mass(&plate, Kit.ribbon(curl, 0.065))
            plate.line(Array(curl[4..<(curl.count - 10)]), 0.012, .bone)
        }

        callout(&plate, "A", from: P(notches[1], top + 0.03), to: P(-0.78, 0.4))
        callout(&plate, "B", from: k(0.2, 0.02), to: P(0.6, 0.38))
        callout(&plate, "C", from: flameBase + P(0, -0.1), to: P(0.66, -0.8))
        return plate
    }

    /// Problem 51, Lunar month, hex, clocks 1+,2-,3+: a crescent moon in solid ink with a face in profile looking into
    /// its hollow, round it an ellipse of its orbit with the month's twenty-nine days as dots, each in its phase, and
    /// bold stars past the rim; the new moon's dot, at three o'clock, in the second ink.
    static func plate51() -> Plate {
        var plate = Plate()
        let o = Kit.origin
        // The crescent: the outer disc less an inner one set to the right, the inner edge cut as a face.
        let c1 = P(0.0, 0.0), r1 = 0.68, c2 = P(0.34, 0.0), r2 = 0.63
        func dent(_ t: Double) -> Double {
            func bump(_ at: Double, _ w: Double, _ h: Double) -> Double { h * exp(-pow((t - at) / w, 2)) }
            let nose = max(0, 1 - abs(t - .pi + 0.01) / 0.075) * 0.14
            return nose + bump(.pi + 0.36, 0.16, 0.06) + bump(.pi + 0.2, 0.05, 0.03) + bump(.pi - 0.17, 0.035, 0.045)
                + bump(.pi - 0.26, 0.03, 0.04) + bump(.pi - 0.42, 0.07, 0.075) + bump(.pi - 0.08, 0.04, 0.02)
        }
        let outer = arc(c1, r1, from: -.pi, to: .pi).filter { simd_distance($0, c2) > r2 }
        let inner = stride(from: .pi - 1.7, through: .pi + 1.7, by: 0.01).map { polar(c2, r2 - dent($0), $0) }
            .filter { simd_distance($0, c1) < r1 }
        // Start the outer arc just after its gap so it runs top tip to bottom tip round the left.
        let gap = outer.indices.dropFirst().first { simd_distance(outer[$0], outer[$0 - 1]) > 0.05 } ?? 0
        let rim = Array(outer[gap...] + outer[..<gap])
        let moon = rim + inner.reversed() + [rim[0]]

        // The orbit and its days, the new moon at three o'clock and the days running anticlockwise.
        let rx = 0.88, ry = 0.82
        func day(_ i: Int) -> P { P(rx * cos(-2 * .pi * Double(i) / 29), ry * sin(-2 * .pi * Double(i) / 29)) }
        let disc = 0.042

        // Stars past the rim, in the corners the orbit leaves.
        let stars = [P(0.72, -0.72), P(-0.74, 0.7), P(0.72, 0.72), P(-0.72, -0.74), P(0.5, -0.4), P(0.52, 0.36),
                     P(0.2, -0.24), P(0.24, 0.2)]
        func star(_ c: P, _ r: Double) -> [P] {
            (0...10).map { (i: Int) -> P in
                let reach: Double = i % 2 == 0 ? r : 0.4 * r
                return polar(c, reach, -.pi / 2 + Double(i) * .pi / 5)
            }
        }

        Kit.ground(&plate, angle: -0.45, around: [moon] + (0..<29).map { arc(day($0), disc + 0.012) }
                   + stars.enumerated().map { star($1, $0 < 4 ? 0.07 : 0.05) })

        plate.line(ellipse(o, rx, ry), 0.012)

        // The moon: ink, a bone line along its lit limb, the face's eye, brow, nostril and lips cut in bone, and
        // craters on its back.
        Kit.mass(&plate, moon)
        for r in stride(from: r1 - 0.035, to: r1 - 0.4, by: -0.05) {
            var run: [P] = []
            for p in arc(c1, r, from: -.pi, to: .pi) + [polar(c1, r, -.pi)] {
                if simd_distance(p, c2) > r2 + 0.05 { run.append(p) } else { if run.count > 1 { plate.line(run, 0.028, .bone) }; run = [] }
            }
            if run.count > 1 { plate.line(run, 0.028, .bone) }
        }
        let face = { (t: Double, d: Double) in polar(c2, r2 - dent(t) + d, t) }
        let eye = face(.pi + 0.13, 0.06)
        plate.fill(ellipse(eye, 0.03, 0.014, turned: -0.15))
        plate.fill(arc(eye + P(0.012, 0), 0.009), .black)
        plate.line([face(.pi + 0.24, 0.03), face(.pi + 0.18, 0.07), face(.pi + 0.08, 0.075)], 0.012, .bone)
        plate.line(curve(face(.pi - 0.01, 0.1), face(.pi - 0.07, 0.075), face(.pi - 0.08, 0.045), 6), 0.01, .bone)
        plate.line([face(.pi - 0.215, 0.0), face(.pi - 0.215, 0.05)], 0.01, .bone)
        plate.line(curve(face(.pi - 0.34, 0.06), face(.pi - 0.46, 0.13), face(.pi - 0.6, 0.06), 10), 0.01, .bone)
        

        // The days, each a disc lit as the moon is that day.
        for i in 0..<29 {
            let c = day(i), phase = 2 * .pi * Double(i) / 29
            plate.fill(arc(c, disc))
            if i == 0 {
                plate.fill(arc(c, disc + 0.012), .second)
            } else {
                let k = phase < .pi ? cos(phase) : -cos(phase), side = phase < .pi ? -1.0 : 1.0
                let limb = stride(from: -0.5 * .pi, through: 0.5 * .pi, by: 0.1).map { P(side * disc * cos($0), disc * sin($0)) }
                let term = stride(from: 0.5 * .pi, through: -0.5 * .pi, by: -0.1).map { P(k * disc * cos($0), disc * sin($0)) }
                plate.fill((limb + term).map { $0 + c }, .black)
            }
            plate.line(arc(c, disc), medium)
        }

        for (i, c) in stars.enumerated() { Kit.mass(&plate, star(c, i < 4 ? 0.07 : 0.05)) }

        callout(&plate, "A", from: P(-0.6, 0.12), to: P(-0.34, 0.48))
        callout(&plate, "B", from: day(11), to: P(-0.36, -0.46))
        return plate
    }

    /// Problem 52, Almanac, hex, clocks 1+,3+,5+: an almanac lying open, its spine along one and seven o'clock, its
    /// pages fanned in bold over an ink board, a star chart engraved on the left page and a tide table with its curve on
    /// the right; the ribbon bookmark hanging from the foot of the spine in the second ink.
    static func plate52() -> Plate {
        var plate = Plate()
        let tilt = Double.pi / 6
        func q(_ points: [P]) -> [P] { turned(points, by: tilt) }
        func q(_ p: P) -> P { turned([p], by: tilt)[0] }

        // A page, left or right, in the book's own frame: spine up the middle, the far edge rising in perspective.
        func page(_ side: Double, _ d: Double) -> [P] {
            let top = curve(P(0, -0.42 + d), P(side * 0.34, -0.53 + d), P(side * (0.68 + d), -0.5 + 0.8 * d), 16)
            let bottom = curve(P(side * (0.82 + d), 0.44 + d), P(side * 0.4, 0.52 + d), P(0, 0.42 + d), 16)
            return q(top + bottom + [top[0]])
        }
        let board = q([P(-0.88, -0.44), P(0, -0.4), P(0.88, -0.44), P(0.98, 0.56), P(0, 0.56), P(-0.98, 0.56), P(-0.88, -0.44)])

        Kit.ground(&plate, angle: -0.8, around: [board])
        Kit.mass(&plate, board)
        for side in [-1.0, 1.0] {
            for i in stride(from: 3, through: 1, by: -1) {
                let d = 0.03 * Double(i)
                if i % 2 == 1 { Kit.cut(&plate, page(side, d)) } else { Kit.mass(&plate, page(side, d)) }
            }
            Kit.cut(&plate, page(side, 0), edge: heavy)
        }
        // The shadow in the spine's fold, and the fold.
        for side in [-1.0, 1.0] {
            Kit.mass(&plate, q(curve(P(0, -0.42), P(side * 0.07, 0), P(0, 0.42), 16) + [P(0, -0.42)]))
        }
        plate.line(q(curve(P(0, -0.42), P(0.012, 0), P(0, 0.42), 12)), heavy)
        plate.lines([q(curve(P(-0.03, -0.41), P(-0.04, 0), P(-0.03, 0.41), 12)), q(curve(P(0.03, -0.41), P(0.04, 0), P(0.03, 0.41), 12))], fine)

        // Each page's printed head: a bold rule over a fine one.
        for side in [-1.0, 1.0] {
            Kit.mass(&plate, q(Kit.band(P(side * 0.1, -0.415), P(side * 0.6, -0.445), 0.04)))
            plate.line(q([P(side * 0.1, -0.375), P(side * 0.6, -0.4)]), medium)
        }

        // The star chart: a planisphere's rim, its meridians, and constellations in bold.
        let sc = P(-0.38, 0.0), sr = 0.27
        plate.line(q(arc(sc, sr)), 0.02)
        plate.line(q(arc(sc, sr - 0.035)), medium)
        for k in 0..<24 {
            let a = Double(k) * .pi / 12
            plate.line(q([polar(sc, sr - 0.035, a), polar(sc, sr - (k % 2 == 0 ? 0.0 : 0.018), a)]), k % 2 == 0 ? medium : fine)
        }
        for k in 0..<6 { plate.line(q([polar(sc, 0.03, Double(k) * .pi / 6), polar(sc, sr - 0.035, Double(k) * .pi / 6)]), fine) }
        for k in 0..<6 { plate.line(q([polar(sc, 0.03, Double(k) * .pi / 6 + .pi), polar(sc, sr - 0.035, Double(k) * .pi / 6 + .pi)]), fine) }
        plate.line(q(arc(sc, 0.12)), fine)
        let figures: [[P]] = [
            [P(-0.52, -0.12), P(-0.46, -0.16), P(-0.4, -0.13), P(-0.34, -0.17), P(-0.28, -0.1)],
            [P(-0.5, 0.1), P(-0.44, 0.04), P(-0.38, 0.08), P(-0.42, 0.16), P(-0.5, 0.1)],
            [P(-0.3, 0.02), P(-0.25, 0.1), P(-0.22, 0.18)],
        ]
        for figure in figures {
            plate.line(q(figure), medium)
            for (i, p) in figure.enumerated() where i == 0 || p != figure[0] {
                let r = i % 2 == 0 ? 0.03 : 0.022
                let points: [P] = (0...8).map { (j: Int) -> P in
                    let reach: Double = j % 2 == 0 ? r : 0.35 * r
                    return polar(p, reach, -.pi / 2 + Double(j) * .pi / 4)
                }
                Kit.mass(&plate, q(points))
            }
        }
        Kit.mass(&plate, q(arc(sc, 0.022)))

        // The tide table: ruled columns headed by the hours, the tide's curve in ink and the water under it ruled bold.
        let left = 0.1, right = 0.66, high = -0.32, low = 0.3
        for (i, x) in stride(from: left, through: right, by: (right - left) / 6).enumerated() {
            plate.line(q([P(x, high), P(x, low)]), i == 0 || i == 6 ? medium : fine)
            if i < 6 {
                plate.lines(Kit.numeral(roman(i + 1), at: P(x + (right - left) / 12, high - 0.04), height: 0.045, squeeze: 0.8).map(q), medium)
            }
        }
        plate.line(q([P(left, high), P(right, high)]), medium)
        plate.line(q([P(left, low), P(right, low)]), medium)
        for y in stride(from: high + 0.1, to: low, by: 0.1) { plate.line(q([P(left, y), P(right, y)]), fine) }
        let tide = stride(from: left, through: right, by: 0.01).map { x in P(x, 0.0 - 0.13 * sin((x - left) / (right - left) * 4 * .pi + 0.6)) }
        let water = tide + [P(right, low), P(left, low), tide[0]]
        plate.lines(hatch([q(water)], angle: tilt, gap: 0.055), 0.022)
        plate.line(q(tide), 0.026)
        // Print below the table.
        for (i, y) in stride(from: 0.36, through: 0.42, by: 0.03).enumerated() {
            plate.lines(dashed(q([P(left, y), P(right - 0.05 * Double(i), y)]), on: 0.05, off: 0.015), fine)
        }
        for (i, y) in stride(from: 0.33, through: 0.42, by: 0.03).enumerated() {
            plate.lines(dashed(q([P(-0.66 + 0.02 * Double(i), y), P(-0.12, y)]), on: 0.045, off: 0.015), fine)
        }

        // The ribbon from the foot of the spine, out over the board and down past seven, swallow-tailed.
        let path = q(curve(P(0, 0.3), P(0.06, 0.62), P(-0.02, 0.86), 20))
        let ribbon = Kit.ribbon(path, 0.055)
        plate.fill(ribbon, .second)
        plate.line(ribbon, medium)
        let end = path[path.count - 1], dir = simd_normalize(end - path[path.count - 2]), across = P(-dir.y, dir.x)
        let w = 0.0275
        let tail: [P] = [end + w * across, end + w * across + 0.06 * dir, end + 0.025 * dir, end - w * across + 0.06 * dir,
                         end - w * across, end + w * across]
        plate.fill(tail, .second)
        plate.line(tail, medium)

        callout(&plate, "A", from: q(polar(sc, sr, -2.2)), to: q(P(-0.36, -0.66)))
        callout(&plate, "B", from: q(tide[30]), to: q(P(0.56, -0.66)))
        return plate
    }

    /// Problem 53, Solstice, hex, clocks 1+,2+,3+: a stone circle's trilithons against the dawn in solid ink, the
    /// midsummer sun half risen on the horizon through the central arch, its rays across the sky and the stones' long
    /// shadows thrown across the ground toward the eye; the sun's disc, between the hub and twelve, in the second ink.
    static func plate53() -> Plate {
        var plate = Plate()
        let horizon = -0.2, sun = P(0, -0.2), disc = 0.085

        // A standing stone from its foot's corners up to its head, a little tapered and leaning.
        func stone(_ x0: Double, _ x1: Double, _ base: Double, _ head: Double, lean: Double = 0) -> [P] {
            [P(x0, base), P(x1, base), P(x1 - 0.008 + lean, head + 0.01), P((x0 + x1) / 2 + lean, head),
             P(x0 + 0.01 + lean, head + 0.012), P(x0, base)]
        }
        func lintel(_ x0: Double, _ x1: Double, _ low: Double, _ high: Double) -> [P] {
            [P(x0, low), P(x1, low - 0.005), P(x1 + 0.01, high + 0.01), P((x0 + x1) / 2, high - 0.006), P(x0 - 0.008, high + 0.008),
             P(x0, low)]
        }
        var uprights: [[P]] = [stone(-0.22, -0.14, 0.2, -0.4, lean: 0.005), stone(0.14, 0.22, 0.2, -0.4, lean: -0.005)]
        var lintels: [[P]] = [lintel(-0.26, 0.26, -0.4, -0.48)]
        for side in [-1.0, 1.0] {
            uprights.append(stone(side * 0.63, side * 0.56, 0.08, -0.26))
            uprights.append(stone(side * 0.42, side * 0.35, 0.08, -0.26))
            lintels.append(lintel(min(side * 0.65, side * 0.33), max(side * 0.65, side * 0.33), -0.26, -0.315))
            uprights.append(stone(side * 0.86, side * 0.8, -0.06, -0.3))
        }

        // The sky: the sun's rays, ink and bone in turn, above the horizon.
        for k in 0..<16 {
            let a = .pi + (Double(k) + 0.5) * .pi / 16, n = P(-sin(a), cos(a))
            let near = polar(sun, k % 2 == 0 ? 0.2 : 0.14, a), far = polar(sun, 1.3, a)
            plate.fill([near - 0.004 * n, far - 0.024 * n, far + 0.024 * n, near + 0.004 * n, near - 0.004 * n], .black)
        }
        // The ground, ruled level, and the stones' shadows running from the sun toward the eye.
        let land = box(P(-1.1, horizon), P(1.1, 1.1))
        plate.fill(land)
        var shadows: [[P]] = []
        for u in uprights {
            let a = u[0], b = u[1]
            let da = simd_normalize(a - sun), db = simd_normalize(b - sun)
            shadows.append([a, b, b + 1.4 * db, a + 1.4 * da, a])
        }
        plate.lines(hatch([land] + shadows, angle: 0, gap: Kit.groundGap), Kit.groundWidth)
        for sh in shadows { plate.fill(sh, .black) }
        plate.line([P(-1.1, horizon), P(1.1, horizon)], heavy)
        // Far hills along the horizon.
        for hill in [curve(P(-1.1, horizon), P(-0.7, horizon - 0.07), P(-0.32, horizon), 16),
                     curve(P(0.36, horizon), P(0.75, horizon - 0.06), P(1.1, horizon), 16)] {
            plate.fill(hill + [hill[0]])
            plate.lines(hatch([hill + [hill[0]]], angle: 0, gap: 0.02), medium)
            plate.line(hill, heavy)
        }

        // The sun, half risen in the arch.
        let half = arc(sun, disc, from: .pi, to: 2 * .pi) + [P(-disc, horizon)]
        plate.fill(half, .second)
        plate.line(half, medium)
        plate.line(arc(sun, disc + 0.025, from: .pi + 0.1, to: 2 * .pi - 0.1), medium)

        // The stones, black against the dawn, a bone line where the light catches each edge and their cracks.
        for st in uprights + lintels {
            Kit.mass(&plate, st)
        }
        for st in uprights {
            let top = st[3], foot = st[0]
            plate.line([foot + P(0.014, -0.03), top + P(0.012, 0.03)], 0.011, .bone)
            plate.line([st[1] + P(-0.014, -0.03), st[2] + P(-0.006, 0.03)], 0.011, .bone)
            let mid = (top + foot) / 2
            plate.line([mid + P(-0.015, -0.02), mid + P(0.005, 0.0), mid + P(-0.01, 0.04)], medium, .bone)
        }
        for l in lintels { plate.line([l[4] + P(0.02, 0.012), l[3] + P(0, 0.014), l[2] + P(-0.02, 0.012)], fine, .bone) }

        callout(&plate, "A", from: P(-0.2, -0.46), to: P(-0.44, -0.62))
        callout(&plate, "B", from: P(0.4, 0.5), to: P(0.62, 0.34))
        return plate
    }

    /// Problem 54, Equinox, hex, clocks 1+,3+,5+: a balance with its pans level, the sun in the left and the moon in
    /// the right, its beam, pillar and plinth in ink, before a ground ruled lightly for day on the left and heavily for
    /// night on the right; the pointer at the top of the balance, above twelve's hub, in the second ink.
    static func plate54() -> Plate {
        var plate = Plate()
        let pivot = P(0, -0.78), reach = 0.72, drop = 0.52, panY = 0.12, panW = 0.2

        let beam = [P(-reach - 0.02, -drop - 0.02), P(-0.1, -0.78), P(0, -0.81), P(0.1, -0.78), P(reach + 0.02, -drop - 0.02),
                    P(reach + 0.02, -drop + 0.02), P(0.1, -0.735), P(0, -0.745), P(-0.1, -0.735), P(-reach - 0.02, -drop + 0.02),
                    P(-reach - 0.02, -drop - 0.02)]
        let pillar = [P(-0.035, -0.72), P(0.035, -0.72), P(0.048, 0.7), P(-0.048, 0.7), P(-0.035, -0.72)]
        let capital = [P(-0.08, -0.745), P(0.08, -0.745), P(0.05, -0.69), P(-0.05, -0.69), P(-0.08, -0.745)]
        let plinth = [P(-0.26, 0.7), P(0.26, 0.7), P(0.26, 0.76), P(-0.26, 0.76), P(-0.26, 0.7)]
        let steps = [P(-0.34, 0.76), P(0.34, 0.76), P(0.34, 0.84), P(0.44, 0.84), P(0.44, 1.1), P(-0.44, 1.1), P(-0.44, 0.84),
                     P(-0.34, 0.84), P(-0.34, 0.76)]
        func pan(_ x: Double) -> [P] {
            ellipse(P(x, panY), panW, 0.13, from: 0, to: .pi) + [P(x - panW, panY)]
        }
        let sunC = P(-reach, panY - 0.12), moonC = P(reach, panY - 0.12)

        // Day on the left, night on the right.
        let day = box(P(-1.1, -1.1), P(0, 1.1)), night = box(P(0, -1.1), P(1.1, 1.1))
        let parts = [beam, pillar, capital, plinth, steps, pan(-reach), pan(reach), arc(sunC, 0.17), arc(moonC, 0.15)]
        plate.lines(hatch([day] + parts, angle: 0.4, gap: Kit.groundGap), Kit.groundWidth)
        plate.lines(hatch([night] + parts, angle: -0.4, gap: Kit.groundGap), 0.02)
        for (c, r) in [(P(0.3, -0.4), 0.03), (P(0.62, -0.68), 0.025), (P(0.3, 0.46), 0.022), (P(0.7, 0.58), 0.03), (P(0.22, -0.1), 0.02)] {
            let st: [P] = (0...10).map { (i: Int) -> P in
                let reach: Double = i % 2 == 0 ? r : 0.4 * r
                return polar(c, reach, -.pi / 2 + Double(i) * .pi / 5)
            }
            plate.fill(arc(c, r + 0.018))
            Kit.mass(&plate, st)
        }

        // The chains from the beam's ends to each pan's rim.
        for x in [-reach, reach] {
            let hook = P(x, -drop + 0.02)
            for dx in [-panW + 0.02, 0.0, panW - 0.02] {
                plate.lines(dashed([hook, P(x + dx, panY)], on: 0.03, off: 0.012), 0.014)
            }
            Kit.mass(&plate, arc(hook + P(0, 0.03), 0.022))
        }

        // The sun in the left pan, its rays ink about a bone disc; the moon in the right, a crescent in ink.
        for k in 0..<12 {
            let a = Double(k) * .pi / 6
            Kit.mass(&plate, [polar(sunC, 0.1, a - 0.18), polar(sunC, 0.17, a), polar(sunC, 0.1, a + 0.18), polar(sunC, 0.1, a - 0.18)])
        }
        plate.fill(arc(sunC, 0.1))
        plate.line(arc(sunC, 0.1), heavy)
        plate.lines(hatch([arc(sunC, 0.07)], angle: 0.8, gap: 0.022), medium)
        plate.line(arc(sunC, 0.07), medium)
        let limb = arc(moonC, 0.14, from: -.pi / 2 + 0.35, to: -1.5 * .pi - 0.35)
        let moon = limb + curve(limb[limb.count - 1], moonC + P(-0.1, 0), limb[0], 16)
        Kit.mass(&plate, moon)
        plate.line(arc(moonC, 0.12, from: -.pi / 2 - 0.5, to: -1.5 * .pi + 0.5), 0.01, .bone)

        // The pans, solid ink with a bone rim line.
        for x in [-reach, reach] {
            Kit.mass(&plate, pan(x))
            plate.line(ellipse(P(x, panY), panW - 0.02, 0.1, from: 0.15, to: .pi - 0.15), medium, .bone)
            plate.line([P(x - panW - 0.01, panY), P(x + panW + 0.01, panY)], heavy)
        }

        // The pillar, fluted in bone, its capital and stepped plinth.
        Kit.mass(&plate, pillar)
        plate.line([P(-0.015, -0.72), P(-0.02, 0.6)], 0.01, .bone)
        plate.line([P(0.015, -0.72), P(0.02, 0.6)], 0.01, .bone)
        Kit.solid(&plate, plinth, angle: .pi / 2, gap: 0.04, width: 0.016, edge: heavy)
        Kit.solid(&plate, steps, angle: 0, gap: 0.05, width: 0.016, edge: heavy)
        plate.line([P(-0.34, 0.84), P(0.34, 0.84)], heavy)
        Kit.mass(&plate, capital)
        Kit.mass(&plate, beam)
        plate.line([P(-reach + 0.02, -drop - 0.002), P(-0.1, -0.777), P(0.1, -0.777), P(reach - 0.02, -drop - 0.002)], fine, .bone)

        // The index arc above the pivot and the pointer standing upright against it.
        plate.line(arc(pivot, 0.13, from: -.pi / 2 - 0.4, to: -.pi / 2 + 0.4), heavy)
        for k in -3...3 {
            let a = -.pi / 2 + Double(k) * 0.12
            plate.line([polar(pivot, 0.13, a), polar(pivot, k == 0 ? 0.17 : 0.155, a)], k == 0 ? heavy : medium)
        }
        let pointer = [P(-0.02, -0.78), P(0, -0.91), P(0.02, -0.78), P(-0.02, -0.78)]
        plate.fill(pointer, .second)
        plate.line(pointer, medium)
        plate.fill(arc(pivot, 0.03))
        plate.line(arc(pivot, 0.03), heavy)
        plate.fill(arc(pivot, 0.01), .black)

        callout(&plate, "A", from: sunC + P(0.06, 0.06), to: P(-0.46, 0.0))
        callout(&plate, "B", from: moonC + P(-0.02, 0.1), to: P(0.42, 0.06))
        callout(&plate, "C", from: P(0.0, 0.36), to: P(-0.26, 0.5))
        return plate
    }
}
