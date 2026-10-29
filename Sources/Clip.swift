// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// A pack card's clip: real levels played by a drawn fingertip at a hand's pace, each move through `Array.commit` and,
/// on a clock, its tick through `Game.tick`, so the stacks are the ones the level would show. Drawn live by the game's
/// own views, as a pure function of the clip's time, so the harness can hold any frame and Reduce Motion holds `still`.
struct Clip: Sendable {
    let reels: [Reel]
    /// The frame Reduce Motion holds, in the clip's time.
    let still: Double

    var period: Double { reels.reduce(0) { $0 + $1.shown } }

    /// The reel at clip time `t`, wrapped onto the loop, and the reel's own time there.
    func reel(at t: Double) -> (reel: Reel, index: Int, t: Double) {
        var u = t.truncatingRemainder(dividingBy: period)
        if u < 0 { u += period }
        for (i, r) in reels.enumerated() {
            if u < r.shown || i == reels.count - 1 { return (r, i, r.from + min(u, r.shown)) }
            u -= r.shown
        }
        fatalError("a clip has reels")
    }

    /// Each offer's clip. Complete cuts between the three.
    static func of(_ offer: Offer) -> Clip {
        switch offer {
        case .pack(.firstStir): firstStir
        case .pack(.lens): lens
        case .pack(.escapement): escapement
        case .pack(.prism): prism
        case .complete: complete
        }
    }

    /// Level 1 healed top first, the night winding back a stage and its clock stepping back with each vignette.
    static let firstStir = Clip(reels: [.firstStir()], still: Reel.firstStir().beats[1].lift + 0.5)

    /// Level 3 as dealt, the lens newest, so its rim runs whole through both twists beside it: the order read. The finger
    /// drags it down to clean and back up, so it zooms out and in again, crisp at its rim, and lets go where it took it.
    static let lens = Clip(reels: [.lens()], still: 0.5)

    /// Escapement 1 solved in its par of three: a stir, its tick landing; a wait, and a tick; the last stir, whose tick
    /// stops the clock on the clean picture.
    static let escapement = Clip(reels: [.escapement()], still: Reel.escapement().beats[0].lift + 0.6)

    /// Specimen 1 healed top first.
    static let prism = Clip(reels: [.prism()], still: 0.5)

    /// Each pack's telling beat in turn, inside about eight seconds: a vignette, a zoom, a tick.
    static let complete = Clip(reels: [cutStory, .lens(dips: true, rest: 0.3, down: 0.6, hold: 0.1, up: 0.6, tail: 0.25),
                                       .escapement(moves: 1, rest: 0.45, tail: 0.7)],
                               still: cutStory.beats[0].lift + 0.5)
    private static let cutStory = Reel.firstStir(moves: 1, rest: 0.45, tail: 0.6)
}

/// One level's part of a clip, timed in its own seconds from 0 to `length`.
struct Reel: Sendable {
    /// One move of the fingertip: a knob's turn through `keys` (steps from where it took the knob, and the seconds to get
    /// there), let go at the last; or a tap on a ratchet.
    enum Gesture: Sendable {
        case turn(knob: Int, keys: [(steps: Double, seconds: Double)])
        case tap(knob: Int)

        /// A plain turn at the fingertip's pace, as `UNSTIR_FINGER` turns: about a step a tenth of a second.
        static func turn(_ knob: Int, _ steps: Int) -> Gesture { .turn(knob: knob, keys: [(Double(steps), 0.1 * Double(abs(steps)) + 0.25)]) }

        var knob: Int {
            switch self {
            case .turn(let k, _), .tap(let k): k
            }
        }
    }

    struct Beat: Sendable {
        let gesture: Gesture
        /// When the fingertip lands, the turn or the press begins, and it lifts and the move commits.
        let land: Double, start: Double, lift: Double
        let before: [Game.Entry]
        /// After the move, under the clock's tick as it lands.
        let moved: [Game.Entry]
        /// After the move and its tick.
        let after: [Game.Entry]
        /// Nil where nothing commits: a turn let go where it began, or a wait.
        let result: Commit?
        let heals: Bool
        let ticked: Bool
        /// The tick emptied the clock's rod.
        let stops: Bool
    }

    let level: Level
    let opening: [Game.Entry]
    let beats: [Beat]
    let length: Double
    /// The part shown, and whether it dips in from black and out to it.
    let from: Double, to: Double
    let dips: Bool
    /// First Stir's time under the tank, in minutes after midnight, as the level opens and once every entry has gone.
    let night: (late: Double, early: Double)?

    var shown: Double { to - from }

    static let dip = 0.35
    /// The fingertip's beat between landing and turning, and between turning and letting go.
    static let settle = 0.35, hold = 0.25, press = 0.18

    init(level: Level, opening: [Game.Entry]? = nil, gestures: [Gesture], rest: Double, gap: Double, tail: Double,
         dips: Bool = true, night: (late: Double, early: Double)? = nil) {
        self.level = level
        self.night = night
        self.dips = dips
        let opening = opening ?? Game.dealt(level)
        self.opening = opening
        var entries = opening, t = rest, beats: [Beat] = []
        for (i, g) in gestures.enumerated() {
            let land = t, start = land + Self.settle, playedWas = Self.played(level, entries)
            var lift = start + Self.press, result: Commit?
            var moved = entries
            if case .turn(let k, let keys) = g {
                lift = start + keys.reduce(0) { $0 + $1.seconds } + Self.hold
                let net = Int(keys.last!.steps.rounded())
                if net != 0 {
                    result = moved.commit(Game.Entry(twist: Twist(rod: k, steps: net), pushed: true), in: level.layout, lenses: level.lenses, masks: level.masks)
                }
            }
            var after = moved, ticked = false, stops = false
            if let e = level.clock, g.knob == e || result != nil, let r = Game.tick(&after, on: e, in: level), r != .refused {
                ticked = true
                stops = !after.contains { $0.twist.rod == e }
            }
            let heals = level.story != nil ? !Self.played(level, after).isSubset(of: playedWas) : result == .cancelled
            beats.append(Beat(gesture: g, land: land, start: start, lift: lift, before: entries, moved: moved, after: after,
                              result: result, heals: heals, ticked: ticked, stops: stops))
            entries = after
            t = lift + (i == gestures.count - 1 ? tail : gap)
        }
        self.beats = beats
        length = t + (dips ? Self.dip : 0)
        from = 0
        to = length
    }

    /// The story's vignettes played on `entries`; a solved tank has played them all.
    static func played(_ level: Level, _ entries: [Game.Entry]) -> Set<Int> {
        guard let story = level.story else { return [] }
        return entries.isEmpty ? story.vignettes : story.vignettes.subtracting(entries.flatMap(\.tags))
    }

    /// Top first, each newest entry a working knob can take off: what the harness's autoplay plays.
    static func solve(_ level: Level, moves: Int = .max) -> [Gesture] {
        var stack = level.scramble, out: [Gesture] = []
        while out.count < moves, let i = level.layout.removable(stack, lenses: level.lenses, masks: level.masks).last {
            out.append(.turn(stack[i].rod, -stack[i].steps))
            stack.commit(rod: stack[i].rod, steps: -stack[i].steps, in: level.layout, lenses: level.lenses, masks: level.masks)
        }
        return out
    }

    /// Level 1, the harbour, as the outline's scene 16 (12:30 am back to 11:40 pm) until the level carries its own clock.
    static func firstStir(moves: Int = .max, rest: Double = 0.7, tail: Double = 1.3) -> Reel {
        let level = Level.firstStir[0]
        return Reel(level: level, gestures: solve(level, moves: moves), rest: rest, gap: 0.6, tail: tail, night: (30, -20))
    }

    static func lens(dips: Bool = false, rest: Double = 1.4, down: Double = 1.3, hold: Double = 0.5, up: Double = 1.3,
                     tail: Double = 1.75) -> Reel {
        let level = Level.lens[2], lens = level.lenses.min()!
        let dealt = level.scramble.last { $0.rod == lens }!.steps
        return Reel(level: level, gestures: [.turn(knob: lens, keys: [(Double(-dealt), down), (Double(-dealt), hold), (0, up)])],
                    rest: rest, gap: 0, tail: tail, dips: dips)
    }

    /// Specimen 1: tri's red rod and cyan one over a white bottom entry, the red stir buried under the cyan one healed first.
    static func prism() -> Reel {
        let level = Level.prism[0]
        return Reel(level: level, gestures: solve(level), rest: 0.7, gap: 0.6, tail: 1.2)
    }

    /// Its par's three moves, the second a wait on the clock.
    static func escapement(moves: Int = 3, rest: Double = 0.7, tail: Double = 1.2) -> Reel {
        let level = Level.escapement[0]
        let line: [Gesture] = [.turn(2, 4), .tap(knob: level.clock!), .turn(1, -3)]
        return Reel(level: level, gestures: Array(line.prefix(moves)), rest: rest, gap: 0.9, tail: tail)
    }

    // MARK: - A frame

    /// What the tank shows at reel time `t`.
    func frame(at t: Double) -> ClipFrame {
        var f = ClipFrame()
        if dips {
            f.dip = max(1 - (t - from) / Self.dip, (t - (to - Self.dip)) / Self.dip, 0)
        }
        let done = beats.filter { $0.lift <= t }
        var entries = done.last?.after ?? opening
        f.played = Self.played(level, entries)
        // The player's own turning per knob, so a knob shows only what the finger did.
        for b in done {
            if case .turn(let k, let keys) = b.gesture { f.knobs[k, default: 0] += keys.last!.steps.rounded() * Tank.step }
        }
        f.ticks = done.filter(\.ticked).count
        if let b = done.last {
            let s = t - b.lift
            if case .tap = b.gesture { f.flash = (b.gesture.knob, s) } else if b.result != nil { f.flash = (b.gesture.knob, s) }
            if b.heals { f.heal = (b.gesture.knob, s) }
            if b.result == .pushed { f.push = (b.gesture.knob, s) }
            if b.ticked {
                f.tickLit = s
                if b.stops { f.stop = s }
                let p = Self.flight(s)
                if p < 1 {
                    entries = b.moved
                    f.tick = (level.clock!, p * Tank.step)
                    f.ratchetTurn = p
                    f.pawl = sin(.pi * p)
                }
            }
            if b.after.isEmpty { f.solved = (b.gesture.knob, s) }
        }
        f.stack = entries.map(\.twist)
        f.clockRuns = entries.contains { $0.twist.rod == level.clock }
        f.finished = entries.isEmpty
        if let night {
            let count = level.scramble.count
            let gone = entries.isEmpty ? count : max(count - entries.filter { !$0.pushed }.count, 0)
            f.caption = Self.clock(night.late - (night.late - night.early) * Double(gone) / Double(max(count, 1)))
        }
        // The fingertip, from its landing until just after it lifts.
        if let b = beats.first(where: { $0.land <= t && t < $0.lift + 0.12 }) {
            let k = b.gesture.knob, rod = level.layout.rods[k], c = SIMD2(rod.x, rod.y)
            let shown = t < b.lift ? min((t - b.land) / 0.12, 1) : 1 - (t - b.lift) / 0.12
            switch b.gesture {
            case .tap:
                f.finger = (c, shown)
                f.pressing = t >= b.start && t < b.lift
            case .turn(_, let keys):
                let steps = t < b.lift ? Self.steps(keys, at: t - b.start) : keys.last!.steps
                let at = c + 0.5 * rod.z * SIMD2(0.7071, -0.7071)
                if t < b.lift {
                    f.live = (k, steps * Tank.step)
                    f.knobs[k, default: 0] += steps * Tank.step
                }
                let angle = steps * Tank.step
                // A lens follows the finger up and down; any other knob, round.
                let finger = level.lenses.contains(k) ? at - SIMD2(0, steps * LevelView.lensPitch)
                    : c + SIMD2((at - c).x * cos(angle) - (at - c).y * sin(angle), (at - c).x * sin(angle) + (at - c).y * cos(angle))
                f.finger = (finger, shown)
            }
        }
        return f
    }

    /// A tick's flight `s` seconds after the lift, 0 to 1, as `LevelView.tickKeys` plays it.
    static func flight(_ s: Double) -> Double {
        ease((s - LevelView.tickBeat) / LevelView.tickTurn)
    }

    /// Where a turn stands `s` seconds after it began: eased from key to key.
    static func steps(_ keys: [(steps: Double, seconds: Double)], at s: Double) -> Double {
        var from = 0.0, s = s
        for key in keys {
            if s < key.seconds { return from + (key.steps - from) * ease(s / key.seconds) }
            s -= key.seconds
            from = key.steps
        }
        return from
    }

    static func ease(_ x: Double) -> Double { let c = min(max(x, 0), 1); return c * c * (3 - 2 * c) }

    /// The time as First Stir's caption shows it (Jack, F3): "6:40 am".
    static func clock(_ minutes: Double) -> String {
        let m = (Int(minutes.rounded()) % 1440 + 1440) % 1440, h = m / 60
        return "\((h + 11) % 12 + 1):\(String(format: "%02d", m % 60)) \(h < 12 ? "am" : "pm")"
    }
}

/// One frame of a reel. Each `(rod, s)` is a ring's seconds since the lift that set it off.
struct ClipFrame {
    var stack: [Twist] = []
    var played: Set<Int> = []
    var live: (rod: Int, angle: Double)?
    var tick: (rod: Int, angle: Double)?
    var knobs: [Int: Double] = [:]
    var ticks = 0
    var ratchetTurn = 1.0
    var pawl = 0.0
    var pressing = false
    var clockRuns = false
    var finished = false
    var finger: (at: SIMD2<Double>, shown: Double)?
    var flash: (rod: Int, s: Double)?
    var heal: (rod: Int, s: Double)?
    var push: (rod: Int, s: Double)?
    var tickLit: Double?
    var stop: Double?
    var solved: (rod: Int, s: Double)?
    var caption: String?
    var dip = 0.0
}

/// A clip's tank and, on First Stir, its time under it, drawn with the level's own views.
struct ClipTank: View {
    let reel: Reel
    let t: Double
    let side: CGFloat

    var body: some View {
        let f = reel.frame(at: t)
        VStack(spacing: 20) {
            tank(f)
            if reel.night != nil {
                Text(f.caption ?? "").font(.mono(.subheadline, .medium)).monospacedDigit().opacity(0.8)
                    .contentTransition(.identity)
            }
        }
        .opacity(1 - f.dip)
        .accessibilityHidden(true)
    }

    private func tank(_ f: ClipFrame) -> some View {
        let level = reel.level, layout = level.layout, rods = layout.rods, r = side / 2
        func at(_ k: Int) -> CGPoint { CGPoint(x: r + rods[k].x * r, y: r + rods[k].y * r) }
        func disc(_ k: Int) -> CGFloat { min(rods[k].z * r, r - 4) }
        let core = 2 * Tank.coreRadius * r, hairline: CGFloat = 0.5
        var unstirred = Unstirred(stack: f.stack, layout: layout, lenses: level.lenses, masks: level.masks, liveRod: f.live?.rod,
                                  liveAngle: f.live?.angle ?? 0, side: side, fillEntries: level.picture.fillEntries)
        unstirred.tick = f.tick
        if let w = f.solved {
            unstirred.wave = SIMD3(Float(rods[w.rod].x), Float(rods[w.rod].y), Float(1.9 * (1 - pow(1 - min(w.s / 0.9, 1), 2))))
        }
        let ratchet = LevelView.ratchetSize(core)
        return ZStack {
            Group {
                if let story = level.story {
                    StoryLayer(story: story, played: f.played, side: side)
                } else {
                    PictureLayer(picture: level.picture, side: side, seed: Int(level.label) ?? 0, clock: t)
                }
            }
            .modifier(unstirred)
            .clipShape(Circle())
            if let e = level.clock, !f.finished {
                ClockHint(radius: disc(e)).position(at(e))
            }
            if let fl = f.flash, fl.s < 0.3 {
                Circle().stroke(Color.live, lineWidth: hairline).frame(width: 2 * disc(fl.rod), height: 2 * disc(fl.rod))
                    .opacity(0.9 * pow(1 - fl.s / 0.3, 2)).position(at(fl.rod))
            }
            Bezel(r: r)
            if let h = f.heal, h.s < 0.45 {
                let u = 1 - pow(1 - h.s / 0.45, 2), across = 2 * disc(h.rod) * (0.3 + 0.7 * u)
                Circle().stroke(Color.magenta, lineWidth: hairline).frame(width: across, height: across)
                    .opacity(0.9 * (1 - u * u)).position(at(h.rod))
            }
            ForEach(rods.indices.filter { $0 != layout.swirl }, id: \.self) { k in
                if k == level.clock {
                    RatchetView(angle: (Double(f.ticks) - (1 - f.ratchetTurn)) * Tank.step,
                                size: ratchet, pawl: f.pawl, lit: f.pressing, stopped: !f.clockRuns)
                        .position(at(k))
                } else {
                    RodView(angle: f.knobs[k] ?? 0, size: core, seized: level.kind(of: k) != .working, grabbed: f.live?.rod == k,
                            lens: level.lenses.contains(k), tint: level.tint(of: k))
                        .position(at(k))
                }
            }
            if let p = f.push, p.s < 0.4 {
                Circle().strokeBorder(Color.alarm, lineWidth: 1).padding(-3).frame(width: core, height: core)
                    .opacity(pow(1 - p.s / 0.4, 2)).position(at(p.rod))
            }
            if let e = level.clock {
                if let s = f.tickLit {
                    let v = s < 0.15 ? 0.25 * s / 0.15 : min(0.25 + 0.75 * (s - 0.15) / 0.6, 1)
                    Circle().stroke(Color.vermilion, lineWidth: hairline).frame(width: 2 * disc(e), height: 2 * disc(e))
                        .opacity(v >= 1 ? 0 : 0.9 * sin(.pi * v)).position(at(e))
                }
                if let s = f.stop, s > 0.3, s < 1 {
                    let u = 1 - pow(1 - (s - 0.3) / 0.7, 2), coreSize = 2 * Tank.plateau * disc(e), w = ratchet + (coreSize - ratchet) * u
                    Circle().stroke(Color.amber, lineWidth: 2).frame(width: w, height: w).opacity(0.9 * (1 - u * u)).position(at(e))
                }
            }
            if let finger = f.finger {
                let d = 40 * min(1, side / 360)
                Circle().fill(Color.white.opacity(0.28)).overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                    .frame(width: d, height: d)
                    .opacity(finger.shown)
                    .position(x: r + finger.at.x * r, y: r + finger.at.y * r)
            }
        }
        .frame(width: side, height: side)
        .scaleEffect(f.solved.map { 1 + 0.02 * sin(min($0.s / 0.9, 1) * .pi) } ?? 1)
    }
}

/// A clip on the loop from when it appears, or held at the harness's `held` seconds, or under Reduce Motion at its still.
struct ClipPlayer: View {
    let clip: Clip
    let side: CGFloat
    var held: Double?
    @State private var start = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let t = held ?? (reduceMotion ? clip.still : nil) {
                frame(t)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60)) { tl in frame(tl.date.timeIntervalSince(start)) }
            }
        }
        .onAppear { start = .now }
    }

    /// Every reel stays drawn, the others clear and held at their start, so a cut never waits on a picture's bake or
    /// strike. Only First Stir's reel has a caption under its tank, so the reels share a top, not a centre, or a
    /// Complete clip's tank would jump at each cut to or from it.
    private func frame(_ t: Double) -> some View {
        let (_, i, u) = clip.reel(at: t)
        return ZStack(alignment: .top) {
            ForEach(clip.reels.indices, id: \.self) { j in
                ClipTank(reel: clip.reels[j], t: j == i ? u : clip.reels[j].from, side: side).opacity(j == i ? 1 : 0)
            }
        }
    }
}
