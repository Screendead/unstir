// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 8, Retrograde: problems 43 to 48's plates, drawn with `Kit`.
extension EscapementArt {
    /// A closed outline through the points, rounded by Catmull-Rom.
    private static func smooth(_ points: [P], steps: Int = 6) -> [P] {
        let n = points.count
        var out: [P] = []
        for i in 0..<n {
            let p0 = points[(i + n - 1) % n], p1 = points[i], p2 = points[(i + 1) % n], p3 = points[(i + 2) % n]
            for s in 0..<steps {
                let t = Double(s) / Double(steps), t2 = t * t, t3 = t2 * t
                out.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3))
            }
        }
        return out + [out[0]]
    }

    /// An open path through the points, rounded by Catmull-Rom.
    private static func smoothed(_ points: [P], steps: Int = 6) -> [P] {
        let ends = [2 * points[0] - points[1]] + points + [2 * points[points.count - 1] - points[points.count - 2]]
        var out: [P] = []
        for i in 1..<(ends.count - 2) {
            let p0 = ends[i - 1], p1 = ends[i], p2 = ends[i + 1], p3 = ends[i + 2]
            for s in 0..<steps {
                let t = Double(s) / Double(steps), t2 = t * t, t3 = t2 * t
                out.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3))
            }
        }
        return out + [points[points.count - 1]]
    }

    /// The path again, its points `spacing` apart along it.
    private static func resampled(_ path: [P], spacing: Double) -> [P] {
        var out = [path[0]], left = spacing
        for i in 1..<path.count {
            var a = path[i - 1]
            let b = path[i]
            while simd_distance(a, b) >= left {
                a += simd_normalize(b - a) * left
                out.append(a)
                left = spacing
            }
            left -= simd_distance(a, b)
        }
        return out
    }

    /// Whether `p` lies inside the ring, by the even-odd rule.
    private static func inside(_ p: P, _ ring: [P]) -> Bool {
        var odd = false
        for i in ring.indices {
            let a = ring[i], b = ring[(i + 1) % ring.count]
            if (a.y <= p.y) != (b.y <= p.y), p.x < a.x + (p.y - a.y) / (b.y - a.y) * (b.x - a.x) { odd.toggle() }
        }
        return odd
    }

    private static func placed(_ points: [(Double, Double)], at c: P, scale: Double = 1) -> [P] {
        points.map { c + scale * P($0.0, $0.1) }
    }

    /// A five-petalled blossom about `c`.
    private static func blossom(_ c: P, _ r: Double, turn: Double = 0) -> [P] {
        (0...100).map { i in
            let a = turn + 2 * .pi * Double(i) / 100
            return polar(c, r * (0.62 + 0.38 * abs(cos(2.5 * (a - turn)))), a)
        }
    }

    /// Problem 43, Spring forward, pent, clocks 0+,1-: a hare in mid-leap over a Breguet hand laid flat, a sprig of
    /// blossom at the hand's tip, a forward arrow cut in the meadow under it, and the top of the dial's chapter ring
    /// round the rim; one blossom in the second ink.
    static func plate43() -> Plate {
        var plate = Plate()
        let o = Kit.origin
        let hare = smooth(placed([
            (0.5, -0.02), (0.47, 0.02), (0.4, 0.05), (0.33, 0.08), (0.36, 0.13), (0.48, 0.2), (0.6, 0.24), (0.58, 0.28),
            (0.46, 0.255), (0.3, 0.19), (0.18, 0.16), (0.0, 0.165), (-0.16, 0.15), (-0.3, 0.22), (-0.5, 0.275),
            (-0.72, 0.3), (-0.73, 0.265), (-0.55, 0.225), (-0.43, 0.17), (-0.47, 0.11), (-0.54, 0.07), (-0.55, 0.01),
            (-0.49, -0.015), (-0.4, -0.05), (-0.24, -0.11), (-0.04, -0.125), (0.16, -0.1), (0.28, -0.08), (0.37, -0.1),
            (0.44, -0.075),
        ], at: P(0.02, -0.1), scale: 0.71), steps: 5)
        let ears = [(P(0.31, -0.085), P(0.02, -0.3), 0.05), (P(0.35, -0.095), P(0.1, -0.33), 0.055)].map { base, tip, w -> [P] in
            let d = simd_normalize(tip - base), n = P(-d.y, d.x) * w
            return smooth([base, (base * 0.55 + tip * 0.45) + n, tip, (base * 0.5 + tip * 0.5) - n * 0.6], steps: 6)
                .map { P(0.02, -0.1) + 0.71 * $0 }
        }
        let hand = Kit.hand(P(-0.82, 0.25), toward: 0, length: 1.46, width: 0.1, tail: 0.1)
        let meadow = smoothed([P(-1.1, 0.72), P(-0.6, 0.79), P(-0.15, 0.68), P(0.15, 0.67), P(0.55, 0.77), P(1.1, 0.68)])
            + [P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.7)]
        let ring = arc(o, 1.08, from: Kit.clock(9.45), to: Kit.clock(14.55)) + arc(o, 0.86, from: Kit.clock(14.55), to: Kit.clock(9.45))
            + [polar(o, 1.08, Kit.clock(9.45))]

        Kit.ground(&plate, angle: -0.42, around: [hare, hand] + ears)
        // The chapter ring over the top, its hours cut in bone.
        Kit.mass(&plate, ring)
        for k in 10...14 {
            let a = Kit.clock(Double(k))
            plate.lines(Kit.numeral(roman((k - 1) % 12 + 1), at: polar(o, 0.935, a), height: 0.085, turn: a + .pi / 2, squeeze: 0.8),
                        0.016, .bone)
        }
        for k in stride(from: 9.6, through: 14.4, by: 0.2) where abs(k - k.rounded()) > 0.01 {
            plate.line([polar(o, 0.865, Kit.clock(k)), polar(o, 0.885, Kit.clock(k))], medium, .bone)
        }

        // The meadow, its grass cut in bone and the arrow forward.
        Kit.mass(&plate, meadow)
        for k in 0..<34 {
            let x = -0.95 + Double(k) * 0.058, top = meadow.min { abs($0.x - x) < abs($1.x - x) }!.y
            let lean = 0.03 * (rnd(43, k) - 0.3)
            plate.line([P(x, top + 0.07), P(x + lean, top + 0.012)], heavy, .bone)
        }
        let shaft = Kit.band(P(-0.3, 0.85), P(0.2, 0.85), 0.06)
        plate.fill(shaft)
        plate.fill(Kit.barb(P(0.34, 0.85), toward: 0, size: 0.15))

        // The hand laid flat, its arbor bored.
        Kit.mass(&plate, hand)
        plate.fill(arc(P(-0.82, 0.25), 0.045))
        plate.line(arc(P(-0.82, 0.25), 0.045), medium)
        plate.fill(arc(P(-0.82, 0.25), 0.016), .black)
        plate.line([P(-0.7, 0.25), P(0.22, 0.25)], fine, .bone)
        // A Breguet hand's hollow moon near the tip.
        Kit.mass(&plate, arc(P(0.42, 0.25), 0.075))
        Kit.cut(&plate, arc(P(0.42, 0.25), 0.042))

        // The sprig from the hand's tip, its blossoms bone and one in the second ink.
        let twig = smoothed([P(0.62, 0.25), P(0.72, 0.19), P(0.8, 0.06), P(0.86, -0.04), P(0.93, -0.12)])
        plate.line(twig, 0.016)
        plate.line(smoothed([P(0.79, 0.09), P(0.88, 0.1), P(0.95, 0.06)]), heavy)
        for (c, r, t) in [(P(0.95, 0.05), 0.045, 0.2), (P(0.93, -0.14), 0.05, 0.6), (P(0.73, 0.15), 0.04, 1.0)] {
            plate.fill(blossom(c, r, turn: t))
            plate.line(blossom(c, r, turn: t), medium)
            plate.fill(arc(c, 0.01), .black)
        }
        let red = P(0.83, -0.01)
        plate.fill(blossom(red, 0.048, turn: 0.9), .second)
        plate.line(blossom(red, 0.048, turn: 0.9), medium)
        plate.fill(arc(red, 0.011), .black)
        for (a, b) in [(P(0.86, -0.06), P(0.79, -0.09)), (P(0.76, 0.14), P(0.68, 0.1))] {
            Kit.mass(&plate, smooth([a, (a + b) / 2 + P(0, -0.02), b, (a + b) / 2 + P(0, 0.02)], steps: 4))
        }

        // The leap's path, dotted, and the hare.
        let at = { (x: Double, y: Double) in P(0.02, -0.1) + 0.71 * P(x, y) }
        plate.lines(dashed(curve(P(-0.98, 0.17), P(-0.8, 0.05), at(-0.72, 0.25)), on: 0.03, off: 0.028), heavy)
        plate.lines(dashed(curve(at(0.6, 0.27), P(0.6, 0.1), P(0.72, 0.17)), on: 0.03, off: 0.028), heavy)
        for ear in ears { Kit.mass(&plate, ear) }
        plate.line(ears[1], medium, .bone)
        Kit.mass(&plate, hare)
        plate.fill(arc(at(0.4, -0.035), 0.016))
        plate.fill(arc(at(0.405, -0.035), 0.007), .black)
        plate.line(smoothed([at(-0.24, -0.07), at(-0.37, 0.0), at(-0.37, 0.12), at(-0.25, 0.165)]), medium, .bone)
        plate.line(smoothed([at(0.27, 0.0), at(0.3, 0.09), at(0.42, 0.18)]), medium, .bone)
        plate.line([at(0.5, -0.01), at(0.56, -0.03)], fine)
        for k in 0..<8 {
            let p = at(-0.2 + 0.06 * Double(k), -0.085 + 0.004 * Double(k))
            plate.line([p, p + P(-0.03, 0.025)], fine, .bone)
        }

        callout(&plate, "A", from: P(-0.1, -0.08), to: P(-0.3, -0.5))
        callout(&plate, "B", from: P(-0.82, 0.25), to: P(-0.72, 0.5))
        callout(&plate, "C", from: red, to: P(0.68, -0.48))
        callout(&plate, "D", from: P(0.0, 0.85), to: P(0.0, 0.58))
        return plate
    }

    /// Problem 44, Recoil, hex, clocks 1+,3-: a field gun firing to the left along the nine o'clock lane, its barrel
    /// and wheel in ink on a hatched carriage, smoke billowing round the rim ahead of it and recoil lines along the three
    /// o'clock lane behind, an earthwork round the foot; the muzzle flash in the second ink.
    static func plate44() -> Plate {
        var plate = Plate()
        let o = Kit.origin, breech = -0.18, axis = -0.01, length = 0.66
        // The barrel's radius along it from the breech: base ring, first reinforce, second, chase, muzzle swell.
        let profile: [(Double, Double)] = [(0, 0.09), (0.04, 0.09), (0.045, 0.082), (0.22, 0.079), (0.23, 0.072),
                                           (0.4, 0.068), (0.41, 0.061), (0.58, 0.054), (0.6, 0.066), (0.66, 0.07)]
        let upper = profile.map { P(breech - $0.0, axis - $0.1) }, lower = profile.map { P(breech - $0.0, axis + $0.1) }
        let barrel = upper + lower.reversed() + [upper[0]]
        let hub = P(-0.26, 0.17), rim = 0.2, muzzle = P(breech - length, axis)
        let cheek = smooth([P(-0.56, 0.05), P(-0.26, 0.04), P(-0.16, 0.1), P(0.12, 0.31), P(0.14, 0.355), P(0.07, 0.365),
                            P(-0.24, 0.21), P(-0.56, 0.13)], steps: 3)
        // Smoke billowing from the muzzle round the rim, thickest ahead of it: round billows, seen from the middle.
        let billows = [(8.9, 0.22, 0.98), (9.5, 0.17, 0.9), (8.3, 0.17, 0.93), (10.05, 0.16, 0.95), (7.75, 0.14, 0.97),
                       (10.6, 0.14, 0.98), (11.1, 0.12, 0.99), (7.3, 0.11, 1.0), (11.6, 0.1, 1.0), (12.05, 0.08, 1.02)]
            .map { (c: polar(o, $0.2, Kit.clock($0.0)), r: $0.1) }
        func edge(_ a: Double) -> Double {
            let d = P(cos(a), sin(a))
            return billows.compactMap { c, r -> Double? in
                let along = simd_dot(d, c), off = simd_length_squared(c) - along * along
                return off < r * r ? along - sqrt(r * r - off) : nil
            }.min() ?? 1.1
        }
        let angles = stride(from: Kit.clock(7.1), through: Kit.clock(12.3), by: 0.004).map { $0 }
        let inner = angles.map { polar(o, min(edge($0), 1.059), $0) }
        let smoke = inner + arc(o, 1.059, from: angles[angles.count - 1], to: angles[0]) + [inner[0]]
        let bank = stride(from: 2.6, through: 7.3, by: 0.05).map { h -> P in
            polar(o, 0.86 + 0.02 * sin(h * 7) + 0.2 * pow(max(0, (h - 6.6) / 0.7), 2) + 0.2 * pow(max(0, (3.4 - h) / 0.8), 2), Kit.clock(h))
        }
        let earth = bank + arc(o, 1.059, from: Kit.clock(7.3), to: Kit.clock(2.6)) + [bank[0]]

        Kit.ground(&plate, angle: 0.3, around: [barrel, cheek, arc(hub, rim), earth, smoke])
        Kit.mass(&plate, earth)
        for k in 0..<16 {
            let h = 3.0 + Double(k) * 0.26 + 0.1 * rnd(44, k), c = polar(o, 0.93 + 0.04 * rnd(44, k + 9), Kit.clock(h))
            plate.fill(ellipse(c, 0.03, 0.016, turned: Kit.clock(h) + .pi / 2 + 0.5 * rnd(44, k + 18)))
        }
        Kit.mass(&plate, smoke)
        for (k, (c, r)) in billows.enumerated() where r > 0.09 {
            let a = atan2(-c.y, -c.x) + 0.5 * (rnd(44, k) - 0.5)
            plate.line(arc(c + simd_normalize(c) * 0.2 * r, 0.75 * r, from: a - 1.2, to: a + 1.0), heavy, .bone)
            plate.line(arc(c + simd_normalize(c) * 0.45 * r, 0.4 * r, from: a - 0.8, to: a + 1.4), medium, .bone)
        }

        // The recoil: tapering lines along the lane behind, the wheel's last place dashed, the run back on the platform.
        for (y, from, to) in [(-0.06, 0.32, 0.7), (-0.025, 0.25, 0.86), (0.025, 0.25, 0.94), (0.06, 0.32, 0.76)] {
            let w = abs(y) < 0.03 ? 0.03 : 0.022
            Kit.mass(&plate, [P(from, y - w / 2), P(to, y), P(from, y + w / 2), P(from, y - w / 2)])
        }
        Kit.solid(&plate, Kit.band(P(-0.54, 0.39), P(0.24, 0.39), 0.04), angle: 0.8, gap: 0.02)
        plate.line([P(-0.2, 0.45), P(0.12, 0.45)], heavy)
        plate.fill(Kit.barb(P(0.2, 0.45), toward: 0, size: 0.06), .black)

        // The carriage, the wheel over it, then the barrel on its trunnions.
        Kit.solid(&plate, cheek, angle: -0.6, gap: 0.028, width: heavy)
        Kit.mass(&plate, arc(hub, rim))
        Kit.cut(&plate, arc(hub, rim - 0.034))
        for k in 0..<10 {
            let a = 0.2 + Double(k) * .pi / 5
            Kit.mass(&plate, Kit.band(polar(hub, 0.03, a), polar(hub, rim - 0.035, a), 0.024))
        }
        Kit.mass(&plate, arc(hub, 0.052))
        plate.fill(arc(hub, 0.018))
        Kit.mass(&plate, barrel)
        for (u, _) in [profile[1], profile[3], profile[5], profile[7]] {
            plate.line([P(breech - u - 0.006, axis - 0.075), P(breech - u - 0.006, axis + 0.075)], medium, .bone)
        }
        plate.line([P(breech - 0.06, axis - 0.05), P(breech - 0.56, axis - 0.034)], medium, .bone)
        Kit.mass(&plate, arc(P(breech + 0.04, axis), 0.036))
        Kit.mass(&plate, Kit.band(P(breech, axis), P(breech + 0.03, axis), 0.03))
        plate.fill(arc(P(-0.33, axis), 0.03))
        plate.line(arc(P(-0.33, axis), 0.03), medium)

        // The flash at the muzzle.
        let glare = muzzle + P(-0.09, 0)
        Kit.cut(&plate, arc(glare, 0.15), edge: fine)
        for k in 0..<24 {
            let a = Double.pi * Double(k) / 12 + 0.13
            plate.line([polar(glare, 0.12, a), polar(glare, 0.15, a)], fine)
        }
        Kit.mass(&plate, Array(barrel.filter { $0.x < breech - 0.45 }) + [barrel.first { $0.x < breech - 0.45 }!])
        let flash = (0...16).map { k -> P in
            let r: Double = k % 2 == 1 ? 0.035 : (k % 4 == 0 ? 0.12 : 0.08)
            return polar(glare, r, Double.pi * Double(k) / 8)
        }
        plate.fill(flash, .second)
        plate.line(flash, medium)

        callout(&plate, "A", from: P(-0.3, axis - 0.05), to: P(-0.22, -0.42))
        callout(&plate, "B", from: hub + P(0.13, 0.09), to: P(-0.14, 0.62))
        callout(&plate, "C", from: muzzle + P(-0.1, 0.05), to: P(-0.6, 0.6))
        callout(&plate, "D", from: P(0.62, 0.0), to: P(0.76, -0.44))
        return plate
    }

    /// Problem 45, Backlash, hex, clocks 1+,2-: a pinion on the middle arbor over a rack in elevation, a rack tooth
    /// riding loose in the pinion's space below, arrows of play either way, the frame's bridge over the top and the
    /// bed under the rack; the gap's marker in the second ink.
    static func plate45() -> Plate {
        var plate = Plate()
        let o = Kit.origin, teeth = 6, pitch = 0.25, m = 2 * pitch / Double(teeth), step = 2 * .pi * pitch / Double(teeth)
        let slack = 0.06, root = pitch - 1.2 * m, tip = pitch + 0.9 * m, rackTop = pitch + 1.2 * m, rackBottom = 0.52
        // A pinion of six leaves, a 30° step setting each leaf in a space; a space centred straight down.
        let tau = 2 * Double.pi / Double(teeth)
        let leaf: [(Double, Double)] = [(0.0, root), (0.3, root), (0.315, pitch), (0.33, tip - 0.02), (0.38, tip),
                                        (0.5, tip + 0.012), (0.62, tip), (0.67, tip - 0.02), (0.685, pitch), (0.7, root)]
        var pinion: [P] = []
        for k in 0..<teeth {
            let a: Double = .pi / 2 + Double(k) * tau
            for (f, r) in leaf { pinion.append(polar(o, r, a + f * tau)) }
        }
        pinion.append(pinion[0])
        // The rack's teeth, each narrowed by the slack and set back against the pinion's driving flank.
        let half = step / 4 - slack / 2, lean = 0.36 * m
        var rack: [P] = [P(-1.1, rackBottom), P(-1.1, rackTop)]
        for k in -5...5 {
            let x = Double(k) * step - slack / 2
            rack += [P(x - half - 1.2 * lean, rackTop), P(x - half + 0.9 * lean, pitch - 0.9 * m),
                     P(x + half - 0.9 * lean, pitch - 0.9 * m), P(x + half + 1.2 * lean, rackTop)]
        }
        rack += [P(1.1, rackTop), P(1.1, rackBottom), P(-1.1, rackBottom)]
        let body = box(P(-1.1, rackTop), P(1.1, rackBottom))
        let bridge = arc(o, 1.06, from: Kit.clock(9.6), to: Kit.clock(14.4)) + arc(o, 0.85, from: Kit.clock(14.4), to: Kit.clock(9.6))
            + [polar(o, 1.06, Kit.clock(9.6))]
        let bed = smoothed([P(-0.9, 0.64), P(-0.5, 0.81), P(0, 0.85), P(0.5, 0.81), P(0.9, 0.64)])
            + arc(o, 1.06, from: Kit.clock(3.6), to: Kit.clock(8.4)).dropFirst()

        Kit.ground(&plate, angle: -0.5, around: [pinion, bridge, bed, rack])
        Kit.mass(&plate, bridge)
        for h in [10.2, 11.3, 12.7, 13.8] {
            let c = polar(o, 0.94, Kit.clock(h))
            plate.fill(arc(c, 0.042))
            plate.line(arc(c, 0.042), medium)
            Kit.mass(&plate, Kit.band(polar(c, 0.036, Kit.clock(h) + 0.6), polar(c, 0.036, Kit.clock(h) + 0.6 + .pi), 0.016))
        }
        Kit.mass(&plate, bed)
        // The play either way, cut in the bed.
        plate.fill(Kit.band(P(-0.3, 0.91), P(0.3, 0.91), 0.045))
        plate.fill(Kit.barb(P(0.44, 0.91), toward: 0, size: 0.15))
        plate.fill(Kit.barb(P(-0.44, 0.91), toward: .pi, size: 0.15))

        // The gap, marked, then the rack over it: heavy teeth on a sectioned body, its screws in a row.
        let gap = P(half - slack / 2, pitch)
        plate.fill(box(gap + P(-0.01, -0.1), gap + P(slack + 0.02, 0.09)), .second)
        Kit.mass(&plate, rack)
        Kit.solid(&plate, body, angle: 0.75, gap: 0.06, width: medium)
        plate.line([P(-1.1, rackTop + 0.008), P(1.1, rackTop + 0.008)], 0.016)
        plate.line([P(-1.1, rackBottom - 0.008), P(1.1, rackBottom - 0.008)], 0.016)
        for k in -4...4 {
            let c = P(Double(k) * 0.25 + 0.125, (rackTop + rackBottom) / 2)
            plate.fill(arc(c, 0.03))
            plate.line(arc(c, 0.03), heavy)
            plate.line([c + P(-0.02, 0.02), c + P(0.02, -0.02)], heavy)
        }

        // The pinion: heavy leaves, its arbor sectioned.
        Kit.mass(&plate, pinion)
        Kit.solid(&plate, arc(o, root - 0.006), angle: 0.75, gap: 0.05, width: heavy)

        // The play round the pinion, either way.
        let swing = arc(o, 0.385, from: Kit.clock(10.6), to: Kit.clock(13.4))
        plate.line(swing, 0.018)
        plate.fill(Kit.barb(swing[swing.count - 1], toward: Kit.clock(13.4) + .pi / 2, size: 0.07), .black)
        plate.fill(Kit.barb(swing[0], toward: Kit.clock(10.6) - .pi / 2, size: 0.07), .black)

        callout(&plate, "A", from: polar(o, 0.29, Kit.clock(3.6)), to: P(0.3, -0.06))
        callout(&plate, "B", from: P(-0.6, 0.31), to: P(-0.78, 0.02))
        callout(&plate, "C", from: gap + P(slack / 2, 0.07), to: P(0.24, 0.66))
        callout(&plate, "D", from: P(0.0, 0.91), to: P(-0.12, 0.66))
        return plate
    }

    /// Problem 46, Ebb tide, pent, clocks 0+,1-: a pier's piles standing in a sea drawn back, its swell in bands of
    /// ink, the wet tide-line high on the piles, a waning moon over it and its track on the water, and a tide gauge
    /// on the nearest pile; the gauge's marker at the water in the second ink.
    static func plate46() -> Plate {
        var plate = Plate()
        let o = Kit.origin, deck = -0.05, wet = 0.04, water = 0.31, gaugeX = -0.04
        let piles: [Double] = [-0.8, -0.47, -0.22, gaugeX]
        func swell(_ j: Int, _ x: Double) -> Double {
            let y0 = water + 0.05 + Double(j) * 0.1, a = 0.012 + 0.004 * Double(j)
            return y0 + a * sin(x * (7 - 0.4 * Double(j)) + 1.3 * Double(j)) + 0.5 * a * sin(x * 13 + Double(j))
        }
        let sea = box(P(-1.1, water), P(1.1, 1.1))
        let moon = polar(o, 0.79, Kit.clock(1.3)), lunar = 0.17

        Kit.ground(&plate, angle: 0.3, around: [sea, arc(moon, lunar)])
        // The sea drawn back: the swell in bands, each heaviest at its crest, then the shingle bared at the foot.
        plate.fill(sea)
        plate.line([P(-1.1, water), P(1.1, water)], 0.016)
        for j in 0..<5 {
            let xs = stride(from: -1.1, through: 1.1, by: 0.01).map { $0 }
            let top = xs.map { P($0, swell(j, $0)) }
            let bottom = xs.reversed().map { x -> P in P(x, swell(j, x) + 0.018 + 0.026 * max(0, sin(x * (7 - 0.4 * Double(j)) + 1.3 * Double(j)))) }
            Kit.mass(&plate, top + bottom + [top[0]])
        }
        let shingle = smoothed([P(-1.1, 0.8), P(-0.6, 0.83), P(-0.2, 0.79), P(0.3, 0.82), P(0.7, 0.78), P(1.1, 0.8)]) + [P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.8)]
        Kit.mass(&plate, shingle)
        // The moon's track on the water, broken by the swell.
        for j in 0..<4 {
            let y = swell(j, moon.x) - 0.035, w = 0.05 + 0.025 * Double(j)
            plate.line([P(moon.x - w, y), P(moon.x + w, y)], heavy)
        }

        // The moon, waning: its lit side bone, its dark side in ink.
        plate.fill(arc(moon, lunar))
        let shade = arc(moon, lunar, from: .pi / 2, to: 3 * .pi / 2) + ellipse(moon, 0.06, lunar, from: 3 * .pi / 2, to: .pi / 2).reversed()
        Kit.mass(&plate, shade)
        for (d, r) in [(P(0.06, -0.05), 0.022), (P(0.08, 0.05), 0.017), (P(0.02, 0.09), 0.012)] { plate.line(arc(moon + d, r), medium) }
        plate.line(arc(moon, lunar), heavy)

        // The pier: piles dry and grained above the tide-line, wet and black below it, braced, the deck and its rail.
        for (k, x) in piles.enumerated() {
            let dry = box(P(x - 0.038, deck), P(x + 0.038, wet))
            Kit.solid(&plate, dry, angle: .pi / 2, gap: 0.025, width: fine)
            Kit.mass(&plate, box(P(x - 0.038, wet), P(x + 0.038, water)))
            let drowned = box(P(x - 0.034, water), P(x + 0.034, 0.82))
            plate.fill(drowned)
            plate.lines(hatch([drowned], angle: 0.25, gap: 0.03), heavy)
            plate.line([P(x - 0.034, water), P(x - 0.034, 0.82)], heavy)
            plate.line([P(x + 0.034, water), P(x + 0.034, 0.82)], heavy)
            let weed = (0...8).map { i -> P in P(x - 0.038 + 0.0095 * Double(i), wet + (i % 2 == 0 ? 0.0 : 0.02 + 0.015 * rnd(46, k * 9 + i))) }
            plate.line(weed, medium, .bone)
            if k + 1 < piles.count {
                let next = piles[k + 1]
                Kit.mass(&plate, Kit.band(P(x + 0.03, deck + 0.02), P(next - 0.03, water - 0.08), 0.026))
                Kit.mass(&plate, Kit.band(P(next - 0.03, deck + 0.02), P(x + 0.03, water - 0.08), 0.026))
            }
        }
        Kit.mass(&plate, box(P(-1.1, deck - 0.06), P(gaugeX + 0.12, deck)))
        for x in stride(from: -0.98, through: gaugeX + 0.1, by: 0.07) {
            plate.line([P(x, deck - 0.055), P(x, deck - 0.005)], medium, .bone)
        }
        for x in stride(from: -0.95, through: gaugeX + 0.1, by: 0.21) { Kit.mass(&plate, Kit.band(P(x, deck - 0.06), P(x, deck - 0.2), 0.024)) }
        Kit.mass(&plate, Kit.band(P(-1.1, deck - 0.2), P(gaugeX + 0.11, deck - 0.2), 0.026))

        // The tide gauge on the nearest pile: a board ruled in feet, the marker at the water.
        let board = box(P(gaugeX + 0.04, wet - 0.04), P(gaugeX + 0.12, water + 0.05))
        Kit.cut(&plate, board, edge: heavy)
        for (i, y) in stride(from: wet - 0.02, through: water + 0.04, by: 0.03).enumerated() {
            plate.line([P(gaugeX + 0.04, y), P(gaugeX + (i % 3 == 0 ? 0.1 : 0.07), y)], i % 3 == 0 ? heavy : medium)
        }
        for (i, n) in ["IV", "III", "II"].enumerated() {
            plate.lines(Kit.numeral(n, at: P(gaugeX + 0.155, wet + 0.015 + 0.09 * Double(i)), height: 0.04, squeeze: 0.8), medium)
        }
        let marker = [P(gaugeX + 0.125, water), P(gaugeX + 0.18, water - 0.03), P(gaugeX + 0.18, water + 0.03), P(gaugeX + 0.125, water)]
        plate.fill(marker, .second)
        plate.line(marker, medium)

        // The ebb, cut in the shingle.
        plate.fill(Kit.band(P(-0.2, 0.9), P(0.22, 0.9), 0.045))
        plate.fill(Kit.barb(P(0.36, 0.9), toward: 0, size: 0.14))

        callout(&plate, "A", from: P(-0.22, wet + 0.08), to: P(-0.3, -0.64))
        callout(&plate, "B", from: moon + P(-0.12, -0.04), to: P(0.24, -0.84))
        callout(&plate, "C", from: marker[1] + P(0, 0.02), to: P(0.6, 0.18))
        callout(&plate, "D", from: P(0.62, swell(3, 0.62) + 0.02), to: P(0.72, 0.5))
        return plate
    }

    /// Problem 47, Turnback, hex, clocks 1+,3-: a road climbing a dark hill in hairpin bends, a bone ribbon kerbed
    /// in ink, trees on the hillside between its legs, and a signpost on the bend in the three o'clock lane; the
    /// signpost's arrow in the second ink.
    static func plate47() -> Plate {
        var plate = Plate()
        let legs: [Double] = [0.86, 0.6, 0.37, 0.17, 0.0, -0.15, -0.28, -0.39]
        let reach: [Double] = [0.38, 0.68, 0.8, 0.78, 0.68, 0.55, 0.42, 0.3]
        // The road from the foot, bottom right, each leg turned back on itself at alternate ends.
        var path: [P] = [P(reach[0] + 0.1, 1.08), P(reach[0] - 0.02, legs[0] + 0.04)]
        for k in 0..<(legs.count - 1) {
            let side: Double = k % 2 == 0 ? -1 : 1, r = (legs[k] - legs[k + 1]) / 2
            let e = min(reach[k], reach[k + 1]) - r, mid = (legs[k] + legs[k + 1]) / 2
            path.append(P(side * e * 0.2, legs[k] - 0.008))
            for i in 0...14 {
                let a = Double.pi / 2 + side * Double(i) * Double.pi / 14 * -1
                path.append(P(side * e + r * cos(a) * side * side, mid + r * sin(a)))
            }
        }
        path.append(P(0.05, legs[legs.count - 1] - 0.005))
        path = resampled(path, spacing: 0.012)
        // The road narrows as it climbs away.
        func width(_ p: P) -> Double { 0.075 + 0.1 * min(1, max(0, (p.y + 0.4) / 1.26)) }
        var left: [P] = [], right: [P] = []
        for i in path.indices {
            let d = path[min(i + 1, path.count - 1)] - path[max(i - 1, 0)]
            let n = simd_normalize(P(-d.y, d.x)) * (width(path[i]) / 2)
            left.append(path[i] + n)
            right.append(path[i] - n)
        }
        let road = left + right.reversed() + [left[0]]
        // The hill a little past each bend, its top just over the last leg.
        let flank: [P] = [P(0.99, 0.6), P(0.96, 0.37), P(0.9, 0.17), P(0.8, 0.0), P(0.66, -0.17), P(0.5, -0.31), P(0.3, -0.42)]
        let hill = smoothed(flank.reversed().map { P(-$0.x, $0.y) } + [P(-0.1, -0.47), P(0.08, -0.48)] + flank)
            + [P(1.1, 0.6), P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, 0.6)]

        Kit.ground(&plate, angle: -0.35, around: [hill])
        Kit.mass(&plate, hill)
        // Trees on the hillside: bone firs in the ink, thinning toward the top.
        for k in 0..<900 {
            let c = P(-1 + 2 * rnd(47, k), -0.6 + 1.6 * rnd(47, k + 200))
            let tall = (0.03 + 0.05 * min(1, max(0, (c.y + 0.5) / 1.3))) * (0.8 + 0.4 * rnd(47, k + 400))
            // A tree the road would cut is drawn smaller, to stand clear of it, or left out.
            func cut(_ h: Double) -> Bool {
                [c + P(0, -h), c + P(0, 0.25 * h), c + P(0.4 * h, 0), c + P(-0.4 * h, 0)].contains { q in
                    stride(from: 0, to: path.count, by: 2).contains { simd_distance(path[$0], q) < width(path[$0]) / 2 + 0.008 }
                }
            }
            guard simd_length(c) < 0.98, inside(c + P(0, -tall), hill), let h = [tall, 0.7 * tall, 0.5 * tall].first(where: { !cut($0) })
            else { continue }
            plate.fill([c + P(0, -h), c + P(0.4 * h, 0), c + P(-0.4 * h, 0), c + P(0, -h)])
            plate.line([c, c + P(0, 0.25 * h)], medium, .bone)
        }
        // The road over them, kerbed, its crown dashed.
        plate.fill(road)
        plate.line(left, heavy)
        plate.line(right, heavy)
        plate.lines(dashed(path.filter { $0.y > -0.2 }, on: 0.03, off: 0.03), medium)

        // The signpost on the bend, its arm pointing back.
        let foot = P(0.87, 0.16), top = P(0.87, -0.04)
        Kit.cut(&plate, Kit.band(foot, top, 0.026), edge: medium)
        let arm = [top + P(0.07, 0.0), top + P(-0.1, 0.0), top + P(-0.15, 0.03), top + P(-0.1, 0.06), top + P(0.07, 0.06),
                   top + P(0.07, 0.0)]
        plate.fill(arm, .second)
        plate.line(arm, medium)
        plate.fill(arc(top + P(0, -0.012), 0.014))
        plate.line(arc(top + P(0, -0.012), 0.014), medium)

        callout(&plate, "A", from: path[path.count / 2], to: P(-0.28, -0.75))
        callout(&plate, "B", from: P(0.74, 0.09), to: P(0.78, -0.4))
        callout(&plate, "C", from: top + P(-0.12, 0.03), to: P(0.66, 0.6))
        callout(&plate, "D", from: P(-0.75, 0.3), to: P(-0.86, -0.32))
        return plate
    }

    /// Problem 48, Tide clock, hex, clocks 1+,2-: a tide clock's dial set off the hub between the middle rod and the
    /// two above it, a ring of waves for its hours, tall at high water and flat at low, one bold hand an hour past
    /// high water, and a ship's wheel behind it whose spokes and handles reach across the glass; the hand's tip in
    /// the second ink.
    static func plate48() -> Plate {
        var plate = Plate()
        let c = P(0.16, -0.28), face = 0.6, wheel = 0.86
        let tip = P(0.42, -0.64), toward = atan2(tip.y - c.y, tip.x - c.x), reach = simd_distance(tip, c)

        Kit.ground(&plate, angle: 0.4, around: [arc(c, face + 0.02)])
        // The ship's wheel behind: its spokes out to turned handles, then its rim.
        for k in 0..<8 {
            let a = Kit.clock(0.75) + Double(k) * .pi / 4
            Kit.mass(&plate, [polar(c, face, a - 0.05), polar(c, wheel + 0.1, a - 0.03), polar(c, wheel + 0.1, a + 0.03),
                              polar(c, face, a + 0.05), polar(c, face, a - 0.05)])
            let grip = smooth([polar(c, wheel + 0.1, a - 0.025), polar(c, wheel + 0.16, a - 0.045), polar(c, wheel + 0.26, a - 0.035),
                               polar(c, wheel + 0.3, a), polar(c, wheel + 0.26, a + 0.035), polar(c, wheel + 0.16, a + 0.045),
                               polar(c, wheel + 0.1, a + 0.025)], steps: 4)
            Kit.mass(&plate, grip)
            plate.line([polar(c, wheel + 0.13, a), polar(c, wheel + 0.25, a)], medium, .bone)
        }
        let rim = arc(c, wheel + 0.03) + arc(c, wheel - 0.03).reversed()
        Kit.mass(&plate, rim)
        plate.line(arc(c, wheel), medium, .bone)
        for k in 0..<8 {
            let a = Kit.clock(0.75) + Double(k) * .pi / 4
            plate.fill(arc(polar(c, wheel, a), 0.022))
            plate.line(arc(polar(c, wheel, a), 0.022), medium)
        }

        // The dial: a heavy bezel, the waves for hours, the face rayed.
        plate.fill(arc(c, face + 0.02))
        for k in 0..<36 where k % 2 == 0 {
            let a = Double(k) * .pi / 18
            Kit.mass(&plate, [polar(c, 0.1, a), polar(c, 0.6 * face, a - 0.045), polar(c, 0.6 * face, a + 0.045), polar(c, 0.1, a)])
        }
        plate.line(arc(c, 0.6 * face), heavy)
        Kit.mass(&plate, arc(c, face + 0.02) + arc(c, face - 0.035).reversed())
        for k in 0..<12 {
            let a = Kit.clock(Double(k)), height = 0.5 + 0.5 * cos(Double(k) * .pi / 6)
            let amp = 0.006 + 0.022 * height, w = 0.075
            let up = P(cos(a), sin(a)), along = P(-up.y, up.x)
            for (row, r) in [0.64, 0.73].enumerated() {
                let base = polar(c, r * face, a)
                let swell = (0...24).map { i -> P in
                    let t = Double(i) / 24 * 2 - 1
                    return base + along * (t * w) + up * (amp * sin(.pi * 2 * t + Double(row)))
                }
                plate.line(swell, 0.016)
            }
        }
        for k in 0..<60 where k % 5 != 0 {
            let a = Double(k) * .pi / 30
            plate.line([polar(c, face - 0.085, a), polar(c, face - 0.055, a)], medium)
        }
        plate.line(arc(c, face - 0.09), medium)

        // The hand, an hour past high water, its tail weighted and its tip in the second ink.
        let hand = Kit.hand(c, toward: toward, length: reach, width: 0.07, tail: 0.16)
        Kit.mass(&plate, hand)
        Kit.mass(&plate, arc(polar(c, 0.15, toward + .pi), 0.045))
        let point = [polar(c, 0.66 * reach, toward - 0.07), tip, polar(c, 0.66 * reach, toward + 0.07)]
        plate.fill(point + [point[0]], .second)
        plate.line(point + [point[0]], medium)
        plate.fill(arc(c, 0.03))
        plate.line(arc(c, 0.03), medium)

        callout(&plate, "A", from: polar(c, 0.68 * face + 0.05, Kit.clock(0)), to: P(-0.28, -0.84))
        callout(&plate, "B", from: tip, to: P(0.7, -0.62))
        callout(&plate, "C", from: polar(c, wheel, Kit.clock(7.5)), to: P(-0.82, 0.18))
        callout(&plate, "D", from: polar(c, 0.68 * face + 0.02, Kit.clock(6)), to: P(0.42, 0.62))
        return plate
    }
}
