// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

/// One stack entry: `steps` is a nonzero count of 30-degree turns on `rod`.
struct Twist: Hashable {
    var rod: Int
    var steps: Int
}

/// Tank geometry in normalized coordinates: tank radius 1, centre at the origin, y down.
enum Tank {
    static let step = Double.pi / 6
    static let coreRadius = 0.07
    /// Inside plateau * radius a disc turns rigidly; all shear lives in the ring out to its edge, so each twist leaves
    /// one seam and the newest seam is the unbroken one. Every layout keeps its rigid cores clear of each other at 0.6.
    static let plateau = 0.6
    /// Pushes past this are refused: every pixel runs each shader tap through every entry, plus the live twist.
    static let maxStack = 36
    /// Committed entries the shader runs four taps through, less a live picture's fill; past it, two.
    static let fourTaps = 30

    /// Rotation fraction at s = |p - c| / radius. The Metal shader carries the same function.
    static func profile(_ s: Double) -> Double {
        let t = min(max((s - plateau) / (1 - plateau), 0), 1)
        return 1 - t * t * (3 - 2 * t)
    }

    /// Positive angle turns clockwise on screen. The inverse is the same call with -angle.
    static func twist(_ p: SIMD2<Double>, rod: SIMD3<Double>, angle: Double) -> SIMD2<Double> {
        let c = SIMD2(rod.x, rod.y)
        let d = p - c
        let s = simd_length(d) / rod.z
        // Untouched outside the disc, as the shader leaves it: merges rely on rods that miss a point fixing it exactly.
        guard s < 1 else { return p }
        let a = angle * profile(s)
        return c + SIMD2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a))
    }

    /// Centres of an n-by-n grid of cells across the tank, those inside it.
    static func grid(_ n: Int) -> some Sequence<SIMD2<Double>> {
        let cell = 2 / Double(n)
        return (0..<n * n).lazy.map { i -> SIMD2<Double> in (SIMD2(Double(i % n), Double(i / n)) + 0.5) * cell - 1 }
            .filter { simd_length($0) < 1 }
    }

    /// ponytail: merges judge commutation on a 100-by-100 grid to 1e-6 tank radii, so a difference confined between grid
    /// points merges anyway; sample finer if one ever shows. Shuffled, so a failing test usually exits within a few points.
    static let samples: [SIMD2<Double>] = {
        var rng = SplitMix64(state: 0)
        return grid(100).shuffled(using: &rng)
    }()

    /// ponytail: a stack looks solved when no point of a 2 px grid (tank radius ~568 px) moves half a pixel; a residual
    /// narrower than the grid slips through, which the eye misses too.
    static let pixelGrid = 568, halfPixel = 0.5 / 568
}

/// Rod arrangements; `eye` is the mixed-sizes one. Every disc stays inside the tank, so nothing is stirred through the glass.
enum Layout: String, CaseIterable {
    case tri, quad, eye, pent, hex

    /// (x, y, disc radius) per rod.
    var rods: [SIMD3<Double>] { Layout.table[self]! }

    private static let table: [Layout: [SIMD3<Double>]] = {
        func ring(_ n: Int, _ r: Double, _ radius: Double, from a0: Double = -90) -> [SIMD3<Double>] {
            (0..<n).map { k in
                let a = (a0 + 360 * Double(k) / Double(n)) * .pi / 180
                return SIMD3(r * cos(a), r * sin(a), radius)
            }
        }
        return [
            .tri: ring(3, 0.42, 0.58),
            .quad: ring(4, 0.5, 0.48, from: -45),
            .eye: [SIMD3(-0.4, 0, 0.58), SIMD3(0.4, 0, 0.58), SIMD3(0, -0.56, 0.44), SIMD3(0, 0.56, 0.44)],
            .pent: ring(5, 0.56, 0.44),
            .hex: [SIMD3(0, 0, 0.44)] + ring(6, 0.56, 0.44),
        ]
    }()

    /// Steps in one full turn of the tank. A step is the layout's rotational symmetry (hex's hub held still), so it sets
    /// every rod's fluid down on a rod of the same size.
    var order: Int {
        switch self {
        case .tri: 3
        case .quad: 4
        case .eye: 2
        case .pent: 5
        case .hex: 6
        }
    }
    var tankStep: Double { 2 * .pi / Double(order) }

    /// After one step of the tank clockwise, knob k sits over the fluid that rod `behind[k]` stirs.
    private var behind: [Int] {
        switch self {
        case .tri: [2, 0, 1]
        case .quad: [3, 0, 1, 2]
        case .eye: [1, 0, 3, 2]
        case .pent: [4, 0, 1, 2, 3]
        case .hex: [0, 6, 1, 2, 3, 4, 5]
        }
    }

    /// The rod whose fluid sits under knob k with the tank `position` steps clockwise of home: the stack names that rod.
    func slot(of knob: Int, at position: Int) -> Int {
        (0..<(position % order + order) % order).reduce(knob) { k, _ in behind[k] }
    }

    /// The knob over rod `slot`'s fluid.
    func knob(over slot: Int, at position: Int) -> Int { self.slot(of: slot, at: -position) }

    func overlaps(_ i: Int, _ j: Int) -> Bool {
        let a = rods[i], b = rods[j]
        return i == j || simd_distance(SIMD2(a.x, a.y), SIMD2(b.x, b.y)) < a.z + b.z
    }

    /// Indices of the entries whose inverse would cancel right now: the inverse lands on them.
    func removable(_ stack: [Twist]) -> [Int] {
        stack.indices.filter { stack.landing(rod: stack[$0].rod, steps: -stack[$0].steps, in: self) == $0 }
    }

    /// Whether the entries above index i commute with a turn of `rod` by `steps`, so the turn can merge into entry i.
    func commutes(_ stack: [some Stacked], above i: Int, rod: Int, steps: Int) -> Bool {
        let above = stack[(i + 1)...].map(\.twist)
        if above.allSatisfy({ !overlaps($0.rod, rod) }) { return true }
        // Overlapping rods can still commute exactly (a word can hold a whole disc still), and only the maps show it.
        let turn = Twist(rod: rod, steps: steps)
        return same(above + [turn], [turn] + above, at: Tank.samples, within: 1e-6)
    }

    /// Whether the stack leaves the picture looking unstirred.
    func looksSolved(_ stack: [Twist]) -> Bool {
        // The coarse pass first, so a stirred tank exits within a few points.
        same(stack, [], at: Tank.samples, within: Tank.halfPixel)
            && same(stack, [], at: Tank.grid(Tank.pixelGrid), within: Tank.halfPixel)
    }

    /// Whether words a and b, each applied bottom first, send every point within `tolerance` of each other.
    func same(_ a: [Twist], _ b: [Twist], at points: some Sequence<SIMD2<Double>>, within tolerance: Double) -> Bool {
        let rods = self.rods
        func map(_ word: [Twist], _ p: SIMD2<Double>) -> SIMD2<Double> {
            word.reduce(p) { Tank.twist($0, rod: rods[$1.rod], angle: Double($1.steps) * Tank.step) }
        }
        return points.allSatisfy { simd_distance(map(a, $0), map(b, $0)) <= tolerance }
    }
}

enum Commit { case pushed, reduced, cancelled, refused }

/// What a stack holds: a twist, and whatever rides along with it. A turn that merges keeps the entry it lands on, so
/// what rides with that entry stays.
protocol Stacked {
    var twist: Twist { get set }
}

extension Twist: Stacked {
    var twist: Twist {
        get { self }
        set { self = newValue }
    }
}

extension Array where Element: Stacked {
    /// The rod's newest entry that everything above it commutes with the turn: where the turn merges.
    func landing(rod: Int, steps: Int, in layout: Layout) -> Int? {
        indices.reversed().first { self[$0].twist.rod == rod && layout.commutes(self, above: $0, rod: rod, steps: steps) }
    }

    /// Merges into the landing entry, popping at zero; otherwise pushes. `popped` is handed every entry that merges to
    /// nothing, whether the turn lands on it or an entry the merge lets fall does.
    @discardableResult
    mutating func commit(_ entry: Element, in layout: Layout, popped: (Element) -> Void = { _ in }) -> Commit {
        guard entry.twist.steps != 0 else { return .refused }
        if let i = landing(rod: entry.twist.rod, steps: entry.twist.steps, in: layout) {
            // A merge under an overlapping rod changes what the entries above it were checked against, so the merged
            // entry and everything above go back on in order and merge wherever they now can.
            var rest = Array(self[i...])
            rest[0].twist.steps += entry.twist.steps
            removeSubrange(i...)
            let merged: Commit
            if rest[0].twist.steps == 0 {
                popped(rest[0])
                merged = .cancelled
            } else {
                merged = commit(rest[0], in: layout, popped: popped)
            }
            for t in rest.dropFirst() { commit(t, in: layout, popped: popped) }
            return merged == .cancelled ? .cancelled : .reduced
        }
        guard count < Tank.maxStack else { return .refused }
        append(entry)
        return .pushed
    }
}

extension Array where Element == Twist {
    @discardableResult
    mutating func commit(rod: Int, steps: Int, in layout: Layout) -> Commit {
        commit(Twist(rod: rod, steps: steps), in: layout)
    }

    /// "0:+3,1:-6" -> [(0,3),(1,-6)], committed in order so entries that can merge do.
    static func parse(_ s: String, in layout: Layout) -> [Twist] {
        var stack: [Twist] = []
        for part in s.split(separator: ",") {
            let f = part.split(separator: ":")
            if f.count == 2, let r = Int(f[0]), layout.rods.indices.contains(r),
               let n = Int(f[1]) {
                stack.commit(rod: r, steps: n, in: layout)
            }
        }
        return stack
    }
}
