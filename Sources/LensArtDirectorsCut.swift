// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 76 to 79, the first of the chapter Director's cut.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let directorsCut: [Int: Halftone.Panel] = [76: rangefinder, 77: lensflare, 78: slideviewer, 79: photobooth]

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

    /// A rectangle about `centre` with its corners rounded to `round`, turned `degrees`, tested without a polygon.
    fileprivate struct Rounded: Sendable {
        var centre: P
        var half: P
        var round: Double
        var turn: P

        init(_ centre: P, _ half: P, round: Double, degrees: Double = 0) {
            self.centre = centre
            self.half = half
            self.round = round
            turn = P(cos(degrees * .pi / 180), sin(degrees * .pi / 180))
        }

        func holds(_ p: P) -> Bool {
            let d = p - centre, q = simd_abs(P(d.x * turn.x + d.y * turn.y, -d.x * turn.y + d.y * turn.x)) - half + P(round, round)
            return simd_length(simd_max(q, P(0, 0))) + min(max(q.x, q.y), 0) < round
        }

        var outline: [P] {
            let corners: [(P, Double)] = [(P(1, 1), 0), (P(-1, 1), 90), (P(-1, -1), 180), (P(1, -1), 270)]
            let local: [P] = corners.flatMap { (s: P, a: Double) -> [P] in arc(s * (half - P(round, round)), round, a, a + 90, 6) }
            return closed(local.map { centre + P($0.x * turn.x - $0.y * turn.y, $0.x * turn.y + $0.y * turn.x) })
        }
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
        let dial: P = cam(-0.68, 0.24), timer: P = cam(0.64, 0.22), lugs: [P] = [cam(-1.06, 0.3), cam(1.06, 0.3)]
        let straps: [[P]] = [bar(lugs[0], lugs[0] + P(-0.3, 0.5), 0.1), bar(lugs[1], lugs[1] + P(0.2, 0.6), 0.1)]
        let can: [P] = rect(0.36, 0.62, 0.66, 0.78), caps: [[P]] = [rect(0.34, 0.6, 0.4, 0.8), rect(0.62, 0.6, 0.68, 0.8)]
        let leader: [P] = [P(0.68, 0.64), P(1, 0.6), P(1, 0.7), P(0.68, 0.74)]
        let hoods: [Fill] = spares.map { ring($0, coreR, coreR + 0.06, black) }
        var fills: [Fill] = hoods + [disc(barrel + P(-0.04, 0.03), 0.07, m(0.6)), ring(barrel, 0.1, 0.14, black), ring(barrel, 0.14, 0.2, chrome)]
        fills += caps.map { fill($0, black) } + [fill(can, y(0.85)), fill(leader, black)]
        fills += [fill(tab, chrome), disc(dial, 0.075, chrome)] + straps.map { fill($0, y(0.6)) }
        let lever: [P] = bar(timer, timer + 0.17 * u + 0.12 * v, 0.045)
        let screws: [P] = [cam(-0.42, 0.4), cam(-0.5, 0.15), cam(0.5, 0.42)]
        fills += [disc(timer, 0.05, chrome), fill(lever, chrome)] + screws.map { disc($0, 0.032, y(0.7)) }
        let shell = fill(body, black), front = fill(plate, chrome), base = fill([cam(-1.4, 0.5), cam(1.4, 0.5), cam(1.4, 0.7), cam(-1.4, 0.7)], chrome)

        var s: [Halftone.Stroke] = []
        // The body: its outline, the plate's edge, the lugs and the slow speeds' dial.
        s.append(stroke(closed(body), bold))
        s += runs(span(cam(-1.2, 0.12), cam(1.2, 0.12), 120), mid) { shell.holds($0) }
        for l in lugs { s.append(stroke(circle(l, 0.03, 12), mid)) }
        for st in straps { s.append(stroke([st[0], st[1]], mid)); s.append(stroke([st[3], st[2]], mid)) }
        s.append(stroke(circle(dial, 0.075, 24), mid))
        for k in 0..<8 { s.append(stroke([polar(dial, 0.05, 45 * Double(k) + 10), polar(dial, 0.075, 45 * Double(k) + 10)], hair)) }
        s.append(stroke([dial, polar(dial, 0.05, 200)], mid))
        // The self-timer's lever, and the base plate's edge.
        s.append(stroke(circle(timer, 0.05, 20), mid))
        s.append(stroke(closed(lever), mid))
        s.append(stroke(circle(timer, 0.012, 8), hair))
        for (k, sc) in screws.enumerated() { s.append(stroke(circle(sc, 0.032, 12), mid)); s.append(stroke([polar(sc, 0.024, 40 + 50 * Double(k)), polar(sc, 0.024, 220 + 50 * Double(k))], hair)) }
        s += runs(span(cam(-1.4, 0.5), cam(1.4, 0.5), 140), mid) { shell.holds($0) }
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
            if shell.holds(p) { return front.holds(p) || base.holds(p) ? chrome : black }
            return cloth
        }
        return Halftone.Panel(name: "rangefinder", tones: tones, strokes: cut(s))
    }
}

// MARK: - 77: Lens flare

/// Level 77's name: a film's last shot of a beach at sunset, shot into the sun, and the flare it throws across the
/// frame: the sun itself over the upper right core in a burst of spikes, a streak drawn level across the sky through
/// it, a palm leaning in from the upper left and a striped umbrella on the sand, and the flare's ghosts strung on the
/// line from the sun through the middle, each rimmed in split colour: a hexagon of the iris over the hub and a broad
/// disc over the lower left, and a third over the lower right, where the sun's path glitters on the sea. Through them:
/// a gull crossing the sun, a yacht on the horizon (hub), a surfer on the glitter (lower right) and a sandcastle with
/// its flag (lower left).
extension LensArt {
    static let lensflare: Halftone.Panel = drawLensflare()

    private static func drawLensflare() -> Halftone.Panel {
        let sun: P = rods[2], ghosts: [P] = [rods[0], rods[3], rods[5]]
        let horizon = -0.06, shore = 0.46
        let chroma: [Tone] = [c(0.75), .zero, m(0.75), y(0.85), .zero]
        let ports: [Port] = [
            port(sun, y(0.9), [(14, m(0.5)), (40, y(0.95)), (52, m(0.5)), (100, y(0.95)), (118, m(0.5)), (190, y(0.95)), (200, m(0.5)), (262, y(0.95)), (290, m(0.5)), (360, y(0.95))]),
            port(rods[3], m(0.55), [(30, chroma[0]), (70, chroma[1]), (130, chroma[2]), (150, chroma[3]), (220, chroma[1]), (280, chroma[0]), (310, chroma[2]), (360, chroma[3])]),
            port(rods[5], y(0.65), [(50, chroma[3]), (80, chroma[2]), (170, chroma[1]), (200, chroma[0]), (260, chroma[3]), (300, chroma[1]), (360, chroma[2])]),
        ]
        // The iris's ghost over the hub: a hexagon of glass in its split rim.
        let iris: [P] = closed((0..<6).map { polar(rods[0], 0.215, 60 * Double($0) + 12) })
        let irisRim: Port = port(rods[0], .zero, [(40, chroma[0]), (75, chroma[1]), (120, chroma[2]), (160, chroma[3]), (230, chroma[4]), (250, chroma[0]), (300, chroma[2]), (360, chroma[3])], glass: 0)
        let small: [(P, Double, Tone)] = [(P(0.25, -0.145), 0.055, y(0.5)), (P(-0.8, 0.46), 0.1, m(0.45)), (P(0.68, -0.39), 0.035, c(0.5))]
        // The palm: its trunk leaning in, and its fronds from the crown.
        let crown: P = P(-0.56, -0.5)
        let trunk: [P] = curve(P(-1.0, 0.2), P(-0.66, -0.1), crown, 10)
        let trunkShape: [P] = trunk.map { $0 + P(-0.03, 0) } + trunk.reversed().map { $0 + P(0.03, 0) }
        let fronds: [[P]] = [-10.0, 30, 75, 150, 200, 250].map { (a: Double) -> [P] in
            let tip: P = polar(crown, 0.36, a) + P(0, 0.08), n: P = polar(P(0, 0), 0.07, a + 90)
            return curve(crown, polar(crown, 0.2, a) + n + P(0, -0.03), tip, 8) + curve(tip, polar(crown, 0.18, a) - n + P(0, 0.02), crown, 8)
        }
        let umbrella: P = P(0.2, 0.62)
        let canopy: [[P]] = (0..<4).map { (k: Int) -> [P] in [umbrella] + arc(umbrella, 0.17, 180 + 45 * Double(k), 225 + 45 * Double(k), 6) }
        let towel: [P] = [P(-0.36, 0.72), P(-0.12, 0.66), P(-0.08, 0.8), P(-0.32, 0.86)]
        let clouds: [(P, P)] = [(P(-0.12, -0.66), P(0.26, 0.05)), (P(0.22, -0.78), P(0.2, 0.04)), (P(0.1, -0.5), P(0.18, 0.03))]
        var fills: [Fill] = small.map { disc($0.0, $0.1, $0.2) } + fronds.map { fill($0, .zero) } + [fill(trunkShape, .zero)]
        fills += canopy.enumerated().map { fill($0.element, $0.offset % 2 == 0 ? m(0.75) : y(0.9)) } + [fill(bar(umbrella, umbrella + P(0.03, 0.3), 0.025), .zero), fill(towel, c(0.75))]
        fills += clouds.map { oval($0.0, $0.1.x, $0.1.y, m(0.75)) }

        var s: [Halftone.Stroke] = []
        // The horizon, the shore's foam, the glitter on the sun's path.
        s.append(stroke(span(P(-1, horizon), P(1, horizon), 60), mid))
        s.append(stroke((0...40).map { (i: Int) -> P in let x: Double = -1 + 0.05 * Double(i); return P(x, shore + 0.025 * sin(x * 9)) }, mid))
        for k in 0..<12 {
            let yy: Double = horizon + 0.03 + 0.04 * Double(k), w: Double = 0.03 + 0.006 * Double(k)
            s.append(stroke([P(sun.x - w + 0.01 * Double(k % 3), yy), P(sun.x + w - 0.01 * Double(k % 2), yy)], hair))
        }
        // The palm's fronds and trunk, the umbrella and the towel.
        for f in fronds { s.append(stroke(f, mid)) }
        s.append(stroke(trunk.map { $0 + P(-0.03, 0) }, mid)); s.append(stroke(trunk.map { $0 + P(0.03, 0) }, mid))
        for k in 1..<8 { let at: P = trunk[k]; s.append(stroke([at + P(-0.03, 0), at + P(0.03, -0.015)], hair)) }
        s.append(stroke(arc(umbrella, 0.17, 180, 360, 24) + [umbrella + P(-0.17, 0)], mid))
        for k in 1..<4 { s.append(stroke([umbrella, polar(umbrella, 0.17, 180 + 45 * Double(k))], hair)) }
        s.append(stroke([umbrella, umbrella + P(0.03, 0.3)], mid))
        s.append(stroke(closed(towel), mid))
        // The streak drawn level through the sun, the clouds' edges, the small ghosts, gulls far off.
        for e in [-0.012, 0.012] { s.append(stroke([P(-1, sun.y + e), P(1, sun.y + e * 0.4)], hair)) }
        for (cc, r) in clouds { s.append(stroke(Array(ellipse(cc, r.x, r.y, 32)[16...32]), mid)) }
        for (cc, r, _) in small { s.append(stroke(circle(cc, r, 24), mid)) }
        for at in [P(-0.2, -0.36), P(-0.08, -0.4), P(0.62, -0.62)] { s.append(stroke([at + P(-0.03, 0.006), at + P(-0.012, -0.01), at, at + P(0.012, -0.01), at + P(0.03, 0.006)], hair)) }
        s = clearOf(s, [sun] + ghosts, by: coreR + 0.004)
        // The sun's spikes, the ghosts' rims.
        for k in 0..<12 {
            let a: Double = 30 * Double(k) + 7, l: Double = k % 2 == 0 ? 0.42 : 0.16
            s += clearOf([stroke([polar(sun, coreR + 0.02, a), polar(sun, coreR + l, a)], k % 2 == 0 ? mid : hair)], ghosts + [P(0, -0.56)], by: coreR + 0.004)
        }
        for p in ports {
            s.append(stroke(circle(p.centre, p.rim, 56), bold))
            s.append(stroke(circle(p.centre, p.glass, 48), hair))
        }
        s.append(stroke(circle(rods[0], 0.258, 56), bold))
        s.append(stroke(iris, mid))
        // In the sun: a gull crossing it.
        let gull: P = sun + P(0.02, 0.024)
        s.append(stroke(circle(gull + P(0.012, 0.008), 0.042, 28), 0.0026))
        s.append(stroke(curve(gull + P(-0.05, 0.004), gull + P(-0.03, -0.03), gull + P(0, 0.0), 8) + curve(gull + P(0, 0.0), gull + P(0.03, -0.03), gull + P(0.05, 0.004), 8).dropFirst(), 0.0036))
        // In the iris: a yacht on the horizon.
        let yacht: P = rods[0] + P(0.02, -0.024)
        s += runs(span(yacht + P(-0.1, 0.03), yacht + P(0.1, 0.03), 30), 0.0022) { abs($0.x - yacht.x) > 0.045 }
        s.append(stroke(closed([yacht + P(-0.045, 0.012), yacht + P(0.045, 0.012), yacht + P(0.032, 0.03), yacht + P(-0.032, 0.03)]), 0.0032))
        s.append(stroke([yacht + P(0, 0.012), yacht + P(0, -0.07)], 0.0026))
        s.append(stroke(closed([yacht + P(0.004, -0.064), yacht + P(0.04, 0.004), yacht + P(0.004, 0.004)]), 0.003))
        s.append(stroke(closed([yacht + P(-0.004, -0.05), yacht + P(-0.004, 0.004), yacht + P(-0.034, 0.004)]), 0.003))
        // On the glitter: a surfer on his board under a wave's curl.
        let surf: P = rods[3] + P(-0.022, 0.024)
        s.append(stroke(closed(ellipse(surf + P(0, 0.034), 0.05, 0.008, degrees: -8, 16)), 0.003))
        s.append(stroke([surf + P(-0.016, 0.026), surf + P(-0.004, 0.0), surf + P(0.014, 0.026)], 0.003))
        s.append(stroke([surf + P(-0.004, 0.0), surf + P(0.002, -0.03)], 0.0032))
        s.append(stroke([surf + P(-0.03, -0.02), surf + P(0.0, -0.022), surf + P(0.03, -0.012)], 0.0028))
        s.append(stroke(circle(surf + P(0.004, -0.042), 0.01, 10), 0.003))
        s.append(stroke(curve(surf + P(0.08, 0.05), surf + P(0.1, -0.06), surf + P(0.04, -0.07), 10) + curve(surf + P(0.04, -0.07), surf + P(0.03, -0.05), surf + P(0.05, -0.045), 4), 0.0026))
        // In the broad ghost: a sandcastle and its flag.
        let castle: P = rods[5] + P(0.024, 0.02)
        let wall: [P] = [P(-0.06, 0.04), P(-0.06, -0.01), P(-0.05, -0.01), P(-0.05, -0.02), P(-0.04, -0.02), P(-0.04, -0.01), P(-0.02, -0.01),
                         P(-0.02, -0.04), P(-0.012, -0.04), P(-0.012, -0.05), P(-0.004, -0.05), P(-0.004, -0.04), P(0.004, -0.04), P(0.004, -0.05),
                         P(0.012, -0.05), P(0.012, -0.04), P(0.02, -0.04), P(0.02, -0.01), P(0.04, -0.01), P(0.04, -0.02), P(0.05, -0.02),
                         P(0.05, -0.01), P(0.06, -0.01), P(0.06, 0.04)]
        s.append(stroke(wall.map { castle + $0 }, 0.0032))
        s.append(stroke(arc(castle + P(0, 0.04), 0.014, 180, 360, 8), 0.0028))
        s.append(stroke([castle + P(0, -0.05), castle + P(0, -0.09)], 0.0024))
        s.append(stroke(closed([castle + P(0, -0.09), castle + P(0.03, -0.08), castle + P(0, -0.07)]), 0.0026))
        s.append(stroke([castle + P(-0.09, 0.04), castle + P(0.09, 0.04)], 0.0024))

        let shapes: [Fill] = fills, hub: P = rods[0]
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for pt in ports { if let t = pt.tone(at: p) { return t } }
            let dh = simd_distance(p, hub)
            if dh < 0.258 { return inside(p, iris) ? c(0.5) : (irisRim.tone(at: p) ?? .zero) }
            for f in shapes where f.holds(p) { return f.tone }
            if p.y < horizon {
                if abs(p.y - sun.y + 0.0) < 0.03 * (1 - abs(p.x - sun.x) * 0.6) { return c(0.65) }
                return p.y < -0.62 ? m(0.65) : p.y < -0.4 ? m(0.4) : m(0.22)
            }
            let ys = shore + 0.025 * sin(p.x * 9)
            if p.y < ys { return abs(p.x - sun.x) < 0.09 && Int(((p.y - horizon) / 0.04).rounded(.down)) % 2 == 0 ? y(0.85) : c(0.6) }
            return y(0.45)
        }
        return Halftone.Panel(name: "lensflare", tones: tones, strokes: cut(s))
    }
}

// MARK: - 78: Slide viewer

/// Level 78's name: a picture reel for a stereo slide viewer, its card disc filling the glass with its ring of film
/// slides in their mounts, five showing over the ring's lenses and the sixth gone into the red viewer that grips the
/// reel at the lower left, its advance lever down its side. On the reel's label in the middle a printed title and
/// picture, off the centre hole. In the slides: a big wheel at a fair (top), a rocket climbing (upper right), a castle
/// on its hill (lower right), a cactus in the desert (bottom) and a long-necked dinosaur (upper left).
extension LensArt {
    static let slideviewer: Halftone.Panel = drawSlideviewer()

    private static func drawSlideviewer() -> Halftone.Panel {
        let slides: [P] = [rods[1], rods[2], rods[3], rods[4], rods[6]]
        let card = y(0.35), reelR = 0.9
        let glassTones: [Tone] = [c(0.6), y(0.75), m(0.55), c(0.55), y(0.7)]
        let frames: [[(Double, Tone)]] = [
            [(40, .zero), (80, m(0.7)), (150, .zero), (200, c(0.8)), (300, .zero), (330, m(0.7)), (360, .zero)],
            [(20, c(0.8)), (90, .zero), (120, m(0.7)), (210, .zero), (250, c(0.8)), (360, .zero)],
            [(60, .zero), (100, y(0.85)), (180, .zero), (230, c(0.8)), (320, .zero), (360, y(0.85))],
            [(30, m(0.7)), (110, .zero), (140, y(0.85)), (250, .zero), (290, m(0.7)), (360, .zero)],
            [(70, .zero), (120, c(0.8)), (190, .zero), (220, m(0.7)), (300, .zero), (360, c(0.8))],
        ]
        let mounts: [Port] = (0..<5).map { (k: Int) -> Port in port(slides[k], glassTones[k], frames[k], glass: 0) }
        // Each slide's window, its long side across the reel's radius.
        let windows: [Rounded] = slides.map { (c0: P) -> Rounded in Rounded(c0, P(0.19, 0.14), round: 0.05, degrees: heading(c0, P(0, 0)) + 90) }
        let body = Rounded(P(-0.66, 0.5), P(0.44, 0.3), round: 0.16, degrees: -30)
        let viewer: [P] = body.outline
        let eyes: [P] = [P(-0.78, 0.43), P(-0.5, 0.59)]
        let lever: [P] = bar(P(-0.3, 0.68), P(-0.16, 0.92), 0.07)
        let label: Double = 0.22, picture: [P] = rect(0.02, -0.17, 0.16, -0.07)
        let fills: [Fill] = eyes.map { disc($0, 0.05, c(0.35)) } + eyes.map { disc($0, 0.09, .zero) } + [fill(lever, m(0.55)), disc(P(0, 0), 0.03, .zero), fill(picture, m(0.65)), fill(closed(sector(P(0, 0), 0.045, label, 120, 240)), c(0.55)),
                             fill(rect(0.02, 0.06, 0.17, 0.13), y(0.8)), disc(P(0, 0), label, .zero)]

        var s: [Halftone.Stroke] = []
        // The reel: its rim, the label's ring, the centre hole and its notch, the title's lines and the picture.
        s.append(stroke(circle(P(0, 0), reelR, 120), bold))
        s.append(stroke(circle(P(0, 0), reelR - 0.04, 120), hair))
        s.append(stroke(circle(P(0, 0), label, 48), mid))
        s.append(stroke(circle(P(0, 0), 0.03, 12), mid))
        s.append(stroke(closed(picture), mid))
        s.append(stroke([P(0.04, -0.08), P(0.08, -0.14), P(0.11, -0.1), P(0.13, -0.12), P(0.15, -0.08)], hair))
        s.append(stroke(closed(rect(0.02, 0.06, 0.17, 0.13)), mid))
        s.append(stroke(closed(sector(P(0, 0), 0.045, label, 120, 240)), mid))
        for (x0, x1, yy) in [(-0.12, -0.02, -0.17), (-0.06, 0.0, -0.11), (0.04, 0.15, 0.17), (-0.16, -0.08, 0.0)] { s.append(stroke([P(x0, yy), P(x1, yy)], mid)) }
        // The numbers' ticks round the rim, between the slides.
        for k in 0..<6 { let a: Double = 60 * Double(k) - 60; s.append(stroke([polar(P(0, 0), reelR - 0.12, a), polar(P(0, 0), reelR - 0.06, a)], mid)) }
        // The viewer: its body, the lit panel, the lever, the reel's slot.
        s.append(stroke(closed(viewer), bold))
        for e in eyes { s.append(stroke(circle(e, 0.09, 24), mid)); s.append(stroke(circle(e, 0.05, 20), hair)); s.append(stroke(arc(e, 0.035, 200, 260, 6), hair)) }
        s.append(stroke(curve(eyes[0] + P(0.06, -0.06), (eyes[0] + eyes[1]) / 2 + P(0.02, -0.08), eyes[1] + P(0.02, -0.09), 8), hair))
        s.append(stroke(closed(lever), mid))
        s.append(stroke(Array(Rounded(P(-0.66, 0.5), P(0.38, 0.24), round: 0.12, degrees: -30).outline.prefix(12)), hair))
        s = clearOf(s, slides, by: coreR + 0.004)
        for m0 in mounts { s.append(stroke(circle(m0.centre, m0.rim, 56), bold)) }
        for w in windows { s.append(stroke(w.outline, mid)) }
        // The big wheel.
        let wheel: P = slides[0] + P(0.022, 0.02)
        s.append(stroke(circle(wheel, 0.048, 28), 0.0034))
        for k in 0..<6 { s.append(stroke([wheel, polar(wheel, 0.048, 30 * Double(k) * 2)], 0.002)) }
        for k in 0..<8 { s.append(stroke(circle(polar(wheel, 0.048, 45 * Double(k)), 0.007, 6), 0.0024)) }
        s.append(stroke([wheel + P(-0.034, 0.07), wheel, wheel + P(0.034, 0.07)], 0.003))
        // The rocket.
        let rocket: P = slides[1] + P(0.02, 0.026)
        s.append(stroke(closed([rocket + P(0, -0.07), rocket + P(0.016, -0.04), rocket + P(0.016, 0.03), rocket + P(-0.016, 0.03), rocket + P(-0.016, -0.04)]), 0.0034))
        for e in [-1.0, 1.0] { s.append(stroke([rocket + P(0.016 * e, 0.004), rocket + P(0.034 * e, 0.036), rocket + P(0.016 * e, 0.03)], 0.003)) }
        s.append(stroke(circle(rocket + P(0, -0.024), 0.008, 8), 0.0026))
        s.append(stroke([rocket + P(-0.01, 0.036), rocket + P(-0.004, 0.06), rocket + P(0, 0.044), rocket + P(0.005, 0.066), rocket + P(0.01, 0.036)], 0.0026))
        // The castle on its hill.
        let castle: P = slides[2] + P(-0.022, 0.024)
        let walls: [P] = [P(-0.05, 0.03), P(-0.05, -0.03), P(-0.036, -0.03), P(-0.036, -0.016), P(0.036, -0.016), P(0.036, -0.03), P(0.05, -0.03), P(0.05, 0.03)]
        s.append(stroke(walls.map { castle + $0 }, 0.0032))
        s.append(stroke(closed([castle + P(-0.012, -0.016), castle + P(-0.012, -0.05), castle + P(0.012, -0.05), castle + P(0.012, -0.016)]), 0.003))
        s.append(stroke([castle + P(-0.016, -0.05), castle + P(0, -0.074), castle + P(0.016, -0.05)], 0.003))
        s.append(stroke(arc(castle + P(0, 0.03), 0.012, 180, 360, 8), 0.0026))
        s.append(stroke(curve(castle + P(-0.09, 0.06), castle + P(0, 0.0), castle + P(0.09, 0.06), 12), 0.0026))
        // The cactus in the desert, the sun over it.
        let cactus: P = slides[3] + P(0.022, -0.022)
        s.append(stroke([cactus + P(-0.01, 0.05), cactus + P(-0.01, -0.05)] + arc(cactus + P(0, -0.05), 0.01, 180, 360, 6) + [cactus + P(0.01, 0.05)], 0.0034))
        s.append(stroke([cactus + P(-0.01, 0.0), cactus + P(-0.034, 0.0), cactus + P(-0.034, -0.03)], 0.003))
        s.append(stroke([cactus + P(0.01, 0.014), cactus + P(0.032, 0.014), cactus + P(0.032, -0.016)], 0.003))
        s.append(stroke([cactus + P(-0.09, 0.05), cactus + P(0.09, 0.05)], 0.0024))
        s.append(stroke(circle(cactus + P(0.06, -0.05), 0.014, 10), 0.0026))
        // The dinosaur.
        let dino: P = slides[4] + P(0.024, 0.022)
        s.append(stroke(closed(ellipse(dino + P(0.0, 0.01), 0.036, 0.02, 20)), 0.0034))
        s.append(stroke(curve(dino + P(0.03, 0.0), dino + P(0.05, -0.02), dino + P(0.05, -0.06), 8), 0.003))
        s.append(stroke(circle(dino + P(0.056, -0.064), 0.008, 8), 0.003))
        s.append(stroke(curve(dino + P(-0.034, 0.012), dino + P(-0.06, 0.03), dino + P(-0.08, 0.016), 8), 0.003))
        for x in [-0.022, -0.008, 0.012, 0.024] { s.append(stroke([dino + P(x, 0.026), dino + P(x, 0.05)], 0.003)) }

        let shapes: [Fill] = fills, cut0: [Rounded] = windows
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, m0) in mounts.enumerated() where simd_distance(p, m0.centre) < m0.rim {
                return cut0[k].holds(p) ? m0.tone : (m0.tone(at: p) ?? card)
            }
            for f in shapes where f.holds(p) { return f.tone }
            if body.holds(p) { return m(0.75) }
            let r = simd_length(p)
            if r < reelR { return r > reelR - 0.12 ? .zero : card }
            return c(0.45)
        }
        return Halftone.Panel(name: "slideviewer", tones: tones, strokes: cut(s))
    }
}

// MARK: - 79: Photo booth

/// Level 79's name: the front of a photo booth at a fair, its lit sign across the top, the coin plate and the slot the
/// prints drop from in the middle, the curtain drawn below with two pairs of feet under it, and a sample strip of four
/// pictures pinned up either side, a picture of each over the four corner cores. In the pictures, four poses of the
/// sitters: a grin under big glasses (upper left), a wink and a tongue out (upper right), a shout of surprise (lower
/// right) and a kiss (lower left).
extension LensArt {
    static let photobooth: Halftone.Panel = drawPhotobooth()

    private static func drawPhotobooth() -> Halftone.Panel {
        let shots: [P] = [rods[6], rods[5], rods[2], rods[3]]
        let wall = c(0.5), cardTone = y(0.2), board = m(0.75)
        let photoTones: [Tone] = [y(0.6), c(0.75), m(0.55), y(0.6)]
        let edges: [[(Double, Tone)]] = [
            [(35, cardTone), (55, .zero), (140, cardTone), (165, m(0.7)), (250, cardTone), (275, .zero), (360, cardTone)],
            [(80, cardTone), (100, m(0.7)), (190, cardTone), (215, .zero), (310, cardTone), (330, .zero), (360, cardTone)],
            [(20, .zero), (110, cardTone), (130, .zero), (220, cardTone), (240, m(0.7)), (360, cardTone)],
            [(60, cardTone), (85, .zero), (170, cardTone), (195, .zero), (290, cardTone), (310, m(0.7)), (360, cardTone)],
        ]
        let mounts: [Port] = (0..<4).map { (k: Int) -> Port in port(shots[k], photoTones[k], edges[k], glass: 0) }
        let pictures: [Rounded] = shots.map { Rounded($0, P(0.19, 0.2), round: 0.03) }
        let spare: [Rounded] = [P(-0.485, 0.84), P(0.485, 0.84)].map { Rounded($0, P(0.19, 0.2), round: 0.03) }
        let strips: [[P]] = [rect(-0.72, -0.54, -0.25, 1), rect(0.25, -0.54, 0.72, 1)]
        let sign: [P] = rect(-0.62, -0.9, 0.62, -0.58)
        let plate: [P] = rect(-0.2, -0.22, 0.02, -0.04), slot: [P] = rect(0.04, 0.0, 0.2, 0.06), burst: P = P(0.12, -0.36)
        let folds: [Double] = [-0.22, -0.15, -0.11, -0.02, 0.03, 0.12, 0.16, 0.22]
        let feet: [P] = [P(-0.14, 0.86), P(-0.06, 0.87), P(0.07, 0.85), P(0.15, 0.86)]
        let fills: [Fill] = feet.map { oval($0, 0.035, 0.022, .zero) }
            + [disc(burst, 0.1, y(0.9)), fill(plate, y(0.75)), fill(slot, .zero), fill(sign, board)]
        let cards: [Fill] = strips.map { fill($0, cardTone) }

        var s: [Halftone.Stroke] = []
        // The sign and its bulbs, its letters.
        s.append(stroke(closed(sign), bold))
        for k in 0..<13 { let x: Double = -0.6 + 0.1 * Double(k); for yy in [-0.88, -0.6] { s.append(stroke(circle(P(x, yy), 0.012, 8), hair)) } }
        let letters: [[P]] = [
            [P(-0.42, -0.66), P(-0.42, -0.82), P(-0.36, -0.82), P(-0.34, -0.78), P(-0.36, -0.74), P(-0.42, -0.74)],
            [P(-0.28, -0.66), P(-0.28, -0.82)], [P(-0.2, -0.66), P(-0.2, -0.82)], [P(-0.28, -0.74), P(-0.2, -0.74)],
            [P(-0.12, -0.82), P(-0.04, -0.82), P(-0.04, -0.66), P(-0.12, -0.66), P(-0.12, -0.82)],
            [P(0.02, -0.82), P(0.12, -0.82)], [P(0.07, -0.82), P(0.07, -0.66)],
            [P(0.18, -0.82), P(0.26, -0.82), P(0.26, -0.66), P(0.18, -0.66), P(0.18, -0.82)],
            [P(0.4, -0.82), P(0.32, -0.82), P(0.32, -0.74), P(0.4, -0.74), P(0.4, -0.66), P(0.32, -0.66)],
        ]
        for l in letters { s.append(stroke(l, bold)) }
        // The coin plate, its slot and price, the slot the prints drop from, the burst over it.
        s.append(stroke(closed(plate), mid))
        s.append(stroke(closed(rect(-0.12, -0.18, -0.1, -0.1)), mid))
        for yy in [-0.08, -0.06] { s.append(stroke([P(-0.18, yy), P(-0.02, yy)], hair)) }
        s.append(stroke(closed(slot), mid))
        s.append(stroke([P(0.12, -0.06), P(0.12, -0.02)], mid)); s.append(stroke([P(0.1, -0.04), P(0.12, -0.02), P(0.14, -0.04)], mid))
        s.append(stroke(star(burst, 0.13, points: 10, inner: 0.75), mid))
        s.append(stroke([burst + P(0.012, 0.04), burst + P(0.012, -0.04), burst + P(-0.03, 0.014), burst + P(0.03, 0.014)], mid))
        // The curtain's folds and hem, the feet under it.
        s.append(stroke([P(-0.26, 0.12), P(0.26, 0.12)], bold))
        for (k, x) in folds.enumerated() where k > 0 { s.append(stroke(curve(P(x, 0.14), P(x + 0.01, 0.46), P(x - 0.005, 0.78), 12), k == folds.count - 1 ? mid : hair)) }
        s.append(stroke((0...16).map { (i: Int) -> P in let x: Double = -0.22 + 0.44 * Double(i) / 16; return P(x, 0.78 + (i % 2 == 0 ? 0 : 0.012)) }, mid))
        for f in feet { s.append(stroke(ellipse(f, 0.035, 0.022, 16), mid)) }
        // The strips' edges and their other pictures.
        for st in strips { s.append(stroke([st[0], st[3]], mid)); s.append(stroke([st[1], st[2]], mid)) }
        for r in spare { s.append(stroke(r.outline, mid)) }
        s = clearOf(s, shots, by: coreR + 0.004)
        for m0 in mounts { s.append(stroke(circle(m0.centre, m0.rim, 56), bold)) }
        for r in pictures { s.append(stroke(r.outline, mid)) }
        // A grin under big glasses.
        let grin: P = shots[0] + P(0.022, 0.024)
        s.append(stroke(circle(grin, 0.05, 28), 0.0034))
        for e in [-1.0, 1.0] { s.append(stroke(circle(grin + P(0.02 * e, -0.012), 0.015, 12), 0.003)) }
        s.append(stroke([grin + P(-0.005, -0.012), grin + P(0.005, -0.012)], 0.0026))
        s.append(stroke(arc(grin + P(0, 0.008), 0.026, 20, 160, 10), 0.0032))
        // A wink and a tongue out.
        let wink: P = shots[2] + P(-0.022, 0.024)
        s.append(stroke(circle(wink, 0.05, 28), 0.0034))
        s.append(stroke(circle(wink + P(-0.018, -0.014), 0.006, 8), 0.003))
        s.append(stroke(arc(wink + P(0.018, -0.008), 0.01, 200, 340, 6), 0.003))
        s.append(stroke([wink + P(-0.022, 0.016), wink + P(0.022, 0.016)], 0.003))
        s.append(stroke(arc(wink + P(0.004, 0.016), 0.012, 0, 180, 8), 0.003))
        // A shout of surprise, hands up.
        let shout: P = shots[3] + P(-0.022, -0.02)
        s.append(stroke(circle(shout, 0.05, 28), 0.0034))
        for e in [-1.0, 1.0] { s.append(stroke(circle(shout + P(0.018 * e, -0.014), 0.007, 8), 0.003)) }
        s.append(stroke(closed(ellipse(shout + P(0, 0.022), 0.01, 0.015, 12)), 0.003))
        for e in [-1.0, 1.0] { s.append(stroke([shout + P(0.05 * e, 0.01), shout + P(0.07 * e, -0.04), shout + P(0.066 * e, -0.06)], 0.003)) }
        // A kiss: two faces in profile, a heart over them.
        let kiss: P = shots[1] + P(0.024, 0.024)
        let face: [P] = arc(P(0, 0), 0.04, 90, 270, 14) + [P(0.02, -0.032), P(0.026, -0.016), P(0.036, -0.004), P(0.026, 0.002), P(0.032, 0.01),
                                                           P(0.025, 0.016), P(0.028, 0.026), P(0.0, 0.04)]
        for e in [-1.0, 1.0] { s.append(stroke(face.map { kiss + P(0.037 * e, 0.0) + P(-e * $0.x, $0.y) }, 0.0032)) }
        s.append(stroke([kiss + P(0, -0.05), kiss + P(-0.012, -0.062)] + arc(kiss + P(-0.007, -0.066), 0.007, 150, 330, 6) + arc(kiss + P(0.007, -0.066), 0.007, 210, 390, 6) + [kiss + P(0.012, -0.062), kiss + P(0, -0.05)], 0.0026))

        let shapes: [Fill] = fills, inner: [Rounded] = pictures, others: [Rounded] = spare
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, m0) in mounts.enumerated() where simd_distance(p, m0.centre) < m0.rim {
                return inner[k].holds(p) ? m0.tone : (m0.tone(at: p) ?? cardTone)
            }
            for f in shapes where f.holds(p) { return f.tone }
            for (k, r) in others.enumerated() where r.holds(p) { return photoTones[k + 1] }
            if p.y > 0.14, p.y < 0.78, abs(p.x) < 0.22 {
                var k = 0
                for f in folds where p.x > f { k += 1 }
                return k % 2 == 0 ? m(0.45) : m(0.75)
            }
            for f in cards where f.holds(p) { return f.tone }
            return wall
        }
        return Halftone.Panel(name: "photobooth", tones: tones, strokes: cut(s))
    }
}
