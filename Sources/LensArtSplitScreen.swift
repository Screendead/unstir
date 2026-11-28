// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 50 to 55, the chapter Split screen.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let splitScreen: [Int: Halftone.Panel] = [50: owl, 51: flyseye, 52: chameleon, 53: catseye, 54: eagleeye, 55: peacock]
}

private extension LensArt {
    /// The direction of d in degrees, 0 to 360, 0 at three o'clock and clockwise on screen.
    static func bearing(_ d: P) -> Double { (atan2(d.y, d.x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360) }

    /// Whether an odd number of `seams` lie before `degrees`: which of two tones a band takes there.
    static func odd(_ degrees: Double, _ seams: [Double]) -> Bool {
        var n = 0
        for seam in seams where seam < degrees { n += 1 }
        return n % 2 == 1
    }

    static func turned(_ v: P, _ degrees: Double) -> P {
        let t = degrees * .pi / 180
        return P(v.x * cos(t) - v.y * sin(t), v.x * sin(t) + v.y * cos(t))
    }

    /// A number in 0 to 1 that only the cell (i, j) gives.
    static func scatter(_ i: Int, _ j: Int) -> Double {
        let h = UInt64(bitPattern: Int64(i &* 73_856_093 ^ j &* 19_349_663)) &* 0x9E37_79B9_7F4A_7C15
        return Double(h >> 40) / Double(1 << 24)
    }

    /// A band `w0` wide at the line's start and `w1` at its end, as a polygon.
    static func ribbon(_ line: [P], _ w0: Double, _ w1: Double) -> [P] {
        var left: [P] = [], right: [P] = []
        for (i, p) in line.enumerated() {
            let a = line[max(i - 1, 0)], b = line[min(i + 1, line.count - 1)], u = simd_normalize(b - a)
            let w = (w0 + (w1 - w0) * Double(i) / Double(line.count - 1)) / 2
            left.append(p + P(-u.y, u.x) * w)
            right.append(p - P(-u.y, u.x) * w)
        }
        return left + right.reversed()
    }

    /// Moves the strokes from `start` on, a clue, straight out from its lens core's centre until it clears the knob
    /// there by 0.022, as a clue must, first drawing it `scale` its size about its middle.
    static func fit(_ s: inout [Halftone.Stroke], from start: Int, core: P, scale: Double = 1) {
        let drawn = s[start...].flatMap(\.points), g = drawn.reduce(P(0, 0), +) / Double(drawn.count)
        for i in start..<s.count { s[i].points = s[i].points.map { g + ($0 - g) * scale } }
        let points = s[start...].flatMap(\.points), u = simd_normalize(g - core)
        var shift = 0.0
        while points.contains(where: { simd_distance($0 + u * shift, core) < 0.022 }) { shift += 0.002 }
        for i in start..<s.count { s[i].points = s[i].points.map { $0 + u * shift } }
    }

    /// Strokes cut into runs of a few segments each: the bake tests every stroke whose box holds a pixel, segment by
    /// segment, so a long curve's wide box costs every pixel inside it.
    static func pieces(_ strokes: [Halftone.Stroke]) -> [Halftone.Stroke] {
        strokes.flatMap { stroke -> [Halftone.Stroke] in
            guard stroke.points.count > 17 else { return [stroke] }
            return stride(from: 0, to: stroke.points.count - 1, by: 16).map {
                Halftone.Stroke(points: Array(stroke.points[$0...min($0 + 16, stroke.points.count - 1)]), width: stroke.width)
            }
        }
    }
}

// MARK: - 50: Owl

/// Level 50's name: a horned owl on a branch over still water at night, face on, and its reflection under it, rippled
/// and gone cool in the pond. Its eyes are over the upper cores and the reflection's over the lower (hex's four lenses
/// on this level), each a ruff of feathers round an iris, and in each pupil what the eye has caught: a mouse, a bat,
/// and in the water's eyes a frog and a dragonfly.
extension LensArt {
    static let owl: Halftone.Panel = drawOwl()

    private static func drawOwl() -> Halftone.Panel {
        let eyes = [P(-0.485, -0.28), P(0.485, -0.28)], water = 0.0
        let iris = y(1), ruffA = y(0.45), ruffB = m(0.3)
        let body = m(0.6), sky = c(0.2), beakTone = y(0.75), branchTone = y(0.3)
        let beak = [P(-0.075, -0.19), P(0.075, -0.19), P(0.006, 0.0)]
        let tufts = [[P(-0.2, -0.7), P(-0.62, -0.62), P(-0.5, -0.95)], [P(0.2, -0.7), P(0.62, -0.62), P(0.46, -0.96)]]
        let brow = [P(-0.82, -0.56), P(-0.3, -0.66), P(0, -0.3), P(0.3, -0.66), P(0.82, -0.56), P(0.3, -0.58), P(0, -0.18), P(-0.3, -0.58)]
        let branch = bar(P(-1.05, -0.035), P(0.42, -0.005), 0.07)
        let feet = [P(-0.2, -0.045), P(0.16, -0.04)]
        let head = oval(P(0, -0.4), 0.9, 0.44, body)
        // The ruff's feathers, as the angles where each eye's tone changes, so a neighbour's twist slides a seam along.
        let seams: [[Double]] = [[10, 48, 70, 118, 150, 196, 222, 268, 300, 334], [-6, 30, 64, 96, 140, 172, 210, 250, 286, 318]]
        let fills = [fill(beak, beakTone)] + feet.map { oval($0, 0.075, 0.035, y(0.85)) } + [fill(branch, branchTone)]
            + tufts.map { fill($0, m(0.9)) } + [fill(brow, c(0.35))]

        // Lily pads on the pond, off the bottom rod's centre, each with its notch.
        let padAt = [(P(-0.3, 0.8), 0.15, 0.065, 70.0), (P(0.36, 0.64), 0.1, 0.045, 120.0), (P(0.12, 0.9), 0.08, 0.035, 300.0)]
        let pads = [disc(P(-0.24, 0.77), 0.03, m(0.85))] + padAt.map { oval($0.0, $0.1, $0.2, Tone(0.35, 0, 0.75)) }

        @Sendable func above(_ p: P) -> Tone {
            let k = p.x < 0 ? 0 : 1, d = p - eyes[k], r2 = simd_length_squared(d)
            if r2 < 0.1764 {
                if r2 < 0.0009 { return .zero }
                if r2 < 0.069696 { return iris }
                let a = bearing(d)
                if r2.squareRoot() < 0.4 + 0.022 * cos(a * 12 * .pi / 180) { return odd(a, seams[k]) ? ruffB : ruffA }
            }
            for f in fills where f.holds(p) { return f.tone }
            return head.holds(p) ? body : sky
        }

        var s: [Halftone.Stroke] = []
        // The head: outline, ear tufts, brow, beak, the ruffs' scalloped edges and their seams, and each eye's rim and
        // pupil with a catchlight.
        let crown = ellipse(P(0, -0.4), 0.9, 0.44, 96).filter { $0.y < water - 0.01 }
        s += runs(crown, bold) { !(abs($0.x) > 0.2 && abs($0.x) < 0.62 && $0.y < -0.6) }
        for t in tufts { s.append(stroke(t, bold)) }
        s.append(stroke(closed(brow), mid))
        s.append(stroke(closed(beak), bold))
        s.append(stroke([P(0, -0.17), P(0.004, -0.06)], hair))
        for (k, e) in eyes.enumerated() {
            s.append(stroke(closed((0..<96).map { i in
                let a = Double(i) * 3.75
                return polar(e, 0.4 + 0.022 * cos(a * 12 * .pi / 180), a)
            }), mid))
            for a in seams[k] { s.append(stroke([polar(e, 0.275, a), polar(e, 0.38, a + 6)], hair)) }
            s += runs(circle(e, 0.264, 64), bold) { simd_distance($0, polar(e, 0.264, k == 0 ? 130 : 50)) > 0.05 }
            s.append(stroke(circle(e, 0.03, 16), hair))
            s.append(stroke(arc(e, 0.2, 200, 250, 10), mid))
        }
        // The breast's feathers between the ruffs, and the feet on the branch.
        for (k, at) in [P(-0.16, -0.12), P(0.16, -0.12), P(-0.27, -0.04), P(0.28, -0.05), P(-0.06, -0.06)].enumerated() {
            let w = 0.04 + 0.006 * Double(k % 2)
            s.append(stroke([at + P(-w, -0.025), at, at + P(w, -0.025)], hair))
        }
        for f in feet {
            for dx in ([-0.05, 0.0, 0.05] as [Double]) { s.append(stroke([f + P(dx * 0.6, -0.01), f + P(dx, 0.04)], mid)) }
        }
        s.append(stroke(closed(branch), mid))
        s.append(stroke(curve(P(-0.62, -0.03), P(-0.7, -0.1), P(-0.84, -0.12), 8), mid))
        // The night: stars, a few with rays.
        for (k, at) in [P(-0.08, -0.9), P(0.72, -0.58), P(-0.76, -0.58), P(0.3, -0.9), P(0.86, -0.3), P(-0.9, -0.22)].enumerated() {
            if k == 0 { s += glint(at, 0.04, hair) } else { s.append(stroke(circle(at, 0.008, 6), mid)) }
        }
        // The waterline, and the reflection's outlines broken by ripples, which run across the pond.
        s.append(stroke([P(-1, water), P(1, water)], mid))
        let ripple = { (p: P) in sin(p.y * 2 * .pi / 0.09) > -0.55 }
        let mirrored = { (line: [P]) in line.map { P($0.x, 2 * water - $0.y) } }
        s += runs(mirrored(crown), mid, keep: ripple)
        for e in eyes.map({ P($0.x, 2 * water - $0.y) }) {
            s += runs(circle(e, 0.264, 64), mid, keep: ripple)
            s.append(stroke(circle(e, 0.03, 16), hair))
        }
        s += runs(mirrored(span(beak[0], beak[2], 16) + span(beak[2], beak[1], 16)), hair, keep: ripple)
        for t in tufts { s += runs(mirrored(span(t[1], t[2], 16) + span(t[2], t[0], 16)), hair, keep: ripple) }
        for (k, yy) in stride(from: 0.08, through: 0.95, by: 0.15).enumerated() {
            let half = (1 - yy * yy).squareRoot()
            s += runs(span(P(-half, yy), P(half, yy), 60)) { p in
                sin((p.x + 0.13 * Double(k)) * 2 * .pi / 0.5) > -0.3 && eyes.allSatisfy { simd_distance(p, P($0.x, -$0.y)) > 0.14 }
            }
        }

        for (c, rx, ry, notch) in padAt {
            s += runs(ellipse(c, rx, ry, 40), mid) { simd_distance(P(($0.x - c.x) / rx, ($0.y - c.y) / ry), polar(P(0, 0), 1, notch)) > 0.3 }
            s.append(stroke([c, c + P(rx * cos(notch * .pi / 180), ry * sin(notch * .pi / 180))], hair))
        }
        s += (0..<6).map { k in stroke([P(-0.24, 0.77), polar(P(-0.24, 0.77), 0.05, -150 + 24 * Double(k))], mid) }

        // What each eye has caught, in its pupil: a mouse; a bat; in the water, a frog and a dragonfly.
        var mark = s.count
        let mouse = eyes[0] + P(0.01, -0.03)
        s.append(stroke(ellipse(mouse, 0.03, 0.017, 20), 0.0036))
        s.append(stroke(circle(mouse + P(0.02, -0.018), 0.009, 10), 0.003))
        s.append(stroke(circle(mouse + P(0.024, -0.003), 0.0025, 6), 0.003))
        s.append(stroke(curve(mouse + P(-0.03, 0.004), mouse + P(-0.06, 0.03), mouse + P(-0.07, -0.01), 8), 0.0024))
        for dx in ([-0.015, 0.012] as [Double]) { s.append(stroke([mouse + P(dx, 0.016), mouse + P(dx - 0.004, 0.026)], 0.0024)) }
        fit(&s, from: mark, core: eyes[0])
        mark = s.count
        let bat = eyes[1] + P(0.0, -0.035)
        for side in ([-1.0, 1.0] as [Double]) {
            let w = { (x: Double, y: Double) in bat + P(side * x, y) }
            s.append(stroke(curve(w(0, 0), w(0.03, -0.03), w(0.07, -0.01), 8) + curve(w(0.07, -0.01), w(0.058, 0.006), w(0.05, 0.004), 4)
                + curve(w(0.05, 0.004), w(0.04, 0.016), w(0.028, 0.008), 4) + curve(w(0.028, 0.008), w(0.016, 0.018), w(0.008, 0.01), 4), 0.0034))
        }
        s.append(stroke([bat + P(-0.008, -0.004), bat + P(-0.006, -0.016), bat + P(0, -0.008), bat + P(0.006, -0.016), bat + P(0.008, -0.004)], 0.003))
        s.append(stroke(ellipse(bat + P(0, 0.004), 0.008, 0.012, 10), 0.003))
        fit(&s, from: mark, core: eyes[1])
        mark = s.count
        let frog = P(-0.485, 0.28) + P(0.01, 0.045)
        s.append(stroke(arc(frog, 0.032, 190, 350, 14) + [frog + P(0.032, 0.0), frog + P(-0.032, 0.0)], 0.0036))
        for dx in ([-0.018, 0.018] as [Double]) {
            s.append(stroke(circle(frog + P(dx, -0.026), 0.009, 10), 0.003))
            s.append(stroke(circle(frog + P(dx, -0.026), 0.002, 4), 0.003))
        }
        s.append(stroke(curve(frog + P(-0.02, -0.006), frog + P(0, 0.004), frog + P(0.02, -0.006), 6), 0.0024))
        for dx in ([-1.0, 1.0] as [Double]) { s.append(stroke([frog + P(0.026 * dx, 0.0), frog + P(0.04 * dx, 0.02), frog + P(0.05 * dx, 0.018)], 0.0024)) }
        fit(&s, from: mark, core: P(-0.485, 0.28))
        mark = s.count
        let fly = P(0.485, 0.28) + P(-0.01, 0.04)
        s.append(stroke([fly + P(-0.05, 0.03), fly + P(0.02, -0.012)], 0.0034))
        s.append(stroke(circle(fly + P(0.028, -0.017), 0.007, 8), 0.003))
        for (w, t) in [(0.05, -60.0), (0.046, -100), (0.044, 20), (0.04, 60)] {
            let root = fly + P(0.006, -0.004)
            s.append(stroke(ellipse(polar(root, w / 2, t - 30), w / 2, 0.008, degrees: t - 30, 14), 0.0024))
        }
        fit(&s, from: mark, core: P(0.485, 0.28))
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            guard p.y > water else { return above(p) }
            for f in pads where f.holds(p) { return f.tone }
            // Under the waterline, the owl again, mirrored, shaken sideways by the ripples, and gone cool.
            let q = P(p.x + 0.01 * sin(p.y * 2 * .pi / 0.09), 2 * water - p.y), t = above(q)
            return Tone(min(0.3 * t.x + 0.35 * t.y + 0.9 * t.z, 1), 0.6 * t.y, 0)
        }
        return Halftone.Panel(name: "owl", tones: tones, strokes: pieces(s))
    }
}

// MARK: - 51: Fly's eye

/// Level 51's name: a bluebottle's head face on at the hub, red eyes, feelers and mouth, set in its own compound eye
/// drawn huge round it, a honeycomb of facets; six facets, over the six ring cores (hex's six lenses on this level), are
/// each drawn whole in a colour of their own inside a hexagon's dark corners, and each shows the fly its piece of the
/// kitchen: a swatter coming, a spider, the window, a sugar cube, an apple core and the lamp.
extension LensArt {
    static let flyseye: Halftone.Panel = drawFlyseye()

    private static func drawFlyseye() -> Halftone.Panel {
        let facets = (0..<6).map { polar(P(0, 0), 0.56, -90 + 60 * Double($0)) }
        let cores: [Tone] = [y(0.95), c(0.75), y(0.6), c(0.5), y(0.8), c(0.95)]
        let head = P(0.015, -0.01), tilt = 12.0, red = m(0.95)
        let eyes = [(P(-0.13, -0.05), -14.0), (P(0.13, -0.05), 14.0)]
        let size = 0.11, root3 = 3.0.squareRoot(), bulge = 0.35
        /// The eye's dome: facets laid out evenly over it, so they crowd towards the rim of the glass.
        let dome: @Sendable (P) -> P = { p in p * (1 + bulge * simd_length_squared(p)) }
        let flat = { (q: P) -> P in
            let rho = simd_length(q)
            guard rho > 0 else { return q }
            var r = rho
            for _ in 0..<6 { r -= (r + bulge * r * r * r - rho) / (1 + 3 * bulge * r * r) }
            return q * (r / rho)
        }
        /// The fly's head, in its own frame turned `tilt` from the screen's.
        @Sendable func fly(_ p: P) -> Tone? {
            let q = turned(p - head, -tilt)
            for (at, t) in eyes {
                let e = turned(q - at, -t) / P(0.13, 0.17)
                if simd_length_squared(e) < 1 { return red }
            }
            for x in [-0.035, 0.035] where simd_length_squared((q - P(x, 0.06)) / P(0.025, 0.05)) < 1 { return y(0.85) }
            if abs(q.x) < 0.028 && q.y > 0.1 && q.y < 0.21 { return m(0.45) }
            if simd_length_squared((q - P(0, 0.215)) / P(0.07, 0.03)) < 1 { return m(0.75) }
            if simd_length_squared((q - P(0, 0.02)) / P(0.27, 0.235)) < 1 { return abs(q.x) < 0.045 && q.y < 0.1 ? y(0.35) : c(0.45) }
            return nil
        }
        /// Whether d lies inside a hexagon of circumradius r, corners at three and nine o'clock.
        @Sendable func hexagon(_ d: P, _ r: Double) -> Bool {
            let ri = r * root3 / 2
            return abs(d.y) < ri && abs(d.x * root3 / 2 + d.y * 0.5) < ri && abs(d.x * root3 / 2 - d.y * 0.5) < ri
        }

        var s: [Halftone.Stroke] = []
        // The compound eye's facets round about, each outlined.
        for b in -14...14 {
            for a in -14...14 {
                let middle = P(size * root3 * (Double(a) + Double(b) / 2), size * 1.5 * Double(b)), centre = flat(middle)
                guard simd_length(centre) < 1.02, simd_length(centre) > 0.34, facets.allSatisfy({ simd_distance(centre, $0) > 0.36 }) else { continue }
                s.append(stroke(closed((0..<6).map { flat(polar(middle, size - 0.016, 30 + 60 * Double($0))) }), hair))
            }
        }
        // The facets drawn whole: each hexagon, its round glass and a gleam on it.
        for (k, f) in facets.enumerated() {
            s.append(stroke(closed((0..<6).map { polar(f, 0.315, 60 * Double($0)) }), bold))
            s.append(stroke(circle(f, 0.264, 56), hair))
            s.append(stroke(arc(f, 0.225, 196 + 9 * Double(k), 236 + 9 * Double(k), 8), mid))
        }
        // The head: its capsule, the eyes and their gleams, the face's plate, feelers with their bristles, the mouth and
        // its pad, and bristles round the crown.
        let at = { (x: Double, y: Double) in head + turned(P(x, y), tilt) }
        let rim: [P] = (0..<40).map { (k: Int) -> P in
            let t: Double = Double(k) * .pi / 20
            return at(0.27 * cos(t), 0.02 + 0.235 * sin(t))
        }
        s.append(stroke(closed(rim), bold))
        for (c, t) in eyes {
            s.append(stroke(closed((0..<32).map { i -> P in
                let a = Double(i) * .pi / 16, e = turned(P(0.13 * cos(a), 0.17 * sin(a)), t) + c
                return at(e.x, e.y)
            }), mid))
            s.append(stroke((0...6).map { i -> P in
                let a = (200 + 10 * Double(i)) * .pi / 180, e = turned(P(0.09 * cos(a), 0.12 * sin(a)), t) + c
                return at(e.x, e.y)
            }, mid))
        }
        for x in ([-0.035, 0.035] as [Double]) {
            let nostril: [P] = (0..<16).map { (k: Int) -> P in
                let t: Double = Double(k) * .pi / 8
                return at(x + 0.025 * cos(t), 0.06 + 0.05 * sin(t))
            }
            s.append(stroke(closed(nostril), mid))
            s.append(stroke([at(x, 0.09), at(x * 2.2, 0.17)], hair))
        }
        s.append(stroke([at(-0.028, 0.1), at(-0.028, 0.2)], mid))
        s.append(stroke([at(0.028, 0.1), at(0.028, 0.2)], mid))
        let mouth: [P] = (0..<16).map { (k: Int) -> P in
            let t: Double = Double(k) * .pi / 8
            return at(0.07 * cos(t), 0.215 + 0.03 * sin(t))
        }
        s.append(stroke(closed(mouth), mid))
        for k in 0..<9 {
            let a = 200 + 17 * Double(k)
            s.append(stroke([at(0.27 * cos(a * .pi / 180), 0.02 + 0.235 * sin(a * .pi / 180)), at(0.33 * cos((a + 6) * .pi / 180), 0.02 + 0.29 * sin((a + 6) * .pi / 180))], hair))
        }

        // What each facet shows: a swatter, a spider, the window, a sugar cube, an apple core and the lamp.
        var mark = s.count
        let swat = facets[0] + P(0.045, -0.05)
        s.append(stroke(closed(squircle(swat, 0.028, 0.032, degrees: 20, 24)), 0.0036))
        for k in -1...1 {
            s.append(stroke([swat + turned(P(Double(k) * 0.012, -0.028), 20), swat + turned(P(Double(k) * 0.012, 0.028), 20)], 0.0016))
            s.append(stroke([swat + turned(P(-0.024, Double(k) * 0.012), 20), swat + turned(P(0.024, Double(k) * 0.012), 20)], 0.0016))
        }
        s.append(stroke([swat + turned(P(0, 0.032), 20), swat + turned(P(0, 0.09), 20)], 0.0034))
        fit(&s, from: mark, core: facets[0])
        mark = s.count
        let spider = facets[1] + P(-0.055, 0.035)
        s.append(stroke(circle(spider, 0.012, 12), 0.0036))
        s.append(stroke(circle(spider + P(0, -0.02), 0.007, 8), 0.0034))
        s.append(stroke([spider + P(0, -0.027), spider + P(0, -0.1)], 0.0016))
        for side in ([-1.0, 1.0] as [Double]) {
            for k in 0..<4 {
                let knee = spider + P(side * 0.03, -0.03 + 0.016 * Double(k))
                s.append(stroke([spider + P(side * 0.008, -0.006 + 0.005 * Double(k)), knee, knee + P(side * 0.012, 0.02)], 0.0024))
            }
        }
        fit(&s, from: mark, core: facets[1])
        mark = s.count
        let window = facets[2] + P(0.045, 0.045)
        s.append(stroke(closed(rect(window.x - 0.035, window.y - 0.045, window.x + 0.035, window.y + 0.04)), 0.0036))
        s.append(stroke([window + P(0, -0.045), window + P(0, 0.04)], 0.0024))
        s.append(stroke([window + P(-0.035, -0.005), window + P(0.035, -0.005)], 0.0024))
        s.append(stroke(curve(window + P(-0.035, -0.045), window + P(-0.05, 0.0), window + P(-0.06, 0.05), 8), 0.0024))
        s.append(stroke(circle(window + P(0.016, -0.026), 0.008, 8), 0.0016))
        fit(&s, from: mark, core: facets[2])
        mark = s.count
        let cube = facets[3] + P(-0.035, -0.045)
        let top = [cube + P(0, -0.03), cube + P(0.03, -0.015), cube, cube + P(-0.03, -0.015)]
        s.append(stroke(closed(top), 0.0036))
        s.append(stroke([top[3], top[3] + P(0, 0.034), cube + P(0, 0.05), top[1] + P(0, 0.034), top[1]], 0.0036))
        s.append(stroke([cube, cube + P(0, 0.05)], 0.0024))
        s += glint(cube + P(0.04, -0.04), 0.014, 0.0016)
        fit(&s, from: mark, core: facets[3])
        mark = s.count
        let apple = facets[4] + P(0.05, -0.05)
        let flesh: [P] = arc(apple + P(0, -0.026), 0.027, 180, 360, 12) + curve(apple + P(0.027, -0.026), apple + P(-0.004, 0), apple + P(0.027, 0.026), 8)
        s.append(stroke(flesh + arc(apple + P(0, 0.026), 0.027, 0, 180, 12) + curve(apple + P(-0.027, 0.026), apple + P(0.004, 0), apple + P(-0.027, -0.026), 8), 0.0036))
        s.append(stroke([apple + P(0, -0.053), apple + P(0.006, -0.07)], 0.0024))
        s.append(stroke(closed(curve(apple + P(0.004, -0.064), apple + P(0.02, -0.08), apple + P(0.03, -0.066), 5) + curve(apple + P(0.03, -0.066), apple + P(0.016, -0.058), apple + P(0.004, -0.064), 5).dropFirst()), 0.0018))
        for yy in ([-0.008, 0.008] as [Double]) { s.append(stroke(ellipse(apple + P(0, yy), 0.003, 0.006, 8), 0.0016)) }
        fit(&s, from: mark, core: facets[4])
        mark = s.count
        let lamp = facets[5] + P(0.03, 0.025)
        s.append(stroke(arc(lamp, 0.024, 135, 405, 20) + [lamp + P(0.011, 0.034), lamp + P(-0.011, 0.034), lamp + P(-0.017, 0.017)], 0.0036))
        for yy in ([0.04, 0.046] as [Double]) { s.append(stroke([lamp + P(-0.01, yy), lamp + P(0.01, yy)], 0.0018)) }
        s.append(stroke([lamp + P(-0.008, 0.018), lamp + P(-0.004, -0.004), lamp + P(0, 0.004), lamp + P(0.004, -0.004), lamp + P(0.008, 0.018)], 0.0016))
        s.append(stroke([lamp + P(0, -0.024), lamp + P(0, -0.09)], 0.0016))

        fit(&s, from: mark, core: facets[5])
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            if simd_length_squared(p) < 0.0841, let t = fly(p) { return t }
            let k = Int(((bearing(p) + 90) / 60).rounded()) % 6, d = p - facets[k]
            if simd_length_squared(d) < 0.069696 { return cores[k] }
            if hexagon(d, 0.315) { return .zero }
            // The compound eye: a facet a cell, each its own red, the seams between them left dark.
            let w = dome(p), q = (root3 / 3 * w.x - w.y / 3) / size, r = 2.0 / 3 * w.y / size
            var a = q.rounded(), b = r.rounded()
            let cz = -q - r, c = cz.rounded()
            let da = abs(a - q), db = abs(b - r), dc = abs(c - cz)
            if da > db && da > dc { a = -b - c } else if db > dc { b = -a - c }
            let centre = P(size * root3 * (a + b / 2), size * 1.5 * b), e = w - centre
            let ri = size * root3 / 2, edge = max(abs(e.x), abs(e.x * 0.5 + e.y * root3 / 2), abs(e.x * 0.5 - e.y * root3 / 2))
            if edge > ri - 0.02 { return .zero }
            let h: Double = scatter(Int(a), Int(b))
            let tone: Tone = m(0.3 + 0.5 * h)
            return tone
        }
        return Halftone.Panel(name: "flyseye", tones: tones, strokes: pieces(s))
    }
}

// MARK: - 52: Chameleon

/// Level 52's name: a chameleon side on across the glass at dusk, climbing, its head tipped up to the right: the
/// turret of its eye over the hub, its snout up into the upper right, the casque raised up the upper left, its body
/// down the left to two mitten feet gripping a branch, and its tail curled under into a coil over the bottom core. A
/// moon rises over the top core and a flower opens over the lower right (hex's four lenses on this level). Each holds
/// what the chameleon has its eye on: a cricket in the eye, a hawk across the moon, a bee on the flower and a
/// butterfly in the coil.
extension LensArt {
    static let chameleon: Halftone.Panel = drawChameleon()

    private static func drawChameleon() -> Halftone.Panel {
        let eye = P(0, 0), moon = P(0, -0.56), flower = P(0.485, 0.28), coil = P(0, 0.56)
        let skin = c(0.85), pale = Tone(0.3, 0.3, 0.35), sky = m(0.3), wood = y(0.5)
        // The tail's coil: a band of skin winding out a tenth of the glass a turn, the gap between dark.
        let coiled: @Sendable (P) -> Bool = { d in
            let turns = simd_length(d) / 0.1 - bearing(d) / 360
            return turns - turns.rounded(.down) < 0.55
        }
        // Head and body as one outline, clockwise from the snout's tip: over the eye, up the casque, down the back to
        // the rump, along the belly to the chest and up the throat and jaw.
        let lizard: [P] = [P(0.6, -0.33), P(0.54, -0.42), P(0.38, -0.4), P(0.22, -0.3), P(0.0, -0.28), P(-0.2, -0.3),
                           P(-0.3, -0.5), P(-0.44, -0.68), P(-0.56, -0.64), P(-0.62, -0.46), P(-0.66, -0.3), P(-0.8, -0.2), P(-0.92, -0.02),
                           P(-0.96, 0.2), P(-0.9, 0.38), P(-0.7, 0.48), P(-0.46, 0.46), P(-0.24, 0.36), P(0.0, 0.29),
                           P(0.13, 0.29), P(0.23, 0.16), P(0.31, 0.03), P(0.44, -0.08), P(0.55, -0.18), P(0.6, -0.28)]
        let belly = ribbon(curve(P(0.02, 0.27), P(-0.5, 0.5), P(-0.92, 0.3), 14), 0.05, 0.09)
        let branch = bar(P(-1.0, 0.5), P(-0.34, 0.76), 0.055)
        let legs: [[P]] = [bar(P(-0.4, 0.4), P(-0.5, 0.68), 0.08), bar(P(-0.76, 0.42), P(-0.8, 0.56), 0.085)]
        let feet: [P] = [P(-0.5, 0.7), P(-0.8, 0.58)]
        let tail = ribbon(curve(P(-0.9, 0.34), P(-0.6, 0.94), P(-0.28, 0.66), 16), 0.12, 0.075)
        let scales: [Double] = [8, 30, 55, 74, 100, 128, 150, 171, 197, 222, 248, 266, 290, 316, 337]
        let craters: [Double] = [5, 22, 38, 61, 80, 97, 118, 139, 157, 176, 194, 212, 235, 251, 270, 290, 309, 331, 347]
        let body = fill(lizard, skin)
        let fills = [fill(belly, pale), body, fill(branch, wood)]
            + legs.map { fill($0, skin) } + [fill(tail, skin)]
        let petal: @Sendable (Double) -> Double = { a in 0.27 + 0.15 * abs(cos((a - 10) * 4 * .pi / 180)).squareRoot() * (0.85 + 0.15 * sin(a * .pi / 60)) }

        var s: [Halftone.Stroke] = []
        // The chameleon: its outline, the casque's ridge, the mouth, the crest down its back, legs and gripping feet,
        // the branch and the tail.
        let outline = (0..<lizard.count).flatMap { span(lizard[$0], lizard[($0 + 1) % lizard.count], 10).dropLast() }
        let free = { (p: P) in
            simd_distance(p, eye) > 0.345 && simd_distance(p, moon) > 0.27 && simd_distance(p, flower) > 0.27 && simd_distance(p, coil) > 0.345
        }
        s += runs(outline + [lizard[0]], bold, keep: free)
        for k in 0..<3 {
            let d = 0.07 * Double(k)
            s += runs(curve(P(-0.24 - d, -0.3), P(-0.36 - d, -0.42), P(-0.46 - 0.04 * Double(k), -0.64 + d), 10), hair, keep: free)
        }
        s += runs(curve(P(0.6, -0.31), P(0.46, -0.2), P(0.36, -0.06), 10), bold, keep: free)
        s += runs(closed(belly), hair, keep: free)
        s += runs((0..<15).map { (k: Int) -> P in
            let a = P(-0.66, -0.3) + (P(-0.95, 0.12) - P(-0.66, -0.3)) * (Double(k) / 14)
            return k % 2 == 0 ? a : a + P(-0.04, -0.025)
        }, mid, keep: free)
        for l in legs { s += runs(closed(l), mid, keep: free) }
        for f in feet {
            s.append(stroke(curve(f + P(-0.06, -0.05), f + P(-0.08, 0.05), f + P(-0.01, 0.06), 8), bold))
            s.append(stroke(curve(f + P(0.06, -0.03), f + P(0.08, 0.06), f + P(0.01, 0.06), 8), bold))
        }
        s += runs(closed(branch), mid, keep: free)
        s += runs(closed(tail), mid, keep: free)
        // The eye's turret, the moon's rim, the flower's petals and the coil's turns.
        s.append(stroke(circle(eye, 0.34, 64), bold))
        s.append(stroke(circle(eye, 0.264, 64), mid))
        for a in scales { s.append(stroke([polar(eye, 0.27, a), polar(eye, 0.335, a)], hair)) }
        s.append(stroke(circle(moon, 0.264, 56), mid))
        s.append(stroke(closed((0..<96).map { polar(flower, petal(Double($0) * 3.75), Double($0) * 3.75) }), mid))
        s.append(stroke(circle(flower, 0.264, 56), hair))
        s.append(stroke(circle(coil, 0.264, 56), hair))
        s += runs(spiral(coil, 0.05, grow: 0.1 / 36, turn: 10, 104), mid) { simd_distance($0, coil) > 0.06 }

        // A cricket in the eye, a hawk across the moon, a bee on the flower and a butterfly in the coil.
        var mark = s.count
        let cricket = eye + P(-0.03, -0.055)
        s.append(stroke(ellipse(cricket, 0.03, 0.011, degrees: 10, 18), 0.0036))
        s.append(stroke(circle(cricket + P(0.034, 0.006), 0.008, 8), 0.0034))
        s.append(stroke([cricket + P(-0.01, 0.006), cricket + P(-0.03, -0.03), cricket + P(-0.04, 0.02)], 0.003))
        s.append(stroke(curve(cricket + P(0.04, 0.0), cricket + P(0.07, -0.05), cricket + P(0.1, -0.03), 8), 0.0016))
        for dx in ([0.0, 0.016] as [Double]) { s.append(stroke([cricket + P(dx, 0.01), cricket + P(dx + 0.008, 0.028)], 0.002)) }
        fit(&s, from: mark, core: eye)
        mark = s.count
        let hawk = moon + P(0.02, 0.035)
        s.append(stroke([hawk + P(-0.08, -0.02), hawk + P(-0.045, -0.032), hawk + P(-0.012, -0.004), hawk + P(0, -0.016),
                         hawk + P(0.012, -0.004), hawk + P(0.045, -0.032), hawk + P(0.08, -0.02)], 0.0038))
        s.append(stroke([hawk + P(-0.065, -0.022), hawk + P(-0.03, 0.004), hawk + P(-0.01, 0.0)], 0.003))
        s.append(stroke([hawk + P(0.065, -0.022), hawk + P(0.03, 0.004), hawk + P(0.01, 0.0)], 0.003))
        s.append(stroke([hawk + P(-0.01, 0.0), hawk + P(-0.014, 0.03), hawk + P(0.014, 0.03), hawk + P(0.01, 0.0)], 0.003))
        fit(&s, from: mark, core: moon)
        mark = s.count
        let bee = flower + P(-0.03, -0.045)
        s.append(stroke(ellipse(bee, 0.026, 0.015, 18), 0.0036))
        for dx in ([-0.01, 0.004] as [Double]) { s.append(stroke([bee + P(dx, -0.014), bee + P(dx, 0.014)], 0.003)) }
        s.append(stroke(circle(bee + P(0.032, -0.002), 0.007, 8), 0.003))
        s.append(stroke(ellipse(bee + P(-0.006, -0.03), 0.014, 0.018, degrees: -20, 14), 0.0024))
        s.append(stroke(ellipse(bee + P(0.012, -0.028), 0.01, 0.014, degrees: 25, 12), 0.0024))
        s.append(stroke([bee + P(-0.026, 0), bee + P(-0.036, 0.002)], 0.0024))
        fit(&s, from: mark, core: flower)
        mark = s.count
        let fly = coil + P(0.035, 0.05)
        for side in ([-1.0, 1.0] as [Double]) {
            s.append(stroke(closed([fly, fly + P(side * 0.03, -0.045), fly + P(side * 0.055, -0.03), fly + P(side * 0.04, -0.004)]), 0.0034))
            s.append(stroke(closed([fly + P(0, 0.004), fly + P(side * 0.036, 0.01), fly + P(side * 0.03, 0.036)]), 0.003))
            s.append(stroke([fly + P(0, -0.014), fly + P(side * 0.014, -0.04)], 0.0018))
        }
        s.append(stroke([fly + P(0, -0.016), fly + P(0, 0.024)], 0.0034))

        fit(&s, from: mark, core: coil)
        return panel("chameleon", fills: [], strokes: pieces(s)) { p in
            let de = simd_length_squared(p - eye), dm = simd_length_squared(p - moon)
            let df = simd_length_squared(p - flower), dc = simd_length_squared(p - coil)
            if de < 0.069696 { return simd_distance(p, eye + P(0.07, -0.04)) < 0.04 ? .zero : y(0.9) }
            if dm < 0.069696 { return pale }
            if df < 0.069696 { return y(0.8) }
            if dc < 0.1156 { return coiled(p - coil) ? skin : .zero }
            if de < 0.1156 { return odd(bearing(p - eye), scales) != (de < 0.09) ? .zero : skin }
            if dm < 0.0961, odd(bearing(p - moon), craters), !body.holds(p) { return m(0.55) }
            if df < 0.1764, df.squareRoot() < petal(bearing(p - flower)), !body.holds(p) { return Tone(0.4, 0.4, 0.45) }
            for f in fills where f.holds(p) { return f.tone }
            return sky
        }
    }
}

// MARK: - 53: Cat's eye

/// Level 53's name, both ways: a ginger tabby seen from above, head cocked on the floorboards, its blue eyes over
/// the lower right and bottom cores, and two cat's-eye marbles it is after over the top and upper left (hex's four
/// lenses on this level), a paw out for one and a ball of wool by its ear. In its eyes a butterfly and a sparrow; in
/// the marbles a fish's bones and, looking back, a cat's eye.
extension LensArt {
    static let catseye: Halftone.Panel = drawCatseye()

    private static func drawCatseye() -> Halftone.Panel {
        let eyes = [P(0, 0.56), P(0.485, 0.28)], marbles = [P(0, -0.56), P(-0.485, -0.28)]
        let u = simd_normalize(eyes[1] - eyes[0]), n = P(-u.y, u.x), crown = (eyes[0] + eyes[1]) / 2 + 0.1 * n
        let face = { (x: Double, y: Double) in crown + x * u + y * n }
        let fur = y(0.8), stripe = m(0.65), pale = Tone(0.3, 0.3, 0.35), iris = c(0.9)
        let ears = [[face(-0.66, -0.3), face(-0.4, -0.8), face(-0.12, -0.58)], [face(0.66, -0.3), face(0.4, -0.8), face(0.12, -0.58)]]
        let inner = ears.map { e in e.map { 0.55 * $0 + 0.45 * (e[0] + e[1] + e[2]) / 3 } }
        let wool = P(0.68, -0.28), leg = bar(P(-0.3, 1.0), P(-0.5, 0.16), 0.16)
        let swirls: [[Double]] = [[12, 40, 95, 130, 160, 205, 250, 290, 318, 345], [-4, 33, 70, 110, 140, 190, 226, 262, 300, 333]]
        let early = inner.map { fill($0, m(0.6)) } + ears.map { fill($0, fur) } + [disc(wool, 0.2, c(0.55)), fill(leg, fur), oval(P(-0.5, 0.15), 0.1, 0.09, pale)]
        let shadows = marbles.map { oval($0 + P(0.08, 0.1), 0.27, 0.25, .zero) }
        let liner: @Sendable (Int, Double) -> Bool = { k, a in abs(a - (k == 0 ? 330.0 : 150.0)) > 18 }

        @Sendable func head(_ p: P) -> Tone? {
            let d = p - crown, x = simd_dot(d, u), y = simd_dot(d, n)
            guard (x / 0.7) * (x / 0.7) + (y / 0.62) * (y / 0.62) < 1 else { return nil }
            let cheek: P = (P(abs(x), y) - P(0.08, 0.29)) / P(0.1, 0.075), chin: P = (P(x, y) - P(0, 0.42)) / P(0.12, 0.08)
            if simd_length_squared(cheek) < 1 || simd_length_squared(chin) < 1 { return pale }
            if y > 0.15 && y < 0.24 && abs(x) < (0.24 - y) * 0.6 { return m(0.85) }
            // The tabby's stripes: three down the brow, two across each cheek.
            if y < -0.3 && abs(x) < 0.17 && abs(abs(x) - 0.1 * (abs(x) / 0.1).rounded()) < 0.022 { return stripe }
            if abs(x) > 0.5 && (abs(y - 0.06) < 0.025 || abs(y - 0.17) < 0.025) { return stripe }
            return fur
        }

        var s: [Halftone.Stroke] = []
        // The head: outline, ears and their fur, brow stripes, nose, mouth, muzzle and whiskers.
        let outline = (0..<96).map { (k: Int) -> P in
            let a = Double(k) * .pi / 48
            return face(0.7 * cos(a), 0.62 * sin(a))
        }
        s += runs(outline + [outline[0]], bold) { p in eyes.allSatisfy { simd_distance(p, $0) > 0.3 } && simd_length(p) < 1 }
        for (e, i) in zip(ears, inner) {
            s.append(stroke(e, bold))
            s.append(stroke([i[0], i[1], i[2]], hair))
        }
        s.append(stroke(closed([face(-0.05, 0.15), face(0.05, 0.15), face(0, 0.24)]), mid))
        s.append(stroke([face(0, 0.24), face(0, 0.3)] + curve(face(0, 0.3), face(-0.05, 0.36), face(-0.1, 0.32), 6), mid))
        s.append(stroke(curve(face(0, 0.3), face(0.05, 0.36), face(0.1, 0.32), 6), mid))
        for side in ([-1.0, 1.0] as [Double]) {
            for (k, t) in ([-0.06, 0.0, 0.07] as [Double]).enumerated() {
                s.append(stroke(curve(face(side * 0.12, 0.28 + 0.02 * Double(k)), face(side * 0.35, 0.24 + t), face(side * 0.62, 0.2 + 2.2 * t), 10), hair))
            }
            for k in 0..<3 { s.append(stroke(circle(face(side * (0.06 + 0.035 * Double(k)), 0.29 + 0.012 * Double(k % 2)), 0.006, 6), hair)) }
        }
        // The paw, its toes and its pad, and the ball of wool, wound, its end trailing to the paw.
        s.append(stroke(closed(leg), mid))
        s.append(stroke(ellipse(P(-0.5, 0.15), 0.1, 0.09, 28), bold))
        for dx in ([-0.04, 0.0, 0.04] as [Double]) { s.append(stroke([P(-0.5 + dx, 0.07), P(-0.5 + dx * 1.2, 0.11)], mid)) }
        s.append(stroke(circle(wool, 0.2, 48), bold))
        for (k, t) in ([-30.0, 20, 70, 120] as [Double]).enumerated() {
            s += runs(ellipse(wool, 0.19, 0.08 + 0.03 * Double(k % 2), degrees: t, 40), hair) { simd_distance($0, wool) < 0.195 }
        }
        s.append(stroke(curve(polar(wool, 0.2, 200), P(0.1, -0.1), P(-0.42, 0.05), 24), mid))
        // The floorboards' seams, staggered.
        for k in -4...4 {
            let off = 0.22 * Double(k), dir = P(cos(0.35), sin(0.35)), across = P(-sin(0.35), cos(0.35))
            s += runs(span(across * off - dir * 1.2, across * off + dir * 1.2, 60), mid) { p in
                simd_length(p) < 1 && head(p) == nil && marbles.allSatisfy { simd_distance(p, $0) > 0.3 } && simd_distance(p, wool) > 0.2
            }
            let shift: Double = 0.3 * Double(k % 3) - 0.3, end: P = across * (off + 0.11) + dir * shift
            s.append(stroke([end - across * 0.11, end + across * 0.11], hair))
        }
        // The eyes: rims, slits, gleams. The marbles: rims and gleams.
        for (k, e) in eyes.enumerated() {
            s += runs(circle(e, 0.264, 64), mid) { liner(k, bearing($0 - e)) }
            s += runs(circle(e, 0.3, 64), bold) { liner(k, bearing($0 - e)) }
            s.append(stroke(arc(e, 0.21, 200, 240, 8), mid))
        }
        for m in marbles {
            s.append(stroke(circle(m, 0.3, 64), bold))
            s.append(stroke(circle(m, 0.264, 56), hair))
            s.append(stroke(arc(m, 0.22, 195, 255, 12), mid))
            s.append(stroke(arc(m, 0.21, 20, 40, 5), hair))
        }

        // In its eyes a butterfly and a sparrow; in the marbles a fish's bones and a cat's eye.
        var mark = s.count
        let bfly = eyes[0] + P(-0.065, -0.01)
        for side in ([-1.0, 1.0] as [Double]) {
            s.append(stroke(ellipse(bfly + P(side * 0.024, -0.014), 0.024, 0.015, degrees: side * -35, 18), 0.0034))
            s.append(stroke(ellipse(bfly + P(side * 0.017, 0.016), 0.015, 0.01, degrees: side * 35, 14), 0.003))
            s.append(stroke(curve(bfly + P(0, -0.014), bfly + P(side * 0.004, -0.03), bfly + P(side * 0.016, -0.036), 5), 0.0018))
        }
        s.append(stroke([bfly + P(0, -0.012), bfly + P(0, 0.022)], 0.0034))
        fit(&s, from: mark, core: eyes[0])
        mark = s.count
        let bird = eyes[1] + P(0.07, -0.045)
        s.append(stroke(ellipse(bird, 0.026, 0.016, degrees: -15, 18), 0.0036))
        s.append(stroke(circle(bird + P(0.026, -0.016), 0.01, 10), 0.0034))
        s.append(stroke([bird + P(0.035, -0.02), bird + P(0.046, -0.016), bird + P(0.035, -0.012)], 0.0024))
        s.append(stroke([bird + P(-0.024, 0.004), bird + P(-0.05, 0.012), bird + P(-0.046, -0.004)], 0.0028))
        s.append(stroke(curve(bird + P(-0.016, -0.006), bird + P(0, -0.004), bird + P(0.012, 0.008), 5), 0.0018))
        for dx in ([-0.004, 0.008] as [Double]) { s.append(stroke([bird + P(dx, 0.015), bird + P(dx, 0.03)], 0.0018)) }
        s.append(stroke([bird + P(-0.05, 0.03), bird + P(0.04, 0.03)], 0.0024))
        fit(&s, from: mark, core: eyes[1])
        mark = s.count
        let bones = marbles[0] + P(0.02, -0.05)
        s.append(stroke([bones + P(-0.045, 0), bones + P(0.03, 0)], 0.0034))
        s.append(stroke(ellipse(bones + P(0.042, 0), 0.014, 0.012, 12), 0.0034))
        s.append(stroke(closed([bones + P(-0.045, 0), bones + P(-0.065, -0.016), bones + P(-0.065, 0.016)]), 0.003))
        for k in 0..<4 {
            let x = -0.03 + 0.016 * Double(k)
            s.append(stroke([bones + P(x - 0.006, -0.018), bones + P(x, 0), bones + P(x - 0.006, 0.018)], 0.0024))
        }
        fit(&s, from: mark, core: marbles[0])
        mark = s.count
        let look = marbles[1] + P(0.04, 0.035)
        s.append(stroke(closed(curve(look + P(-0.045, 0), look + P(0, -0.04), look + P(0.045, 0), 10) + curve(look + P(0.045, 0), look + P(0, 0.04), look + P(-0.045, 0), 10).dropFirst()), 0.0034))
        s.append(stroke(closed(curve(look + P(0, -0.018), look + P(0.008, 0), look + P(0, 0.018), 6) + curve(look + P(0, 0.018), look + P(-0.008, 0), look + P(0, -0.018), 6).dropFirst()), 0.0028))
        s.append(stroke(circle(look, 0.018, 12), 0.0016))

        fit(&s, from: mark, core: marbles[1])
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for (k, e) in eyes.enumerated() {
                let d = p - e, r2 = simd_length_squared(d)
                guard r2 < 0.09 else { continue }
                if r2 < 0.069696 {
                    let along = simd_dot(d, n), across = simd_dot(d, u)
                    return abs(across) < 0.035 * max(0, 1 - along * along / 0.053).squareRoot() ? .zero : iris
                }
                if liner(k, bearing(d)) { return .zero }
            }
            for (k, ball) in marbles.enumerated() {
                let d = p - ball, r2 = simd_length_squared(d)
                guard r2 < 0.09 else { continue }
                if r2 < 0.069696 { return k == 0 ? y(0.9) : c(0.6) }
                return odd(bearing(d), swirls[k]) ? (k == 0 ? c(0.9) : y(0.95)) : .zero
            }
            if let t = head(p) { return t }
            for f in early where f.holds(p) { return f.tone }
            for f in shadows where f.holds(p) { return f.tone }
            // The floor: boards along a diagonal, each its own blue.
            let dir: P = P(cos(0.35), sin(0.35))
            let across: Double = simd_dot(p, P(-dir.y, dir.x)) / 0.22 + 10
            let plank: Int = Int(across.rounded(.down))
            return plank % 2 == 0 ? m(0.3) : m(0.18)
        }
        return Halftone.Panel(name: "catseye", tones: tones, strokes: pieces(s))
    }
}

// MARK: - 54: Eagle eye

/// Level 54's name: a bald eagle's head filling the glass, side on and facing right: its white head with hackles
/// raised up the left, the dark of its neck below, a heavy brow slanting down over its yellow eye on the hub, and the
/// hooked yellow beak over the lower right. Over the top core the sun, over the upper right a cloud and over the
/// bottom a pool below its chin (hex's four lenses on this level), each holding what it has seen: a hare in its eye,
/// a goat on a crag against the sun, a dove by the cloud and a salmon leaping in the pool.
extension LensArt {
    static let eagleeye: Halftone.Panel = drawEagleeye()

    private static func drawEagleeye() -> Halftone.Panel {
        let eye = P(0, 0), sun = P(0, -0.56), cloud = P(0.485, -0.28), pool = P(0, 0.56)
        let white = Tone(0.3, 0.3, 0.35), gold = y(0.95), sky = c(0.3), dark = Tone(0, 0.4, 0.22), puff = c(0.75)
        let rays: [Double] = [5, 22, 38, 61, 80, 97, 118, 139, 157, 176, 194, 212, 235, 251, 270, 290, 309, 331, 347]
        let ripples: [Double] = [10, 40, 55, 100, 145, 190, 205, 250, 290, 335]
        // The head, clockwise from the beak's root: over the eye, up the crown, its hackles down the back of the head,
        // the white's ragged edge across the neck, and the chin back to the beak.
        let head: [P] = [P(0.3, -0.1), P(0.2, -0.27), P(0.0, -0.28), P(-0.18, -0.3), P(-0.34, -0.44), P(-0.52, -0.56),
                         P(-0.72, -0.56), P(-0.86, -0.44), P(-0.92, -0.3), P(-0.86, -0.22), P(-0.97, -0.12), P(-0.9, -0.02),
                         P(-1.05, 0.06), P(-1.05, 0.3), P(-0.86, 0.24), P(-0.78, 0.42), P(-0.64, 0.34), P(-0.54, 0.52), P(-0.42, 0.4),
                         P(-0.3, 0.37), P(-0.16, 0.3), P(0.0, 0.285), P(0.18, 0.29), P(0.3, 0.26)]
        let neck: [P] = [P(-1.05, 0.3), P(-0.86, 0.24), P(-0.78, 0.42), P(-0.64, 0.34), P(-0.54, 0.52), P(-0.42, 0.4),
                         P(-0.3, 0.37), P(-0.29, 0.7), P(-0.32, 1.05), P(-1.05, 1.05)]
        let beak: [P] = [P(0.26, -0.12), P(0.42, -0.01), P(0.62, 0.03), P(0.78, 0.11), P(0.89, 0.25), P(0.91, 0.4), P(0.85, 0.54),
                         P(0.74, 0.64), P(0.76, 0.52), P(0.72, 0.43), P(0.62, 0.38), P(0.52, 0.42), P(0.38, 0.38), P(0.28, 0.26),
                         P(0.24, 0.06)]
        let brow: [P] = [P(-0.34, -0.4), P(-0.18, -0.31), P(0.0, -0.29), P(0.2, -0.27), P(0.3, -0.07), P(0.2, -0.05),
                         P(0.06, -0.13), P(-0.1, -0.19), P(-0.3, -0.25)]
        let gape = curve(P(0.3, 0.22), P(0.48, 0.34), P(0.72, 0.43), 10)
        let shade = fill(brow, .zero), bill = fill(beak, gold), crown = fill(head, white), nape = fill(neck, dark)

        var s: [Halftone.Stroke] = []
        // The eagle: its outline, brow, beak and gape, the cere and nostril, feathers and the white's edge.
        let free = { (p: P) in
            simd_distance(p, eye) > 0.345 && simd_distance(p, sun) > 0.27 && simd_distance(p, cloud) > 0.27 && simd_distance(p, pool) > 0.27
        }
        let ring = { (line: [P]) in (0..<line.count - 1).flatMap { span(line[$0], line[$0 + 1], 10).dropLast() } + [line[line.count - 1]] }
        s += runs(ring(Array(head[0...12])), bold, keep: free)
        s += runs(ring(Array(neck[0...8])), bold, keep: free)
        s += runs(ring(Array(head[19...]) + [beak[13]]), bold, keep: free)
        s += runs(ring(closed(brow)), bold) { simd_distance($0, sun) > 0.27 && simd_distance($0, cloud) > 0.27 }
        s += runs(ring(closed(beak)), bold) { simd_distance($0, cloud) > 0.27 }
        s.append(stroke(gape, mid))
        s.append(stroke(curve(P(0.4, 0.0), P(0.36, 0.12), P(0.38, 0.27), 8), mid))
        s.append(stroke(ellipse(P(0.47, 0.1), 0.035, 0.016, degrees: 15, 12), mid))
        s.append(stroke(curve(P(0.66, 0.08), P(0.82, 0.24), P(0.77, 0.52), 10), hair))
        for (k, at) in ([P(-0.48, -0.3), P(-0.6, -0.16), P(-0.44, -0.02), P(-0.7, 0.04), P(-0.52, 0.16), P(-0.86, 0.06)] as [P]).enumerated() {
            s.append(stroke(curve(at, at + P(-0.06, -0.02), at + P(-0.13, 0.01 * Double(k % 3)), 6), hair))
        }
        for at in ([P(-0.6, 0.66), P(-0.8, 0.6), P(-0.46, 0.84), P(-0.7, 0.84)] as [P]) {
            s.append(stroke(curve(at, at + P(0.04, 0.05), at + P(0.1, 0.04), 6), hair))
        }
        // The rims: the eye's, the sun's with its rays, the cloud's and the pool's.
        s.append(stroke(circle(eye, 0.34, 64), bold))
        s.append(stroke(circle(eye, 0.264, 56), mid))
        s.append(stroke(circle(sun, 0.264, 56), mid))
        for a in stride(from: 200.0, through: 340, by: 28) { s.append(stroke([polar(sun, 0.3, a), polar(sun, 0.4, a)], mid)) }
        s.append(stroke(circle(cloud, 0.264, 56), mid))
        s.append(stroke(circle(pool, 0.264, 56), bold))
        s.append(stroke(arc(pool, 0.22, 200, 250, 10), mid))

        // What it has seen: a hare in its eye, a goat against the sun, a dove by the cloud and a salmon in the pool.
        var mark = s.count
        let hare = eye + P(-0.035, 0.04)
        s.append(stroke(ellipse(hare, 0.03, 0.018, 20), 0.0038))
        s.append(stroke(ellipse(hare + P(0.034, -0.016), 0.013, 0.01, 12), 0.0036))
        s.append(stroke(circle(hare + P(0.04, -0.018), 0.002, 4), 0.003))
        for (dx, t) in [(0.026, -20.0), (0.034, 5.0)] { s.append(stroke(ellipse(hare + P(dx, -0.045), 0.006, 0.022, degrees: t, 12), 0.003)) }
        s.append(stroke(circle(hare + P(-0.032, -0.004), 0.007, 8), 0.0024))
        s.append(stroke([hare + P(-0.018, 0.014), hare + P(-0.03, 0.026), hare + P(-0.01, 0.026)], 0.0024))
        fit(&s, from: mark, core: eye)
        mark = s.count
        let goat = sun + P(-0.05, 0.02)
        s.append(stroke(closed(rect(goat.x - 0.028, goat.y - 0.012, goat.x + 0.02, goat.y + 0.008)), 0.0036))
        for dx in ([-0.022, -0.012, 0.008, 0.016] as [Double]) { s.append(stroke([goat + P(dx, 0.008), goat + P(dx, 0.03)], 0.0024)) }
        s.append(stroke([goat + P(0.018, -0.01), goat + P(0.03, -0.03), goat + P(0.04, -0.024), goat + P(0.026, -0.008)], 0.003))
        s.append(stroke(curve(goat + P(0.03, -0.03), goat + P(0.024, -0.05), goat + P(0.01, -0.046), 6), 0.0024))
        s.append(stroke([goat + P(0.036, -0.022), goat + P(0.034, -0.008)], 0.0018))
        s.append(stroke([goat + P(-0.06, 0.04), goat + P(-0.02, 0.03), goat + P(0.04, 0.034), goat + P(0.07, 0.05)], 0.0024))
        fit(&s, from: mark, core: sun)
        mark = s.count
        let dove = cloud + P(0.04, 0.05)
        s.append(stroke(ellipse(dove, 0.024, 0.012, degrees: -10, 16), 0.0036))
        s.append(stroke(circle(dove + P(0.026, -0.01), 0.008, 8), 0.0034))
        s.append(stroke([dove + P(0.034, -0.012), dove + P(0.044, -0.008)], 0.0024))
        s.append(stroke(closed([dove + P(-0.006, -0.008), dove + P(0.0, -0.05), dove + P(0.02, -0.04), dove + P(0.01, -0.01)]), 0.003))
        s.append(stroke(closed([dove + P(-0.022, 0.004), dove + P(-0.046, 0.016), dove + P(-0.044, -0.004)]), 0.0024))
        fit(&s, from: mark, core: cloud)
        mark = s.count
        let fish = pool + P(0.012, -0.04)
        s.append(stroke(closed(curve(fish + P(-0.04, 0.02), fish + P(-0.005, -0.03), fish + P(0.035, -0.02), 10)
            + curve(fish + P(0.035, -0.02), fish + P(0.0, 0.0), fish + P(-0.04, 0.02), 10).dropFirst()), 0.0036))
        s.append(stroke(closed([fish + P(-0.038, 0.018), fish + P(-0.06, 0.012), fish + P(-0.052, 0.04)]), 0.003))
        s.append(stroke(circle(fish + P(0.022, -0.017), 0.003, 6), 0.0024))
        for (k, at) in [P(0.05, -0.022), P(0.064, -0.036), P(0.074, -0.056)].enumerated() { s.append(stroke(circle(fish + at, 0.004 + 0.002 * Double(k), 8), 0.0016)) }

        fit(&s, from: mark, core: pool)
        return panel("eagleeye", fills: [], strokes: pieces(s)) { p in
            let de = simd_length_squared(p - eye), ds = simd_length_squared(p - sun)
            let dc = simd_length_squared(p - cloud), dp = simd_length_squared(p - pool)
            if de < 0.069696 {
                if shade.holds(p) { return .zero }
                return simd_distance(p, eye + P(0.05, 0.02)) < 0.08 ? .zero : gold
            }
            if ds < 0.069696 { return gold }
            if dc < 0.069696 { return puff }
            if dp < 0.069696 { return c(0.9) }
            if shade.holds(p) { return .zero }
            if bill.holds(p) { return gold }
            if de < 0.1156 { return .zero }
            if ds < 0.1225, !crown.holds(p) { return odd(bearing(p - sun), rays) ? y(0.6) : sky }
            if dc < 0.1156 { return dc.squareRoot() < 0.3 + 0.035 * cos(bearing(p - cloud) * 6 * .pi / 180) ? puff : sky }
            if dp < 0.1156, !nape.holds(p) { return odd(bearing(p - pool), ripples) ? c(0.6) : sky }
            if crown.holds(p) { return white }
            if nape.holds(p) { return dark }
            return sky
        }
    }
}

// MARK: - 55: Peacock

/// Level 55's name: a peacock face on with his train up, its barbs fanning from behind him, his blue neck up the
/// hub and his body over the bottom rod, and five of the train's eyes over the top and side cores (hex's five lenses on
/// this level), each a magenta heart in a notched teal ring, then bronze and gold, the upper left's heart gilded. In the
/// eyes: a peahen, a rain cloud, a snake, a lotus and, in the gilded one, a crown.
extension LensArt {
    static let peacock: Halftone.Panel = drawPeacock()

    private static func drawPeacock() -> Halftone.Panel {
        let base = P(0, 0.66), spots = [1, 2, 3, 5, 6].map { polar(P(0, 0), 0.56, -90 + 60 * Double($0 - 1)) }
        let hearts = [m(0.85), m(0.5), m(0.85), m(0.5), y(0.8)], teal = c(0.95), bronze = y(0.9), gold = Tone(0, 0.45, 0.6)
        let barbs = [c(0.35), y(0.28)]
        let neck = ribbon(curve(P(0.0, 0.44), P(-0.16, 0.12), P(0.07, -0.13), 16), 0.16, 0.07)
        let crown = P(0.09, -0.17)
        let bird = [oval(crown, 0.07, 0.055, c(0.95)), fill([crown + P(0.05, -0.02), crown + P(0.13, 0.0), crown + P(0.05, 0.02)], y(0.6)),
                    fill(neck, c(0.95)), fill(ellipse(P(0.14, 0.62), 0.16, 0.24, degrees: -18, 28), y(0.6)),
                    oval(P(-0.02, 0.6), 0.2, 0.26, c(0.75)), fill(rect(-0.3, 0.86, 0.36, 1.0), m(0.4))]
        // Each eye's rings: their reach along the feather and across it, and how far down the feather each is centred.
        let rings: [(Double, Double, Double, Tone)] = [(0.34, 0.31, 0.05, teal), (0.42, 0.36, 0.1, bronze), (0.5, 0.41, 0.15, gold)]
        let wobble: [[Double]] = [[20, 70, 110, 170, 230, 300], [0, 50, 130, 160, 250, 320], [35, 95, 140, 210, 260, 340], [15, 80, 120, 190, 280, 310], [40, 60, 150, 200, 240, 330]]

        var s: [Halftone.Stroke] = []
        // The train: a shaft up each feather from behind him, and the rims of each eye's rings.
        for k in 0..<15 {
            let a = 180 + 180 * Double(k) / 14, tip = polar(base, 1.8, a)
            s += runs(span(base, tip, 60), hair) { p in simd_length(p) < 1 && p.y < 0.5 && spots.allSatisfy { simd_distance(p, $0) > 0.27 } }
        }
        for (k, c) in spots.enumerated() {
            let along = simd_normalize(c - base), across = P(-along.y, along.x)
            for (j, r) in rings.enumerated() {
                let rim = (0..<64).map { i -> P in
                    let t = Double(i) * .pi / 32
                    return c + along * (r.2 + r.0 * cos(t)) + across * (r.1 * sin(t))
                }
                s += runs(rim + [rim[0]], j == 2 ? mid : hair) { (p: P) -> Bool in
                    if j < 2 { return true }
                    return simd_length(p) < 1 && spots.allSatisfy { $0 == c || simd_distance(p, $0) > 0.4 }
                }
            }
            s.append(stroke(circle(c, 0.264, 56), mid))
            s.append(stroke(arc(c, 0.21, 200 + 11 * Double(k), 240 + 11 * Double(k), 8), mid))
        }
        // The bird: neck and head, his crest's six plumes, beak, eye stripe, body, folded wing and legs on the ground.
        s.append(stroke(closed(neck), mid))
        s.append(stroke(ellipse(crown, 0.07, 0.055, 24), mid))
        s.append(stroke(closed([crown + P(0.05, -0.02), crown + P(0.13, 0.0), crown + P(0.05, 0.02)]), mid))
        s.append(stroke(curve(crown + P(-0.03, 0.0), crown + P(0.01, -0.035), crown + P(0.05, -0.01), 6), mid))
        s.append(stroke(circle(crown + P(0.02, -0.012), 0.008, 6), mid))
        for k in 0..<6 {
            let top = crown + P(-0.08 + 0.035 * Double(k), -0.11 + 0.008 * Double(k % 2))
            s.append(stroke([crown + P(-0.01 + 0.006 * Double(k), -0.05), top], hair))
            s.append(stroke(circle(top, 0.008, 6), mid))
        }
        s.append(stroke(ellipse(P(-0.02, 0.6), 0.2, 0.26, 40), bold))
        s.append(stroke(ellipse(P(0.14, 0.62), 0.16, 0.24, degrees: -18, 32), mid))
        for k in 0..<4 { s.append(stroke(curve(P(0.04, 0.48 + 0.07 * Double(k)), P(0.14, 0.5 + 0.07 * Double(k)), P(0.24, 0.44 + 0.08 * Double(k)), 6), hair)) }
        for x in ([-0.08, 0.06] as [Double]) { s.append(stroke([P(x, 0.84), P(x, 0.94), P(x - 0.04, 0.97)], mid)) }
        s.append(stroke([P(-0.6, 0.86), P(0.62, 0.86)], mid))

        // In the eyes: a peahen, a rain cloud, a snake, a lotus and a crown.
        var mark = s.count
        let hen = spots[0] + P(-0.035, -0.025)
        s.append(stroke(ellipse(hen, 0.032, 0.02, 20), 0.0036))
        s.append(stroke(curve(hen + P(0.022, -0.016), hen + P(0.03, -0.034), hen + P(0.034, -0.046), 6), 0.0042))
        s.append(stroke(circle(hen + P(0.038, -0.056), 0.009, 10), 0.0036))
        s.append(stroke([hen + P(0.046, -0.058), hen + P(0.056, -0.054), hen + P(0.046, -0.051)], 0.0024))
        for dx in ([-0.004, 0.0, 0.004] as [Double]) { s.append(stroke([hen + P(0.036 + dx, -0.063), hen + P(0.036 + 2 * dx, -0.075)], 0.0016)) }
        s.append(stroke([hen + P(-0.03, -0.004), hen + P(-0.05, -0.016)], 0.003))
        for dx in ([-0.006, 0.008] as [Double]) { s.append(stroke([hen + P(dx, 0.02), hen + P(dx, 0.036)], 0.0018)) }
        fit(&s, from: mark, core: spots[0])
        mark = s.count
        let cloud = spots[1] + P(-0.04, -0.03)
        s.append(stroke(arc(cloud + P(-0.02, 0), 0.014, 90, 270, 8) + arc(cloud + P(0.0, -0.01), 0.018, 180, 330, 10) + arc(cloud + P(0.024, -0.002), 0.014, 250, 450, 10) + [cloud + P(-0.02, 0.014)], 0.0036))
        for (k, dx) in ([-0.016, 0.0, 0.016] as [Double]).enumerated() { s.append(stroke([cloud + P(dx, 0.024 + 0.004 * Double(k)), cloud + P(dx - 0.006, 0.042 + 0.004 * Double(k))], 0.0024)) }
        fit(&s, from: mark, core: spots[1])
        mark = s.count
        let snake = spots[2] + P(0.0, -0.06)
        s.append(stroke((0...30).map { k in
            let t = Double(k) / 30
            return snake + P(-0.05 + 0.1 * t, 0.012 * sin(t * 3 * .pi))
        }, 0.0036))
        s.append(stroke(ellipse(snake + P(0.058, 0.004), 0.012, 0.008, 12), 0.0034))
        s.append(stroke([snake + P(0.07, 0.004), snake + P(0.082, 0.0), snake + P(0.086, -0.004), snake + P(0.082, 0.0), snake + P(0.086, 0.006)], 0.0016))
        fit(&s, from: mark, core: spots[2])
        mark = s.count
        let lotus = spots[3] + P(0.03, -0.045)
        for t in ([-50.0, -25, 0, 25, 50] as [Double]) {
            s.append(stroke(closed(curve(lotus, lotus + turned(P(-0.016, -0.03), t), lotus + turned(P(0, -0.045), t), 6)
                + curve(lotus + turned(P(0, -0.045), t), lotus + turned(P(0.016, -0.03), t), lotus, 6).dropFirst()), abs(t) > 30 ? 0.0024 : 0.0034))
        }
        s.append(stroke(curve(lotus + P(-0.05, 0.006), lotus + P(0, 0.016), lotus + P(0.05, 0.006), 8), 0.0024))
        fit(&s, from: mark, core: spots[3])
        mark = s.count
        let crownMark = spots[4] + P(0.045, 0.03)
        s.append(stroke(closed([crownMark + P(-0.03, 0.016), crownMark + P(-0.034, -0.02), crownMark + P(-0.015, 0.0), crownMark + P(0, -0.028),
                                crownMark + P(0.015, 0.0), crownMark + P(0.034, -0.02), crownMark + P(0.03, 0.016)]), 0.0036))
        for x in ([-0.034, 0.0, 0.034] as [Double]) { s.append(stroke(circle(crownMark + P(x, x == 0 ? -0.034 : -0.026), 0.004, 6), 0.0024)) }
        s.append(stroke([crownMark + P(-0.03, 0.008), crownMark + P(0.03, 0.008)], 0.0016))

        fit(&s, from: mark, core: spots[4])
        let tones: @Sendable (P) -> Tone = { (p: P) -> Tone in
            for f in bird where f.holds(p) { return f.tone }
            var best = 0, near = Double.infinity
            for (k, c) in spots.enumerated() {
                let d = simd_length_squared(p - c)
                if d < near { near = d; best = k }
            }
            let spot = spots[best], d = p - spot, axis = simd_normalize(spot - base)
            if near < 0.069696 { return hearts[best] }
            let along = simd_dot(d, axis), across = simd_dot(d, P(-axis.y, axis.x))
            for (j, r) in rings.enumerated() {
                let e = P((along - r.2) / r.0, across / r.1)
                if simd_length_squared(e) < 1 {
                    // The bronze ring torn into barbs, a few of them gold, so it is never the same twice round.
                    if j == 0 { return (bearing(d) + 13 * Double(best)).truncatingRemainder(dividingBy: 40) < 13 ? .zero : teal }
                    return j == 1 && odd(bearing(d), wobble[(best + 2) % 5]) && simd_length_squared(e) > 0.8 ? gold : r.3
                }
            }
            return barbs[Int((bearing(p - base) / 6.5).rounded(.down)) % 2]
        }
        return Halftone.Panel(name: "peacock", tones: tones, strokes: pieces(s))
    }
}
