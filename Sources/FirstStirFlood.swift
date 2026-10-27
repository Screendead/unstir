// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// First Stir's chapter 3, The Flood: scenes 11 to 15 of the outline, from 2:30 back to 12:30 am, in flood teal. The
/// father goes back along the breakwater to the quay, the high street's water falls back from the sills, the float drifts
/// back in at the cottage door, the kitchen drains to the table's legs, and the sea sinks back below the quay wall. Each
/// scene's night carries on from the one before: its held-back sky is the last scene's played one, and the Rescue's rain
/// keeps falling, thicker as the night winds back towards the storm.
///
/// A scene is drawn as the Rescue's are, with its `Brush` and `Cast`: single-weight line on black, baked held back and
/// played, every difference between the two, glow included, inside its own rod's core, clear of the knob and of the
/// core's edge. The floodwater's level is fixed in each scene outside the cores; only a vignette moves it.
enum Flood: Int, CaseIterable, Sendable {
    case path = 11, street, window, kitchen, quay

    static let ink = Color(0x8F9CFF)
    static let sea = Color(0x2CD5C4)
    static let deep = Color(0x0B2238)
    static let rain = Color(0xB7CEFF)
    /// The child's torch.
    static let torch = Color(0xDFF6FF)
    /// The drowned lamps, and every lamp lit: the family's sodium and flame, as in the other chapters.
    static let sodium = Color(0xFFA53A)
    static let flame = Color(0xFFE2A0)
    /// The float keeps its teal all night.
    static let float = Color(0x3FE0B0)

    var title: String {
        ["The breakwater path", "High street under water", "The upstairs window", "The kitchen, flooded", "Over the quay"][rawValue - 11]
    }

    var layout: Layout { [.eye, .pent, .quad, .eye, .pent][rawValue - 11] }

    /// Par, the entry count, is each one's optimum, and plain untwisting reaches it (`testFirstStirParIsTheOptimum`).
    var scramble: String {
        [
            // The path's rod (1) at the bottom, below both of the quay end's (0): the wave over the father reaches rod
            // 0's disc, so he goes back to the quay only once it is still.
            "1:+4,0:-3,3:+5,2:-4,0:-2,3:+3,2:+2",
            "0:+3,2:-4,3:+5,1:-3,0:-5,4:+2,2:+4,3:-2",
            "1:-4,3:+3,0:+5,2:-3,1:+2,0:-4,3:-5,2:+4",
            // The table's rod (0) at the bottom, below all three of the stair's (1): the tabletop reaches the stair's
            // disc, so the cup lands back on it only once the stair is still.
            "0:+4,3:-3,1:+5,2:-4,1:-2,3:+3,2:+2,1:+4",
            "4:-3,1:+4,3:+5,0:-2,4:+3,2:-4,1:-5,3:+2,0:+3",
        ][rawValue - 11]
    }

    var vignettes: Set<Int> { [[0, 1, 2], [0, 2, 3], [3, 0, 1], [0, 1, 3], [1, 3, 4]][rawValue - 11] }

    /// The chapter's window, minutes after midnight, 2:30 back to 12:30: each scene's played time is the next one's
    /// held-back time, and its first is the Rescue's last.
    static let times: [Double] = [Rescue.times.last!, 125, 100, 75, 55, 30]
    var late: Double { Self.times[rawValue - 11] }
    var early: Double { Self.times[rawValue - 10] }

    /// How far the chapter has wound back at `minutes`: 0 at 2:30, 1 at 12:30.
    static func back(_ minutes: Double) -> Double { min(max((times[0] - minutes) / (times[0] - times.last!), 0), 1) }

    // MARK: The time layer

    /// Drops falling at `minutes`: the Rescue's rain at 2:30, steadier and thicker back towards the storm.
    static func rain(_ minutes: Double) -> Double { Rescue.rain(times[0]) + 80 * back(minutes) }

    func drawOver(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        Rescue.rain(ctx, r: r, minutes: minutes, drops: Self.rain(minutes), through: self == .kitchen ? { Kitchen.windows($0) } : nil)
    }

    /// How far the sky has turned from the Rescue's at 2:30 to the flood's own: wholly by the end of the first scene.
    static func turned(_ minutes: Double) -> Double {
        let x = min(back(minutes) / back(times[1]), 1)
        return x * x * (3 - 2 * x)
    }

    /// The sky's tones from the zenith down to the horizon at `minutes`: the town's lit cloud gone, the deep sea's blue
    /// low down, leaning towards the storm's indigo as the night winds back; turned from the Rescue's at 2:30.
    static func skyTones(_ minutes: Double) -> [Tone] {
        let night = Tone(0x05050F), low = Tone(0x0B2238).mix(Tone(0x1E1960), 0.7 * back(minutes))
        return zip(Rescue.skyTones(times[0]), [night, night.mix(low, 0.4), low]).map { $0.mix($1, turned(minutes)) }
    }

    static func skyStops(_ minutes: Double) -> [Gradient.Stop] {
        zip(skyTones(minutes), [0, CGFloat(Dawn.middle), 1]).map { .init(color: $0.color, location: $1) }
    }

    /// The sea's tones at the horizon and halfway to the viewer, turned from the Rescue's as the sky is, then black.
    static func seaTones(_ minutes: Double) -> [Tone] {
        let rescue = Rescue.seaTones(times[0]), t = turned(minutes), deep = Tone(0x0B2238)
        return [rescue[0].mix(deep.mix(Tone(0x2CD5C4), 0.12), t), rescue[1].mix(deep.scaled(0.45), t), Tone(0)]
    }

    func drawSky(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {
        let pen = Brush(ctx: ctx, r: r)
        if self == .kitchen {
            Kitchen.sky(pen, minutes: minutes)
        } else {
            Rescue.outside(pen, horizon: horizon, sky: Self.skyStops(minutes), sea: Self.seaTones(minutes), swell: Self.sea)
        }
    }

    func draw(_ ctx: GraphicsContext, r: CGFloat, played: Set<Int>) {
        let pen = Brush(ctx: ctx, r: r)
        switch self {
        case .path: BreakwaterPath.draw(pen, played: played)
        case .street: HighStreet.draw(pen, played: played)
        case .window: UpstairsWindow.draw(pen, played: played)
        case .kitchen: Kitchen.draw(pen, played: played)
        case .quay: OverTheQuay.draw(pen, played: played)
        }
    }

    var horizon: Double { [BreakwaterPath.horizon, HighStreet.water, -0.7, 0, -0.5][rawValue - 11] }

    /// Low cloud in the chapter's ink.
    static func clouds(_ pen: Brush, _ banks: [(x0: Double, x1: Double, y: Double, h: Double)]) {
        Rescue.clouds(pen, banks, colour: ink.opacity(0.55))
    }

    /// Floodwater from y down to the foot of the tank: a black that dims whatever stands in it, its surface in the sea's
    /// line with a ripple or two under it.
    static func water(_ pen: Brush, _ y: Double, x0: Double = -1, x1: Double = 1, glows: [(blur: Double, opacity: Double)]? = nil) {
        pen.fill(pen.rect(x0, y, x1, 1), .black, 0.6)
        var ripples = Path()
        for (k, dy) in [0.035, 0.08].enumerated() {
            ripples.addPath(pen.path { p in
                p.move(to: CGPoint(x: x0, y: y + dy))
                for x in Swift.stride(from: x0, through: x1, by: 0.01) {
                    p.addLine(to: CGPoint(x: x, y: y + dy - 0.004 * sin(x * (40 + 13 * Double(k)))))
                }
            })
        }
        pen.lit(glows ?? [(0.02, 0.3), (0.007, 0.8)]) { g in
            g.stroke(g.seg(x0, y, x1, y), sea, 0.9)
            g.stroke(ripples, sea, 0.35)
        }
    }
}

extension Level {
    /// The Flood's scenes in story order, numbered by place in `firstStir`.
    static let flood: [Level] = Flood.allCases.map { scene in
        Level(id: "", pack: .firstStir, label: "", title: scene.title, note: "", layout: scene.layout,
              scramble: .parse(scene.scramble, in: scene.layout), story: .flood(scene))
    }
}

extension Cast {
    /// A figure kneeling on (0, 0), facing right, its far arm reaching down and forward to the ground: drawn as the
    /// standing figure sunk by its shins: one knee down with the shin back along the ground, the other foot planted.
    static func kneeling(_ pen: Brush, _ who: Who, arms: [Limb], colour: Color = Flood.ink) {
        figure(pen.at(0, 0.15), who, arms: arms,
               legs: [[(0.05, -0.3), (0.18, -0.3), (0.18, -0.15)], [(-0.05, -0.3), (0.04, -0.15), (-0.22, -0.15)]],
               colour: colour)
    }
}

/// Scene 11, 2:30 back to 2:05, on eye: the breakwater curving out from the quay end on the left, round to the dark
/// lighthouse on its end, the rope line along it on posts, the sea over it. Rod 0, the quay end: the rope tied off on its
/// ring and running out, then the father kneeling there tying it. Rod 1, the path: the father halfway out, crouched
/// against a wave breaking over him, then the path bare between waves. Rod 2, the lantern: the hand-lamp in the gallery
/// window, then dark.
enum BreakwaterPath {
    static let horizon = -0.3
    /// The quay's top, and the ring on its face.
    static let quay = 0.12
    static let ring = (x: -0.5, y: 0.165)
    /// The breakwater's line: from the quay end round to the lighthouse's foot.
    static let a = (x: -0.28, y: 0.12), c = (x: 0.8, y: 0.06), b = (x: 0.16, y: -0.29)
    static func arm(_ t: Double) -> (x: Double, y: Double) {
        let u = 1 - t
        return (u * u * a.x + 2 * u * t * c.x + t * t * b.x, u * u * a.y + 2 * u * t * c.y + t * t * b.y)
    }
    /// The path's depth, seen from the quay, and its wall's height above the sea, shrinking with the distance.
    static func depth(_ t: Double) -> Double { 0.04 * (1 - t) + 0.01 * t }
    static func wall(_ t: Double) -> Double { 0.07 * (1 - t) + 0.02 * t }
    /// Where the father crouches, halfway out.
    static let halfway = 0.29
    static let axis = 0.16

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Flood.ink
        Flood.clouds(pen, [(-1, -0.4, -0.78, 0.05), (0.3, 1, -0.84, 0.05), (-0.55, -0.05, -0.95, 0.04)])

        // The breakwater: its path's far edge, its near edge and the wall down to the sea, black inside.
        let ts = Array(Swift.stride(from: 0.0, through: 1.0, by: 0.02))
        let far = ts.map { (arm($0).x, arm($0).y - depth($0)) }, near = ts.map { (arm($0).x, arm($0).y) }
        let foot = ts.map { (arm($0).x, arm($0).y + wall($0)) }
        pen.fill(pen.poly(far + foot.reversed()), .black)
        var stone = Path()
        stone.addPath(pen.poly(far, closed: false))
        stone.addPath(pen.poly(near, closed: false))
        stone.addPath(pen.poly(foot, closed: false))
        for t in Swift.stride(from: 0.06, through: 0.9, by: 0.08) {
            let p = arm(t)
            stone.addPath(pen.seg(p.x, p.y, p.x, p.y + wall(t)))
        }
        // The rope line on its posts, along the path's harbour edge.
        var rope = Path(), posts = Path()
        rope.addPath(pen.poly([(ring.x, ring.y)] + ts.map { t in (arm(t).x, arm(t).y - 0.025 - 0.05 * depth(t)) }, closed: false))
        for t in Swift.stride(from: 0.08, through: 0.95, by: 0.12) {
            let p = arm(t)
            posts.addPath(pen.seg(p.x, p.y, p.x, p.y - 0.03 - 0.06 * depth(t)))
        }

        // The quay end in the foreground on the left: its top, its face of stone courses, the ring on it.
        let block = pen.poly([(-1, quay), (a.x, quay), (a.x, 0.34), (-1, 0.34)])
        pen.fill(block, .black)
        var quayside = Path()
        quayside.addPath(pen.poly([(-1, quay), (a.x, quay), (a.x, 0.34)], closed: false))
        for (i, y) in [0.19, 0.26].enumerated() {
            quayside.addPath(pen.seg(-1, y, a.x, y))
            for x in Swift.stride(from: -0.96 + 0.06 * Double(i), to: a.x - 0.02, by: 0.13) {
                quayside.addPath(pen.seg(x, y, x, y + 0.07))
            }
        }
        quayside.addPath(pen.seg(-1, quay + 0.02, a.x, quay + 0.02))
        quayside.addPath(pen.circle(ring.x, ring.y, 0.016))
        quayside.addPath(pen.seg(ring.x, quay + 0.02, ring.x, ring.y - 0.016))

        // The lighthouse on the end, dark.
        let tower = pen.poly([(axis - 0.042, -0.285), (axis - 0.026, -0.6), (axis + 0.026, -0.6), (axis + 0.042, -0.285)])
        let room = pen.rect(axis - 0.03, -0.69, axis + 0.03, -0.6)
        pen.fill(tower, .black)
        pen.fill(room, .black)
        var house = Path()
        house.addPath(tower)
        house.addPath(room)
        house.addPath(pen.seg(axis - 0.045, -0.6, axis + 0.045, -0.6))
        house.addPath(pen.curve(axis - 0.034, -0.69, axis, -0.735, axis + 0.034, -0.69))
        house.addPath(pen.seg(axis, -0.725, axis, -0.75))
        house.addPath(pen.rect(axis - 0.012, -0.36, axis + 0.012, -0.3))
        house.addPath(pen.rect(axis - 0.009, -0.5, axis + 0.009, -0.47))

        pen.lit { g in
            g.stroke(stone, ink, 0.85)
            g.stroke(quayside, ink)
            g.stroke(house, ink)
            g.stroke(posts, ink, 0.8)
            g.stroke(rope, Flood.sodium, 0.6)
        }
        // The sea breaking over the far arm and along the quay's foot, and in the foreground, rod 3's core.
        for (x, y, k) in [(0.62, -0.2, 0.14), (0.66, 0.2, 0.16), (-0.7, 0.4, 0.18), (0.05, 0.5, 0.22), (0.3, 0.74, 0.24),
                          (-0.38, 0.72, 0.22), (0.72, 0.52, 0.2)] {
            Cast.breaker(pen.at(x, y, k: k), colour: Flood.sea)
        }

        // Vignette 0, the quay end.
        pen.vignette(0) { pen in
            if played.contains(0) {
                Cast.kneeling(pen.at(-0.6, quay, k: 0.15), .father,
                              arms: [[(0.1, -0.74), (0.3, -0.5), (0.62, -0.32)], [(-0.1, -0.74), (0.12, -0.52), (0.5, -0.38)]])
                // The rest of the coil on the stones in front of him.
                pen.stroke(pen.ellipse(-0.47, quay - 0.012, 0.03, 0.011), Flood.sodium, 0.8)
                pen.stroke(pen.ellipse(-0.47, quay - 0.016, 0.02, 0.008), Flood.sodium, 0.8)
            } else {
                // The hitch on the ring and its tail hanging down the face.
                pen.stroke(pen.ellipse(ring.x + 0.004, ring.y + 0.004, 0.012, 0.02), Flood.sodium, 0.8)
                pen.stroke(pen.curve(ring.x - 0.006, ring.y + 0.02, ring.x - 0.03, ring.y + 0.06, ring.x - 0.015, ring.y + 0.1), Flood.sodium, 0.8)
            }
        }

        // Vignette 1, the path: the father crouched into a wave coming over the far edge at him.
        pen.vignette(1) { pen in
            if !played.contains(1) {
                let p = arm(halfway)
                Cast.figure(pen.at(p.x + 0.02, p.y - depth(halfway) / 2, k: 0.13, turn: 0.28), .father,
                            arms: [[(0.1, -0.74), (0.2, -0.56), (0.24, -0.4)], [(-0.1, -0.74), (-0.22, -0.6), (-0.3, -0.62)]],
                            legs: [[(-0.05, -0.3), (-0.14, -0.14), (-0.1, 0)], [(0.05, -0.3), (0.16, -0.16), (0.14, 0)]],
                            colour: ink)
                Cast.breaker(pen.at(p.x - 0.035, p.y - depth(halfway), k: 0.1, flip: true), glows: Rescue.tight, colour: Flood.sea)
                for (x, y) in [(p.x - 0.07, p.y - 0.1), (p.x - 0.03, p.y - 0.12), (p.x - 0.1, p.y - 0.07)] {
                    pen.stroke(pen.seg(x, y, x + 0.03, y - 0.02), Flood.sea, 0.8)
                }
            }
        }

        // Vignette 2, the gallery window.
        pen.vignette(2) { pen in
            let pane = pen.rect(axis - 0.018, -0.68, axis + 0.018, -0.61)
            if played.contains(2) {
                pen.stroke(pen.seg(axis - 0.018, -0.645, axis + 0.018, -0.645), ink, 0.6)
            } else {
                pen.fill(pane, Flood.sodium, 0.25)
                Rescue.handLamp(pen, x: axis, y: -0.612, glass: Flood.sodium)
            }
        }
    }
}

/// Scene 12, 2:05 back to 1:40, on pent: the high street from across the water, its shopfronts flooded to the sills, the
/// town hall's clock over them, a street lamp half drowned in the foreground. The flood is the scene's sea, so it fades
/// away from the fronts. Rod 0, the town clock: its hands at 2:05, then at 1:40. Rod 2, the street lamp: drowned to its
/// crossbar and dark, then the water at its foot and the lamp still lit, sparking. Rod 3, the dinghy: the father and a
/// neighbour rowing it down the street, a coil of rope aboard, then tied to a drainpipe, empty.
enum HighStreet {
    /// The water's line along the fronts.
    static let water = 0.28
    static let clock = (x: 0.15, y: -0.62, r: 0.062)
    static let drain = -0.43
    static let lamp = 0.2

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Flood.ink
        Flood.clouds(pen, [(-1, -0.4, -0.86, 0.05), (0.35, 1, -0.82, 0.05)])

        // The fronts: gables and parapets down to the water, black inside.
        let fronts: [(x0: Double, x1: Double, top: [(Double, Double)])] = [
            (-1, -0.62, [(-1, -0.42), (-0.81, -0.58), (-0.62, -0.42)]),
            (-0.62, -0.22, [(-0.62, -0.48), (-0.22, -0.48)]),
            (-0.22, 0.32, [(-0.22, -0.42), (0.32, -0.42)]),
            (0.32, 0.64, [(0.32, -0.32), (0.48, -0.46), (0.64, -0.32)]),
            (0.64, 1, [(0.64, -0.4), (1, -0.4)]),
        ]
        var lines = Path()
        for f in fronts {
            let outline = pen.poly([(f.x0, water)] + f.top + [(f.x1, water)])
            pen.fill(outline, .black)
            lines.addPath(pen.poly([(f.x0, water)] + f.top + [(f.x1, water)], closed: false))
        }
        // The clock tower over the town hall, its pyramid roof and face.
        let tower = pen.poly([(0.07, -0.42), (0.07, -0.7), (0.23, -0.7), (0.23, -0.42)])
        let cap = pen.poly([(0.05, -0.7), (0.15, -0.82), (0.25, -0.7)])
        pen.fill(tower, .black)
        pen.fill(cap, .black)
        lines.addPath(tower)
        lines.addPath(cap)
        lines.addPath(pen.seg(0.15, -0.82, 0.15, -0.86))
        lines.addPath(pen.circle(clock.x, clock.y, clock.r))
        var ticks = Path()
        for h in 0..<12 {
            let a = Double(h) * .pi / 6, long = h % 3 == 0 ? 0.016 : 0.009
            ticks.addPath(pen.seg(clock.x + (clock.r - 0.008) * sin(a), clock.y - (clock.r - 0.008) * cos(a),
                                  clock.x + (clock.r - 0.008 - long) * sin(a), clock.y - (clock.r - 0.008 - long) * cos(a)))
        }
        // Windows above the water, sills just clear of it; doors drowned but for their heads; the town hall's steps
        // gone under.
        var windows = Path()
        for x in [-0.92, -0.76, -0.52, -0.38, -0.12, 0.38, 0.52, 0.72, 0.86] {
            windows.addPath(pen.rect(x - 0.035, -0.3, x + 0.035, -0.18))
            windows.addPath(pen.rect(x - 0.035, 0.08, x + 0.035, 0.22))
            windows.addPath(pen.seg(x - 0.045, 0.235, x + 0.045, 0.235))
        }
        for x in [-0.84, -0.3, 0.1, 0.45, 0.8] {
            windows.addPath(pen.poly([(x - 0.04, water), (x - 0.04, 0.2), (x + 0.04, 0.2), (x + 0.04, water)], closed: false))
        }
        windows.addPath(pen.rect(-0.12, -0.38, 0.0, -0.33))
        // Hanging signs, shapes for words: a fish, a loaf, a cup.
        var signs = Path()
        for (x, y) in [(-0.62, -0.1), (0.32, -0.12), (0.64, -0.08)] {
            signs.addPath(pen.seg(x, y - 0.05, x + 0.07, y - 0.05))
            signs.addPath(pen.seg(x + 0.06, y - 0.05, x + 0.06, y - 0.03))
        }
        signs.addPath(pen.path { f in
            f.move(to: CGPoint(x: -0.6, y: -0.01)); f.addQuadCurve(to: CGPoint(x: -0.535, y: -0.01), control: CGPoint(x: -0.565, y: -0.05))
            f.addQuadCurve(to: CGPoint(x: -0.6, y: -0.01), control: CGPoint(x: -0.565, y: 0.03))
            f.move(to: CGPoint(x: -0.535, y: -0.01)); f.addLine(to: CGPoint(x: -0.52, y: -0.03)); f.addLine(to: CGPoint(x: -0.52, y: 0.01))
            f.closeSubpath()
        })
        signs.addPath(pen.path { l in
            l.move(to: CGPoint(x: 0.35, y: -0.03)); l.addQuadCurve(to: CGPoint(x: 0.41, y: -0.03), control: CGPoint(x: 0.38, y: -0.1))
            l.closeSubpath()
        })
        signs.addPath(pen.poly([(0.675, -0.02), (0.68, 0.02), (0.705, 0.02), (0.71, -0.02)]))
        signs.addPath(pen.curve(0.71, -0.012, 0.725, -0.005, 0.708, 0.008))
        // The drainpipe down the fish shop's front, and a lamp further down the street drowned to its head.
        var pipe = Path()
        pipe.addPath(pen.seg(drain, -0.48, drain, water))
        pipe.addPath(pen.seg(drain + 0.015, -0.48, drain + 0.015, water))
        pipe.addPath(pen.rect(drain - 0.01, -0.49, drain + 0.025, -0.46))
        var far = Path()
        far.addPath(pen.seg(0.92, 0.36, 0.92, 0.3))
        far.addPath(pen.rect(0.905, 0.27, 0.935, 0.3))
        far.addPath(pen.ellipse(0.92, 0.36, 0.03, 0.008))
        pen.lit { g in
            g.stroke(lines, ink)
            g.stroke(windows, ink, 0.75)
            g.stroke(ticks, ink)
            g.stroke(signs, ink, 0.9)
            g.stroke(pipe, ink, 0.8)
            g.stroke(far, ink, 0.8)
        }
        Flood.water(pen, water, glows: nil)

        // Vignette 0, the town clock's hands.
        pen.vignette(0) { pen in
            let (hour, minute) = played.contains(0) ? (1.0, 40.0) : (2.0, 5.0)
            let h = (hour + minute / 60) * .pi / 6, m = minute * .pi / 30
            pen.stroke(pen.seg(clock.x, clock.y, clock.x + 0.03 * sin(h), clock.y - 0.03 * cos(h)), ink)
            pen.stroke(pen.seg(clock.x, clock.y, clock.x + 0.048 * sin(m), clock.y - 0.048 * cos(m)), ink)
        }

        // Vignette 2, the street lamp.
        pen.vignette(2) { pen in
            let lit = played.contains(2), surface = lit ? 0.6 : 0.43
            var post = Path()
            post.addPath(pen.seg(lamp, surface, lamp, 0.34))
            post.addPath(pen.seg(lamp - 0.035, 0.42, lamp + 0.035, 0.42))
            let head = pen.poly([(lamp - 0.018, 0.34), (lamp - 0.024, 0.3), (lamp + 0.024, 0.3), (lamp + 0.018, 0.34)])
            post.addPath(head)
            post.addPath(pen.seg(lamp - 0.03, 0.3, lamp + 0.03, 0.3))
            post.addPath(pen.ellipse(lamp, surface, 0.03, 0.008))
            if lit {
                pen.glow(lamp, 0.32, 0.06, Flood.sodium, 0.5)
                pen.fill(head, Flood.flame, 0.9)
                for a in [-2.4, -1.6, -0.8] {
                    pen.stroke(pen.seg(lamp - 0.034 + 0.01 * cos(a), 0.35 + 0.01 * sin(a), lamp - 0.034 + 0.026 * cos(a), 0.35 + 0.026 * sin(a)),
                               Flood.sodium)
                }
            } else {
                pen.fill(head, .black)
            }
            pen.lit { g in
                g.stroke(post, ink)
                if lit { g.stroke(head, Flood.sodium) }
            }
        }

        // Vignette 3, the dinghy.
        pen.vignette(3) { pen in
            if played.contains(3) {
                HighStreet.dinghy(pen.at(-0.29, water + 0.035, k: 0.15), crew: false)
                pen.stroke(pen.curve(-0.36, water + 0.012, -0.4, water + 0.01, drain + 0.008, water - 0.005), Flood.sodium, 0.8)
            } else {
                HighStreet.dinghy(pen.at(-0.33, 0.645, k: 0.14, flip: true), crew: true)
            }
        }
    }

    /// A rowing dinghy afloat on y = 0, 1 long, bow right: rowed by the father aft and a neighbour forward, a coil of rope
    /// in the bow, when `crew`.
    static func dinghy(_ pen: Brush, crew: Bool) {
        let hull = pen.path { h in
            h.move(to: CGPoint(x: -0.5, y: -0.16))
            h.addLine(to: CGPoint(x: 0.5, y: -0.2))
            h.addQuadCurve(to: CGPoint(x: -0.4, y: 0.02), control: CGPoint(x: 0.3, y: 0.06))
            h.closeSubpath()
        }
        if crew {
            let seat = pen.clipped(to: pen.rect(-1, -2, 1, -0.17))
            Cast.figure(seat.at(-0.18, 0.14, k: 0.75), .father,
                        arms: [[(0.1, -0.74), (0.3, -0.56), (0.42, -0.5)]], colour: Flood.ink)
            Cast.figure(seat.at(0.2, 0.14, k: 0.72), .neighbour,
                        arms: [[(0.1, -0.74), (0.3, -0.56), (0.42, -0.5)]], colour: Flood.ink)
        }
        pen.fill(hull, .black)
        var lines = Path()
        lines.addPath(hull)
        if crew {
            for x in [-0.12, 0.27] { lines.addPath(pen.seg(x + 0.06, -0.24, x - 0.12, 0.1)) }
            lines.addPath(pen.ellipse(0.38, -0.21, 0.07, 0.025))
        }
        pen.lit(Rescue.tight) { g in
            g.stroke(hull, Flood.ink)
            if crew {
                for x in [-0.12, 0.27] { g.stroke(g.seg(x + 0.06, -0.24, x - 0.12, 0.1), Flood.ink) }
                g.stroke(g.ellipse(0.38, -0.21, 0.07, 0.025), Flood.sodium)
            }
        }
    }
}
enum UpstairsWindow { static func draw(_ pen: Brush, played: Set<Int>) {} }
enum Kitchen {
    static func windows(_ pen: Brush) -> Path { pen.rect(0.4, -0.6, 0.6, -0.4) }
    static func sky(_ pen: Brush, minutes: Double) { pen.fill(pen.rect(-1, -1, 1, 1), .black) }
    static func draw(_ pen: Brush, played: Set<Int>) {}
}
enum OverTheQuay { static func draw(_ pen: Brush, played: Set<Int>) {} }
