// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 83 to 86, the opening of the chapter Fade out.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let fadeOut: [Int: Halftone.Panel] = [83: trainwindow, 84: windscreen, 85: fireflyjar, 86: readingstone]

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
        for j in 1..<line.count {
            let steps: Int = max(1, Int((simd_distance(line[j - 1], line[j]) / 0.008).rounded(.up)))
            fine += span(line[j - 1], line[j], steps).dropFirst()
        }
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

    /// A rounded rectangle's outline, `rx` by `ry` about c: (x/rx)⁴ + (y/ry)⁴ = 1, as `squircle` draws it.
    fileprivate static func within(_ p: P, _ c: P, _ rx: Double, _ ry: Double) -> Bool {
        let x = (p.x - c.x) / rx, y = (p.y - c.y) / ry
        let x2: Double = x * x, y2: Double = y * y
        return x2 * x2 + y2 * y2 < 1
    }

    /// Points turned `degrees` about c and moved to `at`.
    fileprivate static func placed(_ points: [P], at: P, degrees: Double) -> [P] {
        let t = degrees * .pi / 180, cs = cos(t), sn = sin(t)
        return points.map { q in at + P(q.x * cs - q.y * sn, q.x * sn + q.y * cs) }
    }
}

// MARK: - 83: Train window

/// Level 83's name: a railway carriage's window at nightfall, its rounded frame in the carriage's wooden wall, the glass
/// misted and lit by the carriage's lamps, the hills, the telegraph wires and the lights of a town faint through it,
/// curtains tied back at each side, and wiped dark in the mist a child's handprint (the hub), a smiling face drawn with
/// a finger (lower right) and a heart with its arrow (lower left). Over
/// hex's four lenses on this level, rounds wiped clear with a sleeve, their edges smeared and dripping, and in each
/// the evening going by: the moon over a church on its hill (upper left), a telegraph pole with birds flying past
/// (top), a farmhouse with its window lit and its chimney smoking (upper right), and the home signal at the line's
/// side, its arm raised and its lamp lit (bottom).
extension LensArt {
    static let trainwindow: Halftone.Panel = drawTrainwindow()

    private static func drawTrainwindow() -> Halftone.Panel {
        let views = [hex[6], hex[1], hex[2], hex[4]]
        let pane = (c: P(0, 0.02), rx: 0.86, ry: 0.9)
        let horizon = 0.18
        let hill: @Sendable (Double) -> Double = { x in horizon - 0.06 - 0.06 * sin(3 * x + 1) - 0.03 * sin(7 * x) }
        // What the finger drew in the mist, wiped clear: a handprint, a smiling face and a heart with its arrow.
        let palm = P(0.08, 0.12)
        let hand: [Fill] = [oval(palm, 0.135, 0.12, .zero),
                            fill(ellipse(palm + P(-0.17, 0.0), 0.085, 0.028, degrees: -40, 16), .zero)]
            + [-0.105, -0.035, 0.035, 0.105].map { (x: Double) -> Fill in
                let up: Double = abs(x) > 0.07 ? 0.08 : 0.1
                return oval(palm + P(x, -0.1 - up * 0.7), 0.023, up, .zero)
            }
        let face = P(0.56, 0.33)
        let smile: [P] = arc(face, 0.09, 25, 155, 16)
        let eyes = [face + P(-0.06, -0.05), face + P(0.06, -0.05)]
        // The curtains, tied back at each side of the window.
        let curtain: @Sendable (P) -> Bool = { p in
            let pinch: Double = 0.1 * exp(-(p.y - 0.12) * (p.y - 0.12) / 0.05)
            return abs(p.x) > 0.76 + pinch
        }
        let heartAt = P(-0.5, 0.33)
        let heart: [P] = (0...48).map { (i: Int) -> P in
            let t = 2 * Double.pi * Double(i) / 48, s = sin(t)
            let hx: Double = 16 * s * s * s
            let hy: Double = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
            return heartAt + 0.0105 * P(hx, -hy)
        }
        let arrow: [P] = [heartAt + P(-0.26, 0.14), heartAt + P(0.24, -0.15)]

        var s: [Halftone.Stroke] = []
        // The window's frame: the pane's rubber seal and the wooden frame round it, screwed to the wall.
        s.append(stroke(closed(squircle(pane.c, pane.rx, pane.ry, 96)), bold))
        s.append(stroke(closed(squircle(pane.c, pane.rx + 0.05, pane.ry + 0.05, 96)), mid))
        for k in 0..<16 {
            let a = 22.5 * Double(k) + 11
            s.append(stroke(circle(polar(pane.c, 0.94, a), 0.01, 8), hair))
        }
        s.append(stroke(closed(rect(-0.08, -0.97, 0.08, -0.91)), mid))
        // Outside: the hills' line, a town's lights along it, and the telegraph wires swinging between their poles.
        s.append(stroke((0...100).map { (i: Int) -> P in let x = -1 + 0.02 * Double(i); return P(x, hill(x)) }, mid))
        for x in stride(from: -0.3, through: 0.36, by: 0.07) {
            let at = P(x, hill(x) - 0.03)
            s.append(stroke(closed(rect(at.x, at.y, at.x + 0.018, at.y + 0.022)), hair))
        }
        let poles: [Double] = [-0.95, -0.2, 0.55, 1.3]
        for x in poles.dropLast() { s.append(stroke([P(x, -0.24), P(x, hill(x) + 0.02)], mid)); s.append(stroke([P(x - 0.05, -0.22), P(x + 0.05, -0.22)], mid)) }
        for j in 0..<3 {
            let dy: Double = -0.22 + 0.025 * Double(j)
            for k in 0..<(poles.count - 1) {
                let a = P(poles[k] + (j == 1 ? 0.0 : (j == 0 ? -0.04 : 0.04)), dy), b = P(poles[k + 1] + (j == 1 ? 0.0 : (j == 0 ? -0.04 : 0.04)), dy)
                s.append(stroke(curve(a, (a + b) / 2 + P(0, 0.12), b, 24), hair))
            }
        }
        for at in [P(-0.2, -0.86), P(0.5, -0.74), P(-0.72, -0.62), P(0.28, -0.6), P(0.82, -0.1)] { s += glint(at, 0.03, hair) }
        // The finger's lines, and the mist running down from them.
        for e in eyes { s.append(stroke([e + P(0, 0.03), e + P(0, 0.07)], hair)) }
        s.append(stroke([face + P(0.04, 0.2), face + P(0.04, 0.27)], hair))
        s.append(stroke([heartAt + P(0.0, 0.2), heartAt + P(0.0, 0.26)], hair))
        s.append(stroke([palm + P(0.03, 0.12), palm + P(0.03, 0.19)], hair))
        // The curtains' edges, their folds and the ties.
        for e in [-1.0, 1.0] {
            let edge: [P] = (0...60).map { (i: Int) -> P in
                let yy: Double = -0.98 + 1.96 * Double(i) / 60
                let pinch: Double = 0.1 * exp(-(yy - 0.12) * (yy - 0.12) / 0.05)
                return P(e * (0.76 + pinch), yy)
            }
            s.append(stroke(edge, mid))
            for k in 1..<4 {
                let fold: [P] = edge.map { q in P(q.x + e * 0.05 * Double(k) * (1 - 0.4 * exp(-(q.y - 0.12) * (q.y - 0.12) / 0.05)), q.y) }
                s.append(stroke(fold, hair))
            }
            s.append(stroke(closed(ellipse(P(e * 0.9, 0.12), 0.05, 0.03, 16)), mid))
        }
        s = clear(s, of: views)
        // The wiped rounds: their smeared edges and the drips under each.
        for (k, v) in views.enumerated() {
            for j in 0..<5 {
                let a: Double = 30 + 70 * Double(j) + 17 * Double(k)
                s.append(stroke(arc(v, core + 0.03, a, a + 22, 5), hair))
            }
            for (j, dx) in [-0.12, -0.03, 0.08].enumerated() {
                let top = P(v.x + dx, v.y + (core * core - dx * dx).squareRoot() + 0.04)
                let fall: Double = [0.06, 0.1, 0.04][(j + k) % 3]
                s.append(stroke([top, top + P(0, fall)], mid))
                s.append(stroke(circle(top + P(0, fall + 0.008), 0.008, 8), hair))
            }
        }
        // The moon over a church on its hill.
        let church = views[0] + P(0.024, 0.026)
        s.append(stroke(curve(church + P(-0.07, 0.03), church + P(-0.01, -0.006), church + P(0.06, 0.03), 12), 0.003))
        s.append(stroke(closed(rect(church.x - 0.03, church.y, church.x, church.y + 0.022)), 0.0025))
        s.append(stroke(closed([church + P(0.0, 0.022), church + P(0.0, -0.012), church + P(0.007, -0.045), church + P(0.014, -0.012), church + P(0.014, 0.022)]), 0.0025))
        s.append(stroke([church + P(-0.03, 0.0), church + P(-0.015, -0.014), church + P(0.0, 0.0)], 0.0025))
        let moon = church + P(-0.04, -0.045)
        s.append(stroke(arc(moon, 0.017, 70, 290, 16) + arc(moon + P(-0.009, 0), 0.013, 250, 110, 12), 0.003))
        // A telegraph pole, its insulators, its wires, and birds flying past.
        let pole = views[1] + P(0.024, 0.02)
        s.append(stroke([pole + P(0, -0.045), pole + P(0, 0.055)], 0.0035))
        s.append(stroke([pole + P(-0.026, -0.035), pole + P(0.026, -0.035)], 0.003))
        for x in [-0.022, 0.022] { s.append(stroke(circle(pole + P(x, -0.041), 0.004, 6), 0.002)) }
        s.append(stroke(curve(pole + P(-0.022, -0.037), pole + P(-0.06, -0.0), pole + P(-0.1, -0.03), 10), 0.002))
        s.append(stroke(curve(pole + P(0.022, -0.037), pole + P(0.06, -0.0), pole + P(0.1, -0.03), 10), 0.002))
        for (at, w) in [(P(-0.052, -0.062), 0.02), (P(0.05, -0.072), 0.016)] {
            s.append(stroke(curve(at + P(-w, 0.004), at + P(-w / 2, -w * 0.8), at, 5) + curve(at, at + P(w / 2, -w * 0.8), at + P(w, 0.004), 5), 0.003))
        }
        // A farmhouse, its window lit and its chimney smoking.
        let house = views[2] + P(-0.022, 0.024)
        s.append(stroke(closed(rect(house.x - 0.035, house.y - 0.004, house.x + 0.035, house.y + 0.04)), 0.003))
        s.append(stroke([house + P(-0.046, -0.002), house + P(0, -0.038), house + P(0.046, -0.002)], 0.003))
        s.append(stroke([house + P(0.018, -0.022), house + P(0.018, -0.042), house + P(0.03, -0.042), house + P(0.03, -0.012)], 0.0025))
        s.append(stroke(curve(house + P(0.024, -0.048), house + P(0.0, -0.06), house + P(0.03, -0.07), 6) + curve(house + P(0.03, -0.07), house + P(0.06, -0.08), house + P(0.04, -0.1), 6), 0.002))
        s.append(stroke(closed(rect(house.x - 0.024, house.y + 0.008, house.x - 0.004, house.y + 0.026)), 0.003))
        s.append(stroke([house + P(-0.014, 0.008), house + P(-0.014, 0.026)], 0.002))
        s.append(stroke([house + P(-0.024, 0.017), house + P(-0.004, 0.017)], 0.002))
        s.append(stroke(closed(rect(house.x + 0.01, house.y + 0.014, house.x + 0.024, house.y + 0.04)), 0.0025))
        // The home signal by the line, its arm raised for the train and its lamp lit, the rails running past it.
        let signal = views[3] + P(0.026, -0.022)
        s.append(stroke([signal + P(0, 0.06), signal + P(0, -0.05)], 0.004))
        s.append(stroke(closed(bar(signal + P(0.0, -0.04), signal + P(0.06, -0.066), 0.016)), 0.003))
        s.append(stroke(closed(bar(signal + P(0.036, -0.054), signal + P(0.046, -0.058), 0.016)), 0.002))
        let lamp = signal + P(-0.016, -0.032)
        s.append(stroke(circle(lamp, 0.01, 10), 0.003))
        for a in [140.0, 180, 220] { s.append(stroke([polar(lamp, 0.016, a), polar(lamp, 0.028, a)], 0.0022)) }
        s.append(stroke([signal + P(-0.08, 0.08), signal + P(-0.03, 0.01)], 0.0025))
        s.append(stroke([signal + P(-0.045, 0.085), signal + P(-0.016, 0.01)], 0.0025))
        for k in 0..<3 { let t: Double = 0.2 + 0.3 * Double(k); s.append(stroke([signal + P(-0.03 - 0.05 * t, 0.01 + 0.07 * t), signal + P(-0.016 - 0.029 * t + 0.008, 0.01 + 0.075 * t)], 0.0018)) }

        let glass: [Tone] = [c(0.65), m(0.6), c(0.65), m(0.6)]
        let cuts: [Double] = [0, 34, 70, 96, 150, 176, 222, 260, 300, 330]
        let smear: [Tone] = [y(0.8), y(0.15), Tone(0, 0.3, 0.5), y(0.85), c(0.3)]
        let wall = Tone(0.3, 0.5, 0), wood = c(0.5), drape = m(0.7)
        let mist = y(0.45)
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, v) in views.enumerated() {
                let d = simd_distance(p, v)
                if d < core { return glass[k] }
                if d < core + 0.045 { return runTone((bearing(p, v) + 41 * Double(k)).truncatingRemainder(dividingBy: 360), cuts, smear) }
            }
            if curtain(p) { return abs(p.y - 0.12) < 0.03 && abs(p.x) < 0.95 ? y(0.8) : drape }
            if !within(p, pane.c, pane.rx, pane.ry) { return within(p, pane.c, pane.rx + 0.05, pane.ry + 0.05) ? wood : wall }
            // What the finger cleared shows the night outside, dark against the mist the carriage's lamps light.
            let scene: Tone = .zero
            if simd_distance(p, palm) < 0.3 { for f in hand where f.holds(p) { return scene } }
            let fd = simd_distance(p, face)
            if fd < 0.21 {
                if abs(fd - 0.17) < 0.032 { return scene }
                for e in eyes where simd_distance(p, e) < 0.03 { return scene }
                if distance(p, smile) < 0.03 { return scene }
            }
            if simd_distance(p, heartAt) < 0.32, distance(p, heart) < 0.032 || distance(p, arrow) < 0.024 { return scene }
            return mist
        }
        return Halftone.Panel(name: "trainwindow", tones: tones, strokes: pieces(s))
    }
}

// MARK: - 84: Windscreen

/// Level 84's name: a car's windscreen on the road home at dusk, rain beaded on the glass but where the wipers have
/// swept it, the road running ahead between its hedges to the hills under a violet sky, the streetlamps lit along it,
/// the dashboard below with its vents and the radio glowing, and over hex's four lenses on this level: the cleared
/// glass straight ahead (the hub), where a fingerpost points the way at a fork; the rear-view mirror (top), in it a
/// child asleep on the back seat; the moon rising through the rain (upper left); and the steering wheel (bottom), its
/// stitched rim round the speedometer.
extension LensArt {
    static let windscreen: Halftone.Panel = drawWindscreen()

    private static func drawWindscreen() -> Halftone.Panel {
        let ahead = hex[0], mirror = hex[1], moon = hex[6], wheel = hex[4]
        let views = [ahead, mirror, moon, wheel]
        let screen: [P] = [P(-0.6, -0.8), P(0.6, -0.8), P(0.74, -0.74), P(1.0, 0.2), P(1.0, 0.26), P(-1.0, 0.26), P(-1.0, 0.2), P(-0.74, -0.74)]
        let dash = 0.26, horizon = -0.04, vanish = P(0.08, -0.05)
        let road: [P] = [vanish + P(-0.015, 0), vanish + P(0.015, 0), P(1.05, dash), P(-0.75, dash)]
        let lamps: [(P, Double)] = [(P(0.6, -0.36), 0.1), (P(0.36, -0.14), 0.05), (P(-0.34, -0.1), 0.035)]
        let wiper = (P(0.4, 0.27), P(0.86, -0.3))
        let blade = bar(wiper.0, wiper.1, 0.035)
        let vent = rect(0.5, 0.36, 0.76, 0.46), radio = rect(-0.66, 0.36, -0.36, 0.45)
        let hedges = [fill([P(-1, horizon + 0.02), vanish, P(-0.75, dash), P(-1, dash)], Tone(0.55, 0, 0.45)),
                      fill([vanish, P(1, horizon - 0.02), P(1, 0.08), P(1.05, dash)], Tone(0.45, 0, 0.55))]
        let cabin = [fill(vent, c(0.1)), fill(radio, c(0.75))], wiperBlade = fill(blade, .zero)
        let rain: [P] = (0..<160).map { (i: Int) -> P in
            let a: Double = Double(i) * 2.39996, r: Double = 0.95 * (Double(i) / 160).squareRoot()
            return P(r * cos(a), -0.27 + 0.6 * r * sin(a))
        }
        let swept: @Sendable (P) -> Bool = { p in
            let l = simd_distance(p, P(-0.3, 0.27)), r = simd_distance(p, P(0.4, 0.27))
            return (l < 0.78 && l > 0.2) || (r < 0.78 && r > 0.2)
        }

        var s: [Halftone.Stroke] = []
        // The windscreen's edge, the pillars and the dashboard's line, the vent's slats and the radio.
        s += outside(closed(screen).filter { $0.y < 0.25 } , bold, of: views, by: core + 0.05)
        s += outside((0...60).map { i in let x = -1 + Double(i) / 30; return P(x, dash + 0.02 * cos(x * 3)) }, bold, of: views, by: core + 0.06)
        s.append(stroke(closed(vent), mid))
        for k in 1..<5 { let yy: Double = 0.36 + 0.02 * Double(k); s.append(stroke([P(0.52, yy), P(0.74, yy - 0.012)], hair)) }
        s.append(stroke(closed(radio), mid))
        for x in [-0.72, -0.3] { s.append(stroke(circle(P(x, 0.405), 0.025, 12), mid)) }
        s.append(stroke([P(-0.62, 0.395), P(-0.56, 0.395)], hair))
        s.append(stroke([P(-0.5, 0.395), P(-0.4, 0.395)], hair))
        // The road: its edges and centre line, the lamps along it, the hills and the hedge tops.
        s += outside([vanish, P(-0.75, dash)], mid, of: views, by: core + 0.05)
        s += outside([vanish, P(1.05, dash)], mid, of: views, by: core + 0.05)
        for k in 0..<7 {
            let t0: Double = pow(Double(k) / 7, 1.6), t1: Double = pow((Double(k) + 0.5) / 7, 1.6)
            let a = vanish + (P(0.12, dash) - vanish) * t0, b = vanish + (P(0.12, dash) - vanish) * t1
            s += outside([a, b], mid, of: views, by: core + 0.05)
        }
        for (at, r) in lamps {
            s += outside([at + P(0, r * 0.4), at + P(0, 0.5 * r + (r > 0.06 ? 0.5 : 0.16))], mid, of: views, by: core + 0.05)
            s.append(stroke(circle(at, r * 0.35, 12), mid))
        }
        s += outside((0...50).map { i in let x = -1 + Double(i) / 25; return P(x, horizon - 0.08 - 0.05 * sin(2.5 * x + 0.5)) }, mid, of: views, by: core + 0.05)
        s += outside((0...50).map { i in let x = -1 + Double(i) / 25; return P(x, horizon - 0.18 - 0.08 * sin(1.7 * x + 2)) }, hair, of: views, by: core + 0.05)
        // The wiper blade, and the rain beaded where no wiper has swept.
        s.append(stroke(closed(blade), mid))
        for (i, at) in rain.enumerated() where !swept(at) && inside(at, screen) && views.allSatisfy({ simd_distance(at, $0) > core + 0.06 }) {
            s.append(stroke(circle(at, 0.008 + 0.006 * Double(i % 3), 8), hair))
        }
        for (k, pivot) in [P(-0.3, 0.27), P(0.4, 0.27)].enumerated() {
            s += outside(arc(pivot, 0.78, 190 + 10 * Double(k), 350 - 10 * Double(k), 40), hair, of: views, by: core + 0.05)
        }
        for at in [P(-0.3, -0.62), P(0.22, -0.72), P(-0.82, 0.04), P(0.88, -0.02)] { s += glint(at, 0.026, hair) }
        s = clear(s, of: views)
        // The rear-view mirror on its stalk, and the beads of rain round the cleared glass.
        s.append(stroke(closed(squircle(mirror, core + 0.07, core + 0.03, 64)), bold))
        s.append(stroke(closed(bar(P(0, -0.98), P(0, mirror.y - core - 0.03), 0.05)), mid))
        for v in [ahead, moon] {
            s.append(stroke(circle(v, core, 56), mid))
            for j in 0..<14 { let a: Double = 25.7 * Double(j) + 9; s.append(stroke(circle(polar(v, core + 0.026, a), 0.008 + 0.004 * Double(j % 2), 8), hair)) }
        }
        // The steering wheel's rim, its stitching and spokes, round the speedometer.
        s.append(stroke(circle(wheel, core, 56), bold))
        s.append(stroke(circle(wheel, core + 0.06, 56), bold))
        for j in 0..<48 where j % 12 < 9 { let a: Double = 7.5 * Double(j); s.append(stroke([polar(wheel, core + 0.022, a), polar(wheel, core + 0.038, a + 4)], hair)) }
        for a in [200.0, 340] { s.append(stroke(closed(bar(polar(wheel, core + 0.06, a), polar(wheel, core + 0.16, a + (a > 270 ? 12 : -12)), 0.05)), mid)) }
        // A fingerpost at a fork in the road, one arm each way.
        let post = ahead + P(0.024, 0.024)
        s.append(stroke([post + P(0, 0.06), post + P(0, -0.05)], 0.0035))
        s.append(stroke(circle(post + P(0, -0.056), 0.006, 8), 0.0025))
        s.append(stroke(closed([post + P(0.004, -0.04), post + P(0.05, -0.04), post + P(0.062, -0.032), post + P(0.05, -0.024), post + P(0.004, -0.024)]), 0.003))
        s.append(stroke(closed([post + P(-0.004, -0.014), post + P(-0.05, -0.014), post + P(-0.062, -0.006), post + P(-0.05, 0.002), post + P(-0.004, 0.002)]), 0.003))
        s.append(stroke([post + P(0.012, -0.032), post + P(0.04, -0.032)], 0.0018))
        s.append(stroke([post + P(-0.012, -0.006), post + P(-0.04, -0.006)], 0.0018))
        s.append(stroke([post + P(-0.08, 0.075), post + P(-0.02, 0.04), post + P(0.0, 0.03)], 0.0022))
        s.append(stroke([post + P(0.08, 0.075), post + P(0.02, 0.04)], 0.0022))
        // In the mirror, a child asleep on the back seat with a bear, dreaming.
        let child = mirror + P(-0.018, 0.026)
        s.append(stroke(circle(child, 0.022, 20), 0.0035))
        for e in [-1.0, 1.0] { s.append(stroke(arc(child + P(e * 0.009, 0.0), 0.006, 20, 160, 6), 0.0025)) }
        s.append(stroke(arc(child + P(0, 0.008), 0.006, 30, 150, 6), 0.002))
        s.append(stroke(curve(child + P(-0.02, -0.012), child + P(-0.01, -0.032), child + P(0.012, -0.02), 8), 0.0025))
        let bear = child + P(0.04, 0.02)
        s.append(stroke(circle(bear, 0.013, 12), 0.003))
        for e in [-1.0, 1.0] { s.append(stroke(circle(bear + P(e * 0.011, -0.012), 0.005, 8), 0.0025)) }
        s.append(stroke(curve(child + P(-0.05, 0.05), child + P(0.0, 0.035), child + P(0.07, 0.05), 10), 0.0022))
        for (at, w) in [(P(0.02, -0.045), 0.012), (P(0.04, -0.062), 0.009)] {
            let z = child + at
            s.append(stroke([z + P(-w / 2, -w / 2), z + P(w / 2, -w / 2), z + P(-w / 2, w / 2), z + P(w / 2, w / 2)], 0.0025))
        }
        // The moon rising through the rain, a cloud drawn across it.
        let disc = moon + P(0.024, 0.022)
        s.append(stroke(circle(disc, 0.03, 28), 0.0035))
        s.append(stroke(curve(disc + P(-0.06, 0.008), disc + P(-0.01, -0.014), disc + P(0.05, 0.016), 10), 0.0028))
        s.append(stroke(curve(disc + P(-0.045, 0.024), disc + P(0.0, 0.01), disc + P(0.06, 0.03), 10), 0.002))
        for (at, r) in [(P(-0.012, -0.012), 0.006), (P(0.012, 0.0), 0.004)] { s.append(stroke(circle(disc + at, r, 8), 0.0018)) }
        for at in [P(-0.05, -0.04), P(0.055, -0.045)] { s += glint(disc + at, 0.012, 0.002) }
        // The speedometer: its dial, its ticks, the needle at thirty and the fuel gauge beside it.
        let dial = wheel + P(0.024, -0.022)
        s.append(stroke(arc(dial, 0.036, 135, 405, 30), 0.0035))
        for k in 0..<10 { let a: Double = 135 + 30 * Double(k); s.append(stroke([polar(dial, 0.026, a), polar(dial, 0.034, a)], 0.0022)) }
        s.append(stroke([polar(dial, 0.006, 45), polar(dial, 0.032, 225)], 0.003))
        s.append(stroke(circle(dial, 0.005, 8), 0.0025))
        let fuel = dial + P(-0.05, 0.04)
        s.append(stroke(arc(fuel, 0.016, 200, 340, 10), 0.0025))
        s.append(stroke([fuel, polar(fuel, 0.014, 300)], 0.0022))

        let glass: [Tone] = [y(0.6), m(0.55), c(0.65), c(0.5)]
        let cuts: [Double] = [0, 26, 60, 98, 130, 168, 214, 246, 290, 318]
        let rims: [[Tone]] = [[y(0.8), .zero, c(0.4), .zero, y(0.5)], [c(0.15), c(0.15), m(0.5)],
                              [y(0.6), .zero, .zero, c(0.5)], [m(0.6), m(0.6), y(0.6), .zero]]
        let sky: [Tone] = [Tone(0.6, 0.3, 0), Tone(0.35, 0.55, 0), Tone(0.0, 0.55, 0.6)]
        let liner = c(0.22), board = m(0.32)
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, v) in views.enumerated() {
                let d = simd_distance(p, v)
                if d < core { return glass[k] }
                let reach: Double = k == 3 ? 0.06 : 0.045
                if d < core + reach { return runTone((bearing(p, v) + 37 * Double(k)).truncatingRemainder(dividingBy: 360), cuts, rims[k]) }
            }
            if p.y < mirror.y - core, abs(p.x) < 0.025 { return liner }
            if within(p, mirror, core + 0.07, core + 0.03) { return c(0.15) }
            if p.y > dash + 0.02 * cos(p.x * 3) {
                for f in cabin where f.holds(p) { return f.tone }
                return board
            }
            if !Halftone.inside(p, screen) { return liner }
            if wiperBlade.holds(p) { return .zero }
            for (at, r) in lamps {
                let d = simd_distance(p, at)
                if d < r { return y(0.85) }
                if d < 1.7 * r { return y(0.45) }
            }
            if p.y > horizon - 0.08 - 0.05 * sin(2.5 * p.x + 0.5) {
                if inside(p, road) { return .zero }
                for f in hedges where f.holds(p) { return f.tone }
                return Tone(0.2, 0, 0.45)
            }
            if p.y > horizon - 0.18 - 0.08 * sin(1.7 * p.x + 2) { return Tone(0.45, 0.3, 0) }
            return p.y < -0.55 ? sky[0] : p.y < -0.3 ? sky[1] : sky[2]
        }
        return Halftone.Panel(name: "windscreen", tones: tones, strokes: pieces(s))
    }
}

// MARK: - 85: Firefly jar

/// Level 85's name: a glass jar of fireflies set down in the long grass at nightfall, its lid punched with air holes,
/// grass blades and a leaf inside, the glass's shine down its left side, the moon up over its shoulder, and over hex's
/// five lenses on this level the glow of a firefly, each one's halo flickering round it. In each glow the firefly
/// itself: in flight, wings spread, its looping trail behind it (top); climbing a grass stem (upper right); resting
/// with its wings folded, its lamp blazing (lower right); on a twig (bottom); and in the last, the moon seen
/// through the glass, a star by it (lower left).
extension LensArt {
    static let fireflyjar: Halftone.Panel = drawFireflyjar()

    /// A firefly at `at`, facing `degrees` (0 at three o'clock, head first), its wings spread when `open`, its lamp's
    /// rays round its tail.
    private static func firefly(_ at: P, _ degrees: Double, open: Bool) -> [Halftone.Stroke] {
        var s: [Halftone.Stroke] = []
        func put(_ points: [P]) -> [P] { placed(points.map { $0 * 0.78 }, at: at, degrees: degrees) }
        let lamp = P(-0.03, 0)
        s.append(stroke(put(circle(lamp, 0.017, 16)), 0.004))
        for a in stride(from: 105.0, through: 255, by: 30) {
            s.append(stroke(put([polar(lamp, 0.026, a), polar(lamp, 0.042, a)]), 0.0035))
        }
        s.append(stroke(put(closed(ellipse(P(0.0, 0), 0.014, 0.01, 14))), 0.0035))
        s.append(stroke(put(circle(P(0.023, 0), 0.008, 10)), 0.0035))
        for e in [-1.0, 1.0] {
            s.append(stroke(put(curve(P(0.028, e * 0.006), P(0.036, e * 0.008), P(0.042, e * 0.018), 4)), 0.0025))
            if open {
                s.append(stroke(put(closed(ellipse(P(-0.006, e * 0.024), 0.02, 0.009, degrees: e * 30, 14))), 0.003))
            } else {
                for k in 0..<3 { let x: Double = 0.008 - 0.008 * Double(k); s.append(stroke(put([P(x, e * 0.01), P(x - 0.004, e * 0.02)]), 0.0025)) }
            }
        }
        return s
    }

    private static func drawFireflyjar() -> Halftone.Panel {
        let glows = [hex[1], hex[2], hex[3], hex[4], hex[5]]
        let jar = (c: P(0, 0.16), rx: 0.72, ry: 0.8)
        let neck = 0.42, lidTop = -0.9, lidBottom = -0.74
        let moonAt = P(-0.68, -0.56)
        let shine: [P] = curve(P(-0.6, -0.42), P(-0.68, 0.1), P(-0.56, 0.66), 16)
        // Inside: two grass blades and a leaf on its stalk.
        let blades: [[P]] = [
            curve(P(-0.22, 0.98), P(-0.24, 0.4), P(-0.06, -0.14), 16) + curve(P(-0.06, -0.14), P(-0.16, 0.4), P(-0.1, 0.98), 16),
            curve(P(0.16, 0.98), P(0.26, 0.5), P(0.2, 0.12), 12) + curve(P(0.2, 0.12), P(0.2, 0.5), P(0.24, 0.98), 12),
        ]
        let leaf: [P] = closed(curve(P(-0.04, -0.02), P(-0.02, -0.16), P(-0.2, -0.17), 10) + curve(P(-0.2, -0.17), P(-0.16, -0.02), P(-0.04, -0.02), 10))
        let greens = blades.map { fill($0, Tone(0.35, 0, 0.75)) } + [fill(leaf, Tone(0.15, 0, 0.8))]
        let grassOut: [[P]] = [(-0.95, 0.12), (-0.86, 0.2), (0.82, 0.16), (0.92, 0.1), (0.74, 0.22), (-0.78, 0.1)].map { (x: Double, h: Double) -> [P] in
            [P(x - 0.03, 1), P(x + 0.01, 0.98 - 3 * h), P(x + 0.03, 1)]
        }

        var s: [Halftone.Stroke] = []
        // The jar: its body and neck, the lid's ribs and air holes, the shine down the glass.
        let body: [P] = closed(squircle(jar.c, jar.rx, jar.ry, 128))
        s += runs(body, bold) { abs($0.x) > neck - 0.01 || $0.y > -0.3 }
        for e in [-1.0, 1.0] { s.append(stroke([P(e * neck, lidBottom), P(e * neck, -0.6)], bold)) }
        s.append(stroke(closed(rect(-neck - 0.04, lidTop, neck + 0.04, lidBottom)), bold))
        for x in stride(from: -0.42, through: 0.43, by: 0.06) { s.append(stroke([P(x, lidTop + 0.02), P(x, lidBottom - 0.02)], hair)) }
        for x in [-0.2, -0.07, 0.07, 0.2] { s.append(stroke(closed([P(x - 0.02, -0.66), P(x, -0.7), P(x + 0.02, -0.66)]), hair)) }
        for e in [-1.0, 1.0] { s.append(stroke(curve(P(e * neck, -0.6), P(e * neck * 1.05, -0.5), P(e * 0.6, -0.44), 8), mid)) }
        s.append(stroke(shine, mid))
        s.append(stroke(shine.map { $0 + P(0.06, 0) }, hair))
        // The grass and the leaf inside, the grass outside, and the moon and stars.
        for b in blades { s += outside(b, mid, of: glows, by: core + 0.05) }
        s += outside(leaf, mid, of: glows, by: core + 0.05)
        s.append(stroke([P(-0.04, -0.02), P(0.06, 0.12)], mid))
        for g in grassOut { s.append(stroke(g, mid)) }
        s.append(stroke(circle(moonAt, 0.08, 28), mid))
        for (at, r) in [(P(-0.7, -0.58), 0.016), (P(-0.64, -0.52), 0.01)] { s.append(stroke(circle(at, r, 10), hair)) }
        for at in [P(0.62, -0.72), P(0.86, -0.4), P(-0.32, -0.95), P(-0.9, -0.2), P(0.36, -0.98)] { s += glint(at, 0.03, hair) }
        s = clear(s, of: glows)
        // The halos: a ring at each glow's edge and the flicker of its rays.
        for (k, g) in glows.enumerated() {
            s.append(stroke(circle(g, core, 56), hair))
            for j in 0..<9 {
                let a: Double = 40 * Double(j) + 13 * Double(k)
                s.append(stroke([polar(g, core + 0.01, a), polar(g, core + 0.03 + 0.012 * Double((j + k) % 3), a)], mid))
            }
        }
        // In flight, wings spread, its trail dotted behind.
        let flyer = glows[0] + P(0.02, 0.024)
        s += firefly(flyer, -25, open: true)
        for k in 0..<3 { let t: Double = Double(k); s.append(stroke(arc(flyer + P(0.0, 0.03), 0.05, 120 + 22 * t, 132 + 22 * t, 4), 0.003)) }
        // Climbing a grass stem.
        let climber = glows[1] + P(-0.026, 0.01)
        s.append(stroke(curve(climber + P(0.036, 0.06), climber + P(0.046, 0.0), climber + P(0.03, -0.06), 10), 0.003))
        s += firefly(climber + P(0.0, 0.006), -80, open: false)
        // Resting, wings folded, its lamp blazing.
        let rester = glows[2] + P(-0.02, -0.024)
        s += firefly(rester, 200, open: true)
        // On a twig.
        let perch = glows[3] + P(0.024, -0.016)
        s.append(stroke(curve(perch + P(-0.06, 0.04), perch + P(0.0, 0.01), perch + P(0.055, 0.03), 10), 0.003))
        s += firefly(perch + P(0.004, -0.008), 180, open: false)
        // The moon through the glass, and a star.
        let disc = glows[4] + P(0.026, -0.022)
        s.append(stroke(arc(disc, 0.03, 60, 300, 20) + arc(disc + P(0.016, 0), 0.024, 235, 125, 16), 0.0035))
        s.append(stroke(star(disc + P(0.036, -0.03), 0.016, degrees: -90), 0.0025))
        s.append(stroke(curve(disc + P(-0.06, 0.05), disc + P(0.0, 0.03), disc + P(0.07, 0.055), 10), 0.002))

        let lamps: [Tone] = [y(0.55), y(0.55), y(0.55), y(0.55), c(0.55)]
        let cuts: [Double] = [0, 16, 40, 52, 90, 108, 130, 170, 184, 220, 236, 270, 300, 316, 340]
        let flicker: [Tone] = [y(0.85), .zero, y(0.5), m(0.4), y(0.85), y(0.25)]
        let glassTone = Tone(0.45, 0.3, 0), shineTone = Tone(0.5, 0.5, 0)
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, g) in glows.enumerated() {
                let d = simd_distance(p, g)
                if d < core { return lamps[k] }
                if d < core + 0.045 { return runTone((bearing(p, g) + 11 * Double(k)).truncatingRemainder(dividingBy: 360), cuts, flicker) }
            }
            if p.y > lidTop, p.y < lidBottom, abs(p.x) < neck + 0.04 { return Tone(0.3, 0.15, 0) }
            for g in glows where simd_distance(p, g) < core + 0.075 { return y(0.3) }
            let inJar = within(p, jar.c, jar.rx, jar.ry) && (p.y > -0.5 || abs(p.x) < neck) || (p.y > lidBottom && abs(p.x) < neck)
            if inJar {
                if p.x < -0.5, p.y > -0.42, p.y < 0.66, distance(p, shine) < 0.03 { return shineTone }
                for f in greens where f.holds(p) { return f.tone }
                return glassTone
            }
            if simd_distance(p, moonAt) < 0.08 { return y(0.8) }
            if p.y > 0.7 { return Tone(0.45, 0, 0.5) }
            return p.y < -0.4 ? Tone(0.55, 0.35, 0) : Tone(0.3, 0.55, 0)
        }
        return Halftone.Panel(name: "fireflyjar", tones: tones, strokes: pieces(s))
    }
}

// MARK: - 86: Reading stone

/// Level 86's name: an old book open by candlelight, its right-hand page written in two columns, a blue initial R set in
/// gold, a vine up the margin, a red ribbon laid down the page and the gutter's shadow on the left, the candle at the
/// top on its brass dish, and over hex's four lenses on this level a reading stone, a glass dome laid on the page, its
/// rim catching the flame and its shadow cast away from it. Under each stone, enlarged, the page's own work: the
/// illuminated letter A (the hub), a snail in the margin (upper right), a pointing hand (upper left) and an owl (bottom).
extension LensArt {
    static let readingstone: Halftone.Panel = drawReadingstone()

    private static func drawReadingstone() -> Halftone.Panel {
        let stones = [hex[0], hex[2], hex[4], hex[6]]
        let flame = P(0.24, -0.92), top = -0.6, gutter = -0.78
        let shadows: [P] = stones.map { $0 + 0.05 * simd_normalize($0 - flame) }
        let initial = rect(0.52, 0.06, 0.74, 0.28)
        let ribbon = bar(P(-0.66, top), P(-0.5, 1.02), 0.065)
        let candle = rect(0.19, -0.88, 0.29, -0.66), dish = (P(0.24, -0.66), P(0.14, 0.035))
        let page: [Fill] = [fill(ribbon, Tone(0, 0.75, 0.3)), fill(initial, c(0.75))]

        var s: [Halftone.Stroke] = []
        // The page's edge, the gutter and the facing page's edge, the ribbon.
        s += outside([P(gutter, 1.0), P(gutter + 0.03, 0.2), P(gutter, top)], bold, of: stones, by: core + 0.05)
        s += outside([P(gutter, top), P(1.0, top)], bold, of: stones, by: core + 0.05)
        s.append(stroke([P(gutter - 0.06, top + 0.02), P(-1.0, top + 0.05)], mid))
        s += outside(closed(ribbon), mid, of: stones, by: core + 0.05)
        // Two columns of writing, the initial in its gold border with a vine, and the margin's vine.
        let columns: [(Double, Double)] = [(-0.66, 0.1), (0.2, 0.84)]
        for (x0, x1) in columns {
            var row = 0
            for yy in stride(from: top + 0.08, through: 0.94, by: 0.05) {
                row += 1
                let indent: Double = row % 4 == 1 ? 0.04 : 0
                var x: Double = x0 + indent
                var w = 0
                while x < x1 - 0.03 {
                    let word: Int = (row * 7 + w * 3) % 4
                    let len: Double = 0.04 + 0.025 * Double(word)
                    let end = min(x + len, x1)
                    let line = span(P(x, yy), P(end, yy), 4)
                    if line.allSatisfy({ !inside($0, initial) && !inside($0, ribbon) && simd_length($0) < 0.99 }) {
                        s += outside(line, hair, of: stones, by: core + 0.05)
                    }
                    x = end + 0.018
                    w += 1
                }
            }
        }
        s.append(stroke(closed(initial), bold))
        s.append(stroke(closed(rect(0.545, 0.085, 0.715, 0.255)), hair))
        s.append(stroke([P(0.59, 0.24), P(0.59, 0.1), P(0.645, 0.1)] + arc(P(0.645, 0.137), 0.037, -90, 90, 10) + [P(0.59, 0.174)], mid))
        s.append(stroke([P(0.63, 0.174), P(0.69, 0.24)], mid))
        s.append(stroke(spiral(P(0.78, 0.36), 0.01, grow: 0.004, turn: 40, 14), hair))
        s += outside((0...40).map { i in let t = Double(i) / 40; return P(0.9 + 0.025 * sin(t * 14), top + 0.05 + 1.3 * t) }, mid, of: stones, by: core + 0.05)
        for k in 0..<7 { let at = P(0.9 + 0.025 * sin(Double(k) * 2 + 1), top + 0.12 + 0.18 * Double(k)); s.append(stroke(closed(ellipse(at + P(0.03, 0), 0.028, 0.012, degrees: -30, 12)), hair)) }
        // The candle, its flame and dish, and the night round the book.
        s.append(stroke(closed(candle), mid))
        s.append(stroke(closed(ellipse(dish.0, dish.1.x, dish.1.y, 28)), mid))
        s.append(stroke(closed(curve(flame + P(-0.025, 0.05), flame + P(-0.03, 0.0), flame + P(0, -0.04), 8) + curve(flame + P(0, -0.04), flame + P(0.03, 0.0), flame + P(0.025, 0.05), 8)), mid))
        s.append(stroke([P(0.24, -0.88), P(0.24, -0.86)], mid))
        s.append(stroke(curve(P(0.29, -0.82), P(0.31, -0.78), P(0.295, -0.74), 6), hair))
        s = clear(s, of: stones)
        // The stones: the rim, its glints towards the flame.
        for (k, st) in stones.enumerated() {
            s.append(stroke(circle(st, core, 56), bold))
            s.append(stroke(circle(st, core + 0.045, 56), hair))
            let toward = bearing(flame, st)
            s.append(stroke(arc(st, core + 0.022, toward - 30, toward + 30, 10), mid))
            s.append(stroke(arc(st, core - 0.03, toward + 150 + 6 * Double(k), toward + 200, 8), hair))
        }
        // The illuminated letter A, in its box, a vine curling out of it.
        let letter = stones[0] + P(0.024, 0.024)
        s.append(stroke(closed(rect(letter.x - 0.036, letter.y - 0.036, letter.x + 0.036, letter.y + 0.036)), 0.0035))
        s.append(stroke([letter + P(-0.024, 0.026), letter + P(0, -0.028), letter + P(0.024, 0.026)], 0.0035))
        s.append(stroke([letter + P(-0.012, 0.006), letter + P(0.012, 0.006)], 0.003))
        s.append(stroke(spiral(letter + P(0.05, 0.05), 0.004, grow: 0.0012, turn: 45, 14), 0.002))
        s.append(stroke(closed(ellipse(letter + P(-0.05, 0.05), 0.012, 0.006, degrees: 40, 10)), 0.002))
        // A snail in the margin.
        let snail = stones[1] + P(-0.03, 0.02)
        s.append(stroke(spiral(snail, 0.004, grow: 0.0014, turn: 30, 24), 0.0035))
        s.append(stroke(closed(curve(snail + P(-0.05, 0.04), snail + P(0.0, 0.05), snail + P(0.07, 0.04), 12) + [snail + P(0.07, 0.03), snail + P(0.034, 0.03)]), 0.0035))
        for e in [-1.0, 1.0] {
            let tip = snail + P(0.07 + e * 0.012, -0.012)
            s.append(stroke([snail + P(0.066, 0.03), tip], 0.0025))
            s.append(stroke(circle(tip, 0.004, 6), 0.0025))
        }
        // A pointing hand, its cuff and its finger.
        let hand = stones[3] + P(0.02, 0.026)
        let palm: [P] = [P(-0.062, -0.022), P(-0.02, -0.028), P(0.064, -0.028), P(0.071, -0.021), P(0.064, -0.014), P(0.0, -0.014),
                         P(0.006, -0.006), P(0.0, 0.002), P(0.004, 0.01), P(-0.004, 0.018), P(-0.002, 0.026), P(-0.062, 0.024)]
        s.append(stroke(closed(rect(hand.x - 0.082, hand.y - 0.026, hand.x - 0.062, hand.y + 0.03)), 0.0035))
        s.append(stroke(closed(palm.map { hand + $0 }), 0.0035))
        for yy in [0.002, 0.01, 0.018] { s.append(stroke([hand + P(-0.004, yy), hand + P(-0.03, yy)], 0.0022)) }
        s.append(stroke(curve(hand + P(-0.04, -0.024), hand + P(-0.02, -0.04), hand + P(0.006, -0.03), 6), 0.0025))
        // An owl on a branch.
        let owl = stones[2] + P(0.024, -0.024)
        s.append(stroke(closed(ellipse(owl, 0.028, 0.036, 24)), 0.0035))
        for e in [-1.0, 1.0] {
            s.append(stroke(circle(owl + P(e * 0.012, -0.014), 0.009, 12), 0.003))
            s.append(stroke(circle(owl + P(e * 0.012, -0.014), 0.002, 4), 0.003))
            s.append(stroke([owl + P(e * 0.018, -0.03), owl + P(e * 0.026, -0.046), owl + P(e * 0.006, -0.034)], 0.0025))
        }
        s.append(stroke([owl + P(-0.004, -0.004), owl + P(0, 0.004), owl + P(0.004, -0.004)], 0.0022))
        for k in 0..<3 { s.append(stroke(arc(owl + P(-0.012 + 0.012 * Double(k), 0.014), 0.006, 20, 160, 6), 0.0018)) }
        s.append(stroke([owl + P(-0.06, 0.04), owl + P(0.07, 0.03)], 0.003))

        let cuts: [Double] = [0, 28, 64, 110, 150, 200, 236, 270, 312]
        let lens = c(0.5)
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, st) in stones.enumerated() {
                let d = simd_distance(p, st)
                if d < core { return lens }
                if d < core + 0.045 {
                    // The rim: bright towards the flame, dark away from it, coloured where it splits the light.
                    let a = (bearing(p, st) - bearing(flame, st) + 360 + 30).truncatingRemainder(dividingBy: 360)
                    return runTone((a + 7 * Double(k)).truncatingRemainder(dividingBy: 360), cuts, [Tone(0.5, 0.5, 0.6), y(0.8), .zero, c(0.5), .zero, m(0.5), .zero, y(0.5), Tone(0.5, 0.5, 0.6)])
                }
                if simd_distance(p, shadows[k]) < core + 0.045 { return m(0.25) }
            }
            let f = simd_distance(p, flame)
            if f < 0.06 { return y(0.9) }
            if p.x > candle[0].x, p.x < candle[2].x, p.y > candle[0].y, p.y < candle[2].y { return Tone(0, 0.1, 0.45) }
            if simd_length_squared((p - dish.0) / dish.1) < 1 { return y(0.75) }
            if p.y < top || p.x < gutter {
                if f < 0.3 { return y(0.45) }
                return p.x < gutter && p.y > top + 0.03 ? Tone(0, 0.35, 0.35) : Tone(0.25, 0.35, 0)
            }
            for t in page where t.holds(p) { return t.tone }
            if p.x < gutter + 0.1 { return Tone(0, 0.5, 0.25) }
            if f < 0.75 { return Tone(0, 0.2, 0.7) }
            if f < 1.15 { return Tone(0, 0.3, 0.55) }
            if f < 1.5 { return Tone(0, 0.4, 0.42) }
            return Tone(0, 0.5, 0.3)
        }
        return Halftone.Panel(name: "readingstone", tones: tones, strokes: pieces(s))
    }
}
