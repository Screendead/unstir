// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What the menu's ground may show beyond the slope itself: things a player finds, never told of, that reward
/// nothing (Jack's call of 2026-11-24). Only the menu hands its ground one; every other ground has none, and draws and
/// costs what it did.
///
/// - Still water: left alone for `Power.idleAfter`, the water goes flat and clear and its clock slows to a stop
///   (`Calm`), where any other ground's clock stops at once; a touch brings it back.
/// - The night above: pulled down past the surface, the sky over it holds stars and the moon at `moon`.
struct SlopeEggs: Equatable {
    /// The moon: its terminator's place across the disc, 1 new to -1 full, and its lit side, 1 the trailing.
    var moon = SIMD2<Float>(1, 1)

    /// The eggs on `date`, as the player's part of the world sees its sky.
    init(_ date: Date = .now, region: Locale.Region? = Locale.current.region) {
        let south = region.map { Self.southern.contains($0.identifier) } ?? false
        let sun = Self.elongation(date)
        moon = SIMD2(Float(cos(sun)), (sun < .pi) != south ? 1 : -1)
    }

    /// Where the waxing moon is lit on the left.
    private static let southern: Set<String> = ["AU", "NZ", "ZA", "AR", "CL", "UY", "PY", "BO", "PE", "BR", "NA", "BW", "ZW", "MZ",
                                                "MG", "ZM", "AO", "TZ", "ID", "PG", "FJ", "LS", "SZ", "MW"]

    /// The moon's angle from the sun at `date`, 0 new, π full, from 0 to 2π: the mean elongation with the six largest
    /// terms of its phase angle (Meeus, Astronomical Algorithms, 48.4), within a fraction of a degree.
    static func elongation(_ date: Date) -> Double {
        let t = (date.timeIntervalSince1970 / 86400 + 2440587.5 - 2451545) / 36525, rad = Double.pi / 180
        let d = (297.8501921 + 445267.1114034 * t) * rad, m = (357.5291092 + 35999.0502909 * t) * rad
        let n = (134.9633964 + 477198.8675055 * t) * rad
        let more = -6.289 * sin(n) + 2.1 * sin(m) - 1.274 * sin(2 * d - n) - 0.658 * sin(2 * d) - 0.214 * sin(2 * n) - 0.11 * sin(d)
        let angle = (d - more * rad).truncatingRemainder(dividingBy: 2 * .pi)
        return angle < 0 ? angle + 2 * .pi : angle
    }

    /// How far the night has come out over a camera `lift` points above the surface's place.
    static func night(lift: CGFloat) -> Double {
        let x = min(max((lift - 16) / 134, 0), 1)
        return x * x * (3 - 2 * x)
    }

    /// Slope.metal's `SlopeEgg`, in its order.
    func uniforms(calm: Double, night: Double) -> [Float] {
        [Float(night), 0, Float(calm), 0, moon.x, moon.y, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
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
/// - `night`: a second in, the overview is pulled down past the surface, held five seconds and let go.
enum SlopeEggHarness: String {
    case still, night

    static let wanted = ProcessInfo.processInfo.environment["UNSTIR_EGG"].flatMap(SlopeEggHarness.init(rawValue:))

    @MainActor static func start() {
        guard wanted == .still else { return }
        Power.shared.idleSooner = .seconds(2)
        Power.shared.touched()
    }
}
#endif
