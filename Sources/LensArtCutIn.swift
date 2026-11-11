// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 7 to 12, the second chapter.

// MARK: - 7: Binoculars

/// Level 7's name: field glasses from the front, tilted so their two big lenses lie over the top and lower right cores
/// (tri's two lenses on this level), a bird on its branch in one and its nest of eggs in the other. Level 7 deals the
/// top lens +2 and the other +1.
extension LensArt {
    static let binoculars: Halftone.Panel = {
        let a = P(0, -0.42), b = P(0.3637, 0.21), back = P(-0.3, 0.17), hinge = (a + b) / 2
        func barrel(_ c: P) -> [P] {
            let n = simd_normalize(P(-back.y, back.x))
            return [c + n * 0.3, c + back + n * 0.2, c + back - n * 0.2, c - n * 0.3]
        }
        var fills: [Fill] = []
        for c in [a, b] { fills += [disc(c, 0.27, c == a ? LensArt.c(0.3) : LensArt.c(0.22)), disc(c, 0.33, y(0.85))] }
        fills += [disc(hinge, 0.075, y(0.8)), fill(bar(a, b, 0.2), m(0.75))]
        for c in [a, b] { fills += [disc(c + back, 0.2, m(0.8)), fill(barrel(c), m(0.5))] }

        var s: [Halftone.Stroke] = []
        // Leaves about, and the strap looping off the far barrel.
        for (k, at) in [P(-0.8, -0.45), P(-0.62, -0.72), P(0.7, -0.6), P(0.86, -0.2), P(-0.1, 0.84), P(0.5, 0.78), P(-0.84, 0.3)].enumerated() {
            let t = 40.0 * Double(k) + 15, tip = polar(at, 0.13, t), root = polar(at, -0.13, t)
            s.append(stroke(curve(root, polar(at, 0.07, t + 90), tip, 10) + curve(tip, polar(at, 0.07, t - 90), root, 10), mid))
            s.append(stroke([root, tip], hair))
        }
        s.append(stroke(curve(a + back + P(-0.18, 0.06), P(-0.95, 0.5), P(-0.5, 0.74), 20) + curve(P(-0.5, 0.74), P(-0.2, 0.86), P(0.0, 0.56), 12), bold))
        // The barrels running back to the eyepieces, the bridge and its focus wheel.
        for c in [a, b] {
            let q = barrel(c)
            s.append(stroke([q[0], q[1]], bold))
            s.append(stroke([q[3], q[2]], bold))
            s += runs(circle(c + back, 0.2, 40), bold) { simd_distance($0, c) > 0.33 && simd_distance($0, a) > 0.33 }
            s += runs(circle(c + back, 0.13, 30), hair) { simd_distance($0, c) > 0.33 && simd_distance($0, a) > 0.33 }
            for k in 1..<4 {
                let t = Double(k) / 4, n = simd_normalize(P(-back.y, back.x)), w = 0.3 - 0.1 * t
                s += runs([c + back * t + n * w, c + back * t - n * w]) { simd_distance($0, c) > 0.33 }
            }
        }
        s.append(stroke(circle(hinge, 0.075, 24), bold))
        for k in 0..<8 { s.append(stroke([polar(hinge, 0.035, 45 * Double(k)), polar(hinge, 0.07, 45 * Double(k))], hair)) }
        for c in [a, b] {
            s.append(stroke(circle(c, 0.33, 64), bold))
            s.append(stroke(circle(c, 0.27, 64), mid))
            s.append(stroke(arc(c, 0.23, 195, 240, 10), mid))
        }
        // In the top glass: a bird on a branch, looking back. Body, head, beak, eye, wing, tail, legs.
        let bird = a + P(0.012, -0.05)
        s.append(stroke(curve(a + P(-0.22, 0.0), a + P(0, -0.035), a + P(0.22, 0.03), 12), 0.004))
        s.append(stroke(curve(a + P(-0.12, -0.014), a + P(-0.14, -0.06), a + P(-0.18, -0.07), 6), hair))
        s.append(stroke(ellipse(a + P(-0.185, -0.085), 0.02, 0.012, degrees: -30, 12), hair))
        s.append(stroke(ellipse(bird, 0.036, 0.026, degrees: 20, 20), 0.003))
        s.append(stroke(circle(bird + P(0.034, -0.03), 0.016, 14), 0.003))
        s.append(stroke([bird + P(0.049, -0.034), bird + P(0.066, -0.028), bird + P(0.048, -0.024)], 0.002))
        s.append(stroke(circle(bird + P(0.037, -0.033), 0.002, 6), 0.003))
        s.append(stroke(curve(bird + P(-0.022, -0.012), bird + P(0, 0.016), bird + P(0.018, -0.006), 8), 0.002))
        s.append(stroke([bird + P(-0.03, 0.01), bird + P(-0.068, 0.032), bird + P(-0.034, 0.018)], 0.002))
        for x in [-0.004, 0.012] { s.append(stroke([bird + P(x, 0.025), bird + P(x, 0.04)], 0.002)) }
        // In the other: the nest, woven, three eggs in it.
        let nest = b + P(0.0, 0.07)
        s.append(stroke(arc(nest + P(0, -0.03), 0.085, 10, 170, 16), 0.004))
        s.append(stroke([nest + P(-0.09, -0.02), nest + P(0.09, -0.02)], 0.003))
        for k in 0..<6 {
            let x = -0.06 + 0.024 * Double(k)
            s.append(stroke([nest + P(x, -0.015), nest + P(x + 0.02, 0.03 - abs(x) * 0.3)], hair))
            s.append(stroke([nest + P(x + 0.02, -0.015), nest + P(x, 0.03 - abs(x) * 0.3)], hair))
        }
        for (k, x) in [-0.045, 0.0, 0.045].enumerated() {
            s.append(stroke(ellipse(nest + P(x, -0.04 - (k == 1 ? 0.012 : 0)), 0.02, 0.027, degrees: 12 * Double(k - 1), 14).prefix(k == 1 ? 15 : 9) + [], 0.003))
        }
        s.append(stroke(curve(b + P(-0.2, 0.14), b + P(-0.1, 0.1), b + P(-0.09, 0.05), 6), 0.003))
        s.append(stroke(curve(b + P(0.2, 0.16), b + P(0.12, 0.1), b + P(0.09, 0.05), 6), 0.003))
        return panel("binoculars", fills: fills, strokes: s) { p in p.y > 0.3 * p.x + 0.42 ? Tone(0.3, 0, 0.3) : Tone(0.14, 0, 0.2) }
    }()
}

// MARK: - 8: Spectacles

/// Level 8's name: round spectacles laid across an open book, their glasses over the top and lower left cores (tri's
/// two lenses on this level), flat cyan, a bookworm in one and a pressed clover in the other. The print is set in
/// blocks of tone, a paragraph each, ragged at its ends, and a ribbon lies down the right page, so the rod that twists
/// turns shapes broad enough to read without the lines; the frames are tortoiseshell, so a twist that drags one shows
/// along it, and a lens's flat tone shows whole and round when it was dealt last, and bitten, its edge pulled out
/// across the page, under a twist. Level 8 deals each lens +3 in all.
extension LensArt {
    static let spectacles: Halftone.Panel = {
        // Each glass fills its core, so the frames, a core apart less than their width, run into each other at the bridge.
        let a = P(0, -0.42), b = P(-0.3637, 0.21), inner = 0.348, outer = 0.385
        let along = simd_normalize(a - b), across = P(-along.y, along.x)
        let worm = a + P(0.03, -0.04), clover = b + P(-0.026, -0.04)
        let picture = rect(-0.72, -0.62, -0.2, -0.2)
        let ribbon = bar(P(0.03, -0.9), P(0.22, 0.96), 0.08)
        // The print's blocks, as (x0, y0, x1, y1): a heading and the plate's caption on the left page, paragraphs on both.
        let blocks = [(-0.72, -0.82, -0.36, -0.72), (-0.6, -0.14, -0.3, -0.06), (-0.78, 0.02, -0.12, 0.2), (-0.78, 0.2, -0.4, 0.26),
                      (-0.7, 0.36, -0.12, 0.42), (-0.78, 0.42, -0.12, 0.62), (-0.78, 0.74, -0.3, 0.84),
                      (0.12, -0.82, 0.78, -0.64), (0.12, -0.64, 0.5, -0.58), (0.2, -0.46, 0.78, -0.4), (0.12, -0.4, 0.78, -0.16),
                      (0.12, 0.02, 0.78, 0.22), (0.12, 0.22, 0.42, 0.28), (0.2, 0.4, 0.78, 0.46), (0.12, 0.46, 0.78, 0.62),
                      (0.12, 0.74, 0.56, 0.84)]
        var fills = [disc(P(-0.52, -0.48), 0.075, y(0.85)), fill([P(-0.72, -0.2), P(-0.56, -0.44), P(-0.44, -0.3), P(-0.3, -0.46), P(-0.2, -0.2)], c(0.8)),
                     fill(picture, c(0.3))]
        // The frames are tortoiseshell, yellow let into the magenta an eighth of the way round at a time: a twist slides
        // a rim along itself, which only a rim that changes along its length shows.
        let frames = [a, b].flatMap { c in
            (0..<4).map { fill(sector(c, inner, outer, 90 * Double($0) + 20, 90 * Double($0) + 65), y(0.9)) } + [ring(c, inner, outer, m(0.8))]
        }
        fills += [fill(ribbon, Tone(0, 0.45, 0.9))]
        fills += blocks.map { fill(rect($0.0, $0.1, $0.2, $0.3), m(0.6)) }
        fills += [fill(rect(-0.86, -0.9, 0.86, 0.9), y(0.14)), fill(rect(-0.93, -0.96, 0.93, 0.96), m(0.4))]

        var s: [Halftone.Stroke] = []
        // The book: cover, pages, the gutter, and the lines of print in each block, parted where a clue sits.
        s.append(stroke(closed(rect(-0.86, -0.9, 0.86, 0.9)), mid))
        /// A line's runs clear of both glasses, each of its segments cut fine enough to stop at a frame.
        func clear(_ line: [P], _ width: Double) -> [Halftone.Stroke] {
            let fine = zip(line, line.dropFirst()).flatMap { span($0, $1, 24) }
            return runs(fine, width) { simd_distance($0, a) > outer && simd_distance($0, b) > outer }
        }
        s += clear([P(0, -0.9), P(0, 0.9)], mid)
        s += clear(curve(P(-0.06, -0.9), P(-0.02, 0), P(-0.06, 0.9), 12), hair)
        s += clear(curve(P(0.06, -0.9), P(0.02, 0), P(0.06, 0.9), 12), hair)
        for block in blocks {
            for yy in stride(from: block.1 + 0.03, to: block.3, by: 0.06) {
                s += runs(span(P(block.0 + 0.02, yy), P(block.2 - 0.02, yy), 44)) {
                    simd_distance($0, a) > outer && simd_distance($0, b) > outer && !inside($0, ribbon)
                }
            }
        }
        for edge in [(ribbon[0], ribbon[1]), (ribbon[3], ribbon[2])] { s += clear([edge.0, edge.1], mid) }
        // The plate on the left page: a hill, a sun.
        s += clear(closed(picture), mid)
        s += clear([P(-0.72, -0.2), P(-0.56, -0.44), P(-0.44, -0.3), P(-0.3, -0.46), P(-0.2, -0.2)], hair)
        s.append(stroke(circle(P(-0.52, -0.48), 0.075, 16), hair))
        // The spectacles: rims, the bridge, and the arms folded out across the right page.
        s.append(stroke(curve(polar(a, outer, 160), (a + b) / 2 - across * 0.2, polar(b, outer, 260), 16), bold))
        s.append(stroke(curve(a + along * outer, a + along * (outer + 0.1) + across * 0.3, a + along * outer + across * 0.75, 20), bold))
        s.append(stroke(curve(b - along * outer, b - along * (outer + 0.1) + across * 0.3, b - along * outer + across * 0.7, 20), bold))
        for c in [a, b] {
            s.append(stroke(circle(c, outer, 64), bold))
            s.append(stroke(circle(c, inner, 64), mid))
            s.append(stroke(arc(c, 0.3, 200, 240, 10), mid))
        }
        // The bookworm, arched along a line of print, and the clover, four leaves and a stalk.
        s.append(stroke([worm + P(-0.09, 0.012), worm + P(0.09, 0.012)], 0.002))
        s.append(stroke(arc(worm + P(-0.006, 0.008), 0.014, 180, 360, 10), 0.006))
        s.append(stroke(circle(worm + P(0.016, 0.003), 0.006, 10), 0.005))
        s.append(stroke([worm + P(0.019, -0.004), worm + P(0.026, -0.013)], 0.0018))
        s.append(stroke([worm + P(0.014, -0.004), worm + P(0.014, -0.014)], 0.0018))
        for k in 0..<4 { s.append(stroke(circle(polar(clover, 0.012, 90 * Double(k) + 20), 0.009, 10), 0.003)) }
        s.append(stroke(curve(clover, clover + P(0.012, 0.02), clover + P(0.004, 0.04), 8), 0.003))
        let under = fills
        return Halftone.Panel(name: "spectacles", tones: { p in
            for f in frames where f.holds(p) { return f.tone }
            // Each lens is flat cyan, so its edge shows against the page wherever a twist drags it.
            if simd_distance(p, a) < inner || simd_distance(p, b) < inner { return c(0.75) }
            for f in under where f.holds(p) { return f.tone }
            return c(0.26)
        }, strokes: s)
    }()
}

// MARK: - 9: Sunglasses

/// Level 9's name: sunglasses on the sand, face on, and what they are for in the top and bottom cores (eye's two small
/// lenses on this level): the sun, pleased with itself, and a crab that has come to look. Level 9 deals each lens +3 in
/// all.
extension LensArt {
    static let sunglasses: Halftone.Panel = {
        let sun = P(0, -0.56), crab = P(0.008, 0.548)
        let lens = [P(0.1, -0.2), P(0.72, -0.25), P(0.75, -0.04), P(0.62, 0.2), P(0.3, 0.24), P(0.12, 0.1)]
        func flip(_ q: [P]) -> [P] { q.map { P(-$0.x, $0.y) } }
        func grown(_ q: [P], _ by: Double) -> [P] { q.map { P(0.42, 0) + ($0 - P(0.42, 0)) * by } }
        let frame = grown(lens, 1.2), bridge = [P(-0.12, -0.2), P(0.12, -0.2), P(0.1, -0.08), P(-0.1, -0.08)]
        let arm = [P(0.76, -0.24), P(1.0, -0.42), P(1.0, -0.32), P(0.8, -0.14)]
        var fills: [Fill] = []
        for side in [lens, flip(lens)] {
            fills += [fill(side.map { P($0.x, min($0.y, -0.02)) }, c(0.6)), fill(side, m(0.6))]
        }
        fills += [fill(frame, y(0.85)), fill(flip(frame), y(0.85)), fill(bridge, y(0.85)), fill(arm, y(0.85)), fill(flip(arm), y(0.85)),
                  disc(sun, 0.19, y(0.9)), oval(crab + P(0, 0.002), 0.0275, 0.0187, m(0.8)), fill(rect(-1, 0.3, 1, 1), y(0.22)),
                  fill(rect(-1, -0.02, 1, 0.3), c(0.5))]

        var s: [Halftone.Stroke] = []
        // The sun, its rays long and short, and its face: eyes shut, a smile.
        s.append(stroke(circle(sun, 0.19, 48), bold))
        for k in 0..<16 { s.append(stroke([polar(sun, 0.23, 22.5 * Double(k)), polar(sun, k % 2 == 0 ? 0.34 : 0.28, 22.5 * Double(k))], mid)) }
        for x in [-0.02, 0.02] { s.append(stroke(arc(sun + P(x, -0.012), 0.009, 200, 340, 6), 0.0036)) }
        s.append(stroke(arc(sun + P(0, 0.0), 0.028, 30, 150, 10), 0.0036))
        for x in [-0.045, 0.045] { s.append(stroke(circle(sun + P(x, 0.012), 0.008, 8), 0.0016)) }
        // The sea's edge and its waves, a sail far out, and the sand.
        s.append(stroke([P(-1, -0.02), P(1, -0.02)], mid))
        for (k, at) in [P(-0.86, 0.1), P(-0.2, 0.26), P(0.84, 0.12), P(0.0, 0.3)].enumerated() {
            s.append(stroke(curve(at + P(-0.07, 0), at + P(-0.035, -0.03), at, 6) + curve(at, at + P(0.035, 0.03), at + P(0.07, 0), 6), k == 3 ? hair : mid))
        }
        s.append(stroke(closed([P(-0.82, -0.04), P(-0.82, -0.2), P(-0.72, -0.04)]), mid))
        s.append(stroke(curve(P(-1, 0.3), P(0, 0.36), P(1, 0.3), 16), mid))
        for (k, at) in [P(-0.7, 0.5), P(-0.5, 0.74), P(0.6, 0.52), P(0.44, 0.8), P(-0.34, 0.5), P(0.3, 0.44), P(0.76, 0.42)].enumerated() {
            s.append(stroke(circle(at, 0.008 + 0.005 * Double(k % 2), 6), hair))
        }
        // The sunglasses: frames, lenses, a palm bent across each, the bridge and the arms going back.
        for side in [1.0, -1.0] {
            let q = side > 0 ? lens : flip(lens), f = side > 0 ? frame : flip(frame), a = side > 0 ? arm : flip(arm)
            s.append(stroke(closed(f), bold))
            s.append(stroke(closed(q), mid))
            s.append(stroke(closed(a), mid))
            s.append(stroke([P(side * 0.14, -0.02), P(side * 0.71, -0.02)], hair))
            let foot = P(side * 0.4 + 0.1, 0.2), top = P(side * 0.4 - 0.04, -0.1)
            s.append(stroke(curve(foot, P(foot.x - 0.02, 0.04), top, 10), mid))
            for t in [150.0, 195, 240, 300, 345, 30] { s.append(stroke(curve(top, polar(top, 0.08, t - 25), polar(top, 0.13, t), 6), hair)) }
        }
        s.append(stroke(closed(bridge), mid))
        // The crab: shell, eyes on stalks, claws up, legs out, small enough to sit whole under the lens at x8.
        let z = 0.55
        s.append(stroke(ellipse(crab + P(0, 0.004) * z, 0.05 * z, 0.034 * z, 24), 0.0036))
        for side in [-1.0, 1.0] {
            s.append(stroke([crab + P(side * 0.016, -0.026) * z, crab + P(side * 0.018, -0.046) * z], 0.0024))
            s.append(stroke(circle(crab + P(side * 0.018, -0.054) * z, 0.0035, 8), 0.003))
            s.append(stroke([crab + P(side * 0.045, -0.012) * z, crab + P(side * 0.075, -0.034) * z, crab + P(side * 0.07, -0.06) * z], 0.003))
            s.append(stroke(arc(crab + P(side * 0.07, -0.078) * z, 0.016 * z, side > 0 ? -60 : 240, side > 0 ? 200 : -20, 8), 0.003))
            for k in 0..<3 {
                let yy = 0.012 + 0.012 * Double(k)
                s.append(stroke([crab + P(side * 0.045, yy) * z, crab + P(side * 0.075, yy + 0.004) * z, crab + P(side * 0.09, yy + 0.022) * z], 0.002))
            }
        }
        s.append(stroke(arc(crab + P(0, 0.002) * z, 0.014 * z, 30, 150, 6), 0.0024))
        return panel("sunglasses", fills: fills, strokes: s) { _ in c(0.2) }
    }()
}

// MARK: - 10: Pinhole

/// Level 10's name: a pinhole camera, a plain box on a tripod, its pinhole in the lower left core (tri's lens on this
/// level), and in the hole the tree it is aimed at, upside down as a pinhole throws it. Level 10 deals the lens +2 then
/// +1.
extension LensArt {
    static let pinhole: Halftone.Panel = {
        let hole = P(-0.3637, 0.16), green = Tone(0.5, 0, 0.5)
        let front = rect(-0.63, -0.06, -0.1, 0.47)
        let top = [P(-0.63, -0.06), P(-0.1, -0.06), P(-0.2, -0.17), P(-0.73, -0.17)]
        let side = [P(-0.63, -0.06), P(-0.73, -0.17), P(-0.73, 0.36), P(-0.63, 0.47)]
        let crown = [(P(0.55, -0.1), 0.26), (P(0.37, 0.04), 0.15), (P(0.73, 0.02), 0.15)]
        let sun = P(-0.1, -0.64)
        var fills = [disc(hole, 0.04, .zero), disc(hole, 0.085, y(0.85)), fill(front, m(0.5)), fill(top, m(0.25)), fill(side, m(0.75)),
                     fill(rect(0.5, 0.1, 0.6, 0.52), m(0.6))]
        fills += crown.map { disc($0.0, $0.1, green) }
        fills += [disc(sun, 0.13, y(0.9)), fill(rect(-1, 0.52, 1, 1), Tone(0.3, 0, 0.3))]

        var s: [Halftone.Stroke] = []
        // The sun, a bird, the ground and its tufts.
        s.append(stroke(circle(sun, 0.13, 32), mid))
        for k in 0..<12 { s.append(stroke([polar(sun, 0.16, 30 * Double(k)), polar(sun, k % 2 == 0 ? 0.23 : 0.19, 30 * Double(k))], hair)) }
        s.append(stroke(curve(P(0.2, -0.7), P(0.26, -0.77), P(0.31, -0.7), 6) + curve(P(0.31, -0.7), P(0.36, -0.77), P(0.42, -0.7), 6), mid))
        s += runs(span(P(-1, 0.52), P(1, 0.52), 40), mid) { $0.x > 0.02 || $0.x < -0.76 }
        for (k, x) in [-0.9, 0.1, 0.28, 0.84, -0.05].enumerated() {
            let foot = P(x, 0.62 + 0.07 * Double(k % 3))
            for t in [-110.0, -90, -65] { s.append(stroke([foot, polar(foot, 0.05, t)], hair)) }
        }
        // The tree: trunk, a knot, the crown's scallops and three apples.
        s.append(stroke([P(0.5, 0.14), P(0.5, 0.52)], mid))
        s.append(stroke([P(0.6, 0.12), P(0.6, 0.52)], mid))
        s.append(stroke(ellipse(P(0.55, 0.34), 0.016, 0.03, 10), hair))
        s.append(stroke(arc(crown[0].0, 0.26, 150, 395, 28), bold))
        s.append(stroke(arc(crown[1].0, 0.15, 60, 250, 14), bold))
        s.append(stroke(arc(crown[2].0, 0.15, -75, 120, 14), bold))
        for at in [P(0.45, -0.16), P(0.66, -0.2), P(0.58, 0.0)] { s.append(stroke(circle(at, 0.026, 10), mid)) }
        s.append(stroke(curve(P(0.4, -0.02), P(0.5, 0.06), P(0.62, -0.06), 8), hair))
        // The light's two rays, from the tree's top and foot, crossing at the pinhole.
        for from in [P(0.55, -0.36), P(0.55, 0.52)] { s += dashes(from, hole + simd_normalize(from - hole) * 0.09, 14) }
        // The box, its lid's seam and a carrying strap, on its tripod.
        s.append(stroke(closed(front), bold))
        s.append(stroke(Array(top[1...3]) + [side[2], side[3]], bold))
        s.append(stroke([P(-0.63, 0.02), P(-0.1, 0.02)], hair))
        s.append(stroke([P(-0.73, -0.09), P(-0.63, 0.02)], hair))
        s.append(stroke(curve(P(-0.6, -0.17), P(-0.42, -0.34), P(-0.28, -0.17), 12), mid))
        for (x0, x1) in [(-0.52, -0.78), (-0.36, -0.36), (-0.2, 0.02)] { s.append(stroke(bar(P(x0, 0.47), P(x1, 1.05), 0.035), mid)) }
        s.append(stroke(closed(rect(-0.56, 0.47, -0.16, 0.52)), mid))
        // The pinhole in its brass plate, the shutter swung clear of it, and two screws.
        s.append(stroke(circle(hole, 0.085, 32), bold))
        s.append(stroke(circle(hole, 0.04, 24), mid))
        s.append(stroke(closed(bar(hole + P(0.075, -0.075), hole + P(0.19, -0.14), 0.05)), mid))
        s.append(stroke(circle(hole + P(0.075, -0.075), 0.012, 8), mid))
        for (at, t) in [(hole + P(-0.062, 0), 30.0), (hole + P(0, 0.064), 100.0)] { s.append(stroke([polar(at, 0.011, t), polar(at, -0.011, t)], mid)) }
        // Through it: the ground on top, the tree hanging from it, the sun at the bottom.
        s.append(stroke([hole + P(-0.032, -0.022), hole + P(0.032, -0.022)], 0.0026))
        s.append(stroke([hole + P(0.006, -0.022), hole + P(0.006, 0.004)], 0.0036))
        s.append(stroke(circle(hole + P(0.006, 0.012), 0.012, 12), 0.003))
        s.append(stroke(circle(hole + P(-0.018, 0.018), 0.0045, 8), 0.0024))
        return panel("pinhole", fills: fills, strokes: s) { _ in c(0.2) }
    }()
}

// MARK: - 11: Bifocals

/// Level 11's name: bifocals laid open on the mending, each lens cut across by its reading line. The cloth is a
/// ticking, broad stripes that run under the glass, where they show tinted cyan, and across every rim, and the
/// pincushion sits well off the top rod's centre, so its twist turns shapes that read without the pins and the thread,
/// and drags each glass's cyan out over the magenta cloth. The lenses lie side by side over the lower left and lower
/// right cores (tri's two lenses on this level): under one a needle's eye, the thread through it, and under the other
/// a button, sewn on with a cross. Level 11 deals each lens +3 in all.
extension LensArt {
    static let bifocals: Halftone.Panel = {
        let a = P(-0.3637, 0.21), b = P(0.3637, 0.21), axis = P(1, 0), down = P(0, 1)
        func lens(_ c: P, _ k: Double) -> [P] { squircle(c, 0.32 * k, 0.28 * k) }
        func reading(_ c: P) -> [P] { lens(c, 1).filter { simd_dot($0 - c, down) > 0.09 } }
        let reel = P(-0.36, -0.56), eye = a + P(0.034, -0.03), button = b + P(0.022, -0.03), cushion = P(0.2, -0.6)
        let arms = [bar(a - axis * 0.4 - down * 0.1, a - axis * 0.4 + down * 0.5, 0.055), bar(b + axis * 0.4 - down * 0.1, b + axis * 0.4 + down * 0.5, 0.055)]
        let bridge = bar(a + axis * 0.3 - down * 0.08, b - axis * 0.3 - down * 0.08, 0.06)
        var fills: [Fill] = []
        for c in [a, b] { fills.append(fill(lens(c, 1.13), y(0.85))) }
        let readings = [a, b].map { fill(reading($0), Tone(0.8, 0, 0.3)) }, glass = [a, b].map { fill(lens($0, 1), .zero) }
        // The ticking: a dark stripe 0.13 wide every 0.3, tilted off the level.
        let cloth: @Sendable (P) -> Tone = { p in
            let v = (p.y * 0.94 - p.x * 0.34 + 2) / 0.3
            return m(v - v.rounded(.down) < 0.43 ? 0.66 : 0.2)
        }
        fills += [fill(bridge, y(0.85)), fill(arms[0], y(0.85)), fill(arms[1], y(0.85)), disc(cushion, 0.17, c(0.6)),
                  fill(rect(reel.x - 0.14, reel.y - 0.17, reel.x + 0.14, reel.y - 0.12), y(0.8)),
                  fill(rect(reel.x - 0.14, reel.y + 0.12, reel.x + 0.14, reel.y + 0.17), y(0.8)),
                  fill(rect(reel.x - 0.1, reel.y - 0.12, reel.x + 0.1, reel.y + 0.12), c(0.7)),
                  fill([P(-0.2, 1), P(-0.1, 0.66), P(0.06, 0.78), P(0.2, 0.62), P(0.34, 1)], c(0.4))]

        var s: [Halftone.Stroke] = []
        // The mending: a hem's stitches, a patch pinked along its edge, and pins.
        s += dashes(P(0.96, -0.2), P(0.5, -0.9), 12, mid)
        s.append(stroke([P(-0.2, 1), P(-0.1, 0.66), P(0.06, 0.78), P(0.2, 0.62), P(0.34, 1)], mid))
        for (at, t) in [(P(0.02, 0.86), -30.0), (P(0.66, -0.36), 60.0), (P(-0.8, -0.28), 10.0)] {
            s.append(stroke([at, polar(at, 0.16, t)], hair))
            s.append(stroke(circle(at, 0.016, 8), mid))
        }
        // The reel of thread, wound, its end run off to the needle.
        s.append(stroke(closed(rect(reel.x - 0.14, reel.y - 0.17, reel.x + 0.14, reel.y - 0.12)), mid))
        s.append(stroke(closed(rect(reel.x - 0.14, reel.y + 0.12, reel.x + 0.14, reel.y + 0.17)), mid))
        for k in 0..<7 { s.append(stroke([P(reel.x - 0.1, reel.y - 0.1 + 0.035 * Double(k)), P(reel.x + 0.1, reel.y - 0.085 + 0.035 * Double(k))], hair)) }
        s.append(stroke([P(reel.x - 0.1, reel.y - 0.12), P(reel.x - 0.1, reel.y + 0.12)], mid))
        s.append(stroke([P(reel.x + 0.1, reel.y - 0.12), P(reel.x + 0.1, reel.y + 0.12)], mid))
        let thread = curve(reel + P(0.1, -0.1), P(0.1, -0.5), P(-0.04, -0.2), 20) + curve(P(-0.04, -0.2), P(-0.2, 0.06), eye, 16)
            + curve(eye, eye + P(0.06, 0.03), eye + P(0.1, -0.06), 10) + curve(eye + P(0.1, -0.06), eye + P(0.14, -0.16), eye + P(0.26, -0.12), 10)
        s.append(stroke(thread, hair))
        // A pincushion, ribbed like a tomato, pins in it.
        s.append(stroke(circle(cushion, 0.17, 32), bold))
        for k in 0..<6 { s.append(stroke(curve(cushion, polar(cushion, 0.11, 60 * Double(k) + 35), polar(cushion, 0.17, 60 * Double(k) + 10), 8), hair)) }
        for (t, r) in [(-100.0, 0.24), (-30, 0.26), (70, 0.26), (170, 0.27)] {
            s.append(stroke([polar(cushion, 0.06, t), polar(cushion, r, t)], hair))
            s.append(stroke(circle(polar(cushion, r, t), 0.016, 8), mid))
        }
        // The arms, open, running off the cloth.
        for q in arms { s.append(stroke(closed(q), bold)) }
        s.append(stroke(closed(bridge), bold))
        // The bifocals: bridge, nose pads, rims and the reading line across each lens.
        for side in [-1.0, 1.0] { s.append(stroke(ellipse(P(side * 0.05, 0.36), 0.02, 0.04, degrees: side * 25, 12), mid)) }
        for c in [a, b] {
            s.append(stroke(closed(lens(c, 1.14)), bold))
            s.append(stroke(closed(lens(c, 1)), mid))
            let cut = reading(c)
            s.append(stroke([cut[0], cut[cut.count - 1]], mid))
        }
        // The needle and its eye, the thread through it.
        let along = P(cos(-0.3), sin(-0.3))
        s.append(stroke(closed([eye - along * 0.3, eye - along * 0.02 + P(0.004, 0.012), eye + along * 0.03, eye - along * 0.02 - P(0.004, 0.012)]), 0.0026))
        s.append(stroke(ellipse(eye - along * 0.004, 0.014, 0.0045, degrees: -17, 12), 0.0026))
        // The button: rim, dish, four holes and the cross of thread.
        s.append(stroke(circle(button, 0.032, 24), 0.0044))
        s.append(stroke(circle(button, 0.022, 20), 0.0016))
        for (dx, dy) in [(-1.0, -1.0), (1, -1), (1, 1), (-1, 1)] { s.append(stroke(circle(button + P(dx, dy) * 0.008, 0.003, 6), 0.003)) }
        s.append(stroke([button + P(-0.008, -0.008), button + P(0.008, 0.008)], 0.002))
        s.append(stroke([button + P(0.008, -0.008), button + P(-0.008, 0.008)], 0.002))
        let under = fills
        return Halftone.Panel(name: "bifocals", tones: { p in
            // The reading segments first, then the cloth through the rest of each glass, tinted cyan, under which no
            // frame shows.
            for f in readings where f.holds(p) { return f.tone }
            for f in glass where f.holds(p) { return cloth(p) + c(0.5) }
            for f in under where f.holds(p) { return f.tone }
            return cloth(p)
        }, strokes: s)
    }()
}

// MARK: - 12: 3D glasses

/// Level 12's name: card 3D glasses, one window magenta and one cyan, over the left and right cores (eye's two big
/// lenses on this level), a flying saucer in one and a rocket in the other, with the film above and the popcorn below.
/// Level 12 deals each lens +3 in all.
extension LensArt {
    static let glasses3d: Halftone.Panel = {
        let a = P(-0.4, 0), b = P(0.4, 0)
        let card = [P(-0.86, -0.3), P(0.86, -0.3), P(0.86, 0.2), P(0.78, 0.3), P(0.13, 0.3), P(0.05, 0.1), P(-0.05, 0.1), P(-0.13, 0.3),
                    P(-0.78, 0.3), P(-0.86, 0.2)]
        let arms = [[P(0.86, -0.3), P(1.02, -0.44), P(1.02, -0.22), P(0.86, -0.06)], [P(-0.86, -0.3), P(-1.02, -0.44), P(-1.02, -0.22), P(-0.86, -0.06)]]
        let film = [P(-1, -0.8), P(1, -0.72), P(1, -0.42), P(-1, -0.5)]
        let tub = [P(-0.24, 0.5), P(0.24, 0.5), P(0.17, 1.0), P(-0.17, 1.0)]
        let corn = [P(-0.17, 0.46), P(-0.05, 0.42), P(0.08, 0.45), P(0.18, 0.47), P(-0.1, 0.36), P(0.03, 0.34), P(0.13, 0.38)]
        var fills = [fill(squircle(a, 0.31, 0.2), m(0.7)), fill(squircle(b, 0.31, 0.2), c(0.7)), fill(card, y(0.8)), fill(arms[0], y(0.45)),
                     fill(arms[1], y(0.45))]
        fills += corn.map { disc($0, 0.07, y(0.75)) }
        for k in 0..<4 {
            let x0 = -0.24 + 0.12 * Double(k), x1 = -0.17 + 0.085 * Double(k)
            fills.append(fill([P(x0, 0.5), P(x0 + 0.12, 0.5), P(x1 + 0.085, 1.0), P(x1, 1.0)], k % 2 == 0 ? m(0.75) : y(0.3)))
        }
        fills += [fill(film, c(0.45)), fill(rect(-1, -1, -0.66, 1), m(0.4)), fill(rect(0.66, -1, 1, 1), m(0.4))]

        var s: [Halftone.Stroke] = []
        // The curtains' folds, and the film across the top: its sprocket holes and frames, a shape in each.
        for (k, x) in [-0.92, -0.8, -0.7, 0.72, 0.83, 0.94].enumerated() {
            let bow = k % 2 == 0 ? -0.03 : 0.03
            s.append(stroke(curve(P(x, -1), P(x + bow, 0), P(x, 1), 12), hair))
        }
        s.append(stroke([film[0], film[1]], mid))
        s.append(stroke([film[3], film[2]], mid))
        for k in 0..<14 {
            let x = -0.94 + 0.145 * Double(k), lift = 0.04 * (x + 1)
            s.append(stroke(closed(rect(x, -0.775 + lift, x + 0.06, -0.735 + lift)), hair))
            s.append(stroke(closed(rect(x, -0.545 + lift, x + 0.06, -0.505 + lift)), hair))
        }
        for k in 0..<6 {
            let x = -0.86 + 0.36 * Double(k), lift = 0.04 * (x + 1)
            s.append(stroke([P(x, -0.71 + lift), P(x, -0.57 + lift)], mid))
            let at = P(x + 0.18, -0.64 + lift + 0.007)
            switch k % 3 {
            case 0: s.append(stroke(star(at, 0.05), hair))
            case 1: s.append(stroke(circle(at, 0.04, 14), hair))
            default: s.append(stroke(closed([at + P(-0.05, 0.04), at + P(0, -0.05), at + P(0.05, 0.04)]), hair))
            }
        }
        // The popcorn in its striped tub, some of it spilt, and two tickets.
        for at in corn { s.append(stroke(arc(at, 0.07, 170, 370, 12), mid)) }
        s.append(stroke(closed(tub), bold))
        for k in 1..<4 { s.append(stroke([P(-0.24 + 0.12 * Double(k), 0.5), P(-0.17 + 0.085 * Double(k), 1.0)], hair)) }
        for at in [P(0.36, 0.62), P(0.44, 0.76), P(0.3, 0.84)] { s.append(stroke(arc(at, 0.035, 150, 400, 10), mid)) }
        for (k, at) in [P(-0.46, 0.6), P(-0.4, 0.74)].enumerated() {
            let q = bar(polar(at, -0.13, 20 - 30 * Double(k)), polar(at, 0.13, 20 - 30 * Double(k)), 0.11)
            s.append(stroke(closed(q), mid))
            s.append(stroke(star(at, 0.03), hair))
        }
        // The glasses: the card, its nose cut, the windows and the arms folded back.
        s.append(stroke(closed(card), bold))
        for q in arms { s.append(stroke(closed(q), mid)) }
        for c in [a, b] {
            s.append(stroke(closed(squircle(c, 0.31, 0.2)), mid))
            for (k, at) in [P(-0.2, -0.1), P(0.2, 0.08), P(-0.14, 0.1), P(0.18, -0.1), P(0.0, 0.13)].enumerated() {
                s.append(stroke(star(c + at, 0.014 + 0.006 * Double(k % 2), points: 4, inner: 0.3), hair))
            }
        }
        // In the magenta window, a flying saucer: dome, rim, lights and its beam.
        let ufo = a + P(0.016, -0.03)
        s.append(stroke(ellipse(ufo, 0.036, 0.011, 20), 0.004))
        s.append(stroke(arc(ufo + P(0, -0.006), 0.017, 180, 360, 10), 0.0036))
        for x in [-0.02, 0.0, 0.02] { s.append(stroke(circle(ufo + P(x, 0.001), 0.002, 6), 0.003)) }
        s.append(stroke([ufo + P(-0.012, 0.014), ufo + P(-0.03, 0.05)], 0.002))
        s.append(stroke([ufo + P(0.012, 0.014), ufo + P(0.03, 0.05)], 0.002))
        // In the cyan, a rocket, climbing: nose, body, window, fins and flame.
        let rocket = b + P(0.02, -0.028), up = P(sin(0.5), -cos(0.5)), out = P(cos(0.5), sin(0.5))
        s.append(stroke(closed([rocket + up * 0.04, rocket + up * 0.016 + out * 0.014, rocket - up * 0.024 + out * 0.014,
                                rocket - up * 0.024 - out * 0.014, rocket + up * 0.016 - out * 0.014]), 0.004))
        s.append(stroke(circle(rocket + up * 0.006, 0.005, 8), 0.003))
        for side in [-1.0, 1.0] {
            s.append(stroke([rocket - up * 0.008 + out * (side * 0.014), rocket - up * 0.034 + out * (side * 0.03), rocket - up * 0.024 + out * (side * 0.014)], 0.003))
        }
        s.append(stroke([rocket - up * 0.026 - out * 0.008, rocket - up * 0.046 - out * 0.003, rocket - up * 0.034, rocket - up * 0.052 + out * 0.004,
                         rocket - up * 0.026 + out * 0.008], 0.002))
        return panel("glasses3d", fills: fills, strokes: s) { _ in c(0.13) }
    }()
}
