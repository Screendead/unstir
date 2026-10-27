// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import simd

/// Endless's brim as a measuring jug on the tank's own bezel, which Brim.metal draws: ticks engraved on the steel, a
/// brim pin at twelve, and a liquid in the picture's own colours climbing both sides from six o'clock to a level line.
/// Ported from the mockup Jack approved (2026-09-28), with its constants in its own units.
enum Brim {
    /// The mockup's pixels to the glass's radius, Brim.metal's unit of length.
    static let unit = 480.0
    static let rOut = unit * 1.045, rMid = (unit + rOut) / 2
    /// How far past the bezel the rim draws: out to where the glow and a spill's drops have faded.
    static let reach = 110.0

    /// The spill, in seconds after the push that fills the brim. The two fronts meet at the brim pin, a crest swells over
    /// the lip and breaks 0.3 s later (Brim.metal times the pour from the meet).
    static let meet = 0.44
    /// The brim pin dims from here.
    static let drain = meet + 0.6
    /// What ran over soaks away from here, over `soakFor`.
    static let soak = meet + 1.2, soakFor = 1.6
    /// The picture starts to stir together.
    static let murk = meet + 0.1
    static let words = 1.3
    static let card = 2.0
    /// How long the rim moves after a change: the liquid settles still, and the spill has run its course.
    static let settle = 3.0, spillSettle = 4.8

    /// A change of the brim, from and to how many notches, `time` in seconds since the reference date.
    struct Event: Equatable {
        var from: Int
        var to: Int
        var time: Double
    }

    private static func sstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }

    static func ease(_ x: Double) -> Double { sstep(0, 1, x) }

    /// A damped spring from 0 to 1, `tau` seconds after it is let go: it overshoots, which is the slosh of a pour.
    static func spring(_ tau: Double) -> Double {
        guard tau > 0 else { return 0 }
        let zeta = 0.5, w = 2 * Double.pi * 1.7, root = (1 - zeta * zeta).squareRoot()
        return 1 - exp(-zeta * w * tau) * (cos(w * root * tau) + zeta / root * sin(w * root * tau))
    }

    /// The fill in ticks at `t`, from `base` as the tank opened: each change springs in, except the one that fills the
    /// brim, whose two fronts climb faster and faster to meet at twelve.
    static func level(at t: Double, _ events: [Event], base: Int, room: Int) -> Double {
        if let last = events.last, last.to >= room, t >= last.time + 0.06 {
            let x = (t - last.time - 0.06) / (meet - 0.06)
            return x < 1 ? Double(room - 1) + x * x : Double(room)
        }
        return events.filter { $0.to < room }.reduce(Double(base)) { $0 + Double($1.to - $1.from) * spring(t - $1.time - 0.06) }
    }

    /// Where the surface stands for a fill of `g` ticks, in Brim.metal's units below the centre: a level chord that
    /// crosses the bezel's middle at the tick for g on both sides, and clears the bezel when empty and when full.
    /// Empty, it stands far enough below that the meniscus (3.4 up the walls), the bob and the ripple leave no glint on
    /// the edge.
    static func levelY(_ g: Double, room: Int) -> Double {
        let n = Double(room), g = min(max(g, 0), n)
        let rl = rMid + (rOut + 11 - rMid) * sstep(1, 0, g) + (rOut + 3 - rMid) * sstep(n - 1, n, g)
        return rl * cos(g * .pi / n)
    }

    /// How much the liquid moves at `t`: fully while room runs short and for a while after each change, then it settles.
    static func alive(at t: Double, _ events: [Event], warn: Double, room: Int) -> Double {
        guard let last = events.last else { return warn > 0.01 ? 1 : 0 }
        if last.to >= room { return 1 - sstep(spillSettle - 0.6, spillSettle - 0.2, t - last.time) }
        return warn > 0.01 ? 1 : 1 - sstep(settle - 0.6, settle, t - last.time)
    }

    /// The liquid's own time, which stands still while it rests, and the phase of the brim pin's pulse.
    final class Clock {
        private var last: Double?
        private(set) var time = 0.0, phase = 0.0

        func advance(to now: Double, alive: Double, warn: Double) {
            if let last {
                let dt = min(max(now - last, 0), 0.1) * alive
                time += dt
                phase += 2 * .pi * (1.3 + 2 * warn) * dt
            }
            last = now
        }
    }

    /// Everything Brim.metal needs for the rim at `now`, in its order (see its comment). With `held`, the liquid's
    /// clock stands at that many seconds instead of `clock`'s.
    static func frame(at now: Double, _ events: [Event], base: Int, room: Int, clock: Clock, held: Double?)
        -> [Float] {
        let n = Double(room)
        let spill = events.last.flatMap { $0.to >= room ? $0.time : nil }
        let met = spill.map { now >= $0 + meet } ?? false
        func g(_ t: Double) -> Double { level(at: t, events, base: base, room: room) }
        let fill = g(now)
        let warn = met ? 0 : sstep(n - 1.7, n - 1, fill)
        let live = alive(at: now, events, warn: warn, room: room)
        let t: Double, phase: Double
        if let held {
            (t, phase) = (held, 2 * .pi * (1.3 + 2 * warn) * held)
        } else {
            clock.advance(to: now, alive: live, warn: warn)
            (t, phase) = (clock.time, clock.phase)
        }
        let calm = met ? 0 : live
        var slosh = 0.0
        if !met {
            for (i, e) in events.enumerated() where now > e.time {
                slosh += (i % 2 == 0 ? 4.5 : -4.5) * exp(-(now - e.time) / 0.4) * sin(2 * .pi * 2 * (now - e.time))
            }
        }
        let bob = calm * (1.1 * sin(2 * .pi * 0.61 * t) + 0.7 * sin(2 * .pi * 1.07 * t + 1.3))
        let tilt = slosh * .pi / 180 + calm * 0.004 * sin(2 * .pi * 0.83 * t + 0.4)
        var rng = SplitMix64(state: UInt64(max(t * 30, 0)))
        let j = (0..<3).map { _ in Double.random(in: -1...1, using: &rng) }
        func tremble(_ side: Int) -> Double {
            let s = Double(side), fast: Double = 0.55 * sin(2 * .pi * 9.3 * t + j[0] + s)
            return warn * 2.4 * (fast + 0.3 * j[1 + side] + 0.25 * sin(2 * .pi * 14.1 * t + 2 * s))
        }
        let trem = [tremble(0), tremble(1)]
        // Where the liquid stood a moment ago, drying back at 1.1 ticks a second.
        var wet = fill
        if let last = events.last, now - last.time < 3 {
            for k in 1...180 { wet = max(wet, g(now - Double(k) / 60) - 1.1 * Double(k) / 60) }
        }
        let rises = events.filter { $0.to > $0.from && now >= $0.time }
        let kick = rises.map { e -> Double in
            let since = now - e.time
            return sstep(0.04, 0.22, since) * exp(-max(since - 0.22, 0) / 0.45)
        }.max() ?? 0
        // Each of the last two notches' colour spreads across the channel where the surface has come up since it began.
        func spread(_ e: Event?) -> (old: Double, tau: Double) {
            guard let e, now - e.time < 2 else { return (-1e4, 1e3) }
            return (levelY(g(e.time), room: room), now - e.time - 0.08)
        }
        let (old, tau) = spread(rises.last), (old2, tau2) = spread(rises.dropLast().last)
        let pulse = 0.5 + 0.5 * sin(phase)
        let tb = spill.map { now - $0 - meet } ?? -1e3
        let flash = tb >= 0 ? exp(-tb / 0.3) : 0
        var bri = 0.9 + warn * (0.25 + 0.75 * pulse * pulse) + 1.4 * flash
        if let spill, now >= spill + drain { bri *= 1 - 0.45 * ease((now - spill - drain) / 2) }
        let soaked = spill.map { 1 - ease((now - $0 - soak) / soakFor) } ?? 1
        let wetFilm: Double = min(max((wet - fill) * 1.4, 0), 1) * 0.35
        let fullness = sstep(3 * n / 8, n, fill)
        let floats: [Double] = [t, levelY(fill, room: room), tan(tilt), bob, trem[0], trem[1], warn, calm, old, tau,
                                levelY(wet, room: room), wetFilm, kick, pulse, fullness, tb, flash, bri, soaked, reach,
                                180 / n, old2, tau2, sstep(0, 0.6, fill)]
        return floats.map { Float($0) }
    }

    /// The picture's colours round the rim as the stack stirs them, 3 floats per angle clockwise from three o'clock: the
    /// liquid's, sampled deep and wide and pushed apart from grey at full strength, and the picture's own lines where
    /// they meet the rim. Each point is mapped back as the tank's shader maps it, the glass's turn first. The picture is
    /// endless's, the grid.
    static func colours(_ stack: [Twist], layout: Layout, turn: Double) -> (hue: [Float], lines: [Float]) {
        let rods = layout.rods, ct = cos(turn), st = sin(turn)
        func seen(_ p: SIMD2<Double>) -> SIMD3<Double> {
            var q = SIMD2(p.x * ct + p.y * st, p.y * ct - p.x * st)
            for t in stack.reversed() { q = Tank.twist(q, rod: rods[t.rod], angle: -Double(t.steps) * Tank.step) }
            return Picture.gridLight(q)
        }
        func around(_ n: Int, radii: [Double], blur sigma: Double) -> [SIMD3<Double>] {
            let raw = (0..<n).map { i in
                let a = 2 * Double.pi * Double(i) / Double(n)
                return radii.reduce(SIMD3<Double>.zero) { $0 + seen($1 * SIMD2(cos(a), sin(a))) } / Double(radii.count)
            }
            let k = Int(3 * sigma), w = (-k...k).map { exp(-pow(Double($0) / sigma, 2) / 2) }, sum = w.reduce(0, +)
            return (0..<n).map { i in (-k...k).reduce(SIMD3<Double>.zero) { $0 + raw[(i + $1 + n) % n] * w[$1 + k] } / sum }
        }
        let hue = around(360, radii: (0..<8).map { 0.883 + 0.1 * Double($0) / 7 }, blur: 5).map { p in
            let p = p / (p.max() + 1e-4), mean = (p.x + p.y + p.z) / 3
            let wide = simd_clamp(SIMD3(repeating: mean) + (p - mean) * 1.5, .zero, .one)
            return wide / (wide.max() + 1e-4)
        }
        let lines = around(720, radii: [0.979, 0.9855, 0.992], blur: 1)
        func floats(_ v: [SIMD3<Double>]) -> [Float] { v.flatMap { [Float($0.x), Float($0.y), Float($0.z)] } }
        return (floats(hue), floats(lines))
    }

    /// After the spill, `t` seconds after they begin, the stirs that mix the picture together (Brim.metal's `murk`), 4
    /// floats each, oldest first: eight rounds of the tank's own vortex, its eye wandering so no point is left unmixed,
    /// and two of the rods, each easing in a moment after the one before, wound only so far that broad bands keep their
    /// colours.
    static func murk(_ layout: Layout, seed: UInt64, at t: Double) -> [Float] {
        var rng = SplitMix64(state: seed)
        var stirs: [SIMD4<Double>] = []
        for k in 0..<8 {
            let eye = 0.05 * SIMD2(cos(2.4 * Double(k)), sin(2.4 * Double(k)))
            stirs.append(SIMD4(eye.x, eye.y, 1 - simd_length(eye), .random(in: 3.0..<4.2, using: &rng)))
            for rod in layout.rods.indices.shuffled(using: &rng).prefix(2) {
                let c = layout.rods[rod]
                stirs.append(SIMD4(c.x, c.y, c.z, .random(in: 2.8..<3.8, using: &rng) * (rng.below(2) == 0 ? 1 : -1)))
            }
        }
        return stirs.enumerated().flatMap { i, s in
            [Float(s.x), Float(s.y), Float(s.z), Float(s.w * 0.5 * ease((t - 0.054 * Double(i)) / 1.45))]
        }
    }
}

/// Endless's brim round glass of radius `r`, filled into a ring from the glass's edge out, so it shades none of the glass.
struct BrimRing: View {
    let r: CGFloat
    let brim: Int
    let events: [Brim.Event]
    /// The notches the tank opened with.
    let base: Int
    let colours: (hue: [Float], lines: [Float])
    /// UNSTIR_CLOCK: the rim held this many seconds after the newest change.
    let held: Double?
    let paused: Bool
    @State private var clock = Brim.Clock()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: paused || held != nil)) { timeline in
            let now = held.map { (events.last?.time ?? 0) + $0 } ?? timeline.date.timeIntervalSinceReferenceDate
            let floats = Brim.frame(at: now, events, base: base, room: Run.room, clock: clock, held: held)
            let outer = CGFloat(Brim.rOut + Brim.reach) / CGFloat(Brim.unit) * r
            Circle()
                .stroke(ShaderLibrary.brim(.float2((r + outer) / 2, (r + outer) / 2), .float(r), .floatArray(floats),
                                           .floatArray(colours.hue), .floatArray(colours.lines)),
                        lineWidth: outer - r)
                .frame(width: r + outer, height: r + outer)
        }
        .frame(width: 2 * r, height: 2 * r)
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel("brim")
        .accessibilityValue("\(brim) of \(Run.room)")
    }
}

/// "spilled.", stamped over the tank of radius `r` once the pour has run, `at` seconds after the spill, over a dark
/// pool so it reads on any picture.
struct SpillWords: View {
    let r: CGFloat
    let at: Double

    var body: some View {
        let x = Brim.ease((at - Brim.words) / 0.35)
        ZStack {
            Circle().fill(RadialGradient(colors: [.black.opacity(0.8), .black.opacity(0.55), .clear], center: .center,
                                         startRadius: 0, endRadius: 0.65 * r))
                .frame(width: 1.3 * r, height: 1.3 * r)
                .scaleEffect(x: 1, y: 0.45)
            Text("spilled.").font(.mono(40, .semibold)).foregroundStyle(Color.text)
                .shadow(color: .alarm.opacity(0.9), radius: 12)
                .shadow(color: .white.opacity(0.4), radius: 3)
                .scaleEffect(1.3 - 0.3 * x)
        }
        .opacity(x)
        .allowsHitTesting(false)
    }
}

/// After the spill, the picture stirred together by `stirs` (Brim.murk); off until then.
struct Murk: ViewModifier {
    let stirs: [Float]
    let side: CGFloat
    @Environment(\.displayScale) private var scale

    func body(content: Content) -> some View {
        content.layerEffect(ShaderLibrary.murk(.float2(side / 2, side / 2), .float(side / 2),
                                               .floatArray(stirs.isEmpty ? [0, 0, 0, 0] : stirs), .float(Float(scale))),
                            maxSampleOffset: CGSize(width: side, height: side), isEnabled: !stirs.isEmpty)
    }
}
