// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 80 to 82, the end of the chapter Director's cut.

extension LensArt {
    /// This part of the chapter's drawn panels by their level's number.
    static let directorsCutEnd: [Int: Halftone.Panel] = [80: darkroom, 81: contactsheet, 82: widescreen]
}

private extension LensArt {
    /// Hex's rods, the hub first.
    static let hexAt: [P] = [P(0, 0), P(0, -0.56), P(0.485, -0.28), P(0.485, 0.28), P(0, 0.56), P(-0.485, 0.28), P(-0.485, -0.28)]
    /// A hex core's radius.
    static let hexCore = 0.264

    /// p's bearing about c in degrees, 0 to 360, 0 at three o'clock and clockwise on screen.
    static func bearingOf(_ p: P, _ c: P) -> Double {
        let a: Double = atan2(p.y - c.y, p.x - c.x) * 180 / .pi
        return a < 0 ? a + 360 : a
    }

    /// v turned `degrees` clockwise on screen.
    static func spun(_ v: P, _ degrees: Double) -> P {
        let t: Double = degrees * .pi / 180
        return P(v.x * cos(t) - v.y * sin(t), v.x * sin(t) + v.y * cos(t))
    }

    /// A line cut where it passes within `r` of any of `centres`, split finely enough for the cut to fall close to the
    /// circle.
    static func cutRuns(_ line: [P], _ width: Double, of centres: [P], by r: Double) -> [Halftone.Stroke] {
        guard centres.contains(where: { distance($0, line) <= r }) else { return [stroke(line, width)] }
        var fine: [P] = [line[0]]
        for j in 1..<line.count {
            let steps: Int = max(1, Int((simd_distance(line[j - 1], line[j]) / 0.008).rounded(.up)))
            fine += span(line[j - 1], line[j], steps).dropFirst()
        }
        return runs(fine, width) { (p: P) -> Bool in centres.allSatisfy { simd_distance(p, $0) > r } }
    }

    /// The scene's strokes cut clear of the lens cores, so only a lens's own clue and frame show magnified in it.
    static func clearOf(_ strokes: [Halftone.Stroke], _ centres: [P]) -> [Halftone.Stroke] {
        strokes.flatMap { cutRuns($0.points, $0.width, of: centres, by: hexCore + 0.004) }
    }

    /// Strokes with long reaches cut into pieces of at most `n` segments, as the bake tests every segment of a stroke
    /// at each pixel in its box.
    static func shotPieces(_ strokes: [Halftone.Stroke], _ n: Int = 12) -> [Halftone.Stroke] {
        strokes.flatMap { (s: Halftone.Stroke) -> [Halftone.Stroke] in
            let lo: P = s.points.reduce(s.points[0], simd_min), hi: P = s.points.reduce(s.points[0], simd_max)
            guard s.points.count > n + 1, simd_distance(lo, hi) > 0.12 else { return [s] }
            return stride(from: 0, to: s.points.count - 1, by: n).map { stroke(Array(s.points[$0...min($0 + n, s.points.count - 1)]), s.width) }
        }
    }

    /// The tone of a frame cut into runs: `cuts` are the bearings where each run starts, in order, and `tones` the run
    /// each starts, the last run wrapping to the first cut.
    static func bandTone(_ a: Double, _ cuts: [Double], _ tones: [Tone]) -> Tone {
        var k: Int = cuts.count - 1
        for (i, cut) in cuts.enumerated() where a >= cut { k = i }
        return tones[k % tones.count]
    }

    /// Moves the strokes from `start` on, a clue, straight out from its lens core's centre until it clears the knob
    /// there by 0.022, first drawing it `scale` its size about its middle.
    static func nudge(_ s: inout [Halftone.Stroke], from start: Int, core: P, scale: Double = 1) {
        let first: [P] = s[start...].flatMap(\.points)
        let g: P = first.reduce(P(0, 0), +) / Double(first.count)
        for i in start..<s.count { s[i].points = s[i].points.map { g + ($0 - g) * scale } }
        let drawn: [P] = s[start...].flatMap(\.points)
        let u: P = simd_normalize(g - core)
        var shift = 0.0
        while drawn.contains(where: { simd_distance($0 + u * shift, core) < 0.022 }) { shift += 0.002 }
        for i in start..<s.count { s[i].points = s[i].points.map { $0 + u * shift } }
    }

    /// A lens's bezel: what lies inside `glass` shows through (or takes `tone` when set), and its frame out to `rim`
    /// changes tone along its length, so a neighbour's twist that slides it shows. Both stay inside the core.
    struct Bezel: Sendable {
        var centre: P
        var glass: Double
        var rim: Double
        var tone: Tone?
        var cuts: [Double]
        var tones: [Tone]
        /// Degrees the frame's runs are turned by, so bezels sharing runs differ.
        var turn: Double = 0

        /// The bezel's tone at p, or nil where the scene shows.
        func at(_ p: P) -> Tone? {
            let d: Double = simd_distance(p, centre)
            guard d < rim else { return nil }
            if d < glass { return tone }
            let a: Double = (LensArt.bearingOf(p, centre) + turn).truncatingRemainder(dividingBy: 360)
            return LensArt.bandTone(a, cuts, tones)
        }
    }

    typealias Tray = (centre: P, degrees: Double, rim: Tone, bath: Tone)
    typealias Print = (centre: P, degrees: Double)
}

// MARK: - 80: Darkroom

/// Level 80's name: a darkroom under its red safelight, the enlarger standing over the hub, its head and lens at the top
/// throwing a cone of white light down onto the easel, where the picture lies projected big, a house and a tree; its
/// column up the right past the safelight, and negatives hanging to dry from a line along the top. Three trays on the
/// bench below, developer, stop and fixer, each with a print coming up in it, and a loupe on a hanging negative at the
/// upper left. The five lenses (top, the bench's three and the upper left): down the enlarger's lens the negative in
/// its carrier, the house and tree small; in the trays a face, a sailing boat and a cat; and under the loupe a
/// bicycle on a frame of the negative.
extension LensArt {
    static let darkroom: Halftone.Panel = drawDarkroom()

    private static func darkroomTrays() -> [Tray] {
        [(hexAt[5], 18, Tone(0, 0.55, 0.2), Tone(0, 0.14, 0.08)),
         (hexAt[4], -4, Tone(0.08, 0.5, 0.62), Tone(0.02, 0.12, 0.14)),
         (hexAt[3], -20, Tone(0.38, 0.38, 0.4), Tone(0.08, 0.1, 0.12))]
    }

    /// Each tray's print: its centre and its turn.
    private static func darkroomPrints() -> [Print] {
        let trays: [Tray] = darkroomTrays()
        let offsets: [P] = [P(0.012, -0.008), P(-0.012, -0.006), P(0.01, 0.01)]
        let turns: [Double] = [10, -9, 14]
        return (0..<3).map { (k: Int) -> Print in (trays[k].centre + spun(offsets[k], trays[k].degrees), trays[k].degrees + turns[k]) }
    }

    private static func drawDarkroom() -> Halftone.Panel {
        let lensAt: P = hexAt[1], loupeAt: P = hexAt[6]
        let lenses: [P] = [hexAt[1], hexAt[3], hexAt[4], hexAt[5], hexAt[6]]
        let black: Tone = Tone(0.04, 0.03, 0.03), silver: Tone = Tone(0.42, 0.4, 0.4), red: Tone = Tone(0, 0.85, 0.45)
        let bezels: [Bezel] = [
            Bezel(centre: lensAt, glass: 0.17, rim: 0.25, tone: y(0.6),
                  cuts: [0, 30, 52, 100, 122, 200, 230, 300, 330], tones: [black, silver, black, red, black, silver, black, silver, black]),
            Bezel(centre: loupeAt, glass: 0.215, rim: 0.256, tone: y(0.5),
                  cuts: [0, 60, 90, 180, 210, 240, 300, 330], tones: [silver, black, silver, red, silver, black, silver, black]),
        ]
        let trays: [Tray] = darkroomTrays(), prints: [Print] = darkroomPrints()
        let lamp: P = P(0.66, -0.2)
        let head: [P] = squircle(P(0, -0.6), 0.34, 0.31, 40)
        let column: [P] = rect(0.3, -0.98, 0.37, 0.22), arm: [P] = rect(0.2, -0.88, 0.32, -0.8)
        let cone: [P] = [P(-0.13, -0.3), P(0.13, -0.3), P(0.27, -0.17), P(-0.27, -0.17)]
        let easel: [P] = rect(-0.27, -0.17, 0.27, 0.17), base: [P] = rect(-0.4, 0.17, 0.44, 0.25)
        let blades: [[P]] = [rect(-0.27, -0.17, 0.27, -0.12), rect(0.2, -0.17, 0.27, 0.17)]
        let roof: [P] = [P(-0.21, 0.0), P(-0.11, -0.09), P(-0.01, 0.0)], house: [P] = rect(-0.19, 0.0, -0.03, 0.12)
        let crown: P = P(0.09, -0.04)
        // The drying line along the top, and the negatives hanging from it: (x, top, bottom).
        let line: [P] = curve(P(-0.86, -0.5), P(0, -1.12), P(0.86, -0.5), 40)
        let strips: [(Double, Double, Double)] = [(-0.66, -0.66, -0.02), (-0.5, -0.74, 0.0), (0.5, -0.77, -0.46), (0.64, -0.7, -0.4)]
        let film: Tone = Tone(0.03, 0.5, 0.36), frames: Tone = Tone(0.2, 0.1, 0.16)

        var s: [Halftone.Stroke] = []
        // The enlarger: its head, the column and the arm, the cone of light, the easel and its blades, the baseboard.
        s.append(stroke(closed(head), bold))
        s.append(stroke(closed(column), mid))
        s.append(stroke(closed(arm), mid))
        s.append(stroke([cone[0], cone[3]], hair))
        s.append(stroke([cone[1], cone[2]], hair))
        s.append(stroke(closed(easel), mid))
        s.append(stroke(closed(base), mid))
        for b in blades { s.append(stroke(closed(b), hair)) }
        // The picture on the easel, projected big: the house, its door, the tree and the ground.
        s.append(stroke(closed(roof), mid))
        s.append(stroke(closed(house), mid))
        s.append(stroke(closed(rect(-0.13, 0.05, -0.08, 0.12)), hair))
        s.append(stroke(circle(crown, 0.075, 28), mid))
        s.append(stroke([P(0.09, 0.035), P(0.09, 0.12)], mid))
        s.append(stroke([P(-0.22, 0.12), P(0.2, 0.12)], hair))
        // The safelight: its rim, the cord up to the ceiling.
        s.append(stroke(circle(lamp, 0.11, 32), bold))
        s.append(stroke(circle(lamp, 0.14, 32), mid))
        s.append(stroke([lamp + P(0, -0.14), P(lamp.x, -0.76)], mid))
        // The line, the negatives on it and their pegs, the bench's edge.
        s += runs(line, mid) { !inside($0, head) }
        for (x, top, bottom) in strips {
            s.append(stroke(closed(rect(x - 0.06, top, x + 0.06, bottom)), mid))
            s.append(stroke(closed(rect(x - 0.025, top - 0.05, x + 0.025, top + 0.03)), mid))
            var yy: Double = top + 0.06
            while yy < bottom - 0.02 {
                for e: Double in [-0.045, 0.045] { s.append(stroke(closed(rect(x + e - 0.008, yy, x + e + 0.008, yy + 0.014)), hair)) }
                yy += 0.04
            }
        }
        s.append(stroke([P(-1, 0.1), P(-0.4, 0.1)], mid))
        s.append(stroke([P(0.44, 0.1), P(1, 0.1)], mid))
        s = clearOf(s, lenses)
        s += darkroomLenses(bezels: bezels, trays: trays, prints: prints)

        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for b in bezels { if let t = b.at(p) { return t } }
            for (k, tr) in trays.enumerated() where simd_distance(p, tr.centre) < 0.31 {
                let q: P = spun(p - tr.centre, -tr.degrees)
                if abs(q.x) < 0.225 && abs(q.y) < 0.17 {
                    let pr: P = spun(p - prints[k].centre, -prints[k].degrees)
                    if abs(pr.x) < 0.14 && abs(pr.y) < 0.105 { return abs(pr.x) < 0.122 && abs(pr.y) < 0.087 ? m(0.5) : y(0.8) }
                    return abs(q.x) < 0.195 && abs(q.y) < 0.14 ? tr.bath : tr.rim
                }
            }
            let dl: Double = simd_distance(p, lamp)
            if dl < 0.11 { return Tone(0, 0.95, 0.4) }
            if dl < 0.14 { return black }
            for (x, top, bottom) in strips where abs(p.x - x) < 0.06 && p.y > top && p.y < bottom {
                let gap: Bool = ((p.y - top) / 0.12).truncatingRemainder(dividingBy: 1) < 0.12
                return abs(p.x - x) > 0.035 || gap ? film : frames
            }
            if inside(p, column) || inside(p, arm) { return Tone(0.12, 0.3, 0.2) }
            if inside(p, easel) {
                if blades.contains(where: { inside(p, $0) }) { return Tone(0.1, 0.5, 0.62) }
                let trunk: Bool = abs(p.x - 0.09) < 0.015 && p.y > 0 && p.y < 0.12
                if simd_distance(p, crown) < 0.075 || trunk { return Tone(0.05, 0.05, 0.06) }
                if inside(p, roof) { return Tone(0.04, 0.04, 0.05) }
                if inside(p, house) { return Tone(0.24, 0.24, 0.24) }
                return p.y > 0.12 ? Tone(0.3, 0.3, 0.3) : Tone(0.62, 0.62, 0.6)
            }
            if inside(p, cone) { return Tone(0.3, 0.32, 0.3) }
            if inside(p, head) { return Tone(0.14, 0.16, 0.16) }
            if inside(p, base) { return Tone(0.04, 0.3, 0.2) }
            let glow: Double = max(0, 1 - dl / 0.75)
            let wall: Tone = p.y > 0.1 ? Tone(0, 0.12, 0.07) : Tone(0, 0.06, 0.02)
            return wall + Tone(0, 0.5 * glow * glow, 0.12 * glow * glow)
        }
        return Halftone.Panel(name: "darkroom", tones: tones, strokes: shotPieces(s))
    }

    /// The darkroom's lens cores: the enlarger's lens and the loupe, the trays and their prints, and each clue.
    private static func darkroomLenses(bezels: [Bezel], trays: [Tray], prints: [Print]) -> [Halftone.Stroke] {
        var s: [Halftone.Stroke] = []
        for b in bezels {
            s.append(stroke(circle(b.centre, b.rim, 56), bold))
            s.append(stroke(circle(b.centre, b.glass, 48), mid))
        }
        // The enlarger lens's aperture scale.
        for k in 0..<7 {
            let a: Double = 200 + 20 * Double(k)
            s.append(stroke([polar(bezels[0].centre, 0.18, a), polar(bezels[0].centre, 0.2, a)], hair))
        }
        // The negative under the loupe: its strip's edges and sprocket holes.
        let lx: Double = -0.5, loupe: P = bezels[1].centre
        for e: Double in [-0.06, 0.06] { s += runs(span(P(lx + e, -0.5), P(lx + e, -0.06), 40), hair) { simd_distance($0, loupe) < 0.214 } }
        for k in 0..<12 {
            let yy: Double = -0.5 + 0.04 * Double(k)
            for e: Double in [-0.045, 0.045] where simd_distance(P(lx + e, yy), loupe) < 0.2 {
                s.append(stroke(closed(rect(lx + e - 0.008, yy, lx + e + 0.008, yy + 0.014)), hair))
            }
        }
        // The trays' rims and the prints in them.
        for (k, tr) in trays.enumerated() {
            let outer: [P] = [P(-0.225, -0.17), P(0.225, -0.17), P(0.225, 0.17), P(-0.225, 0.17)].map { tr.centre + spun($0, tr.degrees) }
            s.append(stroke(closed(outer), mid))
            let inner: [P] = [P(-0.195, -0.14), P(0.195, -0.14), P(0.195, 0.14), P(-0.195, 0.14)].map { tr.centre + spun($0, tr.degrees) }
            s.append(stroke(closed(inner), hair))
            let corners: [P] = [P(-0.14, -0.105), P(0.14, -0.105), P(0.14, 0.105), P(-0.14, 0.105)].map { prints[k].centre + spun($0, prints[k].degrees) }
            s.append(stroke(closed(corners), mid))
        }
        var mark: Int = s.count
        s += negativeHouse(bezels[0].centre + P(0.01, 0.006))
        nudge(&s, from: mark, core: bezels[0].centre, scale: 0.85)
        mark = s.count
        s += bicycle(loupe + P(-0.004, 0.01))
        nudge(&s, from: mark, core: loupe)
        mark = s.count
        s += face(prints[0].centre, prints[0].degrees)
        nudge(&s, from: mark, core: trays[0].centre)
        mark = s.count
        s += sailboat(prints[1].centre, prints[1].degrees)
        nudge(&s, from: mark, core: trays[1].centre, scale: 0.85)
        mark = s.count
        s += cat(prints[2].centre, prints[2].degrees)
        nudge(&s, from: mark, core: trays[2].centre)
        return s
    }

    /// The negative in the enlarger's carrier: its frame, the house, the tree and the ground.
    private static func negativeHouse(_ o: P) -> [Halftone.Stroke] {
        var s: [Halftone.Stroke] = []
        s.append(stroke(closed([o + P(-0.046, 0.0), o + P(-0.024, -0.026), o + P(-0.002, 0.0)]), 0.0034))
        s.append(stroke(closed(rect(o.x - 0.042, o.y, o.x - 0.006, o.y + 0.03)), 0.0034))
        s.append(stroke(closed(rect(o.x - 0.029, o.y + 0.012, o.x - 0.019, o.y + 0.03)), 0.0022))
        s.append(stroke(circle(o + P(0.026, -0.008), 0.017, 16), 0.0034))
        s.append(stroke([o + P(0.026, 0.009), o + P(0.026, 0.03)], 0.0034))
        s.append(stroke([o + P(-0.056, 0.03), o + P(0.056, 0.03)], 0.0024))
        return s
    }

    /// A bicycle on a frame of the negative.
    private static func bicycle(_ o: P) -> [Halftone.Stroke] {
        let rear: P = o + P(-0.03, 0.012), front: P = o + P(0.03, 0.012), crank: P = o + P(-0.002, 0.012)
        let seat: P = o + P(-0.012, -0.022), bars: P = o + P(0.022, -0.024)
        var s: [Halftone.Stroke] = []
        s.append(stroke(circle(rear, 0.02, 16), 0.0032))
        s.append(stroke(circle(front, 0.02, 16), 0.0032))
        s.append(stroke([rear, seat, crank, rear], 0.003))
        s.append(stroke([seat, bars, crank], 0.003))
        s.append(stroke([bars, front], 0.003))
        s.append(stroke([bars, bars + P(-0.006, -0.012), bars + P(0.004, -0.014)], 0.0026))
        s.append(stroke([seat + P(-0.009, -0.004), seat + P(0.007, -0.004)], 0.003))
        return s
    }

    /// A portrait coming up on a print: the face, its hair, eyes and smile, and the shoulders.
    private static func face(_ o: P, _ degrees: Double) -> [Halftone.Stroke] {
        let at = { (x: Double, y: Double) -> P in o + spun(P(x, y), degrees) }
        let outline: [P] = (0...24).map { (i: Int) -> P in
            let a: Double = Double(i) * .pi / 12
            return at(0.026 * cos(a), 0.034 * sin(a))
        }
        var s: [Halftone.Stroke] = [stroke(outline, 0.0034)]
        s.append(stroke(curve(at(-0.03, -0.004), at(-0.01, -0.06), at(0.032, -0.01), 10), 0.003))
        for x: Double in [-0.01, 0.01] { s.append(stroke(circle(at(x, -0.004), 0.004, 8), 0.0026)) }
        s.append(stroke(curve(at(-0.012, 0.014), at(0, 0.024), at(0.012, 0.014), 6), 0.0026))
        return s
    }

    /// A sailing boat on the sea.
    private static func sailboat(_ o: P, _ degrees: Double) -> [Halftone.Stroke] {
        let at = { (x: Double, y: Double) -> P in o + spun(P(x, y), degrees) }
        var s: [Halftone.Stroke] = []
        s.append(stroke(closed([at(-0.04, 0.02), at(0.04, 0.02), at(0.028, 0.034), at(-0.03, 0.034)]), 0.0034))
        s.append(stroke([at(0.0, 0.02), at(0.0, -0.05)], 0.003))
        s.append(stroke(closed([at(0.004, -0.046), at(0.004, 0.014), at(0.038, 0.014)]), 0.003))
        s.append(stroke(closed([at(-0.004, -0.036), at(-0.004, 0.014), at(-0.03, 0.014)]), 0.003))
        for k in 0..<2 {
            let x0: Double = -0.07 + 0.07 * Double(k)
            let wave: [P] = curve(at(x0, 0.05), at(x0 + 0.017, 0.04), at(x0 + 0.034, 0.05), 5) + curve(at(x0 + 0.034, 0.05), at(x0 + 0.051, 0.06), at(x0 + 0.068, 0.05), 5)
            s.append(stroke(wave, 0.0024))
        }
        return s
    }

    /// A cat sitting: its head and ears, its body and its tail.
    private static func cat(_ o: P, _ degrees: Double) -> [Halftone.Stroke] {
        let at = { (x: Double, y: Double) -> P in o + spun(P(x, y), degrees) }
        let head: [P] = (0..<20).map { (i: Int) -> P in
            let a: Double = Double(i) * .pi / 10
            return at(0.016 * cos(a), -0.03 + 0.014 * sin(a))
        }
        var s: [Halftone.Stroke] = [stroke(closed(head), 0.0034)]
        for e: Double in [-1, 1] { s.append(stroke([at(e * 0.014, -0.036), at(e * 0.016, -0.056), at(e * 0.004, -0.043)], 0.003)) }
        let body: [P] = curve(at(-0.012, -0.018), at(-0.036, 0.03), at(-0.02, 0.044), 10) + [at(0.02, 0.044)] + curve(at(0.02, 0.044), at(0.034, 0.03), at(0.012, -0.018), 10)
        s.append(stroke(body, 0.0034))
        s.append(stroke(curve(at(0.022, 0.04), at(0.06, 0.04), at(0.05, 0.0), 10), 0.003))
        for e: Double in [-1, 1] { s.append(stroke(circle(at(e * 0.006, -0.032), 0.0025, 6), 0.002)) }
        return s
    }
}

// MARK: - 81: Contact sheet

/// Level 81's name: a contact sheet of a day at the seaside, three strips of the roll printed side by side and laid
/// askew, black between them, each frame a little grey photograph between its rebates' sprocket holes, and the pick of
/// the roll at the hub, a parasol on the sand under the sun, ringed in red grease pencil. A loupe sits on each of the
/// six frames round it (hex's six lenses on this level), each a different barrel, and under each what that frame
/// caught: a kite (top), a gull (upper right), a sandcastle and its flag (lower right), an ice cream (bottom), a crab
/// (lower left) and a beach ball (upper left).
extension LensArt {
    static let contactsheet: Halftone.Panel = drawContactsheet()

    /// The sheet's strips run along this, 0.485 apart across it, a frame every 0.56 along, so each of hex's rods sits
    /// on a frame's middle.
    private static let sheetAlong: P = P(0.866025, 0.5)
    private static let sheetAcross: P = P(-0.5, 0.866025)

    private static func stripPhase(_ k: Int) -> Double { k % 2 == 0 ? 0 : 0.28 }

    /// Where p lies on the sheet: its strip, its frame along the strip, and its place in that frame, along and across
    /// (down the photograph).
    private static func onSheet(_ p: P) -> (strip: Int, frame: Int, x: Double, y: Double) {
        let a: Double = simd_dot(p, sheetAcross)
        let k: Int = Int((a / 0.485).rounded())
        let t: Double = simd_dot(p, sheetAlong) - stripPhase(k)
        let f: Int = Int((t / 0.56).rounded())
        return (k, f, t - 0.56 * Double(f), a - 0.485 * Double(k))
    }

    /// The point at (x, y) in frame f of strip k.
    private static func onFrame(_ k: Int, _ f: Int, _ x: Double, _ y: Double) -> P {
        let along: Double = stripPhase(k) + 0.56 * Double(f) + x
        let across: Double = 0.485 * Double(k) + y
        return sheetAlong * along + sheetAcross * across
    }

    /// The sheet's one ink, cyan, a tone in a single screen, as a mixed grey's three screens shimmer.
    private static func grey(_ g: Double) -> Tone { c(g) }

    /// A frame's photograph at (x, y): the sky, the sea and the sand, the horizon at its own height in each frame, and
    /// the hub's frame the pick: a parasol and a bather under the sun, the horizon tipped.
    private static func snapshot(_ k: Int, _ f: Int, _ x: Double, _ y: Double) -> Tone {
        if k == 0 && f == 0 {
            if simd_distance(P(x, y), P(-0.17, -0.09)) < 0.045 { return LensArt.y(0.9) }
            let canopy: Double = simd_distance(P(x, y), P(0.1, 0.01))
            if canopy < 0.12 && y < 0.01 { return .zero }
            if abs(x - 0.1) < 0.01 && y > 0 && y < 0.14 { return .zero }
            if simd_length_squared((P(x, y) - P(-0.09, 0.06)) / P(0.03, 0.07)) < 1 { return .zero }
            let horizon: Double = -0.03 + 0.12 * x
            return y < horizon ? grey(0.62) : y < horizon + 0.05 ? grey(0.12) : grey(0.36)
        }
        let seed: Double = Double(3 * k + f)
        let horizon: Double = -0.05 + 0.04 * sin(seed * 1.7) + 0.025 * x
        let shore: Double = horizon + 0.05 + 0.02 * sin(seed * 2.3 + x * 9)
        return y < horizon ? grey(0.58 + 0.06 * sin(seed)) : y < shore ? grey(0.12) : grey(0.34)
    }

    private static func drawContactsheet() -> Halftone.Panel {
        let ring: [P] = Array(hexAt[1...6])
        let black: Tone = Tone(0.03, 0.03, 0.03), chrome: Tone = Tone(0.45, 0.45, 0.46)
        let barrels: [[Tone]] = [[black, chrome], [c(0.75), black], [y(0.8), black], [chrome, black], [m(0.7), black], [Tone(0.5, 0.2, 0), black]]
        let bezels: [Bezel] = (0..<6).map { (k: Int) -> Bezel in
            Bezel(centre: ring[k], glass: 0.226, rim: 0.26, tone: nil, cuts: [0, 40, 75, 150, 178, 250, 292],
                  tones: barrels[k] + barrels[k] + barrels[k] + [barrels[k][0]], turn: 53 * Double(k))
        }
        let open: (P) -> Bool = { (p: P) -> Bool in
            ring.allSatisfy { (c: P) -> Bool in
                let d: Double = simd_distance(p, c)
                return d < 0.222 || d > 0.264
            }
        }

        var s: [Halftone.Stroke] = []
        // Each strip's edges, each frame's edge, all cut where a loupe's barrel lies.
        for k in -2...2 {
            for e: Double in [-0.225, 0.225] {
                let line: [P] = span(onFrame(k, -3, 0, e), onFrame(k, 3, 0, e), 340)
                s += runs(line, hair) { open($0) && simd_length($0) < 1.01 }
            }
            for f in -3...3 where simd_length(onFrame(k, f, 0, 0)) < 1.25 {
                let corners: [P] = [onFrame(k, f, -0.255, -0.155), onFrame(k, f, 0.255, -0.155), onFrame(k, f, 0.255, 0.155), onFrame(k, f, -0.255, 0.155)]
                var line: [P] = []
                for j in 0..<4 { line += span(corners[j], corners[(j + 1) % 4], 64).dropLast() }
                line.append(corners[0])
                s += runs(line, k == 0 && f == 0 ? mid : hair) { open($0) && simd_length($0) < 1.01 }
            }
        }
        // The pick's parasol and bather, drawn.
        let canopy: [P] = arc(P(0.1, 0.01), 0.12, 180, 360, 20).map { onFrame(0, 0, $0.x, $0.y) }
        s.append(stroke(canopy + [canopy[0]], mid))
        s.append(stroke([onFrame(0, 0, 0.1, 0.01), onFrame(0, 0, 0.1, 0.14)], mid))
        for b in bezels {
            s.append(stroke(circle(b.centre, b.rim, 56), mid))
            s.append(stroke(circle(b.centre, b.glass, 56), bold))
        }
        s += contactClues()

        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for b in bezels { if let t = b.at(p) { return t } }
            // The grease pencil's ring round the pick.
            let g: P = P(simd_dot(p, sheetAlong) - 0.012, simd_dot(p, sheetAcross) - 0.006)
            let e: Double = simd_length(g / P(0.29, 0.19))
            if abs(e - 1) < 0.075 { return Tone(0, 0.9, 0.3) }
            let at = onSheet(p)
            let ay: Double = abs(at.y)
            if ay > 0.225 { return black }
            if ay > 0.155 || abs(at.x) > 0.255 {
                let w: Double = at.x - 0.07 * (at.x / 0.07).rounded(.down)
                return ay > 0.174 && ay < 0.206 && abs(w - 0.035) < 0.017 ? y(0.85) : .zero
            }
            return snapshot(at.strip, at.frame, at.x, at.y)
        }
        return Halftone.Panel(name: "contactsheet", tones: tones, strokes: shotPieces(s))
    }

    /// Under each loupe, what its frame caught, drawn upright in the frame.
    private static func contactClues() -> [Halftone.Stroke] {
        // Each ring rod's frame: (strip, frame), and the clue's start off the frame's middle.
        let frames: [(Int, Int)] = [(-1, -1), (-1, 0), (0, 1), (1, 0), (1, -1), (0, -1)]
        var s: [Halftone.Stroke] = []
        for (r, kf) in frames.enumerated() {
            let mark: Int = s.count
            let at = { (x: Double, y: Double) -> P in onFrame(kf.0, kf.1, x, y) }
            switch r {
            case 0: s += kite(at)
            case 1: s += gulls(at)
            case 2: s += sandcastle(at)
            case 3: s += icecream(at)
            case 4: s += crab(at)
            default: s += beachball(at)
            }
            nudge(&s, from: mark, core: hexAt[r + 1])
        }
        return s
    }

    private static func kite(_ at: (Double, Double) -> P) -> [Halftone.Stroke] {
        let o: P = P(0.012, -0.012)
        let top: P = o + P(0, -0.034), right: P = o + P(0.022, -0.004), foot: P = o + P(0, 0.036), left: P = o + P(-0.022, -0.004)
        var s: [Halftone.Stroke] = [stroke([top, right, foot, left, top].map { at($0.x, $0.y) }, 0.0034)]
        s.append(stroke([at(top.x, top.y), at(foot.x, foot.y)], 0.0024))
        s.append(stroke([at(left.x, left.y), at(right.x, right.y)], 0.0024))
        let tail: [P] = curve(foot, foot + P(0.03, 0.02), foot + P(0.02, 0.06), 10)
        s.append(stroke(tail.map { at($0.x, $0.y) }, 0.0024))
        for t in [3, 7] { s.append(stroke([tail[t] + P(-0.007, -0.004), tail[t] + P(0.007, 0.004)].map { at($0.x, $0.y) }, 0.003)) }
        return s
    }

    private static func gulls(_ at: (Double, Double) -> P) -> [Halftone.Stroke] {
        var s: [Halftone.Stroke] = []
        for (o, w) in [(P(0.0, -0.02), 0.03), (P(0.03, 0.022), 0.018)] as [(P, Double)] {
            let wing: [P] = curve(o + P(-w, 0), o + P(-w / 2, -w * 0.7), o, 8) + curve(o, o + P(w / 2, -w * 0.7), o + P(w, 0), 8).dropFirst()
            s.append(stroke(wing.map { at($0.x, $0.y) }, w > 0.02 ? 0.0036 : 0.0028))
        }
        return s
    }

    private static func sandcastle(_ at: (Double, Double) -> P) -> [Halftone.Stroke] {
        let o: P = P(0.004, 0.006)
        func line(_ q: [P], _ w: Double) -> Halftone.Stroke { stroke(q.map { at(o.x + $0.x, o.y + $0.y) }, w) }
        var s: [Halftone.Stroke] = [line([P(-0.04, 0.03), P(0.04, 0.03)], 0.0034)]
        for x: Double in [-0.04, 0.012] {
            s.append(line([P(x, 0.03), P(x, -0.02), P(x + 0.007, -0.02), P(x + 0.007, -0.012), P(x + 0.014, -0.012), P(x + 0.014, -0.02), P(x + 0.021, -0.02),
                           P(x + 0.021, -0.012), P(x + 0.028, -0.012), P(x + 0.028, 0.03)], 0.003))
        }
        s.append(line([P(-0.012, 0.0), P(0.012, 0.0)], 0.003))
        s.append(line([P(-0.006, 0.03), P(-0.006, 0.016)] + arc(P(0, 0.016), 0.006, 180, 360, 6) + [P(0.006, 0.03)], 0.0026))
        s.append(line([P(0.026, -0.02), P(0.026, -0.05)], 0.0026))
        s.append(line([P(0.026, -0.05), P(0.046, -0.043), P(0.026, -0.036)], 0.0026))
        return s
    }

    private static func icecream(_ at: (Double, Double) -> P) -> [Halftone.Stroke] {
        let o: P = P(-0.006, 0.004)
        func line(_ q: [P], _ w: Double) -> Halftone.Stroke { stroke(q.map { at(o.x + $0.x, o.y + $0.y) }, w) }
        var s: [Halftone.Stroke] = [line([P(-0.02, 0.0), P(0.0, 0.05), P(0.02, 0.0)], 0.0034)]
        s.append(line([P(-0.012, 0.012), P(0.008, 0.03)], 0.002))
        s.append(line([P(0.012, 0.012), P(-0.008, 0.03)], 0.002))
        s.append(line(arc(P(0, -0.004), 0.021, 160, 380, 14), 0.0034))
        s.append(line(arc(P(0.004, -0.03), 0.015, 170, 370, 12), 0.0034))
        s.append(line(circle(P(0.008, -0.05), 0.005, 8), 0.0028))
        return s
    }

    private static func crab(_ at: (Double, Double) -> P) -> [Halftone.Stroke] {
        let o: P = P(0.008, 0.01)
        func line(_ q: [P], _ w: Double) -> Halftone.Stroke { stroke(q.map { at(o.x + $0.x, o.y + $0.y) }, w) }
        var s: [Halftone.Stroke] = [line(ellipse(P(0, 0), 0.026, 0.016, 20), 0.0034)]
        for e: Double in [-1, 1] {
            s.append(line([P(e * 0.02, -0.01), P(e * 0.036, -0.03), P(e * 0.03, -0.044)], 0.003))
            s.append(line([P(e * 0.03, -0.044), P(e * 0.042, -0.05), P(e * 0.038, -0.036)], 0.003))
            for k in 0..<3 { s.append(line([P(e * 0.022, 0.004 + 0.006 * Double(k)), P(e * 0.042, 0.012 + 0.01 * Double(k)), P(e * 0.046, 0.024 + 0.01 * Double(k))], 0.0024)) }
            s.append(line([P(e * 0.008, -0.014), P(e * 0.01, -0.026)], 0.0024))
            s.append(line(circle(P(e * 0.01, -0.029), 0.003, 6), 0.0024))
        }
        return s
    }

    private static func beachball(_ at: (Double, Double) -> P) -> [Halftone.Stroke] {
        let o: P = P(0.016, -0.006)
        func line(_ q: [P], _ w: Double) -> Halftone.Stroke { stroke(q.map { at(o.x + $0.x, o.y + $0.y) }, w) }
        var s: [Halftone.Stroke] = [line(circle(P(0, 0), 0.032, 28), 0.0036)]
        s.append(line(curve(P(0, -0.032), P(-0.022, 0), P(0, 0.032), 10), 0.0026))
        s.append(line(curve(P(0, -0.032), P(0.022, 0), P(0, 0.032), 10), 0.0026))
        s.append(line(curve(P(-0.032, 0), P(0, 0.012), P(0.032, 0), 10), 0.0026))
        s.append(line(arc(P(0, 0), 0.022, 200, 250, 6), 0.002))
        s.append(line(curve(P(-0.06, 0.05), P(0, 0.042), P(0.06, 0.05), 10), 0.0022))
        return s
    }
}

// MARK: - 82: Widescreen

/// Level 82's name: a picture palace from the stalls, the screen stretched wide across the glass between red curtains
/// under a gold pelmet, the audience's heads black against it in their rows of red seats, an exit sign glowing green
/// at the lower left. On the screen a western in its widest close-up: the gunfighter's eyes under his hat's brim, his
/// revolver's muzzle up between them at us. The four lenses: his two eyes (upper left and right), his rival far down
/// the street in one pupil and the town clock at noon in the other; the muzzle at the hub, the rifling down the
/// barrel; and at the lower right a woman's opera glasses, the screen small through them, his eyes and the gun.
extension LensArt {
    static let widescreen: Halftone.Panel = drawWidescreen()

    /// The hat's brim across the screen, a little lower at the left.
    private static func brim(_ x: Double) -> Double { -0.47 - 0.09 * x * x + 0.05 * x }

    /// The audience's heads, as (centre, radii).
    private static let heads: [(P, P)] = [
        (P(-0.84, 0.27), P(0.07, 0.085)), (P(-0.58, 0.25), P(0.075, 0.09)), (P(-0.3, 0.28), P(0.07, 0.085)), (P(-0.11, 0.27), P(0.072, 0.088)),
        (P(-0.72, 0.52), P(0.085, 0.1)), (P(-0.44, 0.5), P(0.09, 0.105)), (P(-0.16, 0.53), P(0.085, 0.1)), (P(0.12, 0.5), P(0.09, 0.105)), (P(0.34, 0.62), P(0.085, 0.1)),
        (P(-0.56, 0.8), P(0.1, 0.12)), (P(-0.26, 0.78), P(0.11, 0.13)), (P(0.06, 0.82), P(0.1, 0.12)), (P(0.36, 0.8), P(0.11, 0.13)),
    ]

    private static func drawWidescreen() -> Halftone.Panel {
        let muzzle: P = hexAt[0], right: P = hexAt[2], opera: P = hexAt[3], left: P = hexAt[6]
        let lenses: [P] = [muzzle, right, opera, left]
        let top: Double = -0.62, bottom: Double = 0.16, side: Double = 0.86
        let skin: Tone = Tone(0.04, 0.4, 0.56), shade: Tone = Tone(0.02, 0.22, 0.3), dark: Tone = Tone(0.01, 0.01, 0.02)
        let steel: Tone = Tone(0.4, 0.4, 0.46), blued: Tone = Tone(0.12, 0.12, 0.18), gold: Tone = Tone(0.06, 0.45, 0.7)
        let irises: [Tone] = [c(0.7), Tone(0.25, 0.08, 0.3), c(0.5), Tone(0.3, 0.3, 0.1)]
        let bezels: [Bezel] = [
            Bezel(centre: muzzle, glass: 0.085, rim: 0.2, tone: dark, cuts: [0, 30, 70, 120, 200, 230, 300], tones: [steel, blued, Tone(0.6, 0.6, 0.62), blued, steel, blued, steel]),
            Bezel(centre: left, glass: 0.085, rim: 0.18, tone: dark, cuts: (0..<18).map { 20 * Double($0) }, tones: irises),
            Bezel(centre: right, glass: 0.085, rim: 0.18, tone: dark, cuts: (0..<18).map { 20 * Double($0) }, tones: irises, turn: 9),
            Bezel(centre: opera, glass: 0.17, rim: 0.24, tone: y(0.55), cuts: [0, 50, 80, 160, 190, 280, 310],
                  tones: [gold, Tone(0.55, 0.5, 0.5), gold, dark, gold, Tone(0.55, 0.5, 0.5), gold]),
        ]
        let other: P = opera + P(-0.36, 0.0), lady: P = opera + P(0.32, 0.14)
        let exit: [P] = rect(-0.75, 0.33, -0.55, 0.41)

        var s: [Halftone.Stroke] = []
        // The screen's edge, the hat's brim and its crown's band, the brows, the creases at the eyes, the nose's bridge.
        s.append(stroke(closed(rect(-side, top, side, bottom)), bold))
        let brimLine: [P] = stride(from: -side, through: side, by: 0.02).map { P($0, brim($0)) }
        s.append(stroke(brimLine, bold))
        s.append(stroke(brimLine.map { $0 + P(0, -0.06) }, hair))
        for e in [left, right] {
            let toward: Double = e.x < 0 ? 1 : -1
            s.append(stroke(curve(e + P(-0.3, -0.16), e + P(0, -0.26), e + P(0.3, -0.16), 16), mid))
            for k in 0..<3 {
                let corner: P = e + P(-toward * 0.36, 0.0)
                s.append(stroke(curve(corner, corner + P(-toward * 0.04, -0.03 + 0.03 * Double(k)), corner + P(-toward * 0.09, -0.05 + 0.05 * Double(k)), 6), hair))
            }
        }
        s.append(stroke(curve(P(-0.06, -0.2), P(-0.04, -0.1), P(-0.07, -0.02), 10), hair))
        // The curtains' folds and the pelmet's fringe.
        for x in stride(from: -1.0, through: 1.0, by: 0.05) where abs(x) > side + 0.02 { s.append(stroke([P(x, -0.74), P(x + 0.01, bottom)], hair)) }
        s.append(stroke(stride(from: -1.0, through: 1.0, by: 0.01).map { P($0, -0.74 + 0.025 * abs(sin($0 * 14))) }, mid))
        // The stage's edge, the heads in their rows, the exit sign and its letters.
        s.append(stroke([P(-1, 0.21), P(1, 0.21)], mid))
        for (c, r) in heads { s.append(stroke(ellipse(c, r.x, r.y, 24), mid)) }
        s.append(stroke(closed(exit), mid))
        s += exitLetters(P(-0.73, 0.35))
        // The opera glasses' other barrel, their bridge, the lady's head and her hand.
        s.append(stroke(circle(other, 0.12, 32), bold))
        s.append(stroke(circle(other, 0.085, 28), mid))
        s.append(stroke([other + P(0.12, -0.02), opera + P(-0.24, -0.02)], mid))
        s.append(stroke([other + P(0.12, 0.02), opera + P(-0.24, 0.02)], mid))
        s.append(stroke(ellipse(lady, 0.16, 0.2, 32), mid))
        s.append(stroke(circle(lady + P(0.08, -0.18), 0.07, 20), mid))
        s = clearOf(s, lenses)
        s += widescreenLenses(bezels: bezels)

        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            // The eyes: the lids close over the iris above and below.
            for e in [left, right] {
                let q: P = p - e
                if abs(q.x) < 0.36 {
                    let open: Double = 0.17 * (1 - (q.x / 0.36) * (q.x / 0.36))
                    if abs(q.y) < open { return bezels[e == left ? 1 : 2].at(p) ?? Tone(0.5, 0.5, 0.48) }
                    if abs(q.y) < open + 0.03 { return shade }
                }
            }
            if let t = bezels[0].at(p) { return t }
            if let t = bezels[3].at(p) { return t }
            if abs(p.x + 0) < 0.02 && p.y > muzzle.y - 0.26 && p.y < muzzle.y - 0.19 { return dark }
            if simd_distance(p, other) < 0.12 { return simd_distance(p, other) < 0.085 ? Tone(0.04, 0.16, 0.24) : gold }
            if simd_length_squared((p - lady) / P(0.16, 0.2)) < 1 || simd_distance(p, lady + P(0.08, -0.18)) < 0.07 { return Tone(0.06, 0.03, 0.02) }
            if p.y > bottom {
                for (c, r) in heads where simd_length_squared((p - c) / r) < 1 { return dark }
                if inside(p, exit) { return Tone(0.6, 0, 0.6) }
                if p.y < 0.21 { return Tone(0.05, 0.14, 0.1) }
                let row: Double = (p.y - 0.21).truncatingRemainder(dividingBy: 0.26)
                return row < 0.16 ? Tone(0.02, 0.34, 0.12) : Tone(0.01, 0.12, 0.05)
            }
            if p.y < -0.74 + 0.025 * abs(sin(p.x * 14)) {
                let fold: Double = 0.5 + 0.5 * sin(p.x * 30)
                return Tone(0.04, 0.3 + 0.25 * fold, 0.5 + 0.25 * fold)
            }
            if abs(p.x) > side {
                let fold: Double = 0.5 + 0.5 * sin(p.x * 60)
                return Tone(0, 0.25 + 0.45 * fold, 0.06 + 0.1 * fold)
            }
            if p.y < top { return .zero }
            // The film: his hat, the brim's shadow over his brow, his face.
            let b: Double = brim(p.x)
            if p.y < b - 0.06 { return Tone(0.06, 0.24, 0.22) }
            if p.y < b { return Tone(0.03, 0.08, 0.08) }
            if p.y < b + 0.08 { return shade }
            if abs(p.x) > 0.66 { return shade }
            return skin
        }
        return Halftone.Panel(name: "widescreen", tones: tones, strokes: shotPieces(s))
    }

    /// The sign's EXIT in strokes, from its top left.
    private static func exitLetters(_ o: P) -> [Halftone.Stroke] {
        let h: Double = 0.04, w: Double = 0.026, gap: Double = 0.042
        var s: [Halftone.Stroke] = [stroke([o + P(w, 0), o, o + P(0, h), o + P(w, h)], hair), stroke([o + P(0, h / 2), o + P(w * 0.8, h / 2)], hair)]
        let x: P = o + P(gap, 0)
        s.append(stroke([x, x + P(w, h)], hair))
        s.append(stroke([x + P(w, 0), x + P(0, h)], hair))
        let i: P = o + P(2 * gap + w / 2, 0)
        s.append(stroke([i, i + P(0, h)], hair))
        let t: P = o + P(2.6 * gap, 0)
        s.append(stroke([t, t + P(w, 0)], hair))
        s.append(stroke([t + P(w / 2, 0), t + P(w / 2, h)], hair))
        return s
    }

    /// The lenses' frames and clues: the muzzle's rims, its sight, the rifling; the eyes'
    /// lids and pupils, the rival and the clock; the opera glass's rims and the screen through it.
    private static func widescreenLenses(bezels: [Bezel]) -> [Halftone.Stroke] {
        let muzzle: P = bezels[0].centre, left: P = bezels[1].centre, right: P = bezels[2].centre, opera: P = bezels[3].centre
        var s: [Halftone.Stroke] = []
        s.append(stroke(circle(muzzle, 0.2, 56), bold))
        s.append(stroke(circle(muzzle, 0.085, 40), mid))
        s.append(stroke(closed(rect(-0.02, muzzle.y - 0.26, 0.02, muzzle.y - 0.19)), mid))
        for e in [left, right] {
            s.append(stroke(curve(e + P(-0.36, 0), e + P(0, -0.34), e + P(0.36, 0), 24), mid))
            s.append(stroke(curve(e + P(-0.36, 0), e + P(0, 0.34), e + P(0.36, 0), 24), mid))
            s += runs(circle(e, 0.18, 56), mid) { abs($0.y - e.y) < 0.17 * (1 - (($0.x - e.x) / 0.36) * (($0.x - e.x) / 0.36)) }
            s.append(stroke(circle(e, 0.085, 32), hair))
        }
        s.append(stroke(circle(opera, 0.24, 56), bold))
        s.append(stroke(circle(opera, 0.17, 48), mid))
        // Down the barrel: the rifling's six lands twisting in, and a glint on the bore.
        for k in 0..<6 {
            let spiral: [P] = (0...10).map { (i: Int) -> P in
                let r: Double = 0.03 + 0.005 * Double(i)
                return polar(muzzle, r, 60 * Double(k) + 9 * Double(i))
            }
            s.append(stroke(spiral, 0.0026))
        }
        s.append(stroke(arc(muzzle, 0.072, 200, 250, 8), 0.0034))
        // In the left pupil, the rival far down the street: hat, head, body, legs apart, his gun hand.
        var mark: Int = s.count
        let rv: P = left + P(0.03, 0.004)
        s.append(stroke([rv + P(-0.016, -0.03), rv + P(0.016, -0.03)], 0.003))
        s.append(stroke(closed(rect(rv.x - 0.008, rv.y - 0.042, rv.x + 0.008, rv.y - 0.03)), 0.0026))
        s.append(stroke(circle(rv + P(0, -0.022), 0.007, 10), 0.0028))
        s.append(stroke([rv + P(0, -0.015), rv + P(0, 0.012)], 0.0034))
        s.append(stroke([rv + P(-0.014, 0.04), rv + P(0, 0.012), rv + P(0.014, 0.04)], 0.003))
        s.append(stroke([rv + P(-0.016, 0.012), rv + P(-0.008, -0.01), rv + P(0.008, -0.01), rv + P(0.018, 0.01), rv + P(0.026, 0.008)], 0.0026))
        nudge(&s, from: mark, core: left)
        // In the right, the town clock at noon.
        mark = s.count
        let ck: P = right + P(-0.026, -0.016)
        s.append(stroke(circle(ck, 0.03, 24), 0.0034))
        for k in 0..<12 { s.append(stroke([polar(ck, 0.022, 30 * Double(k)), polar(ck, 0.028, 30 * Double(k))], k % 3 == 0 ? 0.0026 : 0.0016)) }
        s.append(stroke([ck, polar(ck, 0.016, -90)], 0.003))
        s.append(stroke([ck, polar(ck, 0.024, -96)], 0.0024))
        s.append(stroke(closed([ck + P(-0.034, -0.03), ck + P(0, -0.056), ck + P(0.034, -0.03)]), 0.0026))
        nudge(&s, from: mark, core: right)
        // Through the opera glass, the screen small and wide: the brim, his eyes and the muzzle.
        mark = s.count
        let sc: P = opera + P(0.006, -0.012)
        s.append(stroke(closed(rect(sc.x - 0.06, sc.y - 0.025, sc.x + 0.06, sc.y + 0.025)), 0.0034))
        s.append(stroke(curve(sc + P(-0.06, -0.012), sc + P(0, -0.022), sc + P(0.06, -0.012), 10), 0.0024))
        for x: Double in [-0.034, 0.034] {
            s.append(stroke(closed(ellipse(sc + P(x, -0.002), 0.016, 0.006, 12)), 0.0024))
            s.append(stroke(circle(sc + P(x, -0.002), 0.0025, 6), 0.002))
        }
        s.append(stroke(circle(sc + P(0, 0.008), 0.008, 10), 0.0026))
        nudge(&s, from: mark, core: opera)
        return s
    }
}
