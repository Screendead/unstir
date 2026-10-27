// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// First Stir's chapter 5, Dusk Before: scenes 21 to 25 of the outline, from 9:30 back to 7:40 pm, in dusk rose ending in
/// kitchen gold. The grandmother lights the lamp, then walks back along the breakwater before she has; the father doubles
/// the boat's lines; the float is given; and the last tank is the kitchen at golden dusk, where the swirl in the child's
/// cup is the night's first stir. Still air: no rain, and the one cloud bank on the horizon has sunk by 9:00. The sky
/// climbs back from night to sunset, and the sun is up again in the last scene's window.
///
/// Drawn as the Rescue is, through `Brush` and `Cast`: single-weight line on black, baked held back and played, every
/// difference between the two, glow included, inside its own rod's core, clear of the knob and of the core's edge.
enum Dusk: Int, CaseIterable, Sendable, StoryScene {
    case lamp = 21, path, lines, gift, stir

    static let ink = Color(0xB0A6E8)
    static let lamplight = Color(0xFFC27A)
    static let sun = Color(0xFF8A5C)
    static let float = Color(0x3FE0B0)
    static let kitchen = Color(0xFFC94A)
    static let cream = Color(0xFFF1C8)
    static let tea = Color(0xD98B4A)

    var title: String {
        ["Lighting the lamp", "The path to the light", "Doubling the lines", "The float", "First stir"][rawValue - 21]
    }

    var layout: Layout { [.quad, .eye, .pent, .quad, .tri][rawValue - 21] }

    /// Par, the entry count, is each one's optimum, and plain untwisting reaches it (`testFirstStirParIsTheOptimum`).
    var scramble: String {
        [
            "3:+4,0:-3,1:+5,2:-2,3:-5,0:+2,1:-3,2:+4",
            "0:+3,2:-4,1:+5,3:-2,0:-4,1:+3,2:+2,3:+4",
            "4:+3,1:-4,3:+5,2:-3,0:+4,1:+2,4:-5",
            "0:+4,3:-3,2:+5,1:-2,0:-3,3:+2",
            // The cup's one entry (rod 2) at the bottom, so the stir is always the pack's last heal.
            "2:+4,0:-3,1:+5,0:+2,1:-3",
        ][rawValue - 21]
    }

    var vignettes: Set<Int> { [[0, 3, 2], [1, 0, 2], [1, 3, 4], [3, 0, 2], [0, 1, 2]][rawValue - 21] }

    /// The chapter's window, minutes after midnight, 9:30 back to 7:40 pm: each scene's played time is the next one's
    /// held-back time. The Storm's last scene ends where this one opens.
    static let times: [Double] = [1290, 1260, 1235, 1210, 1195, 1180]
    var late: Double { Self.times[rawValue - 21] }
    var early: Double { Self.times[rawValue - 20] }

    /// How far the chapter has wound back at `minutes`: 0 at 9:30, 1 at 7:40.
    static func back(_ minutes: Double) -> Double { min(max((times[0] - minutes) / (times[0] - times.last!), 0), 1) }

    // MARK: The sky

    /// Where the sky's middle tone sits, from the top (0) to the horizon (1).
    static let middle = 0.6

    /// The sky's tones from the zenith to the horizon at `minutes`: night blue at 9:30, climbing back through dusk rose to
    /// the sunset's coral at 7:40. The Storm's scene 20 is to end on these at 9:30.
    static func skyTones(_ minutes: Double) -> [Tone] {
        let b = back(minutes)
        let night = Tone(0x03062A), rose = Tone(0x4A2C78)
        return [night.mix(night.mix(rose, 0.45), b), night.mix(rose, 0.3).mix(rose, b), rose.scaled(0.55).mix(Tone(0xC8605A), b)]
    }

    /// The sea's tone at the horizon, catching the sunset as the night winds back; it darkens to black towards the viewer.
    static func seaTone(_ minutes: Double) -> Tone {
        Tone(0x2A3E6A).scaled(0.45).mix(Tone(0x2A3E6A).mix(Tone(0xC8605A), 0.3), back(minutes))
    }

    var horizon: Double { [-0.12, -0.4, -0.3, -0.32, -0.5][rawValue - 21] }
    /// Where on the horizon the sun went down, under its afterglow.
    var west: Double { [-0.75, -0.55, 0.2, -0.45, -0.14][rawValue - 21] }

    func drawSky(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        let pen = Brush(ctx: ctx, r: r)
        switch self {
        case .gift:
            Self.room(pen, wall: Tone(0x4A2C78).scaled(0.22), windows: [Gift.window, Gift.pane], horizon: horizon, west: west, minutes: minutes)
        case .stir:
            Self.room(pen, wall: Tone(0xFFC94A).scaled(0.16), windows: [Stir.window], horizon: horizon, west: west, minutes: minutes)
        default:
            Self.sea(pen, box: (-1, -1, 1, 1), horizon: horizon, west: west, minutes: minutes)
        }
    }

    func drawLive(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        if self == .lamp { Lamp.bank(Brush(ctx: ctx, r: r), minutes: minutes) }
    }

    /// The bodies `drawLive` draws, as points along their outlines where they stand highest, for the test that keeps them
    /// clear of every disc: the bank only sinks from there.
    var bodies: [(x: Double, y: Double, radius: Double)] {
        guard self == .lamp else { return [] }
        return Lamp.bumps.flatMap { q in
            (0...16).map { k -> (x: Double, y: Double, radius: Double) in
                let t = Double(k) / 16, u = 1 - t, h = Dusk.lamp.horizon
                return (u * u * q.x0 + 2 * t * u * (q.x0 + q.x1) / 2 + t * t * q.x1, h - 4 * t * u * q.peak, 0)
            }
        }
    }

    func draw(_ ctx: GraphicsContext, r: CGFloat, played: Set<Int>) {
        let pen = Brush(ctx: ctx, r: r)
        switch self {
        case .lamp: Lamp.draw(pen, played: played)
        case .path: Walk.draw(pen, played: played)
        case .lines: Lines.draw(pen, played: played)
        case .gift: Gift.draw(pen, played: played)
        case .stir: Stir.draw(pen, played: played)
        }
    }

    /// The sky over the sea inside `box` (x0, y0, x1, y1), its afterglow over the sun's going down, and the swell.
    static func sea(_ pen: Brush, box: (Double, Double, Double, Double), horizon h: Double, west: Double, minutes: Double) {
        let (x0, y0, x1, y1) = box, b = back(minutes)
        pen.fill(pen.rect(x0, y0, x1, y1), .black)
        let stops = zip(skyTones(minutes), [0, CGFloat(middle), 1]).map { Gradient.Stop(color: $0.color, location: $1) }
        pen.fill(pen.rect(x0, y0, x1, h), .linearGradient(Gradient(stops: stops), startPoint: pen.point(0, min(y0, h - 0.5)),
                                                           endPoint: pen.point(0, h)))
        var sky = pen
        sky = sky.clipped(to: pen.rect(x0, y0, x1, h))
        sky.fill(pen.circle(west, h, 0.9), .radialGradient(
            Gradient(stops: [.init(color: sun.opacity(0.5 * b * b), location: 0), .init(color: sun.opacity(0.18 * b), location: 0.35),
                             .init(color: sun.opacity(0), location: 1)]),
            center: pen.point(west, h), startRadius: 0, endRadius: 0.9 * pen.r))
        pen.fill(pen.rect(x0, h, x1, y1), .linearGradient(Gradient(colors: [seaTone(minutes).color, .black]),
                                                           startPoint: pen.point(0, h), endPoint: pen.point(0, max(y1, h + 0.6))))
        var swell = Path()
        var rng = SplitMix64(state: 71)
        for k in 1...10 {
            let t = Double(k) / 10, y = h + 0.012 + (1 - h) * 0.98 * pow(t, 1.7)
            let amp = 0.002 + 0.014 * t, wave = 0.05 + 0.22 * t, phase = Double.random(in: 0..<6.3, using: &rng)
            guard y < y1 else { continue }
            swell.addPath(pen.path { s in
                s.move(to: CGPoint(x: x0 - 0.05, y: y))
                for x in Swift.stride(from: x0 - 0.05, through: x1 + 0.05, by: 0.01) {
                    s.addLine(to: CGPoint(x: x, y: y - amp * sin(x / wave * 2 * .pi + phase)))
                }
            })
        }
        let water = pen.clipped(to: pen.rect(x0, h, x1, y1))
        water.lit([(0.02, 0.25), (0.007, 0.6)]) { g in
            g.stroke(swell, ink, 0.18 + 0.1 * b)
            g.stroke(g.seg(x0, h, x1, h), ink, 0.45)
        }
    }

    /// A room's wall in a flat tone, and the sky over the sea through its windows.
    static func room(_ pen: Brush, wall: Tone, windows: [(x0: Double, y0: Double, x1: Double, y1: Double)], horizon: Double,
                     west: Double, minutes: Double) {
        pen.fill(pen.rect(-1, -1, 1, 1), wall.color)
        for w in windows { sea(pen, box: (w.x0, w.y0, w.x1, w.y1), horizon: horizon, west: west, minutes: minutes) }
    }

    // MARK: Things

    /// A storm lantern on its base at (0, 0), 1 tall, lit or not.
    static func lantern(_ pen: Brush, lit: Bool) {
        var cage = Path()
        cage.addPath(pen.seg(-0.32, 0, 0.32, 0))
        cage.addPath(pen.poly([(-0.26, 0), (-0.22, -0.62), (0.22, -0.62), (0.26, 0)], closed: false))
        cage.addPath(pen.poly([(-0.28, -0.62), (-0.12, -0.8), (0.12, -0.8), (0.28, -0.62)], closed: false))
        cage.addPath(pen.curve(-0.2, -0.84, 0, -1.12, 0.2, -0.84))
        pen.lit(Rescue.tight) { g in
            if lit { g.fill(g.ellipse(0, -0.3, 0.17, 0.21), cream) }
            g.stroke(cage, lit ? lamplight : ink)
        }
    }

    /// The green glass float in its net at (x, y), `radius` across, hung from its string.
    static func glassFloat(_ pen: Brush, x: Double, y: Double, radius: Double, string: Double, lit: Bool = false) {
        let ball = pen.circle(x, y, radius)
        var net = Path()
        net.addPath(pen.seg(x, y - radius - string, x, y - radius))
        net.addPath(pen.curve(x - radius, y, x, y + radius * 0.5, x + radius, y))
        net.addPath(pen.curve(x, y - radius, x - radius * 0.7, y, x, y + radius))
        net.addPath(pen.curve(x, y - radius, x + radius * 0.7, y, x, y + radius))
        pen.fill(ball, float, lit ? 0.45 : 0.2)
        pen.lit(Rescue.tight) { g in
            g.stroke(ball, float)
            g.stroke(net, float, 0.7)
        }
    }

    /// A gull in flight at (x, y), its wings `w` across.
    static func gull(_ pen: Brush, _ x: Double, _ y: Double, w: Double) -> Path {
        var p = Path()
        p.addPath(pen.curve(x - w / 2, y - w * 0.2, x - w / 4, y - w * 0.4, x, y))
        p.addPath(pen.curve(x, y, x + w / 4, y - w * 0.4, x + w / 2, y - w * 0.2))
        return p
    }

    /// A star at (x, y): a point and four short rays.
    static func star(_ pen: Brush, _ x: Double, _ y: Double, size s: Double) {
        pen.lit(Rescue.tight) { g in
            g.fill(g.circle(x, y, s * 0.25), cream)
            g.stroke(g.seg(x - s, y, x + s, y), cream, 0.8)
            g.stroke(g.seg(x, y - s, x, y + s), cream, 0.8)
        }
    }
}

extension Level {
    /// Dusk Before's scenes in story order, numbered by place in `firstStir`.
    static let dusk: [Level] = Dusk.allCases.map { scene in
        Level(id: "", pack: .firstStir, label: "", title: scene.title, note: "", layout: scene.layout,
              scramble: .parse(scene.scramble, in: scene.layout), story: .dusk(scene))
    }
}

extension Dusk {
    /// Scene 21, 9:30 back to 9:00, on quad: the lighthouse on the breakwater's end from along it, the town's houses on
    /// the quay to the left, a cloud bank low on the sea that sinks out of sight by 9:00. Rod 0, the lantern: lit, its
    /// first beam out over the bay, then dark, the grandmother in the lamp room with a taper. Rod 3, the sky over the sea:
    /// gulls flocking inland, then clear, the evening star. Rod 2, the town: four windows lit, then one.
    enum Lamp {
        static let room = (x0: 0.29, y0: -0.6, x1: 0.418, y1: -0.468)
        static let lampAt = (x: 0.385, y: -0.53)

        /// The cloud bank's humps along the horizon, at the glass's left edge: the only stretch of the quad's horizon that no
        /// disc reaches (`testTheBodiesStayClearOfEveryDisc`).
        static let bumps: [(x0: Double, x1: Double, peak: Double)] = [(-0.985, -0.93, 0.03), (-0.93, -0.875, 0.045), (-0.875, -0.83, 0.03)]

        /// The cloud bank low on the sea, sunk out of sight by 9:00: drawn live, as Dawn's sun is, and cut off at the horizon.
        static func bank(_ pen: Brush, minutes: Double) {
            let up = min(max((minutes - 1260) / 30, 0), 1)
            guard up > 0 else { return }
            let h = Dusk.lamp.horizon, sink = (1 - up) * 0.05
            let bank = pen.path { c in
                c.move(to: CGPoint(x: bumps[0].x0, y: h + sink))
                for b in bumps {
                    c.addQuadCurve(to: CGPoint(x: b.x1, y: h + sink), control: CGPoint(x: (b.x0 + b.x1) / 2, y: h + sink - 2 * b.peak))
                }
                c.closeSubpath()
            }
            let sky = pen.clipped(to: pen.rect(-1, -1, 1, h))
            sky.fill(bank, .black, 0.7)
            sky.lit([(Dawn.bodyGlow, 0.4), (0.007, 0.8)]) { $0.stroke(bank, ink, 0.6) }
        }

        static func draw(_ pen: Brush, played: Set<Int>) {
            let h = Dusk.lamp.horizon
            // The breakwater from the viewer's feet out to the lighthouse on its end, paved across.
            func left(_ y: Double) -> Double { 0.32 + (-0.1 - 0.32) * (y + 0.1) / 1.1 }
            func right(_ y: Double) -> Double { 0.39 + (0.86 - 0.39) * (y + 0.1) / 1.1 }
            let top = pen.poly([(left(1.02), 1.02), (left(h + 0.02), h + 0.02), (right(h + 0.02), h + 0.02), (right(1.02), 1.02)])
            pen.fill(top, .black)
            var walk = Path()
            walk.addPath(pen.seg(left(1.02), 1.02, left(h + 0.02), h + 0.02))
            walk.addPath(pen.seg(right(1.02), 1.02, right(h + 0.02), h + 0.02))
            for k in 1...9 {
                let y = h + 0.02 + 1.0 * pow(Double(k) / 9, 1.8)
                walk.addPath(pen.seg(left(y), y, right(y), y))
            }
            // The face on the sea side.
            let face = pen.poly([(right(h + 0.02), h + 0.02), (right(h + 0.02) + 0.012, h + 0.05), (1.02, 0.9), (1.02, 1.02), (right(1.02), 1.02)])
            pen.fill(face, .black)

            // The lighthouse on the end, its gallery and its lamp room, drawn larger than life.
            let tower = pen.poly([(0.31, h + 0.03), (0.326, room.y1), (0.382, room.y1), (0.398, h + 0.03)])
            pen.fill(tower, .black)
            let glass = pen.rect(room.x0, room.y0, room.x1, room.y1)
            pen.fill(glass, Color(0x03062A))
            var dome = pen.curve(room.x0 - 0.01, room.y0, 0.354, room.y0 - 0.08, room.x1 + 0.01, room.y0)
            dome.closeSubpath()
            pen.fill(dome, .black)
            var house = Path()
            house.addPath(tower)
            for y in [-0.2, -0.3, -0.4] { house.addPath(pen.seg(0.31 + 0.016 * (y - h - 0.03) / (room.y1 - h - 0.03), y,
                                                                0.398 - 0.016 * (y - h - 0.03) / (room.y1 - h - 0.03), y)) }
            house.addPath(pen.seg(room.x0 - 0.025, room.y1, room.x1 + 0.025, room.y1))
            house.addPath(pen.seg(room.x0 - 0.025, room.y1 - 0.024, room.x1 + 0.025, room.y1 - 0.024))
            for x in Swift.stride(from: room.x0 - 0.025, through: room.x1 + 0.026, by: 0.0445) {
                house.addPath(pen.seg(x, room.y1, x, room.y1 - 0.024))
            }
            house.addPath(glass)
            house.addPath(dome)
            house.addPath(pen.seg(0.354, room.y0 - 0.04, 0.354, room.y0 - 0.07))
            // The lamp on its stand in the middle of the room.
            house.addPath(pen.seg(lampAt.x, room.y1, lampAt.x, lampAt.y + 0.025))
            house.addPath(pen.ellipse(lampAt.x, lampAt.y, 0.016, 0.022))
            pen.lit { g in
                g.stroke(walk, ink, 0.7)
                g.stroke(face, ink, 0.5)
                g.stroke(house, ink)
            }

            // The quay on the left, the harbour between it and the breakwater, and the town's houses along it.
            let quay = 0.6
            pen.fill(pen.rect(-1, quay, 0.02, 1.02), .black)
            var stone = Path()
            stone.addPath(pen.seg(-1, quay, 0.02, quay))
            stone.addPath(pen.seg(0.02, quay, 0.02, 1.02))
            for (i, y) in [0.7, 0.8, 0.9].enumerated() {
                stone.addPath(pen.seg(-1, y, 0.02, y))
                for x in Swift.stride(from: -0.95 + (i % 2 == 0 ? 0 : 0.07), to: 0.0, by: 0.14) { stone.addPath(pen.seg(x, y - 0.1, x, y)) }
            }
            let houses = [pen.poly([(-1, quay), (-1, 0.2), (-0.82, 0.11), (-0.66, 0.2), (-0.66, quay)]),
                          pen.poly([(-0.64, quay), (-0.64, 0.24), (-0.52, 0.15), (-0.4, 0.24), (-0.4, quay)]),
                          pen.poly([(-0.38, quay), (-0.38, 0.27), (-0.25, 0.17), (-0.12, 0.27), (-0.12, quay)])]
            var town = Path()
            for house in houses { pen.fill(house, .black); town.addPath(house) }
            town.addPath(pen.rect(-0.86, 0.46, -0.78, quay))
            town.addPath(pen.rect(-0.6, 0.53, -0.555, quay))
            town.addPath(pen.rect(-0.34, 0.52, -0.29, quay))
            town.addPath(pen.poly([(-0.2, 0.2), (-0.2, 0.13), (-0.16, 0.13), (-0.16, 0.235)], closed: false))
            for w in windows { town.addPath(pen.rect(w.x - 0.0225, w.y - 0.0275, w.x + 0.0225, w.y + 0.0275)) }
            pen.lit { g in
                g.stroke(stone, ink, 0.55)
                g.stroke(town, ink)
            }

            // Vignette 0, the lantern.
            pen.vignette(0) { pen in
                if played.contains(0) {
                    // Dark, the grandmother at the lamp reaching her taper to its wick.
                    // 0.125 tall with her bun, past the spec's 0.12 for a standing adult, her head under the room's top.
                    Cast.figure(pen.at(0.328, room.y1 - 0.003, k: 0.135), .grandmother,
                                arms: [[(0.1, -0.72), (0.2, -0.7), (0.24, -0.585)], [(-0.1, -0.72), (-0.14, -0.45)]], colour: ink)
                    pen.lit(Rescue.tight) { g in
                        g.stroke(g.seg(0.36, -0.55, 0.379, -0.557), cream)
                        g.fill(g.circle(0.381, -0.558, 0.005), lamplight)
                    }
                } else {
                    pen.fill(pen.poly([(room.x1, -0.548), (0.49, -0.566), (0.49, -0.506), (room.x1, -0.52)]), lamplight, 0.3)
                    pen.fill(pen.poly([(room.x0, -0.548), (0.232, -0.56), (0.232, -0.512), (room.x0, -0.52)]), lamplight, 0.18)
                    pen.lit(Rescue.tight) { g in
                        g.fill(g.rect(room.x0 + 0.008, room.y0 + 0.008, room.x1 - 0.008, room.y1 - 0.008), lamplight, 0.3)
                        g.fill(g.ellipse(lampAt.x, lampAt.y, 0.016, 0.022), cream)
                        g.stroke(g.rect(room.x0 + 0.008, room.y0 + 0.008, room.x1 - 0.008, room.y1 - 0.008), lamplight)
                    }
                }
            }

            // Vignette 3, the sky over the sea.
            pen.vignette(3) { pen in
                if played.contains(3) {
                    Dusk.star(pen, -0.43, -0.52, size: 0.016)
                } else {
                    var flock = Path()
                    for (x, y) in [(-0.35, -0.5), (-0.43, -0.45), (-0.27, -0.55), (-0.46, -0.54), (-0.22, -0.46), (-0.39, -0.575)] {
                        flock.addPath(Dusk.gull(pen, x, y, w: 0.045))
                    }
                    pen.lit(Rescue.tight) { $0.stroke(flock, ink) }
                }
            }

            // Vignette 2, the town.
            pen.vignette(2) { pen in
                for (i, w) in windows.enumerated() where !played.contains(2) || i == 2 {
                    let pane = pen.rect(w.x - 0.0225, w.y - 0.0275, w.x + 0.0225, w.y + 0.0275)
                    pen.fill(pane, lamplight, 0.8)
                    pen.lit(Rescue.tight) { $0.stroke(pane, lamplight) }
                }
            }
        }

        /// The town's windows in rod 2's core, clear of its knob: the one still lit at 9:00 third.
        static let windows: [(x: Double, y: Double)] = [(-0.52, 0.31), (-0.5, 0.47), (-0.22, 0.33), (-0.23, 0.48)]
    }
}

extension Dusk {
    /// Scene 22, 9:00 back to 8:35, on eye: the breakwater path at dusk from the quay, the lighthouse dark on its end. Rod
    /// 1, the grandmother: at the lighthouse door, her lantern raised, then just out on the path, lantern swinging, shawl
    /// blowing. Rod 0, the child: at the quay rail, waving after her, then running along the quay, arm up. Rod 2, the sky:
    /// a thin moon up beside the evening star, then the afterglow alone.
    enum Walk {
        static let quay = 0.2
        /// The breakwater's top, from the quay's end out to the lighthouse: its height at x.
        static func top(_ x: Double) -> Double { quay - 0.17 * x / 0.5 }

        static func draw(_ pen: Brush, played: Set<Int>) {
            // The lighthouse on the end, dark: its door at the path's end, the lamp room not yet lit.
            let tower = pen.poly([(0.5, 0.045), (0.535, -0.62), (0.625, -0.62), (0.66, 0.045)])
            let room = pen.rect(0.545, -0.71, 0.615, -0.62)
            var dome = pen.curve(0.535, -0.71, 0.58, -0.77, 0.625, -0.71)
            dome.closeSubpath()
            pen.fill(tower, .black); pen.fill(room, Color(0x03062A)); pen.fill(dome, .black)
            var house = Path()
            house.addPath(tower); house.addPath(room); house.addPath(dome)
            house.addPath(pen.seg(0.52, -0.62, 0.64, -0.62))
            house.addPath(pen.seg(0.58, -0.77, 0.58, -0.79))
            house.addPath(pen.rect(0.566, -0.075, 0.604, 0.045))
            for y in [-0.45, -0.25] { house.addPath(pen.rect(0.571, y - 0.03, 0.589, y)) }

            // The breakwater: its path along the top, its face down to the water, stone courses on it.
            let wall = pen.poly([(0, quay), (0.5, top(0.5)), (0.7, top(0.5)), (0.7, 0.1), (0, 0.33)])
            pen.fill(wall, .black)
            var stone = Path()
            stone.addPath(pen.poly([(0, quay), (0.5, top(0.5)), (0.7, top(0.5))], closed: false))
            stone.addPath(pen.seg(0, 0.33, 0.7, 0.1))
            for t in [0.35, 0.65] { stone.addPath(pen.seg(0, quay + 0.13 * t, 0.7, top(0.5) + 0.055 * t)) }

            // The quay in front, its rail along the edge, and its wall down to the water.
            pen.fill(pen.rect(-1, quay, 0, 0.42), .black)
            var rail = Path()
            rail.addPath(pen.seg(-1, quay, 0, quay))
            rail.addPath(pen.seg(-1, 0.42, 0, 0.42))
            rail.addPath(pen.seg(0, quay, 0, 0.42))
            for y in [0.28, 0.35] { rail.addPath(pen.seg(-1, y, 0, y)) }
            for x in Swift.stride(from: -0.95, through: -0.04, by: 0.13) { rail.addPath(pen.seg(x, quay, x, quay - 0.08)) }
            rail.addPath(pen.seg(-1, quay - 0.08, -0.04, quay - 0.08))
            rail.addPath(pen.seg(-1, quay - 0.04, -0.04, quay - 0.04))
            // A lamp post at the quay's end, not yet lit.
            rail.addPath(pen.poly([(-0.06, quay), (-0.06, -0.12), (-0.03, -0.14)], closed: false))
            rail.addPath(pen.rect(-0.045, -0.17, -0.015, -0.135))
            pen.lit { g in
                g.stroke(house, ink)
                g.stroke(stone, ink, 0.7)
                g.stroke(rail, ink, 0.85)
            }

            // Vignette 1, the grandmother.
            pen.vignette(1) { pen in
                if played.contains(1) {
                    // Just out along the path, facing out, the lantern swinging behind her and her shawl's ends blowing.
                    let x = 0.265, y = top(0.265)
                    Cast.figure(pen.at(x, y, k: 0.155), .grandmother, arms: [[(-0.1, -0.72), (-0.22, -0.5), (-0.3, -0.38)]], colour: ink)
                    pen.lit(Rescue.tight) { g in
                        g.stroke(g.curve(x - 0.014, y - 0.12, x - 0.042, y - 0.126, x - 0.06, y - 0.108), ink)
                        g.stroke(g.curve(x - 0.014, y - 0.108, x - 0.036, y - 0.102, x - 0.054, y - 0.084), ink)
                    }
                    Dusk.lantern(pen.at(x - 0.054, y - 0.036, k: 0.04, turn: 0.4), lit: true)
                } else {
                    Cast.figure(pen.at(0.548, 0.045, k: 0.155), .grandmother,
                                arms: [[(0.1, -0.72), (0.2, -0.95), (0.3, -1.12)], [(-0.1, -0.72), (-0.12, -0.45)]], colour: ink)
                    Dusk.lantern(pen.at(0.594, -0.13, k: 0.04), lit: true)
                    pen.glow(0.594, -0.148, 0.05, Dusk.lamplight, 0.45)
                }
            }

            // Vignette 0, the child.
            pen.vignette(0) { pen in
                if played.contains(0) {
                    Cast.figure(pen.at(-0.6, quay, k: 0.13), .child, arms: [[(0.1, -0.6), (0.2, -0.85), (0.24, -1.1)], [(-0.1, -0.6), (-0.24, -0.42)]],
                                legs: [[(-0.06, -0.32), (-0.22, -0.16), (-0.2, 0)], [(0.06, -0.32), (0.22, -0.18), (0.3, -0.04)]], colour: ink)
                } else {
                    Cast.figure(pen.at(-0.25, quay, k: 0.13), .child, arms: [[(0.1, -0.6), (0.26, -0.8), (0.2, -1.08)], [(-0.1, -0.6), (-0.14, -0.36)]],
                                colour: ink)
                }
            }

            // Vignette 2, the sky.
            pen.vignette(2) { pen in
                if !played.contains(2) {
                    let moon = pen.circle(-0.09, -0.66, 0.032).subtracting(pen.circle(-0.075, -0.672, 0.03))
                    pen.fill(moon, Dusk.cream, 0.9)
                    pen.lit(Rescue.tight) { $0.stroke(moon, Dusk.cream, 0.7) }
                    Dusk.star(pen, 0.07, -0.7, size: 0.014)
                }
            }
        }
    }

    /// Scene 23, 8:35 back to 8:10, on pent: the harbour at sunset from the quay, the cottage's gable on the left, the
    /// harbourmaster's hut in front, the family's boat moored out on the right, bow and stern to two buoys. Rod 1, the
    /// boat: its two lines out, lamps lit, nobody aboard, then the father in the stern tying the second line. Rod 3, the
    /// barometer on the hut: its needle on the storm glyph, then on the sun's. Rod 4, the cottage window: the float
    /// hanging in it, the lamp lit, then the float hanging and the lamp unlit.
    enum Lines {
        static let window = (x0: -0.573, y0: -0.388, x1: -0.493, y1: -0.298)
        /// The barometer, drawn larger than life: its glyphs near the rim, its needle stopping short of them.
        static let dial = (x: -0.46, y: 0.32, r: 0.09)
        static let needle = 0.03

        static func draw(_ pen: Brush, played: Set<Int>) {
            // The far breakwater on the horizon and its lighthouse, dark.
            let h = Dusk.lines.horizon
            let far = pen.poly([(0.08, h + 0.005), (1, h - 0.01), (1, h + 0.012), (0.08, h + 0.015)])
            let light = pen.poly([(0.13, h + 0.005), (0.138, -0.47), (0.162, -0.47), (0.17, h + 0.005)])
            pen.fill(far, .black); pen.fill(light, .black)
            var distance = Path()
            distance.addPath(far); distance.addPath(light)
            distance.addPath(pen.rect(0.138, -0.5, 0.162, -0.47))
            distance.addPath(pen.seg(0.13, -0.47, 0.17, -0.47))
            distance.addPath(pen.curve(0.135, -0.5, 0.15, -0.52, 0.165, -0.5))

            // The cottage's gable, its window over the knob.
            let quay = 0.27
            let gable = pen.poly([(-1, -0.48), (-0.74, -0.68), (-0.4, -0.48), (-0.4, quay), (-1, quay)])
            pen.fill(gable, .black)
            var cottage = Path()
            cottage.addPath(pen.poly([(-1, -0.48), (-0.74, -0.68), (-0.4, -0.48), (-0.4, quay)], closed: false))
            cottage.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
            cottage.addPath(pen.seg(window.x0 - 0.01, window.y1 + 0.008, window.x1 + 0.01, window.y1 + 0.008))
            cottage.addPath(pen.rect(-0.86, -0.25, -0.76, -0.1))
            // The sill's lamp, its chimney and base.
            cottage.addPath(pen.poly([(-0.563, window.y1), (-0.56, -0.315), (-0.548, -0.318), (-0.545, window.y1)]))

            // The quay along the front, from the cottage's foot across, its wall's coping, a bollard on it.
            pen.fill(pen.rect(-1, quay, 1, 1), .black)
            var wall = Path()
            wall.addPath(pen.seg(-1, quay, 1, quay))
            wall.addPath(pen.seg(-1, 0.34, 1, 0.34))
            for (i, x) in Swift.stride(from: -0.98, to: 1, by: 0.12).enumerated() {
                wall.addPath(pen.seg(x + (i % 2 == 0 ? 0 : 0.06), quay, x + (i % 2 == 0 ? 0 : 0.06), 0.34))
            }
            wall.addPath(pen.poly([(0.42, quay), (0.42, 0.225), (0.405, 0.215), (0.475, 0.215), (0.46, 0.225), (0.46, quay)], closed: false))
            var flags = Path()
            for x in Swift.stride(from: -1.5, through: 1.5, by: 0.3) { flags.addPath(pen.seg(x * 0.6, 0.4, x, 1)) }
            for y in [0.4, 0.6, 0.82] { flags.addPath(pen.seg(-1, y, 1, y)) }

            // The harbourmaster's hut on the quay in front, its barometer on the wall by the door.
            let hut = pen.poly([(-0.66, 0.78), (-0.66, 0.24), (-0.34, 0.12), (-0.02, 0.24), (-0.02, 0.78)])
            var shed = Path()
            shed.addPath(hut)
            shed.addPath(pen.rect(-0.2, 0.5, -0.09, 0.78))
            shed.addPath(pen.rect(-0.6, 0.55, -0.5, 0.65))
            shed.addPath(pen.circle(dial.x, dial.y, dial.r))
            shed.addPath(pen.circle(dial.x, dial.y, 0.005))
            // The glyphs: a cloud with a bolt under it upper left, a rayed sun upper right, each where the needle points.
            let reach = 0.058, storm = (x: dial.x - reach * 0.7071, y: dial.y - reach * 0.7071)
            let fair = (x: dial.x + reach * 0.7071, y: dial.y - reach * 0.7071)
            var glyphs = Path()
            glyphs.addPath(pen.curve(storm.x - 0.02, storm.y, storm.x - 0.01, storm.y - 0.022, storm.x, storm.y - 0.006))
            glyphs.addPath(pen.curve(storm.x, storm.y - 0.006, storm.x + 0.014, storm.y - 0.022, storm.x + 0.02, storm.y))
            glyphs.addPath(pen.seg(storm.x - 0.02, storm.y, storm.x + 0.02, storm.y))
            glyphs.addPath(pen.poly([(storm.x + 0.003, storm.y + 0.003), (storm.x - 0.007, storm.y + 0.014), (storm.x + 0.005, storm.y + 0.014),
                                     (storm.x - 0.004, storm.y + 0.024)], closed: false))
            glyphs.addPath(pen.circle(fair.x, fair.y, 0.008))
            for k in 0..<8 {
                let a = Double(k) * .pi / 4
                glyphs.addPath(pen.seg(fair.x + 0.013 * cos(a), fair.y + 0.013 * sin(a), fair.x + 0.021 * cos(a), fair.y + 0.021 * sin(a)))
            }
            pen.lit { g in
                g.stroke(distance, ink, 0.6)
                g.stroke(cottage, ink)
                g.stroke(flags, ink, 0.2)
                g.stroke(wall, ink, 0.7)
            }
            pen.fill(hut, .black)
            pen.lit { g in
                g.stroke(shed, ink)
                g.stroke(glyphs, Dusk.lamplight, 0.9)
            }

            // The boat, moored bow to the left: its hull, wheelhouse and the mast at its stern, the bow line out to its buoy,
            // and the stern's buoy, its line in the vignette.
            let boat = pen.at(0.555, 0.0, k: 0.24)
            let hull = boat.path { b in
                b.move(to: CGPoint(x: -0.5, y: -0.13))
                b.addQuadCurve(to: CGPoint(x: -0.34, y: 0.06), control: CGPoint(x: -0.47, y: 0.04))
                b.addLine(to: CGPoint(x: 0.42, y: 0.06))
                b.addQuadCurve(to: CGPoint(x: 0.5, y: -0.11), control: CGPoint(x: 0.5, y: 0.04))
                b.closeSubpath()
            }
            let cab = boat.rect(-0.25, -0.31, 0.05, -0.12)
            pen.fill(hull, .black); pen.fill(cab, .black)
            var hulk = Path()
            hulk.addPath(hull); hulk.addPath(cab)
            hulk.addPath(boat.rect(-0.18, -0.26, -0.06, -0.18))
            hulk.addPath(boat.seg(0.395, -0.1, 0.395, -0.45))
            hulk.addPath(boat.seg(-0.46, -0.04, 0.46, -0.04))
            hulk.addPath(pen.curve(0.437, -0.03, 0.4, 0.004, 0.374, -0.001))
            for b in [(x: 0.37, y: 0.018), (x: 0.692, y: 0.012)] {
                let buoy = pen.ellipse(b.x, b.y, 0.014, 0.011)
                pen.fill(buoy, .black)
                hulk.addPath(buoy)
                hulk.addPath(pen.circle(b.x, b.y - 0.016, 0.005))
            }
            pen.lit { $0.stroke(hulk, ink) }

            // Vignette 1, the boat.
            pen.vignette(1) { pen in
                if played.contains(1) {
                    // The father in the stern, bent over the cleat with the second line, slack from his hands to its buoy.
                    Cast.figure(pen.at(0.625, -0.03, k: 0.125, turn: 0.35), .father,
                                arms: [[(0.1, -0.74), (0.3, -0.55), (0.36, -0.36)], [(-0.1, -0.74), (0.12, -0.5), (0.3, -0.38)]], colour: ink)
                    pen.lit(Rescue.tight) { $0.stroke($0.curve(0.668, -0.035, 0.676, 0.012, 0.69, -0.004), ink) }
                } else {
                    pen.lit(Rescue.tight) { g in
                        g.stroke(g.seg(0.668, -0.03, 0.69, -0.004), ink)
                        g.fill(g.circle(0.65, -0.112, 0.009), Dusk.cream)
                        g.fill(g.rect(0.515, -0.061, 0.54, -0.044), Dusk.lamplight, 0.9)
                    }
                    pen.glow(0.65, -0.112, 0.03, Dusk.lamplight, 0.5)
                }
            }

            // Vignette 3, the barometer's needle.
            pen.vignette(3) { pen in
                let a = played.contains(3) ? -0.25 * Double.pi : -0.75 * Double.pi
                pen.lit(Rescue.tight) { $0.stroke($0.seg(dial.x, dial.y, dial.x + needle * cos(a), dial.y + needle * sin(a)), Dusk.cream) }
            }

            // Vignette 4, the cottage window: the float hanging in it both ways, the lamp lit or not.
            pen.vignette(4) { pen in
                if !played.contains(4) {
                    pen.fill(pen.rect(window.x0 + 0.006, window.y0 + 0.006, window.x1 - 0.006, window.y1 - 0.006), Dusk.lamplight, 0.3)
                    pen.lit(Rescue.tight) { $0.fill($0.ellipse(-0.554, -0.322, 0.006, 0.01), Dusk.cream) }
                    pen.glow(-0.554, -0.325, 0.04, Dusk.lamplight, 0.4)
                }
            }
            Dusk.glassFloat(pen, x: -0.513, y: -0.338, radius: 0.017, string: 0.032, lit: false)
        }
    }

    /// Scene 24, 8:10 back to 7:55, on quad: the kitchen at sunset, its window over the sea on the left, the door with its
    /// pegs on the right, the sea through its glazed top, the table between. Rod 3, the window: the float hanging in it, lit teal by the sunset, then bare,
    /// its hook waiting. Rod 0, the door: the oilskin gone from its peg and the door ajar, then the oilskin on its peg, the
    /// boots below it. Rod 2, the gift: the child reaching up to the window, her hands empty, then the grandmother holding
    /// the float out to her in both hands.
    enum Gift {
        static let window = (x0: -0.53, y0: -0.6, x1: -0.19, y1: -0.16)
        static let floor = 0.42
        static let door = (x0: 0.48, y0: -0.66, x1: 0.72, y1: 0.42)
        static let hook = (x: -0.3, y: -0.58)
        /// The door's glazed upper panel, the sea's horizon through it in rod 0's core.
        static let pane = (x0: door.x0 + 0.03, y0: door.y0 + 0.04, x1: door.x1 - 0.03, y1: -0.18)

        static func draw(_ pen: Brush, played: Set<Int>) {
            var room = Path()
            // The window's frame, its sill and mullion; the hook in its top for the float.
            room.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
            room.addPath(pen.seg(window.x0 - 0.02, window.y1 + 0.012, window.x1 + 0.02, window.y1 + 0.012))
            room.addPath(pen.seg(-0.42, window.y0, -0.42, window.y1))
            room.addPath(pen.curve(hook.x, window.y0, hook.x + 0.012, hook.y + 0.012, hook.x, hook.y + 0.02))
            // The floor, the door and its pegs, a shelf under them for boots.
            room.addPath(pen.seg(-1, floor, 1, floor))
            room.addPath(pen.rect(door.x0, door.y0, door.x1, door.y1))
            room.addPath(pen.rect(pane.x0, pane.y0, pane.x1, pane.y1))
            room.addPath(pen.seg((pane.x0 + pane.x1) / 2, pane.y0, (pane.x0 + pane.x1) / 2, pane.y1))
            room.addPath(pen.rect(door.x0 + 0.03, -0.12, door.x1 - 0.03, door.y1 - 0.04))
            room.addPath(pen.circle(door.x1 - 0.04, -0.15, 0.01))
            for x in [0.2, 0.29] { room.addPath(pen.seg(x, -0.52, x + 0.012, -0.535)) }
            room.addPath(pen.seg(0.12, -0.19, 0.31, -0.19))
            // The table with a teapot, and a chair.
            room.addPath(pen.seg(0.12, 0.3, 0.62, 0.3))
            room.addPath(pen.seg(0.12, 0.32, 0.62, 0.32))
            for x in [0.16, 0.58] { room.addPath(pen.seg(x, 0.32, x, 0.6)) }
            room.addPath(pen.poly([(0.06, 0.62), (0.06, 0.36), (0.02, 0.18)], closed: false))
            room.addPath(pen.seg(0.06, 0.44, 0.16, 0.44))
            let pot = pen.ellipse(0.42, 0.25, 0.055, 0.045)
            room.addPath(pot)
            room.addPath(pen.curve(0.365, 0.25, 0.33, 0.24, 0.32, 0.2))
            room.addPath(pen.curve(0.475, 0.23, 0.51, 0.25, 0.475, 0.27))
            room.addPath(pen.seg(0.405, 0.205, 0.435, 0.205))
            // The ceiling lamp, unlit.
            room.addPath(pen.seg(0, -1, 0, -0.78))
            room.addPath(pen.curve(-0.06, -0.72, 0, -0.8, 0.06, -0.72))
            room.addPath(pen.seg(-0.06, -0.72, 0.06, -0.72))
            pen.fill(pot, .black)
            pen.fill(pen.rect(-1, floor, 1, 1), .black)
            var boards = Path()
            for x in Swift.stride(from: -1.5, through: 1.5, by: 0.25) { boards.addPath(pen.seg(x * 0.6, floor, x, 1)) }
            pen.lit { g in
                g.stroke(room, ink)
                g.stroke(boards, ink, 0.2)
            }

            // Vignette 3, the window.
            pen.vignette(3) { pen in
                if !played.contains(3) {
                    Dusk.glassFloat(pen, x: hook.x, y: hook.y + 0.08, radius: 0.028, string: 0.032, lit: true)
                }
            }

            // Vignette 0, the door.
            pen.vignette(0) { pen in
                if played.contains(0) {
                    let coat = pen.poly([(0.2, -0.52), (0.162, -0.49), (0.15, -0.3), (0.25, -0.3), (0.238, -0.49)])
                    pen.fill(coat, .black)
                    var kit = Path()
                    kit.addPath(coat)
                    kit.addPath(pen.seg(0.2, -0.49, 0.2, -0.32))
                    kit.addPath(pen.ellipse(0.295, -0.5, 0.034, 0.01))
                    kit.addPath(pen.curve(0.275, -0.5, 0.295, -0.545, 0.315, -0.5))
                    for x in [0.175, 0.235] {
                        kit.addPath(pen.poly([(x, -0.19), (x, -0.255), (x + 0.024, -0.255), (x + 0.024, -0.205), (x + 0.044, -0.2), (x + 0.044, -0.19)]))
                    }
                    pen.lit(Rescue.tight) { $0.stroke(kit, ink) }
                } else {
                    // Ajar: the sunset through the gap along its hinge side.
                    let gap = pen.rect(door.x0 + 0.004, -0.55, door.x0 + 0.022, -0.16)
                    pen.fill(gap, Dusk.lamplight, 0.55)
                    pen.lit(Rescue.tight) { $0.stroke($0.seg(door.x0 + 0.022, -0.55, door.x0 + 0.022, -0.16), Dusk.lamplight) }
                }
            }

            // Vignette 2, the gift.
            pen.vignette(2) { pen in
                let ground = 0.55
                if played.contains(2) {
                    Cast.figure(pen.at(-0.51, ground, k: 0.2), .grandmother,
                                arms: [[(0.1, -0.72), (0.38, -0.5), (0.62, -0.32)], [(0.1, -0.68), (0.36, -0.46), (0.6, -0.28)]], colour: ink)
                    Cast.figure(pen.at(-0.21, ground, k: 0.14, flip: true), .child,
                                arms: [[(0.1, -0.6), (0.3, -0.62), (0.5, -0.66)], [(-0.1, -0.6), (-0.14, -0.36)]], colour: ink)
                    Dusk.glassFloat(pen, x: -0.37, y: ground - 0.06, radius: 0.024, string: 0)
                } else {
                    Cast.figure(pen.at(-0.51, ground, k: 0.2), .grandmother, colour: ink)
                    Cast.figure(pen.at(-0.21, ground, k: 0.14, flip: true), .child,
                                arms: [[(0.1, -0.6), (0.2, -0.85), (0.3, -1.05)], [(-0.1, -0.6), (0.06, -0.85), (0.16, -1.05)]], colour: ink)
                }
            }
        }
    }

    /// Scene 25, 7:55 back to 7:40, on tri: the kitchen table at golden dusk from the child's seat, the window over the
    /// sea above it, the clock on the wall, the teapot, and her cup. Rod 0, the window: the sun touching the sea with one
    /// small curl of cloud, then a hand above it, clear. Rod 1, the clock: 7:55, then 7:40. Rod 2, the cup: the spoon in
    /// the saucer and the tea still, steaming, then the child's hand stirring it, the tea's swirl: the night's first stir.
    /// Every entry of the cup's rod lies under the others, so it always plays last.
    enum Stir {
        static let window = (x0: -0.27, y0: -0.76, x1: 0.27, y1: -0.28)
        static let clock = (x: 0.5, y: 0.02, r: 0.08)
        static let table = 0.12
        static let cup = (x: -0.5, y: 0.39)

        static func draw(_ pen: Brush, played: Set<Int>) {
            let gold = Dusk.kitchen, cream = Dusk.cream
            var room = Path()
            room.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
            room.addPath(pen.seg(window.x0 - 0.03, window.y1 + 0.014, window.x1 + 0.03, window.y1 + 0.014))
            // The curtains drawn back either side, gathered at the sill.
            for s in [-1.0, 1] {
                room.addPath(pen.curve(s * 0.3, window.y0 - 0.03, s * 0.36, -0.5, s * 0.31, window.y1))
                room.addPath(pen.curve(s * 0.34, window.y0 - 0.03, s * 0.42, -0.5, s * 0.35, window.y1))
            }
            room.addPath(pen.seg(-0.4, window.y0 - 0.03, 0.4, window.y0 - 0.03))
            // The table's far edge against the wall, and its cloth's hem.
            room.addPath(pen.seg(-1, table, 1, table))
            room.addPath(pen.poly([(-1, 0.9), (-0.7, 0.86), (0.7, 0.86), (1, 0.9)], closed: false))
            // The teapot on its stand.
            let pot = pen.ellipse(0.06, 0.3, 0.09, 0.07)
            room.addPath(pot)
            room.addPath(pen.curve(-0.03, 0.3, -0.09, 0.28, -0.11, 0.22))
            room.addPath(pen.curve(0.15, 0.27, 0.2, 0.3, 0.15, 0.33))
            room.addPath(pen.ellipse(0.06, 0.235, 0.035, 0.01))
            room.addPath(pen.circle(0.06, 0.215, 0.008))
            room.addPath(pen.ellipse(0.06, 0.37, 0.1, 0.018))
            // The clock's face: its rim and twelve marks, no numerals.
            room.addPath(pen.circle(clock.x, clock.y, clock.r))
            var marks = Path()
            for k in 0..<12 {
                let a = Double(k) * .pi / 6, l = k % 3 == 0 ? 0.016 : 0.009
                marks.addPath(pen.seg(clock.x + (clock.r - 0.008) * sin(a), clock.y - (clock.r - 0.008) * cos(a),
                                      clock.x + (clock.r - 0.008 - l) * sin(a), clock.y - (clock.r - 0.008 - l) * cos(a)))
            }
            // The cup on its saucer, drawn larger than life, its handle to the right.
            let saucer = pen.ellipse(cup.x, cup.y + 0.1, 0.155, 0.04)
            let body = pen.path { c in
                c.move(to: CGPoint(x: cup.x - 0.105, y: cup.y))
                c.addQuadCurve(to: CGPoint(x: cup.x + 0.105, y: cup.y), control: CGPoint(x: cup.x, y: cup.y + 0.2))
            }
            let rim = pen.ellipse(cup.x, cup.y, 0.105, 0.03)
            var crockery = Path()
            crockery.addPath(saucer); crockery.addPath(body); crockery.addPath(rim)
            crockery.addPath(pen.curve(cup.x + 0.095, cup.y + 0.03, cup.x + 0.17, cup.y + 0.03, cup.x + 0.08, cup.y + 0.08))
            pen.fill(pot, .black)
            pen.fill(saucer, .black)
            pen.fill(body, .black)
            pen.fill(rim, Dusk.tea, 0.55)
            pen.lit { g in
                g.stroke(room, gold)
                g.stroke(marks, gold, 0.8)
                g.stroke(crockery, cream)
            }

            // Vignette 0, the sun over the sea in the window.
            pen.vignette(0) { pen in
                let h = Dusk.stir.horizon, x = -0.14
                let sky = pen.clipped(to: pen.rect(window.x0, window.y0, window.x1, h))
                if played.contains(0) {
                    sky.glow(x, -0.6, 0.1, Dusk.sun, 0.45)
                    sky.lit(Rescue.tight) { $0.fill($0.circle(x, -0.6, 0.034), Dusk.sun) }
                } else {
                    sky.glow(x, h, 0.1, Dusk.sun, 0.5)
                    sky.lit(Rescue.tight) { g in
                        g.fill(g.circle(x, h, 0.034), Dusk.sun)
                        g.stroke(g.curve(-0.07, -0.585, -0.04, -0.61, -0.01, -0.588), cream, 0.8)
                        g.stroke(g.curve(-0.01, -0.588, 0.015, -0.6, 0.02, -0.58), cream, 0.8)
                    }
                }
                // The sun's path on the water.
                pen.lit(Rescue.tight) { g in
                    for (i, y) in [h + 0.018, h + 0.04, h + 0.065].enumerated() {
                        let w = 0.03 - 0.006 * Double(i) - (played.contains(0) ? 0.008 : 0)
                        g.stroke(g.seg(x - w, y, x + w, y), Dusk.sun, 0.7)
                    }
                }
            }

            // Vignette 1, the clock's hands.
            pen.vignette(1) { pen in
                let (hour, minute) = played.contains(1) ? (7.0 + 40 / 60, 40.0) : (7.0 + 55 / 60, 55.0)
                let a = hour / 12 * 2 * .pi, b = minute / 60 * 2 * .pi
                pen.lit(Rescue.tight) { g in
                    g.stroke(g.seg(clock.x, clock.y, clock.x + 0.04 * sin(a), clock.y - 0.04 * cos(a)), cream)
                    g.stroke(g.seg(clock.x, clock.y, clock.x + 0.06 * sin(b), clock.y - 0.06 * cos(b)), cream)
                    g.fill(g.circle(clock.x, clock.y, 0.006), cream)
                }
            }

            // Vignette 2, the cup.
            pen.vignette(2) { pen in
                if played.contains(2) {
                    // The tea's swirl, and the child's hand on the spoon, stirring.
                    let swirl = pen.path { s in
                        for k in 0...48 {
                            let t = Double(k) / 48, a = t * 3.4 * .pi, rr = 0.09 * (1 - 0.85 * t)
                            let q = CGPoint(x: cup.x + rr * cos(a), y: cup.y + rr * 0.3 * sin(a))
                            if k == 0 { s.move(to: q) } else { s.addLine(to: q) }
                        }
                    }
                    let spoon = pen.seg(cup.x - 0.01, cup.y + 0.005, cup.x - 0.085, cup.y - 0.09)
                    // A small fist round the spoon's handle, thumb over it, the sleeve's cuff at the wrist.
                    let fist = pen.at(cup.x - 0.1, cup.y - 0.11, turn: -0.65)
                    let hand = fist.path { h in
                        h.addRoundedRect(in: CGRect(x: -0.045, y: -0.028, width: 0.075, height: 0.056), cornerSize: CGSize(width: 0.022, height: 0.022))
                    }
                    var fingers = Path()
                    for x in [-0.015, 0.005] { fingers.addPath(fist.seg(x, 0.028, x, 0.012)) }
                    fingers.addPath(fist.curve(-0.03, -0.028, 0.0, -0.05, 0.03, -0.022))
                    fingers.addPath(fist.seg(-0.055, -0.032, -0.055, 0.032))
                    pen.lit(Rescue.tight) { g in
                        g.stroke(swirl, Dusk.tea)
                        g.stroke(spoon, Dusk.cream)
                    }
                    pen.fill(hand, .black)
                    pen.lit(Rescue.tight) { g in
                        g.stroke(hand, Dusk.kitchen)
                        g.stroke(fingers, Dusk.kitchen, 0.8)
                    }
                } else {
                    // Still, the spoon on the saucer, steam rising.
                    pen.lit(Rescue.tight) { g in
                        g.stroke(g.seg(cup.x + 0.04, cup.y + 0.1, cup.x + 0.13, cup.y + 0.092), Dusk.cream)
                        g.fill(g.ellipse(cup.x + 0.035, cup.y + 0.1, 0.014, 0.007), Dusk.cream)
                        for o in [-0.05, 0.0, 0.05] {
                            g.stroke(g.path { s in
                                s.move(to: CGPoint(x: cup.x + o, y: cup.y - 0.04))
                                s.addQuadCurve(to: CGPoint(x: cup.x + o - 0.01, y: cup.y - 0.075), control: CGPoint(x: cup.x + o + 0.015, y: cup.y - 0.06))
                                s.addQuadCurve(to: CGPoint(x: cup.x + o - 0.03, y: cup.y - 0.11), control: CGPoint(x: cup.x + o - 0.03, y: cup.y - 0.09))
                            }, Dusk.cream, 0.45)
                        }
                    }
                }
            }
        }
    }
}
