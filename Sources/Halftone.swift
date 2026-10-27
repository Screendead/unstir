// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Lens's halftone test panel. Flat tones printed as dot screens laid out in clean-picture coordinates, so the pitch is
/// a ruler a lens cannot fake: a magnified core shows swollen, wider-spaced dots. White ink lines on top keep every
/// core asymmetric, so no turn hides in the square screens. Pure geometry, so the tests read the same panel.
enum Halftone {
    /// Dot spacing in tank units, the same for every screen.
    static let pitch = 0.03

    /// An ink: its colour in linear light and its screen's angle.
    struct Ink {
        var colour: SIMD3<Double>
        var degrees: Double
    }

    static let cyan = Ink(colour: linear(0x00E5FF), degrees: 15)
    static let magenta = Ink(colour: linear(0xFF2BD6), degrees: 75)
    static let yellow = Ink(colour: linear(0xFFE600), degrees: 0)

    /// The magenta dial and the yellow gem.
    static let dial = (centre: SIMD2(-0.3, -0.12), radius: 0.42)
    static let gem: [SIMD2<Double>] = [SIMD2(0.34, -0.32), SIMD2(0.74, 0.12), SIMD2(0.36, 0.7), SIMD2(-0.02, 0.18)]

    static let inks = [cyan, magenta, yellow]

    /// Each ink's tone (its dots' share of area) at a point of the clean panel, in the order of `inks`.
    static func tones(_ p: SIMD2<Double>) -> SIMD3<Double> {
        let inDial = simd_distance(p, dial.centre) < dial.radius
        let inGem = inside(p, gem)
        // A cyan sky over the top, a lighter one below the horizon, knocked out under the shapes as print does: on black
        // the inks add, and cyan over magenta would print white.
        let sky = inDial || inGem ? 0 : p.y < 0.38 ? 0.32 : 0.14
        return SIMD3(sky, inDial ? 0.5 : 0, inGem && !inDial ? 0.42 : 0)
    }

    /// The white ink, as polylines.
    static let lines: [[SIMD2<Double>]] = {
        var l: [[SIMD2<Double>]] = []
        func arc(_ c: SIMD2<Double>, _ r: Double, _ a0: Double, _ a1: Double, _ n: Int = 48) -> [SIMD2<Double>] {
            (0...n).map { i in
                let a = (a0 + (a1 - a0) * Double(i) / Double(n)) * .pi / 180
                return c + r * SIMD2(cos(a), sin(a))
            }
        }
        // The dial: its rim, a tick every 30 degrees but none at three o'clock, and a pointer to about two.
        let c = dial.centre, r = dial.radius
        l.append(arc(c, r, 0, 360, 96))
        for k in 0..<12 where k != 0 {
            let a = Double(k) * .pi / 6, u = SIMD2(cos(a), sin(a))
            l.append([c + u * (r * (k % 3 == 0 ? 0.68 : 0.8)), c + u * (r * 0.93)])
        }
        l.append([c + SIMD2(-0.05, 0.04), c + SIMD2(0.2, -0.17), c + SIMD2(0.26, -0.27)])
        l.append(arc(c, 0.035, 0, 360, 24))
        // The gem: its outline, a girdle and facets that lean one way.
        l.append(gem + [gem[0]])
        l.append([gem[3], SIMD2(0.2, 0.06), SIMD2(0.5, 0.0), gem[1]])
        l.append([gem[0], SIMD2(0.2, 0.06), SIMD2(0.36, 0.7)])
        l.append([SIMD2(0.5, 0.0), SIMD2(0.36, 0.7)])
        // A horizon, kinked where it meets the gem, and a bolt down the left.
        l.append([SIMD2(-1, 0.38), SIMD2(-0.1, 0.38), SIMD2(0.08, 0.3)])
        l.append([SIMD2(0.62, 0.38), SIMD2(1, 0.38)])
        l.append([SIMD2(-0.82, 0.46), SIMD2(-0.5, 0.52), SIMD2(-0.6, 0.62), SIMD2(-0.22, 0.86)])
        // Speed lines off the top right, and a star of uneven rays bottom left.
        for k in 0..<5 {
            let y = -0.82 + 0.09 * Double(k), x = 0.12 + 0.06 * Double(k % 3)
            l.append([SIMD2(x, y), SIMD2(x + 0.42 - 0.05 * Double(k), y + 0.12)])
        }
        let star = SIMD2(-0.36, 0.62)
        for k in 0..<7 {
            let a = Double(k) * 2 * .pi / 7 + 0.3, len = [0.18, 0.1, 0.14, 0.07, 0.2, 0.11, 0.09][k]
            l.append([star + 0.03 * SIMD2(cos(a), sin(a)), star + len * SIMD2(cos(a), sin(a))])
        }
        // An arrow pointing up, top left, and a hook top right.
        l.append([SIMD2(-0.62, -0.44), SIMD2(-0.62, -0.76)])
        l.append([SIMD2(-0.7, -0.66), SIMD2(-0.62, -0.76), SIMD2(-0.54, -0.66)])
        l.append(arc(SIMD2(0.72, -0.4), 0.1, -90, 160, 24) + [SIMD2(0.56, -0.28)])
        return l
    }()

    static let lineWidth = 0.008

    private static let boxes: [(lo: SIMD2<Double>, hi: SIMD2<Double>)] = lines.map { line in
        let pad = SIMD2(repeating: lineWidth)
        return (line.reduce(line[0], simd_min) - pad, line.reduce(line[0], simd_max) + pad)
    }

    /// The panel's light at p (tank units, y down) in linear sRGB, edges faded over `aa` (a pixel, in tank units).
    static func light(_ p: SIMD2<Double>, aa: Double) -> SIMD3<Double> {
        var c = SIMD3<Double>(repeating: 0)
        for k in inks.indices { c += inks[k].colour * screen(p, inks[k].degrees, aa: aa) { tones($0)[k] } }
        c = simd_min(c, SIMD3(repeating: 1))
        var d = Double.infinity
        for (i, line) in lines.enumerated() {
            let b = boxes[i]
            guard p.x >= b.lo.x - aa, p.y >= b.lo.y - aa, p.x <= b.hi.x + aa, p.y <= b.hi.y + aa else { continue }
            for j in 1..<line.count { d = min(d, segmentDistance(p, line[j - 1], line[j])) }
        }
        let ink = min(max((lineWidth / 2 - d) / aa + 0.5, 0), 1)
        return c * (1 - ink) + SIMD3(repeating: ink)
    }

    /// Coverage at p of a screen at `degrees`: the nearest cell's dot, sized by the tone at its own centre, so dots are
    /// whole and a shape's edge is dotted, as in print.
    private static func screen(_ p: SIMD2<Double>, _ degrees: Double, aa: Double, tone: (SIMD2<Double>) -> Double) -> Double {
        let a = degrees * .pi / 180, cs = cos(a), sn = sin(a)
        let u = SIMD2(p.x * cs + p.y * sn, -p.x * sn + p.y * cs)
        let cell = (u / pitch).rounded(.toNearestOrAwayFromZero) * pitch
        let centre = SIMD2(cell.x * cs - cell.y * sn, cell.x * sn + cell.y * cs)
        let t = tone(centre)
        guard t > 0 else { return 0 }
        let radius = pitch * (t / .pi).squareRoot()
        return min(max((radius - simd_distance(u, cell)) / aa + 0.5, 0), 1)
    }

    private static func segmentDistance(_ p: SIMD2<Double>, _ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
        let ab = b - a, h = min(max(simd_dot(p - a, ab) / simd_length_squared(ab), 0), 1)
        return simd_distance(p, a + h * ab)
    }

    private static func inside(_ p: SIMD2<Double>, _ polygon: [SIMD2<Double>]) -> Bool {
        var odd = false
        for i in polygon.indices {
            let a = polygon[i], b = polygon[(i + 1) % polygon.count]
            if (a.y > p.y) != (b.y > p.y), p.x < a.x + (p.y - a.y) / (b.y - a.y) * (b.x - a.x) { odd.toggle() }
        }
        return odd
    }

    static func linear(_ hex: UInt32) -> SIMD3<Double> {
        func c(_ v: UInt32) -> Double {
            let s = Double(v & 0xFF) / 255
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        return SIMD3(c(hex >> 16), c(hex >> 8), c(hex))
    }

    static func gamma(_ c: Double) -> Double {
        let c = min(max(c, 0), 1)
        return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055
    }

    /// The clean panel as gamma-encoded RGBA8, `n` pixels a side over the tank's square, rows top first.
    static func pixels(_ n: Int) -> [UInt8] {
        var out = [UInt8](repeating: 255, count: 4 * n * n)
        let px = 2 / Double(n)
        out.withUnsafeMutableBufferPointer { buf in
            nonisolated(unsafe) let base = buf.baseAddress!
            DispatchQueue.concurrentPerform(iterations: n) { j in
                for i in 0..<n {
                    let c = light(SIMD2((Double(i) + 0.5) * px - 1, (Double(j) + 0.5) * px - 1), aa: px)
                    let k = 4 * (j * n + i)
                    base[k] = UInt8(gamma(c.x) * 255 + 0.5)
                    base[k + 1] = UInt8(gamma(c.y) * 255 + 0.5)
                    base[k + 2] = UInt8(gamma(c.z) * 255 + 0.5)
                }
            }
        }
        return out
    }
}
