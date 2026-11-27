// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 15, Perpetual: problems 85 to 90's plates, drawn with `Kit`.
extension EscapementArt {
    /// Problem 85, Regulator, hex, clocks 1+: a regulator's gridiron pendulum caught near the end of its beat, hung
    /// from its cock between the case's fluted ebony stiles, its steel bars in ink and its brass in bone, the lens bob
    /// below and the beat scale under it; the beat scale's index in the second ink.
    static func plate85() -> Plate {
        var plate = Plate()
        plate85Stiles(&plate)
        plate85Cock(&plate)
        plate85Gridiron(&plate)
        plate85Rod(&plate)
        let o: P = Kit.origin, pivot: P = plate85Pivot
        callout(&plate, "A", from: plate85At(-0.24, 0.55), to: polar(o, 0.56, Kit.clock(9)))
        callout(&plate, "B", from: plate85At(0.12, 0.9), to: polar(o, 0.56, Kit.clock(3)))
        callout(&plate, "C", from: plate85At(0.12, 1.79), to: P(0.46, 0.66))
        callout(&plate, "D", from: polar(pivot, 1.91, .pi / 2 + 0.12), to: P(-0.44, 0.7))
        return plate
    }

    private static let plate85Pivot: P = P(0, -0.99)
    private static let plate85Tilt: Double = 0.03
    private static let plate85Top: Double = 0.16
    private static let plate85Foot: Double = 1.2
    private static let plate85Bar: Double = 0.06
    private static let plate85Pitch: Double = 0.12

    private static func plate85At(_ u: Double, _ v: Double) -> P {
        let tilt: Double = plate85Tilt
        return plate85Pivot + P(u * cos(tilt) + v * sin(tilt), -u * sin(tilt) + v * cos(tilt))
    }

    private static func plate85Box(_ u0: Double, _ v0: Double, _ u1: Double, _ v1: Double) -> [P] {
        [plate85At(u0, v0), plate85At(u1, v0), plate85At(u1, v1), plate85At(u0, v1), plate85At(u0, v0)]
    }

    private static let plate85Bob: [P] = ellipse(plate85At(0, 1.81), 0.19, 0.07, turned: -plate85Tilt)

    /// Plate 85's case stiles, ebony, each fluted.
    private static func plate85Stiles(_ plate: inout Plate) {
        let o: P = Kit.origin, top: Double = plate85Top, foot: Double = plate85Foot
        let edge: Double = acos(-0.64 / 1.06)
        let stile: [P] = arc(o, 1.06, from: edge, to: 2 * .pi - edge) + [polar(o, 1.06, edge)]
        Kit.ground(&plate, angle: -0.5, around: [plate85Box(-0.31, top, 0.31, foot), plate85Bob])
        for side in [-1.0, 1.0] {
            Kit.mass(&plate, stile.map { (p: P) -> P in P(p.x * -side, p.y) })
            plate.line([P(0.67 * side, -0.83), P(0.67 * side, 0.83)], heavy, .bone)
            for x in [0.74, 0.82, 0.9] {
                let h: Double = sqrt(1.0 - (x + 0.03) * (x + 0.03)) - 0.08
                plate.fill(Kit.band(P(x * side, -h), P(x * side, h), 0.024), .bone)
                plate.line([P(x * side + 0.006 * side, -h + 0.02), P(x * side + 0.006 * side, h - 0.02)], fine)
            }
        }
    }

    /// Plate 85's cock the pendulum hangs from, its spring and chops.
    private static func plate85Cock(_ plate: inout Plate) {
        Kit.mass(&plate, [P(-0.32, -1.12), P(0.32, -1.12), P(0.24, -0.93), P(-0.24, -0.93), P(-0.32, -1.12)])
        for x in [-0.16, 0.16] {
            plate.fill(arc(P(x, -0.975), 0.02))
            plate.line([P(x - 0.014, -0.975), P(x + 0.014, -0.975)], medium)
        }
        Kit.solid(&plate, plate85Box(-0.022, 0.04, 0.022, 0.1), angle: 0, gap: 0.012, width: fine)
        Kit.mass(&plate, plate85Box(-0.07, 0.09, 0.07, 0.13))
    }

    /// Plate 85's gridiron: steel in ink, brass in bone, held by its crossbars.
    private static func plate85Gridiron(_ plate: inout Plate) {
        let top: Double = plate85Top, foot: Double = plate85Foot, bar: Double = plate85Bar, pitch: Double = plate85Pitch
        let bars: [[P]] = [-2.0, -1, 0, 1, 2].map { (u: Double) -> [P] in plate85Box(u * pitch - bar / 2, top, u * pitch + bar / 2, foot) }
        for (k, ring) in bars.enumerated() {
            if k % 2 == 0 {
                Kit.mass(&plate, ring)
                plate.line([plate85At(Double(k - 2) * pitch - 0.012, top + 0.04), plate85At(Double(k - 2) * pitch - 0.012, foot - 0.04)], fine, .bone)
            } else {
                let u: Double = Double(k - 2) * pitch
                plate.fill(ring)
                plate.line(ring, heavy)
                plate.line([plate85At(u + 0.01, top + 0.03), plate85At(u + 0.01, foot - 0.03)], fine)
                for v in stride(from: 0.24, to: foot - 0.04, by: 0.1) { plate.line([plate85At(u - 0.018, v), plate85At(u - 0.004, v)], fine) }
            }
        }
        for (v0, v1, w) in [(top - 0.07, top + 0.01, 0.31), (0.29, 0.35, 0.18), (0.7, 0.76, 0.18), (foot - 0.01, foot + 0.07, 0.31)] {
            Kit.mass(&plate, plate85Box(-w, v0, w, v1))
            let pins: [Double] = w > 0.2 ? [-0.24, -0.12, 0.12, 0.24] : [-0.12, 0.12]
            for u in pins { plate.fill(arc(plate85At(u, (v0 + v1) / 2), 0.012)) }
        }
    }

    /// Plate 85's rod on down to the rating nut and the lens bob, and the beat scale under it with its index.
    private static func plate85Rod(_ plate: inout Plate) {
        let pivot: P = plate85Pivot, foot: Double = plate85Foot, tilt: Double = plate85Tilt
        // The rod on down to the rating nut and the lens bob, lit across its upper left.
        Kit.mass(&plate, plate85Box(-0.02, foot + 0.07, 0.02, 1.76))
        Kit.solid(&plate, plate85Box(-0.042, 1.66, 0.042, 1.71), angle: tilt + .pi / 2, gap: 0.012, width: fine)
        Kit.mass(&plate, plate85Bob)
        plate.fill(ellipse(plate85At(-0.055, 1.79), 0.085, 0.018, turned: -tilt - 0.08), .bone)

        // The beat scale, its degrees either side of the rest, and the index under the bob reading it.
        let outerEdge: [P] = arc(pivot, 1.935, from: .pi / 2 + 0.14, to: .pi / 2 - 0.14)
        let innerEdge: [P] = arc(pivot, 1.88, from: .pi / 2 - 0.14, to: .pi / 2 + 0.14)
        let scale: [P] = outerEdge + innerEdge
        Kit.cut(&plate, scale + [scale[0]], edge: heavy)
        for k in -6...6 {
            let a: Double = .pi / 2 + Double(k) * 0.02
            plate.line([polar(pivot, 1.88, a), polar(pivot, k % 3 == 0 ? 1.925 : 1.905, a)], k == 0 ? heavy : medium)
        }
        Kit.mass(&plate, [plate85At(-0.025, 1.85), plate85At(0.025, 1.85), plate85At(0, 1.925), plate85At(-0.025, 1.85)], ink: .second)
    }

    /// Problem 86, Chronometer, hex, clocks 1+: a marine chronometer seen from above and before in its box, the lid
    /// thrown back and the box rolled as at sea, while its two gimbal rings, in ink, hold the bowl and dial level: the
    /// dial's seconds below and its power reserve above, whose hand is in the second ink.
    static func plate86() -> Plate {
        var plate = Plate()
        Kit.ground(&plate, angle: 0.6)
        plate86Lid(&plate)
        plate86Box(&plate)
        plate86Gimbals(&plate)
        plate86Bowl(&plate)
        let o: P = Kit.origin
        let reserve: P = plate86Reserve
        callout(&plate, "A", from: plate86View(plate86Rolled(Q86(-0.925 * cos(0.7), -0.925 * sin(0.7), -0.16))),
                to: polar(o, 0.62, Kit.clock(7)))
        callout(&plate, "B", from: plate86View(Q86(0.775 * cos(0.25), -0.775 * sin(0.25), -0.14)), to: polar(o, 0.62, Kit.clock(3)))
        callout(&plate, "C", from: plate86At(1.03, 0.4, 0), to: polar(o, 0.86, Kit.clock(1.5)))
        callout(&plate, "D", from: plate86View(Q86(reserve.x, -reserve.y + 0.06, -0.08)), to: polar(o, 0.62, Kit.clock(1)))
        return plate
    }

    private typealias Q86 = SIMD3<Double>
    private static let plate86Rise: Double = 0.85
    private static let plate86Roll: Double = 0.2
    private static let plate86Pitch: Double = 0.08
    private static let plate86Scale: Double = 0.7
    private static let plate86Rim: Double = 1.1
    private static let plate86Wall: Double = 1.03
    private static let plate86Deep: Double = 0.5
    private static let plate86Reserve: P = polar(Kit.origin, 0.415, Kit.clock(2))

    private static func plate86View(_ q: Q86) -> P {
        let rise: Double = plate86Rise
        let k: Double = 5 / (5 + q.y * cos(rise) - q.z * sin(rise))
        return P(q.x * k, -(q.y * sin(rise) + q.z * cos(rise)) * k) * plate86Scale + P(0, 0.1)
    }

    private static func plate86Rolled(_ q: Q86) -> Q86 {
        let roll: Double = plate86Roll
        return Q86(q.x * cos(roll) - q.z * sin(roll), q.y, q.x * sin(roll) + q.z * cos(roll))
    }

    private static func plate86Boxed(_ q: Q86) -> Q86 {
        let r: Q86 = plate86Rolled(q), pitch: Double = plate86Pitch
        return Q86(r.x, r.y * cos(pitch) - r.z * sin(pitch), r.y * sin(pitch) + r.z * cos(pitch))
    }

    private static func plate86At(_ x: Double, _ y: Double, _ z: Double) -> P { plate86View(plate86Boxed(Q86(x, y, z))) }

    private static func plate86Quad(_ a: Q86, _ b: Q86, _ c: Q86, _ d: Q86) -> [P] {
        [a, b, c, d, a].map { (q: Q86) -> P in plate86View(plate86Boxed(q)) }
    }

    /// A drawing in a plane laid level at height z, or rolled with the box when the outer ring has taken out its pitch.
    private static func plate86Laid(_ sub: Plate, z: Double, withRoll: Bool = false) -> [Mark] {
        sub.marks.map { (mark: Mark) -> Mark in
            let moved: [P] = mark.points.map { (f: P) -> P in withRoll ? plate86View(plate86Rolled(Q86(f.x, -f.y, z))) : plate86View(Q86(f.x, -f.y, z)) }
            return Mark(points: moved, width: mark.width, ink: mark.ink)
        }
    }

    private static func plate86Annulus(_ r0: Double, _ r1: Double) -> [P] {
        arc(Kit.origin, r1) + arc(Kit.origin, r0).reversed() + [polar(Kit.origin, r1, 0)]
    }

    private static func plate86LidAt(_ x: Double, _ t: Double) -> Q86 { Q86(x, plate86Rim + 0.5 * t, 1.3 * t) }

    private static func plate86LidRing(_ x0: Double, _ x1: Double, _ t0: Double, _ t1: Double) -> [P] {
        let a: Q86 = plate86LidAt(x0, t0), b: Q86 = plate86LidAt(x1, t0), c: Q86 = plate86LidAt(x1, t1), d: Q86 = plate86LidAt(x0, t1)
        return plate86Quad(a, b, c, d)
    }

    /// Plate 86's lid thrown back on its hinges, ebony, with a bone stringing and the maker's plaque.
    private static func plate86Lid(_ plate: inout Plate) {
        let rim: Double = plate86Rim
        Kit.mass(&plate, plate86LidRing(-rim, rim, 0, 1))
        Kit.cut(&plate, plate86LidRing(-0.95, 0.95, 0.06, 0.95), edge: heavy)
        Kit.mass(&plate, plate86LidRing(-0.4, 0.4, 0.3, 0.66))
        plate.line(plate86LidRing(-0.34, 0.34, 0.35, 0.61), medium, .bone)
        for t in [0.43, 0.5] { plate.line([plate86LidAt(-0.24, t), plate86LidAt(0.24, t)].map { (q: Q86) -> P in plate86View(plate86Boxed(q)) }, heavy, .bone) }
        for t in [0.2, 0.78, 0.86] { plate.line([plate86LidAt(-0.84, t), plate86LidAt(0.84, t)].map { (q: Q86) -> P in plate86View(plate86Boxed(q)) }, medium) }
        for x in [-0.66, 0.66] {
            Kit.cut(&plate, plate86LidRing(x - 0.1, x + 0.1, 0, 0.07))
            plate.line([plate86LidAt(x - 0.1, 0.035), plate86LidAt(x + 0.1, 0.035)].map { (q: Q86) -> P in plate86View(plate86Boxed(q)) }, medium)
        }
    }

    /// Plate 86's box: its back and side walls inside, the rim, and the front, in ebony grained bold.
    private static func plate86Box(_ plate: inout Plate) {
        let rim: Double = plate86Rim, wall: Double = plate86Wall, deep: Double = plate86Deep
        Kit.cut(&plate, plate86Quad(Q86(-wall, wall, 0), Q86(wall, wall, 0), Q86(wall, wall, -deep), Q86(-wall, wall, -deep)))
        for z in [-0.17, -0.34] { plate.line([plate86At(-wall, wall, z), plate86At(wall, wall, z)], heavy) }
        for x in [-wall, wall] {
            Kit.cut(&plate, plate86Quad(Q86(x, wall, 0), Q86(x, -wall, 0), Q86(x, -wall, -deep), Q86(x, wall, -deep)))
            for z in [-0.17, -0.34] { plate.line([plate86At(x, wall, z), plate86At(x, -wall, z)], heavy) }
        }
        let rims: [[P]] = [plate86Quad(Q86(-rim, rim, 0), Q86(rim, rim, 0), Q86(wall, wall, 0), Q86(-wall, wall, 0)),
                           plate86Quad(Q86(rim, rim, 0), Q86(rim, -rim, 0), Q86(wall, -wall, 0), Q86(wall, wall, 0)),
                           plate86Quad(Q86(rim, -rim, 0), Q86(-rim, -rim, 0), Q86(-wall, -wall, 0), Q86(wall, -wall, 0)),
                           plate86Quad(Q86(-rim, -rim, 0), Q86(-rim, rim, 0), Q86(-wall, wall, 0), Q86(-wall, -wall, 0))]
        for ring in rims { Kit.mass(&plate, ring) }
        Kit.mass(&plate, plate86Quad(Q86(-rim, -rim, 0), Q86(rim, -rim, 0), Q86(rim, -rim, -deep), Q86(-rim, -rim, -deep)))
        for k in 0..<4 {
            let z: Double = -0.08 - 0.12 * Double(k)
            let grain: [P] = (0...16).map { (i: Int) -> P in
                let x: Double = -rim + 2 * rim * Double(i) / 16
                return plate86At(x, -rim, z + 0.025 * sin(Double(i) * 0.9 + Double(k)))
            }
            plate.line(grain, heavy, .bone)
        }
        plate.line([plate86At(-rim, -rim, 0), plate86At(rim, -rim, 0)], heavy, .bone)
    }

    /// Plate 86's outer gimbal ring, pivoted in the side walls and pitched with the sea, then the inner ring on it, level.
    private static func plate86Gimbals(_ plate: inout Plate) {
        let o: P = Kit.origin
        var outer = Plate(), inner = Plate()
        for side in [-1.0, 1.0] {
            Kit.mass(&outer, Kit.band(P(0.9 * side, 0), P(1.04 * side, 0), 0.07))
            outer.fill(arc(P(1.0 * side, 0), 0.02))
            Kit.mass(&inner, Kit.band(P(0, 0.76 * side), P(0, 0.93 * side), 0.06))
            inner.fill(arc(P(0, 0.9 * side), 0.018))
        }
        Kit.mass(&outer, plate86Annulus(0.89, 0.96))
        for k in 0..<16 {
            let a: Double = Double(k) * .pi / 8 + 0.2
            outer.fill(Kit.band(polar(o, 0.895, a), polar(o, 0.955, a), 0.028), .bone)
        }
        Kit.mass(&inner, plate86Annulus(0.755, 0.805))
        inner.line(arc(o, 0.78), heavy, .bone)
        plate.marks += plate86Laid(outer, z: -0.16, withRoll: true)
        plate.marks += plate86Laid(inner, z: -0.14)
    }

    /// Plate 86's bowl under the dial, lit on its near side, the bezel and the dial.
    private static func plate86Bowl(_ plate: inout Plate) {
        let o: P = Kit.origin
        let r: Double = 0.62
        var face = Plate()
        Kit.mass(&face, arc(o, 0.655))
        Kit.dial(&face, o, r, numerals: false)
        for k in 1...12 {
            let at: P = polar(o, 0.81 * r, Kit.clock(Double(k)))
            face.lines(Kit.numeral(roman(k), at: at, height: 0.13 * r, turn: Kit.clock(Double(k)) + .pi / 2, squeeze: 0.66), 0.014)
        }
        face.line(arc(o, 0.645), fine, .bone)
        // The seconds at six, the power reserve over two.
        let seconds: P = P(0, 0.31), reserve: P = plate86Reserve, small: Double = 0.085
        for (c, ticks) in [(seconds, 12), (reserve, 0)] {
            face.fill(arc(c, small))
            face.line(arc(c, small), heavy)
            for k in 0..<ticks { face.line([polar(c, 0.06, Double(k) * .pi / 6), polar(c, small, Double(k) * .pi / 6)], medium) }
        }
        for k in 0...6 {
            let a: Double = Kit.clock(2) - .pi / 2 - 1.0 + 2.0 * Double(k) / 6
            face.line([polar(reserve, k % 3 == 0 ? 0.045 : 0.065, a), polar(reserve, small, a)], k % 3 == 0 ? heavy : medium)
        }
        Kit.hands(&face, o, r, hours: 3, minutes: 40)
        Kit.mass(&face, Kit.hand(seconds, toward: Kit.clock(4), length: 0.075, width: 0.016, tail: 0.02))
        face.fill(arc(seconds, 0.011))
        Kit.mass(&face, Kit.hand(reserve, toward: Kit.clock(2) - .pi / 2 + 0.55, length: 0.085, width: 0.024, tail: 0.016), ink: .second)
        face.fill(arc(reserve, 0.011))
        plate.marks += plate86Laid(face, z: -0.08)
    }

    /// Problem 87, Longcase clock, hex, clocks 1+: a longcase clock the height of the glass in figured mahogany, its
    /// hood with the arched dial between pillars, the trunk's door in flame figure, and the plinth on bracket feet; the
    /// pendulum's bob, seen through the lenticle in the door, in the second ink.
    static func plate87() -> Plate {
        var plate = Plate()
        Kit.ground(&plate, angle: 0.5)
        plate87Plinth(&plate)
        plate87Trunk(&plate)
        plate87Hood(&plate)
        plate87DialDraw(&plate)
        callout(&plate, "A", from: P(-0.3, -0.62), to: polar(Kit.origin, 0.62, Kit.clock(10.8)))
        callout(&plate, "B", from: P(0.19, 0.1), to: polar(Kit.origin, 0.6, Kit.clock(3)))
        callout(&plate, "C", from: plate87Lenticle + P(0.06, 0.03), to: polar(Kit.origin, 0.62, Kit.clock(5)))
        callout(&plate, "D", from: P(-0.3, 0.73), to: polar(Kit.origin, 0.64, Kit.clock(7)))
        return plate
    }

    private static let plate87Dial: P = P(0, -0.53)
    private static let plate87Face: Double = 0.175
    private static let plate87Lenticle: P = P(0, 0.28)
    private static let plate87Waist: Double = -0.3

    /// Plate 87's floor it stands on, the plinth on its bracket feet, its raised panel figured in burr, and the
    /// moulding into the trunk.
    private static func plate87Plinth(_ plate: inout Plate) {
        // The floor it stands on.
        Kit.mass(&plate, [P(-1.1, 0.9), P(1.1, 0.9), P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.9)])
        for x in stride(from: -0.9, through: 0.9, by: 0.3) { plate.line([P(x, 0.92), P(x - 0.03, 1.06)], heavy, .bone) }

        // The plinth on its bracket feet, its raised panel figured in burr, and the moulding into the trunk.
        for side in [-1.0, 1.0] {
            Kit.mass(&plate, [P(0.42 * side, 0.85), P(0.42 * side, 0.96), P(0.34 * side, 0.96), P(0.3 * side, 0.9), P(0.3 * side, 0.85), P(0.42 * side, 0.85)])
        }
        Kit.mass(&plate, box(P(-0.42, 0.86), P(0.42, 0.91)))
        Kit.mass(&plate, box(P(-0.38, 0.6), P(0.38, 0.88)))
        Kit.cut(&plate, box(P(-0.34, 0.62), P(0.34, 0.845)), edge: heavy)
        for k in 0..<3 {
            let w: Double = 0.24 - 0.075 * Double(k), h: Double = 0.07 - 0.02 * Double(k)
            plate.line(ellipse(P(0.012 * Double(k), 0.735), w, h), 0.014)
        }
        Kit.mass(&plate, box(P(-0.26, 0.555), P(0.26, 0.57)))
        Kit.cut(&plate, box(P(-0.3, 0.57), P(0.3, 0.6)))
    }

    /// Plate 87's trunk: its stiles in straight grain, the door in flame figure, and the lenticle in the door.
    private static func plate87Trunk(_ plate: inout Plate) {
        let lenticle: P = plate87Lenticle, waist: Double = plate87Waist
        /// Straight grain down a rect, in bold lines that wander.
        func grain(_ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double, gap: Double, seed: Int, ink: Ink = .bone) {
            var x = x0 + gap / 2, k = 0
            while x < x1 - gap / 3 {
                let wander: Double = 6 * rnd(seed, k)
                let rule: [P] = (0...10).map { (i: Int) -> P in
                    let t: Double = Double(i)
                    return P(x + 0.01 * sin(t * 0.9 + wander), y0 + (y1 - y0) * t / 10)
                }
                plate.line(rule, 0.012, ink)
                x += gap
                k += 1
            }
        }

        // The trunk: its stiles in straight grain, the door in flame figure, and the lenticle in the door.
        Kit.mass(&plate, box(P(-0.22, waist + 0.02), P(0.22, 0.555)))
        for x in [-0.19, 0.19] { Kit.cut(&plate, box(P(x - 0.03, waist + 0.02), P(x + 0.03, 0.55)), edge: medium) }
        grain(-0.22, -0.16, waist + 0.04, 0.54, gap: 0.03, seed: 1, ink: .black)
        grain(0.16, 0.22, waist + 0.04, 0.54, gap: 0.03, seed: 2, ink: .black)
        let crown: P = P(0, -0.07), spring: Double = atan2(-0.17 - crown.y, -0.15)
        let head: [P] = arc(crown, simd_distance(crown, P(-0.15, -0.17)), from: spring, to: -.pi - spring)
        let door: [P] = [P(-0.15, 0.545)] + head + [P(0.15, 0.545), P(-0.15, 0.545)]
        Kit.cut(&plate, door, edge: 0.016)
        for k in 0..<8 {
            let crest: Double = 0.6 - 0.1 * Double(k)
            let figure: [P] = (0...16).map { (i: Int) -> P in
                let x: Double = -0.125 + 0.25 * Double(i) / 16
                return P(x, min(0.51, crest + 0.14 * pow(abs(x) / 0.125, 1.4) + 0.01 * sin(Double(i + k))))
            }
            plate.line(figure, 0.024)
        }
        Kit.mass(&plate, arc(lenticle, 0.085))
        plate.line(arc(lenticle, 0.085), 0.016, .bone)
        plate.line(arc(lenticle, 0.07), fine, .bone)
        plate.line([lenticle + P(0, -0.07), lenticle + P(0, -0.02)], medium, .bone)
        Kit.mass(&plate, arc(lenticle + P(0, 0.008), 0.045), ink: .second)
        plate.line(arc(lenticle + P(-0.014, -0.006), 0.016, from: 3.4, to: 4.6), medium, .bone)
        Kit.mass(&plate, box(P(-0.27, waist - 0.005), P(0.27, waist + 0.02)))
        Kit.mass(&plate, box(P(-0.33, waist - 0.035), P(0.33, waist - 0.015)))
    }

    /// Plate 87's hood: its pillars, the arched dial, and the cornice under the finials.
    private static func plate87Hood(_ plate: inout Plate) {
        let dial: P = plate87Dial, waist: Double = plate87Waist
        let hood: Double = 0.34, square: Double = 0.2, arch: P = P(0, dial.y - square)
        Kit.mass(&plate, box(P(-hood, waist - 0.035), P(hood, -0.93)))
        for side in [-1.0, 1.0] {
            let x: Double = 0.27 * side
            Kit.cut(&plate, box(P(x - 0.02, -0.86), P(x + 0.02, waist - 0.06)), edge: medium)
            for y in [-0.85, waist - 0.07] { Kit.mass(&plate, box(P(x - 0.033, y - 0.018), P(x + 0.033, y + 0.018))) }
            plate.line([P(x - 0.007, -0.83), P(x - 0.007, waist - 0.09)], medium)
            Kit.mass(&plate, arc(P(0.33 * side, -0.99), 0.035))
        }
        Kit.mass(&plate, box(P(-0.39, -0.94), P(0.39, -0.9)))
        plate.line([P(-0.38, -0.92), P(0.38, -0.92)], medium, .bone)
        Kit.mass(&plate, arc(P(0, -1.0), 0.05))
        let sill: [P] = [P(-square - 0.04, waist - 0.05), P(square + 0.04, waist - 0.05), P(square + 0.04, arch.y)]
        let opening: [P] = sill + arc(arch, square + 0.04, from: 0, to: -.pi) + [P(-square - 0.04, waist - 0.05)]
        Kit.cut(&plate, opening, edge: heavy)
        // The arch's boss, the moon riding over its hills, and the spandrels' scrolls in the dial's corners.
        plate.line(arc(arch, 0.15, from: .pi, to: 2 * .pi) + [arch + P(0.15, 0), arch + P(-0.15, 0)], heavy)
        Kit.solid(&plate, arc(arch, 0.1, from: .pi, to: 2 * .pi) + [arch + P(-0.1, 0)], angle: 0, gap: 0.016)
        Kit.mass(&plate, arc(arch + P(0.02, -0.06), 0.03))
        for (sx, sy) in [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)] {
            let corner: P = P(0.19 * sx, dial.y + 0.19 * sy)
            let scroll: [P] = [corner + P(0.02 * sx, 0.01 * sy), corner + P(-0.01 * sx, 0.025 * sy), corner + P(-0.045 * sx, -0.01 * sy),
                               corner + P(-0.01 * sx, -0.045 * sy), corner + P(0.01 * sx, 0.005 * sy), corner + P(0.02 * sx, 0.01 * sy)]
            Kit.solid(&plate, scroll, angle: 0.8 * sx * sy, gap: 0.012, width: fine)
        }
    }

    /// Plate 87's dial, drawn without a heavy rim.
    private static func plate87DialDraw(_ plate: inout Plate) {
        let dial: P = plate87Dial, face: Double = plate87Face
        // The dial without a heavy rim, so its rings do not hold still under the hub's step.
        plate.fill(arc(dial, face))
        for k in 0..<60 where k % 5 == 0 {
            Kit.mass(&plate, Kit.band(polar(dial, 0.86 * face, Double(k) * .pi / 30), polar(dial, face, Double(k) * .pi / 30), 0.014))
        }
        for k in 1...12 {
            plate.lines(Kit.numeral(roman(k), at: polar(dial, 0.7 * face, Kit.clock(Double(k))), height: 0.2 * face,
                                    turn: Kit.clock(Double(k)) + .pi / 2, squeeze: 0.72), heavy)
        }
        plate.line(arc(dial, 0.93 * face), fine)
        Kit.hands(&plate, dial, face, hours: 10, minutes: 9)
    }

    /// Problem 88, Atomic clock, hex, clocks 1+: an atom inside a seconds bezel, three bold orbits crossing about the
    /// nucleus, set off the hub in the lane at one o'clock, each orbit's far half passing behind it and an electron
    /// streaking along its near half; the nucleus's protons in the second ink.
    static func plate88() -> Plate {
        var plate = Plate()
        let o = Kit.origin, nucleus = polar(o, 0.285, Kit.clock(1)), a = 0.7, b = 0.2, band = 0.088
        let third: Double = .pi / 3
        let turns: [Double] = [0.25, 0.25 + third, 0.25 + 2 * third]
        func orbit(_ turn: Double, _ from: Double, _ to: Double) -> [P] { ellipse(nucleus, a, b, from: from, to: to, turned: turn) }
        func lay(_ path: [P]) {
            let ring = Kit.ribbon(path, band)
            plate.fill(ring, .bone)
            Kit.mass(&plate, Kit.ribbon(path, band - 0.026))
            plate.line(path, fine, .bone)
        }

        Kit.ground(&plate, angle: -0.7)
        // The bezel, its seconds cut in bone.
        Kit.mass(&plate, arc(o, 1.06) + arc(o, 0.9).reversed() + [polar(o, 1.06, 0)])
        for k in 0..<60 {
            let t = Double(k) * .pi / 30
            plate.line([polar(o, k % 5 == 0 ? 0.92 : 0.95, t), polar(o, 1.0, t)], k % 5 == 0 ? 0.026 : 0.012, .bone)
        }
        plate.line(arc(o, 0.885), heavy)

        // The far halves of the orbits, behind the nucleus.
        for turn in turns { lay(orbit(turn, .pi, 2 * .pi)) }

        // The nucleus: protons in the second ink and neutrons in ink, packed.
        let packed: [(Double, Double, Bool)] = [(0, 0, true), (0.042, 0.3, false), (0.042, 1.35, true), (0.042, 2.4, false),
                                                 (0.042, 3.45, true), (0.042, 4.5, false), (0.042, 5.55, true)]
        plate.fill(arc(nucleus, 0.088))
        plate.line(arc(nucleus, 0.088), medium)
        for (r, t, proton) in packed.sorted(by: { $0.0 > $1.0 }) {
            let c = polar(nucleus, r, t)
            Kit.mass(&plate, arc(c, 0.03), ink: proton ? .second : .black)
            plate.line(arc(c, 0.03), medium)
            plate.line(arc(c + P(-0.008, -0.008), 0.013, from: 3.3, to: 4.6), fine, .bone)
        }

        // The near halves, over the nucleus, each with its electron and the streak behind it.
        for (k, turn) in turns.enumerated() {
            lay(orbit(turn, 0, .pi))
            let at = 0.9 + 0.75 * Double(k)
            for i in 1...5 {
                let back = orbit(turn, at - 0.09 * Double(i) - 0.07, at - 0.09 * Double(i))
                plate.line(back, 0.028 - 0.004 * Double(i), .bone)
            }
            let e = ellipse(nucleus, a, b, from: at, to: at, turned: turn)[0]
            plate.fill(arc(e, 0.062))
            plate.line(arc(e, 0.062), 0.014)
            Kit.mass(&plate, arc(e, 0.03))
            plate.line(arc(e + P(-0.012, -0.012), 0.012, from: 3.3, to: 4.6), fine, .bone)
        }

        callout(&plate, "A", from: ellipse(nucleus, a, b, from: 2.2, to: 2.2, turned: turns[0])[0], to: polar(o, 0.6, Kit.clock(9)))
        callout(&plate, "B", from: ellipse(nucleus, a, b, from: 0.9, to: 0.9, turned: turns[0])[0] + P(0.05, 0.03), to: polar(o, 0.62, Kit.clock(5)))
        callout(&plate, "C", from: nucleus + P(0.07, -0.05), to: polar(o, 0.62, Kit.clock(2.8)))
        callout(&plate, "D", from: polar(o, 0.96, Kit.clock(7.6)), to: polar(o, 0.62, Kit.clock(7)))
        return plate
    }

    /// Problem 89, Millennium, hex, clocks 1+: a great Roman M cut in the round, each stroke's shadowed face in ink and
    /// its lit face ruled, standing over the roofs of a town while fireworks burst behind it in bold rays and their
    /// rockets' trails climb; the spark of the one rocket still rising in the second ink.
    static func plate89() -> Plate {
        var plate = Plate()
        let o: P = Kit.origin
        Kit.ground(&plate, angle: 0.3)
        plate89Bursts(&plate)
        plate89Roofs(&plate)
        plate89Letter(&plate)
        callout(&plate, "A", from: P(-0.2, 0.2), to: polar(o, 0.3, Kit.clock(5.5)))
        callout(&plate, "B", from: P(-0.44, -0.56) + P(0.19, 0.17), to: polar(o, 0.62, Kit.clock(11)))
        callout(&plate, "C", from: plate89Spark + P(0.0, 0.05), to: polar(o, 0.86, Kit.clock(4)))
        return plate
    }

    private static let plate89Spark: P = P(0.72, 0.0)

    /// One burst: tapered rays, each ending in a star, about `c`.
    private static func plate89Burst(_ plate: inout Plate, _ c: P, _ r: Double, rays: Int, turn: Double, seed: Int) {
        for k in 0..<rays {
            let t: Double = turn + 2 * .pi * Double(k) / Double(rays) + 0.08 * (rnd(seed, k) - 0.5)
            let reach: Double = r * (0.8 + 0.2 * rnd(seed, k + 50)), w: Double = 0.046 * r / 0.35
            let ray: [P] = [polar(c, 0.22 * r, t), polar(c, reach, t - w / reach / 2), polar(c, reach + 0.03, t),
                            polar(c, reach, t + w / reach / 2), polar(c, 0.22 * r, t)]
            Kit.mass(&plate, ray)
            Kit.mass(&plate, arc(polar(c, reach + 0.075 * r / 0.35, t), 0.018 * r / 0.35 + 0.006))
        }
        Kit.mass(&plate, arc(c, 0.09 * r))
        plate.fill(arc(c, 0.04 * r))
    }

    /// A stroke of the letter from its head to its foot, cut to a ridge: the face away from the light in ink, the lit
    /// face ruled along the stroke.
    private static func plate89Stroke(_ plate: inout Plate, _ head: P, _ foot: P, _ wHead: Double, _ wFoot: Double) {
        let d: P = simd_normalize(foot - head), n: P = P(-d.y, d.x)
        let l0: P = head + n * (wHead / 2), r0: P = head - n * (wHead / 2)
        let l1: P = foot + n * (wFoot / 2), r1: P = foot - n * (wFoot / 2)
        let shade: [P] = [r0, head, foot, r1, r0], lit: [P] = [head, l0, l1, foot, head]
        plate.fill(lit)
        plate.lines(hatch([lit], angle: atan2(d.y, d.x), gap: 0.022), fine)
        plate.fill(shade, .black)
        plate.line([l0, l1, r1, r0, l0], medium)
    }

    /// Plate 89's rockets' trails and bursts, and the rocket still rising with its spark.
    private static func plate89Bursts(_ plate: inout Plate) {
        let spark: P = plate89Spark
        // The rockets' trails, climbing to their bursts.
        for (from, bend, to) in [(P(-0.55, 0.95), P(-0.6, 0.0), P(-0.42, -0.5)), (P(0.35, 0.95), P(0.6, 0.1), P(0.5, -0.52)),
                                 (P(-0.1, 0.95), P(0.15, -0.2), P(0.02, -0.74))] {
            plate.lines(dashed(curve(from, bend, to, 40), on: 0.05, off: 0.035), 0.016)
        }
        plate89Burst(&plate, P(-0.44, -0.56), 0.33, rays: 13, turn: 0.1, seed: 3)
        plate89Burst(&plate, P(0.5, -0.52), 0.3, rays: 12, turn: 0.3, seed: 4)
        plate89Burst(&plate, P(0.02, -0.76), 0.24, rays: 11, turn: 0.0, seed: 5)
        plate89Burst(&plate, P(-0.8, 0.12), 0.17, rays: 9, turn: 0.2, seed: 6)

        // The rocket still rising, its trail and its spark.
        plate.lines(dashed(curve(P(0.9, 0.75), P(0.82, 0.3), spark + P(0.02, 0.06), 24), on: 0.04, off: 0.03), 0.016)
        Kit.mass(&plate, Kit.band(spark + P(0.015, 0.1), spark + P(0.004, 0.04), 0.03))
        let star: [P] = (0..<16).map { (k: Int) -> P in
            let reach: Double = k % 2 == 0 ? 0.075 : 0.03
            return polar(spark, reach, Double(k) * .pi / 8 - .pi / 2)
        }
        Kit.mass(&plate, star + [star[0]], ink: .second)
        plate.fill(arc(spark, 0.014))
    }

    /// Plate 89's town roofs along the foot of the glass.
    private static func plate89Roofs(_ plate: inout Plate) {
        var roofs: [P] = [P(-1.1, 1.1), P(-1.1, 0.8)]
        let steps: [(Double, Double)] = [(-0.86, 0.8), (-0.86, 0.72), (-0.76, 0.64), (-0.66, 0.72), (-0.66, 0.76), (-0.3, 0.76), (-0.3, 0.84),
                                         (0.3, 0.84), (0.3, 0.76), (0.62, 0.76), (0.62, 0.7), (0.7, 0.7), (0.7, 0.6), (0.74, 0.6), (0.74, 0.7),
                                         (0.86, 0.7), (0.86, 0.8)]
        for (x, y) in steps { roofs.append(P(x, y)) }
        roofs += [P(1.1, 0.8), P(1.1, 1.1), P(-1.1, 1.1)]
        Kit.mass(&plate, roofs)
        let windows: [(Double, Double)] = [(-0.76, 0.72), (-0.5, 0.82), (0.45, 0.82), (0.72, 0.68), (0.8, 0.78), (-0.8, 0.88), (0.2, 0.92), (-0.2, 0.94)]
        for (x, y) in windows {
            plate.fill(box(P(x - 0.018, y - 0.025), P(x + 0.018, y + 0.025)))
        }
    }

    /// Plate 89's M, its plinth under it.
    private static func plate89Letter(_ plate: inout Plate) {
        let top: Double = -0.36, foot: Double = 0.6
        Kit.solid(&plate, box(P(-0.68, foot), P(0.68, foot + 0.08)), angle: 0, gap: 0.022, width: fine)
        Kit.mass(&plate, box(P(-0.68, foot + 0.065), P(0.68, foot + 0.08)))
        plate89Stroke(&plate, P(-0.47, top), P(-0.52, foot), 0.07, 0.075)
        plate89Stroke(&plate, P(-0.45, top), P(0.0, foot), 0.17, 0.17)
        plate89Stroke(&plate, P(0.45, top), P(0.0, foot), 0.075, 0.075)
        plate89Stroke(&plate, P(0.47, top), P(0.52, foot), 0.17, 0.17)
        for (x, w) in [(-0.52, 0.27), (0.52, 0.36)] {
            Kit.mass(&plate, box(P(x - w / 2, foot - 0.045), P(x + w / 2, foot)))
        }
        for (x, w) in [(-0.5, 0.24), (0.5, 0.28)] {
            Kit.solid(&plate, box(P(x - w / 2, top), P(x + w / 2, top + 0.045)), angle: 0, gap: 0.016, width: fine)
            Kit.mass(&plate, box(P(x - w / 2, top + 0.03), P(x + w / 2, top + 0.045)))
        }
    }

    /// Problem 90, Eternity, hex, clocks 1+: the serpent that eats its tail, round the rim past every hub, its jaws
    /// closed on its tail at eleven, about a Moebius band, the strip with one side and no end, its face toward the eye
    /// ruled across in bone and its face away in ink, so the half turn shows as the change; the serpent's eye in the
    /// second ink.
    static func plate90() -> Plate {
        var plate = Plate()
        let o: P = Kit.origin
        Kit.ground(&plate, angle: 0.35, around: [plate90Serpent, plate90Head] + plate90Quads.map(\.ring))
        plate90Moebius(&plate)
        plate90SerpentDraw(&plate)
        // The hours outside the serpent, bold.
        for k in 1..<12 {
            Kit.mass(&plate, Kit.band(polar(o, 0.955, Kit.clock(Double(k))), polar(o, 1.01, Kit.clock(Double(k))), 0.035))
        }
        callout(&plate, "A", from: polar(o, plate90Body, Kit.clock(7.4)), to: P(-0.68, 0.36))
        callout(&plate, "B", from: plate90Seen(plate90At(.pi * 0.3, plate90Half * 0.6)), to: polar(o, 0.62, Kit.clock(5)))
        callout(&plate, "C", from: plate90Local(0.3, -0.06), to: polar(o, 0.6, Kit.clock(11)))
        return plate
    }

    private static let plate90Body: Double = 0.85
    private static let plate90Thick: Double = 0.11
    private static let plate90Big: Double = 1.5
    private static let plate90N: Int = 320
    /// The neck's angle, round past a full turn.
    private static let plate90Neck: Double = Kit.clock(10.25) + 2 * .pi

    /// A point `s` along the serpent from its neck, clockwise, and `n` out from its spine.
    private static func plate90Local(_ s: Double, _ n: Double) -> P { polar(Kit.origin, plate90Body + n, plate90Neck + s / plate90Body) }

    /// The serpent from its tail, held in its jaws, clockwise all the way round to its neck, swelling from the tail.
    private static let plate90Spine: [P] = {
        let neck: Double = plate90Neck, body: Double = plate90Body, n: Int = plate90N
        let start: Double = neck - 2 * .pi + 0.2 / body
        return (0...n).map { (i: Int) -> P in
            let t: Double = Double(i) / Double(n)
            return polar(Kit.origin, body + 0.012 * sin(t * 36 * .pi) * min(1, 8 * t), start + (neck - start) * t)
        }
    }()

    private static let plate90Girth: [Double] = (0...plate90N).map { (i: Int) -> Double in
        plate90Thick * min(1, 0.2 + 3.2 * Double(i) / Double(plate90N))
    }

    private static let plate90Normals: [P] = plate90Spine.indices.map { (i: Int) -> P in
        let d: P = plate90Spine[min(i + 1, plate90N)] - plate90Spine[max(i - 1, 0)]
        return simd_normalize(P(-d.y, d.x))
    }

    private static let plate90Serpent: [P] = {
        let spine: [P] = plate90Spine, normals: [P] = plate90Normals, girth: [Double] = plate90Girth
        let near: [P] = spine.indices.map { (i: Int) -> P in spine[i] + normals[i] * girth[i] / 2 }
        let far: [P] = spine.indices.reversed().map { (i: Int) -> P in spine[i] - normals[i] * girth[i] / 2 }
        return near + far + [spine[0] + normals[0] * girth[0] / 2]
    }()

    /// The head, wider than the neck, its jaws shut on the tail's tip.
    private static let plate90Head: [P] = {
        let big: Double = plate90Big
        let outline: [(Double, Double)] = [(0.0, 0.056), (0.05, 0.08), (0.11, 0.086), (0.17, 0.068), (0.215, 0.036), (0.215, 0.016), (0.1, 0.014),
                                           (0.1, -0.014), (0.2, -0.018), (0.195, -0.045), (0.13, -0.07), (0.05, -0.074), (0.0, -0.056), (0.0, 0.056)]
        return outline.map { (e: (Double, Double)) -> P in plate90Local(big * e.0, big * e.1) }
    }()

    private static let plate90Radius: Double = 0.42
    private static let plate90Half: Double = 0.21
    private static let plate90Tilt: Double = 0.82
    private static let plate90M: Int = 160
    private static let plate90Phase: Double = 0.5

    private static func plate90At(_ u: Double, _ v: Double) -> SIMD3<Double> {
        let r: Double = plate90Radius + v * cos(u / 2)
        return SIMD3(1.12 * r * cos(u + plate90Phase), r * sin(u + plate90Phase), v * sin(u / 2))
    }

    private static func plate90Seen(_ q: SIMD3<Double>) -> P {
        let tilt: Double = plate90Tilt
        return P(q.x, q.y * cos(tilt) - q.z * sin(tilt) + 0.03)
    }

    private static func plate90Depth(_ q: SIMD3<Double>) -> Double {
        let tilt: Double = plate90Tilt
        return q.y * sin(tilt) + q.z * cos(tilt)
    }

    /// The Moebius band: a strip turned half over in one round, seen from above and before, its quads laid back to front.
    private static let plate90Quads: [(ring: [P], depth: Double, face: Bool, edge: [P], other: [P])] = {
        let m: Int = plate90M, half: Double = plate90Half, tilt: Double = plate90Tilt
        return (0..<m).map { (i: Int) -> (ring: [P], depth: Double, face: Bool, edge: [P], other: [P]) in
            let u0: Double = 2 * .pi * Double(i) / Double(m), u1: Double = 2 * .pi * (Double(i) + 1.06) / Double(m)
            let a: SIMD3<Double> = plate90At(u0, -half), b: SIMD3<Double> = plate90At(u1, -half)
            let c: SIMD3<Double> = plate90At(u1, half), d: SIMD3<Double> = plate90At(u0, half)
            // The side facing the eye: the normal's component toward it.
            let normal: SIMD3<Double> = simd_cross(b - a, d - a), toward: SIMD3<Double> = SIMD3(0, -sin(tilt), cos(tilt))
            let ring: [P] = [plate90Seen(a), plate90Seen(b), plate90Seen(c), plate90Seen(d), plate90Seen(a)]
            return (ring, plate90Depth(a + b + c + d), simd_dot(normal, toward) > 0,
                    [plate90Seen(a), plate90Seen(b)], [plate90Seen(d), plate90Seen(c)])
        }
    }()

    /// Plate 90's Moebius band, its quads laid back to front.
    private static func plate90Moebius(_ plate: inout Plate) {
        let quads: [(ring: [P], depth: Double, face: Bool, edge: [P], other: [P])] = plate90Quads
        for (k, q) in quads.enumerated().sorted(by: { $0.element.depth < $1.element.depth }) {
            if q.face {
                plate.fill(q.ring)
                if k % 4 == 0 { plate.line([q.ring[0], q.ring[3]], 0.013) }
            } else {
                plate.fill(q.ring, .black)
                if k % 4 == 2 { plate.line([q.ring[0], q.ring[3]], 0.016, .bone) }
            }
            plate.line(q.edge, 0.014)
            plate.line(q.other, 0.014)
        }
    }

    /// Plate 90's serpent: ink, its scales in bone across its back, its belly's line, then the head over the tail's tip.
    private static func plate90SerpentDraw(_ plate: inout Plate) {
        let spine: [P] = plate90Spine, normals: [P] = plate90Normals, girth: [Double] = plate90Girth, n: Int = plate90N
        let head: [P] = plate90Head
        Kit.mass(&plate, plate90Serpent)
        for k in stride(from: 12, to: n - 4, by: 7) {
            let w: Double = girth[k] * 0.32, ahead: P = simd_normalize(spine[min(k + 3, n)] - spine[k]) * 0.026
            plate.line([spine[k] + normals[k] * w, spine[k] + ahead, spine[k] - normals[k] * w], medium, .bone)
        }
        let belly: [P] = spine.indices.filter { (i: Int) -> Bool in i > 40 }.map { (i: Int) -> P in spine[i] - normals[i] * girth[i] * 0.36 }
        plate.lines(dashed(belly, on: 0.04, off: 0.03), fine, .bone)
        Kit.mass(&plate, head)
        plate.line([plate90Local(0.03, 0.0), plate90Local(0.15, 0.0)], heavy, .bone)
        for s in [0.04, 0.1] { plate.line([plate90Local(s, 0.075), plate90Local(s + 0.03, 0.045), plate90Local(s, 0.018)], medium, .bone) }
        plate.line([plate90Local(0.04, -0.075), plate90Local(0.07, -0.045), plate90Local(0.04, -0.018)], medium, .bone)
        plate.fill(arc(plate90Local(0.285, 0.065), 0.011))
        let eye: P = plate90Local(0.185, 0.07)
        plate.fill(arc(eye, 0.04))
        Kit.mass(&plate, arc(eye, 0.032), ink: .second)
        let ahead: P = simd_normalize(plate90Local(0.2, 0.07) - eye)
        Kit.mass(&plate, Kit.band(eye - P(-ahead.y, ahead.x) * 0.022, eye + P(-ahead.y, ahead.x) * 0.022, 0.011))
    }
}
