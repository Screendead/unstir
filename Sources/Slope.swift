// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreGraphics
import Foundation

/// The slope: the world every screen outside the tank is laid out on, a column of water seen from the side beside a
/// shelf of rock that falls away in overhung ledges. This is its geometry alone, the one source for Slope.metal (which
/// draws the rock from `Frame.uniforms`) and for the views that set pebbles and words on it.
///
/// World units are points at the dive's zoom of 1. y is depth, 0 at the water's surface; x is 0 on the line the
/// ledges' lips wander about, the rock to its left. Ledges are a lattice `pitch` apart, counted from the first under
/// the surface: the shallows' (settings' stones, the daily's pebble and the archive's), then for each tier two bare
/// ones its name sits beside and its 27 levels'. Under maelstrom's last the shelf breaks into open water.
struct Slope: Equatable, Sendable {
    /// World units between two ledges' tops: a level's number, name and facts must fit in it, so it grows with the type.
    var pitch: CGFloat
    /// How far from the screen's leading edge the lips' line sits in the dive: it draws in as the type grows, to leave
    /// the words their room.
    var lip: CGFloat
    /// The share of its overhang each ledge keeps, less at the largest type, where the rock is narrow.
    var overhang: CGFloat
    /// How far the lips wander from their line: a slow swing, and a quick one from ledge to ledge.
    var swing: CGFloat, jitter: CGFloat

    /// `type` is the body role's size over its default, 1 at the default Dynamic Type size.
    init(type: CGFloat = 1) {
        let s = min(max((type - 1) / 1.35, 0), 1.6), narrow = min(s, 1)
        pitch = 110 + 86 * s
        lip = max(170 - 108 * s, 48)
        overhang = 1 - 0.3 * narrow
        swing = 14 - 9 * narrow
        jitter = 8 - 5 * narrow
    }

    /// A terrace: two bare ledges, then nine that hold a pebble each. In the dive they are ledges like any others; in
    /// the overview they stand out as one overhung step (`stair`).
    static let terrace = 11
    /// The shallows are two terraces. Settings' stones rest on the first ledges under the surface, the daily's pebble
    /// on the first terrace's nose and the archive's on the second's.
    static let shallows = 2 * terrace
    static let daily = terrace - 1
    static let archive = shallows - 1
    static let tiers = 4
    static let levels = 27
    /// A tier's ledges: three terraces, nine levels to each.
    static let stretch = 3 * terrace
    static let count = shallows + tiers * stretch

    /// A ledge's shape by tier (sand, mauve scallops, slate plates, basalt pillows): its lip's thickness, how far the
    /// rock cuts back under it, how blunt its nose is and the ripples down its face.
    static let shapes: [(thick: CGFloat, under: CGFloat, nose: CGFloat, ripple: CGFloat)] =
        [(56, 42, 1.7, 0), (64, 46, 1.9, 3), (28, 60, 1.2, 0), (80, 40, 2.4, 0)]

    /// The tier (0 to 3) whose rock ledge `k` is cut from.
    static func tier(of k: Int) -> Int { min(max((k - shallows) / stretch, 0), tiers - 1) }
    /// The ledge of `tier`'s level `number`, from 1.
    static func ledge(tier: Int, level number: Int) -> Int {
        shallows + tier * stretch + (number - 1) / 9 * terrace + 2 + (number - 1) % 9
    }
    /// The first of the two bare ledges `tier`'s name sits beside.
    static func heading(tier: Int) -> Int { shallows + tier * stretch }
    /// Whether ledge `k` is one of a terrace's two bare ones.
    static func bare(_ k: Int) -> Bool { k % terrace < 2 }
    /// The last ledge, the brink: under it the rock falls back and the water is open.
    static let brink = count - 1

    /// The depth of ledge `k`'s top.
    func y(_ k: Int) -> CGFloat { (0.8 + CGFloat(k)) * pitch }
    /// The depth a tier's name is written at, in the water beside its two bare ledges.
    func heading(tier: Int) -> CGFloat { y(Self.heading(tier: tier)) + 0.75 * pitch }
    /// The depth of the open water under the brink where endless waits.
    var endless: CGFloat { y(Self.brink) + 4.6 * pitch }
    /// The deepest the world is drawn for.
    var floor: CGFloat { y(Self.brink) + 8 * pitch }

    /// Where a pack's hollow opens in the rock between level `number` and the next of `tier`, and how wide; nil at the
    /// type sizes that leave the rock too narrow to hold one.
    func hollow(tier: Int, after number: Int) -> (centre: CGPoint, diameter: CGFloat)? {
        let d = min(58, lip - 104)
        guard d >= 44 else { return nil }
        let k = Self.ledge(tier: tier, level: number)
        return (CGPoint(x: -lip + 27 + d / 2 + 5 * sin(CGFloat(k)), y: y(k) + 0.5 * pitch), d)
    }

    /// How far ledge `k`'s lip sits from the lips' line in the dive.
    func wander(_ k: Int) -> CGFloat {
        let k = CGFloat(k)
        return swing * sin(k * 0.85 + 0.6) + 0.5 * swing * sin(k * 0.31 + 2.0) + jitter * sin(k * 2.4 + 1.0)
    }

    /// How far out ledge `k`'s lip stands from the wall in the overview, in the overview's own points. There each
    /// terrace reads as one long step: its nine lips step out as they descend to its nose, and the two bare ledges
    /// after it carry the rock back under. Each tier's terraces are its own: sand's long, mauve's round, slate's
    /// straight, basalt's full.
    static func stair(_ k: Int) -> CGFloat {
        let tier = tier(of: k), place = k % terrace
        let reach: CGFloat = [100, 106, 94, 102][tier] * (1 + 0.09 * sin(CGFloat(k / terrace) * 2.3 + 0.7))
        if place < 2 { return reach * [0.56, 0.3][place] }
        return reach * (0.3 + 0.7 * pow((CGFloat(place - 2) + 0.6) / 8.6, [0.8, 0.64, 1, 0.5][tier]))
    }

    /// The camera that shows the whole slope on a screen of `size`: the surface under the wordmark, the brink above the
    /// room endless takes.
    func overview(in size: CGSize) -> SlopeCamera {
        let zoom = 0.692 * size.height / y(Self.brink)
        return SlopeCamera(y: (0.5 - 0.188) * size.height / zoom, zoom: zoom)
    }

    /// The dive's camera with ledge `k` at the screen's middle.
    func dive(to k: Int) -> SlopeCamera { SlopeCamera(y: y(k), zoom: 1) }
    /// The dive's camera at the top of its travel on a screen of `size`, the surface under the wordmark's room, and at
    /// the bottom.
    func top(in size: CGSize) -> SlopeCamera { SlopeCamera(y: size.height * (0.5 - 0.188), zoom: 1) }
    func bottom(in size: CGSize) -> SlopeCamera { SlopeCamera(y: floor - size.height / 2, zoom: 1) }
}

/// Where the slope is seen from: the depth at the screen's middle, and points to a world unit. Everything else about
/// the view follows from these two (`Slope.Frame`).
struct SlopeCamera: Equatable, Sendable {
    var y: CGFloat
    var zoom: CGFloat = 1
}

extension Slope {
    /// The slope as one camera shows it on one screen: where each lip is, where a pebble sits, and what the shader is
    /// given, all from the same numbers.
    struct Frame: Sendable {
        let slope: Slope
        let camera: SlopeCamera
        let size: CGSize
        /// 1 in the overview, where the flights stand out as stairs, falling to 0 in the dive, where every lip is on
        /// its line.
        let stairs: CGFloat
        /// The world point at the screen's top leading corner.
        let origin: CGPoint
        /// Each ledge's lip, in world x.
        let tips: [CGFloat]

        init(_ slope: Slope, camera: SlopeCamera, size: CGSize) {
            self.slope = slope
            self.camera = camera
            self.size = size
            let wide = slope.overview(in: size).zoom
            // Unwound by the zoom's logarithm, so a zoom at a steady rate straightens the flights at a steady rate.
            let t = min(max(log(camera.zoom / (wide * 1.15)) / log(0.62 / (wide * 1.15)), 0), 1)
            let unwound = t * t * (3 - 2 * t)
            stairs = 1 - unwound
            let wall = 44 + (slope.lip - 44) * unwound
            origin = CGPoint(x: -wall / camera.zoom, y: camera.y - size.height / 2 / camera.zoom)
            tips = (0 ..< Slope.count).map { slope.wander($0) + Slope.stair($0) / wide * (1 - unwound) }
        }

        /// A world point on the screen.
        func point(_ world: CGPoint) -> CGPoint {
            CGPoint(x: (world.x - origin.x) * camera.zoom, y: (world.y - origin.y) * camera.zoom)
        }

        /// The depth at a screen y.
        func depth(at y: CGFloat) -> CGFloat { origin.y + y / camera.zoom }

        private func tip(_ k: Int) -> CGFloat { tips[min(max(k, 0), Slope.count - 1)] }
        private func under(_ k: Int) -> CGFloat {
            Slope.shapes[Slope.tier(of: min(max(k, 0), Slope.count - 1))].under * slope.overhang
        }

        /// Where the rock under ledge `k - 1` meets ledge `k`'s top: Slope.metal's `back`.
        private func back(_ k: Int) -> CGFloat { min(tip(k - 1), tip(k)) - 0.85 * under(k - 1) }

        /// Ledge `k`'s lip in the world: its nose, just under its top.
        func lip(_ k: Int) -> CGPoint { CGPoint(x: tip(k), y: slope.y(k) + Slope.nose) }

        /// How far under its lattice line ledge `k`'s top lies at world `x`: Slope.metal's `crown`, which rounds the
        /// top down to the nose.
        func crown(_ k: Int, at x: CGFloat) -> CGFloat {
            let share = min(max((tip(k) - x) / max(tip(k) - back(k), 1), 0), 1)
            return Slope.nose * (1 - cbrt(share))
        }

        /// Where a pebble rests on ledge `k`, in the world: the point of the ledge's top under the pebble's middle. It
        /// sits back from the nose by a share of its own width, never further than the top is long.
        func seat(_ k: Int) -> CGPoint {
            let inset = min(max(min(max(17 + 6 * (slope.lip - 62) / 108, 17), 23), 4 / camera.zoom), 0.45 * (tip(k) - back(k)))
            let x = tip(k) - inset
            return CGPoint(x: x, y: slope.y(k) + crown(k, at: x))
        }

        /// What a length of the dive's measures on this screen, never under `least` points: a pebble shrinks with the
        /// zoom until it would be lost, and holds there.
        func length(_ world: CGFloat, least: CGFloat) -> CGFloat { max(world * camera.zoom, least) }

        /// The stone on the dry bank above the water, settings': a screen point, as the bank is drawn by the screen.
        var bank: CGPoint {
            let surface = -origin.y * camera.zoom
            return CGPoint(x: 40, y: surface - Slope.bank(40) - 5)
        }

        /// What Slope.metal's `slope` reads: the view, each tier's shape, then every lip.
        var uniforms: [Float] {
            var u: [CGFloat] = [origin.x, origin.y, camera.zoom, slope.pitch, slope.y(0), slope.lip, CGFloat(Slope.count), stairs,
                                CGFloat(Slope.shallows), CGFloat(Slope.stretch), 0, 0, 0, 0, 0, 0]
            for s in Slope.shapes { u += [s.thick, s.under * slope.overhang, s.nose, s.ripple] }
            return (u + tips).map(Float.init)
        }
    }

    /// How far under a ledge's lattice line its nose is: the top rounds down to it.
    static let nose: CGFloat = 10

    /// The dry bank's height over the water at screen x: Slope.metal's `bank`.
    static func bank(_ x: CGFloat) -> CGFloat { 26 * exp(-pow(x / 80, 2)) - 6 }

    /// The top of the terrace that rises under the tank while a level plays, at screen x on a screen `height` tall:
    /// Slope.metal's `terrace`, for the stones that rest on it.
    static func terrace(_ x: CGFloat, height: CGFloat) -> CGFloat {
        height - 54 + 8 * sin(x * 0.0085 + 1.2) - 3 * sin(x * 0.021 + 0.4)
    }
}
