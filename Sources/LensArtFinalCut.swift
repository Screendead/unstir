// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 68 to 75, the chapter Final cut.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let finalCut: [Int: Halftone.Panel] = [68: lighthouse, 69: eclipseglasses]

    /// Hex's rods, the hub first.
    fileprivate static let hex = [P(0, 0), P(0, -0.56), P(0.485, -0.28), P(0.485, 0.28), P(0, 0.56), P(-0.485, 0.28), P(-0.485, -0.28)]
    /// A hex core's radius.
    fileprivate static let core = 0.264

    /// p's bearing about c in degrees, 0 to 360, 0 at three o'clock and clockwise on screen.
    fileprivate static func bearing(_ p: P, _ c: P) -> Double {
        let a = atan2(p.y - c.y, p.x - c.x) * 180 / .pi
        return a < 0 ? a + 360 : a
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
/// other four of hex's five lenses on this level, each pool's rim broken by glitter. In the lantern's lens the lamp:
/// its flame on the wick in a glass chimney; in the pools, what the light finds: a steamer on the horizon (upper
/// right), a seal on a rock (lower right), a rowing boat (bottom) and a bell buoy (lower left).
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
        // A whale's tail up out of the water, and the splash it throws.
        let whale = hex[3] + P(0.018, 0.012)
        s.append(stroke([whale + P(-0.006, 0.03), whale + P(-0.0045, -0.003)] + curve(whale + P(-0.0045, -0.003), whale + P(-0.0225, -0.003), whale + P(-0.039, -0.0255), 6)
            + curve(whale + P(-0.039, -0.0255), whale + P(-0.0165, -0.024), whale + P(0.0015, -0.0135), 6) + curve(whale + P(0.0015, -0.0135), whale + P(0.0195, -0.024), whale + P(0.042, -0.0255), 6)
            + curve(whale + P(0.042, -0.0255), whale + P(0.027, -0.003), whale + P(0.009, -0.003), 6) + [whale + P(0.009, 0.03)], 0.003))
        s += runs(span(whale + P(-0.0525, 0.03), whale + P(0.0525, 0.03), 20), 0.0025) { abs($0.x - whale.x - 0.002) > 0.011 }
        for (a, b) in [(P(-0.0338, -0.015), P(-0.045, -0.0375)), (P(0.0375, -0.009), P(0.051, -0.03)), (P(-0.0225, 0), P(-0.0413, -0.0045))] { s.append(stroke([whale + a, whale + b], 0.0022)) }
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
        let cuts = [0.0, 24, 50, 90, 118, 150, 196, 230, 262, 300, 330]
        return Halftone.Panel(name: "lighthouse", tones: { p in
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
        }, strokes: s)
    }()
}

// MARK: - 69: Eclipse glasses

/// Level 69's name: a total eclipse watched from a dark hillside, a woman in card eclipse glasses looking up from the
/// lower right, and over hex's five lenses on this level the sun as her glasses show it, gold in the dark filter, each
/// framed in the printed card: in the four ring lenses the moon biting deeper into the sun (a nick, half, a thin
/// crescent, the diamond ring) and in the hub, where the glasses come off, totality: the black moon in its corona, two
/// prominences at its edge.
extension LensArt {
    static let eclipseglasses: Halftone.Panel = {
        let phases = [hex[5], hex[6], hex[1], hex[2]], sun = hex[0]
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
        for at in [P(-0.85, -0.12), P(0.32, -0.86), P(-0.22, -0.3), P(0.86, -0.02), P(-0.72, -0.62), P(0.7, -0.66), P(0.26, 0.04)] { s += glint(at, 0.03, hair) }
        // The card frames round the filters, printed with a border and their safety marks.
        for c in phases {
            s.append(stroke(circle(c, core, 56), bold))
            s.append(stroke(circle(c, core + 0.05, 56), mid))
            for k in 0..<9 { let a = 40 * Double(k) + 7; s.append(stroke([polar(c, core + 0.012, a), polar(c, core + 0.038, a + 4)], hair)) }
        }
        // The sun in the filters, the moon biting in deeper each time: a nick, half, a crescent, the diamond ring.
        for (k, c) in phases.enumerated() {
            let o = c + P(0.03, -0.022), r = 0.032, d = [0.05, 0.034, 0.014, 0.004][k], moon = o + d * simd_normalize(P(1, -0.6))
            s += runs(circle(o, r, 40), 0.0035) { simd_distance($0, moon) > r + 0.001 }
            if k < 3 { s += runs(circle(moon, r, 40), 0.002) { simd_distance($0, o) < r } }
            if k == 3 {
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

        let cuts = [0.0, 18, 40, 75, 96, 140, 160, 205, 226, 270, 290, 330]
        return Halftone.Panel(name: "eclipseglasses", tones: { p in
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
            return p.y < 0.38 ? c(0.42) : m(0.5)
        }, strokes: s)
    }()
}
