// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Direction C: the page varies by chapter, a ground from the family and a second ink each, and on it the problem's
/// emblem, a bold silhouette cut out of the ground and ruled in the chapter's ink, over the problem's number in Roman.
extension EscapementArt {
    static let chapterGrounds: [Pattern] = [.waves, .quilt, .contours, .barleycorn, .rosette]
    static let chapterInks = [vermilion, prussian, viridian, sepia, oxblood]

    static func chapterPlate(_ n: Int) -> Plate {
        let chapter = (n - 1) / 6
        var plate = Plate(second: chapterInks[chapter])
        ground(&plate, chapterGrounds[chapter], seed: n)
        switch n {
        case 2:
            let top = P(-0.3, -0.92), bob = P(0.14, 0.3), along = simd_normalize(bob - top)
            let rod = [top - P(along.y, -along.x) * 0.035, bob - P(along.y, -along.x) * 0.035,
                       bob + P(along.y, -along.x) * 0.035, top + P(along.y, -along.x) * 0.035]
            emblem(&plate, [rod + [rod[0]]], turn: 0.3)
            emblem(&plate, [arc(bob, 0.3), arc(bob, 0.09)], turn: 0.9)
            emblem(&plate, [arc(polar(top, 0.16, atan2(along.y, along.x)), 0.075)], turn: -0.4)
        case 4:
            let c = P(0.03, -0.06)
            emblem(&plate, [gear(c, 0.56, teeth: 17, phase: 0.1)] + windows(c, hub: 0.2, rim: 0.42, spokes: 5, width: 0.055, phase: 0.4)
                + [arc(c, 0.07)], turn: 0.7)
        case 9:
            let at = P(0, -0.08)
            func place(_ points: [P]) -> [P] { turned(points.map { $0 * 0.9 + at }, by: -0.14, about: at) }
            emblem(&plate, [place(bulbs)], turn: 0.5, open: true)
            let below = stride(from: 0.3, through: 0.66, by: 0.01).map { $0 }, above = stride(from: -0.3, through: 0.0, by: 0.01).map { $0 }
            let heap = below.map { P(min(bulb($0), ($0 - 0.3) / 0.5), $0) } + below.reversed().map { P(-min(bulb($0), ($0 - 0.3) / 0.5), $0) }
            let sand = above.map { P(bulb($0), $0) } + above.reversed().map { P(-bulb($0), $0) }
            for part in [heap, sand] { emblem(&plate, [place(part + [part[0]])], turn: 0.5) }
            for y in [-0.71, 0.71] { emblem(&plate, [place(box(P(-0.46, y - 0.05), P(0.46, y + 0.05)))], turn: 1.5) }
        case 25:
            emblem(&plate, [turned(darkSide(P(0.16, -0.06), 0.62, lit: 0.7), by: 0.5, about: P(0.16, -0.06))], turn: 1.0)
            for (c, r) in [(P(0.36, -0.3), 0.1), (P(0.5, 0.12), 0.065), (P(0.2, 0.3), 0.05)] {
                emblem(&plate, [star(c, r, turn: 0.2 + r)], turn: 0.2)
            }
        default: break
        }
        // The plate's number, in a cartouche under the emblem.
        let number = roman(n), width = text(number, at: P(0, 0), height: 0.1).flatMap { $0 }.map(\.x).max() ?? 0
        let frame = box(P(-width / 2 - 0.05, 0.71), P(width / 2 + 0.05, 0.88))
        plate.fill(frame)
        plate.line(frame, medium)
        plate.lines(text(number, at: P(-width / 2, 0.745), height: 0.1), heavy)
        return plate
    }

    /// A silhouette cut out of the ground: the rings by the even-odd rule, ruled close in the second ink and crossed
    /// wide in black, under a heavy outline. An open one is only ruled wide, as glass.
    private static func emblem(_ plate: inout Plate, _ rings: [[P]], turn: Double, open: Bool = false) {
        plate.fill(rings[0])
        if open {
            plate.lines(hatch(rings, angle: turn + 1.3, gap: 0.04).flatMap { dashed($0, on: 0.05, off: 0.025) }, fine)
        } else {
            plate.lines(hatch(rings, angle: turn, gap: 0.013), fine, .second)
            plate.lines(hatch(rings, angle: turn + 1.2, gap: 0.034), fine)
            for hole in rings.dropFirst() {
                plate.lines(hatch([hole], angle: turn - 0.5, gap: 0.03).flatMap { dashed($0, on: 0.03, off: 0.03) }, fine)
            }
        }
        for ring in rings { plate.line(ring, heavy) }
    }
}
