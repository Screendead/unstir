// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Plate: a Victorian cabinet drawer of pinned moths and butterflies round an atlas moth, venation and eyespots in line.
enum Moths {
    typealias Line = Engraving.Line
    private typealias E = Engraving
    private typealias P = SIMD2<Double>

    private enum Antenna { case feathered(Double), clubbed, hooked }

    /// A right wing in the specimen's frame (x out to the right, y back towards the tail, the base at its first point)
    /// and what is drawn on it. Transverse lines are fractions of the reach from the base; `margin` is the submarginal
    /// line's distance in from the edge.
    private struct Wing {
        var outline: [P]
        var veins: Int
        var lines: [Double] = []
        var wave: Double = 0.012
        var margin: Double = 0
        var hatch = false
        var eye: (across: Double, out: Double, r: Double)? = nil
        var window = false
        var lunules = false
        var streaks = false
        /// The base of the wing shaded in parallel hatching.
        var basal = false
    }

    private struct Specimen {
        var c: P, heading: Double, scale: Double
        var fore: Wing, hind: Wing
        var abdomen: Double, girth: Double
        var antenna: Antenna
        /// How much further back the left pair is set than the right, as a pinned specimen is never quite even.
        var spread: Double
        var label: Bool = true
    }

    static let lines: [Line] = {
        var rng = SplitMix64(state: 0x4D4F_5448)
        var out: [Line] = []
        for s in specimens + lesser { specimen(&out, &rng, s) }
        silk(&out, &rng)
        caterpillar(&out, P(-0.12, -0.41), P(-0.03, -0.62), P(0.17, -0.45), girth: 0.024, stripes: true)
        return out
    }()

    private static var specimens: [Specimen] {
        [
            // Atlas moth: hooked forewing tips, a window in every wing, a wavy pale band through all four.
            Specimen(c: P(0.05, 0.08), heading: 0.1, scale: 0.41,
                     fore: Wing(outline: [P(0.05, -0.06), P(0.3, -0.3), P(0.62, -0.5), P(0.88, -0.64), P(1.02, -0.69),
                                          P(1.13, -0.64), P(1.17, -0.54), P(1.12, -0.45), P(1.03, -0.44), P(0.96, -0.38),
                                          P(0.92, -0.24), P(0.88, -0.04), P(0.78, 0.12), P(0.46, 0.13), P(0.15, 0.03)],
                                veins: 9, lines: [0.26, 0.72], wave: 0.018, margin: 0.09, hatch: true,
                                eye: (0.1, 0.9, 0.035), window: true),
                     hind: Wing(outline: [P(0.06, 0.03), P(0.45, 0.0), P(0.74, 0.1), P(0.86, 0.32), P(0.8, 0.56),
                                          P(0.6, 0.72), P(0.35, 0.74), P(0.15, 0.56), P(0.05, 0.25)],
                                veins: 7, lines: [0.26, 0.7], wave: 0.018, margin: 0.09, window: true),
                     abdomen: 0.5, girth: 0.07, antenna: .feathered(0.06), spread: 0.05),
            // Luna moth: a slim eyespot in each wing, the hindwings drawn out into long curling tails.
            Specimen(c: P(-0.5, -0.58), heading: 0.95, scale: 0.33,
                     fore: Wing(outline: [P(0.05, -0.06), P(0.4, -0.3), P(0.8, -0.5), P(0.95, -0.53), P(1.0, -0.45),
                                          P(0.93, -0.2), P(0.78, 0.02), P(0.62, 0.1), P(0.35, 0.07), P(0.12, 0.02)],
                                veins: 9, lines: [0.66], wave: 0.008, margin: 0.06, eye: (0.5, 0.48, 0.07)),
                     hind: Wing(outline: [P(0.06, 0.03), P(0.45, 0.06), P(0.66, 0.18), P(0.7, 0.36), P(0.58, 0.54),
                                          P(0.44, 0.7), P(0.42, 0.95), P(0.47, 1.2), P(0.46, 1.36), P(0.39, 1.32),
                                          P(0.33, 1.08), P(0.28, 0.82), P(0.16, 0.6), P(0.04, 0.3)],
                                veins: 7, lines: [0.62], wave: 0.008, margin: 0.06, eye: (0.45, 0.42, 0.065)),
                     abdomen: 0.46, girth: 0.065, antenna: .feathered(0.07), spread: -0.06, label: false),
            // Swallowtail: lunules along the margins, a shaded base, the tails and an eye at each hindwing's inner angle.
            Specimen(c: P(0.44, -0.66), heading: -0.42, scale: 0.33,
                     fore: Wing(outline: [P(0.05, -0.06), P(0.4, -0.38), P(0.75, -0.6), P(0.95, -0.68), P(0.99, -0.6),
                                          P(0.89, -0.3), P(0.75, -0.02), P(0.6, 0.06), P(0.3, 0.04), P(0.12, 0.0)],
                                veins: 11, lines: [], margin: 0.12, lunules: true, basal: true),
                     hind: Wing(outline: [P(0.06, 0.03), P(0.4, 0.0), P(0.62, 0.08), P(0.72, 0.24), P(0.7, 0.4),
                                          P(0.62, 0.52), P(0.57, 0.6), P(0.6, 0.74), P(0.62, 0.86), P(0.59, 0.91),
                                          P(0.55, 0.87), P(0.53, 0.75), P(0.49, 0.64), P(0.36, 0.68), P(0.24, 0.66),
                                          P(0.14, 0.56), P(0.08, 0.38), P(0.04, 0.2)],
                                veins: 8, lines: [], margin: 0.11, eye: (0.9, 0.78, 0.055), lunules: true, basal: true),
                     abdomen: 0.5, girth: 0.05, antenna: .clubbed, spread: 0.07, label: false),
            // Emperor moth: a great ringed eye in every wing and wavy cross-lines.
            Specimen(c: P(0.66, 0.4), heading: -0.75, scale: 0.32,
                     fore: Wing(outline: [P(0.05, -0.06), P(0.35, -0.3), P(0.7, -0.45), P(0.9, -0.48), P(0.96, -0.38),
                                          P(0.88, -0.15), P(0.72, 0.04), P(0.5, 0.08), P(0.25, 0.05), P(0.1, 0.0)],
                                veins: 7, lines: [0.74], wave: 0.022, margin: 0.08, hatch: true,
                                eye: (0.52, 0.5, 0.12)),
                     hind: Wing(outline: [P(0.06, 0.03), P(0.4, 0.04), P(0.65, 0.12), P(0.75, 0.3), P(0.68, 0.5),
                                          P(0.48, 0.62), P(0.25, 0.6), P(0.1, 0.45), P(0.04, 0.22)],
                                veins: 5, lines: [0.74], wave: 0.022, margin: 0.08,
                                eye: (0.5, 0.5, 0.11)),
                     abdomen: 0.42, girth: 0.07, antenna: .feathered(0.08), spread: -0.05),
            // Hawkmoth: narrow swept forewings streaked along their veins, small banded hindwings, a long tapering body.
            Specimen(c: P(-0.68, 0.34), heading: 0.66, scale: 0.34,
                     fore: Wing(outline: [P(0.05, -0.08), P(0.4, -0.25), P(0.8, -0.38), P(1.05, -0.43), P(1.0, -0.33),
                                          P(0.85, -0.15), P(0.6, -0.02), P(0.35, 0.03), P(0.12, 0.0)],
                                veins: 7, lines: [0.34, 0.7], wave: 0.01, margin: 0.05, streaks: true),
                     hind: Wing(outline: [P(0.06, 0.01), P(0.3, 0.0), P(0.5, 0.08), P(0.53, 0.2), P(0.4, 0.31),
                                          P(0.2, 0.32), P(0.08, 0.2)],
                                veins: 5, lines: [0.45, 0.72], wave: 0.006, margin: 0.04),
                     abdomen: 0.62, girth: 0.12, antenna: .hooked, spread: 0.06),
            // Silk moth: plump and pale, faint cross-lines and a hooked forewing tip.
            Specimen(c: P(0.05, 0.66), heading: -0.14, scale: 0.29,
                     fore: Wing(outline: [P(0.05, -0.06), P(0.3, -0.25), P(0.6, -0.4), P(0.78, -0.45), P(0.83, -0.37),
                                          P(0.76, -0.32), P(0.75, -0.15), P(0.62, 0.04), P(0.4, 0.08), P(0.12, 0.02)],
                                veins: 7, lines: [0.38, 0.68], wave: 0.01),
                     hind: Wing(outline: [P(0.06, 0.03), P(0.35, 0.06), P(0.55, 0.15), P(0.58, 0.3), P(0.45, 0.42),
                                          P(0.25, 0.42), P(0.1, 0.3)],
                                veins: 5, lines: [0.6], wave: 0.008),
                     abdomen: 0.4, girth: 0.09, antenna: .feathered(0.06), spread: -0.04),
        ]
    }

    /// Small moths set in the gaps, unlabelled.
    private static var lesser: [Specimen] {
        let geometrid = Wing(outline: [P(0.05, -0.06), P(0.4, -0.3), P(0.78, -0.42), P(0.86, -0.32), P(0.74, -0.04),
                                       P(0.5, 0.06), P(0.15, 0.02)], veins: 5, lines: [0.4, 0.72], wave: 0.02)
        let geometridHind = Wing(outline: [P(0.06, 0.03), P(0.4, 0.04), P(0.66, 0.16), P(0.62, 0.36), P(0.4, 0.46),
                                           P(0.18, 0.4), P(0.06, 0.2)], veins: 5, lines: [0.62], wave: 0.02)
        let tiger = Wing(outline: [P(0.05, -0.06), P(0.5, -0.36), P(0.9, -0.48), P(0.92, -0.36), P(0.7, -0.02),
                                   P(0.4, 0.06), P(0.12, 0.02)], veins: 7, lines: [0.5], wave: 0.0,
                         eye: (0.4, 0.62, 0.09))
        let tigerHind = Wing(outline: [P(0.06, 0.03), P(0.45, 0.04), P(0.62, 0.2), P(0.5, 0.4), P(0.25, 0.42),
                                       P(0.08, 0.24)], veins: 5, margin: 0.08, lunules: true)
        return [
            Specimen(c: P(0.0, -0.8), heading: -0.15, scale: 0.15, fore: geometrid, hind: geometridHind,
                     abdomen: 0.4, girth: 0.06, antenna: .feathered(0.05), spread: 0.08, label: false),
            Specimen(c: P(-0.7, -0.1), heading: -0.9, scale: 0.15, fore: tiger, hind: tigerHind,
                     abdomen: 0.4, girth: 0.07, antenna: .clubbed, spread: -0.05, label: false),
            Specimen(c: P(0.72, -0.14), heading: 1.15, scale: 0.15, fore: geometrid, hind: geometridHind,
                     abdomen: 0.38, girth: 0.06, antenna: .hooked, spread: 0.1, label: false),
        ]
    }


    /// A closed Catmull-Rom curve through `p`, ending where it starts.
    private static func smooth(_ p: [P], _ m: Int = 10) -> [P] {
        var out: [P] = []
        let n = p.count
        for i in 0..<n {
            let p0 = p[(i + n - 1) % n], p1 = p[i], p2 = p[(i + 1) % n], p3 = p[(i + 2) % n]
            for k in 0..<m {
                let t = Double(k) / Double(m), t2 = t * t, t3 = t2 * t
                let a = 2 * p1, b = p2 - p0, c = 2 * p0 - 5 * p1 + 4 * p2 - p3, d = 3 * p1 - p0 - 3 * p2 + p3
                out.append(0.5 * (a + b * t + c * t2 + d * t3))
            }
        }
        out.append(out[0])
        return out
    }

    private static func ray(_ a: Double) -> P { P(cos(a), sin(a)) }

    /// How far a ray from `o` along `d` runs before it last leaves the closed polygon.
    private static func reach(_ poly: [P], _ o: P, _ d: P) -> Double {
        var best = 0.0
        for i in 0..<(poly.count - 1) {
            let a = poly[i], e = poly[i + 1] - a, den = d.x * e.y - d.y * e.x
            guard abs(den) > 1e-12 else { continue }
            let w = a - o, t = (w.x * e.y - w.y * e.x) / den, s = (w.x * d.y - w.y * d.x) / den
            if t > 0, s >= 0, s <= 1 { best = max(best, t) }
        }
        return best
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

    /// The runs of a polyline that lie outside `hull`.
    private static func clip(_ points: [P], _ hull: [P]) -> [[P]] {
        var runs: [[P]] = [], run: [P] = []
        for p in points {
            if inside(p, hull) {
                if run.count > 1 { runs.append(run) }
                run = []
            } else {
                run.append(p)
            }
        }
        if run.count > 1 { runs.append(run) }
        return runs
    }


    /// A wing's lines in its own frame, and its outline for hiding what lies under it.
    private static func wing(_ w: Wing, _ rng: inout SplitMix64) -> (hull: [P], lines: [(points: [P], width: Double)]) {
        var lines: [(points: [P], width: Double)] = []
        let hull = smooth(w.outline)
        let base = w.outline[0]
        let centroid = hull.reduce(P.zero, +) / Double(hull.count)
        let focus = base + 0.06 * (centroid - base)
        let axis = atan2(centroid.y - focus.y, centroid.x - focus.x)
        let far = hull.map { simd_distance($0, focus) }.max()!
        var lo = 0.0, hi = 0.0
        for p in hull where simd_distance(p, focus) > 0.3 * far {
            let a = remainder(atan2(p.y - focus.y, p.x - focus.x) - axis, 2 * .pi)
            lo = min(lo, a)
            hi = max(hi, a)
        }
        lo += 0.05
        hi -= 0.05
        lines.append((hull, E.medium))
        func angle(_ u: Double) -> Double { axis + lo + (hi - lo) * u }
        func r(_ a: Double) -> Double { reach(hull, focus, ray(a)) }
        func at(_ u: Double, _ f: Double) -> P { let a = angle(u); return focus + f * r(a) * ray(a) }
        let samples = (0...120).map { r(angle(Double($0) / 120)) }.sorted()
        let cap = samples[Int(0.8 * Double(samples.count - 1))]

        // The discal cell, and the veins: the outer two from the base, the rest from the cell's end.
        let cellLo = 0.3, cellHi = 0.66
        let cellEnd = (0...12).map { k -> P in
            let u = cellLo + (cellHi - cellLo) * Double(k) / 12
            let a = angle(u)
            return focus + (0.46 + 0.03 * sin(.pi * Double(k) / 12)) * min(r(a), cap) * ray(a)
        }
        lines.append(([focus] + cellEnd + [focus], E.fine))
        for k in 0..<w.veins {
            let u = (Double(k) + 0.5) / Double(w.veins) + Double.random(in: -0.015..<0.015, using: &rng)
            let a = angle(u), end = focus + 0.985 * r(a) * ray(a)
            let inCell = u > cellLo && u < cellHi
            let start = inCell ? cellEnd[Int(((u - cellLo) / (cellHi - cellLo) * 12).rounded())] : focus
            let mid = (start + end) / 2 + 0.03 * simd_distance(start, end) * ray(a + .pi / 2)
            lines.append((E.curve(start, mid, end, 16), E.fine))
            if k == 1, w.veins > 6 {
                let fork = E.curve(start, mid, end, 16)[10]
                lines.append((E.curve(fork, fork + 0.5 * (end - fork) + 0.05 * ray(a - .pi / 2), at(u - 0.06, 0.98), 12), E.fine))
            }
        }
        if w.basal {
            let d = ray(axis + 0.5), n = P(-d.y, d.x)
            var k = -0.6
            while k < 0.6 {
                var run: [P] = []
                for i in 0...80 {
                    let p = focus + (-0.2 + 0.9 * Double(i) / 80) * d + k * n, q = p - focus
                    let a = atan2(q.y, q.x)
                    if inside(p, hull), simd_length(q) < 0.36 * min(r(a), cap) {
                        run.append(p)
                    } else {
                        if run.count > 1 { lines.append((run, E.fine)) }
                        run = []
                    }
                }
                if run.count > 1 { lines.append((run, E.fine)) }
                k += 0.022
            }
        }
        if w.streaks {
            // Hawkmoth streaks: long dashes in the spaces between the veins.
            for k in 1..<w.veins {
                let u = Double(k) / Double(w.veins)
                lines.append(((0...10).map { at(u, 0.3 + 0.5 * Double($0) / 10) }, E.fine))
            }
        }
        // Transverse lines, waving between the veins.
        for f in w.lines {
            // Slanted across the wing, so no line is an arc about the body that a core turning on it would leave in place.
            let n = 90, ph = Double.random(in: 0..<(2 * .pi), using: &rng), slant = f > 0.5 ? 0.16 : -0.12
            lines.append(((0...n).map { i in
                let u = Double(i) / Double(n), a = angle(u)
                let rr = min(r(a), cap) * (f + slant * (u - 0.5)) + w.wave * sin(Double(w.veins) * .pi * u + ph)
                return focus + rr * ray(a)
            }, E.fine))
            if w.wave > 0.015, f > 0.5 {
                lines.append(((0...n).map { i in
                    let u = Double(i) / Double(n), a = angle(u)
                    return focus + (min(r(a), cap) * (f + slant * (u - 0.5)) + 0.022 + w.wave * sin(Double(w.veins) * .pi * u + ph)) * ray(a)
                }, E.fine))
            }
        }
        // The submarginal line, and the marginal band's scales hatched between it and the edge.
        if w.margin > 0 {
            var run: [P] = []
            for i in 0...120 {
                let a = angle(Double(i) / 120), rr = r(a)
                if rr > 1.25 * cap || rr - w.margin < 0.5 * rr {
                    if run.count > 1 { lines.append((run, E.fine)) }
                    run = []
                    continue
                }
                run.append(focus + (rr - w.margin + 0.008 * sin(Double(i) * 0.9)) * ray(a))
            }
            if run.count > 1 { lines.append((run, E.fine)) }
            if w.hatch {
                for i in stride(from: 2, to: 118, by: 4) {
                    let a = angle(Double(i) / 120), rr = r(a)
                    guard rr < 1.25 * cap, rr - w.margin > 0.5 * rr else { continue }
                    let s = focus + (rr - w.margin + 0.012) * ray(a), e = focus + (rr - 0.012) * ray(a + 0.015)
                    lines.append(([s, e], E.fine))
                }
            }
        }
        if w.lunules {
            // A crescent in each space between the veins, inside the margin.
            for k in 1..<w.veins {
                let u = Double(k) / Double(w.veins), a = angle(u), rr = r(a)
                guard rr < 1.25 * cap else { continue }
                let c = focus + (rr - 0.55 * w.margin) * ray(a), size = 0.32 * w.margin + 0.008
                lines.append((E.arc(c, size, from: a + .pi / 2 - 1.2 + .pi, to: a + .pi / 2 + 1.2 + .pi, 10)
                              + E.arc(c - 0.4 * size * ray(a), size * 0.9, from: a + .pi / 2 + 1.0 + .pi,
                                      to: a + .pi / 2 - 1.0 + .pi, 10), E.fine))
            }
        }
        if let eye = w.eye {
            let c = at(eye.across, eye.out), a = angle(eye.across)
            let u = ray(a), v = ray(a + .pi / 2)
            for (k, f) in [1.0, 0.72, 0.46].enumerated() {
                let off = 0.08 * eye.r * Double(k) * u
                lines.append(((0...40).map { i in
                    let t = 2 * .pi * Double(i) / 40
                    return c + off + f * eye.r * (1.15 * cos(t) * u + 0.9 * sin(t) * v)
                }, k == 0 ? E.medium : E.fine))
            }
            // The pupil's highlight, a crescent off-centre.
            let pc = c + 0.1 * eye.r * u - 0.12 * eye.r * v
            lines.append((E.arc(pc, 0.2 * eye.r, from: a + 2.2, to: a + 4.4, 10), E.fine))
        }
        if w.window {
            let tri = smooth([at(0.38, 0.38), at(0.6, 0.4), at(0.5, 0.58)], 5)
            lines.append((tri, E.medium))
            let inner = tri.map { $0 + 0.22 * (at(0.5, 0.45) - $0) }
            lines.append((inner, E.fine))
        }
        return (hull, lines)
    }


    private static func specimen(_ out: inout [Line], _ rng: inout SplitMix64, _ s: Specimen) {
        let up = E.dir(s.heading), right = P(-up.y, up.x)
        func world(_ p: P) -> P { s.c + s.scale * (p.x * right - p.y * up) }
        let fore = wing(s.fore, &rng), hind = wing(s.hind, &rng)
        for side in [1.0, -1.0] {
            let turn = side < 0 ? s.spread : 0
            func place(_ p: P) -> P {
                let q = P(p.x * cos(turn) - p.y * sin(turn), p.x * sin(turn) + p.y * cos(turn))
                return world(P(side * q.x, q.y))
            }
            for l in fore.lines { out.append(Line(points: l.points.map(place), width: l.width)) }
            for l in hind.lines {
                for run in clip(l.points, fore.hull) { out.append(Line(points: run.map(place), width: l.width)) }
            }
        }
        body(&out, &rng, s, world)
        if s.label {
            // The label pinned under the specimen, ruled in a fair hand.
            let low = (s.hind.outline + s.fore.outline).map(\.y).max()!
            let w = 0.3, h = 0.1, top = max(s.abdomen + 0.08, low) + 0.08
            let box = [P(-w, top), P(w, top), P(w, top + h), P(-w, top + h), P(-w, top)]
            out.append(Line(points: box.map(world), width: E.fine))
            for (k, len) in [0.62, 0.4].enumerated() {
                let y = top + 0.04 + 0.04 * Double(k), ph = Double.random(in: 0..<6, using: &rng)
                out.append(Line(points: (0...40).map { i in
                    let x = -w + 0.08 + 2 * (w - 0.08) * len * Double(i) / 40
                    return world(P(x, y + 0.008 * sin(Double(i) * 1.9 + ph)))
                }, width: E.fine))
            }
        }
    }

    private static func body(_ out: inout [Line], _ rng: inout SplitMix64, _ s: Specimen, _ world: (P) -> P) {
        let g = s.girth
        // Head and eyes.
        out.append(Line(points: E.circle(P(0, -0.12), 0.04, 20).map(world), width: E.medium))
        for x in [-0.03, 0.028] { out.append(Line(points: E.circle(P(x, -0.135), 0.014, 10).map(world), width: E.fine)) }
        // The thorax, furred.
        out.append(Line(points: (0...40).map { i in
            let t = 2 * .pi * Double(i) / 40
            return world(P(g * cos(t), -0.01 + 0.09 * sin(t)))
        }, width: E.medium))
        for _ in 0..<14 {
            let p = P(Double.random(in: -0.7..<0.7, using: &rng) * g, Double.random(in: -0.08..<0.06, using: &rng))
            out.append(Line(points: [world(p), world(p + P(0.01 * p.x / g, 0.025))], width: E.fine))
        }
        // The abdomen: tapering, its segments ringed.
        let top = 0.08, len = s.abdomen
        func half(_ t: Double) -> Double { 0.85 * g * sin(.pi * min(1, 0.15 + 0.85 * t)) * (1 - 0.35 * t) + 0.006 }
        for side in [-1.0, 1.0] {
            out.append(Line(points: (0...40).map { i in
                let t = Double(i) / 40
                return world(P(side * half(t), top + len * t))
            }, width: E.medium))
        }
        for k in 1..<8 {
            let t = Double(k) / 8, y = top + len * t, w = half(t)
            out.append(Line(points: E.curve(P(-w, y), P(0, y + 0.6 * w), P(w, y), 10).map(world), width: E.fine))
        }
        // The pin through the thorax.
        out.append(Line(points: E.circle(P(0.012, -0.01), 0.016, 12).map(world), width: E.fine))
        // Antennae from the head, out and forward.
        for side in [-1.0, 1.0] {
            let root = P(side * 0.025, -0.15), tip = P(side * 0.3, -0.5)
            let ctrl = P(side * 0.08, -0.42)
            let shaft = E.curve(root, ctrl, tip, 30)
            out.append(Line(points: shaft.map(world), width: E.fine))
            switch s.antenna {
            case .feathered(let width):
                for i in stride(from: 3, to: 29, by: 2) {
                    let p = shaft[i], d = simd_normalize(shaft[i + 1] - shaft[i - 1]), n = P(-d.y, d.x)
                    let w = width * sin(.pi * Double(i) / 30)
                    out.append(Line(points: [p + w * (0.8 * n + 0.5 * d), p, p - w * (0.8 * n - 0.5 * d)].map(world),
                                    width: E.fine))
                }
            case .clubbed:
                let d = simd_normalize(tip - shaft[27])
                out.append(Line(points: (0...16).map { i in
                    let t = 2 * .pi * Double(i) / 16
                    return world(tip + 0.02 * d + 0.035 * cos(t) * d + 0.015 * sin(t) * P(-d.y, d.x))
                }, width: E.fine))
            case .hooked:
                out.append(Line(points: E.curve(tip, tip + P(side * 0.06, -0.02), tip + P(side * 0.07, 0.04), 8).map(world),
                                width: E.medium))
            }
        }
    }

    /// The silk moth's cocoons beside it, wound in crossing threads, and its caterpillar on a mulberry leaf.
    private static func silk(_ out: inout [Line], _ rng: inout SplitMix64) {
        for (c, a, size) in [(P(0.42, 0.84), 0.5, 0.075), (P(0.6, 0.74), -0.3, 0.064), (P(0.26, 0.9), 2.0, 0.06)] {
            let u = P(cos(a), sin(a)), v = P(-u.y, u.x)
            let shell = (0...40).map { i -> P in
                let t = 2 * .pi * Double(i) / 40
                return c + size * cos(t) * u + 0.55 * size * (1 - 0.12 * cos(t)) * sin(t) * v
            }
            out.append(Line(points: shell, width: E.medium))
            out.append(Line(points: E.curve(c - 0.5 * size * v - 0.05 * size * u, c - 0.05 * size * u,
                                            c + 0.5 * size * v - 0.05 * size * u, 8), width: E.fine))
            for k in 0..<9 {
                let x = -0.85 + 1.7 * Double(k) / 8 + Double.random(in: -0.05..<0.05, using: &rng)
                let p = c + x * size * u, w = 0.5 * size * sqrt(max(0, 1 - x * x))
                out.append(Line(points: [p - w * v - 0.18 * size * u, p + w * v + 0.18 * size * u], width: E.fine))
            }
        }
        // The mulberry leaf: a toothed heart on its stalk, veined from the base.
        let stalk = P(-0.2, 0.95), tip = P(-0.62, 0.62), axis = simd_normalize(tip - stalk), side = P(-axis.y, axis.x)
        let length = simd_distance(stalk, tip)
        out.append(Line(points: E.curve(stalk + 0.08 * axis - 0.1 * side, stalk + 0.02 * side, stalk + 0.12 * axis, 10)
                        .map { $0 - 0.1 * axis }, width: E.medium))
        for s in [-1.0, 1.0] {
            let teeth = 13
            var edge: [P] = []
            for i in 0...(teeth * 4) {
                let t = Double(i) / Double(teeth * 4)
                let w = 0.42 * length * pow(sin(.pi * pow(t, 0.75)), 0.9) * (1 + 0.25 * (1 - t) * (1 - t))
                let tooth = i % 4 == 2 ? 0.018 : 0
                edge.append(stalk + (length * t - 0.03 * (1 - t) * (1 - t)) * axis + s * (w + tooth) * side)
            }
            out.append(Line(points: edge, width: E.fine))
            for k in 0..<5 {
                let t0 = 0.06 + 0.17 * Double(k), t1 = min(1, t0 + 0.24)
                let w1 = 0.36 * length * pow(sin(.pi * pow(t1, 0.75)), 0.9)
                out.append(Line(points: E.curve(stalk + length * t0 * axis, stalk + length * (t0 + 0.04) * axis + s * 0.5 * w1 * side,
                                                stalk + length * t1 * axis + s * 0.9 * w1 * side, 12), width: E.fine))
            }
        }
        out.append(Line(points: [stalk, tip], width: E.medium))
        caterpillar(&out, P(-0.5, 0.64), P(-0.38, 0.84), P(-0.26, 0.74), girth: 0.022, stripes: false)
    }

    /// A caterpillar along the curve from its head at `a` to its tail at `b`: ringed, prolegs beneath, the horn at its
    /// tail and, on a hawkmoth's, oblique stripes down its flank.
    private static func caterpillar(_ out: inout [Line], _ a: P, _ ctrl: P, _ b: P, girth: Double, stripes: Bool) {
        let spine = E.curve(a, ctrl, b, 60)
        func half(_ t: Double) -> Double { girth * (0.7 + 0.3 * sin(.pi * min(1, t * 1.2))) }
        func normal(_ i: Int) -> P {
            let d = simd_normalize(spine[min(i + 1, 60)] - spine[max(i - 1, 0)])
            return P(-d.y, d.x)
        }
        for s in [-1.0, 1.0] {
            out.append(Line(points: spine.indices.map { spine[$0] + s * half(Double($0) / 60) * normal($0) }, width: E.medium))
        }
        for k in 1..<13 {
            let i = k * 60 / 13, n = normal(i), d = P(n.y, -n.x), w = half(Double(i) / 60)
            out.append(Line(points: E.curve(spine[i] - w * n, spine[i] - 0.4 * w * d, spine[i] + w * n, 8), width: E.fine))
            if k % 3 != 1 {
                out.append(Line(points: [spine[i] + w * n, spine[i] + 1.5 * w * n - 0.2 * w * d], width: E.fine))
            }
            if stripes, k < 12 {
                let j = (k + 1) * 60 / 13
                out.append(Line(points: [spine[i] + 0.85 * w * n, spine[j] - 0.3 * half(Double(j) / 60) * normal(j)], width: E.fine))
            }
        }
        out.append(Line(points: E.circle(a - 0.6 * girth * simd_normalize(ctrl - a), 0.75 * girth, 14), width: E.medium))
        let tail = spine[57], back = simd_normalize(spine[60] - spine[54]), side = P(-back.y, back.x)
        let horn = stripes ? 2.6 * girth : 2.2 * girth
        out.append(Line(points: E.curve(tail, tail + 0.6 * horn * back - 0.9 * girth * side, tail + horn * back - 1.6 * girth * side, 8),
                        width: E.fine))
    }
}
