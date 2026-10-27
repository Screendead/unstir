// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// First Stir's chapter 2, The Rescue: scenes 6 to 10 of the outline, from 4:45 back to 2:30 am, in rescue amber. The
/// lifeboat comes home, the grandmother is helped down off the breakwater, the town's lanterns go home along it one by
/// one, and back up the lighthouse stair to where she fell. Each scene's night carries on from the one before: its
/// held-back sky is the last scene's played one, and the rain thickens as the night winds back.
///
/// A scene is drawn as the harbour is: single-weight line on black, baked held back and played, every difference
/// between the two, glow included, inside its own rod's core, clear of the knob and of the core's edge.
enum Rescue: Int, CaseIterable, Sendable {
    case homeLight = 6, breakwater, chain, stair, door

    static let line = Harbour.line
    /// Every vignette's glow, held tight so a beat's light stays well inside its core.
    static let tight: [(blur: Double, opacity: Double)] = [(0.016, 0.45), (0.006, 0.9)]

    static let sky = Color(0x05050F)
    static let cloud = Color(0x3A3550)
    static let torch = Color(0xFFB347)
    static let flame = Color(0xFFE2A0)
    /// The rain's colour, and at full strength the chapter's line ink.
    static let ink = Color(0xB7CEFF)

    var title: String {
        ["Home light", "Off the breakwater", "The lantern chain", "The stair", "The lighthouse door"][rawValue - 6]
    }

    var layout: Layout { [.pent, .eye, .quad, .tri, .pent][rawValue - 6] }

    /// Par, the entry count, is each one's optimum, and plain untwisting reaches it (`testFirstStirParIsTheOptimum`).
    var scramble: String {
        [
            // Every vignette clear of the other discs, so any order plays them whole.
            "1:+3,0:-4,2:+5,4:-3,3:+4,0:+2",
            // The steps' rod (0) at the bottom, below both of the lifeboat's (1): the father and the grandmother come
            // back down only once the boat is still.
            "0:+4,3:-3,1:+5,2:-4,1:-2,3:+3",
            "3:+4,0:-3,1:+5,2:-2,3:-5,0:+2,1:-3",
            // The turn of the stair (0) at the bottom, so she is found sitting there last.
            "0:+4,1:-3,2:+5,1:+4,2:-3,1:-5,2:+2",
            "3:-4,1:+3,0:+5,4:-2,2:+4,1:-5,3:+2",
        ][rawValue - 6]
    }

    var vignettes: Set<Int> { [[0, 4, 2], [0, 1, 2], [3, 0, 1], [0, 1, 2], [0, 1, 3]][rawValue - 6] }

    /// The chapter's window, minutes after midnight, 4:45 back to 2:30: each scene's played time is the next one's
    /// held-back time, and its first is Dawn After's last.
    static let times: [Double] = [Dawn.times.last!, 255, 230, 205, 180, 150]
    var late: Double { Self.times[rawValue - 6] }
    var early: Double { Self.times[rawValue - 5] }

    /// How far the chapter has wound back at `minutes`: 0 at 4:45, 1 at 2:30.
    static func back(_ minutes: Double) -> Double { min(max((times[0] - minutes) / (times[0] - times.last!), 0), 1) }

    // MARK: The time layer

    /// The rain, one field over everything but a roof: in a random order, so the first n are an even thickening.
    static let drops: [(x: Double, y: Double, l: Double)] = {
        var drops = SplitMix64(state: 61)
        return (0..<340).map { _ in
            (Double.random(in: -1.1..<1.1, using: &drops), Double.random(in: -1.1..<1.0, using: &drops),
             Double.random(in: 0.035..<0.08, using: &drops))
        }
    }()
    static let slant = 22 * Double.pi / 180
    /// How far the rain climbs back up its slant per minute wound back, in tank radii.
    static let climb = 0.09

    /// Drops falling at `minutes`, the last one partly: the rain eases towards the dawn.
    static func rain(_ minutes: Double) -> Double { 110 + 210 * back(minutes) }

    /// The rain over the whole picture, played cores and all, at `minutes`: it climbs back up its slant as the night
    /// winds back, so a rewind moves it, and thickens.
    func drawOver(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: r + x * r, y: r + y * r) }
        let style = StrokeStyle(lineWidth: Self.line * r, lineCap: .round, lineJoin: .round)
        var c = ctx
        if let roofed = indoors {
            c.clip(to: roofed(Brush(ctx: ctx, r: r)))
        }
        let climbed = Self.climb * (Self.times[0] - minutes), shown = Self.rain(minutes), whole = Int(shown)
        func wrap(_ v: Double) -> Double { (v + 1.1).truncatingRemainder(dividingBy: 2.2) + (v + 1.1 < 0 ? 2.2 : 0) - 1.1 }
        var steady = Path(), last = Path()
        for (i, d) in Self.drops.prefix(whole + 1).enumerated() {
            let x = wrap(d.x - climbed * sin(Self.slant)), y = wrap(d.y - climbed * cos(Self.slant))
            let streak = Path { $0.move(to: p(x, y)); $0.addLine(to: p(x + d.l * sin(Self.slant), y + d.l * cos(Self.slant))) }
            if i < whole { steady.addPath(streak) } else { last.addPath(streak) }
        }
        c.stroke(steady, with: .color(Self.ink.opacity(0.2)), style: style)
        c.stroke(last, with: .color(Self.ink.opacity(0.2 * (shown - Double(whole)))), style: style)
    }

    /// Where an indoor scene's rain may fall: only through its windows.
    var indoors: ((Brush) -> Path)? {
        self == .stair ? { pen in Stair.windows(pen) } : nil
    }

    /// How far the sky has turned from Dawn After's at 4:45 to the chapter's own: wholly by the end of the first scene,
    /// so that scene opens on the sky the last one ended on.
    static func turned(_ minutes: Double) -> Double {
        let x = min(back(minutes) / back(times[1]), 1)
        return x * x * (3 - 2 * x)
    }

    /// The sky's tones from the zenith down to the horizon at `minutes` (the middle one at `Dawn.middle`): low cloud lit
    /// from below by the town, fading as the night winds back towards the rain's height, turned from the dawn's sky at
    /// 4:45.
    static func skyTones(_ minutes: Double) -> [Tone] {
        let lit = 0.75 - 0.5 * back(minutes), dawn = Dawn.tones(times[0]), night = Tone(0x05050F), cloud = Tone(0x3A3550)
        return zip([dawn.zenith, dawn.middle, dawn.low], [night, night.mix(cloud, lit * 0.35), night.mix(cloud, lit)])
            .map { $0.mix($1, turned(minutes)) }
    }

    static func skyStops(_ minutes: Double) -> [Gradient.Stop] {
        zip(skyTones(minutes), [0, CGFloat(Dawn.middle), 1]).map { .init(color: $0.color, location: $1) }
    }

    /// The sea's tones at the horizon and halfway to the viewer, turned from the dawn's as the sky is, then black.
    static func seaTones(_ minutes: Double) -> [Tone] {
        let dawn = Dawn.tones(times[0]).sea, t = turned(minutes), sea = Tone(0x0E3A40)
        return [dawn.mix(sea.scaled(0.7), t), dawn.scaled(0.5).mix(sea.scaled(0.25), t), Tone(0)]
    }

    func drawSky(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        let pen = Brush(ctx: ctx, r: r)
        if self == .stair {
            Stair.sky(pen, minutes: minutes)
        } else {
            Self.outside(pen, minutes: minutes, horizon: horizon)
        }
    }

    func draw(_ ctx: GraphicsContext, r: CGFloat, played: Set<Int>) {
        let pen = Brush(ctx: ctx, r: r)
        switch self {
        case .homeLight: HomeLight.draw(pen, played: played)
        case .breakwater: OffTheBreakwater.draw(pen, played: played)
        case .chain: LanternChain.draw(pen, played: played)
        case .stair: Stair.draw(pen, played: played)
        case .door: LighthouseDoor.draw(pen, played: played)
        }
    }

    var horizon: Double { [-0.66, -0.3, -0.62, 0, -0.70][rawValue - 6] }

    /// The sky over the sea, the night's swell under it, darkening towards the viewer.
    static func outside(_ pen: Brush, minutes: Double, horizon: Double) {
        pen.fill(pen.rect(-1, -1, 1, 1), .black)
        pen.fill(pen.rect(-1, -1, 1, horizon), .linearGradient(Gradient(stops: skyStops(minutes)),
                                                                         startPoint: pen.point(0, -1), endPoint: pen.point(0, horizon)))
        pen.fill(pen.rect(-1, horizon, 1, 1), .linearGradient(
            Gradient(colors: seaTones(minutes).map(\.color)), startPoint: pen.point(0, horizon), endPoint: pen.point(0, 1)))
        var swell = Path()
        var rng = SplitMix64(state: 43)
        for k in 1...10 {
            let t = Double(k) / 10, y = horizon + 0.012 + (1 - horizon) * 0.98 * pow(t, 1.7)
            let amp = 0.003 + 0.022 * t, wave = 0.05 + 0.22 * t, phase = Double.random(in: 0..<6.3, using: &rng)
            swell.addPath(pen.path { s in
                s.move(to: CGPoint(x: -1.05, y: y))
                for x in stride(from: -1.05, through: 1.05, by: 0.01) {
                    s.addLine(to: CGPoint(x: x, y: y - amp * sin(x / wave * 2 * .pi + phase)))
                }
            })
        }
        pen.lit([(0.02, 0.25), (0.007, 0.6)]) { g in
            var s = g
            s.ctx.clip(to: g.rect(-1, horizon, 1, 1))
            s.ctx.stroke(swell, with: .linearGradient(Gradient(colors: [ink.opacity(0.04), ink.opacity(0.16)]),
                                                     startPoint: g.point(0, horizon), endPoint: g.point(0, 0.9)), style: g.style)
            g.stroke(g.seg(-1, horizon, 1, horizon), ink, 0.45)
        }
    }

    /// Low cloud, flat-bellied and heaped on top, so a core of sky knows which way is up.
    static func clouds(_ pen: Brush, _ banks: [(x0: Double, x1: Double, y: Double, h: Double)]) {
        var clouds = Path()
        for (x0, x1, y, h) in banks {
            clouds.addPath(pen.path { c in
                c.move(to: CGPoint(x: x0, y: y))
                var x = x0, k = 0
                while x < x1 - 0.01 {
                    let w = min([0.11, 0.16, 0.09, 0.14][k % 4] * (h / 0.06), x1 - x)
                    c.addQuadCurve(to: CGPoint(x: x + w, y: y), control: CGPoint(x: x + w / 2, y: y - h * [1.5, 2.1, 1.2, 1.8][k % 4]))
                    x += w; k += 1
                }
                c.closeSubpath()
            })
        }
        pen.fill(clouds, .black, 0.5)
        pen.lit([(0.03, 0.3), (0.008, 0.6)]) { $0.stroke(clouds, cloud, 0.9) }
    }
}

/// A pen on tank units (x right, y down, the glass's radius 1) that a figure can be drawn through in its own units.
struct Brush {
    var ctx: GraphicsContext
    let r: CGFloat
    /// From the units being drawn in to tank units.
    var t = CGAffineTransform.identity
    /// Where what is drawn is clipped to, in pixels.
    var clip: Path?
    /// Collects a vignette's drawing, to be laid down under one glow: see `vignette`.
    var sketch: Sketch?

    final class Sketch {
        var ops: [(path: Path, shading: GraphicsContext.Shading, stroke: Bool, clip: Path?, blur: Double)] = []
    }

    private var px: CGAffineTransform { t.concatenating(CGAffineTransform(a: r, b: 0, c: 0, d: r, tx: r, ty: r)) }
    var style: StrokeStyle { StrokeStyle(lineWidth: Rescue.line * r, lineCap: .round, lineJoin: .round) }

    /// The same pen drawing in units `k` tank radii long from (x, y), mirrored when `flip`, turned by `turn`.
    func at(_ x: Double, _ y: Double, k: Double = 1, flip: Bool = false, turn: Double = 0) -> Brush {
        var q = self
        q.t = CGAffineTransform(scaleX: flip ? -k : k, y: k).concatenating(CGAffineTransform(rotationAngle: turn))
            .concatenating(CGAffineTransform(translationX: x, y: y)).concatenating(t)
        return q
    }

    func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y).applying(px) }
    func path(_ build: (inout Path) -> Void) -> Path { var p = Path(); build(&p); return p.applying(px) }
    func poly(_ pts: [(Double, Double)], closed: Bool = true) -> Path {
        path { p in
            p.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
            for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
            if closed { p.closeSubpath() }
        }
    }
    func seg(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double) -> Path { poly([(ax, ay), (bx, by)], closed: false) }
    func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Path {
        path { $0.addRect(CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)) }
    }
    func circle(_ x: Double, _ y: Double, _ radius: Double) -> Path { ellipse(x, y, radius, radius) }
    func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> Path {
        path { $0.addEllipse(in: CGRect(x: x - rx, y: y - ry, width: 2 * rx, height: 2 * ry)) }
    }
    func curve(_ ax: Double, _ ay: Double, _ cx: Double, _ cy: Double, _ bx: Double, _ by: Double) -> Path {
        path { $0.move(to: CGPoint(x: ax, y: ay)); $0.addQuadCurve(to: CGPoint(x: bx, y: by), control: CGPoint(x: cx, y: cy)) }
    }

    func fill(_ path: Path, _ colour: Color, _ opacity: Double = 1) { fill(path, .color(colour.opacity(opacity))) }
    func fill(_ path: Path, _ shading: GraphicsContext.Shading) { put(path, shading, stroke: false) }
    func stroke(_ path: Path, _ colour: Color, _ opacity: Double = 1) { put(path, .color(colour.opacity(opacity)), stroke: true) }

    private func put(_ path: Path, _ shading: GraphicsContext.Shading, stroke: Bool, blur: Double = 0) {
        if let sketch {
            sketch.ops.append((path, shading, stroke, clip, blur))
            return
        }
        Self.lay(ctx, path, shading, stroke: stroke, clip: clip, blur: blur * r, style: style)
    }

    private static func lay(_ ctx: GraphicsContext, _ path: Path, _ shading: GraphicsContext.Shading, stroke: Bool, clip: Path?,
                            blur: CGFloat, style: StrokeStyle) {
        var c = ctx
        if let clip { c.clip(to: clip) }
        if blur > 0 { c.addFilter(.blur(radius: blur)) }
        if stroke { c.stroke(path, with: shading, style: style) } else { c.fill(path, with: shading) }
    }

    /// The same pen clipped to `path`, in the units being drawn in.
    func clipped(to path: Path) -> Brush {
        var q = self
        q.clip = clip.map { $0.intersection(path) } ?? path
        return q
    }

    /// Strokes with the neon glow; inside a vignette, the vignette's one glow.
    func lit(_ glows: [(blur: Double, opacity: Double)] = [(0.03, 0.4), (0.008, 1.0)], _ draw: (Brush) -> Void) {
        if sketch != nil { return draw(self) }
        neon(ctx, r: r, glows: glows) { g in
            var q = self
            q.ctx = g
            draw(q)
        }
    }

    /// Vignette `rod`'s state, laid down whole under one tight glow.
    func vignette(_ rod: Int, _ draw: (Brush) -> Void) {
        let sketch = Sketch()
        var q = self
        q.sketch = sketch
        draw(q)
        neon(ctx, r: r, glows: Rescue.tight) { g in
            for op in sketch.ops where op.blur == 0 { Self.lay(g, op.path, op.shading, stroke: op.stroke, clip: op.clip, blur: 0, style: style) }
        }
        for op in sketch.ops where op.blur > 0 { Self.lay(ctx, op.path, op.shading, stroke: op.stroke, clip: op.clip, blur: op.blur * r, style: style) }
    }

    /// A soft round of light about `radius` across at (x, y): a flat fill under a blur, as the neon glow is, since the art
    /// spec allows no gradient but the sky and sea.
    func glow(_ x: Double, _ y: Double, _ radius: Double, _ colour: Color, _ strength: Double) {
        put(circle(x, y, radius * 0.4), .color(colour.opacity(strength)), stroke: false,
            blur: radius * 0.28 * (t.a * t.a + t.b * t.b).squareRoot())
    }
}

/// The chapter's people and things, each drawn in its own units through `Brush.at`: a figure stands on (0, 0) and is 1
/// tall, facing right (mirror it to face left); a boat floats on y = 0, 1 long, its bow to the right. Silhouettes are
/// black inside one outline, so the family are told apart by outline alone: the father's oilskin and wide-brimmed hat,
/// the grandmother's shawl, bun and long skirt, the child's bobble hat (drawn at about two thirds an adult's height),
/// a neighbour's cap and a lifeboat crewman's hood and life jacket.
enum Cast {
    enum Who { case father, grandmother, child, neighbour, crew }

    /// One limb's polyline in the figure's units, from the shoulder.
    typealias Limb = [(Double, Double)]
    static let armsDown: [Limb] = [[(-0.1, -0.74), (-0.13, -0.5), (-0.12, -0.36)], [(0.1, -0.74), (0.13, -0.5), (0.12, -0.36)]]

    static func figure(_ pen: Brush, _ who: Who, arms: [Limb] = armsDown, legs: [Limb]? = nil, colour: Color = Rescue.ink,
                       glows: [(blur: Double, opacity: Double)] = Rescue.tight) {
        var body = Path(), lines = Path()
        func add(_ p: Path) { body.addPath(p); lines.addPath(p) }
        let stride: [Limb]
        switch who {
        case .father:
            add(pen.circle(0, -0.85, 0.07))
            add(pen.poly([(-0.07, -0.9), (-0.06, -1.0), (0.06, -1.0), (0.07, -0.9)]))
            lines.addPath(pen.curve(-0.17, -0.86, 0, -0.95, 0.17, -0.86))
            add(pen.poly([(-0.1, -0.77), (0.1, -0.77), (0.15, -0.3), (-0.15, -0.3)]))
            stride = [[(-0.05, -0.3), (-0.06, 0)], [(0.05, -0.3), (0.06, 0)]]
        case .grandmother:
            add(pen.circle(0, -0.84, 0.07))
            add(pen.circle(-0.08, -0.89, 0.035))
            add(pen.poly([(-0.08, -0.72), (0.08, -0.72), (0.16, 0), (-0.16, 0)]))
            add(pen.poly([(-0.13, -0.76), (0.13, -0.76), (0.1, -0.6), (0, -0.48), (-0.1, -0.6)]))
            stride = []
        case .child:
            add(pen.circle(0, -0.78, 0.1))
            add(pen.path { h in
                h.move(to: CGPoint(x: -0.11, y: -0.8)); h.addQuadCurve(to: CGPoint(x: 0.11, y: -0.8), control: CGPoint(x: 0, y: -1.02))
                h.closeSubpath()
            })
            add(pen.circle(0, -0.95, 0.045))
            add(pen.poly([(-0.1, -0.66), (0.1, -0.66), (0.14, -0.32), (-0.14, -0.32)]))
            stride = [[(-0.06, -0.32), (-0.06, 0)], [(0.06, -0.32), (0.06, 0)]]
        case .neighbour:
            add(pen.circle(0, -0.86, 0.07))
            add(pen.path { c in
                c.move(to: CGPoint(x: -0.075, y: -0.87)); c.addQuadCurve(to: CGPoint(x: 0.07, y: -0.89), control: CGPoint(x: 0, y: -0.98))
                c.addLine(to: CGPoint(x: 0.14, y: -0.87)); c.closeSubpath()
            })
            add(pen.poly([(-0.1, -0.77), (0.1, -0.77), (0.12, -0.4), (-0.12, -0.4)]))
            stride = [[(-0.05, -0.4), (-0.06, 0)], [(0.05, -0.4), (0.06, 0)]]
        case .crew:
            add(pen.circle(0.01, -0.86, 0.09))
            lines.addPath(pen.circle(0.02, -0.855, 0.055))
            add(pen.poly([(-0.14, -0.76), (0.14, -0.76), (0.13, -0.46), (-0.13, -0.46)]))
            stride = [[(-0.06, -0.46), (-0.07, 0)], [(0.06, -0.46), (0.07, 0)]]
        }
        for limb in (legs ?? stride) + arms { lines.addPath(pen.poly(limb, closed: false)) }
        pen.fill(body, .black)
        pen.lit(glows) { $0.stroke(lines, colour) }
    }

    /// A dog standing on (0, 0), its body 1 long, facing right; `ears` up or down.
    static func dog(_ pen: Brush, ears up: Bool = true, nose: Double = 0, colour: Color = Rescue.ink,
                    glows: [(blur: Double, opacity: Double)] = Rescue.tight) {
        let head = pen.circle(0.46, -0.7 + nose, 0.14)
        let body = pen.ellipse(0, -0.46, 0.38, 0.17)
        let ears = up ? pen.poly([(0.38, -0.78 + nose), (0.42, -0.95 + nose), (0.5, -0.8 + nose)])
            : pen.poly([(0.38, -0.78 + nose), (0.3, -0.62 + nose), (0.42, -0.72 + nose)])
        var lines = Path()
        lines.addPath(body)
        lines.addPath(head)
        lines.addPath(ears)
        for x in [-0.28, -0.16, 0.16, 0.28] { lines.addPath(pen.seg(x, -0.36, x + 0.01, 0)) }
        lines.addPath(pen.curve(-0.36, -0.52, -0.5, -0.6, -0.55, -0.82))
        pen.fill(body, .black)
        pen.fill(head, .black)
        pen.fill(ears, .black)
        pen.lit(glows) { $0.stroke(lines, colour) }
    }

    /// A storm lantern on its base at (0, 0), 1 tall.
    static func lantern(_ pen: Brush, lit: Bool, glows: [(blur: Double, opacity: Double)] = Rescue.tight) {
        var cage = Path()
        cage.addPath(pen.seg(-0.32, 0, 0.32, 0))
        cage.addPath(pen.poly([(-0.26, 0), (-0.22, -0.62), (0.22, -0.62), (0.26, 0)], closed: false))
        cage.addPath(pen.poly([(-0.28, -0.62), (-0.12, -0.8), (0.12, -0.8), (0.28, -0.62)], closed: false))
        cage.addPath(pen.curve(-0.2, -0.84, 0, -1.12, 0.2, -0.84))
        pen.lit(glows) { g in
            if lit { g.fill(g.ellipse(0, -0.3, 0.17, 0.21), Rescue.flame) }
            g.stroke(cage, lit ? Rescue.torch : Rescue.ink)
        }
    }

    /// The lifeboat afloat on y = 0, bow right: a high bow, a wheelhouse, a mast with its lamp, and a searchlight on
    /// the wheelhouse roof whose beam shines ahead when `beam`.
    static func lifeboat(_ pen: Brush, beam: Bool = false, reach: Double = 0.6, glows: [(blur: Double, opacity: Double)] = Rescue.tight) {
        let hull = pen.path { h in
            h.move(to: CGPoint(x: -0.5, y: -0.12))
            h.addLine(to: CGPoint(x: 0.3, y: -0.13))
            h.addQuadCurve(to: CGPoint(x: 0.52, y: -0.28), control: CGPoint(x: 0.45, y: -0.15))
            h.addQuadCurve(to: CGPoint(x: 0.32, y: 0.04), control: CGPoint(x: 0.5, y: -0.02))
            h.addLine(to: CGPoint(x: -0.42, y: 0.04))
            h.addQuadCurve(to: CGPoint(x: -0.5, y: -0.12), control: CGPoint(x: -0.5, y: 0.02))
        }
        let house = pen.rect(-0.28, -0.36, 0.08, -0.13)
        var lines = Path()
        lines.addPath(hull)
        lines.addPath(house)
        lines.addPath(pen.seg(-0.44, -0.05, 0.42, -0.06))
        lines.addPath(pen.seg(-0.1, -0.36, -0.1, -0.62))
        lines.addPath(pen.seg(-0.18, -0.52, -0.02, -0.52))
        pen.fill(hull, .black)
        pen.fill(house, .black)
        pen.lit(glows) { g in
            g.stroke(lines, Rescue.ink)
            g.fill(g.rect(-0.22, -0.3, -0.12, -0.21), Rescue.torch, 0.8)
            g.fill(g.rect(-0.06, -0.3, 0.03, -0.21), Rescue.torch, 0.8)
            g.fill(g.circle(-0.1, -0.66, 0.035), Rescue.flame)
            g.stroke(g.rect(0.0, -0.44, 0.08, -0.37), Rescue.torch)
        }
        if beam {
            let tip = 0.08 + reach
            pen.fill(pen.poly([(0.08, -0.43), (tip, -0.43 - reach * 0.25), (tip, -0.38 + reach * 0.25), (0.08, -0.38)]), Rescue.flame, 0.3)
        }
    }

    /// A wave breaking towards the right, 1 wide on the water at y = 0: its back, the crest and the lip curling over a
    /// dark hollow, and spray thrown off it.
    static func breaker(_ pen: Brush, glows: [(blur: Double, opacity: Double)] = [(0.03, 0.35), (0.008, 0.9)]) {
        let face = pen.path { b in
            b.move(to: CGPoint(x: -0.5, y: 0))
            b.addQuadCurve(to: CGPoint(x: 0.12, y: -0.3), control: CGPoint(x: -0.12, y: -0.04))
            b.addQuadCurve(to: CGPoint(x: 0.4, y: -0.16), control: CGPoint(x: 0.36, y: -0.34))
            b.addQuadCurve(to: CGPoint(x: 0.28, y: -0.1), control: CGPoint(x: 0.36, y: -0.06))
            b.addQuadCurve(to: CGPoint(x: 0.5, y: 0), control: CGPoint(x: 0.3, y: 0))
        }
        var lines = Path()
        lines.addPath(face)
        for (x, y, a) in [(0.18, -0.36, -1.3), (0.3, -0.33, -0.7), (0.06, -0.34, -1.9)] {
            lines.addPath(pen.seg(x, y, x + 0.07 * cos(a), y + 0.07 * sin(a)))
        }
        pen.fill(face, .black, 0.6)
        pen.lit(glows) { $0.stroke(lines, Rescue.ink, 0.8) }
    }
}

/// Scene 6, 4:45 back to 4:15, on pent: the harbour mouth from the quay, the cottage's gable on the left, the
/// lifeboat house's door on the right. Rod 0, the harbour mouth: the lifeboat just inside, nearly home, then outside high
/// on a swell, its searchlight out. Rod 4, the upstairs window: the torch left on the sill pointing out, then the child
/// holding it out with the dog's ears at the sill. Rod 2, the quay steps: a neighbour holding out blankets, then two
/// carrying them out of the doorway.
enum HomeLight {
    static let horizon = -0.66
    static let quay = 0.28
    /// Where people stand on the quay, level with rod 2's knob so a figure keeps clear of it either side.
    static let ground = 0.515
    static let window = (x0: -0.45, y0: -0.27, x1: -0.34, y1: -0.1)

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Rescue.ink
        Rescue.clouds(pen, [(-1, -0.3, -0.8, 0.05), (0.25, 1, -0.86, 0.05), (-0.45, 0.2, -0.95, 0.04)])

        // The breakwaters: the far one from the right, the lighthouse dark on its end; the near one from behind the
        // cottage. The mouth between them lies right of rod 0's knob.
        let far = pen.poly([(0.22, -0.6), (1, -0.53), (1, -0.48), (0.22, -0.575)])
        let near = pen.poly([(-0.34, -0.52), (0.1, -0.54), (0.1, -0.515), (-0.34, -0.49)])
        let tower = pen.poly([(0.24, -0.595), (0.258, -0.86), (0.302, -0.86), (0.32, -0.59)])
        pen.fill(far, .black); pen.fill(near, .black); pen.fill(tower, .black)
        var stone = Path()
        stone.addPath(far); stone.addPath(near); stone.addPath(tower)
        stone.addPath(pen.seg(0.24, -0.86, 0.32, -0.86))
        stone.addPath(pen.rect(0.256, -0.91, 0.304, -0.86))
        stone.addPath(pen.curve(0.25, -0.91, 0.28, -0.95, 0.31, -0.91))
        stone.addPath(pen.seg(0.1, -0.54, 0.1, -0.575))
        pen.lit { $0.stroke(stone, ink, 0.8) }

        // The family's boat, keel up at its mooring since midnight, and its buoy.
        let hull = pen.path { h in
            h.move(to: CGPoint(x: 0.5, y: -0.04))
            h.addQuadCurve(to: CGPoint(x: 0.64, y: -0.1), control: CGPoint(x: 0.52, y: -0.1))
            h.addQuadCurve(to: CGPoint(x: 0.78, y: -0.045), control: CGPoint(x: 0.76, y: -0.1))
            h.closeSubpath()
        }
        pen.fill(hull, .black)
        pen.lit { g in
            g.stroke(hull, ink)
            g.stroke(g.seg(0.64, -0.1, 0.64, -0.125), ink)
            g.stroke(g.poly([(0.84, -0.03), (0.85, -0.065), (0.875, -0.065), (0.885, -0.03)]), ink, 0.8)
        }

        // The cottage's gable end on the quay, its chimney, a dark ground floor.
        let gable = pen.poly([(-1, -0.36), (-0.66, -0.62), (-0.32, -0.36), (-0.32, quay), (-1, quay)])
        pen.fill(gable, .black)
        pen.fill(pen.rect(-0.86, -0.62, -0.78, -0.48), .black)
        var house = Path()
        house.addPath(pen.poly([(-1, -0.36), (-0.66, -0.62), (-0.32, -0.36), (-0.32, quay)], closed: false))
        house.addPath(pen.poly([(-0.86, -0.51), (-0.86, -0.62), (-0.78, -0.62), (-0.78, -0.57)], closed: false))
        house.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
        house.addPath(pen.seg(window.x0 - 0.01, window.y1 + 0.012, window.x1 + 0.01, window.y1 + 0.012))
        house.addPath(pen.rect(-0.74, -0.25, -0.65, -0.11))
        house.addPath(pen.rect(-0.7, 0.06, -0.6, quay))
        house.addPath(pen.rect(-0.5, 0.08, -0.4, 0.19))
        pen.lit { $0.stroke(house, ink) }

        // The quay: its edge, stone courses, steps down to the water left of rod 2's knob, and the lifeboat house on the
        // right, its door open and lit.
        pen.fill(pen.rect(-1, quay, 1, 1), .black)
        var quayside = Path()
        quayside.addPath(pen.seg(-0.32, quay, 1, quay))
        quayside.addPath(pen.seg(-1, 0.36, 1, 0.36))
        for (i, x) in Swift.stride(from: -0.3, to: 1, by: 0.12).enumerated() {
            quayside.addPath(pen.seg(x + (i % 2 == 0 ? 0 : 0.06), quay, x + (i % 2 == 0 ? 0 : 0.06), 0.36))
        }
        for k in 0..<4 {
            let y = 0.36 + 0.045 * Double(k)
            quayside.addPath(pen.seg(0.09 + 0.03 * Double(k), y, 0.2 + 0.03 * Double(k), y))
        }
        quayside.addPath(pen.seg(0.09, 0.36, 0.17, ground))
        let shed = pen.poly([(0.42, ground), (0.42, 0.3), (0.72, 0.22), (1, 0.3), (1, ground)])
        let door = pen.rect(0.44, 0.38, 0.54, ground)
        pen.fill(shed, .black)
        pen.fill(door, Rescue.torch, 0.35)
        quayside.addPath(pen.seg(-1, ground, 1, ground))
        // A crate of blankets waiting by a bollard, its rope coiled, in rod 3's core.
        quayside.addPath(pen.rect(-0.3, 0.47, -0.17, 0.53))
        for y in [0.455, 0.44] { quayside.addPath(pen.seg(-0.29 + (0.455 - y), y, -0.18, y)) }
        quayside.addPath(pen.poly([(-0.5, 0.53), (-0.5, 0.47), (-0.515, 0.46), (-0.445, 0.46), (-0.46, 0.47), (-0.46, 0.53)],
                                  closed: false))
        quayside.addPath(pen.ellipse(-0.4, 0.52, 0.04, 0.012))
        quayside.addPath(pen.ellipse(-0.4, 0.512, 0.03, 0.009))
        // The quay's flags running towards the viewer, so its foreground is ground.
        var flags = Path()
        for x in Swift.stride(from: -1.5, through: 1.5, by: 0.3) { flags.addPath(pen.seg(x * 0.55, 0.6, x, 1)) }
        for y in [0.6, 0.78] { flags.addPath(pen.seg(-1, y, 1, y)) }
        pen.lit { g in
            g.stroke(flags, ink, 0.22)
            g.stroke(quayside, ink, 0.7)
            g.stroke(shed, ink)
            g.stroke(door, Rescue.torch)
        }

        // Vignette 0, the harbour mouth.
        pen.vignette(0) { pen in
            if played.contains(0) {
                Rescue.swellUnder(pen, x: 0.11, y: -0.665, w: 0.12)
                Cast.lifeboat(pen.at(0.1, -0.675, k: 0.12, turn: -0.15), beam: true, reach: 0.08)
            } else {
                Cast.lifeboat(pen.at(0.11, -0.445, k: 0.12), beam: true, reach: 0.08)
            }
        }

        // Vignette 4, the upstairs window.
        pen.vignette(4) { pen in
            // The pane's left edge kept a little further in, so its glow stays clear of the knob.
            let inside = pen.clipped(to: pen.rect(window.x0 + 0.014, window.y0 + 0.004, window.x1 - 0.004, window.y1 - 0.004))
            if played.contains(4) {
                inside.fill(inside.rect(window.x0, window.y0, window.x1, window.y1), Rescue.torch, 0.22)
                Cast.figure(inside.at(-0.385, -0.0, k: 0.2), .child,
                            arms: [[(0.1, -0.62), (0.3, -0.62), (0.4, -0.66)], [(-0.1, -0.62), (-0.13, -0.42)]])
                Cast.dog(inside.at(-0.43, -0.06, k: 0.1))
                Rescue.torchlight(pen, x: -0.335, y: -0.135, k: 0.035, beam: 0.02)
            } else {
                Rescue.torchlight(pen, x: -0.38, y: window.y1 - 0.009, k: 0.035, beam: 0.04)
            }
        }

        // Vignette 2, the quay steps.
        pen.vignette(2) { pen in
            if played.contains(2) {
                Cast.figure(pen.at(0.46, ground, k: 0.125), .neighbour, arms: [[(0.1, -0.72), (0.16, -0.52), (0.24, -0.5)]])
                Cast.figure(pen.at(0.52, ground, k: 0.125, flip: true), .neighbour, arms: [[(0.1, -0.72), (0.16, -0.52), (0.24, -0.5)]])
                Rescue.blankets(pen, x: 0.49, y: 0.455, w: 0.05)
            } else {
                Cast.figure(pen.at(0.205, ground, k: 0.13, flip: true), .neighbour,
                            arms: [[(0.1, -0.72), (0.3, -0.62)], [(-0.1, -0.72), (0.2, -0.6)]])
                Rescue.blankets(pen, x: 0.16, y: 0.44, w: 0.05)
            }
        }
    }
}

extension Rescue {
    /// A hump of swell under a boat riding it.
    static func swellUnder(_ pen: Brush, x: Double, y: Double, w: Double) {
        let crest = pen.curve(x - w / 2, y + 0.02, x, y - 0.03, x + w / 2, y + 0.02)
        pen.lit(tight) { $0.stroke(crest, ink, 0.8) }
    }

    /// A hand torch at (x, y), pointing right, `k` long, its beam `beam` on beyond the lens.
    static func torchlight(_ pen: Brush, x: Double, y: Double, k: Double, beam: Double) {
        let body = pen.rect(x - k, y - k * 0.3, x, y + k * 0.3)
        pen.fill(pen.poly([(x, y - k * 0.3), (x + beam, y - k * 0.3 - beam * 0.35), (x + beam, y + k * 0.3 + beam * 0.35), (x, y + k * 0.3)]),
                 torch, 0.3)
        pen.fill(body, .black)
        pen.lit(tight) { g in
            g.stroke(body, ink)
            g.stroke(g.seg(x, y - k * 0.42, x, y + k * 0.42), torch)
        }
    }

    /// A folded stack of blankets held at (x, y), `w` wide.
    static func blankets(_ pen: Brush, x: Double, y: Double, w: Double) {
        var lines = Path()
        let stack = pen.rect(x - w / 2, y - w * 0.4, x + w / 2, y + w * 0.1)
        lines.addPath(stack)
        lines.addPath(pen.seg(x - w / 2, y - w * 0.15, x + w / 2, y - w * 0.15))
        pen.fill(stack, .black)
        pen.lit(tight) { $0.stroke(lines, torch) }
    }
}

extension Level {
    /// The Rescue's scenes in story order, numbered by place in `firstStir`.
    static let rescue: [Level] = Rescue.allCases.map { scene in
        Level(id: "", pack: .firstStir, label: "", title: scene.title, note: "", layout: scene.layout,
              scramble: .parse(scene.scramble, in: scene.layout), story: .rescue(scene))
    }
}

/// Scene 7, 4:15 back to 3:50, on eye: the breakwater's end in surf, its seaward face with steps cut down it to the
/// water, the lighthouse dark on its end. Rod 0, the steps: empty, a rope hanging and the surf over the lower steps, then the
/// father helping the grandmother down. Rod 1, the lifeboat: alongside the steps' foot, two crew reaching up, then further off,
/// bow high on a wave. Rod 2, the lighthouse: dark, then a glow at the stair window from the lamp she left.
enum OffTheBreakwater {
    static let top = -0.36, water = 0.12

    /// The steps' foot, at the water inside the lifeboat's core, so the boat waiting there lies alongside them, clear of
    /// the steps' disc.
    static let foot = 0.17
    /// The steps' nosings, top left down to the foot.
    static func step(_ x: Double) -> Double { water + (x - foot) * 0.45 }
    /// Where the steps leave the breakwater's top.
    static let head = foot - (water - top - 0.06) / 0.45

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Rescue.ink
        Rescue.clouds(pen, [(-1, -0.35, -0.72, 0.05), (0.3, 1, -0.62, 0.05), (-0.4, 0.05, -0.92, 0.04), (0.35, 0.9, -0.9, 0.04)])

        // The breakwater from the left, its end under the lighthouse; its face down to the water.
        let wall = pen.poly([(-1, top), (0.27, top), (0.27, water), (-1, water)])
        pen.fill(wall, .black)
        var stone = Path()
        stone.addPath(wall)
        stone.addPath(pen.seg(-1, top + 0.03, 0.27, top + 0.03))
        for (i, y) in Swift.stride(from: top + 0.11, to: water - 0.02, by: 0.08).enumerated() {
            stone.addPath(pen.seg(-1, y, 0.27, y))
            for x in Swift.stride(from: -0.98 + (i % 2 == 0 ? 0 : 0.07), to: 0.26, by: 0.14) {
                stone.addPath(pen.seg(x, y, x, y + 0.08 > water ? water : y + 0.08))
            }
        }
        // The steps, cut into the face from the top down to the water, a rail post at their head.
        var steps = Path()
        let tread = (foot - head) / 18
        steps.addPath(pen.seg(head, step(head), foot, step(foot)))
        for x in (0..<18).map({ head + tread * Double($0) }) {
            steps.addPath(pen.poly([(x, step(x)), (x + tread, step(x)), (x + tread, step(x + tread))], closed: false))
        }
        steps.addPath(pen.poly([(head - 0.02, top), (head - 0.02, top - 0.06), (head + 0.04, top - 0.06)], closed: false))
        pen.fill(pen.poly([(head, step(head)), (foot, step(foot)), (foot, step(foot) + 0.04), (head, step(head) + 0.04)]), .black)
        pen.lit { g in
            g.stroke(stone, ink, 0.55)
            g.stroke(steps, ink)
        }

        // The lighthouse on the end, its door shut and its stair window dark.
        let tower = pen.poly([(0.1, top), (0.125, -0.8), (0.215, -0.8), (0.24, top)])
        pen.fill(tower, .black)
        var house = Path()
        house.addPath(tower)
        house.addPath(pen.seg(0.09, -0.8, 0.25, -0.8))
        house.addPath(pen.rect(0.13, -0.87, 0.21, -0.8))
        house.addPath(pen.curve(0.12, -0.87, 0.17, -0.93, 0.22, -0.87))
        house.addPath(pen.seg(0.17, -0.93, 0.17, -0.96))
        house.addPath(pen.rect(0.15, -0.44, 0.19, top))
        house.addPath(pen.rect(0.155, -0.63, 0.185, -0.57))
        pen.lit { $0.stroke(house, ink) }

        // The surf in front: breakers along the foot of the wall and across the foreground, in rod 3's core.
        for (x, y, k) in [(-0.82, water + 0.02, 0.14), (0.62, 0.3, 0.18), (-0.24, 0.5, 0.22), (0.2, 0.74, 0.24), (-0.66, 0.74, 0.2)] {
            Cast.breaker(pen.at(x, y, k: k))
        }
        // Rocks of the breakwater's toe, heaped.
        let rocks = pen.poly([(-1, 0.32), (-0.9, 0.27), (-0.78, 0.3), (-0.7, 0.26), (-0.58, 0.31), (-0.5, 0.36), (-1, 0.4)])
        pen.fill(rocks, .black)
        pen.lit { $0.stroke(rocks, ink, 0.7) }

        // Vignette 0, the steps.
        pen.vignette(0) { pen in
            if played.contains(0) {
                Cast.figure(pen.at(-0.31, step(-0.31), k: 0.13), .grandmother, arms: [[(0.1, -0.72), (0.3, -0.74), (0.5, -0.66)]])
                Cast.figure(pen.at(-0.2, step(-0.2), k: 0.15, flip: true), .father,
                            arms: [[(0.1, -0.74), (0.32, -0.66), (0.62, -0.62)], [(-0.1, -0.74), (-0.14, -0.5)]])
            } else {
                // A rope hanging off the post's ring down the face, and the surf breaking up over the lower steps.
                pen.stroke(pen.curve(-0.24, step(-0.24) - 0.01, -0.28, step(-0.24) + 0.06, -0.25, step(-0.24) + 0.11), ink)
                Cast.breaker(pen.at(-0.17, step(-0.17) + 0.012, k: 0.1))
            }
        }

        // Vignette 1, the lifeboat.
        pen.vignette(1) { pen in
            if played.contains(1) {
                Rescue.swellUnder(pen, x: 0.6, y: 0.035, w: 0.2)
                Cast.lifeboat(pen.at(0.6, 0.02, k: 0.17, flip: true, turn: 0.3))
            } else {
                // Its stern at the steps' foot, the crew reaching up them for her, all clear of the steps' disc and the
                // surf's, so it plays still whichever heals first.
                Cast.lifeboat(pen.at(0.285, 0.15, k: 0.16))
                Cast.figure(pen.at(0.225, 0.135, k: 0.12), .crew, arms: [[(-0.1, -0.74), (-0.14, -0.95), (-0.12, -1.12)]])
                Cast.figure(pen.at(0.265, 0.135, k: 0.12), .crew, arms: [[(-0.1, -0.74), (-0.18, -0.92), (-0.2, -1.08)]])
            }
        }

        // Vignette 2, the stair window.
        pen.vignette(2) { pen in
            let window = pen.rect(0.155, -0.63, 0.185, -0.57)
            if played.contains(2) {
                pen.glow(0.17, -0.6, 0.045, Rescue.torch, 0.6)
                pen.fill(window, Rescue.flame, 0.85)
                pen.stroke(window, Rescue.torch)
            } else {
                pen.stroke(pen.seg(0.155, -0.6, 0.185, -0.6), ink, 0.6)
            }
        }
    }
}

/// Scene 8, 3:50 back to 3:25, on quad: the breakwater path running from the quay out to the lighthouse door, the
/// harbour on its left with the lifeboat house, the open sea on its right, a rope line along it on posts. Rod 3, the
/// lifeboat house: its doors open on an empty slip, then the crew pushing the lifeboat off it, its lamp lit. Rod 0, the
/// far end: the chain of lights reaching the lighthouse door, then ending halfway, one light at the door. Rod 1, the
/// bearers: four lanterns held high in a row, then two, and two figures running up with theirs unlit.
enum LanternChain {
    /// The path's centre line, from the quay at the bottom to the lighthouse door: x at height y.
    static func path(_ y: Double) -> Double { -0.05 + 0.55 * (1 - y) / 1.42 }
    /// How wide the path is at height y, in perspective.
    static func width(_ y: Double) -> Double { 0.02 + 0.2 * (y + 0.42) / 1.42 }

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Rescue.ink
        Rescue.clouds(pen, [(-1, -0.25, -0.8, 0.05), (0.1, 0.95, -0.86, 0.05), (-0.55, 0.3, -0.98, 0.04)])

        // The lighthouse on the far end, dark, its door at the path's end.
        let tower = pen.poly([(0.46, -0.41), (0.475, -0.8), (0.545, -0.8), (0.56, -0.41)])
        let rock = pen.poly([(0.36, -0.4), (0.44, -0.43), (0.6, -0.43), (0.7, -0.39)])
        pen.fill(tower, .black)
        pen.fill(rock, .black)
        var house = Path()
        house.addPath(tower)
        house.addPath(rock)
        house.addPath(pen.seg(0.455, -0.8, 0.565, -0.8))
        house.addPath(pen.rect(0.485, -0.86, 0.535, -0.8))
        house.addPath(pen.curve(0.48, -0.86, 0.51, -0.9, 0.54, -0.86))
        house.addPath(pen.rect(0.495, -0.47, 0.525, -0.42))
        house.addPath(pen.rect(0.5, -0.62, 0.52, -0.58))

        // The path, widening towards the viewer, and the rope line on posts along its harbour side.
        let ys = Array(Swift.stride(from: -0.42, through: 1.05, by: 0.03))
        let left = ys.map { (path($0) - width($0), $0) }, right = ys.map { (path($0) + width($0), $0) }
        let band = pen.poly(left + right.reversed())
        pen.fill(band, .black)
        var walk = Path()
        walk.addPath(pen.poly(left, closed: false))
        walk.addPath(pen.poly(right, closed: false))
        var rope = Path()
        rope.addPath(pen.poly(ys.map { (path($0) - width($0) * 0.8, $0 - 0.02 - 0.06 * width($0) / 0.22) }, closed: false))
        for y in Swift.stride(from: -0.36, through: 1.0, by: 0.16) {
            let x = path(y) - width(y) * 0.8, h = 0.02 + 0.06 * width(y) / 0.22
            rope.addPath(pen.seg(x, y, x, y - h - 0.01))
        }

        // The lifeboat house on the harbour side, its doors swung open on the dark inside, the slip's rails running in to
        // its back wall, and the slip down from them to the water.
        let shed = pen.poly([(-0.6, -0.33), (-0.6, -0.47), (-0.5, -0.55), (-0.4, -0.47), (-0.4, -0.33)])
        let leaves = [pen.poly([(-0.55, -0.45), (-0.585, -0.43), (-0.585, -0.315), (-0.55, -0.33)]),
                      pen.poly([(-0.45, -0.45), (-0.415, -0.43), (-0.415, -0.315), (-0.45, -0.33)])]
        pen.fill(shed, .black)
        house.addPath(shed)
        house.addPath(pen.rect(-0.55, -0.45, -0.45, -0.33))
        for leaf in leaves { pen.fill(leaf, .black); house.addPath(leaf) }
        house.addPath(pen.poly([(-0.535, -0.33), (-0.515, -0.39), (-0.485, -0.39), (-0.465, -0.33)], closed: false))
        house.addPath(pen.poly([(-0.45, -0.33), (-0.56, -0.2), (-0.68, -0.2), (-0.55, -0.33)], closed: false))
        house.addPath(pen.seg(-0.5, -0.265, -0.62, -0.265))

        // The quay end in the foreground: a lamp post, lit, and a bollard.
        house.addPath(pen.poly([(-0.3, 0.72), (-0.3, 0.42), (-0.27, 0.4)], closed: false))
        house.addPath(pen.rect(-0.28, 0.36, -0.24, 0.41))
        house.addPath(pen.poly([(-0.5, 0.72), (-0.5, 0.66), (-0.515, 0.65), (-0.445, 0.65), (-0.46, 0.66), (-0.46, 0.72)], closed: false))
        house.addPath(pen.seg(-1, 0.72, -0.12, 0.72))
        pen.fill(pen.rect(-1, 0.72, -0.12, 1), .black)
        pen.lit { g in
            g.stroke(house, ink)
            g.stroke(walk, ink, 0.85)
            g.stroke(rope, Rescue.torch, 0.6)
            g.fill(g.rect(-0.275, 0.365, -0.245, 0.405), Rescue.flame)
        }
        pen.glow(-0.26, 0.39, 0.08, Rescue.torch, 0.35)
        // The surf on the sea side.
        for (x, y, k) in [(0.82, -0.1, 0.16), (0.78, 0.62, 0.2), (0.62, 0.86, 0.22)] { Cast.breaker(pen.at(x, y, k: k)) }

        /// A light carried along the far path: a lantern too far off to show its bearer.
        func far(_ pen: Brush, _ y: Double) {
            Cast.lantern(pen.at(path(y) + 0.025, y - 0.03, k: 0.03), lit: true)
            pen.glow(path(y) + 0.025, y - 0.04, 0.03, Rescue.torch, 0.5)
        }
        for y in [-0.04, 0.06] { far(pen, y) }

        // Vignette 0, the far end.
        pen.vignette(0) { pen in
            // Played, the chain stops short of this core and leaves the last stretch of path dark.
            for y in played.contains(0) ? [-0.415] : [-0.13, -0.21, -0.28, -0.35, -0.415] { far(pen, y) }
        }

        // Vignette 1, the bearers on the near path: a row across it, shoulder to shoulder, the lanterns hung from hands
        // raised over their heads.
        pen.vignette(1) { pen in
            let k = 0.12, lantern = 0.03
            var lanterns: [(x: Double, y: Double, lit: Bool)] = []
            for (i, x) in [0.14, 0.173, 0.206, 0.239].enumerated() {
                let y = 0.44 - 0.01 * Double(i)
                if played.contains(1), i < 2 {
                    // Running up the path, lantern swinging unlit.
                    Cast.figure(pen.at(x, y, k: k), .neighbour, arms: [[(0.1, -0.74), (0.24, -0.6), (0.3, -0.45)], [(-0.1, -0.74), (-0.24, -0.58)]],
                                legs: [[(-0.05, -0.4), (-0.22, -0.18), (-0.2, 0)], [(0.05, -0.4), (0.2, -0.2), (0.3, -0.06)]])
                    lanterns.append((x + 0.3 * k, y - 0.45 * k + lantern, false))
                } else {
                    Cast.figure(pen.at(x, y, k: k), .neighbour, arms: [[(0.1, -0.74), (0.14, -1.0), (0.12, -1.32)]])
                    lanterns.append((x + 0.12 * k, y - 1.32 * k + lantern * 1.12, true))
                }
            }
            for l in lanterns {
                Cast.lantern(pen.at(l.x, l.y, k: lantern), lit: l.lit)
                if l.lit { pen.glow(l.x, l.y - 0.4 * lantern, 0.035, Rescue.torch, 0.5) }
            }
        }

        // Vignette 3, the lifeboat house.
        pen.vignette(3) { pen in
            // Held back, the slip empty, as the house draws it. Played, the lifeboat out on the slip, bow down to the water,
            // one of the crew walking it down beyond its hull and one leaning on its stern.
            if played.contains(3) {
                Cast.figure(pen.at(-0.565, -0.275, k: 0.12, flip: true), .crew, arms: [[(0.1, -0.7), (0.2, -0.55), (0.26, -0.42)]])
                Cast.lifeboat(pen.at(-0.52, -0.251, k: 0.11, flip: true, turn: -0.35))
                Cast.figure(pen.at(-0.44, -0.235, k: 0.12, flip: true, turn: -0.35), .crew,
                            arms: [[(0.1, -0.7), (0.25, -0.54), (0.38, -0.44)], [(-0.1, -0.7), (0.16, -0.52), (0.3, -0.4)]],
                            legs: [[(-0.06, -0.46), (-0.12, -0.24), (-0.22, 0)], [(0.06, -0.46), (0.04, -0.2), (-0.06, 0)]])
            }
        }
    }
}

/// Scene 9, 3:25 back to 3:00, on tri: inside the lighthouse, its stair climbing the wall from the door at its foot,
/// past a window, to a turn below the lamp room. The night shows only through the window and the open door. Every
/// vignette keeps to the part of its core no other disc reaches. Rod 0, the turn of the stair: the hand-lamp left
/// burning on a step, then the grandmother sitting there, her ankle bound with her shawl, the lamp beside her. Rod 1,
/// the window: the lantern chain's lights far below, then dark. Rod 2, the foot: the storm lantern left on the bottom
/// step, then the father there, lantern raised, looking up.
enum Stair {
    static let window = (x0: 0.47, y0: 0.1, x1: 0.62, y1: 0.34)
    static let door = (x0: -0.74, y0: 0.13, x1: -0.62, y1: 0.42)
    static let floor = 0.42, turn = -0.53
    /// The bottom step's tread, the first of the nine that climb from the floor to the landing.
    static let bottom = floor - 0.4 / 9

    /// The window and the open door, where the night shows.
    static func windows(_ pen: Brush) -> Path {
        var p = Path()
        p.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
        p.addPath(pen.rect(door.x0, door.y0, door.x1, door.y1))
        return p
    }

    /// Dark stone inside, and through the openings the sky at `minutes` over a black sea.
    static func sky(_ pen: Brush, minutes: Double) {
        pen.fill(pen.rect(-1, -1, 1, 1), Rescue.sky)
        for (o, horizon) in [(window, 0.25), (door, 0.3)] {
            pen.fill(pen.rect(o.x0, o.y0, o.x1, horizon), .linearGradient(Gradient(stops: Rescue.skyStops(minutes)),
                                                                          startPoint: pen.point(0, o.y0 - 0.3), endPoint: pen.point(0, horizon)))
            pen.fill(pen.rect(o.x0, horizon, o.x1, o.y1), .linearGradient(Gradient(colors: [Rescue.seaTones(minutes)[0].color, .black]),
                                                                          startPoint: pen.point(0, horizon), endPoint: pen.point(0, o.y1)))
        }
    }

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Rescue.ink
        // The tower's round wall, its stone courses bowing as they go round, and the lamp room's floor above.
        var wall = Path()
        for x in [-0.86, 0.86] { wall.addPath(pen.seg(x, -0.6, x, floor)) }
        for y in Swift.stride(from: -0.62, through: 0.36, by: 0.14) {
            wall.addPath(pen.curve(-0.86, y, 0, y + 0.06, 0.86, y))
        }
        wall.addPath(pen.seg(-0.6, -0.78, 0.6, -0.78))
        wall.addPath(pen.rect(-0.1, -0.86, 0.1, -0.78))
        // The stair: from the floor by the door up to the right, a landing under the window, then back up to the left
        // to the turn, its steps' nosings and a rope rail along the wall.
        var stair = Path()
        func flight(_ a: (Double, Double), _ b: (Double, Double), _ n: Int) {
            let dx = (b.0 - a.0) / Double(n), dy = (b.1 - a.1) / Double(n)
            var pts: [(Double, Double)] = [a]
            for i in 0..<n {
                let x = a.0 + dx * Double(i), y = a.1 + dy * Double(i)
                pts.append((x, y + dy)); pts.append((x + dx, y + dy))
            }
            stair.addPath(pen.poly(pts, closed: false))
            stair.addPath(pen.seg(a.0, a.1 + 0.04, b.0, b.1 + 0.04))
        }
        flight((-0.3, floor), (0.42, 0.02), 9)
        stair.addPath(pen.seg(0.42, 0.02, 0.7, 0.02))
        flight((0.62, 0.02), (0.22, turn), 8)
        stair.addPath(pen.seg(0.22, turn, -0.3, turn))
        stair.addPath(pen.seg(-0.3, turn, -0.3, turn + 0.04))
        stair.addPath(pen.seg(-0.3, turn + 0.04, 0.2, turn + 0.04))
        var rail = Path()
        rail.addPath(pen.curve(-0.28, floor - 0.12, 0.1, 0.12, 0.44, -0.08))
        rail.addPath(pen.curve(0.6, -0.08, 0.42, -0.3, 0.22, turn - 0.12))
        // The window's deep reveal and its bars, the door standing open on its hinges.
        var frames = Path()
        frames.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
        frames.addPath(pen.poly([(window.x0, window.y0), (window.x0 - 0.03, window.y0 - 0.03), (window.x1 + 0.03, window.y0 - 0.03),
                                 (window.x1, window.y0)], closed: false))
        frames.addPath(pen.seg((window.x0 + window.x1) / 2, window.y0, (window.x0 + window.x1) / 2, window.y1))
        frames.addPath(pen.rect(door.x0, door.y0, door.x1, door.y1))
        frames.addPath(pen.poly([(door.x1, door.y0), (door.x1 + 0.06, door.y0 + 0.03), (door.x1 + 0.06, door.y1 + 0.02), (door.x1, door.y1)]))
        let leaf = pen.poly([(door.x1, door.y0), (door.x1 + 0.06, door.y0 + 0.03), (door.x1 + 0.06, door.y1 + 0.02), (door.x1, door.y1)])
        pen.fill(leaf, .black)
        frames.addPath(pen.seg(-1, floor, 1, floor))
        // The floor's flags running towards the viewer, faint, and a coil of rope by the door.
        var flags = Path()
        for x in Swift.stride(from: -1.5, through: 1.5, by: 0.3) { flags.addPath(pen.seg(x * 0.6, floor, x, 1)) }
        for y in [0.55, 0.78] { flags.addPath(pen.seg(-1, y, 1, y)) }
        frames.addPath(pen.ellipse(-0.8, floor + 0.05, 0.06, 0.018))
        frames.addPath(pen.ellipse(-0.8, floor + 0.04, 0.045, 0.013))
        pen.lit { g in
            g.stroke(wall, ink, 0.4)
            g.stroke(flags, ink, 0.22)
            g.stroke(stair, ink)
            g.stroke(rail, Rescue.torch, 0.5)
            g.stroke(frames, ink)
            g.stroke(g.seg(window.x0, 0.25, window.x1, 0.25), ink, 0.5)
            g.stroke(g.seg(door.x0, 0.3, door.x1, 0.3), ink, 0.5)
        }

        // Vignette 0, the turn of the stair: the hand-lamp on the step, and the grandmother sitting by it.
        pen.vignette(0) { pen in
            if played.contains(0) {
                Stair.sitting(pen.at(-0.17, turn, k: 0.15))
            }
            Rescue.handLamp(pen, x: -0.065, y: turn)
        }

        // Vignette 1, the window: the chain of lights along the breakwater far below.
        pen.vignette(1) { pen in
            if !played.contains(1) {
                for (i, x) in [0.49, 0.515, 0.54, 0.565, 0.59].enumerated() {
                    let y = 0.275 + 0.01 * Double(i)
                    pen.fill(pen.circle(x, y, 0.01), Rescue.flame)
                    pen.glow(x, y, 0.025, Rescue.torch, 0.55)
                }
            }
        }

        // Vignette 2, the foot of the stair.
        pen.vignette(2) { pen in
            if played.contains(2) {
                // His far arm holds the lantern up behind him, out of his own light, as he looks up the stair.
                Cast.figure(pen.at(-0.5, floor, k: 0.16), .father,
                            arms: [[(-0.1, -0.74), (-0.26, -0.94), (-0.34, -1.1)], [(0.1, -0.74), (0.16, -0.5)]])
                Cast.lantern(pen.at(-0.555, floor - 0.17, k: 0.045), lit: true)
                pen.glow(-0.555, floor - 0.185, 0.06, Rescue.torch, 0.4)
            } else {
                // On the bottom step's tread.
                Cast.lantern(pen.at(-0.26, bottom, k: 0.05), lit: true)
                pen.glow(-0.26, bottom - 0.02, 0.06, Rescue.torch, 0.4)
            }
        }
    }

    /// The grandmother sitting on a step at (0, 0), facing right, her hurt leg out along the step with the shawl bound
    /// round its ankle, the other knee up.
    static func sitting(_ pen: Brush) {
        var body = Path(), lines = Path()
        let head = pen.circle(0, -0.86, 0.07), bun = pen.circle(-0.08, -0.91, 0.035)
        let torso = pen.poly([(-0.1, -0.74), (0.1, -0.74), (0.12, -0.3), (-0.14, -0.3), (-0.16, 0)])
        let skirt = pen.poly([(-0.16, 0), (-0.12, -0.3), (0.12, -0.3), (0.26, -0.34), (0.58, -0.06), (0.58, 0)])
        for p in [head, bun, torso, skirt] { body.addPath(p); lines.addPath(p) }
        lines.addPath(pen.poly([(0.6, 0), (0.66, -0.02), (0.68, -0.1)], closed: false))
        lines.addPath(pen.poly([(0.44, -0.11), (0.5, -0.02), (0.54, -0.15)], closed: false))
        lines.addPath(pen.poly([(0.1, -0.7), (0.24, -0.5), (0.3, -0.36)], closed: false))
        lines.addPath(pen.poly([(-0.1, -0.7), (-0.2, -0.42), (-0.2, -0.1)], closed: false))
        pen.fill(body, .black)
        pen.lit(Rescue.tight) { $0.stroke(lines, Rescue.ink) }
    }
}

extension Rescue {
    /// The grandmother's hand-lamp, standing lit on a step at (x, y): a wide base with a finger loop, a tall glass
    /// chimney open at the top, and a pointed flame low in it, so it reads as a lamp and not a numeral.
    static func handLamp(_ pen: Brush, x: Double, y: Double) {
        var lamp = Path()
        lamp.addPath(pen.poly([(x - 0.026, y), (x - 0.018, y - 0.014), (x + 0.018, y - 0.014), (x + 0.026, y)]))
        lamp.addPath(pen.path { c in
            c.move(to: CGPoint(x: x - 0.01, y: y - 0.014))
            c.addQuadCurve(to: CGPoint(x: x - 0.006, y: y - 0.062), control: CGPoint(x: x - 0.024, y: y - 0.034))
            c.move(to: CGPoint(x: x + 0.006, y: y - 0.062))
            c.addQuadCurve(to: CGPoint(x: x + 0.01, y: y - 0.014), control: CGPoint(x: x + 0.024, y: y - 0.034))
        })
        lamp.addPath(pen.curve(x + 0.024, y - 0.004, x + 0.046, y - 0.008, x + 0.022, y - 0.014))
        let flame = pen.path { f in
            f.move(to: CGPoint(x: x, y: y - 0.046))
            f.addQuadCurve(to: CGPoint(x: x, y: y - 0.02), control: CGPoint(x: x + 0.012, y: y - 0.024))
            f.addQuadCurve(to: CGPoint(x: x, y: y - 0.046), control: CGPoint(x: x - 0.012, y: y - 0.024))
        }
        pen.glow(x, y - 0.03, 0.05, torch, 0.5)
        pen.fill(flame, Rescue.flame)
        pen.lit(tight) { $0.stroke(lamp, torch) }
    }
}

/// Scene 10, 3:00 back to 2:30, on pent: the foot of the lighthouse on its rocks, waves breaking, the breakwater path
/// running in from the right. Rod 0, the gallery window: dark, then the hand-lamp in it blinking a signal. Rod 1, the
/// path: the rope tied off on an iron ring and stretched back along the path, then the father out on it, the coil on
/// his shoulder, bent into the spray. Rod 3, the door: open, light on the stair inside, then shut, a wave breaking over
/// its step.
enum LighthouseDoor {
    static let axis = -0.12, base = 0.56

    /// The path's walking surface, from the right edge in to the lighthouse's foot: its height at x.
    static func path(_ x: Double) -> Double { x > 0.3 ? 0.02 - 0.08 * (x - 0.3) : 0.02 + (0.3 - x) * 1.6 }

    /// The rope from the quay, along the path's harbour edge: its height at x.
    static func rope(_ x: Double) -> Double { path(x) - 0.03 - 0.012 * sin(x * 9) }

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Rescue.ink
        Rescue.clouds(pen, [(-1, -0.4, -0.82, 0.05), (0.2, 1, -0.88, 0.05), (0.35, 0.95, -0.76, 0.03)])

        // The tower, tapering up to its gallery and lamp room, dark; a stone course every so often.
        let w = { (y: Double) in 0.17 - 0.07 * (base - y) / (base + 0.6) }
        let tower = pen.poly([(axis - w(base), base), (axis - w(-0.6), -0.6), (axis + w(-0.6), -0.6), (axis + w(base), base)])
        let room = pen.rect(axis - 0.07, -0.74, axis + 0.07, -0.62)
        let dome = pen.path { d in
            d.move(to: CGPoint(x: axis - 0.085, y: -0.74)); d.addQuadCurve(to: CGPoint(x: axis + 0.085, y: -0.74), control: CGPoint(x: axis, y: -0.86))
            d.closeSubpath()
        }
        pen.fill(tower, .black); pen.fill(dome, .black)
        var house = Path()
        house.addPath(tower)
        house.addPath(room)
        house.addPath(dome)
        house.addPath(pen.seg(axis, -0.86, axis, -0.9))
        house.addPath(pen.seg(axis - 0.13, -0.6, axis + 0.13, -0.6))
        house.addPath(pen.seg(axis - 0.13, -0.6, axis - 0.13, -0.635))
        house.addPath(pen.seg(axis + 0.13, -0.6, axis + 0.13, -0.635))
        house.addPath(pen.seg(axis - 0.13, -0.635, axis + 0.13, -0.635))
        for x in [axis - 0.025, axis + 0.025] { house.addPath(pen.seg(x, -0.74, x, -0.62)) }
        for y in Swift.stride(from: -0.45, to: 0.5, by: 0.16) { house.addPath(pen.seg(axis - w(y), y, axis + w(y), y)) }
        // The door's frame and step, its little window above.
        house.addPath(pen.rect(-0.21, 0.36, -0.12, base))
        house.addPath(pen.rect(-0.24, base, -0.08, base + 0.03))
        house.addPath(pen.rect(-0.18, 0.12, -0.15, 0.18))

        // The rocks heaped round the foot, the path coming in on its wall from the right.
        let rocks = pen.poly([(-1, 0.66), (-0.82, 0.6), (-0.66, 0.63), (-0.5, 0.57), (-0.34, 0.6), (0.14, 0.6), (0.3, 0.64), (0.48, 0.61),
                              (0.7, 0.66), (0.86, 0.62), (1, 0.66), (1, 1), (-1, 1)])
        let xs = Array(Swift.stride(from: 0.06, through: 1.0, by: 0.02))
        let walk = pen.poly(xs.map { ($0, path($0)) } + [(1, path(1) + 0.08), (0.06, base + 0.04)])
        pen.fill(rocks, .black)
        pen.fill(walk, .black)
        house.addPath(pen.poly(xs.map { ($0, path($0)) }, closed: false))
        house.addPath(pen.poly(xs.map { ($0, path($0) + 0.05) }, closed: false))
        var rocky = Path()
        rocky.addPath(rocks)
        // Boulders, flat-bottomed and heaped, so the foot of the picture reads as ground.
        for (x, y, k) in [(-0.8, 0.76, 0.1), (-0.52, 0.74, 0.12), (-0.24, 0.73, 0.09), (0.18, 0.75, 0.11), (0.46, 0.76, 0.1),
                          (0.72, 0.78, 0.09), (-0.05, 0.9, 0.13), (-0.62, 0.92, 0.11), (0.48, 0.94, 0.12)] {
            rocky.addPath(pen.poly([(x - k, y), (x - 0.8 * k, y - 0.45 * k), (x - 0.2 * k, y - 0.7 * k), (x + 0.5 * k, y - 0.55 * k),
                                    (x + k, y)]))
        }
        // The rope from the quay along the path, outside the path's core.
        let line = pen.poly(Swift.stride(from: 0.8, through: 1.0, by: 0.02).map { ($0, rope($0)) }, closed: false)
        pen.lit { g in
            g.stroke(house, ink)
            g.stroke(rocky, ink, 0.6)
            g.stroke(line, Rescue.torch, 0.8)
        }
        for (x, y, k) in [(-0.62, 0.55, 0.24), (0.36, 0.58, 0.22), (-0.72, -0.08, 0.2), (0.8, 0.4, 0.2), (-0.88, 0.3, 0.18)] {
            Cast.breaker(pen.at(x, y, k: k))
        }

        // Vignette 0, the gallery window.
        pen.vignette(0) { pen in
            if played.contains(0) {
                // In the pane away from the knob, its light flashing out to sea.
                pen.fill(pen.rect(axis - 0.065, -0.69, axis - 0.03, -0.625), Rescue.torch, 0.25)
                Rescue.handLamp(pen, x: axis - 0.045, y: -0.625)
                for a in [Double.pi - 0.5, .pi, .pi + 0.5] {
                    let x = axis - 0.045, y = -0.655
                    pen.stroke(pen.seg(x + 0.024 * cos(a), y + 0.024 * sin(a), x + 0.036 * cos(a), y + 0.036 * sin(a)), Rescue.flame)
                }
            }
        }

        // Vignette 1, the path.
        pen.vignette(1) { pen in
            if played.contains(1) {
                pen.stroke(pen.poly(Swift.stride(from: 0.72, through: 0.8, by: 0.02).map { ($0, rope($0)) }, closed: false), Rescue.torch, 0.8)
                Cast.figure(pen.at(0.685, path(0.685), k: 0.13, turn: -0.25), .father,
                            arms: [[(0.1, -0.74), (0.22, -0.6), (0.3, -0.62)], [(-0.1, -0.74), (-0.2, -0.56), (-0.26, -0.44)]])
                // The coil over his shoulder.
                pen.stroke(pen.ellipse(0.672, path(0.685) - 0.093, 0.026, 0.019), Rescue.torch)
                pen.stroke(pen.ellipse(0.672, path(0.685) - 0.093, 0.017, 0.012), Rescue.torch)
                // Spray driving across him from the sea.
                for (x, y) in [(0.72, -0.13), (0.74, -0.09), (0.7, -0.17)] {
                    pen.stroke(pen.seg(x, y, x - 0.035, y + 0.012), Rescue.ink, 0.8)
                }
            } else {
                pen.stroke(pen.poly(Swift.stride(from: 0.42, through: 0.8, by: 0.02).map { ($0, rope($0)) }, closed: false), Rescue.torch, 0.8)
                pen.stroke(pen.circle(0.405, rope(0.42) + 0.004, 0.014), Rescue.ink)
                pen.stroke(pen.seg(0.405, rope(0.42) + 0.018, 0.405, path(0.405)), Rescue.ink)
            }
        }

        // Vignette 3, the door.
        pen.vignette(3) { pen in
            if played.contains(3) {
                pen.fill(pen.rect(-0.21, 0.36, -0.12, base), .black)
                pen.stroke(pen.rect(-0.2, 0.37, -0.13, base), Rescue.ink)
                pen.stroke(pen.seg(-0.165, 0.37, -0.165, base), Rescue.ink, 0.6)
                Cast.breaker(pen.at(-0.205, base + 0.03, k: 0.125), glows: Rescue.tight)
            } else {
                pen.fill(pen.rect(-0.21, 0.36, -0.12, base), Rescue.torch, 0.35)
                for k in 0..<4 {
                    let y = base - 0.04 - 0.04 * Double(k)
                    pen.stroke(pen.seg(-0.2 + 0.015 * Double(k), y, -0.13, y), Rescue.flame, 0.8)
                }
            }
        }
    }
}
