// Copyright © 2026 Jack Lusher. All rights reserved.

import AVFoundation
import SwiftUI

/// What the shelf sells: a pack, or Complete, which grants every pack.
enum Offer: Hashable, Sendable {
    case pack(Pack)
    case complete

    static let all: [Offer] = Pack.allCases.map(Offer.pack) + [.complete]

    /// The covers the dock shows. A pack goes on sale only once it has levels past its taste, and Complete only once every
    /// pack is on sale (Jack, 2026-10-26, S1); a build outside Release shows every cover, so the shop can be looked at.
    static func shelf(release: Bool = Build.release, ready: (Pack) -> Bool = { $0.levels.count > $0.taste }) -> [Offer] {
        guard release else { return all }
        let packs = Pack.allCases.filter(ready)
        return packs.map(Offer.pack) + (packs.count == Pack.allCases.count ? [.complete] : [])
    }

    /// Some of what it sells is still to come.
    var arriving: Bool { (pack.map { [$0] } ?? Pack.allCases).contains { $0.levels.count < $0.planned } }

    /// A pack's prefix, or "complete", as the harness names it and the clip's file is named.
    init?(name: String) {
        if name == "complete" { self = .complete } else if let p = Pack(rawValue: name) { self = .pack(p) } else { return nil }
    }

    var key: String {
        switch self {
        case .pack(let p): p.rawValue
        case .complete: "complete"
        }
    }

    var pack: Pack? { if case .pack(let p) = self { p } else { nil } }

    var name: String { pack?.name ?? "Complete" }

    var productID: String { pack?.productID ?? Pack.completeID }

    var pitch: String {
        switch self {
        case .pack(.firstStir): "a story told backwards"
        case .pack(.lens): "some rods zoom instead of turning"
        case .pack(.escapement): "a clock rod ticks after every move"
        case .complete: "every pack, for less"
        }
    }

    /// What the pack assumes of the player, as its card says it.
    var assumes: String {
        switch self {
        case .pack(.firstStir): "anyone \u{00B7} an evening, not a challenge"
        case .pack(.lens): "after plughole"
        case .pack(.escapement): "hard \u{00B7} composed problems"
        case .complete: "anyone, then harder"
        }
    }

    var holds: String {
        switch self {
        case .pack(.firstStir): "\(Pack.firstStir.planned) scenes in five chapters"
        case .pack(.lens): "\(Pack.lens.planned) panels in four issues"
        case .pack(.escapement): "\(Pack.escapement.planned) problems in five chapters"
        case .complete: "First Stir, Lens and Escapement \u{00B7} \(Pack.allCases.map(\.planned).reduce(0, +)) levels"
        }
    }

    var free: String {
        switch self {
        case .pack(let p): "levels 1\u{2013}\(p.taste) free, no purchase"
        case .complete: "each pack's first 3 levels"
        }
    }

    var sweep: [Color] {
        switch self {
        case .pack(.firstStir): [Color(0xFFC857), Color(0xFF6FA5), Color(0x7A7CFF)]
        case .pack(.lens): [.neonCyan, .magenta, Color(0xFFE600)]
        case .pack(.escapement): [Color(0xF3EAD8), Color(0xD8402A)]
        case .complete: [Color(0xFFC857), .neonCyan, Color(0xD8402A)]
        }
    }

    var glow: Color {
        switch self {
        case .pack(.firstStir): Color(0xFFC857)
        case .pack(.lens): .magenta
        case .pack(.escapement): Color(0xD8402A)
        case .complete: .neonCyan
        }
    }

    /// The pack's levels; before it has any, a Debug build lists `placeholders` of the harness's stand-ins.
    func levels(placeholders: Int = 0) -> [Level] {
        guard let pack else { return [] }
        #if DEBUG
        if pack.levels.isEmpty, placeholders > 0 { return (1...placeholders).map(pack.placeholder) }
        #endif
        return pack.levels
    }

    var gradient: LinearGradient { LinearGradient(colors: sweep, startPoint: .leading, endPoint: .trailing) }

    var layout: Layout {
        switch self {
        case .pack(.lens), .complete: .quad
        default: .tri
        }
    }

    /// The placeholder clip's scramble, bottom first.
    var scramble: [Twist] {
        switch self {
        case .pack(.firstStir): [Twist(rod: 0, steps: 3), Twist(rod: 2, steps: -4), Twist(rod: 1, steps: 5)]
        case .pack(.lens): [Twist(rod: 1, steps: -3), Twist(rod: 3, steps: 4), Twist(rod: 0, steps: 5), Twist(rod: 2, steps: -4)]
        case .pack(.escapement): [Twist(rod: 2, steps: 4), Twist(rod: 0, steps: -5), Twist(rod: 1, steps: 3)]
        case .complete: [Twist(rod: 0, steps: 4), Twist(rod: 2, steps: -5), Twist(rod: 3, steps: 3), Twist(rod: 1, steps: -4)]
        }
    }
}

extension Store {
    /// Complete is owned once its own product or every pack is.
    func state(_ offer: Offer) -> Purchase {
        switch offer {
        case .pack(let p): return state(p)
        case .complete:
            let l = harness ?? ledger
            if Pack.allCases.allSatisfy({ l.state($0) == .owned }) { return .owned }
            return l.products[Pack.completeID] ?? .unowned
        }
    }

    /// The pack whose card a level shows instead of playing: one past its taste that the player doesn't own.
    func card(for level: Level) -> Pack? { access(level) == .needsCard ? level.pack : nil }
}

extension Purchase {
    /// The shelf's one word for a state, nil when there is nothing to say.
    var tag: (word: String, colour: Color)? {
        switch self {
        case .unowned: nil
        case .owned: ("owned", .lime)
        case .pending: ("waiting for approval", .amber)
        case .failed: ("purchase failed", .magenta)
        case .revoked: ("refunded", .alarm)
        }
    }
}

extension Font {
    /// The game's mono at a text style's size, so it follows Dynamic Type.
    static func mono(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }
}

// MARK: - Covers

/// Each offer's cover, baked once per size: the picture its clip stirs.
@MainActor
enum Cover {
    private static var cache: [String: UIImage] = [:]

    static func image(_ offer: Offer, side: CGFloat, scale: CGFloat) -> UIImage? {
        let key = "\(offer.productID) \(side) \(scale)"
        if let image = cache[key] { return image }
        let renderer = ImageRenderer(content: Canvas { ctx, size in draw(offer, ctx, r: size.width / 2) }
            .frame(width: side, height: side))
        renderer.scale = scale
        renderer.isOpaque = true
        renderer.colorMode = .extendedLinear
        let image = renderer.uiImage
        cache[key] = image
        return image
    }

    static func draw(_ offer: Offer, _ ctx: GraphicsContext, r: CGFloat) {
        switch offer {
        case .pack(.firstStir): firstStir(ctx, r: r)
        case .pack(.lens): lens(ctx, r: r)
        case .pack(.escapement): escapement(ctx, r: r)
        case .complete:
            // A third of the tank each, cut from the centre.
            let packs: [Offer] = [.pack(.firstStir), .pack(.lens), .pack(.escapement)]
            for (k, p) in packs.enumerated() {
                var c = ctx
                c.clip(to: wedge(r, from: -150 + 120 * Double(k), to: -30 + 120 * Double(k)))
                draw(p, c, r: r)
            }
            var seams = Path()
            for k in 0..<3 {
                let a = (-150 + 120 * Double(k)) * .pi / 180
                seams.move(to: CGPoint(x: r, y: r))
                seams.addLine(to: CGPoint(x: r + 1.5 * r * cos(a), y: r + 1.5 * r * sin(a)))
            }
            ctx.stroke(seams, with: .color(.white.opacity(0.85)), lineWidth: 0.008 * r)
        }
    }

    private static func wedge(_ r: CGFloat, from a0: Double, to a1: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r, y: r))
        p.addArc(center: CGPoint(x: r, y: r), radius: 1.5 * r, startAngle: .degrees(a0), endAngle: .degrees(a1), clockwise: false)
        p.closeSubpath()
        return p
    }

    /// Tank units (radius 1, y down) to points.
    private struct Units {
        let r: CGFloat
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: r + x * r, y: r + y * r) }
        func circle(_ x: Double, _ y: Double, _ rad: Double) -> Path {
            Path(ellipseIn: CGRect(x: r + (x - rad) * r, y: r + (y - rad) * r, width: 2 * rad * r, height: 2 * rad * r))
        }
        func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> Path {
            Path(ellipseIn: CGRect(x: r + (x - rx) * r, y: r + (y - ry) * r, width: 2 * rx * r, height: 2 * ry * r))
        }
        func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Path {
            var path = Path()
            path.move(to: p(x0, y0))
            path.addLine(to: p(x1, y1))
            return path
        }
    }

    /// The night's last scene, its first stir: a cup of tea under a rainy window, the lighthouse out at sea.
    private static func firstStir(_ ctx: GraphicsContext, r: CGFloat) {
        let u = Units(r: r)
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 2 * r, height: 2 * r)), with: .color(.black))
        let gold = Color(0xFFC857), rose = Color(0xFF6FA5), indigo = Color(0x7A7CFF), teal = Color(0x2EE6C5)
        let amber = Color(0xFFB000), w = 0.016 * r
        neon(ctx, r: r, glows: [(0.04, 0.35), (0.01, 0.8)]) { g in
            // The window and its cross.
            g.stroke(Path(roundedRect: CGRect(x: u.p(-0.62, -0.84).x, y: u.p(-0.62, -0.84).y, width: 1.24 * r, height: 0.78 * r),
                          cornerRadius: 0.05 * r), with: .color(indigo), lineWidth: w)
            g.stroke(u.line(0, -0.84, 0, -0.06), with: .color(indigo), lineWidth: w)
            g.stroke(u.line(-0.62, -0.47, 0.62, -0.47), with: .color(indigo), lineWidth: w)
            // Rain, slanting one way.
            var rng = SplitMix64(state: 5)
            var rain = Path()
            for _ in 0..<30 {
                let x = Double.random(in: -0.56..<0.5, using: &rng), y = Double.random(in: -0.8 ..< -0.2, using: &rng)
                rain.addPath(u.line(x, y, x + 0.03, y + 0.08))
            }
            g.stroke(rain, with: .color(indigo.opacity(0.7)), lineWidth: 0.6 * w)
            // A crescent moon in the top right pane.
            var moon = Path()
            moon.addArc(center: u.p(0.34, -0.68), radius: 0.09 * r, startAngle: .degrees(-40), endAngle: .degrees(200), clockwise: false)
            moon.addArc(center: u.p(0.38, -0.71), radius: 0.07 * r, startAngle: .degrees(195), endAngle: .degrees(-35), clockwise: true)
            g.stroke(moon, with: .color(amber), lineWidth: w)
            // The sea and the lighthouse, its beam to the right.
            var sea = Path()
            sea.move(to: u.p(-0.6, -0.2))
            for k in 1...12 {
                let x = -0.6 + 0.1 * Double(k)
                sea.addQuadCurve(to: u.p(x, -0.2), control: u.p(x - 0.05, k % 2 == 0 ? -0.24 : -0.16))
            }
            g.stroke(sea, with: .color(teal), lineWidth: w)
            var tower = Path()
            tower.move(to: u.p(-0.38, -0.2))
            tower.addLine(to: u.p(-0.34, -0.38))
            tower.addLine(to: u.p(-0.28, -0.38))
            tower.addLine(to: u.p(-0.24, -0.2))
            g.stroke(tower, with: .color(amber), lineWidth: w)
            g.stroke(u.line(-0.27, -0.38, -0.06, -0.44), with: .color(amber.opacity(0.6)), lineWidth: 0.6 * w)
            g.stroke(u.line(-0.27, -0.38, -0.06, -0.32), with: .color(amber.opacity(0.6)), lineWidth: 0.6 * w)
            // The table's edge, the saucer and the cup.
            g.stroke(u.line(-0.98, 0.56, 0.98, 0.56), with: .color(rose.opacity(0.8)), lineWidth: w)
            g.stroke(u.ellipse(0, 0.47, 0.38, 0.07), with: .color(gold), lineWidth: w)
            g.stroke(u.ellipse(0, 0.12, 0.27, 0.06), with: .color(gold), lineWidth: w)
            var cup = Path()
            cup.move(to: u.p(-0.27, 0.12))
            cup.addCurve(to: u.p(0, 0.44), control1: u.p(-0.27, 0.34), control2: u.p(-0.16, 0.44))
            cup.addCurve(to: u.p(0.27, 0.12), control1: u.p(0.16, 0.44), control2: u.p(0.27, 0.34))
            cup.move(to: u.p(0.25, 0.18))
            cup.addCurve(to: u.p(0.2, 0.36), control1: u.p(0.46, 0.14), control2: u.p(0.44, 0.38))
            g.stroke(cup, with: .color(gold), lineWidth: w)
            // The stir in the tea.
            var swirl = Path()
            for k in 0...60 {
                let t = Double(k) / 60, a = 3 * .pi * t, rad = 0.2 * (1 - t) + 0.02
                let q = u.p(rad * cos(a), 0.12 + 0.22 * rad * sin(a))
                if k == 0 { swirl.move(to: q) } else { swirl.addLine(to: q) }
            }
            g.stroke(swirl, with: .color(rose), lineWidth: 0.7 * w)
            // Steam rising into the window.
            var steam = Path()
            for x0 in [-0.11, 0.0, 0.11] {
                steam.move(to: u.p(x0, 0.0))
                steam.addCurve(to: u.p(x0, -0.3), control1: u.p(x0 + 0.08, -0.1), control2: u.p(x0 - 0.08, -0.2))
            }
            g.stroke(steam, with: .color(rose.opacity(0.85)), lineWidth: 0.8 * w)
        }
    }

    /// An eye in three dot screens, white ink over them: the screen's pitch is the ruler a zoom is read against.
    private static func lens(_ ctx: GraphicsContext, r: CGFloat) {
        let u = Units(r: r)
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 2 * r, height: 2 * r)), with: .color(.black))
        let pitch = 0.036, cy = -0.04
        // The eye's almond: |y - cy| under a parabola between the corners at x = ±0.74.
        func inAlmond(_ x: Double, _ y: Double) -> Bool { abs(y - cy) < 0.3 * (1 - (x / 0.74) * (x / 0.74)) }
        func screen(_ degrees: Double, _ coverage: (Double, Double) -> Double) -> Path {
            let a = degrees * .pi / 180, c = cos(a), s = sin(a)
            var dots = Path()
            for i in -32...32 {
                for j in -32...32 {
                    let gx = Double(i) * pitch, gy = Double(j) * pitch
                    let x = gx * c - gy * s, y = gx * s + gy * c
                    guard x * x + y * y < 1.1 else { continue }
                    let k = coverage(x, y)
                    guard k > 0.02 else { continue }
                    dots.addPath(u.circle(x, y, 0.56 * pitch * sqrt(min(k, 1))))
                }
            }
            return dots
        }
        var g = ctx
        g.blendMode = .plusLighter
        let iris = 0.26, pupil = 0.1
        g.fill(screen(15) { x, y in
            let d = hypot(x, y - cy)
            return d < iris && d > pupil ? 0.25 + 0.75 * (d - pupil) / (iris - pupil) : 0
        }, with: .color(.neonCyan))
        g.fill(screen(75) { x, y in inAlmond(x, y) ? 0 : 0.85 - 0.8 * (y + 1) / 2 }, with: .color(.magenta))
        g.fill(screen(0) { x, y in inAlmond(x, y) ? 0 : 0.05 + 0.8 * (y + 1) / 2 }, with: .color(Color(0xFFE600)))
        let ink = Color.white, w = 0.014 * r
        var almond = Path()
        almond.move(to: u.p(-0.74, cy))
        almond.addQuadCurve(to: u.p(0.74, cy), control: u.p(0, cy - 0.6))
        almond.addQuadCurve(to: u.p(-0.74, cy), control: u.p(0, cy + 0.6))
        ctx.stroke(almond, with: .color(ink), lineWidth: 1.4 * w)
        ctx.stroke(u.circle(0, cy, iris), with: .color(ink), lineWidth: w)
        ctx.fill(u.circle(0, cy, pupil), with: .color(.black))
        ctx.stroke(u.circle(0, cy, pupil), with: .color(ink), lineWidth: w)
        ctx.fill(u.circle(0.07, cy - 0.1, 0.035), with: .color(ink))
        // Lashes over the upper lid only, so up reads in the eye.
        var lashes = Path()
        for k in 0..<7 {
            let x = -0.5 + Double(k) / 6
            let y = cy - 0.3 * (1 - (x / 0.74) * (x / 0.74))
            lashes.addPath(u.line(x, y, x * 1.15, y - 0.13))
        }
        ctx.stroke(lashes, with: .color(ink), lineWidth: w)
        // A glint, top right.
        var star = Path()
        let sx = 0.56, sy = -0.58
        star.move(to: u.p(sx, sy - 0.13))
        star.addQuadCurve(to: u.p(sx + 0.13, sy), control: u.p(sx + 0.02, sy - 0.02))
        star.addQuadCurve(to: u.p(sx, sy + 0.13), control: u.p(sx + 0.02, sy + 0.02))
        star.addQuadCurve(to: u.p(sx - 0.13, sy), control: u.p(sx - 0.02, sy + 0.02))
        star.addQuadCurve(to: u.p(sx, sy - 0.13), control: u.p(sx - 0.02, sy - 0.02))
        ctx.fill(star, with: .color(ink))
        // The registration mark, bottom left.
        let m = (-0.5, 0.62)
        ctx.stroke(u.circle(m.0, m.1, 0.06), with: .color(ink), lineWidth: 0.6 * w)
        ctx.stroke(u.line(m.0 - 0.1, m.1, m.0 + 0.1, m.1), with: .color(ink), lineWidth: 0.6 * w)
        ctx.stroke(u.line(m.0, m.1 - 0.1, m.0, m.1 + 0.1), with: .color(ink), lineWidth: 0.6 * w)
    }

    /// A plate from the problem book: engine-turned rays, a barleycorn band, the clock's vermilion sub-dial and the
    /// ratchet, in ink on bone paper. Ink lines keep to 2 px or more, or the four-tap average fades them on paper.
    private static func escapement(_ ctx: GraphicsContext, r: CGFloat) {
        let u = Units(r: r)
        let paper = Color(0xF3EAD8), ink = Color(0x1A1A1A), red = Color(0xD8402A)
        let hair = max(0.006 * r, 2 / 3), w = max(0.012 * r, 1)
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 2 * r, height: 2 * r)), with: .color(paper))
        var rays = Path()
        for k in 0..<44 {
            let a = (2 + 2 * Double(k)) * .pi / 180
            rays.addPath(u.line(-0.95, -0.95, -0.95 + 2.8 * cos(a), -0.95 + 2.8 * sin(a)))
        }
        ctx.stroke(rays, with: .color(ink.opacity(0.85)), lineWidth: hair)
        // The barleycorn band, across the bottom.
        ctx.fill(Path(CGRect(x: 0, y: u.p(0, 0.42).y, width: 2 * r, height: 0.26 * r)), with: .color(paper))
        var corn = Path()
        corn.addPath(u.line(-1, 0.42, 1, 0.42))
        corn.addPath(u.line(-1, 0.68, 1, 0.68))
        for row in 0..<5 {
            let y = 0.46 + 0.045 * Double(row)
            corn.move(to: u.p(-1, y))
            var x = -1.0, up = true
            while x < 1 {
                x += 0.04
                corn.addLine(to: u.p(x, y + (up ? -0.018 : 0.018)))
                up.toggle()
            }
        }
        ctx.stroke(corn, with: .color(ink), lineWidth: hair)
        // The ratchet: saw teeth, a hub and the pawl resting in a tooth.
        let rc = (-0.42, 0.08)
        ctx.fill(u.circle(rc.0, rc.1, 0.25), with: .color(paper))
        var wheel = Path()
        for k in 0...12 {
            let a0 = Double(k) / 12 * 2 * .pi - .pi / 2, a1 = a0 + 2 * .pi / 12 * 0.85
            let outer = u.p(rc.0 + 0.22 * cos(a0), rc.1 + 0.22 * sin(a0))
            if k == 0 { wheel.move(to: outer) } else { wheel.addLine(to: outer) }
            wheel.addLine(to: u.p(rc.0 + 0.16 * cos(a1), rc.1 + 0.16 * sin(a1)))
            wheel.addLine(to: u.p(rc.0 + 0.16 * cos(a0 + 2 * .pi / 12), rc.1 + 0.16 * sin(a0 + 2 * .pi / 12)))
        }
        ctx.stroke(wheel, with: .color(ink), lineWidth: w)
        ctx.stroke(u.circle(rc.0, rc.1, 0.04), with: .color(ink), lineWidth: w)
        var pawl = Path()
        pawl.move(to: u.p(rc.0 + 0.3, rc.1 - 0.3))
        pawl.addQuadCurve(to: u.p(rc.0 + 0.05, rc.1 - 0.2), control: u.p(rc.0 + 0.14, rc.1 - 0.32))
        ctx.stroke(pawl, with: .color(ink), lineWidth: w)
        ctx.fill(u.circle(rc.0 + 0.3, rc.1 - 0.3, 0.025), with: .color(ink))
        // The clock's sub-dial, twelve at the top.
        let dc = (0.3, -0.2), dr = 0.3
        ctx.fill(u.circle(dc.0, dc.1, dr), with: .color(paper))
        ctx.stroke(u.circle(dc.0, dc.1, dr), with: .color(red), lineWidth: w)
        ctx.stroke(u.circle(dc.0, dc.1, dr - 0.06), with: .color(red), lineWidth: hair)
        var ticks = Path()
        for k in 0..<12 {
            let a = Double(k) / 12 * 2 * .pi - .pi / 2, inner = k % 3 == 0 ? dr - 0.11 : dr - 0.06
            ticks.addPath(u.line(dc.0 + inner * cos(a), dc.1 + inner * sin(a), dc.0 + dr * cos(a), dc.1 + dr * sin(a)))
        }
        ctx.stroke(ticks, with: .color(red), lineWidth: w)
        ctx.draw(Text("12").font(.system(size: 0.075 * r, weight: .semibold, design: .serif)).foregroundStyle(red),
                 at: u.p(dc.0, dc.1 - dr + 0.16))
        let ha: Double = .pi / 3 - .pi / 2
        ctx.stroke(u.line(dc.0, dc.1, dc.0 + 0.19 * cos(ha), dc.1 + 0.19 * sin(ha)), with: .color(ink), lineWidth: 1.6 * w)
        ctx.fill(u.circle(dc.0, dc.1, 0.025), with: .color(ink))
        ctx.draw(Text("Unstir in 4.").font(.system(size: 0.09 * r, design: .serif).italic()).foregroundStyle(ink),
                 at: u.p(0, 0.8))
    }
}

// MARK: - The tank

/// The tank's own map, each entry of `twists` at its own angle (rod, radians), over a flat picture `side` wide.
struct Swirled: ViewModifier {
    let layout: Layout
    let twists: [(rod: Int, angle: Double)]
    let side: CGFloat
    @Environment(\.displayScale) private var scale

    func body(content: Content) -> some View {
        let rods = layout.rods
        var floats = twists.flatMap { [Float(rods[$0.rod].x), Float(rods[$0.rod].y), Float(rods[$0.rod].z), Float($0.angle)] }
        let n = twists.count
        if floats.isEmpty { floats = [0, 0, 0, 0] }
        let r = side / 2
        return content.layerEffect(
            ShaderLibrary.unstir(.float2(r, r), .float(r), .floatArray(floats), .float(Float(n)), .float(30),
                                 .float(Float(Tank.plateau)), .float(Float(Tank.swirlPlateau)), .float(Float(scale)),
                                 .float(0), .float3(0, 0, -1), .float(0)),
            maxSampleOffset: CGSize(width: side, height: side))
    }
}

/// An offer's cover in a tank. `clock` nil draws it still, `stirred` of the way; otherwise the placeholder clip at that
/// time: clean, stirred in bottom first, then unstirred top first a move at a time.
struct PackTank: View {
    let offer: Offer
    let side: CGFloat
    var clock: Double?
    var stirred = 0.4
    @Environment(\.displayScale) private var scale

    static let period = 7.0

    var body: some View {
        let image = Cover.image(offer, side: side, scale: scale)
        let wind = clock.map { Self.wind(offer.scramble.count, at: $0) }
            ?? Array(repeating: stirred, count: offer.scramble.count)
        let twists = zip(offer.scramble, wind).map { ($0.rod, Double($0.steps) * Tank.step * $1) }
        Group {
            if let image { Image(uiImage: image).resizable() } else { Color.black }
        }
        .frame(width: side, height: side)
        .modifier(Swirled(layout: offer.layout, twists: twists, side: side))
        .clipShape(Circle())
        .overlay { Bezel(r: side / 2) }
        .accessibilityHidden(true)
    }

    /// Each entry's share of its turn, 0 clean to 1 stirred, `t` seconds into the clip.
    static func wind(_ m: Int, at t: Double) -> [Double] {
        let t = t.truncatingRemainder(dividingBy: period)
        func ease(_ x: Double) -> Double { let c = min(max(x, 0), 1); return c * c * (3 - 2 * c) }
        return (0..<m).map { k in
            let dIn = 1.2 / Double(m), dOut = 3.2 / Double(m)
            if t < 2.6 { return ease((t - 1.0 - Double(k) * dIn) / dIn) }
            return 1 - ease((t - 3.2 - Double(m - 1 - k) * dOut) / (0.8 * dOut))
        }
    }
}

/// A tank whose clip runs on the clock, unless the harness holds it at `held` seconds. Reduce Motion holds it stirred.
struct LoopingTank: View {
    let offer: Offer
    let side: CGFloat
    var held: Double?
    var offset = 0.0
    /// The dock runs at a lower rate, and stops under the card.
    var interval = 0.0
    var paused = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let held {
            PackTank(offer: offer, side: side, clock: held + offset)
        } else if reduceMotion {
            PackTank(offer: offer, side: side)
        } else {
            TimelineView(.animation(minimumInterval: interval > 0 ? interval : nil, paused: paused)) { tl in
                PackTank(offer: offer, side: side, clock: tl.date.timeIntervalSinceReferenceDate + offset)
            }
        }
    }
}

/// The card's clip: `<key>-clip.mp4` from the bundle once it is filmed, else the cover's own loop in its tank.
struct PackClip: View {
    let offer: Offer
    let side: CGFloat
    var held: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let url = Bundle.main.url(forResource: "\(offer.key)-clip", withExtension: "mp4") {
            LoopingVideo(url: url, playing: held == nil && !reduceMotion)
                .frame(width: side, height: side)
                .clipShape(Circle())
                .overlay { Bezel(r: side / 2) }
                .accessibilityHidden(true)
        } else {
            LoopingTank(offer: offer, side: side, held: held)
        }
    }
}

/// A muted clip on a loop, held on its first frame when not `playing`.
private struct LoopingVideo: UIViewRepresentable {
    let url: URL
    let playing: Bool

    final class Screen: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        let player = AVQueuePlayer()
        var looper: AVPlayerLooper?
    }

    func makeUIView(context: Context) -> Screen {
        let view = Screen()
        let layer = view.layer as! AVPlayerLayer
        layer.player = view.player
        layer.videoGravity = .resizeAspectFill
        view.player.isMuted = true
        view.player.preventsDisplaySleepDuringVideoPlayback = false
        view.looper = AVPlayerLooper(player: view.player, templateItem: AVPlayerItem(url: url))
        return view
    }

    func updateUIView(_ view: Screen, context: Context) {
        if playing { view.player.play() } else { view.player.pause() }
    }
}

// MARK: - The card

/// A pack's card, or Complete's: its clip, what it assumes, the free taste, the App Store's price, buy and restore, and
/// the pack's levels once it has them.
struct PackCard: View {
    let offer: Offer
    /// The harness's clip time, else the clip runs.
    var clock: Double?
    /// The pack's own, unless the harness lists placeholders.
    var levels: [Level]
    let onBack: () -> Void
    let onPlay: (Level) -> Void
    var store = Store.shared
    @State private var buying = false
    @State private var restoring = false
    @State private var restored: Bool?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let state = store.state(offer)
        GeometryReader { g in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: onBack) { Text("\u{2039} back").font(.mono(.subheadline, .medium)) }
                        .buttonStyle(.plain).padding(.top, 18).opacity(0.8)
                        .accessibilityLabel("Back")
                    Text(offer.pack == nil ? "BUNDLE \u{00B7} PAID ADD-ON" : "PACK \u{00B7} PAID ADD-ON").font(.mono(.caption2, .semibold)).tracking(2).opacity(0.42)
                        .padding(.top, 26)
                    Text(offer.name).font(.system(.largeTitle, weight: .black).width(.expanded)).tracking(2)
                        .foregroundStyle(offer.gradient).shadow(color: offer.glow.opacity(0.55), radius: 10).padding(.top, 6)
                        .accessibilityAddTraits(.isHeader)
                    Text(offer.pitch).font(.mono(.footnote)).opacity(0.62).padding(.top, 4)
                    PackClip(offer: offer, side: min(typeSize.isAccessibilitySize ? 200 : 320, g.size.width - 48), held: clock)
                        .frame(maxWidth: .infinity).padding(.top, 28)
                    VStack(alignment: .leading, spacing: 9) {
                        fact("for", offer.assumes)
                        fact("free", offer.free)
                        fact("holds", offer.holds)
                    }
                    .padding(.top, 32)
                    if offer.arriving {
                        Text("More levels arrive in an update.").font(.mono(.caption)).opacity(0.62).padding(.top, 12)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // Buying comes before the list, so it is on the first screen whatever the pack holds.
                    if levels.isEmpty { Spacer(minLength: 24) }
                    status(state).padding(.top, levels.isEmpty ? 0 : 32)
                    action(state).padding(.top, 14)
                    if offer.pack != nil, state != .owned, store.state(.complete) != .owned, Offer.shelf().contains(.complete) {
                        completeLine.padding(.top, 14)
                    }
                    restore.padding(.top, 18).padding(.bottom, 10)
                    if !levels.isEmpty { list.padding(.top, 26).padding(.bottom, 10) }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, minHeight: g.size.height, alignment: .topLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(Color.text)
        .background(Color.black.ignoresSafeArea())
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onBack)
        .task { await store.fetchPrices() }
        .onAppear {
            Log.write("card \(offer.key) opens")
            if let pack = offer.pack { Analytics.shared.cardSeen(pack) }
        }
        .onChange(of: state) {
            if let tag = state.tag { AccessibilityNotification.Announcement("\(offer.name) \(tag.word)").post() }
        }
    }

    private var price: String? { store.price(offer.productID) }

    @ViewBuilder private func fact(_ key: String, _ value: String) -> some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 0))
        layout {
            Text(key).font(.mono(.caption2)).opacity(0.38)
                .frame(width: typeSize.isAccessibilitySize ? nil : 52, alignment: .leading)
            Text(value).font(.mono(.footnote)).opacity(0.85).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    /// Every level, those past the taste locked until the pack is owned.
    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("levels").font(.mono(.caption2, .semibold)).foregroundStyle(offer.gradient)
                Rectangle().fill(offer.gradient).frame(height: 1).opacity(0.8)
            }
            .padding(.bottom, 4)
            ForEach(levels, id: \.id) { level in
                let open = store.access(level) != .needsCard, best = Best.load(level.id)
                Button { onPlay(level) } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(level.label).font(.mono(.footnote, .semibold)).foregroundStyle(offer.glow)
                            .opacity(open ? 1 : 0.5).frame(minWidth: 30, alignment: .leading)
                        Text(level.title).font(.mono(.subheadline)).multilineTextAlignment(.leading)
                            .opacity(open ? 1 : 0.38)
                        Spacer(minLength: 8)
                        if !open {
                            Image(systemName: "lock.fill").font(.caption2).opacity(0.4)
                        } else if let best {
                            Text(best.over == 0 ? "par" : "+\(best.over)").font(.mono(.caption2))
                                .foregroundStyle(best.over == 0 ? Color.amber : Color.magenta)
                        }
                    }
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!open)
                .accessibilityValue(open ? best.map { $0.over == 0 ? "at par" : "\($0.over) over par" } ?? "" : "locked, needs the pack")
            }
        }
    }

    @ViewBuilder private func status(_ state: Purchase) -> some View {
        switch state {
        case .unowned: EmptyView()
        case .owned:
            line(offer.pack == nil ? "\u{2713} owned \u{00B7} every pack open" : "\u{2713} owned \u{00B7} every level open", .lime)
        case .pending:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    PulsingDot(colour: .amber)
                    Text("waiting for approval").font(.mono(.footnote, .semibold)).foregroundStyle(Color.amber)
                }
                Text("Ask to Buy: the pack opens here once it's approved.").font(.mono(.caption2)).opacity(0.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        case .failed:
            line("the purchase didn't go through", .magenta)
        case .revoked:
            line("refunded, or no longer shared with you", .alarm)
        }
    }

    private func line(_ s: String, _ colour: Color) -> some View {
        Text(s).font(.mono(.footnote, .semibold)).foregroundStyle(colour).shadow(color: colour.opacity(0.6), radius: 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Owned, play; otherwise buy at the App Store's price, and the taste beside it.
    @ViewBuilder private func action(_ state: Purchase) -> some View {
        if state == .owned {
            if let level = next {
                pill("play \u{203A}", trailing: nil, colour: .lime) { onPlay(level) }
                    .accessibilityLabel("Play \(offer.name)")
            }
        } else {
            let label = switch state {
            case .failed: "try again"
            case .revoked: "buy again"
            default: buying ? "buying\u{2026}" : "buy"
            }
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
                : AnyLayout(HStackLayout(spacing: 14))
            layout {
                pill(label, trailing: price, colour: offer.glow) { buy(offer) }
                    .disabled(state == .pending || buying)
                    .opacity(state == .pending ? 0.5 : 1)
                    .accessibilityLabel(state == .pending ? "Waiting for approval" : "\(label.capitalized) \(offer.name)")
                    .accessibilityValue(price ?? "")
                if let level = levels.first ?? Self.placeholder(offer) {
                    Button { onPlay(level) } label: {
                        Text("try \(offer.pack?.taste ?? 3) free \u{203A}").font(.mono(.footnote)).opacity(0.7)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Try the first \(offer.pack?.taste ?? 3) levels free")
                }
            }
        }
    }

    /// The first level without a best, else the first: where an owner picks up.
    private var next: Level? {
        levels.first { Best.load($0.id) == nil } ?? levels.first ?? Self.placeholder(offer)
    }

    /// Before a pack has levels, a Debug build plays its harness placeholder.
    private static func placeholder(_ offer: Offer) -> Level? {
        #if DEBUG
        offer.pack?.placeholder(1)
        #else
        nil
        #endif
    }

    private func pill(_ title: String, trailing: String?, colour: Color, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack(spacing: 14) {
                Text(title).font(.mono(.subheadline, .semibold))
                if let trailing { Text(trailing).font(.mono(.subheadline)).opacity(0.75) }
            }
            .padding(.horizontal, 22).padding(.vertical, 12).frame(minHeight: 46)
            .overlay { Capsule().strokeBorder(colour, lineWidth: 1).shadow(color: colour, radius: 5) }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Complete's failure stays off the pack's own status, so it is said here, beside the button that tried.
    private var completeLine: some View {
        let complete = store.price(Pack.completeID)
        return VStack(alignment: .leading, spacing: 6) {
            Button { buy(.complete) } label: {
                HStack(spacing: 6) {
                    Text("or all three in Complete").opacity(0.55)
                    if let complete { Text(complete).opacity(0.75) }
                    Text("\u{203A}").opacity(0.55)
                }
                .font(.mono(.caption))
            }
            .buttonStyle(.plain)
            .disabled(buying || store.state(.complete) == .pending)
            .accessibilityLabel("Buy Complete, every pack")
            .accessibilityValue(complete ?? "")
            if store.state(.complete) == .failed {
                Text("Complete's purchase didn't go through").font(.mono(.caption, .semibold)).foregroundStyle(Color.magenta)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var restore: some View {
        Button {
            restoring = true
            Task {
                restored = await store.restore()
                restoring = false
            }
        } label: {
            let s = restoring ? "restoring\u{2026}" : restored == false ? "couldn't reach the App Store \u{00B7} restore purchases"
                : restored == true ? "restored \u{00B7} restore purchases" : "restore purchases"
            Text(s).font(.mono(.caption2)).opacity(0.4).underline(pattern: .dot)
        }
        .buttonStyle(.plain)
        .disabled(restoring)
    }

    private func buy(_ o: Offer) {
        buying = true
        Task {
            await store.purchase(o.productID)
            buying = false
        }
    }
}

private struct PulsingDot: View {
    let colour: Color
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle().fill(colour).frame(width: 7, height: 7).shadow(color: colour, radius: on ? 6 : 2).opacity(on ? 1 : 0.45)
            .onAppear {
                if reduceMotion { on = true } else { withAnimation(.easeInOut(duration: 0.9).repeatForever()) { on = true } }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - The dock

/// The menu's shelf: a live cover per pack and Complete along the bottom, each opening its card. Out of step, so the
/// dock never stirs all at once.
struct PackDock: View {
    let open: (Offer, UnitPoint) -> Void
    var held: Double?
    /// The card covers it.
    var paused = false
    var store = Store.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("PACKS \u{00B7} PAID ADD-ONS").font(.mono(.caption2, .semibold)).tracking(2).opacity(0.38)
                Spacer()
                if typeSize < .xxLarge {
                    Text("first 3 levels of each free").font(.mono(.caption2)).opacity(0.3)
                }
            }
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 0) {
                let shelf = Offer.shelf()
                ForEach(Array(shelf.enumerated()), id: \.offset) { i, offer in
                    let x = (Double(i) + 0.5) / Double(shelf.count), state = store.state(offer)
                    Button { open(offer, UnitPoint(x: x, y: 0.88)) } label: {
                        VStack(spacing: 8) {
                            LoopingTank(offer: offer, side: 66, held: held, offset: 1.75 * Double(i), interval: 1.0 / 30,
                                        paused: paused)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(offer.name).font(.mono(.caption2)).opacity(0.7).lineLimit(2)
                                    .multilineTextAlignment(.center).minimumScaleFactor(0.8)
                                if let tag = state.tag {
                                    Circle().fill(tag.colour).frame(width: 4, height: 4).shadow(color: tag.colour, radius: 2)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(offer.name), \(offer.pack == nil ? "every pack" : "pack")")
                    .accessibilityValue(state.tag?.word ?? store.price(offer.productID) ?? "")
                    .accessibilityHint(offer.pitch)
                    .accessibilityShowsLargeContentViewer {
                        Text(offer.name)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        // A bar, like a tab bar: its names stop growing where four no longer fit, and a long press shows one large.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background {
            // Opaque under the label, so the list scrolls away behind a short fade above it.
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 28)
                Color.black
            }
            .padding(.top, -28)
            .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(Offer.complete.gradient).frame(height: 0.5).opacity(0.45).padding(.horizontal, 20)
        }
    }
}
