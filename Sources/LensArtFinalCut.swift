// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 68 to 75, the chapter Final cut.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let finalCut: [Int: Halftone.Panel] = [68: lighthouse, 69: eclipseglasses, 70: searchlight, 71: planetarium, 72: observatory, 73: radiotelescope, 74: spacetelescope, 75: mindseye]

    /// Hex's rods, the hub first.
    fileprivate static let hex = [P(0, 0), P(0, -0.56), P(0.485, -0.28), P(0.485, 0.28), P(0, 0.56), P(-0.485, 0.28), P(-0.485, -0.28)]
    /// A hex core's radius.
    fileprivate static let core = 0.264

    /// p's bearing about c in degrees, 0 to 360, 0 at three o'clock and clockwise on screen.
    fileprivate static func bearing(_ p: P, _ c: P) -> Double {
        let a = atan2(p.y - c.y, p.x - c.x) * 180 / .pi
        return a < 0 ? a + 360 : a
    }

    /// A line cut where it passes within `r` of any of `centres`, its segments split finely enough for the cut to fall
    /// close to the circle.
    fileprivate static func outside(_ line: [P], _ width: Double, of centres: [P], by r: Double) -> [Halftone.Stroke] {
        guard centres.contains(where: { distance($0, line) <= r }) else { return [stroke(line, width)] }
        var fine = [line[0]]
        for j in 1..<line.count { fine += span(line[j - 1], line[j], max(1, Int((simd_distance(line[j - 1], line[j]) / 0.008).rounded(.up)))).dropFirst() }
        return runs(fine, width) { p in centres.allSatisfy { simd_distance(p, $0) > r } }
    }

    /// The scene's strokes cut clear of the lens cores, so only a lens's own clue and frame show magnified in it.
    fileprivate static func clear(_ strokes: [Halftone.Stroke], of centres: [P], by r: Double = core + 0.004) -> [Halftone.Stroke] {
        strokes.flatMap { outside($0.points, $0.width, of: centres, by: r) }
    }

    /// Strokes with long reaches cut into pieces of at most `n` segments, as the bake tests every segment of a stroke
    /// at each pixel in its box.
    fileprivate static func pieces(_ strokes: [Halftone.Stroke], _ n: Int = 12) -> [Halftone.Stroke] {
        strokes.flatMap { s -> [Halftone.Stroke] in
            let lo = s.points.reduce(s.points[0], simd_min), hi = s.points.reduce(s.points[0], simd_max)
            guard s.points.count > n + 1, simd_distance(lo, hi) > 0.12 else { return [s] }
            return stride(from: 0, to: s.points.count - 1, by: n).map { stroke(Array(s.points[$0...min($0 + n, s.points.count - 1)]), s.width) }
        }
    }

    /// The tone of a frame cut into runs: `cuts` are the bearings where each run starts, in order, and `tones` the run
    /// each starts, the last run wrapping to the first cut.
    fileprivate static func runTone(_ a: Double, _ cuts: [Double], _ tones: [Tone]) -> Tone {
        var k = cuts.count - 1
        for (i, cut) in cuts.enumerated() where a >= cut { k = i }
        return tones[k % tones.count]
    }
}

// MARK: - 68: Lighthouse

/// Level 68's name: a striped lighthouse on its rock at night, its lantern's great round lens over the top core, its
/// beams thrown left across the moonlit sky and right to the horizon, and the pools its light lays on the sea over the
/// other four of hex's five lenses on this level, each pool's rim broken by glitter. In the lantern's lens the lamp, a
/// bulb lit on its screw base; in the pools, what the light finds: a steamer at sea (upper right), a shark's fin
/// (lower right), a rowing boat (bottom) and a lifebuoy (lower left).
extension LensArt {
    static let lighthouse: Halftone.Panel = {
        let lamp = hex[1], horizon = -0.12
        let pools = [hex[2], hex[3], hex[4], hex[5]]
        let tower = [P(-0.13, -0.3), P(0.13, -0.3), P(0.19, 0.2), P(-0.19, 0.2)]
        let rock = [P(-0.26, 0.26), P(-0.2, 0.14), P(-0.08, 0.12), P(0.1, 0.13), P(0.22, 0.17), P(0.27, 0.26)]
        let door = rect(0.02, 0.06, 0.09, 0.18)
        let room = rect(-0.3, -0.84, 0.3, -0.29)
        let bands: [ClosedRange<Double>] = [-0.2 ... -0.1, 0.0 ... 0.1]
        let shaft = fill(tower, m(0.75))
        let body = [fill(door, Tone(0.3, 0.3, 0)), fill(rock, Tone(0.5, 0.5, 0)), fill(rect(-0.36, -0.3, 0.36, -0.26), y(0.7)),
                    fill(room, Tone(0.35, 0.55, 0)), oval(P(0, -0.84), 0.3, 0.13, m(0.7))]
        let moon = P(-0.5, -0.74)
        let clouds = [(P(-0.36, -0.62), P(0.16, 0.05)), (P(-0.74, -0.24), P(0.14, 0.04)), (P(0.46, -0.72), P(0.17, 0.05))]

        var s: [Halftone.Stroke] = []
        // The lantern: its room's glazing bars, the gallery and its rail, the dome.
        s.append(stroke(closed(room), mid))
        for x in [-0.22, 0.22] { s += runs(span(P(x, -0.84), P(x, -0.29), 20), mid) { simd_distance($0, lamp) > core } }
        s.append(stroke([P(-0.36, -0.3), P(0.36, -0.3)], bold))
        for x in stride(from: -0.32, through: 0.33, by: 0.08) { s.append(stroke([P(x, -0.3), P(x, -0.26)], hair)) }
        s.append(stroke([P(-0.36, -0.26), P(0.36, -0.26)], mid))
        s.append(stroke(ellipse(P(0, -0.84), 0.3, 0.13, 32).filter { $0.y <= -0.84 }, bold))
        // The tower: outline, bands, door, windows, and the rock under it.
        s.append(stroke(closed(tower), bold))
        for b in bands { for yy in [b.lowerBound, b.upperBound] { let w = 0.13 + 0.06 * (yy + 0.3) / 0.5; s.append(stroke([P(-w, yy), P(w, yy)], mid)) } }
        s.append(stroke(closed(door), mid))
        for at in [P(-0.04, -0.06), P(0.03, -0.18)] { s.append(stroke(closed(rect(at.x - 0.02, at.y - 0.03, at.x + 0.02, at.y + 0.03)), mid)) }
        s.append(stroke(rock, bold))
        // The sea's horizon, broken by the pools, and waves.
        s += runs(span(P(-1, horizon), P(1, horizon), 100), mid) { p in pools.allSatisfy { simd_distance(p, $0) > core + 0.04 } && abs(p.x) > 0.13 }
        for at in [P(-0.3, 0.02), P(0.24, 0.0), P(-0.78, 0.1), P(0.8, 0.02), P(-0.2, 0.36), P(0.2, 0.4), P(-0.7, 0.62), P(0.72, 0.6), P(-0.3, 0.86), P(0.32, 0.84)] {
            s.append(stroke(curve(at + P(-0.05, 0), at + P(-0.025, -0.025), at, 5) + curve(at, at + P(0.025, 0.025), at + P(0.05, 0), 5), hair))
        }
        // The sky: the moon, clouds, the beams' edges and stars.
        s.append(stroke(arc(moon, 0.11, 0, 360, 28), mid))
        for (c, r) in clouds { s.append(stroke(ellipse(c, r.x, r.y, 24), mid)) }
        for (a, b) in [(P(-0.3, -0.6), P(-1, -0.684)), (P(-0.3, -0.52), P(-1, -0.352)), (P(0.3, -0.6), P(0.95, -0.522)), (P(0.3, -0.52), P(0.95, -0.26))] {
            s += runs(span(a, b, 40), hair) { p in simd_distance(p, hex[2]) > core + 0.03 && simd_distance(p, moon) > 0.12 && p.y < horizon }
        }
        for at in [P(-0.2, -0.9), P(0.62, -0.62), P(-0.86, -0.36), P(0.4, -0.88), P(-0.5, -0.8)] { s += glint(at, 0.035, hair) }
        s = clear(s, of: [lamp] + pools)
        // The great lens: its rim, a hinge on the right, and its prism rings round the lamp.
        s.append(stroke(circle(lamp, core, 56), bold))
        s.append(stroke(closed(rect(lamp.x + 0.25, lamp.y - 0.05, lamp.x + 0.29, lamp.y + 0.05)), mid))
        for r in [0.2, 0.225, 0.25] { s.append(stroke(circle(lamp, r, 48), hair)) }
        for k in 0..<8 { s.append(stroke([polar(lamp, 0.2, 22.5 + 45 * Double(k)), polar(lamp, 0.25, 22.5 + 45 * Double(k))], mid)) }
        // The lamp: a bulb on its screw base, its filament lit, and its glow.
        let f = lamp + P(0.028, -0.006)
        s.append(stroke(closed(arc(f, 0.03, 140, 400, 20) + [f + P(0.012, 0.042), f + P(-0.012, 0.042)]), 0.0035))
        for k in 0..<3 { s.append(stroke([f + P(-0.012, 0.047 + 0.007 * Double(k)), f + P(0.012, 0.05 + 0.007 * Double(k))], 0.0025)) }
        s.append(stroke([f + P(-0.008, 0.024), f + P(-0.008, 0.004), f + P(-0.004, -0.008), f + P(0, 0.0), f + P(0.004, -0.008), f + P(0.008, 0.004), f + P(0.008, 0.024)], 0.002))
        for a in [200.0, 240, 290, 330, 10] { s.append(stroke([polar(f, 0.042, a), polar(f, 0.06, a)], 0.0025)) }
        // The pools' rims and their glitter.
        for (k, c) in pools.enumerated() {
            for j in 0..<7 {
                let a = 25 + 51 * Double(j) + 13 * Double(k)
                s.append(stroke(arc(c, core + 0.025, a, a + 14, 4), hair))
            }
        }
        // A steamer on the horizon: hull, deckhouse, funnel and its smoke.
        let ship = hex[2] + P(0.022, 0.03)
        s += runs(span(hex[2] + P(-0.18, 0.04), hex[2] + P(0.18, 0.04), 30)) { abs($0.x - ship.x) > 0.07 }
        s.append(stroke(closed([ship + P(-0.06, -0.012), ship + P(0.065, -0.012), ship + P(0.05, 0.008), ship + P(-0.05, 0.008)]), 0.003))
        s.append(stroke(closed(rect(ship.x - 0.03, ship.y - 0.03, ship.x + 0.02, ship.y - 0.012)), 0.0025))
        s.append(stroke(closed(rect(ship.x + 0.0, ship.y - 0.055, ship.x + 0.014, ship.y - 0.03)), 0.0025))
        s.append(stroke(curve(ship + P(0.007, -0.06), ship + P(-0.02, -0.08), ship + P(-0.06, -0.07), 6), 0.002))
        for x in [-0.02, -0.006, 0.008] { s.append(stroke(circle(ship + P(x, -0.002), 0.0035, 6), 0.0018)) }
        // A shark's fin cutting the water, its wake behind it.
        let fin = hex[3] + P(0.022, 0.02)
        s.append(stroke([fin + P(-0.03, 0.02)] + curve(fin + P(-0.03, 0.02), fin + P(-0.006, -0.01), fin + P(-0.004, -0.05), 8) + curve(fin + P(-0.004, -0.05), fin + P(0.006, -0.012), fin + P(0.026, 0.02), 8), 0.0035))
        s += runs(span(fin + P(-0.075, 0.02), fin + P(0.06, 0.02), 24), 0.0028) { abs($0.x - fin.x + 0.002) > 0.03 }
        for k in 0..<2 { s.append(stroke(curve(fin + P(0.035 + 0.02 * Double(k), 0.032 + 0.012 * Double(k)), fin + P(0.05 + 0.02 * Double(k), 0.024), fin + P(0.065 + 0.02 * Double(k), 0.032 + 0.012 * Double(k)), 6), 0.002)) }
        // A rowing boat, its rower and oars.
        let boat = hex[4] + P(-0.02, 0.03)
        s.append(stroke(closed(curve(boat + P(-0.07, -0.01), boat + P(0, 0.05), boat + P(0.07, -0.01), 10)), 0.003))
        s.append(stroke(circle(boat + P(0.0, -0.05), 0.011, 10), 0.0025))
        s.append(stroke([boat + P(0.0, -0.039), boat + P(0.0, -0.008)], 0.003))
        s.append(stroke([boat + P(-0.09, 0.03), boat + P(0.0, -0.028), boat + P(0.09, 0.03)], 0.0022))
        // A lifebuoy afloat, its bands and its line.
        let buoy = hex[5] + P(-0.022, 0.016)
        for r in [0.018, 0.04] { s.append(stroke(circle(buoy, r, 20), 0.003)) }
        for k in 0..<4 { let a = 45 + 90 * Double(k); s.append(stroke(closed(sector(buoy, 0.018, 0.04, a - 12, a + 12)), 0.0018)) }
        s.append(stroke(curve(polar(buoy, 0.04, 20), buoy + P(0.07, 0.0), buoy + P(0.06, 0.06), 8), 0.0022))
        s += runs(span(buoy + P(-0.08, 0.03), buoy + P(0.08, 0.03), 24), 0.0022) { simd_distance($0, buoy) > 0.044 }
        let poolTones = [y(0.75), Tone(0.25, 0, 0.45), Tone(0.25, 0, 0.45), Tone(0.25, 0, 0.45)]
        let cuts: [Double] = [0, 24, 50, 90, 118, 150, 196, 230, 262, 300, 330]
        return Halftone.Panel(name: "lighthouse", tones: { (p: P) -> Tone in
            if p.y > -0.56 {
                for (k, pc) in pools.enumerated() {
                    let d = simd_distance(p, pc)
                    if d < core { return poolTones[k] }
                    if d < core + 0.05 {
                        let a = (bearing(p, pc) + 37 * Double(k)).truncatingRemainder(dividingBy: 360)
                        return runTone(a, cuts, [y(0.9), .zero, m(0.6), .zero, y(0.9), c(0.15)])
                    }
                }
            }
            if simd_distance(p, lamp) < core { return y(0.85) }
            if shaft.holds(p) { return bands.contains { $0.contains(p.y) } ? y(0.7) : shaft.tone }
            for f in body where f.holds(p) { return f.tone }
            if p.y < horizon {
                if simd_distance(p, moon) < 0.11 { return y(0.75) }
                for (cc, r) in clouds where simd_length_squared((p - cc) / r) < 1 { return m(0.4) }
                // The beams, widening from the lantern.
                let t = abs(p.x) - 0.3
                if t > 0 {
                    let top = p.x < 0 ? -0.6 - 0.12 * t : -0.6 + 0.12 * t, bottom = p.x < 0 ? -0.52 + 0.24 * t : -0.52 + 0.4 * t
                    if p.y > top, p.y < bottom { return y(0.3) }
                }
                return Tone(0.1, 0.12, 0)
            }
            return c(0.6)
        }, strokes: pieces(s))
    }()
}

// MARK: - 69: Eclipse glasses

/// Level 69's name: a total eclipse watched from a dark hillside, a woman in card eclipse glasses looking up from the
/// lower right, and over hex's four lenses on this level the sun as her glasses show it, gold in the dark filter, each
/// framed in the printed card: in the three ring lenses the moon biting deeper into the sun (half, a thin crescent, the
/// diamond ring) and in the hub, where the glasses come off, totality: the black moon in its corona, two prominences at
/// its edge. Over the upper left, a twist rod, clouds lit gold underneath and Venus out in the darkened sky.
extension LensArt {
    static let eclipseglasses: Halftone.Panel = {
        let phases = [hex[5], hex[1], hex[2]], sun = hex[0]
        let venus = hex[6] + P(-0.1, 0.1)
        let clouds = [(hex[6] + P(0.05, 0.03), P(0.2, 0.065), m(0.55)), (hex[6] + P(-0.06, -0.12), P(0.14, 0.045), y(0.6))]
        let head = P(0.6, 0.44), eye = P(0.44, 0.36)
        let nose = [P(0.405, 0.4), P(0.35, 0.47), P(0.41, 0.49)]
        let card = [P(0.33, 0.33), P(0.56, 0.27), P(0.7, 0.27), P(0.7, 0.35), P(0.56, 0.35), P(0.35, 0.41)]
        let hairOval = (P(0.68, 0.38), P(0.22, 0.27))
        let body = closed([P(0.18, 1), P(0.28, 0.78), P(0.46, 0.7), P(0.74, 0.7), P(0.9, 0.78), P(1, 1)])
        let neck = rect(0.5, 0.6, 0.66, 0.74)
        let hills = closed([P(-1, 0.66), P(-0.7, 0.6), P(-0.45, 0.64), P(-0.2, 0.7), P(0.1, 0.66), P(0.4, 0.72), P(1, 0.64), P(1, 1), P(-1, 1)])
        let skin = Tone(0, 0.25, 0.55)
        let figure = [fill(card, y(0.9)), fill(nose, skin), fill(body, Tone(0.55, 0, 0.55)), fill(neck, skin), oval(head, 0.17, 0.22, skin),
                      oval(hairOval.0, hairOval.1.x, hairOval.1.y, Tone(0.12, 0.22, 0)), fill(hills, Tone(0.15, 0.12, 0))]

        var s: [Halftone.Stroke] = []
        // The watcher: her profile, hair, glasses and shoulders.
        let profile = curve(P(0.5, 0.2), P(0.42, 0.24), P(0.41, 0.34), 8) + nose + curve(P(0.41, 0.49), P(0.4, 0.53), P(0.44, 0.55), 4)
            + curve(P(0.44, 0.55), P(0.42, 0.6), P(0.48, 0.62), 4) + [P(0.5, 0.64)]
        s.append(stroke(profile, mid))
        s.append(stroke(curve(P(0.415, 0.53), P(0.43, 0.54), P(0.445, 0.53), 4), mid))
        s += runs(ellipse(hairOval.0, hairOval.1.x, hairOval.1.y, degrees: 0, 48), mid) { $0.x > 0.5 }
        for k in 0..<5 { s.append(stroke(curve(P(0.62 + 0.04 * Double(k), 0.14 + 0.01 * Double(k)), P(0.88, 0.32), P(0.7 + 0.04 * Double(k), 0.64), 10), hair)) }
        s.append(stroke(closed(card), bold))
        s.append(stroke(closed(ellipse(eye, 0.05, 0.026, degrees: -14, 16)), mid))
        s.append(stroke(arc(P(0.63, 0.31), 0.02, 0, 360, 10), hair))
        s.append(stroke(closed(body), bold))
        s.append(stroke(closed(neck), mid))
        s.append(stroke(curve(P(0.5, 0.74), P(0.58, 0.82), P(0.66, 0.74), 6), mid))
        // The hills and their trees, and the stars out at totality.
        s.append(stroke(Array(hills.dropLast(3)), mid))
        for (x, h) in [(-0.82, 0.13), (-0.62, 0.1), (-0.36, 0.11), (0.06, 0.09)] {
            let base = P(x, 0.65 + 0.03 * sin(x * 7))
            s.append(stroke(closed([base + P(-0.045, 0), base + P(0, -h), base + P(0.045, 0)]), mid))
            s.append(stroke([base, base + P(0, 0.04)], mid))
        }
        for at in [P(-0.85, -0.12), P(0.32, -0.86), P(0.86, -0.02), P(-0.72, -0.62), P(0.7, -0.66), P(0.26, 0.04)] { s += glint(at, 0.03, hair) }
        // The clouds lit from under, and Venus, out at totality.
        for (c, r, _) in clouds {
            s += runs(ellipse(c, r.x, r.y, 36), mid) { p in clouds.allSatisfy { $0.0 == c || simd_length_squared((p - $0.0) / $0.1) > 1 } }
        }
        s.append(stroke(circle(venus, 0.035, 16), mid))
        s += glint(venus, 0.08, hair)
        s = clear(s, of: phases + [sun])
        // The card frames round the filters, printed with a border and their safety marks.
        for c in phases {
            s.append(stroke(circle(c, core, 56), bold))
            s.append(stroke(circle(c, core + 0.05, 56), mid))
            for k in 0..<9 { let a = 40 * Double(k) + 7; s.append(stroke([polar(c, core + 0.012, a), polar(c, core + 0.038, a + 4)], hair)) }
        }
        // The sun in the filters, the moon biting in deeper each time: half, a crescent, the diamond ring.
        for (k, c) in phases.enumerated() {
            let o = c + P(0.03, -0.022), r = 0.032, d = [0.034, 0.014, 0.004][k], moon = o + d * simd_normalize(P(1, -0.6))
            s += runs(circle(o, r, 40), 0.0035) { simd_distance($0, moon) > r + 0.001 }
            if k < 2 { s += runs(circle(moon, r, 40), 0.002) { simd_distance($0, o) < r } }
            if k == 2 {
                s.append(stroke(circle(o, r + 0.01, 40), 0.0015))
                s += glint(o + polar(P(0, 0), r, 210), 0.034, 0.0028)
            }
        }
        // Totality: the moon's black disc, streamers of corona and prominences at its rim.
        let o = sun + P(-0.028, 0.026)
        s.append(stroke(circle(o, 0.03, 32), 0.0035))
        for k in 0..<18 {
            let a = 20 * Double(k) + 5, l = [0.04, 0.016, 0.026, 0.012, 0.034, 0.018][k % 6]
            s.append(stroke([polar(o, 0.037, a), polar(o, 0.037 + l, a + 3)], 0.002))
        }
        for a in [62.0, 245] { s.append(stroke(arc(polar(o, 0.03, a), 0.008, a - 100, a + 100, 8), 0.003)) }
        s.append(stroke(circle(sun, core, 56), mid))

        let cuts: [Double] = [0, 18, 40, 75, 96, 140, 160, 205, 226, 270, 290, 330]
        return Halftone.Panel(name: "eclipseglasses", tones: { (p: P) -> Tone in
            for c in phases {
                let d = simd_distance(p, c)
                if d < core { return y(0.75) }
                if d < core + 0.05 { return runTone(bearing(p, c), cuts, [m(0.7), m(0.7), .zero]) }
            }
            let d = simd_distance(p, sun)
            if d < core { return c(0.15) }
            if d < core + 0.09 {
                // The corona's streamers, uneven round the rim.
                let a = bearing(p, sun), reach = core + 0.03 + 0.06 * abs(sin(a * .pi / 180 * 2.5 + 0.7))
                if d < reach { return y(0.85) }
            }
            for f in figure where f.holds(p) { return f.tone }
            if p.y < 0.1, p.x < -0.1 {
                if simd_distance(p, venus) < 0.035 { return y(0.9) }
                for (cc, r, t) in clouds where simd_length_squared((p - cc) / r) < 1 { return t }
            }
            return p.y < 0.38 ? c(0.42) : m(0.5)
        }, strokes: pieces(s))
    }()
}

// MARK: - 70: Searchlight

/// Level 70's name: a battery of searchlights on the roofs of a city at night, their beams crossing high over the top
/// and upper right where a plane is caught in them, each lamp's glass over one of hex's four lenses on this level, its
/// drum rim bolted, a clamp at one side, and at the bottom, a twist rod, a roof with its water tank and lit windows
/// below. In each glass, the thing its beam has found: in the big lamp at the hub the arc itself, spitting between its
/// two carbons; in the others a biplane (upper left), an airship (lower left) and a balloon (lower right).
extension LensArt {
    static let searchlight: Halftone.Panel = {
        let lamps = [hex[0], hex[6], hex[5], hex[3]], back = P(-0.05, 0.08)
        // Each beam: its lamp, its heading (degrees, -90 straight up) and its half-spread.
        let beams: [(P, Double, Double)] = [(hex[0], -62, 9), (hex[6], -72, 8), (hex[5], -100, 7), (hex[3], -96, 8)]
        let wedges = beams.map { ($0.0, polar(P(0, 0), 1, $0.1), cos($0.2 * .pi / 180)) }
        let towers = [rect(-0.82, -0.02, -0.18, 1), rect(0.2, 0.2, 0.9, 1), rect(-0.3, 0.42, 0.34, 1)]
        let plane = P(0.18, -0.62)
        let planeShape = [plane + P(-0.13, 0.0), plane + P(-0.02, -0.03), plane + P(0.06, -0.12), plane + P(0.1, -0.12), plane + P(0.06, -0.02),
                          plane + P(0.15, -0.02), plane + P(0.18, -0.06), plane + P(0.2, -0.06), plane + P(0.19, 0.02), plane + P(0.06, 0.03),
                          plane + P(0.1, 0.12), plane + P(0.06, 0.12), plane + P(-0.02, 0.03)]
        let cloud = [(P(0.62, -0.42), P(0.2, 0.06)), (P(0.48, -0.36), P(0.12, 0.05)), (P(-0.38, -0.74), P(0.18, 0.05))]
        // The roof under the bottom rod: a water tank on its legs and a stair hut, and lit windows below.
        let tank = rect(-0.2, 0.3, -0.06, 0.38), hut = rect(0.06, 0.34, 0.2, 0.42)
        let windows = [rect(-0.22, 0.5, -0.15, 0.58), rect(-0.02, 0.5, 0.05, 0.58), rect(0.12, 0.66, 0.19, 0.74), rect(-0.12, 0.66, -0.05, 0.74)]
        let blocks = [fill(tank, m(0.7)), fill(hut, m(0.55))] + windows.map { fill($0, y(0.85)) } + [fill(planeShape, .zero)] + cloud.map { oval($0.0, $0.1.x, $0.1.y, y(0.35)) }
            + towers.enumerated().map { fill($0.element, [c(0.6), y(0.45), c(0.45)][$0.offset]) }

        var s: [Halftone.Stroke] = []
        // The beams' edges, where no lamp stands in front.
        for (c, a, w) in beams {
            for e in [a - w, a + w] {
                s += runs(span(polar(c, core + 0.06, e), polar(c, 2.2, e), 90), hair) { p in
                    simd_length(p) < 1 && lamps.allSatisfy { simd_distance(p, $0) > core + 0.07 } && !towers.contains { inside(p, $0) }
                }
            }
        }
        // The city: its towers, their edges and lit windows, and the plane in the beams.
        for t in towers { s += outside(closed(t), mid, of: lamps, by: core + 0.06) }
        for (k, t) in towers.enumerated() {
            let lo = t[0], hi = t[2]
            for row in 0..<8 {
                for col in 0..<6 where (row * 5 + col * 3 + k) % 4 == 0 {
                    let at = P(lo.x + 0.05 + 0.1 * Double(col), lo.y + 0.05 + 0.08 * Double(row))
                    guard at.x < hi.x - 0.04, at.y < 1, lamps.allSatisfy({ simd_distance(at, $0) > core + 0.1 }), simd_length(at) < 0.96 else { continue }
                    s.append(stroke(closed(rect(at.x, at.y, at.x + 0.03, at.y + 0.04)), hair))
                }
            }
        }
        for r in [tank, hut] + windows { s.append(stroke(closed(r), mid)) }
        for x in [-0.18, -0.08] { s.append(stroke([P(x, 0.38), P(x, 0.42)], mid)) }
        s.append(stroke(arc(P(-0.13, 0.3), 0.07, 180, 360, 12), mid))
        s.append(stroke(closed(planeShape), mid))
        s.append(stroke([plane + P(-0.06, 0.0), plane + P(0.12, 0.0)], hair))
        for (c, r) in cloud { s += runs(ellipse(c, r.x, r.y, 36), mid) { p in cloud.allSatisfy { $0.0 == c || simd_length_squared((p - $0.0) / $0.1) > 1 } } }
        for at in [P(-0.7, -0.5), P(0.82, -0.12), P(-0.1, -0.9), P(0.42, -0.84)] { s += glint(at, 0.03, hair) }
        s = clear(s, of: lamps)
        // The lamps: each drum's barrel behind it, its bolts, the clamp and the yoke's arms.
        for (k, c) in lamps.enumerated() {
            let big = k == 0
            s += runs(circle(c + back, core + 0.055, 56), mid) { p in simd_distance(p, c) > core + 0.055 && lamps.allSatisfy { $0 == c || simd_distance(p, $0) > core + 0.06 } }
            for e in [-1.0, 1.0] {
                let n = P(back.y, -back.x) / simd_length(back) * (core + 0.055) * e
                s += runs(span(c + n, c + back + n, 8), mid) { p in lamps.allSatisfy { $0 == c || simd_distance(p, $0) > core + 0.06 } }
            }
            s.append(stroke(circle(c, core, 56), bold))
            s.append(stroke(circle(c, core + 0.055, 56), big ? bold : mid))
            for j in 0..<10 { s.append(stroke(circle(polar(c, core + 0.028, 36 * Double(j) + 18), 0.008, 6), hair)) }
            for j in 0..<6 { let a = 60 * Double(j) + 30 * Double(k % 2); s.append(stroke([polar(c, 0.2, a), polar(c, core, a)], mid)) }
            s.append(stroke(circle(c, 0.2, 40), hair))
            let side = k % 2 == 0 ? 0.0 : 180.0
            s.append(stroke(closed(sector(c, core + 0.055, core + 0.1, side - 12, side + 12)), mid))
        }
        // In each glass, the thing its beam has found. The hub: the arc between its carbons.
        let arcAt = hex[0] + P(0.026, -0.02)
        for side in [-1.0, 1.0] {
            s.append(stroke(closed([arcAt + P(side * 0.012, -0.006), arcAt + P(side * 0.06, -0.012), arcAt + P(side * 0.06, 0.012), arcAt + P(side * 0.012, 0.006)]), 0.003))
        }
        s.append(stroke([arcAt + P(-0.012, 0), arcAt + P(-0.006, -0.008), arcAt + P(0, 0.006), arcAt + P(0.006, -0.006), arcAt + P(0.012, 0)], 0.0025))
        for a: Double in [-120, -90, -60, 60, 90, 120] { s.append(stroke([polar(arcAt, 0.016, a), polar(arcAt, 0.03, a)], 0.002)) }
        // A biplane.
        let bi = hex[6] + P(0.022, -0.018)
        s.append(stroke(closed(ellipse(bi, 0.045, 0.01, 16)), 0.003))
        for yy in [-0.022, 0.016] { s.append(stroke(closed(rect(bi.x - 0.012, bi.y + yy - 0.005, bi.x + 0.016, bi.y + yy + 0.005)), 0.0025)) }
        s.append(stroke([bi + P(-0.006, -0.017), bi + P(-0.006, 0.011)], 0.002))
        s.append(stroke([bi + P(0.01, -0.017), bi + P(0.01, 0.011)], 0.002))
        s.append(stroke([bi + P(0.05, -0.016), bi + P(0.05, 0.016)], 0.0025))
        s.append(stroke([bi + P(-0.045, 0), bi + P(-0.055, -0.018), bi + P(-0.04, -0.006)], 0.0025))
        // An airship.
        let ship = hex[5] + P(-0.02, -0.024)
        s.append(stroke(closed(ellipse(ship, 0.055, 0.02, 24)), 0.003))
        s.append(stroke(closed(rect(ship.x - 0.012, ship.y + 0.02, ship.x + 0.014, ship.y + 0.03)), 0.0025))
        for x in [-0.025, 0.0, 0.025] { s.append(stroke([ship + P(x, -0.018), ship + P(x, 0.018)], 0.0018)) }
        s.append(stroke(closed([ship + P(-0.05, 0), ship + P(-0.07, -0.016), ship + P(-0.066, 0.0), ship + P(-0.07, 0.016)]), 0.0025))
        // A balloon.
        let balloon = hex[3] + P(-0.024, -0.03)
        s.append(stroke(arc(balloon, 0.032, 150, 390, 24) + [balloon + P(0.008, 0.05), balloon + P(-0.008, 0.05)] + [polar(balloon, 0.032, 150)], 0.003))
        s.append(stroke(closed(rect(balloon.x - 0.01, balloon.y + 0.058, balloon.x + 0.01, balloon.y + 0.072)), 0.0025))
        for x in [-0.008, 0.008] { s.append(stroke([balloon + P(x, 0.05), balloon + P(x, 0.058)], 0.0018)) }
        s.append(stroke(curve(balloon + P(0, -0.032), balloon + P(-0.018, 0.0), balloon + P(-0.006, 0.048), 8), 0.0018))
        s.append(stroke(curve(balloon + P(0, -0.032), balloon + P(0.018, 0.0), balloon + P(0.006, 0.048), 8), 0.0018))

        let glass = [y(0.85), y(0.7), y(0.85), y(0.7)]
        let cuts: [Double] = [0, 30, 54, 90, 120, 160, 196, 230, 262, 300, 330]
        return Halftone.Panel(name: "searchlight", tones: { (p: P) -> Tone in
            for (k, lamp) in lamps.enumerated() {
                let d = simd_distance(p, lamp)
                if d < core { return glass[k] }
                if d < core + 0.055 { return runTone((bearing(p, lamp) + 29 * Double(k)).truncatingRemainder(dividingBy: 360), cuts, [c(0.8), c(0.8), .zero, y(0.6)]) }
            }
            for lc in lamps where simd_distance(p, lc) < 0.44 {
                let q = p - lc, h = min(max(simd_dot(q, back) / simd_length_squared(back), 0), 1)
                if simd_distance(q, h * back) < core + 0.055 { return c(0.25) }
            }
            for f in blocks where f.holds(p) { return f.tone }
            var lit = 0
            for (c, u, cw) in wedges {
                let q = p - c, l = simd_length(q)
                if l > core, simd_dot(q, u) > l * cw { lit += 1 }
            }
            return lit == 0 ? m(0.35) : lit == 1 ? c(0.4) : c(0.75)
        }, strokes: pieces(s))
    }()
}

// MARK: - 71: Planetarium

/// Level 71's name: inside a planetarium's dome, the star projector rising on its pillar from the hub, its two globes
/// pricked with lenses, the audience's heads tipped back in their rows below and the city's skyline round the dome's
/// foot, and over hex's five lenses on this level the discs of sky the projector throws, each ringed with its zodiac
/// band. In each disc a constellation: the Plough (top), Orion (upper right), Scorpius (lower right), the Southern Cross
/// (lower left) and Cassiopeia (upper left).
extension LensArt {
    static let planetarium: Halftone.Panel = {
        let discs = [hex[1], hex[2], hex[3], hex[5], hex[6]]
        let globes = [(P(-0.05, -0.1), 0.15), (P(0.13, 0.2), 0.1)]
        let truss = bar(globes[0].0, globes[1].0, 0.09)
        let pillar = [P(0.0, -0.02), P(0.08, -0.02), P(0.12, 0.62), P(-0.04, 0.62)]
        let seats = [(0.62, 0.05), (0.78, 0.06)]
        let heads = [P(-0.3, 0.56), P(-0.16, 0.55), P(0.26, 0.55), P(0.4, 0.56), P(-0.24, 0.72), P(-0.08, 0.71), P(0.2, 0.71), P(0.36, 0.72)]
        let skyline = closed([P(-1, 0.6), P(-0.92, 0.6), P(-0.92, 0.5), P(-0.84, 0.5), P(-0.84, 0.56), P(-0.76, 0.56), P(-0.76, 0.66), P(-0.6, 0.66),
                              P(-0.6, 0.62), P(0.62, 0.62), P(0.62, 0.66), P(0.74, 0.66), P(0.74, 0.54), P(0.8, 0.48), P(0.86, 0.54), P(0.86, 0.6), P(1, 0.6), P(1, 1), P(-1, 1)])
        let parts = globes.map { disc($0.0, $0.1, y(0.75)) } + [fill(truss, m(0.7)), fill(pillar, m(0.55))]
            + heads.map { oval($0, 0.055, 0.06, Tone(0.4, 0.2, 0)) }
        let console = rect(0.5, 0.74, 0.72, 0.84)

        var s: [Halftone.Stroke] = []
        // The projector: its globes pricked with lenses, the truss between them, the pillar and its cradle.
        for (c, r) in globes {
            s.append(stroke(circle(c, r, 40), bold))
            for k in 0..<3 { let rr = r * (0.35 + 0.3 * Double(k)); for j in 0..<(4 + 4 * k) {
                s.append(stroke(circle(polar(c, rr, 360 / Double(4 + 4 * k) * Double(j) + 20 * Double(k)), 0.012 - 0.002 * Double(k), 8), hair))
            } }
        }
        s += runs(closed(truss), mid) { p in globes.allSatisfy { simd_distance(p, $0.0) > $0.1 } }
        s += runs(pillar, mid) { p in !globes.contains { simd_distance(p, $0.0) < $0.1 } && !inside(p, truss) && heads.allSatisfy { simd_distance(p, $0) > 0.06 } }
        s.append(stroke(arc(P(0.04, 0.02), 0.1, 20, 160, 12), mid))
        // The beams thrown from the globes to each disc, and the dome's ribs.
        for (k, c) in discs.enumerated() {
            let from = k < 3 ? globes[1].0 : globes[0].0, u = simd_normalize(c - from), n = P(-u.y, u.x)
            for e in [-1.0, 1.0] {
                s += runs(span(from, c + e * (core - 0.02) * n, 30), hair) { p in
                    globes.allSatisfy { simd_distance(p, $0.0) > $0.1 + 0.01 } && discs.allSatisfy { simd_distance(p, $0) > core + 0.05 } && !inside(p, truss)
                }
            }
        }
        for r in [1.25, 1.6] { s += runs(circle(P(0, 1.1), r, 160), hair) { p in simd_length(p) < 1 && discs.allSatisfy { simd_distance(p, $0) > core + 0.05 } && p.y < 0.45 } }
        // The audience, heads tipped back over their rows, and the console's glow.
        for (yy, h) in seats { s += runs(span(P(-0.6, yy), P(0.6, yy), 60), mid) { p in heads.allSatisfy { simd_distance(p, $0) > 0.065 } && abs(p.y - yy) < h } }
        for (k, h) in heads.enumerated() {
            s.append(stroke(ellipse(h, 0.055, 0.06, 20), mid))
            s.append(stroke(curve(h + P(-0.03, -0.03), h + P(0, -0.05), h + P(0.03, -0.035), 6), hair))
            if k % 3 == 0 { s.append(stroke([h + P(0.04, -0.03), h + P(0.1, -0.12)], hair)) }
        }
        s.append(stroke(closed(console), mid))
        for k in 0..<5 { s.append(stroke(circle(P(0.53 + 0.04 * Double(k), 0.79), 0.008, 6), hair)) }
        // The skyline round the dome's foot, its lit windows, and the stars on the dome.
        s += runs(Array(skyline.dropLast(3)), mid) { simd_length($0) < 1 }
        for at in [P(-0.88, 0.56), P(-0.8, 0.6), P(-0.7, 0.7), P(0.68, 0.7), P(0.8, 0.56), P(0.92, 0.66)] { s.append(stroke(closed(rect(at.x, at.y, at.x + 0.025, at.y + 0.03)), hair)) }
        for at in [P(-0.18, -0.86), P(0.22, -0.9), P(-0.78, -0.02), P(0.8, -0.02), P(0.02, -0.34), P(-0.6, 0.38), P(0.66, -0.66), P(-0.62, -0.66)] { s += glint(at, 0.028, hair) }
        s = clear(s, of: discs)
        // Each disc's zodiac band: its rim and a tick at each sign.
        for c in discs {
            s.append(stroke(circle(c, core, 56), mid))
            s.append(stroke(circle(c, core + 0.045, 56), hair))
            for k in 0..<12 { s.append(stroke([polar(c, core, 30 * Double(k) + 15), polar(c, core + 0.045, 30 * Double(k) + 15)], hair)) }
        }
        // The constellations: each star a ring, each figure joined.
        let figures: [[[P]]] = [
            [[P(-0.05, 0.0), P(-0.05, 0.026), P(-0.02, 0.032), P(-0.014, 0.006), P(-0.05, 0.0)], [P(-0.014, 0.006), P(0.008, -0.004), P(0.03, -0.012), P(0.052, -0.032)]],
            [[P(-0.03, -0.045), P(-0.012, -0.002), P(0.014, 0.006), P(0.034, -0.04)], [P(-0.012, -0.002), P(-0.028, 0.05)], [P(0.014, 0.006), P(0.03, 0.046)],
             [P(-0.03, -0.045), P(0.0, -0.062), P(0.034, -0.04)]],
            [[P(-0.05, -0.04), P(-0.035, -0.022), P(-0.02, -0.03)], [P(-0.035, -0.022), P(-0.02, 0.0), P(-0.012, 0.024), P(0.006, 0.042), P(0.03, 0.046), P(0.046, 0.032), P(0.05, 0.014), P(0.04, 0.004)]],
            [[P(0.0, -0.05), P(0.004, 0.05)], [P(-0.034, 0.002), P(0.036, -0.008)]],
            [[P(-0.055, -0.006), P(-0.028, 0.024), P(-0.002, -0.004), P(0.024, 0.026), P(0.054, -0.014)]],
        ]
        let offsets = [P(0.008, 0.022), P(0.046, 0.0), P(-0.004, -0.006), P(0.03, 0.03), P(0.0, 0.03)]
        for (k, c) in discs.enumerated() {
            let o = c + offsets[k]
            var stars: [P] = []
            for line in figures[k] {
                s.append(stroke(line.map { o + $0 }, 0.0018))
                stars += line
            }
            if k == 3 { stars.append(P(0.018, 0.022)) }
            for (j, st) in stars.enumerated() where !stars[..<j].contains(st) { s.append(stroke(circle(o + st, 0.0055, 8), 0.0026)) }
            if k == 1 { for j in 0..<3 { s.append(stroke(circle(o + P(-0.008 + 0.006 * Double(j), 0.012 + 0.006 * Double(j)) , 0.0025, 6), 0.002)) } }
        }

        let skies = [y(0.6), m(0.55), Tone(0.3, 0, 0.5), m(0.55), y(0.6)]
        let cuts = (0..<12).map { 30 * Double($0) }
        return Halftone.Panel(name: "planetarium", tones: { (p: P) -> Tone in
            for (k, c) in discs.enumerated() {
                let d = simd_distance(p, c)
                if d < core { return skies[k] }
                if d < core + 0.045 { return runTone((bearing(p, c) + 15).truncatingRemainder(dividingBy: 360), cuts, [k % 2 == 0 ? m(0.7) : y(0.8), .zero]) }
            }
            for f in parts where f.holds(p) { return f.tone }
            if p.x > console[0].x, p.x < console[2].x, p.y > console[0].y, p.y < console[2].y { return y(0.8) }
            if p.y > 0.48, inside(p, skyline) { return Tone(0.12, 0.1, 0) }
            for (yy, h) in seats where abs(p.y - yy - 0.02) < h && abs(p.x) < 0.62 { return m(0.6) }
            return p.y < 0.45 && simd_distance(p, P(0, 1.1)) > 1.25 && simd_distance(p, P(0, 1.1)) < 1.6 ? c(0.35) : c(0.2)
        }, strokes: pieces(s))
    }()
}

// MARK: - 72: Observatory

/// Level 72's name: an observatory on a mountain top at night, its gold dome on the summit at the right, the shutter
/// open and the telescope's tube out of the slit over the hub, pines and the road down the slope at the lower right, and over hex's five lenses
/// on this level what the telescope sees, each through an eyepiece's knurled barrel: the cratered moon (top), a double star
/// (upper right), a comet (bottom), the Pleiades (lower left) and a spiral galaxy (upper left).
extension LensArt {
    static let observatory: Halftone.Panel = {
        let views = [hex[1], hex[2], hex[4], hex[5], hex[6]]
        let dome = P(0.32, 0.22), domeR = 0.18, slit = (0.3, 0.38)
        let tube = bar(P(0.34, 0.14), P(0.14, -0.06), 0.09)
        let drum = rect(0.14, 0.22, 0.5, 0.32)
        let door = rect(0.2, 0.24, 0.26, 0.32)
        let mountain = closed([P(-1, 0.62), P(-0.6, 0.52), P(-0.3, 0.48), P(0.1, 0.36), P(0.14, 0.32), P(0.5, 0.32), P(0.62, 0.4), P(0.8, 0.5),
                               P(1, 0.56), P(1, 1), P(-1, 1)])
        let pines = [P(0.62, 0.46), P(0.74, 0.52), P(0.88, 0.6), P(0.7, 0.66), P(0.84, 0.76)].map { closed([$0 + P(-0.05, 0.12), $0, $0 + P(0.05, 0.12)]) }
        let road = [P(0.42, 0.32), P(0.58, 0.46), P(0.42, 0.6), P(0.6, 0.76), P(0.5, 0.94)]
        let built = pines.map { fill($0, c(0.7)) } + [fill(tube, m(0.75)), fill(door, c(0.6)), fill(drum, m(0.55))]

        var s: [Halftone.Stroke] = []
        // The dome, its ribs and open shutter, the tube out of the slit, the drum and its lit door.
        s.append(stroke(arc(dome, domeR, 180, 360, 40) + [dome + P(-domeR, 0)], bold))
        for x in [0.2, 0.25] { s.append(stroke([P(x, dome.y), P(x, dome.y - (domeR * domeR - (x - dome.x) * (x - dome.x)).squareRoot())], hair)) }
        for x in [slit.0, slit.1] { s.append(stroke([P(x, dome.y), P(x, dome.y - (domeR * domeR - (x - dome.x) * (x - dome.x)).squareRoot())], mid)) }
        s.append(stroke(closed(tube), mid))
        s.append(stroke(closed(bar(P(0.16, -0.04), P(0.12, -0.08), 0.12)), mid))
        s += outside(closed(drum), mid, of: views, by: core + 0.055)
        s += outside(closed(door), mid, of: views, by: core + 0.055)
        for x in [0.32, 0.42] { s.append(stroke(closed(rect(x, 0.25, x + 0.04, 0.29)), hair)) }
        // The mountain, its pines, the road up and a car's lights on it.
        s += outside(Array(mountain.dropLast(3)), mid, of: views, by: core + 0.055)
        for pine in pines { s.append(stroke(pine, mid)); s.append(stroke([pine[1] + P(0, 0.12), pine[1] + P(0, 0.16)], mid)) }
        s += outside(road, mid, of: views, by: core + 0.055)
        s += outside(road.map { $0 + P(0.04, 0) }, hair, of: views, by: core + 0.055)
        s.append(stroke(circle(P(0.52, 0.69), 0.012, 8), mid))
        // Stars coming out, and the eyepieces' knurled barrels round the views.
        for at in [P(-0.24, -0.92), P(0.3, -0.84), P(-0.84, 0.04), P(0.86, 0.06), P(-0.14, -0.18), P(0.74, -0.66), P(-0.72, -0.66)] { s += glint(at, 0.03, hair) }
        s = clear(s, of: views)
        for c in views {
            s.append(stroke(circle(c, core, 56), bold))
            s.append(stroke(circle(c, core + 0.05, 56), mid))
            for k in 0..<36 where k % 9 != 4 { let a = 10 * Double(k); s.append(stroke([polar(c, core + 0.012, a), polar(c, core + 0.04, a)], hair)) }
        }
        // The moon, cratered.
        let moon = views[0] + P(0.026, 0.02)
        s.append(stroke(circle(moon, 0.045, 32), 0.0035))
        for (at, r) in [(P(-0.016, -0.014), 0.011), (P(0.018, 0.012), 0.008), (P(0.004, 0.026), 0.005), (P(0.022, -0.02), 0.006), (P(-0.022, 0.018), 0.007)] {
            s.append(stroke(circle(moon + at, r, 10), 0.002))
        }
        // A double star, the bright one and its fainter partner, each with its spikes.
        let pair = views[1] + P(0.018, 0.022)
        for (at, r) in [(P(-0.016, 0.01), 0.012), (P(0.024, -0.018), 0.007)] {
            s.append(stroke(circle(pair + at, r, 14), 0.003))
            for a in [0.0, 90, 180, 270] { s.append(stroke([polar(pair + at, r + 0.004, a), polar(pair + at, r * 3.2, a)], 0.002)) }
        }
        // A comet, its tail fanned away from the sun.
        let comet = views[2] + P(0.03, 0.02)
        s.append(stroke(circle(comet, 0.008, 10), 0.003))
        for (a, l) in [(200.0, 0.07), (210, 0.08), (220, 0.065)] { s.append(stroke(curve(polar(comet, 0.008, a), polar(comet, l * 0.5, a + 4), polar(comet, l, a - 3), 8), 0.002)) }
        // The Pleiades.
        let pleiades = views[3] + P(0.026, -0.02)
        for (at, r) in [(P(-0.03, -0.01), 0.006), (P(-0.012, -0.024), 0.005), (P(0.006, -0.01), 0.007), (P(0.02, -0.026), 0.005), (P(0.028, 0.004), 0.006),
                        (P(0.0, 0.016), 0.005), (P(-0.02, 0.014), 0.004)] { s += glint(pleiades + at, r * 2.4, 0.002) }
        // A spiral galaxy, its arms trailing.
        let galaxy = views[4] + P(0.024, 0.024)
        for k in 0..<2 {
            let arm = (0...20).map { i -> P in
                let t = Double(i) / 20, a = 180 * Double(k) + 250 * t, r = 0.008 + 0.045 * t
                return galaxy + P(r * cos(a * .pi / 180), 0.5 * r * sin(a * .pi / 180))
            }
            s.append(stroke(arm.map { galaxy + P(($0 - galaxy).x * 0.94 - ($0 - galaxy).y * 0.34, ($0 - galaxy).x * 0.34 + ($0 - galaxy).y * 0.94) }, 0.0025))
        }
        s.append(stroke(circle(galaxy, 0.007, 8), 0.003))

        let cuts: [Double] = [0, 40, 80, 130, 170, 220, 260, 310]
        return Halftone.Panel(name: "observatory", tones: { (p: P) -> Tone in
            for (k, v) in views.enumerated() {
                let d = simd_distance(p, v)
                if d < core { return c(0.6) }
                if d < core + 0.05 { return runTone((bearing(p, v) + 23 * Double(k)).truncatingRemainder(dividingBy: 360), cuts, [y(0.75), .zero]) }
            }
            for f in built where f.holds(p) { return f.tone }
            if p.y < dome.y, simd_distance(p, dome) < domeR {
                return p.x > slit.0 && p.x < slit.1 ? .zero : y(0.8)
            }
            if p.y > 0.3, inside(p, mountain) { return Tone(0.3, 0.3, 0) }
            return p.y > 0.05 ? m(0.5) * min((p.y - 0.05) / 0.3, 1) : .zero
        }, strokes: pieces(s))
    }()
}

// MARK: - 73: Radio telescope

/// Level 73's name: a radio telescope array seen from the air, its dishes on the three arms of a Y of rails laid over
/// the desert, the control hut and the transporter at the hub, a mesa's broken edge at the upper right where the radio
/// waves come rolling in, and each dish face up over one of hex's five lenses on this level, magenta, its rim broken
/// where the feed's three legs stand, its shadow cast on the sand. In each dish what it hears: a little green man, as
/// the first pulsar was nicknamed (top), a radio galaxy's jets and lobes (lower right), a black hole's ring (bottom), a
/// signal's trace, one spike ringed (lower left), and a satellite, antennas trailing (upper left).
extension LensArt {
    static let radiotelescope: Halftone.Panel = {
        let dishes = [hex[1], hex[3], hex[4], hex[5], hex[6]]
        let centre = P(0.02, 0.04), arms = [-90.0, 30, 150]
        let source = P(1.15, -0.85)
        let hut = rect(-0.2, -0.2, -0.06, -0.08), van = [P(0.1, 0.12), P(0.22, 0.06), P(0.25, 0.12), P(0.13, 0.18)]
        let mesa = closed([P(0.3, -1), P(0.36, -0.82), P(0.5, -0.78), P(0.56, -0.62), P(0.78, -0.58), P(0.86, -0.4), P(1, -0.36), P(1, -1)])
        let things = [fill(hut, m(0.7)), fill(van, m(0.7)), fill(mesa, Tone(0.2, 0.6, 0))]

        var s: [Halftone.Stroke] = []
        // The Y of rails: each arm's two rails, cut where a dish stands, a spur to each dish off the arms.
        let open: (P) -> Bool = { p in dishes.allSatisfy { simd_distance(p, $0) > core + 0.07 } && simd_length(p) < 1 }
        for a in arms {
            let u = polar(P(0, 0), 1, a), n = P(-u.y, u.x)
            for e in [-0.03, 0.03] { s += runs(span(centre + e * n, centre + 1.2 * u + e * n, 80), mid, keep: open) }
            for k in 1..<24 { let at = centre + 0.05 * Double(k) * u; if open(at) { s.append(stroke([at - 0.04 * n, at + 0.04 * n], hair)) } }
        }
        for (a, b) in [(P(0.02, 0.3), hex[4]), (P(-0.22, -0.3), hex[6])] { s += runs(span(a, b, 30), hair, keep: open) }
        // The hut, the transporter, and the mesa's edge with its gullies.
        s.append(stroke(closed(hut), mid))
        s.append(stroke([P(-0.2, -0.14), P(-0.06, -0.14)], hair))
        s.append(stroke(closed(van), mid))
        for at in [P(0.12, 0.17), P(0.22, 0.13)] { s.append(stroke(circle(at, 0.014, 8), mid)) }
        s.append(stroke(Array(mesa.dropLast(2)), bold))
        for (a, b) in [(P(0.5, -0.78), P(0.46, -0.66)), (P(0.78, -0.58), P(0.72, -0.48)), (P(0.42, -0.8), P(0.44, -0.9))] { s.append(stroke([a, b], hair)) }
        // The radio waves rolling in from the upper right.
        for k in 0..<5 {
            let r = 0.62 + 0.14 * Double(k)
            s += runs(arc(source, r, 100, 190, 30), hair) { p in open(p) && !inside(p, mesa) }
        }
        s = clear(s, of: dishes)
        // The dishes: rim, panel rings, and the feed's three legs.
        for c in dishes {
            s.append(stroke(circle(c, core, 56), bold))
            s.append(stroke(circle(c, core + 0.045, 56), mid))
            s.append(stroke(circle(c, 0.2, 48), mid))
            for k in 0..<3 { let a = 120 * Double(k) + 60; s.append(stroke([polar(c, core + 0.04, a), polar(c, 0.2, a)], mid)) }
            for k in 0..<12 { s.append(stroke([polar(c, 0.2, 30 * Double(k) + 15), polar(c, core, 30 * Double(k) + 15)], hair)) }
        }
        // A little green man, the first pulsar's nickname: his head, eyes and antennae.
        let man = dishes[0] + P(0.026, 0.024)
        s.append(stroke(closed(arc(man, 0.03, 180, 360, 16) + curve(man + P(0.03, 0), man + P(0.02, 0.04), man, 8) + curve(man, man + P(-0.02, 0.04), man + P(-0.03, 0), 8).dropFirst()), 0.0035))
        for e in [-1.0, 1.0] {
            s.append(stroke(closed(ellipse(man + P(e * 0.013, 0.002), 0.009, 0.005, degrees: e * 25, 10)), 0.0028))
            s.append(stroke([man + P(e * 0.012, -0.028), man + P(e * 0.024, -0.052)], 0.0025))
            s.append(stroke(circle(man + P(e * 0.026, -0.058), 0.005, 8), 0.0025))
        }
        // A radio galaxy: the nucleus, its jets and two lobes.
        let galaxy = dishes[1] + P(-0.016, 0.026)
        s.append(stroke(circle(galaxy, 0.006, 8), 0.003))
        for e in [-1.0, 1.0] {
            s.append(stroke([galaxy + e * P(0.008, -0.004), galaxy + e * P(0.034, -0.016)], 0.0025))
            s.append(stroke(closed(ellipse(galaxy + e * P(0.05, -0.024), 0.02, 0.014, degrees: -25, 16)), 0.0025))
        }
        // A black hole: its ring of light, brighter on one side, and the shadow in it.
        let hole = dishes[2] + P(0.024, -0.024)
        s.append(stroke(circle(hole, 0.032, 32), 0.0035))
        s.append(stroke(arc(hole, 0.026, 40, 160, 14), 0.003))
        s.append(stroke(arc(hole, 0.038, 50, 140, 12), 0.0018))
        // A signal: a trace along a strip of printout, one spike ringed.
        let trace = dishes[3] + P(0.0, 0.03)
        s.append(stroke(closed(rect(trace.x - 0.06, trace.y - 0.05, trace.x + 0.06, trace.y + 0.016)), 0.0022))
        s.append(stroke((0...20).map { i in
            let x = -0.054 + 0.108 * Double(i) / 20, spike = i == 12 ? -0.04 : 0.0
            return trace + P(x, ((i * 7) % 5 == 0 ? -0.006 : 0.0) + spike)
        }, 0.0022))
        s.append(stroke(circle(trace + P(0.011, -0.02), 0.022, 16), 0.0025))
        // A satellite, its four antennas trailing.
        let sat = dishes[4] + P(0.026, 0.022)
        s.append(stroke(circle(sat, 0.014, 12), 0.003))
        for a in [150.0, 165, 195, 210] { s.append(stroke([polar(sat, 0.014, a), polar(sat, 0.065, a)], 0.002)) }
        s.append(stroke(arc(sat, 0.024, -60, 60, 6), 0.0018))

        let cuts: [Double] = [0, 50, 70, 170, 190, 290, 310], rim = c(0.85)
        return Halftone.Panel(name: "radiotelescope", tones: { (p: P) -> Tone in
            for dc in dishes {
                let d = simd_distance(p, dc)
                if d < core { return m(0.55) }
                if d < core + 0.045 { return runTone(bearing(p, dc), cuts, [rim, .zero, rim, .zero, rim, .zero, rim]) }
            }
            for f in things where f.holds(p) { return f.tone }
            for dc in dishes where simd_distance(p, dc + P(0.07, 0.09)) < core + 0.045 { return y(0.2) }
            // The rails' bed, a broad band along each arm.
            let q = p - centre
            for a in arms {
                let u = polar(P(0, 0), 1, a), t = simd_dot(q, u)
                if t > -0.06, abs(q.x * u.y - q.y * u.x) < 0.06 { return c(0.6) }
            }
            // The waves: bands of tone round their source.
            let r = simd_distance(p, source)
            if p.x > 0.0, p.y < 0.2, r > 0.55, (r - 0.55).truncatingRemainder(dividingBy: 0.14) < 0.07 { return Tone(0.3, 0, 0.55) }
            return y(0.6)
        }, strokes: pieces(s))
    }()
}

// MARK: - 74: Space telescope

/// Level 74's name: a space telescope in orbit, its steel-blue tube banded in gold foil running in from the left with
/// a solar wing up and a solar wing down, its open end over the hub, and round it, over the other three of hex's four
/// lenses on this level, the worlds it turns to, each limb ringed with its own weather: banded Jupiter (top), ringed
/// Saturn (upper right) and the blue Earth below (bottom). In the hub, down the tube, a deep field of faint galaxies;
/// on Jupiter its great red spot, on Saturn the hexagon storm at its pole, and on Earth a hurricane. Over the lower
/// right, a twist rod, the moon half in shadow, cratered, a lander on its legs at the edge of the dark.
extension LensArt {
    static let spacetelescope: Halftone.Panel = {
        let worlds = [hex[1], hex[2], hex[4]]
        let moon = hex[3] + P(0.05, 0.02), shadow = moon + P(-0.09, -0.07)
        let craters = [(moon + P(0.07, 0.05), 0.04), (moon + P(0.02, 0.12), 0.03), (moon + P(0.11, -0.05), 0.025)]
        let tube = rect(-1, -0.25, 0, 0.25)
        let wings = [bar(P(-0.5, -0.26), P(-0.62, -0.96), 0.24), bar(P(-0.5, 0.26), P(-0.4, 0.96), 0.24)]
        let foil = [rect(-0.8, -0.25, -0.62, 0.25), rect(-0.38, -0.25, -0.3, 0.25)]
        let craft = foil.map { fill($0, y(0.75)) } + [fill(tube, c(0.3))] + wings.map { fill($0, c(0.65)) }
        // Saturn's rings' own frame, tipped 10 degrees.
        let ringFrame: @Sendable (P) -> P = { q in P(q.x * 0.985 + q.y * 0.174, -q.x * 0.174 + q.y * 0.985) }
        let globes = [Tone(0, 0.3, 0.55), y(0.7), c(0.6)]

        var s: [Halftone.Stroke] = []
        // The craft: the tube and its foil, the handrails, the solar wings, their cells and booms.
        s += runs(closed(tube), bold) { simd_distance($0, hex[0]) > core + 0.05 }
        for f in foil { s.append(stroke(closed(f), mid)) }
        for yy in [-0.12, 0.12] { s += runs(span(P(-0.98, yy), P(-0.3, yy), 40), hair) { p in !foil.contains { inside(p, $0) } } }
        for (k, w) in wings.enumerated() {
            s.append(stroke(closed(w), mid))
            let a = k == 0 ? P(-0.5, -0.26) : P(-0.5, 0.26), b = k == 0 ? P(-0.62, -0.96) : P(-0.4, 0.96)
            s.append(stroke([a, b], mid))
            for j in 1..<8 {
                let t = Double(j) / 8, at = a + (b - a) * t, n = simd_normalize(P(-(b - a).y, (b - a).x)) * 0.12
                s.append(stroke([at - n, at + n], hair))
            }
        }
        for at in [P(-0.2, -0.82), P(0.8, -0.72), P(0.86, 0.66), P(-0.84, 0.48), P(0.3, -0.12), P(-0.15, 0.8), P(0.2, 0.36)] { s += glint(at, 0.03, hair) }
        // The tube's open end round the hub, its latches.
        // Saturn's rings, either side of the planet.
        s.append(stroke(ellipse(hex[2], 0.34, 0.085, degrees: 10, 64), mid))
        s.append(stroke(ellipse(hex[2], 0.29, 0.065, degrees: 10, 64), hair))
        s = clear(s, of: [hex[0]] + worlds)
        s.append(stroke(circle(hex[0], core, 56), bold))
        s.append(stroke(circle(hex[0], core + 0.05, 56), mid))
        // The worlds' limbs.
        for c in worlds { s.append(stroke(circle(c, core, 56), mid)) }
        // Down the tube, a deep field: a spiral, ellipticals, a star with spikes.
        let field = hex[0]
        let spiral = field + P(0.03, -0.03)
        s.append(stroke((0...16).map { i in polar(spiral, 0.004 + 0.0016 * Double(i), 26 * Double(i)) }, 0.0022))
        s.append(stroke((0...16).map { i in polar(spiral, 0.004 + 0.0016 * Double(i), 180 + 26 * Double(i)) }, 0.0022))
        for (at, rx, ry, a) in [(P(-0.04, -0.02), 0.012, 0.006, 30.0), (P(-0.01, 0.045), 0.009, 0.005, -40), (P(0.05, 0.03), 0.007, 0.007, 0)] {
            s.append(stroke(closed(ellipse(field + at, rx, ry, degrees: a, 12)), 0.0022))
        }
        let star = field + P(-0.035, 0.03)
        for a in stride(from: 0.0, to: 360, by: 60) { s.append(stroke([star, polar(star, 0.02, a + 30)], 0.0018)) }
        // Jupiter's great red spot and its belts.
        let spot = worlds[0] + P(0.024, 0.026)
        s.append(stroke(closed(ellipse(spot, 0.03, 0.016, 24)), 0.0035))
        s.append(stroke(closed(ellipse(spot + P(0.002, 0), 0.016, 0.007, 16)), 0.002))
        for yy in [-0.026, 0.046] { s.append(stroke(curve(worlds[0] + P(-0.07, yy), worlds[0] + P(0.02, yy - 0.01), worlds[0] + P(0.08, yy + 0.004), 10), 0.002)) }
        // Saturn's hexagon at its pole.
        let hexagon = worlds[1] + P(-0.024, -0.028)
        s.append(stroke(closed((0..<6).map { polar(hexagon, 0.03, 60 * Double($0) + 10) }), 0.003))
        let swirl: [P] = (0...12).map { (i: Int) -> P in polar(hexagon, 0.003 + 0.0015 * Double(i), 30 * Double(i)) }
        s.append(stroke(swirl, 0.002))
        // The moon: its limb, the shadow's edge, its craters and a lander at the edge of the dark.
        s.append(stroke(circle(moon, 0.18, 48), mid))
        s += runs(circle(shadow, 0.17, 48), mid) { simd_distance($0, moon) < 0.18 }
        for (c, r) in craters { s.append(stroke(circle(c, r, 16), hair)) }
        let lander = moon + P(-0.03, 0.06)
        s.append(stroke(closed([lander + P(-0.036, -0.012), lander + P(0.036, -0.012), lander + P(0.044, 0.016), lander + P(-0.044, 0.016)]), mid))
        s.append(stroke(closed([lander + P(-0.024, -0.012), lander + P(-0.016, -0.048), lander + P(0.02, -0.048), lander + P(0.028, -0.012)]), mid))
        for e in [-1.0, 1.0] { s.append(stroke([lander + P(e * 0.036, 0.016), lander + P(e * 0.068, 0.06), lander + P(e * 0.08, 0.06)], mid)) }
        // A hurricane on Earth, its eye and arms.
        let storm = worlds[2] + P(-0.026, 0.022)
        s.append(stroke(circle(storm, 0.006, 8), 0.0025))
        for k in 0..<3 {
            s.append(stroke((0...14).map { i in polar(storm, 0.008 + 0.0028 * Double(i), 120 * Double(k) + 22 * Double(i)) }, 0.0025))
        }

        let cuts: [Double] = [0, 30, 46, 120, 136, 210, 226, 300, 316]
        return Halftone.Panel(name: "spacetelescope", tones: { (p: P) -> Tone in
            let d0 = simd_distance(p, hex[0])
            if d0 < core { return Tone(0.15, 0.25, 0) }
            if d0 < core + 0.05 { return runTone(bearing(p, hex[0]), cuts, [c(0.45), .zero, c(0.45), y(0.8)]) }
            for (k, w) in worlds.enumerated() {
                let d = simd_distance(p, w)
                if d < core { return globes[k] }
                if d < core + 0.04 {
                    // Each limb's weather: Jupiter's belts, Saturn's ring shadow, Earth's clouds.
                    let q = p - w
                    switch k {
                    case 0: return Int(((q.y + 0.4) / 0.07).rounded(.down)) % 2 == 0 ? m(0.6) : y(0.75)
                    case 1: return abs(ringFrame(q).y) < 0.07 ? .zero : y(0.4)
                    default: return sin(bearing(p, w) * .pi / 30) > 0.2 ? y(0.8) : m(0.5)
                    }
                }
            }
            if simd_distance(p, moon) < 0.18 {
                if simd_distance(p, shadow) < 0.17 { return m(0.12) }
                for (c, r) in craters where simd_distance(p, c) < r { return m(0.3) }
                return y(0.55)
            }
            let rings = simd_length_squared(ringFrame(p - hex[2]) / P(0.34, 0.085))
            if rings < 1, rings > 0.6 { return y(0.45) }
            for f in craft where f.holds(p) { return f.tone }
            return .zero
        }, strokes: pieces(s))
    }()
}

// MARK: - 75: Mind's eye

/// Level 75's name, the pack's last: a head in profile, eyes shut, a third eye open on its brow, a trail of little
/// bubbles rising from it to the thoughts round it, each a cloud over one of hex's five lenses on this level, and in
/// each what the mind's eye sees again from the pack: the keyhole it began with (top), a pair of spectacles (upper
/// right), a magnifying glass (lower right), a telescope (bottom) and the moon and a star it dreams by (upper left).
extension LensArt {
    static let mindseye: Halftone.Panel = {
        let thoughts = [hex[1], hex[2], hex[3], hex[4], hex[6]]
        let head = closed([P(0.0, -0.26)] + curve(P(0.0, -0.26), P(0.16, -0.25), P(0.2, -0.12), 8)
            + [P(0.21, -0.08), P(0.28, 0.0), P(0.21, 0.03), P(0.23, 0.07), P(0.2, 0.09), P(0.22, 0.12), P(0.2, 0.16)]
            + curve(P(0.2, 0.16), P(0.2, 0.22), P(0.08, 0.23), 6) + [P(0.06, 0.32), P(-0.12, 0.62), P(-0.5, 0.92), P(-0.95, 0.4)]
            + curve(P(-0.62, 0.26), P(-0.4, 0.2), P(-0.34, 0.02), 6) + curve(P(-0.34, 0.02), P(-0.3, -0.24), P(0.0, -0.26), 10))
        let face = fill(head, m(0.7))
        let brow = P(0.08, -0.15)
        let trail = [(P(0.12, -0.26), 0.02), (P(0.17, -0.315), 0.013), (P(-0.16, -0.26), 0.018), (P(-0.2, -0.33), 0.012)]
        let blobs = trail.map { disc($0.0, $0.1, m(0.35)) } + [oval(brow, 0.07, 0.035, y(0.85))]
        let cloud: @Sendable (Double) -> Double = { a in core + 0.022 + 0.026 * abs(sin(a * .pi / 180 * 4.5)) }

        var s: [Halftone.Stroke] = []
        // The head: its profile, the shut eye and lashes, the ear, and thought's swirl inside.
        s += outside(head, bold, of: thoughts, by: core + 0.05).flatMap { runs($0.points, bold) { simd_length($0) < 1 } }
        s.append(stroke(curve(P(0.08, -0.04), P(0.12, -0.0), P(0.17, -0.04), 6), mid))
        for k in 0..<3 { let at = P(0.095 + 0.03 * Double(k), -0.012); s.append(stroke([at, at + P(-0.008, 0.024)], hair)) }
        s.append(stroke(arc(P(-0.12, 0.04), 0.06, 250, 470, 16), mid))
        s.append(stroke(spiral(P(-0.16, -0.12), 0.01, grow: 0.006, turn: 40, 16), hair))
        // The third eye: lids, iris, pupil and its rays.
        s.append(stroke(closed(curve(brow + P(-0.07, 0), brow + P(0, -0.06), brow + P(0.07, 0), 10) + curve(brow + P(0.07, 0), brow + P(0, 0.06), brow + P(-0.07, 0), 10)), mid))
        s.append(stroke(circle(brow + P(0.006, 0), 0.026, 16), mid))
        s.append(stroke(circle(brow + P(0.01, -0.004), 0.008, 8), mid))
        for a in stride(from: 200.0, through: 340, by: 35) { s.append(stroke([polar(brow, 0.08, a), polar(brow, 0.11, a)], mid)) }
        // The trail of bubbles up to the thoughts, and stars round them.
        for (c, r) in trail { s.append(stroke(circle(c, r, 12), mid)) }
        for at in [P(-0.8, -0.3), P(0.84, 0.0), P(-0.3, -0.86), P(0.3, -0.88), P(0.7, 0.68), P(-0.88, 0.2)] { s += glint(at, 0.03, hair) }
        s = clear(s, of: thoughts)
        // The thought clouds' scalloped edges.
        for c in thoughts {
            s.append(stroke(closed((0..<120).map { polar(c, cloud(3 * Double($0)), 3 * Double($0)) }), mid))
            s.append(stroke(circle(c, core, 56), hair))
        }
        // The keyhole.
        let key = thoughts[0] + P(0.024, 0.02)
        s.append(stroke(arc(key + P(0, -0.014), 0.018, 125, 415, 20) + [key + P(0.018, 0.04), key + P(-0.018, 0.04)] + [polar(key + P(0, -0.014), 0.018, 125)], 0.0035))
        // Spectacles.
        let specs = thoughts[1] + P(0.0, 0.026)
        for e in [-1.0, 1.0] { s.append(stroke(circle(specs + P(e * 0.03, 0), 0.022, 18), 0.0035)) }
        s.append(stroke(arc(specs, 0.01, 200, 340, 6), 0.003))
        for e in [-1.0, 1.0] { s.append(stroke([specs + P(e * 0.052, -0.004), specs + P(e * 0.07, -0.016)], 0.003)) }
        // A magnifying glass.
        let glass = thoughts[2] + P(-0.022, -0.024)
        s.append(stroke(circle(glass, 0.026, 20), 0.0035))
        s.append(stroke(closed(bar(polar(glass, 0.03, 45), polar(glass, 0.07, 45), 0.012)), 0.003))
        s.append(stroke(arc(glass, 0.016, 200, 260, 6), 0.002))
        // A telescope on its tripod.
        let scope = thoughts[3] + P(0.02, -0.02)
        s.append(stroke(closed(bar(scope + P(-0.05, 0.02), scope + P(0.04, -0.02), 0.018)), 0.003))
        s.append(stroke(closed(bar(scope + P(0.04, -0.02), scope + P(0.056, -0.027), 0.026)), 0.003))
        for x in [-0.02, 0.0, 0.02] { s.append(stroke([scope + P(0.0, 0.006), scope + P(x, 0.05)], 0.0025)) }
        // The moon and a star.
        let moon = thoughts[4] + P(0.02, 0.024)
        s.append(stroke(arc(moon, 0.03, 60, 300, 18) + arc(moon + P(0.02, 0), 0.024, 240, 120, 14), 0.0035))
        s.append(stroke(star(moon + P(0.03, -0.034), 0.014, degrees: -80), 0.0025))

        let tones = [y(0.75), c(0.6), y(0.75), c(0.6), y(0.75)]
        return Halftone.Panel(name: "mindseye", tones: { (p: P) -> Tone in
            for (k, t) in thoughts.enumerated() {
                let d = simd_distance(p, t)
                if d < core { return tones[k] }
                if d < core + 0.05, d < cloud(bearing(p, t)) { return k % 2 == 0 ? c(0.5) : y(0.55) }
            }
            for f in blobs where f.holds(p) { return f.tone }
            if face.holds(p) { return m(0.7) }
            return .zero
        }, strokes: pieces(s))
    }()
}
