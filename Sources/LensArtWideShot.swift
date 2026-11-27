// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 26 to 31, the chapter Wide shot.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let wideShot: [Int: Halftone.Panel] = [26: dewdrop, 27: fishbowl]

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

// MARK: - 27: Fishbowl

/// Level 27's name: a goldfish bowl filled to its lip, two goldfish turning in it, weed and a castle in the gravel, an
/// air bubble at the top core and a coin in the gravel at the bottom (eye's two lenses on this level). Through the
/// bubble the cat that is looking down into the bowl; on the coin, seen through the water, a ship under sail.
extension LensArt {
    static let fishbowl: Halftone.Panel = {
        let bubble = P(0, -0.56), coin = P(0, 0.56), bowl = P(0, 0.05), wall = 0.86, surface = -0.72
        let fish = [(at: P(0.48, -0.14), size: 0.21, faces: -1.0), (at: P(-0.5, 0.2), size: 0.17, faces: 1.0)]
        let tower = rect(0.34, 0.24, 0.52, 0.62), crenels = [0.34, 0.4, 0.46].map { rect($0, 0.2, $0 + 0.04, 0.24) }
        let weed = [curve(P(-0.62, 0.66), P(-0.86, 0.3), P(-0.66, -0.12), 10) + curve(P(-0.6, -0.12), P(-0.72, 0.3), P(-0.52, 0.66), 10),
                    curve(P(-0.42, 0.66), P(-0.3, 0.44), P(-0.34, 0.3), 8) + curve(P(-0.3, 0.3), P(-0.24, 0.46), P(-0.34, 0.66), 8)]
        // A goldfish's back fin, swept back towards its tail.
        func dorsal(_ f: (at: P, size: Double, faces: Double)) -> [P] {
            curve(f.at + P(f.faces * f.size * 0.35, -f.size * 0.52), f.at + P(-f.faces * f.size * 0.05, -f.size * 1.0), f.at + P(-f.faces * f.size * 0.55, -f.size * 0.95), 8)
                + [f.at + P(-f.faces * f.size * 0.45, -f.size * 0.45)]
        }
        var fills: [Fill] = []
        for f in fish {
            fills.append(disc(f.at + P(f.faces * f.size * 0.6, -f.size * 0.12), f.size * 0.12, .zero))
            fills.append(oval(f.at, f.size, f.size * 0.6, Tone(0, 0.38, 0.62)))
            let root = f.at - P(f.faces * f.size * 0.85, 0)
            fills.append(fill([root, root - P(f.faces * f.size * 0.75, f.size * 0.6), root - P(f.faces * f.size * 0.55, 0),
                               root - P(f.faces * f.size * 0.75, -f.size * 0.6)], Tone(0, 0.7, 0.3)))
            fills.append(fill(dorsal(f), Tone(0, 0.7, 0.3)))
        }
        let clinging = [(P(0.2, 0.19), 0.055), (P(-0.24, 0.13), 0.045), (P(0.03, 0.285), 0.035), (P(0.27, -0.05), 0.03)]
        fills += clinging.map { disc(bubble + $0.0, $0.1, Tone(0.4, 0.4, 0.45)) }
        fills += crenels.map { fill($0, m(0.75)) } + [fill(rect(0.4, 0.42, 0.46, 0.52), .zero), fill(tower, m(0.75))]
        fills += weed.map { fill($0, Tone(0.55, 0, 0.62)) }

        var s: [Halftone.Stroke] = []
        // The bowl: its glass, the lip, the waterline and the table it stands on.
        s += pieces(arc(bowl, wall, -62, 242, 72), bold)
        s += pieces(ellipse(P(0, -0.76), 0.41, 0.06, 36), bold)
        s += pieces((0...40).map { P(-0.8 + 0.04 * Double($0), surface + 0.012 * sin(Double($0) * 1.3)) }, mid)
        s += pieces(arc(bowl, wall - 0.07, 150, 215, 16), bold, 8)
        s += runs(span(P(-1, 0.86), P(1, 0.86), 40), mid) { abs($0.x) > 0.4 }
        // The gravel's top, the weed and the castle with its door and window.
        s += pieces((0...30).map { P(-0.75 + 0.05 * Double($0), 0.66 + 0.015 * sin(Double($0) * 2.1)) }, mid)
        for w in weed { s += pieces(w, mid, 5) }
        s.append(stroke(closed(tower), bold))
        for c in crenels { s.append(stroke([c[3], c[0], c[1], c[2]], mid)) }
        s.append(stroke(closed(rect(0.4, 0.42, 0.46, 0.52)), mid))
        s.append(stroke(closed(rect(0.41, 0.3, 0.45, 0.35)), hair))
        // The goldfish: body, eye, gill, scales, fins and tail, and their bubbles rising.
        for f in fish {
            s.append(stroke(ellipse(f.at, f.size, f.size * 0.6, 36), bold))
            s.append(stroke(circle(f.at + P(f.faces * f.size * 0.6, -f.size * 0.12), f.size * 0.12, 10), mid))
            s.append(stroke(arc(f.at + P(f.faces * f.size * 0.2, 0), f.size * 0.45, f.faces > 0 ? -50 : 130, f.faces > 0 ? 50 : 230, 10), mid))
            for k in 0..<3 { s.append(stroke(arc(f.at + P(-f.faces * f.size * 0.25 * Double(k), 0.02), f.size * 0.18, f.faces > 0 ? -60 : 120, f.faces > 0 ? 60 : 240, 6), hair)) }
            let root = f.at - P(f.faces * f.size * 0.85, 0)
            s.append(stroke(closed([root, root - P(f.faces * f.size * 0.75, f.size * 0.6), root - P(f.faces * f.size * 0.55, 0), root - P(f.faces * f.size * 0.75, -f.size * 0.6)]), mid))
            for t in [-0.3, 0.3] { s.append(stroke([root - P(f.faces * f.size * 0.1, 0), root - P(f.faces * f.size * 0.62, t * f.size)], hair)) }
            s.append(stroke(Array(dorsal(f).dropLast()), mid))
            let mouth = f.at + P(f.faces * f.size * 1.05, -0.01)
            for (k, r) in [0.012, 0.018, 0.024].enumerated() { s.append(stroke(circle(mouth + P(f.faces * 0.02 * Double(k), -0.06 - 0.07 * Double(k)), r, 10), hair)) }
        }
        // The bubble: its rim, a glint and the bubbles clinging to it.
        s.append(stroke(circle(bubble, 0.25, 48), bold))
        s.append(stroke(arc(bubble, 0.2, 200, 260, 10), bold))
        s.append(stroke(arc(bubble, 0.2, 20, 70, 8), hair))
        for (at, r) in clinging { s.append(stroke(circle(bubble + at, r, 12), mid)) }
        // The coin: its milled edge and rim.
        s.append(stroke(circle(coin, 0.25, 48), bold))
        s.append(stroke(circle(coin, 0.205, 44), mid))
        // Through the bubble: the cat looking down, ears up, slit eyes, nose and whiskers.
        let cat = bubble + P(0.018, -0.024)
        s.append(stroke(arc(cat, 0.032, 300, 600, 20), 0.0036))
        for side in [-1.0, 1.0] {
            s.append(stroke([cat + P(side * 0.016, -0.028), cat + P(side * 0.03, -0.05), cat + P(side * 0.031, -0.014)], 0.0034))
            s.append(stroke(ellipse(cat + P(side * 0.012, -0.006), 0.007, 0.005, 10), 0.0026))
            s.append(stroke([cat + P(side * 0.012, -0.011), cat + P(side * 0.012, -0.001)], 0.0022))
            for t in [-0.006, 0.002, 0.01] { s.append(stroke([cat + P(side * 0.012, 0.012), cat + P(side * 0.05, 0.012 + 2 * t)], 0.0016)) }
        }
        s.append(stroke(closed([cat + P(-0.005, 0.006), cat + P(0.005, 0.006), cat + P(0, 0.012)]), 0.0024))
        s.append(stroke(curve(cat + P(-0.008, 0.02), cat + P(0, 0.016), cat + P(0.008, 0.02), 4), 0.0018))
        // On the coin: a ship under two sails on a line of sea, a pennant at her masthead.
        let ship = coin + P(0.018, -0.02)
        s.append(stroke(closed([ship + P(-0.036, 0.016), ship + P(0.036, 0.016), ship + P(0.026, 0.03), ship + P(-0.026, 0.03)]), 0.0034))
        s.append(stroke([ship + P(0, 0.016), ship + P(0, -0.05)], 0.0028))
        s.append(stroke(curve(ship + P(-0.026, -0.04), ship + P(-0.03, -0.014), ship + P(-0.026, 0.01), 6) + [ship + P(-0.004, 0.01), ship + P(-0.004, -0.04), ship + P(-0.026, -0.04)], 0.0028))
        s.append(stroke(curve(ship + P(0.026, -0.03), ship + P(0.032, -0.008), ship + P(0.026, 0.01), 6) + [ship + P(0.004, 0.01), ship + P(0.004, -0.03), ship + P(0.026, -0.03)], 0.0028))
        s.append(stroke(closed([ship + P(0, -0.05), ship + P(0.018, -0.045), ship + P(0, -0.04)]), 0.002))
        s.append(stroke((0...8).map { ship + P(-0.05 + 0.0125 * Double($0), 0.04 + ($0 % 2 == 0 ? 0 : 0.005)) }, 0.0022))
        return panel("fishbowl", fills: fills, strokes: s) { p in
            let dc = p - coin, rc = simd_length(dc)
            if rc < 0.25 {
                guard rc > 0.205 else { return y(0.82) }
                return Int(((atan2(dc.y, dc.x) / .pi + 1) * 18).rounded(.down)) % 2 == 0 ? y(0.95) : Tone(0, 0.3, 0.35)
            }
            let db = p - bubble, rb = simd_length(db)
            if rb < 0.25 {
                guard rb > 0.2 else { return m(0.34) }
                return db.y > 0.06 ? Tone(0.1, 0.15, 0.95) : db.y < -0.1 ? Tone(0.3, 0.3, 0.35) : c(0.9)
            }
            guard simd_distance(p, bowl) < wall, p.y > -0.76 else {
                if p.y > 0.86 { return Tone(0, 0.25, 0.6) }
                return Int(((p.x + 1) / 0.12).rounded(.down)) % 2 == 0 ? m(0.42) : m(0.28)
            }
            guard p.y > 0.67 else { return p.y < surface ? c(0.12) : c(0.5) }
            // The gravel: a pebble a cell, its tone by the cell.
            let j = (p.y / 0.07).rounded(.down), i = ((p.x + (Int(j) % 2 == 0 ? 0 : 0.035)) / 0.07).rounded(.down)
            let centre = P((i + 0.5) * 0.07 - (Int(j) % 2 == 0 ? 0 : 0.035), (j + 0.5) * 0.07)
            guard simd_length((p - centre) / P(0.032, 0.026)) < 1 else { return m(0.12) }
            switch Int(i * 7 + j * 3).quotientAndRemainder(dividingBy: 3).remainder {
            case 0: return m(0.7)
            case 1, -1: return Tone(0, 0.25, 0.75)
            default: return Tone(0.3, 0.35, 0)
            }
        }
    }()
}
