// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// The drawing kit for problems 31 to 90's plates, one file a chapter (EscapementArtChapter6.swift to 15). Those
/// problems are dealt 9 to 38 entries deep, and a deep stack shears a fine ruling into a grey that hides every seam:
/// their plates are cut bold, in large masses of ink and bone over a coarse ground, so a twisted piece of the picture
/// still reads as a shape, and fine hatching is kept to small parts.
extension EscapementArt {
    enum Kit {
        typealias P = EscapementArt.P
        static let origin = P(0, 0)
        /// The bold plates' ground: rules this far apart and this wide, which a stack of 38 shears into bands a player
        /// can still follow, where the first book's 0.034 apart at `fine` goes grey past about 20.
        static let groundGap = 0.06, groundWidth = 0.008
        /// The narrowest a band of ink or bone is drawn, where it can be followed through a twist.
        static let boldest = 0.05

        /// The direction of hour `h` on a dial, twelve up.
        static func clock(_ h: Double) -> Double { -.pi / 2 + h * .pi / 6 }

        /// The coarse ruled ground over the glass, left out of the rings by the even-odd rule.
        static func ground(_ plate: inout Plate, angle: Double, around rings: [[P]] = [], gap: Double = groundGap,
                           width: Double = groundWidth) {
            plate.lines(hatch([Array(glass)] + rings, angle: angle, gap: gap), width)
        }

        /// A straight strip `width` wide from a to b, as an outline.
        static func band(_ a: P, _ b: P, _ width: Double) -> [P] {
            let n = simd_normalize(P(-(b - a).y, (b - a).x)) * (width / 2)
            return [a + n, b + n, b - n, a - n, a + n]
        }

        /// A mass of ink: the outline filled solid, and its edge.
        static func mass(_ plate: inout Plate, _ ring: [P], ink: Ink = .black) {
            plate.fill(ring, ink)
            plate.line(ring, medium, ink)
        }

        /// A part cut from the ground: bone under it, section hatching, then its edge.
        static func solid(_ plate: inout Plate, _ ring: [P], angle: Double, gap: Double = 0.03, ink: Ink = .black,
                          width: Double = medium, edge: Double = medium) {
            plate.fill(ring)
            plate.lines(hatch([ring], angle: angle, gap: gap), width, ink)
            plate.line(ring, edge)
        }

        /// A part cut from the ground in plain bone, outlined.
        static func cut(_ plate: inout Plate, _ ring: [P], edge: Double = medium) {
            plate.fill(ring)
            plate.line(ring, edge)
        }

        /// A strip `width` wide along a path, as one outline.
        static func ribbon(_ path: [P], _ width: Double) -> [P] {
            var left: [P] = [], right: [P] = []
            for i in path.indices {
                let d = path[min(i + 1, path.count - 1)] - path[max(i - 1, 0)]
                let n = simd_normalize(P(-d.y, d.x)) * (width / 2)
                left.append(path[i] + n)
                right.append(path[i] - n)
            }
            return left + right.reversed() + [left[0]]
        }

        /// A strip along a path that crosses itself, laid down a short length at a time so each loop lies over the last.
        static func strand(_ plate: inout Plate, _ path: [P], _ width: Double, ink: Ink = .black) {
            for from in stride(from: 0, to: path.count - 1, by: 6) {
                let piece = ribbon(Array(path[max(from - 1, 0)...min(from + 7, path.count - 1)]), width), half = piece.count / 2
                plate.fill(piece)
                plate.line(Array(piece[0..<half]), medium, ink)
                plate.line(Array(piece[half..<(piece.count - 1)]), medium, ink)
            }
        }

        /// An arrow's barbed head, its tip at `tip`, flying toward `a`.
        static func barb(_ tip: P, toward a: Double, size: Double) -> [P] {
            [tip, polar(tip, size, a + .pi - 0.42), polar(tip, 0.6 * size, a + .pi), polar(tip, size, a + .pi + 0.42), tip]
        }

        /// A Roman numeral centred on `c`, its head turned to `turn` from upright, its width squeezed.
        static func numeral(_ s: String, at c: P, height h: Double, turn: Double = 0, squeeze: Double = 1) -> [[P]] {
            guard let first = s.first, let last = s.last else { return [] }
            let advance = s.reduce(0.0) { $0 + ($1 == "I" ? 0.62 : 0.86) * h }
            let left = first == "I" ? 0.12 * h : 0, right = advance - (last == "I" ? 0.14 : 0.26) * h
            let mid = P((left + right) / 2, h / 2)
            return text(s, at: P(0, 0), height: h).map { stroke in
                turned(stroke.map { P(($0.x - mid.x) * squeeze, $0.y - mid.y) }, by: turn).map { $0 + c }
            }
        }

        /// A hand's outline from its arbor at `c`: a sword, or a spade for the hours, with a tail behind the arbor.
        static func hand(_ c: P, toward a: Double, length l: Double, width w: Double, spade: Bool = false,
                         tail: Double = 0) -> [P] {
            let upper: [(Double, Double)] = spade
                ? [(-tail, 0.5 * w), (0.56 * l, 0.5 * w), (0.6 * l, 1.25 * w), (0.68 * l, 1.7 * w), (0.78 * l, 1.45 * w), (0.9 * l, 0.65 * w), (l, 0)]
                : [(-tail, 0.4 * w), (0.08 * l, 0.6 * w), (0.8 * l, 0.42 * w), (l, 0)]
            let half = upper.map { P($0.0, $0.1) }
            let ring = half + half.dropLast().reversed().map { P($0.x, -$0.y) } + [half[0]]
            return turned(ring, by: a).map { $0 + c }
        }

        /// A bold dial about `c`: a heavy rim, a minute track of wedges, Roman chapters read from the centre, and its
        /// middle left bone for whatever the plate sets there.
        static func dial(_ plate: inout Plate, _ c: P, _ r: Double, numerals: Bool = true) {
            plate.fill(arc(c, r))
            for k in 0..<60 {
                let a = Double(k) * .pi / 30
                if k % 5 == 0 {
                    mass(&plate, band(polar(c, 0.88 * r, a), polar(c, r, a), 0.035 * r + 0.008))
                } else {
                    plate.line([polar(c, 0.94 * r, a), polar(c, r, a)], medium)
                }
            }
            if numerals {
                for k in 1...12 {
                    plate.lines(numeral(roman(k), at: polar(c, 0.74 * r, clock(Double(k))), height: 0.19 * r,
                                        turn: clock(Double(k)) + .pi / 2, squeeze: 0.72), max(heavy, 0.018 * r))
                }
            }
            plate.line(arc(c, 0.94 * r), medium)
            plate.line(arc(c, r), 0.02)
        }

        /// Bold hands at `hours` and `minutes`, solid ink, the hour hand under.
        static func hands(_ plate: inout Plate, _ c: P, _ r: Double, hours: Double, minutes: Double, ink: Ink = .black) {
            mass(&plate, hand(c, toward: clock(hours + minutes / 60), length: 0.56 * r, width: 0.1 * r, spade: true, tail: 0.12 * r), ink: ink)
            mass(&plate, hand(c, toward: clock(minutes / 5), length: 0.88 * r, width: 0.09 * r, tail: 0.18 * r), ink: ink)
            plate.fill(arc(c, 0.06 * r))
            plate.line(arc(c, 0.06 * r), medium)
        }

        static func mirrored(_ marks: [Mark], about x: Double) -> [Mark] {
            marks.map { Mark(points: $0.points.map { P(2 * x - $0.x, $0.y) }, width: $0.width, ink: $0.ink) }
        }
    }
}
