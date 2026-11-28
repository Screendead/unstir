// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 12, Dead Beat: problems 67 to 72's plates, drawn with `Kit`.
extension EscapementArt {
    /// A strip along a path that swells from `thin` at its ends to `thick` in its middle, as one outline.
    private static func swell(_ path: [P], _ thin: Double, _ thick: Double) -> [P] {
        var left: [P] = []
        var right: [P] = []
        let last: Int = path.count - 1
        for i in 0...last {
            let next: Int = min(i + 1, last)
            let prev: Int = max(i - 1, 0)
            let d: P = path[next] - path[prev]
            let u: Double = Double.pi * Double(i) / Double(last)
            let s: Double = sin(u)
            let w: Double = thin + (thick - thin) * s
            let perp: P = P(-d.y, d.x)
            let unit: P = simd_normalize(perp)
            let n: P = unit * (w / 2)
            left.append(path[i] + n)
            right.append(path[i] - n)
        }
        let back: [P] = Array(right.reversed())
        return left + back + [left[0]]
    }

    /// A sail hung slack from a yard at `yard`: bone cloth in ink folds that widen to its foot, the foot gathered.
    private static func limpSail(_ plate: inout Plate, _ yard: P, half: Double, drop: Double, seed: Int) {
        let foot: [P] = (0...16).map { (i: Int) -> P in
            let t: Double = Double(i) / 16, x: Double = yard.x + half * 0.82 * (1 - 2 * t)
            return P(x, yard.y + drop + 0.022 * abs(sin(t * 4 * .pi)) - 0.03 * sin(t * .pi))
        }
        let top: [P] = [P(yard.x - half, yard.y), P(yard.x + half, yard.y)]
        let right: [P] = Array(curve(P(yard.x + half, yard.y), P(yard.x + 0.9 * half, yard.y + 0.5 * drop), foot[0], 8).dropFirst())
        let left: [P] = Array(curve(foot[16], P(yard.x - 0.9 * half, yard.y + 0.5 * drop), P(yard.x - half, yard.y), 8).dropFirst())
        let cloth: [P] = top + right + Array(foot.dropFirst()) + left
        plate.fill(cloth)
        limpSailLee(&plate, yard, half: half, foot: foot)
        limpSailFolds(&plate, yard, half: half, drop: drop, seed: seed)
        plate.line(cloth, heavy)
    }

    private static func limpSailLee(_ plate: inout Plate, _ yard: P, half: Double, foot: [P]) {
        // The lee edge in shadow, a bold wedge widening to the foot.
        let lee: [P] = [P(yard.x + half - 0.004, yard.y + 0.01), foot[0] + P(-0.004, -0.01), foot[2] + P(0, -0.01),
                   P(yard.x + half - 0.03, yard.y + 0.01), P(yard.x + half - 0.004, yard.y + 0.01)]
        plate.fill(lee, .black)
    }

    private static func limpSailFolds(_ plate: inout Plate, _ yard: P, half: Double, drop: Double, seed: Int) {
        // Deep folds in ink, bold enough to follow through a stir, each with a bone crease beside it.
        let folds = half < 0.1 ? [-0.2] : [-0.45, 0.15]
        for (k, u0) in folds.enumerated() {
            let u = u0 + 0.08 * (rnd(seed, k) - 0.5)
            let top = P(yard.x + u * half, yard.y + 0.015), low = P(yard.x + u * half * 0.82, yard.y + drop - 0.01)
            let fold = curve(top, P(top.x + 0.025, (top.y + low.y) / 2), low, 12)
            let near: [P] = fold.enumerated().map { (i: Int, p: P) -> P in
                let w: Double = 0.012 + 0.016 * Double(i) / 12
                return p - P(w, 0)
            }
            let far: [P] = fold.enumerated().reversed().map { (i: Int, p: P) -> P in
                let w: Double = 0.012 + 0.016 * Double(i) / 12
                return p + P(w, 0)
            }
            let ring: [P] = near + far
            plate.fill(ring + [ring[0]], .black)
            plate.line(fold.map { $0 + P(0.04, 0) }.dropLast(3), medium)
        }
    }

    private static let plate67MastList: [(x: Double, top: Double, yards: [(y: Double, half: Double, drop: Double)])] = [
        (-0.36, -0.6, [(-0.04, 0.14, 0.2), (-0.32, 0.11, 0.19), (-0.52, 0.075, 0.09)]),
        (0.0, -0.84, [(-0.1, 0.16, 0.26), (-0.42, 0.135, 0.24), (-0.67, 0.1, 0.13)]),
        (0.33, -0.72, [(-0.06, 0.15, 0.24), (-0.36, 0.12, 0.22), (-0.59, 0.085, 0.11)]),
    ]

    /// Problem 67, Lull, hex, clocks 1+: a three-masted ship becalmed, its sails hanging slack in folds from the yards,
    /// its hull in ink over its broken reflection on a sea of long flat bands; the limp pennant at the main truck in the
    /// second ink, above the hubs.
    static func plate67() -> Plate {
        var plate = Plate()
        let sea: Double = 0.42
        plate67Sea(&plate, sea)
        // The hull: high stern on the left, sheer dipping amidships, the bow raked to its beak.
        let (deck, hull, wale) = plate67Hull(sea)
        plate67Water(&plate, sea)
        plate67Rigging(&plate)
        plate67Masts(&plate)
        plate67Wale(&plate, deck, hull, wale)
        plate67Boot(&plate, sea)
        plate67Stern(&plate, deck, sea)
        plate67Pennant(&plate)
        callout(&plate, "A", from: P(-0.2, 0.3), to: P(-0.74, 0.5))
        callout(&plate, "B", from: P(0.38, -0.25), to: P(0.74, -0.52))
        callout(&plate, "C", from: P(0.12, 0.68), to: P(0.52, 0.8))
        callout(&plate, "D", from: P(0.09, -0.86), to: P(0.34, -0.9))
        return plate
    }

    private static func plate67Sea(_ plate: inout Plate, _ sea: Double) {
        let o = Kit.origin, R = 1.06, a0 = asin(sea / R)
        let sky = arc(o, R, from: .pi - a0, to: 2 * .pi + a0), water = arc(o, R, from: a0, to: .pi - a0)
        plate.lines(hatch([sky + [sky[0]]], angle: 0, gap: Kit.groundGap), Kit.groundWidth)
        let still = [P(-0.52, sea), P(0.48, sea), P(0.24, 0.98), P(-0.2, 0.98), P(-0.52, sea)]
        plate.lines(hatch([water + [water[0]], still], angle: 0, gap: Kit.groundGap, shift: 0.3), Kit.groundWidth)
    }

    private static func plate67Hull(_ sea: Double) -> ([P], [P], [P]) {
        let deck = curve(P(-0.66, 0.12), P(0, 0.3), P(0.6, 0.15), 30)
        let hull = deck + curve(P(0.6, 0.15), P(0.56, 0.36), P(0.44, sea), 12)
            + [P(-0.5, sea)] + curve(P(-0.5, sea), P(-0.62, 0.3), P(-0.66, 0.12), 10).dropFirst()
        let wale = Kit.ribbon(deck.enumerated().filter { $0.offset >= 2 && $0.offset <= 27 }.map { $0.element + P(0, 0.075) }, 0.05)
        return (deck, hull, wale)
    }

    private static func plate67Water(_ plate: inout Plate, _ sea: Double) {
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
    }

    private static func plate67Rigging(_ plate: inout Plate) {
        // The rigging under the sails: stays to the bowsprit and the stern, shrouds to the deck.
        let sprit = P(0.92, -0.02)
        plate.line([P(0.33, -0.66), sprit], medium)
        plate.line([P(0.0, -0.78), P(0.33, -0.3)], medium)
        plate.line([P(-0.36, -0.56), P(0.0, -0.36)], medium)
        plate.line([P(-0.36, -0.56), P(-0.66, 0.1)], medium)
        for m in plate67MastList {
            for d in [-0.15, -0.09, 0.09, 0.15] {
                plate.line([P(m.x, m.yards[0].y - 0.05), P(m.x + d, 0.2 + 0.1 * (m.x + d) * (m.x + d))], fine)
            }
        }
        Kit.mass(&plate, Kit.band(P(0.5, 0.17), sprit, 0.034))
    }

    private static func plate67Masts(_ plate: inout Plate) {
        for m in plate67MastList {
            Kit.mass(&plate, [P(m.x - 0.026, 0.22), P(m.x - 0.014, m.top), P(m.x + 0.014, m.top), P(m.x + 0.026, 0.22), P(m.x - 0.026, 0.22)])
            plate.fill(arc(P(m.x, m.top - 0.012), 0.02), .black)
            for (i, yard) in m.yards.enumerated() {
                limpSail(&plate, P(m.x, yard.y), half: yard.half, drop: yard.drop, seed: Int(m.x * 100) + i)
                Kit.mass(&plate, Kit.band(P(m.x - yard.half - 0.03, yard.y), P(m.x + yard.half + 0.03, yard.y), 0.03))
            }
        }
    }

    private static func plate67Wale(_ plate: inout Plate, _ deck: [P], _ hull: [P], _ wale: [P]) {
        Kit.mass(&plate, hull + [hull[0]])
        Kit.cut(&plate, wale, edge: medium)
        for k in 0..<10 {
            let i = 4 + 2 * k
            let c = deck[i] + P(0, 0.075)
            plate.fill(box(c - P(0.014, 0.014), c + P(0.014, 0.014)), .black)
        }
        plate.line(deck.enumerated().filter { $0.offset < 28 }.map { $0.element + P(0, 0.028) }, 0.02, .bone)
    }

    private static func plate67Boot(_ plate: inout Plate, _ sea: Double) {
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
    }

    private static func plate67Stern(_ plate: inout Plate, _ deck: [P], _ sea: Double) {
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
    }

    private static func plate67Pennant(_ plate: inout Plate) {
        // The pennant at the main truck, hanging limp, clear of the hub below.
        let truck = P(0.0, -0.87)
        let streamer = [truck + P(0, -0.02), P(0.1, -0.89), P(0.17, -0.85), P(0.2, -0.77), P(0.19, -0.72), P(0.175, -0.775),
                        P(0.14, -0.835), P(0.09, -0.86), truck + P(0, 0.02), truck + P(0, -0.02)]
        plate.fill(streamer, .second)
        plate.line(streamer, medium)
        plate.fill(arc(truck, 0.016), .black)
    }

    /// Problem 68, Interlude, pent, clocks 0+: a theatre's stage with its curtains drawn, heavy folds of ink and bone
    /// under a valance of three swags, the footlights along the apron and the dark of the pit below; the tassel hanging
    /// between the right-hand swags in the second ink, clear of every hub.
    static func plate68() -> Plate {
        var plate = Plate()
        let opening: Double = 0.74, top: Double = -0.84, stage: Double = 0.5, apron: Double = 0.7
        Kit.ground(&plate, angle: -0.6)

        plate68Pilasters(&plate, opening, top, apron)
        plate68Curtains(&plate, opening, top, stage)
        plate68Hem(&plate, opening, stage)
        plate68Valance(&plate, opening, top)
        plate68Tassels(&plate, top)
        plate68Boards(&plate, opening, stage, apron)
        plate68Pit(&plate, apron)
        callout(&plate, "A", from: P(-0.5, top + 0.2), to: P(-0.86, -0.55))
        callout(&plate, "B", from: P(-0.3, 0.1), to: P(-0.9, 0.2))
        callout(&plate, "C", from: P(0.2, apron - 0.04), to: P(0.6, 0.86))
        callout(&plate, "D", from: P(0.27, top + 0.42), to: P(0.42, -0.3))
        return plate
    }

    private static func plate68Pilasters(_ plate: inout Plate, _ opening: Double, _ top: Double, _ apron: Double) {
        // The proscenium's pilasters, fluted, either side of the opening, and its arch over the top.
        for side in [-1.0, 1.0] {
            let inner = side * opening, outer = side * (opening + 0.13)
            let pilaster = box(P(min(inner, outer), -1.0), P(max(inner, outer), apron))
            Kit.cut(&plate, pilaster, edge: heavy)
            for k in 0..<2 {
                let x = inner + side * (0.035 + 0.06 * Double(k))
                plate.line([P(x, -0.9), P(x, apron - 0.1)], 0.014)
                plate.lines(hatch([box(P(x + 0.008, -0.9), P(x + 0.024, apron - 0.1))], angle: 0, gap: 0.016), fine)
            }
            plate.lines(hatch([box(P(min(inner, outer), apron - 0.08), P(max(inner, outer), apron))], angle: 0.8, gap: 0.016), fine)
            plate.line([P(min(inner, outer), apron - 0.08), P(max(inner, outer), apron - 0.08)], medium)
        }
        Kit.solid(&plate, box(P(-opening, -1.0), P(opening, top)), angle: 0.8, gap: 0.03)
        Kit.mass(&plate, box(P(-opening, top - 0.03), P(opening, top)))
    }

    private static func plate68Curtains(_ plate: inout Plate, _ opening: Double, _ top: Double, _ stage: Double) {
        // The curtains, drawn to meet in the middle: bone cloth, deep folds of ink that sway and flare toward the hem.
        Kit.cut(&plate, box(P(-opening, top), P(opening, stage)))
        for side in [-1.0, 1.0] {
            for k in 0..<5 {
                let x0 = side * (0.08 + 0.14 * Double(k))
                let path = (0...24).map { i -> P in
                    let y = top + (stage - 0.02 - top) * Double(i) / 24, t = max(0, y + 0.1) / (stage + 0.1)
                    return P(x0 + 0.014 * sin(7 * y + Double(k)) + side * 0.05 * t * t * (1 - abs(x0) / opening), y)
                }
                let width: [Double] = (0...24).map { (i: Int) -> Double in 0.04 + 0.024 * Double(i) / 24 }
                let left: [P] = path.indices.map { (i: Int) -> P in path[i] - P(width[i] / 2, 0) }
                let right: [P] = path.indices.reversed().map { (i: Int) -> P in path[i] + P(width[i] / 2, 0) }
                let ring: [P] = left + right
                plate.fill(ring + [ring[0]], .black)
                // The light side of each fold, shaded toward its shadow.
                let lit: [P] = path.indices.reversed().map { (i: Int) -> P in path[i] + P(width[i] / 2 + 0.026, 0) }
                let shade: [P] = right.reversed() + lit
                plate.lines(hatch([shade + [shade[0]]], angle: 0.2, gap: 0.02), fine)
            }
        }
        plate.line([P(0, top), P(0, stage)], heavy)
    }

    private static func plate68Hem(_ plate: inout Plate, _ opening: Double, _ stage: Double) {
        // The hem, a fringed band of bone, the cloth pooling on the boards.
        let hem = curve(P(-opening, stage - 0.06), P(0, stage - 0.03), P(opening, stage - 0.06), 24)
        Kit.cut(&plate, Kit.ribbon(hem, 0.05), edge: medium)
        for i in stride(from: 1, to: 24, by: 1) { plate.line([hem[i] + P(0, 0.008), hem[i] + P(0, 0.025)], medium) }
    }

    private static func plate68Valance(_ plate: inout Plate, _ opening: Double, _ top: Double) {
        // The valance: three swags hung in festoons, each a sag of ink folds on bone, over the curtains' heads.
        let swags = [(-opening, -0.25), (-0.25, 0.25), (0.25, opening)]
        for (a, b) in swags {
            let m = (a + b) / 2
            let hang = curve(P(a, top + 0.24), P(m, top + 0.5), P(b, top + 0.24), 20)
            Kit.cut(&plate, [P(a, top)] + hang + [P(b, top), P(a, top)], edge: medium)
            for k in 0..<2 {
                let d = 0.07 + 0.13 * Double(k)
                let fold = curve(P(a + 0.02, top + 0.05 + 0.6 * d), P(m, top + 0.05 + 2.3 * d), P(b - 0.02, top + 0.05 + 0.6 * d), 24)
                Kit.mass(&plate, swell(fold, 0.008, 0.06))
            }
        }
    }

    private static func plate68Tassels(_ plate: inout Plate, _ top: Double) {
        // The tassels where the swags meet, one in the second ink.
        for x in [-0.25, 0.25] {
            let knot = P(x, top + 0.3)
            let ink: Ink = x > 0 ? .second : .black
            plate.line([P(x, top + 0.24), knot], heavy)
            plate.fill(arc(knot, 0.03), ink)
            plate.line(arc(knot, 0.03), medium)
            let skirt = [knot + P(-0.024, 0.02), knot + P(0.024, 0.02), knot + P(0.055, 0.17), knot + P(-0.055, 0.17), knot + P(-0.024, 0.02)]
            plate.fill(skirt, ink)
            for k in 0..<7 { plate.line([knot + P(-0.018 + 0.006 * Double(k), 0.03), knot + P(-0.045 + 0.015 * Double(k), 0.165)], fine) }
            plate.line([knot + P(-0.03, 0.045), knot + P(0.03, 0.045)], medium)
            plate.line(skirt, medium)
        }
    }

    private static func plate68Boards(_ plate: inout Plate, _ opening: Double, _ stage: Double, _ apron: Double) {
        // The stage's boards in perspective and the footlights along the apron.
        let boards = box(P(-opening, stage), P(opening, apron))
        Kit.cut(&plate, boards, edge: heavy)
        for k in -7...7 {
            plate.line([P(0.06 * Double(k), stage), P(0.1 * Double(k), apron)], fine)
        }
        for x in stride(from: -0.6, through: 0.61, by: 0.2) {
            let c = P(x, apron - 0.04)
            let hood = arc(c, 0.055, from: .pi, to: 2 * .pi) + [c + P(0.055, 0.03), c + P(-0.055, 0.03), c + P(-0.055, 0)]
            for k in 0..<4 {
                let a = -.pi / 2 + (Double(k) - 1.5) * 0.45
                plate.line([polar(c, 0.075, a), polar(c, 0.11, a)], medium)
            }
            Kit.mass(&plate, hood)
            plate.line(arc(c + P(0, 0.008), 0.024, from: .pi, to: 2 * .pi), medium, .bone)
        }
    }

    private static func plate68Pit(_ plate: inout Plate, _ apron: Double) {
        // The pit, dark below the stage's lip, its rail in bone.
        Kit.mass(&plate, box(P(-1.1, apron), P(1.1, 1.1)))
        plate.line([P(-1.1, apron + 0.07), P(1.1, apron + 0.07)], 0.02, .bone)
        for x in stride(from: -0.9, through: 0.9, by: 0.1) { plate.line([P(x, apron + 0.07), P(x, apron + 0.16)], 0.016, .bone) }
        plate.line([P(-1.1, apron + 0.16), P(1.1, apron + 0.16)], 0.016, .bone)
    }

    /// Problem 69, Siesta, hex, clocks 1+: a black cat curled asleep on a tufted cushion, its fur's lie and sheen cut in
    /// bone, its tail wrapped round to its chin, the window's louvred shutters closed on the afternoon above; the bell on
    /// its collar in the second ink, in the lane between the hubs at four and six.
    static func plate69() -> Plate {
        var plate = Plate()
        Kit.ground(&plate, angle: 0.6)
        plate69Shutters(&plate)
        plate69Cushion(&plate)
        // The cat, drawn about its head and set down where no rod's core is mostly its ink: its face in the lane between
        // the middle hub and the hubs at two and four, its bell clear of the hubs at four and six.
        var cat = Plate()
        let curl = P(-0.06, 0.15), h = P(0.33, 0.07)
        plate69Fur(&cat, curl)
        plate69Haunch(&cat, curl)
        plate69Tail(&cat)
        plate69Head(&cat, h)
        plate69Paw(&cat, h)
        let ring = plate69Collar(&cat, h)
        let seat = P(0.23, 0.23), scale = 0.86
        for mark in cat.marks {
            plate.marks.append(Mark(points: mark.points.map { ($0 - h) * scale + seat }, width: mark.width == 0 ? 0 : max(fine, mark.width * 0.9), ink: mark.ink))
        }
        let bell = (ring - h) * scale + seat

        callout(&plate, "A", from: P(-0.3, 0.12), to: P(-0.72, -0.1))
        callout(&plate, "B", from: P(-0.36, 0.5), to: P(-0.84, 0.36))
        callout(&plate, "C", from: P(0.5, 0.78), to: P(0.66, 0.88))
        callout(&plate, "D", from: bell + P(0.03, 0.02), to: P(0.86, 0.14))
        return plate
    }

    private static func plate69Shutters(_ plate: inout Plate) {
        // The shutters closed on the afternoon above: the window's frame, two louvred leaves and the light between them.
        Kit.mass(&plate, box(P(-0.44, -1.0), P(0.44, -0.3)))
        for side in [-1.0, 1.0] {
            let x0 = side < 0 ? -0.4 : 0.035, x1 = side < 0 ? -0.035 : 0.4
            Kit.cut(&plate, box(P(x0, -1.0), P(x1, -0.3)), edge: heavy)
            for k in 0..<9 {
                let y = -0.97 + 0.074 * Double(k)
                plate.fill(box(P(x0 + 0.035, y + 0.042), P(x1 - 0.035, y + 0.071)), .black)
                plate.line([P(x0 + 0.035, y + 0.03), P(x1 - 0.035, y + 0.03)], fine)
            }
            plate.line(box(P(x0 + 0.035, -0.97), P(x1 - 0.035, -0.33)), medium)
        }
        Kit.cut(&plate, box(P(-0.035, -1.0), P(0.035, -0.3)), edge: medium)
        Kit.cut(&plate, box(P(-0.5, -0.3), P(0.5, -0.25)), edge: heavy)
    }

    private static func plate69Cushion(_ plate: inout Plate) {
        // The cushion: a tufted top in bone, its front a bold ticking of ink and bone, piped at the seams.
        let topFace = ellipse(P(0, 0.38), 0.96, 0.32)
        let front = ellipse(P(0, 0.38), 0.96, 0.32, from: 0, to: .pi) + ellipse(P(0, 0.6), 0.96, 0.32, from: .pi, to: 0)
        plate.fill(front + [front[0]])
        for k in -5...5 {
            let x = 0.165 * Double(k) + 0.08
            guard abs(x) < 0.92 else { continue }
            let y0 = 0.38 + 0.32 * sqrt(max(0, 1 - x * x / 0.9216)), y1 = y0 + 0.22
            plate.fill(box(P(x - 0.025, y0), P(x + 0.025, y1)), .black)
            plate.line([P(x + 0.082, y0), P(x + 0.082, y1)], medium)
        }
        plate.line(front + [front[0]], heavy)
        Kit.cut(&plate, topFace, edge: 0.016)
        plate.lines(hatch([topFace], angle: -0.3, gap: Kit.groundGap), Kit.groundWidth)
        for b in [P(-0.72, 0.3), P(0.64, 0.32), P(0.6, 0.56), P(-0.56, 0.58), P(-0.25, 0.62), P(0.25, 0.62)] {
            for a in stride(from: 0.0, to: 2 * .pi, by: .pi / 2) { plate.line([polar(b, 0.02, a + 0.4), polar(b, 0.09, a + 0.4)], medium) }
            plate.fill(arc(b, 0.024), .black)
        }
    }

    private static func plate69Fur(_ cat: inout Plate, _ curl: P) {
        Kit.mass(&cat, ellipse(curl, 0.45, 0.21, turned: -0.06))
        // The fur's lie in bone along the back, the sheen on it, the hind leg drawn up and the foreleg folded.
        for k in 0..<3 {
            let f = 0.88 - 0.13 * Double(k)
            cat.fill(swell(ellipse(curl, 0.45 * f, 0.21 * f, from: .pi * (0.95 + 0.06 * Double(k)), to: .pi * (1.62 - 0.05 * Double(k)), turned: -0.06), 0.004, 0.024))
        }
        cat.fill(swell(ellipse(curl, 0.42, 0.19, from: .pi * 1.05, to: .pi * 1.78, turned: -0.06), 0.006, 0.04))
    }

    private static func plate69Haunch(_ cat: inout Plate, _ curl: P) {
        for k in 0..<4 {
            let f = 0.5 + 0.13 * Double(k)
            cat.fill(swell(ellipse(curl, 0.45 * f, 0.21 * f, from: .pi * (0.22 + 0.04 * Double(k)), to: .pi * (0.62 + 0.05 * Double(k % 2)), turned: -0.06), 0.003, 0.03))
        }
        for k in 0..<3 {
            let f = 0.62 + 0.14 * Double(k)
            cat.fill(swell(ellipse(curl, 0.45 * f, 0.21 * f, from: .pi * (0.8 + 0.03 * Double(k)), to: .pi * (1.02 + 0.02 * Double(k)), turned: -0.06), 0.003, 0.026))
        }
        for k in 0..<3 {
            let f = 0.42 + 0.18 * Double(k)
            cat.fill(swell(ellipse(curl, 0.45 * f, 0.21 * f, from: .pi * (1.62 + 0.03 * Double(k)), to: .pi * (1.98 + 0.03 * Double(k)), turned: -0.06), 0.003, 0.028))
        }
        cat.fill(swell(ellipse(P(-0.24, 0.2), 0.15, 0.1, from: -.pi * 0.6, to: .pi * 0.75), 0.004, 0.03))
        cat.fill(swell(curve(P(0.02, 0.1), P(0.0, 0.26), P(0.12, 0.33), 10), 0.004, 0.024))
        cat.fill(swell(curve(P(-0.04, 0.24), P(0.06, 0.34), P(0.14, 0.36), 10), 0.003, 0.016))
    }

    private static func plate69Tail(_ cat: inout Plate) {
        // The tail wrapped round the front to the chin.
        let tailPath = curve(P(-0.44, 0.16), P(-0.42, 0.42), P(-0.05, 0.38), 16) + curve(P(-0.05, 0.38), P(0.16, 0.36), P(0.22, 0.29), 8).dropFirst()
        Kit.mass(&cat, swell(tailPath, 0.04, 0.07))
        cat.fill(swell(curve(P(-0.41, 0.2), P(-0.4, 0.4), P(-0.05, 0.36), 16), 0.003, 0.03))
        cat.fill(swell(curve(P(-0.02, 0.365), P(0.14, 0.35), P(0.2, 0.3), 8), 0.003, 0.022))
    }

    private static func plate69Head(_ cat: inout Plate, _ h: P) {
        // The head, resting on the tail.
        let head = [h + P(-0.16, 0.02), h + P(-0.14, -0.08), h + P(-0.12, -0.2), h + P(-0.04, -0.12), h + P(0.04, -0.12),
                    h + P(0.13, -0.19), h + P(0.13, -0.06), h + P(0.16, 0.03), h + P(0.12, 0.12), h + P(0.03, 0.16),
                    h + P(-0.08, 0.15), h + P(-0.15, 0.1), h + P(-0.16, 0.02)]
        Kit.mass(&cat, head)
        Kit.solid(&cat, [h + P(-0.115, -0.15), h + P(-0.07, -0.1), h + P(-0.115, -0.085), h + P(-0.115, -0.15)], angle: 0.7, gap: 0.012)
        Kit.solid(&cat, [h + P(0.11, -0.14), h + P(0.11, -0.07), h + P(0.06, -0.1), h + P(0.11, -0.14)], angle: 0.7, gap: 0.012)
        cat.line(curve(h + P(-0.1, -0.01), h + P(-0.06, 0.03), h + P(-0.02, -0.005), 8), 0.018, .bone)
        cat.line(curve(h + P(0.02, -0.005), h + P(0.06, 0.03), h + P(0.1, -0.01), 8), 0.018, .bone)
        cat.fill([h + P(-0.02, 0.06), h + P(0.02, 0.06), h + P(0, 0.085), h + P(-0.02, 0.06)])
        cat.line([h + P(0, 0.085), h + P(0, 0.105)], 0.008, .bone)
        for k in 0..<3 {
            let y = 0.08 + 0.022 * Double(k)
            cat.line([h + P(0.05, y), h + P(0.3, y - 0.06 + 0.05 * Double(k))], medium)
            cat.line([h + P(0.05, y), h + P(0.15, y - 0.025 + 0.02 * Double(k))], 0.008, .bone)
            cat.line([h + P(-0.05, y), h + P(-0.15, y - 0.025 + 0.02 * Double(k))], 0.008, .bone)
        }
    }

    private static func plate69Paw(_ cat: inout Plate, _ h: P) {
        let paw = ellipse(h + P(0.02, 0.2), 0.1, 0.045)
        Kit.mass(&cat, paw)
        for k in 0..<3 { cat.line([h + P(0.06 + 0.025 * Double(k), 0.185), h + P(0.065 + 0.025 * Double(k), 0.225)], 0.01, .bone) }
    }

    private static func plate69Collar(_ cat: inout Plate, _ h: P) -> P {
        // The collar under the chin, and its bell.
        let collar = curve(h + P(-0.15, 0.06), h + P(-0.1, 0.17), h + P(-0.01, 0.15), 12)
        Kit.cut(&cat, Kit.ribbon(collar, 0.036), edge: medium)
        for i in stride(from: 2, to: 12, by: 3) { cat.fill(arc(collar[i], 0.007), .black) }
        let ring = h + P(-0.04, 0.205)
        cat.line([collar[9], ring], medium)
        cat.fill(arc(ring, 0.045), .second)
        cat.line(arc(ring, 0.045), medium)
        cat.line([ring + P(-0.043, -0.004), ring + P(0.043, -0.004)], fine)
        cat.line([ring, ring + P(0, 0.04)], medium)
        cat.fill(arc(ring + P(0, 0.02), 0.01), .black)
        return ring
    }

    private static func plate70Shore(_ x: Double) -> Double { 0.0 - 0.1 * x }

    /// Problem 70, Respite, pent, clocks 0+: a clinker-built rowing boat drawn up on a shingle beach, its oars shipped
    /// and crossed over the thwarts, its painter run up the beach to a stake; the mooring ring on the stake in the second
    /// ink, in the gap between the hubs at two and five.
    static func plate70() -> Plate {
        var plate = Plate()
        let horizon: Double = -0.34
        plate70Sky(&plate, horizon)
        plate70Clouds(&plate)
        plate70Sea(&plate, horizon)
        plate70Shingle(&plate)
        let (sheer, keel) = plate70Boat(&plate)
        plate70Strakes(&plate, sheer, keel)
        plate70Oars(&plate)
        let ring = plate70Stake(&plate)
        callout(&plate, "A", from: P(-0.2, 0.25), to: P(-0.64, 0.66))
        callout(&plate, "B", from: P(-0.62, -0.18), to: P(-0.78, -0.4))
        callout(&plate, "C", from: P(0.3, 0.5), to: P(0.1, 0.82))
        callout(&plate, "D", from: ring + P(0.045, 0.02), to: P(0.86, 0.3))
        return plate
    }

    private static func plate70Sky(_ plate: inout Plate, _ horizon: Double) {
        let R = 1.06, a0 = asin(horizon / R)
        let sky = arc(Kit.origin, R, from: .pi - a0, to: 2 * .pi + a0)
        plate.lines(hatch([sky + [sky[0]]], angle: 0, gap: Kit.groundGap), Kit.groundWidth)
    }

    private static func plate70Clouds(_ plate: inout Plate) {
        // Long clouds low over the sea.
        for (y, x0, x1) in [(-0.72, -0.62, -0.18), (-0.62, 0.12, 0.7), (-0.5, -0.86, -0.42), (-0.46, 0.4, 0.86)] {
            Kit.mass(&plate, swell(curve(P(x0, y), P((x0 + x1) / 2, y - 0.03), P(x1, y), 12), 0.01, 0.05))
        }
    }

    private static func plate70Sea(_ plate: inout Plate, _ horizon: Double) {
        // The sea, in long bands that crowd toward the shore, and its last wave's foam along the shingle.
        let sea = [P(-1.1, horizon), P(1.1, horizon), P(1.1, plate70Shore(1.1)), P(-1.1, plate70Shore(-1.1)), P(-1.1, horizon)]
        plate.fill(sea)
        for k in 0..<7 {
            let y = horizon + 0.035 + 0.055 * Double(k) * (1 + 0.15 * Double(k))
            for seg in 0..<3 {
                let x0 = -1.0 + 0.7 * Double(seg) + 0.25 * rnd(70, 10 * k + seg), x1 = x0 + 0.3 + 0.25 * rnd(71, 10 * k + seg)
                guard y + 0.02 < plate70Shore(x1) - 0.02 else { continue }
                Kit.mass(&plate, swell([P(x0, y), P((x0 + x1) / 2, y), P(x1, y)], 0.006, 0.02 + 0.006 * Double(k)))
            }
        }
        plate.line([P(-1.1, plate70Shore(-1.1)), P(1.1, plate70Shore(1.1))], heavy)
        plate.lines(dashed(curve(P(-1.1, plate70Shore(-1.1) - 0.035), P(0, plate70Shore(0) - 0.05), P(1.1, plate70Shore(1.1) - 0.035), 30), on: 0.07, off: 0.03), medium)
    }

    private static func plate70Shingle(_ plate: inout Plate) {
        // The shingle, ruled, with its pebbles laid in ink.
        let beach = [P(-1.1, plate70Shore(-1.1)), P(1.1, plate70Shore(1.1)), P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, plate70Shore(-1.1))]
        plate.lines(hatch([beach], angle: 0.45, gap: Kit.groundGap), Kit.groundWidth)
        for k in 0..<60 {
            let x = -1.0 + 2.0 * rnd(72, k), y = plate70Shore(x) + 0.06 + (1.0 - plate70Shore(x)) * rnd(73, k)
            guard x * x + y * y < 1.0 else { continue }
            let r = 0.022 + 0.026 * rnd(74, k)
            Kit.mass(&plate, ellipse(P(x, y), r, 0.6 * r, turned: rnd(75, k) - 0.5))
            plate.line(ellipse(P(x, y) + P(-0.2 * r, -0.15 * r), 0.45 * r, 0.22 * r, from: .pi, to: 1.7 * .pi, turned: rnd(75, k) - 0.5), fine, .bone)
        }
    }

    private static func plate70Boat(_ plate: inout Plate) -> ([P], [P]) {
        // The boat, lying a little canted on the shingle, bow up the beach.
        let sheer = curve(P(-0.62, -0.0), P(-0.05, 0.12), P(0.5, -0.1), 30)
        let far = curve(P(-0.58, -0.05), P(-0.05, 0.03), P(0.46, -0.14), 30)
        let keel = curve(P(0.36, 0.2), P(-0.08, 0.3), P(-0.52, 0.19), 24)
        let stem: [P] = Array(curve(P(0.54, -0.13), P(0.5, 0.12), P(0.36, 0.2), 10).dropFirst())
        let hull: [P] = sheer + [P(0.54, -0.13)] + stem + Array(keel.dropFirst()) + [P(-0.64, -0.01), sheer[0]]
        // Its shadow on the stones.
        Kit.mass(&plate, ellipse(P(-0.08, 0.29), 0.46, 0.03, turned: -0.02))
        // Inside, seen over the near gunwale: the far side's planking, the thwarts.
        let inside = sheer + far.reversed() + [sheer[0]]
        Kit.cut(&plate, inside)
        plate.lines(hatch([inside], angle: 1.2, gap: 0.03), fine)
        for x in [-0.28, 0.12] {
            let t = (x + 0.62) / 1.12
            let top = far[Int(t * 30)], low = sheer[Int(t * 30)]
            Kit.mass(&plate, [top + P(-0.035, 0), top + P(0.035, 0), low + P(0.035, 0), low + P(-0.035, 0), top + P(-0.035, 0)])
        }
        Kit.mass(&plate, hull)
        return (sheer, keel)
    }

    private static func plate70Strakes(_ plate: inout Plate, _ sheer: [P], _ keel: [P]) {
        // The clinker strakes in bone, each lapping the one below.
        for k in 1...4 {
            let f = Double(k) / 5
            let strake = sheer.indices.map { i -> P in
                let t = Double(i) / 30, low = keel[min(24, Int((1 - t) * 24))]
                return sheer[i] + (low - sheer[i]) * f
            }
            plate.line(Array(strake[1..<29]), 0.016, .bone)
        }
        plate.line(sheer, 0.02, .bone)
        Kit.mass(&plate, Kit.ribbon(sheer.map { $0 + P(0, -0.012) }, 0.024))
    }

    private static func plate70Oars(_ plate: inout Plate) {
        // The rowlocks, and the oars shipped and crossed over the thwarts.
        for x in [-0.2, 0.2] { plate.line([P(x, 0.07 - 0.08 * x - 0.06), P(x, 0.07 - 0.08 * x - 0.02)], 0.018) }
        for (a, b) in [(P(-0.78, -0.22), P(0.62, 0.08)), (P(-0.74, 0.08), P(0.6, -0.22))] {
            let d = simd_normalize(b - a), n = P(-d.y, d.x)
            let neck = a + d * 0.26
            let blade = [a + n * 0.012, a + n * 0.045 + d * 0.03, neck + n * 0.038, neck + n * 0.014, neck - n * 0.014, neck - n * 0.038,
                         a - n * 0.045 + d * 0.03, a - n * 0.012, a + n * 0.012]
            let loom = Kit.band(neck, b - d * 0.06, 0.03)
            Kit.cut(&plate, loom, edge: medium)
            Kit.cut(&plate, blade, edge: heavy)
            plate.line([a + d * 0.03, neck - d * 0.01], 0.014)
            Kit.cut(&plate, Kit.band(b - d * 0.07, b, 0.024), edge: medium)
        }
    }

    private static func plate70Stake(_ plate: inout Plate) -> P {
        // The stake up the beach, its ring, and the painter from the stem.
        let stake = P(0.66, 0.1)
        Kit.mass(&plate, [stake + P(-0.03, -0.02), stake + P(0.03, -0.035), stake + P(0.035, 0.27), stake + P(-0.025, 0.28), stake + P(-0.03, -0.02)])
        plate.lines(hatch([[stake + P(0.0, -0.02), stake + P(0.03, -0.035), stake + P(0.035, 0.27), stake + P(0.005, 0.275), stake + P(0.0, -0.02)]], angle: 0.4, gap: 0.012), fine, .bone)
        let ring = stake + P(-0.012, 0.075)
        plate.line(arc(ring, 0.05), 0.02, .second)
        plate.line(arc(ring, 0.06), fine)
        plate.line(arc(ring, 0.04), fine)
        plate.line(curve(P(0.46, -0.08), P(0.55, 0.12), ring + P(-0.035, 0.035), 14), 0.012)
        plate.line(curve(ring + P(-0.035, 0.035), ring + P(-0.06, 0.1), ring + P(-0.05, 0.15), 6), 0.012)
        return ring
    }

    private static let plate71Mouth: P = P(-0.2, -0.38), plate71Rx: Double = 0.44, plate71Ry: Double = 0.3, plate71Tilt: Double = -0.32
    private static let plate71Throat: P = P(0.38, 0.12)

    private static func plate71Rim(_ a: Double) -> P {
        let x: Double = plate71Rx * cos(a) * cos(plate71Tilt) - plate71Ry * sin(a) * sin(plate71Tilt)
        let y: Double = plate71Rx * cos(a) * sin(plate71Tilt) + plate71Ry * sin(a) * cos(plate71Tilt)
        return plate71Mouth + P(x, y)
    }

    /// Problem 71, Intermission, hex, clocks 1+: a gramophone on its cabinet, its morning-glory horn flaring in panels
    /// of ink and bone, the tone arm lifted off the record, the winding crank at its side; the record's label in the
    /// second ink, centred in the lane between the middle hub and the hubs at six and eight.
    static func plate71() -> Plate {
        var plate = Plate()
        Kit.ground(&plate, angle: -0.5)
        plate71Floor(&plate)
        let boss = plate71Cabinet(&plate)
        plate71Turntable(&plate)
        plate71Bell(&plate)
        plate71Gores(&plate)
        plate71Arm(&plate)
        callout(&plate, "A", from: P(-0.44, -0.52), to: P(-0.74, -0.62))
        callout(&plate, "B", from: P(0.2, 0.04), to: P(0.74, -0.04))
        callout(&plate, "C", from: P(-0.36, 0.3), to: P(-0.82, 0.3))
        callout(&plate, "D", from: boss + P(0.19, 0.12), to: P(0.72, 0.5))
        return plate
    }

    private static func plate71Floor(_ plate: inout Plate) {
        // The floor.
        plate.fill([P(-1.1, 0.84), P(1.1, 0.84), P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.84)])
        plate.lines(hatch([[P(-1.1, 0.84), P(1.1, 0.84), P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.84)]], angle: 0, gap: 0.04), medium)
    }

    private static func plate71Cabinet(_ plate: inout Plate) -> P {
        // The cabinet: its top in perspective, its front panelled, on short feet.
        let top = [P(-0.62, 0.36), P(-0.42, 0.22), P(0.5, 0.22), P(0.3, 0.36), P(-0.62, 0.36)]
        let front = box(P(-0.62, 0.36), P(0.3, 0.8))
        let side = [P(0.3, 0.36), P(0.5, 0.22), P(0.5, 0.66), P(0.3, 0.8), P(0.3, 0.36)]
        Kit.solid(&plate, side, angle: 1.2, gap: 0.03)
        Kit.cut(&plate, front, edge: heavy)
        plate.line([P(-0.62, 0.4), P(0.3, 0.4)], heavy)
        let panel = box(P(-0.54, 0.47), P(0.22, 0.73))
        Kit.mass(&plate, panel)
        Kit.cut(&plate, box(P(-0.49, 0.52), P(0.17, 0.68)), edge: medium)
        plate.lines(hatch([box(P(-0.49, 0.52), P(0.17, 0.68))], angle: 0.9, gap: 0.05), fine)
        for x in [-0.56, 0.24] { Kit.mass(&plate, [P(x, 0.8), P(x + 0.06, 0.8), P(x + 0.05, 0.86), P(x + 0.01, 0.86), P(x, 0.8)]) }
        Kit.cut(&plate, top, edge: heavy)
        // The crank on the cabinet's side.
        let boss = P(0.41, 0.48)
        plate.fill(arc(boss, 0.028), .black)
        Kit.mass(&plate, Kit.band(boss, boss + P(0.14, 0.12), 0.026))
        Kit.mass(&plate, Kit.band(boss + P(0.14, 0.12), boss + P(0.2, 0.12), 0.034))
        return boss
    }

    private static func plate71Turntable(_ plate: inout Plate) {
        // The turntable and the record, centred in a lane so its grooves are no rod's rings.
        let disc = P(-0.15, 0.29)
        Kit.mass(&plate, ellipse(disc + P(0, 0.012), 0.36, 0.085))
        for k in 0..<4 {
            plate.line(ellipse(disc, 0.33 - 0.055 * Double(k), 0.075 - 0.0125 * Double(k)), 0.008, .bone)
        }
        plate.fill(ellipse(disc, 0.1, 0.026), .second)
        plate.line(ellipse(disc, 0.1, 0.026), fine)
        plate.fill(ellipse(disc, 0.012, 0.005), .black)
    }

    private static func plate71Bell(_ plate: inout Plate) {
        // The horn: a flared bell of panels, ink and bone by turns, from its elbow behind the record to its mouth.
        let bellOut: [P] = (0...40).map { (i: Int) -> P in plate71Rim(-0.25 + 1.95 * Double(i) / 40) }
        let neckA: [P] = curve(plate71Rim(1.7), P(0.08, 0.02), plate71Throat + P(-0.025, 0.025), 16)
        let neckB: [P] = curve(plate71Throat + P(0.025, -0.025), P(0.24, -0.14), plate71Rim(-0.25), 16)
        let body: [P] = bellOut + neckA + neckB + [bellOut[0]]
        Kit.mass(&plate, body)
        for k in 0..<7 {
            let t = 0.12 + 0.13 * Double(k)
            let a = plate71Rim(-0.25 + 1.95 * t)
            plate.fill(swell(curve(a, (a + plate71Throat) / 2 + P(0.02, 0.03), plate71Throat, 14), 0.004, 0.04))
        }
    }

    private static func plate71Gores(_ plate: inout Plate) {
        // The pipe down to the arm's elbow.
        Kit.mass(&plate, Kit.band(plate71Throat, P(0.36, 0.25), 0.05))
        let mouthRing = ellipse(plate71Mouth, plate71Rx, plate71Ry, turned: plate71Tilt)
        plate.fill(mouthRing, .black)
        let well = plate71Mouth + P(0.13, 0.07)
        for k in 0..<7 {
            let a0 = 2 * .pi * Double(k) / 7, a1 = a0 + 2 * .pi / 7 * 0.7
            let edge: [P] = (0...10).map { (i: Int) -> P in plate71Rim(a0 + (a1 - a0) * Double(i) / 10) }
            let gore: [P] = [well] + edge + [well]
            plate.fill(gore)
        }
        plate.fill(ellipse(well, 0.05, 0.035, turned: plate71Tilt), .black)
        plate.line(mouthRing, 0.03)
        plate.line(ellipse(plate71Mouth, plate71Rx - 0.025, plate71Ry - 0.022, turned: plate71Tilt), 0.012, .bone)
    }

    private static func plate71Arm(_ plate: inout Plate) {
        // The tone arm from its pillar, lifted clear of the record, the soundbox at its end.
        let pillar = P(0.32, 0.27)
        Kit.mass(&plate, box(pillar + P(-0.03, -0.02), pillar + P(0.03, 0.06)))
        let elbow = pillar + P(-0.02, -0.07), head = P(-0.04, 0.1)
        Kit.mass(&plate, swell([pillar + P(0, -0.02), elbow, (elbow + head) / 2 + P(0, -0.04), head], 0.04, 0.045))
        let box1 = head + P(-0.02, 0.03)
        Kit.mass(&plate, ellipse(box1, 0.06, 0.055))
        Kit.cut(&plate, ellipse(box1, 0.038, 0.034), edge: medium)
        plate.lines(hatch([ellipse(box1, 0.038, 0.034)], angle: 0.7, gap: 0.012), fine)
        plate.line([box1 + P(0, 0.055), box1 + P(-0.01, 0.1)], 0.012)
        // The gap under the needle, the intermission.
        plate.lines(dashed([box1 + P(-0.01, 0.11), box1 + P(-0.012, 0.16)], on: 0.012, off: 0.01), fine)
    }

    /// Problem 72, Hiatus, hex, clocks 1+: a stone bridge across a gorge, its first arch whole, its second fallen
    /// between the springers so the road stops short over the drop, stones still tumbling into the river below; the
    /// lamp on its post at the break in the second ink, in the lane between the middle hub and the hubs at twelve and two.
    static func plate72() -> Plate {
        var plate = Plate()
        Kit.ground(&plate, angle: -0.35)
        let road: Double = 0.0, spring: Double = 0.5

        plate72River(&plate)
        plate72Walls(&plate)
        plate72Arch(&plate, road, spring)
        plate72Fallen(&plate, road, spring)
        plate72Parapet(&plate, road)
        let lamp = plate72Lamp(&plate, road)
        callout(&plate, "A", from: P(-0.28, 0.25), to: P(-0.7, -0.5))
        callout(&plate, "B", from: P(0.17, 0.6), to: P(0.0, 0.92))
        callout(&plate, "C", from: P(0.56, 0.42), to: P(0.86, 0.48))
        callout(&plate, "D", from: lamp + P(0.03, -0.01), to: P(0.5, -0.62))
        return plate
    }

    private static func plate72River(_ plate: inout Plate) {
        // The river at the gorge's foot.
        let river = [P(-1.1, 0.84), P(1.1, 0.8), P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.84)]
        Kit.mass(&plate, river)
        for k in 0..<4 {
            let y = 0.87 + 0.045 * Double(k)
            plate.lines(dashed([P(-0.9 + 0.1 * Double(k % 2), y), P(0.9, y - 0.02)], on: 0.12, off: 0.07), 0.012, .bone)
        }
    }

    private static func plate72Walls(_ plate: inout Plate) {
        // The gorge's walls: rock in ink, split by bone faults and bedded in strata.
        let left = [P(-1.1, -0.06), P(-0.7, -0.04), P(-0.64, 0.12), P(-0.68, 0.3), P(-0.58, 0.48), P(-0.62, 0.66), P(-0.5, 0.86),
                    P(-1.1, 0.88), P(-1.1, -0.06)]
        let right = [P(1.1, -0.1), P(0.78, -0.08), P(0.74, 0.1), P(0.8, 0.28), P(0.7, 0.46), P(0.74, 0.62), P(0.6, 0.84),
                     P(1.1, 0.82), P(1.1, -0.1)]
        for (k, rock) in [left, right].enumerated() {
            Kit.mass(&plate, rock)
            let side = k == 0 ? -1.0 : 1.0
            for j in 0..<6 {
                let y = 0.02 + 0.14 * Double(j)
                let inner = side < 0 ? -0.66 + 0.04 * sin(Double(j)) : 0.74 + 0.04 * cos(Double(j))
                plate.fill(swell(curve(P(inner + side * 0.04, y), P(inner + side * 0.25, y + 0.05 * side), P(side * 1.05, y + 0.02), 14), 0.004, 0.028))
            }
            for j in 0..<5 {
                let y = 0.06 + 0.14 * Double(j), x = side * (0.78 + 0.06 * Double(j % 3)) + (side < 0 ? 0.08 : 0.0)
                plate.fill(swell([P(x, y), P(x + side * 0.02, y + 0.05), P(x - side * 0.01, y + 0.1)], 0.003, 0.018))
            }
        }
    }

    private static func plate72Arch(_ plate: inout Plate, _ road: Double, _ spring: Double) {
        // The whole arch: its opening in shadow, ruled, its ring of voussoirs, the spandrel's coursed masonry above.
        let c1 = P(-0.28, spring), r1 = 0.36
        let opening = arc(c1, r1, from: .pi, to: 2 * .pi) + [P(c1.x + r1, 0.86), P(c1.x - r1, 0.86), P(c1.x - r1, spring)]
        let pier = box(P(0.08, spring - 0.02), P(0.26, 0.86))
        let spanL = [P(-0.7, road), P(0.34, road), P(0.34, spring - 0.02), P(0.08, spring - 0.02)] + arc(c1, r1, from: 0, to: -.pi).dropFirst()
            + [P(-0.7, spring), P(-0.7, road)]
        Kit.cut(&plate, spanL, edge: heavy)
        coursed(&plate, spanL, from: road, seed: 72)
        plate.fill(opening)
        plate.lines(hatch([opening], angle: 0, gap: 0.04), 0.014)
        plate.line(opening, heavy)
        voussoirs(&plate, c1, r1, from: .pi, to: 2 * .pi)
        Kit.cut(&plate, pier, edge: heavy)
        coursed(&plate, pier, from: spring, seed: 73)
    }

    private static func plate72Fallen(_ plate: inout Plate, _ road: Double, _ spring: Double) {
        // The fallen arch's springers, one off the pier and one off the far rock, the road ragged where it broke.
        let c2 = P(0.53, spring), r2 = 0.27
        let stubL = [P(0.26, spring - 0.02), P(0.26, road), P(0.36, road), P(0.4, 0.06), P(0.34, 0.14), P(0.33, 0.22)]
            + arc(c2, r2, from: .pi + 0.85, to: .pi).dropFirst() + [P(0.26, spring - 0.02)]
        Kit.cut(&plate, stubL, edge: heavy)
        coursed(&plate, stubL, from: road, seed: 74)
        voussoirs(&plate, c2, r2, from: .pi, to: .pi + 0.85)
        let stubR = [P(0.78, -0.02), P(0.68, -0.02), P(0.66, 0.05), P(0.7, 0.12)] + arc(c2, r2, from: 2 * .pi - 0.7, to: 2 * .pi).dropFirst()
            + [P(0.8, spring), P(0.78, -0.02)]
        Kit.cut(&plate, stubR, edge: heavy)
        coursed(&plate, stubR, from: road, seed: 75)
        voussoirs(&plate, c2, r2, from: 2 * .pi - 0.7, to: 2 * .pi)
    }

    private static func plate72Parapet(_ plate: inout Plate, _ road: Double) {
        // The parapet and its coping along what is left of the road.
        for (a, b) in [(-0.7, 0.36), (0.68, 0.8)] {
            Kit.mass(&plate, box(P(a, road - 0.1), P(b, road - 0.075)))
            let wall = box(P(a + 0.01, road - 0.075), P(b - 0.01, road))
            Kit.cut(&plate, wall, edge: medium)
            for x in stride(from: a + 0.07, to: b - 0.03, by: 0.09) { plate.line([P(x, road - 0.075), P(x, road)], 0.012) }
        }
        // Stones still falling into the gorge.
        for (k, c) in [P(0.5, 0.2), P(0.56, 0.42), P(0.46, 0.6), P(0.58, 0.74)].enumerated() {
            let block = turned(box(P(-0.035, -0.025), P(0.035, 0.025)), by: 0.5 + 0.7 * Double(k)).map { $0 + c }
            Kit.mass(&plate, block)
            plate.line([c + P(-0.06, -0.06), c + P(-0.04, -0.1)], medium)
        }
    }

    private static func plate72Lamp(_ plate: inout Plate, _ road: Double) -> P {
        // The lamp at the break, its post on the parapet, its lantern in the second ink.
        let post = P(0.25, road - 0.1)
        Kit.mass(&plate, Kit.band(post, post + P(0, -0.2), 0.03))
        Kit.mass(&plate, Kit.band(post + P(0, -0.2), post + P(-0.07, -0.22), 0.022))
        let lamp = post + P(-0.09, -0.24)
        let lantern = [lamp + P(-0.035, -0.03), lamp + P(0.035, -0.03), lamp + P(0.028, 0.06), lamp + P(-0.028, 0.06), lamp + P(-0.035, -0.03)]
        plate.fill(lantern, .second)
        plate.line(lantern, medium)
        plate.line([lamp + P(0, -0.03), lamp + P(0, 0.06)], fine)
        Kit.mass(&plate, [lamp + P(-0.05, -0.03), lamp + P(0, -0.075), lamp + P(0.05, -0.03), lamp + P(-0.05, -0.03)])
        Kit.mass(&plate, box(lamp + P(-0.03, 0.06), lamp + P(0.03, 0.08)))
        for k in 0..<5 {
            let a = -.pi * (0.1 + 0.2 * Double(k))
            plate.line([polar(lamp + P(0, 0.015), 0.085, a + .pi), polar(lamp + P(0, 0.015), 0.12, a + .pi)], medium)
        }
        return lamp
    }

    /// Ashlar laid in courses inside an outline: bone blocks, a joint in ink between each, every third block shaded.
    private static func coursed(_ plate: inout Plate, _ ring: [P], from top: Double, seed: Int) {
        let xs = ring.map(\.x), ys = ring.map(\.y)
        guard let x0 = xs.min(), let x1 = xs.max(), let y1 = ys.max() else { return }
        var row = 0
        for y in stride(from: top + 0.07, to: y1, by: 0.07) {
            plate.lines(clip([P(x0, y), P(x1, y)], ring), 0.014)
            var x = x0 + (row % 2 == 0 ? 0 : 0.06)
            var k = 0
            while x < x1 {
                for piece in clip([P(x, y - 0.07), P(x, y)], ring) { plate.line(piece, 0.014) }
                if rnd(seed, 100 * row + k) < 0.3 {
                    let cell = box(P(x + 0.012, y - 0.06), P(x + 0.108, y - 0.01))
                    if cell.allSatisfy({ inside($0, ring) }) { plate.lines(hatch([cell], angle: 0.8, gap: 0.016), fine) }
                }
                x += 0.12
                k += 1
            }
            row += 1
        }
    }

    /// The pieces of a segment inside a ring, by the even-odd rule.
    private static func clip(_ seg: [P], _ ring: [P]) -> [[P]] {
        let a = seg[0], b = seg[1], d = b - a
        var ts: [Double] = []
        for i in 0..<(ring.count - 1) {
            let p = ring[i], q = ring[i + 1], e = q - p
            let den = d.x * e.y - d.y * e.x
            guard abs(den) > 1e-12 else { continue }
            let t = ((p.x - a.x) * e.y - (p.y - a.y) * e.x) / den, u = ((p.x - a.x) * d.y - (p.y - a.y) * d.x) / den
            if t >= 0 && t <= 1 && u >= 0 && u < 1 { ts.append(t) }
        }
        ts = ([0.0, 1.0] + ts).sorted()
        var out: [[P]] = []
        for i in 0..<(ts.count - 1) where ts[i + 1] - ts[i] > 1e-6 {
            let m = a + d * ((ts[i] + ts[i + 1]) / 2)
            if inside(m, ring) { out.append([a + d * ts[i], a + d * ts[i + 1]]) }
        }
        return out
    }

    private static func inside(_ p: P, _ ring: [P]) -> Bool {
        var odd = false
        for i in 0..<(ring.count - 1) {
            let a = ring[i], b = ring[i + 1]
            if (a.y > p.y) != (b.y > p.y) && p.x < a.x + (p.y - a.y) / (b.y - a.y) * (b.x - a.x) { odd.toggle() }
        }
        return odd
    }

    /// An arch's ring of voussoirs between two angles: bone stones with ink joints, the keystone bold.
    private static func voussoirs(_ plate: inout Plate, _ c: P, _ r: Double, from a: Double, to b: Double) {
        let depth = 0.08
        let band = arc(c, r, from: a, to: b) + arc(c, r + depth, from: b, to: a) + [polar(c, r, a)]
        Kit.cut(&plate, band, edge: heavy)
        let n = max(2, Int((b - a) * r / 0.07))
        for k in 1..<n {
            let t = a + (b - a) * Double(k) / Double(n)
            plate.line([polar(c, r, t), polar(c, r + depth, t)], 0.016)
            if k % 2 == 0 {
                let t1 = a + (b - a) * Double(k + 1) / Double(n)
                let stone = arc(c, r + 0.012, from: t + 0.02, to: t1 - 0.02) + arc(c, r + depth - 0.012, from: t1 - 0.02, to: t + 0.02)
                plate.lines(hatch([stone + [stone[0]]], angle: t, gap: 0.016), fine)
            }
        }
    }
}
