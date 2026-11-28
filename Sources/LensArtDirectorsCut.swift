// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 76 to 79, the first of the chapter Director's cut.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let directorsCut: [Int: Halftone.Panel] = [76: rangefinder]

    /// Hex's rods, the hub first.
    fileprivate static let rods: [P] = [P(0, 0), P(0, -0.56), P(0.485, -0.28), P(0.485, 0.28), P(0, 0.56), P(-0.485, 0.28), P(-0.485, -0.28)]
    /// A hex core's radius.
    fileprivate static let coreR = 0.264

    /// p's bearing about c in degrees, 0 to 360, 0 at three o'clock and clockwise on screen.
    fileprivate static func heading(_ p: P, _ c: P) -> Double {
        let a = atan2(p.y - c.y, p.x - c.x) * 180 / .pi
        return a < 0 ? a + 360 : a
    }

    /// The scene's strokes cut clear of the lens cores, split finely enough for each cut to fall close to the circle,
    /// so only a lens's own clue and frame show magnified in it.
    fileprivate static func clearOf(_ strokes: [Halftone.Stroke], _ centres: [P], by r: Double = coreR + 0.004) -> [Halftone.Stroke] {
        strokes.flatMap { s -> [Halftone.Stroke] in
            let line = s.points
            guard centres.contains(where: { distance($0, line) <= r }) else { return [s] }
            var fine: [P] = [line[0]]
            for j in 1..<line.count {
                let n: Int = max(1, Int((simd_distance(line[j - 1], line[j]) / 0.008).rounded(.up)))
                fine += span(line[j - 1], line[j], n).dropFirst()
            }
            return runs(fine, s.width) { p in centres.allSatisfy { simd_distance(p, $0) > r } }
        }
    }

    /// Strokes cut into pieces of at most `n` segments, as the bake tests every segment of a stroke at each pixel in
    /// its box.
    fileprivate static func cut(_ strokes: [Halftone.Stroke], _ n: Int = 12) -> [Halftone.Stroke] {
        strokes.flatMap { s -> [Halftone.Stroke] in
            guard s.points.count > n + 1 else { return [s] }
            return stride(from: 0, to: s.points.count - 1, by: n).map { stroke(Array(s.points[$0...min($0 + n, s.points.count - 1)]), s.width) }
        }
    }

    /// A lens's glass, a flat tone out to `glass`, in a frame out to `rim` whose tone changes along it in bands, each
    /// band running to its `ends` bearing, so a neighbour's twist that slides the rim along itself shows.
    fileprivate struct Port: Sendable {
        var centre: P
        var glass: Double
        var rim: Double
        var tone: Tone
        var ends: [Double]
        var bands: [Tone]

        func tone(at p: P) -> Tone? {
            let d = p - centre, r2 = simd_length_squared(d)
            guard r2 < rim * rim else { return nil }
            if r2 < glass * glass { return tone }
            let a = heading(p, centre)
            for (k, e) in ends.enumerated() where a < e { return bands[k] }
            return bands[0]
        }
    }

    fileprivate static func port(_ centre: P, _ tone: Tone, _ frame: [(Double, Tone)], glass: Double = 0.2, rim: Double = 0.258) -> Port {
        Port(centre: centre, glass: glass, rim: rim, tone: tone, ends: frame.map { $0.0 }, bands: frame.map { $0.1 })
    }
}

// MARK: - 76: Rangefinder

/// Level 76's name: a black rangefinder camera of the thirties face on, tilted, filling the glass: its chrome front
/// plate holding the rangefinder's two round windows over the top and upper right cores, its lens barrel beside the
/// hub with the focusing tab out over it, a strap lug and its strap at each rounded end, and two spare lenses stood
/// on the red cloth in front of it over the bottom and lower left cores, a film cartridge by them. Through the
/// rangefinder window the two images not yet in coincidence, a street lamp seen twice; through the viewfinder the frame
/// lines round a cyclist; in the spare lenses a man leaping a puddle (bottom) and the Eiffel tower (lower left).
extension LensArt {
    static let rangefinder: Halftone.Panel = drawRangefinder()

    private static func drawRangefinder() -> Halftone.Panel {
        // The camera's own frame: u along the body, v down its face.
        let o: P = P(0.1625, -0.2816), u: P = P(0.866, 0.5), v: P = P(-0.5, 0.866)
        let cam: (Double, Double) -> P = { (a: Double, b: Double) -> P in o + a * u + b * v }
        let windows: [P] = [rods[1], rods[2]], spares: [P] = [rods[4], rods[5]]
        let chrome = c(0.3), black = Tone.zero, cloth = m(0.4)
        let ports: [Port] = [
            port(rods[1], m(0.6), [(30, black), (75, chrome), (160, black), (200, chrome), (290, black), (320, y(0.7)), (360, black)]),
            port(rods[2], y(0.75), [(50, chrome), (100, black), (150, chrome), (250, black), (280, chrome), (360, black)]),
            port(rods[4], c(0.65), [(20, black), (60, chrome), (140, black), (170, y(0.7)), (260, black), (300, chrome), (360, black)]),
            port(rods[5], y(0.7), [(90, chrome), (130, black), (200, chrome), (240, m(0.6)), (330, black), (360, chrome)]),
        ]
        // The body, its ends rounded, and the chrome plate across its top.
        let ends: [P] = arc(P(0.78, 0), 0.55, -90, 90, 16).map { cam($0.x, $0.y * 0.98) } + arc(P(-0.78, 0), 0.55, 90, 270, 16).map { cam($0.x, $0.y * 0.98) }
        let body: [P] = ends.map { $0 + 0.04 * v }
        let plate: [P] = [cam(-1.2, -0.7), cam(1.2, -0.7), cam(1.2, 0.12), cam(-1.2, 0.12)]
        let barrel: P = cam(0.2, 0.3)
        let tab: [P] = bar(polar(barrel, 0.15, 185), polar(barrel, 0.31, 185), 0.08)
        let dial: P = cam(-0.6, 0.16), lugs: [P] = [cam(-1.06, 0.3), cam(1.06, 0.3)]
        let straps: [[P]] = [bar(lugs[0], lugs[0] + P(-0.3, 0.5), 0.1), bar(lugs[1], lugs[1] + P(0.2, 0.6), 0.1)]
        let can: [P] = rect(0.36, 0.62, 0.66, 0.78), caps: [[P]] = [rect(0.34, 0.6, 0.4, 0.8), rect(0.62, 0.6, 0.68, 0.8)]
        let leader: [P] = [P(0.68, 0.64), P(1, 0.6), P(1, 0.7), P(0.68, 0.74)]
        let hoods: [Fill] = spares.map { ring($0, coreR, coreR + 0.06, black) }
        var fills: [Fill] = hoods + [disc(barrel + P(-0.04, 0.03), 0.07, m(0.6)), ring(barrel, 0.1, 0.14, black), ring(barrel, 0.14, 0.2, chrome)]
        fills += caps.map { fill($0, black) } + [fill(can, y(0.85)), fill(leader, black)]
        fills += [fill(tab, chrome), disc(dial, 0.075, chrome)] + straps.map { fill($0, y(0.6)) }
        let shell = fill(body, black), front = fill(plate, chrome)

        var s: [Halftone.Stroke] = []
        // The body: its outline, the plate's edge, the lugs and the slow speeds' dial.
        s.append(stroke(closed(body), bold))
        s += runs(span(cam(-1.2, 0.12), cam(1.2, 0.12), 120), mid) { shell.holds($0) }
        for l in lugs { s.append(stroke(circle(l, 0.03, 12), mid)) }
        for st in straps { s.append(stroke([st[0], st[1]], mid)); s.append(stroke([st[3], st[2]], mid)) }
        s.append(stroke(circle(dial, 0.075, 24), mid))
        for k in 0..<8 { s.append(stroke([polar(dial, 0.05, 45 * Double(k) + 10), polar(dial, 0.075, 45 * Double(k) + 10)], hair)) }
        // The barrel: its rings, the knurl on the focusing ring, the tab and its knob, the front glass's glint.
        for r in [0.1, 0.14, 0.2] { s.append(stroke(circle(barrel, r, 40), r == 0.2 ? bold : mid)) }
        for k in 0..<36 where k % 6 != 2 { let a: Double = 10 * Double(k); s.append(stroke([polar(barrel, 0.155, a), polar(barrel, 0.185, a)], hair)) }
        s.append(stroke(closed(tab), mid))
        s.append(stroke(circle(polar(barrel, 0.31, 185), 0.04, 12), mid))
        s.append(stroke(arc(barrel + P(-0.04, 0.03), 0.05, 200, 260, 8), mid))
        // The cartridge, its film's leader and sprocket holes.
        s.append(stroke(closed(can), mid))
        for q in caps { s.append(stroke(closed(q), mid)) }
        for k in 0..<4 { let x: Double = 0.72 + 0.065 * Double(k); s.append(stroke(closed(rect(x, 0.64, x + 0.025, 0.655)), hair)); s.append(stroke(closed(rect(x, 0.695, x + 0.025, 0.71)), hair)) }
        // The cloth's folds.
        for (a, b) in [(P(-0.9, 0.5), P(-0.6, 0.66)), (P(-0.3, 0.94), P(0.3, 0.9)), (P(0.3, 0.88), P(0.7, 0.86))] {
            s.append(stroke(curve(a, (a + b) / 2 + P(0, 0.03), b, 12), hair))
        }
        s = clearOf(s, windows + spares, by: coreR + 0.004)
        // The windows' and lenses' frames, the spares' barrels.
        for p in ports {
            s.append(stroke(circle(p.centre, p.rim, 56), bold))
            s.append(stroke(circle(p.centre, p.glass, 48), mid))
        }
        for c0 in spares { s.append(stroke(circle(c0, coreR + 0.06, 56), mid)) }
        // Through the rangefinder window: a street lamp, seen twice, the images not yet brought together.
        let lamp: P = windows[0] + P(0.02, 0.022)
        for (dx, w) in [(0.0, 0.0035), (0.024, 0.0022)] {
            let at: P = lamp + P(dx, 0)
            s.append(stroke([at + P(0, 0.055), at + P(0, -0.03)], w))
            s.append(stroke(closed([at + P(-0.014, -0.03), at + P(0.014, -0.03), at + P(0.009, -0.058), at + P(-0.009, -0.058)]), w))
            s.append(stroke([at + P(-0.012, 0.055), at + P(0.012, 0.055)], w))
        }
        // Through the viewfinder: the frame lines' corners round a cyclist.
        let vf: P = windows[1] + P(0.02, 0.024)
        for (sx, sy) in [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)] {
            let at: P = vf + P(0.075 * sx, 0.06 * sy)
            s.append(stroke([at - P(0.024 * sx, 0), at, at - P(0, 0.018 * sy)], 0.0028))
        }
        for x in [-0.026, 0.026] { s.append(stroke(circle(vf + P(x, 0.022), 0.017, 14), 0.003)) }
        s.append(stroke([vf + P(-0.026, 0.022), vf + P(-0.004, 0.022), vf + P(0.014, -0.004), vf + P(-0.012, -0.004), vf + P(-0.004, 0.022)], 0.0026))
        s.append(stroke([vf + P(0.014, -0.004), vf + P(0.026, 0.022)], 0.0026))
        s.append(stroke([vf + P(-0.004, 0.012), vf + P(-0.008, -0.03), vf + P(0.012, -0.012)], 0.003))
        s.append(stroke(circle(vf + P(-0.004, -0.042), 0.01, 10), 0.003))
        // In the bottom spare: a man leaping a puddle, his reflection under him.
        let leap: P = spares[0] + P(0.022, -0.026)
        let figure: [[P]] = [[P(0.05, 0.02), P(0.03, 0.004), P(-0.008, 0.0), P(-0.035, 0.012), P(-0.055, 0.0)], [P(-0.008, 0.0), P(0.0, -0.035)],
                             [P(-0.03, -0.015), P(0.0, -0.026), P(0.026, -0.042)]]
        for line in figure {
            s.append(stroke(line.map { leap + $0 }, 0.0034))
            s.append(stroke(line.map { leap + P($0.x, 0.1 - $0.y) }, 0.0018))
        }
        s.append(stroke(circle(leap + P(0.004, -0.047), 0.011, 10), 0.0032))
        s.append(stroke(closed(ellipse(leap + P(-0.01, 0.06), 0.07, 0.014, 24)), 0.0022))
        // In the lower left spare: the Eiffel tower.
        let tower: P = spares[1] + P(0.026, 0.016)
        s.append(stroke(curve(tower + P(-0.05, 0.065), tower + P(-0.012, 0.0), tower + P(-0.003, -0.08), 10), 0.0034))
        s.append(stroke(curve(tower + P(0.05, 0.065), tower + P(0.012, 0.0), tower + P(0.003, -0.08), 10), 0.0034))
        s.append(stroke(arc(tower + P(0, 0.065), 0.025, 180, 360, 10), 0.0026))
        for (yy, w) in [(0.026, 0.03), (-0.024, 0.014), (-0.056, 0.007)] { s.append(stroke([tower + P(-w, yy), tower + P(w, yy)], 0.003)) }
        s.append(stroke([tower + P(0, -0.08), tower + P(0, -0.1)], 0.0022))

        let shapes: [Fill] = fills
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for pt in ports { if let t = pt.tone(at: p) { return t } }
            for f in shapes where f.holds(p) { return f.tone }
            if shell.holds(p) { return front.holds(p) ? chrome : black }
            return cloth
        }
        return Halftone.Panel(name: "rangefinder", tones: tones, strokes: cut(s))
    }
}
