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
    @ObservationIgnored private var waking: Task<Void, Never>?
    @ObservationIgnored private var watching = false

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
        let now = Self.saving(lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled, thermal: ProcessInfo.processInfo.thermalState)
        guard now != saving else { return }
        saving = now
        Log.write("power \(now ? "saving" : "normal")")
    }

    /// A finger came down: the idle clock starts again.
    func touched() {
        if idle { idle = false }
        waking?.cancel()
        waking = Task { [weak self] in
            guard (try? await Task.sleep(for: Self.idleAfter)) != nil else { return }
            self?.idle = true
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
