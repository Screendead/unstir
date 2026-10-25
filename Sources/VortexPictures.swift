// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// The floats for the candidates for vortex's own family, per seed and time t. A pitch for Jack, not yet a family.
extension Picture {
    /// Gradient noise tables: `count` tables of 8 x 8 unit gradients (x, y), tiled. The shaders sample them at under
    /// eight cells across the tank, so no tile repeats inside it.
    static func gradients(seed: Int, salt: UInt64, count: Int) -> [Float] {
        var rng = SplitMix64(state: UInt64(seed) &+ salt)
        var f: [Float] = []
        f.reserveCapacity(128 * count)
        for _ in 0..<64 * count {
            let a = Double(rng.next() >> 11) * 0x1p-53 * 2 * .pi
            f += [Float(cos(a)), Float(sin(a))]
        }
        return f
    }
}
