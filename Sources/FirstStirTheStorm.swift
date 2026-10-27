// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// First Stir's chapter 4, The Storm: scenes 16 to 20 of the outline, from 12:30 am back to 9:30 pm, in storm indigo
/// with sodium (the lab's). The lantern unbreaks and the boat rights itself at the storm's peak, the lightning goes, the
/// bell buoy stands up, the high street's awning and sign mend, and the washing goes back on the line before the storm
/// comes in. The rain climbs back up its slant and thins as the night winds back, and the sky warms towards the dusk.
///
/// Scene 16 is the lab's harbour, drawn from the same plan as Dawn After's sunrise (scene 1), so the same view opens and
/// closes the night's worst. Every difference between a scene's two states, glow included, keeps inside its own core,
/// clear of the knob and of the core's edge.
enum Storm: Int, CaseIterable, Sendable {
    case harbour = 16, lightning, buoy, street, washing

    static let ink = Color(0x8F9CFF)
    static let sodium = Color(0xFFA53A)
    static let flame = Color(0xFFE2A0)
    static let bolt = Color(0xD9CCFF)
    static let rain = Color(0xB7CEFF)
    static let cloud = Color(0x5F59D6)

    var title: String { ["The harbour", "Lightning", "The bell buoy", "High street, rain", "Washing"][rawValue - 16] }

    var layout: Layout { [.tri, .quad, .pent, .eye, .pent][rawValue - 16] }

    /// Par, the entry count, is each one's optimum, and plain untwisting reaches it (`testFirstStirParIsTheOptimum`).
    var scramble: String {
        [
            // The cottage's doorway lies in the boat's disc and the father's lantern in the lighthouse's, so the
            // cottage's bottom entry, under every other rod's, heals last (the lab's order).
            "2:+5,1:-4,0:+3,2:-2,1:+5,0:-4,1:+2,0:+3",
            // Every vignette clear of the other discs, so any order plays them whole.
            "3:+4,0:-3,1:+5,2:-2,3:+3,0:+4,1:-4,2:+5,3:-2",
            "0:+4,2:-3,1:+5,3:+2,4:-4,0:-2,2:+5,3:-3,1:+2",
            "0:+4,2:-3,1:+5,3:+2,0:-3,1:+4,2:+5,0:+2,3:-4,1:-2",
            "3:+4,0:-3,1:+5,4:-2,2:+4,0:+3,1:-4,3:-5,2:+2,0:-2",
        ][rawValue - 16]
    }

    var vignettes: Set<Int> { [[0, 1, 2], [0, 2, 3], [0, 2, 3], [0, 1, 2], [0, 1, 3]][rawValue - 16] }

    /// The chapter's window, minutes after midnight, 12:30 am back to 9:30 pm the evening before (negative past
    /// midnight): each scene's played time is the next one's held-back time. The Flood (scenes 11 to 15) ends at 12:30.
    static let times: [Double] = [30, -20, -45, -75, -105, -150]
    var late: Double { Self.times[rawValue - 16] }
    var early: Double { Self.times[rawValue - 15] }

    /// How far the chapter has wound back at `minutes`: 0 at 12:30 am, 1 at 9:30 pm.
    static func back(_ minutes: Double) -> Double { min(max((times[0] - minutes) / (times[0] - times.last!), 0), 1) }

    // MARK: The time layer

    /// The sky's tones at `minutes`, from the zenith to the horizon (the middle one at `Dawn.middle`), and the sea's at
    /// the horizon: the lab's storm at 12:30, warming late towards the dusk rose the evening stood in at 9:30.
    static func tones(_ minutes: Double) -> (zenith: Tone, middle: Tone, low: Tone, sea: Tone) {
        let t = back(minutes) * back(minutes)
        return (Tone(0x000000).mix(Tone(0x03062A), t), Tone(0x0E0B3C).mix(Tone(0x4A2C78), t), Tone(0x1E1960).mix(Tone(0xC8605A), t),
                Tone(0x0B2238).mix(Tone(0x2A3E6A), t))
    }

    /// The rain, one field over everything but a roof: in a random order, so the first n are an even thinning.
    static let drops: [(x: Double, y: Double, l: Double)] = {
        var drops = SplitMix64(state: 67)
        return (0..<380).map { _ in
            (Double.random(in: -1.1..<1.1, using: &drops), Double.random(in: -1.1..<1.0, using: &drops),
             Double.random(in: 0.04..<0.09, using: &drops))
        }
    }()
    static let slant = 18 * Double.pi / 180
    /// How far the rain climbs back up its slant per minute wound back, in tank radii.
    static let climb = 0.07

    /// Drops falling at `minutes`, the last one partly: driving at the storm's peak, a few before it came in.
    static func rain(_ minutes: Double) -> Double { 30 + 340 * (1 - back(minutes)) }

    /// How bright the far lightning stands at `minutes`: the storm's peak, gone by about 10:50.
    static func flash(_ minutes: Double) -> Double { max(1 - back(minutes) / 0.6, 0) }

    /// The rain over the whole picture, played cores and all, at `minutes`, and the far lightning where the scene's sky
    /// has room for it.
    func drawOver(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        let pen = Brush(ctx: ctx, r: r)
        if let bolt, Self.flash(minutes) > 0 {
            let f = Self.flash(minutes)
            neon(ctx, r: r, glows: [(0.05, 0.5 * f), (0.01, 0.9 * f)]) { g in
                g.stroke(pen.poly(bolt, closed: false), with: .color(Self.bolt.opacity(f)), style: pen.style)
            }
        }
        var c = ctx
        if self == .lightning { c.clip(to: Bedroom.windows(pen)) }
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: r + x * r, y: r + y * r) }
        let climbed = Self.climb * (Self.times[0] - minutes), shown = Self.rain(minutes), whole = Int(shown)
        func wrap(_ v: Double) -> Double { (v + 1.1).truncatingRemainder(dividingBy: 2.2) + (v + 1.1 < 0 ? 2.2 : 0) - 1.1 }
        var steady = Path(), last = Path()
        for (i, d) in Self.drops.prefix(whole + 1).enumerated() {
            let x = wrap(d.x - climbed * sin(Self.slant)), y = wrap(d.y - climbed * cos(Self.slant))
            let streak = Path { $0.move(to: p(x, y)); $0.addLine(to: p(x + d.l * sin(Self.slant), y + d.l * cos(Self.slant))) }
            if i < whole { steady.addPath(streak) } else { last.addPath(streak) }
        }
        c.stroke(steady, with: .color(Self.rain.opacity(0.22)), style: pen.style)
        c.stroke(last, with: .color(Self.rain.opacity(0.22 * (shown - Double(whole)))), style: pen.style)
    }

    /// The far lightning's fork, in a part of the sky nothing else is drawn in.
    var bolt: [(Double, Double)]? {
        switch self {
        case .harbour: [(0.70, -0.66), (0.66, -0.56), (0.71, -0.52), (0.64, -0.40), (0.69, -0.37), (0.62, -0.24), (0.64, -0.12)]
        case .buoy: [(-0.74, -0.66), (-0.70, -0.58), (-0.75, -0.53), (-0.68, -0.44), (-0.72, -0.40), (-0.66, -0.31)]
        default: nil
        }
    }

    /// Where the sea meets the sky; the high street's and the yard's lie behind their buildings, so only sky shows.
    var horizon: Double { [0, -0.3, -0.3, 0.3, 0.3][rawValue - 16] }

    func drawSky(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        let pen = Brush(ctx: ctx, r: r)
        if self == .lightning {
            Bedroom.sky(pen, minutes: minutes)
        } else {
            Self.outside(pen, minutes: minutes, box: pen.rect(-1, -1, 1, 1), horizon: horizon)
        }
    }

    func draw(_ ctx: GraphicsContext, r: CGFloat, played: Set<Int>) {
        let pen = Brush(ctx: ctx, r: r)
        switch self {
        case .harbour: StormHarbour.draw(pen, played: played)
        case .lightning: Bedroom.draw(pen, played: played)
        case .buoy: BellBuoy.draw(pen, played: played)
        case .street: HighStreet.draw(pen, played: played)
        case .washing: Washing.draw(pen, played: played)
        }
    }

    /// The sky and sea at `minutes` inside `box`, the sea's swell under the horizon darkening towards the viewer, and
    /// the storm's cloud.
    static func outside(_ pen: Brush, minutes: Double, box: Path, horizon: Double) {
        let tones = tones(minutes), t = back(minutes)
        var pen = pen.clipped(to: box)
        pen.fill(pen.rect(-1, -1, 1, 1), .black)
        pen.fill(pen.rect(-1, -1, 1, horizon), .linearGradient(
            Gradient(stops: [.init(color: tones.zenith.color, location: 0), .init(color: tones.middle.color, location: Dawn.middle),
                             .init(color: tones.low.color, location: 1)]),
            startPoint: pen.point(0, -1), endPoint: pen.point(0, horizon)))
        pen.fill(pen.rect(-1, horizon, 1, 1), .linearGradient(Gradient(colors: [tones.sea.color, .black]),
                                                               startPoint: pen.point(0, horizon), endPoint: pen.point(0, 1)))
        var swell = Path()
        var rng = SplitMix64(state: 41)
        for k in 1...14 {
            let u = Double(k) / 14, y = horizon + 0.012 + (1 - horizon) * 0.98 * pow(u, 1.7)
            // Higher in the storm, calmer as the night winds back to before it came in.
            let amp = (0.003 + 0.024 * u) * (1 - 0.5 * t), wave = 0.05 + 0.22 * u, phase = Double.random(in: 0..<6.3, using: &rng)
            swell.addPath(pen.path { s in
                s.move(to: CGPoint(x: -1.05, y: y))
                for x in Swift.stride(from: -1.05, through: 1.05, by: 0.01) {
                    s.addLine(to: CGPoint(x: x, y: y - amp * sin(x / wave * 2 * .pi + phase)))
                }
            })
        }
        pen.clip = nil
        let sea = pen.clipped(to: pen.rect(-1, horizon, 1, 1)).clipped(to: box)
        sea.lit([(0.025, 0.3), (0.007, 0.7)]) { g in
            g.stroke(swell, ink, 0.3)
        }
        pen.clipped(to: box).lit([(0.025, 0.3), (0.007, 0.7)]) { $0.stroke($0.seg(-1, horizon, 1, horizon), ink, 0.6) }
        // Cloud banks: flat bellies, heaped tops, so every core that holds sky knows which way is up.
        var clouds = Path()
        for (x0, x1, y, h) in [(-0.98, -0.28, horizon - 0.7, 0.07), (0.12, 0.92, horizon - 0.8, 0.06), (-0.62, 0.22, horizon - 0.9, 0.05),
                               (0.46, 0.99, horizon - 0.42, 0.05), (-0.95, -0.4, horizon - 0.25, 0.04)] where y > -1.05 {
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
        let sky = pen.clipped(to: pen.rect(-1, -1.1, 1, horizon)).clipped(to: box)
        sky.fill(clouds, .black, 0.55 * (1 - 0.5 * t))
        sky.lit([(0.03, 0.3), (0.008, 0.6)]) { $0.stroke(clouds, cloud, 0.75 * (1 - 0.45 * t)) }
    }

    /// A storm lantern on its base at (0, 0), 1 tall.
    static func lantern(_ pen: Brush, lit: Bool) {
        var cage = Path()
        cage.addPath(pen.seg(-0.32, 0, 0.32, 0))
        cage.addPath(pen.poly([(-0.26, 0), (-0.22, -0.62), (0.22, -0.62), (0.26, 0)], closed: false))
        cage.addPath(pen.seg(0, -0.02, 0, -0.6))
        cage.addPath(pen.poly([(-0.28, -0.62), (-0.12, -0.8), (0.12, -0.8), (0.28, -0.62)], closed: false))
        cage.addPath(pen.curve(-0.2, -0.84, 0, -1.12, 0.2, -0.84))
        pen.lit(Rescue.tight) { g in
            if lit { g.fill(g.ellipse(0, -0.3, 0.17, 0.21), flame) }
            g.stroke(cage, lit ? sodium : ink)
        }
    }

    /// A figure of the cast in the chapter's ink.
    static func figure(_ pen: Brush, _ who: Cast.Who, arms: [Cast.Limb] = Cast.armsDown, legs: [Cast.Limb]? = nil) {
        Cast.figure(pen, who, arms: arms, legs: legs, colour: ink)
    }
}

extension Level {
    /// The Storm's scenes in story order, numbered by place in `firstStir`.
    static let storm: [Level] = Storm.allCases.map { scene in
        Level(id: "", pack: .firstStir, label: "", title: scene.title, note: "", layout: scene.layout,
              scramble: .parse(scene.scramble, in: scene.layout), story: .storm(scene))
    }
}

/// Scene 16, 12:30 back to 11:40, on tri: the lab's harbour at the storm's peak, on the sunrise's plan. Rod 0, the
/// lantern: smashed and dark, its shards falling past the gallery, then whole and lit. Rod 1, the boat: capsized, the
/// buoy rope snapped and the oar adrift, then moored upright with its lamps lit. Rod 2, the cottage: the door flung
/// open, the window dark and the lantern dropped on the quay, then the father in the lit doorway holding it up and out.
///
/// The lab's two faults are drawn out (F4): the shards fall on the gallery's own side, inside the lantern's core and
/// clear of the other discs, and the boat lies right of the cottage's disc, so neither plays while another rod still
/// stirs it.
enum StormHarbour {
    static let quay = 0.30
    static let waterline = 0.41

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Storm.ink, quay = Self.quay

        // The breakwater's rock and the lighthouse, the sunrise's plan, its lantern storey a fifth larger than life.
        let rock = pen.poly([(-0.27, 0.03), (-0.21, -0.012), (-0.14, -0.03), (-0.07, -0.026), (0.03, -0.045), (0.11, -0.03),
                             (0.19, -0.016), (0.28, 0.03)])
        let tower = pen.poly([(-0.10, -0.025), (-0.062, -0.51), (0.062, -0.51), (0.10, -0.025)])
        pen.fill(rock, .black)
        pen.fill(tower, .black)
        var house = Path()
        house.addPath(tower)
        for y in [-0.14, -0.26, -0.38] {
            let w = 0.10 - 0.038 * (y + 0.025) / -0.485
            house.addPath(pen.curve(-w, y, 0, y + 0.02, w, y))
        }
        house.addPath(pen.poly([(-0.024, -0.03), (-0.024, -0.075), (0, -0.092), (0.024, -0.075), (0.024, -0.03)], closed: false))
        for y in [-0.20, -0.32] { house.addPath(pen.rect(-0.009, y - 0.015, 0.009, y + 0.015)) }
        let room = pen.rect(-0.09, -0.7, 0.09, -0.564)
        var dome = pen.curve(-0.106, -0.7, 0, -0.85, 0.106, -0.7)
        dome.closeSubpath()
        pen.fill(dome, .black)
        pen.fill(pen.rect(-0.132, -0.564, 0.132, -0.51), .black)
        pen.fill(room, .black)
        house.addPath(pen.seg(-0.132, -0.51, 0.132, -0.51))
        house.addPath(pen.seg(-0.132, -0.51, -0.074, -0.474))
        house.addPath(pen.seg(0.132, -0.51, 0.074, -0.474))
        house.addPath(pen.seg(-0.132, -0.564, 0.132, -0.564))
        for x in Swift.stride(from: -0.132, through: 0.133, by: 0.066) { house.addPath(pen.seg(x, -0.51, x, -0.564)) }
        house.addPath(room)
        house.addPath(dome)
        house.addPath(pen.circle(0, -0.792, 0.0156))
        house.addPath(pen.seg(0, -0.808, 0, -0.856))
        pen.lit { g in
            g.stroke(rock, ink, 0.8)
            g.stroke(house, ink)
        }

        // Vignette 0, the lantern.
        pen.vignette(0) { pen in
            if played.contains(0) {
                // Whole and lit, its beams stopping short of the core's edge.
                for side in [-1.0, 1] {
                    pen.fill(pen.poly([(0.09 * side, -0.655), (0.16 * side, -0.67), (0.16 * side, -0.6), (0.09 * side, -0.61)]),
                             Storm.sodium, 0.3)
                }
                pen.fill(pen.rect(-0.086, -0.696, 0.086, -0.568), Storm.sodium, 0.3)
                pen.fill(pen.circle(0, -0.632, 0.03), Storm.flame)
                pen.stroke(room, Storm.sodium)
                pen.stroke(pen.seg(-0.03, -0.7, -0.03, -0.564), Storm.sodium)
                pen.stroke(pen.seg(0.03, -0.7, 0.03, -0.564), Storm.sodium)
            } else {
                // Dark, its panes smashed to the teeth left in their frames, and the shards falling down the
                // lighthouse's own side past the gallery, short of the rock.
                var broken = Path()
                for side in [-1.0, 1] {
                    func m(_ u: Double, _ v: Double) -> (Double, Double) { (side * u, v) }
                    broken.addPath(pen.poly([m(0.09, -0.7), m(0.03, -0.7), m(0.048, -0.674), m(0.062, -0.686), m(0.077, -0.652)]))
                    broken.addPath(pen.poly([m(0.09, -0.564), m(0.03, -0.564), m(0.041, -0.596), m(0.058, -0.58), m(0.074, -0.618)]))
                    broken.addPath(pen.seg(0.03 * side, -0.7, 0.03 * side, -0.564))
                }
                var falling = Path()
                for (x, y, a) in [(-0.145, -0.48, 0.4), (-0.16, -0.42, -0.3), (-0.13, -0.37, 0.9), (0.14, -0.46, 2.2), (0.155, -0.4, 1.1)] {
                    falling.addPath(pen.poly([(x, y), (x + 0.024 * cos(a), y + 0.024 * sin(a)), (x + 0.007, y + 0.02)]))
                }
                pen.stroke(broken, ink, 0.9)
                pen.stroke(falling, ink, 0.75)
            }
        }

        // The quay on the left, the neighbour's gable past the core with its lit window, and the cottage.
        pen.fill(pen.rect(-1, quay, 0, 0.41), .black)
        pen.fill(pen.poly([(-0.99, quay), (-0.99, -0.02), (-0.845, -0.12), (-0.70, -0.02), (-0.70, quay)]), .black)
        pen.fill(pen.rect(-0.81, -0.135, -0.78, -0.08), .black)
        let walls = pen.rect(-0.62, 0.02, -0.04, quay)
        let roof = pen.poly([(-0.66, 0.03), (-0.33, -0.13), (0, 0.03)])
        pen.fill(walls, .black)
        pen.fill(roof, .black)
        pen.fill(pen.rect(-0.54, -0.11, -0.49, -0.02), .black)
        var stone = Path()
        stone.addPath(pen.seg(-1, quay, 0, quay))
        stone.addPath(pen.seg(0, quay, 0, 0.41))
        stone.addPath(pen.seg(-1, 0.355, 0, 0.355))
        stone.addPath(pen.seg(-1, 0.41, 0, 0.41))
        for (i, x) in Swift.stride(from: -0.98, to: -0.01, by: 0.11).enumerated() {
            let o = i % 2 == 0 ? 0.0 : 0.055
            stone.addPath(pen.seg(x + o, quay, x + o, 0.355))
            stone.addPath(pen.seg(x + 0.055 - o, 0.355, x + 0.055 - o, 0.41))
        }
        var cottage = Path()
        cottage.addPath(walls)
        cottage.addPath(roof)
        cottage.addPath(pen.poly([(-0.54, -0.028), (-0.54, -0.11), (-0.49, -0.11), (-0.49, -0.052)], closed: false))
        cottage.addPath(pen.seg(-0.615, 0.03, -0.045, 0.03))
        cottage.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
        cottage.addPath(pen.rect(door.x0, door.y0, door.x1, door.y1))
        cottage.addPath(pen.poly([(-0.99, -0.02), (-0.845, -0.12), (-0.70, -0.02), (-0.70, quay)], closed: false))
        cottage.addPath(pen.poly([(-0.81, -0.08), (-0.81, -0.135), (-0.78, -0.135), (-0.78, -0.08)], closed: false))
        cottage.addPath(pen.poly([(-0.045, quay), (-0.045, 0.265), (-0.055, 0.258), (0.005, 0.258), (-0.005, 0.265), (-0.005, quay)],
                                 closed: false))
        pen.lit { g in
            g.stroke(stone, ink, 0.6)
            g.stroke(cottage, ink)
            g.fill(g.rect(-0.90, 0.06, -0.80, 0.14), Storm.sodium, 0.75)
        }

        // Vignette 2, the cottage door.
        pen.vignette(2) { pen in
            let pane = pen.rect(window.x0, window.y0, window.x1, window.y1)
            let bars = [pen.seg(-0.545, window.y0, -0.545, window.y1), pen.seg(window.x0, 0.135, window.x1, 0.135)]
            if played.contains(2) {
                pen.fill(pane, Storm.sodium, 0.4)
                pen.stroke(pane, Storm.sodium)
                for b in bars { pen.stroke(b, Storm.sodium) }
                // Lit from inside, the light held off the jamb nearest the knob.
                pen.fill(pen.rect(door.x0 + 0.012, door.y0 + 0.006, door.x1 - 0.004, door.y1), Storm.sodium, 0.45)
                // The father in the doorway, backlit, holding the lantern up and out over the quay.
                Storm.figure(pen.at(-0.2125, quay, k: 0.155), .father,
                             arms: [[(0.1, -0.74), (0.36, -0.86), (0.56, -1.0)], [(-0.1, -0.74), (-0.13, -0.42)]])
                Storm.lantern(pen.at(-0.126, 0.172, k: 0.05), lit: true)
                pen.glow(-0.126, 0.157, 0.05, Storm.sodium, 0.45)
            } else {
                // The door flung back on its hinge, the window dark, the lantern on its side on the quay, its glass out.
                let leaf = pen.poly([(door.x1, door.y0), (door.x1 + 0.05, door.y0 - 0.02), (door.x1 + 0.05, quay + 0.02), (door.x1, quay)])
                pen.fill(leaf, .black)
                pen.stroke(leaf, ink)
                for t in [0.33, 0.66] { pen.stroke(pen.seg(door.x1 + 0.05 * t, door.y0 - 0.02 * t, door.x1 + 0.05 * t, quay + 0.02 * t), ink) }
                for b in bars { pen.stroke(b, ink) }
                pen.fill(pen.rect(-0.625, 0.236, -0.52, 0.297), .black)
                Storm.lantern(pen.at(-0.62, quay - 0.034, k: 0.1, turn: .pi / 2), lit: false)
                var spilt = Path()
                for (x, y, a) in [(-0.49, 0.292, 0.3), (-0.47, 0.288, -0.4), (-0.455, 0.294, 0.2)] {
                    spilt.addPath(pen.poly([(x, y), (x + 0.02 * cos(a), y - 0.02 * sin(a)), (x + 0.008, y - 0.014)]))
                }
                pen.stroke(spilt, ink, 0.8)
            }
        }

        // Vignette 1, the boat at its mooring, right of the cottage's disc and below the knob.
        let w = waterline
        let buoy = pen.poly([(0.545, w + 0.005), (0.552, w - 0.025), (0.574, w - 0.025), (0.581, w + 0.005)])
        pen.vignette(1) { pen in
            pen.fill(buoy, .black)
            pen.stroke(buoy, ink)
            pen.stroke(pen.seg(0.563, w - 0.025, 0.563, w - 0.05), ink)
            if played.contains(1) {
                let hull = pen.path { h in
                    h.move(to: CGPoint(x: 0.27, y: w - 0.05)); h.addLine(to: CGPoint(x: 0.47, y: w - 0.05))
                    h.addQuadCurve(to: CGPoint(x: 0.52, y: w - 0.08), control: CGPoint(x: 0.51, y: w - 0.055))
                    h.addQuadCurve(to: CGPoint(x: 0.48, y: w), control: CGPoint(x: 0.51, y: w - 0.02))
                    h.addLine(to: CGPoint(x: 0.29, y: w))
                    h.addQuadCurve(to: CGPoint(x: 0.27, y: w - 0.05), control: CGPoint(x: 0.272, y: w - 0.02))
                }
                let cabin = pen.rect(0.31, w - 0.085, 0.39, w - 0.05)
                pen.fill(hull, .black)
                pen.fill(cabin, .black)
                var boat = Path()
                boat.addPath(hull)
                boat.addPath(cabin)
                boat.addPath(pen.seg(0.28, w - 0.025, 0.5, w - 0.028))
                // Mast with its furled sail, and a pennant streaming downwind.
                boat.addPath(pen.seg(0.49, w - 0.05, 0.49, 0.16))
                boat.addPath(pen.poly([(0.49, 0.16), (0.54, 0.17), (0.49, 0.18)]))
                pen.stroke(boat, ink)
                pen.stroke(pen.seg(0.49, 0.18, 0.512, w - 0.075), ink, 0.5)
                // The mooring line from the bow to the buoy, slack in the swell.
                pen.stroke(pen.curve(0.515, w - 0.07, 0.54, w - 0.01, 0.563, w - 0.05), ink, 0.8)
                // The lamps lit: the cabin's window and the masthead.
                pen.fill(pen.circle(0.35, w - 0.067, 0.011), Storm.sodium, 0.8)
                pen.stroke(pen.circle(0.35, w - 0.067, 0.011), Storm.sodium)
                pen.fill(pen.rect(0.482, 0.19, 0.498, 0.21), Storm.flame)
                var track = Path()
                for (i, y) in Swift.stride(from: w + 0.02, to: w + 0.09, by: 0.03).enumerated() {
                    let d = 0.008 + 0.006 * Double(i % 2)
                    track.addPath(pen.seg(0.35 - d, y, 0.35 + d, y))
                }
                pen.stroke(track, Storm.sodium, 0.55)
            } else {
                // Keel up, the rudder in the air, the mast down in the water, the lamp gone out.
                let hull = pen.path { h in
                    h.move(to: CGPoint(x: 0.28, y: w))
                    h.addQuadCurve(to: CGPoint(x: 0.40, y: w - 0.075), control: CGPoint(x: 0.29, y: w - 0.07))
                    h.addQuadCurve(to: CGPoint(x: 0.52, y: w), control: CGPoint(x: 0.51, y: w - 0.07))
                    h.closeSubpath()
                }
                pen.fill(hull, .black)
                var wreck = Path()
                wreck.addPath(hull)
                wreck.addPath(pen.curve(0.3, w - 0.02, 0.4, w - 0.085, 0.5, w - 0.022))
                wreck.addPath(pen.poly([(0.29, w - 0.015), (0.275, w - 0.045), (0.29, w - 0.055), (0.302, w - 0.03)], closed: false))
                for (x, y, a) in [(0.3, w - 0.06, -2.4), (0.312, w - 0.07, -1.9)] {
                    wreck.addPath(pen.seg(x, y, x + 0.025 * cos(a), y + 0.025 * sin(a)))
                }
                pen.stroke(wreck, ink)
                pen.stroke(pen.seg(0.42, w + 0.012, 0.36, w + 0.1), ink, 0.35)
                // The oar adrift, and the snapped mooring line hanging off the buoy.
                pen.stroke(pen.seg(0.43, w + 0.06, 0.5, w + 0.045), ink, 0.8)
                pen.stroke(pen.poly([(0.5, w + 0.045), (0.53, w + 0.036), (0.534, w + 0.046), (0.503, w + 0.054)]), ink, 0.8)
                pen.stroke(pen.curve(0.563, w - 0.05, 0.535, w - 0.02, 0.54, w + 0.03), ink, 0.8)
                Storm.lantern(pen.at(0.32, w + 0.07, k: 0.035, turn: 0.5), lit: false)
            }
        }
    }

    static let window = (x0: -0.6, y0: 0.09, x1: -0.49, y1: 0.18)
    static let door = (x0: -0.26, y0: 0.14, x1: -0.165, y1: 0.30)
}

/// Scene 17, 11:40 back to 11:15, on quad: the cottage's upstairs room, its bay window over the bay, a small window high
/// on the left wall and a low one over the window seat. Rod 0, the window's view: a fork of lightning to the sea, then
/// none, the lighthouse beam sweeping in. Rod 3, the light: a candle lit on the small window's sill, the ceiling lamp
/// dark, then the lamp lit and the candle out. Rod 2, the child: in her father's arms, face hidden, then kneeling on the
/// window seat beside the dog, both looking out.
enum Bedroom {
    static let bay = (x0: 0.1, y0: -0.62, x1: 0.64, y1: -0.1)
    static let high = (x0: -0.6, y0: -0.5, x1: -0.44, y1: -0.28)
    static let low = (x0: -0.64, y0: 0.04, x1: -0.22, y1: 0.2)
    static let floor = 0.54
    static let seat = 0.27

    static func windows(_ pen: Brush) -> Path {
        var p = Path()
        for o in [bay, high, low] { p.addPath(pen.rect(o.x0, o.y0, o.x1, o.y1)) }
        return p
    }

    /// The room dark, and the night through each window, its horizon a little below the bay's middle.
    static func sky(_ pen: Brush, minutes: Double) {
        pen.fill(pen.rect(-1, -1, 1, 1), .black)
        for o in [bay, high, low] {
            Storm.outside(pen, minutes: minutes, box: pen.rect(o.x0, o.y0, o.x1, o.y1), horizon: o.y0 + (o.y1 - o.y0) * 0.55)
        }
    }

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Storm.ink
        // The room: a sloping ceiling under the roof, the floorboards, the window seat's box.
        var room = Path()
        room.addPath(pen.poly([(-1, -0.66), (-0.2, -0.8), (1, -0.8)], closed: false))
        room.addPath(pen.seg(-1, floor, 1, floor))
        for x in Swift.stride(from: -1.4, through: 1.4, by: 0.28) { room.addPath(pen.seg(x * 0.7, floor, x, 1)) }
        room.addPath(pen.seg(-1, 0.8, 1, 0.8))
        room.addPath(pen.rect(-0.72, seat, -0.18, floor))
        room.addPath(pen.seg(-0.72, seat + 0.03, -0.18, seat + 0.03))
        // The window frames, their sills and bars.
        for o in [bay, high, low] {
            room.addPath(pen.rect(o.x0, o.y0, o.x1, o.y1))
            room.addPath(pen.seg(o.x0 - 0.02, o.y1 + 0.012, o.x1 + 0.02, o.y1 + 0.012))
        }
        room.addPath(pen.seg(0.37, bay.y0, 0.37, -0.42))
        room.addPath(pen.seg(0.37, -0.29, 0.37, bay.y1))
        room.addPath(pen.seg(bay.x0, -0.36, 0.26, -0.36))
        room.addPath(pen.seg(0.48, -0.36, bay.x1, -0.36))
        room.addPath(pen.seg(-0.43, low.y0, -0.43, low.y1))
        // A bed in the right-hand corner, its quilt and pillow, so the corner reads as a floor.
        let bed = pen.poly([(0.18, 0.44), (0.86, 0.44), (0.86, floor), (0.18, floor)])
        pen.fill(bed, .black)
        room.addPath(bed)
        room.addPath(pen.seg(0.18, 0.34, 0.18, floor + 0.04))
        room.addPath(pen.seg(0.86, 0.38, 0.86, floor + 0.04))
        room.addPath(pen.ellipse(0.28, 0.42, 0.07, 0.025))
        room.addPath(pen.curve(0.4, 0.44, 0.6, 0.4, 0.84, 0.44))
        // The ceiling lamp's flex, down to where its shade hangs in rod 3's core.
        room.addPath(pen.seg(-0.24, -0.76, -0.24, -0.56))
        pen.lit { $0.stroke(room, ink) }

        // Vignette 0, the view: the lighthouse on the far breakwater, then the lightning or its beam.
        pen.vignette(0) { pen in
            if played.contains(0) {
                pen.fill(pen.poly([(0.21, -0.44), (0.45, -0.53), (0.45, -0.49), (0.21, -0.425)]), Storm.flame, 0.35)
                pen.fill(pen.rect(0.2, -0.445, 0.222, -0.425), Storm.flame)
            } else {
                pen.fill(pen.rect(0.2, -0.445, 0.222, -0.425), Storm.sodium, 0.7)
                let fork = pen.poly([(0.5, -0.53), (0.485, -0.47), (0.51, -0.44), (0.48, -0.39), (0.505, -0.36), (0.495, -0.335)], closed: false)
                pen.stroke(fork, Storm.bolt)
                pen.stroke(pen.poly([(0.51, -0.44), (0.55, -0.41), (0.545, -0.38)], closed: false), Storm.bolt, 0.8)
                pen.glow(0.5, -0.44, 0.05, Storm.bolt, 0.3)
            }
        }
        // The lighthouse itself, the same in both.
        pen.lit { g in
            g.stroke(g.poly([(0.198, -0.332), (0.204, -0.425), (0.218, -0.425), (0.224, -0.332)]), ink)
            g.stroke(g.seg(0.1, -0.332, 0.3, -0.332), ink, 0.8)
        }

        // Vignette 3, the light.
        pen.vignette(3) { pen in
            let shade = pen.poly([(-0.27, -0.52), (-0.21, -0.52), (-0.19, -0.48), (-0.29, -0.48)])
            let candle = pen.rect(-0.538, -0.33, -0.522, -0.28)
            pen.fill(shade, .black)
            pen.fill(candle, .black)
            pen.stroke(pen.seg(-0.24, -0.56, -0.24, -0.52), ink)
            pen.stroke(pen.poly([(-0.555, -0.27), (-0.505, -0.27)], closed: false), ink)
            if played.contains(3) {
                pen.glow(-0.24, -0.46, 0.09, Storm.sodium, 0.5)
                pen.fill(pen.ellipse(-0.24, -0.475, 0.025, 0.012), Storm.flame)
                pen.stroke(shade, Storm.sodium)
                pen.stroke(candle, ink)
                pen.stroke(pen.seg(-0.53, -0.33, -0.53, -0.342), ink)
            } else {
                pen.stroke(shade, ink)
                pen.stroke(candle, Storm.sodium)
                pen.fill(pen.path { f in
                    f.move(to: CGPoint(x: -0.53, y: -0.37))
                    f.addQuadCurve(to: CGPoint(x: -0.53, y: -0.334), control: CGPoint(x: -0.518, y: -0.345))
                    f.addQuadCurve(to: CGPoint(x: -0.53, y: -0.37), control: CGPoint(x: -0.542, y: -0.345))
                }, Storm.flame)
                pen.glow(-0.53, -0.35, 0.06, Storm.sodium, 0.45)
            }
        }

        // Vignette 2, the child.
        pen.vignette(2) { pen in
            if played.contains(2) {
                // Kneeling on the seat, the dog up on it beside her, its nose raised to the glass, both heads against the
                // low window's sky.
                Storm.figure(pen.at(-0.48, seat, k: 0.1, flip: true), .child,
                             arms: [[(0.1, -0.6), (0.2, -0.5), (0.3, -0.58)]], legs: [[(-0.06, -0.32), (0.06, -0.12), (-0.18, 0)]])
                Cast.dog(pen.at(-0.26, seat, k: 0.1, flip: true), ears: true, nose: -0.12, colour: ink)
            } else {
                // Her father standing on the boards holding her up on his shoulder, her face turned into his neck: her
                // bobble hat beside his brim, her outline over his chest, his arm round her legs.
                Storm.figure(pen.at(-0.22, floor, k: 0.2), .father, arms: [[(-0.1, -0.74), (-0.14, -0.5), (-0.12, -0.36)]])
                Storm.figure(pen.at(-0.18, floor - 0.07, k: 0.12, flip: true), .child,
                             arms: [[(0.1, -0.6), (0.16, -0.7)]], legs: [[(-0.06, -0.32), (-0.1, -0.02)], [(0.06, -0.32), (0.02, -0.04)]])
                pen.stroke(pen.poly([(-0.2, floor - 0.148), (-0.15, floor - 0.1), (-0.21, floor - 0.075)], closed: false), ink)
            }
        }
    }
}

/// Scene 18, 11:15 back to 10:45, on pent: the bay from the headland, the breakwater running out to the lighthouse, the
/// harbourmaster's hut on the headland and the family's boat's mast lamp at its mooring. Rod 0, the lighthouse: spray
/// reaching its gallery, then its beam out, no spray. Rod 2, the bell buoy: heeled hard over, its bell swinging, then
/// upright, bobbing. Rod 3, the hut: a shutter torn off and hanging, then the harbourmaster closing it.
enum BellBuoy {
    static let horizon = -0.3

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Storm.ink
        // The breakwater from the left out to the lighthouse, which stands on its end on the horizon.
        let arm = pen.poly([(-1, -0.27), (-0.08, -0.31), (0.08, -0.31), (0.08, -0.29), (-1, -0.24)])
        let tower = pen.poly([(-0.05, -0.31), (-0.032, -0.64), (0.032, -0.64), (0.05, -0.31)])
        pen.fill(arm, .black)
        pen.fill(tower, .black)
        var house = Path()
        house.addPath(arm)
        house.addPath(tower)
        house.addPath(pen.seg(-0.065, -0.64, 0.065, -0.64))
        house.addPath(pen.seg(-0.065, -0.64, -0.065, -0.66))
        house.addPath(pen.seg(0.065, -0.64, 0.065, -0.66))
        house.addPath(pen.rect(-0.03, -0.71, 0.03, -0.66))
        house.addPath(pen.curve(-0.04, -0.71, 0, -0.76, 0.04, -0.71))
        pen.fill(pen.rect(-0.03, -0.71, 0.03, -0.66), Storm.sodium, 0.4)
        pen.lit { g in
            g.stroke(house, ink)
            g.fill(g.circle(0, -0.685, 0.012), Storm.flame)
        }

        // The headland in the foreground on the left, the hut on it, its door and window; the shutter's hinge side.
        let land = pen.path { l in
            l.move(to: CGPoint(x: -1, y: 0.4))
            l.addQuadCurve(to: CGPoint(x: -0.64, y: ground), control: CGPoint(x: -0.8, y: ground))
            l.addLine(to: CGPoint(x: -0.04, y: ground))
            l.addQuadCurve(to: CGPoint(x: 0.1, y: 1), control: CGPoint(x: 0.04, y: 0.75))
            l.addLine(to: CGPoint(x: -1, y: 1))
            l.closeSubpath()
        }
        pen.fill(land, .black)
        let hut = pen.rect(-0.6, 0.31, -0.15, ground)
        let roof = pen.poly([(-0.64, 0.32), (-0.375, 0.22), (-0.11, 0.32)])
        pen.fill(hut, .black)
        pen.fill(roof, .black)
        var shed = Path()
        shed.addPath(hut)
        shed.addPath(roof)
        shed.addPath(pen.rect(-0.56, 0.4, -0.5, ground))
        shed.addPath(pen.rect(Self.pane.x0, Self.pane.y0, Self.pane.x1, Self.pane.y1))
        shed.addPath(pen.seg(-0.5, 0.26, -0.5, 0.18))
        // Tufts of grass along the headland, bent by the wind.
        for x in [-0.9, -0.78, -0.66, 0.0] {
            let y = x < -0.64 ? ground - 0.06 * pow((-0.64 - x) / 0.36, 2) * 2 : ground
            shed.addPath(pen.curve(x, y, x + 0.01, y - 0.03, x + 0.04, y - 0.04))
        }
        pen.lit { g in
            g.stroke(land, ink, 0.8)
            g.stroke(shed, ink)
        }

        // The family's boat at its mooring, far out on the right, only its mast lamp lit.
        pen.lit { g in
            g.stroke(g.curve(0.66, -0.13, 0.72, -0.17, 0.78, -0.13), ink, 0.8)
            g.stroke(g.seg(0.72, -0.15, 0.72, -0.26), ink, 0.8)
            g.fill(g.circle(0.72, -0.265, 0.008), Storm.sodium)
        }

        // Vignette 0, the lighthouse's spray or its beam.
        pen.vignette(0) { pen in
            if played.contains(0) {
                pen.fill(pen.poly([(0.03, -0.692), (0.15, -0.715), (0.15, -0.66), (0.03, -0.676)]), Storm.flame, 0.3)
                pen.fill(pen.poly([(-0.03, -0.69), (-0.1, -0.705), (-0.1, -0.67), (-0.03, -0.677)]), Storm.flame, 0.2)
            } else {
                // A sea breaking on the end, its spray thrown up the tower to the gallery and blown off downwind.
                var spray = Path()
                spray.addPath(pen.curve(-0.15, -0.38, -0.16, -0.56, -0.1, -0.67))
                spray.addPath(pen.curve(0.15, -0.38, 0.16, -0.56, 0.1, -0.68))
                spray.addPath(pen.curve(-0.11, -0.4, -0.125, -0.5, -0.1, -0.56))
                spray.addPath(pen.curve(0.11, -0.4, 0.125, -0.5, 0.1, -0.57))
                for (x, y) in [(-0.13, -0.69), (0.12, -0.71), (0.18, -0.62), (-0.18, -0.58), (0.19, -0.5), (0.06, -0.73)] {
                    spray.addPath(pen.circle(x, y, 0.008))
                }
                pen.stroke(spray, ink, 0.9)
            }
        }

        pen.lit { $0.stroke($0.curve(0.4, 0.54, 0.46, 0.515, 0.53, 0.54), ink, 0.8) }

        // Vignette 2, the bell buoy.
        pen.vignette(2) { pen in
            let heel = played.contains(2) ? 0.0 : 0.5
            Self.buoy(pen.at(0.46, 0.53, k: 0.13, turn: heel), swinging: !played.contains(2))
        }

        // Vignette 3, the shutter.
        pen.vignette(3) { pen in
            let p = Self.pane
            if played.contains(3) {
                // Both shutters to, and the harbourmaster pulling the second one shut.
                pen.fill(pen.rect(p.x0, p.y0, p.x1, p.y1), .black)
                pen.stroke(pen.rect(p.x0, p.y0, (p.x0 + p.x1) / 2, p.y1), ink)
                let open = pen.poly([((p.x0 + p.x1) / 2, p.y0), (p.x1 + 0.01, p.y0 - 0.01), (p.x1 + 0.01, p.y1 + 0.01), ((p.x0 + p.x1) / 2, p.y1)])
                pen.fill(open, .black)
                pen.stroke(open, ink)
                Storm.figure(pen.at(-0.16, ground, k: 0.12, flip: true), .neighbour, arms: [[(0.1, -0.72), (0.2, -0.86), (0.18, -1.06)]])
            } else {
                // The window bare and dark, one shutter gone, the other hanging by its lower hinge.
                pen.stroke(pen.seg((p.x0 + p.x1) / 2, p.y0, (p.x0 + p.x1) / 2, p.y1), ink)
                let hanging = pen.poly([(p.x1, p.y1), (p.x1 + 0.035, p.y1 - 0.012), (p.x1 + 0.055, p.y1 + 0.022), (p.x1 + 0.02, p.y1 + 0.034)])
                pen.fill(hanging, .black)
                pen.stroke(hanging, ink)
                pen.stroke(pen.seg(p.x1 + 0.018, p.y1 + 0.004, p.x1 + 0.038, p.y1 + 0.017), ink)
            }
        }
    }

    static let pane = (x0: -0.245, y0: 0.33, x1: -0.19, y1: 0.4)
    static let ground = 0.54

    /// A bell buoy floating on (0, 0), 1 tall: its float, the cage above it and the bell hung in the cage, swinging
    /// when the sea throws it.
    static func buoy(_ pen: Brush, swinging: Bool) {
        let float = pen.poly([(-0.3, 0), (-0.22, -0.18), (0.22, -0.18), (0.3, 0)])
        var cage = Path()
        cage.addPath(pen.poly([(-0.18, -0.18), (-0.08, -0.82), (0.08, -0.82), (0.18, -0.18)], closed: false))
        cage.addPath(pen.seg(-0.13, -0.5, 0.13, -0.5))
        cage.addPath(pen.seg(-0.12, -0.86, 0.12, -0.86))
        let bell = pen.at(0, -0.74, turn: swinging ? 0.5 : 0).path { b in
            b.move(to: CGPoint(x: -0.06, y: 0))
            b.addQuadCurve(to: CGPoint(x: -0.1, y: 0.2), control: CGPoint(x: -0.08, y: 0.12))
            b.addLine(to: CGPoint(x: 0.1, y: 0.2))
            b.addQuadCurve(to: CGPoint(x: 0.06, y: 0), control: CGPoint(x: 0.08, y: 0.12))
            b.closeSubpath()
        }
        pen.fill(float, .black)
        pen.fill(bell, .black)
        pen.stroke(float, Storm.ink)
        pen.stroke(cage, Storm.ink)
        pen.stroke(bell, Storm.ink)
        if swinging {
            pen.stroke(pen.curve(0.12, -0.62, 0.2, -0.56, 0.2, -0.46), Storm.ink, 0.6)
        }
    }
}

/// Scene 19, 10:45 back to 10:15, on eye: the high street in driving rain under its sodium lamps, the café on the left,
/// a shop's sign over the street, a bicycle on the right. Rod 0, the café's awning: torn and flapping in strips, then
/// whole, the café's owner winding it in. Rod 1, the bicycle: blown over in the gutter, a wheel spinning, then leaning on
/// the lamp post. Rod 2, the shop sign: hanging by one chain, then by two.
enum HighStreet {
    static let roofs = -0.62
    static let pavement = 0.16
    static let kerb = 0.22

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Storm.ink
        // The street's far side: shopfronts in a row under their roofs and chimneys, windows above, the road and its
        // far kerb in front of them.
        let row = pen.poly([(-1, roofs + 0.06), (-0.62, roofs + 0.06), (-0.62, roofs), (-0.2, roofs), (-0.2, -0.8), (0.03, -0.9), (0.26, -0.8),
                            (0.26, roofs + 0.03), (0.7, roofs + 0.03), (0.7, roofs - 0.02), (1, roofs - 0.02), (1, pavement), (-1, pavement)])
        pen.fill(row, .black)
        var fronts = Path()
        fronts.addPath(row)
        for x in [-0.62, -0.2, 0.26, 0.7] { fronts.addPath(pen.seg(x, roofs + 0.06, x, pavement)) }
        fronts.addPath(pen.circle(0.03, -0.8, 0.03))
        for (x, y) in [(-0.86, -0.42), (-0.12, -0.38), (0.38, -0.44), (0.82, -0.42)] {
            fronts.addPath(pen.rect(x - 0.05, y - 0.07, x + 0.05, y + 0.07))
        }
        fronts.addPath(pen.rect(-0.5, roofs - 0.09, -0.44, roofs))
        fronts.addPath(pen.rect(0.46, roofs - 0.06, 0.52, roofs + 0.03))
        fronts.addPath(pen.rect(-0.16, -0.86, -0.1, -0.76))
        // The café: its door and the big window under where the awning goes.
        fronts.addPath(pen.rect(-0.74, -0.08, -0.48, 0.12))
        fronts.addPath(pen.rect(-0.38, -0.06, -0.28, pavement))
        fronts.addPath(pen.seg(-0.74, 0.02, -0.48, 0.02))
        // The shop on the right with its window, the lamp post in front of it.
        fronts.addPath(pen.rect(0.3, -0.12, 0.56, 0.08))
        fronts.addPath(pen.rect(0.06, -0.08, 0.16, pavement))
        pen.fill(pen.rect(-1, pavement, 1, 1), .black)
        var street = Path()
        street.addPath(pen.seg(-1, kerb, 1, kerb))
        for x in Swift.stride(from: -1.6, through: 1.6, by: 0.4) { street.addPath(pen.seg(x * 0.5, kerb, x, 1)) }
        for y in [0.42, 0.7] { street.addPath(pen.seg(-1, y, 1, y)) }
        pen.lit { g in
            g.stroke(fronts, ink)
            g.stroke(street, ink, 0.35)
            g.fill(g.rect(-0.735, -0.075, -0.485, 0.115), Storm.sodium, 0.18)
            g.fill(g.rect(0.305, -0.115, 0.555, 0.075), Storm.sodium, 0.14)
        }
        // Sodium lamps along the kerb, their pools on the wet road.
        for (x, top) in [(0.66, -0.3), (-0.9, -0.3)] {
            pen.lit { g in
                g.stroke(g.seg(x, kerb, x, top), ink)
                g.stroke(g.curve(x, top, x - 0.01, top - 0.05, x - 0.06, top - 0.04), ink)
                g.fill(g.ellipse(x - 0.065, top - 0.03, 0.02, 0.01), Storm.sodium)
            }
            pen.lit([(0.03, 0.3), (0.01, 0.6)]) { g in
                g.fill(g.ellipse(x - 0.065, kerb + 0.06, 0.1, 0.012), Storm.sodium, 0.25)
            }
        }

        // Vignette 0, the awning.
        pen.vignette(0) { pen in
            if played.contains(0) {
                // Whole, its stripes and valance, and the café's owner winding it in with the crank pole.
                let canvas = pen.poly([(-0.62, -0.19), (-0.42, -0.19), (-0.42, -0.13), (-0.62, -0.13)])
                pen.fill(canvas, .black)
                pen.stroke(canvas, ink)
                for x in Swift.stride(from: -0.58, through: -0.45, by: 0.04) { pen.stroke(pen.seg(x, -0.19, x, -0.13), ink, 0.7) }
                pen.stroke(pen.poly(Swift.stride(from: -0.62, through: -0.415, by: 0.02).enumerated().map { i, x in (x, i % 2 == 0 ? -0.13 : -0.112) },
                                    closed: false), ink)
                Storm.figure(pen.at(-0.62, pavement, k: 0.14), .neighbour, arms: [[(0.1, -0.72), (0.2, -0.86), (0.26, -0.98)]])
                pen.stroke(pen.seg(-0.584, 0.022, -0.55, -0.13), ink)
            } else {
                // Torn: the frame's bar left, ragged strips streaming off it downwind.
                pen.stroke(pen.seg(-0.62, -0.19, -0.42, -0.19), ink)
                for (i, x) in [-0.61, -0.56, -0.51, -0.47].enumerated() {
                    let l = [0.08, 0.06, 0.09, 0.05][i]
                    pen.stroke(pen.curve(x, -0.19, x + l * 0.6, -0.19 + l * 0.2 + 0.02, x + l, -0.14 + Double(i % 2) * 0.03), ink)
                }
            }
        }

        // Vignette 1, the bicycle.
        pen.vignette(1) { pen in
            if played.contains(1) {
                Self.bicycle(pen.at(0.555, pavement - 0.004, k: 0.17, turn: -0.08))
            } else {
                Self.fallen(pen)
            }
        }

        // Vignette 2, the sign, on its bracket out from the shopfront.
        pen.lit { g in
            g.stroke(g.seg(-0.2, -0.68, -0.08, -0.68), ink)
            g.stroke(g.seg(-0.2, -0.72, -0.16, -0.68), ink)
        }
        pen.vignette(2) { pen in
            // The board hangs from its top left corner by one chain, or level by two.
            let board = played.contains(2) ? pen.at(-0.17, -0.665) : pen.at(-0.17, -0.665, turn: 1.2)
            let w = 0.08, h = 0.04
            let edge = board.rect(0, 0, w, h)
            pen.fill(edge, .black)
            pen.stroke(edge, Storm.sodium)
            // A boot on it, the cobbler's shape.
            pen.stroke(board.at(w / 2, h / 2, k: 0.03).poly([(-0.4, -0.5), (-0.4, 0.4), (0.6, 0.4), (0.6, 0.1), (0.1, 0), (0.1, -0.5)]), Storm.sodium)
            pen.stroke(pen.seg(-0.165, -0.68, -0.165, -0.665), ink)
            if played.contains(2) { pen.stroke(pen.seg(-0.095, -0.68, -0.095, -0.665), ink) }
        }
    }

    /// The bicycle blown over in the gutter on its side, seen from the pavement: the back wheel flat on the road, the
    /// front wheel twisted up and spinning.
    static func fallen(_ pen: Brush) {
        var frame = Path()
        frame.addPath(pen.ellipse(0.42, kerb + 0.012, 0.045, 0.014))
        frame.addPath(pen.ellipse(0.54, kerb - 0.02, 0.035, 0.042))
        frame.addPath(pen.poly([(0.42, kerb + 0.012), (0.47, kerb), (0.525, kerb - 0.03), (0.44, kerb - 0.01), (0.42, kerb + 0.012)], closed: false))
        frame.addPath(pen.poly([(0.525, kerb - 0.03), (0.515, kerb - 0.06), (0.49, kerb - 0.055)], closed: false))
        pen.stroke(frame, Storm.ink)
        for a in [0.3, 1.9, 3.5, 5.1] {
            pen.stroke(pen.curve(0.54 + 0.05 * cos(a), kerb - 0.02 + 0.058 * sin(a), 0.54 + 0.06 * cos(a + 0.3), kerb - 0.02 + 0.068 * sin(a + 0.3),
                                 0.54 + 0.05 * cos(a + 0.6), kerb - 0.02 + 0.058 * sin(a + 0.6)), Storm.ink, 0.6)
        }
    }

    /// A bicycle standing on (0, 0), 1 long, its front to the right; a spinning wheel shows its spokes blurred.
    static func bicycle(_ pen: Brush) {
        var frame = Path()
        let r = 0.26
        frame.addPath(pen.circle(-0.5 + r, -r, r))
        frame.addPath(pen.circle(0.5 - r, -r, r))
        frame.addPath(pen.poly([(-0.5 + r, -r), (-0.04, -r), (0.12, -0.62), (-0.14, -0.6), (-0.5 + r, -r)], closed: false))
        frame.addPath(pen.poly([(-0.04, -r), (-0.14, -0.6)], closed: false))
        frame.addPath(pen.poly([(0.5 - r, -r), (0.12, -0.62), (0.1, -0.72), (0.2, -0.74)], closed: false))
        frame.addPath(pen.seg(-0.2, -0.66, -0.06, -0.66))
        pen.stroke(frame, Storm.ink)
    }
}

/// Scene 20, 10:15 back to 9:30, on pent: the cottage's back yard, the washing line across it, the neighbour's house on
/// the right, the kennel by the back door, the gate. Rod 0, the line: snapped, a shirt flying off over the roofs, then
/// shirts pegged, streaming hard. Rod 1, the neighbour's shutters: shut and barred, then the neighbour leaning out to pull
/// them to. Rod 3, the kennel: empty, its chain lying, then the child unclipping the dog.
enum Washing {
    static let ground = 0.66
    static let line = -0.4

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Storm.ink
        // The roofs over the yard's walls against the sky, and the neighbour's house wall up the right.
        // The town's roofs beyond the yard wall, low enough that the line and its washing stand against the sky.
        let skyline: [(Double, Double)] = [(-0.3, -0.02), (-0.2, -0.1), (-0.1, -0.02), (0.0, -0.02), (0.0, -0.08), (0.12, -0.08),
                                           (0.12, -0.02), (0.2, -0.12), (0.3, -0.02)]
        let roofs = pen.poly([(-1, -0.42), (-0.7, -0.42), (-0.55, -0.56), (-0.4, -0.42), (-0.3, -0.42)] + skyline + [(0.3, -0.5), (1, -0.5), (1, 1), (-1, 1)])
        pen.fill(roofs, .black)
        var yard = Path()
        yard.addPath(pen.poly([(-1, -0.42), (-0.7, -0.42), (-0.55, -0.56), (-0.4, -0.42), (-0.3, -0.42), (-0.3, ground)], closed: false))
        yard.addPath(pen.seg(-0.3, 0.3, 0.3, 0.3))
        yard.addPath(pen.seg(-0.3, 0.33, 0.3, 0.33))
        yard.addPath(pen.rect(-0.78, -0.32, -0.66, -0.2))
        pen.lit { $0.stroke($0.poly(skyline, closed: false), ink, 0.5) }
        yard.addPath(pen.poly([(0.3, ground), (0.3, -0.5), (1, -0.5)], closed: false))
        yard.addPath(pen.rect(-0.6, -0.62, -0.56, -0.5))
        yard.addPath(pen.seg(-1, ground, 1, ground))
        for x in Swift.stride(from: -1.4, through: 1.4, by: 0.28) { yard.addPath(pen.seg(x * 0.6, ground, x, 1)) }
        yard.addPath(pen.seg(-1, 0.8, 1, 0.8))
        // The neighbour's window and its shutters' hinges, and a drainpipe.
        yard.addPath(pen.rect(Self.pane.x0, Self.pane.y0, Self.pane.x1, Self.pane.y1))
        yard.addPath(pen.seg(0.86, -0.5, 0.86, ground))
        yard.addPath(pen.rect(0.7, 0.2, 0.84, 0.42))
        // The cottage's back wall on the left, its back door, the line's two posts.
        yard.addPath(pen.seg(-0.82, -0.42, -0.82, ground))
        yard.addPath(pen.rect(-0.78, 0.0, -0.64, ground))
        yard.addPath(pen.seg(-0.12, ground, -0.12, Self.line - 0.02))
        yard.addPath(pen.seg(0.12, ground, 0.12, Self.line - 0.02))
        // The gate in the yard's wall, bottom right.
        yard.addPath(pen.rect(0.32, 0.3, 0.56, ground))
        yard.addPath(pen.seg(0.32, 0.45, 0.56, 0.45))
        yard.addPath(pen.seg(0.32, ground, 0.56, 0.3))
        // The kennel by the back door.
        let kennel = pen.poly([(-0.68, ground), (-0.68, 0.54), (-0.59, 0.47), (-0.5, 0.54), (-0.5, ground)])
        pen.fill(kennel, .black)
        yard.addPath(kennel)
        yard.addPath(pen.path { a in
            a.move(to: CGPoint(x: -0.62, y: ground)); a.addLine(to: CGPoint(x: -0.62, y: 0.59))
            a.addQuadCurve(to: CGPoint(x: -0.56, y: 0.59), control: CGPoint(x: -0.59, y: 0.55)); a.addLine(to: CGPoint(x: -0.56, y: ground))
        })
        pen.lit { $0.stroke(yard, ink) }
        pen.lit { $0.fill($0.rect(0.705, 0.205, 0.835, 0.415), Storm.sodium, 0.3) }

        // Vignette 0, the line.
        pen.vignette(0) { pen in
            if played.contains(0) {
                pen.stroke(pen.seg(-0.12, line, 0.12, line), ink)
                // Shirts pegged on it, streaming hard downwind.
                for x in [-0.11, 0.0] {
                    let shirt = pen.at(x, line, k: 0.11, turn: -1.2).poly([(0, 0), (0.5, 0), (0.55, 0.3), (0.75, 0.35), (0.7, 0.55), (0.5, 0.5),
                                                                            (0.5, 1), (0, 1), (0, 0.5), (-0.2, 0.55), (-0.25, 0.35), (-0.05, 0.3)])
                    pen.fill(shirt, .black)
                    pen.stroke(shirt, ink)
                }
                for x in [-0.11, -0.055, 0.0, 0.055] { pen.stroke(pen.seg(x, line - 0.012, x, line + 0.012), Storm.sodium) }
            } else {
                // Snapped: its ends hanging off the posts, and a shirt torn off and flying away over the roofs.
                pen.stroke(pen.curve(-0.12, line, -0.1, line + 0.03, -0.1, line + 0.05), ink)
                pen.stroke(pen.curve(0.12, line, 0.1, line + 0.025, 0.105, line + 0.045), ink)
                let shirt = pen.at(0.09, -0.73, k: 0.07, turn: 0.6).poly([(0, 0), (0.5, 0), (0.55, 0.3), (0.75, 0.35), (0.7, 0.55), (0.5, 0.5),
                                                                          (0.5, 1), (0, 1), (0, 0.5), (-0.2, 0.55), (-0.25, 0.35), (-0.05, 0.3)])
                pen.fill(shirt, .black)
                pen.stroke(shirt, ink)
            }
        }

        // Vignette 1, the shutters.
        pen.vignette(1) { pen in
            let p = Self.pane, mid = (p.x0 + p.x1) / 2
            if played.contains(1) {
                // Open, lit inside, the neighbour leaning out to pull them to.
                pen.fill(pen.rect(p.x0, p.y0, p.x1, p.y1), Storm.sodium, 0.35)
                let left = pen.poly([(p.x0, p.y0), (p.x0 - 0.03, p.y0 + 0.012), (p.x0 - 0.03, p.y1 - 0.012), (p.x0, p.y1)])
                let right = pen.poly([(p.x1, p.y0), (p.x1 + 0.03, p.y0 + 0.012), (p.x1 + 0.03, p.y1 - 0.012), (p.x1, p.y1)])
                for s in [left, right] { pen.fill(s, .black); pen.stroke(s, ink) }
                Storm.figure(pen.clipped(to: pen.rect(p.x0 - 0.1, p.y0 - 0.1, p.x1 + 0.1, p.y1)).at(mid, p.y1 + 0.06, k: 0.12), .neighbour,
                             arms: [[(0.1, -0.72), (0.26, -0.7), (0.36, -0.64)], [(-0.1, -0.72), (-0.26, -0.7), (-0.36, -0.64)]])
                pen.stroke(pen.rect(p.x0, p.y0, p.x1, p.y1), Storm.sodium)
            } else {
                // Shut, barred across.
                pen.fill(pen.rect(p.x0, p.y0, p.x1, p.y1), .black)
                pen.stroke(pen.rect(p.x0, p.y0, mid, p.y1), ink)
                pen.stroke(pen.rect(mid, p.y0, p.x1, p.y1), ink)
                pen.stroke(pen.seg(p.x0 - 0.01, (p.y0 + p.y1) / 2, p.x1 + 0.01, (p.y0 + p.y1) / 2), ink)
            }
        }

        // Vignette 3, the kennel: its chain from a ring on the kennel's side.
        pen.vignette(3) { pen in
            if played.contains(3) {
                Cast.dog(pen.at(-0.36, ground, k: 0.09), ears: true, colour: ink)
                pen.stroke(pen.curve(-0.5, 0.6, -0.42, 0.63, -0.33, 0.6), ink, 0.8)
                Storm.figure(pen.at(-0.25, ground, k: 0.09, flip: true), .child,
                             arms: [[(0.1, -0.6), (0.4, -0.6), (0.62, -0.62)]], legs: [[(-0.06, -0.32), (0.08, -0.16), (-0.02, 0)], [(0.06, -0.32), (0.16, -0.02)]])
            } else {
                pen.stroke(pen.path { c in
                    c.move(to: CGPoint(x: -0.5, y: 0.6))
                    c.addQuadCurve(to: CGPoint(x: -0.41, y: ground - 0.008), control: CGPoint(x: -0.47, y: 0.645))
                    c.addQuadCurve(to: CGPoint(x: -0.3, y: ground - 0.01), control: CGPoint(x: -0.36, y: ground - 0.02))
                }, ink, 0.8)
                pen.stroke(pen.circle(-0.29, ground - 0.012, 0.01), ink, 0.8)
            }
        }
    }

    static let pane = (x0: 0.495, y0: -0.39, x1: 0.575, y1: -0.31)
}
