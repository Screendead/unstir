// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 12, Dead Beat: problems 67 to 72's plates, drawn with `Kit`.
extension EscapementArt {
    /// A sail hung slack from a yard at `yard`: bone cloth in ink folds that widen to its foot, the foot gathered.
    private static func limpSail(_ plate: inout Plate, _ yard: P, half: Double, drop: Double, seed: Int) {
        let foot = (0...16).map { i -> P in
            let t = Double(i) / 16, x = yard.x + half * 0.82 * (1 - 2 * t)
            return P(x, yard.y + drop + 0.022 * abs(sin(t * 4 * .pi)) - 0.03 * sin(t * .pi))
        }
        let cloth = [P(yard.x - half, yard.y), P(yard.x + half, yard.y)] + curve(P(yard.x + half, yard.y), P(yard.x + 0.9 * half, yard.y + 0.5 * drop), foot[0], 8).dropFirst()
            + foot.dropFirst() + curve(foot[16], P(yard.x - 0.9 * half, yard.y + 0.5 * drop), P(yard.x - half, yard.y), 8).dropFirst()
        plate.fill(cloth)
        // The lee edge in shadow, a bold wedge widening to the foot.
        let lee = [P(yard.x + half - 0.004, yard.y + 0.01), foot[0] + P(-0.004, -0.01), foot[2] + P(0, -0.01),
                   P(yard.x + half - 0.03, yard.y + 0.01), P(yard.x + half - 0.004, yard.y + 0.01)]
        plate.fill(lee, .black)
        // Deep folds in ink, bold enough to follow through a stir, each with a bone crease beside it.
        let folds = half < 0.1 ? [-0.2] : [-0.45, 0.15]
        for (k, u0) in folds.enumerated() {
            let u = u0 + 0.08 * (rnd(seed, k) - 0.5)
            let top = P(yard.x + u * half, yard.y + 0.015), low = P(yard.x + u * half * 0.82, yard.y + drop - 0.01)
            let fold = curve(top, P(top.x + 0.025, (top.y + low.y) / 2), low, 12)
            let ring = fold.enumerated().map { $0.element + P(-(0.012 + 0.016 * Double($0.offset) / 12), 0) }
                + fold.enumerated().reversed().map { $0.element + P(0.012 + 0.016 * Double($0.offset) / 12, 0) }
            plate.fill(ring + [ring[0]], .black)
            plate.line(fold.map { $0 + P(0.04, 0) }.dropLast(3), medium)
        }
        plate.line(cloth, heavy)
    }

    /// Problem 67, Lull, hex, clocks 1+: a three-masted ship becalmed, its sails hanging slack in folds from the yards,
    /// its hull in ink over its broken reflection on a sea of long flat bands; the limp pennant at the main truck in the
    /// second ink, above the hubs.
    static func plate67() -> Plate {
        var plate = Plate()
        let o = Kit.origin, sea = 0.42, R = 1.06, a0 = asin(sea / R)
        let sky = arc(o, R, from: .pi - a0, to: 2 * .pi + a0), water = arc(o, R, from: a0, to: .pi - a0)
        plate.lines(hatch([sky + [sky[0]]], angle: 0, gap: Kit.groundGap), Kit.groundWidth)
        let still = [P(-0.52, sea), P(0.48, sea), P(0.24, 0.98), P(-0.2, 0.98), P(-0.52, sea)]
        plate.lines(hatch([water + [water[0]], still], angle: 0, gap: Kit.groundGap, shift: 0.3), Kit.groundWidth)

        // The hull: high stern on the left, sheer dipping amidships, the bow raked to its beak.
        let deck = curve(P(-0.66, 0.12), P(0, 0.3), P(0.6, 0.15), 30)
        let hull = deck + curve(P(0.6, 0.15), P(0.56, 0.36), P(0.44, sea), 12)
            + [P(-0.5, sea)] + curve(P(-0.5, sea), P(-0.62, 0.3), P(-0.66, 0.12), 10).dropFirst()
        let wale = Kit.ribbon(deck.enumerated().filter { $0.offset >= 2 && $0.offset <= 27 }.map { $0.element + P(0, 0.075) }, 0.05)

        // The reflection, the hull's dark broken into flat bands that thin away from the waterline.
        var reflection: [[P]] = []
        for k in 0..<5 {
            let y = sea + 0.04 + Double(k) * 0.12, h = 0.045
            let left = -0.48 + 0.07 * Double(k) + 0.05 * rnd(67, k), right = 0.44 - 0.05 * Double(k) - 0.06 * rnd(67, k + 9)
            reflection.append(box(P(left, y), P(right, y + h)))
        }
        // The calm: long flat strokes of ink across the open water either side.
        var calm: [[P]] = []
        for k in 0..<6 {
            let y = sea + 0.095 + Double(k) * 0.11
            let half = sqrt(max(0, 1.0 - y * y))
            let l = -half + 0.04 + 0.12 * rnd(68, k), r = half - 0.04 - 0.12 * rnd(69, k)
            let w = 0.022 + 0.012 * Double(k % 3)
            if l < -0.56 && k % 2 == 1 && y > 0.6 { calm.append(Kit.band(P(l, y), P(min(-0.56 + 0.05 * Double(k), -0.3), y), w)) }
            if r > 0.5 && y > 0.6 { calm.append(Kit.band(P(max(0.5 - 0.05 * Double(k), 0.3), y), P(r, y), w)) }
        }
        for c in calm { plate.fill(c, .black) }
        for r in reflection { plate.fill(r, .black) }
        // A long bone glint across the reflection.

        // Masts, yards and the sails hanging from them, each mast drawn whole before the next.
        let masts: [(x: Double, top: Double, yards: [(y: Double, half: Double, drop: Double)])] = [
            (-0.36, -0.6, [(-0.04, 0.14, 0.2), (-0.32, 0.11, 0.19), (-0.52, 0.075, 0.09)]),
            (0.0, -0.84, [(-0.1, 0.16, 0.26), (-0.42, 0.135, 0.24), (-0.67, 0.1, 0.13)]),
            (0.33, -0.72, [(-0.06, 0.15, 0.24), (-0.36, 0.12, 0.22), (-0.59, 0.085, 0.11)]),
        ]
        // The rigging under the sails: stays to the bowsprit and the stern, shrouds to the deck.
        let sprit = P(0.92, -0.02)
        plate.line([P(0.33, -0.66), sprit], medium)
        plate.line([P(0.0, -0.78), P(0.33, -0.3)], medium)
        plate.line([P(-0.36, -0.56), P(0.0, -0.36)], medium)
        plate.line([P(-0.36, -0.56), P(-0.66, 0.1)], medium)
        for m in masts {
            for d in [-0.15, -0.09, 0.09, 0.15] {
                plate.line([P(m.x, m.yards[0].y - 0.05), P(m.x + d, 0.2 + 0.1 * (m.x + d) * (m.x + d))], fine)
            }
        }
        Kit.mass(&plate, Kit.band(P(0.5, 0.17), sprit, 0.034))
        for m in masts {
            Kit.mass(&plate, [P(m.x - 0.026, 0.22), P(m.x - 0.014, m.top), P(m.x + 0.014, m.top), P(m.x + 0.026, 0.22), P(m.x - 0.026, 0.22)])
            plate.fill(arc(P(m.x, m.top - 0.012), 0.02), .black)
            for (i, yard) in m.yards.enumerated() {
                limpSail(&plate, P(m.x, yard.y), half: yard.half, drop: yard.drop, seed: Int(m.x * 100) + i)
                Kit.mass(&plate, Kit.band(P(m.x - yard.half - 0.03, yard.y), P(m.x + yard.half + 0.03, yard.y), 0.03))
            }
        }

        Kit.mass(&plate, hull + [hull[0]])
        Kit.cut(&plate, wale, edge: medium)
        for k in 0..<10 {
            let i = 4 + 2 * k
            let c = deck[i] + P(0, 0.075)
            plate.fill(box(c - P(0.014, 0.014), c + P(0.014, 0.014)), .black)
        }
        plate.line(deck.enumerated().filter { $0.offset < 28 }.map { $0.element + P(0, 0.028) }, 0.02, .bone)
        // The boot-top above the waterline in bone, its planks drawn.
        let boot = curve(P(-0.52, sea - 0.06), P(0, sea - 0.035), P(0.48, sea - 0.07), 20)
        Kit.cut(&plate, Kit.ribbon(boot, 0.05), edge: medium)
        plate.line(boot, fine)
        for k in stride(from: 1, to: 20, by: 2) { plate.line([boot[k] + P(0, -0.025), boot[k] + P(0, 0)], fine) }
        // The bower anchor catted at the bow, in bone on the dark of the hull, its cable from the hawse.
        let shank = P(0.5, 0.2)
        plate.line([shank, shank + P(-0.01, 0.15)], 0.02, .bone)
        plate.line(curve(shank + P(-0.07, 0.11), shank + P(-0.02, 0.19), shank + P(0.05, 0.1), 10), 0.018, .bone)
        plate.line([shank + P(-0.045, 0.025), shank + P(0.04, 0.025)], 0.016, .bone)
        plate.line(arc(shank + P(0, -0.012), 0.014), 0.008, .bone)
        plate.line(curve(P(0.555, 0.205), P(0.53, 0.3), P(0.5, 0.188), 10), medium, .bone)
        plate.fill(arc(P(0.56, 0.2), 0.016))
        // The rudder's edge down the stern post, and a strake drawn under the wale aft where the hull stands tall.
        plate.line(curve(P(-0.6, 0.3), P(-0.585, 0.37), P(-0.535, sea - 0.04), 8), 0.016, .bone)
        plate.line(deck[3...11].map { $0 + P(0, 0.135) }, 0.016, .bone)
        // The quarter gallery on the stern, in bone with its lights barred.
        let gallery = [P(-0.63, 0.14), P(-0.47, 0.17), P(-0.48, 0.27), P(-0.53, 0.31), P(-0.6, 0.3), P(-0.63, 0.14)]
        Kit.cut(&plate, gallery, edge: heavy)
        for k in 0..<3 {
            let w = P(-0.612 + 0.047 * Double(k), 0.17 + 0.009 * Double(k))
            plate.fill(box(w, w + P(0.03, 0.07)), .black)
            plate.line([w + P(0.015, 0), w + P(0.015, 0.07)], fine, .bone)
            plate.line([w + P(0, 0.035), w + P(0.03, 0.035)], fine, .bone)
        }
        plate.lines(hatch([[P(-0.6, 0.265), P(-0.49, 0.27), P(-0.53, 0.305), P(-0.59, 0.295), P(-0.6, 0.265)]], angle: 0.5, gap: 0.014), fine)
        // The stern's lantern and its castle rail.
        plate.line([P(-0.66, 0.12), P(-0.66, 0.06), P(-0.46, 0.1)], heavy)
        for x in stride(from: -0.64, through: -0.48, by: 0.04) { plate.line([P(x, 0.065 + 0.2 * (x + 0.66)), P(x, 0.12 + 0.2 * (x + 0.66))], fine) }

        // The pennant at the main truck, hanging limp, clear of the hub below.
        let truck = P(0.0, -0.87)
        let streamer = [truck + P(0, -0.02), P(0.1, -0.89), P(0.17, -0.85), P(0.2, -0.77), P(0.19, -0.72), P(0.175, -0.775),
                        P(0.14, -0.835), P(0.09, -0.86), truck + P(0, 0.02), truck + P(0, -0.02)]
        plate.fill(streamer, .second)
        plate.line(streamer, medium)
        plate.fill(arc(truck, 0.016), .black)

        callout(&plate, "A", from: P(-0.2, 0.3), to: P(-0.74, 0.5))
        callout(&plate, "B", from: P(0.38, -0.25), to: P(0.74, -0.52))
        callout(&plate, "C", from: P(0.12, 0.68), to: P(0.52, 0.8))
        callout(&plate, "D", from: P(0.09, -0.86), to: P(0.34, -0.9))
        return plate
    }

    /// Problem 68, Interlude, pent, clocks 0+.
    static func plate68() -> Plate? { nil }

    /// Problem 69, Siesta, hex, clocks 1+.
    static func plate69() -> Plate? { nil }

    /// Problem 70, Respite, pent, clocks 0+.
    static func plate70() -> Plate? { nil }

    /// Problem 71, Intermission, hex, clocks 1+.
    static func plate71() -> Plate? { nil }

    /// Problem 72, Hiatus, hex, clocks 1+.
    static func plate72() -> Plate? { nil }
}
