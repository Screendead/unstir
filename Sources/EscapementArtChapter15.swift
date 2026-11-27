// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 15, Perpetual: problems 85 to 90's plates, drawn with `Kit`. Not drawn yet: each falls back to
/// the shared plate.
extension EscapementArt {
    /// Problem 85, Regulator, hex, clocks 1+: a regulator's gridiron pendulum caught near the end of its beat, hung
    /// from its cock between the case's fluted ebony stiles, its steel bars in ink and its brass in bone, the drum bob
    /// below and the beat scale under it; the beat scale's index in the second ink.
    static func plate85() -> Plate {
        var plate = Plate()
        let o = Kit.origin, pivot = P(0, -0.99), tilt = 0.03
        func at(_ u: Double, _ v: Double) -> P { pivot + P(u * cos(tilt) + v * sin(tilt), -u * sin(tilt) + v * cos(tilt)) }
        func box(_ u0: Double, _ v0: Double, _ u1: Double, _ v1: Double) -> [P] {
            [at(u0, v0), at(u1, v0), at(u1, v1), at(u0, v1), at(u0, v0)]
        }
        let top = 0.16, foot = 1.2, bar = 0.06, pitch = 0.12
        let bars = [-2.0, -1, 0, 1, 2].map { box($0 * pitch - bar / 2, top, $0 * pitch + bar / 2, foot) }
        let bob = ellipse(at(0, 1.81), 0.19, 0.07, turned: -tilt)

        // The case's stiles, ebony, each fluted.
        let edge = acos(-0.64 / 1.06)
        let stile = arc(o, 1.06, from: edge, to: 2 * .pi - edge) + [polar(o, 1.06, edge)]
        Kit.ground(&plate, angle: -0.5, around: [box(-0.31, top, 0.31, foot), bob])
        for side in [-1.0, 1.0] {
            Kit.mass(&plate, stile.map { P($0.x * -side, $0.y) })
            plate.line([P(0.67 * side, -0.83), P(0.67 * side, 0.83)], heavy, .bone)
            for x in [0.74, 0.82, 0.9] {
                let h = sqrt(1.0 - (x + 0.03) * (x + 0.03)) - 0.08
                plate.fill(Kit.band(P(x * side, -h), P(x * side, h), 0.024), .bone)
                plate.line([P(x * side + 0.006 * side, -h + 0.02), P(x * side + 0.006 * side, h - 0.02)], fine)
            }
        }

        // The cock the pendulum hangs from, its spring and chops.
        Kit.mass(&plate, [P(-0.32, -1.12), P(0.32, -1.12), P(0.24, -0.93), P(-0.24, -0.93), P(-0.32, -1.12)])
        for x in [-0.16, 0.16] {
            plate.fill(arc(P(x, -0.975), 0.02))
            plate.line([P(x - 0.014, -0.975), P(x + 0.014, -0.975)], medium)
        }
        Kit.solid(&plate, box(-0.022, 0.04, 0.022, 0.1), angle: 0, gap: 0.012, width: fine)
        Kit.mass(&plate, box(-0.07, 0.09, 0.07, 0.13))

        // The gridiron: steel in ink, brass in bone, held by its crossbars.
        for (k, ring) in bars.enumerated() {
            if k % 2 == 0 {
                Kit.mass(&plate, ring)
                plate.line([at(Double(k - 2) * pitch - 0.012, top + 0.04), at(Double(k - 2) * pitch - 0.012, foot - 0.04)], fine, .bone)
            } else {
                let u = Double(k - 2) * pitch
                plate.fill(ring)
                plate.line(ring, heavy)
                plate.line([at(u + 0.01, top + 0.03), at(u + 0.01, foot - 0.03)], fine)
                for v in stride(from: 0.24, to: foot - 0.04, by: 0.1) { plate.line([at(u - 0.018, v), at(u - 0.004, v)], fine) }
            }
        }
        for (v0, v1, w) in [(top - 0.07, top + 0.01, 0.31), (0.29, 0.35, 0.18), (0.7, 0.76, 0.18), (foot - 0.01, foot + 0.07, 0.31)] {
            Kit.mass(&plate, box(-w, v0, w, v1))
            let pins = w > 0.2 ? [-0.24, -0.12, 0.12, 0.24] : [-0.12, 0.12]
            for u in pins { plate.fill(arc(at(u, (v0 + v1) / 2), 0.012)) }
        }

        // The rod on down to the rating nut and the lens bob, lit across its upper left.
        Kit.mass(&plate, box(-0.02, foot + 0.07, 0.02, 1.76))
        Kit.solid(&plate, box(-0.042, 1.66, 0.042, 1.71), angle: tilt + .pi / 2, gap: 0.012, width: fine)
        Kit.mass(&plate, bob)
        plate.fill(ellipse(at(-0.055, 1.79), 0.085, 0.018, turned: -tilt - 0.08), .bone)

        // The beat scale, its degrees either side of the rest, and the index under the bob reading it.
        let scale = arc(pivot, 1.935, from: .pi / 2 + 0.14, to: .pi / 2 - 0.14) + arc(pivot, 1.88, from: .pi / 2 - 0.14, to: .pi / 2 + 0.14)
        Kit.cut(&plate, scale + [scale[0]], edge: heavy)
        for k in -6...6 {
            let a = .pi / 2 + Double(k) * 0.02
            plate.line([polar(pivot, 1.88, a), polar(pivot, k % 3 == 0 ? 1.925 : 1.905, a)], k == 0 ? heavy : medium)
        }
        Kit.mass(&plate, [at(-0.025, 1.85), at(0.025, 1.85), at(0, 1.925), at(-0.025, 1.85)], ink: .second)

        callout(&plate, "A", from: at(-0.24, 0.55), to: polar(o, 0.56, Kit.clock(9)))
        callout(&plate, "B", from: at(0.12, 0.9), to: polar(o, 0.56, Kit.clock(3)))
        callout(&plate, "C", from: at(0.12, 1.79), to: P(0.46, 0.66))
        callout(&plate, "D", from: polar(pivot, 1.91, .pi / 2 + 0.12), to: P(-0.44, 0.7))
        return plate
    }

    /// Problem 86, Chronometer, hex, clocks 1+: a marine chronometer seen from above and before in its box, the lid
    /// thrown back and the box rolled as at sea, while its two gimbal rings, in ink, hold the bowl and dial level: the
    /// dial's seconds below and its power reserve above, whose hand is in the second ink.
    static func plate86() -> Plate {
        var plate = Plate()
        let o = Kit.origin, rise = 0.85, roll = 0.2, pitch = 0.08, scale = 0.7
        typealias Q = SIMD3<Double>
        func view(_ q: Q) -> P {
            let k = 5 / (5 + q.y * cos(rise) - q.z * sin(rise))
            return P(q.x * k, -(q.y * sin(rise) + q.z * cos(rise)) * k) * scale + P(0, 0.1)
        }
        func rolled(_ q: Q) -> Q { Q(q.x * cos(roll) - q.z * sin(roll), q.y, q.x * sin(roll) + q.z * cos(roll)) }
        func boxed(_ q: Q) -> Q {
            let r = rolled(q)
            return Q(r.x, r.y * cos(pitch) - r.z * sin(pitch), r.y * sin(pitch) + r.z * cos(pitch))
        }
        func box(_ x: Double, _ y: Double, _ z: Double) -> P { view(boxed(Q(x, y, z))) }
        func quad(_ a: Q, _ b: Q, _ c: Q, _ d: Q) -> [P] { [a, b, c, d, a].map { view(boxed($0)) } }
        /// A drawing in a plane laid level at height z, or rolled with the box when the outer ring has taken out its pitch.
        func laid(_ sub: Plate, z: Double, withRoll: Bool = false) -> [Mark] {
            sub.marks.map { mark in
                Mark(points: mark.points.map { f in withRoll ? view(rolled(Q(f.x, -f.y, z))) : view(Q(f.x, -f.y, z)) },
                     width: mark.width, ink: mark.ink)
            }
        }
        func annulus(_ r0: Double, _ r1: Double) -> [P] { arc(o, r1) + arc(o, r0).reversed() + [polar(o, r1, 0)] }

        Kit.ground(&plate, angle: 0.6)

        // The lid thrown back on its hinges, ebony, with a bone stringing and the maker's plaque.
        let rim = 1.1, wall = 1.03, deep = 0.5, lean = 0.5, tall = 1.3
        func lidAt(_ x: Double, _ t: Double) -> Q { Q(x, rim + lean * t, tall * t) }
        Kit.mass(&plate, [lidAt(-rim, 0), lidAt(rim, 0), lidAt(rim, 1), lidAt(-rim, 1), lidAt(-rim, 0)].map { view(boxed($0)) })
        Kit.cut(&plate, [lidAt(-0.95, 0.06), lidAt(0.95, 0.06), lidAt(0.95, 0.95), lidAt(-0.95, 0.95), lidAt(-0.95, 0.06)].map { view(boxed($0)) }, edge: heavy)
        let plaque = [lidAt(-0.4, 0.3), lidAt(0.4, 0.3), lidAt(0.4, 0.66), lidAt(-0.4, 0.66), lidAt(-0.4, 0.3)].map { view(boxed($0)) }
        Kit.mass(&plate, plaque)
        plate.line([lidAt(-0.34, 0.35), lidAt(0.34, 0.35), lidAt(0.34, 0.61), lidAt(-0.34, 0.61), lidAt(-0.34, 0.35)].map { view(boxed($0)) }, medium, .bone)
        for t in [0.43, 0.5] { plate.line([lidAt(-0.24, t), lidAt(0.24, t)].map { view(boxed($0)) }, heavy, .bone) }
        for t in [0.2, 0.78, 0.86] { plate.line([lidAt(-0.84, t), lidAt(0.84, t)].map { view(boxed($0)) }, medium) }
        for x in [-0.66, 0.66] {
            Kit.cut(&plate, [lidAt(x - 0.1, 0), lidAt(x + 0.1, 0), lidAt(x + 0.1, 0.07), lidAt(x - 0.1, 0.07), lidAt(x - 0.1, 0)].map { view(boxed($0)) })
            plate.line([lidAt(x - 0.1, 0.035), lidAt(x + 0.1, 0.035)].map { view(boxed($0)) }, medium)
        }

        // The box: its back and side walls inside, the rim, and the front, in ebony grained bold.
        Kit.cut(&plate, quad(Q(-wall, wall, 0), Q(wall, wall, 0), Q(wall, wall, -deep), Q(-wall, wall, -deep)))
        for z in [-0.17, -0.34] { plate.line([box(-wall, wall, z), box(wall, wall, z)], heavy) }
        for x in [-wall, wall] {
            Kit.cut(&plate, quad(Q(x, wall, 0), Q(x, -wall, 0), Q(x, -wall, -deep), Q(x, wall, -deep)))
            for z in [-0.17, -0.34] { plate.line([box(x, wall, z), box(x, -wall, z)], heavy) }
        }
        let rims = [quad(Q(-rim, rim, 0), Q(rim, rim, 0), Q(wall, wall, 0), Q(-wall, wall, 0)),
                    quad(Q(rim, rim, 0), Q(rim, -rim, 0), Q(wall, -wall, 0), Q(wall, wall, 0)),
                    quad(Q(rim, -rim, 0), Q(-rim, -rim, 0), Q(-wall, -wall, 0), Q(wall, -wall, 0)),
                    quad(Q(-rim, -rim, 0), Q(-rim, rim, 0), Q(-wall, wall, 0), Q(-wall, -wall, 0))]
        for ring in rims { Kit.mass(&plate, ring) }
        Kit.mass(&plate, quad(Q(-rim, -rim, 0), Q(rim, -rim, 0), Q(rim, -rim, -deep), Q(-rim, -rim, -deep)))
        for k in 0..<4 {
            let z = -0.08 - 0.12 * Double(k)
            plate.line((0...16).map { i in
                let x = -rim + 2 * rim * Double(i) / 16
                return box(x, -rim, z + 0.025 * sin(Double(i) * 0.9 + Double(k)))
            }, heavy, .bone)
        }
        plate.line([box(-rim, -rim, 0), box(rim, -rim, 0)], heavy, .bone)

        // The outer gimbal ring, pivoted in the side walls and pitched with the sea, then the inner ring on it, level.
        var outer = Plate(), inner = Plate()
        for side in [-1.0, 1.0] {
            Kit.mass(&outer, Kit.band(P(0.9 * side, 0), P(1.04 * side, 0), 0.07))
            outer.fill(arc(P(1.0 * side, 0), 0.02))
            Kit.mass(&inner, Kit.band(P(0, 0.76 * side), P(0, 0.93 * side), 0.06))
            inner.fill(arc(P(0, 0.9 * side), 0.018))
        }
        Kit.mass(&outer, annulus(0.89, 0.96))
        for k in 0..<16 { outer.fill(Kit.band(polar(o, 0.895, Double(k) * .pi / 8 + 0.2), polar(o, 0.955, Double(k) * .pi / 8 + 0.2), 0.028), .bone) }
        Kit.mass(&inner, annulus(0.755, 0.805))
        inner.line(arc(o, 0.78), heavy, .bone)
        plate.marks += laid(outer, z: -0.16, withRoll: true)
        plate.marks += laid(inner, z: -0.14)

        // The bowl under the dial, lit on its near side, the bezel and the dial.
        let r = 0.62
        var face = Plate()
        Kit.mass(&face, arc(o, 0.655))
        Kit.dial(&face, o, r, numerals: false)
        for k in 1...12 {
            face.lines(Kit.numeral(roman(k), at: polar(o, 0.81 * r, Kit.clock(Double(k))), height: 0.13 * r,
                                   turn: Kit.clock(Double(k)) + .pi / 2, squeeze: 0.66), 0.014)
        }
        face.line(arc(o, 0.645), fine, .bone)
        // The seconds at six, the power reserve over two.
        let seconds = P(0, 0.31), reserve = polar(o, 0.415, Kit.clock(2)), small = 0.085
        for (c, ticks) in [(seconds, 12), (reserve, 0)] {
            face.fill(arc(c, small))
            face.line(arc(c, small), heavy)
            for k in 0..<ticks { face.line([polar(c, 0.06, Double(k) * .pi / 6), polar(c, small, Double(k) * .pi / 6)], medium) }
        }
        for k in 0...6 {
            let a = Kit.clock(2) - .pi / 2 - 1.0 + 2.0 * Double(k) / 6
            face.line([polar(reserve, k % 3 == 0 ? 0.045 : 0.065, a), polar(reserve, small, a)], k % 3 == 0 ? heavy : medium)
        }
        Kit.hands(&face, o, r, hours: 3, minutes: 40)
        Kit.mass(&face, Kit.hand(seconds, toward: Kit.clock(4), length: 0.075, width: 0.016, tail: 0.02))
        face.fill(arc(seconds, 0.011))
        Kit.mass(&face, Kit.hand(reserve, toward: Kit.clock(2) - .pi / 2 + 0.55, length: 0.085, width: 0.024, tail: 0.016), ink: .second)
        face.fill(arc(reserve, 0.011))
        plate.marks += laid(face, z: -0.08)

        callout(&plate, "A", from: view(rolled(Q(-0.925 * cos(0.7), -0.925 * sin(0.7), -0.16))),
                to: polar(o, 0.62, Kit.clock(7)))
        callout(&plate, "B", from: view(Q(0.775 * cos(0.25), -0.775 * sin(0.25), -0.14)), to: polar(o, 0.62, Kit.clock(3)))
        callout(&plate, "C", from: box(1.03, 0.4, 0), to: polar(o, 0.86, Kit.clock(1.5)))
        callout(&plate, "D", from: view(Q(reserve.x, -reserve.y + 0.06, -0.08)), to: polar(o, 0.62, Kit.clock(1)))
        return plate
    }

    /// Problem 87, Longcase clock, hex, clocks 1+: a longcase clock the height of the glass in figured mahogany, its
    /// hood with the arched dial between pillars, the trunk's door in flame figure, and the plinth on bracket feet; the
    /// pendulum's bob, seen through the lenticle in the door, in the second ink.
    static func plate87() -> Plate {
        var plate = Plate()
        let dial = P(0, -0.53), face = 0.175, lenticle = P(0, 0.28), waist = -0.3
        /// Straight grain down a rect, in bold lines that wander.
        func grain(_ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double, gap: Double, seed: Int, ink: Ink = .bone) {
            var x = x0 + gap / 2, k = 0
            while x < x1 - gap / 3 {
                plate.line((0...10).map { i in
                    P(x + 0.01 * sin(Double(i) * 0.9 + 6 * rnd(seed, k)), y0 + (y1 - y0) * Double(i) / 10)
                }, 0.012, ink)
                x += gap
                k += 1
            }
        }

        Kit.ground(&plate, angle: 0.5)
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
            let w = 0.24 - 0.075 * Double(k), h = 0.07 - 0.02 * Double(k)
            plate.line(ellipse(P(0.012 * Double(k), 0.735), w, h), 0.014)
        }
        Kit.mass(&plate, box(P(-0.26, 0.555), P(0.26, 0.57)))
        Kit.cut(&plate, box(P(-0.3, 0.57), P(0.3, 0.6)))

        // The trunk: its stiles in straight grain, the door in flame figure, and the lenticle in the door.
        Kit.mass(&plate, box(P(-0.22, waist + 0.02), P(0.22, 0.555)))
        for x in [-0.19, 0.19] { Kit.cut(&plate, box(P(x - 0.03, waist + 0.02), P(x + 0.03, 0.55)), edge: medium) }
        grain(-0.22, -0.16, waist + 0.04, 0.54, gap: 0.03, seed: 1, ink: .black)
        grain(0.16, 0.22, waist + 0.04, 0.54, gap: 0.03, seed: 2, ink: .black)
        let crown = P(0, -0.07), spring = atan2(-0.17 - crown.y, -0.15)
        let door = [P(-0.15, 0.545)] + arc(crown, simd_distance(crown, P(-0.15, -0.17)), from: spring, to: -.pi - spring)
            + [P(0.15, 0.545), P(-0.15, 0.545)]
        Kit.cut(&plate, door, edge: 0.016)
        for k in 0..<8 {
            let crest = 0.6 - 0.1 * Double(k)
            plate.line((0...16).map { i in
                let x = -0.125 + 0.25 * Double(i) / 16
                return P(x, min(0.51, crest + 0.14 * pow(abs(x) / 0.125, 1.4) + 0.01 * sin(Double(i + k))))
            }, 0.024)
        }
        Kit.mass(&plate, arc(lenticle, 0.085))
        plate.line(arc(lenticle, 0.085), 0.016, .bone)
        plate.line(arc(lenticle, 0.07), fine, .bone)
        plate.line([lenticle + P(0, -0.07), lenticle + P(0, -0.02)], medium, .bone)
        Kit.mass(&plate, arc(lenticle + P(0, 0.008), 0.045), ink: .second)
        plate.line(arc(lenticle + P(-0.014, -0.006), 0.016, from: 3.4, to: 4.6), medium, .bone)
        Kit.mass(&plate, box(P(-0.27, waist - 0.005), P(0.27, waist + 0.02)))
        Kit.mass(&plate, box(P(-0.33, waist - 0.035), P(0.33, waist - 0.015)))

        // The hood: its pillars, the arched dial, and the cornice under the finials.
        let hood = 0.34, square = 0.2, arch = P(0, dial.y - square)
        Kit.mass(&plate, box(P(-hood, waist - 0.035), P(hood, -0.93)))
        for side in [-1.0, 1.0] {
            let x = 0.27 * side
            Kit.cut(&plate, box(P(x - 0.02, -0.86), P(x + 0.02, waist - 0.06)), edge: medium)
            for y in [-0.85, waist - 0.07] { Kit.mass(&plate, box(P(x - 0.033, y - 0.018), P(x + 0.033, y + 0.018))) }
            plate.line([P(x - 0.007, -0.83), P(x - 0.007, waist - 0.09)], medium)
            Kit.mass(&plate, arc(P(0.33 * side, -0.99), 0.035))
        }
        Kit.mass(&plate, box(P(-0.39, -0.94), P(0.39, -0.9)))
        plate.line([P(-0.38, -0.92), P(0.38, -0.92)], medium, .bone)
        Kit.mass(&plate, arc(P(0, -1.0), 0.05))
        let opening = [P(-square - 0.04, waist - 0.05), P(square + 0.04, waist - 0.05), P(square + 0.04, arch.y)]
            + arc(arch, square + 0.04, from: 0, to: -.pi) + [P(-square - 0.04, waist - 0.05)]
        Kit.cut(&plate, opening, edge: heavy)
        // The arch's boss, the moon riding over its hills, and the spandrels' scrolls in the dial's corners.
        plate.line(arc(arch, 0.15, from: .pi, to: 2 * .pi) + [arch + P(0.15, 0), arch + P(-0.15, 0)], heavy)
        Kit.solid(&plate, arc(arch, 0.1, from: .pi, to: 2 * .pi) + [arch + P(-0.1, 0)], angle: 0, gap: 0.016)
        Kit.mass(&plate, arc(arch + P(0.02, -0.06), 0.03))
        for (sx, sy) in [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)] {
            let corner = P(0.19 * sx, dial.y + 0.19 * sy)
            Kit.solid(&plate, [corner + P(0.02 * sx, 0.01 * sy), corner + P(-0.01 * sx, 0.025 * sy), corner + P(-0.045 * sx, -0.01 * sy),
                               corner + P(-0.01 * sx, -0.045 * sy), corner + P(0.01 * sx, 0.005 * sy), corner + P(0.02 * sx, 0.01 * sy)],
                      angle: 0.8 * sx * sy, gap: 0.012, width: fine)
        }
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

        callout(&plate, "A", from: P(-0.3, -0.62), to: polar(Kit.origin, 0.62, Kit.clock(10.8)))
        callout(&plate, "B", from: P(0.19, 0.1), to: polar(Kit.origin, 0.6, Kit.clock(3)))
        callout(&plate, "C", from: lenticle + P(0.06, 0.03), to: polar(Kit.origin, 0.62, Kit.clock(5)))
        callout(&plate, "D", from: P(-0.3, 0.73), to: polar(Kit.origin, 0.64, Kit.clock(7)))
        return plate
    }

    /// Problem 88, Atomic clock, hex, clocks 1+: an atom inside a seconds bezel, three bold orbits crossing about the
    /// nucleus, set off the hub in the lane at one o'clock, each orbit's far half passing behind it and an electron
    /// streaking along its near half; the nucleus's protons in the second ink.
    static func plate88() -> Plate {
        var plate = Plate()
        let o = Kit.origin, nucleus = polar(o, 0.285, Kit.clock(1)), a = 0.7, b = 0.2, band = 0.088
        let turns = [0.25, 0.25 + .pi / 3, 0.25 + 2 * .pi / 3]
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

    /// Problem 89, Millennium, hex, clocks 1+.
    static func plate89() -> Plate? { nil }

    /// Problem 90, Eternity, hex, clocks 1+: the serpent that eats its tail, round the rim past every hub, about a
    /// Moebius band, the strip with one side and no end, its face in ink and its back ruled; the serpent's eye in the
    /// second ink.
    static func plate90() -> Plate {
        var plate = Plate()
        let o = Kit.origin, body = 0.865, thick = 0.105
        // The serpent from its tail just past twelve, clockwise all the way round to its head, swelling from the tail.
        let start = Kit.clock(0.55), end = Kit.clock(12) + 2 * .pi - 0.1, n = 320
        let spine = (0...n).map { i -> P in
            let t = Double(i) / Double(n)
            return polar(o, body + 0.014 * sin(t * 36 * .pi), start + (end - start) * t)
        }
        let girth = (0...n).map { i -> Double in thick * min(1, 0.2 + 4 * Double(i) / Double(n)) }
        let normals = spine.indices.map { i -> P in
            let d = spine[min(i + 1, n)] - spine[max(i - 1, 0)]
            return simd_normalize(P(-d.y, d.x))
        }
        let serpent = spine.indices.map { spine[$0] + normals[$0] * girth[$0] / 2 }
            + spine.indices.reversed().map { spine[$0] - normals[$0] * girth[$0] / 2 } + [spine[0] + normals[0] * girth[0] / 2]
        // The head, a blunt wedge biting the tail.
        let neck = end, snout = end + 0.2
        let head = [polar(o, body + 0.068, neck), polar(o, body + 0.075, neck + 0.1), polar(o, body + 0.04, snout),
                    polar(o, body - 0.035, snout), polar(o, body - 0.07, neck + 0.1), polar(o, body - 0.062, neck),
                    polar(o, body + 0.068, neck)]

        // The Moebius band: a strip turned half over in one round, seen from above, its quads laid back to front.
        let radius = 0.42, half = 0.17, tilt = 1.0, m = 144
        func at(_ u: Double, _ v: Double) -> SIMD3<Double> {
            let r = radius + v * cos(u / 2)
            return SIMD3(r * cos(u - .pi / 2), r * sin(u - .pi / 2), v * sin(u / 2))
        }
        func seen(_ q: SIMD3<Double>) -> P { P(q.x, q.y * cos(tilt) - q.z * sin(tilt) + 0.02) }
        func depth(_ q: SIMD3<Double>) -> Double { q.y * sin(tilt) + q.z * cos(tilt) }
        let quads = (0..<m).map { i -> (ring: [P], depth: Double, face: Bool, edge: [P], other: [P]) in
            let u0 = 2 * .pi * Double(i) / Double(m), u1 = 2 * .pi * (Double(i) + 1.08) / Double(m)
            let a = at(u0, -half), b = at(u1, -half), c = at(u1, half), d = at(u0, half)
            // The side facing the eye: the normal's component toward it.
            let normal = simd_cross(b - a, d - a), toward = SIMD3(0, -sin(tilt), cos(tilt))
            return ([seen(a), seen(b), seen(c), seen(d), seen(a)], depth(a + b + c + d), simd_dot(normal, toward) > 0,
                    [seen(a), seen(b)], [seen(d), seen(c)])
        }

        Kit.ground(&plate, angle: 0.35, around: [serpent, head] + quads.map(\.ring))
        for (k, q) in quads.enumerated().sorted(by: { $0.element.depth < $1.element.depth }) {
            if q.face {
                plate.fill(q.ring, .black)
                if k % 6 == 0 { plate.line([q.ring[0], q.ring[3]], fine, .bone) }
            } else {
                plate.fill(q.ring)
                if k % 3 == 0 { plate.line([q.ring[0], q.ring[3]], medium) }
            }
            plate.line(q.edge, heavy)
            plate.line(q.other, heavy)
        }

        // The serpent: ink, its scales in bone across its back, and its belly's line.
        Kit.mass(&plate, serpent)
        for k in stride(from: 10, to: n - 6, by: 7) {
            let w = girth[k] * 0.3, ahead = simd_normalize(spine[k + 3] - spine[k]) * 0.022
            plate.line([spine[k] + normals[k] * w, spine[k] + ahead, spine[k] - normals[k] * w], fine, .bone)
        }
        Kit.mass(&plate, head)
        plate.line([polar(o, body + 0.005, snout - 0.01), polar(o, body - 0.005, neck + 0.04)], medium, .bone)
        let eye = polar(o, body + 0.03, neck + 0.075)
        plate.fill(arc(eye, 0.022), .second)
        plate.line(arc(eye, 0.022), fine, .bone)
        plate.fill(arc(eye, 0.008), .black)

        // The hours outside the serpent, bold.
        for k in 1..<12 {
            Kit.mass(&plate, Kit.band(polar(o, 0.955, Kit.clock(Double(k))), polar(o, 1.01, Kit.clock(Double(k))), 0.035))
        }
        callout(&plate, "A", from: polar(o, body, Kit.clock(7.4)), to: P(-0.68, 0.36))
        callout(&plate, "B", from: seen(at(.pi * 0.25, 0)), to: P(0.42, 0.62))
        return plate
    }
}
