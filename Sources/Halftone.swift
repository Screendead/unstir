// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// Lens's halftone test panel. Flat tones printed as dot screens laid out in clean-picture coordinates, so the pitch is
/// a ruler a lens cannot fake: a magnified core shows swollen, wider-spaced dots. White ink lines on top keep every
/// core asymmetric, so no turn hides in the square screens. Pure geometry, so the tests read the same panel.
enum Halftone {
    /// Dot spacing in tank units, the same for every screen.
    static let pitch = 0.03

    /// An ink: its colour in linear light and its screen's angle.
    struct Ink {
        var colour: SIMD3<Double>
        var degrees: Double
    }

    static let cyan = Ink(colour: linear(0x00E5FF), degrees: 15)
    static let magenta = Ink(colour: linear(0xFF2BD6), degrees: 75)
    static let yellow = Ink(colour: linear(0xFFE600), degrees: 0)

    /// The magenta dial and the yellow gem.
    static let dial = (centre: SIMD2(-0.3, -0.12), radius: 0.42)
    static let gem: [SIMD2<Double>] = [SIMD2(0.34, -0.32), SIMD2(0.74, 0.12), SIMD2(0.36, 0.7), SIMD2(-0.02, 0.18)]

    static let inks = [cyan, magenta, yellow]

    /// Each ink's tone (its dots' share of area) at a point of the clean panel, in the order of `inks`.
    static func tones(_ p: SIMD2<Double>) -> SIMD3<Double> {
        let inDial = simd_distance(p, dial.centre) < dial.radius
        let inGem = inside(p, gem)
        // A cyan sky over the top, a lighter one below the horizon, knocked out under the shapes as print does: on black
        // the inks add, and cyan over magenta would print white.
        let sky = inDial || inGem ? 0 : p.y < 0.38 ? 0.32 : 0.14
        return SIMD3(sky, inDial ? 0.5 : 0, inGem && !inDial ? 0.42 : 0)
    }

    /// The white ink, as polylines.
    static let lines: [[SIMD2<Double>]] = {
        var l: [[SIMD2<Double>]] = []
        func arc(_ c: SIMD2<Double>, _ r: Double, _ a0: Double, _ a1: Double, _ n: Int = 48) -> [SIMD2<Double>] {
            (0...n).map { i in
                let a = (a0 + (a1 - a0) * Double(i) / Double(n)) * .pi / 180
                return c + r * SIMD2(cos(a), sin(a))
            }
        }
        // The dial: its rim, a tick every 30 degrees but none at three o'clock, and a pointer to about two.
        let c = dial.centre, r = dial.radius
        l.append(arc(c, r, 0, 360, 96))
        for k in 0..<12 where k != 0 {
            let a = Double(k) * .pi / 6, u = SIMD2(cos(a), sin(a))
            l.append([c + u * (r * (k % 3 == 0 ? 0.68 : 0.8)), c + u * (r * 0.93)])
        }
        l.append([c + SIMD2(-0.05, 0.04), c + SIMD2(0.2, -0.17), c + SIMD2(0.26, -0.27)])
        l.append(arc(c, 0.035, 0, 360, 24))
        // The gem: its outline, a girdle and facets that lean one way.
        l.append(gem + [gem[0]])
        l.append([gem[3], SIMD2(0.2, 0.06), SIMD2(0.5, 0.0), gem[1]])
        l.append([gem[0], SIMD2(0.2, 0.06), SIMD2(0.36, 0.7)])
        l.append([SIMD2(0.5, 0.0), SIMD2(0.36, 0.7)])
        // A horizon, kinked where it meets the gem, and a bolt down the left.
        l.append([SIMD2(-1, 0.38), SIMD2(-0.1, 0.38), SIMD2(0.08, 0.3)])
        l.append([SIMD2(0.62, 0.38), SIMD2(1, 0.38)])
        l.append([SIMD2(-0.82, 0.46), SIMD2(-0.5, 0.52), SIMD2(-0.6, 0.62), SIMD2(-0.22, 0.86)])
        // Speed lines off the top right, and a star of uneven rays bottom left.
        for k in 0..<5 {
            let y = -0.82 + 0.09 * Double(k), x = 0.12 + 0.06 * Double(k % 3)
            l.append([SIMD2(x, y), SIMD2(x + 0.42 - 0.05 * Double(k), y + 0.12)])
        }
        let star = SIMD2(-0.36, 0.62)
        for k in 0..<7 {
            let a = Double(k) * 2 * .pi / 7 + 0.3, len = [0.18, 0.1, 0.14, 0.07, 0.2, 0.11, 0.09][k]
            l.append([star + 0.03 * SIMD2(cos(a), sin(a)), star + len * SIMD2(cos(a), sin(a))])
        }
        // An arrow pointing up, top left, and a hook top right.
        l.append([SIMD2(-0.62, -0.44), SIMD2(-0.62, -0.76)])
        l.append([SIMD2(-0.7, -0.66), SIMD2(-0.62, -0.76), SIMD2(-0.54, -0.66)])
        l.append(arc(SIMD2(0.72, -0.4), 0.1, -90, 160, 24) + [SIMD2(0.56, -0.28)])
        return l
    }()

    static let lineWidth = 0.008

    /// A white ink stroke: a polyline and its width, in tank units.
    struct Stroke: Sendable {
        var points: [SIMD2<Double>]
        var width: Double
    }

    /// A panel: each ink's tone at a point of the clean panel, in the order of `inks`, under white strokes. Its name keys
    /// its bake in Caches.
    struct Panel: Sendable {
        let name: String
        let tones: @Sendable (SIMD2<Double>) -> SIMD3<Double>
        let strokes: [Stroke]
        private let boxes: [(lo: SIMD2<Double>, hi: SIMD2<Double>)]

        init(name: String, tones: @escaping @Sendable (SIMD2<Double>) -> SIMD3<Double>, strokes: [Stroke]) {
            self.name = name
            self.tones = tones
            self.strokes = strokes
            boxes = strokes.map { s in
                let pad = SIMD2(repeating: s.width)
                return (s.points.reduce(s.points[0], simd_min) - pad, s.points.reduce(s.points[0], simd_max) + pad)
            }
        }

        /// The panel's light at p (tank units, y down) in linear sRGB, edges faded over `aa` (a pixel, in tank units).
        func light(_ p: SIMD2<Double>, aa: Double) -> SIMD3<Double> {
            var c = SIMD3<Double>(repeating: 0)
            for k in inks.indices { c += inks[k].colour * screen(p, inks[k].degrees, aa: aa) { tones($0)[k] } }
            c = simd_min(c, SIMD3(repeating: 1))
            var ink = 0.0
            for (i, s) in strokes.enumerated() {
                let b = boxes[i]
                guard p.x >= b.lo.x - aa, p.y >= b.lo.y - aa, p.x <= b.hi.x + aa, p.y <= b.hi.y + aa else { continue }
                var d = Double.infinity
                for j in 1..<s.points.count { d = min(d, segmentDistance(p, s.points[j - 1], s.points[j])) }
                ink = max(ink, min(max((s.width / 2 - d) / aa + 0.5, 0), 1))
            }
            return c * (1 - ink) + SIMD3(repeating: ink)
        }

        /// The clean panel as gamma-encoded RGBA8, `n` pixels a side over the tank's square, rows top first.
        func pixels(_ n: Int) -> [UInt8] {
            var out = [UInt8](repeating: 255, count: 4 * n * n)
            let px = 2 / Double(n)
            out.withUnsafeMutableBufferPointer { buf in
                nonisolated(unsafe) let base = buf.baseAddress!
                DispatchQueue.concurrentPerform(iterations: n) { j in
                    for i in 0..<n {
                        let c = light(SIMD2((Double(i) + 0.5) * px - 1, (Double(j) + 0.5) * px - 1), aa: px)
                        let k = 4 * (j * n + i)
                        base[k] = UInt8(gamma(c.x) * 255 + 0.5)
                        base[k + 1] = UInt8(gamma(c.y) * 255 + 0.5)
                        base[k + 2] = UInt8(gamma(c.z) * 255 + 0.5)
                    }
                }
            }
            return out
        }

        /// The panel's detail for a bake `n` pixels a side, with an inset over each of `lenses` (a rod each: x, y and its
        /// disc's radius).
        func detail(_ n: Int, lenses: [SIMD3<Double>]) -> Detail {
            let cells = Detail.cells, side = 2 * cells + 1
            let px = 2 / Double(n), texel = px / Detail.density, range = Detail.range * px
            let sides = lenses.map { Int((2 * Detail.reach * Tank.plateau * $0.z / texel).rounded(.up)) }
            // A texel between insets, so no filter reads across.
            let width = max(3 * side + Detail.marks.count + inks.count, sides.reduce(0) { $0 + $1 + 1 })
            let height = side + 1 + (sides.max() ?? 0)
            var out = [UInt8](repeating: 255, count: 4 * width * height)
            func set(_ x: Int, _ y: Int, _ r: UInt8, _ g: UInt8, _ b: UInt8) {
                let k = 4 * (y * width + x)
                out[k] = r; out[k + 1] = g; out[k + 2] = b
            }
            for (k, ink) in inks.enumerated() {
                let a = ink.degrees * .pi / 180, cs = cos(a), sn = sin(a)
                for j in -cells...cells {
                    for i in -cells...cells {
                        // The cell's centre and its dot's radius as `screen` has them.
                        let cell = SIMD2(Double(i), Double(j)) * pitch
                        let t = tones(SIMD2(cell.x * cs - cell.y * sn, cell.x * sn + cell.y * cs))[k]
                        let v = UInt8(min(max(t / .pi, 0).squareRoot() / Detail.radii, 1) * 255 + 0.5)
                        set(k * side + cells + i, cells + j, v, v, v)
                    }
                }
                let c = ink.colour
                set(3 * side + Detail.marks.count + k, 0, UInt8(gamma(c.x) * 255 + 0.5), UInt8(gamma(c.y) * 255 + 0.5),
                    UInt8(gamma(c.z) * 255 + 0.5))
            }
            for (k, v) in Detail.marks.enumerated() { set(3 * side + k, 0, v, v, v) }
            var table: [Float] = [Float(pitch), Float(cells), Float(Detail.radii), Float(range), Float(1 / texel), 1,
                                  Float(Detail.crisp), Float(Detail.soft)]
            for ink in inks { table += [Float(cos(ink.degrees * .pi / 180)), Float(sin(ink.degrees * .pi / 180))] }
            table += [Float(Detail.fade), 0]
            var x0 = 0
            for (lens, s) in zip(lenses, sides) {
                let half = Detail.reach * Tank.plateau * lens.z, corner = SIMD2(lens.x, lens.y) - SIMD2(repeating: half)
                // The distance to the nearest stroke's edge, a stroke's segment at a time over the texels it reaches.
                var edge = [Double](repeating: range, count: s * s)
                for stroke in strokes {
                    let reach = stroke.width / 2 + range
                    for j in 1..<stroke.points.count {
                        let a = stroke.points[j - 1], b = stroke.points[j]
                        let lo = (simd_min(a, b) - SIMD2(repeating: reach) - corner) / texel
                        let hi = (simd_max(a, b) + SIMD2(repeating: reach) - corner) / texel
                        let x = max(Int(lo.x.rounded(.down)), 0), y = max(Int(lo.y.rounded(.down)), 0)
                        let x1 = min(Int(hi.x.rounded(.up)), s - 1), y1 = min(Int(hi.y.rounded(.up)), s - 1)
                        guard x <= x1, y <= y1 else { continue }
                        for v in y...y1 {
                            for u in x...x1 {
                                let p = corner + SIMD2(Double(u) + 0.5, Double(v) + 0.5) * texel
                                edge[v * s + u] = min(edge[v * s + u], segmentDistance(p, a, b) - stroke.width / 2)
                            }
                        }
                    }
                }
                for v in 0..<s {
                    for u in 0..<s {
                        let g = UInt8(min(max(0.5 + edge[v * s + u] / (2 * range), 0), 1) * 255 + 0.5)
                        set(x0 + u, side + 1 + v, g, g, g)
                    }
                }
                table += [Float(lens.x), Float(lens.y), Float(half), Float(x0), Float(side + 1)]
                x0 += s + 1
            }
            return Detail(width: width, height: height, pixels: out, table: table)
        }
    }

    /// What a lens draws finer than the bake (`unstirLens` in Unstir.metal): the bake holds one sample a device pixel,
    /// which a lens at x8 spreads over eight. The dots are geometry, so the shader draws each from its radius, kept here
    /// a cell of each ink's screen; the white strokes it reads from their distance to the nearest stroke's edge, kept
    /// finer than the bake over the middle of each lens's core, the only fluid a lens magnifies. All of it is one
    /// atlas, RGBA8 and grey, as the shader takes one image and a colour match must not cross its channels.
    struct Detail: Sendable {
        /// The strokes' texels a bake pixel, each way. A distance is linear, and its linear filter exact, in any texel
        /// square that lies on one side of a stroke's middle, so a hairline (`LensArt.hair`, about a pixel and a half)
        /// needs two for its edge to be true along a straight run; three halves what is left where strokes meet, at a
        /// corner or between the rings of Keyhole's eye (drawn at the panel's own size, a sample in 400 was over 24
        /// levels from the bake at two, one in 1200 at three: `testTheDetailAtThePanelsOwnSizeIsTheBake`).
        static let density = 3.0
        /// The distance the strokes' texels hold either side of an edge, in bake pixels: an eighth of a pixel at x8 is
        /// a tenth of a level's step.
        static let range = 1.5
        /// How far out a lens's inset reaches, in core radii. At any zoom a lens magnifies both ways only the fluid
        /// from within 0.58 of its core's radius (the limit as the zoom goes to x1); the shader fades the detail out
        /// over the last `fade` of the inset, so a twist under the lens dragging fluid from outside shows no edge.
        static let reach = 0.7, fade = 0.12
        /// A dot's radius, in pitches, at the top of a texel's range: a tone of 1 is 0.564.
        static let radii = 0.6
        /// The detail's weight against the bake by a pixel's footprint on the panel, in bake pixels along its longer
        /// axis: none from `soft` up, so nothing drawn at the panel's own size or smaller changes, and all of it by
        /// `crisp`.
        static let crisp = 0.8, soft = 0.97
        /// Each screen's cells either way of the centre: the tank's corner is √2 out.
        static let cells = Int((2.0.squareRoot() / pitch).rounded(.up))
        /// Two greys the shader checks before it trusts the atlas, after the three screens on the top rows.
        static let marks: [UInt8] = [64, 192]

        let width: Int, height: Int
        /// The atlas, rows top first: each ink's screen (a cell a texel, its dot's radius), the marks and each ink's
        /// colour, then under them an inset a lens.
        let pixels: [UInt8]
        /// What the shader reads the atlas by: the pitch, `cells`, `radii`, the strokes' range in tank units, their
        /// texels a tank unit, the detail's share (1; the glass fades it in), `crisp`, `soft`, each screen's cosine
        /// and sine, `fade` and a pad, then five floats an inset: its centre, its half side in tank units, and its
        /// corner in texels.
        let table: [Float]
    }

    /// The test panel: the dial, the gem and the linework above.
    static let test = Panel(name: "test", tones: { tones($0) }, strokes: lines.map { Stroke(points: $0, width: lineWidth) })

    /// Every panel, the test panel first, then Lens's in level order.
    static let panels: [Panel] = [test] + LensArt.levels.sorted { $0.key < $1.key }.map(\.value)

    /// The panel a Lens level draws, by the level's number: its own once it is drawn (`LensArt.levels`), and the test
    /// panel until then, as for 0, which is every other use of `Picture.halftone`. In a Debug build the harness can name
    /// one for every level (`UNSTIR_PANEL`).
    static func panel(_ level: Int) -> Panel {
        #if DEBUG
        if let name = ProcessInfo.processInfo.environment["UNSTIR_PANEL"], let p = panels.first(where: { $0.name == name }) {
            return p
        }
        #endif
        return LensArt.levels[level] ?? test
    }

    /// The test panel's light at p, which the tests read.
    static func light(_ p: SIMD2<Double>, aa: Double) -> SIMD3<Double> { test.light(p, aa: aa) }

    /// Coverage at p of a screen at `degrees`: the nearest cell's dot, sized by the tone at its own centre, so dots are
    /// whole and a shape's edge is dotted, as in print.
    private static func screen(_ p: SIMD2<Double>, _ degrees: Double, aa: Double, tone: (SIMD2<Double>) -> Double) -> Double {
        let a = degrees * .pi / 180, cs = cos(a), sn = sin(a)
        let u = SIMD2(p.x * cs + p.y * sn, -p.x * sn + p.y * cs)
        let cell = (u / pitch).rounded(.toNearestOrAwayFromZero) * pitch
        let centre = SIMD2(cell.x * cs - cell.y * sn, cell.x * sn + cell.y * cs)
        let t = tone(centre)
        guard t > 0 else { return 0 }
        let radius = pitch * (t / .pi).squareRoot()
        return min(max((radius - simd_distance(u, cell)) / aa + 0.5, 0), 1)
    }

    private static func segmentDistance(_ p: SIMD2<Double>, _ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
        let ab = b - a, h = min(max(simd_dot(p - a, ab) / simd_length_squared(ab), 0), 1)
        return simd_distance(p, a + h * ab)
    }

    static func inside(_ p: SIMD2<Double>, _ polygon: [SIMD2<Double>]) -> Bool {
        var odd = false
        for i in polygon.indices {
            let a = polygon[i], b = polygon[(i + 1) % polygon.count]
            if (a.y > p.y) != (b.y > p.y), p.x < a.x + (p.y - a.y) / (b.y - a.y) * (b.x - a.x) { odd.toggle() }
        }
        return odd
    }

    static func linear(_ hex: UInt32) -> SIMD3<Double> {
        func c(_ v: UInt32) -> Double {
            let s = Double(v & 0xFF) / 255
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        return SIMD3(c(hex >> 16), c(hex >> 8), c(hex))
    }

    static func gamma(_ c: Double) -> Double {
        let c = min(max(c, 0), 1)
        return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055
    }
}
