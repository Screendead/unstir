// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Direction B: six engraver's grounds, a problem's own by its number: the pattern steps through all six in a chapter
/// and the chapters start two apart, the second ink steps through four, and the number seeds the rest.
extension EscapementArt {
    enum Pattern: CaseIterable {
        case barleycorn, rosette, quilt, gears, contours, waves
    }

    static let inks = [vermilion, prussian, viridian, sepia]

    static func pattern(_ n: Int) -> Pattern { Pattern.allCases[((n - 1) % 6 + 2 * ((n - 1) / 6)) % 6] }

    static func familyPlate(_ n: Int) -> Plate {
        var plate = Plate(second: inks[n % inks.count])
        ground(&plate, pattern(n), seed: n)
        return plate
    }

    static func ground(_ plate: inout Plate, _ pattern: Pattern, seed: Int) {
        switch pattern {
        case .barleycorn: barleycorn(&plate, seed: seed)
        case .rosette: rosette(&plate, seed: seed)
        case .quilt: quilt(&plate, seed: seed)
        case .gears: gearField(&plate, seed: seed)
        case .contours: contours(&plate, seed: seed)
        case .waves: waves(&plate, seed: seed)
        }
    }

    /// Runs of a polyline inside the glass, so a sweep from a centre off it draws only what shows.
    static func inGlass(_ points: [P]) -> [[P]] {
        var out: [[P]] = [], run: [P] = []
        for p in points {
            if simd_length_squared(p) < 1.15 { run.append(p) } else if run.count > 1 { out.append(run); run = [] } else { run = [] }
        }
        if run.count > 1 { out.append(run) }
        return out
    }

    /// Today's plate, turned: rays in the second ink fanned from a point off the glass over chevrons on a lattice.
    static func barleycorn(_ plate: inout Plate, seed: Int) {
        let a = 2 * .pi * rnd(seed, 1), from = polar(P(0, 0), 2.1, a), cone = asin(1.08 / 2.1)
        let rays = 54 + Int(30 * rnd(seed, 2))
        for i in 0..<rays {
            let b = a + .pi - cone + 2 * cone * Double(i) / Double(rays - 1)
            plate.line([polar(from, 1.0, b), polar(from, 3.2, b)], fine, .second)
        }
        let turn = a + 0.5 + rnd(seed, 3), lattice = 0.07 + 0.03 * rnd(seed, 4), cells = Int(1.1 / lattice) + 1
        for j in -cells...cells {
            for i in -cells...cells {
                let c = P(Double(i) * lattice + (j & 1 == 1 ? lattice / 2 : 0), Double(j) * lattice)
                guard simd_length_squared(c) < 1.2 else { continue }
                let w = 0.26 * lattice, h = 0.13 * lattice
                plate.line(turned([c + P(-w, h), c + P(0, -h), c + P(w, h)], by: turn), fine)
            }
        }
    }

    /// Guilloché: scalloped rings about a centre on the glass's edge, each ring's scallops half a lobe round from the
    /// last so they close into scales that grow with the radius, with a plain ring in the second ink between each pair.
    static func rosette(_ plate: inout Plate, seed: Int) {
        let centre = polar(P(0, 0), 0.98 + 0.2 * rnd(seed, 1), 2 * .pi * rnd(seed, 2))
        let lobes = Double([53, 61, 67][Int(3 * rnd(seed, 3))]), ratio = 1.036 + 0.012 * rnd(seed, 4)
        var r = 0.12, k = 0
        while r < simd_length(centre) + 1.1 {
            let m = max(40, Int(2 * .pi * r / 0.006))
            let ring = (0...m).map { i -> P in
                let t = 2 * .pi * Double(i) / Double(m)
                return polar(centre, r * (1 + 0.5 * (ratio - 1) * sin(lobes * t + Double(k) * .pi)), t)
            }
            plate.lines(inGlass(ring), fine)
            if k % 2 == 1 { plate.lines(inGlass(arc(centre, r * (1 + ratio) / 2)), fine, .second) }
            r *= ratio
            k += 1
        }
    }

    /// Banknote waves: parallel sine lines whose phase slips from line to line, crossed by a wider family in the
    /// second ink.
    static func waves(_ plate: inout Plate, seed: Int) {
        let a = .pi * rnd(seed, 1)
        for (family, gap) in [(0, 0.036 + 0.01 * rnd(seed, 2)), (1, 0.085)] {
            let turn = a + Double(family) * (0.9 + 0.5 * rnd(seed, 3))
            let swell = family == 0 ? 0.02 : 0.03, pitch = 2 * Double.pi / (family == 0 ? 0.2 + 0.1 * rnd(seed, 4) : 0.46)
            var k = 0, v = -1.15
            while v < 1.15 {
                let phase = Double(k) * 0.7 + 2.2 * sin(Double(k) * 0.19 + Double(seed))
                let line = stride(from: -1.15, through: 1.15, by: 0.01).map { u in P(u, v + swell * sin(pitch * u + phase)) }
                plate.lines(inGlass(turned(line, by: turn)), family == 0 ? fine : medium, family == 0 ? .black : .second)
                v += gap
                k += 1
            }
        }
    }

    /// Hatch fields: the glass cut into cells, each ruled its own way, some crossed, some in the second ink.
    static func quilt(_ plate: inout Plate, seed: Int) {
        var sites: [P] = [], i = 0
        while sites.count < 15 && i < 4000 {
            let p = P(2.3 * rnd(seed, 2 * i) - 1.15, 2.3 * rnd(seed, 2 * i + 1) - 1.15)
            i += 1
            if sites.allSatisfy({ simd_distance($0, p) > 0.36 }) { sites.append(p) }
        }
        for (k, site) in sites.enumerated() {
            var cell = Array(box(P(-1.3, -1.3), P(1.3, 1.3)).dropLast())
            for other in sites where other != site {
                let n = other - site, mid = (site + other) / 2
                var cut: [P] = []
                for j in cell.indices {
                    let p = cell[j], q = cell[(j + 1) % cell.count]
                    let dp = simd_dot(p - mid, n), dq = simd_dot(q - mid, n)
                    if dp <= 0 { cut.append(p) }
                    if (dp < 0) != (dq < 0), dp != dq { cut.append(p + (q - p) * (dp / (dp - dq))) }
                }
                cell = cut
                if cell.count < 3 { break }
            }
            guard cell.count >= 3 else { continue }
            let angle = .pi * rnd(seed, 100 + k), gap = 0.02 + 0.022 * rnd(seed, 200 + k)
            let ink: Ink = rnd(seed, 300 + k) < 0.3 ? .second : .black
            plate.lines(hatch([cell], angle: angle, gap: gap), fine, ink)
            let kind = rnd(seed, 400 + k)
            if kind < 0.35 {
                plate.lines(hatch([cell], angle: angle + 1.1, gap: gap * 1.6), fine, ink)
            } else if kind < 0.55 {
                plate.lines(hatch([cell], angle: angle + .pi / 2, gap: gap * 3).flatMap { dashed($0, on: 0.03, off: 0.03) }, medium, ink)
            }
            plate.line(cell + [cell[0]], medium)
        }
    }

    /// A field of wheels, packed largest first, on a ruled tint that shows between them and through their spokes.
    static func gearField(_ plate: inout Plate, seed: Int) {
        var placed: [(c: P, r: Double)] = []
        for t in 0..<900 {
            let r = max(0.065, 0.36 * pow(0.994, Double(t)) * (0.8 + 0.2 * rnd(seed, 3 * t)))
            let c = P(2.3 * rnd(seed, 3 * t + 1) - 1.15, 2.3 * rnd(seed, 3 * t + 2) - 1.15)
            if placed.allSatisfy({ simd_distance($0.c, c) > $0.r + r - 0.006 }) { placed.append((c, r)) }
        }
        var wheels = Plate(), holes: [[P]] = []
        for (k, w) in placed.enumerated() {
            let teeth = [7, 11, 13, 17, 19, 23, 25, 29, 31, 35, 37].min { abs(Double($0) - w.r / 0.011) < abs(Double($1) - w.r / 0.011) }!
            let pitch = w.r / (1 + 2 / Double(teeth))
            holes += wheel(&wheels, w.c, pitch, teeth: teeth, spokes: w.r > 0.2 ? 5 : w.r > 0.11 ? 3 : 1,
                           phase: 2 * .pi * rnd(seed, 5000 + k), rimInk: k % 3 == 0 ? .second : .black)
        }
        plate.lines(hatch([Array(glass)] + holes, angle: .pi * rnd(seed, 9000), gap: 0.026), fine)
        plate.marks += wheels.marks
    }

    /// A survey sheet: contours of a few long hills on a slope, every fourth in the second ink.
    static func contours(_ plate: inout Plate, seed: Int) {
        let hills = (0..<6).map { k in
            (c: P(2 * rnd(seed, 5 * k) - 1, 2 * rnd(seed, 5 * k + 1) - 1), turn: .pi * rnd(seed, 5 * k + 2),
             long: 0.3 + 0.25 * rnd(seed, 5 * k + 3), short: 0.16 + 0.1 * rnd(seed, 5 * k + 4), height: k % 3 == 2 ? -0.7 : 1.0)
        }
        let slope = polar(P(0, 0), 1.1, 2 * .pi * rnd(seed, 90))
        func height(_ p: P) -> Double {
            var h = simd_dot(p, slope)
            for hill in hills {
                let d = p - hill.c, u = d.x * cos(hill.turn) + d.y * sin(hill.turn), v = -d.x * sin(hill.turn) + d.y * cos(hill.turn)
                h += hill.height * exp(-(u * u) / (2 * hill.long * hill.long) - (v * v) / (2 * hill.short * hill.short))
            }
            return h
        }
        let n = 150, lo = -1.1, cell = 2.2 / Double(n)
        let grid = (0...n).map { j in (0...n).map { i in height(P(lo + Double(i) * cell, lo + Double(j) * cell)) } }
        let all = grid.flatMap { $0 }, low = all.min()!, high = all.max()!, levels = 56
        for l in 1..<levels {
            let level = low + (high - low) * Double(l) / Double(levels)
            var segments: [[P]] = []
            for j in 0..<n {
                for i in 0..<n {
                    let x = lo + Double(i) * cell, y = lo + Double(j) * cell
                    let corners = [(P(x, y), grid[j][i]), (P(x + cell, y), grid[j][i + 1]),
                                   (P(x + cell, y + cell), grid[j + 1][i + 1]), (P(x, y + cell), grid[j + 1][i])]
                    var cuts: [P] = []
                    for e in 0..<4 {
                        let (p, a) = corners[e], (q, b) = corners[(e + 1) % 4]
                        if (a < level) != (b < level) { cuts.append(p + (q - p) * ((level - a) / (b - a))) }
                    }
                    if cuts.count >= 2 { segments.append([cuts[0], cuts[1]]) }
                    if cuts.count == 4 { segments.append([cuts[2], cuts[3]]) }
                }
            }
            plate.lines(segments, l % 4 == 0 ? medium : fine, l % 4 == 0 ? .second : .black)
        }
    }
}
