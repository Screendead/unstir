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
    /// low down, taking a little of the ink as the night winds back; turned from the Rescue's at 2:30. Only the flood's
    /// palette: the storm's indigo is chapter 4's to turn to, from this sky, as this chapter turns from the Rescue's.
    static func skyTones(_ minutes: Double) -> [Tone] {
        let night = Tone(0x05050F), low = Tone(0x0B2238).mix(Tone(0x8F9CFF).scaled(0.22), 0.5 * back(minutes))
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

    var horizon: Double { [BreakwaterPath.horizon, HighStreet.water, UpstairsWindow.water, Kitchen.water, OverTheQuay.horizon][rawValue - 11] }

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
/// lighthouse on its end, posts along it, the sea over it. Rod 0, the quay end: the rope tied off on its ring and running
/// out along the path, then the father kneeling there tying it. Rod 1, the path: the father halfway out with the coil on
/// his shoulder, paying the rope out behind him, crouched against a wave breaking over him (scene 10's played beat, at
/// the same 2:30), then the path bare between waves. The rope exists only in the two vignettes; between the cores, a
/// wave over the path stands where it would cross in both states. Rod 2, the lantern: the hand-lamp in the gallery
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
    /// The rope along the path's harbour edge, at t along it.
    static func rope(_ t: Double) -> (Double, Double) { (arm(t).x, arm(t).y - 0.025 - 0.05 * depth(t)) }
    /// How far out the quay end's rope reaches before the path's disc (rod 1's), and where the path's takes it up, clear
    /// of the quay end's core.
    static let ropeOut = 0.033, ropeIn = 0.205

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Flood.ink
        Flood.clouds(pen, [(-1, -0.4, -0.78, 0.05), (0.32, 0.72, -0.82, 0.05), (-0.55, -0.05, -0.95, 0.04)])

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
        // Posts along the path's harbour edge.
        var posts = Path()
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
        }
        // The sea breaking over the far arm and along the quay's foot, and in the foreground, rod 3's core.
        for (x, y, k) in [(0.62, -0.2, 0.14), (0.66, 0.2, 0.16), (-0.7, 0.4, 0.18), (0.05, 0.5, 0.22), (0.3, 0.74, 0.24),
                          (-0.38, 0.72, 0.22), (0.72, 0.52, 0.2), (-0.05, 0.1, 0.3)] {
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
                // The hitch on the ring and its tail hanging down the face, the rope running out up onto the path.
                pen.stroke(pen.poly([(ring.x, ring.y)] + Swift.stride(from: 0.0, through: ropeOut, by: 0.011).map(rope), closed: false), Flood.sodium, 0.6)
                pen.stroke(pen.ellipse(ring.x + 0.004, ring.y + 0.004, 0.012, 0.02), Flood.sodium, 0.8)
                pen.stroke(pen.curve(ring.x - 0.006, ring.y + 0.02, ring.x - 0.03, ring.y + 0.06, ring.x - 0.015, ring.y + 0.1), Flood.sodium, 0.8)
            }
        }

        // Vignette 1, the path: the father crouched into a wave coming over the far edge at him.
        pen.vignette(1) { pen in
            if !played.contains(1) {
                let p = arm(halfway)
                // The rope paid out behind him from the coil, back towards the quay.
                pen.stroke(pen.poly(Swift.stride(from: ropeIn, through: halfway, by: 0.01).map(rope), closed: false), Flood.sodium, 0.6)
                let him = pen.at(p.x + 0.02, p.y - depth(halfway) / 2, k: 0.13, turn: 0.28)
                Cast.figure(him, .father,
                            arms: [[(0.1, -0.74), (0.2, -0.56), (0.24, -0.4)], [(-0.1, -0.74), (-0.22, -0.6), (-0.3, -0.62)]],
                            legs: [[(-0.05, -0.3), (-0.14, -0.14), (-0.1, 0)], [(0.05, -0.3), (0.16, -0.16), (0.14, 0)]],
                            colour: ink)
                him.stroke(him.ellipse(-0.12, -0.7, 0.15, 0.11), Flood.sodium)
                him.stroke(him.ellipse(-0.12, -0.7, 0.09, 0.065), Flood.sodium)
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
            // A short hour hand against a long minute hand, and the hub between: at 1:40 the two lie nearly in one line.
            pen.stroke(pen.seg(clock.x, clock.y, clock.x + 0.022 * sin(h), clock.y - 0.022 * cos(h)), ink)
            pen.stroke(pen.seg(clock.x, clock.y, clock.x + 0.052 * sin(m), clock.y - 0.052 * cos(m)), ink)
            pen.fill(pen.circle(clock.x, clock.y, 0.008), .black)
            pen.stroke(pen.circle(clock.x, clock.y, 0.008), ink)
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
                // Afloat at the fronts' foot, its own waterline on theirs, its painter made fast round the drainpipe.
                HighStreet.dinghy(pen.at(-0.3, water, k: 0.13), crew: false)
                pen.stroke(pen.curve(-0.36, water - 0.022, -0.4, water - 0.026, drain + 0.008, water - 0.006), Flood.sodium, 0.8)
            } else {
                // Close in under the knob and large, so the two hats tell father from neighbour.
                HighStreet.dinghy(pen.at(-0.345, 0.66, k: 0.22, flip: true), crew: true)
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
            Cast.figure(seat.at(-0.26, 0.17, k: 0.66), .father,
                        arms: [[(0.1, -0.74), (0.2, -0.6), (0.26, -0.5)]], colour: Flood.ink)
            Cast.figure(seat.at(0.2, 0.17, k: 0.64), .neighbour,
                        arms: [[(0.1, -0.74), (0.2, -0.6), (0.26, -0.5)]], colour: Flood.ink)
        }
        pen.fill(hull, .black)
        var lines = Path()
        lines.addPath(hull)
        if crew {
            for x in [-0.13, 0.32] { lines.addPath(pen.seg(x + 0.06, -0.24, x - 0.08, 0.03)) }
            lines.addPath(pen.ellipse(0.43, -0.2, 0.05, 0.02))
        }
        pen.lit(Rescue.tight) { g in
            g.stroke(hull, Flood.ink)
            if crew {
                for x in [-0.13, 0.32] { g.stroke(g.seg(x + 0.06, -0.24, x - 0.08, 0.03), Flood.ink) }
                g.stroke(g.ellipse(0.43, -0.2, 0.05, 0.02), Flood.sodium)
            }
        }
    }
}
/// Scene 13, 1:40 back to 1:15, on quad: the cottage from across the flooded street, the water up its front to the
/// door's knocker, the child at the window above. Rod 3, the window: the child and the dog at it, the torch shining
/// out, then dark, a curtain blowing in. Rod 0, the roof: the weathervane bent, pointing down, then upright and
/// spinning. Rod 1, the door: open, the water at its knocker and the float drifting out, then the water down at the
/// step and the float on the threshold.
enum UpstairsWindow {
    static let water = 0.28
    static let eaves = -0.33, ridge = -0.5
    /// The child's window: as tall as the others, wider, so the child shows head and shoulders above its sill.
    static let window = (x0: -0.44, y0: -0.255, x1: -0.27, y1: -0.12)
    /// Its glazing bar: below it the pane is dark in both states, since rod 2's disc reaches up to the sill.
    static let bar = -0.15
    static let door = (x0: 0.47, y0: 0.2, x1: 0.57, y1: 0.38)
    static let vane = 0.4

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Flood.ink
        Flood.clouds(pen, [(-1, -0.45, -0.78, 0.05), (0.55, 1, -0.7, 0.04), (-0.3, 0.3, -0.92, 0.04)])

        // The neighbours' gables either side, behind.
        let left = pen.poly([(-1, water), (-1, -0.2), (-0.86, -0.36), (-0.72, -0.2), (-0.72, water)])
        let right = pen.poly([(0.74, water), (0.74, -0.24), (0.88, -0.4), (1, -0.28), (1, water)])
        pen.fill(left, .black); pen.fill(right, .black)
        var behind = Path()
        behind.addPath(left); behind.addPath(right)
        for (x, y) in [(-0.86, -0.12), (-0.86, 0.08), (0.87, -0.14), (0.87, 0.06)] { behind.addPath(pen.rect(x - 0.03, y, x + 0.03, y + 0.1)) }

        // The cottage: its roof, the chimney on the left gable, the front down into the water.
        let front = pen.poly([(-0.72, water), (-0.72, eaves), (0.74, eaves), (0.74, water)])
        let roof = pen.poly([(-0.76, eaves), (-0.56, ridge), (0.58, ridge), (0.78, eaves)])
        let chimney = pen.poly([(-0.62, -0.42), (-0.62, -0.6), (-0.52, -0.6), (-0.52, ridge)])
        for p in [front, roof, chimney] { pen.fill(p, .black) }
        var house = Path()
        house.addPath(front)
        house.addPath(roof)
        house.addPath(chimney)
        house.addPath(pen.seg(-0.64, -0.6, -0.5, -0.6))
        // Slates in rows along the roof.
        var slates = Path()
        for y in [-0.45, -0.4, -0.36] {
            let inset = (y - eaves) / (ridge - eaves) * 0.2
            slates.addPath(pen.seg(-0.76 + inset, y, 0.78 - inset, y))
        }
        // The upstairs windows, the one on the left the child's; downstairs a window drowned to its sill.
        house.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
        house.addPath(pen.seg(window.x0 - 0.012, window.y1 + 0.012, window.x1 + 0.012, window.y1 + 0.012))
        house.addPath(pen.seg(window.x0, bar, window.x1, bar))
        for x in [0.0, 0.3] {
            house.addPath(pen.rect(x - 0.06, -0.255, x + 0.06, -0.12))
            house.addPath(pen.seg(x, -0.255, x, -0.12))
        }
        house.addPath(pen.rect(-0.52, 0.05, -0.36, 0.25))
        house.addPath(pen.seg(-0.44, 0.05, -0.44, 0.25))
        house.addPath(pen.rect(0.05, 0.05, 0.21, 0.25))
        house.addPath(pen.seg(0.13, 0.05, 0.13, 0.25))
        // The door's frame and porch hood, on posts down into the water.
        house.addPath(pen.poly([(door.x0 - 0.03, door.y0 - 0.02), ((door.x0 + door.x1) / 2, door.y0 - 0.06), (door.x1 + 0.03, door.y0 - 0.02)]))
        house.addPath(pen.seg(door.x0 - 0.02, door.y0 - 0.02, door.x0 - 0.02, water))
        house.addPath(pen.seg(door.x1 + 0.02, door.y0 - 0.02, door.x1 + 0.02, water))
        house.addPath(pen.poly([(door.x0, water), (door.x0, door.y0), (door.x1, door.y0), (door.x1, water)], closed: false))
        // The weathervane's pole on the ridge.
        house.addPath(pen.seg(vane, ridge, vane, ridge - 0.025))

        // Railings and a gate's top out of the water in the foreground, in rod 2's core.
        var rails = Path()
        rails.addPath(pen.seg(-1, 0.5, 0.0, 0.5))
        for x in Swift.stride(from: -0.96, through: -0.02, by: 0.06) {
            rails.addPath(pen.poly([(x, 0.56), (x, 0.47), (x + 0.008, 0.455), (x + 0.016, 0.47)], closed: false))
        }
        pen.lit { g in
            g.stroke(behind, ink, 0.6)
            g.stroke(house, ink)
            g.stroke(slates, ink, 0.4)
        }
        Flood.water(pen, water)
        pen.lit { g in g.stroke(rails, ink, 0.8) }

        // Vignette 3, the window.
        pen.vignette(3) { pen in
            let inside = pen.clipped(to: pen.rect(window.x0 + 0.004, window.y0 + 0.004, window.x1 - 0.004, bar - 0.004))
            if played.contains(3) {
                // The curtain blown in off the sill, one corner caught up.
                inside.stroke(inside.path { c in
                    c.move(to: CGPoint(x: window.x0 + 0.01, y: window.y0 + 0.005))
                    c.addQuadCurve(to: CGPoint(x: window.x1 - 0.015, y: bar - 0.01), control: CGPoint(x: window.x0 + 0.02, y: bar))
                    c.addQuadCurve(to: CGPoint(x: window.x0 + 0.05, y: window.y0 + 0.005), control: CGPoint(x: window.x1 - 0.02, y: window.y0 + 0.06))
                }, ink, 0.8)
            } else {
                inside.fill(inside.rect(window.x0, window.y0, window.x1, bar), Flood.torch, 0.12)
                // The child from the waist up, head and hat clear of the frame, the dog's head and ears at the sill.
                Cast.figure(inside.at(-0.35, bar + 0.07, k: 0.16), .child,
                            arms: [[(0.1, -0.62), (0.3, -0.66), (0.44, -0.72)], [(-0.1, -0.62), (-0.14, -0.42)]], colour: ink)
                Cast.dog(inside.at(-0.43, bar + 0.04, k: 0.09), colour: ink)
                // The torch held up to the glass, its beam out into the rain.
                let torch = (x: window.x1 - 0.008, y: -0.185)
                pen.fill(pen.poly([(torch.x, torch.y - 0.004), (torch.x + 0.06, torch.y - 0.03), (torch.x + 0.06, torch.y + 0.015), (torch.x, torch.y + 0.004)]),
                         Flood.torch, 0.25)
                pen.fill(pen.circle(torch.x, torch.y, 0.006), Flood.torch)
            }
        }

        // Vignette 0, the weathervane.
        pen.vignette(0) { pen in
            var vanes = Path()
            if played.contains(0) {
                let top = ridge - 0.055
                vanes.addPath(pen.seg(vane, ridge - 0.025, vane, top - 0.01))
                vanes.addPath(pen.seg(vane - 0.04, top, vane + 0.04, top))
                vanes.addPath(pen.poly([(vane + 0.04, top), (vane + 0.025, top - 0.012), (vane + 0.025, top + 0.012)]))
                vanes.addPath(pen.poly([(vane - 0.04, top), (vane - 0.05, top - 0.014), (vane - 0.03, top)], closed: false))
                // Spinning.
                vanes.addPath(pen.path { a in a.addArc(center: CGPoint(x: vane, y: top), radius: 0.046, startAngle: .degrees(200), endAngle: .degrees(250), clockwise: false) })
                vanes.addPath(pen.path { a in a.addArc(center: CGPoint(x: vane, y: top), radius: 0.046, startAngle: .degrees(20), endAngle: .degrees(70), clockwise: false) })
            } else {
                // Bent over at the pole's head, hanging pointing down the roof.
                let kink = (x: vane, y: ridge - 0.04), tip = (x: vane + 0.03, y: ridge + 0.03)
                vanes.addPath(pen.poly([(vane, ridge - 0.025), (kink.x, kink.y), (kink.x + 0.02, kink.y + 0.005)], closed: false))
                vanes.addPath(pen.seg(kink.x + 0.02, kink.y + 0.005, tip.x, tip.y))
                vanes.addPath(pen.poly([(tip.x, tip.y), (tip.x - 0.012, tip.y - 0.016), (tip.x + 0.01, tip.y - 0.012)]))
            }
            pen.lit(Rescue.tight) { $0.stroke(vanes, ink) }
        }

        // Vignette 1, the door.
        pen.vignette(1) { pen in
            if played.contains(1) {
                // The water down at the step: the porch dry between its posts, the door's foot and step clear of it.
                let bay = pen.rect(door.x0 - 0.014, water - 0.004, door.x1 + 0.014, door.y1 + 0.03)
                pen.fill(bay, .black)
                var dry = Path()
                dry.addPath(pen.seg(door.x0, water - 0.004, door.x0, door.y1))
                dry.addPath(pen.seg(door.x1, water - 0.004, door.x1, door.y1))
                dry.addPath(pen.rect(door.x0 - 0.01, door.y1, door.x1 + 0.01, door.y1 + 0.015))
                dry.addPath(pen.seg(door.x0 - 0.016, door.y1 + 0.03, door.x1 + 0.016, door.y1 + 0.03))
                pen.lit(Rescue.tight) { g in
                    g.stroke(dry, ink)
                    g.stroke(g.seg(door.x0 - 0.016, door.y1 + 0.03, door.x1 + 0.016, door.y1 + 0.03), Flood.sea, 0.9)
                }
                UpstairsWindow.float(pen, door.x0 + 0.05, door.y1 - 0.016)
            } else {
                // The door swung open on the dark hall, its knocker just over the water, the float riding out.
                pen.fill(pen.poly([(door.x0, door.y0), (door.x0 + 0.03, door.y0 + 0.02), (door.x0 + 0.03, water), (door.x0, water)]), .black)
                pen.stroke(pen.poly([(door.x0, door.y0), (door.x0 + 0.03, door.y0 + 0.02), (door.x0 + 0.03, water)], closed: false), ink)
                pen.stroke(pen.circle(door.x0 + 0.016, water - 0.016, 0.007), ink)
                UpstairsWindow.float(pen, door.x0 + 0.07, water + 0.012)
            }
        }
    }

    /// The green glass float, its net over it, at (x, y).
    static func float(_ pen: Brush, _ x: Double, _ y: Double, radius: Double = 0.017) {
        let ball = pen.circle(x, y, radius)
        var net = Path()
        net.addPath(pen.seg(x - radius, y, x + radius, y))
        net.addPath(pen.curve(x, y - radius, x - radius * 0.7, y, x, y + radius))
        net.addPath(pen.curve(x, y - radius, x + radius * 0.7, y, x, y + radius))
        pen.fill(ball, Flood.float, 0.3)
        pen.lit(Rescue.tight) { g in
            g.stroke(ball, Flood.float)
            g.stroke(net, Flood.float, 0.6)
        }
    }
}
/// Scene 14, 1:15 back to 12:55, on eye: the kitchen at night under water, the window over the sea at the top, the back
/// door open on the flooded street, the table on the left, the stair climbing the right wall. Rod 0, the table: the
/// water over it and the teacup floating off on its saucer, then the water down at the table's legs and the cup on the
/// table, its spoon in it. Rod 1, the stair: the water up four steps and the child's boots left on a step above it, then
/// the child on the stair carrying the dog up. Rod 3, the float: drifting towards the open door, then caught on a
/// chair's leg.
enum Kitchen {
    /// The water's line on the back wall, and the earlier one across the table's legs.
    static let water = 0.11, low = 0.215
    static let window = (x0: -0.17, y0: -0.66, x1: 0.17, y1: -0.4)
    static let door = (x0: -0.92, y0: -0.3, x1: -0.76, y1: water)
    static let ceiling = -0.8
    /// The table's ends, legs, top and feet: one table in both states, the water falling round it.
    static let ends = (-0.57, -0.23)
    static let legs = [-0.55, -0.49, -0.31, -0.25]
    static let top = 0.14, feet = 0.25
    /// The stair's nosings, from its foot in the water up to the ceiling: y at x.
    static func step(_ x: Double) -> Double { 0.3 - (x - 0.12) * 0.84 }
    static let tread = 0.06
    /// The chair's front legs and back.
    static let chairFront = 0.11, chairBack = 0.22

    /// The window and the open door, where the night shows.
    static func windows(_ pen: Brush) -> Path {
        var p = Path()
        p.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
        p.addPath(pen.rect(door.x0, door.y0, door.x1, door.y1))
        return p
    }

    /// The dark kitchen, and through the openings the sky at `minutes` over the sea.
    static func sky(_ pen: Brush, minutes: Double) {
        pen.fill(pen.rect(-1, -1, 1, 1), Tone(0x0B2238).scaled(0.25).color)
        for (o, horizon) in [((window.x0, window.y0, window.x1, window.y1), -0.47), ((door.x0, door.y0, door.x1, door.y1), -0.05)] {
            pen.fill(pen.rect(o.0, o.1, o.2, horizon), .linearGradient(Gradient(stops: Flood.skyStops(minutes)),
                                                                       startPoint: pen.point(0, o.1 - 0.3), endPoint: pen.point(0, horizon)))
            pen.fill(pen.rect(o.0, horizon, o.2, o.3), .linearGradient(Gradient(colors: [Flood.seaTones(minutes)[0].color, .black]),
                                                                       startPoint: pen.point(0, horizon), endPoint: pen.point(0, o.3 + 0.1)))
        }
    }

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Flood.ink
        // The ceiling and its beams, the window's frame and bars, the door open on its hinges.
        var room = Path()
        room.addPath(pen.seg(-1, ceiling, 1, ceiling))
        for x in [-0.7, -0.35, 0.35, 0.7] { room.addPath(pen.rect(x - 0.03, ceiling, x + 0.03, ceiling + 0.04)) }
        room.addPath(pen.rect(window.x0, window.y0, window.x1, window.y1))
        room.addPath(pen.seg(0, window.y0, 0, window.y1))
        room.addPath(pen.seg(window.x0, -0.53, window.x1, -0.53))
        room.addPath(pen.seg(window.x0 - 0.03, window.y1 + 0.015, window.x1 + 0.03, window.y1 + 0.015))
        room.addPath(pen.poly([(door.x0, water), (door.x0, door.y0), (door.x1, door.y0), (door.x1, water)], closed: false))
        let leaf = pen.poly([(door.x1, door.y0), (door.x1 + 0.07, door.y0 + 0.04), (door.x1 + 0.07, water), (door.x1, water)])
        pen.fill(leaf, .black)
        room.addPath(leaf)
        // The dresser on the back wall, plates standing on its shelves.
        room.addPath(pen.rect(-0.66, -0.5, -0.44, -0.12))
        for y in [-0.38, -0.25] { room.addPath(pen.seg(-0.66, y, -0.44, y)) }
        for x in [-0.62, -0.55, -0.48] {
            room.addPath(pen.circle(x, -0.415, 0.025))
            room.addPath(pen.circle(x, -0.285, 0.025))
        }
        // The stair up the right wall, through the ceiling: its nosings and treads, a rail above.
        var stair = Path()
        var pts: [(Double, Double)] = [(0.12, 0.36), (0.12, step(0.12))]
        var x = 0.12
        while step(x + tread) > ceiling + 0.01 {
            pts.append((x + tread, step(x)))
            pts.append((x + tread, step(x + tread)))
            x += tread
        }
        stair.addPath(pen.poly(pts, closed: false))
        stair.addPath(pen.seg(0.12, step(0.12) + 0.06, x, step(x) + 0.06))
        stair.addPath(pen.curve(0.16, step(0.16) - 0.16, 0.5, step(0.5) - 0.17, x, step(x) - 0.15))
        // The lamp hanging from the beam, lit.
        let lampX = -0.25
        var lamp = Path()
        lamp.addPath(pen.seg(lampX, ceiling + 0.04, lampX, -0.66))
        let shade = pen.poly([(lampX - 0.045, -0.6), (lampX - 0.02, -0.66), (lampX + 0.02, -0.66), (lampX + 0.045, -0.6)])
        lamp.addPath(shade)
        pen.lit { g in
            g.stroke(room, ink, 0.85)
            g.stroke(stair, ink)
            g.stroke(lamp, ink)
        }
        pen.glow(lampX, -0.59, 0.12, Flood.sodium, 0.3)
        pen.fill(pen.ellipse(lampX, -0.598, 0.04, 0.008), Flood.flame)
        // The water over the floor, dimming all under it.
        Flood.water(pen, water)

        // A chair standing in the water in the foreground, side on and facing left, in rod 3's core beside its knob and
        // clear of the stair's foot: its upright the core's "up".
        var chair = Path()
        chair.addPath(pen.seg(chairBack, 0.4, chairBack, 0.68))
        chair.addPath(pen.poly([(chairBack, 0.53), (chairFront, 0.53), (chairFront, 0.68)], closed: false))
        chair.addPath(pen.seg(chairFront, 0.62, chairBack, 0.62))
        chair.addPath(pen.seg(chairBack - 0.016, 0.4, chairBack + 0.012, 0.4))
        pen.lit { $0.stroke(chair, ink) }
        pen.lit([(0.02, 0.3), (0.007, 0.8)]) { g in
            for x in [chairFront, chairBack] { g.stroke(g.ellipse(x, 0.68, 0.025, 0.006), Flood.sea, 0.8) }
        }

        // Vignette 0, the table.
        pen.vignette(0) { pen in
            if played.contains(0) {
                // The water down at the legs: the table standing clear of it, nearer than the back wall's line, the cup
                // on its top with its spoon.
                let (table, slab) = Kitchen.table(pen)
                pen.fill(slab, .black)
                pen.stroke(table, ink)
                pen.stroke(pen.seg(ends.0 - 0.03, low, ends.1 + 0.03, low), Flood.sea, 0.9)
                for x in Kitchen.legs { pen.stroke(pen.ellipse(x, low, 0.014, 0.004), Flood.sea, 0.8) }
                Kitchen.cup(pen, -0.32, top, spoon: true)
            } else {
                // Sunk under the water, dim, the cup floating off it.
                pen.stroke(Kitchen.table(pen).lines, ink, 0.3)
                Kitchen.cup(pen, -0.22, water + 0.004, spoon: false)
                pen.stroke(pen.ellipse(-0.22, water + 0.006, 0.045, 0.008), Flood.sea, 0.6)
            }
        }

        // Vignette 1, the stair.
        pen.vignette(1) { pen in
            if played.contains(1) {
                // Standing on one tread, the leading foot up on the next.
                let x = 0.51, y = step(0.48)
                Cast.figure(pen.at(x, y, k: 0.16), .child,
                            arms: [[(0.1, -0.62), (0.26, -0.5), (0.3, -0.42)], [(-0.1, -0.62), (0.12, -0.48), (0.22, -0.44)]],
                            legs: [[(-0.05, -0.32), (-0.04, 0)], [(0.06, -0.32), (0.2, -0.44), (0.22, -0.32)]], colour: ink)
                Cast.dog(pen.at(x + 0.045, y - 0.045, k: 0.07, turn: -0.3), colour: ink)
            } else {
                // A pair of boots on a step, toes out.
                for dx in [0.0, 0.026] {
                    let bx = 0.6 + dx, by = step(0.6) + 0.0
                    let boot = pen.poly([(bx, by), (bx, by - 0.035), (bx + 0.014, by - 0.035), (bx + 0.014, by - 0.01), (bx + 0.026, by - 0.005), (bx + 0.026, by)])
                    pen.fill(boot, .black)
                    pen.stroke(boot, ink)
                }
            }
        }

        // Vignette 3, the float.
        pen.vignette(3) { pen in
            if played.contains(3) {
                UpstairsWindow.float(pen, chairFront - 0.018, 0.668)
            } else {
                UpstairsWindow.float(pen, -0.15, 0.69)
                // Its wake spreading behind it as it drifts to the door.
                pen.stroke(pen.poly([(-0.075, 0.665), (-0.125, 0.688), (-0.075, 0.715)], closed: false), Flood.sea, 0.6)
                pen.stroke(pen.poly([(-0.02, 0.66), (-0.1, 0.69), (-0.02, 0.725)], closed: false), Flood.sea, 0.35)
            }
        }
    }

    /// The kitchen table, front on: its lines, and its top and apron to fill.
    static func table(_ pen: Brush) -> (lines: Path, slab: Path) {
        var t = Path()
        let slab = pen.rect(ends.0, top, ends.1, top + 0.04)
        t.addPath(pen.rect(ends.0, top, ends.1, top + 0.015))
        t.addPath(pen.poly([(ends.0 + 0.015, top + 0.015), (ends.0 + 0.015, top + 0.04), (ends.1 - 0.015, top + 0.04), (ends.1 - 0.015, top + 0.015)],
                           closed: false))
        for x in legs { t.addPath(pen.seg(x, top + 0.04, x, feet)) }
        return (t, slab)
    }

    /// The teacup on its saucer at (x, y), the saucer's foot on y; the spoon standing in it when `spoon`.
    static func cup(_ pen: Brush, _ x: Double, _ y: Double, spoon: Bool) {
        let saucer = pen.ellipse(x, y - 0.004, 0.032, 0.006)
        let bowl = pen.path { c in
            c.move(to: CGPoint(x: x - 0.02, y: y - 0.036))
            c.addQuadCurve(to: CGPoint(x: x + 0.02, y: y - 0.036), control: CGPoint(x: x, y: y + 0.008))
            c.closeSubpath()
        }
        pen.fill(bowl, .black)
        pen.lit(Rescue.tight) { g in
            g.stroke(saucer, Flood.ink)
            g.stroke(bowl, Flood.ink)
            g.stroke(g.curve(x + 0.02, y - 0.03, x + 0.034, y - 0.026, x + 0.016, y - 0.016), Flood.ink)
            if spoon { g.stroke(g.seg(x + 0.004, y - 0.03, x + 0.016, y - 0.062), Flood.ink) }
        }
    }
}

/// Scene 15, 12:55 back to 12:30, on pent: the quay running out from the near left towards the dark lighthouse, the sea
/// up its side a hand below the top and white over it, bollards awash, the family's boat capsized at its mooring off it.
/// Rod 1, the boat: awash, its hull barely showing, then keel up, high in the water. Rod 3, the dropped lantern: gone,
/// its bail ring on the stones, then lying on its side, its glass out. Rod 4, the wall: a wave breaking white over it,
/// then the sea a hand below its top, slopping.
enum OverTheQuay {
    static let horizon = -0.5
    /// The quay's seaward edge, from the near foot of the picture out towards the horizon: x at height y.
    static func edge(_ y: Double) -> Double { 0.15 - (1 - y) * 0.6127 }
    /// How far below the edge the sea stands on the wall's face, shrinking with the distance.
    static func freeboard(_ y: Double) -> Double { 0.006 + 0.04 * (y - horizon) / (1 - horizon) }
    static let buoy = (x: 0.3, y: 0.12)
    /// Where the boat's line is made fast, the same whichever way up it floats.
    static let bow = (x: 0.44, y: 0.012)

    static func draw(_ pen: Brush, played: Set<Int>) {
        let ink = Flood.ink
        Flood.clouds(pen, [(-1, -0.25, -0.8, 0.05), (0.2, 1, -0.86, 0.05), (-0.35, 0.3, -0.98, 0.04)])

        // The lighthouse far out on the breakwater, dark since its lantern smashed.
        var far = Path()
        far.addPath(pen.seg(-0.2, horizon - 0.005, 0.35, horizon - 0.02))
        far.addPath(pen.poly([(0.08, horizon - 0.015), (0.09, -0.66), (0.13, -0.66), (0.14, horizon - 0.017)], closed: false))
        far.addPath(pen.rect(0.095, -0.7, 0.125, -0.66))
        far.addPath(pen.seg(0.085, -0.66, 0.135, -0.66))
        far.addPath(pen.curve(0.09, -0.7, 0.11, -0.73, 0.13, -0.7))
        pen.fill(pen.poly([(0.08, horizon - 0.015), (0.09, -0.66), (0.13, -0.66), (0.14, horizon - 0.017)]), .black)

        // The quay: its top, black, out from the near left to the horizon; its edge; the wall's face down to the sea.
        let ys = Array(Swift.stride(from: horizon + 0.04, through: 1.05, by: 0.02))
        let top = pen.poly([(-1, horizon + 0.04)] + ys.map { (edge($0), $0) } + [(-1, 1.05)])
        let face = pen.poly(ys.map { (edge($0), $0) } + ys.reversed().map { (edge($0) + 0.01, $0 + freeboard($0)) })
        pen.fill(top, .black)
        pen.fill(face, .black)
        var quay = Path()
        quay.addPath(pen.poly(ys.map { (edge($0), $0) }, closed: false))
        quay.addPath(pen.poly([(-1, horizon + 0.04), (edge(horizon + 0.04), horizon + 0.04)], closed: false))
        // The flags, running out along it and across.
        var flags = Path()
        // Straight, as the seaward edge is, all running to the quay's far end.
        let end = (x: edge(horizon), y: horizon)
        for k in 1...5 {
            let x = edge(1.05) - Double(k) / 6 * (edge(1.05) + 1) * 1.6
            flags.addPath(pen.seg(end.x + (x - end.x) * 0.04 / (1.05 - end.y), horizon + 0.04, x, 1.05))
        }
        for y in [-0.3, -0.1, 0.15, 0.45, 0.8] { flags.addPath(pen.seg(-1, y, edge(y), y)) }
        // Bollards near the edge, the sea swirling round their feet.
        var bollards = Path(), swirl = Path()
        for (y, k) in [(0.62, 0.05), (-0.3, 0.03)] {
            let x = edge(y) - 0.08
            let b = pen.poly([(x - 0.5 * k, y), (x - 0.5 * k, y - 0.9 * k), (x - 0.7 * k, y - 1.1 * k), (x + 0.7 * k, y - 1.1 * k),
                              (x + 0.5 * k, y - 0.9 * k), (x + 0.5 * k, y)])
            pen.fill(b, .black)
            bollards.addPath(b)
            swirl.addPath(pen.ellipse(x, y, 1.1 * k, 0.3 * k))
            swirl.addPath(pen.curve(x - 1.6 * k, y + 0.3 * k, x - 0.2 * k, y + 0.6 * k, x + 1.4 * k, y + 0.2 * k))
        }
        // The buoy the boat is moored to, and its line from it.
        var mooring = Path()
        mooring.addPath(pen.seg(buoy.x, buoy.y, bow.x, bow.y))
        let float = pen.circle(buoy.x, buoy.y - 0.012, 0.018)
        pen.fill(float, .black)
        pen.lit { g in
            g.stroke(far, ink, 0.8)
            g.stroke(flags, ink, 0.25)
            g.stroke(quay, ink)
            g.stroke(bollards, ink)
            g.stroke(swirl, Flood.rain, 0.6)
            g.stroke(mooring, Flood.sodium, 0.6)
            g.stroke(float, ink)
        }
        // The sea along the wall's face, and breaking in the foreground.
        pen.lit([(0.02, 0.3), (0.007, 0.8)]) { g in
            g.stroke(g.poly(ys.map { (edge($0) + 0.01, $0 + freeboard($0)) }, closed: false), Flood.sea, 0.9)
        }
        for (x, y, k) in [(0.5, 0.5, 0.2), (0.78, 0.25, 0.18), (0.3, 0.84, 0.22), (0.72, 0.72, 0.2), (-0.3, -0.42, 0.12)] {
            Cast.breaker(pen.at(x, y, k: k), colour: Flood.sea)
        }

        // Vignette 1, the boat.
        pen.vignette(1) { pen in
            if played.contains(1) {
                OverTheQuay.keel(pen, depth: 0)
            } else {
                OverTheQuay.keel(pen, depth: 0.045)
            }
        }

        // Vignette 4, the wall.
        pen.vignette(4) { pen in
            let y = -0.03, x = edge(y)
            if played.contains(4) {
                // Slopping against the face, a little short of the top.
                for (dy, a) in [(-0.045, 0.0), (0.012, 0.6)] {
                    let sx = edge(y + dy) + 0.02, sy = y + dy + freeboard(y + dy) - 0.004
                    pen.stroke(pen.curve(sx, sy, sx + 0.016, sy - 0.022 - 0.01 * a, sx + 0.034, sy), Flood.sea, 0.8)
                }
            } else {
                // A wave over the top, its white water spilling across the stones.
                Cast.breaker(pen.at(x + 0.01, y + 0.005, k: 0.09, flip: true), glows: Rescue.tight, colour: Flood.rain)
                for (dx, dy, l) in [(-0.04, 0.02, 0.05), (-0.03, 0.045, 0.045), (-0.05, -0.005, 0.04)] {
                    pen.stroke(pen.seg(x + dx, y + dy, x + dx - l, y + dy + 0.01), Flood.rain, 0.7)
                }
            }
        }

        // Vignette 3, the dropped lantern.
        pen.vignette(3) { pen in
            let x = -0.455, y = 0.585
            if played.contains(3) {
                // On its side, the cage bent, its glass gone: shards by it.
                Cast.lantern(pen.at(x, y, k: 0.08, turn: .pi / 2 - 0.15), lit: false, colours: (Flood.sodium, ink))
                for (dx, dy, a) in [(-0.01, -0.045, 0.4), (0.03, 0.045, -0.6), (0.005, 0.035, 1.2)] {
                    pen.stroke(pen.seg(x + dx, y + dy, x + dx + 0.016 * cos(a), y + dy + 0.016 * sin(a)), ink, 0.8)
                }
            } else {
                // Only the bail ring, left where it fell.
                pen.stroke(pen.ellipse(x + 0.09, y - 0.005, 0.022, 0.011), ink)
            }
        }
    }

    /// The family's boat capsized at its mooring, keel up: `depth` how far it has sunk from riding high.
    static func keel(_ pen: Brush, depth: Double) {
        let water = bow.y, x0 = bow.x, x1 = bow.x + 0.17
        let hull = pen.path { h in
            h.move(to: CGPoint(x: x0, y: water + depth))
            h.addQuadCurve(to: CGPoint(x: x0 + 0.085, y: water - 0.06 + depth), control: CGPoint(x: x0 + 0.01, y: water - 0.055 + depth))
            h.addQuadCurve(to: CGPoint(x: x1, y: water + depth), control: CGPoint(x: x1 - 0.005, y: water - 0.06 + depth))
            h.closeSubpath()
        }
        let above = pen.clipped(to: pen.rect(-1, -1, 1, water))
        above.fill(hull, .black)
        var lines = Path()
        lines.addPath(hull)
        lines.addPath(pen.seg(x0 + 0.085, water - 0.06 + depth, x0 + 0.085, water - 0.08 + depth))
        above.lit(Rescue.tight) { $0.stroke(lines, Flood.ink) }
        // The sea along her, washing over when she is awash.
        var wash = Path()
        wash.addPath(pen.seg(x0 - 0.01, water, x1 + 0.01, water))
        if depth > 0 {
            for (x, w) in [(x0 + 0.05, 0.03), (x0 + 0.11, 0.035)] { wash.addPath(pen.curve(x - w / 2, water, x, water - 0.02, x + w / 2, water)) }
        }
        pen.lit(Rescue.tight) { $0.stroke(wash, Flood.sea, 0.9) }
    }
}
