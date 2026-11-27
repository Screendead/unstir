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
        let notches = (0..<14).map { i -> Double in i < 7 ? -0.88 + Double(i) * pitch : 0.25 + Double(i - 7) * pitch }
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

    /// Problem 51, Lunar month, hex, clocks 1+,2-,3+.
    static func plate51() -> Plate? { nil }

    /// Problem 52, Almanac, hex, clocks 1+,3+,5+.
    static func plate52() -> Plate? { nil }

    /// Problem 53, Solstice, hex, clocks 1+,2+,3+.
    static func plate53() -> Plate? { nil }

    /// Problem 54, Equinox, hex, clocks 1+,3+,5+.
    static func plate54() -> Plate? { nil }
}
