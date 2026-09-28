// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import os

/// The floats each live picture's shader reads, per seed (the level number) and time t.
extension Picture {
    /// The glass: 22 x 22 cells 0.11 across from (-1.21, -1.21), each a seed wandering its own circle inside its cell, a
    /// breath phase, and a scan pane's angle signed by which way it sweeps, or 0. The shader searches the 3 x 3 cells
    /// around a point, so offsets stay under half a cell: 0.3 of jitter, 0.15 of wander.
    static func cells(seed: Int, t: Double) -> [Float] {
        var rng = SplitMix64(state: UInt64(seed))
        func random(_ a: Double, _ b: Double) -> Double { .random(in: a..<b, using: &rng) }
        let pitch = 0.11, n = 22
        var f: [Float] = []
        f.reserveCapacity(4 * n * n)
        for k in 0..<n * n {
            let jitter = SIMD2(random(-0.3, 0.3), random(-0.3, 0.3)), w = 2 * Double.pi * (random(0, 1) + t / random(7, 13))
            let at = (SIMD2(Double(k % n), Double(k / n)) + 0.5 + jitter + 0.15 * SIMD2(cos(w), sin(w))) * pitch - 1.21
            let pane = random(0, 1) < 0.12 ? random(0.001, .pi) * (random(0, 1) < 0.5 ? 1 : -1) : 0
            f += [Float(at.x), Float(at.y), Float(random(0, 1)), Float(pane)]
        }
        return f
    }

    /// Chainmail: 18 x 18 cells 0.14 across from (-1.26, -1.26), each (centre x, y, radius, code). The centre wanders a
    /// circle of 0.004 once or twice a period, either way. With jitter 0.4 + wander 0.004 + radius 0.55 of a cell, a link
    /// two cells away stays over 0.07 from any point, past its stroke, gap and glow. code packs colour (2 bits: ember or
    /// blood), shine direction (1) and speed (1), shine phase (7), breath phase (7), weight (1) and 5 spare random bits.
    static func links(seed: Int, t: Double) -> [Float] {
        var rng = SplitMix64(state: UInt64(seed) &+ 0xC4A1_4AA1)
        let pitch = 0.14, n = 18, origin = -1.26, period = Picture.chainmail.period
        // Dye: 24 blots, each ember (0) or blood (1); a link mostly takes its nearest blot's colour.
        var bx = [Double](repeating: 0, count: 24), by = bx, bc = [UInt64](repeating: 0, count: 24)
        for b in 0..<24 {
            let r = rng.next(), pick = Double((r >> 32) & 0xFFFF) / 65536
            bx[b] = Double(r & 0xFFFF) / 65536 * 2.6 - 1.3
            by[b] = Double((r >> 16) & 0xFFFF) / 65536 * 2.6 - 1.3
            bc[b] = pick < 0.65 ? 0 : 1
        }
        var f: [Float] = []
        f.reserveCapacity(4 * n * n)
        for k in 0..<n * n {
            // One draw gives the link's place, size and wander; the low 24 bits of a second are its code.
            let r = rng.next()
            var code = rng.next() & 0xFF_FFFC
            func unit(_ shift: UInt64) -> Double { Double((r >> shift) & 0xFFFF) / 65536 }
            let jitter = 0.8 * SIMD2(unit(0), unit(16)) - 0.4
            let turns = ((r >> 48) & 1 == 0 ? 1.0 : 2.0) * ((r >> 49) & 1 == 0 ? 1 : -1)
            let w = 2 * Double.pi * (unit(32) + turns * t / period)
            let home = (SIMD2(Double(k % n), Double(k / n)) + 0.5 + jitter) * pitch + origin
            let at = home + 0.004 * SIMD2(cos(w), sin(w))
            let radius = (0.40 + 0.15 * Double((r >> 50) & 0x3FF) / 1024) * pitch
            if (r >> 60) < 13 {
                var best = Double.infinity
                for b in 0..<24 {
                    let dx = bx[b] - home.x, dy = by[b] - home.y, d = dx * dx + dy * dy
                    if d < best { best = d; code = code & ~3 | bc[b] }
                }
            } else {
                code |= (r >> 60) & 1
            }
            f.append(Float(at.x)); f.append(Float(at.y)); f.append(Float(radius)); f.append(Float(code))
        }
        return f
    }

    /// Coral: 15 x 15 cells 0.16 across from (-1.2, -1.2), a wave kernel each, 6 floats (centre x, y, wave vector x, y,
    /// phase, glow), stripes 0.17 apart. Directions are random per kernel, then smoothed once with the 3 x 3 neighbours
    /// (as doubled angles, since a stripe has no sign): walls run straight for about a stripe or two, so a shear ring's
    /// drag shows as a hook, yet directions are unrelated beyond about 0.3, under a rigid core's size. Phases sway by at
    /// most 0.05 pi on their own timing, so a wall moves under 0.005 and never flips where two walls nearly meet.
    static func kernels(seed: Int, t: Double) -> [Float] {
        var rng = SplitMix64(state: UInt64(seed) &+ 0x7475_7269)
        func random(_ a: Double, _ b: Double) -> Double { a + (b - a) * Double(rng.next() >> 11) * 0x1p-53 }
        let n = 15, pitch = 0.16, wave = 2 * Double.pi / 0.17, tau = 2 * Double.pi, period = Picture.coral.period
        var f = [Float](repeating: 0, count: 6 * n * n)
        var ax = [Double](repeating: 0, count: n * n), ay = ax
        for k in 0..<n * n {
            let a = random(0, tau)
            ax[k] = cos(2 * a)
            ay[k] = sin(2 * a)
            f[6 * k] = Float((Double(k % n) + 0.5 + random(-0.35, 0.35)) * pitch - 1.2)
            f[6 * k + 1] = Float((Double(k / n) + 0.5 + random(-0.35, 0.35)) * pitch - 1.2)
            f[6 * k + 4] = Float(random(0, tau) + 0.05 * Double.pi * sin(tau * (random(0, 1) + t / period)))
            f[6 * k + 5] = Float(0.5 + 0.5 * sin(tau * (random(0, 1) + Double(Int(random(2, 5))) * t / period)))
        }
        for k in 0..<n * n {
            var sx = 0.0, sy = 0.0
            for dj in -1...1 {
                for di in -1...1 {
                    let i = k % n + di, j = k / n + dj
                    guard i >= 0, i < n, j >= 0, j < n else { continue }
                    let w = di == 0 && dj == 0 ? 1.0 : (di == 0 || dj == 0 ? 0.5 : 0.28)
                    sx += w * ax[j * n + i]
                    sy += w * ay[j * n + i]
                }
            }
            let a = atan2(sy, sx) / 2
            f[6 * k + 2] = Float(wave * cos(a))
            f[6 * k + 3] = Float(wave * sin(a))
        }
        return f
    }

    /// Marbling: 10 x 10 cells 0.26 across from (-1.3, -1.3), a drop each, two float4s: (x, y, ring offset o, glow) and
    /// (k + |q|, qx, qy, 0). The shader's ring coordinate for a drop is (k + |q|) |r| + q.r - o, in rings: k = 1 / spacing,
    /// and q crowds the rings on one side, up to 2x tighter there, so they are not concentric. -0.1 <= o < 0.5 keeps the
    /// first ring drawn 0.9 to 1.5 spacings out on the loose side, so there is no centre dot. Jitter stays under 0.3 of a
    /// cell. Only glow breathes: swelling drops would have small rings born and dying where three drops meet.
    static func drops(seed: Int, t: Double) -> [Float] {
        var rng = SplitMix64(state: UInt64(seed) &+ 0x4D_41_52_42)
        func random(_ a: Double, _ b: Double) -> Double { .random(in: a..<b, using: &rng) }
        let pitch = 0.26, n = 10, origin = -1.3, period = Picture.marbling.period
        var f: [Float] = []
        f.reserveCapacity(8 * n * n)
        for k in 0..<n * n {
            let jitter = SIMD2(random(-0.3, 0.3), random(-0.3, 0.3))
            let at = (SIMD2(Double(k % n), Double(k / n)) + 0.5 + jitter) * pitch + origin
            let spacing = random(0.04, 0.05)
            let offset = random(-0.1, 0.5)
            let push = random(0.25, 0.5)
            let angle = random(0, 2 * .pi)
            let glow = 0.5 + 0.5 * sin(2 * .pi * (t / period + random(0, 1)))
            let scale = 1 / spacing, q = push * scale
            f += [Float(at.x), Float(at.y), Float(offset), Float(glow),
                  Float(scale + q), Float(q * cos(angle)), Float(q * sin(angle)), 0]
        }
        return f
    }

    /// A twin's heartbeat: the seconds late it reaches each point of a 33 x 33 grid over the tank, from (-1.1, -1.1) to
    /// (1.1, 1.1), t seconds into its minute: up to 0.4, by gradient noise 2.4 cells across the tank whose sample point
    /// circles once a minute, so the beat runs out from wherever the delay is least and the pattern drifts. Linear in the
    /// noise, so a front keeps moving; only the extremes, a few percent of the tank, beat together. Built here, not per
    /// pixel: in the shader the noise alone cost 0.6 of a stack entry of four-tap work (Mac GPU microbench).
    static func delays(t: Double) -> [Float] {
        let a = 2 * Double.pi * t / 60, o = SIMD2(0.6 * cos(a), 0.6 * sin(a))
        return (0..<33 * 33).map { k in
            let p = SIMD2(Double(k % 33), Double(k / 33)) * (2.2 / 32) - 1.1
            return Float(0.4 * min(max(noise(1.2 * p + o) / 0.8 + 0.5, 0), 1))
        }
    }

    /// Perlin's gradient noise at p, within ±0.71 (±0.35 over 90% of the tank): unit cells, each corner's gradient drawn
    /// from an 8 x 8 table, tiled.
    private static func noise(_ p: SIMD2<Double>) -> Double {
        let i = p.rounded(.down), f = p - i, u = f * f * f * (f * (f * 6 - 15) + 10)
        func corner(_ x: Double, _ y: Double) -> Double {
            let g = gradients[(Int(i.y + y) & 7) * 8 + (Int(i.x + x) & 7)]
            return g.x * (f.x - x) + g.y * (f.y - y)
        }
        let low = corner(0, 0) + (corner(1, 0) - corner(0, 0)) * u.x, high = corner(0, 1) + (corner(1, 1) - corner(0, 1)) * u.x
        return low + (high - low) * u.y
    }

    private static let gradients: [SIMD2<Double>] = {
        var rng = SplitMix64(state: 5)
        return (0..<64).map { _ in
            let a = Double(rng.next() >> 11) / Double(1 << 53) * 2 * .pi
            return SIMD2(cos(a), sin(a))
        }
    }()

    private static let webs = OSAllocatedUnfairLock(initialState: [Int: [Float]]())

    /// The neural web for a seed, once `buildWeb` has made it.
    static func web(seed: Int) -> [Float]? { webs.withLock { $0[seed] } }

    /// Nothing in the web moves, and a build takes about 8 ms (Mac, optimised), so each seed is built once, off the
    /// main actor.
    static func buildWeb(seed: Int) async {
        guard web(seed: seed) == nil else { return }
        let f = await Task.detached(priority: .userInitiated) { nodes(seed: seed) }.value
        webs.withLock { $0[seed] = f }
    }

    /// Neurons: nodes 3 floats each (x, y, flags), stored on a lookup lattice of 26 rows 0.0866 apart from y = -1.1258
    /// and 24 cells 0.1 wide from x = -1.2, odd rows shifted half a cell right. A node sits anywhere within `jitter` of
    /// its cell's centre and at least `apart` from every other node, so the lattice's six-fold order does not survive
    /// into the web. Flag bits 0-5 are edges toward the lattice neighbours right, down-right, down-left, left, up-left,
    /// up-right, set at both ends; bit 6 a soma; bit 7 a knob (a node where a single dendrite ends); bits 8-22 the three
    /// edges a node owns (right, down-right, down-left), 5 bits each: a bow level 0-6 (3 straight, steps of `bowStep` of
    /// the edge's length) and a spur code (0 whole, 1 stops partway from this node, 2 from the far one).
    /// The shader draws only the edges of p's nearest node among the 9 it searches. So an edge is kept only if that
    /// search, run here exactly, finds one of the edge's ends at samples 0.004 apart along it, out to `reach` either
    /// side; its bow is cut back first. A soma goes only where the search finds its node out to `room`, which covers
    /// the twin's swollen somas too.
    static func nodes(seed: Int) -> [Float] {
        let n = 24, rows = 26, wide = 0.1, high = 0.0866025, left = -1.2, top = -1.1258
        let jitter = 0.062, apart = 0.05, bowStep = 0.06, spurs = 0.08, somas = 0.3, reach = 0.0125, room = 0.028
        var rng = SplitMix64(state: UInt64(seed) &+ 0x6E65_7572_6F6E)
        func random(_ a: Double, _ b: Double) -> Double { a + (b - a) * Double(rng.next() >> 11) * 0x1p-53 }
        // The lattice neighbour of node k toward right, down-right, down-left, left, up-left or up-right, or -1 off it.
        func step(_ k: Int, _ d: Int) -> Int {
            let i = k % n, j = k / n, o = j & 1
            var si = i, sj = j
            switch d {
            case 0: si += 1
            case 1: si += o; sj += 1
            case 2: si += o - 1; sj += 1
            case 3: si -= 1
            case 4: si += o - 1; sj -= 1
            default: si += o; sj -= 1
            }
            return si >= 0 && si < n && sj >= 0 && sj < rows ? sj * n + si : -1
        }
        let count = n * rows
        var x = [Double](repeating: 0, count: count), y = x
        for k in 0..<count {
            let i = k % n, j = k / n
            let cx = left + (Double(i) + 0.5 + 0.5 * Double(j & 1)) * wide, cy = top + (Double(j) + 0.5) * high
            var best = -1.0
            for _ in 0..<16 {
                let a = random(0, 2 * .pi), r = jitter * random(0, 1).squareRoot()
                let tx = cx + r * cos(a), ty = cy + r * sin(a)
                var near = Double.infinity
                for jj in max(j - 2, 0)...j {
                    for ii in max(i - 2, 0)...min(i + 2, n - 1) where jj * n + ii < k {
                        let o = jj * n + ii
                        near = min(near, (x[o] - tx) * (x[o] - tx) + (y[o] - ty) * (y[o] - ty))
                    }
                }
                if near > best { best = near; x[k] = tx; y[k] = ty }
                if near >= apart * apart { break }
            }
        }
        // The shader's search, clamped the same way.
        func nearest(_ px: Double, _ py: Double) -> Int {
            let j0 = Int(floor((py - top) / high)) - 1
            var best = -1, bd = Double.infinity
            for r in 0..<3 {
                let j = min(max(j0 + r, 0), rows - 1)
                let i0 = Int(floor((px - left) / wide - 0.5 * Double(j & 1))) - 1
                for c in 0..<3 {
                    let k = j * n + min(max(i0 + c, 0), n - 1)
                    let d = (x[k] - px) * (x[k] - px) + (y[k] - py) * (y[k] - py)
                    if d < bd { bd = d; best = k }
                }
            }
            return best
        }
        func holds(_ k: Int, _ r: Double, _ m: Int) -> Bool {
            (0..<m).allSatisfy { s in
                let a = 2 * Double.pi * Double(s) / Double(m)
                return nearest(x[k] + r * cos(a), y[k] + r * sin(a)) == k
            }
        }
        func clear(_ a: Int, _ b: Int, _ bow: Double) -> Bool {
            let ax = x[a], ay = y[a], ex = x[b] - ax, ey = y[b] - ay, len = (ex * ex + ey * ey).squareRoot()
            let nx = -ey / len, ny = ex / len, steps = Int((len / 0.004).rounded(.up))
            for s in 0...steps {
                let u = Double(s) / Double(steps), h = bow * len * 4 * u * (1 - u), slope = bow * 4 * (1 - 2 * u)
                let cx = ax + ex * u + nx * h, cy = ay + ey * u + ny * h
                let tx = ex / len + nx * slope, ty = ey / len + ny * slope, tl = (tx * tx + ty * ty).squareRoot()
                for o in [-reach, -0.5 * reach, 0, 0.5 * reach, reach] {
                    let k = nearest(cx - ty / tl * o, cy + tx / tl * o)
                    if k != a && k != b { return false }
                }
            }
            return true
        }
        let ends = (0..<count).map { holds($0, reach + 0.0015, 16) }
        var flags = [Int](repeating: 0, count: count), degree = flags
        for a in 0..<count {
            for slot in 0..<3 {
                let b = step(a, slot)
                guard b >= 0 else { continue }
                // Once a draw to drop some edges: still spent, so each seed keeps the web it was designed with.
                _ = random(0, 1)
                let q = Int(random(-3.5, 3.5).rounded()), spur = random(0, 1) < spurs, fromFar = random(0, 1) < 0.5
                guard ends[a] && ends[b] else { continue }
                var level = q
                while !clear(a, b, Double(level) * bowStep) {
                    if level == 0 { level = 99; break }
                    level -= level.signum()
                }
                guard level != 99 else { continue }
                let code = (level + 3) | (spur ? (fromFar ? 2 : 1) : 0) << 3
                flags[a] |= 1 << slot | code << (8 + 5 * slot)
                flags[b] |= 1 << (slot + 3)
                if !spur || !fromFar { degree[a] += 1 }
                if !spur || fromFar { degree[b] += 1 }
            }
        }
        for k in 0..<count {
            let roomy = holds(k, room, 24)
            if roomy && random(0, 1) < (degree[k] == 0 ? 0.5 : somas) { flags[k] |= 64 }
            else if degree[k] == 1 { flags[k] |= 128 }
        }
        var f = [Float](repeating: 0, count: 3 * count)
        for k in 0..<count {
            f[3 * k] = Float(x[k])
            f[3 * k + 1] = Float(y[k])
            f[3 * k + 2] = Float(flags[k])
        }
        return f
    }
}
