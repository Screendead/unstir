// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 38 to 43, the chapter Jump cut.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let jumpCut: [Int: Halftone.Panel] = [38: cameraObscura, 39: magicLantern, 40: zoetrope, 41: projector, 42: instantCamera, 43: zoomLens]

    /// A circle as `parts` arcs, so each stroke's box is small and a pixel far from the circle tests none of it.
    fileprivate static func hoop(_ c: P, _ r: Double, _ width: Double, parts: Int = 8, from a0: Double = 0) -> [Halftone.Stroke] {
        (0..<parts).map { k in
            let a = a0 + 360 * Double(k) / Double(parts)
            return stroke(arc(c, r, a, a + 360 / Double(parts), max(4, 64 / parts)), width)
        }
    }

    /// Lines drawn in a unit box, moved to `at`, scaled by `k` and turned `degrees`.
    fileprivate static func place(_ lines: [[P]], at: P, _ k: Double, degrees: Double = 0) -> [[P]] {
        let t = degrees * .pi / 180, cs = cos(t), sn = sin(t)
        return lines.map { $0.map { at + k * P($0.x * cs - $0.y * sn, $0.x * sn + $0.y * cs) } }
    }

    /// A village church in a unit box, its foot at y 0.5: nave and roof, tower, clock, spire and the cock on top.
    fileprivate static let church: [[P]] = [
        [P(-0.6, 0.5), P(0.6, 0.5)],
        closed(rect(-0.55, 0.16, 0.0, 0.5)),
        [P(-0.6, 0.16), P(-0.28, -0.08), P(0.0, 0.1)],
        closed(rect(0.0, -0.14, 0.26, 0.5)),
        [P(0.0, -0.14), P(0.13, -0.58), P(0.26, -0.14)],
        circle(P(0.13, 0.03), 0.06, 10),
        arc(P(0.13, 0.42), 0.05, 180, 360, 6) + [P(0.18, 0.5)],
        [P(0.13, -0.58), P(0.13, -0.72)],
        [P(0.04, -0.66), P(0.22, -0.66)],
        arc(P(-0.27, 0.3), 0.06, 180, 360, 6) + [P(-0.21, 0.4), P(-0.33, 0.4), P(-0.33, 0.3)],
    ]

    /// A sheet ghost in a unit box, arms up: head and sides, a hem in three scallops, eyes and a round mouth.
    fileprivate static let ghost: [[P]] = [
        [P(-0.62, -0.02), P(-0.4, 0.06)] + arc(P(0, 0), 0.4, 180, 360, 14) + [P(0.4, 0.06), P(0.62, -0.02)],
        [P(-0.4, 0.04), P(-0.4, 0.55)] + arc(P(-0.27, 0.55), 0.133, 180, 0, 5) + arc(P(0, 0.55), 0.133, 180, 0, 5)
            + arc(P(0.27, 0.55), 0.133, 180, 0, 5) + [P(0.4, 0.04)],
        circle(P(-0.14, -0.06), 0.06, 8), circle(P(0.14, -0.06), 0.06, 8), ellipse(P(0, 0.18), 0.07, 0.1, 10),
    ]

    /// A bird flying in a unit box, its wings `lift` up (negative for down): body, head and beak, tail and wings.
    fileprivate static func bird(_ lift: Double) -> [[P]] {
        let shoulder = P(0.04, -0.07), tip = P(-0.12 - 0.22 * (1 - abs(lift)), -0.58 * lift)
        let lead = shoulder + P(0.06, -0.3 * lift) + P(0, lift == 0 ? -0.06 : 0), back = P(-0.16, 0.0)
        return [
            closed(curve(P(0.24, -0.1), P(0.0, 0.18), P(-0.3, 0.02), 8) + curve(P(-0.3, 0.02), P(0, -0.12), P(0.24, -0.1), 8)),
            circle(P(0.32, -0.12), 0.09, 8), [P(0.4, -0.15), P(0.54, -0.11), P(0.41, -0.08)],
            [P(-0.28, 0.0), P(-0.56, -0.1), P(-0.5, 0.02), P(-0.56, 0.12), P(-0.28, 0.04)],
            curve(shoulder, lead, tip, 8) + [tip + (back - tip) * 0.35 + P(0.05, 0.03 * lift), tip + (back - tip) * 0.65, back],
        ]
    }

    /// Capitals and figures a unit tall and 0.6 wide, about their middle.
    fileprivate static let glyphs: [Character: [[P]]] = [
        "3": [[P(-0.28, -0.5), P(0.28, -0.5), P(0, -0.08)] + arc(P(0, 0.2), 0.3, -90, 150, 10)],
        "E": [[P(0.3, -0.5), P(-0.3, -0.5), P(-0.3, 0.5), P(0.3, 0.5)], [P(-0.3, 0), P(0.18, 0)]],
        "N": [[P(-0.3, 0.5), P(-0.3, -0.5), P(0.3, 0.5), P(0.3, -0.5)]],
        "D": [[P(-0.3, -0.5), P(-0.3, 0.5), P(-0.05, 0.5)] + arc(P(-0.05, 0), 0.5, 90, -90, 10) + [P(-0.3, -0.5)]],
        "1": [[P(-0.2, -0.3), P(0.05, -0.5), P(0.05, 0.5)], [P(-0.2, 0.5), P(0.3, 0.5)]],
        "2": [arc(P(0, -0.2), 0.28, 200, 360, 8) + [P(0.25, 0.0), P(-0.3, 0.5), P(0.3, 0.5)]],
        "5": [[P(0.28, -0.5), P(-0.24, -0.5), P(-0.28, -0.05)] + arc(P(0, 0.2), 0.3, -120, 150, 10)],
        "7": [[P(-0.3, -0.5), P(0.3, -0.5), P(-0.05, 0.5)]],
        "0": [ellipse(P(0, 0), 0.3, 0.5, 14)],
        "8": [circle(P(0, -0.26), 0.23, 10), circle(P(0, 0.24), 0.27, 10)],
        "Z": [[P(-0.3, -0.5), P(0.3, -0.5), P(-0.3, 0.5), P(0.3, 0.5)]],
        "O": [ellipse(P(0, 0), 0.32, 0.5, 14)],
        "M": [[P(-0.32, 0.5), P(-0.32, -0.5), P(0, 0.1), P(0.32, -0.5), P(0.32, 0.5)]],
    ]

    /// A word's strokes, its letters `k` tall, starting at `at` (the first letter's middle), each turned `degrees`.
    fileprivate static func word(_ text: String, at: P, _ k: Double, degrees: Double = 0, _ width: Double) -> [Halftone.Stroke] {
        let step = polar(P(0, 0), 0.85 * k, degrees)
        return text.enumerated().flatMap { i, ch in
            place(glyphs[ch] ?? [], at: at + step * Double(i), k, degrees: degrees).map { stroke($0, width) }
        }
    }

    /// An oil lamp's flame in a unit box: the flame, its blue heart, the wick and the burner's collar.
    fileprivate static let flame: [[P]] = [
        closed([P(0, -0.6)] + curve(P(0, -0.6), P(0.32, -0.1), P(0.2, 0.18), 8) + arc(P(0, 0.12), 0.21, 15, 165, 8)
            + curve(P(-0.2, 0.18), P(-0.32, -0.1), P(0, -0.6), 8)),
        closed(curve(P(0, -0.18), P(0.12, 0.02), P(0, 0.18), 6) + curve(P(0, 0.18), P(-0.12, 0.02), P(0, -0.18), 6)),
        [P(0, 0.33), P(0, 0.46)],
        closed(rect(-0.3, 0.46, 0.3, 0.62)),
        [P(-0.42, 0.62), P(0.42, 0.62)],
    ]
}

// MARK: - 38: Camera obscura

/// Level 38's name: a darkened room, its window shuttered, and high in the shutter a brass-ringed hole, over the top core
/// (eye's small lens on this level), whose beam falls on a round screen on an easel over the right core (eye's big
/// lens), where an artist below has traced what it throws. Through the hole the village church outside, the right way
/// up; on the screen the same church upside down.
extension LensArt {
    static let cameraObscura: Halftone.Panel = {
        let hole = P(0, -0.56), screen = P(0.4, 0), paper = P(0.13, 0.505)
        let toward = simd_normalize(screen - hole), across = P(-toward.y, toward.x)
        let beam = [hole + across * 0.12, screen + across * 0.3, screen - across * 0.3, hole - across * 0.12]
        let lid = polar(hole, 0.33, 150), split = -0.34
        let table = [P(-0.52, 0.36), P(0.5, 0.36), P(0.62, 0.68), P(-0.64, 0.68)]
        let sheet = [P(-0.08, 0.39), P(0.3, 0.38), P(0.34, 0.65), P(-0.06, 0.66)]
        // What the artist has painted from the screen, upside down: the church on its hill.
        func painted(_ q: [P]) -> [P] { q.map { paper - 0.19 * $0 } }
        let picture = [fill(painted([P(0.13, -0.58), P(0.0, -0.14), P(0.26, -0.14)]), c(0.75)), fill(painted(rect(0.0, -0.14, 0.26, 0.5)), c(0.75)),
                       fill(painted([P(-0.6, 0.16), P(-0.28, -0.08), P(0.0, 0.1), P(0.0, 0.16)]), m(0.8)), fill(painted(rect(-0.55, 0.16, 0.0, 0.5)), m(0.5)),
                       fill(painted(rect(-0.62, 0.5, 0.62, 0.62)), Tone(0.45, 0, 0.6))]
        let warm = m(0.6), warmer = m(0.42)
        let bands = (0..<12).map { k in fill(sector(screen, 0.25, 0.335, 30 * Double(k) + 5, 30 * Double(k) + 19), y(0.85)) }
        let board = rect(screen.x - 0.37, screen.y - 0.37, screen.x + 0.37, screen.y + 0.37)
        let legs = [(P(0.26, 0.24), P(0.14, 0.94)), (P(0.54, 0.24), P(0.68, 0.9)), (P(0.4, 0.3), P(0.42, 0.98))]
        let fills = [disc(screen, 0.25, c(0.5))] + bands + legs.map { fill(bar($0.0, $0.1, 0.05), Tone(0, 0.4, 0.75)) } + [ring(screen, 0.25, 0.335, m(0.7)), disc(hole, 0.2, c(0.65)), ring(hole, 0.2, 0.245, y(0.85)),
                     oval(lid, 0.11, 0.075, y(0.85)), fill(beam, y(0.4)), fill(board, Tone(0.45, 0, 0.55)),
                     fill(rect(split - 0.022, -0.95, split + 0.022, 0.24), y(0.9)), fill(bar(P(-0.56, -0.02), P(-0.16, -0.02), 0.06), c(0.75)),
                     fill(rect(-0.92, -0.95, split, 0.24), warm), fill(rect(split, -0.95, 0.3, 0.24), warmer),
                     ] + picture + [fill(sheet, y(0.55)), disc(P(-0.3, 0.47), 0.05, c(0.85)), fill(table, Tone(0.3, 0.5, 0)), fill(rect(-1, 0.64, 1, 1), c(0.32))]

        var s: [Halftone.Stroke] = []
        // The shutter: its frame, the two leaves, their boards, braces and strap hinges, and the latch across.
        let clear = { (p: P) in simd_distance(p, screen) > 0.345 && !inside(p, board) }
        s += runs(span(P(-0.92, -0.95), P(0.3, -0.95), 40) + span(P(0.3, -0.95), P(0.3, 0.24), 40) + span(P(0.3, 0.24), P(-0.92, 0.24), 40)
            + span(P(-0.92, 0.24), P(-0.92, -0.95), 40), bold, keep: clear)
        for x in [split - 0.022, split + 0.022] { s.append(stroke([P(x, -0.95), P(x, 0.24)], mid)) }
        for k in 0..<12 where k != 6 {
            let x = -0.85 + 0.095 * Double(k)
            s += runs(span(P(x, -0.95), P(x, 0.24), 40)) { p in
                simd_distance(p, hole) > 0.25 && clear(p) && abs(p.y + 0.02) > 0.04
            }
        }
        for (x0, x1) in [(-0.9, split - 0.04), (split + 0.04, 0.28)] {
            s += runs(span(P(x0, 0.14), P(x1, -0.84), 40), mid) { simd_distance($0, hole) > 0.25 && clear($0) }
            for yy in [-0.84, 0.14] { s += runs(span(P(x0, yy), P(x1, yy), 30), mid) { simd_distance($0, hole) > 0.25 && clear($0) } }
        }
        for yy in [-0.7, 0.04] {
            s.append(stroke(closed(bar(P(-0.94, yy), P(-0.66, yy), 0.035)), mid))
            s.append(stroke(circle(P(-0.66, yy), 0.03, 10), mid))
        }
        s.append(stroke(closed(bar(P(-0.56, -0.02), P(-0.16, -0.02), 0.06)), mid))
        s.append(stroke(circle(P(-0.5, -0.02), 0.018, 8), hair))
        s.append(stroke(circle(P(-0.2, -0.02), 0.018, 8), hair))
        // The hole: its brass ring, screwed in, the cover swung off it on a hinge.
        s += hoop(hole, 0.245, bold)
        s += hoop(hole, 0.2, mid)
        for k in 0..<6 { s.append(stroke(circle(polar(hole, 0.222, 60 * Double(k) - 10), 0.01, 6), hair)) }
        s.append(stroke(closed(bar(polar(hole, 0.23, 150), polar(hole, 0.29, 150), 0.05)), mid))
        s.append(stroke(ellipse(lid, 0.11, 0.075, 24), bold))
        s.append(stroke(circle(lid + P(-0.03, 0.01), 0.018, 8), mid))
        // The beam, and three of its rays.
        for t in [-0.7, 0.0, 0.7] {
            s += dashes(hole + across * (0.1 * t) + toward * 0.25, screen + across * (0.24 * t) - toward * 0.32, 6)
        }
        // The screen: its hoop, ticked, the clamp at the top, and the easel.
        s += hoop(screen, 0.335, bold)
        s += hoop(screen, 0.25, mid)
        for k in 0..<36 where k % 9 != 0 && (k < 22 || k > 28) {
            s.append(stroke([polar(screen, k % 3 == 0 ? 0.258 : 0.27, 10 * Double(k)), polar(screen, 0.32, 10 * Double(k))], hair))
        }
        s.append(stroke(closed(bar(polar(screen, 0.32, -90), polar(screen, 0.4, -90), 0.07)), mid))
        s.append(stroke(circle(polar(screen, 0.42, -90), 0.022, 8), mid))
        for (a, b) in legs { s.append(stroke(closed(bar(a, b, 0.05)), mid)) }
        s.append(stroke(closed(board), bold))
        s.append(stroke([P(0.24, 0.5), P(0.58, 0.5)], mid))
        // The table: its top, legs, the sheet with the tracing, the inkwell and quill, and the floor.
        s.append(stroke(closed(table), bold))
        for (a, b) in [(P(-0.6, 0.68), P(-0.58, 0.96)), (P(0.58, 0.68), P(0.56, 0.96))] { s.append(stroke([a, b], bold)) }
        s.append(stroke(closed(sheet), mid))
        for line in place(church, at: paper, 0.19, degrees: 180) { s.append(stroke(line, hair)) }
        s.append(stroke(circle(P(-0.3, 0.47), 0.05, 16), mid))
        s.append(stroke(curve(P(-0.29, 0.44), P(-0.24, 0.3), P(-0.12, 0.24), 10), mid))
        s.append(stroke(curve(P(-0.24, 0.34), P(-0.17, 0.31), P(-0.12, 0.24), 6), hair))
        s += runs(span(P(-1, 0.64), P(1, 0.64), 60), mid) { abs($0.x - 0.4) > 0.05 }
        for k in 0..<4 { s.append(stroke([P(-0.9 + 0.5 * Double(k), 0.64), P(-1.1 + 0.62 * Double(k), 1)], hair)) }
        // Through the hole the church, the right way up; on the screen, upside down and back to front.
        for line in place(church, at: hole + P(0.03, -0.03), 0.05) { s.append(stroke(line, 0.003)) }
        for line in place(church, at: screen + P(-0.01, 0.05), 0.052, degrees: 180) { s.append(stroke(line, 0.0034)) }
        return panel("cameraobscura", fills: fills, strokes: s) { _ in c(0.16) }
    }()
}

// MARK: - 39: Magic lantern

/// Level 39's name: a tin magic lantern on its table, side on, its chimney smoking, a painted slide in the gate of its
/// brass tube, and the beam thrown up onto a sheet hung behind, two of the audience watching. Over the lower left core (one of hex's
/// three lenses on this level) the lamp house's red peep window, and in it the lamp's flame; over the hub the slide,
/// and on it a ghost painted upside down, as slides go in; over the upper right core the picture on the sheet, the
/// ghost the right way up.
extension LensArt {
    static let magicLantern: Halftone.Panel = {
        let hub = P(0, 0), peep = P(-0.485, 0.28), shown = P(0.485, -0.28)
        let u = P(cos(-.pi / 6), sin(-.pi / 6)), n = P(-u.y, u.x)
        let back = hub - u * 0.36, front = hub + u * 0.3
        let tube = bar(back, front, 0.17), hood = bar(hub + u * 0.2, front, 0.22)
        let slide = [hub - n * 0.46 - u * 0.27, hub - n * 0.46 + u * 0.27, hub + n * 0.46 + u * 0.27, hub + n * 0.46 - u * 0.27]
        let toward = simd_normalize(shown - front), across = P(-toward.y, toward.x)
        let beam = [front + across * 0.1, shown + across * 0.3, shown - across * 0.3, front - across * 0.1]
        let body = rect(-0.82, -0.06, -0.15, 0.62), roof = [P(-0.88, -0.06), P(-0.09, -0.06), P(-0.22, -0.17), P(-0.75, -0.17)]
        let chimney = rect(-0.67, -0.6, -0.53, -0.17)
        let crown = closed([P(-0.72, -0.6), P(-0.48, -0.6), P(-0.48, -0.7), P(-0.52, -0.7), P(-0.52, -0.66), P(-0.58, -0.66), P(-0.58, -0.7),
                            P(-0.62, -0.7), P(-0.62, -0.66), P(-0.68, -0.66), P(-0.68, -0.7), P(-0.72, -0.7)])
        let sheet = rect(0.1, -0.9, 0.98, 0.45), heads = [(P(0.42, 0.42), 0.11), (P(0.76, 0.36), 0.1)]
        let wood = Tone(0, 0.45, 0.7), brass = y(0.8)
        // The painted border round a slide's picture and round its picture on the sheet.
        func border(_ c: P) -> [Fill] {
            (0..<10).map { k in disc(polar(c, 0.218, 36 * Double(k) + 9), 0.017, y(0.9)) } + [ring(c, 0.19, 0.245, m(0.8))]
        }
        var fills = [disc(peep, 0.19, m(0.85)), ring(peep, 0.19, 0.245, brass), disc(hub, 0.19, c(0.6))] + border(hub)
        fills += [disc(shown, 0.19, c(0.6))] + border(shown)
        fills += (0..<9).map { k in fill(sector(shown, 0.245, 0.3, 40 * Double(k), 40 * Double(k) + 22), y(0.85)) }
        fills += [fill(hood, brass), fill(tube, y(0.6)), fill(slide, Tone(0.35, 0.5, 0)), fill(beam, y(0.55)), fill(crown, brass), fill(chimney, c(0.55)),
                  fill(roof, brass), fill(body, c(0.55))]
        fills.append(disc(heads[0].0 + P(0.08, -0.08), 0.045, y(0.9)))
        fills += heads.flatMap { [disc($0.0, $0.1, .zero), oval($0.0 + P(0.02, 0.22), $0.1 * 1.9, $0.1 * 1.3, .zero)] }
        fills += [fill(sheet, y(0.3)), fill(rect(-1, 0.62, 0.3, 0.72), wood)]

        var s: [Halftone.Stroke] = []
        // The sheet on its line, pegged, and its folds.
        s += runs(span(sheet[0], sheet[1], 40) + span(sheet[1], sheet[2], 60) + span(sheet[2], sheet[3], 40) + span(sheet[3], sheet[0], 60), mid) { p in
            simd_distance(p, hub) > 0.25 && !inside(p, slide) && !inside(p, hood)
        }
        s.append(stroke(curve(P(0.0, -0.93), P(0.5, -0.86), P(1.0, -0.93), 16), mid))
        for x in [0.16, 0.42, 0.7, 0.92] { s.append(stroke(closed(rect(x - 0.012, -0.95, x + 0.012, -0.86)), hair)) }
        for x in [0.3, 0.56, 0.82] {
            s += runs(span(P(x, -0.86), P(x + 0.03, 0.43), 50)) { p in simd_distance(p, shown) > 0.27 && heads.allSatisfy { simd_distance(p, $0.0) > $0.1 + 0.01 } }
        }
        // The lantern: body and its seams, the roof and its rivets, chimney and crown, smoke, the tube and its rings.
        s.append(stroke(closed(body), bold))
        s += runs(span(P(-0.82, 0.04), P(-0.15, 0.04), 30), hair) { simd_distance($0, peep) > 0.25 }
        s += runs(span(P(-0.82, 0.52), P(-0.15, 0.52), 30), hair) { simd_distance($0, peep) > 0.25 }
        s.append(stroke(closed(roof), bold))
        for k in 0..<6 { s.append(stroke(circle(P(-0.76 + 0.11 * Double(k), -0.115), 0.012, 6), hair)) }
        s.append(stroke(closed(chimney), bold))
        for k in 0..<3 { s.append(stroke(closed(rect(-0.63, -0.52 + 0.1 * Double(k), -0.57, -0.46 + 0.1 * Double(k))), hair)) }
        s.append(stroke(crown, mid))
        s.append(stroke(curve(P(-0.6, -0.74), P(-0.52, -0.82), P(-0.6, -0.88), 10) + curve(P(-0.6, -0.88), P(-0.68, -0.94), P(-0.58, -0.99), 10), mid))
        for q in [tube, hood] {
            s += runs((0..<4).flatMap { span(q[$0], q[($0 + 1) % 4], 30) }, bold) { simd_distance($0, hub) > 0.25 && simd_distance($0, peep) > 0.25 }
        }
        for t in [0.24, 0.28] { s.append(stroke([hub + u * t - n * 0.11, hub + u * t + n * 0.11], hair)) }
        s.append(stroke(closed(bar(hub + u * 0.24 + n * 0.11, hub + u * 0.24 + n * 0.17, 0.035)), mid))
        // The slide: its frame, the pull at its end, and the beam's rays.
        s.append(stroke(closed(slide), bold))
        s += runs(span(slide[0] + n * 0.06, slide[1] + n * 0.06, 20), hair) { _ in true }
        s += runs(span(slide[3] - n * 0.06, slide[2] - n * 0.06, 20), hair) { _ in true }
        s.append(stroke(circle(hub + n * 0.53, 0.04, 10), mid))
        for t in [-0.6, 0.6] { s += dashes(front + across * (0.08 * t), shown + across * (0.26 * t) - toward * 0.25, 3) }
        // The peep window's ring, riveted, its catch; the pictures' borders.
        s += hoop(peep, 0.245, bold)
        s += hoop(peep, 0.19, mid)
        for k in 0..<8 where k != 2 { s.append(stroke(circle(polar(peep, 0.218, 45 * Double(k)), 0.01, 6), hair)) }
        s.append(stroke(closed(bar(polar(peep, 0.2, 90), polar(peep, 0.3, 90), 0.04)), mid))
        for c in [hub, shown] {
            s += hoop(c, 0.245, bold)
            s += hoop(c, 0.19, mid)
        }
        // The audience from behind, one with a bow in her hair; the table's edge.
        for (c, r) in heads {
            s += runs(circle(c, r, 24), mid) { $0.y < c.y + r * 0.7 }
            s += runs(ellipse(c + P(0.02, 0.22), r * 1.9, r * 1.3, 28), mid) { simd_distance($0, c) > r }
        }
        s.append(stroke(circle(heads[0].0 + P(0.08, -0.08), 0.045, 12), mid))
        s += runs(span(P(-1, 0.62), P(0.3, 0.62), 40), mid) { _ in true }
        s.append(stroke([P(0.3, 0.62), P(0.3, 0.72), P(-1, 0.72)], mid))
        for x in [-0.7, 0.18] { s.append(stroke([P(x, 0.72), P(x + 0.02, 1)], bold)) }
        // In the peep window the flame; on the slide the ghost upside down; on the sheet the ghost.
        for line in place(flame, at: peep + P(0.03, -0.036), 0.075) { s.append(stroke(line, 0.0034)) }
        for line in place(ghost, at: hub + P(0.036, 0.032), 0.06, degrees: 180) { s.append(stroke(line, 0.0032)) }
        for line in place(ghost, at: shown + P(0.036, -0.034), 0.064) { s.append(stroke(line, 0.0034)) }
        return panel("magiclantern", fills: fills, strokes: s) { _ in m(0.24) }
    }()
}

// MARK: - 40: Zoetrope

/// Level 40's name: a zoetrope, its red drum seen from a little above, the strip inside lit through the slits, and its
/// paper strip pulled out over the front and hanging, three of its frames over the top, hub and bottom cores (hex's
/// three lenses on this level): a bird with its wings up, level and down, one beat of its flight a frame.
extension LensArt {
    static let zoetrope: Halftone.Panel = {
        let frames = [P(0, -0.56), P(0, 0), P(0, 0.56)]
        let top = P(0, -0.48), foot = P(0, 0.3), rx = 0.86, ry = 0.22
        let front = arc(foot, rx, 0, 180, 24).map { P($0.x, foot.y + ($0.y - foot.y) * ry / rx) }
        let wall = [P(-rx, top.y), P(rx, top.y)] + front
        // A slit at `a` degrees round the drum's front, foreshortened as the drum turns away.
        func slit(_ a: Double) -> [P] {
            let x = rx * sin(a * .pi / 180), w = 0.036 * cos(a * .pi / 180), drop = ry * cos(a * .pi / 180)
            return rect(x - w, top.y + drop + 0.05, x + w, top.y + drop + 0.33)
        }
        let angles = stride(from: -75.0, through: 75, by: 15).filter { abs($0) > 20 }
        let band = rect(-rx, 0.02, rx, 0.1), ribbon = rect(-0.2, -0.86, 0.2, 0.99)
        var fills = frames.map { disc($0, 0.19, c(0.6)) }
        for f in frames {
            fills += (0..<6).map { k in fill(sector(f, 0.19, 0.245, 60 * Double(k) + 20, 60 * Double(k) + 40), y(0.85)) }
            fills.append(ring(f, 0.19, 0.245, m(0.45)))
        }
        fills.append(fill(ribbon, y(0.35)))
        fills += angles.map { fill(slit($0), y(0.9)) }
        let back = arc(top, rx, 180, 360, 24).map { P($0.x, top.y + ($0.y - top.y) * ry / rx) }
        let inner = arc(top, rx - 0.04, 360, 180, 24).map { P($0.x, top.y + 0.1 + ($0.y - top.y) * ry / rx) }
        fills += [fill(back + inner, y(0.6)), oval(top, rx, ry, .zero), fill(band, y(0.8)), fill(wall, m(0.7)),
                  oval(P(0, 0.82), 0.42, 0.1, Tone(0, 0.4, 0.7)), fill(rect(-1, 0.82, 1, 1), c(0.4))]

        var s: [Halftone.Stroke] = []
        // The drum: its rims, the slits, the band round it, the stand and its foot, the table's edge.
        let rim = ellipse(top, rx, ry, 48)
        for k in 0..<6 { s += runs(Array(rim[(8 * k)...(8 * k + 8)]), bold) { abs($0.x) > 0.21 } }
        s += runs(front, bold) { abs($0.x) > 0.21 }
        for x in [-rx, rx] { s.append(stroke([P(x, top.y), P(x, foot.y)], bold)) }
        for a in angles { s.append(stroke(closed(slit(a)), abs(a) > 50 ? hair : mid)) }
        for yy in [band[0].y, band[2].y] { s += runs(span(P(-rx, yy), P(rx, yy), 40), mid) { abs($0.x) > 0.21 } }
        s += runs(ellipse(P(0, 0.82), 0.42, 0.1, 28), bold) { abs($0.x) > 0.2 }
        s += runs(span(P(-1, 0.82), P(1, 0.82), 40), mid) { abs($0.x) > 0.42 }
        // The strip, curled over the rim at the top, its edges and a notch between frames, and its frames' numbers.
        for x in [-0.2, 0.2] { s += runs(span(P(x, -0.86), P(x, 0.99), 80), mid) { p in frames.allSatisfy { simd_distance(p, $0) > 0.25 } } }
        s.append(stroke(curve(P(-0.2, -0.86), P(0, -0.96), P(0.2, -0.86), 10), mid))
        for f in frames {
            s += hoop(f, 0.245, bold)
            s += hoop(f, 0.19, mid)
        }
        for yy in [-0.28, 0.28, 0.84] { s.append(stroke(closed([P(-0.2, yy - 0.03), P(-0.15, yy), P(-0.2, yy + 0.03)]), hair)); s.append(stroke([P(0.12, yy - 0.02), P(0.16, yy + 0.02)], hair)) }
        // The three beats of the bird's flight.
        for (f, lift) in zip(frames, [0.9, 0.05, -0.8]) {
            for line in place(bird(lift), at: f + P(0.032, 0.03), 0.075) { s.append(stroke(line, 0.0032)) }
        }
        return panel("zoetrope", fills: fills, strokes: s) { _ in c(0.2) }
    }()
}

// MARK: - 41: Projector

/// Level 41's name: a film projector in its booth, side on, its two reels up on their arms over the upper left and
/// upper right cores and its lamp house's window over the bottom one (hex's three lenses on this level), the film
/// running down through its sprockets and the beam going out through the lens, a poster for the night's show on the wall.
/// On the feed reel the leader's countdown at 3, on the take-up reel the last frame's END, and in the lamp house the
/// bulb, its filament lit.
extension LensArt {
    static let projector: Halftone.Panel = {
        let feed = P(-0.485, -0.28), takeUp = P(0.485, -0.28), lamp = P(0, 0.56)
        let body = rect(-0.62, 0.02, 0.5, 0.84), motor = P(-0.64, 0.4), barrel = bar(P(0.48, 0.2), P(0.86, 0.2), 0.16)
        let poster = rect(-0.19, -0.93, 0.13, -0.5), sprockets = [P(-0.14, 0.15), P(0.2, 0.32)]
        let filmIn = [polar(feed, 0.2, 60), polar(feed, 0.2, 60) + P(0.04, 0.06), sprockets[0] + P(-0.06, -0.04), sprockets[0] + P(0.0, 0.07)]
        let filmOut = [sprockets[1] + P(0.06, 0.04), sprockets[1] + P(0.12, -0.04), polar(takeUp, 0.2, 110) + P(-0.02, 0.06), polar(takeUp, 0.2, 110)]
        let metal = Tone(0.45, 0, 0.3), film = Tone.zero
        func reel(_ at: P) -> [Fill] {
            (0..<6).map { k in fill(sector(at, 0.205, 0.275, 60 * Double(k) + 15, 60 * Double(k) + 45), .zero) } + [disc(at, 0.19, m(0.55)), ring(at, 0.19, 0.29, y(0.85))]
        }
        var fills = reel(feed) + reel(takeUp) + [disc(lamp, 0.19, y(0.75))]
        fills += (0..<12).map { k in fill(sector(lamp, 0.19, 0.245, 30 * Double(k), 30 * Double(k) + 14), .zero) } + [ring(lamp, 0.19, 0.245, m(0.7))]
        fills += (0..<8).map { k in fill(sector(lamp, 0.25, 0.3, 45 * Double(k) + 10, 45 * Double(k) + 30), .zero) } + [ring(lamp, 0.245, 0.3, y(0.85))]
        fills += [fill(bar(filmIn[0], filmIn[1], 0.07), film), fill(bar(filmIn[1], filmIn[2], 0.07), film), fill(bar(filmOut[1], filmOut[2], 0.07), film),
                  fill(bar(filmOut[2], filmOut[3], 0.07), film)]
        fills += sprockets.map { disc($0, 0.09, c(0.85)) }
        fills += [fill(bar(sprockets[0], sprockets[1], 0.07), film), fill(barrel, y(0.8)), disc(motor, 0.15, c(0.65)), fill(body, metal),
                  fill(bar(P(-0.06, 0.02), feed, 0.05), c(0.7)), fill(bar(P(0.06, 0.02), takeUp, 0.05), c(0.7)),
                  fill([P(0.86, 0.1), P(1, -0.06), P(1, 0.46), P(0.86, 0.3)], y(0.45)), fill(poster, y(0.8)), fill(rect(-1, 0.84, 1, 1), m(0.35))]

        var s: [Halftone.Stroke] = []
        // The body: outline, a seam, its feet, the motor's vents, the rewind crank, the barrel and its focus knob.
        s.append(stroke(closed(body), bold))
        s += runs(span(P(-0.62, 0.24), P(0.5, 0.24), 40), hair) { simd_distance($0, lamp) > 0.25 && simd_distance($0, sprockets[1]) > 0.1 }
        for x in [-0.5, 0.38] { s.append(stroke(closed(rect(x - 0.05, 0.84, x + 0.05, 0.92)), mid)) }
        s.append(stroke(circle(motor, 0.15, 24), bold))
        for k in 0..<4 { s.append(stroke([motor + P(-0.09, -0.06 + 0.04 * Double(k)), motor + P(0.02, -0.06 + 0.04 * Double(k))], hair)) }
        s.append(stroke([motor, motor + P(-0.1, 0.22), motor + P(-0.2, 0.22)], mid))
        s.append(stroke(closed(barrel), bold))
        for x in [0.6, 0.72] { s.append(stroke([P(x, 0.12), P(x, 0.28)], hair)) }
        s.append(stroke(circle(P(0.66, 0.34), 0.035, 10), mid))
        s.append(stroke([P(0.66, 0.28), P(0.66, 0.305)], mid))
        // The beam, and dust in it.
        for t in [0.0, 1.0] { s.append(stroke([P(0.86, 0.1 + 0.2 * t), P(1.02, -0.07 + 0.55 * t)], hair)) }
        for at in [P(0.92, 0.12), P(0.95, 0.26), P(0.9, 0.2)] { s.append(stroke(circle(at, 0.006, 5), hair)) }
        // The reels' arms, the film and its sprockets, its holes down each edge.
        for (a, b) in [(P(-0.06, 0.02), feed), (P(0.06, 0.02), takeUp)] { s += runs(span(a, b, 20), mid) { simd_distance($0, b) > 0.3 } }
        for path in [Array(filmIn[0...2]), Array(filmOut[1...3]), [sprockets[0], sprockets[1]]] {
            for k in 1..<path.count {
                let d = simd_normalize(path[k] - path[k - 1]), side = P(-d.y, d.x) * 0.035
                for e in [side, -side] { s += runs(span(path[k - 1] + e, path[k] + e, 12), hair) { p in sprockets.allSatisfy { simd_distance(p, $0) > 0.09 } } }
            }
        }
        for c in sprockets {
            s.append(stroke(circle(c, 0.09, 20), mid))
            for k in 0..<8 { s.append(stroke([polar(c, 0.09, 45 * Double(k)), polar(c, 0.11, 45 * Double(k))], mid)) }
            s.append(stroke(circle(c, 0.02, 6), hair))
        }
        // The reels: flanges, notched and riveted; the lamp house's grille.
        for c in [feed, takeUp] {
            s += hoop(c, 0.29, bold)
            s += hoop(c, 0.19, mid)
            for k in 0..<6 { s.append(stroke(closed(sector(c, 0.205, 0.275, 60 * Double(k) + 15, 60 * Double(k) + 45)), hair)) }
        }
        s += hoop(lamp, 0.3, bold)
        s += hoop(lamp, 0.245, mid)
        s += hoop(lamp, 0.19, mid)
        // The poster: its border and a star.
        s.append(stroke(closed(poster), mid))
        s.append(stroke(closed(rect(-0.16, -0.9, 0.1, -0.53)), hair))
        s.append(stroke(star(P(-0.03, -0.73), 0.1, degrees: -80), mid))
        // On the feed reel the countdown, on the take-up reel the end; in the lamp house the bulb.
        let count = feed + P(0.036, -0.034)
        s.append(stroke(circle(count, 0.042, 16), 0.003))
        s.append(stroke(circle(count, 0.034, 16), 0.0018))
        for (a, b) in [(P(-0.052, 0), P(-0.04, 0)), (P(0.04, 0), P(0.052, 0)), (P(0, -0.052), P(0, -0.04)), (P(0, 0.04), P(0, 0.052))] {
            s.append(stroke([count + a, count + b], 0.0024))
        }
        s += place(glyphs["3"]!, at: count, 0.044).map { stroke($0, 0.0034) }
        s += word("END", at: takeUp + P(0.0, -0.036), 0.03, 0.003)
        s.append(stroke(curve(takeUp + P(-0.014, -0.012), takeUp + P(0.03, 0.0), takeUp + P(0.074, -0.012), 8), 0.0022))
        let bulb = lamp + P(0.034, -0.038)
        s.append(stroke(arc(bulb, 0.03, 130, 410, 16) + [bulb + P(0.012, 0.045), bulb + P(-0.012, 0.045)] + [polar(bulb, 0.03, 130)], 0.003))
        for k in 0..<3 { s.append(stroke([bulb + P(-0.013, 0.05 + 0.007 * Double(k)), bulb + P(0.013, 0.05 + 0.007 * Double(k))], 0.0022)) }
        s.append(stroke([bulb + P(-0.008, 0.042), bulb + P(-0.012, 0.0)] + (0...6).map { bulb + P(-0.012 + 0.004 * Double($0), $0 % 2 == 0 ? 0.0 : -0.01) }
            + [bulb + P(0.012, 0.0), bulb + P(0.008, 0.042)], 0.0026))
        return panel("projector", fills: fills, strokes: s) { _ in Tone(0.2, 0.2, 0) }
    }()
}

// MARK: - 42: Instant camera

/// Level 42's name: an instant camera face on, mint, a rainbow stripe down its front, a print sliding out of its slot
/// still dark, and its three windows over the upper left, top and lower right cores (hex's three lenses on this level):
/// in the finder the birthday dog in its party hat, framed; in the selfie mirror the one taking it, two fingers up; in
/// the lens the cake, its candles lit.
extension LensArt {
    static let instantCamera: Halftone.Panel = {
        let finder = P(-0.485, -0.28), mirror = P(0, -0.56), lens = P(0.485, 0.28), button = P(-0.64, 0.16)
        let body = squircle(P(0, -0.1), 0.9, 0.72, 64), flash = rect(0.28, -0.6, 0.76, -0.36)
        let print = rect(-0.36, 0.5, 0.2, 0.95), image = rect(-0.31, 0.55, 0.15, 0.8)
        let stripes = [y(0.9), Tone(0, 0.6, 0.8), m(0.85), Tone(0.45, 0.6, 0)]
        var fills = [disc(finder, 0.19, m(0.6)), ring(finder, 0.19, 0.245, .zero)]
        fills += (0..<6).map { k in fill(sector(finder, 0.245, 0.3, 60 * Double(k) + 20, 60 * Double(k) + 50), .zero) } + [ring(finder, 0.245, 0.3, y(0.85)), disc(mirror, 0.19, y(0.75)), disc(lens, 0.19, c(0.75))]
        fills += (0..<8).map { k in fill(sector(mirror, 0.19, 0.245, 45 * Double(k), 45 * Double(k) + 22), .zero) } + [ring(mirror, 0.19, 0.245, m(0.8))]
        fills += (0..<4).map { k in fill(sector(lens, 0.19, 0.245, 90 * Double(k) + 10, 90 * Double(k) + 40), y(0.85)) } + [ring(lens, 0.19, 0.245, .zero)]
        fills += [ring(lens, 0.245, 0.31, m(0.55)), ring(lens, 0.31, 0.38, .zero), fill(image, Tone(0.15, 0.1, 0)), fill(print, y(0.55)), fill(flash, y(0.85)),
                  disc(button, 0.1, m(0.95))]
        fills += stripes.enumerated().map { k, t in fill(rect(-0.34 + 0.07 * Double(k), -0.82, -0.27 + 0.07 * Double(k), 0.5), t) }
        fills += [fill(body, c(0.5)), fill(rect(-1, 0.62, 1, 1), Tone(0.3, 0.3, 0))]

        var s: [Halftone.Stroke] = []
        // The body, its slot and the print in it, the flash's ribs, the button, the strap's lug and the switch.
        let outline = closed(body), front = { (p: P) in simd_distance(p, lens) > 0.385 }
        for k in 0..<8 { s += runs(Array(outline[(8 * k)...(8 * k + 8)]), bold, keep: front) }
        s += runs(span(P(-0.5, 0.5), P(0.5, 0.5), 30), bold) { ($0.x < -0.36 || $0.x > 0.2) && front($0) }
        s.append(stroke(closed(print), mid))
        s.append(stroke(closed(image), hair))
        s.append(stroke(closed(flash), bold))
        for k in 1..<8 { s.append(stroke([P(0.28 + 0.06 * Double(k), -0.6), P(0.28 + 0.06 * Double(k), -0.36)], hair)) }
        s.append(stroke(circle(button, 0.1, 20), bold))
        s.append(stroke(circle(button, 0.06, 14), hair))
        s.append(stroke(closed(rect(0.86, -0.3, 0.96, -0.18)), mid))
        s.append(stroke(closed(rect(-0.82, 0.32, -0.62, 0.38)), mid))
        s.append(stroke(closed(rect(-0.76, 0.31, -0.72, 0.39)), mid))
        for x in [-0.34, -0.27, -0.2, -0.13, -0.06] { s += runs(span(P(x, -0.82), P(x, 0.5), 40), hair) { simd_distance($0, mirror) > 0.25 && simd_distance($0, finder) > 0.3 } }
        // The windows: the finder's dark rim, the mirror's, banded, and the lens: glass, focus ring and barrel.
        s += hoop(finder, 0.3, bold)
        for c in [finder, mirror, lens] {
            s += hoop(c, 0.245, bold)
            s += hoop(c, 0.19, mid)
        }
        s += hoop(lens, 0.31, mid)
        s += hoop(lens, 0.38, bold, parts: 12)
        for k in 0..<40 where k % 10 != 3 { s.append(stroke([polar(lens, 0.32, 9 * Double(k)), polar(lens, k % 5 == 0 ? 0.37 : 0.35, 9 * Double(k))], hair)) }
        for k in 0..<12 where k % 4 != 1 { s.append(stroke([polar(finder, 0.2, 30 * Double(k) + 15), polar(finder, 0.235, 30 * Double(k) + 15)], hair)) }
        // In the finder the dog in its party hat, framed; in the mirror the one taking it; in the lens the cake.
        let dog = finder + P(0.032, 0.03)
        for (sx, sy) in [(-1.0, -1.0), (1, -1), (1, 1), (-1, 1)] {
            s.append(stroke([dog + P(sx * 0.06, sy * 0.045), dog + P(sx * 0.06, sy * 0.06), dog + P(sx * 0.045, sy * 0.06)], 0.0022))
        }
        s.append(stroke(circle(dog + P(0, 0.008), 0.02, 14), 0.0034))
        for sx in [-1.0, 1.0] { s.append(stroke(ellipse(dog + P(sx * 0.024, 0.012), 0.008, 0.016, degrees: sx * 20, 8), 0.003)) }
        s.append(stroke(ellipse(dog + P(0, 0.02), 0.009, 0.006, 8), 0.0028))
        for sx in [-1.0, 1.0] { s.append(stroke(circle(dog + P(sx * 0.008, 0.002), 0.002, 4), 0.0026)) }
        s.append(stroke(closed([dog + P(-0.011, -0.01), dog + P(0.004, -0.044), dog + P(0.013, -0.008)]), 0.003))
        s.append(stroke(circle(dog + P(0.004, -0.048), 0.004, 6), 0.0024))
        let face = mirror + P(-0.03, 0.026)
        s.append(stroke(circle(face, 0.022, 14), 0.0034))
        s.append(stroke(arc(face + P(0, 0.002), 0.012, 20, 160, 8), 0.0026))
        for sx in [-1.0, 1.0] { s.append(stroke(circle(face + P(sx * 0.008, -0.006), 0.0022, 4), 0.0026)) }
        s.append(stroke(curve(face + P(-0.022, -0.006), face + P(-0.012, -0.034), face + P(0.02, -0.014), 8), 0.0024))
        let hand = face + P(0.038, 0.0)
        s.append(stroke(closed(rect(hand.x - 0.008, hand.y - 0.002, hand.x + 0.008, hand.y + 0.016)), 0.003))
        s.append(stroke([hand + P(-0.006, -0.002), hand + P(-0.014, -0.032)], 0.003))
        s.append(stroke([hand + P(0.004, -0.002), hand + P(0.012, -0.032)], 0.003))
        s.append(stroke([hand + P(0, 0.016), hand + P(-0.002, 0.034)], 0.003))
        let cake = lens + P(0.032, 0.034)
        s.append(stroke(closed(rect(cake.x - 0.034, cake.y, cake.x + 0.034, cake.y + 0.024)), 0.0034))
        s.append(stroke(closed(rect(cake.x - 0.024, cake.y - 0.018, cake.x + 0.024, cake.y)), 0.0032))
        s.append(stroke((0...8).map { cake + P(-0.034 + 0.0085 * Double($0), $0 % 2 == 0 ? 0.004 : 0.01) }, 0.0022))
        for x in [-0.014, 0.0, 0.014] {
            s.append(stroke([cake + P(x, -0.018), cake + P(x, -0.032)], 0.0026))
            s.append(stroke(closed([cake + P(x, -0.046), cake + P(x + 0.004, -0.038), cake + P(x, -0.034), cake + P(x - 0.004, -0.038)]), 0.002))
        }
        s.append(stroke(squash(arc(cake + P(0, 0.024), 0.05, 0, 180, 10), about: cake.y + 0.024, by: 0.25), 0.002))
        return panel("instantcamera", fills: fills, strokes: s) { _ in m(0.28) }
    }()
}

// MARK: - 43: Zoom lens

/// Level 43's name: a zoom lens face on, its front glass dark blue and full of coloured reflections, ZOOM and its focal
/// lengths on the name ring and the rubber grip round it. Three of the reflections, in a line through the middle over
/// the upper left, hub and lower right cores (hex's three lenses on this level), show what the lens sees as it zooms
/// in: a giraffe by a tree on the plain, then its head and neck, then its eye.
extension LensArt {
    static let zoomLens: Halftone.Panel = {
        let wide = P(-0.485, -0.28), mid0 = P(0, 0), tight = P(0.485, 0.28), o = P(0, 0)
        let tones = [m(0.75), c(0.85), y(0.85)]
        var fills: [Fill] = []
        for (at, t) in zip([wide, mid0, tight], tones) {
            fills.append(disc(at, 0.19, t))
            fills += (0..<7).map { k in fill(sector(at, 0.19, 0.245, 360 / 7 * Double(k), 360 / 7 * Double(k) + 26), y(0.9)) }
            fills.append(ring(at, 0.19, 0.245, .zero))
            fills += [m(0.8), c(0.9), y(0.9)].enumerated().map { k, t in fill(sector(at, 0.245, 0.3, 120 * Double(k) + 40, 120 * Double(k) + 110), t) }
        }
        // The glass's other reflections, each well off its rod's centre: a window, two crescents and a spark.
        let window = squircle(P(-0.08, -0.62), 0.16, 0.12, degrees: -8, 24)
        fills += [fill(window, y(0.7)), oval(P(0.46, -0.35), 0.19, 0.13, c(0.3)), oval(P(0.53, -0.44), 0.18, 0.12, y(0.9)),
                  oval(P(0.06, 0.56), 0.2, 0.13, c(0.3)), oval(P(0.14, 0.65), 0.18, 0.12, m(0.85)), disc(P(-0.6, 0.38), 0.09, y(0.8)),
                  ring(P(-0.6, 0.38), 0.12, 0.17, m(0.55))]
        fills += [disc(o, 0.86, c(0.3)), ring(o, 0.86, 0.925, Tone(0.15, 0.15, 0)), ring(o, 0.925, 1.0, m(0.22))]

        var s: [Halftone.Stroke] = []
        // The rims: glass, name ring and the grip's ridges; ZOOM and the focal lengths round the name ring.
        s += hoop(o, 0.86, bold, parts: 16)
        s += hoop(o, 0.925, mid, parts: 16)
        for k in 0..<72 { s.append(stroke([polar(o, 0.94, 5 * Double(k)), polar(o, 0.99, 5 * Double(k))], hair)) }
        func around(_ text: String, from a: Double) -> [Halftone.Stroke] {
            text.enumerated().flatMap { i, ch in
                let at = a + 3.8 * Double(i)
                return place(glyphs[ch] ?? [], at: polar(o, 0.892, at), 0.04, degrees: at + 90).map { stroke($0, hair) }
            }
        }
        s += around("ZOOM", from: -103)
        s += around("18", from: -70)
        s += around("35", from: -40)
        s += around("50", from: -10)
        s += around("70", from: 20)
        s += around("105", from: 50)
        s += around("200", from: 86)
        s += around("1", from: 160)
        s += around("35", from: 172)
        // The reflections' rims, the iris's blades and a glint on each, and the others' outlines.
        for c in [wide, mid0, tight] {
            s += hoop(c, 0.245, bold)
            s += hoop(c, 0.19, mid)
            s += hoop(c, 0.3, hair)
            s.append(stroke(arc(c, 0.215, 200, 250, 8), bold))
        }
        s.append(stroke(closed(window), mid))
        s.append(stroke([P(-0.08, -0.74), P(-0.08, -0.5)], mid))
        s.append(stroke([P(-0.24, -0.6), P(0.08, -0.64)], mid))
        s.append(stroke(squash(arc(P(0.53, -0.44), 0.18, 150, 330, 14), about: -0.44, by: 0.67), mid))
        s.append(stroke(squash(arc(P(0.14, 0.65), 0.18, -30, 150, 14), about: 0.65, by: 0.67), mid))
        s += glint(P(-0.6, 0.38), 0.07, mid)
        s += hoop(P(-0.6, 0.38), 0.17, hair)
        // What the zoom sees: the plain, the giraffe's head and neck, its eye.
        let plain = wide + P(0.03, 0.03)
        s.append(stroke([plain + P(-0.06, 0.03), plain + P(0.06, 0.03)], 0.0022))
        let tree = plain + P(-0.03, 0.0)
        s.append(stroke([tree + P(-0.002, 0.03), tree + P(0, 0.008), tree + P(-0.014, -0.004)], 0.003))
        s.append(stroke([tree + P(0, 0.008), tree + P(0.012, -0.004)], 0.0026))
        s.append(stroke([tree + P(-0.032, -0.002)] + arc(tree + P(-0.02, -0.004), 0.012, 180, 300, 5) + arc(tree + P(0, -0.008), 0.013, 220, 320, 5)
            + arc(tree + P(0.02, -0.004), 0.012, 240, 360, 5) + [tree + P(0.032, -0.002), tree + P(-0.032, -0.002)], 0.003))
        let g = plain + P(0.024, 0.0)
        s.append(stroke(closed(rect(g.x - 0.012, g.y - 0.004, g.x + 0.012, g.y + 0.008)), 0.003))
        for x in [-0.01, -0.005, 0.005, 0.01] { s.append(stroke([g + P(x, 0.008), g + P(x * 1.2, 0.03)], 0.0022)) }
        s.append(stroke([g + P(0.01, -0.004), g + P(0.022, -0.036), g + P(0.032, -0.032)], 0.0026))
        s.append(stroke([g + P(0.022, -0.036), g + P(0.021, -0.042)], 0.0018))
        let neck = mid0 + P(0.032, 0.036)
        s.append(stroke(curve(neck + P(-0.03, 0.04), neck + P(-0.026, 0.0), neck + P(-0.008, -0.036), 8), 0.0034))
        s.append(stroke(curve(neck + P(0.0, 0.04), neck + P(0.004, 0.0), neck + P(0.016, -0.03), 8), 0.0034))
        s.append(stroke(closed([neck + P(-0.012, -0.034), neck + P(0.012, -0.05), neck + P(0.046, -0.036), neck + P(0.046, -0.026), neck + P(0.018, -0.024)]), 0.0034))
        for x in [-0.004, 0.006] { s.append(stroke([neck + P(x, -0.042), neck + P(x - 0.002, -0.058)], 0.0028)); s.append(stroke(circle(neck + P(x - 0.002, -0.06), 0.003, 5), 0.0024)) }
        s.append(stroke(circle(neck + P(0.012, -0.036), 0.003, 5), 0.0026))
        s.append(stroke(ellipse(neck + P(-0.016, -0.038), 0.01, 0.004, degrees: 20, 8), 0.0022))
        for at in [P(-0.016, 0.02), P(-0.01, -0.006), P(-0.02, -0.018), P(-0.008, 0.012)] { s.append(stroke(circle(neck + at, 0.0035, 5), 0.0018)) }
        let eye = tight + P(0.03, 0.036)
        s.append(stroke(curve(eye + P(-0.042, 0.0), eye + P(0, -0.034), eye + P(0.042, 0.0), 10), 0.0034))
        s.append(stroke(curve(eye + P(-0.042, 0.0), eye + P(0, 0.028), eye + P(0.042, 0.0), 10), 0.0034))
        s.append(stroke(circle(eye, 0.012, 12), 0.003))
        s.append(stroke(circle(eye + P(0.003, -0.002), 0.004, 6), 0.0034))
        for k in 0..<5 {
            let x = -0.026 + 0.013 * Double(k), lid = eye + P(x, -0.017 + 0.00002 * x * x * 1000)
            s.append(stroke([lid, lid + P(0.004 * (Double(k) - 2), -0.014)], 0.0022))
        }
        return panel("zoomlens", fills: fills, strokes: s) { _ in .zero }
    }()
}
