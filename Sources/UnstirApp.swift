// Copyright © 2026 Jack Lusher. All rights reserved.

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
    /// UNSTIR_TANK=n: the tank turned n steps, through the real path.
    let tank: Int
    /// UNSTIR_TANKLIVE=degrees: a turn of the tank held mid-drag, on top of UNSTIR_TANK.
    let tankLive: Double?
    /// UNSTIR_TOUCH=x,y: a finger down at that point of the tank (tank units, y down), not yet moved; with UNSTIR_LIVE or
    /// UNSTIR_TANKLIVE, where it went down before carrying the turn round.
    let touch: SIMD2<Double>?
    /// UNSTIR_TURNED=rod:steps: a turn committed through the real path and left open, as a finger has just let it go.
    let turned: Twist?
    let hint: Bool
    /// Skip the opening so shots land on a settled tank; UNSTIR_OPEN=1 (or v1's UNSTIR_STIR=1) keeps it.
    let still: Bool
    let autoplay: Bool
    let bench: Bool
    /// UNSTIR_WAVE=r: solve, then hold the solve wave at radius r (tank units).
    let wave: Double?
    /// UNSTIR_CLOCK=s: hold a live picture s seconds in.
    let clock: Double?
    /// UNSTIR_TOUR: menu, then level 01, then back, for filming the cross-fades.
    let tour: Bool
    /// UNSTIR_TIER=whirlpool: the tier the menu opens on, locked or not, plughole when unset. Nil on a launch without
    /// the harness, which opens on the stored tier.
    let menuTier: Tier?
    /// UNSTIR_TIERDEMO: the menu switches tiers on a timer, through the calls a finger makes.
    let tierDemo: Bool
    /// UNSTIR_TIERSPIN=angle[:fade]: the menu's list held mid-twist.
    let tierSpin: (spin: Double, fade: Double)?

    init(_ env: [String: String]) {
        // UNSTIR_LEVEL counts in UNSTIR_TIER too.
        let tier = env["UNSTIR_TIER"].flatMap(Tier.init(rawValue:)) ?? .plughole
        // UNSTIR_UNLOCK on its own is for the phone: =1 stores the developer unlock, =0 clears it, and the launch is
        // otherwise a plain one. Alongside any other UNSTIR_ variable, unset clears it too, so no shot leaves the next
        // one unlocked.
        let harnessed = env.keys.contains { $0.hasPrefix("UNSTIR_") && $0 != "UNSTIR_UNLOCK" }
        if harnessed || env["UNSTIR_UNLOCK"] != nil { Best.unlocked = env["UNSTIR_UNLOCK"] == "1" }
        menuTier = harnessed ? tier : nil
        // UNSTIR_BESTS=plughole:00-1,whirlpool:0: a best for each of a tier's levels from 01, one character each: a
        // digit is that many over par, - is none. For this launch only.
        for part in env["UNSTIR_BESTS"]?.split(separator: ",") ?? [] {
            let f = part.split(separator: ":")
            guard f.count == 2, let owner = Tier(rawValue: String(f[0])) else { continue }
            for (level, c) in zip(owner.levels, f[1]) {
                if let over = c.wholeNumberValue { Best(over: over, hints: 0, seconds: 60).fake(level.id) }
            }
        }
        tierDemo = env["UNSTIR_TIERDEMO"] == "1"
        let spin = env["UNSTIR_TIERSPIN"]?.split(separator: ":").compactMap { Double($0) } ?? []
        tierSpin = spin.first.map { ($0, spin.count > 1 ? spin[1] : 0) }
        bench = env["UNSTIR_BENCH"] == "1"
        wave = env["UNSTIR_WAVE"].flatMap(Double.init)
        clock = env["UNSTIR_CLOCK"].flatMap(Double.init)
        tour = env["UNSTIR_TOUR"] == "1"
        let opensLevel = bench || ["LEVEL", "MODE", "STACK", "WAVE"].contains { env["UNSTIR_\($0)"] != nil }
        screen = env["UNSTIR_SCREEN"] ?? (opensLevel ? "level" : "menu")
        let n = min(max(Int(env["UNSTIR_LEVEL"] ?? "") ?? 1, 1), tier.levels.count)
        var level = switch env["UNSTIR_MODE"] ?? env["UNSTIR_LEVEL"] {
        case "daily": Level.daily()
        case "endless": Level.endless(Run(seed: 7))
        case "sandbox": Level.sandbox
        default: tier.levels[n - 1]
        }
        let picture = env["UNSTIR_PICTURE"].flatMap(Picture.init(rawValue:))
        if bench {
            // UNSTIR_DEPTH overrides. A live picture's heaviest frame is the most entries that keep four taps, and the drag.
            let p = picture ?? tier.levels[0].picture
            let depth = env["UNSTIR_DEPTH"].flatMap(Int.init) ?? (p.isLive ? 30 - p.fillEntries : 24)
            var rng = SplitMix64(state: 24)
            level = Level(id: "bench", tier: tier, label: "bn", title: "Bench: mixed sizes, depth \(depth)", picture: p,
                          layout: .eye, scramble: Layout.eye.scramble(depth: depth, inversions: 6, rng: &rng))
        }
        if let picture { level.picture = picture }
        if let s = env["UNSTIR_STACK"] {
            level.layout = env["UNSTIR_LAYOUT"].flatMap(Layout.init(rawValue:)) ?? level.layout
            level.scramble = .parse(s, in: level.layout)
        }
        // UNSTIR_SEIZED=1,4: those knobs seized.
        if let s = env["UNSTIR_SEIZED"] {
            level.seized = Set(s.split(separator: ",").compactMap { Int($0) }.filter(level.layout.rods.indices.contains))
        }
        self.level = level
        tank = env["UNSTIR_TANK"].flatMap(Int.init) ?? 0
        tankLive = env["UNSTIR_TANKLIVE"].flatMap(Double.init)
        let xy = env["UNSTIR_TOUCH"]?.split(separator: ",").compactMap { Double($0) } ?? []
        touch = xy.count == 2 ? SIMD2(xy[0], xy[1]) : nil
        let t = env["UNSTIR_TURNED"]?.split(separator: ":").compactMap { Int($0) } ?? []
        turned = t.count == 2 && level.layout.rods.indices.contains(t[0]) ? Twist(rod: t[0], steps: t[1]) : nil
        let f = env["UNSTIR_LIVE"]?.split(separator: ":") ?? []
        if f.count == 2, let rod = Int(f[0]), level.layout.rods.indices.contains(rod), let steps = Double(f[1]) {
            live = (rod, steps)
        } else {
            live = nil
        }
        hint = env["UNSTIR_HINT"] == "1"
        still = harnessed && env["UNSTIR_OPEN"] != "1" && env["UNSTIR_STIR"] != "1"
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
        let heat = ["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue]
        print("BENCH \(drive == nil ? "still " : "")n=\(s.count) p50=\(p(0.5))us p95=\(p(0.95))us p99=\(p(0.99))us max=\(Int(s.last!))us at frame \(worst) \(heat)")
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

    init() {
        let h = Harness(ProcessInfo.processInfo.environment)
        _level = State(initialValue: h.screen == "menu" ? nil : h.level)
        _harness = State(initialValue: h)
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
                MenuView(start: harness?.menuTier, demo: harness?.tierDemo ?? false, frozen: harness?.tierSpin) {
                    show($0)
                }
                .transition(dip)
            }
        }
        .background(Color.black)
        .onChange(of: phase) { Log.write("phase \(phase)") }
        .task {
            guard harness?.tour == true else { return }
            try? await Task.sleep(for: .seconds(1.5))
            show(Level.plughole[0], keep: true)
            try? await Task.sleep(for: .seconds(4))
            show(nil)
        }
    }

    private func show(_ next: Level?, keep: Bool = false) {
        if !keep { harness = nil }
        withAnimation(.easeInOut(duration: 0.25)) { level = next }
    }
}
