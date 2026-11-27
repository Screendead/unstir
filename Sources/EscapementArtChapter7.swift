// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 7, Chronograph: problems 37 to 42's plates, drawn with `Kit`.
extension EscapementArt {
    /// A ring from radius `r0` to `r1` about `c`, as one outline.
    private static func annulus(_ c: P, _ r0: Double, _ r1: Double, from a: Double = 0, to b: Double = 2 * .pi) -> [P] {
        let outer = arc(c, r1, from: a, to: b), inner = arc(c, r0, from: b, to: a)
        return outer + inner + [outer[0]]
    }

    /// An outline symmetric about its axis, from the upper half's profile (along, across), laid from `c` toward `a`.
    private static func profile(_ half: [(Double, Double)], at c: P, toward a: Double) -> [P] {
        let upper = half.map { P($0.0, $0.1) }
        let ring = upper + upper.reversed().map { P($0.x, -$0.y) } + [upper[0]]
        return turned(ring, by: a).map { $0 + c }
    }

    /// Any outline in local coordinates, turned to `a` and moved to `c`.
    private static func placed(_ points: [(Double, Double)], at c: P, turn a: Double = 0, scale k: Double = 1) -> [P] {
        turned(points.map { P($0.0 * k, $0.1 * k) }, by: a).map { $0 + c }
    }

    /// Problem 37, Second hand, pent, clocks 0+,2+: a long counterpoised seconds hand, its needle at nine seconds and
    /// its lollipop tail across the middle, over a bone railway-track ring with twelve bold five-second wedges, in a
    /// heavy bezel; the lollipop's disc in the second ink. The middle is clear of every pent hub, and the hand lies
    /// between them.
    static func plate37() -> Plate {
        var plate = Plate()
        let o = Kit.origin, a = -0.2 * .pi
        let track = (inner: 0.66, outer: 0.925)
        let needle = profile([(-0.26, 0.021), (-0.05, 0.028), (0.09, 0.035), (0.5, 0.021), (0.8, 0.009), (0.9, 0)],
                             at: o, toward: a)
        let pop = polar(o, 0.33, a + .pi)

        Kit.ground(&plate, angle: 0.35, around: [arc(o, track.outer), arc(o, track.inner)])
        // The bezel, heavy, with its coin edge.
        Kit.mass(&plate, annulus(o, track.outer, 1.06))
        for k in 0..<120 {
            let t = Double(k) * .pi / 60
            plate.line([polar(o, 0.985, t), polar(o, 1.06, t)], medium, .bone)
        }
        plate.line(arc(o, 0.955), fine, .bone)
        // The railway track: two rails and a tie a second.
        Kit.mass(&plate, annulus(o, track.inner - 0.035, track.inner))
        plate.line(arc(o, 0.84), heavy)
        plate.line(arc(o, 0.89), heavy)
        for k in 0..<60 {
            let t = Double(k) * .pi / 30
            plate.line([polar(o, 0.84, t), polar(o, 0.89, t)], k % 5 == 0 ? heavy : medium)
        }
        // The five-second wedges, the minute's doubled.
        for k in 0..<12 {
            let t = Kit.clock(Double(k)), w = k == 0 ? 0.075 : 0.05
            let wedge = [polar(o, 0.915, t - w / 0.915), polar(o, 0.915, t + w / 0.915), polar(o, 0.69, t),
                         polar(o, 0.915, t - w / 0.915)]
            Kit.mass(&plate, wedge)
            plate.line([polar(o, 0.88, t), polar(o, 0.76, t)], fine, .bone)
        }
        // Where the needle has swept from, dotted along the rails.
        plate.lines(dashed(arc(o, 0.78, from: a - 0.55, to: a - 0.08), on: 0.012, off: 0.018), medium)
        plate.line(Kit.barb(polar(o, 0.78, a - 0.06), toward: a + .pi / 2, size: 0.04), medium)

        // The hand, cut clear of the ground by a bone halo, then solid.
        plate.line(needle, 0.024, .bone)
        plate.line(arc(pop, 0.085), 0.024, .bone)
        Kit.mass(&plate, needle)
        plate.line([polar(o, 0.1, a), polar(o, 0.66, a)], fine, .bone)
        plate.line([polar(o, 0.1, a + .pi), polar(o, 0.24, a + .pi)], fine, .bone)
        Kit.mass(&plate, arc(pop, 0.082))
        plate.fill(arc(pop, 0.058), .second)
        plate.line(arc(pop, 0.058), fine, .bone)
        plate.line(arc(pop, 0.038), fine)
        // The arbor: a domed cap and its pin.
        Kit.mass(&plate, arc(o, 0.07))
        plate.line(arc(o, 0.05), medium, .bone)
        plate.fill(arc(o, 0.022))
        plate.line(arc(o, 0.022), medium)

        callout(&plate, "A", from: pop + P(-0.04, 0.035), to: P(-0.6, 0.12))
        callout(&plate, "B", from: polar(o, 0.865, Kit.clock(6.6)), to: polar(o, 0.6, Kit.clock(6)))
        callout(&plate, "C", from: polar(o, 0.74, Kit.clock(3)), to: P(0.42, 0.12))
        callout(&plate, "D", from: polar(o, 0.8, a), to: P(0.24, -0.38))
        return plate
    }

    /// Problem 38, Pushpiece, hex, clocks 1+,3+: a chronograph's case band, a heavy ring, on its bracelet, its knurled
    /// crown at three and two pushpieces in the lanes either side, a fingertip in solid ink pressing the upper one home;
    /// the pressed pushpiece's cap in the second ink. Crown, pushpieces and finger keep clear of every hex hub.
    static func plate38() -> Plate {
        var plate = Plate()
        let o = Kit.origin, band = (inner: 0.41, outer: 0.55), push = 55.0 * .pi / 180
        let strapHalf = 0.18
        func strap(_ s: Double) -> [P] {
            let a0 = asin(strapHalf / 1.06)
            let rim = arc(o, 1.06, from: s * (.pi / 2) - a0, to: s * (.pi / 2) + a0)
            return [P(s * strapHalf, s * 0.42)] + (s > 0 ? rim : rim) + [P(-s * strapHalf, s * 0.42), P(s * strapHalf, s * 0.42)]
        }

        Kit.ground(&plate, angle: 0.6, around: [arc(o, band.outer), strap(-1), strap(1)])
        // The bracelet: solid outer links and cut centre links, row by row out to the rim.
        for s in [-1.0, 1.0] {
            plate.fill(strap(s))
            for y0 in stride(from: 0.555, to: 1.06, by: 0.105) {
                let y1 = y0 + 0.07
                for x in [-strapHalf, 0.085] {
                    Kit.mass(&plate, box(P(x, s * y0), P(x + 0.095, s * y1)))
                }
                Kit.cut(&plate, box(P(-0.06, s * (y0 + 0.004)), P(0.06, s * (y1 - 0.004))), edge: heavy)
                plate.line([P(-0.035, s * (y0 + 0.025)), P(0.035, s * (y0 + 0.025))], medium)
            }
        }

        // The pushpieces: a stem, a tube and a cap, the upper pressed home.
        for (k, s) in [-1.0, 1.0].enumerated() {
            let t = s * push, pressed = k == 0, at = pressed ? -0.045 : 0.0
            Kit.mass(&plate, Kit.band(polar(o, band.outer - 0.02, t), polar(o, 0.65 + at, t), 0.06))
            Kit.mass(&plate, Kit.band(polar(o, 0.62 + at, t), polar(o, 0.77 + at, t), 0.13))
            for d in [-0.035, 0.035] {
                let side = polar(o, d, t + .pi / 2) - o
                plate.line([polar(o, 0.645 + at, t) + side, polar(o, 0.745 + at, t) + side], 0.012, .bone)
            }
            let cap = profile([(0, 0.08), (0.04, 0.08), (0.065, 0.055), (0.072, 0)], at: polar(o, 0.77 + at, t), toward: t)
            if pressed {
                plate.fill(cap, .second)
                plate.line(cap, medium)
            } else {
                Kit.mass(&plate, cap)
            }
        }
        // The crown at three: its stem, a knurled body and a bone face.
        Kit.mass(&plate, Kit.band(P(band.outer - 0.02, 0), P(0.62, 0), 0.06))
        let crown = profile([(0, 0.11), (0.15, 0.11), (0.17, 0.095), (0.175, 0)], at: P(0.6, 0), toward: 0)
        Kit.mass(&plate, crown)
        for y in stride(from: -0.075, through: 0.076, by: 0.03) {
            plate.line([P(0.615, y), P(0.755, y)], 0.011, .bone)
        }
        plate.line([P(0.773, -0.08), P(0.773, 0.08)], medium, .bone)

        // The case band, heavy, its bevel and bezel in bone.
        Kit.mass(&plate, annulus(o, band.inner, band.outer))
        plate.line(arc(o, band.outer - 0.035), medium, .bone)
        plate.line(arc(o, band.inner + 0.03), 0.014, .bone)
        for k in 0..<60 {
            let t = Double(k) * .pi / 30 + 0.04
            plate.line([polar(o, band.outer - 0.05, t), polar(o, band.outer, t)], 0.018, .bone)
        }
        // The dial: bold batons, the hands and the chronograph's needle at its start.
        plate.fill(arc(o, band.inner))
        plate.line(arc(o, band.inner - 0.02), medium)
        for k in 0..<12 {
            let t = Kit.clock(Double(k))
            Kit.mass(&plate, Kit.band(polar(o, 0.26, t), polar(o, 0.36, t), k % 3 == 0 ? 0.05 : 0.032))
        }
        Kit.mass(&plate, Kit.hand(o, toward: Kit.clock(10.2), length: 0.24, width: 0.05, tail: 0.05))
        Kit.mass(&plate, Kit.hand(o, toward: Kit.clock(2.0), length: 0.34, width: 0.04, tail: 0.06))
        plate.line([polar(o, 0.1, Kit.clock(6)), polar(o, 0.37, Kit.clock(0))], medium)

        // The fingertip, pressing in from the rim along the lane: solid ink, its nail and creases in bone.
        let f = -push, tip = polar(o, 0.79, -push)
        let finger = placed(arc(P(0.12, 0), 0.12, from: .pi / 2, to: 1.5 * .pi).map { ($0.x, $0.y) }
                            + [(0.75, -0.14), (0.75, 0.14), (0.12, 0.12)], at: tip, turn: f)
        plate.line(finger, 0.024, .bone)
        Kit.mass(&plate, finger)
        plate.line(placed(ellipse(P(0.17, -0.07), 0.12, 0.038).map { ($0.x, $0.y) }, at: tip, turn: f), heavy, .bone)
        plate.line(placed(arc(P(0.29, -0.07), 0.04, from: 0.6 * .pi, to: 1.4 * .pi).map { ($0.x, $0.y) }, at: tip, turn: f),
                   medium, .bone)
        for x in [0.44, 0.48] {
            plate.line(placed(curve(P(x, 0.14), P(x - 0.025, 0.1), P(x, 0.06), 6).map { ($0.x, $0.y) }, at: tip, turn: f),
                       medium, .bone)
        }

        callout(&plate, "A", from: P(0.72, 0.1), to: P(0.86, 0.26))
        callout(&plate, "B", from: polar(o, 0.66, -push + 0.04), to: P(0.82, -0.36))
        callout(&plate, "C", from: polar(o, 0.8, push + 0.05), to: P(0.66, 0.66))
        callout(&plate, "D", from: polar(o, 0.5, .pi + 0.08), to: P(-0.78, 0.02))
        return plate
    }

    /// A limb or a stroke of a silhouette: a solid strip through the joints, rounded at each, cut from what lies
    /// under it by a bone halo `halo` wide.
    private static func limb(_ plate: inout Plate, _ joints: [P], _ width: Double, halo: Double = 0.022) {
        if halo > 0 {
            plate.line(joints, width + halo, .bone)
            for j in joints { plate.fill(arc(j, (width + halo) / 2)) }
        }
        plate.fill(Kit.ribbon(joints, width), .black)
        for j in joints { plate.fill(arc(j, width / 2), .black) }
    }

    /// A tapered strip through the joints, `widths` wide at each, as one outline.
    private static func taper(_ joints: [P], _ widths: [Double]) -> [P] {
        var left: [P] = [], right: [P] = []
        for i in joints.indices {
            let d = joints[min(i + 1, joints.count - 1)] - joints[max(i - 1, 0)]
            let n = simd_normalize(P(-d.y, d.x)) * (widths[i] / 2)
            left.append(joints[i] + n)
            right.append(joints[i] - n)
        }
        return left + right.reversed() + [left[0]]
    }

    /// A limb of a silhouette: a tapered solid strip, rounded at each joint, cut from what lies under it by a bone halo.
    private static func limb(_ plate: inout Plate, _ joints: [P], _ widths: [Double], halo: Double = 0.024) {
        let strip = taper(joints, widths)
        plate.line(strip, halo, .bone)
        for (j, w) in zip(joints, widths) { plate.fill(arc(j, w / 2 + halo / 2)) }
        plate.fill(strip, .black)
        for (j, w) in zip(joints, widths) { plate.fill(arc(j, w / 2), .black) }
    }

    /// Problem 39, Lap time, hex, clocks 1+,2+: a running track's bend in perspective, its lanes curving across the glass
    /// in alternate ink and bone with their numbers, a stand along the far side, the finish line chequered across
    /// them, and a runner in silhouette dipping through the line along the lane at three, clear of every hub, the
    /// broken tape falling from his chest; the tape in the second ink.
    static func plate39() -> Plate {
        var plate = Plate()
        let c = P(0.27, -1.75), stretch = 1.35
        let edges = [-0.12, -0.02, 0.09, 0.21, 0.34, 0.48, 0.63, 0.79, 0.96, 1.14].map { $0 - c.y }
        func edge(_ rho: Double) -> [P] {
            stride(from: -1.1, through: 1.1, by: 0.02).map { x in
                let u = (x - c.x) / (stretch * rho)
                return P(x, c.y + rho * (1 - u * u).squareRoot())
            }
        }
        func height(_ rho: Double, at x: Double) -> Double {
            let u = (x - c.x) / (stretch * rho)
            return c.y + rho * (1 - u * u).squareRoot()
        }
        // Where a ray from the bend's middle toward `d` crosses the edge `rho`.
        func cross(_ d: P, _ rho: Double) -> P { c + d * (rho / ((d.x / stretch) * (d.x / stretch) + d.y * d.y).squareRoot()) }

        Kit.ground(&plate, angle: 0, around: [])
        // The stand along the far side: its roof in ink, the crowd's heads under it.
        let far = edge(edges[0]), roof = far.map { P($0.x, $0.y - 0.135 - 0.045 * max(0, -$0.x)) }
        Kit.mass(&plate, far.map { P($0.x, $0.y - 0.012) } + roof.reversed() + [P(far[0].x, far[0].y - 0.012)])
        plate.line(far.map { P($0.x, $0.y - 0.1 - 0.033 * max(0, -$0.x)) }, 0.02, .bone)
        for (k, p) in far.enumerated() where k % 2 == 0 {
            plate.fill(arc(P(p.x, p.y - 0.05 - 0.02 * max(0, -p.x) - (k % 4 == 0 ? 0.012 : 0)), 0.017))
        }
        for (k, p) in roof.enumerated() where k % 4 == 0 {
            plate.line([p + P(0, 0.04), P(p.x, far[k].y - 0.015)], 0.036, .bone)
        }
        for (k, p) in roof.enumerated() where k % 10 == 5 {
            plate.line([p, p + P(0, -0.08)], medium)
            plate.fill([p + P(0, -0.08), p + P(0.05, -0.065), p + P(0, -0.05), p + P(0, -0.08)], .black)
        }

        // The lanes, ink and bone in turn, a bone stripe down each inked one, and their numbers at nine.
        let lanes = edges.count - 1
        for k in 0..<lanes {
            let inner = edge(edges[k]), outer = edge(edges[k + 1])
            plate.fill(inner + outer.reversed() + [inner[0]], k % 2 == 0 ? .black : .bone)
            if k % 2 == 0 { plate.line(edge((edges[k] + edges[k + 1]) / 2), 0.038 + 0.011 * Double(k), .bone) }
            let x = -0.74, y0 = height(edges[k], at: x), y1 = height(edges[k + 1], at: x)
            guard simd_length(P(x, (y0 + y1) / 2)) < 0.9 else { continue }
            let h = 0.45 * (y1 - y0)
            plate.fill(box(P(x - 0.6 * h, (y0 + y1) / 2 - 0.65 * h), P(x + 0.6 * h, (y0 + y1) / 2 + 0.65 * h)),
                       k % 2 == 0 ? .black : .bone)
            plate.lines(Kit.numeral(roman(lanes - k), at: P(x, (y0 + y1) / 2), height: h, squeeze: 1.1), max(medium, 0.14 * h),
                        k % 2 == 0 ? .bone : .black)
        }
        // Two staggers of start marks, each lane's further round the bend than the next lane in.
        for x0 in [-0.66, -0.2, 0.95] {
            for k in 0..<lanes {
                let x = x0 - 0.075 * Double(k), y = (height(edges[k], at: x) + height(edges[k + 1], at: x)) / 2
                let ray = P(x, y) - c, a = cross(ray, edges[k]), b = cross(ray, edges[k + 1]), w = 0.016 * simd_length(a - c)
                let n = P(-ray.y, ray.x) / simd_length(ray) * w
                plate.fill([a - n, b - n, b + n, a + n, a - n], k % 2 == 0 ? .bone : .black)
            }
        }
        for rho in edges { plate.line(edge(rho), heavy) }

        // The finish line, chequered across the lanes.
        let foot = P(0.28, 0.4), d = simd_normalize(foot - c), across = P(-d.y, d.x)
        for k in 0..<lanes {
            for half in 0..<2 {
                let r0 = edges[k] + Double(half) * (edges[k + 1] - edges[k]) / 2, r1 = r0 + (edges[k + 1] - edges[k]) / 2
                let a = cross(d, r0), b = cross(d, r1), wa = 0.02 * simd_length(a - c), wb = 0.02 * simd_length(b - c)
                for side in 0..<2 {
                    let s0 = Double(side) - 1, s1 = Double(side)
                    let square = [a + across * (s0 * wa), b + across * (s0 * wb), b + across * (s1 * wb), a + across * (s1 * wa)]
                    plate.fill(square + [square[0]], (k * 2 + half + side) % 2 == 0 ? .bone : .black)
                }
            }
        }

        // The runner, dipping at the line along the lane at three, arms flung back: solid ink, each part cut clear by a
        // bone halo.
        limb(&plate, [P(0.41, -0.05), P(0.565, -0.115), P(0.7, -0.21), P(0.745, -0.25)], [0.05, 0.042, 0.034, 0.03])
        limb(&plate, [P(0.69, -0.06), P(0.815, 0.09), P(0.915, 0.22), P(0.94, 0.185)], [0.1, 0.064, 0.04, 0.03])
        let torso = [P(0.3, -0.045), P(0.42, -0.085), P(0.55, -0.095), P(0.66, -0.11), P(0.72, -0.07), P(0.7, 0.0),
                     P(0.6, 0.02), P(0.5, 0.05), P(0.39, 0.085), P(0.31, 0.065), P(0.29, 0.01), P(0.3, -0.045)]
        plate.line(torso, 0.024, .bone)
        Kit.mass(&plate, torso)
        let head = P(0.232, 0.005)
        plate.fill(arc(head, 0.071))
        Kit.mass(&plate, arc(head, 0.058))
        plate.fill(arc(P(0.252, -0.015), 0.034), .black)
        plate.line(arc(head, 0.04, from: 3.3, to: 4.5), medium, .bone)
        limb(&plate, [P(0.66, -0.03), P(0.643, 0.16), P(0.685, 0.37), P(0.632, 0.405)], [0.1, 0.062, 0.04, 0.03])
        limb(&plate, [P(0.37, 0.02), P(0.5, 0.095), P(0.61, 0.07), P(0.645, 0.045)], [0.054, 0.044, 0.034, 0.03])
        // His singlet's hem, the number on his bib, the spikes under his shoes.
        plate.line([P(0.62, 0.03), P(0.655, -0.11)], 0.016, .bone)
        Kit.cut(&plate, [P(0.4, -0.04), P(0.52, -0.06), P(0.525, 0.0), P(0.41, 0.025), P(0.4, -0.04)], edge: fine)
        plate.lines(Kit.numeral("VII", at: P(0.462, -0.018), height: 0.04, turn: -0.17, squeeze: 0.9), medium)
        plate.line([P(0.65, 0.425), P(0.64, 0.44)], medium)
        plate.line([P(0.955, 0.17), P(0.97, 0.16)], medium)

        // The tape, broken on his chest, its ends falling away either side of him along the line.
        let upper = (0...14).map { k -> P in
            let t = Double(k) / 14
            return P(0.3 - 0.02 * t + 0.014 * sin(t * 3 * .pi), 0.025 - 0.32 * t)
        }
        let lower = (0...14).map { k -> P in
            let t = Double(k) / 14
            return P(0.31 - 0.025 * t + 0.014 * sin(t * 3 * .pi + 1), 0.075 + 0.3 * t)
        }
        for tail in [upper, lower] {
            let ribbon = Kit.ribbon(tail, 0.03)
            plate.line(ribbon, 0.022, .bone)
            plate.fill(ribbon, .second)
            plate.line(ribbon, fine)
        }

        callout(&plate, "A", from: cross(d, edges[7] + 0.05), to: P(0.06, 0.74))
        callout(&plate, "B", from: P(-0.45, -0.5), to: P(-0.27, -0.76))
        callout(&plate, "C", from: P(0.66, -0.09), to: P(0.86, -0.2))
        return plate
    }

    /// Problem 40, Split second, hex, clocks 1+,3+: a rattrapante's two seconds hands split from one arbor, the split
    /// hand stopped at five seconds in bone and the chronograph hand running on at fifteen in ink, each down a lane
    /// between the hubs, over a bold chapter ring, and below them the isolator's column wheel through a window cut in
    /// the dial; the stopped hand's tip in the second ink.
    static func plate40() -> Plate {
        var plate = Plate()
        let o = Kit.origin, stopped = Kit.clock(1), running = Kit.clock(3)
        let chapter = (inner: 0.79, outer: 0.95), window = P(0, 0.56), opening = 0.41

        Kit.ground(&plate, angle: -0.4, around: [arc(window, opening)])
        // The chapter ring: ink, a bone tick a second and a bone baton every five.
        Kit.mass(&plate, annulus(o, chapter.inner, chapter.outer))
        for k in 0..<60 {
            let t = Double(k) * .pi / 30
            if k % 5 == 0 {
                plate.fill(Kit.band(polar(o, chapter.inner + 0.02, t), polar(o, chapter.outer - 0.015, t), k % 15 == 0 ? 0.05 : 0.034))
            } else {
                plate.line([polar(o, chapter.outer - 0.06, t), polar(o, chapter.outer - 0.015, t)], 0.012, .bone)
            }
        }
        plate.line(arc(o, chapter.outer + 0.025), heavy)
        plate.line(arc(o, chapter.inner - 0.025), medium)

        // The sector ring between the arbor and the hubs: ink, a bone bar every five seconds.
        Kit.mass(&plate, annulus(o, 0.27, 0.35))
        for k in 0..<12 {
            let t = Kit.clock(Double(k))
            plate.line([polar(o, 0.285, t), polar(o, 0.335, t)], 0.026, .bone)
        }
        plate.line(arc(o, 0.375), heavy)

        // The window and the column wheel in it: seven columns standing off its ratchet.
        plate.fill(arc(window, opening))
        plate.lines(hatch([arc(window, opening), arc(window, 0.36)], angle: 1.1, gap: 0.03), fine)
        let ratchet = (0..<21).flatMap { k -> [P] in
            let t = Double(k) * 2 * .pi / 21 + 0.1
            return [polar(window, 0.305, t), polar(window, 0.355, t + 0.2), polar(window, 0.305, t + 2 * .pi / 21)]
        }
        Kit.mass(&plate, ratchet + [ratchet[0]])
        plate.fill(arc(window, 0.29))
        plate.lines(hatch([arc(window, 0.29)], angle: -0.5, gap: 0.03), fine)
        plate.line(arc(window, 0.29), medium)
        for k in 0..<7 {
            let t = Double(k) * 2 * .pi / 7 + 0.25, w = 0.16
            let column = arc(window, 0.27, from: t - w, to: t + w) + arc(window, 0.2, from: t + w * 1.25, to: t - w * 1.25)
            Kit.mass(&plate, column + [column[0]])
            plate.line(arc(window, 0.255, from: t - w * 0.7, to: t + w * 0.7), fine, .bone)
        }
        plate.line(arc(window, opening), 0.03)
        plate.line(arc(window, opening - 0.03), fine)

        // How far the chronograph hand has run since the split.
        for (r, on) in [(0.7, 0.03), (0.62, 0.02)] {
            plate.lines(dashed(arc(o, r, from: stopped + 0.12, to: running - 0.1), on: on, off: 0.018), medium)
        }
        plate.line(Kit.barb(polar(o, 0.7, running - 0.08), toward: running + .pi / 2 - 0.08, size: 0.045), medium)

        // The split hand: bone, edged in ink, its tip in the second ink.
        let split = profile([(-0.2, 0.026), (0.0, 0.04), (0.12, 0.046), (0.62, 0.028), (0.88, 0.0)], at: o, toward: stopped)
        plate.line(split, 0.026, .bone)
        plate.fill(split)
        plate.line(split, heavy)
        plate.line([polar(o, 0.2, stopped), polar(o, 0.6, stopped)], medium)
        let tip = profile([(0.7, 0.019), (0.88, 0.0)], at: o, toward: stopped)
        plate.fill(tip, .second)
        plate.line(tip, medium)
        // The chronograph hand: solid ink, running on, a counterweight behind the arbor.
        let hand = profile([(-0.24, 0.034), (-0.12, 0.028), (0.0, 0.044), (0.12, 0.05), (0.66, 0.026), (0.9, 0.0)],
                           at: o, toward: running)
        plate.line(hand, 0.026, .bone)
        Kit.mass(&plate, hand)
        plate.line([polar(o, 0.22, running), polar(o, 0.68, running)], fine, .bone)
        Kit.mass(&plate, arc(o, 0.075))
        plate.line(arc(o, 0.05), medium, .bone)

        callout(&plate, "A", from: polar(o, 0.8, stopped), to: polar(o, 0.87, Kit.clock(0.45)))
        callout(&plate, "B", from: polar(o, 0.82, running), to: polar(o, 0.87, Kit.clock(3.6)))
        callout(&plate, "C", from: window + polar(o, 0.24, 3.3) - o, to: polar(o, 0.76, Kit.clock(7)))
        callout(&plate, "D", from: polar(o, 0.82, Kit.clock(9.3)), to: P(-0.64, 0))
        return plate
    }

    /// Problem 41, Flyback, hex, clocks 1+,2+.
    static func plate41() -> Plate? { nil }

    /// Problem 42, Tachymeter, hex, clocks 1+,3+.
    static func plate42() -> Plate? { nil }
}
