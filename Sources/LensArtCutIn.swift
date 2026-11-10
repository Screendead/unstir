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

/// Level 8's name: round spectacles laid across an open book, their lenses over the top right and lower left cores
/// (quad's two lenses on this level), and under them in the print a bookworm and a pressed clover. Level 8
/// deals each lens +3 in all.
extension LensArt {
    static let spectacles: Halftone.Panel = {
        let a = P(0.3536, -0.3536), b = P(-0.3536, 0.3536)
        let worm = a + P(0.024, -0.03), clover = b + P(-0.026, -0.03)
        let picture = rect(-0.72, -0.62, -0.2, -0.2)
        var fills = [disc(P(-0.36, -0.36), 0.07, y(0.8)), fill([P(-0.72, -0.2), P(-0.56, -0.44), P(-0.44, -0.3), P(-0.34, -0.4), P(-0.2, -0.2)], c(0.5)),
                     fill(picture, c(0.2))]
        for c in [a, b] { fills += [disc(c, 0.3, y(0.14)), disc(c, 0.335, m(0.75))] }
        fills += [fill(rect(-0.86, -0.9, 0.86, 0.9), y(0.14)), fill(rect(-0.93, -0.96, 0.93, 0.96), m(0.4))]

        var s: [Halftone.Stroke] = []
        // The book: cover, pages, the gutter, and the lines of print, parted where a clue sits and short at a paragraph's end.
        s.append(stroke(closed(rect(-0.86, -0.9, 0.86, 0.9)), mid))
        s.append(stroke([P(0, -0.9), P(0, 0.9)], mid))
        s.append(stroke(curve(P(-0.06, -0.9), P(-0.02, 0), P(-0.06, 0.9), 12), hair))
        s.append(stroke(curve(P(0.06, -0.9), P(0.02, 0), P(0.06, 0.9), 12), hair))
        for row in 0..<27 {
            let yy = -0.8 + 0.06 * Double(row)
            for side in [-1.0, 1.0] {
                if side < 0, yy > -0.68, yy < -0.14 { continue }
                let short = (row + (side < 0 ? 3 : 0)) % 7 == 6, indent = (row + (side < 0 ? 3 : 0)) % 7 == 0
                let x0 = side < 0 ? -0.78 : 0.12, x1 = side < 0 ? -0.12 : 0.78
                let line = (0...44).map { P(x0 + (x1 - x0) * Double($0) / 44, yy) }.filter {
                    (!short || $0.x < x0 + 0.3) && (!indent || $0.x > x0 + 0.06)
                }
                s += runs(line) { simd_distance($0, worm) > 0.05 && simd_distance($0, clover) > 0.05 }
            }
        }
        // The plate on the left page: a hill, a sun.
        s.append(stroke(closed(picture), mid))
        s.append(stroke([P(-0.72, -0.2), P(-0.56, -0.44), P(-0.44, -0.3), P(-0.34, -0.4), P(-0.2, -0.2)], hair))
        s.append(stroke(circle(P(-0.36, -0.5), 0.05, 16), hair))
        // The spectacles: rims, the bridge, and the arms folded out across the right page.
        s.append(stroke(curve(polar(a, 0.335, 160), P(-0.12, -0.12), polar(b, 0.335, -70), 16), bold))
        s.append(stroke(curve(polar(a, 0.335, -20), P(0.98, -0.1), P(0.9, 0.42), 20), bold))
        s.append(stroke(curve(polar(b, 0.335, 110), P(-0.1, 0.98), P(0.42, 0.9), 20), bold))
        s.append(stroke(arc(P(0.84, 0.42), 0.06, 0, 150, 8), bold))
        s.append(stroke(arc(P(0.42, 0.84), 0.06, 90, -60, 8), bold))
        for c in [a, b] {
            s.append(stroke(circle(c, 0.335, 64), bold))
            s.append(stroke(circle(c, 0.3, 64), mid))
            s.append(stroke(arc(c, 0.26, 200, 240, 10), mid))
        }
        // The bookworm, arched along a line of print, and the clover, four leaves and a stalk.
        s.append(stroke([worm + P(-0.04, 0.012), worm + P(0.04, 0.012)], 0.002))
        s.append(stroke(arc(worm + P(-0.006, 0.008), 0.014, 180, 360, 10), 0.006))
        s.append(stroke(circle(worm + P(0.016, 0.003), 0.006, 10), 0.005))
        s.append(stroke([worm + P(0.019, -0.004), worm + P(0.026, -0.013)], 0.0018))
        s.append(stroke([worm + P(0.014, -0.004), worm + P(0.014, -0.014)], 0.0018))
        for k in 0..<4 { s.append(stroke(circle(polar(clover, 0.012, 90 * Double(k) + 20), 0.009, 10), 0.003)) }
        s.append(stroke(curve(clover, clover + P(0.012, 0.02), clover + P(0.004, 0.04), 8), 0.003))
        return panel("spectacles", fills: fills, strokes: s) { _ in c(0.26) }
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
