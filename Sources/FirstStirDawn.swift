// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// First Stir's chapter 1, Dawn After: scenes 1 to 5, 6:40 back to 4:45 am, in dawn pewter. Each is drawn in code in
/// tank units (x right, y down, the glass's radius 1) in three parts: the sky and sea at a time, the scene with a set of
/// vignettes played, and what moves with the time as a body (the sun, a chimney's smoke), which stays where no disc
/// reaches. Everything that differs between a vignette's two states, glow included, keeps inside its own core, clear of
/// its knob.
enum Dawn: Int, CaseIterable, Sendable {
    case sunrise = 1, gallery, rockPool, righting, tea

    var layout: Layout {
        switch self {
        case .sunrise, .rockPool: .tri
        case .gallery, .tea: .quad
        case .righting: .eye
        }
    }

    var vignettes: Set<Int> {
        switch self {
        case .sunrise, .rockPool, .righting: [0, 1, 2]
        case .gallery: [0, 1, 3]
        case .tea: [1, 2, 3]
        }
    }

    /// The chapter's window, minutes after midnight: each scene's played time is the next one's held-back time.
    static let times: [Double] = [400, 375, 350, 325, 305, 285]
    /// The time held back, the latest.
    var late: Double { Self.times[rawValue - 1] }
    /// The time once every entry of the scramble has gone, the earliest.
    var early: Double { Self.times[rawValue] }

    /// Where the sea meets the sky.
    var horizon: Double {
        switch self {
        case .sunrise: 0
        case .gallery: 0.02
        case .rockPool, .righting: -0.3
        case .tea: -0.5
        }
    }

    static let sky = Color(0x2B3550)
    static let glow = Color(0xF2B48C)
    static let sea = Color(0x7D8FA6)
    static let ink = Color(0x9AA8C8)
    static let light = Color(0xFFD9A0)
    static let float = Color(0x3FE0B0)

    /// How far the dawn has come at `minutes`: 0 at 4:45, 1 at 6:40.
    static func dawn(_ minutes: Double) -> Double { min(max((minutes - times.last!) / (times[0] - times.last!), 0), 1) }

    /// The widest glow a body is drawn with, which keeps that far from every disc as well as its line's half-width.
    static let bodyGlow = 0.02

    /// The sun: its centre at `minutes` and its radius, rising out of the sea at the right edge of the sunrise, where
    /// no disc reaches. It is under the sea at every other scene's times.
    static func sun(_ minutes: Double) -> (x: Double, y: Double, radius: Double) {
        (0.97, 0.03 - 0.05 * (minutes - times[1]) / (times[0] - times[1]), 0.022)
    }

    /// The neighbour's chimney smoke on the sunrise, outside every disc: puffs from above the chimney pot up into the
    /// sky, thinning as the night winds back to before the fire was lit.
    static let smoke: [(x: Double, y: Double, radius: Double)] =
        [(-0.835, -0.2, 0.015), (-0.855, -0.25, 0.02), (-0.865, -0.31, 0.024), (-0.865, -0.37, 0.028)]

    /// The smoke's two strands, the second a little further from the discs, as a curve per puff: start, control, end.
    static let strands: [[(a: (Double, Double), c: (Double, Double), b: (Double, Double))]] = [0, -0.012].map { o in
        var at = (smoke[0].x + o, smoke[0].y + smoke[0].radius)
        return smoke.enumerated().map { i, puff in
            let side = i % 2 == 0 ? 1.0 : -1
            let b = (puff.x + o - 0.6 * side * puff.radius, puff.y - puff.radius * 0.5)
            defer { at = b }
            return (at, (puff.x + o + 0.7 * side * puff.radius, puff.y + puff.radius), b)
        }
    }

    /// The bodies `live` draws, as circles (the smoke as points along its strands), for the test that keeps them clear
    /// of every disc.
    var bodies: [(x: Double, y: Double, radius: Double)] {
        guard self == .sunrise else { return [] }
        let smoke = Self.strands.joined().flatMap { q in
            (0...16).map { k -> (x: Double, y: Double, radius: Double) in
                let t = Double(k) / 16, u = 1 - t
                return (u * u * q.a.0 + 2 * t * u * q.c.0 + t * t * q.b.0, u * u * q.a.1 + 2 * t * u * q.c.1 + t * t * q.b.1, 0)
            }
        }
        return smoke + [late, early].map { Self.sun($0) }
    }

    func drawSky(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        let pen = Pen(ctx: ctx, r: r), d = Self.dawn(minutes), h = horizon
        func shade(_ c: UInt32, _ k: Double) -> (Double, Double, Double) {
            (Double(c >> 16 & 0xFF) / 255 * k, Double(c >> 8 & 0xFF) / 255 * k, Double(c & 0xFF) / 255 * k)
        }
        func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ t: Double) -> Color {
            Color(red: a.0 + (b.0 - a.0) * t, green: a.1 + (b.1 - a.1) * t, blue: a.2 + (b.2 - a.2) * t)
        }
        // The zenith greys from near black to pewter; the horizon from a dim pewter to the first light's warm band.
        let zenith = mix(shade(0x2B3550, 0.12), shade(0x2B3550, 0.75), d)
        let low = d < 0.6 ? mix(shade(0x2B3550, 0.4), shade(0x2B3550, 1), d / 0.6) : mix(shade(0x2B3550, 1), shade(0xF2B48C, 1), (d - 0.6) / 0.4)
        let middle = mix(shade(0x2B3550, 0.12 + 0.63 * d), shade(0x2B3550, d < 0.6 ? 0.4 + d : 1), 0.5)
        ctx.fill(pen.rect(-1, -1, 1, 1), with: .color(.black))
        ctx.fill(pen.rect(-1, -1, 1, h), with: .linearGradient(
            Gradient(stops: [.init(color: zenith, location: 0), .init(color: middle, location: 0.6), .init(color: low, location: 1)]),
            startPoint: pen.p(0, -1), endPoint: pen.p(0, h)))
        // The sun's glow over the sea's edge on the right, already up at sunrise and sunk an hour before.
        let g = d * d * d
        var sky = ctx
        sky.clip(to: pen.rect(-1, -1, 1, h))
        sky.fill(pen.circle(0.95, h, 0.9), with: .radialGradient(
            Gradient(stops: [.init(color: Self.light.opacity(0.55 * g), location: 0), .init(color: Self.glow.opacity(0.3 * g), location: 0.35),
                             .init(color: Self.glow.opacity(0), location: 1)]),
            center: pen.p(0.95, h), startRadius: 0, endRadius: 0.9 * r))
        // The sea, darkening towards the viewer, its swell catching the sky.
        ctx.fill(pen.rect(-1, h, 1, 1), with: .linearGradient(
            Gradient(stops: [.init(color: mix(shade(0x2B3550, 0.25), shade(0x7D8FA6, 0.35), d), location: 0),
                             .init(color: .black, location: 1)]),
            startPoint: pen.p(0, h), endPoint: pen.p(0, 1)))
        var swell = Path()
        var rng = SplitMix64(state: 7)
        for k in 1...14 {
            let t = Double(k) / 14, y = h + 0.012 + (1 - h) * 0.98 * pow(t, 1.7)
            let amp = 0.002 + 0.012 * t, wave = 0.05 + 0.2 * t, phase = Double.random(in: 0..<6.3, using: &rng)
            swell.move(to: pen.p(-1.05, y))
            for x in stride(from: -1.05, through: 1.05, by: 0.01) { swell.addLine(to: pen.p(x, y - amp * sin(x / wave * 2 * .pi + phase))) }
        }
        neon(ctx, r: r, glows: [(0.025, 0.3), (0.007, 0.7)]) { g in
            var s = g
            s.clip(to: pen.rect(-1, h, 1, 1))
            s.stroke(swell, with: .color(Self.sea.opacity(0.25 + 0.4 * d)), style: pen.style)
            g.stroke(pen.seg(-1, h, 1, h), with: .color(Self.sea.opacity(0.5 + 0.4 * d)), style: pen.style)
        }
    }

    /// What moves with the time as a body, drawn over the sky and under the scene.
    func drawLive(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        guard self == .sunrise else { return }
        let pen = Pen(ctx: ctx, r: r), d = Self.dawn(minutes)
        let s = Self.sun(minutes)
        neon(ctx, r: r, glows: [(Self.bodyGlow, 0.6), (0.008, 1)]) { g in
            var c = g
            c.clip(to: pen.rect(-1, -1, 1, horizon))
            c.fill(pen.circle(s.x, s.y, s.radius), with: .color(Self.light))
        }
        // The fire was lit a little after six: by 6:15 the smoke is gone.
        let lit = min(max((minutes - Self.times[1]) / (Self.times[0] - Self.times[1]) * 1.6, 0), 1)
        guard lit > 0 else { return }
        neon(ctx, r: r, glows: [(Self.bodyGlow, 0.4), (0.007, 0.9)]) { g in
            for (strand, curves) in Self.strands.enumerated() {
                var curl = Path()
                curl.move(to: pen.p(curves[0].a.0, curves[0].a.1))
                for (i, q) in curves.enumerated() {
                    guard lit * Double(curves.count) - Double(i) > 0 else { break }
                    curl.addQuadCurve(to: pen.p(q.b.0, q.b.1), control: pen.p(q.c.0, q.c.1))
                }
                g.stroke(curl, with: .color(Self.ink.opacity(0.5 * (0.5 + 0.5 * d) * (strand == 0 ? 1 : 0.6))), style: pen.style)
            }
        }
    }

    func draw(_ ctx: GraphicsContext, r: CGFloat, played: Set<Int>) {
        let pen = Pen(ctx: ctx, r: r)
        switch self {
        case .sunrise: Self.sunrise(pen, played)
        case .gallery: Self.gallery(pen, played)
        case .rockPool: Self.rockPool(pen, played)
        case .righting: Self.righting(pen, played)
        case .tea: Self.tea(pen, played)
        }
    }
}

/// Drawing in tank units on a context `r` points to the glass's radius, one line weight throughout.
struct Pen {
    let ctx: GraphicsContext
    let r: CGFloat
    static let line = 0.0075

    var style: StrokeStyle { StrokeStyle(lineWidth: Self.line * r, lineCap: .round, lineJoin: .round) }

    func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: r + x * r, y: r + y * r) }
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
        Path(CGRect(origin: p(x0, y0), size: CGSize(width: (x1 - x0) * r, height: (y1 - y0) * r)))
    }
    func circle(_ x: Double, _ y: Double, _ radius: Double) -> Path {
        Path(ellipseIn: CGRect(origin: p(x - radius, y - radius), size: CGSize(width: 2 * radius * r, height: 2 * radius * r)))
    }
    func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(origin: p(x - rx, y - ry), size: CGSize(width: 2 * rx * r, height: 2 * ry * r)))
    }
    func quad(_ ax: Double, _ ay: Double, _ cx: Double, _ cy: Double, _ bx: Double, _ by: Double) -> Path {
        Path { $0.move(to: p(ax, ay)); $0.addQuadCurve(to: p(bx, by), control: p(cx, cy)) }
    }
    /// A smooth curve through `pts`, each inner point a control between the midpoints either side.
    func smooth(_ pts: [(Double, Double)]) -> Path {
        Path { path in
            path.move(to: p(pts[0].0, pts[0].1))
            guard pts.count > 2 else { path.addLine(to: p(pts[1].0, pts[1].1)); return }
            for i in 1..<pts.count - 1 {
                let m = i == pts.count - 2 ? pts[i + 1] : ((pts[i].0 + pts[i + 1].0) / 2, (pts[i].1 + pts[i + 1].1) / 2)
                path.addQuadCurve(to: p(m.0, m.1), control: p(pts[i].0, pts[i].1))
            }
        }
    }

    /// Strokes in the neon line, each with its colour and opacity.
    func line(_ strokes: [(Path, Color, Double)], glows: [(blur: Double, opacity: Double)] = [(0.03, 0.4), (0.008, 1.0)]) {
        neon(ctx, r: r, glows: glows) { g in
            for (path, colour, opacity) in strokes { g.stroke(path, with: .color(colour.opacity(opacity)), style: style) }
        }
    }
    func fill(_ path: Path, _ colour: Color = .black) { ctx.fill(path, with: .color(colour)) }
    /// A shape filled black and outlined: what stands in front of what is behind it.
    func solid(_ path: Path, _ colour: Color, _ opacity: Double = 1) {
        fill(path)
        line([(path, colour, opacity)])
    }

    /// A storm lantern standing at (x, y) (its base), `size` tall, turned by `angle` about its base.
    func lantern(_ x: Double, _ y: Double, size s: Double, angle: Double = 0) -> Path {
        func q(_ u: Double, _ v: Double) -> CGPoint {
            let (cu, su) = (cos(angle), sin(angle))
            return p(x + (u * cu - v * su) * s, y - (u * su + v * cu) * s)
        }
        var cage = Path()
        cage.move(to: q(-0.32, 0)); cage.addLine(to: q(0.32, 0))
        cage.move(to: q(-0.26, 0)); cage.addLine(to: q(-0.22, 0.62)); cage.addLine(to: q(0.22, 0.62)); cage.addLine(to: q(0.26, 0))
        cage.move(to: q(0, 0.02)); cage.addLine(to: q(0, 0.6))
        cage.move(to: q(-0.28, 0.62)); cage.addLine(to: q(-0.12, 0.8)); cage.addLine(to: q(0.12, 0.8)); cage.addLine(to: q(0.28, 0.62))
        cage.move(to: q(-0.2, 0.84)); cage.addQuadCurve(to: q(0.2, 0.84), control: q(0, 1.12))
        return cage
    }
}

/// The family and the town, as silhouettes: a figure is built from its parts in its own units (its height 1, feet at
/// the origin, y up, facing +x) and their union outlined, so a pose is only where its joints go.
struct Figure {
    enum Who { case father, grandmother, child, neighbour, crew }
    typealias Pt = (Double, Double)

    var who: Who
    var head: Pt
    var neck: Pt
    var hip: Pt
    var legs: [[Pt]]
    var arms: [[Pt]]

    /// Standing, arms down.
    static func standing(_ who: Who) -> Figure {
        Figure(who: who, head: (0, 0.9), neck: (0, 0.79), hip: (0, 0.5),
               legs: [[(0.04, 0.48), (0.05, 0.26), (0.06, 0.03)], [(-0.04, 0.48), (-0.05, 0.26), (-0.06, 0.03)]],
               arms: [[(0.1, 0.76), (0.15, 0.6), (0.17, 0.45)], [(-0.1, 0.76), (-0.15, 0.6), (-0.17, 0.45)]])
    }

    /// The outline at feet (x, y) in tank units, `h` tall, facing right when `facing` is 1 and left when -1.
    func path(_ pen: Pen, x: Double, y: Double, h: Double, facing f: Double = 1) -> Path {
        func q(_ u: Pt) -> CGPoint { pen.p(x + f * u.0 * h, y - u.1 * h) }
        let r = pen.r
        let child = who == .child
        let limb = (child ? 0.12 : 0.09) * h * r, leg = (child ? 0.14 : 0.11) * h * r
        func stroke(_ pts: [Pt], _ width: CGFloat) -> CGPath {
            let path = CGMutablePath()
            path.move(to: q(pts[0]))
            for pt in pts.dropFirst() { path.addLine(to: q(pt)) }
            return path.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 4)
        }
        func blob(_ pts: [Pt]) -> CGPath {
            let path = CGMutablePath()
            path.addLines(between: pts.map(q))
            path.closeSubpath()
            return path
        }
        func disc(_ c: Pt, _ radius: Double) -> CGPath {
            CGPath(ellipseIn: CGRect(x: q(c).x - radius * h * r, y: q(c).y - radius * h * r, width: 2 * radius * h * r, height: 2 * radius * h * r),
                   transform: nil)
        }
        let headR = child ? 0.12 : 0.085
        // The torso's line, for the body and a coat or shawl hung along it.
        let t = (hip.0 - neck.0, hip.1 - neck.1), n = (-t.1, t.0)
        let tl = (t.0 * t.0 + t.1 * t.1).squareRoot(), nn = (n.0 / tl, n.1 / tl)
        func along(_ k: Double, _ w: Double) -> Pt { (neck.0 + t.0 * k + nn.0 * w, neck.1 + t.1 * k + nn.1 * w) }
        let s = child ? 1.2 : 1.0
        var parts: [CGPath] = [disc(head, headR), stroke([neck, head], 0.07 * h * r),
                               blob([along(0.08, 0.13 * s), along(1, 0.09 * s), along(1.08, 0), along(1, -0.09 * s), along(0.08, -0.13 * s),
                                     along(0, -0.1 * s), along(0, 0.1 * s)])]
        parts += legs.map { stroke($0, leg) } + arms.map { stroke($0, limb) }
        // The head's own up, from the neck through it.
        let up = (head.0 - neck.0, head.1 - neck.1), ul = (up.0 * up.0 + up.1 * up.1).squareRoot()
        let u = (up.0 / ul, up.1 / ul), side = (u.1, -u.0)
        func atHead(_ a: Double, _ b: Double) -> Pt { (head.0 + u.0 * a + side.0 * b, head.1 + u.1 * a + side.1 * b) }
        switch who {
        case .father:
            // Oilskin to the knees, and the sou'wester's wide brim, longer at the back.
            parts.append(blob([along(0.05, 0.1), along(1.55, 0.14), along(1.55, -0.14), along(0.05, -0.1)]))
            parts.append(blob([atHead(0.02, 0.15), atHead(0.06, 0.12), atHead(0.1, 0.05), atHead(0.1, -0.05), atHead(0.06, -0.1),
                               atHead(0.0, -0.17), atHead(-0.02, -0.15), atHead(0.02, 0.15)]))
        case .crew:
            parts.append(blob([along(0.0, 0.12), along(0.6, 0.12), along(0.6, -0.12), along(0.0, -0.12)]))
            parts.append(disc(atHead(0.03, 0), headR * 1.15))
        case .grandmother:
            // A long skirt, the shawl's point down her back, the bun behind.
            parts.append(blob([along(0.9, 0.09), along(1.62, 0.16), along(1.62, -0.16), along(0.9, -0.09)]))
            parts.append(blob([along(-0.05, 0.11), along(0.15, 0.14), along(0.75, -0.02), along(0.15, -0.14), along(-0.05, -0.11)]))
            parts.append(disc(atHead(0.03, -0.075), 0.04))
        case .child:
            // A bobble hat.
            parts.append(blob([atHead(0.02, 0.1), atHead(0.09, 0.07), atHead(0.11, 0), atHead(0.09, -0.07), atHead(0.02, -0.1)]))
            parts.append(disc(atHead(0.15, 0), 0.04))
        case .neighbour:
            // A cap, its peak forward.
            parts.append(blob([atHead(0.03, 0.075), atHead(0.08, 0.06), atHead(0.09, -0.04), atHead(0.05, -0.08), atHead(0.04, 0.13),
                               atHead(0.03, 0.12)]))
        }
        return Path(parts.dropFirst().reduce(parts[0]) { $0.union($1) })
    }
}

extension Dawn {
    // MARK: Scene 1, sunrise (6:40 to 6:15): the lab's harbour after the storm.

    /// Rod 0 (top): the lantern boarded, a gull on the rail; earlier, a neighbour on a stepladder nailing the first plank
    /// over its broken panes. Rod 1 (right): the boat bailed and upright on the slip, mast stepped and pennant flying;
    /// earlier, the father in it bailing, the mast still lying aboard. Rod 2 (left): the cottage door shut, its window
    /// lit; earlier, the door open and a neighbour sweeping water and weed out over the step. The doorway lies in the
    /// boat's disc, so the scramble heals the boat first.
    static func sunrise(_ pen: Pen, _ played: Set<Int>) {
        let ink = Self.ink, light = Self.light

        // The breakwater's rock and the lighthouse, the lab's plan, its lantern storey a fifth larger than life.
        let rock = pen.poly([(-0.27, 0.03), (-0.21, -0.012), (-0.14, -0.03), (-0.07, -0.026), (0.03, -0.045), (0.11, -0.03),
                             (0.19, -0.016), (0.28, 0.03)])
        let tower = pen.poly([(-0.10, -0.025), (-0.062, -0.51), (0.062, -0.51), (0.10, -0.025)])
        pen.fill(rock)
        pen.fill(tower)
        var house = Path()
        house.addPath(tower)
        for y in [-0.14, -0.26, -0.38] {
            let w = 0.10 - 0.038 * (y + 0.025) / -0.485
            house.addPath(pen.quad(-w, y, 0, y + 0.02, w, y))
        }
        house.addPath(Path { a in
            a.move(to: pen.p(-0.024, -0.03)); a.addLine(to: pen.p(-0.024, -0.075))
            a.addQuadCurve(to: pen.p(0.024, -0.075), control: pen.p(0, -0.1)); a.addLine(to: pen.p(0.024, -0.03))
        })
        for y in [-0.20, -0.32] { house.addPath(pen.rect(-0.009, y - 0.015, 0.009, y + 0.015)) }
        let room = pen.rect(-0.09, -0.7, 0.09, -0.564)
        var dome = pen.quad(-0.106, -0.7, 0, -0.85, 0.106, -0.7)
        dome.closeSubpath()
        pen.fill(dome)
        pen.fill(pen.rect(-0.132, -0.564, 0.132, -0.51))
        pen.fill(room, Color(0x05060C))
        house.addPath(pen.seg(-0.132, -0.51, 0.132, -0.51))
        house.addPath(pen.seg(-0.132, -0.51, -0.074, -0.474))
        house.addPath(pen.seg(0.132, -0.51, 0.074, -0.474))
        house.addPath(pen.seg(-0.132, -0.564, 0.132, -0.564))
        for x in stride(from: -0.132, through: 0.133, by: 0.066) { house.addPath(pen.seg(x, -0.51, x, -0.564)) }
        house.addPath(room)
        house.addPath(pen.seg(-0.03, -0.7, -0.03, -0.564))
        house.addPath(pen.seg(0.03, -0.7, 0.03, -0.564))
        house.addPath(dome)
        house.addPath(pen.circle(0, -0.792, 0.0156))
        house.addPath(pen.seg(0, -0.808, 0, -0.856))
        pen.line([(rock, ink, 0.8), (house, ink, 1)])

        // Vignette 0: the lantern.
        if played.contains(0) {
            // Its panes broken to the teeth left in their frames, the first plank nailed over the left one, and the
            // neighbour up a stepladder on the gallery with the next, hammer raised.
            var broken = Path()
            for side in [-1.0, 1] {
                func m(_ u: Double, _ v: Double) -> (Double, Double) { (side * u, v) }
                broken.addPath(pen.poly([m(0.09, -0.7), m(0.03, -0.7), m(0.048, -0.674), m(0.062, -0.686), m(0.077, -0.652)]))
                broken.addPath(pen.poly([m(0.09, -0.564), m(0.03, -0.564), m(0.041, -0.596), m(0.058, -0.58), m(0.074, -0.618)]))
            }
            let plank = pen.poly([(-0.1, -0.656), (0.0, -0.664), (0.0, -0.642), (-0.1, -0.634)])
            pen.fill(plank)
            let ladder = Path { l in
                l.move(to: pen.p(0.1, -0.51)); l.addLine(to: pen.p(0.112, -0.575))
                l.move(to: pen.p(0.15, -0.51)); l.addLine(to: pen.p(0.138, -0.575))
                l.move(to: pen.p(0.104, -0.532)); l.addLine(to: pen.p(0.146, -0.532))
                l.move(to: pen.p(0.108, -0.555)); l.addLine(to: pen.p(0.142, -0.555))
                l.move(to: pen.p(0.11, -0.575)); l.addLine(to: pen.p(0.14, -0.575))
            }
            var who = Figure.standing(.neighbour)
            who.head = (-0.05, 0.9)
            who.neck = (-0.03, 0.79)
            who.arms = [[(-0.03, 0.77), (-0.22, 0.84), (-0.33, 0.76)], [(-0.03, 0.77), (-0.13, 0.9), (-0.22, 0.98)]]
            let figure = who.path(pen, x: 0.122, y: -0.575, h: 0.12)
            let next = pen.poly([(-0.005, -0.62), (0.085, -0.628), (0.085, -0.608), (-0.005, -0.6)])
            let hammer = Path { hm in
                hm.move(to: pen.p(0.097, -0.704)); hm.addLine(to: pen.p(0.098, -0.68))
                hm.move(to: pen.p(0.089, -0.704)); hm.addLine(to: pen.p(0.106, -0.704))
            }
            pen.fill(next)
            pen.fill(figure)
            pen.line([(broken, ink, 0.9), (plank, ink, 1), (next, ink, 1), (ladder, ink, 0.9), (figure, ink, 1), (hammer, ink, 1)],
                     glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            // Boarded: three planks across the room, nail heads at their ends, and a gull back on the rail.
            var planks = Path()
            for (y, tilt) in [(-0.684, 0.006), (-0.643, -0.005), (-0.602, 0.004)] {
                let board = pen.poly([(-0.1, y - tilt), (0.1, y + tilt), (0.1, y + tilt + 0.022), (-0.1, y - tilt + 0.022)])
                pen.fill(board)
                planks.addPath(board)
            }
            let gull = Path { g in
                g.addPath(pen.ellipse(-0.105, -0.588, 0.026, 0.012))
                g.addPath(pen.circle(-0.08, -0.606, 0.009))
                g.move(to: pen.p(-0.073, -0.606)); g.addLine(to: pen.p(-0.062, -0.603))
                g.move(to: pen.p(-0.1, -0.576)); g.addLine(to: pen.p(-0.102, -0.566))
                g.move(to: pen.p(-0.13, -0.585)); g.addLine(to: pen.p(-0.142, -0.592))
            }
            pen.fill(gull)
            pen.line([(planks, ink, 1), (gull, ink, 1)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }

        // The quay on the left, the neighbour's gable past the core with its chimney, and the cottage.
        let quayTop = 0.30
        pen.fill(pen.rect(-1, quayTop, 0, 0.41))
        pen.fill(pen.poly([(-0.99, quayTop), (-0.99, -0.02), (-0.845, -0.12), (-0.70, -0.02), (-0.70, quayTop)]))
        pen.fill(pen.rect(-0.81, -0.135, -0.78, -0.08))
        let walls = pen.rect(-0.62, 0.02, -0.04, quayTop)
        let roof = pen.poly([(-0.66, 0.03), (-0.33, -0.13), (0, 0.03)])
        pen.fill(walls)
        pen.fill(roof)
        pen.fill(pen.rect(-0.54, -0.11, -0.49, -0.02))
        var stone = Path()
        stone.addPath(pen.seg(-1, quayTop, 0, quayTop))
        stone.addPath(pen.seg(0, quayTop, 0, 0.41))
        stone.addPath(pen.seg(-1, 0.355, 0, 0.355))
        stone.addPath(pen.seg(-1, 0.41, 0, 0.41))
        for (i, x) in stride(from: -0.98, to: -0.01, by: 0.11).enumerated() {
            let o = i % 2 == 0 ? 0.0 : 0.055
            stone.addPath(pen.seg(x + o, quayTop, x + o, 0.355))
            stone.addPath(pen.seg(x + 0.055 - o, 0.355, x + 0.055 - o, 0.41))
        }
        var cottage = Path()
        cottage.addPath(walls)
        cottage.addPath(roof)
        cottage.addPath(pen.poly([(-0.54, -0.028), (-0.54, -0.11), (-0.49, -0.11), (-0.49, -0.052)], closed: false))
        cottage.addPath(pen.seg(-0.615, 0.03, -0.045, 0.03))
        let window = pen.rect(-0.6, 0.09, -0.49, 0.18)
        let doorway = pen.rect(-0.26, 0.14, -0.165, quayTop)
        cottage.addPath(window)
        cottage.addPath(pen.seg(-0.545, 0.09, -0.545, 0.18))
        cottage.addPath(pen.seg(-0.6, 0.135, -0.49, 0.135))
        cottage.addPath(doorway)
        cottage.addPath(pen.poly([(-0.99, -0.02), (-0.845, -0.12), (-0.70, -0.02), (-0.70, quayTop)], closed: false))
        cottage.addPath(pen.poly([(-0.81, -0.08), (-0.81, -0.135), (-0.78, -0.135), (-0.78, -0.08)], closed: false))
        cottage.addPath(pen.poly([(-0.045, quayTop), (-0.045, 0.265), (-0.055, 0.258), (0.005, 0.258), (-0.005, 0.265), (-0.005, quayTop)],
                                 closed: false))
        pen.line([(stone, ink, 0.6), (cottage, ink, 1)])

        // Vignette 2: the cottage door.
        if played.contains(2) {
            // Open on the dark kitchen, the door back against the wall inside, and a neighbour on the step sweeping the
            // night's water and weed out onto the quay.
            pen.fill(doorway, Color(0x020308))
            var who = Figure.standing(.neighbour)
            who.head = (0.06, 0.88)
            who.neck = (0.04, 0.78)
            who.hip = (-0.02, 0.48)
            who.legs = [[(-0.02, 0.48), (0.06, 0.26), (0.08, 0.02)], [(-0.02, 0.48), (-0.08, 0.25), (-0.12, 0.02)]]
            who.arms = [[(0.04, 0.76), (0.14, 0.6), (0.2, 0.5)], [(0.04, 0.76), (0.1, 0.66), (0.17, 0.62)]]
            let figure = who.path(pen, x: -0.2, y: quayTop, h: 0.13)
            let broom = Path { b in
                b.move(to: pen.p(-0.185, 0.19)); b.addLine(to: pen.p(-0.13, quayTop - 0.012))
                b.addPath(pen.poly([(-0.142, quayTop - 0.02), (-0.112, quayTop - 0.004), (-0.118, quayTop + 0.002), (-0.15, quayTop - 0.008)]))
            }
            var swept = Path()
            for (x, y, l) in [(-0.105, 0.296, 0.03), (-0.115, 0.288, 0.02), (-0.09, 0.302, 0.025)] {
                swept.addPath(pen.seg(x, y, x + l, y + 0.003))
            }
            let weed = Path { w in
                w.addPath(pen.smooth([(-0.12, 0.299), (-0.105, 0.29), (-0.09, 0.297), (-0.078, 0.29)]))
                w.addPath(pen.smooth([(-0.11, 0.3), (-0.1, 0.292), (-0.094, 0.3)]))
            }
            pen.fill(figure)
            pen.line([(pen.rect(-0.258, 0.142, -0.246, quayTop - 0.002), ink, 0.6), (figure, ink, 1), (broom, ink, 1),
                      (swept, Self.sea, 0.9), (weed, ink, 0.8)], glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            // Shut, its boards and latch, and the lamp lit in the window.
            let door = Path { d in
                d.addPath(pen.seg(-0.229, 0.145, -0.229, quayTop - 0.004))
                d.addPath(pen.seg(-0.196, 0.145, -0.196, quayTop - 0.004))
                d.addPath(pen.seg(-0.255, 0.18, -0.17, 0.18))
                d.addPath(pen.seg(-0.255, 0.26, -0.17, 0.26))
                d.addPath(pen.circle(-0.18, 0.225, 0.006))
            }
            pen.fill(window, light.opacity(0.35))
            neon(pen.ctx, r: pen.r) { g in
                g.stroke(window, with: .color(light), style: pen.style)
                g.stroke(pen.seg(-0.545, 0.09, -0.545, 0.18), with: .color(light), style: pen.style)
                g.stroke(pen.seg(-0.6, 0.135, -0.49, 0.135), with: .color(light), style: pen.style)
            }
            pen.line([(door, ink, 0.9)])
        }

        // Vignette 1: the boat on the slip, its hull the same in both states.
        let hard = pen.poly([(0, 0.41), (0.74, 0.43), (0.7, 0.5), (0, 0.5)])
        pen.fill(hard)
        var slip = Path()
        slip.addPath(pen.poly([(0, 0.41), (0.74, 0.43), (0.7, 0.5)], closed: false))
        slip.addPath(pen.seg(0.02, 0.47, 0.71, 0.47))
        for x in stride(from: 0.06, through: 0.7, by: 0.08) { slip.addPath(pen.seg(x, 0.412 + 0.027 * x, x - 0.012, 0.47)) }
        let hull = Path { h in
            h.move(to: pen.p(0.215, 0.305)); h.addLine(to: pen.p(0.6, 0.3))
            h.addQuadCurve(to: pen.p(0.555, 0.405), control: pen.p(0.6, 0.37))
            h.addLine(to: pen.p(0.26, 0.405))
            h.addQuadCurve(to: pen.p(0.215, 0.305), control: pen.p(0.22, 0.37))
        }
        let chocks = Path { c in
            c.addPath(pen.poly([(0.3, 0.405), (0.32, 0.43), (0.28, 0.43)]))
            c.addPath(pen.poly([(0.5, 0.405), (0.52, 0.43), (0.48, 0.43)]))
        }
        if played.contains(1) {
            // The father standing in it, drawn first so the hull hides him below the gunwale.
            var who = Figure.standing(.father)
            who.head = (0.24, 0.82)
            who.neck = (0.16, 0.74)
            who.hip = (0, 0.5)
            who.arms = [[(0.2, 0.72), (0.3, 0.6), (0.4, 0.56)], [(0.12, 0.7), (0.26, 0.58), (0.36, 0.53)]]
            pen.solid(who.path(pen, x: 0.48, y: 0.375, h: 0.15), ink)
        }
        pen.fill(hull)
        var boat = Path()
        boat.addPath(hull)
        boat.addPath(pen.seg(0.225, 0.33, 0.592, 0.326))
        boat.addPath(chocks)
        pen.line([(slip, ink, 0.6), (boat, ink, 1)])
        if played.contains(1) {
            // The mast still down along the thwarts, and the father bent over the side, bailing.
            let mast = pen.seg(0.25, 0.318, 0.43, 0.322)
            let bucket = pen.poly([(0.522, 0.31), (0.548, 0.31), (0.544, 0.334), (0.526, 0.334)])
            var spill = Path()
            for (x, y) in [(0.585, 0.292), (0.6, 0.31), (0.572, 0.278)] { spill.addPath(pen.circle(x, y, 0.005)) }
            spill.addPath(pen.quad(0.548, 0.31, 0.575, 0.288, 0.598, 0.322))
            pen.fill(bucket)
            pen.line([(mast, ink, 0.8), (bucket, ink, 1), (spill, Self.sea, 0.9)], glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            // Bailed and upright: the mast stepped, its stays set, the pennant flying.
            var rig = Path()
            rig.addPath(pen.seg(0.52, 0.3, 0.52, 0.06))
            rig.addPath(pen.seg(0.52, 0.075, 0.59, 0.296))
            rig.addPath(pen.seg(0.52, 0.075, 0.47, 0.3))
            let pennant = pen.poly([(0.52, 0.062), (0.586, 0.07), (0.52, 0.086)])
            pen.line([(rig, ink, 0.9), (pennant, Self.glow, 1)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }
    }
}

extension Pen {
    /// A gull standing at (x, y) (its feet), `s` long, facing right when `f` is 1.
    func gull(_ x: Double, _ y: Double, _ s: Double, facing f: Double = 1) -> Path {
        func q(_ u: Double, _ v: Double) -> (Double, Double) { (x + f * u * s, y - v * s) }
        return Path { g in
            g.addPath(poly([q(-0.5, 0.42), q(-0.1, 0.62), q(0.25, 0.62), q(0.42, 0.46), q(0.1, 0.3), q(-0.3, 0.34)]))
            g.addPath(circle(q(0.36, 0.78).0, q(0.36, 0.78).1, 0.13 * s))
            g.move(to: p(q(0.48, 0.8).0, q(0.48, 0.8).1)); g.addLine(to: p(q(0.66, 0.76).0, q(0.66, 0.76).1))
            g.move(to: p(q(0, 0.32).0, q(0, 0.32).1)); g.addLine(to: p(q(0, 0).0, q(0, 0).1))
            g.move(to: p(q(0.12, 0.32).0, q(0.12, 0.32).1)); g.addLine(to: p(q(0.14, 0).0, q(0.14, 0).1))
        }
    }

    /// A gull in flight, its wings an open M, `s` across.
    func flying(_ x: Double, _ y: Double, _ s: Double) -> Path {
        Path { g in
            g.move(to: p(x - s / 2, y + 0.05 * s))
            g.addQuadCurve(to: p(x, y + 0.12 * s), control: p(x - s / 4, y - 0.22 * s))
            g.addQuadCurve(to: p(x + s / 2, y + 0.05 * s), control: p(x + s / 4, y - 0.22 * s))
        }
    }

    /// A gull asleep, head tucked into its back, at (x, y) (its feet).
    func sleeping(_ x: Double, _ y: Double, _ s: Double) -> Path {
        Path { g in
            g.addPath(ellipse(x, y - 0.4 * s, 0.42 * s, 0.3 * s))
            g.addPath(circle(x + 0.2 * s, y - 0.66 * s, 0.13 * s))
            g.move(to: p(x - 0.42 * s, y - 0.42 * s)); g.addLine(to: p(x - 0.6 * s, y - 0.5 * s))
        }
    }

    /// Glass panes smashed to the teeth left in a frame from x0 to x1, top t to bottom b.
    func teeth(_ x0: Double, _ x1: Double, _ t: Double, _ b: Double) -> Path {
        let w = x1 - x0, hgt = b - t
        return Path { g in
            g.addPath(poly([(x0, t), (x1, t), (x1 - 0.2 * w, t + 0.22 * hgt), (x1 - 0.45 * w, t + 0.1 * hgt), (x0 + 0.3 * w, t + 0.3 * hgt),
                            (x0 + 0.1 * w, t + 0.12 * hgt)]))
            g.addPath(poly([(x0, b), (x1, b), (x1 - 0.15 * w, b - 0.3 * hgt), (x1 - 0.4 * w, b - 0.12 * hgt), (x0 + 0.35 * w, b - 0.36 * hgt),
                            (x0 + 0.12 * w, b - 0.18 * hgt)]))
        }
    }
}

/// The family's dog, built as a figure is: parts in its own units (its height to the top of its head 1, feet at the
/// origin, y up, facing +x), their union outlined.
struct Dog {
    typealias Pt = (Double, Double)
    /// Each part a run of points stroked at a width, or a disc where the run is one point.
    var parts: [(pts: [Pt], width: Double)]

    /// Sitting up, tail curled up behind.
    static let sitting = Dog(parts: [
        ([(-0.12, 0.2)], 0.44), ([(-0.06, 0.3), (0.12, 0.66)], 0.3), ([(0.18, 0.86)], 0.3), ([(0.24, 0.84), (0.42, 0.8)], 0.14),
        ([(0.1, 0.95), (0.06, 1.05), (0.15, 0.98)], 0.08), ([(0.1, 0.55), (0.14, 0.04), (0.2, 0.03)], 0.11),
        ([(0.02, 0.5), (0.04, 0.04), (0.1, 0.03)], 0.1), ([(-0.3, 0.12), (-0.48, 0.32), (-0.44, 0.62)], 0.08),
        ([(-0.1, 0.04), (0.06, 0.04)], 0.1),
    ])
    /// Head down, nose to the ground, tail out.
    static let sniffing = Dog(parts: [
        ([(-0.4, 0.55), (0.15, 0.52)], 0.36), ([(0.12, 0.52), (0.38, 0.24)], 0.24), ([(0.42, 0.2)], 0.24),
        ([(0.46, 0.14), (0.56, 0.04)], 0.12), ([(0.32, 0.3), (0.24, 0.4)], 0.1),
        ([(0.1, 0.42), (0.16, 0.2), (0.12, 0.02)], 0.11), ([(0.0, 0.42), (0.02, 0.2), (-0.04, 0.02)], 0.11),
        ([(-0.3, 0.45), (-0.38, 0.22), (-0.3, 0.02)], 0.12), ([(-0.42, 0.45), (-0.5, 0.22), (-0.46, 0.02)], 0.12),
        ([(-0.56, 0.6), (-0.7, 0.74), (-0.74, 0.86)], 0.07),
    ])

    func path(_ pen: Pen, x: Double, y: Double, h: Double, facing f: Double = 1) -> Path {
        func q(_ u: Pt) -> CGPoint { pen.p(x + f * u.0 * h, y - u.1 * h) }
        let shapes: [CGPath] = parts.map { part in
            let w = part.width * h * pen.r
            if part.pts.count == 1 {
                let c = q(part.pts[0])
                return CGPath(ellipseIn: CGRect(x: c.x - w / 2, y: c.y - w / 2, width: w, height: w), transform: nil)
            }
            let path = CGMutablePath()
            path.addLines(between: part.pts.map(q))
            return path.copy(strokingWithWidth: w, lineCap: .round, lineJoin: .round, miterLimit: 4)
        }
        return Path(shapes.dropFirst().reduce(shapes[0]) { $0.union($1) })
    }
}

extension Dawn {
    // MARK: Scene 2, the gallery (6:15 to 5:50): the lighthouse's top from the headland, the town's roofs below.

    /// Rod 3 (top left): a neighbour on the gallery measuring the broken panes with a rule; earlier, the gallery empty,
    /// shards on the deck. Rod 0 (top right): three gulls back on the rail; earlier, the rail bare, spray blowing over.
    /// Rod 1 (bottom right): smoke from three chimneys; earlier, none, and one window lit by a candle. Rod 2 holds the
    /// roofs and a street lamp, still.
    static func gallery(_ pen: Pen, _ played: Set<Int>) {
        let ink = Self.ink, deck = -0.19, rail = -0.27
        // The rock and the tower under the gallery, the lantern room with every pane smashed out, its dome.
        let rock = pen.poly([(-0.32, 0.07), (-0.2, 0.0), (-0.1, -0.012), (0.1, -0.008), (0.22, 0.01), (0.34, 0.07)])
        let tower = pen.poly([(-0.17, 0.01), (-0.13, deck + 0.03), (0.13, deck + 0.03), (0.17, 0.01)])
        let room = pen.rect(-0.17, -0.49, 0.17, deck - 0.005)
        var dome = pen.quad(-0.2, -0.49, 0, -0.72, 0.2, -0.49)
        dome.closeSubpath()
        for path in [rock, tower, dome] { pen.fill(path) }
        pen.fill(room, Color(0x05060C))
        pen.fill(pen.rect(-0.62, rail, 0.62, deck))
        var house = Path()
        house.addPath(tower)
        house.addPath(pen.quad(-0.155, -0.12, 0, -0.1, 0.155, -0.12))
        house.addPath(pen.rect(-0.016, -0.17, 0.016, -0.11))
        house.addPath(room)
        for x in [-0.06, 0.06] { house.addPath(pen.seg(x, -0.49, x, deck - 0.005)) }
        for (x0, x1) in [(-0.17, -0.06), (-0.06, 0.06), (0.06, 0.17)] { house.addPath(pen.teeth(x0 + 0.008, x1 - 0.008, -0.485, deck - 0.01)) }
        house.addPath(dome)
        house.addPath(pen.circle(0, -0.635, 0.022))
        house.addPath(pen.seg(0, -0.657, 0, -0.7))
        house.addPath(pen.seg(-0.62, deck, 0.62, deck))
        house.addPath(pen.seg(-0.62, rail, 0.62, rail))
        for x in stride(from: -0.6, through: 0.61, by: 0.075) { house.addPath(pen.seg(x, rail, x, deck)) }
        house.addPath(pen.seg(-0.62, deck, -0.15, deck + 0.05))
        house.addPath(pen.seg(0.62, deck, 0.15, deck + 0.05))
        pen.line([(rock, ink, 0.8), (house, ink, 1)])

        // The town's roofs in front, gables up, and chimneys; a street lamp, unlit, among the left-hand ones.
        var roofs = Path()
        // Chimney tops first, so the roofs in front cover their feet.
        let chimneys: [(Double, Double)] = [(0.22, 0.3), (0.5, 0.33), (0.58, 0.44)]
        for (x, y) in chimneys {
            let stack = pen.rect(x - 0.016, y - 0.05, x + 0.016, y + 0.06)
            pen.fill(stack)
            roofs.addPath(stack)
        }
        let gables: [(x: Double, w: Double, eave: Double, peak: Double)] = [
            (-0.7, 0.3, 0.46, 0.36), (-0.42, 0.28, 0.54, 0.44), (-0.14, 0.26, 0.64, 0.55), (0.2, 0.3, 0.38, 0.29),
            (0.5, 0.28, 0.42, 0.33), (0.62, 0.24, 0.52, 0.45), (0.28, 0.32, 0.66, 0.56)]
        for g in gables {
            let shape = pen.poly([(g.x - g.w / 2, 1), (g.x - g.w / 2, g.eave), (g.x, g.peak), (g.x + g.w / 2, g.eave), (g.x + g.w / 2, 1)])
            pen.fill(shape)
            roofs.addPath(shape)
        }
        var lamp = Path()
        lamp.addPath(pen.seg(-0.56, 0.5, -0.56, 0.3))
        lamp.addPath(pen.quad(-0.56, 0.3, -0.56, 0.27, -0.53, 0.27))
        lamp.addPath(pen.poly([(-0.53, 0.27), (-0.515, 0.3), (-0.545, 0.3)]))
        var windows = Path()
        for (x, y) in [(-0.42, 0.62), (-0.74, 0.54), (-0.14, 0.72), (0.2, 0.48), (0.62, 0.6), (0.36, 0.74)] {
            windows.addPath(pen.rect(x - 0.022, y - 0.025, x + 0.022, y + 0.025))
        }
        pen.line([(roofs, ink, 0.9), (lamp, ink, 0.8), (windows, ink, 0.7)])

        // Vignette 3: the gallery's left.
        if played.contains(3) {
            var shards = Path()
            for (x, a) in [(-0.28, 0.3), (-0.24, -0.5), (-0.205, 0.9), (-0.5, 0.1), (-0.46, -0.7)] {
                shards.addPath(pen.poly([(x, deck), (x + 0.022 * cos(a), deck - 0.012 - 0.008 * sin(a)), (x + 0.016, deck)]))
            }
            pen.line([(shards, ink, 0.9)], glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            // The neighbour on the gallery, a rule held up against the nearest pane.
            var who = Figure.standing(.neighbour)
            who.arms = [[(0.1, 0.76), (0.2, 0.84), (0.27, 0.95)], [(-0.1, 0.76), (-0.12, 0.6), (-0.1, 0.45)]]
            let figure = who.path(pen, x: -0.222, y: deck, h: 0.14)
            let rule = Path { r in
                r.addPath(pen.seg(-0.183, -0.32, -0.183, -0.41))
                for y in stride(from: -0.33, through: -0.405, by: 0.017) { r.addPath(pen.seg(-0.183, y, -0.172, y)) }
            }
            pen.solid(figure, ink)
            pen.line([(rule, Self.light, 1)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }

        // Vignette 0: the rail's right.
        if played.contains(0) {
            var spray = Path()
            for (x, y, l) in [(0.5, -0.17, 0.07), (0.56, -0.24, 0.06), (0.26, -0.16, 0.06), (0.47, -0.44, 0.05), (0.56, -0.38, 0.06)] {
                spray.addPath(pen.quad(x, y, x - l * 0.4, y - l * 0.8, x - l, y - l * 0.7))
            }
            for (x, y) in [(0.2, -0.24), (0.36, -0.46), (0.48, -0.5), (0.24, -0.42)] { spray.addPath(pen.circle(x, y, 0.006)) }
            pen.line([(spray, Self.sea, 0.9)], glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            var gulls = Path()
            for (x, f) in [(0.17, 1.0), (0.236, -1), (0.485, 1)] { gulls.addPath(pen.gull(x, rail, 0.06, facing: f)) }
            pen.solid(gulls, ink)
        }

        // Vignette 1: the right-hand roofs.
        if played.contains(1) {
            let pane = pen.rect(0.4, 0.46, 0.47, 0.525)
            pen.fill(pane, Self.light.opacity(0.3))
            pen.line([(pane, Self.light, 1), (pen.ellipse(0.435, 0.49, 0.008, 0.016), Self.light, 1), (pen.rect(0.427, 0.506, 0.443, 0.525), Self.light, 1)],
                     glows: [(0.02, 0.45), (0.007, 0.9)])
        } else {
            var smoke = Path()
            for (x, y) in chimneys {
                smoke.addPath(pen.smooth([(x, y - 0.06), (x - 0.018, y - 0.085), (x + 0.012, y - 0.11), (x - 0.006, y - 0.135)]))
            }
            pen.line([(smoke, ink, 0.6)], glows: [(0.02, 0.35), (0.007, 0.8)])
        }
    }
}

extension Figure {
    /// Kneeling, facing right, arms held up and out in front.
    static func kneeling(_ who: Who) -> Figure {
        Figure(who: who, head: (0.05, 0.74), neck: (0.03, 0.62), hip: (-0.02, 0.34),
               legs: [[(0.0, 0.34), (0.2, 0.08), (0.0, 0.04)], [(-0.04, 0.34), (0.14, 0.06), (-0.08, 0.04)]],
               arms: [[(0.08, 0.6), (0.22, 0.58), (0.36, 0.64)], [(0.0, 0.6), (0.16, 0.54), (0.32, 0.6)]])
    }
}

extension Dawn {
    // MARK: Scene 3, the rock pool (5:50 to 5:25): the breakwater's rocks at low tide, the lighthouse door above.

    /// Rod 0 (top): the lighthouse door shut, a coil of rope on its hook; earlier, open, the rope trailing out across the
    /// rocks. Rod 1 (right): the child kneeling at the pool, holding up the green float; earlier, the float bobbing alone
    /// among the weed. Rod 2 (left): the dog sitting, tail up; earlier, nose down, sniffing along towards the pool. The
    /// child kneels in the dog's disc, so the scramble heals the dog first.
    static func rockPool(_ pen: Pen, _ played: Set<Int>) {
        let ink = Self.ink
        // The rocks climbing to the lighthouse's foot, and the tower going up out of sight.
        let mound = pen.poly([(-0.62, -0.3), (-0.4, -0.36), (-0.24, -0.46), (-0.13, -0.52), (0.13, -0.52), (0.26, -0.45), (0.42, -0.35),
                              (0.66, -0.3), (0.66, -0.285), (-0.62, -0.285)])
        let tower = pen.poly([(-0.13, -0.52), (-0.1, -1.0), (0.1, -1.0), (0.13, -0.52)])
        pen.fill(mound)
        pen.fill(tower)
        let doorway = pen.rect(-0.045, -0.69, 0.045, -0.535)
        var house = Path()
        house.addPath(tower)
        house.addPath(pen.quad(-0.118, -0.86, 0, -0.84, 0.118, -0.86))
        house.addPath(doorway)
        house.addPath(pen.poly([(-0.07, -0.52), (-0.07, -0.535), (0.07, -0.535), (0.07, -0.52)], closed: false))
        house.addPath(pen.seg(0.09, -0.66, 0.09, -0.645))
        house.addPath(pen.quad(0.09, -0.645, 0.1, -0.64, 0.105, -0.65))
        pen.line([(house, ink, 1), (pen.poly([(-0.62, -0.3), (-0.4, -0.36), (-0.24, -0.46), (-0.13, -0.52)], closed: false), ink, 0.8),
                  (pen.poly([(0.13, -0.52), (0.26, -0.45), (0.42, -0.35), (0.66, -0.3)], closed: false), ink, 0.8)])

        // Boulders down the breakwater, weed hanging off them; the pool on the right.
        var rocks = Path()
        let boulders: [[(Double, Double)]] = [
            [(-1, -0.05), (-0.8, -0.12), (-0.62, -0.08), (-0.5, 0.02), (-0.52, 0.12), (-1, 0.14)],
            [(-0.56, 0.14), (-0.44, 0.05), (-0.2, 0.04), (-0.08, 0.14), (-0.1, 0.24), (-0.56, 0.26)],
            [(-0.08, 0.12), (0.06, 0.0), (0.3, -0.04), (0.5, 0.02), (0.6, 0.12), (-0.08, 0.16)],
            [(0.6, 0.12), (0.76, -0.02), (1, 0.0), (1, 0.2), (0.6, 0.2)],
            [(-1, 0.42), (-0.8, 0.4), (-0.6, 0.42), (-0.15, 0.42), (0.02, 0.44), (0.24, 0.42), (0.6, 0.44), (0.8, 0.42), (1, 0.44), (1, 1), (-1, 1)],
        ]
        for b in boulders {
            let shape = pen.smooth(b + [b[0]])
            pen.fill(shape)
            rocks.addPath(shape)
        }
        let pool = pen.ellipse(0.43, 0.43, 0.15, 0.04)
        pen.fill(pool, Color(0x080B12))
        var weed = Path()
        for (x, y, l) in [(-0.7, 0.13, 0.05), (-0.62, 0.135, 0.04), (-0.4, 0.25, 0.05), (-0.25, 0.25, 0.04), (0.0, 0.15, 0.05),
                          (0.3, 0.465, 0.03), (0.52, 0.465, 0.03), (0.66, 0.45, 0.04), (0.75, 0.2, 0.05)] {
            weed.addPath(pen.smooth([(x, y), (x + 0.012, y + l * 0.5), (x - 0.006, y + l)]))
        }
        var ripples = Path()
        ripples.addPath(pen.ellipse(0.43, 0.43, 0.15, 0.04))
        ripples.addPath(pen.seg(0.33, 0.43, 0.38, 0.43))
        ripples.addPath(pen.seg(0.48, 0.44, 0.53, 0.44))
        // A marker post at the pool's far side, upright whatever happens round it.
        let post = pen.rect(0.585, 0.2, 0.605, 0.44)
        pen.fill(post)
        pen.line([(rocks, ink, 0.85), (weed, ink, 0.5), (ripples, Self.sea, 0.9), (post, ink, 1),
                  (pen.seg(0.575, 0.2, 0.615, 0.2), ink, 1)])

        // Vignette 0: the door.
        if played.contains(0) {
            pen.fill(doorway, Color(0x020308))
            let leaf = pen.poly([(-0.045, -0.69), (-0.085, -0.675), (-0.085, -0.55), (-0.045, -0.535)])
            pen.fill(leaf)
            let rope = pen.smooth([(0.0, -0.545), (0.04, -0.53), (0.1, -0.535), (0.16, -0.5), (0.2, -0.46), (0.26, -0.43), (0.3, -0.38)])
            pen.line([(leaf, ink, 1), (rope, Self.glow, 0.9)], glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            var door = Path()
            for x in [-0.015, 0.015] { door.addPath(pen.seg(x, -0.685, x, -0.54)) }
            door.addPath(pen.circle(0.03, -0.61, 0.005))
            var coil = Path()
            for k in 0..<3 { coil.addPath(pen.ellipse(0.1, -0.615 + 0.006 * Double(k), 0.024 - 0.003 * Double(k), 0.03)) }
            pen.line([(door, ink, 0.9), (coil, Self.glow, 0.9)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }

        // Vignette 2: the dog, up the rocks.
        if played.contains(2) {
            pen.solid(Dog.sniffing.path(pen, x: -0.32, y: 0.42, h: 0.11), ink)
        } else {
            pen.solid(Dog.sitting.path(pen, x: -0.3, y: 0.42, h: 0.12), ink)
        }

        // Vignette 1: the pool.
        if played.contains(1) {
            Self.drawFloat(pen, 0.45, 0.415, 0.026)
        } else {
            pen.solid(Figure.kneeling(.child).path(pen, x: 0.188, y: 0.42, h: 0.17), ink)
            Self.drawFloat(pen, 0.272, 0.318, 0.026)
        }
    }

    /// The green glass float in its net, the one thing in the town that is always teal.
    static func drawFloat(_ pen: Pen, _ x: Double, _ y: Double, _ radius: Double) {
        let ball = pen.circle(x, y, radius)
        pen.fill(ball, Self.float.opacity(0.25))
        var net = Path()
        net.addPath(pen.seg(x - radius, y, x + radius, y))
        net.addPath(pen.ellipse(x, y, radius * 0.45, radius))
        pen.line([(ball, Self.float, 1), (net, Self.float, 0.7)], glows: [(0.02, 0.5), (0.007, 1)])
    }
}

extension Dawn {
    // MARK: Scene 4, righting the boat (5:25 to 5:05): the beach beside the slip, the horizon high.

    /// Rod 0 (left): three townsfolk, the rope slack at their feet, one waving; earlier, all three leaning back,
    /// hauling. Rod 1 (right): the boat upright on the sand; earlier, keel up and dark. Rod 2 (top): gulls coming back
    /// over a paling sky; earlier, the last stars and a gull asleep on the beacon. Between the cores the rope is one line
    /// in both states. Rod 3 holds a lantern and a bucket on the sand, still.
    static func righting(_ pen: Pen, _ played: Set<Int>) {
        let ink = Self.ink, sand = 0.245, shore = -0.27
        // The sand, from the water's edge down, rippled.
        pen.fill(pen.rect(-1, shore, 1, 1))
        var ripples = Path()
        for (y, x0, x1) in [(-0.2, -0.9, -0.3), (-0.12, 0.62, 0.95), (0.08, -0.95, -0.7), (0.33, 0.3, 0.8), (0.42, -0.8, -0.3),
                            (0.6, 0.35, 0.75), (0.75, -0.6, -0.25)] {
            ripples.addPath(pen.smooth([(x0, y), ((x0 + x1) / 2, y - 0.012), (x1, y)]))
        }
        // The beacon pole standing in the shallows, and the shared run of rope from the haulers' feet to the boat's bow.
        let pole = pen.rect(0.152, -0.66, 0.168, shore + 0.02)
        pen.fill(pole)
        var beacon = Path()
        beacon.addPath(pole)
        beacon.addPath(pen.seg(0.13, -0.66, 0.19, -0.66))
        let rope = pen.smooth([(-0.335, 0.21), (-0.1, 0.17), (0.1, 0.02), (0.26, -0.1), (0.3, -0.14)])
        pen.line([(pen.seg(-1, shore, 1, shore), Self.sea, 0.9), (ripples, ink, 0.35), (beacon, ink, 1), (rope, Self.glow, 0.85)])

        // Rod 3: a lantern and a bucket left on the sand either side of its knob, so up reads in its core.
        var kit = Path()
        kit.addPath(pen.lantern(-0.15, 0.7, size: 0.11))
        kit.addPath(pen.poly([(0.11, 0.63), (0.19, 0.63), (0.18, 0.7), (0.12, 0.7)]))
        kit.addPath(pen.quad(0.11, 0.63, 0.15, 0.59, 0.19, 0.63))
        pen.line([(kit, ink, 0.9)])

        // Vignette 1: the boat, above its knob.
        if played.contains(1) {
            // Keel up, dark, the rope run over it to the far side.
            let hull = Path { h in
                h.move(to: pen.p(0.3, -0.11))
                h.addQuadCurve(to: pen.p(0.45, -0.235), control: pen.p(0.32, -0.23))
                h.addQuadCurve(to: pen.p(0.61, -0.11), control: pen.p(0.59, -0.23))
                h.closeSubpath()
            }
            pen.fill(hull)
            var wreck = Path()
            wreck.addPath(hull)
            wreck.addPath(pen.quad(0.33, -0.13, 0.45, -0.21, 0.59, -0.13))
            wreck.addPath(pen.seg(0.46, -0.235, 0.46, -0.25))
            pen.line([(wreck, ink, 0.55), (pen.smooth([(0.3, -0.14), (0.35, -0.2), (0.45, -0.236), (0.55, -0.2)]), Self.glow, 0.85)],
                     glows: [(0.02, 0.3), (0.007, 0.8)])
        } else {
            let hull = Path { h in
                h.move(to: pen.p(0.3, -0.19)); h.addLine(to: pen.p(0.61, -0.2))
                h.addQuadCurve(to: pen.p(0.55, -0.105), control: pen.p(0.6, -0.13))
                h.addLine(to: pen.p(0.35, -0.105))
                h.addQuadCurve(to: pen.p(0.3, -0.19), control: pen.p(0.305, -0.13))
            }
            pen.fill(hull)
            var boat = Path()
            boat.addPath(hull)
            boat.addPath(pen.seg(0.31, -0.168, 0.6, -0.175))
            boat.addPath(pen.seg(0.44, -0.2, 0.44, -0.25))
            pen.line([(boat, ink, 1), (pen.seg(0.3, -0.14, 0.305, -0.17), Self.glow, 0.85)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }

        // Vignette 0: the haulers, below their knob.
        let xs = [-0.555, -0.462, -0.372]
        if played.contains(0) {
            var people = Path()
            for (i, x) in xs.enumerated() {
                var who = Figure.standing(i == 1 ? .father : .neighbour)
                who.head = (-0.2, 0.86)
                who.neck = (-0.14, 0.76)
                who.hip = (0, 0.47)
                who.legs = [[(0.02, 0.47), (0.14, 0.26), (0.24, 0.03)], [(-0.02, 0.47), (-0.06, 0.24), (-0.08, 0.03)]]
                who.arms = [[(-0.08, 0.72), (0.06, 0.66), (0.2, 0.62)], [(-0.14, 0.72), (0.0, 0.64), (0.16, 0.6)]]
                people.addPath(who.path(pen, x: x, y: sand, h: 0.13))
            }
            pen.solid(people, ink)
            let taut = pen.seg(-0.59, 0.165, -0.335, 0.21)
            pen.line([(taut, Self.glow, 0.85)], glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            var people = Path()
            for (i, x) in xs.enumerated() {
                var who = Figure.standing(i == 1 ? .father : .neighbour)
                if i == 0 { who.arms[1] = [(-0.1, 0.76), (-0.22, 0.9), (-0.3, 1.04)] }
                people.addPath(who.path(pen, x: x, y: sand, h: 0.13, facing: i == 0 ? 1 : -1))
            }
            pen.solid(people, ink)
            let slack = pen.smooth([(-0.335, 0.21), (-0.38, 0.248), (-0.5, 0.256), (-0.58, 0.25), (-0.6, 0.24), (-0.55, 0.236)])
            pen.line([(slack, Self.glow, 0.85)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }

        // Vignette 2: the sky over the beacon.
        if played.contains(2) {
            var stars = Path()
            for (x, y) in [(-0.15, -0.72), (0.03, -0.76), (-0.1, -0.655), (0.12, -0.72), (-0.19, -0.6)] {
                stars.addPath(pen.seg(x - 0.01, y, x + 0.01, y))
                stars.addPath(pen.seg(x, y - 0.01, x, y + 0.01))
            }
            pen.line([(stars, Self.light, 0.8)], glows: [(0.02, 0.4), (0.007, 0.9)])
            pen.solid(pen.sleeping(0.16, -0.665, 0.05), ink)
        } else {
            var gulls = Path()
            for (x, y, w) in [(-0.13, -0.72, 0.06), (0.05, -0.755, 0.05), (-0.07, -0.665, 0.05), (0.13, -0.69, 0.045)] {
                gulls.addPath(pen.flying(x, y, w))
            }
            pen.line([(gulls, ink, 1)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }
    }
}

extension Figure {
    /// Sitting on a seat at 0.4 of the figure's standing height, hands in its lap.
    static func seated(_ who: Who) -> Figure {
        Figure(who: who, head: (0, 0.79), neck: (0, 0.68), hip: (0, 0.42),
               legs: [[(0.03, 0.4), (0.22, 0.4), (0.24, 0.03)], [(-0.03, 0.4), (0.18, 0.4), (0.18, 0.03)]],
               arms: [[(0.08, 0.64), (0.12, 0.5), (0.2, 0.44)], [(-0.08, 0.64), (-0.02, 0.5), (0.14, 0.44)]])
    }
}

extension Dawn {
    // MARK: Scene 5, tea on the quay (5:05 to 4:45): the quay at first grey light, the harbour high behind it.

    /// Rod 3 (top left): the lifeboat moored, its crew gone and its lamp out; earlier, a crewman coiling rope on deck,
    /// the searchlight still on. Rod 2 (bottom left): the three on a bench under one blanket, the child asleep against
    /// her father; earlier, the child awake, standing on the bench and pointing out to sea. Rod 1 (bottom right): three
    /// cups steaming on a crate; earlier, a neighbour pouring from a flask into the first. Rod 0 holds the dark
    /// lighthouse on its breakwater, still.
    static func tea(_ pen: Pen, _ played: Set<Int>) {
        let ink = Self.ink, quay = 0.14, ground = 0.585
        // The breakwater along the horizon and the lighthouse at its end, dark.
        let wall = pen.poly([(-0.2, -0.5), (0.7, -0.5), (0.72, -0.475), (-0.2, -0.485)])
        let tower = pen.poly([(0.34, -0.5), (0.355, -0.74), (0.425, -0.74), (0.44, -0.5)])
        let lantern = pen.rect(0.36, -0.8, 0.42, -0.74)
        for path in [wall, tower, lantern] { pen.fill(path) }
        var light = Path()
        for path in [wall, tower, lantern] { light.addPath(path) }
        light.addPath(pen.quad(0.35, -0.8, 0.39, -0.84, 0.43, -0.8))
        light.addPath(pen.seg(0.39, -0.8, 0.39, -0.74))

        // The lifeboat on its mooring: hull, cabin and the searchlight on its roof.
        let hull = Path { h in
            h.move(to: pen.p(-0.53, -0.485)); h.addLine(to: pen.p(-0.17, -0.48))
            h.addQuadCurve(to: pen.p(-0.22, -0.43), control: pen.p(-0.18, -0.44))
            h.addLine(to: pen.p(-0.48, -0.43))
            h.addQuadCurve(to: pen.p(-0.53, -0.485), control: pen.p(-0.52, -0.44))
        }
        let cabin = pen.rect(-0.43, -0.535, -0.32, -0.485)
        let lamp = pen.rect(-0.405, -0.56, -0.38, -0.538)
        for path in [hull, cabin, lamp] { pen.fill(path) }
        var boat = Path()
        for path in [hull, cabin, lamp] { boat.addPath(path) }
        boat.addPath(pen.seg(-0.52, -0.465, -0.19, -0.462))
        boat.addPath(pen.rect(-0.415, -0.525, -0.39, -0.5))
        boat.addPath(pen.rect(-0.365, -0.525, -0.34, -0.5))
        let mooring = pen.quad(-0.53, -0.475, -0.6, -0.4, -0.66, -0.2)
        pen.line([(light, ink, 0.8), (boat, ink, 1), (mooring, ink, 0.6)])

        // The quay: its edge, a bollard, the bench and the crate on it.
        pen.fill(pen.rect(-1, quay, 1, 1))
        var stone = Path()
        stone.addPath(pen.seg(-1, quay, 1, quay))
        stone.addPath(pen.seg(-1, quay + 0.05, 1, quay + 0.05))
        for x in stride(from: -0.95, through: 0.95, by: 0.14) { stone.addPath(pen.seg(x, quay, x, quay + 0.05)) }
        stone.addPath(pen.seg(-1, ground, 1, ground))
        let bollard = pen.poly([(0.0, quay), (0.0, quay - 0.05), (-0.01, quay - 0.06), (0.06, quay - 0.06), (0.05, quay - 0.05), (0.05, quay)])
        pen.fill(bollard)
        var bench = Path()
        bench.addPath(pen.seg(-0.56, 0.522, -0.22, 0.522))
        bench.addPath(pen.seg(-0.53, 0.522, -0.53, ground))
        bench.addPath(pen.seg(-0.25, 0.522, -0.25, ground))
        let crate = pen.rect(0.46, 0.5, 0.6, ground)
        pen.fill(crate)
        var box = Path()
        box.addPath(crate)
        box.addPath(pen.seg(0.46, 0.542, 0.6, 0.542))
        pen.line([(stone, ink, 0.55), (bollard, ink, 0.9), (bench, ink, 1), (box, ink, 1)])

        // Vignette 3: the lifeboat's deck.
        if played.contains(3) {
            let beam = pen.poly([(-0.405, -0.553), (-0.5, -0.58), (-0.5, -0.53), (-0.405, -0.545)])
            pen.fill(beam, Self.light.opacity(0.3))
            var who = Figure.standing(.crew)
            who.head = (0.1, 0.84)
            who.neck = (0.07, 0.74)
            who.arms = [[(0.12, 0.72), (0.24, 0.6), (0.3, 0.5)], [(0.0, 0.72), (0.14, 0.58), (0.26, 0.48)]]
            pen.solid(who.path(pen, x: -0.275, y: -0.468, h: 0.12), ink)
            var coil = Path()
            for k in 0..<3 { coil.addPath(pen.ellipse(-0.235, -0.515 + 0.004 * Double(k), 0.016 - 0.003 * Double(k), 0.022)) }
            coil.addPath(pen.ellipse(-0.205, -0.47, 0.022, 0.006))
            pen.line([(lamp, Self.light, 1), (coil, Self.glow, 0.9)], glows: [(0.02, 0.45), (0.007, 0.9)])
            pen.fill(pen.rect(-0.401, -0.556, -0.384, -0.542), Self.light)
        } else {
            pen.line([(pen.ellipse(-0.205, -0.47, 0.022, 0.006), Self.glow, 0.9), (pen.ellipse(-0.205, -0.474, 0.014, 0.004), Self.glow, 0.9)],
                     glows: [(0.02, 0.4), (0.007, 0.9)])
        }

        // Vignette 2: the bench.
        let seat = 0.522, h = 0.15
        var family = Path()
        family.addPath(Figure.seated(.grandmother).path(pen, x: -0.49, y: ground, h: h))
        family.addPath(Figure.seated(.father).path(pen, x: -0.4, y: ground, h: h))
        if played.contains(2) {
            var child = Figure.standing(.child)
            child.arms = [[(0.1, 0.76), (0.24, 0.92), (0.36, 1.08)], [(-0.1, 0.76), (-0.15, 0.6), (-0.16, 0.46)]]
            family.addPath(child.path(pen, x: -0.25, y: seat, h: 0.11))
            pen.solid(family, ink)
            let blanket = pen.smooth([(-0.53, seat), (-0.535, 0.49), (-0.49, 0.485), (-0.445, 0.493), (-0.4, 0.485), (-0.355, 0.494),
                                      (-0.35, seat), (-0.53, seat)])
            pen.fill(blanket)
            pen.line([(blanket, Self.glow, 0.9)], glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            var child = Figure.seated(.child)
            child.head = (-0.14, 0.74)
            child.neck = (-0.06, 0.64)
            family.addPath(child.path(pen, x: -0.322, y: ground, h: 0.12))
            pen.solid(family, ink)
            let blanket = pen.smooth([(-0.53, seat), (-0.535, 0.49), (-0.49, 0.485), (-0.445, 0.493), (-0.4, 0.485), (-0.35, 0.497),
                                      (-0.31, 0.5), (-0.28, 0.5), (-0.275, seat), (-0.53, seat)])
            pen.fill(blanket)
            pen.line([(blanket, Self.glow, 0.9)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }

        // Vignette 1: the crate.
        let cups: [Double] = [0.49, 0.53, 0.57]
        var mugs = Path()
        for x in cups {
            mugs.addPath(pen.rect(x - 0.012, 0.475, x + 0.012, 0.5))
            mugs.addPath(pen.quad(x + 0.012, 0.48, x + 0.024, 0.487, x + 0.012, 0.494))
        }
        if played.contains(1) {
            var who = Figure.standing(.neighbour)
            // The pouring hand holds the flask's neck over the first cup.
            who.arms = [[(0.1, 0.76), (0.36, 1.0), (0.6, 1.18)], [(-0.1, 0.76), (-0.12, 0.6), (-0.1, 0.45)]]
            pen.solid(who.path(pen, x: 0.39, y: ground, h: 0.13), ink)
            let flask = pen.poly([(0.465, 0.42), (0.482, 0.408), (0.51, 0.44), (0.493, 0.452)])
            pen.fill(flask)
            pen.line([(mugs, ink, 1), (flask, ink, 1), (pen.seg(0.496, 0.445, 0.49, 0.473), Self.glow, 0.9)],
                     glows: [(0.02, 0.4), (0.007, 0.9)])
        } else {
            var steam = Path()
            for x in cups { steam.addPath(pen.smooth([(x, 0.465), (x - 0.01, 0.45), (x + 0.008, 0.435), (x - 0.004, 0.42)])) }
            pen.line([(mugs, ink, 1), (steam, ink, 0.6)], glows: [(0.02, 0.4), (0.007, 0.9)])
        }
    }
}
