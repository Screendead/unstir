// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// First Stir's scenes, one per level. Each rod in `vignettes` holds one vignette in its rigid core, drawn in two states:
/// held back (later in the night) and played (earlier). A vignette is named by its rod, and every one of the scramble's
/// entries on that rod holds it back, so it plays once its core is still.
enum Story: Hashable, Sendable {
    /// The lab's harbour in the storm: the outline's scene 16, with no level until that chapter is drawn.
    case harbour
    /// Chapter 1, Dawn After: scenes 1 to 5.
    case dawn(Dawn)
    /// Chapter 2, The Rescue: scenes 6 to 10.
    case rescue(Rescue)

    var vignettes: Set<Int> {
        switch self {
        case .harbour: [0, 1, 2]
        case .dawn(let scene): scene.vignettes
        case .rescue(let scene): scene.vignettes
        }
    }
}

extension Level {
    /// The pack's scenes in the outline's order, the night told backwards, numbered by place as `Pack.levels` reads
    /// them. A scene's caption is its time.
    static let firstStir: [Level] = (dawn + rescue).enumerated().map { i, level in
        var level = level
        level.id = Pack.firstStir.id(i + 1)
        level.label = String(format: "%02d", i + 1)
        return level
    }

    /// Chapter 1, Dawn After (FirstStirDawn.swift).
    private static let dawn: [Level] = [
        // Tri's rods all overlap, so its stack orders every heal: the cottage's doorway lies in the boat's disc, so the
        // cottage's one entry is the bottom.
        Level(id: "", pack: .firstStir, label: "", title: "Sunrise", note: "", layout: .tri,
              scramble: .parse("2:+5,1:-4,0:+3,1:+2", in: .tri), story: .dawn(.sunrise)),
        Level(id: "", pack: .firstStir, label: "", title: "The gallery", note: "", layout: .quad,
              scramble: .parse("3:+4,0:-3,1:+5,2:-2", in: .quad), story: .dawn(.gallery)),
        // The child kneels in the dog's disc, so the pool's bottom entry lies under both of the dog's.
        Level(id: "", pack: .firstStir, label: "", title: "The rock pool", note: "", layout: .tri,
              scramble: .parse("1:+4,2:-3,0:+5,1:-2,2:+3", in: .tri), story: .dawn(.rockPool)),
        Level(id: "", pack: .firstStir, label: "", title: "Righting the boat", note: "", layout: .eye,
              scramble: .parse("0:+3,1:-4,2:+5,3:-2,1:+2", in: .eye), story: .dawn(.righting)),
        Level(id: "", pack: .firstStir, label: "", title: "Tea on the quay", note: "", layout: .quad,
              scramble: .parse("2:+4,3:-3,1:+5,0:-2,3:+2,2:-5", in: .quad), story: .dawn(.tea)),
    ]
}

/// First Stir's harbour in the storm, in single-weight neon line, on the tri layout. Everything that differs between a
/// vignette's two states, glow included, keeps inside its own core, so the picture with some vignettes played is the
/// held-back one with those cores cut from the all-played one.
///
/// Rod 0 (top): the lighthouse lantern, smashed and dark, then whole and lit. Rod 1 (right): the boat, capsized with its
/// buoy rope snapped, then moored upright with its lamps lit. Rod 2 (left): the cottage door flung open and a lantern
/// dropped on the quay, then someone in the lit doorway holding it up.
///
/// The night winds back a stage with each vignette played, over the whole sky, until the last shows the calm evening
/// before the storm: the sky warms from storm indigo to an afterglow, the clouds thin, the lightning goes after the
/// first, the rain thins to none, and the moon sinks back towards the rooftops. Nothing but the sky changes, so no pixel
/// moves in a way that could pass for a rod solved.
enum Harbour {
    static let layout = Layout.tri
    /// Every stroke's width, in tank radii.
    static let line = 0.0075
    /// How long a vignette takes to fade in as it plays.
    static let fade = 0.4
    static let stages = Story.harbour.vignettes.count
    /// How long the night takes to wind back a stage, the rain climbing back up its slant all the while.
    static let rewind = 1.6
    /// How far the rain climbs per stage, in tank radii.
    static let climb = 0.9
    static let rainLeft = [320, 200, 90, 0]
    /// The moon's centre per stage, and its radius: every point of it stays outside all three discs (radius 0.58), so no
    /// rod ever stirs it, and in the wedge of sky between the lighthouse's disc and the cottage's.
    static let moon: [(x: Double, y: Double)] = [(-0.62, -0.62), (-0.69, -0.51), (-0.75, -0.40), (-0.80, -0.30)]
    static let moonRadius = 0.05
    /// The far lightning's box in tank units, glow included: it is baked alone, at that size.
    static let boltBox = CGRect(x: 0.46, y: -0.82, width: 0.41, height: 0.74)

    /// ponytail: not measured on the phone. Four tank-sized float images (two skies, the scene held back and played)
    /// at 3x on the largest phone come to about 51 MB; past this the layers bake at a lower scale.
    static let budget = 64 << 20

    /// The scale to bake at for a tank `side` points across: the screen's, unless the layers would pass `budget`.
    static func bakeScale(side: CGFloat, scale: CGFloat) -> CGFloat {
        min(scale, ((Double(budget) / Double(layerBytes(side: side, scale: 1))).squareRoot() * 100).rounded(.down) / 100)
    }

    /// What the baked layers hold at `scale`: four tank-sized images and the bolt's box, at 8 bytes a pixel.
    static func layerBytes(side: CGFloat, scale: CGFloat) -> Int {
        let px = side * scale / 2
        return Int(8 * px * px * (4 * 4 + boltBox.width * boltBox.height))
    }

    static let ink = Color(0x8F9CFF)
    static let sodium = Color(0xFFA53A)
    static let flame = Color(0xFFE2A0)
    static let sea = Color(0x2CD5C4)
    static let rain = Color(0xB7CEFF)
    static let cloud = Color(0x5F59D6)
    static let moonlight = Color(0xFFF1C8)

    /// The rain, one direction field over everything: a turned core shows it slanting the wrong way. In a random order,
    /// so the first n are an even thinning.
    static let drops: [(x: Double, y: Double, l: Double)] = {
        var drops = SplitMix64(state: 23)
        return (0..<320).map { _ in
            (Double.random(in: -1.1..<1.1, using: &drops), Double.random(in: -1.1..<1.0, using: &drops),
             Double.random(in: 0.035..<0.08, using: &drops))
        }
    }()
    static let slant = 16 * Double.pi / 180

    /// The rain and the moon, drawn over the baked layers so they can move: `from` is the stage being wound back from,
    /// `u` how far (0 to 1) the rewind to `stage` has gone.
    static func weather(_ ctx: GraphicsContext, r: CGFloat, stage: Int, from: Int, u: Double) {
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: r + x * r, y: r + y * r) }
        let style = StrokeStyle(lineWidth: line * r, lineCap: .round, lineJoin: .round)
        let m = (x: moon[from].x + (moon[stage].x - moon[from].x) * u, y: moon[from].y + (moon[stage].y - moon[from].y) * u)
        let disc = Path(ellipseIn: CGRect(origin: p(m.x - moonRadius, m.y - moonRadius), size: CGSize(width: 2 * moonRadius * r, height: 2 * moonRadius * r)))
        // Veiled by the storm, clearer each stage back.
        let clear = 0.4 + 0.6 * (Double(from) + Double(stage - from) * u) / Double(stages)
        neon(ctx, r: r, glows: [(0.03, 0.45 * clear), (0.008, 0.9 * clear)]) { g in
            g.fill(disc, with: .color(moonlight.opacity(0.85 * clear)))
            g.stroke(disc, with: .color(flame.opacity(clear)), style: style)
        }
        // While it winds back the rain climbs, its streaks drawn out by the speed; the drops this stage loses fade as they go.
        let climbed = climb * (Double(from) + Double(stage - from) * u), stretch = 1 + 2 * sin(.pi * u) * (stage > from ? 1 : 0)
        let shown = rainLeft[stage], fading = rainLeft[from]
        func wrap(_ v: Double) -> Double { (v + 1.1).truncatingRemainder(dividingBy: 2.2) + (v + 1.1 < 0 ? 2.2 : 0) - 1.1 }
        var steady = Path(), going = Path()
        for (i, d) in drops.prefix(max(shown, fading)).enumerated() {
            let x = wrap(d.x - climbed * sin(slant)), y = wrap(d.y - climbed * cos(slant)), l = d.l * stretch
            let streak = Path { $0.move(to: p(x, y)); $0.addLine(to: p(x + l * sin(slant), y + l * cos(slant))) }
            if i < shown { steady.addPath(streak) } else { going.addPath(streak) }
        }
        ctx.stroke(steady, with: .color(rain.opacity(0.2)), style: style)
        ctx.stroke(going, with: .color(rain.opacity(0.2 * (1 - u))), style: style)
    }

    /// The sky's colour from the zenith down to the horizon, the storm's at 0 and the afterglow's at 1.
    static func sky(_ t: Double) -> [Gradient.Stop] {
        let storm: [UInt32] = [0x000000, 0x04031C, 0x0E0B3C, 0x1E1960], dusk: [UInt32] = [0x03062A, 0x16205E, 0x4A2C78, 0xC8605A]
        return zip(zip(storm, dusk), [0, 0.4, 0.75, 1]).map { pair, at in
            func c(_ v: UInt32, _ shift: UInt32) -> Double { Double(v >> shift & 0xFF) / 255 }
            func mix(_ shift: UInt32) -> Double { c(pair.0, shift) + (c(pair.1, shift) - c(pair.0, shift)) * t }
            return .init(color: Color(red: mix(16), green: mix(8), blue: mix(0)), location: at)
        }
    }

    /// What is baked apart, so the night can wind back without a bake per stage. The sky at any stage is the storm's
    /// faded into the evening's, so two skies hold every stage; the bolt comes and goes on its own; the scene, with every
    /// vignette in `played` played, is transparent over the sky.
    enum Layer: Equatable {
        case sky(evening: Bool)
        case bolt
        case scene(played: Set<Int>)
    }

    @MainActor
    static func render(_ layer: Layer, side: CGFloat, scale: CGFloat, colorMode: ColorRenderingMode = .extendedLinear) -> UIImage? {
        let box = layer == .bolt ? boltBox : CGRect(x: -1, y: -1, width: 2, height: 2)
        let r = ImageRenderer(content: Canvas { ctx, _ in
            var c = ctx
            c.translateBy(x: -(box.minX + 1) * side / 2, y: -(box.minY + 1) * side / 2)
            draw(c, r: side / 2, layer: layer)
        }
        .frame(width: box.width * side / 2, height: box.height * side / 2))
        r.scale = scale
        r.isOpaque = layer == .sky(evening: false) || layer == .sky(evening: true)
        r.colorMode = colorMode
        return r.uiImage
    }

    // ponytail: one long drawing function, top to bottom of the picture; split it only if a second scene is drawn.
    static func draw(_ ctx: GraphicsContext, r: CGFloat, layer: Layer) {
        // Where the piece being drawn sits: a figure is drawn in its own place, then set down where its core leaves it in view.
        var off = (x: 0.0, y: 0.0)
        // And how much it is enlarged, about which point of its own: the lantern's storey is drawn larger than life.
        var zoom = (k: 1.0, x: 0.0, y: 0.0)
        func p(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: r + (zoom.x + (x - zoom.x) * zoom.k + off.x) * r, y: r + (zoom.y + (y - zoom.y) * zoom.k + off.y) * r)
        }
        func poly(_ pts: [(Double, Double)], closed: Bool = true) -> Path {
            Path { path in
                path.move(to: p(pts[0].0, pts[0].1))
                for q in pts.dropFirst() { path.addLine(to: p(q.0, q.1)) }
                if closed { path.closeSubpath() }
            }
        }
        func seg(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double) -> Path {
            Path { $0.move(to: p(ax, ay)); $0.addLine(to: p(bx, by)) }
        }
        func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Path {
            Path(CGRect(origin: p(x0, y0), size: CGSize(width: (x1 - x0) * zoom.k * r, height: (y1 - y0) * zoom.k * r)))
        }
        func circle(_ x: Double, _ y: Double, _ radius: Double) -> Path {
            Path(ellipseIn: CGRect(origin: p(x - radius, y - radius), size: CGSize(width: 2 * radius * zoom.k * r, height: 2 * radius * zoom.k * r)))
        }
        func quad(_ ax: Double, _ ay: Double, _ cx: Double, _ cy: Double, _ bx: Double, _ by: Double) -> Path {
            Path { $0.move(to: p(ax, ay)); $0.addQuadCurve(to: p(bx, by), control: p(cx, cy)) }
        }
        let style = StrokeStyle(lineWidth: line * r, lineCap: .round, lineJoin: .round)
        func stroke(_ g: GraphicsContext, _ path: Path, _ colour: Color, _ opacity: Double = 1) {
            g.stroke(path, with: .color(colour.opacity(opacity)), style: style)
        }
        func glow(_ x: Double, _ y: Double, _ radius: Double, _ colour: Color, _ strength: Double) {
            ctx.fill(circle(x, y, radius), with: .radialGradient(
                Gradient(stops: [.init(color: colour.opacity(strength), location: 0), .init(color: colour.opacity(strength * 0.35), location: 0.4),
                                 .init(color: colour.opacity(0), location: 1)]),
                center: p(x, y), startRadius: 0, endRadius: radius * r))
        }
        /// A storm lantern standing at (x, y) (its base), `size` tall, turned by `angle` about its base.
        func lantern(_ g: GraphicsContext, _ x: Double, _ y: Double, size s: Double, angle: Double = 0, lit: Bool) {
            var l = g
            l.translateBy(x: p(x, y).x, y: p(x, y).y)
            l.rotate(by: .radians(angle))
            func q(_ u: Double, _ v: Double) -> CGPoint { CGPoint(x: u * s * r, y: -v * s * r) }
            var cage = Path()
            // Base, glass, cap, then the bail.
            cage.move(to: q(-0.32, 0)); cage.addLine(to: q(0.32, 0))
            cage.move(to: q(-0.26, 0)); cage.addLine(to: q(-0.22, 0.62)); cage.addLine(to: q(0.22, 0.62)); cage.addLine(to: q(0.26, 0))
            cage.move(to: q(0, 0.02)); cage.addLine(to: q(0, 0.6))
            cage.move(to: q(-0.28, 0.62)); cage.addLine(to: q(-0.12, 0.8)); cage.addLine(to: q(0.12, 0.8)); cage.addLine(to: q(0.28, 0.62))
            cage.move(to: q(-0.2, 0.84)); cage.addQuadCurve(to: q(0.2, 0.84), control: q(0, 1.12))
            if lit {
                l.fill(Path(ellipseIn: CGRect(origin: q(-0.18, 0.5), size: CGSize(width: 0.36 * s * r, height: 0.42 * s * r))),
                       with: .color(flame))
            }
            l.stroke(cage, with: .color(lit ? sodium : ink), style: style)
        }
        let horizon = 0.0

        switch layer {
        case .bolt:
            // Far lightning, outside every disc, lighting the cloud it falls from; gone once the night winds back.
            let bolt = poly([(0.70, -0.66), (0.66, -0.56), (0.71, -0.52), (0.64, -0.40), (0.69, -0.37), (0.62, -0.24)], closed: false)
            neon(ctx, r: r, glows: [(0.05, 0.5), (0.01, 0.9)]) { g in stroke(g, bolt, Color(0xD9CCFF)) }
            return
        case .sky(let evening):
            let t = evening ? 1.0 : 0
            // Sky, storm indigo down to the horizon; the sea below it, darkening towards the viewer.
            ctx.fill(rect(-1, -1, 1, 1), with: .color(.black))
            ctx.fill(rect(-1, -1, 1, horizon), with: .linearGradient(Gradient(stops: sky(t)), startPoint: p(0, -1), endPoint: p(0, horizon)))
            ctx.fill(rect(-1, horizon, 1, 1), with: .linearGradient(
                Gradient(stops: [(0, 0x0B2238), (0.35, 0x04101C), (1, 0x000000)].map { .init(color: Color($0.1), location: $0.0) }),
                startPoint: p(0, horizon), endPoint: p(0, 1)))

            // Cloud banks: flat bellies, heaped tops, so every core that holds sky knows which way is up. The moon's way
            // down, on the left, is clear.
            var clouds = Path()
            let banks = [(-0.98, -0.28, -0.70, 0.07), (0.12, 0.92, -0.80, 0.06), (-0.62, 0.22, -0.90, 0.05),
                         (0.46, 0.99, -0.42, 0.05), (-0.25, 0.30, -0.16, 0.03)]
            for (x0, x1, y, h) in banks {
                clouds.move(to: p(x0, y))
                var x = x0, k = 0
                while x < x1 - 0.01 {
                    let w = min([0.11, 0.16, 0.09, 0.14][k % 4] * (h / 0.06), x1 - x)
                    clouds.addQuadCurve(to: p(x + w, y), control: p(x + w / 2, y - h * [1.5, 2.1, 1.2, 1.8][k % 4]))
                    x += w; k += 1
                }
                clouds.closeSubpath()
            }
            ctx.fill(clouds, with: .color(.black.opacity(0.55 * (1 - 0.5 * t))))
            neon(ctx, r: r, glows: [(0.03, 0.3), (0.008, 0.6)]) { g in stroke(g, clouds, cloud, 0.75 * (1 - 0.45 * t)) }

            // The swell: lines closer and calmer towards the horizon, longer and higher towards the viewer.
            var swell = Path()
            var rng = SplitMix64(state: 41)
            for k in 1...16 {
                let t = Double(k) / 16, y = horizon + 0.012 + 0.98 * pow(t, 1.7)
                let amp = 0.002 + 0.02 * t, wave = 0.05 + 0.22 * t, phase = Double.random(in: 0..<6.3, using: &rng)
                swell.move(to: p(-1.05, y))
                for x in stride(from: -1.05, through: 1.05, by: 0.01) {
                    swell.addLine(to: p(x, y - amp * sin(x / wave * 2 * .pi + phase)))
                }
            }
            neon(ctx, r: r, glows: [(0.025, 0.35), (0.007, 0.8)]) { g in
                var s = g
                s.clip(to: rect(-1, horizon, 1, 1))
                s.stroke(swell, with: .linearGradient(Gradient(colors: [sea.opacity(0.35), sea.opacity(0.9)]),
                                                      startPoint: p(0, horizon), endPoint: p(0, 0.9)), style: style)
                stroke(g, seg(-1, horizon, 1, horizon), sea, 0.9)
            }
            return
        case .scene:
            break
        }
        guard case .scene(let played) = layer else { return }

        // The breakwater's rock and a tall lighthouse: the knob sits on the tower, the lantern above it in the top core.
        let rock = poly([(-0.27, 0.03), (-0.21, -0.012), (-0.14, -0.03), (-0.07, -0.026), (0.03, -0.045), (0.11, -0.03),
                         (0.19, -0.016), (0.28, 0.03)])
        let tower = poly([(-0.10, -0.025), (-0.062, -0.51), (0.062, -0.51), (0.10, -0.025)])
        ctx.fill(rock, with: .color(.black))
        ctx.fill(tower, with: .color(.black))
        var house = Path()
        house.addPath(tower)
        for y in [-0.14, -0.26, -0.38] {
            let w = 0.10 - 0.038 * (y + 0.025) / -0.485
            house.addPath(quad(-w, y, 0, y + 0.02, w, y))
        }
        house.addPath(Path { a in
            a.move(to: p(-0.024, -0.03)); a.addLine(to: p(-0.024, -0.075))
            a.addQuadCurve(to: p(0.024, -0.075), control: p(0, -0.1)); a.addLine(to: p(0.024, -0.03))
        })
        for y in [-0.20, -0.32, -0.44] { house.addPath(rect(-0.009, y - 0.015, 0.009, y + 0.015)) }
        // The lantern's storey, drawn as if the tower ended at -0.30 and lifted onto it, a fifth larger about its deck so
        // its glass reads at phone size; the lit beams stop short of the core's edge.
        off = (0, -0.21)
        zoom = (1.2, 0, -0.30)
        let lanternRoom = rect(-0.075, -0.475, 0.075, -0.345)
        var dome = quad(-0.088, -0.475, 0, -0.60, 0.088, -0.475)
        dome.closeSubpath()
        ctx.fill(dome, with: .color(.black))
        ctx.fill(rect(-0.11, -0.345, 0.11, -0.30), with: .color(.black))
        ctx.fill(lanternRoom, with: .color(Color(0x05041A)))
        // The gallery: deck, brackets, rail and posts.
        house.addPath(seg(-0.11, -0.30, 0.11, -0.30))
        house.addPath(seg(-0.11, -0.30, -0.062, -0.27))
        house.addPath(seg(0.11, -0.30, 0.062, -0.27))
        house.addPath(seg(-0.11, -0.345, 0.11, -0.345))
        for x in stride(from: -0.11, through: 0.111, by: 0.055) { house.addPath(seg(x, -0.30, x, -0.345)) }
        house.addPath(lanternRoom)
        house.addPath(seg(-0.025, -0.475, -0.025, -0.345))
        house.addPath(seg(0.025, -0.475, 0.025, -0.345))
        house.addPath(dome)
        house.addPath(circle(0, -0.552, 0.013))
        house.addPath(seg(0, -0.565, 0, -0.605))
        neon(ctx, r: r) { g in
            stroke(g, rock, ink, 0.8)
            stroke(g, house, ink)
        }

        // Vignette 0: the lantern.
        if played.contains(0) {
            for side in [-1.0, 1] {
                let beam = poly([(0.06 * side, -0.43), (0.17 * side, -0.45), (0.17 * side, -0.37), (0.06 * side, -0.39)])
                ctx.fill(beam, with: .linearGradient(Gradient(colors: [sodium.opacity(0.6), sodium.opacity(0)]),
                                                     startPoint: p(0.06 * side, -0.41), endPoint: p(0.17 * side, -0.41)))
            }
            neon(ctx, r: r, glows: [(0.022, 0.75), (0.008, 1)]) { g in
                g.fill(rect(-0.071, -0.471, 0.071, -0.349), with: .color(sodium.opacity(0.3)))
                g.fill(circle(0, -0.41, 0.026), with: .color(flame))
                stroke(g, lanternRoom, sodium)
                stroke(g, seg(-0.025, -0.475, -0.025, -0.345), sodium)
                stroke(g, seg(0.025, -0.475, 0.025, -0.345), sodium)
            }
        } else {
            // Dark, its outer panes smashed out to the jagged teeth left in their frames, shards of them falling past the
            // gallery. No lamp is drawn: an empty black room is what a dead lantern looks like.
            var broken = Path()
            for side in [-1.0, 1] {
                func m(_ u: Double, _ v: Double) -> (Double, Double) { (side * u, v) }
                broken.addPath(poly([m(0.075, -0.475), m(0.025, -0.475), m(0.04, -0.452), m(0.052, -0.462), m(0.064, -0.43)]))
                broken.addPath(poly([m(0.075, -0.345), m(0.025, -0.345), m(0.034, -0.372), m(0.048, -0.358), m(0.062, -0.39)]))
            }
            var falling = Path()
            for (x, y, a) in [(-0.135, -0.27, 0.4), (-0.165, -0.22, -0.3), (-0.13, -0.17, 0.9)] {
                falling.addPath(poly([(x, y), (x + 0.022 * cos(a), y + 0.022 * sin(a)), (x + 0.006, y + 0.018)]))
            }
            neon(ctx, r: r, glows: [(0.02, 0.35), (0.006, 0.8)]) { g in
                stroke(g, broken, ink, 0.9)
                stroke(g, falling, ink, 0.7)
            }
        }
        zoom = (1, 0, 0)
        off = (0, 0)

        // The quay on the left, a neighbour's house past the core, and the cottage, its door and window clear of the knob.
        let quayTop = 0.30
        ctx.fill(rect(-1, quayTop, 0, 0.41), with: .color(.black))
        ctx.fill(poly([(-0.99, quayTop), (-0.99, -0.02), (-0.845, -0.12), (-0.70, -0.02), (-0.70, quayTop)]), with: .color(.black))
        let walls = rect(-0.62, 0.02, -0.04, quayTop)
        let roof = poly([(-0.66, 0.03), (-0.33, -0.13), (0, 0.03)])
        ctx.fill(walls, with: .color(.black))
        ctx.fill(roof, with: .color(.black))
        ctx.fill(rect(-0.54, -0.11, -0.49, -0.02), with: .color(.black))
        var stone = Path()
        stone.addPath(seg(-1, quayTop, 0, quayTop))
        stone.addPath(seg(0, quayTop, 0, 0.41))
        stone.addPath(seg(-1, 0.355, 0, 0.355))
        stone.addPath(seg(-1, 0.41, 0, 0.41))
        for (i, x) in stride(from: -0.98, to: -0.01, by: 0.11).enumerated() {
            let o = i % 2 == 0 ? 0.0 : 0.055
            stone.addPath(seg(x + o, quayTop, x + o, 0.355))
            stone.addPath(seg(x + 0.055 - o, 0.355, x + 0.055 - o, 0.41))
        }
        var cottage = Path()
        cottage.addPath(walls)
        cottage.addPath(roof)
        cottage.addPath(poly([(-0.54, -0.028), (-0.54, -0.11), (-0.49, -0.11), (-0.49, -0.052)], closed: false))
        cottage.addPath(seg(-0.615, 0.03, -0.045, 0.03))
        let window = rect(-0.57, 0.09, -0.46, 0.18)
        let doorway = rect(-0.18, 0.07, -0.07, quayTop)
        cottage.addPath(window)
        cottage.addPath(doorway)
        // Neighbour: gable and a lit window, past the core.
        cottage.addPath(poly([(-0.99, -0.02), (-0.845, -0.12), (-0.70, -0.02), (-0.70, quayTop)], closed: false))
        // A bollard at the quay's end.
        cottage.addPath(poly([(-0.045, quayTop), (-0.045, 0.265), (-0.055, 0.258), (0.005, 0.258), (-0.005, 0.265), (-0.005, quayTop)],
                             closed: false))
        neon(ctx, r: r) { g in
            stroke(g, stone, ink, 0.6)
            stroke(g, cottage, ink)
            g.fill(rect(-0.90, 0.06, -0.80, 0.14), with: .color(sodium.opacity(0.75)))
        }

        // Vignette 2: the cottage door.
        if played.contains(2) {
            // Its glow held tight, so the core's edge never clips it beside the doorway.
            neon(ctx, r: r, glows: [(0.022, 0.55), (0.009, 1)]) { g in
                g.fill(window, with: .color(sodium.opacity(0.4)))
                stroke(g, window, sodium)
                stroke(g, seg(-0.515, 0.09, -0.515, 0.18), sodium)
                stroke(g, seg(-0.57, 0.135, -0.46, 0.135), sodium)
                g.fill(doorway, with: .linearGradient(Gradient(colors: [sodium.opacity(0.6), sodium.opacity(0.25)]),
                                                     startPoint: p(0, 0.07), endPoint: p(0, quayTop)))
                stroke(g, doorway, sodium)
            }
            // Someone in the doorway, backlit, holding the lantern up and out.
            let figure = Path { f in
                f.move(to: p(-0.1601, quayTop)); f.addLine(to: p(-0.1549, 0.261))
                f.addLine(to: p(-0.1679, 0.261)); f.addLine(to: p(-0.1497, 0.1596))
                f.addQuadCurve(to: p(-0.1003, 0.1596), control: p(-0.125, 0.1414))
                f.addLine(to: p(-0.0821, 0.261)); f.addLine(to: p(-0.0951, 0.261)); f.addLine(to: p(-0.0899, quayTop))
                f.closeSubpath()
                f.addEllipse(in: CGRect(origin: p(-0.1458, 0.0946), size: CGSize(width: 0.0416 * r, height: 0.0442 * r)))
            }
            let arm = poly([(-0.1445, 0.1674), (-0.1939, 0.1414), (-0.2121, 0.0816)], closed: false)
            ctx.fill(figure, with: .color(.black))
            neon(ctx, r: r, glows: [(0.03, 0.5), (0.008, 1)]) { g in
                stroke(g, figure, flame)
                stroke(g, arm, flame)
                lantern(g, -0.2121, 0.1518, size: 0.065, lit: true)
            }
            glow(-0.2121, 0.1245, 0.07, sodium, 0.5)
        } else {
            // The door flung open on its hinge, the window dark, the lantern dropped on the quay.
            let door = poly([(-0.18, 0.07), (-0.23, 0.05), (-0.23, 0.32), (-0.18, quayTop)])
            ctx.fill(door, with: .color(.black))
            var planks = Path()
            planks.addPath(door)
            for t in [0.33, 0.66] { planks.addPath(seg(-0.18 - 0.05 * t, 0.07 - 0.02 * t, -0.18 - 0.05 * t, quayTop + 0.02 * t)) }
            planks.addPath(seg(-0.515, 0.09, -0.515, 0.18))
            planks.addPath(seg(-0.57, 0.135, -0.46, 0.135))
            neon(ctx, r: r) { g in
                stroke(g, planks, ink)
                // On its side under the window, clear of the knob, its glass out in pieces on the stones.
                var spilt = Path()
                for (x, y, a) in [(-0.43, 0.292, 0.3), (-0.62, 0.288, -0.4), (-0.645, 0.294, 0.2)] {
                    spilt.addPath(poly([(x, y), (x + 0.02 * cos(a), y - 0.02 * sin(a)), (x + 0.008, y - 0.014)]))
                }
                g.fill(rect(-0.585, 0.231, -0.468, 0.297), with: .color(.black))
                lantern(g, -0.465, quayTop - 0.036, size: 0.11, angle: -.pi / 2, lit: false)
                stroke(g, spilt, ink, 0.8)
            }
        }

        // Vignette 1: the boat, and its buoy, drawn as if afloat at 0.27 and set down below the knob, left of it.
        off = (-0.06, 0.12)
        let waterline = 0.27
        var buoy = Path()
        buoy.addPath(poly([(0.62, waterline + 0.005), (0.63, waterline - 0.03), (0.66, waterline - 0.03), (0.67, waterline + 0.005)]))
        buoy.addPath(seg(0.645, waterline - 0.03, 0.645, waterline - 0.06))
        ctx.fill(buoy, with: .color(.black))
        if played.contains(1) {
            let hull = Path { h in
                h.move(to: p(0.17, 0.212)); h.addLine(to: p(0.52, 0.212))
                h.addQuadCurve(to: p(0.60, 0.172), control: p(0.57, 0.205))
                h.addQuadCurve(to: p(0.545, waterline), control: p(0.585, 0.245))
                h.addLine(to: p(0.195, waterline))
                h.addQuadCurve(to: p(0.17, 0.212), control: p(0.175, 0.25))
            }
            let cabin = rect(0.245, 0.142, 0.365, 0.212)
            ctx.fill(hull, with: .color(.black))
            ctx.fill(cabin, with: .color(.black))
            var boat = Path()
            boat.addPath(hull)
            boat.addPath(seg(0.185, 0.24, 0.565, 0.235))
            boat.addPath(cabin)
            boat.addPath(seg(0.235, 0.142, 0.375, 0.142))
            // Mast, boom and furled sail, a pennant streaming downwind.
            boat.addPath(seg(0.42, 0.212, 0.42, -0.06))
            boat.addPath(seg(0.42, 0.10, 0.215, 0.128))
            boat.addPath(Path { s in
                s.move(to: p(0.415, 0.094))
                for (i, x) in stride(from: 0.39, through: 0.23, by: -0.04).enumerated() {
                    s.addQuadCurve(to: p(x, 0.12 - 0.026 * (x - 0.215) / 0.205), control: p(x + 0.02, 0.10 - 0.016 * Double(i % 2)))
                }
            })
            boat.addPath(poly([(0.42, -0.06), (0.50, -0.044), (0.42, -0.03)]))
            let stays = Path { s in
                s.move(to: p(0.42, -0.04)); s.addLine(to: p(0.595, 0.175))
                s.move(to: p(0.42, -0.04)); s.addLine(to: p(0.18, 0.212))
            }
            // The mooring line from the bow to the buoy, slack in the swell.
            let mooring = quad(0.585, 0.195, 0.62, 0.27, 0.645, waterline - 0.06)
            neon(ctx, r: r) { g in
                stroke(g, boat, ink)
                stroke(g, stays, ink, 0.5)
                stroke(g, mooring, ink, 0.8)
                stroke(g, buoy, ink)
            }
            neon(ctx, r: r, glows: [(0.035, 0.6), (0.009, 1)]) { g in
                g.fill(circle(0.305, 0.177, 0.016), with: .color(sodium.opacity(0.8)))
                stroke(g, circle(0.305, 0.177, 0.016), sodium)
                g.fill(rect(0.41, -0.02, 0.43, 0.005), with: .color(flame))
                var track = Path()
                for (i, y) in stride(from: 0.29, to: 0.37, by: 0.035).enumerated() {
                    let w = 0.008 + 0.008 * Double(i % 2)
                    track.addPath(seg(0.305 - w, y, 0.305 + w, y))
                    track.addPath(seg(0.42 - w * 0.8, y + 0.012, 0.42 + w * 0.8, y + 0.012))
                }
                stroke(g, track, sodium, 0.55)
            }
        } else {
            // Keel up, rudder in the air, the mast down in the water and the lamp gone out.
            let hull = Path { h in
                h.move(to: p(0.19, waterline))
                h.addQuadCurve(to: p(0.39, 0.175), control: p(0.22, 0.18))
                h.addQuadCurve(to: p(0.58, waterline - 0.008), control: p(0.56, 0.18))
                h.closeSubpath()
            }
            ctx.fill(hull, with: .color(.black))
            var wreck = Path()
            wreck.addPath(hull)
            wreck.addPath(quad(0.215, waterline - 0.03, 0.39, 0.16, 0.565, waterline - 0.035))
            wreck.addPath(seg(0.25, 0.214, 0.53, 0.214))
            wreck.addPath(poly([(0.205, 0.245), (0.18, 0.205), (0.205, 0.185), (0.225, 0.225)], closed: false))
            // Spray off the windward side.
            for (x, y, a) in [(0.18, 0.25, -2.6), (0.17, 0.235, -2.2), (0.185, 0.215, -1.9)] {
                wreck.addPath(seg(x, y, x + 0.03 * cos(a), y + 0.03 * sin(a)))
            }
            let mast = seg(0.40, waterline + 0.01, 0.34, 0.38)
            // The oar adrift, and the snapped mooring line hanging off the buoy.
            var drift = Path()
            drift.addPath(seg(0.48, 0.31, 0.58, 0.29))
            drift.addPath(poly([(0.58, 0.29), (0.62, 0.278), (0.625, 0.288), (0.585, 0.30)]))
            drift.addPath(Path { s in
                s.move(to: p(0.645, waterline - 0.06)); s.addQuadCurve(to: p(0.60, 0.30), control: p(0.60, 0.24))
                s.move(to: p(0.60, 0.30)); s.addLine(to: p(0.59, 0.31))
                s.move(to: p(0.60, 0.30)); s.addLine(to: p(0.585, 0.298))
            })
            neon(ctx, r: r) { g in
                stroke(g, wreck, ink)
                stroke(g, mast, ink, 0.35)
                stroke(g, drift, ink, 0.8)
                stroke(g, buoy, ink)
                lantern(g, 0.255, 0.322, size: 0.04, angle: 0.5, lit: false)
            }
        }
    }
}

/// A story's picture as the stack has played it: the held-back scene over the sky, each played core cut in from the
/// all-played scene over its own sky and cross-faded as it plays or unplays, and the night wound back a stage per
/// vignette played. It bakes its layers as it appears, within `Harbour.budget`, and strikes as `PictureLayer` does.
struct StoryLayer: View {
    let story: Story
    let played: Set<Int>
    let side: CGFloat
    var onStrike: () -> Void = {}
    @Environment(\.displayScale) private var scale
    @State private var layers: (storm: UIImage, evening: UIImage, bolt: UIImage, held: UIImage, played: UIImage)?
    /// The stage being wound back from, and when the rewind began.
    @State private var rewind: (from: Int, at: Date)?
    /// The stage the rain and moon rest at between rewinds: it lags `stage` until `onChange` sees the change.
    @State private var rested = 0
    /// When each vignette played, for its fade: on the clock that runs the rewind, which starts with it and outlasts it.
    @State private var playedAt: [Int: Date] = [:]

    private var stage: Int { played.count }

    var body: some View {
        TimelineView(.animation(paused: rewind == nil)) { timeline in
            // How far the night stands wound back, in stages: between two while a rewind runs.
            let (from, to, u) = rewind.map { rewind -> (Int, Int, Double) in
                let x: Double = min(max(timeline.date.timeIntervalSince(rewind.at) / Harbour.rewind, 0), 1)
                return (rewind.from, stage, x * x * (3 - 2 * x))
            } ?? (rested, rested, 1)
            let night = Double(from) + Double(to - from) * u
            ZStack {
                if let layers {
                    sky(layers, night: night)
                    Image(uiImage: layers.held)
                    ForEach(Harbour.layout.rods.indices.filter(story.vignettes.contains), id: \.self) { k in
                        let rod = Harbour.layout.rods[k], core = Tank.plateau * rod.z * side
                        ZStack {
                            sky(layers, night: night)
                            Image(uiImage: layers.played)
                        }
                        .mask(Circle().frame(width: core, height: core).position(x: side / 2 * (1 + rod.x), y: side / 2 * (1 + rod.y)))
                        .opacity(playedAt[k].map { at in
                            let x = min(max(timeline.date.timeIntervalSince(at) / Harbour.fade, 0), 1)
                            return x * x * (3 - 2 * x)
                        } ?? 0)
                    }
                    Canvas { ctx, size in Harbour.weather(ctx, r: size.width / 2, stage: to, from: from, u: u) }
                } else {
                    Color.black
                }
            }
        }
        .frame(width: side, height: side)
        .drawingGroup(colorMode: .extendedLinear)
        .keyframeAnimator(initialValue: 0.0, trigger: layers != nil) { picture, o in picture.opacity(o) } keyframes: { _ in
            PictureLayer.strike
        }
        .onChange(of: layers != nil) { if layers != nil { onStrike() } }
        .onAppear {
            rested = stage
            for k in played { playedAt[k] = .distantPast }
        }
        // The core snaps back turned at once on an undo: a fade would show the played state on a turned core.
        .onChange(of: played) { old, new in
            for k in new.subtracting(old) { playedAt[k] = .now }
            for k in old.subtracting(new) { playedAt[k] = nil }
        }
        .onChange(of: stage) { old, new in
            if new > old { rewind = (old, .now) } else { rewind = nil; rested = new }
        }
        .task(id: rewind?.at) {
            guard rewind != nil, (try? await Task.sleep(for: .seconds(Harbour.rewind))) != nil else { return }
            rested = stage
            rewind = nil
        }
        .task(id: "\(side) \(scale)") {
            let s = Harbour.bakeScale(side: side, scale: scale)
            @MainActor func bake(_ layer: Harbour.Layer) -> UIImage? { Harbour.render(layer, side: side, scale: s) }
            guard let storm = bake(.sky(evening: false)), let evening = bake(.sky(evening: true)), let bolt = bake(.bolt),
                  let held = bake(.scene(played: [])), let played = bake(.scene(played: story.vignettes)) else { return }
            layers = (storm, evening, bolt, held, played)
        }
    }

    /// The storm's sky faded into the evening's as far as the night stands wound back, the bolt going in the first stage.
    private func sky(_ layers: (storm: UIImage, evening: UIImage, bolt: UIImage, held: UIImage, played: UIImage),
                     night: Double) -> some View {
        let box = Harbour.boltBox
        return ZStack {
            Image(uiImage: layers.storm)
            Image(uiImage: layers.evening).opacity(night / Double(Harbour.stages))
            Image(uiImage: layers.bolt)
                .position(x: side / 2 * (1 + box.midX), y: side / 2 * (1 + box.midY))
                .opacity(max(1 - night, 0))
        }
        .frame(width: side, height: side)
    }
}
