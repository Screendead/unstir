// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: a Victorian slide of diatoms: a great centric valve in radial rows of areolae, a frustule's valves drawn
/// apart, a pillbox in girdle view, a sigmoid shuttle with its raphe and striae, a sieve of hexagonal cells and a
/// necklace of cells end to end, with lesser valves strewn between. Every figure is tilted or foreshortened and its
/// counts are prime to 12, so no core holds a whole radial figure.
enum Diatoms {
    typealias Line = Engraving.Line
    private typealias E = Engraving

    /// A specimen's own coordinates mapped onto the glass: x along `u`, y along `v`, foreshortened by `k` along y.
    private struct Frame {
        var c: SIMD2<Double>, u: SIMD2<Double>, v: SIMD2<Double>, k: Double

        init(_ c: SIMD2<Double>, _ size: Double, heading h: Double, squash: Double = 1, skew: Double = 0, k: Double = 0) {
            let x = SIMD2(cos(h), sin(h)), y = SIMD2(-sin(h), cos(h))
            self.c = c
            u = size * x
            v = size * squash * (y + skew * x)
            self.k = k
        }

        func callAsFunction(_ p: SIMD2<Double>) -> SIMD2<Double> { c + (p.x * u + p.y * v) / (1 + k * p.y) }
        func callAsFunction(_ ps: [SIMD2<Double>]) -> [SIMD2<Double>] { ps.map { self($0) } }
    }

    private static func polar(_ r: Double, _ a: Double) -> SIMD2<Double> { r * SIMD2(cos(a), sin(a)) }

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4449_4154)
        var out: [Line] = []
        centric(&out, &rng, Frame(SIMD2(-0.27, -0.37), 0.37, heading: 0.5, squash: 0.74, skew: 0.06, k: 0.05),
                rays: 23, striae: 89, pore: 0.03, rosette: 7)
        frustule(&out, &rng)
        pillbox(&out, &rng, Frame(SIMD2(0.2, 0.04), 0.12, heading: 0.42))
        shuttle(&out, &rng, Frame(SIMD2(-0.24, 0.47), 0.46, heading: -0.4), width: 0.24, sigmoid: 0.07, striae: 47)
        sieve(&out, &rng, Frame(SIMD2(0.62, 0.14), 0.26, heading: 1.15, squash: 0.68, skew: 0.1))
        necklace(&out, &rng)
        strew(&out, &rng)
        return out
    }()

    /// A centric valve: its rim and marginal striae, a rosette off the centre and radial rows of areolae, every other
    /// row starting halfway out, twisting a little as they go.
    private static func centric(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, rays: Int, striae: Int,
                                pore: Double, rosette: Int) {
        out.append(Line(points: f(E.circle(.zero, 1, 180)), width: E.medium))
        out.append(Line(points: f(E.circle(.zero, 0.93, 180)), width: E.fine))
        let phase = Double.random(in: 0..<(2 * .pi), using: &rng)
        for i in 0..<striae {
            let a = 1.3 * phase + 2 * .pi * Double(i) / Double(striae)
            out.append(Line(points: f([polar(0.935, a), polar(0.99, a)]), width: E.fine))
        }
        for k in 0..<(2 * rays) {
            let a0 = phase + .pi * Double(k) / Double(rays) + Double.random(in: -0.015..<0.015, using: &rng)
            var rho = k % 2 == 0 ? 0.2 : Double.random(in: 0.46..<0.56, using: &rng)
            while rho < 0.88 {
                let r = pore * (0.6 + 0.55 * rho)
                out.append(Line(points: f(E.circle(polar(rho, a0 + 0.06 * rho), r, 10)), width: E.fine))
                rho += 3.1 * r
            }
        }
        let off = SIMD2(Double.random(in: -0.04..<0.04, using: &rng), Double.random(in: -0.04..<0.04, using: &rng))
        for k in 0..<rosette {
            let a = phase + 2 * .pi * Double(k) / Double(rosette) + Double.random(in: -0.12..<0.12, using: &rng)
            out.append(Line(points: f(E.circle(off + polar(0.1, a), 0.9 * pore, 10)), width: E.fine))
        }
        out.append(Line(points: f(E.circle(off, 0.7 * pore, 10)), width: E.fine))
    }

    /// One valve seen from above and a little to the side: its face with radial striae round a hyaline centre, and the
    /// near half of its mantle hanging `depth` below, ribbed.
    private static func valve(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, depth: Double, striae: Int) {
        let drop = depth * simd_normalize(f.v)
        out.append(Line(points: f(E.circle(.zero, 1, 120)), width: E.medium))
        out.append(Line(points: f(E.circle(SIMD2(0.04, -0.03), 0.24, 40)), width: E.fine))
        let phase = Double.random(in: 0..<(2 * .pi), using: &rng)
        for i in 0..<(2 * striae) {
            let a = phase + .pi * Double(i) / Double(striae)
            out.append(Line(points: f([polar(i % 2 == 0 ? 0.3 : 0.6, a), polar(0.9, a)]), width: E.fine))
        }
        out.append(Line(points: E.arc(.zero, 1, from: 0, to: .pi, 60).map { f($0) + drop }, width: E.medium))
        out.append(Line(points: E.arc(.zero, 1, from: 0, to: .pi, 60).map { f($0) + 0.45 * drop }, width: E.fine))
        for a in [0.0, Double.pi] { out.append(Line(points: [f(polar(1, a)), f(polar(1, a)) + drop], width: E.medium)) }
        for i in 1..<17 {
            let a = Double.pi * Double(i) / 17
            out.append(Line(points: [f(polar(1, a)) + 0.45 * drop, f(polar(1, a)) + drop], width: E.fine))
        }
    }

    /// A frustule drawn apart: the epivalve lifted off, the girdle band between and the hypovalve below, each a little
    /// askew, with dotted leaders down their sides.
    private static func frustule(_ out: inout [Line], _ rng: inout SplitMix64) {
        let size = 0.165, squash = 0.42, heading = 0.28
        let base = SIMD2(0.53, -0.24), up = SIMD2(-0.36, -1.0)
        let parts = [Frame(base + 0.44 * up, size * 1.04, heading: heading + 0.07, squash: squash),
                     Frame(base + 0.22 * up, size * 1.01, heading: heading - 0.03, squash: squash),
                     Frame(base, size, heading: heading, squash: squash)]
        valve(&out, &rng, parts[0], depth: 0.05, striae: 19)
        // The girdle band: an open hoop, its near face between two rims and its far rim seen over the top.
        let band = parts[1], drop = 0.045 * simd_normalize(band.v)
        out.append(Line(points: band(E.arc(.zero, 1, from: .pi + 0.35, to: 2 * .pi, 50)), width: E.fine))
        out.append(Line(points: band(E.arc(.zero, 1, from: -0.12, to: .pi, 60)), width: E.medium))
        out.append(Line(points: E.arc(.zero, 1, from: -0.12, to: .pi, 60).map { band($0) + drop }, width: E.medium))
        for a in [-0.12, Double.pi] { out.append(Line(points: [band(polar(1, a)), band(polar(1, a)) + drop], width: E.fine)) }
        for i in 1..<13 {
            let a = Double.pi * Double(i) / 13
            out.append(Line(points: [band(polar(1, a)) + 0.3 * drop, band(polar(1, a)) + 0.7 * drop], width: E.fine))
        }
        valve(&out, &rng, parts[2], depth: 0.06, striae: 17)
        for a in [0.0, Double.pi] {
            let top = parts[0](polar(1, a)) + 0.06 * simd_normalize(parts[0].v), bottom = parts[2](polar(1, a))
            let n = Int(simd_distance(top, bottom) / 0.028)
            for i in 0..<n where i % 2 == 1 {
                let s0 = Double(i) / Double(n), s1 = Double(i + 1) / Double(n)
                out.append(Line(points: [top + (bottom - top) * s0, top + (bottom - top) * s1], width: E.fine))
            }
        }
    }

    /// A cylinder in girdle view, its axis along x: the near valve's face whole, the far one's rim, the girdle's
    /// overlapping bands and rows of pores over the mantles.
    private static func pillbox(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame) {
        let half = 1.35, e = 0.32
        func surface(_ x: Double, _ phi: Double) -> SIMD2<Double> { SIMD2(x - e * sin(phi), -cos(phi)) }
        out.append(Line(points: f(E.circle(.zero, 1, 90).map { SIMD2(half + e * $0.y, $0.x) }), width: E.medium))
        out.append(Line(points: f((0...50).map { surface(-half, .pi * Double($0) / 50) }), width: E.medium))
        for y in [-1.0, 1.0] { out.append(Line(points: f([SIMD2(-half, y), SIMD2(half, y)]), width: E.medium)) }
        for x in [-0.22, 0.08, 0.2] { out.append(Line(points: f((0...40).map { surface(x, .pi * Double($0) / 40) }), width: E.fine)) }
        for x in [-half + 0.3, half - 0.3] {
            out.append(Line(points: f((0...40).map { surface(x, .pi * Double($0) / 40) }), width: E.fine))
        }
        // The near face: 13 radial striae about a hyaline centre.
        let phase = Double.random(in: 0..<(2 * .pi), using: &rng)
        for i in 0..<13 {
            let a = phase + 2 * .pi * Double(i) / 13
            out.append(Line(points: f([0.3, 0.88].map { SIMD2(half + e * $0 * sin(a), $0 * cos(a)) }), width: E.fine))
        }
        out.append(Line(points: f(E.circle(.zero, 0.25, 30).map { SIMD2(half + e * $0.y, $0.x) }), width: E.fine))
        for (from, to) in [(-half + 0.42, -0.34), (0.32, half - 0.42)] {
            var x = from
            var row = 0
            while x < to {
                for j in 0..<6 {
                    let phi = 0.32 + (Double(j) + (row % 2 == 0 ? 0.25 : 0.75)) * (.pi - 0.64) / 6
                    let p = surface(x, phi), r = 0.065
                    out.append(Line(points: f((0...8).map { i in
                        let t = 2 * .pi * Double(i) / 8
                        return p + SIMD2(r * cos(t), r * sin(phi) * sin(t))
                    }), width: E.fine))
                }
                x += 0.19
                row += 1
            }
        }
    }

    /// A pennate valve, boat-shaped and bent a little into an S: its outline, the raphe in two branches hooked at the
    /// ends, the central and terminal nodules, and transverse striae radiating from the middle.
    private static func shuttle(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, width w: Double, sigmoid: Double,
                                striae: Int) {
        func mid(_ s: Double) -> Double { sigmoid * sin(.pi * s) }
        func half(_ s: Double) -> Double { w * pow(max(0, 1 - s * s), 0.7) * (1 + 0.05 * s) }
        let n = 120
        let edge = (0...n).map { i -> SIMD2<Double> in
            let s = -1 + 2 * Double(i) / Double(n)
            return SIMD2(s, mid(s) + half(s))
        } + (0..<n).reversed().map { i -> SIMD2<Double> in
            let s = -1 + 2 * Double(i) / Double(n)
            return SIMD2(s, mid(s) - half(s))
        }
        out.append(Line(points: f(edge), width: E.heavy))
        for side in [-1.0, 1.0] {
            out.append(Line(points: f((0...n).map { i in
                let s = -0.95 + 1.9 * Double(i) / Double(n)
                return SIMD2(s, mid(s) + side * 0.86 * half(s))
            }), width: E.fine))
        }
        for sign in [-1.0, 1.0] {
            var raphe = (0...40).map { i -> SIMD2<Double> in
                let s = sign * (0.07 + 0.83 * Double(i) / 40)
                return SIMD2(s, mid(s) + 0.05 * w * sin(2.4 * s))
            }
            let end = raphe.last!
            raphe += E.curve(end, end + SIMD2(sign * 0.04, 0), end + SIMD2(sign * 0.035, sign * 0.18 * w), 6).dropFirst()
            out.append(Line(points: f(raphe), width: E.medium))
            out.append(Line(points: f(E.circle(SIMD2(sign * 0.935, mid(sign * 0.935)), 0.012, 10)), width: E.fine))
        }
        out.append(Line(points: f(E.circle(.zero, 1, 30).map { SIMD2(0.04 * $0.x, mid(0) + 0.3 * w * $0.y) }), width: E.fine))
        for side in [-1.0, 1.0] {
            for j in 0..<striae {
                let s = -0.88 + 1.76 * (Double(j) + 0.5) / Double(striae) + Double.random(in: -0.004..<0.004, using: &rng)
                guard abs(s) > 0.09 else { continue }
                let lean = 0.05 * (s > 0 ? 1 : -1) * (1 - abs(s))
                let inner = SIMD2(s - lean, mid(s) + side * 0.2 * w)
                let outer = SIMD2(s + lean, mid(s + lean) + side * 0.8 * half(s))
                out.append(Line(points: f([inner, outer]), width: E.fine))
            }
        }
    }

    /// An oval valve netted with hexagonal cells, the net turned against the oval, with a pseudonodulus and five
    /// processes round the rim.
    private static func sieve(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame) {
        out.append(Line(points: f(E.circle(.zero, 1, 160)), width: E.medium))
        out.append(Line(points: f(E.circle(.zero, 0.94, 160)), width: E.fine))
        let spacing = 0.145, turn = 0.23, cell = 0.066, nodule = SIMD2(-0.32, 0.18)
        let a = polar(spacing, turn), b = polar(spacing, turn + .pi / 3)
        for i in -10...10 {
            for j in -10...10 {
                let p = Double(i) * a + Double(j) * b + SIMD2(0.031, -0.02)
                guard simd_length(p) < 0.85, simd_distance(p, nodule) > 0.1 else { continue }
                let shrink = 1 - 0.3 * simd_length_squared(p)
                out.append(Line(points: f((0...6).map { polar(cell * shrink, turn + .pi / 6 + Double($0) * .pi / 3) + p }),
                                width: E.fine))
            }
        }
        out.append(Line(points: f(E.circle(nodule, 0.05, 14)), width: E.fine))
        for k in 0..<5 {
            let t = 2 * .pi * (Double(k) + Double.random(in: -0.2..<0.2, using: &rng)) / 5
            out.append(Line(points: f([polar(0.94, t), polar(1.08, t + 0.02)]), width: E.fine))
        }
    }

    private static let chain = E.curve(SIMD2(-0.02, 0.9), SIMD2(0.7, 0.86), SIMD2(0.88, 0.26), 400)

    /// A chain of cells joined valve to valve along a curve near the rim, each a short barrel with its girdle seam and
    /// pores, one of them just divided.
    private static func necklace(_ out: inout [Line], _ rng: inout SplitMix64) {
        let path = chain
        var lengths = [0.0]
        for i in 1..<path.count { lengths.append(lengths[i - 1] + simd_distance(path[i], path[i - 1])) }
        func at(_ d: Double) -> (SIMD2<Double>, SIMD2<Double>) {
            let i = max(1, min(path.count - 2, lengths.firstIndex { $0 >= d } ?? path.count - 2))
            return (path[i], simd_normalize(path[i + 1] - path[i - 1]))
        }
        var d = 0.02, k = 0
        while d < lengths.last! - 0.06 {
            let len = (k == 5 ? 0.5 : 1) * Double.random(in: 0.068..<0.082, using: &rng), r = 0.04
            let (p, t0) = at(d + len / 2)
            let t = simd_normalize(t0 + Double.random(in: -0.06..<0.06, using: &rng) * SIMD2(-t0.y, t0.x))
            let h = len / 2 - 0.009
            let drum = Frame(p, 1, heading: atan2(t.y, t.x))
            out.append(Line(points: drum((0...64).map { i in
                let a = 2 * .pi * Double(i) / 64, c = cos(a), s = sin(a)
                return SIMD2(h * copysign(pow(abs(c), 0.4), c), r * copysign(pow(abs(s), 0.4), s))
            }), width: E.medium))
            out.append(Line(points: drum((0...12).map { i in
                let y = -0.9 * r + 1.8 * r * Double(i) / 12
                return SIMD2(0.012 * (1 - pow(y / r, 2)), y)
            }), width: E.fine))
            if k > 0 {
                for y in [-0.45 * r, 0.45 * r] { out.append(Line(points: drum([SIMD2(-h - 0.018, y), SIMD2(-h, y)]), width: E.fine)) }
            }
            if len > 0.05 {
                for x in [-0.6 * h, 0.55 * h] {
                    for y in [-0.55 * r, 0.03 * r, 0.6 * r] {
                        out.append(Line(points: drum(E.circle(SIMD2(x, y), 0.0065, 8)), width: E.fine))
                    }
                }
            }
            d += len
            k += 1
        }
    }

    /// Lesser valves strewn over what the specimens leave: small shuttles, small centrics, Actinoptychus in seven
    /// undulating sectors and crescents.
    private static func strew(_ out: inout [Line], _ rng: inout SplitMix64) {
        let taken: [(SIMD2<Double>, Double)] = [
            (SIMD2(-0.27, -0.37), 0.41), (SIMD2(0.37, -0.68), 0.2), (SIMD2(0.45, -0.46), 0.2), (SIMD2(0.53, -0.24), 0.2),
            (SIMD2(0.2, 0.04), 0.2), (SIMD2(0.62, 0.14), 0.26),
            (SIMD2(-0.24, 0.47), 0.2), (SIMD2(-0.03, 0.38), 0.12), (SIMD2(-0.45, 0.56), 0.12), (SIMD2(0.18, 0.29), 0.1),
            (SIMD2(-0.64, 0.64), 0.08),
        ] + stride(from: 0, to: chain.count, by: 15).map { (chain[$0], 0.06) }
        var placed: [(SIMD2<Double>, Double)] = []
        var kind = 0
        for _ in 0..<20000 where placed.count < 56 {
            let p = SIMD2(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<1, using: &rng))
            let size = Double.random(in: 0.035..<0.07, using: &rng), reach = kind % 4 == 3 ? 1.2 * size : size
            guard simd_length(p) < 0.97 - reach,
                  !(taken + placed).contains(where: { simd_distance($0.0, p) < $0.1 + reach + 0.01 }) else { continue }
            placed.append((p, reach))
            let heading = Double.random(in: 0..<(2 * .pi), using: &rng)
            switch kind % 4 {
            case 0:
                shuttle(&out, &rng, Frame(p, size, heading: heading), width: 0.3, sigmoid: 0, striae: 11)
            case 1:
                rayed(&out, &rng, Frame(p, size, heading: heading, squash: Double.random(in: 0.75..<0.95, using: &rng)),
                      rays: [11, 13][rng.below(2)])
            case 2:
                actinoptychus(&out, Frame(p, size, heading: heading, squash: 0.85))
            default:
                crescent(&out, &rng, Frame(p, 1.2 * size, heading: heading), striae: 13)
            }
            kind += 1
        }
    }

    /// A small centric valve: its rim, a hyaline centre and radial striae, every other one short.
    private static func rayed(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, rays: Int) {
        out.append(Line(points: f(E.circle(.zero, 1, 60)), width: E.medium))
        out.append(Line(points: f(E.circle(.zero, 0.26, 20)), width: E.fine))
        let phase = Double.random(in: 0..<(2 * .pi), using: &rng)
        for i in 0..<(2 * rays) {
            let a = phase + .pi * Double(i) / Double(rays)
            out.append(Line(points: f([polar(i % 2 == 0 ? 0.32 : 0.62, a), polar(0.9, a)]), width: E.fine))
        }
    }

    /// A centric valve in seven sectors, every other one shaded where it rises.
    private static func actinoptychus(_ out: inout [Line], _ f: Frame) {
        out.append(Line(points: f(E.circle(.zero, 1, 80)), width: E.medium))
        out.append(Line(points: f(E.circle(.zero, 0.22, 30)), width: E.fine))
        let sectors = 7
        for k in 0..<sectors {
            let a0 = 2 * .pi * Double(k) / Double(sectors), a1 = 2 * .pi * Double(k + 1) / Double(sectors)
            out.append(Line(points: f([polar(0.22, a0), polar(1, a0)]), width: E.fine))
            guard k % 2 == 0 else { continue }
            for j in 1...3 {
                let a = a0 + (a1 - a0) * Double(j) / 4
                out.append(Line(points: f([polar(0.3, a), polar(0.92, a)]), width: E.fine))
            }
        }
    }

    /// A crescent valve: its back arched, its belly almost straight, the raphe along the belly and striae fanning
    /// across the back.
    private static func crescent(_ out: inout [Line], _ rng: inout SplitMix64, _ f: Frame, striae: Int) {
        func back(_ s: Double) -> Double { -0.5 * pow(max(0, 1 - s * s), 0.65) }
        func belly(_ s: Double) -> Double { 0.1 * pow(max(0, 1 - s * s), 0.8) }
        let n = 40
        let edge = (0...n).map { i -> SIMD2<Double> in
            let s = -1 + 2 * Double(i) / Double(n)
            return SIMD2(s, back(s))
        } + (0..<n).reversed().map { i -> SIMD2<Double> in
            let s = -1 + 2 * Double(i) / Double(n)
            return SIMD2(s, belly(s))
        }
        out.append(Line(points: f(edge), width: E.medium))
        out.append(Line(points: f((0...n).map { i in
            let s = -0.88 + 1.76 * Double(i) / Double(n)
            return SIMD2(s, 0.02 * (1 - s * s))
        }), width: E.fine))
        let jitter = Double.random(in: -0.02..<0.02, using: &rng)
        for j in 0..<striae {
            let s = -0.84 + 1.68 * (Double(j) + 0.5) / Double(striae) + jitter
            guard abs(s) > 0.07 else { continue }
            out.append(Line(points: f([SIMD2(s, -0.06), SIMD2(1.12 * s, 0.85 * back(1.12 * s))]), width: E.fine))
        }
    }
}
