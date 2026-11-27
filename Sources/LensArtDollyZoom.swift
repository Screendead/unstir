// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 62 to 67, the chapter Dolly zoom.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let dollyZoom: [Int: Halftone.Panel] = [65: sextant, 67: spectroscope]

    /// A frame's tone from its last band's end, in degrees clockwise from three o'clock, up to `end`.
    fileprivate struct Band: Sendable {
        var end: Double
        var tone: Tone
    }

    /// A lens's glass, a flat tone out to `glass`, in a frame out to `rim` whose tone changes along it, so a neighbour's
    /// twist that slides the rim along itself shows. Both stay inside the core: hex's cores are 0.032 apart.
    fileprivate struct Glass: Sendable {
        var centre: P
        var glass: Double
        var rim: Double
        var tone: Tone
        var bands: [Band]

        func tone(at p: P) -> Tone? {
            let d = p - centre, r2 = simd_length_squared(d)
            guard r2 < rim * rim else { return nil }
            if r2 < glass * glass { return tone }
            var a = atan2(d.y, d.x) * 180 / .pi
            if a < 0 { a += 360 }
            for b in bands where a < b.end { return b.tone }
            return bands[0].tone
        }
    }

    fileprivate static func glass(_ centre: P, _ tone: Tone, frame: [(Double, Tone)], glass: Double = 0.2, rim: Double = 0.258) -> Glass {
        Glass(centre: centre, glass: glass, rim: rim, tone: tone, bands: frame.map { Band(end: $0.0, tone: $0.1) })
    }

    /// The glasses first, then the fills, the first that holds a point giving its tone, over `ground`.
    fileprivate static func drawn(_ name: String, glasses: [Glass], fills: [Fill], strokes: [Halftone.Stroke],
                                  ground: @escaping @Sendable (P) -> Tone) -> Halftone.Panel {
        Halftone.Panel(name: name, tones: { p in
            for g in glasses { if let t = g.tone(at: p) { return t } }
            for f in fills where f.holds(p) { return f.tone }
            return ground(p)
        }, strokes: strokes)
    }

    /// A circle as `pieces` arcs, so each pixel tests only the arcs whose boxes reach it.
    fileprivate static func hoop(_ c: P, _ r: Double, _ width: Double, pieces: Int = 6) -> [Halftone.Stroke] {
        (0..<pieces).map { k in stroke(arc(c, r, 360 * Double(k) / Double(pieces), 360 * Double(k + 1) / Double(pieces), 10), width) }
    }

    /// A long line as pieces of `n` steps each, for the same reason.
    fileprivate static func pieces(_ line: [P], _ width: Double, every n: Int = 8) -> [Halftone.Stroke] {
        stride(from: 0, to: line.count - 1, by: n).map { stroke(Array(line[$0...min($0 + n, line.count - 1)]), width) }
    }

    /// A ring's fill with its box cut to `lo` and `hi`, so only that stretch of it shows and costs a test.
    fileprivate static func band(_ c: P, _ inner: Double, _ outer: Double, _ tone: Tone, lo: P, hi: P) -> Fill {
        var f = ring(c, inner, outer, tone)
        f.lo = simd_max(f.lo, lo)
        f.hi = simd_min(f.hi, hi)
        return f
    }
}

// MARK: - 65: Sextant

/// Level 65's name: a brass sextant held up against the sea at sunset, its index arm swung down from the mirror at its
/// apex to the scale along its foot, coloured shades folded out beside the mirror and its telescope across the frame.
/// The five lenses are its glasses: the telescope's eyepiece over the upper right core, where the sun sits on the
/// horizon; the horizon glass over the upper left, half silvered, a ship hull down in its clear half; the reading
/// glass over the scale at the bottom, the vernier on forty degrees; and two holes in the cast frame low on each side,
/// the new moon and a star through the right and an island with its palm through the left.
extension LensArt {
    static let sextant: Halftone.Panel = {
        let pivot = P(0.06, -0.78), spread = 38.0, limb = (1.18, 1.4), sea = -0.05
        let eyepiece = P(0.485, -0.28), horizon = P(-0.485, -0.28), reader = P(0, 0.56), moonHole = P(0.485, 0.28), isleHole = P(-0.485, 0.28)
        let brass = y(0.72), dark = Tone.zero, silver = Tone(0.4, 0.4, 0.4)
        func onArc(_ degrees: Double, _ r: Double) -> P { pivot + r * P(sin(degrees * .pi / 180), cos(degrees * .pi / 180)) }
        let index = bar(pivot, reader, 0.08), tube = bar(P(-0.24, -0.28), P(0.27, -0.28), 0.12)
        let mirror = rect(pivot.x - 0.03, -0.95, pivot.x + 0.16, -0.78), hole = P(-0.17, 0.16), hinge = P(-0.1, -0.72)
        let shadeTones = [(158.0, m(0.85)), (182.0, Tone(0.7, 0, 0.6)), (206.0, c(0.9))]
        let shades = shadeTones.map { bar(polar(hinge, 0.02, $0.0), polar(hinge, 0.27, $0.0), 0.075) }
        let glasses = [
            glass(eyepiece, m(0.7), frame: [(40, dark), (95, silver), (130, dark), (215, silver), (250, dark), (360, y(0.9))]),
            glass(horizon, c(0.8), frame: [(70, brass), (100, m(0.7)), (200, brass), (225, dark), (360, brass)]),
            glass(reader, c(0.72), frame: [(30, dark), (75, brass), (160, dark), (190, y(0.95)), (300, dark), (360, brass)]),
            glass(moonHole, Tone(0.3, 0, 0.1), frame: [(50, silver), (90, dark), (240, silver), (275, dark), (360, silver)]),
            glass(isleHole, Tone(0.45, 0, 0.45), frame: [(120, silver), (150, dark), (290, silver), (320, dark), (360, silver)]),
        ]
        var sun = oval(P(-0.84, sea), 0.13, 0.13, y(0.9))
        sun.hi.y = sea
        let fills = zip(shades, shadeTones).map { fill($0.0, $0.1.1) }
            + [fill(mirror, c(0.75)), disc(pivot, 0.06, dark), fill(tube, dark), fill(index, silver), disc(hole, 0.11, c(0.42)), sun]

        var s: [Halftone.Stroke] = []
        // The frame: its two sides from the apex, the limb along its foot and the limb's scale, and a hole in its casting.
        let clear = { (p: P) in glasses.allSatisfy { simd_distance(p, $0.centre) > $0.rim } }
        for side in [-spread, spread] { s += runs(span(pivot, onArc(side, limb.1), 40), bold, keep: clear) }
        s += runs(arc(pivot, limb.0, 90 - spread, 90 + spread, 120), mid, keep: clear) + runs(arc(pivot, limb.1, 90 - spread, 90 + spread, 120), bold, keep: clear)
        for k in -18...18 {
            let a = 2 * Double(k), long = k % 5 == 0, tick = [onArc(a, limb.1 - 0.02), onArc(a, long ? limb.0 + 0.02 : limb.0 + 0.1)]
            if tick.allSatisfy(clear) { s.append(stroke(tick, long ? mid : hair)) }
        }
        s += hoop(hole, 0.11, mid, pieces: 3)
        // The sea's horizon either side of the frame, the sun setting into it, and swell.
        for side in [-1.0, 1.0] {
            s += runs(span(P(side * 0.4, sea), P(side, sea), 30), mid) { p in simd_distance(p, eyepiece) > 0.26 && simd_distance(p, horizon) > 0.26 }
        }
        s += pieces(arc(P(-0.84, sea), 0.13, 180, 360, 12), mid, every: 6)
        for at in [P(-0.86, 0.12), P(0.84, 0.08), P(-0.74, 0.62), P(0.8, 0.6), P(-0.9, 0.38), P(0.92, 0.32)] {
            s.append(stroke(curve(at + P(-0.05, 0), at + P(-0.025, -0.025), at, 5) + curve(at, at + P(0.025, 0.025), at + P(0.05, 0), 5), hair))
        }
        // The index arm on its pivot, the mirror over it, the shades folded out on their hinge.
        s.append(stroke(closed(index), mid))
        s.append(stroke(closed(mirror), bold))
        s.append(stroke([P(mirror[0].x + 0.04, -0.92), P(mirror[1].x - 0.03, -0.82)], hair))
        for q in shades { s.append(stroke(closed(q), mid)) }
        s += hoop(pivot, 0.06, bold, pieces: 2) + hoop(hinge, 0.025, mid, pieces: 1)
        // The telescope, banded.
        s.append(stroke(closed(tube), mid))
        for x in [-0.14, 0.04, 0.18] { s.append(stroke([P(x, -0.34), P(x, -0.22)], mid)) }
        // Every glass's rims.
        for g in glasses {
            s += hoop(g.centre, g.rim, bold)
            s += hoop(g.centre, g.glass, mid)
        }
        // Through the eyepiece: the sun on the horizon, and a gull.
        let e = eyepiece + P(0.024, -0.004)
        s += runs(span(eyepiece + P(-0.17, 0.012), eyepiece + P(0.17, 0.012), 34), 0.0028) { abs($0.x - e.x) > 0.024 }
        s.append(stroke(arc(e + P(0, 0.016), 0.028, 180, 360, 14), 0.0045))
        for k in 0..<5 { s.append(stroke([polar(e + P(0, 0.016), 0.036, 200 + 35 * Double(k)), polar(e + P(0, 0.016), 0.05, 200 + 35 * Double(k))], 0.003)) }
        for k in 0..<3 { s.append(stroke([e + P(-0.022 + 0.008 * Double(k), 0.024 + 0.008 * Double(k)), e + P(0.022 - 0.008 * Double(k), 0.024 + 0.008 * Double(k))], 0.0024)) }
        s.append(stroke(curve(e + P(-0.07, -0.05), e + P(-0.058, -0.064), e + P(-0.046, -0.05), 5) + curve(e + P(-0.046, -0.05), e + P(-0.034, -0.064), e + P(-0.022, -0.05), 5), 0.0024))
        // Through the horizon glass: the silvered half's edge and, in the clear half, a ship on the horizon.
        let h = horizon + P(-0.028, -0.004)
        s.append(stroke([horizon + P(0.012, -0.17), horizon + P(0.012, 0.17)], 0.0024))
        s += runs(span(horizon + P(-0.17, 0.02), horizon + P(0.012, 0.02), 30), 0.0028) { abs($0.x - h.x) > 0.03 }
        s.append(stroke(closed([h + P(-0.03, 0.012), h + P(0.03, 0.012), h + P(0.022, 0.024), h + P(-0.024, 0.024)]), 0.0034))
        s.append(stroke([h + P(0, 0.012), h + P(0, -0.04)], 0.003))
        s.append(stroke(closed([h + P(0.004, -0.036), h + P(0.026, 0.006), h + P(0.004, 0.006)]), 0.0026))
        s.append(stroke(closed([h + P(-0.004, -0.03), h + P(-0.024, 0.006), h + P(-0.004, 0.006)]), 0.0026))
        // Under the reading glass: the scale's degrees, forty marked, and the vernier's index against it.
        let v = reader + P(-0.006, -0.026)
        s.append(stroke([v + P(-0.07, 0), v + P(0.07, 0)], 0.0024))
        for k in -6...6 { s.append(stroke([v + P(0.011 * Double(k), 0), v + P(0.011 * Double(k), k % 5 == 0 ? -0.022 : -0.012)], 0.002)) }
        for k in -5...5 { s.append(stroke([v + P(0.0099 * Double(k), 0.006), v + P(0.0099 * Double(k), k == 0 ? 0.026 : 0.016)], 0.0018)) }
        let d = v + P(-0.012, -0.05)
        s.append(stroke([d + P(0.004, 0.012), d + P(-0.008, 0.012), d + P(0.0, -0.012), d + P(0.0, 0.018)], 0.0026))
        s.append(stroke(ellipse(d + P(0.022, 0.003), 0.008, 0.015, 14), 0.0026))
        // Through the right hole: the new moon and a star by it.
        let mo = moonHole + P(0.022, -0.018)
        s.append(stroke(arc(mo, 0.03, 60, 300, 18) + arc(mo + P(0.016, 0), 0.026, 240, 120, 14), 0.0038))
        s.append(stroke(star(mo + P(0.05, 0.03), 0.012), 0.0026))
        s.append(stroke(star(mo + P(-0.08, 0.07), 0.008), 0.002))
        // Through the left hole: an island, its palm, and the sea.
        let i = isleHole + P(-0.02, 0.012)
        s.append(stroke(curve(i + P(-0.06, 0.012), i + P(0, -0.024), i + P(0.06, 0.012), 12), 0.0034))
        s += runs(span(isleHole + P(-0.17, 0.024), isleHole + P(0.17, 0.024), 34), 0.0024) { abs($0.x - i.x) > 0.07 }
        s.append(stroke(curve(i + P(0.004, -0.006), i + P(0.014, -0.03), i + P(0.006, -0.056), 6), 0.004))
        for a in [-170.0, -130, -60, -20] { s.append(stroke(curve(i + P(0.006, -0.056), polar(i + P(0.006, -0.056), 0.02, a - 15), polar(i + P(0.006, -0.056), 0.036, a + 25), 6), 0.0034)) }
        return drawn("sextant", glasses: glasses, fills: fills, strokes: s) { p in
            // The frame, a sixth of a circle cast in brass from the apex, its limb inlaid in silver.
            let q = p - pivot, r = simd_length(q)
            if r < limb.1, abs(atan2(q.x, q.y)) < spread * .pi / 180 { return r < limb.0 ? brass : silver }
            return p.y < sea ? m(0.3) : c(0.42)
        }
    }()
}

// MARK: - 67: Spectroscope

/// Level 67's name: Kirchhoff and Bunsen's spectroscope, a prism under its drum over the hub with brass tubes out to
/// the lower ring, a burner's flame at the end of the slit's tube, and the light it splits fanned out across the right
/// of the glass in six broad bands of colour. The five lenses: over the hub, the prism under the drum bending a ray
/// into a fan; over the top core the sun in eclipse, its corona and a flame of its edge, where helium was first seen;
/// over the upper left the slit, the flame between its jaws; over the lower left the eyepiece, sodium's two lines and
/// its name; and over the bottom the scale's tube, hydrogen's four lines and its letter.
extension LensArt {
    static let spectroscope: Halftone.Panel = {
        let drum = P(0, 0), sun = P(0, -0.56), slit = P(-0.485, -0.28), eye = P(-0.485, 0.28), scale = P(0, 0.56)
        let brass = y(0.65), dark = Tone.zero, flame = P(-0.78, -0.47)
        let bands = [Tone(0, 0.75, 0.55), y(0.9), Tone(0.55, 0, 0.75), c(0.85), Tone(0.7, 0.5, 0), m(0.75)]
        let fan = (-45.0, 45.0)
        let glasses = [
            glass(drum, c(0.5), frame: [(25, brass), (60, dark), (150, brass), (170, dark), (290, brass), (325, m(0.7)), (360, brass)]),
            glass(sun, m(0.5), frame: [(60, dark), (100, y(0.85)), (200, dark), (220, y(0.85)), (330, dark), (360, y(0.85))]),
            glass(slit, y(0.75), frame: [(30, brass), (140, dark), (175, brass), (250, dark), (360, brass)]),
            glass(eye, m(0.7), frame: [(80, dark), (110, brass), (230, dark), (265, c(0.7)), (360, dark)]),
            glass(scale, c(0.65), frame: [(50, brass), (75, dark), (200, brass), (235, dark), (300, brass), (330, dark), (360, brass)]),
        ]
        let tubes = [slit, eye, scale].map { bar(drum, $0, 0.13) }
        var fills = [oval(flame, 0.05, 0.085, y(0.9)), oval(flame + P(0, 0.03), 0.026, 0.04, c(0.8)), fill(rect(flame.x - 0.025, flame.y + 0.09, flame.x + 0.025, flame.y + 0.3), brass)]
        fills += tubes.map { fill($0, brass) }

        var s: [Halftone.Stroke] = []
        let clear = { (p: P) in glasses.allSatisfy { simd_distance(p, $0.centre) > $0.rim } }
        // The fan's bands and the card they fall on.
        for k in 0...6 {
            let a = fan.0 + (fan.1 - fan.0) * Double(k) / 6
            s += runs(span(polar(drum, 0.26, a), polar(drum, 0.97, a), 40), k == 0 || k == 6 ? mid : hair, keep: clear)
        }
        s += pieces(arc(drum, 0.93, fan.0 - 4, fan.1 + 4, 32), bold)
        // The tubes, banded where they join their glasses, the burner and its flame.
        for t in tubes {
            s += runs(span(t[0], t[1], 30), mid, keep: clear) + runs(span(t[3], t[2], 30), mid, keep: clear)
        }
        s.append(stroke(ellipse(flame, 0.05, 0.085, 20), mid))
        s.append(stroke(ellipse(flame + P(0, 0.03), 0.026, 0.04, 14), hair))
        s.append(stroke(closed(rect(flame.x - 0.025, flame.y + 0.09, flame.x + 0.025, flame.y + 0.3)), mid))
        s.append(stroke(closed(rect(flame.x - 0.07, flame.y + 0.3, flame.x + 0.07, flame.y + 0.34)), mid))
        for g in glasses {
            s += hoop(g.centre, g.rim, bold)
            s += hoop(g.centre, g.glass, mid)
        }
        // Under the drum: the prism, a ray into it and its fan out.
        let pr = drum + P(0.012, -0.026)
        s.append(stroke(closed([pr + P(0, -0.03), pr + P(0.028, 0.018), pr + P(-0.028, 0.018)]), 0.004))
        s.append(stroke([pr + P(-0.09, 0.02), pr + P(-0.016, -0.002)], 0.0034))
        for k in 0..<3 { s.append(stroke([pr + P(0.016, -0.002), pr + P(0.09, -0.02 + 0.026 * Double(k))], 0.0026)) }
        // The sun in eclipse: the moon's disc, the corona's streamers and a prominence.
        let ec = sun + P(-0.02, -0.022)
        s += hoop(ec, 0.026, 0.005, pieces: 2)
        for (a, l) in [(-80.0, 0.064), (-30, 0.044), (20, 0.058), (80, 0.04), (150, 0.062), (200, 0.042), (250, 0.054)] {
            s.append(stroke([polar(ec, 0.034, a), polar(ec, l, a + 8)], 0.003))
        }
        s.append(stroke(arc(polar(ec, 0.03, 120), 0.01, 120, 330, 8), 0.0036))
        // Through the slit's tube: its two jaws, and the flame standing between them.
        let sl = slit + P(0.03, -0.004)
        for x in [-0.02, 0.02] { s.append(stroke([sl + P(x, -0.07), sl + P(x, 0.07)], 0.004)) }
        let wick = sl + P(0, 0.024)
        s.append(stroke(arc(wick, 0.02, 0, 180, 10) + curve(wick + P(-0.02, 0), wick + P(-0.02, -0.04), wick + P(0.006, -0.078), 10)
            + curve(wick + P(0.006, -0.078), wick + P(0.024, -0.036), wick + P(0.02, 0), 10), 0.0036))
        s.append(stroke(arc(wick, 0.008, 0, 180, 6) + [wick + P(0.002, -0.03), wick + P(0.008, 0)], 0.0024))
        /// A strip of spectrum `w` long under its element's name, with its lines at `lines` (shares of the strip).
        func spectrum(_ at: P, _ lines: [Double]) {
            for dy in [-0.014, 0.014] { s.append(stroke([at + P(-0.06, dy), at + P(0.06, dy)], 0.0024)) }
            for x in lines { s.append(stroke([at + P(-0.06 + 0.12 * x, -0.014), at + P(-0.06 + 0.12 * x, 0.014)], 0.004)) }
        }
        // Through the eyepiece: sodium, its two lines close together, and its name.
        let na = eye + P(0.008, 0.026)
        spectrum(na, [0.55, 0.6])
        let n = na + P(-0.036, -0.05)
        s.append(stroke([n + P(0, 0.016), n + P(0, -0.016), n + P(0.02, 0.016), n + P(0.02, -0.016)], 0.0036))
        s.append(stroke(arc(n + P(0.038, 0.006), 0.009, 0, 360, 12) + [n + P(0.047, 0.016)], 0.0036))
        // Down the scale's tube: hydrogen, its four lines, and its letter.
        let hy = scale + P(-0.006, 0.026)
        spectrum(hy, [0.9, 0.5, 0.3, 0.18])
        let hh = hy + P(0.03, -0.048)
        s.append(stroke([hh + P(-0.011, -0.016), hh + P(-0.011, 0.016)], 0.0036))
        s.append(stroke([hh + P(0.011, -0.016), hh + P(0.011, 0.016)], 0.0036))
        s.append(stroke([hh + P(-0.011, 0), hh + P(0.011, 0)], 0.0036))
        return drawn("spectroscope", glasses: glasses, fills: fills, strokes: s) { p in
            // The fan of the split light, a band of colour for every fifteen degrees.
            let r2 = simd_length_squared(p)
            if p.x > 0, r2 < 0.93 * 0.93 {
                let a = atan2(p.y, p.x) * 180 / .pi
                if a > fan.0, a < fan.1 { return bands[min(Int((a - fan.0) / 15), 5)] }
            }
            return c(0.14)
        }
    }()
}
