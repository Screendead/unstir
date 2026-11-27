// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 14, Tourbillon: problems 79 to 84's plates, drawn with `Kit`. Every one is on hex with a two-card hub, so
/// the part each is named for keeps 0.195 clear of the middle and of the six rods at 0.56.
extension EscapementArt {
    /// A closed outline through `points`, each corner rounded by a quadratic.
    private static func smooth(_ points: [P], _ n: Int = 8) -> [P] {
        var out: [P] = []
        for i in points.indices {
            let a = (points[(i + points.count - 1) % points.count] + points[i]) / 2
            let b = (points[i] + points[(i + 1) % points.count]) / 2
            out += curve(a, points[i], b, n).dropLast()
        }
        return out + [out[0]]
    }

    /// A drop of water hanging point up, its belly at `c`.
    private static func drop(_ c: P, _ r: Double) -> [P] {
        let belly = arc(c, r, from: -0.25, to: .pi + 0.25)
        return [c + P(0, -2.3 * r)] + belly + [c + P(0, -2.3 * r)]
    }

    /// Problem 79, Water clock, hex, clocks 1-: a clepsydra. An urn hung from a beam drips through its cock into a
    /// basin whose float lifts a pointer up a column ruled with the hours; the falling drop in the second ink.
    static func plate79() -> Plate {
        var plate = Plate()
        let spoutX = -0.22, surface = 0.13, rodX = 0.04, arm = -0.23
        let beam = box(P(-0.5, -0.89), P(0.7, -0.8))
        let column = box(P(0.43, -0.8), P(0.63, 0.66))
        let urn = smooth([P(-0.52, -0.79), P(0.08, -0.79), P(0.02, -0.73), P(0.08, -0.6), P(-0.04, -0.47),
                          P(spoutX + 0.04, -0.44), P(spoutX - 0.04, -0.44), P(-0.4, -0.47), P(-0.52, -0.6), P(-0.46, -0.73)], 10)
        let basin = box(P(-0.5, -0.12), P(0.24, 0.71))

        Kit.ground(&plate, angle: -0.5, around: [beam, column, urn, basin])

        // The column: two rails, the hours between them rising from the foot as the water fills.
        Kit.cut(&plate, column)
        for x in [0.455, 0.605] { Kit.mass(&plate, box(P(x - 0.025, -0.8), P(x + 0.025, 0.66))) }
        for k in 1...12 {
            let y = 0.55 - Double(k - 1) * 0.112
            Kit.mass(&plate, box(P(0.48, y + 0.048), P(0.53, y + 0.062)))
            plate.lines(Kit.numeral(roman(k), at: P(0.545, y), height: 0.05, squeeze: 0.7), heavy)
        }
        Kit.mass(&plate, box(P(0.39, -0.8), P(0.67, -0.74)))
        Kit.mass(&plate, box(P(0.39, 0.62), P(0.67, 0.7)))

        // The beam, the urn's straps and the urn, fluted in ink and bone.
        Kit.mass(&plate, beam)
        plate.line([P(-0.48, -0.85), P(0.68, -0.85)], 0.012, .bone)
        for x in [-0.42, -0.02] { Kit.mass(&plate, box(P(x - 0.02, -0.8), P(x + 0.02, -0.74))) }
        Kit.cut(&plate, urn)
        let flutes = hatch([urn], angle: 0, gap: 0.09, shift: 0.3)
        for f in flutes where f.count == 2 {
            Kit.mass(&plate, Kit.band(f[0], f[1], 0.03))
        }
        plate.line(urn, 0.03)
        Kit.mass(&plate, box(P(-0.55, -0.81), P(0.11, -0.77)))
        // The cock, hatched in section, and its key.
        Kit.solid(&plate, box(P(spoutX - 0.035, -0.45), P(spoutX + 0.035, -0.38)), angle: 0.8, gap: 0.014, width: fine)
        Kit.mass(&plate, Kit.band(P(spoutX - 0.09, -0.415), P(spoutX + 0.09, -0.415), 0.022))
        Kit.mass(&plate, box(P(spoutX - 0.012, -0.38), P(spoutX + 0.012, -0.355)))

        // The basin's walls, its water in bold ripples and the float riding it.
        Kit.cut(&plate, basin)
        for k in 0..<5 {
            let y = surface + 0.01 + Double(k) * 0.12
            let wave = (0...40).map { i in P(-0.43 + 0.6 * Double(i) / 40, y + 0.008 * sin(Double(i) * 0.7 + Double(k))) }
            Kit.mass(&plate, Kit.ribbon(wave, k == 0 ? 0.04 : 0.03))
        }
        for r in [0.04, 0.075] { plate.line(ellipse(P(spoutX, surface - 0.005), r, 0.28 * r, from: .pi + 0.3, to: 2 * .pi - 0.3), medium) }
        Kit.mass(&plate, box(P(-0.5, -0.12), P(-0.43, 0.71)))
        Kit.mass(&plate, box(P(0.17, -0.12), P(0.24, 0.71)))
        Kit.mass(&plate, box(P(-0.5, 0.675), P(0.24, 0.71)))
        for x in [-0.465, 0.205] { plate.line([P(x, -0.1), P(x, 0.65)], heavy, .bone) }
        Kit.mass(&plate, box(P(-0.54, -0.15), P(-0.39, -0.11)))
        Kit.mass(&plate, box(P(0.13, -0.15), P(0.28, -0.11)))
        for x in [-0.465, 0.205] {
            Kit.mass(&plate, smooth([P(x - 0.07, 0.83), P(x - 0.04, 0.71), P(x + 0.04, 0.71), P(x + 0.07, 0.83)], 3))
        }
        Kit.mass(&plate, Kit.band(P(rodX, surface - 0.07), P(rodX, arm), 0.036))
        Kit.solid(&plate, smooth([P(-0.06, surface - 0.075), P(0.14, surface - 0.075), P(0.15, surface + 0.03), P(-0.07, surface + 0.03)], 4),
                  angle: 0.7, gap: 0.016, width: fine, edge: heavy)
        Kit.mass(&plate, Kit.band(P(rodX - 0.02, arm), P(0.37, arm), 0.04))
        Kit.mass(&plate, Kit.barb(P(0.47, arm), toward: 0, size: 0.1))
        plate.fill(arc(P(rodX, arm), 0.018))
        plate.line(arc(P(rodX, arm), 0.018), medium)

        plate.fill(drop(P(spoutX, -0.27), 0.024), .second)
        plate.line(drop(P(spoutX, -0.27), 0.024), fine)
        plate.lines(dashed([P(spoutX, -0.22), P(spoutX, surface - 0.04)], on: 0.03, off: 0.04), fine)

        callout(&plate, "A", from: P(-0.47, -0.62), to: P(-0.68, -0.44))
        callout(&plate, "B", from: P(-0.3, 0.4), to: P(-0.7, 0.5))
        callout(&plate, "C", from: P(0.12, surface - 0.03), to: P(0.3, 0.04))
        callout(&plate, "D", from: P(0.62, 0.2), to: P(0.8, 0.04))
        return plate
    }

    /// A flame's outline, its base at `c`, `h` tall, licking a little to the right.
    private static func flame(_ c: P, _ h: Double, _ w: Double) -> [P] {
        let tip = c + P(0.12 * w, -h)
        return curve(tip, c + P(0.9 * w, -0.35 * h), c + P(0.05 * w, 0.02 * h), 16)
            + curve(c + P(0.05 * w, 0.02 * h), c + P(-0.95 * w, -0.25 * h), tip, 16).dropFirst()
    }

    /// Problem 80, Candle clock, hex, clocks 1-: a tall candle in a pricket stick, banded in ink with the hours, burned
    /// past the third into the fourth, the burned length ghosted above it and its light thrown out in rays across the
    /// night; the flame in the second ink.
    static func plate80() -> Plate {
        var plate = Plate()
        let x = -0.2, half = 0.1, top = -0.22, foot = 0.56, wick = top - 0.03
        let light = P(x, top - 0.09)

        // The light, ink rays with a hairline down each bone one between.
        let n = 30
        for k in 0..<n {
            let a = 2 * .pi * Double(k) / Double(n) + 0.04
            let b = a + 0.68 * .pi / Double(n)
            plate.fill([polar(light, 0.16, a), polar(light, 2.2, a), polar(light, 2.2, b), polar(light, 0.16, b), polar(light, 0.16, a)], .black)
            plate.line([polar(light, 0.3, a + 1.34 * .pi / Double(n)), polar(light, 2.2, a + 1.34 * .pi / Double(n))], fine)
        }
        for r in [0.1, 0.13] { plate.line(arc(light, r), fine) }

        // The burned length, ghosted: the candle's first three hours.
        let gone = top - 3 * 0.085
        plate.fill(box(P(x - half, gone), P(x + half, top - 0.012)))
        plate.lines(dashed(box(P(x - half, gone), P(x + half, top - 0.012)), on: 0.025, off: 0.02), medium)
        for k in 1...2 {
            plate.lines(dashed([P(x - half, gone + Double(k) * 0.085), P(x + half, gone + Double(k) * 0.085)], on: 0.02, off: 0.02), fine)
        }

        // The candle: bone, its hours banded in ink and numbered, the fourth now burning; shaded down its right side.
        let body = [P(x - half, top + 0.01), P(x - 0.05, top - 0.012), P(x + 0.05, top - 0.012), P(x + half, top + 0.01),
                    P(x + half, foot), P(x - half, foot), P(x - half, top + 0.01)]
        Kit.cut(&plate, body, edge: 0.016)
        plate.lines(hatch([box(P(x + half - 0.045, top + 0.02), P(x + half, foot))], angle: .pi / 2, gap: 0.014), fine)
        for k in 1...9 {
            let y = top + Double(k) * 0.085
            Kit.mass(&plate, Kit.ribbon(curve(P(x - half, y - 0.01), P(x, y + 0.012), P(x + half, y - 0.01), 10), 0.022))
            plate.lines(Kit.numeral(roman(3 + k), at: P(x - 0.012, y - 0.047), height: 0.034, squeeze: 0.72), heavy)
        }
        // Wax run down its left side and pooled.
        let run = smooth([P(x - half - 0.01, top + 0.005), P(x - half + 0.03, top + 0.0), P(x - half + 0.02, top + 0.13),
                          P(x - half - 0.005, top + 0.17), P(x - half - 0.02, top + 0.1)], 5)
        Kit.cut(&plate, run, edge: heavy)

        // The wick.
        plate.line([P(x, top - 0.01), P(x + 0.006, wick), P(x + 0.014, wick - 0.012)], 0.012)

        // The pricket stick: pan, baluster, foot and a ring to carry it by.
        let pan = ellipse(P(x, foot + 0.03), 0.28, 0.055)
        plate.line(pan, 0.05, .bone)
        Kit.solid(&plate, pan, angle: 0.4, gap: 0.022, edge: 0.03)
        Kit.mass(&plate, Kit.ribbon(ellipse(P(x, foot + 0.03), 0.25, 0.04, from: 0.15, to: .pi - 0.15), 0.025))
        let stem = smooth([P(x - 0.04, foot + 0.07), P(x + 0.04, foot + 0.07), P(x + 0.09, foot + 0.15), P(x + 0.03, foot + 0.2),
                           P(x + 0.06, foot + 0.27), P(x - 0.06, foot + 0.27), P(x - 0.03, foot + 0.2), P(x - 0.09, foot + 0.15)], 6)
        plate.line(stem, 0.04, .bone)
        Kit.mass(&plate, stem)
        plate.line(curve(P(x + 0.05, foot + 0.11), P(x + 0.075, foot + 0.15), P(x + 0.035, foot + 0.19)), heavy, .bone)
        let base = ellipse(P(x, foot + 0.3), 0.24, 0.06)
        plate.line(base, 0.05, .bone)
        Kit.mass(&plate, base)
        plate.line(ellipse(P(x, foot + 0.3), 0.2, 0.035, from: 0.2, to: .pi - 0.2), heavy, .bone)
        let ring = P(x + 0.37, foot + 0.04)
        plate.line(arc(ring, 0.07), 0.07, .bone)
        plate.line(arc(ring, 0.07), 0.035)
        Kit.mass(&plate, Kit.band(P(x + 0.26, foot + 0.04), P(x + 0.31, foot + 0.04), 0.03))

        let tongue = flame(P(x + 0.01, wick + 0.01), 0.13, 0.045)
        plate.line(tongue, 0.03, .bone)
        plate.fill(tongue, .second)
        plate.line(tongue, fine)
        plate.fill(flame(P(x + 0.01, wick), 0.05, 0.016))

        callout(&plate, "A", from: P(x, gone + 0.03), to: P(-0.46, -0.66))
        callout(&plate, "B", from: P(x + 0.06, top + 0.25), to: P(0.26, 0.14))
        callout(&plate, "C", from: P(x - 0.25, foot + 0.04), to: P(-0.68, 0.44))
        callout(&plate, "D", from: P(x + 0.2, foot + 0.32), to: P(0.4, 0.8))
        return plate
    }

    /// A star of `points` points about `c`, its rays `r` long and its waist `inner`.
    private static func star(_ c: P, _ r: Double, points: Int = 5, inner: Double = 0.42, turn: Double = -.pi / 2) -> [P] {
        let ring = (0..<(2 * points)).map { k in
            polar(c, k % 2 == 0 ? r : inner * r, turn + Double(k) * .pi / Double(points))
        }
        return ring + [ring[0]]
    }

    /// Problem 81, Nocturnal, hex, clocks 1-: the night instrument held up by its handle, its ring of months in ink, its
    /// toothed hour wheel and its long arm laid along the Plough's guards to the pole star, over hills at the foot of the
    /// sky; the pole star in the second ink.
    static func plate81() -> Plate {
        var plate = Plate()
        let c = P(-0.16, 0.16), pole = P(0.36, -0.74)
        let outer = arc(c, 0.44)
        let hills = [P(-1.1, 0.78), P(-0.7, 0.7), P(-0.42, 0.76), P(-0.1, 0.84), P(0.25, 0.74), P(0.55, 0.64),
                     P(0.8, 0.7), P(1.1, 0.6), P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.78)]
        let ridge = smooth(Array(hills.dropLast()), 12)
        let handle = smooth([P(-0.39, 0.5), P(-0.29, 0.56), P(-0.42, 0.74), P(-0.4, 0.9), P(-0.58, 0.92),
                             P(-0.56, 0.74), P(-0.5, 0.62)], 8)
        Kit.ground(&plate, angle: 0.25, around: [outer, ridge])

        // The Plough, its two guards in line with the pole star.
        let plough = [P(0.9, -0.12), P(0.78, -0.02), P(0.66, -0.05), P(0.54, -0.13), P(0.56, -0.32), P(0.38, -0.4), P(0.42, -0.58)]
        plate.lines(dashed(plough, on: 0.03, off: 0.025), fine)
        plate.lines(dashed([plough[6], pole], on: 0.015, off: 0.03), fine)
        for (k, p) in plough.enumerated() {
            let ray = star(p, k == 4 || k == 6 ? 0.05 : 0.04)
            plate.line(ray, 0.03, .bone)
            Kit.mass(&plate, ray)
        }
        for (k, p) in [P(-0.62, -0.62), P(-0.78, -0.2), P(-0.3, -0.84), P(0.08, -0.32), P(0.72, -0.56), P(0.84, 0.3),
                       P(-0.86, 0.18), P(0.12, -0.72), P(-0.5, -0.36)].enumerated() {
            let ray = star(p, 0.03 + 0.012 * Double(k % 3), points: 4, inner: 0.3, turn: 0.4 * Double(k))
            plate.line(ray, 0.022, .bone)
            Kit.mass(&plate, ray)
        }

        // The hills, ink, a road of bone over them.
        Kit.mass(&plate, ridge)
        plate.line(curve(P(-0.95, 0.92), P(0.1, 0.8), P(0.9, 0.86)), 0.014, .bone)

        // The handle.
        plate.line(handle, 0.05, .bone)
        Kit.mass(&plate, handle)
        plate.fill(arc(P(-0.49, 0.83), 0.035))
        plate.line(arc(P(-0.49, 0.83), 0.035), medium)
        plate.line(curve(P(-0.45, 0.6), P(-0.5, 0.7), P(-0.47, 0.78)), heavy, .bone)

        // The ring of months: ink, cut with its divisions and numbered in bone.
        plate.line(outer, 0.05, .bone)
        Kit.mass(&plate, outer)
        Kit.cut(&plate, arc(c, 0.37), edge: heavy)
        for k in 0..<72 {
            let a = 2 * .pi * Double(k) / 72
            if k % 6 == 0 {
                plate.line([polar(c, 0.3, a), polar(c, 0.44, a)], heavy, .bone)
                plate.line([polar(c, 0.3, a), polar(c, 0.37, a)], heavy)
            } else {
                plate.line([polar(c, k % 3 == 0 ? 0.33 : 0.35, a), polar(c, 0.37, a)], medium)
            }
        }
        for k in 1...12 {
            let a = Kit.clock(Double(k) - 0.5)
            plate.lines(Kit.numeral(roman(k), at: polar(c, 0.405, a), height: 0.04, turn: a + .pi / 2, squeeze: 0.7), heavy, .bone)
        }

        // The hour wheel, its teeth to be counted in the dark and its XII tooth long; hatched between its hours.
        let teeth: [P] = (0..<48).map { k in
            let a = Kit.clock(Double(k) / 4) - 0.04
            let r = k % 2 == 0 ? (k == 0 ? 0.35 : 0.29) : 0.245
            return polar(c, r, a)
        }
        Kit.cut(&plate, teeth + [teeth[0]], edge: heavy)
        plate.line(arc(c, 0.225), 0.016)
        plate.line(arc(c, 0.155), medium)
        for k in 0..<12 {
            let a = Kit.clock(Double(k))
            plate.lines(hatch([arc(c, 0.225, from: a + 0.1, to: a + 0.42) + arc(c, 0.155, from: a + 0.42, to: a + 0.1)],
                              angle: a + 0.9, gap: 0.02), fine)
            Kit.mass(&plate, Kit.band(polar(c, 0.155, a), polar(c, 0.225, a), 0.026))
        }

        // The arm, sighted along its edge from the pivot's hole to the pole star.
        let dir = simd_normalize(pole - c), side = P(-dir.y, dir.x)
        let tip = c + dir * 0.84
        let arm = [c - dir * 0.12 + side * 0.06, tip + side * 0.012, tip, c - dir * 0.12 - side * 0.06, c - dir * 0.12 + side * 0.06]
        plate.line(arm, 0.04, .bone)
        Kit.mass(&plate, arm)
        plate.line([c + dir * 0.13 - side * 0.01, tip - dir * 0.04], heavy, .bone)
        plate.lines(dashed([tip, pole - dir * 0.08], on: 0.02, off: 0.025), medium)
        Kit.cut(&plate, arc(c, 0.07), edge: 0.02)
        plate.fill(arc(c, 0.026), .black)
        plate.line(arc(c, 0.045), fine)

        // The pole star.
        let polaris = star(pole, 0.075, points: 8, inner: 0.36, turn: -.pi / 2)
        plate.line(polaris, 0.03, .bone)
        plate.fill(polaris, .second)
        plate.line(polaris, fine)

        callout(&plate, "A", from: polar(c, 0.4, Kit.clock(8.6)), to: P(-0.74, -0.08))
        callout(&plate, "B", from: polar(c, 0.24, Kit.clock(4.5)), to: P(0.4, 0.46))
        callout(&plate, "C", from: c + dir * 0.6, to: P(-0.12, -0.6))
        callout(&plate, "D", from: P(-0.47, 0.66), to: P(-0.78, 0.5))
        return plate
    }

    /// A star pointer's flame on an astrolabe's rete: a curved blade from `base` to its tip at `tip`.
    private static func pointer(_ base: P, _ tip: P, width w: Double, bend: Double = 0.3) -> [P] {
        let d = tip - base, n = simd_normalize(P(-d.y, d.x))
        let mid = base + 0.5 * d + n * bend * simd_length(d) * 0.5
        let left = curve(base + n * w, mid + n * w * 0.5, tip, 12)
        let right = curve(tip, mid - n * w * 0.3, base - n * w, 12)
        return left + right.dropFirst() + [left[0]]
    }

    /// Problem 82, Astrolabe, hex, clocks 1-: an astrolabe's face hung from its throne. Its limb in ink with the hours,
    /// the plate's tropics and almucantars ruled under, the sky below the horizon shaded, and over them the pierced
    /// rete in bold ink, its ecliptic ring and star pointers, with the rule across; one star pointer in the second ink.
    static func plate82() -> Plate {
        var plate = Plate()
        let o = Kit.origin, limb = 0.74, tropic = 0.6, cancer = 0.26, equator = 0.4
        let throne = smooth([P(-0.2, -0.7), P(-0.17, -0.8), P(-0.08, -0.82), P(-0.05, -0.88), P(0.05, -0.88), P(0.08, -0.82),
                             P(0.17, -0.8), P(0.2, -0.7)], 6)
        Kit.ground(&plate, angle: 0.6, around: [arc(o, limb + 0.01), throne])

        // The throne and its shackle.
        Kit.solid(&plate, throne, angle: 1.2, gap: 0.03, width: medium, edge: 0.028)
        for x in [-0.1, 0.1] { Kit.mass(&plate, arc(P(x, -0.77), 0.03)); plate.fill(arc(P(x, -0.77), 0.012)) }
        Kit.mass(&plate, Kit.band(P(0, -0.84), P(0, -0.74), 0.03))
        plate.line(arc(P(0, -0.92), 0.05), 0.03)
        Kit.mass(&plate, box(P(-0.025, -0.9), P(0.025, -0.86)))

        // The limb: ink, its degrees cut and the hours twice round.
        Kit.mass(&plate, arc(o, limb))
        Kit.cut(&plate, arc(o, 0.71), edge: heavy)
        for k in 0..<72 {
            let a = Double(k) * .pi / 36
            plate.line([polar(o, 0.71, a), polar(o, limb, a)], k % 3 == 0 ? 0.014 : medium, .bone)
        }
        for k in 0..<24 {
            let a = -.pi / 2 + Double(k) * .pi / 12
            Kit.mass(&plate, Kit.band(polar(o, 0.62, a), polar(o, 0.7, a), 0.014))
            let b = a + .pi / 24
            plate.lines(Kit.numeral(roman(k % 12 + 1), at: polar(o, 0.66, b), height: 0.04, turn: b + .pi / 2, squeeze: 0.66), heavy)
        }
        plate.line(arc(o, 0.62), heavy)

        // The plate: the sky below the horizon shaded, the tropics and almucantars ruled.
        let alts: [(top: Double, bottom: Double)] = (0...5).map { k in (-0.56 + 0.06 * Double(k), 0.5 - 0.13 * Double(k)) }
        let horizon = arc(P(0, (alts[0].top + alts[0].bottom) / 2), (alts[0].bottom - alts[0].top) / 2)
        plate.lines(hatch([arc(o, tropic), horizon], angle: 0.6, gap: Kit.groundGap), Kit.groundWidth)
        for (k, alt) in alts.enumerated() {
            let ring = arc(P(0, (alt.top + alt.bottom) / 2), (alt.bottom - alt.top) / 2)
            var run: [P] = []
            for p in ring {
                if simd_length(p) < tropic { run.append(p) } else if run.count > 1 { plate.line(run, k == 0 ? 0.016 : fine); run = [] } else { run = [] }
            }
            if run.count > 1 { plate.line(run, k == 0 ? 0.016 : fine) }
        }
        for r in [cancer, equator] { plate.line(arc(o, r), medium) }
        plate.line(arc(o, tropic), heavy)
        plate.line([P(-tropic, 0), P(tropic, 0)], fine)
        plate.line([P(0, -tropic), P(0, tropic)], fine)

        // The rete: its rim, the ecliptic ring cut with the signs, bars and star pointers.
        let ecliptic = P(0, -(tropic - cancer) / 2), er = (tropic + cancer) / 2
        // Turned a little off the meridian, as it stands at some hour of the night.
        let turn = -Double.pi / 6
        var rete = Plate()
        Kit.mass(&rete, Kit.ribbon(arc(o, tropic - 0.02, from: 0.35, to: .pi - 0.35), 0.04))
        let bars: [[P]] = [
            curve(polar(o, tropic - 0.02, 0.35), P(0.42, 0.06), polar(ecliptic, er, 0.12)),
            curve(polar(o, tropic - 0.02, .pi - 0.35), P(-0.42, 0.06), polar(ecliptic, er, .pi - 0.12)),
            curve(P(0, tropic - 0.03), P(0.04, 0.38), P(0, cancer + 0.02)),
            curve(polar(ecliptic, er, -0.9), P(0.12, -0.12), P(0.03, -0.03)),
            curve(polar(ecliptic, er, -2.24), P(-0.12, -0.12), P(-0.03, -0.03)),
            curve(P(-0.3, equator - 0.12), P(0, equator + 0.04), P(0.3, equator - 0.12)),
        ]
        for bar in bars { Kit.mass(&rete, Kit.ribbon(bar, 0.04)) }
        Kit.mass(&rete, Kit.ribbon(arc(ecliptic, er), 0.06))
        for k in 0..<36 {
            let a = Double(k) * .pi / 18
            rete.line([polar(ecliptic, er - (k % 3 == 0 ? 0.028 : 0.005), a), polar(ecliptic, er + 0.028, a)], k % 3 == 0 ? heavy : medium, .bone)
        }
        let stars: [(base: P, tip: P, bend: Double)] = [
            (polar(ecliptic, er, -1.25), P(0.34, -0.47), 0.4), (polar(ecliptic, er, -1.95), P(-0.36, -0.46), -0.4),
            (polar(ecliptic, er, 2.6), P(-0.5, 0.0), 0.3), (polar(ecliptic, er, 0.55), P(0.5, 0.0), -0.3),
            (P(0.3, 0.28), P(0.4, 0.4), 0.4), (P(-0.3, 0.28), P(-0.42, 0.38), -0.4),
            (P(0.02, 0.48), P(0.12, 0.53), 0.5), (P(-0.02, 0.33), P(-0.14, 0.46), -0.3),
            (P(0.06, -0.1), P(0.14, -0.2), 0.3), (P(-0.06, -0.1), P(-0.1, -0.21), -0.3),
        ]
        for st in stars {
            Kit.mass(&rete, pointer(st.base, st.tip, width: 0.026, bend: st.bend * 0.4))
            rete.fill(arc(st.tip, 0.012), .bone)
            rete.line(arc(st.tip, 0.012), fine)
        }
        plate.marks += rete.marks.map { Mark(points: turned($0.points, by: turn), width: $0.width, ink: $0.ink) }
        let centre = turned([ecliptic], by: turn)[0], from = polar(centre, er - 0.035, -0.47)
        let named = pointer(from, P(0.13, -0.26), width: 0.028, bend: 0.2)
        plate.line(named, 0.026, .bone)
        plate.fill(named, .second)
        plate.line(named, fine)
        plate.fill(arc(P(0.13, -0.26), 0.012))
        plate.line(arc(P(0.13, -0.26), 0.012), fine)

        // The rule across the face, and the pin.
        let ruleA = polar(o, limb - 0.02, Kit.clock(4.3)), ruleB = polar(o, limb - 0.02, Kit.clock(10.3))
        let rule = Kit.band(ruleA, ruleB, 0.07)
        plate.line(rule, 0.03, .bone)
        Kit.solid(&plate, rule, angle: Kit.clock(4.3) + 0.9, gap: 0.03, edge: heavy)
        plate.line([ruleA, ruleB], 0.016)
        Kit.cut(&plate, arc(o, 0.055), edge: 0.016)
        plate.fill(arc(o, 0.02), .black)

        callout(&plate, "A", from: polar(o, 0.7, Kit.clock(7.5)), to: P(-0.74, 0.6))
        callout(&plate, "B", from: polar(ecliptic, er, 0.2), to: P(0.84, 0.18))
        callout(&plate, "C", from: polar(o, 0.5, Kit.clock(4.3)), to: P(0.62, 0.72))
        callout(&plate, "D", from: P(0.17, -0.78), to: P(0.4, -0.84))
        return plate
    }

    /// Problem 83, Night watch, hex, clocks 1-.
    static func plate83() -> Plate? { nil }

    /// Problem 84, Small hours, hex, clocks 1-.
    static func plate84() -> Plate? { nil }
}
