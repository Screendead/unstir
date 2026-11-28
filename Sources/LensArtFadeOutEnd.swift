// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 87 to 90, the end of the chapter Fade out.

extension LensArt {
    /// This chapter's last drawn panels by their level's number.
    static let fadeOutEnd: [Int: Halftone.Panel] = [87: rearwindow, 88: lantern, 89: dreamcatcher, 90: irisout]

    /// Hex's rods, the hub first.
    fileprivate static let hex: [P] = [P(0, 0), P(0, -0.56), P(0.485, -0.28), P(0.485, 0.28), P(0, 0.56), P(-0.485, 0.28), P(-0.485, -0.28)]
    /// A hex core's radius.
    fileprivate static let core = 0.264

    /// p's bearing about c in degrees, 0 to 360, 0 at three o'clock and clockwise on screen.
    fileprivate static func bearing(_ p: P, _ c: P) -> Double {
        let a = atan2(p.y - c.y, p.x - c.x) * 180 / .pi
        return a < 0 ? a + 360 : a
    }

    /// A line cut where it passes within `r` of any of `centres`, its segments split finely enough for the cut to fall
    /// close to the circle.
    fileprivate static func outside(_ line: [P], _ width: Double, of centres: [P], by r: Double) -> [Halftone.Stroke] {
        guard centres.contains(where: { distance($0, line) <= r }) else { return [stroke(line, width)] }
        var fine = [line[0]]
        for j in 1..<line.count { fine += span(line[j - 1], line[j], max(1, Int((simd_distance(line[j - 1], line[j]) / 0.008).rounded(.up)))).dropFirst() }
        return runs(fine, width) { p in centres.allSatisfy { simd_distance(p, $0) > r } }
    }

    /// The scene's strokes cut clear of the lens cores, so only a lens's own clue and frame show magnified in it.
    fileprivate static func clear(_ strokes: [Halftone.Stroke], of centres: [P], by r: Double = core + 0.004) -> [Halftone.Stroke] {
        strokes.flatMap { outside($0.points, $0.width, of: centres, by: r) }
    }

    /// Strokes with long reaches cut into pieces of at most `n` segments, as the bake tests every segment of a stroke
    /// at each pixel in its box.
    fileprivate static func pieces(_ strokes: [Halftone.Stroke], _ n: Int = 12) -> [Halftone.Stroke] {
        strokes.flatMap { s -> [Halftone.Stroke] in
            let lo = s.points.reduce(s.points[0], simd_min), hi = s.points.reduce(s.points[0], simd_max)
            guard s.points.count > n + 1, simd_distance(lo, hi) > 0.12 else { return [s] }
            return stride(from: 0, to: s.points.count - 1, by: n).map { stroke(Array(s.points[$0...min($0 + n, s.points.count - 1)]), s.width) }
        }
    }

    /// The tone of a frame cut into runs: `cuts` are the bearings where each run starts, in order, and `tones` the run
    /// each starts, the last run wrapping to the first cut.
    fileprivate static func runTone(_ a: Double, _ cuts: [Double], _ tones: [Tone]) -> Tone {
        var k = cuts.count - 1
        for (i, cut) in cuts.enumerated() where a >= cut { k = i }
        return tones[k % tones.count]
    }

    /// Draws the strokes from `start` on, a clue, `scale` their size about their middle, then moves them straight out
    /// from their lens core's centre until they clear the knob there by 0.022, as a clue must.
    fileprivate static func fit(_ s: inout [Halftone.Stroke], from start: Int, core c: P, scale: Double = 1) {
        let all: [P] = s[start...].flatMap(\.points), g: P = all.reduce(P(0, 0), +) / Double(all.count)
        for i in start..<s.count { s[i].points = s[i].points.map { g + ($0 - g) * scale } }
        let drawn: [P] = s[start...].flatMap(\.points)
        let u: P = simd_length(g - c) > 0.001 ? simd_normalize(g - c) : P(0, 1)
        var shift = 0.0
        while drawn.contains(where: { simd_distance($0 + u * shift, c) < 0.022 }) { shift += 0.002 }
        for i in start..<s.count { s[i].points = s[i].points.map { $0 + u * shift } }
    }

    /// Lines drawn about the origin, moved to `at` and scaled by `k`.
    fileprivate static func place(_ lines: [[P]], at: P, _ k: Double = 1) -> [[P]] {
        lines.map { $0.map { at + k * $0 } }
    }
}

// MARK: - 87: Rear window

/// Level 87's name: the back of an apartment block at night, seen across its courtyard, the windows in their rows dark,
/// lit or with the blind half down, a fire escape zigzagging down the middle, the lower block on the right with its
/// water tank under the moon, and over hex's four lenses on this level four windows looked into, curtains drawn back
/// either side of the lit room: a dancer in arabesque (top), a salesman carrying out his big suitcase (lower right), a
/// little dog let down in a basket on a rope (bottom) and a songwriter at his grand piano (upper left).
extension LensArt {
    static let rearwindow: Halftone.Panel = drawRearwindow()

    /// The facing block's window holding p, if any: its middle and whether it is dark (0), lit (1) or half blind (2).
    fileprivate static func pane(_ p: P) -> (at: P, kind: Int)? {
        let i = ((p.x + 0.9) / 0.2).rounded(), j = ((p.y + 0.72) / 0.22).rounded()
        let at = P(-0.9 + 0.2 * i, -0.72 + 0.22 * j)
        guard abs(p.x - at.x) < 0.058, abs(p.y - at.y) < 0.075, at.y < 0.8, at.y > roofline(at.x) + 0.08 else { return nil }
        let n = Int(i) * 7 + Int(j) * 5 + Int(i) * Int(j) * 3
        return (at, [0, 1, 0, 2, 1, 0, 0][n % 7])
    }

    /// The roof's line: the tall block on the left, the low one from x 0.26.
    fileprivate static func roofline(_ x: Double) -> Double { x < 0.26 ? -0.86 : -0.52 }

    private static func drawRearwindow() -> Halftone.Panel {
        let views: [P] = [hex[1], hex[3], hex[4], hex[6]]
        let moon = P(0.46, -0.76), tank = P(0.76, -0.6)
        let landings: [Double] = [-0.41, -0.19, 0.03, 0.25, 0.47]
        let escape: [Fill] = landings.map { fill(rect(-0.24, $0, 0.22, $0 + 0.045), .zero) }
            + zip(landings, landings.dropFirst()).enumerated().map { (k: Int, ys: (Double, Double)) -> Fill in
                let down = k % 2 == 0
                return fill(bar(P(down ? -0.2 : 0.18, ys.0 + 0.045), P(down ? 0.14 : -0.16, ys.1), 0.032), .zero)
            }
        var s: [Halftone.Stroke] = []
        rearwindowBlocks(&s)
        rearwindowEscape(&s, moon: moon, tank: tank, landings: landings)
        s = clear(s, of: views, by: core + 0.05)
        rearwindowFrames(&s, views)
        rearwindowClues(&s, views)
        rearwindowCluesBelow(&s, views)
        return Halftone.Panel(name: "rearwindow", tones: rearwindowTones(views, moon: moon, tank: tank, escape: escape), strokes: pieces(s))
    }

    private static func rearwindowBlocks(_ s: inout [Halftone.Stroke]) {
        // The blocks: the roof's cornice, the low block's parapet, every window's frame and sill.
        s.append(stroke([P(-1, -0.86), P(0.26, -0.86), P(0.26, -0.52), P(1, -0.52)], bold))
        s.append(stroke([P(-1, -0.83), P(0.26, -0.83)], hair))
        for i in 0..<10 {
            for j in 0..<8 {
                let at = P(-0.9 + 0.2 * Double(i), -0.72 + 0.22 * Double(j))
                guard at.y < 0.8, at.y > roofline(at.x) + 0.08, simd_length(at) < 0.97 else { continue }
                s.append(stroke(closed(rect(at.x - 0.058, at.y - 0.075, at.x + 0.058, at.y + 0.075)), mid))
                s.append(stroke([P(at.x - 0.07, at.y + 0.085), P(at.x + 0.07, at.y + 0.085)], mid))
                s.append(stroke([P(at.x, at.y - 0.075), P(at.x, at.y + 0.075)], hair))
            }
        }
    }

    private static func rearwindowEscape(_ s: inout [Halftone.Stroke], moon: P, tank: P, landings: [Double]) {
        // The fire escape: its landings' rails and the stairs between them, and the ladder at its foot.
        for (k, yy) in landings.enumerated() {
            s.append(stroke([P(-0.24, yy - 0.05), P(0.22, yy - 0.05)], hair))
            for x in stride(from: -0.24, through: 0.23, by: 0.046) { s.append(stroke([P(x, yy - 0.05), P(x, yy)], hair)) }
            guard k + 1 < landings.count else { continue }
            let down = k % 2 == 0
            let a = P(down ? -0.2 : 0.18, yy + 0.035), b = P(down ? 0.14 : -0.16, landings[k + 1])
            s.append(stroke([a, b], mid))
            s.append(stroke([a + P(0, -0.04), b + P(0, -0.04)], hair))
            for t in stride(from: 0.1, to: 1, by: 0.12) { let q = a + (b - a) * t; s.append(stroke([q, q + P(0, -0.03)], hair)) }
        }
        for x in [-0.2, -0.16] { s.append(stroke([P(x, 0.505), P(x, 0.7)], mid)) }
        // The low block's water tank on its legs, and the moon over it.
        s.append(stroke(closed(rect(tank.x - 0.07, tank.y - 0.14, tank.x + 0.07, tank.y - 0.02)), mid))
        s.append(stroke([tank + P(-0.07, -0.14), tank + P(0, -0.19), tank + P(0.07, -0.14)], mid))
        for x in [-0.06, 0.06] { s.append(stroke([tank + P(x, -0.02), tank + P(x, 0.08)], mid)) }
        s.append(stroke([tank + P(-0.06, 0.04), tank + P(0.06, 0.0)], hair))
        s.append(stroke(circle(moon, 0.07, 28), mid))
        for at in [P(0.4, -0.84), P(0.84, -0.4), P(0.52, -0.56)] { s += glint(at, 0.025, hair) }
        // The courtyard's fence along the foot.
        s.append(stroke([P(-0.5, 0.88), P(0.5, 0.88)], mid))
        for x in stride(from: -0.46, through: 0.46, by: 0.06) { s.append(stroke([P(x, 0.85), P(x, 0.98)], hair)) }
    }

    private static func rearwindowFrames(_ s: inout [Halftone.Stroke], _ views: [P]) {
        // Each window looked into: its frame inside the round view, the sash, the curtains' edges, the round view's rim.
        for (k, c) in views.enumerated() {
            s.append(stroke(circle(c, core, 56), bold))
            s.append(stroke(circle(c, core + 0.05, 56), mid))
            for j in 0..<10 { let a = 36 * Double(j) + 11 * Double(k); s.append(stroke([polar(c, core + 0.01, a), polar(c, core + 0.04, a + 5)], hair)) }
            s.append(stroke([c + P(-0.16, -0.2), c + P(0.18, -0.2)], mid))
            s += runs(span(c + P(-0.16, -0.2), c + P(-0.16, 0.25), 30), mid) { simd_distance($0, c) < core }
            s += runs(span(c + P(0.18, -0.2), c + P(0.18, 0.25), 30), mid) { simd_distance($0, c) < core }
            for e in [-0.19, -0.215] { s += runs(span(c + P(e, -0.24), c + P(e, 0.25), 30), hair) { simd_distance($0, c) < core - 0.004 } }
            for e in [0.21, 0.235] { s += runs(span(c + P(e, -0.24), c + P(e, 0.25), 30), hair) { simd_distance($0, c) < core - 0.004 } }
        }
    }

    private static func rearwindowTones(_ views: [P], moon: P, tank: P, escape: [Fill]) -> @Sendable (P) -> Tone {
        let cuts: [Double] = [0, 34, 70, 96, 140, 172, 208, 236, 280, 316]
        let frame: [Tone] = [c(0.55), .zero, y(0.5), .zero]
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, v) in views.enumerated() {
                let q = p - v, d = simd_length(q)
                if d < core {
                    if q.y < -0.2 { return Tone(0, 0.35, 0.55) }
                    if q.x < -0.16 || q.x > 0.18 { return m(0.7) }
                    return k % 2 == 0 ? y(0.85) : Tone(0, 0.15, 0.85)
                }
                if d < core + 0.05 { return runTone((bearing(p, v) + 41 * Double(k)).truncatingRemainder(dividingBy: 360), cuts, frame) }
            }
            if p.y < roofline(p.x) {
                if simd_distance(p, moon) < 0.07 { return y(0.8) }
                return c(0.25)
            }
            if p.x > tank.x - 0.07, p.x < tank.x + 0.07, p.y > tank.y - 0.14, p.y < tank.y - 0.02 { return m(0.4) }
            for f in escape where f.holds(p) { return .zero }
            if let w = pane(p) {
                switch w.kind {
                case 1: return y(0.8)
                case 2: return p.y < w.at.y ? Tone(0, 0.4, 0.3) : y(0.75)
                default: return c(0.5)
                }
            }
            if p.y > 0.84 { return c(0.3) }
            return m(0.42)
        }
        return tones
    }

    /// What each window shows: a dancer, the salesman's suitcase, the dog's basket, the songwriter's piano.
    private static func rearwindowClues(_ s: inout [Halftone.Stroke], _ views: [P]) {
        var mark = s.count
        let dancer = views[0] + P(0.022, 0.022)
        s.append(stroke(circle(dancer + P(-0.004, -0.046), 0.009, 10), 0.0034))
        s.append(stroke([dancer + P(-0.002, -0.036), dancer + P(0.004, 0.0), dancer + P(0.0, 0.048)], 0.0034))
        s.append(stroke([dancer + P(0.004, 0.0), dancer + P(0.05, -0.024)], 0.003))
        s.append(stroke([dancer + P(-0.046, -0.044), dancer + P(0.0, -0.026), dancer + P(0.042, -0.056)], 0.0026))
        s.append(stroke(closed(ellipse(dancer + P(0.003, 0.002), 0.022, 0.006, degrees: -10, 14)), 0.0026))
        fit(&s, from: mark, core: views[0], scale: 0.55)
        mark = s.count
        let man = views[1] + P(-0.02, 0.025)
        s.append(stroke(circle(man + P(-0.018, -0.044), 0.009, 10), 0.0034))
        s.append(stroke([man + P(-0.034, -0.052), man + P(-0.002, -0.052)], 0.003))
        s.append(stroke([man + P(-0.018, -0.034), man + P(-0.018, 0.01), man + P(-0.03, 0.05)], 0.0034))
        s.append(stroke([man + P(-0.018, 0.01), man + P(-0.004, 0.05)], 0.0034))
        s.append(stroke([man + P(-0.018, -0.024), man + P(0.008, 0.0)], 0.003))
        s.append(stroke(closed(rect(man.x + 0.002, man.y + 0.004, man.x + 0.06, man.y + 0.042)), 0.0034))
        s.append(stroke(arc(man + P(0.018, 0.004), 0.008, 180, 360, 6), 0.0026))
        for x in [0.02, 0.044] { s.append(stroke([man + P(x, 0.004), man + P(x, 0.042)], 0.0018)) }
        fit(&s, from: mark, core: views[1], scale: 0.55)
    }

    /// What the two lower windows show: the dog's basket and the songwriter's piano.
    private static func rearwindowCluesBelow(_ s: inout [Halftone.Stroke], _ views: [P]) {
        var mark = s.count
        let basket = views[2] + P(0.025, -0.012)
        s.append(stroke(arc(basket, 0.036, 0, 180, 14) + [basket + P(0.036, 0)], 0.0034))
        for x in [-0.018, 0.0, 0.018] { s.append(stroke([basket + P(x, 0.004), basket + P(x * 0.9, 0.03)], 0.0018)) }
        s.append(stroke([basket + P(-0.036, 0), basket + P(0, -0.07), basket + P(0.036, 0)], 0.0022))
        s.append(stroke(circle(basket + P(0.004, -0.014), 0.012, 12), 0.003))
        for e in [-1.0, 1.0] { s.append(stroke([basket + P(0.004 + e * 0.008, -0.022), basket + P(0.004 + e * 0.016, -0.034), basket + P(0.004 + e * 0.014, -0.016)], 0.0026)) }
        s.append(stroke([basket + P(0, -0.07), basket + P(0, -0.09)], 0.0022))
        fit(&s, from: mark, core: views[2], scale: 0.55)
        mark = s.count
        let piano = views[3] + P(0.025, 0.022)
        let body: [P] = [piano + P(-0.05, -0.006), piano + P(0.02, -0.006)] + curve(piano + P(0.02, -0.006), piano + P(0.06, -0.006), piano + P(0.056, 0.018), 6)
            + [piano + P(-0.05, 0.018)]
        s.append(stroke(closed(body), 0.0034))
        s.append(stroke([piano + P(-0.046, -0.006), piano + P(0.03, -0.05)], 0.003))
        s.append(stroke([piano + P(0.004, -0.006), piano + P(0.0, -0.034)], 0.002))
        for x in [-0.044, 0.0, 0.046] { s.append(stroke([piano + P(x, 0.018), piano + P(x, 0.046)], 0.0026)) }
        for k in 0..<4 { s.append(stroke([piano + P(-0.05 + 0.006 * Double(k), -0.006), piano + P(-0.05 + 0.006 * Double(k), 0.004)], 0.0016)) }
        s.append(stroke(circle(piano + P(-0.074, -0.03), 0.008, 10), 0.003))
        s.append(stroke([piano + P(-0.074, -0.022), piano + P(-0.072, 0.014), piano + P(-0.06, 0.016), piano + P(-0.058, 0.046)], 0.003))
        fit(&s, from: mark, core: views[3], scale: 0.55)
    }
}

// MARK: - 88: Lantern

/// Level 88's name: a moonlit garden, a cherry bough across the top black against the moon, and hanging from it on
/// their cords five round paper lanterns, glowing red and gold over hex's five lenses on this level, ribbed, black-capped
/// and tasselled, above a pond at the hub crossed by a red arched bridge, the moon broken in the water and a carp under
/// it. On each lantern its painted picture: a crane flying (upper right), a carp (lower right), the candle lit inside
/// (bottom), the moon's rabbit (lower left) and a moth come to the light (upper left).
extension LensArt {
    static let lantern: Halftone.Panel = drawLantern()

    /// The bough's spine, from the left edge over the top to the right.
    fileprivate static let bough: [P] = curve(P(-1.05, -0.6), P(0, -1.0), P(1.05, -0.66), 24)

    /// Where the bough passes over x.
    fileprivate static func boughY(_ x: Double) -> Double {
        var best = bough[0]
        for q in bough where abs(q.x - x) < abs(best.x - x) { best = q }
        return best.y
    }

    private static func drawLantern() -> Halftone.Panel {
        let lamps: [P] = Array(hex[2...6])
        let moon = P(0.16, -0.58), pond = P(0, 0.06), bridge = P(-0.16, 0.16)
        let blossoms: [P] = [P(-0.7, -0.82), P(-0.34, -0.86), P(-0.06, -0.86), P(0.3, -0.84), P(0.62, -0.78), P(-0.5, -0.74), P(0.46, -0.9)]
        let tassels: [Fill] = [hex[3], hex[4], hex[5]].map { (c: P) -> Fill in
            fill([c + P(-0.012, core + 0.06), c + P(0.012, core + 0.06), c + P(0.03, core + 0.2), c + P(-0.03, core + 0.2)], m(0.8))
        }
        let caps: [Fill] = lamps.map { (c: P) -> Fill in fill(rect(c.x - 0.075, c.y - core - 0.08, c.x + 0.075, c.y - core + 0.01), .zero) }
        let koi: Fill = oval(P(0.12, 0.17), 0.06, 0.022, Tone(0, 0.5, 0.85))
        var s: [Halftone.Stroke] = []
        lanternScene(&s, lamps, moon: moon, pond: pond, bridge: bridge, blossoms: blossoms)
        s = clear(s, of: lamps, by: core + 0.05)
        lanternFrames(&s, lamps)
        lanternClues(&s, lamps)
        lanternCluesBelow(&s, lamps)
        return Halftone.Panel(name: "lantern", tones: lanternTones(lamps, moon: moon, pond: pond, bridge: bridge, tassels: tassels, caps: caps, koi: koi), strokes: pieces(s))
    }

    private static func lanternScene(_ s: inout [Halftone.Stroke], _ lamps: [P], moon: P, pond: P, bridge: P, blossoms: [P]) {
        // The bough, its twigs and blossom, and the moon behind it.
        s.append(stroke(bough.map { $0 + P(0, -0.03) }, mid))
        s.append(stroke(bough.map { $0 + P(0, 0.03) }, mid))
        for (a, b) in [(P(-0.4, -0.8), P(-0.5, -0.62)), (P(0.2, -0.84), P(0.32, -0.66)), (P(0.6, -0.76), P(0.74, -0.86))] { s.append(stroke(curve(a, (a + b) / 2 + P(0.03, 0), b, 8), mid)) }
        for b in blossoms { for j in 0..<5 { s.append(stroke(circle(polar(b, 0.022, 72 * Double(j)), 0.012, 8), hair)) } }
        s.append(stroke(circle(moon, 0.11, 32), mid))
        // The cords down from the bough to each lantern's cap.
        for c in lamps {
            let top = c.y - core - 0.08
            s += runs(span(P(c.x, boughY(c.x) + 0.03), P(c.x, top), 60), hair) { p in lamps.allSatisfy { $0 == c || simd_distance(p, $0) > core + 0.06 } }
        }
        // The pond: its bank, the bridge's arch and rail, the moon broken in the water, ripples.
        s.append(stroke(ellipse(pond, 0.44, 0.2, 64), mid))
        for r in [0.2, 0.245] { s.append(stroke(arc(bridge, r, 180, 360, 24), mid)) }
        for k in 0..<7 { let a = 190 + 26.7 * Double(k); s.append(stroke([polar(bridge, 0.245, a), polar(bridge, 0.3, a)], hair)) }
        s.append(stroke(arc(bridge, 0.3, 190, 350, 24), hair))
        for (k, yy) in [0.0, 0.04, 0.08, 0.12].enumerated() { let w = 0.05 - 0.008 * Double(k); s.append(stroke([P(moon.x - w, yy), P(moon.x + w, yy)], mid)) }
        s.append(stroke(closed([P(0.06, 0.17), P(0.04, 0.15), P(0.04, 0.19)]), hair))
        for at in [P(-0.3, 0.0), P(0.3, 0.1), P(-0.05, 0.22)] { s.append(stroke(arc(at, 0.05, 200, 340, 8), hair)) }
        for at in [P(-0.82, -0.3), P(0.84, -0.04), P(-0.2, -0.46), P(0.56, -0.66)] { s += glint(at, 0.025, hair) }
    }

    private static func lanternFrames(_ s: inout [Halftone.Stroke], _ lamps: [P]) {
        // The lanterns: rim, ribs round the paper, caps and tassels.
        for (k, c) in lamps.enumerated() {
            s.append(stroke(circle(c, core, 56), bold))
            s.append(stroke(circle(c, core + 0.05, 56), mid))
            for dy in [-0.2, -0.13, 0.13, 0.2] {
                let half = (core * core - dy * dy).squareRoot() - 0.004
                s.append(stroke(curve(c + P(-half, dy), c + P(0, dy + (dy > 0 ? 0.03 : -0.03)), c + P(half, dy), 16), hair))
            }
            for e in [-1.0, 1.0] { s += runs(ellipse(c, 0.19, core, 48), hair) { ($0.x - c.x) * e > 0.1 } }
            for j in 0..<18 { let a = 20 * Double(j) + 7 * Double(k); s.append(stroke([polar(c, core + 0.008, a), polar(c, core + 0.042, a)], hair)) }
            s.append(stroke(closed(rect(c.x - 0.075, c.y - core - 0.08, c.x + 0.075, c.y - core + 0.01)), mid))
            if k > 0, k < 4 {
                for x in [-0.02, 0.0, 0.02] { s.append(stroke([c + P(x * 0.6, core + 0.06), c + P(x * 1.4, core + 0.2)], hair)) }
            }
        }
    }

    private static func lanternTones(_ lamps: [P], moon: P, pond: P, bridge: P, tassels: [Fill], caps: [Fill], koi: Fill) -> @Sendable (P) -> Tone {
        let paper: [Tone] = [m(0.8), y(0.85), m(0.8), y(0.85), m(0.8)]
        let cuts: [Double] = [0, 62, 118, 242, 298]
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, v) in lamps.enumerated() where simd_distance(p, v) < core { return paper[k] }
            for (k, v) in lamps.enumerated() where simd_distance(p, v) < core + 0.05 {
                let a: Double = (bearing(p, v) + 12 * Double(k)).truncatingRemainder(dividingBy: 360)
                let side: Tone = k % 2 == 0 ? y(0.6) : m(0.85)
                return runTone(a, cuts, [side, .zero, side, .zero, side])
            }
            for f in caps where f.holds(p) { return .zero }
            for f in tassels where f.holds(p) { return f.tone }
            if p.y < -0.5, abs(p.y - boughY(p.x)) < 0.03 { return .zero }
            if p.y < -0.1 {
                if simd_distance(p, moon) < 0.11 { return y(0.85) }
                return c(0.35)
            }
            if koi.holds(p) { return koi.tone }
            let b = simd_distance(p, bridge)
            if b > 0.2, b < 0.245, p.y < bridge.y { return m(0.8) }
            if simd_length_squared((p - pond) / P(0.44, 0.2)) < 1 {
                if abs(p.x - moon.x) < 0.05, Int((p.y * 25 + 10).rounded(.down)) % 2 == 0 { return y(0.75) }
                return c(0.6)
            }
            return Tone(0.2, 0, 0.2)
        }
        return tones
    }

    /// What each lantern has painted on it: a crane, a carp, the candle inside, the moon's rabbit, a moth.
    private static func lanternClues(_ s: inout [Halftone.Stroke], _ lamps: [P]) {
        var mark = s.count
        let crane = lamps[0] + P(0.015, 0.015)
        s.append(stroke(closed(ellipse(crane, 0.03, 0.01, degrees: -6, 14)), 0.0034))
        s.append(stroke([crane + P(0.028, -0.004), crane + P(0.07, -0.012)], 0.003))
        s.append(stroke(circle(crane + P(0.076, -0.013), 0.006, 8), 0.0026))
        s.append(stroke([crane + P(0.082, -0.012), crane + P(0.098, -0.008)], 0.0024))
        s.append(stroke([crane + P(-0.028, 0.004), crane + P(-0.08, 0.016)], 0.0026))
        s.append(stroke(closed([crane + P(-0.016, -0.006), crane + P(-0.04, -0.07), crane + P(0.016, -0.008)]), 0.003))
        s.append(stroke(closed([crane + P(0.0, 0.006), crane + P(0.02, 0.05), crane + P(0.018, 0.006)]), 0.0026))
        fit(&s, from: mark, core: lamps[0], scale: 0.6)
        mark = s.count
        let carp = lamps[1] + P(-0.012, 0.018)
        s.append(stroke(closed(curve(carp + P(-0.05, 0), carp + P(0, -0.04), carp + P(0.04, 0), 10) + curve(carp + P(0.04, 0), carp + P(0, 0.04), carp + P(-0.05, 0), 10).dropFirst()), 0.0034))
        s.append(stroke(closed([carp + P(0.035, 0), carp + P(0.07, -0.025), carp + P(0.062, 0), carp + P(0.07, 0.025)]), 0.003))
        s.append(stroke(circle(carp + P(-0.032, -0.006), 0.004, 6), 0.0026))
        for x in [-0.01, 0.01] { s.append(stroke(arc(carp + P(x, 0), 0.012, 300, 420, 6), 0.002)) }
        s.append(stroke([carp + P(-0.05, 0.004), carp + P(-0.066, 0.016)], 0.002))
        fit(&s, from: mark, core: lamps[1], scale: 0.6)
        mark = s.count
        let candle = lamps[2] + P(0.018, 0.0)
        s.append(stroke(closed(rect(candle.x - 0.012, candle.y - 0.01, candle.x + 0.012, candle.y + 0.06)), 0.0034))
        s.append(stroke([candle + P(0, -0.01), candle + P(0, -0.02)], 0.0026))
        s.append(stroke(closed([candle + P(0, -0.07)] + curve(candle + P(0, -0.07), candle + P(0.022, -0.036), candle + P(0, -0.022), 8) + curve(candle + P(0, -0.022), candle + P(-0.022, -0.036), candle + P(0, -0.07), 8).dropFirst()), 0.003))
        for a in [200.0, 245, 295, 340] { s.append(stroke([polar(candle + P(0, -0.042), 0.04, a), polar(candle + P(0, -0.042), 0.054, a)], 0.002)) }
        s.append(stroke([candle + P(-0.03, 0.06), candle + P(0.03, 0.06)], 0.003))
        fit(&s, from: mark, core: lamps[2], scale: 0.6)
    }

    /// What the three lower lanterns have painted on them: the candle, the rabbit, the moth.
    private static func lanternCluesBelow(_ s: inout [Halftone.Stroke], _ lamps: [P]) {
        var mark = s.count
        let rabbit = lamps[3] + P(0.014, 0.014)
        s.append(stroke(closed(ellipse(rabbit + P(0, 0.012), 0.032, 0.026, 18)), 0.0034))
        s.append(stroke(circle(rabbit + P(0.03, -0.024), 0.014, 12), 0.003))
        for (dx, tilt) in [(0.024, -100.0), (0.036, -80.0)] { s.append(stroke(closed(ellipse(polar(rabbit + P(dx, -0.036), 0.022, tilt), 0.022, 0.006, degrees: tilt, 10)), 0.0026)) }
        s.append(stroke(circle(rabbit + P(-0.034, 0.008), 0.007, 8), 0.0026))
        s.append(stroke([rabbit + P(-0.01, 0.036), rabbit + P(0.02, 0.038)], 0.0026))
        fit(&s, from: mark, core: lamps[3], scale: 0.6)
        mark = s.count
        let moth = lamps[4] + P(0.014, 0.014)
        s.append(stroke([moth + P(0, -0.03), moth + P(0, 0.03)], 0.0034))
        for e in [-1.0, 1.0] {
            s.append(stroke(closed([moth + P(0, -0.024), moth + P(e * 0.05, -0.046), moth + P(e * 0.06, -0.01), moth + P(0, -0.004)]), 0.003))
            s.append(stroke(closed([moth + P(0, 0.0), moth + P(e * 0.044, 0.014), moth + P(e * 0.03, 0.04), moth + P(0, 0.02)]), 0.003))
            s.append(stroke(circle(moth + P(e * 0.034, -0.026), 0.006, 6), 0.002))
            s.append(stroke(curve(moth + P(0, -0.03), moth + P(e * 0.01, -0.05), moth + P(e * 0.026, -0.056), 5), 0.002))
        }
        fit(&s, from: mark, core: lamps[4], scale: 0.6)
    }
}

// MARK: - 89: Dreamcatcher

/// Level 89's name: a dreamcatcher hung on a bedroom wall at night, its great hoop at the hub and three small hoops tied
/// to it (top, lower right and lower left), hex's four lenses on this level, each wrapped in red and gold thong and
/// strung with its web, and feathers hanging on beaded strings below; the window at the upper right open on the moon
/// and stars, the curtain's folds drawn back at the upper left. In each web a dream it has caught: a sheep jumping a
/// fence (hub), a little sailing boat on the waves (top), a castle flying its flag (lower right) and the spider who
/// spun the first web (lower left).
extension LensArt {
    static let dreamcatcher: Halftone.Panel = drawDreamcatcher()

    /// A hoop's web: rings of eight threads, each ring's knots at the middles of the last's, drawn in towards the centre,
    /// cut clear of the dream drawn in it.
    fileprivate static func web(_ c: P, clear dream: P) -> [Halftone.Stroke] {
        var ring: [P] = (0..<8).map { polar(c, core - 0.004, 45 * Double($0) + 10) }
        var lines: [[P]] = []
        for _ in 0..<5 {
            let next: [P] = (0..<8).map { (i: Int) -> P in c + ((ring[i] + ring[(i + 1) % 8]) / 2 - c) * 0.86 }
            for i in 0..<8 { lines.append([ring[i], next[i], ring[(i + 1) % 8]]) }
            ring = next
        }
        let keep: (P) -> Bool = { simd_distance($0, dream) > 0.05 }
        return lines.flatMap { (line: [P]) -> [Halftone.Stroke] in runs(span(line[0], line[1], 8) + span(line[1], line[2], 8).dropFirst(), hair, keep: keep) }
    }

    private static func drawDreamcatcher() -> Halftone.Panel {
        let hoops: [P] = [hex[0], hex[1], hex[3], hex[5]]
        let window: [P] = rect(0.33, -0.62, 0.78, -0.02), moon = P(0.62, -0.46)
        let feathers: [(P, Double, Double)] = [(P(-0.1, 0.36), 0.36, 6), (P(0.04, 0.37), 0.42, -3), (P(0.15, 0.35), 0.3, -10),
                                              (hex[3] + P(0.02, core + 0.08), 0.3, -4), (hex[5] + P(-0.02, core + 0.08), 0.3, 5)]
        let plumes: [Fill] = feathers.enumerated().map { (k: Int, f: (P, Double, Double)) -> Fill in
            let (top, length, tilt) = f
            let tip = top + polar(P(0, 0), length, 90 + tilt), mid1 = top + (tip - top) * 0.55
            let n = P(-(tip - top).y, (tip - top).x) / length * 0.05
            return fill([top + n * 0.3, mid1 + n, tip, mid1 - n, top - n * 0.3], k % 2 == 0 ? y(0.75) : m(0.65))
        }
        var s: [Halftone.Stroke] = []
        dreamcatcherScene(&s, window: window, moon: moon, feathers: feathers)
        s = clear(s, of: hoops, by: core + 0.05)
        dreamcatcherFrames(&s, hoops)
        let dreams = dreamcatcherClues(&s, hoops) + dreamcatcherCluesBelow(&s, hoops)
        for (k, c) in hoops.enumerated() { s += web(c, clear: dreams[k]) }
        return Halftone.Panel(name: "dreamcatcher", tones: dreamcatcherTones(hoops, moon: moon, plumes: plumes), strokes: pieces(s))
    }

    private static func dreamcatcherScene(_ s: inout [Halftone.Stroke], window: [P], moon: P, feathers: [(P, Double, Double)]) {
        // The window: frame, glazing bars, sill, the moon and stars out.
        s.append(stroke(closed(window), bold))
        s.append(stroke([P(0.555, -0.62), P(0.555, -0.02)], mid))
        s.append(stroke([P(0.33, -0.32), P(0.78, -0.32)], mid))
        s.append(stroke([P(0.3, 0.0), P(0.81, 0.0)], bold))
        s.append(stroke(arc(moon, 0.07, 100, 340, 20) + arc(moon + P(0.03, -0.02), 0.06, 320, 120, 16), mid))
        for at in [P(0.4, -0.54), P(0.7, -0.24), P(0.42, -0.14), P(0.72, -0.58)] { s += glint(at, 0.025, hair) }
        // The curtain's folds and its tie-back.
        for k in 0..<7 { let x = -0.86 + 0.08 * Double(k); s.append(stroke(curve(P(x, -0.9), P(x + 0.06, -0.4), P(x + 0.22 - 0.02 * Double(k), -0.06), 16), hair)) }
        s.append(stroke(closed(ellipse(P(-0.42, -0.12), 0.05, 0.02, degrees: -20, 12)), mid))
        // The feathers: quills, their strings and beads.
        for (top, length, tilt) in feathers {
            let tip = top + polar(P(0, 0), length, 90 + tilt)
            s.append(stroke([top, tip], mid))
            s.append(stroke([top + P(0, -0.06), top], hair))
            s.append(stroke(circle(top + P(0, -0.03), 0.013, 8), mid))
            for t in stride(from: 0.2, to: 0.95, by: 0.15) { let q = top + (tip - top) * t; s.append(stroke([q, q + polar(P(0, 0), 0.035, 125 + tilt)], hair)); s.append(stroke([q, q + polar(P(0, 0), 0.035, 55 + tilt)], hair)) }
        }
        // The hanging loop above the top hoop.
        s.append(stroke(arc(hex[1] + P(0, -core - 0.1), 0.05, 0, 360, 16), mid))
    }

    private static func dreamcatcherFrames(_ s: inout [Halftone.Stroke], _ hoops: [P]) {
        // The hoops: rims and their wraps, the ties between them, the webs.
        for (k, c) in hoops.enumerated() {
            s.append(stroke(circle(c, core, 56), bold))
            s.append(stroke(circle(c, core + 0.046, 56), mid))
            for j in 0..<24 { let a = 15 * Double(j) + 5 * Double(k); s.append(stroke([polar(c, core + 0.004, a), polar(c, core + 0.042, a + 6)], hair)) }
        }
    }

    private static func dreamcatcherTones(_ hoops: [P], moon: P, plumes: [Fill]) -> @Sendable (P) -> Tone {
        let cuts: [Double] = [0, 18, 30, 52, 66, 80, 104, 116, 140, 158, 170, 196, 210, 232, 244, 266, 282, 300, 314, 338]
        let wraps: [Tone] = [m(0.75), y(0.75), m(0.75), y(0.75), .zero]
        let glow: [Tone] = [y(0.6), m(0.5), m(0.5), m(0.5)]
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, v) in hoops.enumerated() where simd_distance(p, v) < core { return glow[k] }
            for (k, v) in hoops.enumerated() where simd_distance(p, v) < core + 0.046 {
                return runTone((bearing(p, v) + 23 * Double(k)).truncatingRemainder(dividingBy: 360), cuts, wraps)
            }
            for f in plumes where f.holds(p) { return f.tone }
            if p.x > 0.33, p.x < 0.78, p.y > -0.62, p.y < -0.02 {
                if simd_distance(p, moon) < 0.07, simd_distance(p, moon + P(0.03, -0.02)) > 0.06 { return y(0.9) }
                return Tone(0.15, 0, 0)
            }
            if p.x < -0.3, p.y < 0.02 {
                let u: Double = p.x - 0.24 * (p.y + 0.9)
                return Int(((u + 2) / 0.08).rounded(.down)) % 2 == 0 ? m(0.65) : m(0.2)
            }
            return c(0.3)
        }
        return tones
    }

    /// The dream in each web: a sheep over a fence, a sailing boat, a castle, the spider. Returns where each sits.
    private static func dreamcatcherClues(_ s: inout [Halftone.Stroke], _ hoops: [P]) -> [P] {
        var at: [P] = []
        func done(_ mark: Int) { let pts = s[mark...].flatMap(\.points); at.append(pts.reduce(P(0, 0), +) / Double(pts.count)) }
        var mark = s.count
        let sheep = hoops[0] + P(0.012, -0.016)
        s.append(stroke(closed((0..<24).map { (i: Int) -> P in polar(sheep, 0.026 + 0.004 * cos(Double(i) * .pi / 2), 15 * Double(i)) }), 0.0034))
        s.append(stroke(closed(ellipse(sheep + P(0.034, -0.012), 0.012, 0.008, degrees: 20, 10)), 0.003))
        for (a, b) in [(P(-0.016, 0.02), P(-0.03, 0.036)), (P(-0.006, 0.024), P(-0.016, 0.04)), (P(0.012, 0.022), P(0.026, 0.034)), (P(0.02, 0.018), P(0.036, 0.028))] {
            s.append(stroke([sheep + a, sheep + b], 0.0026))
        }
        for x in [-0.03, 0.03] { s.append(stroke([sheep + P(x, 0.044), sheep + P(x, 0.07)], 0.0026)) }
        for y in [0.05, 0.062] { s.append(stroke([sheep + P(-0.04, y), sheep + P(0.04, y)], 0.0022)) }
        fit(&s, from: mark, core: hoops[0], scale: 0.5)
        done(mark)
        mark = s.count
        let boat = hoops[1] + P(0.012, 0.012)
        s.append(stroke(closed([boat + P(-0.045, 0.01), boat + P(0.045, 0.01), boat + P(0.03, 0.03), boat + P(-0.03, 0.03)]), 0.0034))
        s.append(stroke([boat + P(0, 0.01), boat + P(0, -0.06)], 0.003))
        s.append(stroke(closed([boat + P(0.004, -0.056), boat + P(0.04, 0.002), boat + P(0.004, 0.002)]), 0.003))
        s.append(stroke(closed([boat + P(-0.004, -0.044), boat + P(-0.034, 0.002), boat + P(-0.004, 0.002)]), 0.0026))
        s.append(stroke((0...16).map { (i: Int) -> P in boat + P(-0.07 + 0.14 * Double(i) / 16, 0.042 + 0.006 * sin(Double(i) * .pi / 2.5)) }, 0.0026))
        fit(&s, from: mark, core: hoops[1], scale: 0.5)
        done(mark)
        return at
    }

    /// The dreams in the two lower webs: a castle and the spider. Returns where each sits.
    private static func dreamcatcherCluesBelow(_ s: inout [Halftone.Stroke], _ hoops: [P]) -> [P] {
        var at: [P] = []
        func done(_ mark: Int) { let pts = s[mark...].flatMap(\.points); at.append(pts.reduce(P(0, 0), +) / Double(pts.count)) }
        var mark = s.count
        let castle = hoops[2] + P(-0.012, 0.012)
        s.append(stroke([castle + P(-0.05, 0.04), castle + P(-0.05, -0.02), castle + P(-0.044, -0.02), castle + P(-0.044, -0.03), castle + P(-0.036, -0.03), castle + P(-0.036, -0.02),
                         castle + P(-0.028, -0.02), castle + P(-0.028, 0.0), castle + P(0.028, 0.0), castle + P(0.028, -0.02), castle + P(0.036, -0.02), castle + P(0.036, -0.03),
                         castle + P(0.044, -0.03), castle + P(0.044, -0.02), castle + P(0.05, -0.02), castle + P(0.05, 0.04), castle + P(-0.05, 0.04)], 0.0034))
        s.append(stroke(arc(castle + P(0, 0.04), 0.012, 180, 360, 8), 0.0026))
        s.append(stroke([castle + P(-0.04, -0.03), castle + P(-0.04, -0.07)], 0.0024))
        s.append(stroke(closed([castle + P(-0.04, -0.07), castle + P(-0.016, -0.062), castle + P(-0.04, -0.054)]), 0.0024))
        fit(&s, from: mark, core: hoops[2], scale: 0.5)
        done(mark)
        mark = s.count
        let spider = hoops[3] + P(0.012, 0.012)
        s.append(stroke(circle(spider, 0.016, 12), 0.0036))
        s.append(stroke(circle(spider + P(0, -0.024), 0.009, 8), 0.0032))
        s.append(stroke([spider + P(0, -0.033), spider + P(0, -0.08)], 0.002))
        for e in [-1.0, 1.0] {
            for k in 0..<4 {
                let knee = spider + P(e * 0.036, -0.03 + 0.02 * Double(k))
                s.append(stroke([spider + P(e * 0.01, -0.008 + 0.006 * Double(k)), knee, knee + P(e * 0.014, 0.022)], 0.0026))
            }
        }
        fit(&s, from: mark, core: hoops[3], scale: 0.5)
        done(mark)
        return at
    }
}

// MARK: - 90: Iris out

/// Level 90's name, the pack's last: the old film's ending, its black circle closing on the last shot, a road over
/// the fields running away to the setting sun and a little figure in bowler and baggy trousers, cane in hand, walking
/// off up it into the sunset, alone at the hub, the reel's change cue in the dark at the upper right and scratches on
/// the black. Six lenses ring the closing circle, each a camera's iris, its blades round the rim, half over the dark,
/// and in each what is left of the scene: birds flying home (top), the new moon (upper right), a cottage's lit window
/// (lower right), THE END on the road (bottom), a flower dropped by the way (lower left) and the evening star (upper
/// left).
extension LensArt {
    static let irisout: Halftone.Panel = drawIrisout()

    /// The iris's opening, about the hub.
    fileprivate static let iris = 0.52
    fileprivate static let horizon = 0.05
    fileprivate static let sunAt = P(0.08, 0.05)

    /// The last shot, before the iris: sky in bands down to the sun, the road and the fields.
    fileprivate static func lastShot(_ p: P) -> Tone {
        let d = simd_distance(p, sunAt)
        if p.y < horizon {
            if d < 0.09 { return y(1) }
            if d < 0.14 { return Tone(0, 0.3, 0.95) }
            if p.y > -0.12 { return Tone(0, 0.5, 0.8) }
            if p.y > -0.3 { return Tone(0, 0.7, 0.35) }
            if p.y > -0.5 { return Tone(0.3, 0.55, 0) }
            return c(0.5)
        }
        let t = p.y - horizon, dx = p.x - sunAt.x
        if abs(dx) < 0.008 + 0.36 * t { return Tone(0, 0.35, 0.6) }
        let furrow = Int(((dx / max(t, 0.01)) * 2.2 + 40).rounded(.down))
        return furrow % 2 == 0 ? Tone(0.4, 0, 0.3) : c(0.25)
    }

    private static func drawIrisout() -> Halftone.Panel {
        let views: [P] = Array(hex[1...6])
        var s: [Halftone.Stroke] = []
        irisoutScene(&s)
        s = clear(s, of: views, by: core + 0.05)
        irisoutFrames(&s, views)
        irisoutWalker(&s)
        irisoutClues(&s, views)
        irisoutCluesBelow(&s, views)
        let figure: [Fill] = walker().map { fill($0, .zero) }
        return Halftone.Panel(name: "irisout", tones: irisoutTones(views, figure: figure), strokes: pieces(s))
    }

    private static func irisoutScene(_ s: inout [Halftone.Stroke]) {
        // The last shot's lines: the horizon, the road's edges, the poles along it, the sun's rim.
        let lit: (P) -> Bool = { simd_length($0) < iris - 0.012 }
        s += runs(span(P(-iris, horizon), P(iris, horizon), 60), mid) { abs($0.x - sunAt.x) > 0.09 && lit($0) }
        for e in [-1.0, 1.0] {
            s += runs(span(sunAt + P(e * 0.008, 0), sunAt + P(e * (0.008 + 0.36 * 0.6), 0.6), 40), mid) { lit($0) && $0.y > 0.3 }
            for k in 1..<3 {
                let t: Double = 0.06 + 0.14 * Double(k * (k + 1)) / 2
                let at: P = sunAt + P(e * (0.05 + 0.7 * t), t)
                s += runs(span(at, at + P(0, -0.04 - 0.5 * t), 12), k < 1 ? hair : mid, keep: lit)
                s += runs(span(at + P(-0.012 - 0.04 * t, -0.04 - 0.45 * t), at + P(0.012 + 0.04 * t, -0.04 - 0.45 * t), 6), hair, keep: lit)
            }
        }
        s.append(stroke(arc(sunAt, 0.09, 180, 360, 24), mid))
        // The black: the iris's edge, the change cue and scratches on the film.
        s.append(stroke(circle(P(0, 0), iris, 120), bold))
        s.append(stroke(circle(P(0.66, -0.62), 0.05, 20), mid))
        s.append(stroke(circle(P(0.66, -0.62), 0.03, 14), hair))
        let scratches: [(Double, Double, Double)] = [(-0.82, -0.5, 0.2), (-0.7, 0.5, 0.7), (0.78, 0.1, 0.6), (0.3, 0.7, 0.95), (-0.2, -0.98, -0.66)]
        for (x, y0, y1) in scratches {
            s += runs(span(P(x, y0), P(x + 0.01, y1), 30), hair) { simd_length($0) > iris + 0.02 && simd_length($0) < 0.99 }
        }
    }

    private static func irisoutFrames(_ s: inout [Halftone.Stroke], _ views: [P]) {
        // The six irises: each rim, its blades' edges across the frame.
        for (k, c) in views.enumerated() {
            s.append(stroke(circle(c, core, 56), mid))
            s.append(stroke(circle(c, core + 0.05, 56), hair))
            for j in 0..<6 {
                let a = 60 * Double(j) + 17 * Double(k)
                s.append(stroke(curve(polar(c, core, a), polar(c, core + 0.03, a + 14), polar(c, core + 0.05, a + 34), 6), hair))
            }
        }
    }

    private static func irisoutTones(_ views: [P], figure: [Fill]) -> @Sendable (P) -> Tone {
        let cuts: [Double] = [0, 28, 60, 88, 120, 148, 180, 208, 240, 268, 300, 328]
        let blades: [Tone] = [c(0.55), .zero, m(0.5), .zero, c(0.55), .zero, y(0.5), .zero]
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for v in views where simd_distance(p, v) < core { return simd_length(p) < iris ? lastShot(p) : .zero }
            for (k, v) in views.enumerated() where simd_distance(p, v) < core + 0.05 {
                let twist: Double = 32 * (simd_distance(p, v) - core) / 0.05
                let a: Double = (bearing(p, v) + 360 - 17 * Double(k) + twist).truncatingRemainder(dividingBy: 360)
                return runTone(a, cuts, blades)
            }
            if simd_length(p) < iris {
                for f in figure where f.holds(p) { return .zero }
                return lastShot(p)
            }
            if simd_distance(p, P(0.66, -0.62)) < 0.03 { return y(0.35) }
            return .zero
        }
        return tones
    }

    /// The little figure walking off up the road, seen from behind, as shapes: bowler's brim and crown, head, coat, and
    /// each baggy trouser leg ending in a big shoe.
    fileprivate static func walker() -> [[P]] {
        let w = P(0.075, 0.17), k = 1.8
        let parts: [[P]] = [
            ellipse(P(0, -0.112), 0.03, 0.007, 16), arc(P(0, -0.112), 0.018, 180, 360, 10), circle(P(0, -0.09), 0.016, 12),
            [P(-0.03, -0.074), P(0.03, -0.074), P(0.038, -0.01), P(-0.038, -0.01)],
            [P(-0.036, -0.012), P(-0.004, -0.012), P(-0.01, 0.046), P(-0.064, 0.058), P(-0.06, 0.046), P(-0.042, 0.042)],
            [P(0.004, -0.012), P(0.036, -0.012), P(0.038, 0.042), P(0.062, 0.05), P(0.058, 0.058), P(0.01, 0.05)],
        ]
        return parts.map { $0.map { w + k * $0 } }
    }

    /// The walker's outlines, his arms and cane, and his long shadow back down the road.
    private static func irisoutWalker(_ s: inout [Halftone.Stroke]) {
        for part in walker() { s.append(stroke(closed(part), hair)) }
        let w = P(0.075, 0.17), mark = s.count
        s.append(stroke([w + P(0.034, -0.06), w + P(0.05, -0.03), w + P(0.07, 0.054)], mid))
        s.append(stroke(arc(w + P(0.06, -0.03), 0.01, 180, 360, 6), mid))
        s.append(stroke([w + P(-0.034, -0.06), w + P(-0.05, -0.02)], mid))
        s.append(stroke([w + P(-0.03, 0.058), w + P(-0.08, 0.2)], hair))
        s.append(stroke([w + P(0.03, 0.058), w + P(0.0, 0.2)], hair))
        for i in mark..<s.count { s[i].points = s[i].points.map { w + ($0 - w) * 1.8 } }
    }

    /// Capitals a unit tall and 0.6 wide, about their middle.
    fileprivate static let letters: [Character: [[P]]] = [
        "T": [[P(-0.3, -0.5), P(0.3, -0.5)], [P(0, -0.5), P(0, 0.5)]],
        "H": [[P(-0.3, -0.5), P(-0.3, 0.5)], [P(0.3, -0.5), P(0.3, 0.5)], [P(-0.3, 0), P(0.3, 0)]],
        "E": [[P(0.3, -0.5), P(-0.3, -0.5), P(-0.3, 0.5), P(0.3, 0.5)], [P(-0.3, 0), P(0.18, 0)]],
        "N": [[P(-0.3, 0.5), P(-0.3, -0.5), P(0.3, 0.5), P(0.3, -0.5)]],
        "D": [[P(-0.3, -0.5), P(-0.3, 0.5), P(-0.05, 0.5)] + arc(P(-0.05, 0), 0.5, 90, -90, 10) + [P(-0.3, -0.5)]],
    ]

    /// What each iris still shows: birds, the new moon, a cottage, THE END, a flower and the evening star.
    private static func irisoutClues(_ s: inout [Halftone.Stroke], _ views: [P]) {
        let inward: [P] = views.map { simd_normalize($0) * 0.04 + $0 }
        var mark = s.count
        let flock: [P] = [P(-0.03, 0.006), P(0.0, -0.016), P(0.032, 0.0), P(0.012, 0.02)]
        for (k, d) in flock.enumerated() {
            let w: Double = 0.016 - 0.002 * Double(k % 2), at: P = inward[0] + d
            let wing: [P] = curve(at + P(-w, -0.006), at + P(-w * 0.4, -0.012), at, 5) + curve(at, at + P(w * 0.4, -0.012), at + P(w, -0.006), 5).dropFirst()
            s.append(stroke(wing, 0.0032))
        }
        fit(&s, from: mark, core: views[0], scale: 0.65)
        mark = s.count
        let moon = inward[1]
        s.append(stroke(arc(moon, 0.03, 50, 290, 18) + arc(moon + P(-0.016, -0.004), 0.024, 280, 60, 14), 0.0034))
        fit(&s, from: mark, core: views[1], scale: 0.65)
        mark = s.count
        let home = inward[2]
        s.append(stroke(closed(rect(home.x - 0.03, home.y - 0.01, home.x + 0.03, home.y + 0.03)), 0.0034))
        s.append(stroke([home + P(-0.04, -0.008), home + P(0, -0.044), home + P(0.04, -0.008)], 0.0034))
        s.append(stroke(closed(rect(home.x + 0.006, home.y + 0.0, home.x + 0.02, home.y + 0.014)), 0.0026))
        s.append(stroke(closed(rect(home.x - 0.022, home.y + 0.008, home.x - 0.008, home.y + 0.03)), 0.0024))
        s.append(stroke([home + P(0.02, -0.03), home + P(0.02, -0.05)], 0.003))
        s.append(stroke(curve(home + P(0.02, -0.056), home + P(0.04, -0.07), home + P(0.03, -0.09), 6), 0.002))
        fit(&s, from: mark, core: views[2], scale: 0.65)
    }

    /// What the three lower-left irises still show: THE END, a flower and the evening star.
    private static func irisoutCluesBelow(_ s: inout [Halftone.Stroke], _ views: [P]) {
        let inward: [P] = views.map { simd_normalize($0) * 0.04 + $0 }
        var mark = s.count
        let k = 0.02, start = inward[3] + P(-0.051, 0)
        for (i, ch) in "THE END".enumerated() {
            for line in place(letters[ch] ?? [], at: start + P(0.85 * k * Double(i), 0), k) { s.append(stroke(line, 0.0028)) }
        }
        fit(&s, from: mark, core: views[3], scale: 0.65)
        mark = s.count
        let flower = inward[4]
        for j in 0..<5 { s.append(stroke(circle(polar(flower, 0.011, 72 * Double(j) - 20), 0.008, 10), 0.0026)) }
        s.append(stroke(circle(flower, 0.004, 6), 0.0026))
        s.append(stroke(curve(flower + P(0.006, 0.018), flower + P(0.02, 0.04), flower + P(0.05, 0.046), 8), 0.0028))
        let leaf: [P] = curve(flower + P(0.03, 0.044), flower + P(0.036, 0.026), flower + P(0.052, 0.028), 5) + curve(flower + P(0.052, 0.028), flower + P(0.044, 0.042), flower + P(0.03, 0.044), 5).dropFirst()
        s.append(stroke(leaf, 0.0022))
        fit(&s, from: mark, core: views[4], scale: 0.65)
        mark = s.count
        let star = inward[5]
        s += glint(star, 0.03, 0.003)
        s += glint(star + P(0.04, 0.03), 0.012, 0.0022)
        fit(&s, from: mark, core: views[5], scale: 0.65)
    }
}
