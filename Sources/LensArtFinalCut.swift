// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 68 to 75, the chapter Final cut.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let finalCut: [Int: Halftone.Panel] = [68: lighthouse]

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
