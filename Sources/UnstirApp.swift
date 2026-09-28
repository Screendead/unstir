import SwiftUI

@main
struct UnstirApp: App {
    init() { Log.write("launch") }

    var body: some Scene {
        WindowGroup { RootView() }
    }
}

/// Launch-time state for screenshots without touch (set via SIMCTL_CHILD_UNSTIR_*).
struct Harness {
    let screen: String
    let level: Level
    let live: (rod: Int, steps: Double)?
    let hint: Bool
    /// Skip the opening so shots land on a settled tank; UNSTIR_OPEN=1 (or v1's UNSTIR_STIR=1) keeps it.
    let still: Bool
    let unlock: Bool
    let autoplay: Bool
    let bench: Bool
    /// UNSTIR_WAVE=r: solve, then hold the solve wave at radius r (tank units).
    let wave: Double?
    /// UNSTIR_CLOCK=s: hold the nightmare background s seconds in.
    let clock: Double?
    /// UNSTIR_TOUR: menu, then level 01, then back, for filming the cross-fades.
    let tour: Bool

    init(_ env: [String: String]) {
        // UNSTIR_PLUS: Nightmare+, which is nightmare with its second toggle on.
        let plus = env["UNSTIR_PLUS"] == "1", nightmare = plus || env["UNSTIR_NIGHTMARE"] == "1"
        // Written whenever the harness runs, so a nightmare shot does not leave the next menu shot in nightmare.
        if env.keys.contains(where: { $0.hasPrefix("UNSTIR_") }) {
            UserDefaults.standard.set(nightmare, forKey: "nightmare")
            UserDefaults.standard.set(plus, forKey: "nightmarePlus")
        }
        bench = env["UNSTIR_BENCH"] == "1"
        wave = env["UNSTIR_WAVE"].flatMap(Double.init)
        clock = env["UNSTIR_CLOCK"].flatMap(Double.init)
        tour = env["UNSTIR_TOUR"] == "1"
        let opensLevel = bench || ["LEVEL", "MODE", "STACK", "WAVE"].contains { env["UNSTIR_\($0)"] != nil }
        screen = env["UNSTIR_SCREEN"] ?? (opensLevel ? "level" : "menu")
        let n = min(max(Int(env["UNSTIR_LEVEL"] ?? "") ?? 1, 1), Level.all.count)
        var level = switch env["UNSTIR_MODE"] ?? env["UNSTIR_LEVEL"] {
        case "daily": Level.daily()
        case "endless": Level.endless(Run(seed: 7))
        case "sandbox": Level.sandbox
        default: (plus ? Level.nightmarePlus : nightmare ? Level.nightmare : Level.all)[n - 1]
        }
        let picture = env["UNSTIR_PICTURE"].flatMap(Picture.init(rawValue:))
        if bench {
            // UNSTIR_DEPTH overrides. A live picture's heaviest frame is the most entries that keep four taps, and the drag.
            let p = picture ?? (plus ? .glassPlus : nightmare ? .glass : .grid)
            let depth = env["UNSTIR_DEPTH"].flatMap(Int.init) ?? (p.isLive ? 30 - p.fillEntries : 24)
            var rng = SplitMix64(state: 24)
            // UNSTIR_PLUS: an N+ id, like the twin's own levels.
            level = Level(id: plus ? "N+bench" : "bench", label: "bn", title: "Bench: mixed sizes, depth \(depth)", picture: p,
                          layout: .eye, scramble: Layout.eye.scramble(depth: depth, inversions: 6, rng: &rng))
        }
        if let picture { level.picture = picture }
        if let s = env["UNSTIR_STACK"] {
            level.layout = env["UNSTIR_LAYOUT"].flatMap(Layout.init(rawValue:)) ?? level.layout
            level.scramble = .parse(s, in: level.layout)
        }
        self.level = level
        let f = env["UNSTIR_LIVE"]?.split(separator: ":") ?? []
        if f.count == 2, let rod = Int(f[0]), level.layout.rods.indices.contains(rod), let steps = Double(f[1]) {
            live = (rod, steps)
        } else {
            live = nil
        }
        hint = env["UNSTIR_HINT"] == "1"
        still = env.keys.contains { $0.hasPrefix("UNSTIR_") } && env["UNSTIR_OPEN"] != "1" && env["UNSTIR_STIR"] != "1"
        unlock = env["UNSTIR_UNLOCK"] == "1"
        autoplay = env["UNSTIR_AUTOPLAY"] == "1"
    }
}

/// UNSTIR_BENCH: turns a rod every frame for 20 s, as a drag that never stops would, then prints the frame intervals.
/// Display-link intervals show main-thread stalls, not frames the render server or GPU drops after the callback.
@MainActor
final class Bench: NSObject {
    private var drive: ((Double) -> Void)?
    /// A live picture: lets go after the drag, then times 20 s more with nothing driven but the background's clock.
    private let still: (() -> Void)?
    private var first = 0.0, last = 0.0
    private var intervals: [Double] = []

    init(drive: @escaping (Double) -> Void, still: (() -> Void)? = nil) {
        self.drive = drive
        self.still = still
    }

    func start() {
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 120, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
    }

    @objc private func tick(_ link: CADisplayLink) {
        if first == 0 { first = link.timestamp } else { intervals.append((link.timestamp - last) * 1e6) }
        last = link.timestamp
        drive?(link.timestamp - first)
        guard last - first >= 20 else { return }
        let s = intervals.sorted()
        func p(_ q: Double) -> Int { Int(s[min(Int(Double(s.count) * q), s.count - 1)]) }
        let worst = intervals.indices.max { intervals[$0] < intervals[$1] }!
        print("BENCH \(drive == nil ? "still " : "")n=\(s.count) p50=\(p(0.5))us p95=\(p(0.95))us p99=\(p(0.99))us max=\(Int(s.last!))us at frame \(worst)")
        guard drive != nil, let still else { link.invalidate(); exit(0) }
        still()
        drive = nil
        first = 0
        intervals = []
    }
}

struct RootView: View {
    @State private var level: Level?
    @State private var harness: Harness?
    @Environment(\.scenePhase) private var phase
    private let unlock: Bool

    init() {
        let h = Harness(ProcessInfo.processInfo.environment)
        _level = State(initialValue: h.screen == "menu" ? nil : h.level)
        _harness = State(initialValue: h)
        unlock = h.unlock
    }

    var body: some View {
        // The outgoing screen is black before the incoming one starts, so the two never show at once.
        let dip = AnyTransition.asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.15).delay(0.12)),
                                           removal: .opacity.animation(.easeIn(duration: 0.12)))
        ZStack {
            if let level {
                LevelView(level: level, harness: harness,
                          onExit: { show(nil) },
                          onNext: { show($0) })
                    .id(level)
                    .transition(dip)
            } else {
                MenuView(unlock: unlock) { show($0) }
                    .transition(dip)
            }
        }
        .background(Color.black)
        .onChange(of: phase) { Log.write("phase \(phase)") }
        .task {
            guard harness?.tour == true else { return }
            try? await Task.sleep(for: .seconds(1.5))
            show(Level.all[0], keep: true)
            try? await Task.sleep(for: .seconds(4))
            show(nil)
        }
    }

    private func show(_ next: Level?, keep: Bool = false) {
        if !keep { harness = nil }
        withAnimation(.easeInOut(duration: 0.25)) { level = next }
    }
}
