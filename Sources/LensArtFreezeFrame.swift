// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 44 to 49, the chapter Freeze frame.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let freezeFrame: [Int: Halftone.Panel] = [44: handmirror, 45: rearview, 46: convexmirror]

    /// A hex rod's core, which a lens magnifies and a twist turns rigidly.
    fileprivate static let core = 0.264

    /// A lens's glass and its frame: the core a flat tone, and round it out to `outer` a band whose tone changes along
    /// its length, each of `tones` from its angle in `at` (degrees, ascending, 0 at three o'clock and clockwise) to the
    /// next, the last running on past 360 to the first.
    fileprivate struct Rim: Sendable {
        var centre: P
        var glass: Tone
        var outer: Double
        var at: [Double]
        var tones: [Tone]

        func tone(_ p: P) -> Tone? {
            let d = p - centre, r2 = simd_length_squared(d)
            guard r2 < outer * outer else { return nil }
            if r2 < LensArt.core * LensArt.core { return glass }
            var a = atan2(d.y, d.x) * 180 / .pi
            if a < 0 { a += 360 }
            var t = tones[tones.count - 1]
            for (k, from) in at.enumerated() where from <= a { t = tones[k] }
            return t
        }
    }

    /// A frame of `n` even lengths taking `tones` in turn, the first from `from` degrees.
    fileprivate static func turns(_ n: Int, _ tones: [Tone], from: Double = 0) -> (at: [Double], tones: [Tone]) {
        let step = 360 / Double(n)
        return ((0..<n).map { from + step * Double($0) }, (0..<n).map { tones[$0 % tones.count] })
    }

    fileprivate static func rim(_ c: P, glass: Tone, outer: Double, _ frame: (at: [Double], tones: [Tone])) -> Rim {
        Rim(centre: c, glass: glass, outer: outer, at: frame.at, tones: frame.tones)
    }

    /// A long line as strokes of `n` segments each, so each stroke's box stays tight and the bake tests few segments a
    /// pixel.
    fileprivate static func pieces(_ line: [P], _ width: Double, every n: Int = 6) -> [Halftone.Stroke] {
        stride(from: 0, to: line.count - 1, by: n).map { stroke(Array(line[$0...min($0 + n, line.count - 1)]), width) }
    }

    /// A panel whose `over` fills lie on top of its lenses' rims, and its `fills` under them, over `ground`.
    fileprivate static func framed(_ name: String, rims: [Rim], over: [Fill] = [], fills: [Fill], strokes: [Halftone.Stroke],
                                   ground: @escaping @Sendable (P) -> Tone) -> Halftone.Panel {
        Halftone.Panel(name: name, tones: { p in
            for f in over where f.holds(p) { return f.tone }
            for r in rims { if let t = r.tone(p) { return t } }
            for f in fills where f.holds(p) { return f.tone }
            return ground(p)
        }, strokes: strokes)
    }
}

// MARK: - 44: Hand mirror

/// Level 44's name: a gilt hand mirror laid on a velvet tray, its glass over the top core and its handle down to the
/// lower left, a tassel on its end; an open powder compact to the right, its mirror over the upper right core and its
/// pan of pink powder, the puff on it, hinged below; a round pocket mirror in striped enamel over the bottom core (hex's
/// three lenses on this level); a scent bottle, a lipstick, a comb and a string of pearls about them. In the hand
/// mirror an eye looks back, in the compact a pair of lips, and in the pocket mirror a ribbon's bow.
extension LensArt {
    static let handmirror: Halftone.Panel = {
        let glass = P(0, -0.56), lid = P(0.485, -0.28), pocket = P(0, 0.56)
        let along = polar(P(0, 0), 1, 115), across = P(-along.y, along.x)
        let neck = glass + along * 0.3, end = glass + along * 1.0
        let handle = [neck + across * 0.04, end + across * 0.06, end - across * 0.06, neck - across * 0.04]
        let finial = end + along * 0.04
        let hinge = polar(lid, 0.3, 62), pan = polar(lid, 0.6, 62), clasp = polar(lid, 0.33, 242)
        let lipstick = bar(P(0.08, 0.24), P(0.27, 0.11), 0.075), bullet = [P(0.25, 0.085), P(0.33, 0.03), P(0.36, 0.075), P(0.3, 0.14)]
        let comb = bar(P(-0.8, -0.34), P(-0.3, -0.5), 0.075)
        let tassel = [P(-0.6, 0.5), P(-0.55, 0.5), P(-0.5, 0.66), P(-0.66, 0.68)]
        let puff = P(0.03, 0.05) + pan
        let bottle = squircle(P(0.09, -0.04), 0.1, 0.085, degrees: -8), stopper = P(0.075, -0.16)

        let gold = y(0.9), deep = Tone(0, 0.5, 0.4), cloth = c(0.2)
        // Each lens's frame: the hand mirror's gilt in lobes of uneven length, the compact's gold and red enamel, the
        // pocket mirror's enamel in stripes.
        let lobes = [0.0, 20, 52, 70, 104, 128, 150, 181, 200, 236, 255, 290, 312, 340]
        let rims = [
            Rim(centre: glass, glass: Tone(0.32, 0.32, 0), outer: 0.335, at: lobes, tones: lobes.indices.map { $0 % 2 == 0 ? gold : deep }),
            rim(lid, glass: y(0.42), outer: 0.31, turns(12, [m(0.85), y(0.9)], from: 2)),
            rim(pocket, glass: m(0.32), outer: 0.32, turns(10, [c(0.95), Tone(0.45, 0.45, 0.45)], from: 5)),
        ]
        let knuckles = bar(polar(hinge, 0.07, -28), polar(hinge, 0.07, 152), 0.05)
        let over = [fill(knuckles, deep)]
        let fills = [fill(handle, gold), disc(finial, 0.06, deep), fill(tassel, m(0.85)),
                     oval(puff, 0.11, 0.085, Tone(0.3, 0.3, 0.35)), disc(pan, 0.24, m(0.7)), disc(pan, 0.29, gold),
                     disc(stopper, 0.04, m(0.8)), fill(bottle, c(0.7)),
                     fill(bullet, m(0.95)), fill(lipstick, gold), fill(comb, deep)]

        var s: [Halftone.Stroke] = []
        // The velvet's nap.
        for (k, y0) in [-0.86, -0.12, 0.3, 0.82].enumerated() {
            let bend = k % 2 == 0 ? 0.08 : -0.06
            s.append(stroke(curve(P(-1, y0), P(0, y0 + bend), P(1, y0 - 0.04), 20), hair))
        }
        // The hand mirror: its frame's edges, a bead at each join of the lobes, a crest at the top, the handle and its ribs,
        // the finial and its tassel, and two streaks of light on the glass.
        s += pieces(circle(glass, core, 64), mid)
        s += pieces(circle(glass, 0.335, 64), bold)
        for a in lobes { s.append(stroke(circle(polar(glass, 0.3, a), 0.011, 6), hair)) }
        let crest = polar(glass, 0.36, -90)
        s.append(stroke(curve(crest + P(-0.1, 0.03), crest + P(-0.06, -0.06), crest, 8) + curve(crest, crest + P(0.06, -0.06), crest + P(0.1, 0.03), 8), mid))
        s.append(stroke(closed(handle), bold))
        for t in [0.42, 0.5, 0.78, 0.86] { s.append(stroke([glass + along * t + across * 0.045, glass + along * t - across * 0.045], hair)) }
        s.append(stroke(circle(finial, 0.06, 16), bold))
        s.append(stroke(curve(finial + P(-0.03, 0.05), P(-0.62, 0.44), P(-0.575, 0.5), 8), mid))
        s.append(stroke(closed(tassel), mid))
        for x in [-0.6, -0.57, -0.54] { s.append(stroke([P(x, 0.53), P(x + (x + 0.57) * 0.6, 0.66)], hair)) }
        s.append(stroke([glass + P(-0.2, 0.02), glass + P(-0.08, -0.16)], hair))
        s.append(stroke([glass + P(-0.17, 0.08), glass + P(-0.04, -0.12)], hair))
        // The eye in it: lids, iris and pupil, lashes and the brow.
        let eye = glass + P(0.024, -0.028)
        let upper = curve(eye + P(-0.036, 0.002), eye + P(0, -0.03), eye + P(0.036, 0.002), 10)
        s.append(stroke(upper, 0.004))
        s.append(stroke(curve(eye + P(-0.036, 0.002), eye + P(0, 0.024), eye + P(0.036, 0.002), 10), 0.003))
        s.append(stroke(circle(eye + P(0.002, -0.001), 0.011, 12), 0.003))
        s.append(stroke(circle(eye + P(0.002, -0.001), 0.003, 6), 0.004))
        for k in 2...8 { s.append(stroke([upper[k], upper[k] + P(0.0025 * Double(k - 5), -0.009)], 0.002)) }
        s.append(stroke(curve(eye + P(-0.038, -0.024), eye + P(0, -0.048), eye + P(0.042, -0.026), 10), 0.003))
        // The compact: the lid's edges, its clasp, the hinge's knuckle, the pan's case and its powder's pressed rose, the
        // puff, and the lips in the lid's mirror.
        s += pieces(circle(lid, core, 64), mid)
        s += pieces(circle(lid, 0.31, 64), bold)
        s += pieces(circle(pan, 0.29, 56), bold)
        s += pieces(circle(pan, 0.24, 48), mid)
        s.append(stroke(closed(knuckles), mid))
        for t in [-0.025, 0.025] { s.append(stroke([polar(hinge, t, -28) + polar(P(0, 0), 0.025, 62), polar(hinge, t, -28) - polar(P(0, 0), 0.025, 62)], hair)) }
        s.append(stroke(closed(rect(clasp.x - 0.03, clasp.y - 0.03, clasp.x + 0.03, clasp.y + 0.01)), mid))
        for k in 0..<5 { s.append(stroke(arc(pan + P(-0.07, -0.02), 0.03 + 0.022 * Double(k), 200 + 15 * Double(k), 330 + 20 * Double(k), 10), hair)) }
        s += pieces(ellipse(puff, 0.11, 0.085, 28), bold)
        s.append(stroke(closed(bar(puff + P(-0.03, -0.02), puff + P(0.04, -0.03), 0.025)), mid))
        let lips = lid + P(0.026, -0.022)
        s.append(stroke(curve(lips + P(-0.036, 0.004), lips + P(-0.02, -0.022), lips + P(0, -0.008), 8)
            + curve(lips + P(0, -0.008), lips + P(0.02, -0.022), lips + P(0.036, 0.004), 8), 0.0036))
        s.append(stroke(curve(lips + P(-0.036, 0.004), lips + P(0, 0.034), lips + P(0.036, 0.004), 12), 0.0036))
        s.append(stroke(curve(lips + P(-0.03, 0.004), lips + P(0, 0.012), lips + P(0.03, 0.004), 8), 0.002))
        s.append(stroke(arc(lips + P(0.012, 0.016), 0.006, 200, 320, 5), 0.0016))
        // The scent bottle and its facets, the lipstick and the comb.
        s.append(stroke(closed(bottle), bold))
        s.append(stroke(circle(stopper, 0.04, 14), mid))
        s.append(stroke([P(0.02, -0.1), P(0.06, 0.02), P(0.16, 0.0)], hair))
        s.append(stroke(closed(lipstick), bold))
        s.append(stroke(closed(bullet), mid))
        s.append(stroke([P(0.2, 0.135), P(0.25, 0.2)], hair))
        s.append(stroke(closed(comb), bold))
        for k in 0..<22 {
            let at = P(-0.8, -0.34) + P(0.5, -0.16) * (0.06 + 0.04 * Double(k))
            s.append(stroke([at + P(0.01, 0.033), at + P(0.024, 0.075)], 0.0035))
        }
        // The pearls, dropped across the handle.
        for q in curve(P(0.02, 0.2), P(-0.2, 0.32), P(-0.26, 0.06), 14).dropLast() { s.append(stroke(circle(q, 0.017, 8), mid)) }
        // The pocket mirror: its enamel band's edges, a loop for its chain, and the bow in its glass.
        s += pieces(circle(pocket, core, 64), mid)
        s += pieces(circle(pocket, 0.32, 64), bold)
        s.append(stroke(circle(polar(pocket, 0.36, 300), 0.04, 12), mid))
        let bow = pocket + P(-0.022, -0.028)
        for side in [-1.0, 1.0] {
            s.append(stroke(closed([bow + P(side * 0.006, -0.002), bow + P(side * 0.036, -0.02), bow + P(side * 0.04, 0.012)]), 0.0036))
            s.append(stroke([bow + P(side * 0.004, 0.006), bow + P(side * 0.02, 0.04), bow + P(side * 0.026, 0.032)], 0.003))
        }
        s.append(stroke(circle(bow, 0.007, 8), 0.004))
        return framed("handmirror", rims: rims, over: over, fills: fills, strokes: s) { _ in cloth }
    }()
}

// MARK: - 45: Rear-view mirror

/// Level 45's name: the road at dusk from behind the wheel of an old car, its rear-view mirror on its stem over the top
/// core, its wing mirror out past the windscreen's pillar over the lower right, and a compass ball on the leather dash
/// over the hub (hex's three lenses on this level). In the rear-view mirror a car follows, its headlamps glaring; in
/// the wing mirror a cyclist keeps up; under the compass's glass its needle points north.
extension LensArt {
    static let rearview: Halftone.Panel = {
        let back = P(0, -0.56), wing = P(0.485, 0.28), ball = P(0, 0), horizon = -0.05, sun = P(-0.3, horizon)
        let wheel = P(-0.45, 0.95)
        let right = bar(P(0.66, -1.05), P(0.2, 0.34), 0.12), left = bar(P(-0.6, -1.05), P(-0.95, 0.34), 0.12)
        let road = [P(-0.14, horizon), P(0.3, 0.4), P(-0.95, 0.4)], housing = squircle(back, 0.46, 0.3)
        let foot = [P(-0.12, 0.3), P(0.12, 0.3), P(0.17, 0.4), P(-0.17, 0.4)]
        let stem = bar(P(0, -1.02), P(0, -0.86), 0.06), arm = bar(polar(wing, 0.3, 160), P(0.18, 0.42), 0.07)
        let spokes = [-50.0, -140].map { bar(wheel, polar(wheel, 0.47, $0), 0.06) }
        let gauges = [(P(0.2, 0.5), 0.075), (P(0.11, 0.7), 0.055)]
        let dash: @Sendable (Double) -> Double = { x in 0.3 + 0.05 * x * x }

        let chrome = Tone(0.55, 0.55, 0.6), shade = Tone(0.06, 0.04, 0.16), paint = c(0.85)
        // The frames: the rear-view mirror's chrome catching the light in uneven lengths, the wing mirror's paint with
        // the arm's dark root and an amber lamp, the compass's bezel in eighths.
        let shine = [0.0, 35, 60, 110, 140, 200, 230, 290, 320]
        let rims = [
            Rim(centre: back, glass: c(0.5), outer: 0.33, at: shine, tones: shine.indices.map { $0 % 2 == 0 ? chrome : shade }),
            Rim(centre: wing, glass: m(0.4), outer: 0.33, at: [0, 140, 215, 285, 350], tones: [paint, shade, paint, y(0.95), paint]),
            rim(ball, glass: y(0.45), outer: 0.32, turns(8, [c(0.75), shade], from: 22.5)),
        ]
        var fills = [fill(stem, shade), fill(arm, shade), fill(foot, shade), fill(housing, Tone(0.12, 0.08, 0.3))]
        fills += gauges.map { disc($0.0, $0.1, c(0.65)) }
        fills += spokes.map { fill($0, y(0.8)) } + [ring(wheel, 0.46, 0.55, y(0.8))]
        fills += [fill(right, .zero), fill(left, .zero), disc(sun, 0.13, y(0.95)), fill(road, .zero)]

        var s: [Halftone.Stroke] = []
        // The land: the horizon either side of the sun, a far line of poles, the road and its centre line, and birds.
        let clear: @Sendable (P) -> Bool = { p in
            simd_distance(p, back) > 0.33 && !inside(p, housing) && simd_distance(p, wing) > 0.33 && simd_distance(p, ball) > 0.32
        }
        s += runs(span(P(-1, horizon), P(1, horizon), 80), mid) { clear($0) && simd_distance($0, sun) > 0.13 }
        s.append(stroke(arc(sun, 0.13, 180, 360, 20), mid))
        for k in 0..<3 { s.append(stroke([sun + P(-0.2 + 0.06 * Double(k), 0.04 + 0.03 * Double(k)), sun + P(0.2 - 0.05 * Double(k), 0.04 + 0.03 * Double(k))], hair)) }
        for x in [0.62, 0.72, 0.8, 0.86] {
            let h = 0.03 + 0.1 * (x - 0.6)
            s.append(stroke([P(x, horizon), P(x, horizon - h)], hair))
            s.append(stroke([P(x - 0.012, horizon - h + 0.008), P(x + 0.012, horizon - h + 0.008)], hair))
        }
        s += runs(span(road[0], road[1], 30), mid) { clear($0) }
        s += runs(span(road[0], road[2], 30), mid) { clear($0) }
        for at in [P(-0.38, -0.36), P(0.3, -0.24), P(0.52, -0.5)] {
            s.append(stroke(curve(at + P(-0.05, 0), at + P(-0.025, -0.035), at, 5) + curve(at, at + P(0.025, -0.035), at + P(0.05, 0), 5), mid))
        }
        // The car: the pillars' edges, the dash and its two gauges, the wheel's rim and spokes.
        for b in [right, left] { s.append(stroke([b[0], b[1]], mid)); s.append(stroke([b[3], b[2]], mid)) }
        s += runs((0...40).map { P(-1 + 0.05 * Double($0), dash(-1 + 0.05 * Double($0))) }, bold) { clear($0) }
        for (at, r) in gauges {
            s.append(stroke(circle(at, r, 20), mid))
            for k in 0..<7 { s.append(stroke([polar(at, r * 0.7, 150 + 40 * Double(k)), polar(at, r * 0.92, 150 + 40 * Double(k))], hair)) }
            s.append(stroke([at, polar(at, r * 0.8, 200 + 160 * r)], mid))
        }
        s += pieces(arc(wheel, 0.55, 180, 360, 40), bold)
        s += pieces(arc(wheel, 0.46, 180, 360, 36), mid)
        for b in spokes { s.append(stroke(closed(b), mid)) }
        // The rear-view mirror: its frame's edges, stem and mount, and in its glass the car behind, lamps glaring, on the
        // road that falls away behind.
        s += pieces(circle(back, core, 64), mid)
        s += pieces(circle(back, 0.33, 64), bold)
        s.append(stroke(closed(stem), mid))
        s += pieces(closed(housing), bold)
        s.append(stroke(closed(foot), mid))
        s.append(stroke(closed(rect(-0.07, -0.99, 0.07, -0.94)), mid))
        let car = back + P(0.024, -0.026)
        s.append(stroke(closed([car + P(-0.018, -0.026), car + P(0.018, -0.026), car + P(0.03, -0.006), car + P(0.035, 0.018), car + P(-0.035, 0.018), car + P(-0.03, -0.006)]), 0.0036))
        s.append(stroke([car + P(-0.03, -0.006), car + P(0.03, -0.006)], 0.0024))
        for side in [-1.0, 1.0] {
            let lamp = car + P(side * 0.021, 0.007)
            s.append(stroke(circle(lamp, 0.006, 8), 0.004))
            for t in [-30.0, 0, 30] { s.append(stroke([lamp + P(side * 0.009, 0), polar(lamp, 0.022, side > 0 ? t : 180 - t)], 0.0018)) }
        }
        s.append(stroke([car + P(-0.008, 0.012), car + P(0.008, 0.012)], 0.002))
        s.append(stroke([car + P(-0.03, 0.018), back + P(-0.09, 0.12)], 0.0024))
        s.append(stroke([car + P(0.03, 0.018), back + P(0.14, 0.11)], 0.0024))
        // The wing mirror: its frame's edges and arm, and in its glass a cyclist.
        s += pieces(circle(wing, core, 64), mid)
        s += pieces(circle(wing, 0.33, 64), bold)
        s.append(stroke(closed(arm), mid))
        let bike = wing + P(-0.02, -0.018)
        for x in [-0.024, 0.024] { s.append(stroke(circle(bike + P(x, 0.012), 0.014, 14), 0.003)) }
        s.append(stroke([bike + P(-0.024, 0.012), bike + P(-0.004, -0.012), bike + P(0.016, -0.012), bike + P(0.024, 0.012)], 0.0024))
        s.append(stroke([bike + P(-0.004, -0.012), bike + P(0.002, 0.012), bike + P(-0.024, 0.012)], 0.0024))
        s.append(stroke([bike + P(-0.004, -0.018), bike + P(0.01, -0.038), bike + P(0.018, -0.016)], 0.003))
        s.append(stroke(circle(bike + P(0.016, -0.048), 0.007, 8), 0.003))
        s.append(stroke([bike + P(-0.004, -0.018), bike + P(0.012, -0.002), bike + P(0.002, 0.012)], 0.0024))
        // The compass ball: its bezel's edges, the card's degrees, and its needle and north.
        s += pieces(circle(ball, core, 64), mid)
        s += pieces(circle(ball, 0.32, 64), bold)
        for k in 0..<24 { s.append(stroke([polar(ball, k % 6 == 0 ? 0.17 : 0.2, 15 * Double(k) + 7), polar(ball, 0.235, 15 * Double(k) + 7)], k % 6 == 0 ? mid : hair)) }
        let pivot = ball + P(0.026, -0.012)
        s.append(stroke(closed([pivot + P(-0.012, -0.056), pivot + P(0.009, 0.0), pivot + P(0.012, 0.05), pivot + P(-0.009, 0.0)]), 0.0036))
        s.append(stroke([pivot + P(-0.012, -0.056), pivot + P(0.0, 0.0)], 0.0024))
        s.append(stroke(circle(pivot, 0.005, 8), 0.003))
        let north = pivot + P(-0.018, -0.082)
        s.append(stroke([north + P(-0.008, 0.01), north + P(-0.008, -0.01), north + P(0.008, 0.01), north + P(0.008, -0.01)], 0.003))
        return framed("rearview", rims: rims, fills: fills, strokes: s) { p in
            p.y < horizon ? Tone(0, 0.35, 0.55) : p.y < dash(p.x) ? c(0.32) : m(0.45)
        }
    }()
}

// MARK: - 46: Convex mirror

/// Level 46's name: a mountain road coming down in hairpins under snowy peaks, a round convex mirror on a post at each
/// blind bend, over the upper right, bottom and lower left cores (hex's three lenses on this level), each rimmed in
/// orange and red with its hood over the top. Each shows what is coming round its bend, bowed by the glass, the road
/// curving round it: a bus, a hiker with her stick, and a goat.
extension LensArt {
    static let convexmirror: Halftone.Panel = {
        let mirrors = [P(0.485, -0.28), P(0, 0.56), P(-0.485, 0.28)]
        let bends = [P(-1.05, -0.45), P(0.12, -0.36), P(-0.18, -0.02), P(0.66, 0.38), P(0.3, 0.98)]
        let road = zip(bends, bends.dropFirst()).map { bar($0, $1, 0.11) }
        let peaks = [P(-1, -0.42), P(-0.7, -0.7), P(-0.5, -0.56), P(-0.12, -0.92), P(0.2, -0.6), P(0.42, -0.78), P(0.9, -0.42), P(1, -0.42)]
        let snow = [[P(-0.22, -0.8), P(-0.12, -0.92), P(-0.02, -0.8), P(-0.08, -0.82), P(-0.12, -0.77), P(-0.16, -0.82)],
                    [P(0.36, -0.71), P(0.42, -0.78), P(0.5, -0.69), P(0.45, -0.7), P(0.41, -0.66)]]
        let pines = [P(-0.62, -0.2), P(-0.78, -0.16), P(0.34, 0.12), P(0.8, 0.1), P(-0.32, 0.52), P(0.62, 0.7)]
        let tunnel = P(0.84, 0.4)

        let orange = Tone(0, 0.55, 1), red = m(0.95), white = Tone(0.55, 0.55, 0.55), hood = Tone(0.05, 0.05, 0.12), grass = Tone(0.35, 0, 0.45)
        // Each mirror's rim in orange and red, the hood dark over its top.
        let rims = mirrors.map {
            Rim(centre: $0, glass: c(0.6), outer: 0.33, at: [0, 45, 90, 135, 180, 225, 315],
                tones: [red, orange, red, orange, red, hood, orange])
        }
        var fills = mirrors.map { fill(rect($0.x - 0.025, $0.y + 0.3, $0.x + 0.025, $0.y + 0.62), hood) }
        fills += pines.map { fill([$0 + P(0, -0.14), $0 + P(0.06, 0.02), $0 + P(-0.06, 0.02)], Tone(0.1, 0, 0.15)) }
        fills += [oval(tunnel, 0.12, 0.13, .zero)] + road.map { fill($0, .zero) } + bends.dropFirst().dropLast().map { disc($0, 0.055, .zero) }
        fills += snow.map { fill($0, white) } + [fill(peaks + [P(1, -0.4), P(-1, -0.4)], m(0.45))]

        var s: [Halftone.Stroke] = []
        // The peaks and their snow, the pines, and the tunnel's mouth.
        s += pieces(Array(peaks.dropFirst()), mid)
        for q in snow { s.append(stroke(closed(q), hair)) }
        for p in pines { s.append(stroke(closed([p + P(0, -0.14), p + P(0.06, 0.02), p + P(-0.06, 0.02)]), mid)); s.append(stroke([p + P(0, 0.02), p + P(0, 0.06)], mid)) }
        s += pieces(arc(tunnel, 0.12, 180, 360, 16) + [tunnel + P(0.12, 0.12), tunnel + P(-0.12, 0.12)] + [tunnel + P(-0.12, 0)], bold)
        for k in 0..<5 { s.append(stroke([polar(tunnel, 0.12, 190 + 40 * Double(k)), polar(tunnel, 0.16, 190 + 40 * Double(k))], hair)) }
        // The road: its edges, its centre line in dashes, and a barrier of posts round the outside of each hairpin.
        let clear: @Sendable (P) -> Bool = { p in mirrors.allSatisfy { simd_distance(p, $0) > 0.33 } }
        for (a, b) in zip(bends, bends.dropFirst()) {
            let n = simd_normalize(P(a.y - b.y, b.x - a.x)) * 0.055
            for side in [n, -n] { s += runs(span(a + side, b + side, 30), mid, keep: clear) }
            for k in 0..<8 {
                let t0 = (Double(k) + 0.2) / 8, t1 = (Double(k) + 0.6) / 8
                if clear(a + (b - a) * t0) && clear(a + (b - a) * t1) { s.append(stroke([a + (b - a) * t0, a + (b - a) * t1], hair)) }
            }
        }
        for (k, c) in bends.dropFirst().dropLast().enumerated() {
            let out = simd_normalize(c - (bends[k] + bends[k + 2]) / 2)
            let rail = (0...8).map { polar(c, 0.1, atan2(out.y, out.x) * 180 / .pi - 80 + 20 * Double($0)) }
            s.append(stroke(rail, mid))
            for q in rail { s.append(stroke([q, q + P(0, 0.03)], hair)) }
        }
        // The mirrors: their rims' edges, hoods and posts, and in each the road bowed round what is coming.
        for c in mirrors {
            s += pieces(circle(c, core, 64), mid)
            s += pieces(circle(c, 0.33, 64), bold)
            s.append(stroke(closed(rect(c.x - 0.025, c.y + 0.33, c.x + 0.025, c.y + 0.62)), mid))
            s += pieces(arc(c, 0.36, 220, 320, 12), bold)
            s.append(stroke(arc(c, 0.16, 20, 160, 16), hair))
            s.append(stroke(arc(c + P(0, -0.05), 0.12, 35, 145, 12), hair))
        }
        // A bus, bowed.
        let bus = mirrors[0] + P(0.012, -0.03)
        s.append(stroke(closed(curve(bus + P(-0.04, -0.012), bus + P(0, -0.028), bus + P(0.042, -0.012), 8) + [bus + P(0.046, 0.014)]
            + curve(bus + P(0.046, 0.014), bus + P(0, 0.024), bus + P(-0.046, 0.014), 8)), 0.0036))
        for k in 0..<4 { let x = -0.03 + 0.017 * Double(k); s.append(stroke(closed(rect(bus.x + x, bus.y - 0.014, bus.x + x + 0.011, bus.y - 0.002)), 0.002)) }
        for x in [-0.026, 0.028] { s.append(stroke(circle(bus + P(x, 0.022), 0.008, 10), 0.0034)) }
        // A hiker with her pack and stick.
        let hiker = mirrors[1] + P(-0.02, -0.03)
        s.append(stroke(circle(hiker + P(0, -0.034), 0.008, 10), 0.0034))
        s.append(stroke([hiker + P(0, -0.026), hiker + P(0.002, 0.008)], 0.0036))
        s.append(stroke(closed(rect(hiker.x - 0.016, hiker.y - 0.022, hiker.x - 0.003, hiker.y + 0.002)), 0.003))
        s.append(stroke([hiker + P(0.002, 0.008), hiker + P(-0.012, 0.036)], 0.003))
        s.append(stroke([hiker + P(0.002, 0.008), hiker + P(0.016, 0.034)], 0.003))
        s.append(stroke([hiker + P(0.001, -0.016), hiker + P(0.018, -0.004)], 0.0024))
        s.append(stroke([hiker + P(0.026, -0.022), hiker + P(0.02, 0.04)], 0.0024))
        // A goat: body, legs, head, horns and beard.
        let goat = mirrors[2] + P(0.018, -0.03)
        s.append(stroke(ellipse(goat, 0.028, 0.014, 20), 0.0036))
        for x in [-0.02, -0.01, 0.012, 0.022] { s.append(stroke([goat + P(x, 0.01), goat + P(x, 0.034)], 0.0026)) }
        s.append(stroke([goat + P(0.022, -0.008), goat + P(0.036, -0.03), goat + P(0.048, -0.022)], 0.003))
        s.append(stroke(curve(goat + P(0.034, -0.03), goat + P(0.026, -0.05), goat + P(0.014, -0.044), 6), 0.0026))
        s.append(stroke([goat + P(0.044, -0.022), goat + P(0.046, -0.01)], 0.002))
        s.append(stroke([goat + P(-0.028, -0.002), goat + P(-0.036, -0.012)], 0.0024))
        return framed("convexmirror", rims: rims, fills: fills, strokes: s) { p in p.y < -0.4 ? c(0.35) : grass }
    }()
}
