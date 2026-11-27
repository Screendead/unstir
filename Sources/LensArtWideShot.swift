// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 26 to 31, the chapter Wide shot.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let wideShot: [Int: Halftone.Panel] = [26: dewdrop]

    /// A long line cut into strokes of `n` segments each: a stroke costs every pixel in its box once a segment, so a
    /// long outline in one piece is the bake's dearest thing.
    private static func pieces(_ line: [P], _ width: Double, _ n: Int = 6) -> [Halftone.Stroke] {
        stride(from: 0, to: line.count - 1, by: n).map { stroke(Array(line[$0...min($0 + n, line.count - 1)]), width) }
    }
}

// MARK: - 26: Dewdrop

/// Level 26's name: two dewdrops on a broad leaf at dawn, one over each of the top and lower left cores (tri's two
/// lenses on this level), each lit cyan along its lower rim and casting its shadow on the leaf, and a ladybird by the
/// leaf's tip on the twisting rod. Each drop holds the garden upside down: through the upper a daisy hanging from its
/// stem, through the lower a bee flying belly up.
extension LensArt {
    static let dewdrop: Halftone.Panel = {
        let drops = [P(0, -0.42), P(-0.3637, 0.21)], body = 0.3, glass = 0.25
        // The leaf's midrib, from its stem off the glass at the left to its tip on the right rod.
        let rib = P(-0.182, -0.105), along = P(cos(22 * .pi / 180), sin(22 * .pi / 180)), across = P(-along.y, along.x)
        let stem = -1.3, tip = 1.05
        @Sendable func half(_ u: Double) -> Double {
            let s = (u - stem) / (tip - stem)
            return s <= 0 || s >= 1 ? 0 : 2.3 * s.squareRoot() * (1 - s)
        }
        let bug = P(0.5, 0.0)
        var fills: [Fill] = []
        for d in drops {
            fills.append(disc(d, glass, Tone(0.1, 0.5, 0)))
            fills.append(fill(sector(d, glass - 0.001, body, 15, 165), Tone(0.8, 0, 0.15)))
            fills.append(ring(d, glass - 0.001, body, Tone(0.06, 0.16, 0)))
        }
        // The ladybird: head and spots first, black, then her red back.
        let spots = [P(-0.06, -0.042), P(0.02, -0.048), P(-0.06, 0.042), P(0.02, 0.048)]
        fills += [disc(bug + P(0.11, 0), 0.045, .zero)] + spots.map { disc(bug + $0, 0.022, .zero) } + [oval(bug, 0.12, 0.085, Tone(0, 0.62, 0.42))]
        // Each drop's shadow, thrown down and right on the leaf.
        fills += drops.map { disc($0 + P(0.05, 0.06), body + 0.01, Tone(0.04, 0, 0.1)) }

        var s: [Halftone.Stroke] = []
        // The leaf: its edges, the midrib and the veins, each vein cut where a drop sits on it.
        let us = stride(from: stem + 0.15, through: tip, by: 0.05).map { $0 }
        for side in [-1.0, 1.0] {
            s += pieces(us.map { rib + along * $0 + across * (side * half($0)) } + [rib + along * tip], bold)
            s += pieces(stride(from: -1.2, through: tip - 0.1, by: 0.1).map { rib + along * $0 + across * (side * 0.03) }, mid, 4)
        }
        let clear = { (p: P) in drops.allSatisfy { simd_distance(p, $0) > body + 0.015 } && simd_distance(p, bug) > 0.13 }
        for k in 0..<9 {
            let u0 = -0.95 + 0.22 * Double(k)
            for side in [-1.0, 1.0] {
                let reach = half(u0 + 0.25) * 0.9
                let vein = curve(rib + along * u0 + across * (side * 0.03), rib + along * (u0 + 0.08) + across * (side * reach * 0.5),
                                 rib + along * (u0 + 0.25) + across * (side * reach), 12)
                s += runs(vein, mid, keep: clear)
            }
        }
        // A strand of web across the dawn above the leaf, and beads of dew strung on it.
        let strand = curve(P(0.2, -0.98), P(0.55, -0.55), P(0.98, -0.3), 20)
        s += pieces(strand, hair)
        for t in [3, 8, 13] { s.append(stroke(circle(strand[t], 0.014, 8), mid)) }
        // The drops: rim, glass and the light on them.
        for d in drops {
            s += pieces(circle(d, body, 56), bold, 8)
            s.append(stroke(arc(d, glass, 170, 370, 28), hair))
            s.append(stroke(arc(d, body - 0.055, 200, 252, 10), bold))
            s.append(stroke(arc(d, body - 0.066, 206, 246, 8), bold))
            s.append(stroke(circle(polar(d, body - 0.1, 258), 0.007, 8), 0.014))
        }
        // Smaller beads of dew on the leaf.
        for (at, r) in [(P(-0.62, -0.2), 0.045), (P(0.3, -0.45), 0.035), (P(-0.1, 0.62), 0.04), (P(0.2, 0.62), 0.03), (P(-0.72, 0.02), 0.03)] {
            s.append(stroke(circle(at, r, 14), mid))
            s.append(stroke(arc(at, r * 0.6, 200, 250, 4), hair))
        }
        // The ladybird: her back, the parting of her wing cases, her spots and her legs.
        s.append(stroke(ellipse(bug, 0.12, 0.085, 32), bold))
        s.append(stroke([bug + P(0.07, 0), bug + P(-0.12, 0)], mid))
        for at in spots { s.append(stroke(circle(bug + at, 0.022, 10), hair)) }
        for y in [-0.022, 0.022] { s.append(stroke(circle(bug + P(0.13, y), 0.006, 6), 0.008)) }
        for x in [-0.04, 0.0, 0.04] {
            s.append(stroke([bug + P(x, -0.08), bug + P(x - 0.02, -0.115)], mid))
            s.append(stroke([bug + P(x, 0.08), bug + P(x - 0.02, 0.115)], mid))
        }
        s.append(stroke([bug + P(0.15, -0.025), bug + P(0.19, -0.055)], hair))
        s.append(stroke([bug + P(0.15, 0.025), bug + P(0.19, 0.055)], hair))
        // Through the upper drop: a daisy upside down, its head below and its stem rising, a leaf on the stem.
        let daisy = drops[0] + P(0.016, 0.022)
        for k in 0..<10 {
            let a = 36 * Double(k) + 8
            s.append(stroke(ellipse(polar(daisy, 0.021, a), 0.01, 0.0042, degrees: a, 10), 0.0026))
        }
        s.append(stroke(circle(daisy, 0.007, 10), 0.004))
        s.append(stroke(curve(daisy + P(0, -0.032), daisy + P(-0.012, -0.06), daisy + P(-0.006, -0.09), 8), 0.003))
        s.append(stroke(ellipse(daisy + P(-0.024, -0.064), 0.014, 0.006, degrees: 30, 12), 0.0024))
        // Through the lower drop: a bee belly up, wings below, its stripes, its sting and feelers.
        let bee = drops[1] + P(0.018, -0.02)
        s.append(stroke(ellipse(bee, 0.028, 0.016, 24), 0.004))
        for x in [-0.008, 0.006] { s.append(stroke([bee + P(x, -0.015), bee + P(x, 0.015)], 0.0026)) }
        s.append(stroke(circle(bee + P(0.036, 0), 0.008, 10), 0.0034))
        s.append(stroke([bee + P(-0.028, 0), bee + P(-0.042, 0.002)], 0.0026))
        for t in [-30.0, 20] { s.append(stroke(ellipse(polar(bee + P(-0.004, 0.012), 0.016, 90 + t), 0.012, 0.007, degrees: 90 + t, 14), 0.0022)) }
        s.append(stroke([bee + P(0.042, 0.004), bee + P(0.056, 0.016)], 0.0018))
        s.append(stroke([bee + P(0.04, 0.007), bee + P(0.05, 0.022)], 0.0018))
        return panel("dewdrop", fills: fills, strokes: s) { p in
            let q = p - rib, u = simd_dot(q, along), v = simd_dot(q, across), w = half(u)
            guard abs(v) < w else { return Tone(0.12, 0.36, 0) }
            if abs(v) < 0.03 { return Tone(0.1, 0, 0.8) }
            return v < 0 ? Tone(0.55, 0, 0.45) : Tone(0.36, 0, 0.7)
        }
    }()
}
