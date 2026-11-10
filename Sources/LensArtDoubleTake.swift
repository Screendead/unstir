// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 13 to 18, the third chapter.

// MARK: - 13: Porthole

/// Level 13's name: a cabin wall, riveted, with two portholes in it, one over the top core and one over the bottom
/// (hex's two lenses on this level): through the upper a lighthouse on its rock, through the lower, under the
/// waterline, a fish. Level 13 deals the upper lens +2 and the lower +3.
extension LensArt {
    static let porthole: Halftone.Panel = {
        let top = P(0, -0.56), low = P(0, 0.56), gauge = P(0.07, -0.05), lamp = P(0.56, -0.3)
        // The gauge's feed: off the centre, as is the gauge, so that a quarter turn of the hub shows.
        let feed = [P(-0.58, 0.1), P(0.11, 0.1), P(0.11, 0.0), P(0.03, 0.0), P(0.03, 0.18), P(-0.58, 0.18)]
        var fills = [fill(rect(-0.17, top.y + 0.05, 0.17, top.y + 0.17), c(0.65)), disc(top, 0.19, c(0.22)), disc(top, 0.245, y(0.85)),
                     disc(low, 0.19, c(0.65)), disc(low, 0.245, y(0.85)), disc(gauge, 0.15, y(0.3)), fill(feed, c(0.55)), oval(lamp, 0.075, 0.1, y(0.9)),
                     fill(rect(-0.7, -1, -0.58, 1), c(0.55)), fill(rect(0.48, 0.2, 0.64, 0.42), c(0.55))]
        fills.append(fill(rect(-1, 0.28, 1, 1), m(0.48)))

        var s: [Halftone.Stroke] = []
        // The wall: its plates' seams and their rivets, a pipe and its flanges, the lamp in its cage and the switch below.
        for yy in [-0.28, 0.28] {
            s += runs((0...80).map { P(-1 + 0.025 * Double($0), yy) }, mid) { $0.x < -0.7 || $0.x > -0.58 }
            for k in 0..<17 where k != 3 { s.append(stroke(circle(P(-0.96 + 0.12 * Double(k), yy + 0.045), 0.012, 6), hair)) }
        }
        for x in [-0.7, -0.58] { s.append(stroke([P(x, -1), P(x, 1)], mid)) }
        for yy in [-0.46, 0.1, 0.66] { s.append(stroke(closed(rect(-0.73, yy, -0.55, yy + 0.06)), mid)) }
        s.append(stroke(ellipse(lamp, 0.075, 0.1, 24), bold))
        for x in [-0.03, 0.03] { s.append(stroke([lamp + P(x, -0.095), lamp + P(x, 0.095)], hair)) }
        s.append(stroke([lamp + P(-0.075, 0), lamp + P(0.075, 0)], hair))
        s.append(stroke(closed(rect(lamp.x - 0.05, lamp.y - 0.15, lamp.x + 0.05, lamp.y - 0.1)), mid))
        s.append(stroke([P(0.56, -0.2), P(0.56, 0.2)], mid))
        s.append(stroke(closed(rect(0.48, 0.2, 0.64, 0.42)), mid))
        s.append(stroke([P(0.56, 0.31), P(0.6, 0.25)], bold))
        // The gauge on its feed pipe: rim, scale, needle.
        s += runs(feed + [feed[0]], mid) { simd_distance($0, gauge) > 0.15 }
        s.append(stroke(closed(rect(-0.3, 0.085, -0.24, 0.195)), mid))
        s.append(stroke(circle(gauge, 0.15, 32), bold))
        for k in 0..<9 { s.append(stroke([polar(gauge, k % 2 == 0 ? 0.1 : 0.115, 150 + 30 * Double(k)), polar(gauge, 0.13, 150 + 30 * Double(k))], hair)) }
        s.append(stroke([polar(gauge, -0.03, 285), polar(gauge, 0.11, 285)], mid))
        s.append(stroke(circle(gauge, 0.015, 8), mid))
        // The portholes: rim, bolts, hinge and dog, and the glass.
        for c in [top, low] {
            s.append(stroke(circle(c, 0.245, 56), bold))
            s.append(stroke(circle(c, 0.19, 48), mid))
            for k in 0..<8 { s.append(stroke(circle(polar(c, 0.218, 45 * Double(k) + 22.5), 0.012, 6), hair)) }
            s.append(stroke(closed(rect(c.x - 0.31, c.y - 0.04, c.x - 0.24, c.y + 0.04)), mid))
            s.append(stroke(closed(bar(polar(c, 0.24, -20), polar(c, 0.33, -20), 0.035)), mid))
            s.append(stroke(arc(c, 0.15, 200, 240, 8), hair))
        }
        // Through the upper: the sea's line, the lighthouse on its rock, its lamp lit, and a gull.
        let house = top + P(0.022, -0.012)
        s += runs((0...30).map { P(top.x - 0.19 + 0.38 * Double($0) / 30, top.y + 0.05) }) { abs($0.x - house.x) > 0.04 }
        s.append(stroke(arc(house + P(0, 0.062), 0.04, 190, 350, 8), 0.003))
        s.append(stroke(closed([house + P(-0.014, 0.05), house + P(-0.009, -0.01), house + P(0.009, -0.01), house + P(0.014, 0.05)]), 0.003))
        s.append(stroke([house + P(-0.012, 0.02), house + P(0.012, 0.02)], 0.002))
        s.append(stroke(closed([house + P(-0.012, -0.01), house + P(-0.012, -0.026), house + P(0, -0.038), house + P(0.012, -0.026), house + P(0.012, -0.01)]), 0.003))
        for side in [-1.0, 1.0] {
            s.append(stroke([house + P(side * 0.02, -0.022), house + P(side * 0.06, -0.034)], 0.002))
            s.append(stroke([house + P(side * 0.02, -0.016), house + P(side * 0.06, -0.006)], 0.002))
        }
        s.append(stroke(curve(top + P(-0.12, -0.08), top + P(-0.095, -0.11), top + P(-0.075, -0.08), 5) + curve(top + P(-0.075, -0.08), top + P(-0.055, -0.11), top + P(-0.03, -0.08), 5), hair))
        // Through the lower: a fish, its bubbles, and weed.
        let fish = low + P(0.014, -0.026)
        s.append(stroke(ellipse(fish, 0.03, 0.017, 20), 0.004))
        s.append(stroke(closed([fish + P(-0.03, 0), fish + P(-0.05, -0.016), fish + P(-0.05, 0.016)]), 0.003))
        s.append(stroke(circle(fish + P(0.016, -0.004), 0.0025, 6), 0.003))
        s.append(stroke(arc(fish + P(-0.002, 0), 0.012, -50, 50, 6), 0.002))
        for (k, at) in [P(0.045, -0.03), P(0.058, -0.056), P(0.05, -0.085)].enumerated() { s.append(stroke(circle(fish + at, 0.005 + 0.002 * Double(k), 8), 0.002)) }
        for x in [-0.12, -0.09, 0.11] {
            s.append(stroke(curve(low + P(x, 0.16), low + P(x - 0.03, 0.1), low + P(x, 0.06), 6) + curve(low + P(x, 0.06), low + P(x + 0.03, 0.02), low + P(x, -0.03), 6), hair))
        }
        return panel("porthole", fills: fills, strokes: s) { _ in m(0.3) }
    }()
}

// MARK: - 14: Periscope

/// Level 14's name: a periscope up through the swell, its eye over the lower left core, and the steamer it is watching
/// on the skyline over the upper right (hex's two lenses on this level): in the periscope's glass the steamer again,
/// on the cross hairs, and on her deck a sailor waving. Level 14 deals each lens +3 in all.
extension LensArt {
    static let periscope: Halftone.Panel = {
        let eye = P(-0.485, 0.26), ship = P(0.485, -0.28), horizon = -0.2
        let mast = rect(-0.56, 0.3, -0.41, 1.1), head = squircle(P(-0.485, 0.24), 0.14, 0.16)
        let hull = [ship + P(-0.2, 0.05), ship + P(0.22, 0.05), ship + P(0.17, 0.11), ship + P(-0.16, 0.11)]
        let house = rect(ship.x - 0.1, ship.y + 0.0, ship.x + 0.1, ship.y + 0.05)
        let bottle = bar(P(-0.14, 0.1), P(0.08, -0.03), 0.1), fin = [P(0.4, 0.36), P(0.5, 0.16), P(0.58, 0.36)]
        var fills = [disc(eye, 0.085, c(0.25)), disc(eye, 0.115, y(0.85)), fill(head, m(0.6)), fill(mast, m(0.45)), fill(hull, m(0.75)),
                     fill(house, y(0.6))]
        for x in [-0.05, 0.03] { fills.append(fill(rect(ship.x + x, ship.y - 0.07, ship.x + x + 0.04, ship.y), m(0.7))) }
        fills += [fill(bottle, y(0.7)), fill(fin, m(0.6)), disc(P(-0.5, -0.62), 0.12, y(0.9)), fill(rect(-1, horizon, 1, 1), c(0.5))]

        var s: [Halftone.Stroke] = []
        // The sky: sun, cloud, two gulls; and the skyline.
        s.append(stroke(circle(P(-0.5, -0.62), 0.12, 28), mid))
        s.append(stroke(arc(P(0.02, -0.66), 0.08, 180, 360, 10) + arc(P(0.15, -0.66), 0.06, 200, 360, 8), mid))
        s.append(stroke([P(-0.1, -0.66), P(0.24, -0.66)], mid))
        for at in [P(-0.2, -0.42), P(0.06, -0.36)] {
            s.append(stroke(curve(at + P(-0.07, 0), at + P(-0.035, -0.05), at, 6) + curve(at, at + P(0.035, -0.05), at + P(0.07, 0), 6), mid))
        }
        s += runs((0...80).map { P(-1 + 0.025 * Double($0), horizon) }, mid) { abs($0.x - ship.x) > 0.22 }
        // The swell, wider the nearer, a bottle bobbing with a note in it, and a fin.
        for (k, at) in [P(-0.7, -0.08), P(-0.1, -0.1), P(0.76, 0.0), P(0.2, 0.2), P(-0.2, 0.34), P(0.74, 0.5), P(0.1, 0.56), P(-0.84, 0.62), P(0.46, 0.8), P(-0.14, 0.86)].enumerated() {
            let w = 0.05 + 0.012 * Double(k)
            s.append(stroke(curve(at + P(-w, 0), at + P(-w / 2, -w / 2), at, 6) + curve(at, at + P(w / 2, w / 2), at + P(w, 0), 6), k > 4 ? mid : hair))
        }
        s.append(stroke(closed(bottle), mid))
        s.append(stroke(closed(bar(P(0.08, -0.03), P(0.15, -0.07), 0.04)), mid))
        s.append(stroke(closed(bar(P(-0.08, 0.065), P(0.02, 0.005), 0.045)), hair))
        s.append(stroke(curve(P(-0.2, 0.14), P(0.0, 0.19), P(0.18, 0.02), 8), hair))
        s.append(stroke([fin[0], fin[1], fin[2]], bold))
        s.append(stroke(curve(P(0.34, 0.38), P(0.5, 0.33), P(0.64, 0.38), 8), mid))
        // The steamer: hull, deckhouse and its ports, two funnels and their smoke, a mast and its flag, and the sailor.
        s.append(stroke(closed(hull), bold))
        s.append(stroke(closed(house), mid))
        for k in 0..<4 { s.append(stroke(circle(P(ship.x - 0.07 + 0.047 * Double(k), ship.y + 0.026), 0.008, 6), hair)) }
        for x in [-0.05, 0.03] {
            s.append(stroke(closed(rect(ship.x + x, ship.y - 0.07, ship.x + x + 0.04, ship.y)), mid))
            s.append(stroke(curve(P(ship.x + x + 0.02, ship.y - 0.08), P(ship.x + x - 0.02, ship.y - 0.14), P(ship.x + x - 0.1, ship.y - 0.15), 8), hair))
        }
        s.append(stroke([ship + P(0.16, 0.05), ship + P(0.16, -0.1)], mid))
        s.append(stroke(closed([ship + P(0.16, -0.1), ship + P(0.2, -0.085), ship + P(0.16, -0.07)]), hair))
        let sailor = ship + P(-0.022, -0.012)
        s.append(stroke(circle(sailor + P(0, -0.014), 0.005, 8), 0.003))
        s.append(stroke([sailor + P(0, -0.008), sailor + P(0, 0.012)], 0.003))
        s.append(stroke([sailor + P(0, -0.004), sailor + P(0.012, -0.018)], 0.002))
        s.append(stroke([sailor + P(0, -0.004), sailor + P(-0.01, 0.004)], 0.002))
        // The periscope: mast, its wake, the head and its glass, cross hairs on it, and the steamer in them.
        s.append(stroke([P(-0.56, 0.38), P(-0.56, 1.1)], bold))
        s.append(stroke([P(-0.41, 0.38), P(-0.41, 1.1)], bold))
        for k in 0..<3 { s.append(stroke(curve(P(-0.7 - 0.06 * Double(k), 0.8 + 0.07 * Double(k)), P(-0.485, 0.7 + 0.07 * Double(k)), P(-0.27 + 0.06 * Double(k), 0.8 + 0.07 * Double(k)), 12), mid)) }
        s.append(stroke(closed(head), bold))
        s.append(stroke(circle(eye, 0.115, 32), bold))
        s.append(stroke(circle(eye, 0.085, 28), mid))
        s.append(stroke([eye + P(-0.085, 0), eye + P(-0.03, 0)], hair))
        s.append(stroke([eye + P(0.045, 0), eye + P(0.085, 0)], hair))
        s.append(stroke([eye + P(0, -0.085), eye + P(0, -0.04)], hair))
        s.append(stroke([eye + P(0, 0.035), eye + P(0, 0.085)], hair))
        let seen = eye + P(0.012, -0.012)
        s.append(stroke(closed([seen + P(-0.026, 0.008), seen + P(0.028, 0.008), seen + P(0.02, 0.02), seen + P(-0.02, 0.02)]), 0.003))
        s.append(stroke(closed(rect(seen.x - 0.012, seen.y - 0.002, seen.x + 0.012, seen.y + 0.008)), 0.002))
        for x in [-0.008, 0.004] { s.append(stroke([seen + P(x, -0.002), seen + P(x, -0.016)], 0.0036)) }
        s.append(stroke(curve(seen + P(-0.008, -0.02), seen + P(-0.02, -0.03), seen + P(-0.034, -0.028), 5), 0.0016))
        return panel("periscope", fills: fills, strokes: s) { _ in c(0.18) }
    }()
}

// MARK: - 15: Telescope

/// Level 15's name: a telescope on its tripod on a hill at night, aimed up at the top core (eye's small lens on this
/// level), where the star it has found turns out to be a ringed planet, a moon beside it. Level 15 deals the lens +1
/// then +2.
extension LensArt {
    static let telescope: Halftone.Panel = {
        let planet = P(0.014, -0.585), foot = P(-0.44, 0.5), tip = P(-0.15, -0.2), aim = simd_normalize(tip - foot)
        let tube = bar(foot, tip, 0.15), cap = bar(tip, tip + aim * 0.13, 0.2), ocular = bar(foot - aim * 0.12, foot, 0.07)
        let finder = bar(foot + aim * 0.2 + P(-0.1, -0.04), foot + aim * 0.48 + P(-0.1, -0.04), 0.045)
        let pivot = foot + aim * 0.36
        let hill = curve(P(-1, 0.86), P(-0.2, 0.56), P(1, 0.9), 24) + [P(1, 1), P(-1, 1)]
        let dome = arc(P(0.6, 0.78), 0.17, 180, 360, 16)
        var fills = [fill(cap, y(0.85)), fill(ocular, y(0.85)), fill(finder, y(0.6)), fill(tube, m(0.6)),
                     fill(dome, c(0.6)), fill(rect(0.43, 0.78, 0.77, 0.9), c(0.4))]
        for end in [P(-0.62, 1.0), P(-0.26, 1.0), P(-0.04, 0.98)] { fills.append(fill(bar(pivot + P(0, 0.06), end, 0.045), y(0.5))) }
        fills.append(fill(hill, m(0.42)))

        var s: [Halftone.Stroke] = []
        // The stars, a few with rays, the Plough joined up, and the moon's crescent.
        for (k, at) in [P(-0.7, -0.5), P(-0.5, -0.74), P(-0.84, -0.1), P(0.3, -0.8), P(0.66, -0.56), P(0.86, -0.2), P(-0.74, 0.3), P(0.9, 0.24),
                        P(0.3, 0.46), P(-0.3, -0.62), P(0.08, 0.26), P(-0.9, 0.56)].enumerated() {
            if k % 3 == 0 { s += glint(at, 0.05, hair) } else { s.append(stroke(circle(at, 0.007, 6), mid)) }
        }
        let plough = [P(0.2, -0.26), P(0.32, -0.16), P(0.44, -0.14), P(0.54, -0.04), P(0.52, 0.12), P(0.7, 0.14), P(0.72, -0.02)]
        s.append(stroke(plough + [plough[3]], hair))
        for at in plough { s.append(stroke(circle(at, 0.012, 8), mid)) }
        let moon = P(0.58, -0.42)
        s.append(stroke(arc(moon, 0.11, 60, 300, 24) + arc(moon + P(0.07, 0), 0.085, 240, 120, 20), bold))
        // The hill, the observatory on it, its slit open.
        s.append(stroke(Array(hill.prefix(25)), bold))
        s.append(stroke(dome, bold))
        s.append(stroke(closed(rect(0.43, 0.78, 0.77, 0.9)), mid))
        s.append(stroke(closed(bar(P(0.6, 0.62), P(0.66, 0.77), 0.05)), hair))
        // The telescope: tube, dew cap, eyepiece, finder and its two rings, the mount and tripod.
        for end in [P(-0.62, 1.0), P(-0.26, 1.0), P(-0.04, 0.98)] { s.append(stroke(closed(bar(pivot + P(0, 0.06), end, 0.045)), mid)) }
        s.append(stroke(closed(tube), bold))
        s.append(stroke(closed(cap), bold))
        s.append(stroke(closed(ocular), mid))
        s.append(stroke(closed(finder), mid))
        for t in [0.24, 0.44] { s.append(stroke([foot + aim * t + P(-0.07, -0.028), foot + aim * t + P(-0.12, -0.05)], mid)) }
        for t in [0.2, 0.55, 0.6] { s.append(stroke([tube[0] + aim * (t * 0.76), tube[3] + aim * (t * 0.76)], hair)) }
        s.append(stroke(circle(pivot + P(0, 0.02), 0.05, 16), bold))
        // Where it points: the planet, banded, in its ring, a moon to one side, and the line of sight up to it.
        s += dashes(tip + aim * 0.16, planet - aim * 0.07, 6)
        s.append(stroke(circle(planet, 0.022, 20), 0.0044))
        s.append(stroke([planet + P(-0.018, -0.006), planet + P(0.018, -0.008)], 0.0016))
        s.append(stroke([planet + P(-0.02, 0.006), planet + P(0.02, 0.004)], 0.0016))
        s += runs(ellipse(planet, 0.048, 0.013, degrees: -18, 40), 0.003) { simd_distance($0, planet) > 0.024 || $0.y > planet.y + 0.2 * ($0.x - planet.x) }
        s.append(stroke(circle(planet + P(-0.052, -0.03), 0.005, 8), 0.003))
        return panel("telescope", fills: fills, strokes: s) { _ in c(0.15) }
    }()
}

// MARK: - 16: Eyepiece

/// Level 16's name: a watchmaker's eyepiece set down on an open watch, over the top core (tri's lens on this level),
/// and under it a jewel in its setting and the maker's star cut beside it. Level 16 deals the lens +1 three times.
extension LensArt {
    static let eyepiece: Halftone.Panel = {
        let loupe = P(0, -0.42), watch = P(0, 0.06), balance = P(0.3637, 0.25), barrel = P(-0.3637, 0.25)
        let jewel = loupe + P(-0.022, -0.02), mark = loupe + P(0.03, 0.016)
        let bridge = [P(-0.1, -0.02), P(0.28, -0.12), P(0.62, 0.1), P(0.56, 0.2), P(0.26, 0.02), P(-0.06, 0.12)]
        let fills = [disc(jewel, 0.013, m(0.9)), disc(loupe, 0.26, c(0.12)), disc(loupe, 0.37, m(0.75)), disc(balance, 0.2, c(0.3)),
                     disc(barrel, 0.27, y(0.6)), fill(bridge, y(0.7)), disc(watch, 0.86, y(0.26)), disc(watch, 0.93, y(0.8))]

        var s: [Halftone.Stroke] = []
        // The case and the plate, striped.
        s.append(stroke(circle(watch, 0.93, 96), bold))
        s.append(stroke(circle(watch, 0.86, 96), mid))
        for k in 0..<9 {
            let x = -0.8 + 0.2 * Double(k)
            s += runs((0...40).map { P(x + 0.2 * Double($0) / 40, 0.5 + 0.5 * Double($0) / 40) }) { simd_distance($0, watch) < 0.86 && simd_distance($0, barrel) > 0.3 }
        }
        // The barrel, toothed, its ratchet and click.
        s.append(stroke(circle(barrel, 0.27, 56), bold))
        for k in 0..<36 { s.append(stroke([polar(barrel, 0.27, 10 * Double(k)), polar(barrel, 0.295, 10 * Double(k) + 3)], hair)) }
        s.append(stroke(circle(barrel, 0.12, 28), mid))
        for k in 0..<10 { s.append(stroke([polar(barrel, 0.12, 36 * Double(k)), polar(barrel, 0.15, 36 * Double(k) + 14), polar(barrel, 0.12, 36 * Double(k) + 36)], hair)) }
        s.append(stroke(closed(rect(barrel.x - 0.025, barrel.y - 0.025, barrel.x + 0.025, barrel.y + 0.025)), mid))
        s.append(stroke(curve(barrel + P(0.16, -0.1), barrel + P(0.26, -0.2), barrel + P(0.2, -0.3), 8), bold))
        // The balance: rim, three arms, its spring wound out from the staff, and the cock over it with its screw.
        s.append(stroke(circle(balance, 0.2, 48), bold))
        s.append(stroke(circle(balance, 0.17, 40), hair))
        for k in 0..<3 { s.append(stroke([balance, polar(balance, 0.17, 120 * Double(k) + 50)], mid)) }
        s.append(stroke((0...60).map { polar(balance, 0.012 + 0.0022 * Double($0), 24 * Double($0)) }, hair))
        s.append(stroke(closed(bridge), bold))
        for (at, t) in [(P(0.0, 0.04), 30.0), (P(0.54, 0.12), 110.0), (P(-0.6, -0.2), 70.0), (P(0.5, 0.62), 160.0), (P(-0.1, 0.7), 15.0)] {
            s.append(stroke(circle(at, 0.035, 14), mid))
            s.append(stroke([polar(at, 0.035, t), polar(at, -0.035, t)], mid))
        }
        // A wheel between them, spoked, and the crown at the side.
        let wheel = P(0.04, 0.5)
        s.append(stroke(circle(wheel, 0.15, 36), mid))
        for k in 0..<30 { s.append(stroke([polar(wheel, 0.15, 12 * Double(k)), polar(wheel, 0.17, 12 * Double(k))], hair)) }
        for k in 0..<5 { s.append(stroke([polar(wheel, 0.03, 72 * Double(k) + 10), polar(wheel, 0.15, 72 * Double(k) + 10)], hair)) }
        s.append(stroke(circle(wheel, 0.03, 10), mid))
        // The eyepiece: its cup, knurled, and its glass, a streak across it.
        s.append(stroke(circle(loupe, 0.37, 72), bold))
        s.append(stroke(circle(loupe, 0.26, 64), bold))
        for k in 0..<40 { s.append(stroke([polar(loupe, 0.29, 9 * Double(k)), polar(loupe, 0.345, 9 * Double(k))], hair)) }
        s.append(stroke(arc(loupe, 0.22, 200, 245, 10), mid))
        // Under it: the jewel in its setting with its two screws, the pivot's hole, and the maker's star.
        s.append(stroke(circle(jewel, 0.013, 14), 0.003))
        s.append(stroke(circle(jewel, 0.024, 18), 0.0024))
        s.append(stroke(circle(jewel, 0.003, 6), 0.003))
        for t in [20.0, 200] { s.append(stroke(circle(polar(jewel, 0.019, t), 0.0025, 6), 0.002)) }
        s.append(stroke(star(mark, 0.016, degrees: -70), 0.003))
        s.append(stroke(curve(loupe + P(-0.2, 0.1), loupe + P(-0.02, 0.07), loupe + P(0.2, 0.14), 12), hair))
        s.append(stroke(curve(loupe + P(-0.16, -0.14), loupe + P(0.04, -0.09), loupe + P(0.2, -0.12), 12), hair))
        return panel("eyepiece", fills: fills, strokes: s) { _ in m(0.24) }
    }()
}

// MARK: - 17: Microscope

/// Level 17's name: a microscope in the middle, and round it, over the top, lower right and lower left cores (hex's
/// three lenses on this level), three views down it: an amoeba, a diatom and a slipper animalcule. Level 17 deals the
/// lenses +3, +2 and +3.
extension LensArt {
    static let microscope: Halftone.Panel = {
        let views = [P(0, -0.56), P(0.485, 0.28), P(-0.485, 0.28)], slide = P(0.03, 0.2)
        let eyeEnd = P(-0.3, -0.36), nose = P(0.02, 0.02), along = simd_normalize(nose - eyeEnd)
        let tube = bar(eyeEnd, nose, 0.13), ocular = bar(eyeEnd - along * 0.09, eyeEnd, 0.09), lensEnd = bar(nose, nose + P(0.006, 0.13), 0.06)
        let arm = curve(P(-0.16, -0.16), P(-0.36, 0.1), P(-0.2, 0.44), 16) + curve(P(-0.11, 0.44), P(-0.24, 0.12), P(-0.08, -0.08), 16)
        let stage = rect(-0.2, 0.2, 0.26, 0.245), foot = [P(-0.3, 0.44), P(0.3, 0.44), P(0.34, 0.54), P(-0.34, 0.54)]
        var fills = views.map { disc($0, 0.2, c(0.3)) } + views.map { disc($0, 0.235, y(0.85)) }
        fills += [fill(ocular, y(0.85)), fill(lensEnd, y(0.85)), fill(tube, m(0.7)), fill(stage, y(0.8)), fill(arm, m(0.5)), fill(foot, m(0.75)),
                  disc(P(0.04, 0.34), 0.05, c(0.6)), fill(rect(-1, 0.54, 1, 1), y(0.22))]

        var s: [Halftone.Stroke] = []
        // The bench, a dropper bottle and a box of slides on it.
        s += runs((0...80).map { P(-1 + 0.025 * Double($0), 0.54) }, mid) { abs($0.x) > 0.34 }
        s.append(stroke(closed(rect(0.52, 0.66, 0.84, 0.8)), mid))
        for k in 1..<6 { s.append(stroke([P(0.52 + 0.053 * Double(k), 0.66), P(0.52 + 0.053 * Double(k), 0.8)], hair)) }
        s.append(stroke(closed(rect(-0.8, 0.64, -0.64, 0.86)), mid))
        s.append(stroke(closed(rect(-0.75, 0.56, -0.69, 0.64)), mid))
        s.append(stroke([P(-0.8, 0.74), P(-0.64, 0.74)], hair))
        // The microscope: foot, arm, stage and slide, the mirror under it, tube, eyepiece, objective and the focus wheels.
        s.append(stroke(closed(foot), bold))
        s.append(stroke(Array(arm.prefix(17)), bold))
        s.append(stroke(Array(arm.suffix(17)), bold))
        s.append(stroke(closed(stage), bold))
        s.append(stroke(closed(rect(-0.06, 0.185, 0.12, 0.2)), mid))
        s.append(stroke(circle(P(0.04, 0.34), 0.05, 16), mid))
        s.append(stroke([P(0.04, 0.39), P(0.04, 0.44)], mid))
        s.append(stroke(closed(tube), bold))
        s.append(stroke(closed(ocular), mid))
        s.append(stroke(closed(lensEnd), mid))
        for at in [P(-0.24, 0.0), P(-0.25, 0.1)] { s.append(stroke(circle(at, 0.045, 14), mid)); s.append(stroke(circle(at, 0.015, 8), hair)) }
        // The three views, each led from the slide: rim, glass and what swims in it.
        for (k, c) in views.enumerated() {
            s += dashes(slide + simd_normalize(c - slide) * 0.06, c - simd_normalize(c - slide) * 0.24, k == 0 ? 7 : 5)
            s.append(stroke(circle(c, 0.235, 56), bold))
            s.append(stroke(circle(c, 0.2, 48), mid))
        }
        // An amoeba: its lobes, its nucleus and two bubbles.
        let amoeba = views[0] + P(0.012, -0.022)
        let lobes = (0..<36).map { k -> P in
            let t = Double(k), r: Double = 0.03 + 0.009 * sin(t * 0.9) + 0.006 * cos(t * 1.7)
            return polar(amoeba, r, 10 * t)
        }
        s.append(stroke(closed(lobes), 0.0036))
        s.append(stroke(circle(amoeba + P(0.006, 0.002), 0.006, 8), 0.0044))
        for at in [P(-0.014, -0.01), P(-0.008, 0.016)] { s.append(stroke(circle(amoeba + at, 0.004, 6), 0.002)) }
        for (at, r) in [(P(-0.11, 0.07), 0.025), (P(0.1, 0.09), 0.018), (P(0.09, -0.1), 0.02)] { s.append(stroke(circle(views[0] + at, r, 12), hair)) }
        // A diatom: a boat-shaped shell, its seam and ribs.
        let diatom = views[1] + P(0.01, -0.03), lie = P(cos(0.4), sin(0.4)), rib = P(-sin(0.4), cos(0.4))
        s.append(stroke(ellipse(diatom, 0.05, 0.017, degrees: 23, 28), 0.004))
        s.append(stroke([diatom - lie * 0.04, diatom + lie * 0.04], 0.002))
        for k in -3...3 where k != 0 { s.append(stroke([diatom + lie * (0.011 * Double(k)) - rib * 0.012, diatom + lie * (0.011 * Double(k)) + rib * 0.012], 0.0016)) }
        for (at, r) in [(P(-0.1, 0.08), 0.02), (P(0.08, 0.1), 0.028), (P(-0.09, -0.09), 0.016)] { s.append(stroke(circle(views[1] + at, r, 12), hair)) }
        // A slipper animalcule: its outline, the hairs it rows with, its mouth's groove and two stars inside.
        let slipper = views[2] + P(-0.01, -0.028)
        let shape = (0..<40).map { k -> P in
            let t = 2 * .pi * Double(k) / 40
            return slipper + lie * (0.046 * cos(t)) + rib * ((0.018 + 0.006 * cos(t)) * sin(t))
        }
        s.append(stroke(closed(shape), 0.0036))
        for k in stride(from: 0, to: 40, by: 2) { s.append(stroke([shape[k], shape[k] + simd_normalize(shape[k] - slipper) * 0.01], 0.0014)) }
        s.append(stroke(curve(slipper - lie * 0.02 - rib * 0.014, slipper, slipper + lie * 0.012 + rib * 0.006, 6), 0.002))
        for x in [-0.024, 0.026] { s.append(stroke(star(slipper + lie * x, 0.006, points: 6, inner: 0.4), 0.0014)) }
        for (at, r) in [(P(0.1, 0.08), 0.022), (P(-0.1, 0.1), 0.016), (P(0.1, -0.08), 0.02)] { s.append(stroke(circle(views[2] + at, r, 12), hair)) }
        return panel("microscope", fills: fills, strokes: s) { _ in c(0.18) }
    }()
}
