// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// A glass the four-tap budget is learnt for: the screen's top rate and the glass's side in pixels, to 16 px, so a
/// phone has one, or one per Display Zoom, and the Duo one per pose.
struct TapKey: Hashable {
    let hz: Int
    let px: Int

    init(hz: Int, pixels: Double) {
        self.hz = hz
        px = Int((pixels / 16).rounded()) * 16
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
    /// budget and further below it.
    var near = 3, far = 6, ring = 30, edge = 4
    /// Clean frames at the budget's edge that step it up one, and that probe a provisional cap.
    var climb = 600, probe = 1200
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
    }

    /// A step down waiting to be shown to have helped, and what it replaced.
    struct Check: Equatable {
        let work: Int
        let from: Int
        let cap: Int?
        let strikes: Int
        let hot: Bool
    }

    /// The frames of one drag, at one committed work and one budget.
    struct Window: Equatable {
        let work: Int
        let four: Bool
        /// A step down at this work has been drawn: these two-tap frames say whether it helped.
        let checks: Bool
        var ring: [FrameClass] = []
        var counted = 0
        var misses = 0
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

    var cuts: TapCuts
    /// The budget the glass draws.
    private(set) var applied: Int
    /// The cool budget last drawn, which a phone keeps.
    private(set) var cool: Int
    /// The cool budget decided, drawn at the next still moment unless the phone is hot.
    private(set) var want: Int
    /// The hot budget decided while the thermal state is serious or worse, never kept.
    private(set) var hot: Int?
    /// The lowest work that missed while cool, provisional at one strike and held at two.
    private(set) var cap: Int?
    private(set) var strikes = 0
    /// On-time four-tap frames at the budget's edge since the last miss.
    private(set) var clean = 0
    /// A provisional cap is probed once a launch.
    private(set) var probed = false
    /// An effect check failed: misses at this glass aren't the shader's, so it steps down no more this launch.
    private(set) var paused = false
    private(set) var check: Check?
    private(set) var window: Window?

    init(start: Int, cap: Int? = nil, strikes: Int = 0, cuts: TapCuts = .attributed) {
        let b = Self.clamp(start)
        (applied, cool, want, self.cap, self.strikes, self.cuts) = (b, b, b, cap, cap == nil ? 0 : min(max(strikes, 1), 2), cuts)
    }

    init(stored: Stored, cuts: TapCuts = .attributed) {
        self.init(start: stored.applied, cap: stored.cap, strikes: stored.strikes, cuts: cuts)
    }

    static func clamp(_ b: Int) -> Int { min(max(b, floor), ceiling) }

    /// What `still` will draw, if it differs from what is drawn.
    var pending: Int? { (hot ?? want) == applied ? nil : hot ?? want }

    func stored(build: String, os: String) -> Stored { Stored(applied: cool, cap: cap, strikes: strikes, build: build, os: os) }

    /// The interval of `d` seconds against a granted period of `t`, in which the main thread ran for `c` seconds.
    /// Busy for all but half a period, the main thread missed it; idle for more than half, it waited on the frames
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

    /// The budget a glass starts from with nothing learnt for it: the nearest glass learnt at the same rate, scaled by
    /// area with the entry in flight, or the static limit.
    static func prior(_ key: TapKey, pixels: Double, learnt: [TapKey: Int]) -> (budget: Int, from: TapKey?) {
        let near = learnt.keys.filter { $0.hz == key.hz && $0 != key }
            .min { (abs($0.px - key.px), $0.px) < (abs($1.px - key.px), $1.px) }
        guard let near, let b = learnt[near] else { return (clamp(Tank.fourTaps(pixels: pixels)), nil) }
        let ratio = Double(near.px) / Double(key.px)
        return (clamp(Int((Double(b + 1) * ratio * ratio).rounded()) - 1), near)
    }

    /// A drag begins at committed work `work`.
    mutating func open(work: Int) {
        window = Window(work: work, four: work <= applied, checks: check.map { $0.work == work && applied < work } ?? false)
    }

    /// One frame of the open window.
    mutating func count(_ c: FrameClass) -> Event? {
        guard var w = window, c != .ignored else { return nil }
        defer { window = w }
        w.counted += 1
        w.ring.append(c)
        if w.ring.count > cuts.ring { w.ring.removeFirst() }
        if c == .gpuMiss { w.misses += 1 }
        let missing = w.ring.filter { $0 == .gpuMiss }.count
        let due = missing >= (w.work >= applied - cuts.edge ? cuts.near : cuts.far)
        if w.checks {
            guard due, !w.reverted, let check else { return nil }
            w.reverted = true
            return revert(check, misses: missing, of: w.ring.count)
        }
        guard w.four else { return nil }
        switch c {
        case .onTime:
            guard hot == nil, want == applied, w.work >= applied - 1 else { return nil }
            clean += 1
            return climb()
        case .gpuMiss:
            clean = 0
            guard due, !w.stepped, !paused else { return nil }
            let b = hot ?? want, to = max(Self.floor, min(b, w.work - 1))
            guard to < b else { return nil }
            w.stepped = true
            check = Check(work: w.work, from: b, cap: cap, strikes: strikes, hot: hot != nil)
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

    private mutating func revert(_ c: Check, misses: Int, of n: Int) -> Event {
        let from = hot ?? want
        if c.hot { hot = c.from } else { (want, cap, strikes) = (c.from, c.cap, c.strikes) }
        (check, paused) = (nil, true)
        return .reverted(from: from, to: c.from, work: c.work, misses: misses, of: n)
    }

    /// The drag ends.
    mutating func close() -> Event? {
        guard let w = window else { return nil }
        window = nil
        if w.checks, !w.reverted, w.counted >= cuts.ring {
            check = nil
            return .held(work: w.work)
        }
        return !w.four && !w.checks && w.misses > 0 ? .twoTap(work: w.work, misses: w.misses, of: w.counted) : nil
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
            if check?.hot == true { check = nil }
            return .cool(from: h, to: want)
        }
    }
}
