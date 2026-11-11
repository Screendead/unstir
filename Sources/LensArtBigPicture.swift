// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 19 to 25, the last chapter.

// MARK: - 19: Camera

/// Level 19's name: a camera face on, its lens over the hub (hex's lens on this level), and in the glass the three it
/// is about to take, standing in a row. Level 19 deals the lens +2 then +1.
extension LensArt {
    static let camera: Halftone.Panel = {
        let lens = P(0, 0.02), body = squircle(P(0, 0.04), 0.86, 0.52), top = rect(-0.74, -0.56, 0.74, -0.38)
        let hump = [P(-0.2, -0.56), P(-0.14, -0.72), P(0.14, -0.72), P(0.2, -0.56)]
        let finder = rect(-0.62, -0.33, -0.38, -0.2), light = rect(0.36, -0.34, 0.66, -0.18)
        let fills = [disc(lens, 0.17, c(0.3)), disc(lens, 0.235, m(0.8)), disc(lens, 0.31, y(0.85)), fill(finder, c(0.6)), fill(light, y(0.4)),
                     fill(rect(0.44, -0.66, 0.62, -0.56), y(0.85)), disc(P(-0.52, -0.6), 0.09, y(0.85)), fill(hump, y(0.5)), fill(top, y(0.7)),
                     fill(body, m(0.5)), fill(rect(-1, 0.62, 1, 1), y(0.2))]

        var s: [Halftone.Stroke] = []
        // The body and its covering's grain, the top plate, the prism's hump and its shoe, the button and the wind knob.
        s.append(stroke(closed(body), bold))
        for k in 0..<9 {
            let x = -0.78 + 0.19 * Double(k)
            s += runs(span(P(x, 0.5), P(x + 0.1, -0.22), 20)) { simd_distance($0, lens) > 0.33 && $0.y > -0.16 }
        }
        s.append(stroke([P(-0.8, -0.38), P(0.8, -0.38)], mid))
        s.append(stroke(closed(hump), bold))
        s.append(stroke(closed(rect(-0.08, -0.78, 0.08, -0.72)), mid))
        s.append(stroke(closed(rect(0.44, -0.66, 0.62, -0.56)), mid))
        s.append(stroke(arc(P(-0.52, -0.6), 0.09, 180, 360, 12), mid))
        for k in 0..<7 { s.append(stroke([P(-0.6 + 0.027 * Double(k), -0.66), P(-0.6 + 0.027 * Double(k), -0.56)], hair)) }
        // The finder's window, the meter's cell, honeycombed, the timer's lever and the strap's lugs.
        s.append(stroke(closed(finder), bold))
        s.append(stroke(closed(rect(-0.58, -0.3, -0.42, -0.23)), hair))
        s.append(stroke(closed(light), mid))
        for k in 0..<5 { s.append(stroke([P(0.41 + 0.05 * Double(k), -0.34), P(0.41 + 0.05 * Double(k), -0.18)], hair)) }
        s.append(stroke([P(0.36, -0.26), P(0.66, -0.26)], hair))
        s.append(stroke(closed(bar(P(0.52, 0.02), P(0.56, 0.28), 0.05)), mid))
        s.append(stroke(circle(P(0.52, 0.02), 0.04, 12), mid))
        for side in [-1.0, 1.0] { s.append(stroke(closed(rect(min(side * 0.84, side * 0.93), -0.26, max(side * 0.84, side * 0.93), -0.18)), mid)) }
        s.append(stroke(curve(P(-0.9, -0.2), P(-1.0, 0.5), P(-0.6, 0.86), 12), mid))
        s.append(stroke([P(-1, 0.62), P(-0.72, 0.62)], mid))
        s.append(stroke([P(0.72, 0.62), P(1, 0.62)], mid))
        // The lens: its mount, the focus ring's scale and grip, the front ring and the glass.
        s.append(stroke(circle(lens, 0.31, 72), bold))
        s.append(stroke(circle(lens, 0.235, 64), bold))
        s.append(stroke(circle(lens, 0.17, 56), mid))
        for k in 0..<36 where k % 9 != 4 { s.append(stroke([polar(lens, k % 3 == 0 ? 0.255 : 0.27, 10 * Double(k)), polar(lens, 0.295, 10 * Double(k))], hair)) }
        s.append(stroke(closed([polar(lens, 0.33, -90), polar(lens, 0.37, -84), polar(lens, 0.37, -96)]), mid))
        s.append(stroke(arc(lens, 0.14, 200, 245, 10), mid))
        // In the glass: three in a row for their picture, tall, small and middling, hands joined, the tall one's hat on.
        let row = lens + P(0.012, -0.018)
        for (x, h) in [(-0.022, 0.03), (0.0, 0.018), (0.022, 0.025)] {
            let foot = row + P(x, 0.03), head = row + P(x, 0.03 - h - 0.012)
            s.append(stroke(circle(head, 0.0055, 8), 0.003))
            s.append(stroke([head + P(0, 0.006), foot + P(0, -0.01)], 0.003))
            s.append(stroke([foot + P(-0.005, 0), foot + P(0, -0.01), foot + P(0.005, 0)], 0.002))
        }
        s.append(stroke([row + P(-0.022, 0.006), row + P(-0.011, 0.014), row + P(0.0, 0.01), row + P(0.011, 0.014), row + P(0.022, 0.008)], 0.002))
        s.append(stroke([row + P(-0.031, -0.018), row + P(-0.013, -0.018)], 0.002))
        s.append(stroke(closed(rect(row.x - 0.027, row.y - 0.026, row.x - 0.017, row.y - 0.018)), 0.002))
        s.append(stroke([row + P(-0.04, 0.03), row + P(0.04, 0.03)], 0.0016))
        return panel("camera", fills: fills, strokes: s) { _ in c(0.2) }
    }()
}

// MARK: - 20: Shutter

/// Level 20's name: a shutter's six blades part closed, their opening over the hub and the speed dial's two ends over
/// the top and bottom cores (hex's three lenses on this level): in the opening the drop it has caught mid-splash, on
/// the dial a bolt for fast and a snail for slow. Level 20 deals the lenses +3, +3 and +2.
extension LensArt {
    static let shutter: Halftone.Panel = {
        let o = P(0, 0), bolt = P(0.012, -0.585), snail = P(0.0, 0.54)
        func corner(_ k: Int) -> P { polar(o, 0.25, 60 * Double(k) + 30) }
        func rim(_ k: Int) -> P { polar(o, 0.9, 60 * Double(k) + 95) }
        var fills: [Fill] = [disc(P(0, -0.56), 0.11, .zero), disc(P(0, 0.56), 0.11, .zero), fill((0..<6).map(corner), c(0.14))]
        for k in 0..<6 { fills.append(fill([corner(k), corner(k + 1), rim(k + 1), rim(k)], k % 2 == 0 ? m(0.55) : m(0.3))) }
        fills += [disc(o, 0.9, m(0.4)), disc(o, 1.1, y(0.8))]

        var s: [Halftone.Stroke] = []
        // The ring, knurled, and the blades: each one's leading edge, and a second line for its thickness.
        s.append(stroke(circle(o, 0.9, 96), bold))
        for k in 0..<48 { s.append(stroke([polar(o, 0.93, 7.5 * Double(k)), polar(o, 0.98, 7.5 * Double(k))], hair)) }
        for k in 0..<6 {
            s.append(stroke([corner(k), rim(k)], bold))
            s.append(stroke([corner(k), corner(k + 1)], bold))
            let edge = rim(k) - corner(k), n = simd_normalize(P(-edge.y, edge.x)) * 0.03
            s += runs(span(corner(k) + n + edge * 0.12, rim(k) + n, 30)) {
                simd_distance($0, P(0, -0.56)) > 0.13 && simd_distance($0, P(0, 0.56)) > 0.13 && simd_length($0) < 0.9
            }
            s.append(stroke(circle(polar(o, 0.82, 60 * Double(k) + 80), 0.022, 10), mid))
        }
        // The dial's two windows.
        for c in [P(0, -0.56), P(0, 0.56)] { s.append(stroke(circle(c, 0.11, 32), mid)) }
        // In the opening: a drop falling, and the crown the last one threw up.
        let drop = o + P(0.012, -0.05)
        s.append(stroke(closed([drop + P(0, -0.03)] + arc(drop, 0.014, -30, 210, 12)), 0.0036))
        let crown = o + P(0.012, 0.03)
        s.append(stroke(squash(arc(crown + P(0, 0.016), 0.05, 200, 340, 12), about: crown.y + 0.016, by: 0.4), 0.003))
        s.append(stroke(squash(arc(crown + P(0, 0.016), 0.05, 20, 160, 12), about: crown.y + 0.016, by: 0.4), 0.003))
        for k in 0..<5 {
            let x = -0.044 + 0.022 * Double(k), lift = 0.03 - 0.012 * abs(Double(k) - 2)
            s.append(stroke([crown + P(x * 0.9, 0.012), crown + P(x * 1.15, 0.012 - lift)], 0.003))
            s.append(stroke(circle(crown + P(x * 1.25, 0.004 - lift), 0.003, 6), 0.0026))
        }
        for r in [0.075, 0.105] { s.append(stroke(squash(arc(crown + P(0, 0.03), r, 20, 160, 12), about: crown.y + 0.03, by: 0.35), 0.0016)) }
        // On the dial: the bolt, and the snail.
        s.append(stroke(closed([bolt + P(0.006, -0.04), bolt + P(-0.02, 0.004), bolt + P(-0.002, 0.004), bolt + P(-0.01, 0.04), bolt + P(0.02, -0.008),
                                bolt + P(0.002, -0.008), bolt + P(0.016, -0.04)]), 0.0036))
        s.append(stroke(spiral(snail + P(-0.008, -0.012), 0.003, grow: 0.0009, turn: 30, 26), 0.003))
        s.append(stroke(curve(snail + P(-0.04, 0.016), snail + P(0.0, 0.022), snail + P(0.034, 0.012), 8) + [snail + P(0.04, -0.006)], 0.0036))
        for x in [0.036, 0.046] { s.append(stroke([snail + P(0.04, -0.006), snail + P(x + 0.004, -0.024)], 0.002)) }
        return panel("shutter", fills: fills, strokes: s) { _ in .zero }
    }()
}

// MARK: - 21: Viewfinder

/// Level 21's name: a view framed in a finder, its corner marks and focus ring over the mountains and the lake, a
/// balloon over the left core and ducks on the water over the bottom one (eye's two lenses on this level): in the
/// balloon's basket someone waves. Level 21 deals each lens +3 in all.
extension LensArt {
    static let viewfinder: Halftone.Panel = {
        let a = P(-0.4, 0), b = P(0, 0.56), basket = a + P(0.024, 0.012), balloon = basket + P(0, -0.2), duck = b + P(0.012, -0.03)
        let peaks = [[P(-1, 0.3), P(-0.62, -0.2), P(-0.3, 0.3)], [P(-0.2, 0.3), P(0.3, -0.42), P(0.62, 0.02), P(0.78, -0.16), P(1.1, 0.3)]]
        let sun = P(0.56, -0.5), green = Tone(0.32, 0, 0.36)
        var fills = [disc(balloon, 0.15, m(0.7)), fill([balloon + P(-0.1, 0.11), balloon + P(0.1, 0.11), basket + P(0.02, -0.03), basket + P(-0.02, -0.03)], m(0.7)),
                     disc(sun, 0.12, y(0.9))]
        fills += peaks.map { fill($0, m(0.4)) }
        fills += [fill(curve(P(-1, 0.3), P(0, 0.22), P(1, 0.3), 12) + [P(1, 0.42), P(-1, 0.42)], green), fill(rect(-1, 0.3, 1, 1), c(0.55))]

        var s: [Halftone.Stroke] = []
        // The view: sun, the mountains and their snow, the far shore and the lake's ripples, reeds at the near edge.
        s.append(stroke(circle(sun, 0.12, 28), mid))
        for k in 0..<12 { s.append(stroke([polar(sun, 0.15, 30 * Double(k)), polar(sun, 0.2, 30 * Double(k))], hair)) }
        for q in peaks { s.append(stroke(q, bold)) }
        s.append(stroke([P(-0.72, -0.07), P(-0.66, -0.02), P(-0.61, -0.08), P(-0.56, -0.02), P(-0.52, -0.05)], hair))
        s.append(stroke([P(0.16, -0.22), P(0.24, -0.14), P(0.3, -0.24), P(0.37, -0.14), P(0.43, -0.22)], hair))
        s.append(stroke(curve(P(-1, 0.3), P(0, 0.22), P(1, 0.3), 16), mid))
        for (k, at) in [P(-0.6, 0.5), P(0.5, 0.48), P(0.7, 0.7), P(-0.5, 0.78), P(0.34, 0.86), P(-0.76, 0.64)].enumerated() {
            let w = 0.07 + 0.01 * Double(k)
            s.append(stroke(curve(at + P(-w, 0), at + P(0, -0.03), at + P(w, 0), 6), hair))
        }
        for x in [0.74, 0.8, 0.86] { s.append(stroke(curve(P(x, 0.98), P(x - 0.03, 0.8), P(x + 0.02, 0.62 + (x - 0.74)), 6), mid)) }
        // The finder: corner marks, the focus ring split across, and the meter's needle at the side.
        for (sx, sy) in [(-1.0, -1.0), (1, -1), (1, 1), (-1, 1)] {
            s.append(stroke([P(sx * 0.6, sy * 0.44), P(sx * 0.6, sy * 0.6), P(sx * 0.44, sy * 0.6)], bold))
        }
        s.append(stroke(circle(P(0, 0), 0.1, 28), mid))
        s.append(stroke([P(-0.1, 0), P(0.1, 0)], hair))
        s.append(stroke(circle(P(0, 0), 0.2, 40), hair))
        for k in 0..<5 { s.append(stroke([P(0.86, -0.16 + 0.08 * Double(k)), P(k == 2 ? 0.94 : 0.9, -0.16 + 0.08 * Double(k))], hair)) }
        s.append(stroke([P(0.8, -0.05), P(0.86, -0.03), P(0.8, -0.01)], mid))
        // The balloon: its envelope and gores, the ropes, the basket and the one waving from it.
        s.append(stroke(arc(balloon, 0.15, 132, 408, 36), bold))
        s.append(stroke([balloon + P(-0.1, 0.11), basket + P(-0.02, -0.03)], mid))
        s.append(stroke([balloon + P(0.1, 0.11), basket + P(0.02, -0.03)], mid))
        for x in [-0.07, 0.0, 0.07] { s.append(stroke(curve(balloon + P(x * 0.3, -0.15), balloon + P(x * 1.9, 0), basket + P(x * 0.2, -0.03), 12), hair)) }
        s.append(stroke(closed(rect(basket.x - 0.02, basket.y - 0.008, basket.x + 0.02, basket.y + 0.022)), 0.0036))
        s.append(stroke([basket + P(-0.02, 0.006), basket + P(0.02, 0.006)], 0.0016))
        s.append(stroke(circle(basket + P(-0.004, -0.02), 0.0055, 8), 0.003))
        s.append(stroke([basket + P(-0.004, -0.014), basket + P(-0.004, -0.008)], 0.003))
        s.append(stroke([basket + P(-0.004, -0.012), basket + P(0.012, -0.03)], 0.002))
        // The ducks: one and two behind, each with its wake.
        for (k, x) in [0.0, -0.05, -0.085].enumerated() {
            let z = k == 0 ? 1.0 : 0.55, at = duck + P(x, k == 0 ? 0 : 0.008)
            let body: [P] = squash(arc(at, 0.02 * z, 0, 180, 8), about: at.y, by: 0.6) + [at + P(-0.03 * z, -0.006 * z), at + P(0.02 * z, 0)]
            s.append(stroke(body, k == 0 ? 0.0036 : 0.0026))
            s.append(stroke(circle(at + P(0.022 * z, -0.016 * z), 0.008 * z, 8), k == 0 ? 0.0036 : 0.0026))
            s.append(stroke([at + P(0.03 * z, -0.016 * z), at + P(0.042 * z, -0.012 * z)], 0.0024))
            s.append(stroke(curve(at + P(-0.03 * z, 0.016 * z), at + P(0, 0.022 * z), at + P(0.034 * z, 0.016 * z), 5), 0.0014))
        }
        return panel("viewfinder", fills: fills, strokes: s) { _ in c(0.2) }
    }()
}

// MARK: - 22: Wide angle

/// Level 22's name: a street taken wide, its buildings leaning in to a point over the hub, where a tram is coming; a
/// cat in a window over the upper right core and a bicycle on the pavement over the lower left (hex's three lenses on
/// this level). Level 22 deals each lens +3 in all.
extension LensArt {
    static let wideAngle: Halftone.Panel = {
        let far = P(0, 0.04), tram = far + P(0.014, -0.024), cat = P(0.485, -0.28) + P(0.012, -0.02), bike = P(-0.485, 0.28) + P(0.006, -0.02)
        // A point `t` of the way from the picture's edge to the far point.
        func back(_ from: P, _ t: Double) -> P { from + (far - from) * t }
        func wall(_ side: Double) -> [P] { [P(side * 1.1, -1.6), back(P(side * 1.1, -1.6), 0.86), back(P(side * 1.1, 0.72), 0.86), P(side * 1.1, 0.72)] }
        var fills = [fill(rect(tram.x - 0.03, tram.y - 0.03, tram.x + 0.03, tram.y + 0.04), y(0.9))]
        for side in [-1.0, 1.0] {
            for row in 0..<4 {
                for col in 0..<5 where (row + col + (side > 0 ? 1 : 0)) % 3 != 0 {
                    let y0 = -1.3 + 0.44 * Double(row), t0 = 0.1 + 0.15 * Double(col)
                    let q: [P] = [back(P(side * 1.1, y0), t0), back(P(side * 1.1, y0), t0 + 0.09), back(P(side * 1.1, y0 + 0.26), t0 + 0.09),
                                  back(P(side * 1.1, y0 + 0.26), t0)]
                    fills.append(fill(q, y(0.75)))
                }
            }
        }
        fills += [fill(wall(-1), m(0.5)), fill(wall(1), c(0.5)), fill([far, P(-0.5, 1.1), P(0.5, 1.1)], c(0.3)),
                  fill([far, P(-1.1, 0.72), P(-1.1, 1.1), P(1.1, 1.1), P(1.1, 0.72)], m(0.22))]

        var s: [Halftone.Stroke] = []
        // The walls' edges and floors, every line to the far point, and the windows' frames.
        for side in [-1.0, 1.0] {
            let w = wall(side)
            s.append(stroke([w[0], w[1], w[2], w[3]], bold))
            for row in 0..<5 { s.append(stroke([P(side * 1.1, -1.38 + 0.44 * Double(row)), back(P(side * 1.1, -1.38 + 0.44 * Double(row)), 0.86)], hair)) }
            for row in 0..<4 {
                for col in 0..<5 {
                    let y0 = -1.3 + 0.44 * Double(row), t0 = 0.1 + 0.15 * Double(col)
                    s.append(stroke(closed([back(P(side * 1.1, y0), t0), back(P(side * 1.1, y0), t0 + 0.09), back(P(side * 1.1, y0 + 0.26), t0 + 0.09),
                                            back(P(side * 1.1, y0 + 0.26), t0)]), hair))
                }
            }
            // The kerb, and a lamp post on each side, the left one nearer.
            s.append(stroke([far, P(side * 0.5, 1.1)], mid))
            let post = back(P(side * 0.8, 0.9), side < 0 ? 0.3 : 0.55), height = side < 0 ? 0.62 : 0.4
            s.append(stroke([post, post + P(0, -height), post + P(-side * 0.1, -height - 0.03)], bold))
            s.append(stroke(circle(post + P(-side * 0.1, -height), 0.03, 10), mid))
        }
        // A drain's grating in the road, a puddle beside it,
        s.append(stroke(closed([P(0.1, 0.62), P(0.2, 0.62), P(0.24, 0.72), P(0.12, 0.72)]), mid))
        for k in 1..<4 { s.append(stroke([P(0.1 + 0.025 * Double(k), 0.62), P(0.12 + 0.03 * Double(k), 0.72)], hair)) }
        s.append(stroke(ellipse(P(-0.16, 0.56), 0.09, 0.03, 16), hair))
        // the road's middle line, in dashes that close up with distance, and the wires overhead.
        for k in 0..<6 { s.append(stroke([back(P(0, 1.1), 0.12 + 0.15 * Double(k)), back(P(0, 1.1), 0.2 + 0.15 * Double(k))], mid)) }
        s.append(stroke(curve(P(-1, -0.9), P(-0.3, -0.3), far + P(0, -0.07), 16), hair))
        s.append(stroke(curve(P(1, -0.98), P(0.3, -0.34), far + P(0, -0.07), 16), hair))
        // The tram, head on: body, two windows, lamp, its pole to the wire and the rails.
        s.append(stroke(closed(rect(tram.x - 0.03, tram.y - 0.03, tram.x + 0.03, tram.y + 0.04)), 0.004))
        for x in [-0.022, 0.004] { s.append(stroke(closed(rect(tram.x + x, tram.y - 0.02, tram.x + x + 0.018, tram.y + 0.002)), 0.002)) }
        s.append(stroke(circle(tram + P(0, 0.022), 0.006, 8), 0.003))
        s.append(stroke([tram + P(0, -0.03), tram + P(0.008, -0.05), tram + P(-0.016, -0.056)], 0.002))
        s.append(stroke([tram + P(-0.02, 0.04), tram + P(-0.05, 0.11)], 0.002))
        s.append(stroke([tram + P(0.02, 0.04), tram + P(0.05, 0.11)], 0.002))
        // The cat in its window: sat up, ears, tail hung over the sill.
        s.append(stroke(closed(rect(cat.x - 0.05, cat.y - 0.07, cat.x + 0.05, cat.y + 0.04)), 0.002))
        s.append(stroke(squash(arc(cat + P(0, 0.04), 0.03, 180, 360, 8), about: cat.y + 0.04, by: 1.5), 0.004))
        s.append(stroke(closed([cat + P(-0.014, -0.02), cat + P(-0.016, -0.046), cat + P(-0.004, -0.034), cat + P(0.004, -0.034), cat + P(0.016, -0.046),
                                cat + P(0.014, -0.02), cat + P(0, -0.008)]), 0.0036))
        for x in [-0.006, 0.006] { s.append(stroke(circle(cat + P(x, -0.024), 0.0016, 6), 0.0024)) }
        s.append(stroke(curve(cat + P(0.03, 0.04), cat + P(0.05, 0.06), cat + P(0.036, 0.08), 6), 0.003))
        // The bicycle against the wall: wheels, frame, saddle and bars.
        for x in [-0.034, 0.034] {
            s.append(stroke(circle(bike + P(x, 0.016), 0.022, 16), 0.0036))
            s.append(stroke(circle(bike + P(x, 0.016), 0.002, 6), 0.003))
        }
        s.append(stroke(closed([bike + P(-0.034, 0.016), bike + P(-0.012, -0.02), bike + P(0.022, -0.02), bike + P(0.0, 0.016)]), 0.003))
        s.append(stroke([bike + P(0.034, 0.016), bike + P(0.022, -0.02), bike + P(0.02, -0.036), bike + P(0.034, -0.04)], 0.003))
        s.append(stroke([bike + P(-0.012, -0.02), bike + P(-0.014, -0.03)], 0.003))
        s.append(stroke([bike + P(-0.024, -0.03), bike + P(-0.004, -0.03)], 0.004))
        return panel("wideangle", fills: fills, strokes: s) { _ in y(0.26) }
    }()
}

// MARK: - 23: Fisheye

/// Level 23's name, taken at its word: a fish, close, its eye over the hub (hex's lens on this level), and in the eye
/// what it is looking at, a hook with a worm on it. Level 23 deals the lens +1 three times.
extension LensArt {
    static let fisheye: Halftone.Panel = {
        let eye = P(0, 0), hook = eye + P(0.016, -0.016)
        let brow = curve(P(1.1, -0.66), P(-0.9, -0.82), P(-0.88, 0.06), 24), jaw = curve(P(-0.86, 0.22), P(-0.8, 0.92), P(1.1, 0.82), 24)
        let head = brow + [P(-0.72, 0.14)] + jaw
        func band(_ x: Double, _ w: Double) -> [P] {
            curve(P(x, -0.9), P(x - 0.16, 0), P(x, 0.95), 12) + curve(P(x + w, 0.95), P(x + w - 0.16, 0), P(x + w, -0.9), 12)
        }
        let fin = [P(0.42, 0.3), P(0.9, 0.42), P(0.86, 0.72), P(0.56, 0.62)]
        let fills = [disc(eye, 0.095, .zero), disc(eye, 0.18, c(0.5)), disc(eye, 0.225, y(0.9)), fill(fin, y(0.8)),
                     fill(head.filter { _ in true }.map { $0 }, y(0.5))]
        let stripes = [band(0.26, 0.2), band(0.72, 0.4)]
        let striped = stripes.map { fill($0, m(0.7)) }
        let all = Array(fills.prefix(4)) + striped + [fills[4]]

        var s: [Halftone.Stroke] = []
        // The fish: brow and jaw, the mouth open, its lips, the gill's edge, the bands and the fin's rays.
        s.append(stroke(brow, bold))
        s.append(stroke(jaw, bold))
        s.append(stroke([P(-0.88, 0.06), P(-0.72, 0.14), P(-0.86, 0.22)], bold))
        s.append(stroke(curve(P(-0.72, 0.14), P(-0.6, 0.18), P(-0.52, 0.3), 8), mid))
        s.append(stroke(curve(P(0.2, -0.62), P(0.5, 0.0), P(0.16, 0.7), 20), bold))
        for q in stripes { s += runs(q + [q[0]], mid) { Halftone.inside($0, head) } }
        s.append(stroke(closed(fin), bold))
        for k in 1..<5 { s.append(stroke([fin[0] + (fin[3] - fin[0]) * (Double(k) / 5), fin[1] + (fin[2] - fin[1]) * (Double(k) / 5)], hair)) }
        for (k, at) in [P(-0.4, -0.3), P(-0.56, -0.12), P(-0.3, 0.42), P(-0.1, 0.5), P(-0.46, 0.5), P(-0.2, -0.46)].enumerated() {
            s.append(stroke(arc(at, 0.06, 100 + 10 * Double(k), 250 + 10 * Double(k), 8), hair))
        }
        for at in [P(-0.74, -0.02), P(-0.66, -0.03)] { s.append(stroke(circle(at, 0.012, 6), mid)) }
        // The water: bubbles from the mouth, and weed.
        for (k, at) in [P(-0.9, -0.2), P(-0.82, -0.42), P(-0.9, -0.62), P(-0.7, -0.7)].enumerated() { s.append(stroke(circle(at, 0.03 + 0.008 * Double(k), 12), mid)) }
        // The eye: its gold ring, the iris and its rays, the pupil.
        s.append(stroke(circle(eye, 0.225, 56), bold))
        s.append(stroke(circle(eye, 0.18, 48), mid))
        s.append(stroke(circle(eye, 0.095, 36), bold))
        for k in 0..<24 { s.append(stroke([polar(eye, 0.11, 15 * Double(k) + 5), polar(eye, k % 2 == 0 ? 0.165 : 0.14, 15 * Double(k) + 5)], hair)) }
        // In the pupil: the line down, the hook and its barb, and the worm on it.
        s.append(stroke([hook + P(0, -0.07), hook + P(0, 0.006)], 0.002))
        s.append(stroke(circle(hook + P(0, -0.004), 0.004, 6), 0.002))
        s.append(stroke([hook + P(0, 0.006)] + arc(hook + P(-0.012, 0.018), 0.012, 0, 170, 10) + [hook + P(-0.018, 0.01)], 0.004))
        s.append(stroke([hook + P(-0.024, 0.016), hook + P(-0.016, 0.02)], 0.003))
        s.append(stroke(curve(hook + P(-0.004, 0.03), hook + P(0.02, 0.05), hook + P(0.028, 0.026), 6) + curve(hook + P(0.028, 0.026), hook + P(0.034, 0.008), hook + P(0.046, 0.02), 6), 0.004))
        return panel("fisheye", fills: all, strokes: s) { _ in c(0.3) }
    }()
}

// MARK: - 24: Telephoto

/// Level 24's name: a long lens from behind the camera, aimed at an eagle far off on a dead branch, over the top core,
/// and the same eagle near on the camera's screen, over the bottom one (eye's two small lenses on this level). Level 24
/// deals each lens +3 in all.
extension LensArt {
    static let telephoto: Halftone.Panel = {
        let far = P(0.012, -0.585), near = P(0.012, 0.535)
        let back = squircle(P(0, 0.6), 0.5, 0.3), screen = rect(-0.22, 0.42, 0.22, 0.72)
        let barrel = [P(-0.15, 0.3), P(0.15, 0.3), P(0.2, -0.12), P(-0.2, -0.12)]
        let hood = [P(-0.21, -0.12), P(0.21, -0.12)] + curve(P(0.225, -0.36), P(0, -0.42), P(-0.225, -0.36), 10)
        // A band round the barrel at `at`, `deep` down it, bowed as a ring seen from behind and below is.
        func band(_ at: Double, _ deep: Double) -> [P] {
            let w0 = 0.15 + 0.05 * (0.3 - at) / 0.42, w1 = 0.15 + 0.05 * (0.3 - at - deep) / 0.42
            return curve(P(-w0, at), P(0, at - 0.05), P(w0, at), 10) + curve(P(w1, at + deep), P(0, at + deep - 0.05), P(-w1, at + deep), 10)
        }
        let hills = [curve(P(-1, 0.2), P(-0.5, -0.12), P(-0.05, 0.2), 12), curve(P(0.1, 0.2), P(0.6, -0.04), P(1, 0.2), 12)]
        var fills = [fill(screen, c(0.25)), fill(rect(-0.1, 0.24, 0.1, 0.32), m(0.8)), disc(P(0.36, 0.56), 0.07, y(0.6)), fill(back, m(0.6)),
                     fill(band(-0.06, 0.03), m(0.9)), fill(band(0.2, -0.12), y(0.7)), fill(hood, m(0.8)),
                     fill(barrel, y(0.3))]
        fills += hills.map { fill($0, m(0.36)) }
        fills.append(fill(rect(-1, 0.2, 1, 1), Tone(0.3, 0, 0.34)))

        var s: [Halftone.Stroke] = []
        // The hills, a sun low between them, grass, and the dead branch in from the right.
        for q in hills { s.append(stroke(q, mid)) }
        s.append(stroke(arc(P(-0.56, 0.02), 0.1, 200, 340, 10), hair))
        for (k, x) in [-0.84, -0.66, 0.6, 0.78, 0.9].enumerated() {
            let foot = P(x, 0.4 + 0.12 * Double(k % 3))
            for t in [-112.0, -90, -64] { s.append(stroke([foot, polar(foot, 0.06, t)], hair)) }
        }
        let branch = curve(P(1, -0.24), P(0.5, -0.4), far + P(-0.1, 0.07), 16)
        s.append(stroke(branch, bold))
        s.append(stroke(curve(branch[6], P(0.56, -0.62), P(0.5, -0.76), 8), mid))
        s.append(stroke(curve(branch[11], P(0.3, -0.3), P(0.22, -0.2), 6), mid))
        // The eagle, far: body, head and hooked beak, wing's edge, tail, feet on the branch.
        s.append(stroke(ellipse(far + P(0, 0.016), 0.02, 0.036, degrees: 8, 18), 0.0036))
        s.append(stroke(circle(far + P(-0.006, -0.03), 0.012, 10), 0.0036))
        s.append(stroke([far + P(-0.017, -0.032), far + P(-0.03, -0.027), far + P(-0.026, -0.018)], 0.003))
        s.append(stroke(circle(far + P(-0.009, -0.033), 0.0014, 5), 0.002))
        s.append(stroke(curve(far + P(0.012, -0.012), far + P(0.022, 0.02), far + P(0.012, 0.05), 6), 0.002))
        s.append(stroke([far + P(0.006, 0.05), far + P(0.014, 0.078), far + P(0.022, 0.05)], 0.003))
        for x in [-0.01, 0.004] { s.append(stroke([far + P(x, 0.05), far + P(x - 0.002, 0.062)], 0.003)) }
        // The lens from behind: the barrel widening to its hood, the hood's mouth, the focus ring and the red one.
        s.append(stroke([barrel[0], barrel[3]], bold))
        s.append(stroke([barrel[1], barrel[2]], bold))
        s.append(stroke(Array(hood[1...]) + [hood[0]], bold))
        for x in [-0.12, -0.04, 0.04, 0.12] { s.append(stroke([P(x, -0.17 + x * x), P(x * 1.07, -0.38 + x * x)], hair)) }
        s.append(stroke(curve(P(-0.2, -0.12), P(0, -0.17), P(0.2, -0.12), 10), mid))
        for q in [band(-0.06, 0.03), band(0.2, -0.12)] {
            s.append(stroke(Array(q.prefix(11)), mid))
            s.append(stroke(Array(q.suffix(11)), mid))
        }
        for k in 0..<9 {
            let x = -0.14 + 0.035 * Double(k)
            s.append(stroke([P(x, 0.185 - 0.05 * (1 - (x / 0.16) * (x / 0.16))), P(x * 1.08, 0.095 - 0.05 * (1 - (x / 0.17) * (x / 0.17)))], hair))
        }
        // The camera's back: body, finder, screen, the dial and its buttons, and the thumbs holding it.
        s.append(stroke(closed(back), bold))
        s.append(stroke(closed(rect(-0.1, 0.24, 0.1, 0.32)), mid))
        s.append(stroke(closed(screen), bold))
        s.append(stroke(circle(P(0.36, 0.56), 0.07, 20), mid))
        s.append(stroke(circle(P(0.36, 0.56), 0.03, 12), hair))
        for (k, at) in [P(-0.36, 0.46), P(-0.36, 0.58), P(-0.36, 0.7), P(0.36, 0.74)].enumerated() { s.append(stroke(circle(at, k == 3 ? 0.03 : 0.024, 10), mid)) }
        for side in [-1.0, 1.0] { s.append(stroke(arc(P(side * 0.56, 0.84), 0.12, side < 0 ? 250 : 190, side < 0 ? 350 : 290, 10), bold)) }
        // On the screen: the eagle near. Its head, the brow over the eye, the beak, and the focus marks round it.
        for (sx, sy) in [(-1.0, -1.0), (1, -1), (1, 1), (-1, 1)] {
            let at = P(sx * 0.16, 0.57 + sy * 0.1)
            s.append(stroke([at + P(-sx * 0.03, 0), at, at + P(0, -sy * 0.03)], hair))
        }
        s.append(stroke(arc(near + P(0.01, 0.0), 0.04, 150, 400, 20), 0.004))
        s.append(stroke([near + P(-0.024, -0.02), near + P(-0.062, -0.006), near + P(-0.066, 0.022), near + P(-0.05, 0.012), near + P(-0.026, 0.016)], 0.004))
        s.append(stroke([near + P(-0.03, -0.022), near + P(0.014, -0.02)], 0.004))
        s.append(stroke(circle(near + P(-0.006, -0.008), 0.007, 8), 0.003))
        s.append(stroke(circle(near + P(-0.006, -0.008), 0.0016, 5), 0.003))
        for k in 0..<4 { s.append(stroke(arc(near + P(0.006 + 0.016 * Double(k % 2), 0.05 + 0.012 * Double(k / 2)), 0.01, 20, 160, 4), 0.0016)) }
        return panel("telephoto", fills: fills, strokes: s) { _ in c(0.2) }
    }()
}

// MARK: - 25: Kaleidoscope

/// Level 25's name: the pattern in a kaleidoscope, one wedge of coloured glass mirrored twelve times round the hub,
/// and over the hub and three of the ring's cores (hex's four lenses on this level) the loose things that make it,
/// each on its own: a star, a paper clip, a moon and a heart. Level 25 deals its lenses +3, +3, +3 and +2.
extension LensArt {
    static let kaleidoscope: Halftone.Panel = {
        // The wedge, from 0 to 30 degrees, as (radius, degrees) corners and a tone.
        let wedge: [([(Double, Double)], Tone)] = [
            ([(0.06, 0), (0.25, 0), (0.2, 30), (0.06, 30)], y(0.75)),
            ([(0.25, 0), (0.52, 0), (0.42, 21)], m(0.7)),
            ([(0.25, 0), (0.42, 21), (0.5, 30), (0.2, 30)], c(0.6)),
            ([(0.52, 0), (0.84, 0), (0.64, 18)], c(0.75)),
            ([(0.52, 0), (0.64, 18), (0.8, 30), (0.5, 30), (0.42, 21)], y(0.55)),
            ([(0.84, 0), (1.1, 0), (1.1, 15), (0.64, 18)], m(0.45)),
            ([(0.64, 18), (1.1, 15), (1.1, 30), (0.8, 30)], Tone(0.4, 0, 0.4)),
        ]
        let shards = wedge.map { fill($0.0.map { polar(P(0, 0), $0.0, $0.1) }, $0.1) }
        let things = [P(0.016, -0.02), P(0, -0.56) + P(0.014, -0.024), P(0.485, 0.28) + P(0.012, -0.024), P(-0.485, 0.28) + P(0.012, -0.022)]

        var s: [Halftone.Stroke] = []
        // Every shard's edge, in each of the twelve wedges, a mirror between each pair.
        for k in 0..<12 {
            let turn = 60 * Double(k / 2), flip = k % 2 == 0 ? 1.0 : -1.0
            for (corners, _) in wedge {
                let q = corners.map { polar(P(0, 0), $0.0, turn + flip * $0.1) }
                s += runs(closed(q)) { p in things.allSatisfy { simd_distance(p, $0) > 0.055 } }
            }
        }
        s.append(stroke(circle(P(0, 0), 0.06, 20), mid))
        // The loose things: a star at the hub, a paper clip, a moon and a heart.
        s.append(stroke(star(things[0], 0.022, degrees: -80), 0.004))
        let clip = things[1]
        s.append(stroke([clip + P(-0.012, 0.02), clip + P(-0.012, -0.018)] + arc(clip + P(0, -0.018), 0.012, 180, 360, 8)
            + [clip + P(0.012, 0.022)] + arc(clip + P(0.004, 0.022), 0.008, 0, 180, 6) + [clip + P(-0.004, -0.012)]
            + arc(clip + P(0.001, -0.012), 0.005, 180, 360, 5) + [clip + P(0.006, 0.014)], 0.003))
        let moon = things[2]
        s.append(stroke(arc(moon, 0.024, 60, 300, 16) + arc(moon + P(0.016, 0), 0.019, 240, 120, 12), 0.004))
        let heart = things[3]
        s.append(stroke(closed(arc(heart + P(-0.011, -0.006), 0.011, 150, 360, 8) + arc(heart + P(0.011, -0.006), 0.011, 180, 390, 8)
            + [heart + P(0, 0.022)]), 0.004))
        return panel("kaleidoscope", fills: [], strokes: s) { p in
            // Folded into the wedge: twelve mirrors, so the pattern costs one wedge's test a pixel.
            let r = simd_length(p)
            var a = atan2(p.y, p.x) * 180 / .pi
            a = (a + 360).truncatingRemainder(dividingBy: 60)
            if a > 30 { a = 60 - a }
            let q = polar(P(0, 0), r, a)
            for f in shards where f.holds(q) { return f.tone }
            return .zero
        }
    }()
}
