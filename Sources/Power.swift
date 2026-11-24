// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import UIKit.UIGestureRecognizerSubclass

/// When decoration gives way: the phone asks the app to spend less (Low Power Mode, or a thermal state of serious or
/// worse), or nobody has touched the screen for `idleAfter`.
@MainActor @Observable
final class Power {
    static let shared = Power()
    static let idleAfter = Duration.seconds(20)
    private(set) var saving = Power.saving(lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled,
                                           thermal: ProcessInfo.processInfo.thermalState)
    private(set) var idle = false
    /// Still water (`Calm`): how far the slope's menu has gone still, and whether that is changing now.
    private(set) var calm = Calm()
    private(set) var turning = false
    @ObservationIgnored private var turned: Task<Void, Never>?
    #if DEBUG
    /// UNSTIR_EGG=still: idle this soon, for its shot and film.
    @ObservationIgnored var idleSooner: Duration?
    #endif
    @ObservationIgnored private var waking: Task<Void, Never>?
    @ObservationIgnored private var watching = false
    @ObservationIgnored private var thermal = ProcessInfo.processInfo.thermalState

    /// How warm the phone says it is and whether it is on a charger, for the log.
    var heat: String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let power = switch UIDevice.current.batteryState {
        case .unplugged: "unplugged"
        case .charging: "charging"
        case .full: "full"
        default: "unknown"
        }
        return "thermal \(Self.name(ProcessInfo.processInfo.thermalState)), power \(power)"
    }

    nonisolated static func name(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
    }

    nonisolated static func saving(lowPower: Bool, thermal: ProcessInfo.ThermalState) -> Bool {
        lowPower || thermal.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    }

    private init() {
        for name in [Notification.Name.NSProcessInfoPowerStateDidChange, ProcessInfo.thermalStateDidChangeNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { Power.shared.update() }
            }
        }
        touched()
    }

    private func update() {
        let state = ProcessInfo.processInfo.thermalState
        if state != thermal {
            thermal = state
            Log.write(heat)
        }
        let now = Self.saving(lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled, thermal: ProcessInfo.processInfo.thermalState)
        guard now != saving else { return }
        saving = now
        Log.write("power \(now ? "saving" : "normal")")
    }

    /// A finger came down: the idle clock starts again.
    func touched() {
        if idle {
            idle = false
            turn(to: 0)
        }
        waking?.cancel()
        waking = Task { [weak self] in
            var wait = Self.idleAfter
            #if DEBUG
            wait = self?.idleSooner ?? wait
            #endif
            guard (try? await Task.sleep(for: wait)) != nil else { return }
            self?.idle = true
            self?.turn(to: 1)
        }
    }

    private func turn(to level: Double) {
        calm = calm.turned(to: level, at: .now)
        turning = true
        turned?.cancel()
        turned = Task { [weak self] in
            guard let self, (try? await Task.sleep(for: .seconds(calm.span))) != nil else { return }
            turning = false
        }
    }

    /// Sees every touch in the app's window, once.
    func watch() {
        guard !watching, let window = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.windows.first }).first
        else { return }
        watching = true
        window.addGestureRecognizer(TouchWatch())
    }
}

/// Still water: left alone for `Power.idleAfter`, the slope's menu goes still and clear over `settle` seconds, its
/// clock slowing to a stop, and a touch brings it back over `wake`. One turn of that, from a level to 0 or 1, and the
/// clock's seconds lost to the stillness before it, so a ground reads both for any moment with no state of its own.
struct Calm {
    static let settle = 4.4, wake = 0.85
    var at = Date.distantPast
    var from = 0.0, to = 0.0
    var lost = 0.0

    var span: Double { to > from ? Self.settle : Self.wake }

    private static func ease(_ x: Double) -> Double { x * x * (3 - 2 * x) }

    func level(_ date: Date) -> Double {
        from + (to - from) * Self.ease(min(max(date.timeIntervalSince(at) / span, 0), 1))
    }

    /// The seconds a clock that runs at `1 - level` has lost by `date`.
    func lost(_ date: Date) -> Double {
        let u = max(date.timeIntervalSince(at), 0), x = min(u / span, 1)
        return lost + from * u + (to - from) * (span * (x * x * x - x * x * x * x / 2) + max(u - span, 0))
    }

    func turned(to level: Double, at date: Date) -> Calm {
        Calm(at: date, from: self.level(date), to: level, lost: lost(date))
    }
}

/// Notes each touch as it lands and fails at once, so it never takes part in a gesture or holds a touch back.
private final class TouchWatch: UIGestureRecognizer {
    init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        Power.shared.touched()
        state = .failed
    }
}

/// An animation timeline whose clock, in seconds since the reference date less the time spent paused, stops while
/// `paused` and carries on from where it stopped, so a loop picks up on the frame it held, never the wall clock's.
struct PausingTimeline<Content: View>: View {
    let interval: Double?
    let paused: Bool
    let content: (Double) -> Content
    @State private var lost = 0.0
    /// When the pause in progress began.
    @State private var since: Double?
    @State private var halted: Bool

    init(interval: Double? = nil, paused: Bool, @ViewBuilder content: @escaping (Double) -> Content) {
        self.interval = interval
        self.paused = paused
        self.content = content
        _halted = State(initialValue: paused)
        _since = State(initialValue: paused ? Date.now.timeIntervalSinceReferenceDate : nil)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: interval, paused: halted)) { tl in
            let now = tl.date.timeIntervalSinceReferenceDate
            // Held at the pause's own moment, whatever date a paused timeline hands a redraw.
            content((halted ? since ?? now : now) - lost)
        }
        .onAppear {
            lost = 0
            since = halted ? Date.now.timeIntervalSinceReferenceDate : nil
        }
        .onChange(of: paused) {
            let now = Date.now.timeIntervalSinceReferenceDate
            if paused { since = now } else if let since { lost += now - since; self.since = nil }
            halted = paused
        }
    }
}
