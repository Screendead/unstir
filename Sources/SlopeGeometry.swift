// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreGraphics
import Foundation

/// The slope's geometry (docs/slope.md, 1.2): the one source of every position on it, for Slope.metal, which draws
/// the rock from `SlopeLay.uniforms`, and for the views that set pebbles, words and targets on it. Pure: no views.
///
/// The world is a column: a surface, then stretches one under another, then a foot. A stretch is a run of terraces, a
/// terrace up to nine ledges, and a ledge seats one pebble. All of it is in points: x from the screen's leading edge,
/// depth from the surface. A zoom `z` from 0 (the overview) to 1 (the dive) does not magnify; it opens depth. At 0
/// a terrace's ledges lie 1.3 pt apart and read as one long ledge with its pebbles along the top; at 1 they stand a
/// pitch apart, each its own overhung ledge.
struct SlopeColumn: Equatable, Sendable {
    /// A stretch's rock, each with its own colour and ledge: sandstone, mauve scallops, slate plates, basalt pillows,
    /// and a pack's pale stone.
    enum Rock: Int, Sendable, CaseIterable { case sand, mauve, slate, basalt, pale }

    /// What lies under the last ledge: more rock, the drop-off into open water, or a hollow's floor.
    enum Foot: Int, Sendable { case wall, dropOff, floor }

    struct Stretch: Equatable, Sendable {
        var rock = Rock.sand
        /// The seats in each of its terraces, 1 to 9.
        var terraces: [Int]
        /// The room over it in the dive for its header's words; nothing at the overview, where they stand beside it.
        var header: CGFloat = 0
        /// What each ledge's own row needs in the dive where that is more than the pitch (settings' rows, a row that
        /// wraps), counted through the stretch; a missing or smaller entry is the pitch.
        var rows: [CGFloat] = []
        /// Its height at the overview; nil is 40 pt a terrace.
        var height: CGFloat?
    }

    var stretches: [Stretch]
    var foot = Foot.wall
    /// Whether air stands over it; a pack's column is all under water.
    var surface = true
    /// The dive's pitch: 110, or more where a row's words need it.
    var pitch: CGFloat = 110
    /// The first lip of a terrace in the dive, and how far each next one steps out.
    var lip: CGFloat = 132
    var step: CGFloat = 6
    /// The first ledge's depth at the overview.
    var lead: CGFloat = 82
    /// The ledge the water's colour counts from, plughole's first in the main column; nil is still water at
    /// `still` ledges' depth all the way down, a pack's.
    var first: Int? = 0
    var still: CGFloat = 16

    /// A ledge's shape by rock: its lip's thickness, how far the rock cuts back under it, how blunt its nose is and
    /// the ripples down its face.
    static let shapes: [(thick: CGFloat, under: CGFloat, nose: CGFloat, ripple: CGFloat)] =
        [(56, 42, 1.7, 0), (64, 46, 1.9, 3), (28, 60, 1.2, 0), (80, 40, 2.4, 0), (48, 40, 1.6, 0)]
    /// A ledge's pitch inside a terrace at the overview.
    static let fine: CGFloat = 1.3
    static let full = 9
    /// How far a ledge's top runs back from its lip in the dive, at the least: room for the largest pebble clear of the
    /// wall, which still stands wide enough of the leading edge to hold a hollow.
    static let shelf: CGFloat = 48

    /// The main column on a screen of `size`: the shallows (today, a bare ledge, the archive), the four tiers and the
    /// drop-off. `headers` is the room each tier's header takes in the dive, `pitch`, `lip` and `step` the type
    /// size's (`SlopeColumn.Measure`).
    static func main(size: CGSize, pitch: CGFloat = 110, lip: CGFloat = 132, step: CGFloat = 6, header: CGFloat? = nil) -> SlopeColumn {
        let h = size.height
        var stretches = [Stretch(terraces: [1, 1, 1], height: 0.1255 * h)]
        for rock in [Rock.sand, .mauve, .slate, .basalt] {
            stretches.append(Stretch(rock: rock, terraces: [9, 9, 9], header: max(pitch, header ?? 0), height: 0.125 * h))
        }
        return SlopeColumn(stretches: stretches, foot: .dropOff, pitch: pitch, lip: lip, step: step, lead: 0.0858 * h, first: 3)
    }

    static let today = 0
    static let archive = 2
    /// The main column's ledge for `tier`'s level `number`, from 1.
    static func ledge(tier: Int, level number: Int) -> Int { 3 + tier * 27 + number - 1 }

    var count: Int { stretches.reduce(0) { $0 + $1.terraces.reduce(0, +) } }
}

/// Where the slope is seen from: the column depth at the screen's top, and the zoom.
struct SlopeCamera: Equatable, Sendable {
    var top: CGFloat
    var z: CGFloat = 1
}

/// Where a camera holds the column: ledge `ledge`'s top at `share` of the screen's height. A ledge past the last is
/// the foot, endless's word.
struct SlopeAim: Equatable, Sendable {
    var ledge: Int
    var share: CGFloat = 0.49
}

/// A column laid out at one zoom: where each ledge is, where its pebble sits, and what the shader is given, all from
/// the same numbers.
struct SlopeLay: Sendable {
    let column: SlopeColumn
    let z: CGFloat
    /// The zoom eased: every measure runs from its overview value to its dive value by this.
    let e: CGFloat
    /// Each ledge's top, as a depth; its lip and its pebble's middle, as x; how far it is to the next ledge's top (or
    /// the foot); its rock; and the stretch, terrace and seat it is.
    let tops: [CGFloat], tips: [CGFloat], pebbles: [CGFloat], drops: [CGFloat]
    /// Where the rock over each ledge meets its top (the wall, for a terrace's first at the overview), and the water's
    /// depth in ledges at its top, which runs evenly down each terrace.
    let backs: [CGFloat], fathoms: [CGFloat]
    let rocks: [SlopeColumn.Rock]
    let places: [(stretch: Int, terrace: Int, seat: Int)]
    /// The depth each stretch's header room starts at (its first ledge's top less the room).
    let headers: [CGFloat]
    /// The depth the last ledge's drop ends at: the brink, or the floor.
    let foot: CGFloat
    /// A ledge's pitch inside a terrace at this zoom.
    let pitch: CGFloat

    init(_ column: SlopeColumn, z: CGFloat) {
        self.column = column
        self.z = z
        let z = min(max(z, 0), 1), e = z * z * (3 - 2 * z)
        self.e = e
        let within = SlopeColumn.fine * pow(column.pitch / SlopeColumn.fine, e)
        pitch = within
        var tops: [CGFloat] = [], tips: [CGFloat] = [], pebbles: [CGFloat] = [], drops: [CGFloat] = []
        var rocks: [SlopeColumn.Rock] = [], places: [(Int, Int, Int)] = [], headers: [CGFloat] = []
        var walls: [CGFloat] = [], starts: [Int] = []
        var depth = column.lead + (0.8 * column.pitch - column.lead) * e, terrace = 0
        for (s, stretch) in column.stretches.enumerated() {
            let wide = (stretch.height ?? 40 * CGFloat(stretch.terraces.count)) / CGFloat(stretch.terraces.count)
            headers.append(depth)
            depth += stretch.header * e
            var row = 0
            for (t, seats) in stretch.terraces.enumerated() {
                let wall = 40 + 8 * sin(0.9 * CGFloat(terrace) + 1)
                var used: CGFloat = 0
                starts.append(tops.count)
                for i in 0 ..< seats {
                    walls.append(wall)
                    let n = tops.count
                    // A short terrace's seats lie at its nose at the overview, so every terrace is as long.
                    let far = wall + 2 + 11.4 * CGFloat(i + SlopeColumn.full - seats)
                    let near = column.lip - 23 + column.step * CGFloat(i) + 4 * sin(2.4 * CGFloat(n) + 1)
                    let x = far + (near - far) * e
                    let own = row < stretch.rows.count ? max(stretch.rows[row], column.pitch) : column.pitch
                    let drop = SlopeColumn.fine * pow(own / SlopeColumn.fine, e)
                    tops.append(depth)
                    pebbles.append(x)
                    tips.append(x + 6 + 17 * e)
                    rocks.append(stretch.rock)
                    places.append((s, t, i))
                    // The terrace keeps its overview height under its last ledge, a gap that closes as the depth opens.
                    let gap = i == seats - 1 ? (wide - used - SlopeColumn.fine) * (1 - e) : 0
                    drops.append(drop + max(gap, 0) + (i == seats - 1 && t == stretch.terraces.count - 1 && s + 1 < column.stretches.count
                                                       ? column.stretches[s + 1].header * e : 0))
                    depth += drop + max(gap, 0)
                    used += SlopeColumn.fine
                    row += 1
                }
                terrace += 1
            }
        }
        // `drops` runs to the next ledge's top, so a stretch's last carries the next header's room; `tops` already do.
        for n in tops.indices.dropLast() { drops[n] = tops[n + 1] - tops[n] }
        let count = tops.count
        func sized(_ n: Int) -> CGFloat { min(0.75 * min(drops[n], within) / SlopeColumn.shapes[rocks[n].rawValue].thick, 1) }
        var backs: [CGFloat] = [], fathoms: [CGFloat] = []
        for n in 0 ..< count {
            let above = max(n - 1, 0)
            // The top runs back at least `shelf` from its lip, so the largest pebble rests on its outer half, clear of
            // the wall.
            let usual = min(min(tips[above], tips[n]) - 0.85 * SlopeColumn.shapes[rocks[above].rawValue].under * sized(above),
                            tips[n] - SlopeColumn.shelf * sized(n))
            // At the overview a terrace is one ledge that runs out from the wall.
            backs.append(places[n].2 == 0 ? usual + (min(usual, walls[n]) - usual) * (1 - e) : usual)
        }
        starts.append(count)
        for t in starts.indices.dropLast() {
            let a = starts[t], b = starts[t + 1], height = (b < count ? tops[b] : depth) - tops[a]
            for n in a ..< b { fathoms.append(CGFloat(a - (column.first ?? 0) + 1) + CGFloat(b - a) * (tops[n] - tops[a]) / height) }
        }
        self.backs = backs
        self.fathoms = fathoms
        self.tops = tops
        self.tips = tips
        self.pebbles = pebbles
        self.drops = drops
        self.rocks = rocks
        self.places = places
        self.headers = headers
        foot = depth
    }

    var count: Int { tops.count }

    /// The ledge that is `seat` of `terrace` of `stretch`.
    func ledge(stretch: Int, terrace: Int = 0, seat: Int = 0) -> Int {
        places.firstIndex { $0 == (stretch, terrace, seat) } ?? 0
    }

    /// How much of its dive's size ledge `n`'s shape has: Slope.metal's `slopeScale`.
    func scale(_ n: Int) -> CGFloat {
        let n = min(max(n, 0), count - 1)
        return min(0.75 * min(drops[n], pitch) / SlopeColumn.shapes[rocks[n].rawValue].thick, 1)
    }


    /// Ledge `n`'s lip: its nose, just under its top.
    func lip(_ n: Int) -> CGPoint { CGPoint(x: tips[n], y: tops[n] + 10 * scale(n)) }

    /// How far under its top line ledge `n`'s top lies at `x`: Slope.metal's `crown`, which rounds the top down to
    /// the nose in the dive and, at the overview, undoes the `lift`.
    func crown(_ n: Int, at x: CGFloat) -> CGFloat {
        10 * scale(n) * (1 - cbrt(min(max((tips[n] - x) / max(tips[n] - backs[n], 1), 0), 1)))
            + max(SlopeLay.lift(x) - SlopeLay.lift(backs[n]), 0) * (1 - e)
    }

    /// Where a pebble rests on ledge `n`: the point of the ledge's top under the pebble's middle.
    func seat(_ n: Int) -> CGPoint { CGPoint(x: pebbles[n], y: raised(tops[n] + crown(n, at: pebbles[n]), at: pebbles[n])) }

    /// At the overview no ledge's top is straight: the whole shelf bows a few points, the same way in Slope.metal
    /// (its `bow`). The depth at which `x` shows the rock of depth `plain`.
    func raised(_ plain: CGFloat, at x: CGFloat) -> CGFloat {
        var depth = plain
        for _ in 0 ..< 4 { depth = plain + SlopeLay.bow(x, depth) * (1 - e) }
        return depth
    }

    static func bow(_ x: CGFloat, _ depth: CGFloat) -> CGFloat { 3.4 * sin(x * 0.021 + depth * 0.033) - lift(x) }

    /// How far the overview lifts the rock at `x`, about what nine ledges step down along a terrace. Each ledge
    /// leans down from its back by as much (`crown`), so on the screen every top lies level and a terrace of nine
    /// reads as one long ledge. Slope.metal's `slopeLift`.
    static func lift(_ x: CGFloat) -> CGFloat { 22 * x / sqrt(x * x + 40000) }

    /// The middle of the water's room beside ledges `a` and the next, where a hollow opens in the wall.
    func between(_ a: Int) -> CGFloat { tops[a] + drops[a] / 2 }

    /// A pebble's half-width at this zoom, by how it is lit (1.2); its half-height is 0.72 of it.
    enum Size { case lit, dull, next }
    func half(_ size: Size) -> CGFloat {
        switch size {
        case .lit: 3.9 + 4.5 * e
        case .dull: 3.3 + 3.5 * e
        case .next: 4.6 + 7.9 * e
        }
    }

    /// The camera that shows the whole column from its surface at 0.188 of a screen `height` tall.
    static func overview(height: CGFloat) -> SlopeCamera { SlopeCamera(top: -0.188 * height, z: 0) }

    /// The camera that holds ledge `n`'s top `at` that share of a screen `height` tall.
    func camera(on n: Int, at share: CGFloat = 0.49, height: CGFloat) -> SlopeCamera {
        SlopeCamera(top: tops[min(max(n, 0), count - 1)] - share * height, z: z)
    }

    /// Ledge `n`'s top, as a depth; past the last ledge, the foot's word.
    func depth(_ n: Int) -> CGFloat { n < count ? tops[max(n, 0)] : endless }

    /// The camera's depth that holds `aim` on a screen `height` tall, kept inside the travel: where a dive rests on it.
    func rest(_ aim: SlopeAim, height: CGFloat) -> CGFloat {
        let travel = travel(height: height)
        return min(max(depth(aim.ledge) - aim.share * height, travel.lowerBound), travel.upperBound)
    }

    /// The dive's travel on a screen `height` tall: from the surface at 0.188 of it, to the foot's word at its middle.
    func travel(height: CGFloat) -> ClosedRange<CGFloat> {
        let from = column.surface ? -0.188 * height : tops[0] - 0.3 * height
        return from ... max(from, endless - 0.5 * height)
    }

    /// The depth of the open water under the brink where endless's word stands.
    var endless: CGFloat { foot + 1.6 * column.pitch * e + 46 * (1 - e) }

    /// The dry bank's stone, settings': a screen point for a camera, as the bank is drawn by the screen.
    static func bank(_ camera: SlopeCamera) -> CGPoint { CGPoint(x: 40, y: -camera.top - bank(40) - 5) }

    /// The dry bank's height over the water at screen x: Slope.metal's bank.
    static func bank(_ x: CGFloat) -> CGFloat { 26 * exp(-pow(x / 80, 2)) - 6 }

    /// The top of the lone terrace that rises under the tank while a level plays, at screen x on a screen `height`
    /// tall: Slope.metal's terrace, for the stones that rest on it.
    static func terrace(_ x: CGFloat, height: CGFloat) -> CGFloat {
        height - 54 + 8 * sin(x * 0.0085 + 1.2) - 3 * sin(x * 0.021 + 0.4)
    }

    /// What Slope.metal reads: the camera and the column's measures, each rock's shape, then every ledge's top, lip,
    /// drop, rock, back and fathoms.
    func uniforms(top: CGFloat) -> [Float] {
        var u: [CGFloat] = [top, e, pitch, CGFloat(count), foot, CGFloat(column.foot.rawValue), column.surface ? 1 : 0,
                            CGFloat(column.first ?? -1), column.still, column.pitch, 0, 0, 0, 0, 0, 0]
        for s in SlopeColumn.shapes { u += [s.thick, s.under, s.nose, s.ripple] }
        for n in 0 ..< count { u += [tops[n], tips[n], drops[n], CGFloat(rocks[n].rawValue), backs[n], fathoms[n]] }
        return u.map(Float.init)
    }
}
