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

    /// The ephemeris: 9 x 9 cells 0.32 across from (-1.44, -1.44), a star each, then its three orbits, 28 floats a
    /// star: (x, y, temperature, reach), then per orbit (centre x, y, a, b) and (cos w, sin w, cos E, sin E), a = 0 for
    /// no orbit, b signed by the way the planet goes. The star is the orbit's focus, reach its furthest orbit's
    /// apoapsis; E is the planet's eccentric anomaly from the apoapsis at t, by Kepler's equation. A star sits within 0.3
    /// of a cell of its cell's centre and no orbit reaches past 1.1 cells from its star, so a star two cells off is at
    /// least 1.2 cells away and the 3 x 3 search sees every orbit near p. Each planet goes round a whole number of times
    /// a period, so the data repeats with it.
    static func ephemeris(seed: Int, t: Double, period: Double) -> [Float] {
        var rng = SplitMix64(state: UInt64(seed) &+ 0x5345_4C45)
        func random(_ a: Double, _ b: Double) -> Double { a + (b - a) * Double(rng.next() >> 11) * 0x1p-53 }
        let n = 9, pitch = 0.32, origin = -1.44, reach = 1.1 * pitch
        let bands = [(0.05, 0.1), (0.11, 0.19), (0.2, 0.3)]
        var f: [Float] = []
        f.reserveCapacity(28 * n * n)
        for k in 0..<n * n {
            let star = (SIMD2(Double(k % n), Double(k / n)) + 0.5 + SIMD2(random(-0.3, 0.3), random(-0.3, 0.3))) * pitch + origin
            let temperature = random(0, 1), orbits = random(0, 1) < 0.5 ? 2 : 3
            var far = 0.0, rows: [Float] = []
            for o in 0..<3 {
                let a = random(bands[o].0, bands[o].1), e = min(random(0.15, 0.7), reach / a - 1)
                let w = random(0, 2 * .pi), laps = Double([1, 2, 3, 4][Int(random(0, 4))])
                let way = random(0, 1) < 0.5 ? 1.0 : -1.0, phase = random(0, 1)
                guard o < orbits else { rows += [0, 0, 0, 0, 0, 0, 0, 0]; continue }
                let m = 2 * Double.pi * (phase + way * laps * t / period)
                var E = m
                for _ in 0..<6 { E -= (E - e * sin(E) - m) / (1 - e * cos(E)) }
                // Measured from the apoapsis, along (cos w, sin w), as the shader's ellipse frame is.
                E += .pi
                let centre = star + a * e * SIMD2(cos(w), sin(w)), b = a * (1 - e * e).squareRoot()
                far = max(far, a * (1 + e))
                rows += [Float(centre.x), Float(centre.y), Float(a), Float(way * b), Float(cos(w)), Float(sin(w)),
                         Float(cos(E)), Float(sin(E))]
            }
            f += [Float(star.x), Float(star.y), Float(temperature), Float(far)] + rows
        }
        return f
    }
}
