// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 10, Countdown: problems 55 to 60's plates, drawn with `Kit`.
extension EscapementArt {
    /// A lump with a ragged edge about `c`, the same on every run for its seed.
    private static func lump(_ c: P, _ r: Double, seed: Int, squash: Double = 0.7) -> [P] {
        let n = 9
        let ring = (0..<n).map { k -> P in
            let a = 2 * .pi * Double(k) / Double(n), s = r * (0.75 + 0.45 * rnd(seed, k))
            return c + P(s * cos(a), squash * s * sin(a))
        }
        return ring + [ring[0]]
    }

    /// Problem 55, Curfew, hex, clocks 1-: the couvre-feu, the hood set over the hearth's fire at nightfall, a bold
    /// ribbed dome with a ring handle and a pierced band, on the hearthstone under the mantel beam, bellows hung on
    /// the left and the poker against the right jamb; the embers' glow in the second ink, through the band's middle
    /// piercings and under the lip.
    static func plate55() -> Plate {
        var plate = Plate()
        let base = 0.8, rx = 0.76, ry = 0.88
        func half(_ y: Double) -> Double { rx * sqrt(max(0, 1 - pow((base - y) / ry, 2))) }
        let dome = ellipse(P(0, base), rx, ry, from: .pi, to: 2 * .pi) + [P(-rx, base)]
        let lip = box(P(-rx - 0.05, base - 0.035), P(rx + 0.05, base + 0.035))
        let floor = box(P(-1.1, base + 0.035), P(1.1, 1.1))
        let beam = box(P(-1.1, -0.68), P(1.1, -0.5))
        let jambs = [box(P(-1.1, -0.5), P(-0.84, base + 0.035)), box(P(0.84, -0.5), P(1.1, base + 0.035))]
        let bellows = [P(-0.7, -0.4), P(-0.6, -0.33), P(-0.56, -0.12), P(-0.62, 0.1), P(-0.7, 0.16), P(-0.78, 0.1),
                       P(-0.84, -0.12), P(-0.8, -0.33), P(-0.7, -0.4)]
        let nozzle = Kit.band(P(-0.7, 0.14), P(-0.7, 0.3), 0.045)
        let poker = Kit.band(P(0.79, base), P(0.66, -0.34), 0.05)
        let grip = arc(P(0.655, -0.39), 0.055)
        let handle = Kit.ribbon(curve(P(-0.16, -0.05), P(0, -0.46), P(0.16, -0.05)), 0.055)
        Kit.ground(&plate, angle: 0.5, around: [box(P(-1.1, -1.1), P(1.1, -0.68)), dome, lip, floor, beam, bellows, nozzle, poker, grip, handle] + jambs)

        // The mantel beam, its grain in bone, and the jambs' stones in courses.
        plate.fill(beam)
        plate.line(beam, 0.04)
        plate.line((0...40).map { i in
            let x = -1.1 + 2.2 * Double(i) / 40
            return P(x, -0.59 + 0.018 * sin(x * 7))
        }, 0.03)
        for x in [-0.62, 0.62] { Kit.mass(&plate, arc(P(x, -0.59), 0.03)) }
        // The chimney breast's stones over it, in courses.
        for (row, y) in stride(from: -0.68, to: -1.1, by: -0.13).enumerated() {
            for x in stride(from: -1.26 + Double(row % 2) * 0.14, to: 1.1, by: 0.28) {
                let stone = box(P(x, y), P(x + 0.28, y - 0.13))
                plate.fill(stone)
                plate.line(stone, 0.04)
            }
        }
        for jamb in jambs {
            let x0 = jamb[0].x, x1 = jamb[1].x
            for (k, y) in stride(from: -0.5, to: base, by: 0.22).enumerated() {
                let stone = box(P(x0, y), P(x1, min(y + 0.22, base + 0.035)))
                if k % 2 == 0 { Kit.mass(&plate, stone) } else { Kit.solid(&plate, stone, angle: -0.8, gap: 0.025) }
            }
        }

        // The bellows on its nail, and the poker leaning on the jamb.
        plate.line([P(-0.7, -0.5), P(-0.7, -0.4)], heavy)
        Kit.mass(&plate, bellows)
        plate.line([P(-0.7, -0.33), P(-0.62, -0.1), P(-0.7, 0.1), P(-0.78, -0.1), P(-0.7, -0.33)], 0.012, .bone)
        plate.fill(arc(P(-0.7, -0.1), 0.03))
        for p in [P(-0.7, -0.37), P(-0.63, -0.3), P(-0.59, -0.12), P(-0.64, 0.07), P(-0.76, 0.07), P(-0.81, -0.12),
                  P(-0.77, -0.3)] {
            plate.fill(arc(p, 0.014))
        }
        plate.line(arc(P(-0.7, -0.1), 0.03), medium)
        Kit.mass(&plate, nozzle)
        Kit.mass(&plate, poker)
        plate.line(arc(P(0.655, -0.39), 0.055), 0.026)

        // The hearthstone, its joints in bone.
        Kit.mass(&plate, floor)
        plate.lines([[P(-0.42, base + 0.035), P(-0.5, 1.1)], [P(0.4, base + 0.035), P(0.48, 1.1)],
                     [P(-1.1, 0.95), P(1.1, 0.95)]], 0.014, .bone)

        // The embers spilt from under the lip.
        let embers = [(P(-0.22, 0.875), 0.04), (P(-0.1, 0.89), 0.035), (P(0.04, 0.88), 0.045), (P(0.17, 0.885), 0.035),
                      (P(0.28, 0.87), 0.03)]
        for (k, (c, r)) in embers.enumerated() {
            let ember = lump(c, 1.3 * r, seed: 55 + k)
            plate.fill(ember, .second)
            plate.line(ember, medium)
        }

        // The dome in gores, ink and bone in turn, girdled, and pierced near the foot.
        let top = base - 0.999 * ry
        let edges = [-1.0, -0.88, -0.64, -0.52, -0.28, -0.14, 0.14, 0.28, 0.52, 0.64, 0.88, 1.0]
        plate.fill(dome)
        func gore(_ a: Double, _ b: Double) -> [P] {
            let up = stride(from: 0.58, through: top, by: -0.02).map { P(a * half($0), $0) }
            return up + stride(from: top, through: 0.58, by: 0.02).map { P(b * half($0), $0) } + [up[0]]
        }
        for k in 0..<(edges.count - 1) {
            let m = (edges[k] + edges[k + 1]) / 2
            if k % 2 == 0 {
                Kit.mass(&plate, gore(edges[k], edges[k + 1]))
            } else {
                for y in stride(from: 0.02, through: 0.54, by: 0.08) where abs(m * half(y)) < half(y) - 0.04 {
                    plate.fill(arc(P(m * half(y), y), 0.022), .black)
                }
            }
        }
        plate.line(dome, 0.02)
        let girdle = stride(from: -1.0, through: 1.0, by: 0.05).map { P($0 * half(0.36), 0.36) }
        Kit.cut(&plate, Kit.ribbon(girdle, 0.05))
        for x in stride(from: -0.6, through: 0.6, by: 0.08) { plate.fill(arc(P(x, 0.36), 0.012), .black) }
        let pierced = (stride(from: 0.58, through: base, by: 0.01).map { P(-half($0), $0) }
            + stride(from: base, through: 0.58, by: -0.01).map { P(half($0), $0) })
        Kit.cut(&plate, pierced + [pierced[0]])
        for x in stride(from: -0.6, through: 0.61, by: 0.1) {
            let hole = arc(P(x, 0.65), 0.03)
            plate.fill(hole, abs(x) > 0.15 && abs(x) < 0.35 ? .second : .black)
            plate.line(hole, medium)
            if x < 0.6 { plate.fill([P(x + 0.05, 0.62), P(x + 0.065, 0.65), P(x + 0.05, 0.68), P(x + 0.035, 0.65), P(x + 0.05, 0.62)], .black) }
        }

        // The lip and the ring handle.
        Kit.mass(&plate, lip)
        plate.line([P(-rx - 0.03, base), P(rx + 0.03, base)], 0.012, .bone)
        Kit.mass(&plate, handle)
        plate.line(curve(P(-0.16, -0.05), P(0, -0.46), P(0.16, -0.05)), 0.01, .bone)
        for x in [-0.16, 0.16] {
            plate.fill(arc(P(x, -0.05), 0.04), .black)
            plate.line(arc(P(x, -0.05), 0.016), medium, .bone)
        }

        callout(&plate, "A", from: P(0.09, -0.24), to: P(0.24, -0.4))
        callout(&plate, "B", from: P(-0.5, 0.65), to: P(-0.3, 0.47))
        callout(&plate, "C", from: P(-0.66, -0.2), to: P(-0.3, -0.38))
        callout(&plate, "D", from: P(0.71, 0.05), to: P(0.6, 0.0))
        return plate
    }

    /// An outline from a spine and its half-widths either side, left then right, closed.
    private static func vane(_ spine: [P], left: (Double) -> Double, right: (Double) -> Double) -> [P] {
        let n = spine.count - 1
        var l: [P] = [], r: [P] = []
        for i in spine.indices {
            let d = simd_normalize(spine[min(i + 1, n)] - spine[max(i - 1, 0)]), side = P(-d.y, d.x)
            let t = Double(i) / Double(n)
            l.append(spine[i] + side * left(t))
            r.append(spine[i] - side * right(t))
        }
        return l + r.reversed() + [l[0]]
    }

    /// Problem 56, Last orders, hex, clocks 1-,2-: a pewter tankard foaming over on the bar, its handle to the left,
    /// bottles on the shelf behind, and the bar's bell hung from its scrolled bracket on the right wall, its pull cord
    /// and tassel below; the bell's clapper in the second ink, under its mouth in the lane at three o'clock.
    static func plate56() -> Plate {
        var plate = Plate()
        let counter = box(P(-1.1, 0.74), P(1.1, 1.1))
        let body = [P(-0.55, -0.08), P(0.15, -0.08), P(0.2, 0.74), P(-0.6, 0.74), P(-0.55, -0.08)]
        func edge(_ y: Double) -> (Double, Double) {
            let t = (y + 0.08) / 0.82
            return (-0.55 - 0.05 * t, 0.15 + 0.05 * t)
        }
        let handlePath = curve(P(-0.56, 0.04), P(-1.02, 0.3), P(-0.58, 0.58))
        let handle = Kit.ribbon(handlePath, 0.08)
        let foam: [(P, Double)] = [(P(-0.52, -0.1), 0.075), (P(-0.4, -0.15), 0.09), (P(-0.25, -0.13), 0.085),
                                    (P(-0.1, -0.16), 0.095), (P(0.06, -0.12), 0.08), (P(0.16, -0.08), 0.065),
                                    (P(-0.46, -0.24), 0.08), (P(-0.3, -0.28), 0.095), (P(-0.12, -0.3), 0.09),
                                    (P(0.03, -0.24), 0.08), (P(-0.2, -0.4), 0.075)]
        let shelf = box(P(-0.75, -0.68), P(0.42, -0.62))
        let bottles = [-0.6, -0.4, -0.18, 0.04, 0.26].enumerated().map { k, x -> [P] in
            let h = k % 2 == 0 ? 0.2 : 0.15, w = k % 2 == 0 ? 0.065 : 0.075, y = -0.68
            return [P(x - w, y), P(x - w, y - h), P(x - 0.025, y - h - 0.07), P(x - 0.025, y - h - 0.17),
                    P(x + 0.025, y - h - 0.17), P(x + 0.025, y - h - 0.07), P(x + w, y - h), P(x + w, y), P(x - w, y)]
        }
        let bellX = 0.7
        let profile: [(Double, Double)] = [(-0.44, 0.06), (-0.41, 0.095), (-0.36, 0.11), (-0.28, 0.12), (-0.2, 0.135),
                                           (-0.14, 0.16), (-0.1, 0.2), (-0.075, 0.22)]
        let bell = profile.map { P(bellX - $0.1, $0.0) } + profile.reversed().map { P(bellX + $0.1, $0.0) }
            + [P(bellX - 0.06, -0.44)]
        let arm = Kit.band(P(1.1, -0.53), P(0.58, -0.53), 0.05)
        let brace = Kit.ribbon(curve(P(1.05, -0.18), P(0.86, -0.22), P(0.84, -0.53)), 0.04)
        let cordPath = (0...24).map { i -> P in
            let t = Double(i) / 24
            return P(bellX + 0.03 * sin(t * 9), 0.08 + 0.34 * t)
        }
        let cord = Kit.ribbon(cordPath, 0.04)
        let tassel = [P(bellX, 0.4), P(bellX + 0.05, 0.46), P(bellX + 0.07, 0.6), P(bellX - 0.07, 0.6), P(bellX - 0.05, 0.46),
                      P(bellX, 0.4)]
        let cloud = [P(-0.62, -0.06), P(-0.56, -0.25), P(-0.42, -0.36), P(-0.28, -0.48), P(-0.1, -0.44),
                     P(0.06, -0.34), P(0.22, -0.14), P(0.24, -0.04), P(-0.62, -0.06)]
        Kit.ground(&plate, angle: -0.55, around: [counter, body, handle, shelf, bell, arm, brace, cord, tassel, cloud]
            + bottles.map { Array($0.dropLast()).map { $0 + P(0, -0.002) } + [$0[0] + P(0, -0.002)] })

        // The shelf and its bottles, each with a blank label.
        for (k, bottle) in bottles.enumerated() {
            Kit.mass(&plate, bottle)
            let x = bottle[0].x + (k % 2 == 0 ? 0.065 : 0.075)
            Kit.cut(&plate, box(P(x - 0.04, -0.75), P(x + 0.04, -0.8 - (k % 2 == 0 ? 0.04 : 0.0))))
        }
        Kit.mass(&plate, shelf)

        // The bar, its planks' grain in bold.
        plate.fill(counter)
        for y in [0.86, 0.96] {
            plate.line((0...40).map { i in
                let x = -1.1 + 2.2 * Double(i) / 40
                return P(x, y + 0.015 * sin(x * 6 + y * 20))
            }, 0.03)
        }
        for x in [-0.72, 0.5] { plate.line([P(x, 0.79), P(x, 1.1)], 0.03) }
        Kit.mass(&plate, box(P(-1.1, 0.74), P(1.1, 0.78)))

        // The tankard: pewter in ink, its shine and hoops in bone, the handle's thumb-piece.
        Kit.mass(&plate, handle)
        plate.line(handlePath, 0.014, .bone)
        Kit.mass(&plate, body)
        let flutes = [P(-0.52, -0.05), P(0.12, -0.05), P(0.165, 0.71), P(-0.56, 0.71), P(-0.52, -0.05)]
        plate.fill(flutes)
        plate.lines(hatch([flutes], angle: .pi / 2 + 0.03, gap: 0.085, shift: 0.3), 0.036)
        plate.fill(Kit.band(P(-0.33, -0.05), P(-0.35, 0.71), 0.05))
        for y in [0.06, 0.6] {
            let (l, r) = edge(y)
            Kit.mass(&plate, box(P(l, y - 0.03), P(r, y + 0.03)))
            plate.fill(box(P(l + 0.01, y - 0.018), P(r - 0.01, y + 0.018)))
            for x in stride(from: l + 0.06, to: r - 0.03, by: 0.08) { plate.fill(arc(P(x, y), 0.012), .black) }
        }
        Kit.mass(&plate, box(P(-0.6, -0.11), P(0.2, -0.05)))

        // The head of foam over the rim, and its drips down the side.
        for (from, to) in [(P(-0.1, -0.06), P(-0.11, 0.2)), (P(0.13, -0.06), P(0.15, 0.1))] {
            Kit.cut(&plate, Kit.ribbon([from, to], 0.055))
            Kit.cut(&plate, arc(to, 0.034))
        }
        for (c, r) in foam { plate.fill(arc(c, r + 0.008), .black) }
        for (c, r) in foam { plate.fill(arc(c, r - 0.008)) }
        for (k, (c, r)) in foam.enumerated() where k % 2 == 0 {
            plate.line(arc(c, 0.55 * r, from: 3.4, to: 5.6), 0.012)
        }
        for (k, (c, _)) in foam.enumerated() where k % 2 == 1 { plate.line(arc(c + P(0.02, 0.02), 0.022), 0.012) }

        // The bracket, the bell and its pull.
        Kit.mass(&plate, brace)
        Kit.mass(&plate, arm)
        Kit.mass(&plate, arc(P(0.57, -0.53), 0.04))
        plate.line(arc(P(bellX, -0.48), 0.035), 0.022)
        Kit.mass(&plate, cord)
        for p in cordPath.enumerated() where p.offset % 3 == 1 {
            plate.line([p.element + P(-0.015, -0.012), p.element + P(0.015, 0.012)], 0.012, .bone)
        }
        Kit.mass(&plate, tassel)
        for y in [0.47, 0.53] { plate.line([P(bellX - 0.06, y), P(bellX + 0.06, y)], 0.014, .bone) }
        plate.fill(Kit.band(P(bellX, -0.11), P(bellX, -0.02), 0.026), .second)
        plate.line(Kit.band(P(bellX, -0.11), P(bellX, -0.02), 0.026), medium)
        plate.fill(arc(P(bellX, 0.025), 0.05), .second)
        plate.line(arc(P(bellX, 0.025), 0.05), medium)
        Kit.mass(&plate, bell)
        for y in [-0.33, -0.15] {
            let w = y < -0.2 ? 0.118 : 0.16
            plate.fill(box(P(bellX - w, y - 0.016), P(bellX + w, y + 0.016)))
        }
        plate.fill(Kit.band(P(bellX - 0.05, -0.4), P(bellX - 0.09, -0.19), 0.03))
        plate.line([P(bellX - 0.22, -0.075), P(bellX + 0.22, -0.075)], 0.02)

        callout(&plate, "A", from: P(-0.22, -0.34), to: P(-0.22, -0.42))
        callout(&plate, "B", from: P(-0.82, 0.3), to: P(-0.86, 0.04))
        callout(&plate, "C", from: P(0.82, -0.25), to: P(0.86, -0.0))
        callout(&plate, "D", from: P(-0.3, 0.9), to: P(-0.45, 0.8))
        return plate
    }

    /// Problem 57, Deadline, hex, clocks 1-,3-: a bold rule drawn across the whole glass, the quill that drew it at
    /// rest on it with the inkwell beside, and below them a folded letter, its flaps closed on a seal with ribbon
    /// tails; the wax seal in the second ink, at the flaps' point in the lane at five o'clock.
    static func plate57() -> Plate {
        var plate = Plate()
        let rule = Kit.band(P(-1.1, -0.06), P(1.1, -0.06), 0.05)
        let well = [P(0.53, -0.085), P(0.83, -0.085), P(0.79, -0.3), P(0.57, -0.3), P(0.53, -0.085)]
        let neck = box(P(0.61, -0.37), P(0.75, -0.3))
        let nib = P(0.2, -0.085)
        let spine = curve(nib, P(-0.18, -0.42), P(-0.78, -0.56), 60)
        let feather = vane(Array(spine[16...]), left: { 0.15 * pow(sin(.pi * min(1, $0 * 1.2)), 0.6) },
                           right: { 0.1 * pow(sin(.pi * min(1, $0 * 1.1)), 0.7) })
        let barrel = Kit.ribbon(Array(spine[3...18]), 0.034)
        let seal = P(0.21, 0.37), turn = -0.1
        let half = P(0.56, 0.29), centre = P(0.2, 0.39)
        let corners = [P(-half.x, -half.y), P(half.x, -half.y), P(half.x, half.y), P(-half.x, half.y)].map {
            turned([$0], by: turn)[0] + centre
        }
        let letter = corners + [corners[0]]
        let shadow = letter.map { $0 + P(0.025, 0.032) }
        Kit.ground(&plate, angle: -0.6, around: [rule, well, neck, feather, barrel, letter, shadow])

        // The letter, its shadow in ink, the lower flap in ink, the side flaps ruled boldly.
        Kit.mass(&plate, shadow)
        plate.fill(letter)
        Kit.mass(&plate, [corners[0], seal, corners[3], corners[0]])
        let leftFlap = [corners[0], seal, corners[3], corners[0]].map { ($0 - seal) * 0.97 + seal + P(0.008, 0) }
        plate.lines(hatch([leftFlap], angle: -0.9, gap: 0.095), 0.045, .bone)
        plate.lines(hatch([[corners[1], seal, corners[2], corners[1]]], angle: 0.9, gap: 0.06), 0.022)
        plate.line([corners[3], seal, corners[2]], 0.02)
        plate.fill([corners[0], corners[1], seal, corners[0]])
        plate.line([corners[0], seal, corners[1]], 0.026)
        plate.line([corners[0] + P(0.03, 0.03), seal + P(0, 0.035), corners[1] + P(-0.03, 0.03)], 0.012)
        plate.line(letter, 0.022)

        // The ribbon's tails and the seal on them.
        for end in [P(0.05, 0.62), P(0.33, 0.63)] {
            let tail = Kit.band(seal, end, 0.06), d = simd_normalize(end - seal), n = P(-d.y, d.x) * 0.03
            Kit.mass(&plate, tail)
            plate.fill([end + n, end - n, end - d * 0.035, end + n])
        }
        let wax = lump(seal, 0.088, seed: 57, squash: 1)
        plate.fill(wax, .second)
        plate.line(wax, medium)
        plate.line(arc(seal, 0.052), 0.012, .bone)
        plate.lines(Kit.numeral("X", at: seal, height: 0.05), 0.012, .bone)

        // The rule, the inkwell and the quill at rest on the rule.
        Kit.mass(&plate, rule)
        Kit.mass(&plate, well)
        Kit.mass(&plate, neck)
        plate.fill(Kit.band(P(0.6, -0.11), P(0.62, -0.27), 0.04))
        plate.fill(box(P(0.535, -0.2), P(0.825, -0.17)))
        plate.fill(box(P(0.53, -0.125), P(0.83, -0.105)))
        for x in [0.68, 0.76] { plate.fill(Kit.band(P(x, -0.22), P(x + 0.01, -0.28), 0.03)) }
        plate.line(box(P(0.6, -0.39), P(0.76, -0.37)), 0.02)
        Kit.mass(&plate, feather)
        let along = Array(spine[16...])
        for i in stride(from: 4, to: along.count - 3, by: 3) {
            let d = simd_normalize(along[i + 1] - along[i - 1]), n = P(-d.y, d.x)
            plate.line([along[i], along[i] + n * 0.11 + d * 0.06], 0.016, .bone)
            plate.line([along[i], along[i] - n * 0.08 + d * 0.05], 0.016, .bone)
        }
        plate.line(along, 0.014, .bone)
        Kit.cut(&plate, barrel, edge: 0.012)
        let d = simd_normalize(spine[3] - nib), n = P(-d.y, d.x)
        Kit.mass(&plate, [nib, spine[3] + n * 0.017, spine[3] - n * 0.017, nib])
        plate.line([nib + d * 0.01, nib + d * 0.04], fine, .bone)

        callout(&plate, "A", from: seal + P(0.07, 0.04), to: P(0.47, 0.58))
        callout(&plate, "B", from: P(-0.33, -0.72), to: P(-0.62, -0.62))
        callout(&plate, "C", from: P(0.76, -0.22), to: P(0.8, -0.5))
        callout(&plate, "D", from: P(-0.8, -0.06), to: P(-0.8, -0.3))
        return plate
    }

    /// A smooth path through points, a Catmull-Rom spline with `n` steps a span.
    private static func spline(_ points: [P], _ n: Int = 12) -> [P] {
        var out: [P] = []
        for i in 0..<(points.count - 1) {
            let p0 = points[max(i - 1, 0)], p1 = points[i], p2 = points[i + 1], p3 = points[min(i + 2, points.count - 1)]
            for k in 0..<n {
                let t = Double(k) / Double(n), t2 = t * t, t3 = t2 * t
                let a = 2 * p1, b = p2 - p0, c = 2 * p0 - 5 * p1 + 4 * p2 - p3, d = 3 * p1 - p0 - 3 * p2 + p3
                out.append(0.5 * (a + b * t + c * t2 + d * t3))
            }
        }
        return out + [points[points.count - 1]]
    }

    /// An outline turned about a vertical axis: half-widths at heights from `base` upward, about x = `x`.
    private static func lathe(_ x: Double, _ profile: [(Double, Double)]) -> [P] {
        let right = profile.map { P(x + $0.1, $0.0) }
        return right + right.reversed().map { P(2 * x - $0.x, $0.y) } + [right[0]]
    }

    /// Problem 58, Final hour, hex, clocks 1-: a tower's striking jack, a carved figure in hat, ruff and hose on his
    /// plinth, his hammer raised high over the hour bell hung from its beam on the right, the swing marked; the
    /// hammer's head in the second ink, up in the rim clear of every hub.
    static func plate58() -> Plate {
        var plate = Plate()
        let fx = -0.46
        let bell = lathe(0.5, [(0.47, 0.35), (0.42, 0.34), (0.34, 0.29), (0.22, 0.22), (0.06, 0.18), (-0.06, 0.16),
                               (-0.12, 0.13), (-0.15, 0.08)])
        let beam = box(P(0.2, -0.27), P(1.1, -0.19))
        let plinth = box(P(-0.8, 0.8), P(-0.1, 1.1))
        let hat = [P(fx - 0.17, -0.3), P(fx + 0.17, -0.3), P(fx + 0.17, -0.27), P(fx + 0.08, -0.27), P(fx + 0.07, -0.44),
                   P(fx - 0.08, -0.44), P(fx - 0.09, -0.27), P(fx - 0.17, -0.27), P(fx - 0.17, -0.3)]
        let head = ellipse(P(fx, -0.2), 0.075, 0.09)
        let doublet = [P(fx - 0.17, -0.08), P(fx + 0.17, -0.08), P(fx + 0.15, 0.24), P(fx + 0.2, 0.42), P(fx - 0.2, 0.42),
                       P(fx - 0.15, 0.24), P(fx - 0.17, -0.08)]
        let legs = [box(P(fx - 0.13, 0.42), P(fx - 0.03, 0.74)), box(P(fx + 0.03, 0.42), P(fx + 0.13, 0.74))]
        let boots = [[P(fx - 0.14, 0.72), P(fx - 0.02, 0.72), P(fx - 0.01, 0.8), P(fx - 0.2, 0.8), P(fx - 0.14, 0.72)],
                     [P(fx + 0.02, 0.72), P(fx + 0.14, 0.72), P(fx + 0.2, 0.8), P(fx + 0.01, 0.8), P(fx + 0.02, 0.72)]]
        let raised = [P(fx + 0.15, -0.04), P(fx + 0.3, -0.18), P(fx + 0.34, -0.46)]
        let sleeve = Kit.ribbon(spline(raised, 8), 0.08)
        let hand = P(fx + 0.34, -0.5)
        let akimbo = Kit.ribbon(spline([P(fx - 0.15, -0.04), P(fx - 0.27, 0.1), P(fx - 0.14, 0.22)], 8), 0.07)
        let grip = hand + P(0.03, 0.08), top = P(-0.18, -0.8)
        let shaft = Kit.band(grip, top, 0.035)
        let d = simd_normalize(top - grip), n = P(-d.y, d.x)
        let hammer = [top + n * 0.11 + d * 0.045, top - n * 0.07 + d * 0.045, top - n * 0.09 - d * 0.045,
                      top + n * 0.11 - d * 0.045, top + n * 0.11 + d * 0.045]
        Kit.ground(&plate, angle: 0.62, around: [bell, beam, plinth, hat, head, doublet, sleeve, akimbo, shaft, hammer]
            + legs + boots)

        // The swing, from the hammer down to the bell's shoulder.
        plate.lines(dashed(arc(P(0.02, -0.12), 0.72, from: -2.0, to: -0.62), on: 0.05, off: 0.035), 0.022)
        Kit.mass(&plate, Kit.barb(polar(P(0.02, -0.12), 0.72, -0.6), toward: -0.6 + .pi / 2, size: 0.07))

        // The beam, the bell's headstock and the bell, banded in bone.
        Kit.mass(&plate, beam)
        plate.line([P(0.2, -0.23), P(1.1, -0.23)], 0.014, .bone)
        Kit.mass(&plate, box(P(0.43, -0.19), P(0.57, -0.14)))
        Kit.mass(&plate, bell)
        for (y, w) in [(-0.06, 0.155), (0.04, 0.17), (0.16, 0.2), (0.27, 0.24), (0.37, 0.31)] {
            plate.fill(box(P(0.5 - w, y - 0.026), P(0.5 + w, y + 0.026)))
        }
        plate.fill(box(P(0.15, 0.43), P(0.85, 0.45)))
        plate.fill(Kit.ribbon(spline([P(0.4, -0.08), P(0.34, 0.14), P(0.24, 0.36)], 6), 0.07))
        plate.fill(Kit.ribbon(spline([P(0.6, -0.08), P(0.66, 0.14), P(0.74, 0.32)], 6), 0.02))

        // The plinth, its face in section.
        Kit.solid(&plate, plinth, angle: -0.7, gap: 0.03)
        Kit.mass(&plate, box(P(-0.84, 0.8), P(-0.06, 0.85)))

        // The jack: boots, hose, doublet, ruff, face and hat, his free hand on his hip.
        for leg in legs {
            Kit.mass(&plate, leg)
            for y in stride(from: 0.46, to: 0.72, by: 0.065) { plate.fill(box(P(leg[0].x, y), P(leg[1].x, y + 0.034))) }
        }
        for boot in boots { Kit.mass(&plate, boot) }
        Kit.mass(&plate, akimbo)
        Kit.mass(&plate, doublet)
        for x in stride(from: fx - 0.12, through: fx + 0.13, by: 0.06) where abs(x - fx) > 0.02 {
            plate.fill(Kit.band(P(x, -0.02), P(x * 1.0, 0.17), 0.03))
        }
        let skirt = [P(fx - 0.15, 0.25), P(fx + 0.15, 0.25), P(fx + 0.2, 0.42), P(fx - 0.2, 0.42), P(fx - 0.15, 0.25)]
        Kit.cut(&plate, skirt, edge: 0.016)
        for x in stride(from: -0.1, through: 0.1, by: 0.066) {
            Kit.mass(&plate, Kit.band(P(fx + x, 0.25), P(fx + 1.35 * x, 0.42), 0.036))
        }
        plate.fill(box(P(fx - 0.155, 0.2), P(fx + 0.155, 0.25)))
        Kit.mass(&plate, box(P(fx - 0.03, 0.195), P(fx + 0.03, 0.255)))
        for y in [0.0, 0.08, 0.15] { plate.fill(arc(P(fx, y), 0.018)) }
        for x in [fx - 0.1, fx + 0.1] { plate.fill(Kit.band(P(x, 0.27), P(x * 1.0 + (x < fx ? -0.03 : 0.03), 0.4), 0.03)) }
        let ruff = (0...10).map { k -> P in
            let x = fx - 0.15 + 0.03 * Double(k)
            return P(x, k % 2 == 0 ? -0.08 : -0.12)
        }
        Kit.cut(&plate, ruff + [P(fx + 0.15, -0.06), P(fx - 0.15, -0.06), ruff[0]], edge: 0.012)
        Kit.cut(&plate, head, edge: 0.014)
        Kit.mass(&plate, [P(fx - 0.06, -0.15), P(fx + 0.06, -0.15), P(fx + 0.035, -0.1), P(fx, -0.08), P(fx - 0.035, -0.1),
                          P(fx - 0.06, -0.15)])
        plate.fill(arc(P(fx + 0.03, -0.22), 0.012), .black)
        plate.fill(arc(P(fx - 0.03, -0.22), 0.012), .black)
        plate.line([P(fx, -0.21), P(fx + 0.012, -0.17), P(fx - 0.005, -0.165)], 0.01)
        Kit.mass(&plate, hat)
        plate.fill(box(P(fx - 0.075, -0.33), P(fx + 0.075, -0.31)))

        // The raised arm, the shaft, and the hammer's head.
        Kit.mass(&plate, sleeve)
        plate.line(spline(raised, 8), 0.012, .bone)
        Kit.mass(&plate, shaft)
        Kit.cut(&plate, arc(hand, 0.045), edge: 0.012)
        plate.fill(hammer, .second)
        plate.line(hammer, medium)
        plate.line([top + n * 0.11 + d * 0.045, top + n * 0.11 - d * 0.045], 0.02)

        callout(&plate, "A", from: top - n * 0.08, to: P(-0.52, -0.66))
        callout(&plate, "B", from: P(0.82, 0.4), to: P(0.9, 0.12))
        callout(&plate, "C", from: P(fx - 0.1, 0.1), to: P(-0.86, 0.02))
        callout(&plate, "D", from: P(-0.3, 0.92), to: P(-0.05, 0.92))
        return plate
    }

    /// Problem 59, Time's up, hex, clocks 1-,2-: a chess clock in a solid ink case on the board's squares, its two
    /// faces and their plungers, the left one's time run out and its flag fallen, the right one's flag still raised,
    /// a king toppled above it and a pawn standing; the fallen flag in the second ink, in the lane at nine o'clock.
    static func plate59() -> Plate {
        var plate = Plate()
        let left = P(-0.62, 0.2), right = P(0.62, 0.2), r = 0.29
        let caseRing = box(P(-1.1, -0.16), P(1.1, 0.64))
        let top = [P(-1.02, -0.3), P(1.02, -0.3), P(1.1, -0.16), P(-1.1, -0.16), P(-1.02, -0.3)]
        let king = turned(lathe(0, [(0, 0.11), (-0.04, 0.11), (-0.05, 0.08), (-0.08, 0.07), (-0.1, 0.095), (-0.12, 0.05),
                                    (-0.26, 0.04), (-0.28, 0.075), (-0.31, 0.075), (-0.33, 0.05), (-0.37, 0.07), (-0.39, 0.02)]),
                          by: .pi / 2 + 0.06).map { $0 + P(-0.22, -0.66) }
        let cross = [Kit.band(P(0.17, -0.63), P(0.28, -0.62), 0.03), Kit.band(P(0.235, -0.68), P(0.235, -0.57), 0.03)]
        let pawn = lathe(0.6, [(-0.36, 0.08), (-0.4, 0.08), (-0.41, 0.06), (-0.44, 0.05), (-0.46, 0.065), (-0.48, 0.035),
                               (-0.56, 0.03), (-0.6, 0.05), (-0.62, 0.055)])
        let pawnHead = arc(P(0.6, -0.67), 0.055)
        Kit.ground(&plate, angle: -0.42, around: [caseRing, top, king, pawn, pawnHead] + cross)

        // The board's squares in perspective under the clock.
        let rows = [0.62, 0.68, 0.75, 0.83, 0.92, 1.02, 1.14], vanish = -1.6
        for (i, y0) in rows.dropLast().enumerated() {
            let y1 = rows[i + 1]
            for c in -12..<12 {
                func x(_ c: Double, _ y: Double) -> Double { c * 0.12 * (y - vanish) / (0.62 - vanish) }
                let cell = [P(x(Double(c), y0), y0), P(x(Double(c + 1), y0), y0), P(x(Double(c + 1), y1), y1),
                            P(x(Double(c), y1), y1), P(x(Double(c), y0), y0)]
                if (i + c) % 2 == 0 { plate.fill(cell, .black) } else { plate.fill(cell); plate.line(cell, medium) }
            }
        }

        // The case: its top in ruled bone, its face solid ink, a cartouche between the dials.
        Kit.cut(&plate, top, edge: 0.02)
        plate.lines(hatch([top], angle: 0.02, gap: 0.06), 0.022)
        Kit.mass(&plate, caseRing)
        let cartouche = ellipse(P(0, 0.22), 0.2, 0.26)
        plate.lines(hatch([box(P(-1.1, -0.16), P(1.1, 0.6)), arc(left, r + 0.05), arc(right, r + 0.05),
                           ellipse(P(0, 0.22), 0.225, 0.285)], angle: .pi / 2, gap: 0.068), 0.043, .bone)
        plate.line(box(P(-1.06, -0.12), P(1.06, 0.55)), 0.02, .bone)
        plate.fill(box(P(-1.1, 0.6), P(1.1, 0.615)))
        Kit.cut(&plate, cartouche, edge: 0.02)
        plate.line(ellipse(P(0, 0.22), 0.15, 0.21), 0.02)
        for k in 0..<8 {
            let a = Double(k) * .pi / 4
            Kit.mass(&plate, [P(0, 0.22), polar(P(0, 0.22), 0.08, a - 0.16), polar(P(0, 0.22), 0.12, a),
                              polar(P(0, 0.22), 0.08, a + 0.16), P(0, 0.22)])
        }
        Kit.mass(&plate, arc(P(0, 0.22), 0.03))

        // The plungers: the left pressed home, the right standing.
        for (x, h) in [(-0.4, 0.07), (0.4, 0.2)] {
            Kit.mass(&plate, box(P(x - 0.045, -0.24 - h), P(x + 0.045, -0.24)))
            plate.fill(Kit.band(P(x - 0.015, -0.24 - h), P(x - 0.015, -0.25), 0.022))
            let cap = ellipse(P(x, -0.24 - h), 0.09, 0.035)
            Kit.cut(&plate, cap, edge: 0.016)
        }

        // The faces in their bezels.
        for c in [left, right] {
            Kit.cut(&plate, arc(c, r + 0.035))
            Kit.dial(&plate, c, r)
        }
        Kit.hands(&plate, left, r, hours: 6, minutes: 0.4)
        Kit.hands(&plate, right, r, hours: 5, minutes: 52)
        // The flags: the right raised by its minute hand, the left fallen.
        let rightPivot = polar(right, 0.84 * r, Kit.clock(0.35))
        Kit.mass(&plate, [rightPivot, rightPivot + P(-0.07, -0.02), rightPivot + P(-0.075, 0.03), rightPivot])
        let pivot = polar(left, 0.84 * r, Kit.clock(0.35))
        let flag = [pivot, pivot + P(0.012, 0.1), pivot + P(-0.045, 0.085), pivot + P(-0.012, 0.012), pivot]
        plate.fill(flag, .second)
        plate.line(flag, medium)
        plate.fill(arc(pivot, 0.014), .black)

        // The king toppled, and a pawn standing.
        Kit.mass(&plate, king)
        plate.line([P(-0.48, -0.66), P(-0.12, -0.648)], 0.014, .bone)
        for x in [-0.33, -0.17, -0.12] {
            plate.line([P(x, -0.76), P(x + 0.012, -0.55)], 0.022, .bone)
        }
        for c in cross { Kit.mass(&plate, c) }
        Kit.mass(&plate, pawn)
        Kit.mass(&plate, pawnHead)
        plate.line(arc(P(0.58, -0.685), 0.022, from: 3.4, to: 4.8), 0.012, .bone)
        plate.line([P(0.575, -0.58), P(0.57, -0.4)], 0.014, .bone)

        callout(&plate, "A", from: pivot + P(-0.02, 0.07), to: P(-0.86, -0.1))
        callout(&plate, "B", from: P(0.42, -0.42), to: P(0.24, -0.38))
        callout(&plate, "C", from: P(-0.3, -0.7), to: P(-0.44, -0.86))
        callout(&plate, "D", from: right + P(0.2, 0.18), to: P(0.86, 0.48))
        return plate
    }

    /// Problem 60, Zero hour, hex, clocks 1-: a round bomb on the floor, its collar and cast highlights, with its lit
    /// fuse snaking out of it up past twelve and round the rim to the left; the fuse's spark in the second ink, at its
    /// burning end in the lane at nine o'clock.
    static func plate60() -> Plate {
        var plate = Plate()
        let c = P(0.12, 0.3), radius = 0.44
        let body = arc(c, radius)
        let collarAt = polar(c, radius, -1.25), up = simd_normalize(collarAt - c), side = P(-up.y, up.x)
        let collar = [collarAt + side * 0.09 - up * 0.03, collarAt + side * 0.08 + up * 0.08,
                      collarAt - side * 0.08 + up * 0.08, collarAt - side * 0.09 - up * 0.03, collarAt + side * 0.09 - up * 0.03]
        let spark = P(-0.72, 0.0)
        let fusePath = spline([collarAt + up * 0.08, P(0.24, -0.36), P(0.14, -0.62), P(-0.08, -0.84), P(-0.42, -0.8),
                               P(-0.72, -0.56), P(-0.84, -0.26), spark + P(-0.03, -0.05)], 14)
        let fuse = Kit.ribbon(fusePath, 0.055)
        let shadow = ellipse(P(0.3, 0.77), 0.36, 0.05)
        Kit.ground(&plate, angle: 0.45, around: [body, collar, fuse, shadow])

        Kit.mass(&plate, shadow)
        // The bomb: cast iron in ink, the light across it in bold rings about the lamp, its highlight cut in section.
        Kit.mass(&plate, body)
        let light = c + P(0.36, -0.4)
        for k in 0..<12 {
            let ring = arc(light, 0.2 + 0.08 * Double(k))
            var run: [P] = []
            for p in ring {
                if simd_distance(p, c) < radius - 0.03 { run.append(p) } else if run.count > 1 {
                    plate.line(run, 0.046, .bone)
                    run = []
                } else { run = [] }
            }
            if run.count > 1 { plate.line(run, 0.046, .bone) }
        }
        let shine = ellipse(c + P(0.2, -0.16), 0.1, 0.05, turned: 0.75)
        Kit.solid(&plate, shine, angle: -0.6, gap: 0.022, edge: 0.012)

        // The collar and the fuse, its cord laid in a twist, charred toward the spark.
        Kit.mass(&plate, collar)
        plate.line([collarAt + side * 0.085 + up * 0.02, collarAt - side * 0.085 + up * 0.02], 0.016, .bone)
        Kit.mass(&plate, fuse)
        for (i, p) in fusePath.enumerated() where i % 3 == 1 && i < fusePath.count - 8 {
            let d = simd_normalize(fusePath[i + 1] - fusePath[i - 1]), n = P(-d.y, d.x)
            plate.line([p + n * 0.02 - d * 0.012, p - n * 0.02 + d * 0.012], 0.012, .bone)
        }
        for i in (fusePath.count - 8)..<(fusePath.count - 1) where i % 2 == 0 {
            plate.fill(arc(fusePath[i], 0.012))
        }

        // The spark: a burst of rays about a hot core.
        for k in 0..<10 {
            let a = Double(k) * .pi / 5 + 0.2, l = k % 2 == 0 ? 0.12 : 0.08
            let ray = [polar(spark, 0.025, a - 0.22), polar(spark, l, a), polar(spark, 0.025, a + 0.22), polar(spark, 0.025, a - 0.22)]
            plate.fill(ray, .second)
            plate.line(ray, fine)
        }
        plate.fill(arc(spark, 0.035), .second)
        plate.line(arc(spark, 0.035), medium)
        plate.fill(arc(spark, 0.014))
        for (k, a) in [-2.4, -1.2, 0.9, 2.2].enumerated() {
            plate.fill(arc(polar(spark, 0.16 + 0.02 * Double(k % 2), a), 0.012), .second)
        }

        callout(&plate, "A", from: collarAt + up * 0.04, to: P(0.42, -0.08))
        callout(&plate, "B", from: P(-0.42, -0.8), to: P(-0.3, -0.62))
        callout(&plate, "C", from: c + P(0.26, -0.2), to: P(0.74, 0.62))
        return plate
    }
}
