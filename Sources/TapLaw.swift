// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// A glass the four-tap budget is learnt for: the screen's top rate and the glass's side in pixels, to 16 px, so a
/// phone has one, or one per Display Zoom, and the Duo one per pose. No key holds glasses either side of
/// `Tank.fourTapsKept`, whose static limits differ by 18.
struct TapKey: Hashable {
    let hz: Int
    let px: Int

    init(hz: Int, pixels: Double) {
        self.hz = hz
        px = Self.side(pixels)
    }

    static func side(_ pixels: Double) -> Int {
        let r = Int((pixels / 16).rounded()) * 16, kept = Int(Tank.fourTapsKept / 16)
        return pixels <= Tank.fourTapsKept ? min(r, kept * 16) : max(r, (kept + 1) * 16)
    }

    var name: String { "\(px)px@\(hz)" }
    /// Its UserDefaults key, never synced.
    var stored: String { "taps.\(hz).\(px)" }
}

/// What one display-link interval says about the frame drawn in it.
enum FrameClass: Equatable {
    case onTime
    /// Late with the main thread mostly idle: blocked on the frames ahead of it, so the GPU's work as far as the link can
    /// tell.
    case gpuMiss
    /// Late with the main thread busy nearly throughout: its own stall, which the taps don't change.
    case cpuMiss
    /// Late but neither, or nothing moved in it: not counted.
    case ignored
}

/// The numbers the law runs on, in one place: starting points to tune on the phone, none measured.
struct TapCuts: Equatable {
    /// A frame is late past this many granted periods, a vsync skipped. Past `hitch` it is a stall no frame of the
    /// shader's makes: the heaviest the ceiling allows, on the largest glass, runs under three.
    var late = 1.5, hitch = 6.0
    /// Whether the main thread's CPU time tells the GPU's misses from its own. Off, every late frame counts.
    var attributes = true
    /// GPU misses among the window's last `ring` counted frames that step the budget down, at work within `edge` of the
    /// budget, and further below it only while the phone is hot. Cool, a miss far below is taken for a passing one: a
    /// step from there would draw every depth above it at two taps, and only play at the new edge climbs back.
    var near = 3, far = 6, ring = 30, edge = 4
    /// Clean frames at the budget's edge that step it up one, and that probe a provisional cap.
    var climb = 600, probe = 1200
    /// On-time two-tap frames at or under a step's work, or up to `edge` over it, that confirm the step.
    var hold = 120
    /// The window's first seconds, uncounted while the GPU's clock ramps up from idle.
    var skip = 0.05

    static let attributed = TapCuts()
    /// The fallback should the phone show the main thread's CPU time doesn't separate the two: every late frame a
    /// GPU miss, only near the edge, and the effect check alone to catch the rest.
    static let unattributed = TapCuts(attributes: false, near: 4, far: .max)
}

/// How one glass's four-tap budget moves: down fast where four-tap frames miss their deadline, up slowly where they
/// hold at the budget's edge, and drawn only once `still` says nothing is moving. A budget B draws four taps for a
/// frame whose committed work (`Unstirred.committedWork`) is at most B.
struct TapLaw: Equatable {
    /// What a phone keeps of a glass's law until a new build or OS, whose shader or driver may cost otherwise.
    struct Stored: Codable, Equatable {
        var applied: Int
        var cap: Int?
        var strikes: Int
        var build: String
        var os: String
        /// The glass's own static limit, so a neighbour's prior reads how far it stepped against that, not the key's.
        var limit: Int?
    }

    /// A glass learnt: its cool budget and its own static limit.
    struct Learnt: Equatable {
        let budget: Int
        let limit: Int
    }

    /// A step down waiting to be shown to have helped, and what it replaced.
    struct Check: Equatable {
        let work: Int
        let from: Int
        let cap: Int?
        let strikes: Int
        let hot: Bool
        /// On-time two-tap frames seen at work it covers.
        var held = 0
    }

    /// The frames of one drag, at one committed work and one budget.
    struct Window: Equatable {
        let work: Int
        let four: Bool
        /// Two-tap frames where a step down is waiting on its check: they say whether it helped.
        let checks: Bool
        var ring: [FrameClass] = []
        var counted = 0
        var misses = 0
        var onTime = 0
        var stepped = false
        var reverted = false
    }

    enum Event: Equatable {

        /// `strike` nil while hot.
        case down(from: Int, to: Int, work: Int, misses: Int, of: Int, strike: Int?)
        case up(from: Int, to: Int)
        case probe(to: Int)
        case erased(cap: Int)
        case reverted(from: Int, to: Int, work: Int, misses: Int, of: Int)
        case held(work: Int)
        case twoTap(work: Int, misses: Int, of: Int)
        case applied(from: Int, to: Int)
        case hot(from: Int, to: Int)
        case cool(from: Int, to: Int)
    }

    /// The fewest committed work units drawn with four taps on any glass, however it drops frames (TAPS-FLOOR).
    static let floor = 12
    /// The most: every stack the game allows on every picture (TAPS-CEIL).
    static let ceiling = Tank.maxStack + (Picture.allCases.map(\.fillEntries).max() ?? 0)
    /// Steps down still waiting on their checks, oldest first.
    static let checksKept = 8

    var cuts: TapCuts
    /// The budget the glass draws.
    private(set) var applied: Int
    /// The cool budget last drawn.
    private(set) var cool: Int
    /// The cool budget decided, drawn at the next still moment unless the phone is hot, and what a phone keeps.
    private(set) var want: Int
    /// The hot budget decided while the thermal state is serious or worse, never kept.
    private(set) var hot: Int?
    /// The lowest work that missed while cool, provisional at one strike and held at two. Always over `want`, bar a
    /// probe's provisional cap, which `want` meets, so the climb, the probe or the erase always has a way on.
    private(set) var cap: Int?
    private(set) var strikes = 0
    /// On-time four-tap frames at the budget's edge since the last miss.
    private(set) var clean = 0
    /// A provisional cap is probed once a launch.
    private(set) var probed = false
    /// An effect check failed: misses at this glass aren't the shader's, so it steps down no more this launch.
    private(set) var paused = false
    private(set) var checks: [Check] = []
    private(set) var window: Window?

    /// A cap the start meets or passes is dropped, bar a probe's single strike at it: it can't be reached from a step,
    /// and kept it would bar every way up.
    init(start: Int, cap: Int? = nil, strikes: Int = 0, cuts: TapCuts = .attributed) {
        let b = Self.clamp(start)
        let cap = cap.flatMap { $0 > b || $0 == b && strikes <= 1 ? $0 : nil }
        (applied, cool, want, self.cap, self.strikes, self.cuts) = (b, b, b, cap, cap == nil ? 0 : min(max(strikes, 1), 2), cuts)
    }

    init(stored: Stored, cuts: TapCuts = .attributed) {
        self.init(start: stored.applied, cap: stored.cap, strikes: stored.strikes, cuts: cuts)
    }

    static func clamp(_ b: Int) -> Int { min(max(b, floor), ceiling) }

    /// What `still` will draw, if it differs from what is drawn.
    var pending: Int? { (hot ?? want) == applied ? nil : hot ?? want }

    /// The cool decision, drawn or not, so a launch ended before the next still moment keeps the step with its cap.
    func stored(build: String, os: String, limit: Int? = nil) -> Stored {
        Stored(applied: want, cap: cap, strikes: strikes, build: build, os: os, limit: limit)
    }

    /// The interval of `d` seconds against a granted period of `t`, in which the main thread ran for `c` seconds.
    /// Busy for all but half a period, the main thread missed it; idle for at least half, it waited on the frames
    /// ahead, which on a frame of steady work is the GPU's.
    static func classify(interval d: Double, period t: Double, cpu c: Double, produced: Bool,
                         cuts: TapCuts = .attributed) -> FrameClass {
        guard produced, t > 0 else { return .ignored }
        guard d > cuts.late * t else { return .onTime }
        guard d <= cuts.hitch * t else { return .ignored }
        guard cuts.attributes else { return .gpuMiss }
        if c >= d - t / 2 { return .cpuMiss }
        return c <= d / 2 ? .gpuMiss : .ignored
    }

    /// The budget a glass starts from with nothing learnt for it: its own static limit, lowered by the share the
    /// nearest glass learnt at the same rate stepped below that glass's static limit. A neighbour never raises it nor
    /// replaces it, as the static limits keep Jack's calls (taps-keep = C on phones, duocap2 = D past 1300 px), which no
    /// rescale between sizes reproduces.
    static func prior(_ key: TapKey, pixels: Double, learnt: [TapKey: Learnt]) -> (budget: Int, from: TapKey?) {
        let own = clamp(Tank.fourTaps(pixels: pixels))
        let near = learnt.keys.filter { $0.hz == key.hz && $0 != key }
            .min { (abs($0.px - key.px), $0.px) < (abs($1.px - key.px), $1.px) }
        guard let near, let l = learnt[near] else { return (own, nil) }
        let theirs = clamp(l.limit)
        guard l.budget < theirs else { return (own, nil) }
        return (clamp(Int((Double(own) * Double(l.budget) / Double(theirs)).rounded(.down))), near)
    }

    /// Two-tap frames at `work` cost no more than the four-tap ones that missed at `c`'s work, give or take the edge's
    /// few entries, so if they miss as often the misses weren't the shader's.
    private func covers(_ c: Check, _ work: Int) -> Bool { work <= c.work + cuts.edge }

    /// A drag begins at committed work `work`.
    mutating func open(work: Int) {
        let four = work <= applied
        window = Window(work: work, four: four, checks: !four && checks.contains { covers($0, work) })
    }

    /// One frame of the open window.
    mutating func count(_ c: FrameClass) -> Event? {
        guard var w = window, c != .ignored else { return nil }
        defer { window = w }
        w.counted += 1
        w.ring.append(c)
        if w.ring.count > cuts.ring { w.ring.removeFirst() }
        if c == .gpuMiss { w.misses += 1 }
        if c == .onTime { w.onTime += 1 }
        let missing = w.ring.filter { $0 == .gpuMiss }.count
        if w.checks {
            guard missing >= cuts.near, !w.reverted, let i = checks.firstIndex(where: { covers($0, w.work) }) else { return nil }
            w.reverted = true
            return revert(i, work: w.work, misses: missing, of: w.ring.count)
        }
        guard w.four else { return nil }
        switch c {
        case .onTime:
            guard hot == nil, want == applied, w.work >= applied - 1 else { return nil }
            clean += 1
            return climb()
        case .gpuMiss:
            clean = 0
            let due = w.work >= applied - cuts.edge ? cuts.near : hot != nil ? cuts.far : Int.max
            guard missing >= due, !w.stepped, !paused else { return nil }
            let b = hot ?? want, to = max(Self.floor, min(b, w.work - 1))
            // Only a step that draws the missed work with two taps changes the frames that missed.
            guard to < b, to < w.work else { return nil }
            w.stepped = true
            checks.append(Check(work: w.work, from: b, cap: cap, strikes: strikes, hot: hot != nil))
            if checks.count > Self.checksKept { checks.removeFirst() }
            if hot != nil {
                hot = to
                return .down(from: b, to: to, work: w.work, misses: missing, of: w.ring.count, strike: nil)
            }
            want = to
            if cap.map({ w.work < $0 }) ?? true {
                (cap, strikes) = (w.work, 1)
            } else if cap == w.work {
                strikes = min(strikes + 1, 2)
            }
            return .down(from: b, to: to, work: w.work, misses: missing, of: w.ring.count, strike: strikes)
        default:
            return nil
        }
    }

    private mutating func climb() -> Event? {
        if let c = cap, strikes == 1, applied == c {
            // Held clean at the cap: the miss that set it was a passing one.
            guard clean >= cuts.climb else { return nil }
            (cap, strikes, clean) = (nil, 0, 0)
            return .erased(cap: c)
        }
        if applied < Self.ceiling, cap.map({ applied + 1 < $0 }) ?? true, clean >= cuts.climb {
            (want, clean) = (applied + 1, 0)
            return .up(from: applied, to: want)
        }
        if let c = cap, strikes == 1, applied + 1 == c, !probed, clean >= cuts.probe {
            (want, probed, clean) = (c, true, 0)
            return .probe(to: c)
        }
        return nil
    }

    /// Takes back the oldest step the window's frames cover, and every step since, which it decided from.
    private mutating func revert(_ i: Int, work: Int, misses: Int, of n: Int) -> Event {
        let c = checks[i], from = c.hot ? hot ?? want : want
        if c.hot { hot = c.from } else { (want, cap, strikes) = (c.from, c.cap, c.strikes) }
        checks.removeSubrange(i...)
        paused = true
        return .reverted(from: from, to: c.from, work: work, misses: misses, of: n)
    }

    /// The drag ends.
    mutating func close() -> Event? {
        guard let w = window else { return nil }
        window = nil
        if w.checks {
            guard !w.reverted else { return nil }
            for i in checks.indices where covers(checks[i], w.work) { checks[i].held += w.onTime }
            let n = checks.count
            checks.removeAll { $0.held >= cuts.hold }
            return checks.count < n ? .held(work: w.work) : nil
        }
        return !w.four && w.misses > 0 ? .twoTap(work: w.work, misses: w.misses, of: w.counted) : nil
    }

    /// Nothing is moving: what is pending is drawn. Never while a window is open, so no drag changes its taps.
    mutating func still() -> Event? {
        guard window == nil, let to = pending else { return nil }
        let from = applied
        applied = to
        if hot == nil { cool = to }
        clean = 0
        return .applied(from: from, to: to)
    }

    /// The phone's thermal state changed: serious or worse takes a quarter off the cool budget, critical goes to the
    /// floor, and cooler gives the cool budget back.
    mutating func heat(_ state: ProcessInfo.ThermalState) -> Event? {
        switch state {
        case .serious, .critical:
            let to = state == .critical ? Self.floor : max(Self.floor, want - (want + 3) / 4)
            guard hot != to else { return nil }
            let from = hot ?? want
            hot = to
            return .hot(from: from, to: to)
        default:
            guard let h = hot else { return nil }
            hot = nil
            checks.removeAll(where: \.hot)
            return .cool(from: h, to: want)
        }
    }
}
