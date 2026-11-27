// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 44 to 49, the chapter Freeze frame.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let freezeFrame: [Int: Halftone.Panel] = [44: handmirror]

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
        s.append(stroke(circle(glass, core, 64), mid))
        s.append(stroke(circle(glass, 0.335, 64), bold))
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
        s.append(stroke(circle(lid, core, 64), mid))
        s.append(stroke(circle(lid, 0.31, 64), bold))
        s.append(stroke(circle(pan, 0.29, 56), bold))
        s.append(stroke(circle(pan, 0.24, 48), mid))
        s.append(stroke(closed(knuckles), mid))
        for t in [-0.025, 0.025] { s.append(stroke([polar(hinge, t, -28) + polar(P(0, 0), 0.025, 62), polar(hinge, t, -28) - polar(P(0, 0), 0.025, 62)], hair)) }
        s.append(stroke(closed(rect(clasp.x - 0.03, clasp.y - 0.03, clasp.x + 0.03, clasp.y + 0.01)), mid))
        for k in 0..<5 { s.append(stroke(arc(pan + P(-0.07, -0.02), 0.03 + 0.022 * Double(k), 200 + 15 * Double(k), 330 + 20 * Double(k), 10), hair)) }
        s.append(stroke(ellipse(puff, 0.11, 0.085, 28), bold))
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
        s.append(stroke(circle(pocket, core, 64), mid))
        s.append(stroke(circle(pocket, 0.32, 64), bold))
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
