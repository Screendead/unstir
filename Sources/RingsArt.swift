// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreText
import UIKit

// The rings' art, all of it (docs/rings.md): every picture the menu shows is a `RingsPiece`, named here, drawn here
// once off the main thread (`RingsPaint`) and kept (`RingsArt`). The engine (RingsView.swift) only places, scales and
// fades what this file hands it, so a new look is new drawing code in this file and nothing else.
// The look is the sun in the ring (Jack, 2026-11-27): a banded sun setting inside the beads, wireframe mountains
// either side, a grid floor running to the horizon under a sky of stars. The grid's straight lines, the sun's bands,
// the horizon and the mountains are his references, which override the redesign's "no hard straight lines" here.

/// A colour of the look by its role, so no caller holds an RGB.
enum RingsInk: Hashable, Sendable {
    /// The words' white, at a strength.
    case ink(Double)
    case tier(Tier)
    /// On a filled bead.
    case dark
    case gold
    /// On the sun: its words, and the quieter line under them.
    case deep, dusk
}

/// Words as one bitmap: a line of runs, or one run wrapped, or set along a circle.
struct RingsText: Hashable, Sendable {
    /// The tier's word (a serif italic), a name, a figure (monospaced).
    enum Voice: Hashable, Sendable { case word, name, data }
    enum Weight: Hashable, Sendable { case light, regular, medium, semibold }

    struct Run: Hashable, Sendable {
        var string: String
        var voice = Voice.data
        var size: CGFloat = 13
        var ink = RingsInk.ink(1)
        var weight = Weight.regular
    }

    struct Arc: Hashable, Sendable {
        var radius: CGFloat
        /// Where the words' middle sits on the circle, in radians from the x axis, y down; `lead` moves the words
        /// along the circle from there by their own half width and this much more, towards the words' start (-1) or
        /// end (1), so two lines can stand either side of a mark.
        var angle: CGFloat
        var lead: CGFloat = 0
        var side: CGFloat = 0
        /// The letters stand on the circle, as over its top; false hangs them inside it, as under its foot.
        var inward = true
    }

    /// What stands behind the words, which decides what keeps them readable.
    enum Finish: Hashable, Sendable {
        case plain
        /// Over the scene: a dark shadow under them.
        case shadowed
        /// A tube not lit: a faint fill and the tier's outline.
        case unlit(Tier)
    }

    var runs: [Run]
    var tracking: CGFloat = 0
    /// Between two runs.
    var gap: CGFloat = 0
    var finish = Finish.plain
    var arc: Arc?
    /// The widest a line may run before the words wrap, centred.
    var wrap: CGFloat?

    init(_ string: String, _ voice: Voice = .data, _ size: CGFloat = 13, _ ink: RingsInk = .ink(1), _ weight: Weight = .regular,
         tracking: CGFloat = 0, finish: Finish = .plain, arc: Arc? = nil, wrap: CGFloat? = nil) {
        runs = [Run(string: string, voice: voice, size: size, ink: ink, weight: weight)]
        self.tracking = tracking
        self.finish = finish
        self.arc = arc
        self.wrap = wrap
    }

    init(runs: [Run], gap: CGFloat) {
        self.runs = runs
        self.gap = gap
    }
}

/// One layer of the ground: a bitmap placed once, which a swipe may slide. The look lists as many as it likes, back
/// to front (`RingsLook.ground`), and says which stand in front of the suns.
struct RingsGround: Hashable, Sendable {
    let name: String
    /// Where it is shown, in the menu's points; a floor's is the window it is seen through.
    let x, y, width, height: CGFloat
    /// The bitmap's own size in points and the scale it is baked at: a soft layer is baked small and stretched.
    let bakedWidth, bakedHeight, scale: CGFloat
    /// Drawn over the suns.
    var front = false
    /// How far it slides for each ring swiped past: a flat layer on the screen, a floor along itself towards the viewer.
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    /// A slide that repeats: the art is the same every `wrap` points, so the layer never travels further than that.
    var wrap: CGFloat = 0
    /// A floor: it lies flat, running away from the foot of its window, seen from this far in front of the screen at
    /// the height of the window's top, which is its horizon. Its bitmap is stretched to `spread` wide. 0 for a layer
    /// flat on the screen.
    var eye: CGFloat = 0
    var spread: CGFloat = 0
    /// A floor's art starts this far in from its foot, and so stands that far off the screen's foot at rest less
    /// half a `wrap`.
    var lead: CGFloat = 0
}

/// One picture of the menu, named by everything that decides its pixels, so a bake is kept for as long as it is true.
enum RingsPiece: Hashable, Sendable {
    case ground(RingsGround)
    /// A ring's sun, the stage its words stand on: up on an open tier, down on a shut one.
    case sun(Tier, shut: Bool)
    case bead(Tier, RingsModel.Bead)
    /// The thread from one bead to the next.
    case link(Tier)
    /// Round a picked bead.
    case halo
    /// The daily's evening star.
    case daily
    case cover(Pack)
    case settings
    case wordmark
    /// The middle's play mark.
    case play
    case text(RingsText)
}

struct RingsBitmap: @unchecked Sendable {
    let image: CGImage
    /// In points.
    let size: CGSize
    /// From the point the piece is placed by (words on a circle: its centre) to the bitmap's middle.
    var offset = CGPoint.zero
    var bytes: Int { image.bytesPerRow * image.height }
}

/// The baked art: drawn once off the main thread, kept by piece across every menu the root builds.
final class RingsArt: @unchecked Sendable {
    static let shared = RingsArt()
    private let lock = NSLock()
    private var made: [RingsPiece: RingsBitmap] = [:]

    func have(_ pieces: some Sequence<RingsPiece>) -> [RingsPiece: RingsBitmap] {
        lock.withLock {
            var out: [RingsPiece: RingsBitmap] = [:]
            for piece in pieces { out[piece] = made[piece] }
            return out
        }
    }

    /// Draws what is missing of `pieces`, each on a thread of the pool, and returns all of them.
    func bake(_ pieces: some Sequence<RingsPiece>, scale: CGFloat) async -> [RingsPiece: RingsBitmap] {
        let wanted = Set(pieces), missing = lock.withLock { wanted.filter { made[$0] == nil } }
        let drawn = await withTaskGroup(of: (RingsPiece, RingsBitmap?).self) { group in
            for piece in missing { group.addTask(priority: .userInitiated) { (piece, RingsPaint.draw(piece, scale: scale)) } }
            var out: [RingsPiece: RingsBitmap] = [:]
            for await (piece, bitmap) in group { out[piece] = bitmap }
            return out
        }
        lock.withLock { made.merge(drawn) { old, _ in old } }
        return have(wanted)
    }

    /// Forgets every bitmap no menu asks for now.
    func keep(_ pieces: Set<RingsPiece>) {
        lock.withLock { made = made.filter { pieces.contains($0.key) } }
    }

    var bytes: Int { lock.withLock { made.values.reduce(0) { $0 + $1.bytes } } }
    var count: Int { lock.withLock { made.count } }
}

/// The look's constants: what the engine must know of it without drawing anything.
enum RingsLook {
    typealias RGB = (r: CGFloat, g: CGFloat, b: CGFloat)

    static func hex(_ v: Int) -> RGB { (CGFloat(v >> 16 & 0xFF) / 255, CGFloat(v >> 8 & 0xFF) / 255, CGFloat(v & 0xFF) / 255) }

    /// Shown until the first bake lands: the sky's top.
    static let backdrop = UIColor(red: 7 / 255, green: 2 / 255, blue: 34 / 255, alpha: 1)

    static let cyan: RGB = (40 / 255, 236 / 255, 1), pink: RGB = (1, 52 / 255, 200 / 255)

    static func rgb(_ tier: Tier) -> RGB {
        switch tier {
        case .plughole: (40 / 255, 240 / 255, 220 / 255)
        case .whirlpool: (198 / 255, 96 / 255, 1)
        case .vortex: (64 / 255, 132 / 255, 1)
        case .maelstrom: (1, 56 / 255, 96 / 255)
        }
    }

    /// The sun's width, and how far under the ring's middle the horizon cuts it, both at the mock's scale.
    static let sun: CGFloat = 300, set: CGFloat = 100
    /// A shut ring's beads stand back.
    static func dim(shut: Bool) -> CGFloat { shut ? 0.72 : 1 }

    /// The floor's cross lines lie this far apart along it, and its eye stands this far from the screen: the nearest
    /// line is drawn three quarters of the way down the floor, as the mock has it.
    static let row: CGFloat = 200, eye: CGFloat = 300
    /// From the strip's foot to its first line: room for the line's glow.
    static let rowLead: CGFloat = 8
    /// Cross lines passed for each ring swiped.
    static let run: CGFloat = 2

    /// The ground's layers for a screen, back to front. `horizon` is the height the floor meets the sky at.
    static func ground(width: CGFloat, height: CGFloat, horizon: CGFloat) -> [RingsGround] {
        let floor = height - horizon, ridge = 160 * width / 440, length: CGFloat = 5200
        return [
            RingsGround(name: "sky", x: 0, y: 0, width: width, height: horizon, bakedWidth: 4, bakedHeight: horizon, scale: 1),
            RingsGround(name: "stars", x: 0, y: 0, width: width, height: horizon, bakedWidth: width, bakedHeight: horizon, scale: 1.5,
                        dy: -10),
            RingsGround(name: "ridge", x: 0, y: horizon - ridge, width: width, height: ridge, bakedWidth: width, bakedHeight: ridge,
                        scale: 2, front: true),
            RingsGround(name: "floor", x: 0, y: horizon, width: width, height: floor, bakedWidth: width, bakedHeight: floor,
                        scale: 2, front: true),
            // The lines across the floor are the only part of the grid a run moves: the lines along it lie where
            // they are, so they are the floor's own.
            RingsGround(name: "rows", x: 0, y: horizon, width: width, height: floor, bakedWidth: 2, bakedHeight: length, scale: 3,
                        front: true, dy: row * run, wrap: row, eye: eye, spread: width * (1 + length / eye), lead: rowLead),
            RingsGround(name: "haze", x: 0, y: horizon - 8, width: width, height: 54, bakedWidth: 4, bakedHeight: 54, scale: 3,
                        front: true),
        ]
    }
}

enum RingsPaint {
    typealias RGB = RingsLook.RGB
    static let space = CGColorSpace(name: CGColorSpace.sRGB)!

    static func draw(_ piece: RingsPiece, scale: CGFloat) -> RingsBitmap? {
        switch piece {
        case let .ground(ground): Self.ground(ground)
        case let .sun(tier, shut): sun(tier, shut: shut)
        case let .bead(tier, state): bead(tier, state, scale: scale)
        case let .link(tier): link(tier, scale: scale)
        case .halo: halo(scale: scale)
        case .daily: daily(scale: scale)
        case let .cover(pack): cover(pack, scale: scale)
        case .settings: settings(scale: scale)
        case .wordmark: wordmark(scale: scale)
        case .play: play(scale: scale)
        case let .text(text): words(text, scale: scale)
        }
    }

    // MARK: Tools

    static func colour(_ c: RGB, _ a: CGFloat = 1) -> CGColor {
        CGColor(colorSpace: space, components: [c.r, c.g, c.b, a])!
    }

    static func colour(_ hex: Int, _ a: CGFloat = 1) -> CGColor { colour(RingsLook.hex(hex), a) }

    static func colour(_ ink: RingsInk) -> CGColor {
        switch ink {
        case let .ink(a): colour((243 / 255, 240 / 255, 236 / 255), a)
        case let .tier(tier): colour(RingsLook.rgb(tier))
        case .dark: colour((14 / 255, 6 / 255, 30 / 255), 0.92)
        case .gold: colour((1, 232 / 255, 72 / 255))
        case .deep: colour(0x1B0440)
        case .dusk: colour((40 / 255, 6 / 255, 80 / 255), 0.86)
        }
    }

    static let night = colour((6 / 255, 0, 24 / 255))

    static func gradient(_ stops: [(CGFloat, CGColor)]) -> CGGradient {
        CGGradient(colorsSpace: space, colors: stops.map(\.1) as CFArray, locations: stops.map(\.0))!
    }

    /// A bitmap `w` by `h` points at `scale`, drawn in points from its top left, y down.
    static func raster(_ w: CGFloat, _ h: CGFloat, scale: CGFloat, offset: CGPoint = .zero, _ draw: (CGContext) -> Void) -> RingsBitmap? {
        let pw = Int((w * scale).rounded(.up)), ph = Int((h * scale).rounded(.up))
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard pw > 0, ph > 0, let ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8, bytesPerRow: 0,
                                                  space: space, bitmapInfo: info) else { return nil }
        ctx.translateBy(x: 0, y: CGFloat(ph))
        ctx.scaleBy(x: scale, y: -scale)
        draw(ctx)
        return ctx.makeImage().map { RingsBitmap(image: $0, size: CGSize(width: w, height: h), offset: offset) }
    }

    static func disc(_ c: CGPoint, _ r: CGFloat) -> CGRect {
        CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
    }

    static func ring(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ colour: CGColor, width: CGFloat) {
        ctx.setStrokeColor(colour)
        ctx.setLineWidth(width)
        ctx.strokeEllipse(in: disc(c, r))
    }

    /// A neon ring: the stroke and its glow.
    static func tube(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ rgb: RGB, width: CGFloat, glow: CGFloat, scale: CGFloat) {
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: glow * scale, color: colour(rgb, 0.95))
        ring(ctx, c, r, colour(rgb), width: width)
        ctx.restoreGState()
    }

    // MARK: The ground

    static func ground(_ g: RingsGround) -> RingsBitmap? {
        raster(g.bakedWidth, g.bakedHeight, scale: g.scale) { ctx in
            let w = g.bakedWidth, h = g.bakedHeight
            switch g.name {
            case "sky":
                ctx.drawLinearGradient(gradient([(0, colour(0x070222)), (0.42, colour(0x1C0648)), (0.72, colour(0x4A0F72)),
                                                 (0.9, colour(0xA3267F)), (1, colour(0xFF7A4A))]),
                                       start: .zero, end: CGPoint(x: 0, y: h), options: [])
            case "stars": stars(ctx, w, h)
            case "ridge": ridge(ctx, w, h, scale: g.scale)
            case "floor": floor(ctx, w, h, scale: g.scale)
            case "rows": rows(ctx, w, h)
            default:
                // The horizon: its haze and its line of light.
                ctx.drawLinearGradient(gradient([(0, colour((1, 110 / 255, 150 / 255), 0.85)), (1, colour((1, 80 / 255, 170 / 255), 0))]),
                                       start: CGPoint(x: 0, y: 8), end: CGPoint(x: 0, y: h), options: [])
                ctx.drawLinearGradient(gradient([(0, colour((1, 1, 1), 0)), (1, colour((1, 1, 1), 0.5))]),
                                       start: CGPoint(x: 0, y: 3), end: CGPoint(x: 0, y: 8), options: [])
                ctx.setFillColor(colour((1, 236 / 255, 240 / 255), 0.95))
                ctx.fill(CGRect(x: 0, y: 8, width: w, height: 1.4))
                ctx.drawLinearGradient(gradient([(0, colour((1, 1, 1), 0.5)), (1, colour((1, 1, 1), 0))]),
                                       start: CGPoint(x: 0, y: 9.4), end: CGPoint(x: 0, y: 14), options: [])
            }
        }
    }

    /// The same stars every launch.
    private static func stars(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
        var seed: UInt64 = 7
        func next() -> CGFloat {
            seed = seed * 16807 % 2_147_483_647
            return CGFloat(seed) / 2_147_483_647
        }
        for _ in 0 ..< 110 {
            let x = next() * w, y = next() * next() * h * 0.8, r = 0.4 + next() * 0.8
            ctx.setFillColor(colour((1, 1, 1), 0.35 + 0.6 * next()))
            ctx.fillEllipse(in: disc(CGPoint(x: x, y: y), r))
        }
    }

    /// Wireframe mountains, low towards the middle so the sun sets between them.
    private static func ridge(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat, scale: CGFloat) {
        let k = w / 440
        let peaks: [(CGFloat, CGFloat)] = [(0, 50), (24, 76), (48, 40), (76, 64), (102, 28), (126, 42), (148, 14), (170, 22), (198, 0)]
        for side in [CGFloat(1), -1] {
            ctx.saveGState()
            if side < 0 {
                ctx.translateBy(x: w, y: 0)
                ctx.scaleBy(x: -1, y: 1)
            }
            ctx.scaleBy(x: k, y: k)
            let base: CGFloat = 160
            ctx.move(to: CGPoint(x: 0, y: base))
            for (x, up) in peaks { ctx.addLine(to: CGPoint(x: x, y: base - up)) }
            ctx.closePath()
            ctx.setFillColor(colour(0x10033A))
            ctx.fillPath()
            ctx.setShadow(offset: .zero, blur: 4 * scale * k, color: colour(RingsLook.cyan, 0.9))
            ctx.setStrokeColor(colour(RingsLook.cyan, 0.95))
            ctx.setLineWidth(1.1)
            ctx.setLineJoin(.round)
            ctx.addLines(between: peaks.map { CGPoint(x: $0.0, y: base - $0.1) })
            ctx.strokePath()
            ctx.setStrokeColor(colour(RingsLook.cyan, 0.52))
            ctx.setLineWidth(0.8)
            for i in [1, 3, 5, 7] {
                for dx in [CGFloat(-17), -4, 11] {
                    ctx.move(to: CGPoint(x: peaks[i].0, y: base - peaks[i].1))
                    ctx.addLine(to: CGPoint(x: peaks[i].0 + dx * (1 + peaks[i].1 / 60), y: base))
                    ctx.strokePath()
                }
            }
            ctx.restoreGState()
        }
    }

    /// The floor, and the grid's lines that run along it to the vanishing point.
    private static func floor(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat, scale: CGFloat) {
        ctx.drawLinearGradient(gradient([(0, colour(0x220648)), (0.25, colour(0x12033A)), (1, colour(0x06011C))]),
                               start: .zero, end: CGPoint(x: 0, y: h), options: [])
        ctx.setShadow(offset: .zero, blur: 3 * scale, color: colour(RingsLook.pink, 0.9))
        ctx.setStrokeColor(colour(RingsLook.pink, 0.7))
        ctx.setLineWidth(1)
        let apart = 62 * w / 440
        for i in -30 ... 30 {
            ctx.move(to: CGPoint(x: w / 2 + CGFloat(i) * 1.6, y: 0))
            ctx.addLine(to: CGPoint(x: w / 2 + CGFloat(i) * apart, y: h))
        }
        ctx.strokePath()
    }

    /// The lines across the floor, as a strip of the flat floor seen from above: the engine lays it down and
    /// stretches it across. Its foot is the near end. A line and its glow, every `RingsLook.row` points.
    private static func rows(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
        let core: CGFloat = 2.6, glow: CGFloat = 7
        var y = h - RingsLook.rowLead
        while y > 0 {
            ctx.drawLinearGradient(gradient([(0, colour(RingsLook.pink, 0)), (0.5, colour(RingsLook.pink, 0.5)), (1, colour(RingsLook.pink, 0))]),
                                   start: CGPoint(x: 0, y: y - glow), end: CGPoint(x: 0, y: y + glow), options: [])
            ctx.setFillColor(colour((1, 96 / 255, 214 / 255), 0.9))
            ctx.fill(CGRect(x: 0, y: y - core / 2, width: w, height: core))
            y -= RingsLook.row
        }
    }

    // MARK: The suns

    /// The sun's bitmap is this wide, for its glow.
    static let sunSide: CGFloat = 400

    static func sun(_ tier: Tier, shut: Bool) -> RingsBitmap? {
        // Cut off at the horizon it sets on, so no pixel is kept for what is never seen.
        let side = sunSide, d = RingsLook.sun, r = d / 2, set = RingsLook.set, scale: CGFloat = 2, tall = side / 2 + set
        return raster(side, tall, scale: scale, offset: CGPoint(x: 0, y: (tall - side) / 2)) { ctx in
            let mid = CGPoint(x: side / 2, y: side / 2)
            let stops: [Int] = shut ? [0x2A1060, 0x3C1272, 0x5A1A7A] : tier == .plughole ? [0xF6FFA0, 0x7AF0C0, 0x22C4E0] : [0xFFF27A, 0xFFB347, 0xFF3D9A]
            ctx.saveGState()
            if !shut { ctx.setShadow(offset: .zero, blur: 26 * scale, color: colour((1, 90 / 255, 150 / 255), 0.9)) }
            ctx.setFillColor(colour(stops[1]))
            ctx.fillEllipse(in: disc(mid, r))
            ctx.restoreGState()
            ctx.saveGState()
            ctx.addEllipse(in: disc(mid, r))
            ctx.clip()
            ctx.drawLinearGradient(gradient(stops.enumerated().map { (CGFloat($0.offset) / CGFloat(stops.count - 1), colour($0.element)) }),
                                   start: CGPoint(x: 0, y: mid.y - r), end: CGPoint(x: 0, y: mid.y + set), options: [])
            ctx.restoreGState()
            // Its bands, cut through to the sky.
            ctx.saveGState()
            ctx.addEllipse(in: disc(mid, r + 0.5))
            ctx.clip()
            ctx.setBlendMode(.clear)
            for (at, tall) in [(0.34, 0.025), (0.44, 0.04), (0.55, 0.055)] {
                ctx.fill(CGRect(x: 0, y: mid.y + at * r, width: side, height: tall * r))
            }
            ctx.restoreGState()
            if shut { tube(ctx, mid, r - 1, RingsLook.rgb(tier), width: 1.4, glow: 6, scale: scale) }
        }
    }

    // MARK: Beads

    /// A bead's width in points, without its rim.
    static func width(_ state: RingsModel.Bead) -> CGFloat { state == .next ? 37 : 27 }

    static func bead(_ tier: Tier, _ state: RingsModel.Bead, scale: CGFloat) -> RingsBitmap? {
        let c = RingsLook.rgb(tier), r = width(state) / 2, side: CGFloat = state == .next ? 108 : state == .par ? 60 : 48
        return raster(side, side, scale: scale) { ctx in
            let mid = CGPoint(x: side / 2, y: side / 2)
            switch state {
            case .dull:
                ctx.setFillColor(colour((12 / 255, 3 / 255, 36 / 255), 0.72))
                ctx.fillEllipse(in: disc(mid, r))
                ring(ctx, mid, r - 0.5, colour(c, 0.6), width: 1)
            case .solved:
                ctx.setFillColor(colour((10 / 255, 4 / 255, 26 / 255), 0.92))
                ctx.fillEllipse(in: disc(mid, r))
                tube(ctx, mid, r - 1, c, width: 2, glow: 7, scale: scale)
            case .par, .next:
                let hot = state == .next
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: (hot ? 28 : 10) * scale, color: colour(c, 0.95))
                ctx.setFillColor(colour(c))
                ctx.fillEllipse(in: disc(mid, r))
                if hot { ctx.fillEllipse(in: disc(mid, r)) }
                ctx.restoreGState()
                ctx.saveGState()
                ctx.addEllipse(in: disc(mid, r))
                ctx.clip()
                let high = CGPoint(x: mid.x - r * 0.3, y: mid.y - r * 0.38)
                ctx.drawRadialGradient(gradient([(0, colour((1, 1, 1))), (hot ? 0.6 : 0.45, colour(c)), (1, colour(c, 0.86))]),
                                       startCenter: high, startRadius: 0, endCenter: mid, endRadius: r, options: [.drawsAfterEndLocation])
                ctx.restoreGState()
                if hot {
                    ring(ctx, CGPoint(x: mid.x - 1.4, y: mid.y), r + 4, colour(RingsLook.cyan, 0.9), width: 1.6)
                    ring(ctx, CGPoint(x: mid.x + 1.4, y: mid.y), r + 4, colour(RingsLook.pink, 0.9), width: 1.6)
                    ring(ctx, mid, r + 4, colour((1, 1, 1)), width: 1.2)
                } else {
                    tube(ctx, mid, r + 2.6, (1, 232 / 255, 72 / 255), width: 1.6, glow: 4, scale: scale)
                }
            }
        }
    }

    /// The thread's length as baked; the engine stretches it from one bead to the next.
    static let linkLength: CGFloat = 44

    static func link(_ tier: Tier, scale: CGFloat) -> RingsBitmap? {
        raster(linkLength, 3, scale: scale) { ctx in
            ctx.setFillColor(colour(RingsLook.rgb(tier), 0.3))
            ctx.fill(CGRect(x: 0, y: 1, width: linkLength, height: 1))
        }
    }

    static func halo(scale: CGFloat) -> RingsBitmap? {
        raster(80, 80, scale: scale) { ctx in
            ctx.setShadow(offset: .zero, blur: 8 * scale, color: colour((1, 1, 1), 0.9))
            ring(ctx, CGPoint(x: 40, y: 40), 20, colour((1, 1, 1), 0.95), width: 1.6)
        }
    }

    // MARK: The daily, the packs, settings, the wordmark

    static func daily(scale: CGFloat) -> RingsBitmap? {
        let side: CGFloat = 72, r: CGFloat = 15
        return raster(side, side, scale: scale) { ctx in
            ctx.setShadow(offset: .zero, blur: 12 * scale, color: colour(RingsLook.cyan, 0.95))
            ctx.setFillColor(colour((1, 1, 1)))
            for _ in 0 ..< 2 {
                for k in 0 ..< 8 {
                    let q = k % 2 == 1 ? r * 0.2 : k % 4 == 0 ? r : r * 0.72, a = CGFloat(k) * .pi / 4 - .pi / 2
                    let p = CGPoint(x: side / 2 + q * cos(a), y: side / 2 + q * sin(a))
                    if k == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
                }
                ctx.closePath()
                ctx.fillPath()
            }
        }
    }

    /// A cover's width in points.
    static let coverWidth: CGFloat = 84

    /// A pack's cover: its glass as the promoted-purchase image draws it, cut to a disc (`scripts/rings-covers.sh`).
    static func cover(_ pack: Pack, scale: CGFloat) -> RingsBitmap? {
        let side = coverWidth + 36, r = coverWidth / 2
        let glass = UIImage(named: "RingsCover-\(pack.rawValue)")?.cgImage
        return raster(side, side, scale: scale) { ctx in
            let mid = CGPoint(x: side / 2, y: side / 2)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 12 * scale, color: colour(RingsLook.cyan, 0.6))
            ctx.setFillColor(colour((0, 0, 0)))
            ctx.fillEllipse(in: disc(mid, r - 1))
            ctx.restoreGState()
            guard let glass else { return ring(ctx, mid, r - 1, colour(RingsLook.cyan, 0.6), width: 1) }
            // The image's first row is its top.
            ctx.saveGState()
            ctx.translateBy(x: mid.x - r, y: mid.y + r)
            ctx.scaleBy(x: 1, y: -1)
            ctx.interpolationQuality = .high
            ctx.draw(glass, in: CGRect(x: 0, y: 0, width: r * 2, height: r * 2))
            ctx.restoreGState()
        }
    }

    static func settings(scale: CGFloat) -> RingsBitmap? {
        raster(44, 44, scale: scale) { ctx in
            ctx.setFillColor(colour(.ink(0.5)))
            for k in 0 ..< 6 {
                let a = CGFloat(k) * .pi / 3
                ctx.fillEllipse(in: disc(CGPoint(x: 22 + 7.5 * cos(a), y: 22 + 7.5 * sin(a)), 1.7))
            }
            ctx.fillEllipse(in: disc(CGPoint(x: 22, y: 22), 2.2))
        }
    }

    /// Chrome: sky over the horizon over sunset.
    static func wordmark(scale: CGFloat) -> RingsBitmap? {
        let w: CGFloat = 300, h: CGFloat = 60, tracking: CGFloat = 11
        let text = NSAttributedString(string: "UNSTIR", attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): UIFont.systemFont(ofSize: 23, weight: .bold),
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): colour((1, 1, 1)),
            NSAttributedString.Key(kCTKernAttributeName as String): tracking,
        ])
        let line = CTLineCreateWithAttributedString(text)
        var ascent: CGFloat = 0, descent: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil)) - tracking
        let at = CGPoint(x: (w - width) / 2, y: h / 2 + (ascent - descent) / 2)
        func letters(_ ctx: CGContext) {
            ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            ctx.textPosition = at
            CTLineDraw(line, ctx)
        }
        // The letters as a mask the gradient is clipped to: the mask's first row is its top, as the bitmap's is.
        let pw = Int((w * scale).rounded(.up)), ph = Int((h * scale).rounded(.up))
        guard let maskContext = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8, bytesPerRow: 0,
                                          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        maskContext.translateBy(x: 0, y: CGFloat(ph))
        maskContext.scaleBy(x: scale, y: -scale)
        letters(maskContext)
        guard let mask = maskContext.makeImage() else { return nil }
        return raster(w, h, scale: scale) { ctx in
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 9 * scale, color: colour(RingsLook.pink, 0.8))
            letters(ctx)
            ctx.restoreGState()
            ctx.saveGState()
            // Undo the bitmap's y-down points for the mask, which is drawn the way up an image is.
            ctx.translateBy(x: 0, y: h)
            ctx.scaleBy(x: 1, y: -1)
            ctx.clip(to: CGRect(x: 0, y: 0, width: w, height: h), mask: mask)
            ctx.translateBy(x: 0, y: h)
            ctx.scaleBy(x: 1, y: -1)
            ctx.drawLinearGradient(gradient([(0, colour(0xFFFFFF)), (0.44, colour(0x62D4FF)), (0.5, colour(0x2A1A90)),
                                             (0.56, colour(0xFF4FD0)), (1, colour(0xFFD65A))]),
                                   start: CGPoint(x: 0, y: 19), end: CGPoint(x: 0, y: 41), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            ctx.restoreGState()
        }
    }

    static func play(scale: CGFloat) -> RingsBitmap? {
        raster(32, 32, scale: scale) { ctx in
            ctx.setFillColor(colour(.deep))
            ctx.setStrokeColor(colour(.deep))
            ctx.setLineJoin(.round)
            ctx.setLineWidth(3)
            ctx.move(to: CGPoint(x: 11, y: 9))
            ctx.addLine(to: CGPoint(x: 23, y: 16))
            ctx.addLine(to: CGPoint(x: 11, y: 23))
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)
        }
    }

    // MARK: Words

    static func font(_ run: RingsText.Run) -> CTFont {
        let weight: UIFont.Weight = switch run.weight {
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        }
        switch run.voice {
        case .word:
            let plain = UIFont.systemFont(ofSize: run.size, weight: weight).fontDescriptor
            let serif = plain.withDesign(.serif).flatMap { $0.withSymbolicTraits(.traitItalic) }
            return UIFont(descriptor: serif ?? plain, size: run.size)
        case .name: return UIFont.systemFont(ofSize: run.size, weight: weight)
        case .data: return UIFont.monospacedSystemFont(ofSize: run.size, weight: weight)
        }
    }

    private struct Set {
        let line: CTLine
        let width, ascent, descent: CGFloat
    }

    private static func set(_ string: String, _ run: RingsText.Run, tracking: CGFloat, finish: RingsText.Finish) -> Set {
        var attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font(run),
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): colour(run.ink),
            NSAttributedString.Key(kCTKernAttributeName as String): tracking,
        ]
        if case let .unlit(tier) = finish {
            attributes[NSAttributedString.Key(kCTForegroundColorAttributeName as String)] = colour(.ink(0.2))
            attributes[NSAttributedString.Key(kCTStrokeColorAttributeName as String)] = colour(RingsLook.rgb(tier), 0.9)
            // Negative strokes and fills; a percentage of the size.
            attributes[NSAttributedString.Key(kCTStrokeWidthAttributeName as String)] = -0.9 / run.size * 100
        }
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        return Set(line: line, width: width - tracking, ascent: ascent, descent: descent)
    }

    private static func shade(_ ctx: CGContext, _ text: RingsText, scale: CGFloat) {
        if text.finish == .shadowed { ctx.setShadow(offset: .zero, blur: 5 * scale, color: night) }
    }

    static func words(_ text: RingsText, scale: CGFloat) -> RingsBitmap? {
        if let arc = text.arc { return bent(text, arc, scale: scale) }
        let pad: CGFloat = text.finish == .shadowed ? 8 : 3
        // Each line is its sets, left to right.
        var lines: [[Set]] = []
        if let wrap = text.wrap, let run = text.runs.first {
            var line = ""
            for word in run.string.split(separator: " ") {
                let longer = line.isEmpty ? String(word) : line + " " + word
                if !line.isEmpty, set(longer, run, tracking: text.tracking, finish: text.finish).width > wrap {
                    lines.append([set(line, run, tracking: text.tracking, finish: text.finish)])
                    line = String(word)
                } else {
                    line = longer
                }
            }
            if !line.isEmpty { lines.append([set(line, run, tracking: text.tracking, finish: text.finish)]) }
        } else {
            lines = [text.runs.map { set($0.string, $0, tracking: text.tracking, finish: text.finish) }]
        }
        let widths = lines.map { $0.reduce(0) { $0 + $1.width } + text.gap * CGFloat(max($0.count - 1, 0)) }
        let talls = lines.map { ($0.map { $0.ascent + $0.descent }.max() ?? 0) * (lines.count > 1 ? 1.2 : 1.05) }
        let w = (widths.max() ?? 0).rounded(.up) + pad * 2, h = talls.reduce(0, +).rounded(.up) + pad * 2
        return raster(w, h, scale: scale) { ctx in
            ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            shade(ctx, text, scale: scale)
            var top = pad
            for (i, line) in lines.enumerated() {
                var x = (w - widths[i]) / 2
                let mid = top + talls[i] / 2
                for set in line {
                    // Runs of different sizes share their middle, not their baseline.
                    ctx.textPosition = CGPoint(x: x, y: mid + (set.ascent - set.descent) / 2)
                    CTLineDraw(set.line, ctx)
                    x += set.width + text.gap
                }
                top += talls[i]
            }
        }
    }

    /// Words along a circle, a letter at a time; placed by the circle's centre.
    private static func bent(_ text: RingsText, _ arc: RingsText.Arc, scale: CGFloat) -> RingsBitmap? {
        guard let run = text.runs.first else { return nil }
        let sets = run.string.map { set(String($0), run, tracking: 0, finish: text.finish) }
        let widths = sets.map { $0.width + text.tracking }, total = widths.reduce(0, +)
        let way: CGFloat = arc.inward ? 1 : -1
        let middle = arc.angle + arc.side * (arc.lead + total / 2) / arc.radius
        var angle = middle - way * total / arc.radius / 2
        var seats: [(Set, CGFloat)] = []
        for (set, width) in zip(sets, widths) {
            seats.append((set, angle + way * width / arc.radius / 2))
            angle += way * width / arc.radius
        }
        let points = seats.map { CGPoint(x: arc.radius * cos($0.1), y: arc.radius * sin($0.1)) }
        guard let first = points.first else { return nil }
        let box = points.reduce(CGRect(origin: first, size: .zero)) { $0.union(CGRect(origin: $1, size: .zero)) }
            .insetBy(dx: -run.size, dy: -run.size).integral
        return raster(box.width, box.height, scale: scale, offset: CGPoint(x: box.midX, y: box.midY)) { ctx in
            ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            shade(ctx, text, scale: scale)
            for ((set, mid), point) in zip(seats, points) {
                ctx.saveGState()
                ctx.translateBy(x: point.x - box.minX, y: point.y - box.minY)
                ctx.rotate(by: mid + way * .pi / 2)
                ctx.textPosition = CGPoint(x: -set.width / 2, y: (set.ascent - set.descent) / 2)
                CTLineDraw(set.line, ctx)
                ctx.restoreGState()
            }
        }
    }
}
