// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 15, Perpetual: problems 85 to 90's plates, drawn with `Kit`. Not drawn yet: each falls back to
/// the shared plate.
extension EscapementArt {
    /// Problem 85, Regulator, hex, clocks 1+.
    static func plate85() -> Plate? { nil }

    /// Problem 86, Chronometer, hex, clocks 1+.
    static func plate86() -> Plate? { nil }

    /// Problem 87, Longcase clock, hex, clocks 1+.
    static func plate87() -> Plate? { nil }

    /// Problem 88, Atomic clock, hex, clocks 1+.
    static func plate88() -> Plate? { nil }

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
