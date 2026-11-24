// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What the menu's ground may show beyond the slope itself: things a player finds, never told of, that reward
/// nothing (Jack's call of 2026-11-24). Only the menu hands its ground one; every other ground has none, and draws and
/// costs what it did.
///
/// - Still water: left alone for `Power.idleAfter`, the water goes flat and clear and its clock slows to a stop
///   (`Calm`), where any other ground's clock stops at once; a touch brings it back.
struct SlopeEggs: Equatable {
    /// Slope.metal's `SlopeEgg`, in its order.
    func uniforms(calm: Double) -> [Float] {
        [0, 0, Float(calm), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }

    static let none = [Float](repeating: 0, count: 16)
}

extension EnvironmentValues {
    /// The menu's water has gone still (`Calm`): what breathes on it holds.
    @Entry var slopeStill = false
}

#if DEBUG
/// UNSTIR_EGG: an egg shown without its finger, for shots and films (scripts/shots/slope-eggs.sh). Debug builds only.
///
/// - `still`: the menu idles two seconds in, not twenty.
enum SlopeEggHarness: String {
    case still

    static let wanted = ProcessInfo.processInfo.environment["UNSTIR_EGG"].flatMap(SlopeEggHarness.init(rawValue:))

    @MainActor static func start() {
        guard wanted == .still else { return }
        Power.shared.idleSooner = .seconds(2)
        Power.shared.touched()
    }
}
#endif
