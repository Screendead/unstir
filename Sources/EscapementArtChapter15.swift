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
