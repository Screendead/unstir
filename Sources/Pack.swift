// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// A paid set of levels, outside the tier ladder: no pack best ever opens a tier. The raw value is the pack's level-id
/// prefix and `productID` is what StoreKit sells it as; bests and purchases are kept under both, so neither ever
/// changes (UnstirTests pins them).
enum Pack: String, CaseIterable, Sendable {
    case firstStir = "first-stir", lens, escapement, prism

    var name: String {
        switch self {
        case .firstStir: "First Stir"
        case .lens: "Lens"
        case .escapement: "Escapement"
        case .prism: "Prism"
        }
    }

    var prefix: String { rawValue }

    var productID: String {
        switch self {
        case .firstStir: "com.screendead.Unstir.pack.firststir"
        case .lens: "com.screendead.Unstir.pack.lens"
        case .escapement: "com.screendead.Unstir.pack.escapement"
        case .prism: "com.screendead.Unstir.pack.prism"
        }
    }

    /// Grants every pack. A later pack joins it, so an older Complete owns it too.
    static let completeID = "com.screendead.Unstir.complete"

    static var productIDs: [String] { sold().map(\.productID) + [completeID] }

    /// Whether a Release build sells it. First Stir is out of v1, to be reworked (Jack, FS17), and Prism is a prototype
    /// until Jack calls it in; a build outside Release keeps both, so their levels, tests and films still run.
    var ships: Bool { self != .firstStir && self != .prism }

    /// The packs a build sells, and Complete grants.
    static func sold(release: Bool = Build.release) -> [Pack] { allCases.filter { !release || $0.ships } }

    /// "Lens and Escapement".
    static func named(_ packs: [Pack]) -> String {
        let names = packs.map(\.name)
        return names.count < 2 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + names.last!
    }

    /// Levels 1 to `taste` play without the pack.
    var taste: Int { 3 }

    /// How many levels its design plans; until it has them all, its card says more arrive in an update.
    var planned: Int {
        switch self {
        case .firstStir, .lens: 25
        case .escapement, .prism: 30
        }
    }

    /// Numbered from 1 by place, each the pack's own `id`; empty until the pack's content lands.
    var levels: [Level] {
        switch self {
        case .firstStir: Level.firstStir
        case .lens: Level.lens
        case .escapement: Level.escapement
        case .prism: Level.prism
        }
    }

    func id(_ number: Int) -> String { "\(prefix)-\(number)" }

    /// The 1-based number in an id of this pack, or nil for any other id.
    func number(of id: String) -> Int? {
        guard id.hasPrefix(prefix + "-") else { return nil }
        return Int(id.dropFirst(prefix.count + 1)).flatMap { $0 > 0 ? $0 : nil }
    }

    /// `withheld`: a pack this build doesn't sell, which opens neither its levels nor its card.
    enum Access: Equatable { case taste, owned, needsCard, withheld }

    /// Whether `number` plays. `owned` is what StoreKit grants; the developer unlock and the harness's packs count only
    /// outside Release, so a shipped build opens a pack past its taste for nothing but a purchase.
    func access(_ number: Int, owned: Set<Pack>, unlocked: Bool = Best.unlocked, harness: Set<Pack> = [],
                release: Bool = Build.release) -> Access {
        if release && !ships { return .withheld }
        if number <= taste { return .taste }
        if owned.contains(self) || (!release && (unlocked || harness.contains(self))) { return .owned }
        return .needsCard
    }

    #if DEBUG
    /// A stand-in for level `number`, for the harness to open before the pack has levels.
    func placeholder(_ number: Int) -> Level {
        if self == .prism {
            // Red and cyan rods over a white bottom entry, on the engraving.
            let masks: [Int: Channels] = [0: .red, 1: .cyan]
            return Level(id: id(number), pack: self, label: String(format: "%02d", number), title: "\(name) placeholder",
                         picture: .fern, layout: .tri, scramble: .parse("2:+3,0:+4,1:-3", in: .tri, masks: masks), masks: masks)
        }
        return Level(id: id(number), pack: self, label: String(format: "%02d", number), title: "\(name) placeholder",
                     layout: .tri, scramble: .parse("0:+4", in: .tri))
    }
    #endif
}

extension Level {
    /// Lens's 25 panels on the halftone test panel, `docs/lens-tables.md`'s table A: the draft table with lenses on rods
    /// of every size. A rod is a lens or a twist for the whole level; every dealt lens entry magnifies by 1 to 3 steps
    /// and each lens nets at most +3. No entry merges as it is dealt, and par is the depth (`testLensLevels`), the
    /// solver's optimum (`testLensParIsTheOptimum`).
    static let lens: [Level] = [
        (Layout.tri, [0], "0:+2"),
        (.tri, [0], "0:+1,1:+3"),
        (.tri, [0], "1:-2,2:+4,0:+3"),
        (.tri, [1], "0:+3,1:+2,2:-4,1:+1"),
        (.eye, [2], "0:-4,2:+2,1:+5,3:-3"),
        (.eye, [0], "2:+3,0:+2,1:-4,3:+5,0:+1"),
        (.tri, [0, 1], "2:+4,0:+2,1:+1"),
        (.quad, [0, 2], "1:+4,0:+2,3:-3,2:+3,1:-5,0:+1"),
        (.eye, [2, 3], "0:+3,2:+2,1:-4,3:+3,0:+2,2:+1"),
        (.tri, [2], "0:+3,2:+2,1:-5,0:-2,2:+1,1:+4"),
        (.quad, [1, 3], "0:+3,1:+3,2:-4,3:+2,0:-3,3:+1,2:+5"),
        (.eye, [0, 1], "2:+3,0:+2,3:-4,1:+3,2:-2,0:+1,3:+5"),
        (.hex, [1, 4], "0:+3,1:+2,2:-4,4:+3,6:+2,0:-2,5:+4"),
        (.hex, [2, 5], "3:-3,2:+2,0:+4,5:+1,6:-3,2:+1,4:+5,5:+2"),
        (.eye, [2], "1:+4,2:+1,0:-5,3:+3,2:+2,1:-3,0:+4,3:-2"),
        (.tri, [0], "1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,0:+1"),
        (.hex, [1, 3, 5], "0:+2,1:+3,2:-4,3:+2,4:+3,5:+1,6:-5,0:+4,5:+2"),
        (.quad, [0, 2], "1:+3,0:+1,3:-4,2:+2,1:+5,0:+2,3:+3,2:+1,1:-4"),
        (.hex, [0], "1:+3,0:+2,4:-3,2:+4,0:+1,5:-3,3:+2,6:+4"),
        (.hex, [0, 1, 4], "2:+3,0:+2,1:+3,5:-4,4:+2,3:+4,0:+1,6:-3,2:-2"),
        (.eye, [0, 3], "2:+4,0:+2,1:-5,3:+2,2:-3,0:+1,1:+4,3:+1,2:+3"),
        (.hex, [0, 2, 5], "1:+3,0:+1,2:+2,3:-4,6:+5,5:+3,4:-3,0:+2,1:-3,2:+1"),
        (.hex, [0], "3:+4,0:+1,6:-3,1:+5,0:+1,2:-4,4:+3,0:+1,5:-5,3:+2"),
        (.eye, [2, 3], "0:+4,2:+2,1:-3,3:+1,0:-4,3:+2,1:+5,2:+1,0:+3,1:-2"),
        (.hex, [0, 1, 3, 5], "2:+3,0:+1,1:+2,4:-4,3:+3,6:+3,0:+1,5:+2,2:-5,1:+1,4:+4,0:+1"),
    ].enumerated().map { i, row in
        let (layout, slots, scramble): (Layout, [Int], String) = row
        let lenses = Set(slots)
        return Level(id: Pack.lens.id(i + 1), pack: .lens, label: String(format: "%02d", i + 1), title: "Panel \(i + 1)",
                     picture: .halftone, layout: layout, scramble: .parse(scramble, in: layout, lenses: lenses), lenses: lenses)
    }
    /// The problem book (docs/escapement-problems.md, scripts/escapement/problems.tsv) in its order: five chapters of
    /// six, each opening on a problem that teaches without words. Each problem's `par`, never shown, is the moves its
    /// slowest clock owes, which the prover (`Solver.escapement`) shows a line reaches; its note, the stipulation, states
    /// the tick budget instead (Jack's call EL1, round 11). The book names only its teachers and the finale; problem 1,
    /// the book's "The tick", is "The clock" (Jack's call D1, round 9).
    static let escapement: [Level] = [
        // The Clock.
        problem(1, "The clock", .tri, "0:-1,1:+3,0:-1,2:-4", clocks: [0], par: 2),
        problem(2, "The wait", .tri, "0:-1,1:+3,0:-2,2:-4", clocks: [0], par: 3),
        problem(3, "The dashed edge", .quad, "0:-1,1:+3,0:-1,2:-4", clocks: [0], par: 2),
        problem(4, "Problem 4", .quad, "0:-1,3:+2,0:-2,2:-4,1:-3,0:-1,2:-2", clocks: [0], par: 4),
        problem(5, "Problem 5", .eye, "2:-2,3:-2,1:-4,2:-2,3:-3,1:+3,2:-1,3:-5", clocks: [2], par: 5),
        problem(6, "Problem 6", .hex, "1:-3,4:-2,3:-4,6:+3,1:-2,5:+3,2:-3,1:-1,3:+2", clocks: [1], par: 6),
        // The Waiting Move.
        problem(7, "The quiet first move", .quad, "0:-2,2:+3,1:-2,0:-1", clocks: [0], par: 3),
        problem(8, "Problem 8", .pent, "0:-1,1:+4,0:-3,2:-4,3:-3,4:-5,0:-1", clocks: [0], par: 5),
        problem(9, "Problem 9", .eye, "2:-3,0:+3,2:-2,3:+4,0:-3,2:-1,3:+3", clocks: [2], par: 6),
        problem(10, "Problem 10", .pent, "0:-3,3:+3,2:-3,1:-2,0:-2,1:-4,0:-1,2:+3", clocks: [0], par: 6),
        problem(11, "Problem 11", .pent, "0:-3,1:+2,0:-2,2:+3,4:+5,0:-2,3:+2,4:-3,0:-1,3:-2", clocks: [0], par: 8),
        problem(12, "Problem 12", .hex, "1:-2,5:+4,2:+5,1:-2,3:+3,2:-3,1:-2,3:-4,0:-5,1:-1", clocks: [1], par: 7),
        // Two Clocks.
        problem(13, "Two dials", .quad, "0:-1,2:-2,1:+3,0:-1,2:-1,3:+2", clocks: [0, 2], par: 3),
        problem(14, "Problem 14", .quad, "0:-1,1:+3,0:-1,3:+3,2:-2,0:-2,3:-3", clocks: [0, 2], par: 4),
        problem(15, "Problem 15", .pent, "2:-1,3:-4,2:-4,4:-5,0:-2,4:+2,0:-1,4:-5", clocks: [0, 2], par: 5),
        problem(16, "Problem 16", .hex, "4:-2,2:+5,5:-3,4:-3,6:+4,1:-3,5:+2,4:-1,3:+2", clocks: [1, 4], par: 6),
        problem(17, "Problem 17", .pent, "1:-3,3:+4,4:-3,0:-1,3:-5,1:-1,0:-1,4:+2,1:-1,0:-1,3:+5", clocks: [0, 1], par: 5),
        problem(18, "Problem 18", .hex, "2:-2,6:+2,3:-4,2:-2,4:-2,1:-1,5:+2,2:-1,1:-1,4:+4,2:-1,1:-1,5:-4", clocks: [1, 2], par: 6),
        // Wound Back.
        problem(19, "Backwards", .tri, "0:+1,1:-3,0:+2,2:+4", clocks: [0], back: [0], par: 3),
        problem(20, "Problem 20", .quad, "2:+1,1:+3,2:+1,1:-3,2:+1,0:-1,1:-4,2:+2,0:-2,1:+5", clocks: [0, 2], back: [2], par: 5),
        problem(21, "Problem 21", .pent, "0:+2,3:+2,4:+5,0:+2,3:+3,2:-2,4:-3,0:+2,3:-4,2:-1", clocks: [0, 2], back: [0], par: 6),
        problem(22, "Problem 22", .hex, "4:+2,2:-2,5:+3,4:+2,6:-5,1:-2,3:-2,4:+3,6:-5,1:-2,5:+3", clocks: [1, 4], back: [4], par: 7),
        problem(23, "Problem 23", .pent, "0:+2,3:-5,4:-5,0:+3,2:-2,3:+4,4:-3,0:+1,3:-4", clocks: [0], back: [0], par: 6),
        problem(24, "Problem 24", .hex, "1:+3,4:-2,5:+4,2:+2,1:+2,3:+3,2:-5,1:+2,3:+2,6:-2", clocks: [1], back: [1], par: 7),
        // Grand Complication.
        problem(25, "Three dials", .hex, "1:-2,3:-1,5:-3,0:+3", clocks: [1, 3, 5], par: 3),
        problem(26, "Problem 26", .pent, "2:-2,4:-3,3:+2,2:-2,4:+3,3:+5,2:-3,0:-2,4:+2,0:-2,3:+3,2:-1,1:+2", clocks: [0, 2], par: 8),
        problem(27, "Problem 27", .pent, "0:-3,3:-4,2:-5,1:-5,0:-2,1:+2,0:-1,1:+2,0:-2,2:+5,1:-2,0:-1,2:+2", clocks: [0], par: 9),
        problem(28, "Problem 28", .hex, "1:-2,0:+5,1:-3,4:-5,3:+3,6:+4,1:-2,5:-4,2:+3,1:-2,4:+5,2:+4", clocks: [1], par: 9),
        problem(29, "Problem 29", .hex, "5:-1,4:+3,5:-2,2:+3,0:-5,5:-5,2:+4,3:-2,1:-2,2:+2,3:-2,1:-2,4:+3", clocks: [1, 3, 5], par: 8),
        problem(30, "Finale", .hex, "1:-4,5:+2,4:+2,5:+3,6:-4,3:-2,1:-4,5:-4,4:+5,3:-2,5:-3,0:+2", clocks: [1, 3], par: 8),
    ]

    /// The book's chapters, six problems each.
    static let escapementChapters = ["The Clock", "The Waiting Move", "Two Clocks", "Wound Back", "Grand Complication"]

    private static func problem(_ n: Int, _ title: String, _ layout: Layout, _ scramble: String, clocks: [Int],
                                back: [Int] = [], par: Int) -> Level {
        var level = Level(id: Pack.escapement.id(n), pack: .escapement, label: String(format: "%02d", n), title: title,
                          layout: layout, scramble: .parse(scramble, in: layout), ratchets: Set(clocks), woundBack: Set(back),
                          chapter: escapementChapters[(n - 1) / 6],
                          // A heal hands the clock its seam and it ticks; a wait, and it ticks again.
                          demo: n == 1 ? .parse("0:-3,1:+2", in: .tri) : [], fixedPar: par)
        level.note = "Unstir in \(level.budget) ticks."
        return level
    }

    /// Prism's specimens on the fern, `docs/prism-design.md`'s table: so far the Two Colours tray, red and cyan rods
    /// over one white rod that holds only the bottom entry, so neither channel is ever clean alone. No entry merges as it
    /// is dealt, and par is the depth (`testPrismLevels`), the solver's optimum (`testPrismParIsTheOptimum`).
    static let prism: [Level] = [
        (Layout.tri, "0:r,1:c,2:w", "2:+3,0:+4,1:-3"),
        (.quad, "0:r,1:c,2:r,3:w", "3:+3,2:-4,1:+3,0:+5"),
        (.eye, "0:r,1:c,2:r,3:w", "3:+4,0:-3,2:+2,1:+5,0:+3"),
        (.quad, "0:r,1:r,2:c,3:w", "3:-3,0:+3,1:+4,2:-5,0:-2,1:+3"),
        (.pent, "0:r,1:r,2:c,3:c,4:w", "4:+3,0:+4,2:-3,1:+2,3:+4,0:-3,2:+5"),
        (.hex, "0:w,1:r,2:r,3:c,4:c,5:r,6:c", "0:+3,1:+4,3:-3,2:-2,5:+2,4:+5,1:+3,6:-4,3:+2"),
    ].enumerated().map { i, row in
        let (layout, mask, scramble): (Layout, String, String) = row
        let masks = Channels.masks(mask)!
        return Level(id: Pack.prism.id(i + 1), pack: .prism, label: String(format: "%02d", i + 1), title: "Specimen \(i + 1)",
                     note: i == 0 ? "Each rod stirs only its knob's colours." : "", picture: .fern, layout: layout,
                     scramble: .parse(scramble, in: layout, masks: masks), masks: masks)
    }

    /// A pack's level keeps a best and its started flag only once it is one of the pack's own, so a harness placeholder
    /// never leaves progress under an id a real level will take.
    var keepsProgress: Bool { pack.map { p in p.levels.contains { $0.id == id } } ?? true }
}

enum Build {
    static let release: Bool = {
        #if DEBUG
        false
        #else
        true
        #endif
    }()
}
