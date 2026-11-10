// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Lens's panels, a level each, drawn the test panel's way (`Halftone.Panel`: tones in three dot screens under white
/// strokes). Each draws its level's name, a thing to look through, with what is seen through it in the core of one of
/// the level's lenses, in hairline white finer than the screen, since a tone region under one pitch prints no dot, and
/// off the core's centre, which the lens's knob covers. Every rod's core holds linework that no turn of 30 degrees
/// leaves as it was, so each step shows (`testEveryLensPanelShowsEachStepOnItsLevel`).
enum LensArt {
    typealias P = SIMD2<Double>
    typealias Tone = SIMD3<Double>

    /// The drawn panels by their level's number. A level without one draws the test panel (`Halftone.panel`).
    static let levels: [Int: Halftone.Panel] = [1: keyhole, 2: peephole, 3: magnifier, 4: monocle, 5: goggles, 6: spyglass,
                                               7: binoculars, 8: spectacles, 9: sunglasses]

    static let bold = 0.008, mid = 0.005, hair = 0.0025

    // MARK: Drawing

    static func stroke(_ points: [P], _ width: Double = mid) -> Halftone.Stroke { Halftone.Stroke(points: points, width: width) }

    static func closed(_ points: [P]) -> [P] { points + [points[0]] }

    /// An arc from a0 to a1 degrees, 0 at three o'clock and clockwise on screen, as y runs down.
    static func arc(_ c: P, _ r: Double, _ a0: Double, _ a1: Double, _ n: Int = 32) -> [P] {
        (0...n).map { i in
            let a = (a0 + (a1 - a0) * Double(i) / Double(n)) * .pi / 180
            return c + r * P(cos(a), sin(a))
        }
    }

    static func circle(_ c: P, _ r: Double, _ n: Int = 48) -> [P] { arc(c, r, 0, 360, n) }

    static func ellipse(_ c: P, _ rx: Double, _ ry: Double, degrees: Double = 0, _ n: Int = 48) -> [P] {
        let t = degrees * .pi / 180
        return (0...n).map { i in
            let a = 2 * .pi * Double(i) / Double(n), e = P(rx * cos(a), ry * sin(a))
            return c + P(e.x * cos(t) - e.y * sin(t), e.x * sin(t) + e.y * cos(t))
        }
    }

    /// A quadratic Bézier from a to b pulled towards c.
    static func curve(_ a: P, _ c: P, _ b: P, _ n: Int = 24) -> [P] {
        (0...n).map { i in
            let t = Double(i) / Double(n)
            return (1 - t) * (1 - t) * a + 2 * (1 - t) * t * c + t * t * b
        }
    }

    /// A star of `points` points, its first ray at `degrees`.
    static func star(_ c: P, _ r: Double, points: Int = 5, inner: Double = 0.4, degrees: Double = -90) -> [P] {
        closed((0..<2 * points).map { i in
            let a = (degrees + 180 * Double(i) / Double(points)) * .pi / 180
            return c + (i % 2 == 0 ? r : r * inner) * P(cos(a), sin(a))
        })
    }

    /// A glint: four long rays and four short.
    static func glint(_ c: P, _ r: Double, _ width: Double = mid) -> [Halftone.Stroke] {
        (0..<8).map { k in
            let a = Double(k) * .pi / 4, l = k % 2 == 0 ? r : r * 0.45
            return stroke([c + 0.12 * r * P(cos(a), sin(a)), c + l * P(cos(a), sin(a))], width)
        }
    }

    static func inside(_ p: P, _ polygon: [P]) -> Bool { Halftone.inside(p, polygon) }

    static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> [P] {
        [P(x0, y0), P(x1, y0), P(x1, y1), P(x0, y1)]
    }

    /// A line's runs of points that `keep` holds, to cut it where something lies over it.
    static func runs(_ line: [P], _ width: Double = hair, keep: (P) -> Bool) -> [Halftone.Stroke] {
        line.split { !keep($0) }.filter { $0.count > 1 }.map { stroke(Array($0), width) }
    }

    /// A bar from a to b, `width` across, as a polygon.
    static func bar(_ a: P, _ b: P, _ width: Double) -> [P] {
        let u = simd_normalize(b - a), n = P(-u.y, u.x) * (width / 2)
        return [a + n, b + n, b - n, a - n]
    }

    /// A point `r` from c at `degrees`, 0 at three o'clock and clockwise on screen.
    static func polar(_ c: P, _ r: Double, _ degrees: Double) -> P {
        c + r * P(cos(degrees * .pi / 180), sin(degrees * .pi / 180))
    }

    static func distance(_ p: P, _ line: [P]) -> Double {
        var d = Double.infinity
        for j in 1..<line.count {
            let a = line[j - 1], ab = line[j] - a, h = min(max(simd_dot(p - a, ab) / simd_length_squared(ab), 0), 1)
            d = min(d, simd_distance(p, a + h * ab))
        }
        return d
    }

    /// Tones as (cyan, magenta, yellow).
    static func c(_ t: Double) -> Tone { SIMD3(t, 0, 0) }
    static func m(_ t: Double) -> Tone { SIMD3(0, t, 0) }
    static func y(_ t: Double) -> Tone { SIMD3(0, 0, t) }

    /// A flat tone inside a polygon, or inside the ellipse of `radii` about `centre` when they are set, which costs a
    /// pixel less to test.
    struct Fill: Sendable {
        var tone: Tone
        var polygon: [P] = []
        var centre = P(0, 0)
        var radii: P?
        var lo: P, hi: P

        func holds(_ p: P) -> Bool {
            guard p.x >= lo.x, p.y >= lo.y, p.x <= hi.x, p.y <= hi.y else { return false }
            if let radii { return simd_length_squared((p - centre) / radii) < 1 }
            return Halftone.inside(p, polygon)
        }
    }

    static func fill(_ polygon: [P], _ tone: Tone) -> Fill {
        Fill(tone: tone, polygon: polygon, lo: polygon.reduce(polygon[0], simd_min), hi: polygon.reduce(polygon[0], simd_max))
    }

    static func disc(_ c: P, _ r: Double, _ tone: Tone) -> Fill { oval(c, r, r, tone) }

    static func oval(_ c: P, _ rx: Double, _ ry: Double, _ tone: Tone) -> Fill {
        Fill(tone: tone, centre: c, radii: P(rx, ry), lo: c - P(rx, ry), hi: c + P(rx, ry))
    }

    /// A panel of fills, the first that holds a point giving its tone, over `ground`.
    static func panel(_ name: String, fills: [Fill], strokes: [Halftone.Stroke],
                      ground: @escaping @Sendable (P) -> Tone) -> Halftone.Panel {
        Halftone.Panel(name: name, tones: { p in
            for f in fills where f.holds(p) { return f.tone }
            return ground(p)
        }, strokes: strokes)
    }
}

