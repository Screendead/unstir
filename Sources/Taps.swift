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

    /// UNSTIR_TAPS: n pins the budget, watch:n pins it and logs every drag, adapt runs the law storing nothing (adapt:n
    /// from n). Unset, a plain launch on a phone runs the law and keeps what it learns; the harness, the test host and
    /// the simulator, whose frames say nothing of a phone's GPU, draw the static limit, so no shot depends on timing.
    nonisolated static func mode(env: [String: String], harnessed: Bool, simulator: Bool) -> Mode {
        let f = env["UNSTIR_TAPS"]?.split(separator: ":").map(String.init) ?? []
        let n = f.count > 1 ? Int(f[1]) : nil
        switch f.first {
        case "adapt"?: return .adapt(from: n, stores: false)
        case "watch"? where n != nil: return .watch(n!)
        case let s? where f.count == 1 && Int(s) != nil: return .pinned(Int(s)!)
        default:
            return harnessed || simulator || env["XCTestConfigurationFilePath"] != nil ? .off : .adapt(from: nil, stores: true)
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
    /// Each glass's budget once `still` has drawn a new one: observed, so the glass draws it then and only then.
    private var drawn: [TapKey: Int] = [:]
    @ObservationIgnored private var laws: [TapKey: TapLaw] = [:]
    /// The cool budgets learnt this launch or kept from earlier ones, which a new glass's prior scales from.
    @ObservationIgnored private var learnt: [TapKey: Int] = [:]
    /// The drag being measured, at the budget it draws, and why its frames say nothing, if they don't.
    private struct Open {
        let key: TapKey
        let window: TapWindow
        let budget: Int
        let four: Bool
        var tally = Tally()
        let frozen: String?
    }

    @ObservationIgnored private var open: Open?
    @ObservationIgnored private var queued: [String] = []
    @ObservationIgnored private let watch = FrameWatch()
    @ObservationIgnored private var posedAt = -Double.infinity
    @ObservationIgnored private var hzRead: Int?
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

    private init() {
        watch.report = { [weak self] in self?.frame($0) }
        NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { Taps.shared.heat(ProcessInfo.processInfo.thermalState) }
        }
    }

    func configure(env: [String: String], harnessed: Bool) {
        #if targetEnvironment(simulator)
        let simulator = true
        #else
        let simulator = false
        #endif
        mode = Self.mode(env: env, harnessed: harnessed, simulator: simulator)
        if stores { learnt = Self.learnt(in: .standard, build: build, os: os) }
    }

    private var stores: Bool { if case .adapt(_, true) = mode { true } else { false } }
    private var measures: Bool { if case .watch = mode { true } else { adapts } }
    private var adapts: Bool { if case .adapt = mode { true } else { false } }
    /// Every drag's line, not only those that missed.
    private var verbose: Bool { if case .adapt(_, true) = mode { false } else { mode != .off } }

    /// The budget the glass `pixels` across draws, nil for its static limit.
    func budget(pixels: Double) -> Int? {
        switch mode {
        case .off: nil
        case .pinned(let n), .watch(let n): n
        case .adapt: pixels > 0 ? drawn[key(pixels)] ?? law(key(pixels), pixels: pixels).applied : nil
        }
    }

    /// The device line's: each glass's budget kept.
    var summary: String {
        guard stores else { return "\(mode)" }
        return learnt.isEmpty ? "none learnt" : learnt.keys.sorted { ($0.hz, $0.px) < ($1.hz, $1.px) }
            .map { "\($0.name) \(learnt[$0]!)" }.joined(separator: " ")
    }

    private var hz: Int {
        if let hzRead { return hzRead }
        let screen = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
        guard let n = screen?.maximumFramesPerSecond, n > 0 else { return 60 }
        hzRead = n
        return n
    }

    private func key(_ pixels: Double) -> TapKey { TapKey(hz: hz, pixels: pixels) }

    private func law(_ key: TapKey, pixels: Double) -> TapLaw {
        if let l = laws[key] { return l }
        var l: TapLaw, from: String
        if case .adapt(let n?, _) = mode {
            (l, from) = (TapLaw(start: n, cuts: Self.cuts), "UNSTIR_TAPS")
        } else if stores, let s = Self.load(key, from: .standard, build: build, os: os) {
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
        let key = key(w.pixels)
        if adapts {
            _ = law(key, pixels: w.pixels)
            laws[key]?.open(work: w.work)
        }
        let b = budget(pixels: w.pixels) ?? 0
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let frozen = ProcessInfo.processInfo.isLowPowerModeEnabled ? "lowpower"
            : scene?.traitCollection.sceneCaptureState == .active ? "captured" : nil
        open = Open(key: key, window: w, budget: b, four: Unstirred.drawsFourTaps(work: w.work, budget: b), frozen: frozen)
        watch.start(hz: hz)
    }

    func moved() { watch.move() }

    /// The window's glass changed size: its frames for the next second say nothing.
    func posed() { posedAt = CACurrentMediaTime() }

    /// Nothing is moving: a budget decided is drawn.
    func still(pixels: Double, _ moment: String) {
        guard adapts, pixels > 0 else { return }
        let key = key(pixels)
        _ = law(key, pixels: pixels)
        guard let e = laws[key]?.still(), let l = laws[key] else { return }
        drawn[key] = l.applied
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

    private func frame(_ f: FrameWatch.Frame) {
        guard var o = open else { return }
        defer { open = o }
        if o.tally.periods.count < 4096 { o.tally.periods.append(f.period) }
        let reason = o.frozen ?? Self.frozen(period: f.period, hz: hz, sincePose: CACurrentMediaTime() - posedAt)
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
        guard stores, let l = laws[key] else { return }
        Self.save(l.stored(build: build, os: os), key, to: .standard)
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

    func start(hz: Int) {
        stop()
        (began, last, moved, movedBefore) = (CACurrentMediaTime(), nil, false, false)
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
