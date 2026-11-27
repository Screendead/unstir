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
        let o = Kit.origin
        let star: [P] = plate49Outline(plate49Middle(0) - plate49Tau / 2, plate49Middle(0) - plate49Tau / 2 + 2 * .pi)
        let bridge: [P] = plate49Bridge()
        let hole: [P] = plate49Hole()
        let (jumper, pivot, springPin, spring) = plate49Jumper()

        Kit.ground(&plate, angle: -0.5, around: [star, bridge, jumper])
        for k in 0..<7 { plate49Day(&plate, k) }
        plate.line(star, heavy)
        plate.fill(arc(o, 0.17))
        plate.line(arc(o, 0.17), medium)
        let square = turned(box(P(-0.04, -0.04), P(0.04, 0.04)), by: 0.3)
        plate.lines(hatch([arc(o, 0.15), square], angle: 0.6, gap: 0.04), medium)
        Kit.mass(&plate, square)
        plate49Rim(&plate)
        plate49Bridged(&plate, bridge, hole)
        plate49Spring(&plate, jumper, pivot, springPin, spring)

        let window = plate49Window, deep = plate49Deep, wide = plate49Wide
        callout(&plate, "A", from: polar(o, 0.62, plate49Middle(2)), to: polar(o, 0.78, Kit.clock(11.05)))
        callout(&plate, "B", from: spring[18], to: polar(o, 0.8, Kit.clock(7)))
        callout(&plate, "C", from: plate49At(window + deep + 0.02, wide + 0.02), to: polar(o, 0.76, Kit.clock(2.95)))
        return plate
    }

    private static let plate49Root = 0.47, plate49Tip = 0.72, plate49Arbor = 0.07
    private static let plate49Tau: Double = 2 * Double.pi / 7, plate49Shown: Double = Kit.clock(1)
    private static let plate49Window = 0.5, plate49Wide = 0.065, plate49Deep = 0.075

    /// Day k's segment is centred on `shown + (k - 3) * tau`, so the fourth sits under the window.
    private static func plate49Middle(_ k: Int) -> Double { plate49Shown + Double(k - 3) * plate49Tau }

    private static func plate49Edge(_ a: Double) -> Double {
        let u: Double = (a - (plate49Shown - 3.5 * plate49Tau)) / plate49Tau, f: Double = u - floor(u)
        return plate49Root + (plate49Tip - plate49Root) * pow(1 - abs(2 * f - 1), 1.4)
    }

    private static func plate49Outline(_ a: Double, _ b: Double) -> [P] {
        let m = 90
        return (0...m).map { (i: Int) -> P in
            let t: Double = a + (b - a) * Double(i) / Double(m)
            return polar(Kit.origin, plate49Edge(t), t)
        }
    }

    private static func plate49Segment(_ k: Int) -> [P] {
        let a: Double = plate49Middle(k) - plate49Tau / 2, b: Double = plate49Middle(k) + plate49Tau / 2
        return plate49Outline(a, b) + arc(Kit.origin, plate49Arbor, from: b, to: a) + [polar(Kit.origin, plate49Edge(a), a)]
    }

    private static func plate49At(_ r: Double, _ s: Double) -> P {
        let shown = plate49Shown
        let across = P(-sin(shown), cos(shown)), out = P(cos(shown), sin(shown))
        return r * out + s * across
    }

    /// The bridge over the wheel, cut along one o'clock, with the window through it.
    private static func plate49Bridge() -> [P] {
        [plate49At(0.29, -0.11), plate49At(1.1, -0.11), plate49At(1.1, 0.11), plate49At(0.29, 0.11), plate49At(0.29, -0.11)]
    }

    private static func plate49Hole() -> [P] {
        let window = plate49Window, wide = plate49Wide, deep = plate49Deep
        return [plate49At(window - deep, -wide), plate49At(window + deep, -wide), plate49At(window + deep, wide),
                plate49At(window - deep, wide), plate49At(window - deep, -wide)]
    }

    /// The jumper: a lever pivoted near six, its beak in the root between two teeth past five, a spring at its back.
    private static func plate49Jumper() -> ([P], P, P, [P]) {
        let o = Kit.origin, root = plate49Root
        let rootAngle: Double = plate49Middle(6) - plate49Tau / 2
        let beak = polar(o, root + 0.01, rootAngle), pivot = polar(o, 0.8, Kit.clock(4.35))
        let along = simd_normalize(beak - pivot), side = P(-along.y, along.x)
        let jumper: [P] = [pivot + 0.035 * side, beak - 0.11 * along + 0.03 * side, polar(o, root + 0.13, rootAngle - 0.17),
                           beak, polar(o, root + 0.13, rootAngle + 0.17), beak - 0.11 * along - 0.03 * side,
                           pivot - 0.035 * side, pivot - 0.035 * side - 0.04 * along, pivot + 0.035 * side - 0.04 * along,
                           pivot + 0.035 * side]
        let springPin = polar(o, 0.84, Kit.clock(6.3))
        let spring = curve(springPin, polar(o, 0.8, Kit.clock(5.5)), beak - 0.12 * along - 0.04 * side, 30)
        return (jumper, pivot, springPin, spring)
    }

    /// Each day's segment, shaded its own way, with its numeral on a bone cartouche, read from the arbor.
    private static func plate49Day(_ plate: inout Plate, _ k: Int) {
        let o = Kit.origin, arbor = plate49Arbor, tip = plate49Tip
        let seg = plate49Segment(k), a: Double = plate49Middle(k) - plate49Tau / 2, b: Double = plate49Middle(k) + plate49Tau / 2
        func inside(_ p: P) -> Bool {
            let r = simd_length(p)
            var t = atan2(p.y, p.x)
            while t < a { t += 2 * .pi }
            while t > a + 2 * .pi { t -= 2 * .pi }
            return t < b && r > arbor + 0.02 && r < plate49Edge(t) - 0.02
        }
        func clipped(_ path: [P], _ width: Double, _ ink: Ink = .black) {
            var run: [P] = []
            for p in path {
                if inside(p) { run.append(p) } else { if run.count > 1 { plate.line(run, width, ink) }; run = [] }
            }
            if run.count > 1 { plate.line(run, width, ink) }
        }
        let n = P(cos(plate49Middle(k)), sin(plate49Middle(k))), d = P(-n.y, n.x)
        plate.fill(seg)
        switch k {
        case 0:
            for r in stride(from: 0.0, to: tip, by: 0.12) {
                clipped(stride(from: -0.6, through: 0.6, by: 0.01).map { (t: Double) -> P in (r + 0.7 * abs(t)) * n + t * d }, Kit.boldest)
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
            plate.lines(hatch([seg], angle: plate49Middle(k) - 0.75, gap: 0.17), Kit.boldest)
            plate.lines(hatch([seg], angle: plate49Middle(k) + 0.75, gap: 0.17), Kit.boldest)
        case 5:
            for i in stride(from: 0, to: 14, by: 2) {
                let u: Double = a + (b - a) * (Double(i) + 0.5) / 14, v: Double = a + (b - a) * (Double(i) + 1.5) / 14
                plate.fill(plate49Outline(u, v) + [polar(o, 0.17, v), polar(o, 0.17, u), polar(o, plate49Edge(u), u)], .black)
            }
        default:
            plate.lines(hatch([seg], angle: plate49Middle(k), gap: 0.115), Kit.boldest)
        }
        plate.line(seg, medium)
        let c = polar(o, 0.28, plate49Middle(k))
        if k != 3 {
            plate.fill(arc(c, 0.062))
            plate.line(arc(c, 0.062), medium)
            plate.lines(Kit.numeral(roman(k + 1), at: c, height: 0.062, turn: plate49Middle(k) + .pi / 2, squeeze: 0.75), 0.011)
        }
    }

    /// The rim of the movement's plate, bold, with its seven screws.
    private static func plate49Rim(_ plate: inout Plate) {
        let o = Kit.origin
        Kit.mass(&plate, arc(o, 1.06) + arc(o, 0.9).reversed())
        plate.line(arc(o, 0.925), fine, .bone)
        for k in 0..<7 {
            let m: Double = plate49Middle(k), screw = polar(o, 0.96, m + plate49Tau / 2)
            plate.fill(arc(screw, 0.028))
            plate.line([screw - 0.022 * P(cos(m), sin(m)), screw + 0.022 * P(cos(m), sin(m))], medium)
        }
    }

    /// The bridge, ink, its screws and bevel in bone, and the day in the window.
    private static func plate49Bridged(_ plate: inout Plate, _ bridge: [P], _ hole: [P]) {
        let window = plate49Window, wide = plate49Wide, deep = plate49Deep
        func at(_ r: Double, _ s: Double) -> P { plate49At(r, s) }
        Kit.mass(&plate, bridge)
        plate.line([at(0.31, -0.09), at(1.1, -0.09)], fine, .bone)
        plate.line([at(0.31, 0.09), at(1.1, 0.09)], fine, .bone)
        for r in [0.32, 0.7] {
            plate.fill(arc(at(r, 0), 0.032))
            plate.line(arc(at(r, 0), 0.032), medium)
            plate.line([at(r, -0.026), at(r, 0.026)], medium)
        }
        plate.fill(hole)
        plate.lines(hatch([hole], angle: plate49Shown + 0.3, gap: 0.02), fine)
        let day = at(window, 0)
        plate.fill(box(day - P(0.06, 0.045), day + P(0.06, 0.045)))
        plate.lines(Kit.numeral("IV", at: day, height: 0.075), 0.014)
        let frame: [P] = [at(window - deep - 0.025, -wide - 0.025), at(window + deep + 0.025, -wide - 0.025),
                          at(window + deep + 0.025, wide + 0.025), at(window - deep - 0.025, wide + 0.025),
                          at(window - deep - 0.025, -wide - 0.025)]
        plate.fill(frame + hole.reversed(), .second)
        plate.line(frame, fine)
        plate.line(hole, medium)
    }

    /// The jumper and its spring.
    private static func plate49Spring(_ plate: inout Plate, _ jumper: [P], _ pivot: P, _ springPin: P, _ spring: [P]) {
        Kit.mass(&plate, jumper)
        plate.fill(arc(pivot, 0.03))
        plate.line(arc(pivot, 0.03), medium)
        plate.line([pivot - P(0.02, 0.02), pivot + P(0.02, 0.02)], medium)
        Kit.mass(&plate, Kit.ribbon(spring, 0.028))
        plate.fill(arc(springPin, 0.026))
        plate.line(arc(springPin, 0.026), medium)
    }

    private static let plate50Left: Double = -1.0
    private static let plate50Right: Double = 1.0
    private static let plate50Top: Double = -0.13
    private static let plate50Mid: Double = -0.03
    private static let plate50Bottom: Double = 0.15
    private static let plate50Neck: Double = 0.86
    private static let plate50KC: P = P(0.0, 0.69)
    private static let plate50KD: P = simd_normalize(P(1, -0.14))
    private static let plate50CC: P = P(0.43, -0.47)
    private static let plate50Body: Double = 0.1
    private static let plate50Height: Double = 0.2

    private static func plate50K(_ u: Double, _ v: Double) -> P {
        let kn: P = P(-plate50KD.y, plate50KD.x)
        return plate50KC + u * plate50KD + v * kn
    }

    /// The stick: its top face bone, its side in shadow, its right end whittled to a grip.
    private static func plate50Stick() -> (stick: [P], side: [P]) {
        let left: Double = plate50Left, right: Double = plate50Right, top: Double = plate50Top
        let mid: Double = plate50Mid, bottom: Double = plate50Bottom, neck: Double = plate50Neck
        let stick: [P] = [P(left, top), P(neck, top), P(right, -0.07), P(right, 0.1), P(neck, bottom), P(left, bottom), P(left, top)]
        let side: [P] = [P(left, mid), P(neck, mid), P(right, -0.01), P(right, 0.1), P(neck, bottom), P(left, bottom), P(left, mid)]
        return (stick, side)
    }

    /// The knife below, its edge up.
    private static func plate50Knife() -> (handle: [P], bolster: [P], blade: [P]) {
        let k = plate50K
        let handle: [P] = [k(-0.64, -0.06), k(-0.12, -0.07), k(-0.12, 0.07), k(-0.64, 0.06), k(-0.69, 0.0), k(-0.64, -0.06)]
        let bolster: [P] = [k(-0.12, -0.075), k(-0.05, -0.075), k(-0.05, 0.075), k(-0.12, 0.075), k(-0.12, -0.075)]
        let blade: [P] = [k(-0.05, -0.06), k(0.36, -0.07), k(0.56, -0.045), k(0.64, 0.04), k(0.36, 0.05), k(-0.05, 0.055),
                          k(-0.05, -0.06)]
        return (handle, bolster, blade)
    }

    private static func plate50FlameBase() -> P { plate50CC + P(0, -plate50Height - 0.035) }

    /// The candle stub in its saucer, above the stick past one o'clock.
    private static func plate50Candle() -> (saucer: [P], candle: [P], flame: [P]) {
        let cc: P = plate50CC, body: Double = plate50Body, height: Double = plate50Height
        let saucer: [P] = ellipse(cc, 0.24, 0.07)
        let candle: [P] = [cc + P(-body, 0), cc + P(-body, -height), cc + P(-0.04, -height - 0.018), cc + P(0.03, -height + 0.012),
                           cc + P(body, -height), cc + P(body, 0), cc + P(-body, 0)]
        let fb: P = plate50FlameBase()
        let left: [P] = curve(fb + P(-0.055, 0), fb + P(-0.07, -0.11), fb + P(0.01, -0.23), 14)
        let right: [P] = curve(fb + P(0.01, -0.23), fb + P(0.07, -0.11), fb + P(0.055, 0), 14)
        let base: [P] = curve(fb + P(0.055, 0), fb + P(0, 0.05), fb + P(-0.055, 0), 8)
        return (saucer, candle, left + right + base)
    }

    /// Two shavings curled off by the knife, above the stick past eleven.
    private static func plate50Curls() -> [[P]] {
        let specs: [(P, Double, Double)] = [(P(-0.38, -0.66), 0.17, 0.2), (P(-0.72, -0.46), 0.1, 2.0)]
        return specs.map { (s: (P, Double, Double)) -> [P] in
            (0...80).map { (i: Int) -> P in
                let u: Double = Double(i) / 80
                return polar(s.0, s.1 * (1 - 0.65 * u), s.2 + u * 4.4)
            }
        }
    }

    /// The stick, its grain and its squared end.
    private static func plate50DrawStick(_ plate: inout Plate, _ stick: [P], _ side: [P]) {
        let left: Double = plate50Left, neck: Double = plate50Neck
        Kit.cut(&plate, stick, edge: heavy)
        plate.line([P(left, -0.08), P(-0.25, -0.085)], medium)
        plate.line([P(0.2, -0.09), P(neck, -0.085)], medium)
        Kit.mass(&plate, side)
        let grain: [(Double, Double, Double)] = [(0.03, left, -0.1), (0.1, -0.7, 0.4), (0.04, -0.3, neck), (0.105, 0.3, neck)]
        for (y, a, b) in grain {
            plate.line(curve(P(a, y), P((a + b) / 2, y + 0.015), P(b, y), 16), 0.026, .bone)
        }
    }

    /// Fourteen notches in two bundles of seven, either side of the hub, each a V cut through the top face into the
    /// side; every seventh cut deeper.
    private static func plate50Notches(_ plate: inout Plate, _ notches: [Double]) {
        let top: Double = plate50Top, mid: Double = plate50Mid
        for (i, x) in notches.enumerated() {
            let ink: Ink = i == 13 ? .second : .black, w: Double = 0.034
            let face: [P] = [P(x - w, top), P(x + w, top), P(x + 0.01, mid), P(x - 0.01, mid), P(x - w, top)]
            plate.fill(face, ink)
            plate.line(face, medium)
            let deep: Double = i % 7 == 6 ? 0.1 : 0.065
            let cut: [P] = [P(x - 0.022, mid), P(x + 0.022, mid), P(x, mid + deep), P(x - 0.022, mid)]
            plate.fill(cut, i == 13 ? .second : .bone)
        }
    }

    /// The knife: ink handle with bone rivets, steel bolster, the blade's bevel in ink along its edge.
    private static func plate50DrawKnife(_ plate: inout Plate, _ handle: [P], _ bolster: [P], _ blade: [P]) {
        let k = plate50K
        Kit.mass(&plate, handle)
        plate.line([k(-0.62, -0.035), k(-0.14, -0.042)], fine, .bone)
        for u in [-0.54, -0.37, -0.2] {
            plate.fill(arc(k(u, 0.01), 0.022))
            plate.line(arc(k(u, 0.01), 0.022), fine)
        }
        Kit.solid(&plate, bolster, angle: 1.4, gap: 0.016, width: fine)
        Kit.cut(&plate, blade, edge: heavy)
        let bevel: [P] = [k(-0.05, -0.06), k(0.36, -0.07), k(0.56, -0.045), k(0.55, -0.01), k(0.34, -0.015), k(-0.05, -0.012),
                          k(-0.05, -0.06)]
        Kit.mass(&plate, bevel)
        plate.line([k(-0.02, 0.02), k(0.36, 0.025)], medium)
    }

    /// The candle, shadowed on its right, a drip down its left, its flame with a bone heart.
    private static func plate50DrawCandle(_ plate: inout Plate, _ saucer: [P], _ candle: [P], _ flame: [P]) {
        let cc: P = plate50CC, body: Double = plate50Body, height: Double = plate50Height
        let flameBase: P = plate50FlameBase()
        Kit.cut(&plate, saucer, edge: heavy)
        let shadow: [P] = ellipse(cc + P(0, 0.035), 0.22, 0.04, from: 0.15, to: .pi - 0.15) + [cc + P(-0.2, 0.05)]
        Kit.mass(&plate, shadow)
        let dripPath: [P] = curve(cc + P(0.24, 0), cc + P(0.36, -0.02), cc + P(0.34, 0.07), 10)
        Kit.mass(&plate, Kit.ribbon(dripPath, 0.035))
        Kit.mass(&plate, ellipse(cc, 0.15, 0.035))
        Kit.cut(&plate, candle, edge: heavy)
        let dark: [P] = [cc + P(0.035, 0), cc + P(0.035, -height + 0.009), cc + P(body, -height), cc + P(body, 0), cc + P(0.035, 0)]
        Kit.mass(&plate, dark)
        let strip: [P] = [cc + P(-0.01, 0), cc + P(-0.01, -height + 0.01), cc + P(0.035, -height + 0.008), cc + P(0.035, 0),
                          cc + P(-0.01, 0)]
        plate.lines(hatch([strip], angle: .pi / 2, gap: 0.016), fine)
        let dripLeft: [P] = curve(cc + P(-0.07, -height), cc + P(-0.085, -height + 0.07), cc + P(-0.07, -height + 0.12), 8)
        Kit.mass(&plate, Kit.ribbon(dripLeft, 0.028))
        plate.line([cc + P(0, -height - 0.005), flameBase], heavy)
        Kit.mass(&plate, flame)
        plate.fill(ellipse(flameBase + P(0, -0.05), 0.018, 0.045))
    }

    /// Problem 50, Fortnight, hex, clocks 1+,2+,3+: a tally stick along three and nine o'clock, cut with two bundles
    /// of seven notches either side of the hub, the knife that cut them below and a candle stub and shavings above; the
    /// last notch in the second ink.
    static func plate50() -> Plate {
        var plate = Plate()
        let (stick, side) = plate50Stick()
        let (handle, bolster, blade) = plate50Knife()
        let (saucer, candle, flame) = plate50Candle()
        let curls: [[P]] = plate50Curls()
        let flameBase: P = plate50FlameBase()

        let shapes: [[P]] = [stick, handle, bolster, blade, saucer, candle, flame]
        let ribbons: [[P]] = curls.map { (c: [P]) -> [P] in Kit.ribbon(c, 0.07) }
        Kit.ground(&plate, angle: 0.5, around: shapes + ribbons)

        plate50DrawStick(&plate, stick, side)
        let pitch: Double = 0.09
        let notches: [Double] = (0..<14).map { (i: Int) -> Double in
            let from: Double = i < 7 ? -0.88 : 0.25
            return from + Double(i < 7 ? i : i - 7) * pitch
        }
        plate50Notches(&plate, notches)
        plate50DrawKnife(&plate, handle, bolster, blade)
        plate50DrawCandle(&plate, saucer, candle, flame)

        // The shavings, their outer face bone and their inner face ink.
        for curl in curls {
            Kit.mass(&plate, Kit.ribbon(curl, 0.065))
            plate.line(Array(curl[4..<(curl.count - 10)]), 0.012, .bone)
        }

        callout(&plate, "A", from: P(notches[1], plate50Top + 0.03), to: P(-0.78, 0.4))
        callout(&plate, "B", from: plate50K(0.2, 0.02), to: P(0.6, 0.38))
        callout(&plate, "C", from: flameBase + P(0, -0.1), to: P(0.66, -0.8))
        return plate
    }

    private static let plate51C1: P = P(0.0, 0.0)
    private static let plate51R1: Double = 0.68
    private static let plate51C2: P = P(0.34, 0.0)
    private static let plate51R2: Double = 0.63
    private static let plate51Rx: Double = 0.88
    private static let plate51Ry: Double = 0.82
    private static let plate51Disc: Double = 0.042
    /// Stars past the rim, in the corners the orbit leaves.
    private static let plate51Stars: [P] = [P(0.72, -0.72), P(-0.74, 0.7), P(0.72, 0.72), P(-0.72, -0.74), P(0.5, -0.4), P(0.52, 0.36),
                                            P(0.2, -0.24), P(0.24, 0.2)]

    private static func plate51Bump(_ t: Double, _ at: Double, _ w: Double, _ h: Double) -> Double { h * exp(-pow((t - at) / w, 2)) }

    private static func plate51Dent(_ t: Double) -> Double {
        let nose: Double = max(0, 1 - abs(t - .pi + 0.01) / 0.075) * 0.14
        var sum: Double = nose
        sum += plate51Bump(t, .pi + 0.36, 0.16, 0.06)
        sum += plate51Bump(t, .pi + 0.2, 0.05, 0.03)
        sum += plate51Bump(t, .pi - 0.17, 0.035, 0.045)
        sum += plate51Bump(t, .pi - 0.26, 0.03, 0.04)
        sum += plate51Bump(t, .pi - 0.42, 0.07, 0.075)
        sum += plate51Bump(t, .pi - 0.08, 0.04, 0.02)
        return sum
    }

    private static func plate51Day(_ i: Int) -> P {
        let t: Double = -2 * .pi * Double(i) / 29
        return P(plate51Rx * cos(t), plate51Ry * sin(t))
    }

    private static func plate51Star(_ c: P, _ r: Double) -> [P] {
        (0...10).map { (i: Int) -> P in
            let reach: Double = i % 2 == 0 ? r : 0.4 * r
            return polar(c, reach, -.pi / 2 + Double(i) * .pi / 5)
        }
    }

    /// The crescent: the outer disc less an inner one set to the right, the inner edge cut as a face.
    private static func plate51Moon() -> [P] {
        let c1: P = plate51C1, r1: Double = plate51R1, c2: P = plate51C2, r2: Double = plate51R2
        let outer: [P] = arc(c1, r1, from: -.pi, to: .pi).filter { (p: P) -> Bool in simd_distance(p, c2) > r2 }
        let inner: [P] = stride(from: .pi - 1.7, through: .pi + 1.7, by: 0.01).map { (t: Double) -> P in
            polar(c2, r2 - plate51Dent(t), t)
        }.filter { (p: P) -> Bool in simd_distance(p, c1) < r1 }
        // Start the outer arc just after its gap so it runs top tip to bottom tip round the left.
        let gap: Int = outer.indices.dropFirst().first { (i: Int) -> Bool in simd_distance(outer[i], outer[i - 1]) > 0.05 } ?? 0
        let rim: [P] = Array(outer[gap...] + outer[..<gap])
        return rim + inner.reversed() + [rim[0]]
    }

    /// The moon: ink, a bone line along its lit limb, the face's eye, brow, nostril and lips cut in bone, and
    /// craters on its back.
    private static func plate51DrawMoon(_ plate: inout Plate, _ moon: [P]) {
        let c1: P = plate51C1, r1: Double = plate51R1, c2: P = plate51C2, r2: Double = plate51R2
        Kit.mass(&plate, moon)
        for r in stride(from: r1 - 0.035, to: r1 - 0.4, by: -0.05) {
            var run: [P] = []
            for p in arc(c1, r, from: -.pi, to: .pi) + [polar(c1, r, -.pi)] {
                if simd_distance(p, c2) > r2 + 0.05 { run.append(p) } else { if run.count > 1 { plate.line(run, 0.028, .bone) }; run = [] }
            }
            if run.count > 1 { plate.line(run, 0.028, .bone) }
        }
        let face = { (t: Double, d: Double) -> P in polar(c2, r2 - plate51Dent(t) + d, t) }
        let eye: P = face(.pi + 0.13, 0.06)
        plate.fill(ellipse(eye, 0.03, 0.014, turned: -0.15))
        plate.fill(arc(eye + P(0.012, 0), 0.009), .black)
        plate.line([face(.pi + 0.24, 0.03), face(.pi + 0.18, 0.07), face(.pi + 0.08, 0.075)], 0.012, .bone)
        plate.line(curve(face(.pi - 0.01, 0.1), face(.pi - 0.07, 0.075), face(.pi - 0.08, 0.045), 6), 0.01, .bone)
        plate.line([face(.pi - 0.215, 0.0), face(.pi - 0.215, 0.05)], 0.01, .bone)
        plate.line(curve(face(.pi - 0.34, 0.06), face(.pi - 0.46, 0.13), face(.pi - 0.6, 0.06), 10), 0.01, .bone)
    }

    /// The days, each a disc lit as the moon is that day.
    private static func plate51Days(_ plate: inout Plate) {
        let disc: Double = plate51Disc
        for i in 0..<29 {
            let c: P = plate51Day(i), phase: Double = 2 * .pi * Double(i) / 29
            plate.fill(arc(c, disc))
            if i == 0 {
                plate.fill(arc(c, disc + 0.012), .second)
            } else {
                let k: Double = phase < .pi ? cos(phase) : -cos(phase), side: Double = phase < .pi ? -1.0 : 1.0
                let limb: [P] = stride(from: -0.5 * .pi, through: 0.5 * .pi, by: 0.1).map { (t: Double) -> P in
                    P(side * disc * cos(t), disc * sin(t))
                }
                let term: [P] = stride(from: 0.5 * .pi, through: -0.5 * .pi, by: -0.1).map { (t: Double) -> P in
                    P(k * disc * cos(t), disc * sin(t))
                }
                plate.fill((limb + term).map { (p: P) -> P in p + c }, .black)
            }
            plate.line(arc(c, disc), medium)
        }
    }

    /// Problem 51, Lunar month, hex, clocks 1+,2-,3+: a crescent moon in solid ink with a face in profile looking into
    /// its hollow, round it an ellipse of its orbit with the month's twenty-nine days as dots, each in its phase, and
    /// bold stars past the rim; the new moon's dot, at three o'clock, in the second ink.
    static func plate51() -> Plate {
        var plate = Plate()
        let moon: [P] = plate51Moon()
        let stars: [P] = plate51Stars

        let discs: [[P]] = (0..<29).map { (i: Int) -> [P] in arc(plate51Day(i), plate51Disc + 0.012) }
        let starShapes: [[P]] = stars.enumerated().map { (e: (offset: Int, element: P)) -> [P] in
            plate51Star(e.element, e.offset < 4 ? 0.07 : 0.05)
        }
        Kit.ground(&plate, angle: -0.45, around: [moon] + discs + starShapes)

        plate.line(ellipse(Kit.origin, plate51Rx, plate51Ry), 0.012)

        plate51DrawMoon(&plate, moon)
        plate51Days(&plate)

        for (i, c) in stars.enumerated() { Kit.mass(&plate, plate51Star(c, i < 4 ? 0.07 : 0.05)) }

        callout(&plate, "A", from: P(-0.6, 0.12), to: P(-0.34, 0.48))
        callout(&plate, "B", from: plate51Day(11), to: P(-0.36, -0.46))
        return plate
    }

    private static let plate52Tilt: Double = Double.pi / 6
    private static let plate52SC: P = P(-0.38, 0.0)
    private static let plate52SR: Double = 0.27
    private static let plate52Left: Double = 0.1
    private static let plate52Right: Double = 0.66
    private static let plate52High: Double = -0.32
    private static let plate52Low: Double = 0.3

    private static func plate52Q(_ points: [P]) -> [P] { turned(points, by: plate52Tilt) }
    private static func plate52Q(_ p: P) -> P { turned([p], by: plate52Tilt)[0] }

    /// A page, left or right, in the book's own frame: spine up the middle, the far edge rising in perspective.
    private static func plate52Page(_ side: Double, _ d: Double) -> [P] {
        let top: [P] = curve(P(0, -0.42 + d), P(side * 0.34, -0.53 + d), P(side * (0.68 + d), -0.5 + 0.8 * d), 16)
        let bottom: [P] = curve(P(side * (0.82 + d), 0.44 + d), P(side * 0.4, 0.52 + d), P(0, 0.42 + d), 16)
        return plate52Q(top + bottom + [top[0]])
    }

    private static func plate52Board() -> [P] {
        plate52Q([P(-0.88, -0.44), P(0, -0.4), P(0.88, -0.44), P(0.98, 0.56), P(0, 0.56), P(-0.98, 0.56), P(-0.88, -0.44)])
    }

    private static func plate52Book(_ plate: inout Plate, _ board: [P]) {
        let q = plate52Q as ([P]) -> [P]
        Kit.mass(&plate, board)
        for side in [-1.0, 1.0] {
            for i in stride(from: 3, through: 1, by: -1) {
                let d: Double = 0.03 * Double(i)
                if i % 2 == 1 { Kit.cut(&plate, plate52Page(side, d)) } else { Kit.mass(&plate, plate52Page(side, d)) }
            }
            Kit.cut(&plate, plate52Page(side, 0), edge: heavy)
        }
        // The shadow in the spine's fold, and the fold.
        for side in [-1.0, 1.0] {
            let fold: [P] = curve(P(0, -0.42), P(side * 0.07, 0), P(0, 0.42), 16) + [P(0, -0.42)]
            Kit.mass(&plate, q(fold))
        }
        plate.line(q(curve(P(0, -0.42), P(0.012, 0), P(0, 0.42), 12)), heavy)
        let edgeL: [P] = q(curve(P(-0.03, -0.41), P(-0.04, 0), P(-0.03, 0.41), 12))
        let edgeR: [P] = q(curve(P(0.03, -0.41), P(0.04, 0), P(0.03, 0.41), 12))
        plate.lines([edgeL, edgeR], fine)

        // Each page's printed head: a bold rule over a fine one.
        for side in [-1.0, 1.0] {
            Kit.mass(&plate, q(Kit.band(P(side * 0.1, -0.415), P(side * 0.6, -0.445), 0.04)))
            plate.line(q([P(side * 0.1, -0.375), P(side * 0.6, -0.4)]), medium)
        }
    }

    /// The star chart: a planisphere's rim, its meridians, and constellations in bold.
    private static func plate52Chart(_ plate: inout Plate) {
        let q = plate52Q as ([P]) -> [P]
        let sc: P = plate52SC, sr: Double = plate52SR
        plate.line(q(arc(sc, sr)), 0.02)
        plate.line(q(arc(sc, sr - 0.035)), medium)
        for k in 0..<24 {
            let a: Double = Double(k) * .pi / 12
            let outer: Double = sr - (k % 2 == 0 ? 0.0 : 0.018)
            plate.line(q([polar(sc, sr - 0.035, a), polar(sc, outer, a)]), k % 2 == 0 ? medium : fine)
        }
        for k in 0..<6 {
            let a: Double = Double(k) * .pi / 6
            plate.line(q([polar(sc, 0.03, a), polar(sc, sr - 0.035, a)]), fine)
        }
        for k in 0..<6 {
            let a: Double = Double(k) * .pi / 6 + .pi
            plate.line(q([polar(sc, 0.03, a), polar(sc, sr - 0.035, a)]), fine)
        }
        plate.line(q(arc(sc, 0.12)), fine)
        let figures: [[P]] = [
            [P(-0.52, -0.12), P(-0.46, -0.16), P(-0.4, -0.13), P(-0.34, -0.17), P(-0.28, -0.1)],
            [P(-0.5, 0.1), P(-0.44, 0.04), P(-0.38, 0.08), P(-0.42, 0.16), P(-0.5, 0.1)],
            [P(-0.3, 0.02), P(-0.25, 0.1), P(-0.22, 0.18)],
        ]
        for figure in figures {
            plate.line(q(figure), medium)
            for (i, p) in figure.enumerated() where i == 0 || p != figure[0] {
                let r: Double = i % 2 == 0 ? 0.03 : 0.022
                let points: [P] = (0...8).map { (j: Int) -> P in
                    let reach: Double = j % 2 == 0 ? r : 0.35 * r
                    return polar(p, reach, -.pi / 2 + Double(j) * .pi / 4)
                }
                Kit.mass(&plate, q(points))
            }
        }
        Kit.mass(&plate, q(arc(sc, 0.022)))
    }

    private static func plate52Tide() -> [P] {
        let left: Double = plate52Left, right: Double = plate52Right
        return stride(from: left, through: right, by: 0.01).map { (x: Double) -> P in
            P(x, 0.0 - 0.13 * sin((x - left) / (right - left) * 4 * .pi + 0.6))
        }
    }

    /// The tide table: ruled columns headed by the hours, the tide's curve in ink and the water under it ruled bold.
    private static func plate52Table(_ plate: inout Plate, _ tide: [P]) {
        let q = plate52Q as ([P]) -> [P]
        let left: Double = plate52Left, right: Double = plate52Right, high: Double = plate52High, low: Double = plate52Low
        for (i, x) in stride(from: left, through: right, by: (right - left) / 6).enumerated() {
            plate.line(q([P(x, high), P(x, low)]), i == 0 || i == 6 ? medium : fine)
            if i < 6 {
                let numeral: [[P]] = Kit.numeral(roman(i + 1), at: P(x + (right - left) / 12, high - 0.04), height: 0.045, squeeze: 0.8)
                plate.lines(numeral.map { (l: [P]) -> [P] in q(l) }, medium)
            }
        }
        plate.line(q([P(left, high), P(right, high)]), medium)
        plate.line(q([P(left, low), P(right, low)]), medium)
        for y in stride(from: high + 0.1, to: low, by: 0.1) { plate.line(q([P(left, y), P(right, y)]), fine) }
        let water: [P] = tide + [P(right, low), P(left, low), tide[0]]
        plate.lines(hatch([q(water)], angle: plate52Tilt, gap: 0.055), 0.022)
        plate.line(q(tide), 0.026)
        // Print below the table.
        for (i, y) in stride(from: 0.36, through: 0.42, by: 0.03).enumerated() {
            plate.lines(dashed(q([P(left, y), P(right - 0.05 * Double(i), y)]), on: 0.05, off: 0.015), fine)
        }
        for (i, y) in stride(from: 0.33, through: 0.42, by: 0.03).enumerated() {
            plate.lines(dashed(q([P(-0.66 + 0.02 * Double(i), y), P(-0.12, y)]), on: 0.045, off: 0.015), fine)
        }
    }

    /// The ribbon from the foot of the spine, out over the board and down past seven, swallow-tailed.
    private static func plate52Ribbon(_ plate: inout Plate) {
        let path: [P] = plate52Q(curve(P(0, 0.3), P(0.06, 0.62), P(-0.02, 0.86), 20))
        let ribbon: [P] = Kit.ribbon(path, 0.055)
        plate.fill(ribbon, .second)
        plate.line(ribbon, medium)
        let end: P = path[path.count - 1], dir: P = simd_normalize(end - path[path.count - 2]), across: P = P(-dir.y, dir.x)
        let w: Double = 0.0275
        let tail: [P] = [end + w * across, end + w * across + 0.06 * dir, end + 0.025 * dir, end - w * across + 0.06 * dir,
                         end - w * across, end + w * across]
        plate.fill(tail, .second)
        plate.line(tail, medium)
    }

    /// Problem 52, Almanac, hex, clocks 1+,3+,5+: an almanac lying open, its spine along one and seven o'clock, its
    /// pages fanned in bold over an ink board, a star chart engraved on the left page and a tide table with its curve on
    /// the right; the ribbon bookmark hanging from the foot of the spine in the second ink.
    static func plate52() -> Plate {
        var plate = Plate()
        let board: [P] = plate52Board()
        let tide: [P] = plate52Tide()

        Kit.ground(&plate, angle: -0.8, around: [board])
        plate52Book(&plate, board)
        plate52Chart(&plate)
        plate52Table(&plate, tide)
        plate52Ribbon(&plate)

        callout(&plate, "A", from: plate52Q(polar(plate52SC, plate52SR, -2.2)), to: plate52Q(P(-0.36, -0.66)))
        callout(&plate, "B", from: plate52Q(tide[30]), to: plate52Q(P(0.56, -0.66)))
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

    private static let plate54Pivot: P = P(0, -0.78)
    private static let plate54Reach: Double = 0.72
    private static let plate54Drop: Double = 0.52
    private static let plate54PanY: Double = 0.12
    private static let plate54PanW: Double = 0.2
    private static let plate54SunC: P = P(-0.72, 0.12 - 0.12)
    private static let plate54MoonC: P = P(0.72, 0.12 - 0.12)

    private static func plate54Beam() -> [P] {
        let reach: Double = plate54Reach, drop: Double = plate54Drop
        return [P(-reach - 0.02, -drop - 0.02), P(-0.1, -0.78), P(0, -0.81), P(0.1, -0.78), P(reach + 0.02, -drop - 0.02),
                P(reach + 0.02, -drop + 0.02), P(0.1, -0.735), P(0, -0.745), P(-0.1, -0.735), P(-reach - 0.02, -drop + 0.02),
                P(-reach - 0.02, -drop - 0.02)]
    }
    private static let plate54Pillar: [P] = [P(-0.035, -0.72), P(0.035, -0.72), P(0.048, 0.7), P(-0.048, 0.7), P(-0.035, -0.72)]
    private static let plate54Capital: [P] = [P(-0.08, -0.745), P(0.08, -0.745), P(0.05, -0.69), P(-0.05, -0.69), P(-0.08, -0.745)]
    private static let plate54Plinth: [P] = [P(-0.26, 0.7), P(0.26, 0.7), P(0.26, 0.76), P(-0.26, 0.76), P(-0.26, 0.7)]
    private static let plate54Steps: [P] = [P(-0.34, 0.76), P(0.34, 0.76), P(0.34, 0.84), P(0.44, 0.84), P(0.44, 1.1), P(-0.44, 1.1),
                                            P(-0.44, 0.84), P(-0.34, 0.84), P(-0.34, 0.76)]

    private static func plate54Pan(_ x: Double) -> [P] {
        ellipse(P(x, plate54PanY), plate54PanW, 0.13, from: 0, to: .pi) + [P(x - plate54PanW, plate54PanY)]
    }

    /// Day on the left, night on the right.
    private static func plate54Ground(_ plate: inout Plate, _ beam: [P]) {
        let reach: Double = plate54Reach
        let day: [P] = box(P(-1.1, -1.1), P(0, 1.1)), night: [P] = box(P(0, -1.1), P(1.1, 1.1))
        let parts: [[P]] = [beam, plate54Pillar, plate54Capital, plate54Plinth, plate54Steps, plate54Pan(-reach), plate54Pan(reach),
                            arc(plate54SunC, 0.17), arc(plate54MoonC, 0.15)]
        plate.lines(hatch([day] + parts, angle: 0.4, gap: Kit.groundGap), Kit.groundWidth)
        plate.lines(hatch([night] + parts, angle: -0.4, gap: Kit.groundGap), 0.02)
    }

    private static func plate54Stars(_ plate: inout Plate) {
        let specs: [(P, Double)] = [(P(0.3, -0.4), 0.03), (P(0.62, -0.68), 0.025), (P(0.3, 0.46), 0.022), (P(0.7, 0.58), 0.03),
                                    (P(0.22, -0.1), 0.02)]
        for (c, r) in specs {
            let st: [P] = (0...10).map { (i: Int) -> P in
                let reach: Double = i % 2 == 0 ? r : 0.4 * r
                return polar(c, reach, -.pi / 2 + Double(i) * .pi / 5)
            }
            plate.fill(arc(c, r + 0.018))
            Kit.mass(&plate, st)
        }
    }

    /// The chains from the beam's ends to each pan's rim.
    private static func plate54Chains(_ plate: inout Plate) {
        let reach: Double = plate54Reach, drop: Double = plate54Drop, panW: Double = plate54PanW
        for x in [-reach, reach] {
            let hook: P = P(x, -drop + 0.02)
            for dx in [-panW + 0.02, 0.0, panW - 0.02] {
                plate.lines(dashed([hook, P(x + dx, plate54PanY)], on: 0.03, off: 0.012), 0.014)
            }
            Kit.mass(&plate, arc(hook + P(0, 0.03), 0.022))
        }
    }

    /// The sun in the left pan, its rays ink about a bone disc; the moon in the right, a crescent in ink.
    private static func plate54Bodies(_ plate: inout Plate) {
        let sunC: P = plate54SunC, moonC: P = plate54MoonC
        for k in 0..<12 {
            let a: Double = Double(k) * .pi / 6
            let ray: [P] = [polar(sunC, 0.1, a - 0.18), polar(sunC, 0.17, a), polar(sunC, 0.1, a + 0.18), polar(sunC, 0.1, a - 0.18)]
            Kit.mass(&plate, ray)
        }
        plate.fill(arc(sunC, 0.1))
        plate.line(arc(sunC, 0.1), heavy)
        plate.lines(hatch([arc(sunC, 0.07)], angle: 0.8, gap: 0.022), medium)
        plate.line(arc(sunC, 0.07), medium)
        let limb: [P] = arc(moonC, 0.14, from: -.pi / 2 + 0.35, to: -1.5 * .pi - 0.35)
        let moon: [P] = limb + curve(limb[limb.count - 1], moonC + P(-0.1, 0), limb[0], 16)
        Kit.mass(&plate, moon)
        plate.line(arc(moonC, 0.12, from: -.pi / 2 - 0.5, to: -1.5 * .pi + 0.5), 0.01, .bone)
    }

    /// The pans, solid ink with a bone rim line.
    private static func plate54Pans(_ plate: inout Plate) {
        let reach: Double = plate54Reach, panW: Double = plate54PanW, panY: Double = plate54PanY
        for x in [-reach, reach] {
            Kit.mass(&plate, plate54Pan(x))
            plate.line(ellipse(P(x, panY), panW - 0.02, 0.1, from: 0.15, to: .pi - 0.15), medium, .bone)
            plate.line([P(x - panW - 0.01, panY), P(x + panW + 0.01, panY)], heavy)
        }
    }

    /// The pillar, fluted in bone, its capital and stepped plinth, then the beam.
    private static func plate54Column(_ plate: inout Plate, _ beam: [P]) {
        let reach: Double = plate54Reach, drop: Double = plate54Drop
        Kit.mass(&plate, plate54Pillar)
        plate.line([P(-0.015, -0.72), P(-0.02, 0.6)], 0.01, .bone)
        plate.line([P(0.015, -0.72), P(0.02, 0.6)], 0.01, .bone)
        Kit.solid(&plate, plate54Plinth, angle: .pi / 2, gap: 0.04, width: 0.016, edge: heavy)
        Kit.solid(&plate, plate54Steps, angle: 0, gap: 0.05, width: 0.016, edge: heavy)
        plate.line([P(-0.34, 0.84), P(0.34, 0.84)], heavy)
        Kit.mass(&plate, plate54Capital)
        Kit.mass(&plate, beam)
        plate.line([P(-reach + 0.02, -drop - 0.002), P(-0.1, -0.777), P(0.1, -0.777), P(reach - 0.02, -drop - 0.002)], fine, .bone)
    }

    /// The index arc above the pivot and the pointer standing upright against it.
    private static func plate54Index(_ plate: inout Plate) {
        let pivot: P = plate54Pivot
        plate.line(arc(pivot, 0.13, from: -.pi / 2 - 0.4, to: -.pi / 2 + 0.4), heavy)
        for k in -3...3 {
            let a: Double = -.pi / 2 + Double(k) * 0.12
            plate.line([polar(pivot, 0.13, a), polar(pivot, k == 0 ? 0.17 : 0.155, a)], k == 0 ? heavy : medium)
        }
        let pointer: [P] = [P(-0.02, -0.78), P(0, -0.91), P(0.02, -0.78), P(-0.02, -0.78)]
        plate.fill(pointer, .second)
        plate.line(pointer, medium)
        plate.fill(arc(pivot, 0.03))
        plate.line(arc(pivot, 0.03), heavy)
        plate.fill(arc(pivot, 0.01), .black)
    }

    /// Problem 54, Equinox, hex, clocks 1+,3+,5+: a balance with its pans level, the sun in the left and the moon in
    /// the right, its beam, pillar and plinth in ink, before a ground ruled lightly for day on the left and heavily for
    /// night on the right; the pointer at the top of the balance, above twelve's hub, in the second ink.
    static func plate54() -> Plate {
        var plate = Plate()
        let beam: [P] = plate54Beam()

        plate54Ground(&plate, beam)
        plate54Stars(&plate)
        plate54Chains(&plate)
        plate54Bodies(&plate)
        plate54Pans(&plate)
        plate54Column(&plate, beam)
        plate54Index(&plate)

        callout(&plate, "A", from: plate54SunC + P(0.06, 0.06), to: P(-0.46, 0.0))
        callout(&plate, "B", from: plate54MoonC + P(-0.02, 0.1), to: P(0.42, 0.06))
        callout(&plate, "C", from: P(0.0, 0.36), to: P(-0.26, 0.5))
        return plate
    }
}
