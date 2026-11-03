// Copyright © 2026 Jack Lusher. All rights reserved.

import QuartzCore
import SwiftUI

/// A drag `Taps` measures: the level's glass, its committed work with what the finger holds in flight, and for the log
/// what is held and the picture.
struct TapWindow: Equatable {
    let pixels: Double
    let work: Int
    let held: String
    let picture: String
}

/// The four-tap budget the level's glass draws, learnt per glass (`TapKey`) from the frames its drags miss by `TapLaw`
/// and drawn only at a still moment. Only the look adapts: the stack's limit, what a level deals and "the tank is full"
/// are the same on every device.
@MainActor @Observable
final class Taps {
    enum Mode: Equatable, CustomStringConvertible {
        /// The glass's static limit, `Tank.fourTaps(pixels:)`, and nothing measured.
        case off
        case pinned(Int)
        /// Pinned, every drag's frames logged, never stepped.
        case watch(Int)
        /// The law, from `from` where given, else the glass's stored budget or its prior.
        case adapt(from: Int?, stores: Bool)

        var description: String {
            switch self {
            case .off: "static"
            case .pinned(let n): "pinned \(n)"
            case .watch(let n): "watch \(n)"
            case .adapt(let n, let stores): "adapt" + (n.map { " from \($0)" } ?? "") + (stores ? ", kept" : "")
            }
        }
    }

    static let shared = Taps()
    /// The law's numbers: `TapCuts.unattributed` should the phone show the main thread's CPU time can't tell the
    /// GPU's misses from its own.
    static let cuts = TapCuts.attributed
    /// Info.plist's `AdaptiveTaps`, which the build's ADAPTIVE_TAPS sets.
    nonisolated static let built = Bundle.main.object(forInfoDictionaryKey: "AdaptiveTaps") as? String == "YES"

    /// UNSTIR_TAPS: n pins the budget, watch:n pins it and logs every drag, adapt runs the law storing nothing (adapt:n
    /// from n); a value it can't read is the static limit. Unset, a plain launch on a phone of a build with
    /// ADAPTIVE_TAPS runs the law and keeps what it learns; the harness, the test host and the simulator, whose frames
    /// say nothing of a phone's GPU, draw the static limit, so no shot depends on timing.
    nonisolated static func mode(env: [String: String], harnessed: Bool, simulator: Bool, built: Bool) -> Mode {
        if let v = env["UNSTIR_TAPS"] { return parse(v) ?? .off }
        return !built || harnessed || simulator || env["XCTestConfigurationFilePath"] != nil ? .off : .adapt(from: nil, stores: true)
    }

    nonisolated static func parse(_ v: String) -> Mode? {
        let f = v.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        switch (f.first, f.count) {
        case ("adapt"?, 1): return .adapt(from: nil, stores: false)
        case ("adapt"?, 2): return Int(f[1]).map { .adapt(from: $0, stores: false) }
        case ("watch"?, 2): return Int(f[1]).map(Mode.watch)
        case (let s?, 1): return Int(s).map(Mode.pinned)
        default: return nil
        }
    }

    /// The frames of an open drag, for its log line.
    struct Tally {
        var counted = 0, gpu = 0, cpu = 0, other = 0, still = 0, skipped = 0
        var frozen: [String: Int] = [:]
        var cpus: [Double] = [], lateCPUs: [Double] = [], periods: [Double] = []
        var longest = 0.0
        var late: Int { gpu + cpu + other }

        mutating func add(_ c: FrameClass, _ f: FrameWatch.Frame, late: Bool) {
            guard f.produced else { still += 1; return }
            if cpus.count < 4096 { cpus.append(f.cpu) }
            longest = max(longest, f.interval)
            switch c {
            case .gpuMiss: gpu += 1
            case .cpuMiss: cpu += 1
            case .ignored where late: other += 1
            default: break
            }
            if c != .ignored { counted += 1 }
            if late, lateCPUs.count < 4096 { lateCPUs.append(f.cpu) }
        }

        static func median(_ v: [Double]) -> String {
            v.isEmpty ? "-" : String(format: "%.1f", 1000 * v.sorted()[v.count / 2])
        }
    }

    private(set) var mode = Mode.off
    /// What each glass, by its side to 16 px, draws: the law and budget its last still moment chose. Observed, so the
    /// glass draws a new budget then and only then, whatever the screen's rate reads meanwhile.
    private var drawn: [Int: Drawn] = [:]
    private struct Drawn: Equatable {
        let key: TapKey
        let budget: Int
    }

    @ObservationIgnored private var laws: [TapKey: TapLaw] = [:]
    /// The cool budgets learnt this launch or kept from earlier ones, which a new glass's prior scales from.
    @ObservationIgnored private var learnt: [TapKey: Int] = [:]
    /// What each glass's law last kept, so a drag that changes nothing writes nothing.
    @ObservationIgnored private var saved: [TapKey: TapLaw.Stored] = [:]
    /// The drag being measured, at the budget it draws. A class, so each frame's tally grows in place.
    private final class Open {
        let key: TapKey
        let window: TapWindow
        let budget: Int
        let four: Bool
        var tally = Tally()
        weak var scene: UIWindowScene?

        init(key: TapKey, window: TapWindow, budget: Int, four: Bool, scene: UIWindowScene?) {
            (self.key, self.window, self.budget, self.four, self.scene) = (key, window, budget, four, scene)
        }
    }

    @ObservationIgnored private var open: Open?
    @ObservationIgnored private var queued: [String] = []
    @ObservationIgnored private let watch = FrameWatch()
    @ObservationIgnored private var posedAt = -Double.infinity
    /// UNSTIR_TAPSTALL=ms: a busy main thread for that long every half second of a drag, to show it isn't the GPU's.
    @ObservationIgnored private var stall = 0.0
    /// What a kept budget belongs to: the build, by its number and its executable's timestamp, and the OS.
    @ObservationIgnored private let build: String = {
        let built = Bundle.main.executableURL.flatMap { try? $0.resourceValues(forKeys: [.contentModificationDateKey]) }?
            .contentModificationDate?.timeIntervalSince1970 ?? 0
        return "\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0")-\(Int(built))"
    }()
    @ObservationIgnored private let os: String = {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion)"
    }()

    /// The screen's top rate as it reads now.
    @ObservationIgnored private let rate: @MainActor () -> Int
    /// The highest top rate read this launch, read again only as a drag opens and at a still moment: a rate the system
    /// caps for a while (Low Power Mode) never stands for the screen's, and no key changes under a drawn glass.
    @ObservationIgnored private var hz = 0

    init(rate: @escaping @MainActor () -> Int = Taps.screenRate) {
        self.rate = rate
        watch.report = { [weak self] in self?.frame($0) }
        NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.heat(ProcessInfo.processInfo.thermalState) }
        }
    }

    static func screenRate() -> Int {
        let screen = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
        return screen.map(\.maximumFramesPerSecond).flatMap { $0 > 0 ? $0 : nil } ?? 60
    }

    func configure(env: [String: String], harnessed: Bool) {
        #if targetEnvironment(simulator)
        let simulator = true
        #else
        let simulator = false
        #endif
        if let v = env["UNSTIR_TAPS"], Self.parse(v) == nil { Log.write("taps: UNSTIR_TAPS=\(v) unread, the static limit") }
        use(Self.mode(env: env, harnessed: harnessed, simulator: simulator, built: Self.built))
        stall = (env["UNSTIR_TAPSTALL"].flatMap(Double.init) ?? 0) / 1000
    }

    func use(_ mode: Mode) {
        self.mode = mode
        if stores { learnt = Self.learnt(in: .standard, build: build, os: os) }
    }

    private var stores: Bool { if case .adapt(_, true) = mode { true } else { false } }
    private var measures: Bool { if case .watch = mode { true } else { adapts } }
    private var adapts: Bool { if case .adapt = mode { true } else { false } }
    /// Every drag's line, not only those that missed.
    private var verbose: Bool { if case .adapt(_, true) = mode { false } else { mode != .off } }

    /// The budget the glass `pixels` across draws, nil for its static limit: until its first still moment, the law's.
    func budget(pixels: Double) -> Int? {
        switch mode {
        case .off: nil
        case .pinned(let n), .watch(let n): n
        case .adapt: drawn[TapKey.side(pixels)]?.budget
        }
    }

    /// The device line's: each glass's budget kept.
    var summary: String {
        guard stores else { return "\(mode)" }
        return learnt.isEmpty ? "none learnt" : learnt.keys.sorted { ($0.hz, $0.px) < ($1.hz, $1.px) }
            .map { "\($0.name) \(learnt[$0]!)" }.joined(separator: " ")
    }

    private func key(_ pixels: Double) -> TapKey {
        hz = max(hz, rate())
        return TapKey(hz: hz, pixels: pixels)
    }

    private func law(_ key: TapKey, pixels: Double) -> TapLaw {
        if let l = laws[key] { return l }
        var l: TapLaw, from: String
        if case .adapt(let n?, _) = mode {
            (l, from) = (TapLaw(start: n, cuts: Self.cuts), "UNSTIR_TAPS")
        } else if stores, let s = Self.load(key, from: .standard, build: build, os: os) {
            saved[key] = s
            (l, from) = (TapLaw(stored: s, cuts: Self.cuts), "stored" + (s.cap.map { ", cap \($0) strikes \(s.strikes)" } ?? ""))
        } else {
            let p = TapLaw.prior(key, pixels: pixels, learnt: learnt)
            (l, from) = (TapLaw(start: p.budget, cuts: Self.cuts), p.from.map { "scaled from \($0.name)" } ?? "static")
        }
        let heat = l.heat(ProcessInfo.processInfo.thermalState)
        laws[key] = l
        Log.write("taps prior \(key.name) \(l.applied) (\(from)), \(mode)")
        if let heat { Log.write(describe(heat, key)) }
        return l
    }

    /// A drag begins or ends, or what it holds changes.
    func window(_ w: TapWindow?) {
        guard measures else { return }
        if open?.window == w { return }
        close()
        guard let w, w.pixels > 0 else { return }
        // The glass's own law, so the drag is judged at the budget it draws.
        let key = drawn[TapKey.side(w.pixels)]?.key ?? key(w.pixels)
        if adapts {
            _ = law(key, pixels: w.pixels)
            laws[key]?.open(work: w.work)
        }
        let b = budget(pixels: w.pixels) ?? Tank.fourTaps(pixels: w.pixels)
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        open = Open(key: key, window: w, budget: b, four: Unstirred.drawsFourTaps(work: w.work, budget: b), scene: scene)
        watch.start(hz: key.hz, stall: stall)
    }

    func moved() { watch.move() }

    /// The window's glass changed size: its frames for the next second say nothing.
    func posed() { posedAt = CACurrentMediaTime() }

    /// Nothing is moving: a budget decided is drawn, and the glass takes the law of the screen's rate as it now reads.
    func still(pixels: Double, _ moment: String) {
        guard adapts, pixels > 0, open == nil else { return }
        let key = key(pixels)
        _ = law(key, pixels: pixels)
        let e = laws[key]?.still()
        guard let l = laws[key] else { return }
        let now = Drawn(key: key, budget: l.applied), side = TapKey.side(pixels)
        if drawn[side] != now { drawn[side] = now }
        guard let e else { return }
        Log.write(describe(e, key) + " at \(moment)")
        if l.hot == nil { learnt[key] = l.cool }
        keep(key)
    }

    private func heat(_ state: ProcessInfo.ThermalState) {
        guard adapts else { return }
        for key in laws.keys {
            guard let e = laws[key]?.heat(state) else { continue }
            if open == nil { Log.write(describe(e, key)) } else { queued.append(describe(e, key)) }
        }
    }

    func frame(_ f: FrameWatch.Frame) {
        guard let o = open else { return }
        if o.tally.periods.count < 4096 { o.tally.periods.append(f.period) }
        let reason = ProcessInfo.processInfo.isLowPowerModeEnabled ? "lowpower"
            : o.scene?.traitCollection.sceneCaptureState == .active ? "captured"
            : Self.frozen(period: f.period, hz: o.key.hz, sincePose: CACurrentMediaTime() - posedAt)
        if let reason { o.tally.frozen[reason, default: 0] += 1; return }
        guard f.age >= Self.cuts.skip else { o.tally.skipped += 1; return }
        let c = TapLaw.classify(interval: f.interval, period: f.period, cpu: f.cpu, produced: f.produced, cuts: Self.cuts)
        o.tally.add(c, f, late: f.produced && f.interval > Self.cuts.late * f.period)
        guard adapts, let e = laws[o.key]?.count(c) else { return }
        queued.append(describe(e, o.key, o))
    }

    /// Why a frame says nothing of the GPU: the system granted less than the screen's top rate (Low Power Mode, Limit
    /// Frame Rate), or the glass changed size within the last second.
    nonisolated static func frozen(period: Double, hz: Int, sincePose: Double) -> String? {
        if period > 1.25 / Double(hz) { return "granted \(Int((1 / period).rounded())) of \(hz) Hz" }
        return sincePose < 1 ? "pose" : nil
    }

    private func close() {
        guard let o = open else { return }
        open = nil
        watch.stop()
        let decided = queued + (adapts ? laws[o.key]?.close().map { [describe($0, o.key, o)] } ?? [] : [])
        queued = []
        let t = o.tally
        if verbose || t.late > 0 || !decided.isEmpty || !t.frozen.isEmpty {
            let frozen = t.frozen.map { "\($0.key) \($0.value)" }.sorted().joined(separator: ", ")
            Log.write("taps drag \(o.key.name) \(o.window.held) B \(o.budget) Wc \(o.window.work) \(o.four ? "four" : "two")-tap: "
                      + "\(t.counted) counted, \(t.late) late (gpu \(t.gpu), cpu \(t.cpu), other \(t.other)), \(t.still) still, "
                      + "\(t.skipped) skipped\(frozen.isEmpty ? "" : ", frozen \(frozen)"), granted \(Tally.median(t.periods)) ms, "
                      + "main cpu p50 \(Tally.median(t.cpus)) ms, late \(Tally.median(t.lateCPUs)) ms, "
                      + "longest \(String(format: "%.1f", 1000 * t.longest)) ms, picture \(o.window.picture), \(Self.thermal)")
        }
        decided.forEach(Log.write)
        keep(o.key)
    }

    private func keep(_ key: TapKey) {
        guard stores, let s = laws[key]?.stored(build: build, os: os), saved[key] != s else { return }
        saved[key] = s
        Self.save(s, key, to: .standard)
    }

    private func describe(_ e: TapLaw.Event, _ key: TapKey, _ o: Open? = nil) -> String {
        let at = key.name
        switch e {
        case let .down(from, to, work, misses, of, strike):
            return "taps down \(at) \(from)->\(to) pending: \(o?.window.held ?? "") Wc \(work) four-tap, gpu \(misses)/\(of), "
                + "main cpu p50 \(Tally.median(o?.tally.cpus ?? [])) ms, picture \(o?.window.picture ?? ""), \(Self.thermal), "
                + (strike.map { "strike \($0)" } ?? "hot")
        case let .up(from, to):
            return "taps up \(at) \(from)->\(to) pending: \(Self.cuts.climb) clean at Wc >= \(from - 1)"
        case let .probe(to):
            return "taps probe \(at) \(to) pending: \(Self.cuts.probe) clean below its provisional cap, once this launch"
        case let .erased(cap):
            return "taps cap \(cap) erased \(at): \(Self.cuts.climb) clean at it"
        case let .reverted(from, to, work, misses, of):
            return "taps reverted \(at) \(from)->\(to) pending: two-tap frames at Wc \(work) still missed \(misses)/\(of); down-steps paused"
        case let .held(work):
            return "taps held \(at): two-tap frames at Wc \(work) kept time"
        case let .twoTap(work, misses, of):
            return "taps two-tap misses \(at) \(misses)/\(of) at Wc \(work), nothing to step"
        case let .applied(from, to):
            return "taps applied \(at) \(from)->\(to)"
        case let .hot(from, to):
            return "taps hot \(at) \(from)->\(to) pending: \(Self.thermal)"
        case let .cool(from, to):
            return "taps cool \(at) \(from)->\(to) pending: \(Self.thermal)"
        }
    }

    private static var thermal: String {
        "thermal " + ["nominal", "fair", "serious", "critical"][min(ProcessInfo.processInfo.thermalState.rawValue, 3)]
    }

    /// A glass's kept law, dropped once the build or the OS has changed.
    nonisolated static func load(_ key: TapKey, from d: UserDefaults, build: String, os: String) -> TapLaw.Stored? {
        guard let data = d.data(forKey: key.stored), let s = try? JSONDecoder().decode(TapLaw.Stored.self, from: data) else { return nil }
        guard s.build == build, s.os == os else { d.removeObject(forKey: key.stored); return nil }
        return s
    }

    nonisolated static func save(_ s: TapLaw.Stored, _ key: TapKey, to d: UserDefaults) {
        if let data = try? JSONEncoder().encode(s) { d.set(data, forKey: key.stored) }
    }

    /// Every glass kept for this build and OS, by its cool budget.
    nonisolated static func learnt(in d: UserDefaults, build: String, os: String) -> [TapKey: Int] {
        var all: [TapKey: Int] = [:]
        for name in d.dictionaryRepresentation().keys where name.hasPrefix("taps.") {
            let f = name.split(separator: ".").compactMap { Int($0) }
            guard f.count == 2 else { continue }
            let key = TapKey(hz: f[0], pixels: Double(f[1]))
            if let s = load(key, from: d, build: build, os: os) { all[key] = s.applied }
        }
        return all
    }
}

/// A display link alive only while a drag is measured: each interval against the period the system grants, the main
/// thread's CPU time in it, and whether the glass moved in it or the one before, as a frame drawn in one may land in
/// the next.
@MainActor
final class FrameWatch: NSObject {
    struct Frame {
        let interval: Double
        let period: Double
        let cpu: Double
        /// Seconds since the drag was taken up.
        let age: Double
        let produced: Bool
    }

    var report: (Frame) -> Void = { _ in }
    private var link: CADisplayLink?
    private var last: (time: Double, cpu: UInt64)?
    private var began = 0.0
    private var moved = false, movedBefore = false
    private var stall = 0.0, stalled = 0.0

    func start(hz: Int, stall: Double) {
        stop()
        (began, last, moved, movedBefore, self.stall) = (CACurrentMediaTime(), nil, false, false, stall)
        let link = CADisplayLink(target: self, selector: #selector(tick))
        // The rate a drag already runs at, so the link never raises the display's.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: Float(hz) / 2, maximum: Float(hz), preferred: Float(hz))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    func move() { moved = true }

    @objc private func tick(_ link: CADisplayLink) {
        let cpu = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)
        if let last {
            report(Frame(interval: link.timestamp - last.time, period: link.targetTimestamp - link.timestamp,
                         cpu: Double(cpu - last.cpu) / 1e9, age: link.timestamp - began, produced: moved || movedBefore))
        }
        (last, movedBefore, moved) = ((link.timestamp, cpu), moved, false)
        guard stall > 0, link.timestamp - stalled >= 0.5 else { return }
        stalled = link.timestamp
        let end = CACurrentMediaTime() + stall
        while CACurrentMediaTime() < end {}
    }
}

/// UNSTIR_TAPDRAG's finger: `step` with the seconds since its first frame, every frame for `seconds`.
@MainActor
final class TapDrive: NSObject {
    private let seconds: Double
    private let step: (Double) -> Void
    private let done: () -> Void
    private var first: Double?

    private init(seconds: Double, step: @escaping (Double) -> Void, done: @escaping () -> Void) {
        (self.seconds, self.step, self.done) = (seconds, step, done)
    }

    static func run(seconds: Double, _ step: @escaping (Double) -> Void) async {
        await withCheckedContinuation { (finished: CheckedContinuation<Void, Never>) in
            let drive = TapDrive(seconds: seconds, step: step) { finished.resume() }
            CADisplayLink(target: drive, selector: #selector(TapDrive.tick(_:))).add(to: .main, forMode: .common)
        }
    }

    @objc private func tick(_ link: CADisplayLink) {
        let t = link.timestamp - (first ?? link.timestamp)
        if first == nil { first = link.timestamp }
        guard t < seconds else {
            link.invalidate()
            done()
            return
        }
        step(t)
    }
}

/// LevelView's ties to `Taps`: the drag measured, each frame a finger moved the glass, and the still moments a new
/// budget lands at: a move, the level appearing, a change of pose. One handler for the drag and the moments, so a
/// let-go that lands a move closes the drag before the move is taken as still.
struct TapHooks: ViewModifier {
    struct Moment: Equatable {
        let window: TapWindow?
        let history: [Twist]
        let pixels: Double
    }

    let moment: Moment
    let motion: [Double]

    func body(content: Content) -> some View {
        content
            .onChange(of: moment, initial: true) { was, now in
                let taps = Taps.shared
                taps.window(now.window)
                if was.pixels > 0, now.pixels != was.pixels { taps.posed() }
                if was == now || was.pixels != now.pixels || was.history != now.history {
                    taps.still(pixels: now.pixels, was == now || was.pixels == 0 ? "open" : was.pixels != now.pixels ? "pose" : "move")
                }
            }
            .onChange(of: motion) { Taps.shared.moved() }
            .onDisappear { Taps.shared.window(nil) }
    }
}
