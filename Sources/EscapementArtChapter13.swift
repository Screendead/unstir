// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Chapter 13, Fusee: problems 73 to 78's plates, drawn with `Kit`. Each keeps its subject clear of a two-card hub
/// (0.195) round every rod of its layout.
extension EscapementArt {
    private typealias K = Kit

    /// A point `p` of a level circle about `c`, radius 1 in its own units, seen from above at a slant that squashes its
    /// depth by `k`.
    private static func level(_ c: P, _ r: Double, _ k: Double, _ p: P) -> P { c + P(r * p.x, r * k * p.y) }

    /// Rows from y0 to y1, closer toward y0, the horizon: a floor or lawn in perspective.
    private static func receding(from y0: Double, to y1: Double, rows: Int) -> [Double] {
        (0...rows).map { i in
            let t = Double(i) / Double(rows)
            return y0 + (y1 - y0) * pow(t, 1.5)
        }
    }

    /// The pieces of the segment from a to b inside a ring.
    private static func clipped(_ ring: [P], from a: P, to b: P) -> [[P]] {
        let d = b - a
        var ts: [Double] = []
        for i in 0..<(ring.count - 1) {
            let p = ring[i], e = ring[i + 1] - p, den = d.x * e.y - d.y * e.x
            guard abs(den) > 1e-12 else { continue }
            let w = p - a, t = (w.x * e.y - w.y * e.x) / den, u = (w.x * d.y - w.y * d.x) / den
            if u >= 0 && u < 1 && t >= 0 && t <= 1 { ts.append(t) }
        }
        ts.sort()
        return stride(from: 0, to: ts.count - 1, by: 2).map { [a + d * ts[$0], a + d * ts[$0 + 1]] }
    }

    /// The pieces of the level line at `y` inside a ring.
    private static func across(_ ring: [P], at y: Double) -> [[P]] { clipped(ring, from: P(-1.2, y), to: P(1.2, y)) }

    // MARK: 73 Sundial

    /// The glass below the line y = `at`, as one outline.
    private static func cap(below at: Double) -> [P] {
        let a = asin(at / 1.06)
        let rim = arc(.zero, 1.06, from: a, to: .pi - a)
        return rim + [rim[0]]
    }

    /// Problem 73, Sundial, pent, clocks 0+: a garden sundial on a baluster pedestal before a clipped hedge, its dial
    /// plate seen from above with the hour lines fanned from the gnomon's root, and the gnomon's shadow lying across
    /// to the hour, the pedestal's own shadow on the lawn; that hour's numeral in the second ink.
    static func plate73() -> Plate {
        var plate = Plate()
        let c = P(0, -0.12), R = 0.33, k = 0.56
        func on(_ p: P) -> P { level(c, R, k, p) }
        // The dial's north, back and to the right; east a quarter turn clockwise of it.
        let phi = 0.45, north = P(sin(phi), -cos(phi)), east = P(cos(phi), sin(phi))
        let root = -0.4 * north
        func hourLine(_ h: Double) -> P {
            let a = (h - 12) * .pi / 12, t = atan2(0.78 * sin(a), cos(a))
            return north * cos(t) + east * sin(t)
        }
        /// Where the ray from the root meets the circle of radius `r` about the dial's centre.
        func reach(_ d: P, _ r: Double) -> P {
            let b = simd_dot(root, d), q = simd_dot(root, root) - r * r
            return root + d * (-b + sqrt(b * b - q))
        }
        func round(_ r: Double) -> [P] { (0...96).map { on(polar(.zero, r, 2 * .pi * Double($0) / 96)) } }
        let dial = round(1), thickness = dial.map { $0 + P(0, 0.05) }
        let slab = Array(dial[0...48]) + Array(thickness[0...48].reversed()) + [dial[0]]

        // The baluster's half-width down from under the dial to its foot on the lawn at y = 0.8.
        let ground = 0.8
        let profile: [(Double, Double)] = [(0.035, 0.2), (0.075, 0.2), (0.075, 0.15), (0.1, 0.15)]
            + (0...24).map { i -> (Double, Double) in
                let t = Double(i) / 24, y = 0.1 + 0.52 * t
                return (y, 0.075 + 0.07 * pow(sin(.pi * pow(t, 0.8)), 1.5))
            }
            + [(0.62, 0.11), (0.65, 0.11), (0.65, 0.2), (0.72, 0.2), (0.72, 0.3), (ground, 0.3)]
        let column = profile.map { P($0.1, $0.0) } + profile.reversed().map { P(-$0.1, $0.0) } + [P(profile[0].1, profile[0].0)]
        let lit = profile.map { P(-0.3 * $0.1, $0.0) } + profile.reversed().map { P(-0.78 * $0.1, $0.0) } + [P(-0.3 * profile[0].1, profile[0].0)]
        // Its shadow laid on the lawn by an afternoon sun from the left.
        let shadow = column.map { p in P(p.x + 0.85 * (ground - p.y) + 0.02, ground - 0.34 * (ground - p.y)) }

        let horizon = 0.25, hedgeLine = 0.0
        var hedgeTop: [P] = []
        for i in 0...44 {
            let x = -1.1 + 2.2 * Double(i) / 44
            hedgeTop.append(P(x, hedgeLine - 0.03 * abs(sin(Double(i) * .pi / 4))))
        }
        let hedge = hedgeTop + [P(1.1, horizon), P(-1.1, horizon), hedgeTop[0]]

        // Two clipped yews standing out of the hedge at either side.
        let yews = [-0.91, 0.91].map { x -> [P] in
            let side: [P] = (0...16).map { i in
                let t = Double(i) / 16
                return P(x - 0.13 * sin(.pi / 2 * t) * (1 - 0.15 * t), -0.6 + 0.62 * t)
            }
            return side + side.reversed().map { P(2 * x - $0.x, $0.y) } + [side[0]]
        }
        K.ground(&plate, angle: 0.35, around: [cap(below: hedgeLine - 0.035)] + yews)
        for (n, yew) in yews.enumerated() {
            K.mass(&plate, yew)
            let x = n == 0 ? -0.91 : 0.91
            for row in 0..<15 {
                let y = -0.55 + 0.04 * Double(row), half = 0.13 * sin(.pi / 2 * min(1, (y + 0.6) / 0.62)) - 0.025
                for i in stride(from: -half, through: half, by: 0.05) {
                    plate.line(arc(P(x + i + (row % 2 == 0 ? 0 : 0.025), y), 0.016, from: 0.2, to: .pi - 0.2), medium, .bone)
                }
            }
        }
        // The lawn ruled level, its rows closing toward the hedge.
        let rows = receding(from: horizon, to: 1.1, rows: 13).dropFirst()
        for y in rows { plate.line([P(-1.1, y), P(1.1, y)], K.groundWidth + 0.005 * y) }
        // The hedge in ink, clipped in courses of bone leaves.
        K.mass(&plate, hedge)
        for row in 0..<7 {
            let y = hedgeLine + 0.03 + 0.034 * Double(row)
            for i in 0..<46 {
                let x = -1.08 + 0.048 * Double(i) + (row % 2 == 0 ? 0 : 0.024) + 0.01 * rnd(73, row * 40 + i)
                plate.line(arc(P(x, y), 0.016, from: 0.2, to: .pi - 0.2), medium, .bone)
            }
        }
        plate.line([P(-1.1, horizon), P(1.1, horizon)], heavy)
        K.mass(&plate, shadow)
        // Bone between the lawn's rows breaks the shadow.
        let rowList = Array(rows)
        for i in 1..<rowList.count where rowList[i] > 0.45 {
            plate.lines(across(shadow, at: (rowList[i] + rowList[i - 1]) / 2), heavy, .bone)
        }

        // The pedestal in ink, lit down its left.
        K.mass(&plate, column)
        plate.fill(lit)
        plate.lines(hatch([lit], angle: 1.25, gap: 0.03), fine)
        plate.line(lit, fine)
        // The flutes and reflected light down its shadowed side.
        for f in [0.22, 0.5, 0.8] {
            plate.line(profile.filter { $0.0 > 0.11 && $0.0 < 0.61 }.map { P(f * $0.1, $0.0) }, f == 0.8 ? heavy : medium, .bone)
        }
        for (y, w) in [(0.075, 0.2), (0.1, 0.15), (0.65, 0.2), (0.72, 0.3)] {
            plate.line([P(-w, y), P(w, y)], heavy, .bone)
        }

        // The dial: its edge in ink, the plate in bone, the chapter ring and hour lines.
        K.mass(&plate, slab)
        plate.lines(hatch([slab], angle: 0, gap: 0.016).filter { $0[0].x < -0.18 }, fine, .bone)
        plate.fill(dial)
        plate.line(dial, 0.016)
        plate.line(round(0.92), medium)
        plate.line(round(0.64), medium)
        for h in stride(from: 6.0, through: 18.0, by: 0.5) {
            let d = hourLine(h), whole = h == h.rounded()
            plate.line([on(whole ? root : reach(d, 0.64)), on(reach(d, 0.92))], whole ? heavy : medium)
        }
        // The gnomon's shadow from the root along the third hour after noon.
        let shadowAt = 15, d = hourLine(Double(shadowAt)), across = P(-d.y, d.x)
        let tip = reach(d, 0.62)
        K.mass(&plate, [on(root + across * 0.03), on(tip + across * 0.13), on(tip - across * 0.06), on(root - across * 0.03), on(root + across * 0.03)])
        // The chapters on the ring, read from the root.
        for h in 6...18 {
            let p = on(reach(hourLine(Double(h)), 0.78))
            let n = h > 12 ? h - 12 : h
            if h == shadowAt {
                plate.fill(arc(p, 0.04))
                plate.lines(K.numeral(roman(n), at: p, height: 0.055, squeeze: 0.8), 0.014, .second)
            } else {
                plate.lines(K.numeral(roman(n), at: p, height: 0.048, squeeze: 0.66), medium)
            }
        }
        // The gnomon: a triangular plate standing on the noon line, its style rising north.
        let foot = on(root + 0.04 * north), heel = on(root + 0.95 * north), top = heel + P(0, -0.16)
        let side = P(0.024, 0.006)
        K.mass(&plate, [foot, heel, heel + side, top + side, top, foot])
        plate.line([foot + P(0.006, -0.006), top + P(0.004, 0.012)], medium, .bone)
        plate.line([top + P(0.012, 0.03), heel + P(0.012, -0.012)], fine, .bone)

        callout(&plate, "A", from: on(P(-0.5, 0.45)), to: P(-0.5, 0.2))
        callout(&plate, "B", from: top + P(0.006, 0.04), to: P(0.22, -0.38))
        callout(&plate, "C", from: P(0.0, 0.4), to: P(-0.2, 0.86))
        callout(&plate, "D", from: P(0.62, 0.66), to: P(0.66, 0.36))
        return plate
    }

    // MARK: 74 Gnomon

    /// Problem 74, Gnomon, hex, clocks 1+: an obelisk standing as a great gnomon in a paved plaza before a colonnade
    /// and a dome, its long shadow laid along an hour line of the plaza's bold fan of hour lines; the sun's spot at its
    /// tip in the second ink.
    static func plate74() -> Plate {
        var plate = Plate()
        // The plaza in perspective: a point (X, Z) of the ground, Z its depth, seen from a horizon at y = -0.12.
        let horizon = -0.12
        func ground(_ q: P) -> P { P(q.x / q.y, horizon + 1 / q.y) }
        let cx = -0.243, foot = 0.4, base = 0.3, shaft = -0.66, tip = -0.82
        let at = P(cx / (foot - horizon), 1 / (foot - horizon))

        // The colonnade and the dome along the horizon behind.
        var skyline: [P] = [P(-1.1, horizon + 0.1), P(-1.1, horizon - 0.2)]
        for x in stride(from: -1.1, through: 1.1, by: 0.02) {
            let dome = 0.26 * sqrt(max(0, 1 - pow((x - 0.36) / 0.21, 2)))
            let drum = abs(x - 0.36) < 0.19 ? 0.07 : 0
            let lantern = abs(x - 0.36) < 0.03 ? 0.08 : 0
            skyline.append(P(x, horizon - 0.2 - max(dome + drum + lantern, 0) - (abs(x - 0.36) < 0.24 ? 0.03 : 0)))
        }
        skyline += [P(1.1, horizon - 0.2), P(1.1, horizon + 0.1), P(-1.1, horizon + 0.1)]
        let plaza = { () -> [P] in
            let a = asin((horizon + 0.1) / 1.06), rim = arc(.zero, 1.06, from: a, to: .pi - a)
            return rim + [rim[0]]
        }()

        // The obelisk: the lit west face, the shadowed south face, and the pyramidion.
        let ridge = cx - 0.014
        let lit = [P(cx - 0.05, base), P(ridge, base), P(ridge, shaft), P(cx - 0.034, shaft), P(cx - 0.05, base)]
        let dark = [P(ridge, base), P(cx + 0.05, base), P(cx + 0.034, shaft), P(ridge, shaft), P(ridge, base)]
        let capLit = [P(cx - 0.034, shaft), P(ridge, shaft), P(ridge + 0.002, tip), P(cx - 0.034, shaft)]
        let capDark = [P(ridge, shaft), P(cx + 0.034, shaft), P(ridge + 0.002, tip), P(ridge, shaft)]
        let plinth = box(P(cx - 0.08, base), P(cx + 0.08, foot - 0.03)), step = box(P(cx - 0.1, foot - 0.03), P(cx + 0.1, foot))

        // Its shadow along the plaza, toward the viewer and right: the shaft's width, then the pyramidion's point.
        let along = simd_normalize(P(0.78, -0.55)), side = P(-along.y, along.x)
        let w = 0.1 / (foot - horizon) / 2, reach = 1.18, capLength = 0.16
        let shadow = [at + side * w, at + along * reach + side * w * 0.72, at + along * (reach + capLength),
                      at + along * reach - side * w * 0.72, at - side * w, at + side * w].map(ground)

        K.ground(&plate, angle: 0.3, around: [skyline, plaza])
        // The colonnade: its columns standing in bone between dark intercolumns, an attic over them.
        K.mass(&plate, skyline)
        let dome = P(0.36, horizon - 0.3)
        for x in stride(from: -1.04, through: 1.04, by: 0.05) {
            plate.line([P(x, horizon + 0.06), P(x, horizon - 0.14)], 0.03, .bone)
        }
        for y in [horizon + 0.075, horizon - 0.165] {
            plate.line([P(-1.1, y), P(1.1, y)], 0.018, .bone)
        }
        // The attic's balusters.
        for x in stride(from: -1.05, through: 1.05, by: 0.026) where abs(x - 0.36) > 0.2 {
            plate.line([P(x, horizon - 0.177), P(x, horizon - 0.198)], 0.011, .bone)
        }
        for x in stride(from: -1.0, through: 1.0, by: 0.16) where abs(x - 0.36) > 0.3 {
            plate.fill(box(P(x - 0.012, horizon - 0.25), P(x + 0.012, horizon - 0.2)), .black)
        }
        // The dome ruled in courses, dark to the east, its ribs and the drum's windows in bone.
        let shell = (0...40).map { i -> P in polar(dome, 1, .pi + .pi * Double(i) / 40) }.map { P(dome.x + 0.21 * ($0.x - dome.x), dome.y + 0.26 * ($0.y - dome.y)) }
        let shellRing = shell + [shell[0]]
        plate.fill(shellRing)
        for l in hatch([shellRing], angle: 0, gap: 0.036) {
            plate.line(l, 0.01)
            if l[1].x > dome.x + 0.08 { plate.line([P(max(l[0].x, dome.x + 0.08), l[0].y), l[1]], 0.018) }
        }
        plate.line(shellRing, medium)
        for k in -3...3 {
            let x = dome.x + Double(k) * 0.05
            let top = dome.y - 0.26 * sqrt(max(0, 1 - pow((x - dome.x) / 0.21, 2)))
            plate.line(curve(P(x, dome.y), P(dome.x + Double(k) * 0.058, (top + dome.y) / 2), P(dome.x + Double(k) * 0.012, dome.y - 0.25)),
                       heavy, k > 0 ? .bone : .black)
        }
        // The drum in bone between dark pilasters, its windows dark.
        plate.fill(box(P(dome.x - 0.19, horizon - 0.3), P(dome.x + 0.19, horizon - 0.205)))
        for (i, x) in stride(from: dome.x - 0.18, through: dome.x + 0.18, by: 0.036).enumerated() {
            plate.line([P(x, horizon - 0.3), P(x, horizon - 0.205)], 0.012)
            if i < 10 { plate.fill(arc(P(x + 0.018, horizon - 0.255), 0.009) + box(P(x + 0.009, horizon - 0.255), P(x + 0.027, horizon - 0.225)), .black) }
        }
        plate.line(box(P(dome.x - 0.19, horizon - 0.3), P(dome.x + 0.19, horizon - 0.205)), medium)

        // The plaza paved in courses closing toward the horizon, its joints running to the vanishing point.
        plate.fill(plaza)
        var z = 0.86
        while z < 7 {
            let y = horizon + 1 / z
            plate.line([P(-1.1, y), P(1.1, y)], fine + 0.004 * (y - horizon))
            z *= 1.16
        }
        for X in stride(from: -2.4, through: 2.4, by: 0.16) {
            plate.line([ground(P(X, 0.8)), ground(P(X, 8))], fine)
        }
        // The hour lines fanned across the plaza from the obelisk's foot, bold, numbered at the rim.
        for h in -5...5 {
            let dir = P(sin(Double(h) * 0.24 + 0.62), -cos(Double(h) * 0.24 + 0.62))
            var path: [P] = []
            for t in stride(from: 0.4, through: 3.0, by: 0.05) {
                let q = at + dir * t
                if q.y < 0.8 || simd_length(ground(q)) > 1.0 { break }
                path.append(q)
            }
            guard path.count > 1 else { continue }
            K.mass(&plate, K.ribbon(path.map(ground), 0.016))
            if let end = path.last, simd_length(ground(end)) > 0.9 {
                let p = ground(at + dir * (simd_distance(end, at) - 0.12))
                let n = h + 6
                plate.fill(arc(p, 0.04))
                plate.lines(K.numeral(roman(n), at: p, height: 0.05, squeeze: 0.7), medium)
            }
        }
        K.mass(&plate, shadow)
        // The paving's joints run on through the shadow in bone.
        var joint = 0.86
        while joint < 3 {
            plate.lines(across(shadow, at: horizon + 1 / joint), heavy, .bone)
            joint *= 1.077
        }
        for X in stride(from: -2.4, through: 2.4, by: 0.08) {
            plate.lines(clipped(shadow, from: ground(P(X, 0.8)), to: ground(P(X, 8))), medium, .bone)
        }

        // The obelisk over its shadow.
        K.cut(&plate, step)
        K.solid(&plate, plinth, angle: 0.8, gap: 0.02, width: fine)
        plate.fill(lit)
        plate.line(lit, medium)
        // Its glyphs cut down the lit face.
        for k in 0..<22 {
            let y = shaft + 0.04 + Double(k) * 0.042, x0 = cx - 0.044 + 0.002 * Double(k) / 22
            switch k % 4 {
            case 0: plate.line(arc(P((x0 + ridge) / 2, y), 0.009), medium)
            case 1: plate.line([P(x0 + 0.004, y), P(ridge - 0.006, y)], heavy)
            case 2: plate.line([P(x0 + 0.006, y - 0.012), P((x0 + ridge) / 2, y + 0.01), P(ridge - 0.006, y - 0.012)], medium)
            default: plate.line([P((x0 + ridge) / 2, y - 0.014), P((x0 + ridge) / 2, y + 0.014)], heavy)
            }
        }
        K.mass(&plate, dark)
        for k in stride(from: 1, to: 22, by: 2) {
            let y = shaft + 0.04 + Double(k) * 0.042
            plate.line([P(ridge + 0.012, y), P(cx + 0.03, y)], medium, .bone)
        }
        plate.fill(capLit)
        plate.line(capLit, medium)
        K.mass(&plate, capDark)
        // The sun's spot sitting on the tip.
        let sun = P(ridge - 0.07, tip - 0.03)
        plate.fill(arc(sun, 0.05), .second)
        for k in 0..<12 {
            let a = Double(k) * .pi / 6
            plate.line([polar(sun, 0.068, a), polar(sun, 0.1, a)], heavy)
        }

        callout(&plate, "A", from: P(cx + 0.03, -0.55), to: P(-0.07, -0.8))
        callout(&plate, "B", from: ground(at + along * 0.55), to: P(0.17, 0.3))
        callout(&plate, "C", from: P(-0.7, horizon - 0.08), to: P(-0.72, -0.42))
        return plate
    }

    // MARK: 75 Noon mark

    /// A pointed arch's outline from the left springing at (-a, spring) to the right one, apex `rise` above them.
    private static func pointed(_ a: Double, spring: Double, rise: Double, _ n: Int = 30) -> [P] {
        let r = (a * a + rise * rise) / (2 * a), lc = P(-a + r, spring), rc = P(a - r, spring)
        let top = 2 * .pi + atan2(-rise, a - r), start = atan2(-rise, r - a)
        let left = (0...n).map { i in polar(lc, r, .pi + (top - .pi) * Double(i) / Double(n)) }
        let right = (0...n).map { i in polar(rc, r, start - start * Double(i) / Double(n)) }
        return left + right.dropFirst()
    }

    /// Problem 75, Noon mark, pent, clocks 0+: a church nave seen through a pointed arch of dark masonry, a meridian line
    /// of brass let into its checkered floor, and the beam from a hole in the vault laying the sun's image on the line
    /// at noon; the sun's image in the second ink.
    static func plate75() -> Plate {
        var plate = Plate()
        let a = 0.78, spring = -0.15, rise = 0.8
        let opening = pointed(a, spring: spring, rise: rise) + [P(a, 1.2), P(-a, 1.2)]
        let openingRing = opening + [opening[0]]
        // The floor in perspective: a point (X, Z) of it, Z its depth.
        let horizon = -0.05, wall = 0.15
        func floor(_ q: P) -> P { P(0.5 * q.x / q.y, horizon + 0.5 / q.y) }
        let back = 0.5 / (wall - horizon)

        // The nave's air, ruled; the floor and the arch's masonry left out.
        let floorRing = [P(-1.1, wall), P(1.1, wall), P(1.1, 1.1), P(-1.1, 1.1), P(-1.1, wall)]
        K.ground(&plate, angle: 0.5, around: [floorRing])

        // The checkered floor: dark tiles inset in bone, rows closing toward the back wall.
        plate.fill(floorRing)
        var zs: [Double] = []
        var z = back
        while z > 0.3 { zs.append(z); z /= 1.22 }
        let tile = 0.2
        for (row, z0) in zs.enumerated() where row + 1 < zs.count {
            let z1 = zs[row + 1]
            for col in -8...8 where (row + col) % 2 == 0 && col != 0 {
                let x0 = Double(col) * tile - tile / 2, x1 = x0 + tile, inset = 0.03
                let q = [P(x0 + inset, z0 - inset * z0), P(x1 - inset, z0 - inset * z0), P(x1 - inset, z1 + inset * z1), P(x0 + inset, z1 + inset * z1)]
                plate.fill((q + [q[0]]).map(floor), .black)
            }
        }
        for z in zs { plate.line([P(-1.1, horizon + 0.5 / z), P(1.1, horizon + 0.5 / z)], fine) }
        for col in -9...9 {
            let x = Double(col) * tile - tile / 2
            plate.line([floor(P(x, back)), floor(P(x, 0.3))], fine)
        }
        // The meridian line: a brass strip along the floor's middle, ticked at each degree, its ends capped.
        let strip = [P(-0.035, back), P(0.035, back), P(0.035, 0.3), P(-0.035, 0.3), P(-0.035, back)].map(floor)
        plate.fill(strip)
        plate.line(strip, heavy)
        var tick = back
        var n = 0
        while tick > 0.32 {
            let w = n % 5 == 0 ? 0.035 : 0.018
            plate.line([floor(P(-w, tick)), floor(P(w, tick))], n % 5 == 0 ? heavy : medium)
            tick /= 1.045
            n += 1
        }
        plate.line([floor(P(0, back)), floor(P(0, 0.3))], fine)

        // The back wall: three dark arches, the middle one over the meridian's end.
        plate.line([P(-1.1, wall), P(1.1, wall)], heavy)
        for (x, w, h) in [(0.0, 0.13, 0.42), (-0.36, 0.09, 0.3), (0.36, 0.09, 0.3)] {
            let arch = pointed(w, spring: wall - h + w, rise: w * 1.3, 12).map { P($0.x + x, $0.y) } + [P(x + w, wall), P(x - w, wall)]
            K.mass(&plate, arch + [arch[0]])
            plate.line(arch.map { P(x + ($0.x - x) * 1.25, $0.y - 0.02) }.dropLast(2), medium)
        }

        // The arch of dark masonry framing the nave: ashlar coursed in bone, its moulding ruled.
        let masonry = [Array(glass), openingRing]
        let foot = sqrt(1.06 * 1.06 - a * a), turn = atan2(foot, a)
        let frame = [P(-a, foot)] + pointed(a, spring: spring, rise: rise) + [P(a, foot)] + arc(.zero, 1.06, from: turn, to: -.pi - turn).dropFirst()
        plate.fill(frame, .black)
        plate.lines(hatch(masonry, angle: 0, gap: 0.07), medium, .bone)
        for (i, y) in stride(from: -1.085, through: 1.06, by: 0.07).enumerated() {
            for x in stride(from: -1.06 + (i % 2 == 0 ? 0 : 0.07), through: 1.06, by: 0.14) {
                let from = P(x, y), to = P(x, y + 0.07)
                guard !inside(openingRing, (from + to) / 2) else { continue }
                plate.lines(clipped(Array(glass), from: from, to: to), medium, .bone)
            }
        }
        // The arch's moulding: a bone band with its voussoirs.
        let inner = pointed(a, spring: spring, rise: rise), outer = pointed(a + 0.07, spring: spring, rise: rise + 0.07)
        let moulding = inner + outer.reversed() + [inner[0]]
        plate.fill(moulding)
        for k in stride(from: 0, to: inner.count, by: 3) {
            plate.line([inner[k], outer[min(k, outer.count - 1)]], medium)
        }
        plate.line(inner + [P(a, 1.2)], heavy)
        plate.line([P(-a, 1.2)] + inner, heavy)
        plate.line(outer, heavy)
        for x in [-a - 0.035, a + 0.035] { plate.line([P(x, spring), P(x, 1.1)], 0.07 - 0.0, .bone) }
        for x in [-a - 0.07, a + 0.07] { plate.line([P(x, spring), P(x, 1.1)], heavy) }

        // The hole in the vault and the beam it lets down to the line.
        let hole = P(-0.68, -0.66), image = floor(P(0, 0.62))
        let along = simd_normalize(image - hole), side = P(-along.y, along.x)
        let beam = [hole + side * 0.012, image + side * 0.06, image - side * 0.06, hole - side * 0.012, hole + side * 0.012]
        plate.fill(beam)
        plate.line([hole + side * 0.012, image + side * 0.06], medium)
        plate.line([hole - side * 0.012, image - side * 0.06], medium)
        for f in [-0.5, 0.0, 0.5] {
            plate.lines(dashed([hole + side * 0.012 * f, image + side * 0.06 * f], on: 0.05, off: 0.03), fine)
        }
        plate.fill(arc(hole, 0.03))
        plate.line(arc(hole, 0.03), heavy)
        for k in 0..<8 {
            let r = Double(k) * .pi / 4
            plate.line([polar(hole, 0.045, r), polar(hole, 0.07, r)], heavy, .bone)
        }
        // The sun's image lying on the meridian, an ellipse foreshortened along the line.
        plate.fill(ellipse(image, 0.075, 0.035), .second)
        plate.line(ellipse(image, 0.075, 0.035), medium)

        callout(&plate, "A", from: floor(P(0.0, 1.3)), to: P(0.2, 0.18))
        callout(&plate, "B", from: hole + P(0.02, 0.03), to: P(-0.4, -0.5))
        callout(&plate, "C", from: image + P(0.07, 0), to: P(0.17, 0.72))
        return plate
    }

    /// Whether p lies inside a ring, by the even-odd rule.
    private static func inside(_ ring: [P], _ p: P) -> Bool {
        var odd = false
        for i in 0..<(ring.count - 1) {
            let a = ring[i], b = ring[i + 1]
            if (a.y <= p.y) != (b.y <= p.y), p.x < a.x + (p.y - a.y) / (b.y - a.y) * (b.x - a.x) { odd.toggle() }
        }
        return odd
    }

    /// Problem 76, Meridian, hex, clocks 1+.
    static func plate76() -> Plate? { nil }

    /// Problem 77, Solar time, pent, clocks 0+.
    static func plate77() -> Plate? { nil }

    /// Problem 78, Analemma, hex, clocks 1+.
    static func plate78() -> Plate? { nil }
}
