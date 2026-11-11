// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Sketches of Escapement's plates for Jack to pick a direction from: polylines and filled outlines in tank units, y
/// down, in ink and one second ink on bone. Nothing draws them unless a Debug launch names a direction
/// (`UNSTIR_ESCART`); every other launch draws `Picture.engineTurning`.
enum EscapementArt {
    typealias P = SIMD2<Double>

    enum Direction: String, CaseIterable {
        /// One engraved plate a problem, drawn as its name.
        case plates = "a"
        /// Six patterns, varied by seed, scale and second ink.
        case family = "b"
        /// A chapter's own ground and ink, the problem's emblem cut into it and its number in Roman.
        case chapters = "c"
    }

    enum Ink: Equatable { case black, second, bone }

    /// A polyline stroked `width` wide, or with width 0 a filled outline.
    struct Mark {
        var points: [P]
        var width: Double
        var ink: Ink
    }

    struct Plate {
        var second: UInt32 = vermilion
        var marks: [Mark] = []

        mutating func line(_ points: [P], _ width: Double = fine, _ ink: Ink = .black) {
            marks.append(Mark(points: points, width: width, ink: ink))
        }
        mutating func lines(_ all: [[P]], _ width: Double = fine, _ ink: Ink = .black) {
            for points in all { line(points, width, ink) }
        }
        mutating func fill(_ points: [P], _ ink: Ink = .bone) { marks.append(Mark(points: points, width: 0, ink: ink)) }
    }

    static let vermilion: UInt32 = 0xD8402A, prussian: UInt32 = 0x23466B, viridian: UInt32 = 0x2E5E4E
    static let sepia: UInt32 = 0x7A4A22, oxblood: UInt32 = 0x8E2B1F
    static let heavy = 0.010, medium = 0.007, fine = 0.005

    static var direction: Direction? {
        #if DEBUG
        ProcessInfo.processInfo.environment["UNSTIR_ESCART"].flatMap(Direction.init(rawValue:))
        #else
        nil
        #endif
    }

    /// The problems direction A and C have drawn; any other draws the family's plate.
    static let drawn = [2, 4, 9, 25]

    static func plate(_ direction: Direction, problem n: Int) -> Plate {
        switch (direction, n) {
        default: familyPlate(n)
        }
    }

    // MARK: Geometry

    static func polar(_ c: P, _ r: Double, _ a: Double) -> P { c + r * P(cos(a), sin(a)) }

    static func arc(_ c: P, _ r: Double, from a: Double = 0, to b: Double = 2 * .pi) -> [P] {
        let m = max(6, Int(abs(b - a) * max(r, 0.02) * 60))
        return (0...m).map { polar(c, r, a + (b - a) * Double($0) / Double(m)) }
    }

    static func ellipse(_ c: P, _ rx: Double, _ ry: Double, from a: Double = 0, to b: Double = 2 * .pi, turned t: Double = 0) -> [P] {
        let m = max(8, Int(abs(b - a) * max(rx, ry) * 60))
        return (0...m).map { i in
            let u = a + (b - a) * Double(i) / Double(m), x = rx * cos(u), y = ry * sin(u)
            return c + P(x * cos(t) - y * sin(t), x * sin(t) + y * cos(t))
        }
    }

    static func curve(_ a: P, _ c: P, _ b: P, _ n: Int = 20) -> [P] {
        (0...n).map { i in
            let t = Double(i) / Double(n)
            return a * ((1 - t) * (1 - t)) + c * (2 * t * (1 - t)) + b * (t * t)
        }
    }

    static func turned(_ points: [P], by a: Double, about c: P = P(0, 0)) -> [P] {
        points.map { p in
            let d = p - c
            return c + P(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a))
        }
    }

    static func box(_ a: P, _ b: P) -> [P] { [a, P(b.x, a.y), b, P(a.x, b.y), a] }

    /// Parallel lines `gap` apart at `angle`, inside the rings by the even-odd rule, so a ring inside a ring is a hole.
    static func hatch(_ rings: [[P]], angle: Double, gap: Double, shift: Double = 0) -> [[P]] {
        let c = cos(angle), s = sin(angle)
        let rot = rings.map { $0.map { P($0.x * c + $0.y * s, -$0.x * s + $0.y * c) } }
        let vs = rot.flatMap { $0.map(\.y) }
        guard let lo = vs.min(), let hi = vs.max() else { return [] }
        var out: [[P]] = []
        var v = (floor(lo / gap) + 0.5 + shift) * gap
        while v < hi {
            var xs: [Double] = []
            for ring in rot {
                for i in ring.indices {
                    let a = ring[i], b = ring[(i + 1) % ring.count]
                    if (a.y <= v) != (b.y <= v) { xs.append(a.x + (v - a.y) / (b.y - a.y) * (b.x - a.x)) }
                }
            }
            xs.sort()
            for k in stride(from: 0, to: xs.count - 1, by: 2) where xs[k + 1] - xs[k] > 0.004 {
                out.append([P(xs[k] * c - v * s, xs[k] * s + v * c), P(xs[k + 1] * c - v * s, xs[k + 1] * s + v * c)])
            }
            v += gap
        }
        return out
    }

    static func dashed(_ points: [P], on: Double, off: Double) -> [[P]] {
        var out: [[P]] = [], run: [P] = [], left = on, drawing = true
        for i in 0..<(points.count - 1) {
            var a = points[i]
            let b = points[i + 1]
            if drawing && run.isEmpty { run = [a] }
            while simd_distance(a, b) > left {
                a += simd_normalize(b - a) * left
                if drawing { run.append(a); out.append(run); run = [] } else { run = [a] }
                drawing.toggle()
                left = drawing ? on : off
            }
            left -= simd_distance(a, b)
            if drawing { run.append(b) }
        }
        if drawing && run.count > 1 { out.append(run) }
        return out
    }

    /// A value in 0..<1 from a seed and an index, the same on every run.
    static func rnd(_ seed: Int, _ i: Int) -> Double {
        var z = UInt64(truncatingIfNeeded: seed) &* 0x9E37_79B9_7F4A_7C15 &+ UInt64(truncatingIfNeeded: i) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }

    static let glass = arc(P(0, 0), 1.06)

    // MARK: Clockwork

    /// A spur wheel's outline: `teeth` trapezoid teeth about pitch radius `r`.
    static func gear(_ c: P, _ r: Double, teeth: Int, phase: Double = 0) -> [P] {
        let m = 2 * r / Double(teeth), tau = 2 * Double.pi / Double(teeth)
        let root = r - 1.2 * m, tip = r + m
        var out: [P] = []
        for k in 0..<teeth {
            let a = phase + Double(k) * tau
            for (f, rad) in [(0.0, root), (0.22, root), (0.34, tip), (0.66, tip), (0.78, root)] {
                out.append(polar(c, rad, a + f * tau))
            }
        }
        return out + [out[0]]
    }

    /// An escape wheel's outline: raked teeth leaning clockwise.
    static func escapeWheel(_ c: P, _ r: Double, teeth: Int, phase: Double = 0) -> [P] {
        let tau = 2 * Double.pi / Double(teeth)
        var out: [P] = []
        for k in 0..<teeth {
            let a = phase + Double(k) * tau
            out += [polar(c, 0.8 * r, a), polar(c, r, a + 0.75 * tau), polar(c, 0.8 * r, a + 0.55 * tau)]
        }
        return out + [out[0]]
    }

    /// The windows between a wheel's spokes, from the hub's radius to the rim's.
    static func windows(_ c: P, hub: Double, rim: Double, spokes: Int, width: Double, phase: Double = 0) -> [[P]] {
        (0..<spokes).map { k in
            let a = phase + 2 * .pi * Double(k) / Double(spokes), b = a + 2 * .pi / Double(spokes)
            let dh = asin(min(0.9, width / hub)), dr = asin(min(0.9, 0.7 * width / rim))
            let inner = arc(c, hub, from: b - dh, to: a + dh), outer = arc(c, rim, from: a + dr, to: b - dr)
            return outer + inner + [outer[0]]
        }
    }

    /// A wheel in elevation: outline, rim, spoke windows and arbor. Returns the rings that cut it out of a ground.
    @discardableResult
    static func wheel(_ plate: inout Plate, _ c: P, _ r: Double, teeth: Int, spokes: Int, phase: Double = 0,
                      rimInk: Ink = .black, escape: Bool = false) -> [[P]] {
        let outline = escape ? escapeWheel(c, r, teeth: teeth, phase: phase) : gear(c, r, teeth: teeth, phase: phase)
        let m = 2 * r / Double(teeth)
        let rim = escape ? 0.74 * r : r - 1.2 * m - 0.09 * r, band = escape ? 0.8 * r : r - 1.2 * m - 0.015
        let hub = max(0.2 * r, 0.035), holes = windows(c, hub: hub * 1.5, rim: rim, spokes: spokes, width: 0.07 * r + 0.006, phase: phase + 0.3)
        plate.line(outline, medium)
        if !escape {
            plate.line(arc(c, band), fine)
            plate.lines(hatch([arc(c, band), arc(c, rim)], angle: phase + 0.9, gap: 0.016), fine, rimInk)
        }
        plate.line(arc(c, rim), fine)
        plate.lines(holes, fine)
        plate.line(arc(c, hub * 1.5), fine)
        plate.lines(hatch([arc(c, hub * 1.5), arc(c, hub * 0.55)], angle: phase - 0.6, gap: 0.012), fine, rimInk)
        plate.line(arc(c, hub * 0.55), medium)
        plate.line([polar(c, hub * 0.55, phase), polar(c, hub * 0.55, phase + .pi)], fine)
        return [outline] + holes
    }

    // MARK: Lettering

    private static let glyphs: [Character: [[(Double, Double)]]] = [
        "A": [[(0, 1), (0.3, 0), (0.6, 1)], [(0.11, 0.64), (0.49, 0.64)]],
        "B": [[(0, 1), (0, 0), (0.38, 0), (0.54, 0.12), (0.54, 0.36), (0.38, 0.48), (0, 0.48)],
              [(0.38, 0.48), (0.6, 0.62), (0.6, 0.86), (0.42, 1), (0, 1)]],
        "C": [[(0.6, 0.16), (0.44, 0), (0.16, 0), (0, 0.16), (0, 0.84), (0.16, 1), (0.44, 1), (0.6, 0.84)]],
        "D": [[(0, 0), (0, 1), (0.34, 1), (0.6, 0.74), (0.6, 0.26), (0.34, 0), (0, 0)]],
        "E": [[(0.56, 0), (0, 0), (0, 1), (0.56, 1)], [(0, 0.48), (0.4, 0.48)]],
        "I": [[(0.3, 0), (0.3, 1)], [(0.12, 0), (0.48, 0)], [(0.12, 1), (0.48, 1)]],
        "V": [[(0, 0), (0.3, 1), (0.6, 0)]],
        "X": [[(0, 0), (0.6, 1)], [(0.6, 0), (0, 1)]],
    ]

    /// Capitals in single strokes, `height` tall from `at`, their top left. Only letters and Roman numerals: a plate
    /// carries no words.
    static func text(_ s: String, at: P, height: Double) -> [[P]] {
        var out: [[P]] = [], x = at.x
        for ch in s {
            for stroke in glyphs[ch] ?? [] { out.append(stroke.map { P(x + $0.0 * height, at.y + $0.1 * height) }) }
            x += (ch == "I" ? 0.62 : 0.86) * height
        }
        return out
    }

    static func roman(_ n: Int) -> String {
        var n = n, out = ""
        for (v, s) in [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")] {
            while n >= v { out += s; n -= v }
        }
        return out
    }

    /// A manual's callout: a dot on the part, a leader and its letter.
    static func callout(_ plate: inout Plate, _ letter: String, from a: P, to b: P) {
        plate.line(arc(a, 0.009), medium)
        plate.line([a, b], fine)
        let h = 0.075, at = b + simd_normalize(b - a) * 0.065 - P(0.3 * h, 0.5 * h)
        plate.fill(arc(at + P(0.3 * h, 0.5 * h), 0.062))
        plate.lines(text(letter, at: at, height: h), medium)
    }
}
