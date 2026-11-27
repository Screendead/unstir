// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: fungi on a woodland floor: a parasol tilted to show its gills, a spotted fly agaric and its button, a
/// honeycombed morel, a puffball smoking spores, a seven-rayed earthstar and shaggy inkcaps dripping ink, over moss,
/// leaf litter and the mycelium's threads, with leaves falling.
enum Fungi {
    typealias Line = Engraving.Line
    private typealias E = Engraving
    private typealias P = SIMD2<Double>

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4655_4E47)
        var s = Sheet()
        // Nearest first: each specimen hides what is drawn after it.
        earthstar(&s, &rng, at: P(0.25, 0.62))
        let pore = puffball(&s, &rng, at: P(-0.15, 0.55))
        cloud(&s, &rng, from: pore)
        morel(&s, &rng, top: P(-0.64, 0.15), foot: P(-0.6, 0.7))
        button(&s, at: P(0.73, 0.5))
        toadstool(&s, &rng)
        parasol(&s, &rng)
        log(&s, &rng, end: P(0.12, 0.345), toward: P(1.1, 0.27), radius: 0.085)
        inkcap(&s, &rng, top: P(0.16, -0.8), height: 0.4, width: 0.085, flare: 0.1, ink: 0, foot: P(0.2, 0.32))
        inkcap(&s, &rng, top: P(0.42, -0.6), height: 0.3, width: 0.095, flare: 0.6, ink: 1, foot: P(0.44, 0.3))
        inkcap(&s, &rng, top: P(0.7, -0.42), height: 0.18, width: 0.055, flare: 0, ink: 0, foot: P(0.7, 0.27))
        ground(&s, &rng)
        sky(&s, &rng)
        return s.lines
    }()

    /// The lines drawn so far and the outlines of what stands in front, which hide any later line passing behind.
    private struct Sheet {
        var lines: [Line] = []
        var hulls: [(lo: P, hi: P, poly: [P])] = []

        mutating func hide(_ poly: [P]) {
            hulls.append((poly.reduce(poly[0], simd_min), poly.reduce(poly[0], simd_max), poly))
        }

        func hidden(_ p: P) -> Bool {
            hulls.contains { p.x >= $0.lo.x && p.y >= $0.lo.y && p.x <= $0.hi.x && p.y <= $0.hi.y && Fungi.inside(p, $0.poly) }
        }

        mutating func draw(_ points: [P], _ width: Double, avoiding extra: [[P]] = []) {
            var run: [P] = []
            for p in points {
                if hidden(p) || extra.contains(where: { Fungi.inside(p, $0) }) {
                    if run.count > 1 { lines.append(Line(points: run, width: width)) }
                    run = []
                } else {
                    run.append(p)
                }
            }
            if run.count > 1 { lines.append(Line(points: run, width: width)) }
        }
    }

    private static func inside(_ p: P, _ poly: [P]) -> Bool {
        var odd = false
        var j = poly.count - 1
        for i in poly.indices {
            let a = poly[i], b = poly[j]
            if (a.y > p.y) != (b.y > p.y), p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { odd.toggle() }
            j = i
        }
        return odd
    }

    private static func lerp(_ a: P, _ b: P, _ t: Double) -> P { a + (b - a) * t }

    /// A teardrop hanging from `top`, its bulb about `r` across, pointing along `u`.
    private static func drop(_ top: P, _ r: Double, _ u: P) -> [P] {
        let v = P(-u.y, u.x)
        return (0...20).map { i in
            let t = 2 * .pi * Double(i) / 20, bulb = 1 - cos(t)
            return top + r * (1.3 * bulb * u + 0.9 * sin(t) * (0.5 + 0.25 * bulb) * v)
        }
    }

    // MARK: Caps

    /// A cap: its rim's centre on screen, radius and dome height, its profile from the centre (0) to the rim (1), and
    /// the eye's elevation over the rim's plane, negative when it looks up at the gills.
    private struct Cap {
        var c: P, a: Double, h: Double, beta: Double, shape: (Double) -> Double

        func height(_ rho: Double) -> Double { h * shape(min(max(rho, 0), 1)) }

        func point(_ rho: Double, _ phi: Double, lift: Double? = nil) -> P {
            let x = a * rho * cos(phi), y = a * rho * sin(phi), z = lift ?? height(rho)
            return c + P(x, y * sin(beta) - z * cos(beta))
        }

        /// Whether the dome's surface at (rho, phi) turns towards the eye.
        func faces(_ rho: Double, _ phi: Double) -> Bool {
            let d = 0.01, slope = (height(rho + d) - height(rho - d)) / (2 * d * a)
            return -slope * sin(phi) * cos(beta) + sin(beta) > 0.03
        }

        /// The dome's silhouette, left to right, then back along the rim's near edge from above or far edge from below.
        var outline: [P] {
            var top: [P] = [], rim: [P] = []
            for i in 0...90 {
                let xi = -1 + 2 * Double(i) / 90, m = sqrt(max(0, 1 - xi * xi))
                var best = point(1, atan2(0, xi))
                for j in 0...40 {
                    let eta = -m + 2 * m * Double(j) / 40
                    let p = point(min(1, sqrt(xi * xi + eta * eta)), atan2(eta, xi))
                    if p.y < best.y { best = p }
                }
                top.append(best)
                rim.append(point(1, atan2(beta > 0 ? m : -m, xi), lift: 0))
            }
            return top + rim.reversed()
        }
    }

    // MARK: Specimens

    /// An earthstar: its spore sac raised on seven splitting rays that arch down to the ground, the inner layer cracked.
    private static func earthstar(_ s: inout Sheet, _ rng: inout SplitMix64, at c: P) {
        let tilt = 0.36, r0 = 0.05
        func flat(_ r: Double, _ phi: Double, lift: Double) -> P { c + P(r * cos(phi), tilt * r * sin(phi) - lift) }
        let sac = c + P(0, -0.075), sacR = 0.062
        let body = E.circle(sac, sacR, 70)
        s.draw(body, E.medium)
        // The peristome: a fringed beak with the pore at its tip.
        let tip = sac + P(0.006, -sacR - 0.032)
        let beakL = sac + P(-0.02, -sacR * 0.94), beakR = sac + P(0.022, -sacR * 0.93)
        s.draw(E.curve(beakL, sac + P(-0.006, -sacR - 0.012), tip, 10) + E.curve(tip, sac + P(0.02, -sacR - 0.01), beakR, 10).dropFirst(), E.fine)
        for k in 0..<11 {
            let t = Double(k) / 10, base = lerp(beakL, tip, 0.15 + 0.7 * t), side = lerp(beakR, tip, 0.15 + 0.7 * t)
            s.draw([base, lerp(base, side, 0.45) + P(0, -0.004)], E.fine)
        }
        // Shading on the sac's lower right.
        for k in 1...4 {
            let off = 0.011 * Double(k)
            s.draw(E.arc(sac + P(-off, -off * 0.8), sacR - 0.004 * Double(k) + off * 0.9, from: -0.4 + 0.15 * Double(k), to: 2.0 - 0.1 * Double(k), 24), E.fine)
        }
        // The saucer the sac sits in.
        s.draw((0...30).map { flat(0.075, .pi * Double($0) / 30, lift: 0.055) }, E.medium)
        s.hide(body)
        let phase = Double.random(in: 0..<(2 * .pi), using: &rng)
        var rays: [[P]] = []
        for k in 0..<7 {
            let phi = phase + 2 * .pi * (Double(k) + .random(in: -0.12..<0.12, using: &rng)) / 7
            let length = Double.random(in: 0.19..<0.25, using: &rng), half = .pi / 7 * 0.9
            func at(_ t: Double, _ side: Double, _ inset: Double = 1) -> P {
                let r = r0 + (length - r0) * t, hw = half * inset * (1 - pow(t, 0.8)) * (1 + 0.3 * sin(.pi * t))
                return flat(r, phi + side * hw, lift: 0.065 * (1 - t) * (1 - t) - 0.022 * pow(t, 4))
            }
            let edgeUp: [P] = (0...30).map { (i: Int) -> P in at(Double(i) / 30, -1) }
            let edgeDown: [P] = (0...30).reversed().map { (i: Int) -> P in at(Double(i) / 30, 1) }
            let edge: [P] = edgeUp + edgeDown
            rays.append(edge)
            s.draw(edge, E.medium)
            let inner0: [P] = (3...26).map { (i: Int) -> P in at(Double(i) / 30, -1, 0.62) }
            let inner1: [P] = (3...26).reversed().map { (i: Int) -> P in at(Double(i) / 30, 1, 0.62) }
            s.draw(inner0 + inner1, E.fine)
            // Cracks across the inner layer.
            for t in [0.3, 0.48, 0.66].map({ $0 + .random(in: -0.04..<0.04, using: &rng) }) {
                s.draw([at(t, -1, 0.55), at(t + 0.03, -0.1, 0.55), at(t - 0.01, 0.6, 0.55)], E.fine)
            }
        }
        for ray in rays { s.hide(ray) }
    }

    /// A puffball: a pear of warty skin narrowing to a pleated foot, its torn pore at the top. Returns the pore.
    private static func puffball(_ s: inout Sheet, _ rng: inout SplitMix64, at c: P) -> P {
        let r = 0.105, ground = c.y + 0.16
        let head = E.arc(c, r, from: 0.78 * .pi, to: 2.22 * .pi, 80)
        let footR = P(c.x + 0.045, ground), footL = P(c.x - 0.05, ground)
        let right = E.curve(head.last!, c + P(0.05, 0.12), footR, 16)
        let left = E.curve(footL, c + P(-0.055, 0.12), head[0], 16)
        let outline = head + right.dropFirst() + left.dropFirst()
        s.draw(outline, E.heavy)
        // Pleats in the foot.
        for k in 0..<5 {
            let x = -0.032 + 0.016 * Double(k) + .random(in: -0.004..<0.004, using: &rng)
            s.draw(E.curve(c + P(1.6 * x, 0.085), c + P(1.1 * x + 0.004, 0.12), P(c.x + 1.05 * x, ground - 0.004), 8), E.fine)
        }
        // The torn pore.
        let pore = c + P(0.012, -r + 0.004)
        s.draw((0...13).map { i in
            let t = 2 * .pi * Double(i) / 13, j = i == 13 ? 1 : (i % 3 == 0 ? 0.6 : 1)
            return pore + j * P(0.02 * cos(t), 0.007 * sin(t))
        }, E.medium)
        // Warts over the head: cones seen end on in the middle, in profile towards the edge.
        let golden = Double.pi * (3 - sqrt(5)), count = 130
        for i in 0..<count {
            let y = 1 - 2 * (Double(i) + 0.5) / Double(count), w = sqrt(1 - y * y), a = golden * Double(i)
            let q = SIMD3(w * cos(a), y, w * sin(a))
            guard q.z > 0.1, q.y < 0.62, q.y > -0.88 else { continue }
            let at = c + 0.93 * r * P(q.x, q.y)
            if q.z > 0.75 {
                s.draw(E.circle(at, 0.0045, 8), E.fine)
            } else {
                let out = simd_normalize(P(q.x, q.y)), side = P(-out.y, out.x)
                let len = 0.013 * (1 - q.z) + 0.004
                s.draw([at - 0.004 * side, at + len * out, at + 0.004 * side], E.fine)
            }
        }
        // Shading round the lower right.
        for k in 1...3 {
            s.draw(E.arc(c + P(-0.012, -0.012) * Double(k), r + 0.007 * Double(k), from: 0.1, to: 1.6, 20), E.fine)
        }
        s.hide(outline)
        return pore
    }

    /// The puffball's cloud: spores puffed up from the pore in curling streams and billows that thin as they rise.
    private static func cloud(_ s: inout Sheet, _ rng: inout SplitMix64, from pore: P) {
        let rise = 0.5
        func axis(_ t: Double) -> P { pore + P(0.16 * t * t + 0.03 * sin(3 * t), -rise * t) }
        func spread(_ t: Double) -> Double { 0.012 + 0.17 * pow(t, 0.85) }
        for _ in 0..<150 {
            let t = pow(Double.random(in: 0..<1, using: &rng), 0.9), x = Double.random(in: -1..<1, using: &rng)
            let p = axis(t) + P(spread(t) * x, 0.04 * Double.random(in: -1..<1, using: &rng))
            s.draw(E.circle(p, Double.random(in: 0.0022..<0.0038, using: &rng), 6), E.fine)
        }
        for k in 0..<5 {
            let off = -0.8 + 0.4 * Double(k) + .random(in: -0.1..<0.1, using: &rng)
            let end = Double.random(in: 0.55..<0.95, using: &rng), ph = Double.random(in: 0..<(2 * .pi), using: &rng)
            var path = (0...50).map { i -> P in
                let t = end * Double(i) / 50
                return axis(t) + P(spread(t) * off + 0.02 * t * sin(9 * t + ph), 0)
            }
            // A curl at the end, turning away from the plume's middle.
            let last = path.last!, turn = off < 0 ? -1.0 : 1.0, curl = 0.03 * end
            let centre = last + P(turn * curl, 0)
            path += (1...30).map { i in
                let a = Double(i) / 30 * 1.6 * .pi, rr = curl * (1 - 0.55 * Double(i) / 30)
                return centre + rr * P(-turn * cos(turn * a), -sin(turn * a))
            }
            s.draw(path, E.fine)
        }
        // Billows: puffs round the plume's head and down its flanks, each the outer arc of a round.
        for (t, count, size) in [(0.92, 7, 0.034), (0.62, 2, 0.026), (0.38, 2, 0.02)] {
            let c = axis(t), spanR = spread(t) * 0.95
            for b in 0..<count {
                let a: Double
                if count == 2 { a = b == 0 ? .pi * 1.02 : -0.02 } else { a = .pi + .pi * (Double(b) + 0.5) / Double(count) }
                let at = c + P(spanR * cos(a), 0.6 * spanR * sin(a)), r = size * Double.random(in: 0.8..<1.2, using: &rng)
                s.draw(E.arc(at, r, from: a - 1.5, to: a + 1.5, 16), E.fine)
            }
        }
    }

    /// A morel: a ridged cone of pits on a pale hollow stem.
    private static func morel(_ s: inout Sheet, _ rng: inout SplitMix64, top: P, foot: P) {
        let height = 0.3, wide = 0.1
        func w(_ v: Double) -> Double {
            wide * pow(sin(.pi / 2 * min(1, v / 0.75)), 1.1) * (1 - 0.06 * max(0, v - 0.75) / 0.25) + 0.004
        }
        func f(_ theta: Double, _ v: Double) -> P {
            P(top.x + 0.03 * v + w(v) * sin(theta), top.y + height * v + 0.2 * w(v) * cos(theta))
        }
        let neck = 0.72 * w(1), base = f(0, 1)
        let sideL: [P] = (0...40).map { f(-Double.pi / 2, 1 - Double($0) / 40) }
        let sideR: [P] = (0...40).map { f(Double.pi / 2, Double($0) / 40) }
        let hem: [P] = (0...30).map { f(Double.pi / 2 - Double.pi * Double($0) / 30, 1) }
        let outline = sideL + sideR + hem
        s.draw(outline, E.heavy)
        let n = 11, phase = Double.random(in: 0..<(2 * .pi), using: &rng)
        let wobble = (0..<n).map { _ in (Double.random(in: 0..<(2 * .pi), using: &rng), Double.random(in: 0..<(2 * .pi), using: &rng)) }
        func ridge(_ k: Int, _ v: Double) -> Double {
            let (a, b) = wobble[(k % n + n) % n]
            return phase + 2 * .pi * Double(k) / Double(n) + 0.16 * sin(5 * v + a) + 0.08 * sin(11 * v + b)
        }
        func seen(_ theta: Double) -> Bool { cos(theta) > 0.02 }
        for k in 0..<n {
            var run: [P] = []
            for i in 0...60 {
                let v = 0.04 + 0.96 * Double(i) / 60, th = ridge(k, v)
                if seen(th) { run.append(f(th, v)) } else {
                    if run.count > 1 { s.draw(run, E.medium) }
                    run = []
                }
            }
            if run.count > 1 { s.draw(run, E.medium) }
        }
        for k in 0..<n {
            var v = Double.random(in: 0.06..<0.14, using: &rng), prev = 0.04
            var rungs: [(Double, Double)] = []
            while v < 0.95 {
                rungs.append((v, v + .random(in: -0.06..<0.06, using: &rng)))
                v += .random(in: 0.09..<0.18, using: &rng)
            }
            rungs.append((1, 1))
            for (a, b) in rungs {
                let mid = (ridge(k, a) + ridge(k + 1, b)) / 2
                if seen(mid), a < 1 {
                    s.draw((0...10).map { i in
                        let t = Double(i) / 10
                        return f(ridge(k, a) * (1 - t) + ridge(k + 1, b) * t, a * (1 - t) + b * t + 0.015 * sin(.pi * t))
                    }, E.medium)
                }
                // The pit above this rung: its shadowed upper and left walls.
                let top = prev, bot = min(a, b)
                let cl = ridge(k, (top + bot) / 2), cr = ridge(k + 1, (top + bot) / 2), cm = (cl + cr) / 2
                if cos(cm) > 0.3, bot - top > 0.05 {
                    let l = cl + 0.22 * (cr - cl), r = cr - 0.25 * (cr - cl)
                    let v0 = top + 0.25 * (bot - top), v1 = bot - 0.2 * (bot - top)
                    let down: [P] = (0...6).map { (i: Int) -> P in f(l, v1 - (v1 - v0) * Double(i) / 6) }
                    let across: [P] = (1...6).map { (i: Int) -> P in
                        let u: Double = Double(i) / 6
                        return f(l + (r - l) * u, v0 + 0.01 * sin(.pi * u))
                    }
                    s.draw(down + across, E.fine)
                }
                prev = max(a, b)
            }
        }
        s.hide(outline)
        // The stem, pale and granular, under the cap's rim.
        let stemR = E.curve(base + P(neck, -0.01), P(base.x + neck + 0.004, (base.y + foot.y) / 2), foot + P(0.07, 0), 12)
        let stemL = E.curve(foot + P(-0.065, 0), P(base.x - neck - 0.01, (base.y + foot.y) / 2), base + P(-neck, -0.01), 12)
        s.draw(stemR, E.heavy)
        s.draw(stemL, E.heavy)
        for _ in 0..<16 {
            let t = Double.random(in: 0.15..<0.9, using: &rng), x = Double.random(in: -0.7..<0.7, using: &rng)
            let p = lerp(base, foot, t) + P(x * (neck + 0.03 * t), 0)
            s.draw([p, p + P(0.004, 0.008)], E.fine)
        }
        for k in 1...3 {
            let x = neck * (1 - 0.18 * Double(k))
            s.draw(E.curve(base + P(x, 0.02), P(base.x + x + 0.004, (base.y + foot.y) / 2), foot + P(0.07 * (1 - 0.15 * Double(k)), -0.012), 10), E.fine)
        }
        s.hide(stemR + stemL)
    }

    /// A young fly agaric still in its egg, the cap's spots showing above the torn cup.
    private static func button(_ s: inout Sheet, at c: P) {
        let egg = (0...48).map { i -> P in
            let t = 2 * .pi * Double(i) / 48
            return c + P(0.052 * cos(t), (sin(t) < 0 ? 0.068 : 0.058) * sin(t))
        }
        s.draw(egg, E.medium)
        // The cup's torn lip across the lower half, and its folds.
        let lip = (0...16).map { i -> P in
            let t = Double(i) / 16, x = -0.051 + 0.102 * t
            return c + P(x, 0.012 - 0.014 * sin(.pi * t) + 0.004 * sin(23 * t))
        }
        s.draw(lip, E.fine)
        for k in 0..<5 {
            let p = lip[2 + 3 * k]
            s.draw(E.curve(p + P(0, 0.008), p + P(0.003, 0.025), p + P(0.002 * Double(k - 2), 0.04), 6), E.fine)
        }
        for (dx, dy, r) in [(-0.02, -0.042, 0.009), (0.014, -0.05, 0.008), (0.03, -0.024, 0.007), (-0.035, -0.018, 0.006), (0.0, -0.022, 0.006)] {
            s.draw((0...6).map { i in
                let t = 2 * .pi * Double(i % 6) / 6
                return c + P(dx, dy) + r * P(cos(t), 0.7 * sin(t)) * (i % 2 == 0 ? 1 : 0.8)
            }, E.fine)
        }
        s.hide(egg)
    }

    /// The fly agaric: a domed cap flecked with warts, a skirt on its stem and a bulb ringed with the egg's scales.
    private static func toadstool(_ s: inout Sheet, _ rng: inout SplitMix64) {
        let cap = Cap(c: P(0.53, 0.1), a: 0.25, h: 0.2, beta: 0.3) { pow(max(0, 1 - $0 * $0), 0.55) }
        let outline = cap.outline
        s.draw(outline, E.heavy)
        // The rim's thickness, the gills' edges glimpsed under it.
        let under = (0...60).map { cap.point(1, .pi * Double($0) / 60, lift: -0.016) }
        s.draw(under, E.fine)
        for k in 0..<41 {
            let phi = .pi * (Double(k) + 0.5) / 41
            s.draw([cap.point(1, phi, lift: -0.003), cap.point(0.985, phi, lift: -0.015)], E.fine)
        }
        // Warts: patches on the dome, foreshortened as they turn away.
        var spots: [[P]] = [], centres: [P] = []
        for _ in 0..<400 where spots.count < 30 {
            let rho = sqrt(Double.random(in: 0..<0.9, using: &rng)), phi = Double.random(in: 0..<(2 * .pi), using: &rng)
            let flat = P(rho * cos(phi), rho * sin(phi)), size = Double.random(in: 0.06..<0.1, using: &rng)
            guard cap.faces(rho, phi), !centres.contains(where: { simd_distance($0, flat) < 0.11 + size }) else { continue }
            let sides = 5 + rng.below(3)
            let poly = (0...sides).map { i -> P in
                let t = 2 * .pi * Double(i % sides) / Double(sides), k = Double.random(in: 0.7..<1.15, using: &rng)
                let q = flat + size * k * P(cos(t), sin(t))
                return cap.point(min(simd_length(q), 1), atan2(q.y, q.x))
            }
            guard poly.allSatisfy({ inside($0, outline) }) else { continue }
            centres.append(flat)
            spots.append(poly)
            s.draw(poly, E.fine)
        }
        // Contours round the dome, broken by the warts.
        for rho in [0.22, 0.4, 0.56, 0.7, 0.82, 0.92] {
            var run: [P] = []
            for i in 0...160 {
                let phi = 2 * .pi * Double(i) / 160
                if cap.faces(rho, phi) { run.append(cap.point(rho, phi)) } else {
                    if run.count > 1 { s.draw(run, E.fine, avoiding: spots) }
                    run = []
                }
            }
            if run.count > 1 { s.draw(run, E.fine, avoiding: spots) }
        }
        s.hide(outline + under.reversed())
        stem(&s, top: cap.c + P(0, 0.01), foot: P(0.56, 0.64), half: 0.03, bulb: 0.06, ring: 0.24)
    }

    /// The fly agaric's stem: a hanging skirt and a bulb ringed with scales.
    private static func stem(_ s: inout Sheet, top: P, foot: P, half: Double, bulb: Double, ring: Double) {
        func x(_ t: Double, _ side: Double) -> P {
            let u = max(0, (t - 0.72) / 0.28)
            let w = half * (0.85 + 0.25 * t) + bulb * pow(u, 1.5) * sin(.pi * min(1, u * 0.75 + 0.25))
            return lerp(top, foot, t) + P(side * w + 0.012 * sin(.pi * t), 0)
        }
        let left = (0...50).map { x(Double($0) / 50, -1) }, right = (0...50).map { x(Double($0) / 50, 1) }
        s.draw(left, E.heavy)
        s.draw(right, E.heavy)
        for k in 1...3 {
            s.draw((5...45).map { i in lerp(x(Double(i) / 50, 1), x(Double(i) / 50, -1), 0.1 * Double(k)) }, E.fine)
        }
        // Scales of the volva in broken rings round the bulb.
        for k in 0..<3 {
            let t = 0.8 + 0.06 * Double(k), l = x(t, -1), r = x(t, 1)
            let n = 6 + k
            for j in 0..<n {
                let a = Double(j) / Double(n), b = (Double(j) + 0.7) / Double(n)
                let p = lerp(l, r, a) + P(0, 0.012 * sin(.pi * a)), q = lerp(l, r, b) + P(0, 0.012 * sin(.pi * b))
                s.draw(E.curve(p, (p + q) / 2 + P(0, 0.012), q, 6), E.fine)
            }
        }
        // The skirt: hung from the stem and flaring, its hem in folds.
        let l = x(ring, -1), r = x(ring, 1)
        let hem = (0...28).map { i -> P in
            let t = Double(i) / 28
            return lerp(l + P(-0.028, 0.05), r + P(0.028, 0.05), t) + P(0, 0.018 * sin(.pi * t) + 0.004 * sin(19 * t))
        }
        s.draw([l] + E.curve(l, l + P(-0.022, 0.02), hem[0], 8).dropFirst(), E.medium)
        s.draw([r] + E.curve(r, r + P(0.022, 0.02), hem.last!, 8).dropFirst(), E.medium)
        s.draw(hem, E.medium)
        s.draw(E.curve(l, (l + r) / 2 + P(0, 0.016), r, 10), E.fine)
        for k in 0..<7 {
            let t = (Double(k) + 0.5) / 7
            s.draw(E.curve(lerp(l, r, t) + P(0, 0.01), lerp(l, r, t) + P(0.006 * (t - 0.5), 0.03), hem[Int(t * 28)], 6), E.fine)
        }
        s.hide(left + right.reversed())
    }

    /// The parasol, seen from below its rim: scaled dome and umbo, the gills fanning from a collar round the stem's
    /// top, and a snakeskin stem with its double ring.
    private static func parasol(_ s: inout Sheet, _ rng: inout SplitMix64) {
        let cap = Cap(c: P(-0.38, -0.13), a: 0.31, h: 0.19, beta: -0.3) { rho in
            pow(max(0, 1 - pow(rho, 1.8)), 0.8) + 0.18 * exp(-rho * rho / 0.02)
        }
        let outline = cap.outline
        let foot = P(-0.36, 0.7)
        // The stem first, so the gills behind it are hidden.
        let top = cap.c, half = 0.022
        func at(_ t: Double, _ side: Double) -> P {
            let w = half * (1 + 0.15 * t) + 0.03 * pow(max(0, (t - 0.86) / 0.14), 2)
            return lerp(top, foot, t) + P(side * w - 0.015 * sin(.pi * t), 0)
        }
        let left = (0...60).map { at(Double($0) / 60, -1) }, right = (0...60).map { at(Double($0) / 60, 1) }
        s.draw(left, E.heavy)
        s.draw(right, E.heavy)
        // The snakeskin: zigzag bands down the stem.
        var t = 0.32
        while t < 0.86 {
            let l = at(t, -1), r = at(t, 1)
            let rung: [P] = (0...5).map { (i: Int) -> P in
                let jog: Double = i % 2 == 0 ? 0 : 0.012
                return lerp(l, r, Double(i) / 5) + P(0, jog)
            }
            s.draw(rung, E.fine)
            t += Double.random(in: 0.045..<0.07, using: &rng)
        }
        // The double ring.
        let rl = at(0.2, -1), rr = at(0.2, 1)
        let ringTop = (0...20).map { i in lerp(rl + P(-0.02, 0), rr + P(0.02, 0), Double(i) / 20) + P(0, 0.012 * sin(.pi * Double(i) / 20)) }
        let ringBot = ringTop.map { $0 + P(0, 0.024) }
        s.draw(ringTop, E.medium)
        s.draw(ringBot, E.medium)
        s.draw([ringTop[0], ringBot[0]], E.medium)
        s.draw([ringTop.last!, ringBot.last!], E.medium)
        s.draw(ringTop.map { $0 + P(0, 0.008) }, E.fine)
        s.hide(left + right.reversed())
        s.hide(ringTop + ringBot.reversed())
        // The gills: long ones from the collar, shorter ones between them from halfway.
        s.draw((0...40).map { cap.point(0.13, 2 * .pi * Double($0) / 40, lift: 0) }, E.medium)
        let gills = 31, ph = Double.random(in: 0..<1, using: &rng)
        for k in 0..<(2 * gills) {
            let phi = 2 * .pi * (Double(k) / 2 + ph) / Double(gills)
            let from = k % 2 == 0 ? 0.15 : (k % 4 == 1 ? 0.5 : 0.7)
            s.draw((0...20).map { cap.point(from + (0.985 - from) * Double($0) / 20, phi, lift: 0) }, E.fine)
        }
        s.draw((0...120).map { cap.point(1, 2 * .pi * Double($0) / 120, lift: 0) }, E.medium)
        // Scales on the dome in rings, and the dark umbo.
        for (j, rho) in [0.3, 0.44, 0.57, 0.69, 0.8, 0.9].enumerated() {
            var phi = Double(j % 2) * 0.1
            while phi < 2 * .pi {
                if cap.faces(rho, phi) {
                    let p = cap.point(rho, phi), q = cap.point(rho + 0.055, phi)
                    let tan = simd_normalize(cap.point(rho, phi + 0.01) - p) * 0.009
                    s.draw(E.curve(p - tan, q + (q - p) * 0.5, p + tan, 8), E.fine)
                }
                phi += 0.032 / (cap.a * rho) * Double.random(in: 0.85..<1.15, using: &rng)
            }
        }
        for rho in [0.1, 0.17] {
            s.draw((0...40).compactMap { i -> P? in
                let phi = 2 * .pi * Double(i) / 40
                return cap.faces(rho, phi) || rho < 0.12 ? cap.point(rho, phi) : nil
            }, rho < 0.12 ? E.fine : E.medium)
        }
        s.draw(Array(outline.prefix(91)), E.heavy)
        s.hide(outline)
    }

    /// A shaggy inkcap: a tall bell of upturned scales, its rim liquefying into ink that drips and falls.
    private static func inkcap(_ s: inout Sheet, _ rng: inout SplitMix64, top: P, height: Double, width: Double,
                               flare: Double, ink: Double, foot: P) {
        func w(_ v: Double) -> Double { width * pow(sin(.pi / 2 * min(1, v / 0.28)), 0.65) * (1 + flare * pow(v, 3)) }
        func f(_ theta: Double, _ v: Double) -> P { top + P(w(v) * sin(theta), height * v + 0.12 * w(v) * cos(theta)) }
        let ph = Double.random(in: 0..<(2 * .pi), using: &rng)
        func rim(_ theta: Double) -> P { f(theta, 1) + P(0, ink * 0.01 * abs(sin(7 * theta + ph))) }
        let sideL: [P] = (0...40).map { f(-Double.pi / 2, 1 - Double($0) / 40) }
        let sideR: [P] = (1...40).map { f(Double.pi / 2, Double($0) / 40) }
        let hem: [P] = (0...30).map { rim(Double.pi / 2 - Double.pi * Double($0) / 30) }
        let outline = sideL + sideR + hem
        s.draw(outline, E.medium)
        // The smooth cap at the tip.
        for v in [0.05, 0.1] {
            s.draw((0...16).map { f(-.pi / 2 + .pi * Double($0) / 16, v) }, E.fine)
        }
        var row = 0, v = 0.17
        while v < 0.93 {
            let n = max(4, Int(7 * width / 0.085 + 0.5))
            for i in 0..<n {
                let theta = -.pi / 2 + .pi * (Double(i) + (row % 2 == 0 ? 0.25 : 0.75) + .random(in: -0.1..<0.1, using: &rng)) / Double(n)
                let p = f(theta, v), outward = sin(theta) >= 0 ? 1.0 : -1.0
                let len = 0.022 * Double.random(in: 0.8..<1.2, using: &rng) * min(1, width / 0.07)
                let d = simd_normalize(P(0.5 * sin(theta), 1)) * len
                s.draw(E.curve(p, p + 0.7 * d, p + d + P(0.007 * outward, -0.005), 6), E.fine)
            }
            v += 0.085 * Double.random(in: 0.9..<1.1, using: &rng)
            row += 1
        }
        if ink > 0 {
            // Ink: the rim blackening upwards, drops hanging from it and falling.
            for k in 0..<9 {
                let theta = -1.3 + 2.6 * (Double(k) + 0.5) / 9
                let len = Double.random(in: 0.12..<0.24, using: &rng)
                s.draw((0...8).map { f(theta, 1 - len * Double($0) / 8) }, E.fine)
            }
            for theta in [-1.05, -0.25, 0.45, 1.15] {
                let r = rim(theta), hang = Double.random(in: 0.012..<0.03, using: &rng)
                s.draw([r, r + P(0, hang)], E.fine)
                s.draw(drop(r + P(0, hang), 0.006, P(0, 1)), E.fine)
            }
            for (theta, fall) in [(-0.7, 0.09), (0.1, 0.14), (0.8, 0.07), (-0.2, 0.22)] {
                s.draw(drop(rim(theta) + P(0, fall), 0.006, P(0, 1)), E.fine)
            }
        }
        s.hide(outline)
        // The stem, slender, with a loose ring.
        let start = f(0, 0.97), bow = P((start.x + foot.x) / 2 + 0.02, (start.y + foot.y) / 2)
        let spine = E.curve(start, bow, foot, 60)
        for side in [-1.0, 1.0] {
            s.draw(spine.enumerated().map { i, p in p + P(side * (0.016 + 0.006 * Double(i) / 60), 0) }, E.medium)
        }
        s.draw(spine.dropFirst(5).map { $0 + P(0.008, 0) }, E.fine)
        let ringAt = spine[8]
        s.draw(E.arc(ringAt, 0.024, from: 0.1, to: .pi - 0.1, 10).map { P($0.x, ringAt.y + ($0.y - ringAt.y) * 0.35) }, E.medium)
        s.hide(spine.map { $0 + P(-0.018, 0) } + spine.reversed().map { $0 + P(0.022, 0) })
    }

    /// A fallen log lying back into the glass, its cut end showing the rings and cracks, its bark furrowed and mossed.
    private static func log(_ s: inout Sheet, _ rng: inout SplitMix64, end: P, toward: P, radius r: Double) {
        let d = simd_normalize(toward - end), n = P(-d.y, d.x), length = simd_distance(end, toward)
        func edge(_ t: Double, _ side: Double) -> P {
            end + length * t * d + side * r * (1 + 0.04 * sin(17 * t + side)) * n
        }
        func face(_ a: Double, _ k: Double) -> P { end + k * r * (0.38 * cos(a) * d + sin(a) * n) }
        let top = (0...60).map { edge(Double($0) / 60, -1) }, bottom = (0...60).map { edge(Double($0) / 60, 1) }
        let rim = (0...60).map { face(.pi / 2 + .pi * Double($0) / 60, 1) }
        s.draw(top, E.heavy)
        s.draw(bottom, E.heavy)
        s.draw((0...60).map { face(2 * .pi * Double($0) / 60, 1) }, E.medium)
        // Rings about a heart off the centre, and the cracks of its drying.
        let heart = P(0.25, -0.2)
        for k in 1...5 {
            let f = Double(k) / 6
            s.draw((0...48).map { i in
                let a = 2 * .pi * Double(i) / 48
                return face(a, f * (1 + 0.06 * sin(3 * a + Double(k)))) + (1 - f) * r * (0.38 * heart.x * d + heart.y * n)
            }, E.fine)
        }
        for k in 0..<5 {
            let a = 2 * .pi * (Double(k) + .random(in: -0.2..<0.2, using: &rng)) / 5
            let c0 = end + r * (0.38 * heart.x * d + heart.y * n)
            s.draw([c0, lerp(c0, face(a, 0.95), 0.5) + 0.006 * n, face(a, 0.95)], E.fine)
        }
        // Bark: furrows along the log, broken, crowding towards its edges.
        for k in 0..<9 {
            let side = sin(.pi * (Double(k) + 0.5) / 9 - .pi / 2)
            var t = Double.random(in: 0.0..<0.06, using: &rng)
            while t < 1 {
                let len = Double.random(in: 0.06..<0.16, using: &rng)
                let furrow: [P] = (0...8).map { (i: Int) -> P in
                    let u: Double = t + len * Double(i) / 8
                    let along: P = (length * u) * d
                    let wobble: Double = 0.004 * sin(40 * u + Double(k))
                    let offset: Double = r * side + wobble
                    let across: P = offset * n
                    return end + along + across
                }
                s.draw(furrow.filter { simd_distance($0, end) > 0.05 }, E.fine)
                t += len + .random(in: 0.02..<0.05, using: &rng)
            }
        }
        // Moss along the top.
        var t = 0.08
        while t < 0.95 {
            let base = edge(t, -1)
            for _ in 0..<3 {
                let lean = Double.random(in: -0.5..<0.5, using: &rng)
                s.draw([base, base + Double.random(in: 0.018..<0.03, using: &rng) * E.dir(lean)], E.fine)
            }
            t += .random(in: 0.04..<0.08, using: &rng)
        }
        s.hide(top + bottom.reversed() + rim)
    }

    // MARK: Ground and air

    /// The woodland floor: its contours and hatching, moss with its capsules, fallen leaves, and the mycelium's
    /// threads under it all.
    private static func ground(_ s: inout Sheet, _ rng: inout SplitMix64) {
        func surface(_ x: Double) -> Double { 0.69 + 0.02 * sin(2.3 * x + 1) + 0.01 * sin(6.1 * x) }
        for k in 0..<4 {
            let y0 = 0.075 * Double(k)
            s.draw((0...80).map { i in
                let x = -1 + 2 * Double(i) / 80
                return P(x, surface(x) + y0 + 0.01 * sin(4.7 * x + 2 * Double(k)))
            }, k == 0 ? E.medium : E.fine)
        }
        // The bank the log lies on, rising behind the earthstar, its face hatched.
        func bank(_ x: Double) -> Double {
            let t = min(max((x + 0.1) / 0.4, 0), 1)
            return 0.69 - 0.26 * t * t * (3 - 2 * t) - 0.02 * max(0, x - 0.3) + 0.008 * sin(9 * x)
        }
        s.draw((0...60).map { i in
            let x = -0.1 + 1.14 * Double(i) / 60
            return P(x, bank(x))
        }, E.medium)
        var bx = 0.0
        while bx < 1.0 {
            let y0 = bank(bx) + 0.01, y1 = surface(bx) - 0.01
            if y1 - y0 > 0.04 {
                var y = y0 + .random(in: 0..<0.03, using: &rng)
                while y < y1 - 0.02 {
                    s.draw([P(bx, y), P(bx - 0.016, y + 0.024)], E.fine)
                    y += .random(in: 0.05..<0.1, using: &rng)
                }
            }
            bx += .random(in: 0.035..<0.06, using: &rng)
        }
        bx = 0.02
        while bx < 0.98 {
            let base = P(bx, bank(bx))
            for _ in 0..<3 {
                let lean = Double.random(in: -0.5..<0.5, using: &rng)
                s.draw([base, base + Double.random(in: 0.015..<0.03, using: &rng) * E.dir(lean)], E.fine)
            }
            bx += .random(in: 0.05..<0.1, using: &rng)
        }
        var x = -0.95
        while x < 0.95 {
            let y = surface(x) + 0.03 + .random(in: 0..<0.05, using: &rng)
            s.draw([P(x, y), P(x - 0.03, y + 0.05)], E.fine)
            x += .random(in: 0.03..<0.06, using: &rng)
        }
        // Moss: tufts of tiny leafy stems, a few with a capsule on a long seta.
        x = -0.92
        while x < 0.92 {
            let base = P(x, surface(x) + 0.004)
            for _ in 0..<3 {
                let lean = Double.random(in: -0.4..<0.4, using: &rng), len = Double.random(in: 0.025..<0.045, using: &rng)
                let tip = base + len * E.dir(lean)
                s.draw([base, tip], E.fine)
                for j in 1...3 {
                    let p = lerp(base, tip, Double(j) / 4)
                    s.draw([p + 0.008 * E.dir(lean - 0.9), p, p + 0.008 * E.dir(lean + 0.9)], E.fine)
                }
            }
            if rng.below(3) == 0 {
                let lean = Double.random(in: -0.3..<0.3, using: &rng), len = Double.random(in: 0.07..<0.12, using: &rng)
                let tip = base + len * E.dir(lean), bend = tip + 0.012 * E.dir(lean + 1.6)
                s.draw(E.curve(base, base + 0.7 * len * E.dir(lean), bend, 10), E.fine)
                let u = E.dir(lean + 2.1)
                s.draw((0...12).map { i in
                    let t = 2 * .pi * Double(i) / 12
                    return bend + u * 0.008 * (1 + cos(t)) + P(-u.y, u.x) * 0.0045 * sin(t)
                }, E.fine)
            }
            x += .random(in: 0.06..<0.12, using: &rng)
        }
        // Fallen leaves lying flat.
        for (c, heading, size, oak) in [(P(-0.8, 0.76), 1.9, 0.14, true), (P(-0.36, 0.83), -1.3, 0.12, false),
                                        (P(0.05, 0.8), 1.4, 0.13, true), (P(0.5, 0.78), -1.8, 0.14, false),
                                        (P(0.78, 0.66), 2.4, 0.1, true)] {
            leaf(&s, at: c, heading: heading, length: size, squash: 0.45, oak: oak)
        }
        // Mycelium: threads branching through the soil.
        for _ in 0..<14 {
            var p = P(Double.random(in: -0.8..<0.8, using: &rng), Double.random(in: 0.76..<0.84, using: &rng))
            var h = Double.random(in: 1.2..<1.9, using: &rng) * (rng.below(2) == 0 ? 1 : -1)
            var path = [p]
            for _ in 0..<40 {
                h += Double.random(in: -0.35..<0.35, using: &rng)
                p += 0.012 * E.dir(h)
                path.append(p)
                if rng.below(9) == 0 {
                    let b = h + (rng.below(2) == 0 ? 0.8 : -0.8)
                    s.draw((0...8).map { p + 0.009 * Double($0) * E.dir(b + 0.04 * Double($0)) }, E.fine)
                }
            }
            s.draw(path, E.fine)
        }
    }

    /// An oak leaf of seven rounded lobes, or a beech leaf, finely toothed, each veined and foreshortened by `squash`.
    private static func leaf(_ s: inout Sheet, at c: P, heading: Double, length: Double, squash: Double, oak: Bool) {
        let u = E.dir(heading), v = P(-u.y, u.x) * squash
        let base = c - 0.5 * length * u
        func at(_ t: Double, _ side: Double) -> P {
            let env = 0.34 * length * pow(sin(.pi * pow(t, 0.85)), 0.9)
            let lobe = oak ? 0.62 + 0.38 * pow(abs(sin(.pi * 3.5 * t)), 0.5) : 1 - 0.06 * abs(sin(.pi * 14 * t))
            return base + length * t * u + side * env * lobe * v
        }
        s.draw((0...70).map { at(Double($0) / 70, -1) } + (0...70).reversed().map { at(Double($0) / 70, 1) }, E.fine)
        s.draw([base - 0.15 * length * u, base + 0.95 * length * u], E.fine)
        let veins = oak ? 7 : 6
        for k in 0..<veins {
            let t = 0.12 + 0.78 * Double(k) / Double(veins)
            for side in oak ? [k % 2 == 0 ? 1.0 : -1.0] : [-1.0, 1.0] {
                let p = base + length * t * u, q = lerp(p, at(min(t + 0.1, 0.97), side), 0.9)
                s.draw(E.curve(p, lerp(p, q, 0.5) - 0.03 * length * u, q, 6), E.fine)
            }
        }
    }

    /// Leaves falling and spores adrift over the whole glass.
    private static func sky(_ s: inout Sheet, _ rng: inout SplitMix64) {
        for (c, heading, size, squash, oak) in [(P(-0.5, -0.62), 2.3, 0.22, 0.8, true), (P(-0.1, -0.8), -0.9, 0.16, 0.55, false),
                                               (P(0.5, -0.8), 0.7, 0.13, 0.65, false), (P(-0.82, -0.2), -2.5, 0.16, 0.7, false),
                                               (P(0.86, -0.18), 2.9, 0.13, 0.55, true), (P(-0.84, 0.3), 0.4, 0.14, 0.6, true),
                                               (P(-0.22, -0.52), -2.0, 0.12, 0.45, false)] {
            leaf(&s, at: c, heading: heading, length: size, squash: squash, oak: oak)
        }
        var placed = 0
        while placed < 130 {
            let p = P(Double.random(in: -1..<1, using: &rng), Double.random(in: -1..<0.6, using: &rng))
            guard simd_length(p) < 0.96 else { continue }
            placed += 1
            let a = Double.random(in: 0..<(2 * .pi), using: &rng), r = Double.random(in: 0.003..<0.006, using: &rng)
            s.draw((0...8).map { i in
                let t = 2 * .pi * Double(i) / 8
                return p + r * (cos(t) * P(cos(a), sin(a)) + 0.6 * sin(t) * P(-sin(a), cos(a)))
            }, E.fine)
        }
    }
}
