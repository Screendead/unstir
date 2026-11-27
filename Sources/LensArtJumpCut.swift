// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 38 to 43, the chapter Jump cut.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let jumpCut: [Int: Halftone.Panel] = [38: cameraObscura]

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
}

// MARK: - 38: Camera obscura

/// Level 38's name: a darkened room, its window shuttered, and high in the shutter a brass-ringed hole, over the top core
/// (eye's small lens on this level), whose beam falls on a round screen on an easel over the right core (eye's big
/// lens), where an artist below has traced what it throws. Through the hole the village church outside, the right way
/// up; on the screen the same church upside down. Level 38 deals each lens +2.
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
        s.append(stroke(closed(rect(-0.92, -0.95, 0.3, 0.24)), bold))
        for x in [split - 0.022, split + 0.022] { s.append(stroke([P(x, -0.95), P(x, 0.24)], mid)) }
        for k in 0..<12 where k != 6 {
            let x = -0.85 + 0.095 * Double(k)
            s += runs(span(P(x, -0.95), P(x, 0.24), 40)) { p in
                simd_distance(p, hole) > 0.25 && simd_distance(p, screen) > 0.345 && abs(p.y + 0.02) > 0.04
            }
        }
        for (x0, x1) in [(-0.9, split - 0.04), (split + 0.04, 0.28)] {
            s += runs(span(P(x0, 0.14), P(x1, -0.84), 40), mid) { simd_distance($0, hole) > 0.25 && simd_distance($0, screen) > 0.345 }
            for yy in [-0.84, 0.14] { s += runs(span(P(x0, yy), P(x1, yy), 30), mid) { simd_distance($0, hole) > 0.25 && simd_distance($0, screen) > 0.345 } }
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
        for line in place(church, at: hole + P(0.024, -0.022), 0.05) { s.append(stroke(line, 0.003)) }
        for line in place(church, at: screen + P(-0.01, 0.05), 0.052, degrees: 180) { s.append(stroke(line, 0.0034)) }
        return panel("cameraobscura", fills: fills, strokes: s) { _ in c(0.16) }
    }()
}
