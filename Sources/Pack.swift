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

    /// Whether a Release build sells it. First Stir is out of v1, to be reworked (Jack, FS17), and Prism takes its place
    /// (PK1); a build outside Release keeps First Stir, so its levels, tests and films still run.
    var ships: Bool { self != .firstStir }

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

    /// Whether `number` plays. `owned` is what StoreKit grants; the developer unlock counts only outside Release or in a
    /// playtest build, and the harness's packs only outside Release, so a shipped build opens a pack past its taste for
    /// nothing but a purchase.
    func access(_ number: Int, owned: Set<Pack>, unlocked: Bool = Best.unlocked, harness: Set<Pack> = [],
                release: Bool = Build.release, playtest: Bool = Build.playtest) -> Access {
        if release && !ships { return .withheld }
        if number <= taste { return .taste }
        if owned.contains(self) || ((!release || playtest) && unlocked) || (!release && harness.contains(self)) { return .owned }
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
        (Layout.tri, [0], "0:+2", "Keyhole"),
        (.tri, [0], "0:+1,1:+3", "Peephole"),
        (.tri, [0], "1:-2,2:+4,0:+3", "Magnifying glass"),
        (.tri, [1], "0:+3,1:+2,2:-4,1:+1", "Monocle"),
        (.eye, [2], "0:-4,2:+2,1:+5,3:-3", "Goggles"),
        (.eye, [0], "2:+3,0:+2,1:-4,3:+5,0:+1", "Spyglass"),
        (.tri, [0, 1], "2:+4,0:+2,1:+1", "Binoculars"),
        (.quad, [0, 2], "1:+4,0:+2,3:-3,2:+3,1:-5,0:+1", "Spectacles"),
        (.eye, [2, 3], "0:+3,2:+2,1:-4,3:+3,0:+2,2:+1", "Sunglasses"),
        (.tri, [2], "0:+3,2:+2,1:-5,0:-2,2:+1,1:+4", "Pinhole"),
        (.quad, [1, 3], "0:+3,1:+3,2:-4,3:+2,0:-3,3:+1,2:+5", "Bifocals"),
        (.eye, [0, 1], "2:+3,0:+2,3:-4,1:+3,2:-2,0:+1,3:+5", "3D glasses"),
        (.hex, [1, 4], "0:+3,1:+2,2:-4,4:+3,6:+2,0:-2,5:+4", "Porthole"),
        (.hex, [2, 5], "3:-3,2:+2,0:+4,5:+1,6:-3,2:+1,4:+5,5:+2", "Periscope"),
        (.eye, [2], "1:+4,2:+1,0:-5,3:+3,2:+2,1:-3,0:+4,3:-2", "Telescope"),
        (.tri, [0], "1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,0:+1", "Eyepiece"),
        (.hex, [1, 3, 5], "0:+2,1:+3,2:-4,3:+2,4:+3,5:+1,6:-5,0:+4,5:+2", "Microscope"),
        (.quad, [0, 2], "1:+3,0:+1,3:-4,2:+2,1:+5,0:+2,3:+3,2:+1,1:-4", "Night vision"),
        (.hex, [0], "1:+3,0:+2,4:-3,2:+4,0:+1,5:-3,3:+2,6:+4", "Camera"),
        (.hex, [0, 1, 4], "2:+3,0:+2,1:+3,5:-4,4:+2,3:+4,0:+1,6:-3,2:-2", "Shutter"),
        (.eye, [0, 3], "2:+4,0:+2,1:-5,3:+2,2:-3,0:+1,1:+4,3:+1,2:+3", "Viewfinder"),
        (.hex, [0, 2, 5], "1:+3,0:+1,2:+2,3:-4,6:+5,5:+3,4:-3,0:+2,1:-3,2:+1", "Wide angle"),
        (.hex, [0], "3:+4,0:+1,6:-3,1:+5,0:+1,2:-4,4:+3,0:+1,5:-5,3:+2", "Fisheye"),
        (.eye, [2, 3], "0:+4,2:+2,1:-3,3:+1,0:-4,3:+2,1:+5,2:+1,0:+3,1:-2", "Telephoto"),
        (.hex, [0, 1, 3, 5], "2:+3,0:+1,1:+2,4:-4,3:+3,6:+3,0:+1,5:+2,2:-5,1:+1,4:+4,0:+1", "Kaleidoscope"),
    ].enumerated().map { i, row in
        let (layout, slots, scramble, title): (Layout, [Int], String, String) = row
        let lenses = Set(slots)
        return Level(id: Pack.lens.id(i + 1), pack: .lens, label: String(format: "%02d", i + 1), title: title,
                     picture: .halftone, layout: layout, scramble: .parse(scramble, in: layout, lenses: lenses),
                     chapter: lensChapters[min(i / 6, 3)], lenses: lenses)
    }

    /// Lens's chapters (Jack's call N1b, round 13): six levels each, the last seven.
    static let lensChapters = ["Close-up", "Cut-in", "Double-take", "Big Picture"]

    /// The problem book (docs/escapement-problems.md, scripts/escapement/problems.tsv) in its order: five chapters of
    /// six, each opening on a problem that teaches without words. Each problem's `par`, never shown, is the moves its
    /// slowest clock owes, which the prover (`Solver.escapement`) shows a line reaches; its note, the stipulation, states
    /// the tick budget instead (Jack's call EL1, round 11). The titles are a clock taken apart, not the book's (Jack's
    /// call N1, round 13); problem 1, D1's "The clock" (round 9), is "Mainspring" (N1a).
    static let escapement: [Level] = [
        // The Clock.
        problem(1, "Mainspring", .tri, "0:-1,1:+3,0:-1,2:-4", clocks: [0], par: 2),
        problem(2, "Pendulum", .tri, "0:-1,1:+3,0:-2,2:-4", clocks: [0], par: 3),
        problem(3, "Clock face", .quad, "0:-1,1:+3,0:-1,2:-4", clocks: [0], par: 2),
        problem(4, "Cogwheel", .quad, "0:-1,3:+2,0:-2,2:-4,1:-3,0:-1,2:-2", clocks: [0], par: 4),
        problem(5, "Winding key", .eye, "2:-2,3:-2,1:-4,2:-2,3:-3,1:+3,2:-1,3:-5", clocks: [2], par: 5),
        problem(6, "Clockwork", .hex, "1:-3,4:-2,3:-4,6:+3,1:-2,5:+3,2:-3,1:-1,3:+2", clocks: [1], par: 6),
        // The Waiting Move.
        problem(7, "Pause", .quad, "0:-2,2:+3,1:-2,0:-1", clocks: [0], par: 3),
        problem(8, "Snooze", .pent, "0:-1,1:+4,0:-3,2:-4,3:-3,4:-5,0:-1", clocks: [0], par: 5),
        problem(9, "Hourglass", .eye, "2:-3,0:+3,2:-2,3:+4,0:-3,2:-1,3:+3", clocks: [2], par: 6),
        problem(10, "Egg timer", .pent, "0:-3,3:+3,2:-3,1:-2,0:-2,1:-4,0:-1,2:+3", clocks: [0], par: 6),
        problem(11, "Stopwatch", .pent, "0:-3,1:+2,0:-2,2:+3,4:+5,0:-2,3:+2,4:-3,0:-1,3:-2", clocks: [0], par: 8),
        problem(12, "Standstill", .hex, "1:-2,5:+4,2:+5,1:-2,3:+3,2:-3,1:-2,3:-4,0:-5,1:-1", clocks: [1], par: 7),
        // Two Clocks.
        problem(13, "Twin dials", .quad, "0:-1,2:-2,1:+3,0:-1,2:-1,3:+2", clocks: [0, 2], par: 3),
        problem(14, "Hour hand", .quad, "0:-1,1:+3,0:-1,3:+3,2:-2,0:-2,3:-3", clocks: [0, 2], par: 4),
        problem(15, "Minute hand", .pent, "2:-1,3:-4,2:-4,4:-5,0:-2,4:+2,0:-1,4:-5", clocks: [0, 2], par: 5),
        problem(16, "Metronome", .hex, "4:-2,2:+5,5:-3,4:-3,6:+4,1:-3,5:+2,4:-1,3:+2", clocks: [1, 4], par: 6),
        problem(17, "Chime", .pent, "1:-3,3:+4,4:-3,0:-1,3:-5,1:-1,0:-1,4:+2,1:-1,0:-1,3:+5", clocks: [0, 1], par: 5),
        problem(18, "Cuckoo clock", .hex, "2:-2,6:+2,3:-4,2:-2,4:-2,1:-1,5:+2,2:-1,1:-1,4:+4,2:-1,1:-1,5:-4", clocks: [1, 2], par: 6),
        // Wound Back.
        problem(19, "Rewind", .tri, "0:+1,1:-3,0:+2,2:+4", clocks: [0], back: [0], par: 3),
        problem(20, "Fall back", .quad, "2:+1,1:+3,2:+1,1:-3,2:+1,0:-1,1:-4,2:+2,0:-2,1:+5", clocks: [0, 2], back: [2], par: 5),
        problem(21, "Mirror dial", .pent, "0:+2,3:+2,4:+5,0:+2,3:+3,2:-2,4:-3,0:+2,3:-4,2:-1", clocks: [0, 2], back: [0], par: 6),
        problem(22, "Anticlockwise", .hex, "4:+2,2:-2,5:+3,4:+2,6:-5,1:-2,3:-2,4:+3,6:-5,1:-2,5:+3", clocks: [1, 4], back: [4], par: 7),
        problem(23, "Overwound", .pent, "0:+2,3:-5,4:-5,0:+3,2:-2,3:+4,4:-3,0:+1,3:-4", clocks: [0], back: [0], par: 6),
        problem(24, "Reverse", .hex, "1:+3,4:-2,5:+4,2:+2,1:+2,3:+3,2:-5,1:+2,3:+2,6:-2", clocks: [1], back: [1], par: 7),
        // Grand Complication.
        problem(25, "Moon phase", .hex, "1:-2,3:-1,5:-3,0:+3", clocks: [1, 3, 5], par: 3),
        problem(26, "Calendar", .pent, "2:-2,4:-3,3:+2,2:-2,4:+3,3:+5,2:-3,0:-2,4:+2,0:-2,3:+3,2:-1,1:+2", clocks: [0, 2], par: 8),
        problem(27, "Time zones", .pent, "0:-3,3:-4,2:-5,1:-5,0:-2,1:+2,0:-1,1:+2,0:-2,2:+5,1:-2,0:-1,2:+2", clocks: [0], par: 9),
        problem(28, "Leap year", .hex, "1:-2,0:+5,1:-3,4:-5,3:+3,6:+4,1:-2,5:-4,2:+3,1:-2,4:+5,2:+4", clocks: [1], par: 9),
        problem(29, "Eleventh hour", .hex, "5:-1,4:+3,5:-2,2:+3,0:-5,5:-5,2:+4,3:-2,1:-2,2:+2,3:-2,1:-2,4:+3", clocks: [1, 3, 5], par: 8),
        problem(30, "Midnight", .hex, "1:-4,5:+2,4:+2,5:+3,6:-4,3:-2,1:-4,5:-4,4:+5,3:-2,5:-3,0:+2", clocks: [1, 3], par: 8),
    ]

    /// The book's chapters, six problems each.
    static let escapementChapters = ["The Clock", "The Waiting Move", "Two Clocks", "Wound Back", "Grand Complication"]
    /// Each chapter's opener adds its rule to the stipulation, as its old title taught it (Jack's call N1, round 13).
    static let escapementRules = ["A clock ticks after every move.", "Sometimes the first move is to wait.",
                                  "Two clocks tick in turn.", "A wound-back clock ticks the other way.", "Three clocks."]

    private static func problem(_ n: Int, _ title: String, _ layout: Layout, _ scramble: String, clocks: [Int],
                                back: [Int] = [], par: Int) -> Level {
        var level = Level(id: Pack.escapement.id(n), pack: .escapement, label: String(format: "%02d", n), title: title,
                          layout: layout, scramble: .parse(scramble, in: layout), ratchets: Set(clocks), woundBack: Set(back),
                          chapter: escapementChapters[(n - 1) / 6],
                          // A heal hands the clock its seam and it ticks; a wait, and it ticks again.
                          demo: n == 1 ? .parse("0:-3,1:+2", in: .tri) : [], fixedPar: par)
        level.note = "Unstir in \(level.budget) ticks." + ((n - 1) % 6 == 0 ? " " + escapementRules[(n - 1) / 6] : "")
        return level
    }

    /// Prism's 30 specimens, `docs/prism-design.md`'s table: five trays of six, each on its own plate. One white rod holds
    /// only the bottom entry, so no channel is ever clean alone; no entry merges as it is dealt; every stack is at most 8
    /// deep, as deeper ones read too busy (Jack's call PK1); par is the depth (`testPrismLevels`), the solver's optimum
    /// (`testPrismParIsTheOptimum`). `scripts/prism-levels.sh table` measures them.
    static let prism: [Level] = [
        // Two Colours, on the fern: red and cyan, which share no channel, so they always pass each other.
        (Layout.tri, "0:r,1:c,2:w", "2:+3,0:+4,1:-3", "Frond"),
        (.quad, "0:r,1:c,2:r,3:w", "3:+3,2:-4,1:+3,0:+5", "Bracken"),
        (.eye, "0:r,1:c,2:r,3:w", "3:+4,0:-3,2:+2,1:+5,0:+3", "Fiddlehead"),
        (.quad, "0:r,1:r,2:c,3:w", "3:-3,0:+3,1:+4,2:-5,0:-2,1:+3", "Maidenhair"),
        (.pent, "0:r,1:r,2:c,3:c,4:w", "4:+3,0:+4,2:-3,1:+2,3:+4,0:-3,2:+5", "Spore"),
        (.hex, "0:c,1:c,2:c,3:r,4:r,5:w,6:c", "5:-2,1:+5,6:+3,1:-5,4:-5,0:+3,2:-3,3:-4", "Tree fern"),
        // Three Colours, on the seed heads: red, green and blue, three words that never meet.
        (.quad, "0:b,1:g,2:r,3:w", "3:-4,2:-5,1:-4,0:-3", "Dandelion"),
        (.pent, "0:b,1:g,2:r,3:w,4:r", "3:+3,1:-5,0:+4,4:-4,2:-2", "Thistle"),
        (.pent, "0:r,1:g,2:b,3:w,4:r", "3:-3,2:+2,1:-2,0:+3,4:+2,0:-2", "Sunflower"),
        (.pent, "0:g,1:g,2:r,3:b,4:w", "4:+4,2:+4,1:+2,0:+2,3:+5,1:+3", "Poppy"),
        (.pent, "0:g,1:w,2:b,3:b,4:r", "1:-5,2:-4,3:-5,0:+3,2:-5,4:-5,3:+5", "Sycamore"),
        (.pent, "0:b,1:w,2:r,3:r,4:g", "1:+5,2:-2,4:+3,0:+4,3:-2,2:-3,3:-3,2:+4", "Acorn"),
        // Colour Order, on the medusae: cyan, magenta and yellow, each pair sharing a channel, so overlapping inks block.
        (.tri, "0:m,1:c,2:w", "2:-5,1:+5,0:-4,1:-5", "Jellyfish"),
        (.quad, "0:w,1:m,2:c,3:y", "0:-5,1:+4,3:-4,2:-2", "Moon jelly"),
        (.quad, "0:y,1:w,2:m,3:c", "1:-3,2:-3,0:+5,3:+3,2:+5", "Sea nettle"),
        (.eye, "0:c,1:w,2:y,3:m", "1:+5,0:+5,2:-2,0:-5,3:+5", "Tentacles"),
        (.pent, "0:c,1:c,2:m,3:w,4:y", "3:+3,0:+5,4:+3,0:+3,2:-2,1:+2", "Lion's mane"),
        (.pent, "0:m,1:y,2:c,3:w,4:y", "3:+3,2:+5,4:+5,1:+4,0:-3,1:-5,2:-3", "Compass jelly"),
        // Overprint, on the radiolarians: primaries and inks together; red passes cyan, and blocks yellow and magenta.
        (.quad, "0:c,1:b,2:y,3:w", "3:-5,2:-2,1:-4,0:+3,1:-3,0:-3", "Plankton"),
        (.eye, "0:w,1:m,2:g,3:b", "0:-2,2:+3,3:+4,1:+3,3:-2,1:-4", "Lattice"),
        (.eye, "0:w,1:b,2:y,3:m", "0:-4,3:+5,1:-2,2:-3,3:+5,1:+3,3:-4", "Pollen"),
        (.pent, "0:c,1:w,2:b,3:m,4:g", "1:+3,4:-2,0:+2,2:-2,3:+5,4:-5,2:+5", "Sunburst"),
        (.pent, "0:m,1:r,2:c,3:b,4:w", "4:+5,3:+2,0:-5,2:-3,1:+3,0:-5,1:-2,0:+2", "Sea urchin"),
        (.pent, "0:y,1:w,2:g,3:c,4:m", "1:-2,4:-5,3:-5,0:+3,2:+3,3:+3,4:+2,3:+2", "Honeycomb"),
        // Spectrum, on the nautilus: every mask on one tank.
        (.tri, "0:w,1:m,2:r", "0:+2,1:+5,2:+3,1:-2,2:-2,1:-3", "Ammonite"),
        (.quad, "0:y,1:c,2:r,3:w", "3:+5,2:+4,1:-4,0:-4,1:-4,0:+2,1:-4", "Oyster"),
        (.eye, "0:b,1:w,2:m,3:y", "1:-4,0:+3,2:-2,3:-3,0:+5,2:+3,0:+3", "Conch"),
        (.eye, "0:w,1:r,2:m,3:b", "0:-3,2:-2,3:-3,1:-5,2:+4,1:+5,2:-2,1:-2", "Pearl"),
        (.pent, "0:c,1:m,2:b,3:y,4:w", "4:-4,3:+5,0:-3,2:+2,1:+4,2:-3,1:+3,0:-4", "Scallop"),
        (.pent, "0:y,1:m,2:r,3:w,4:g", "3:-3,2:+2,1:-2,2:-2,0:+3,4:+2,1:+2,0:-2", "Nautilus"),
    ].enumerated().map { i, row in
        let (layout, mask, scramble, title): (Layout, String, String, String) = row
        let masks = Channels.masks(mask)!, tray = i / 6
        return Level(id: Pack.prism.id(i + 1), pack: .prism, label: String(format: "%02d", i + 1), title: title,
                     note: i % 6 == 0 ? prismNotes[tray] : "", picture: prismPlates[tray], layout: layout,
                     scramble: .parse(scramble, in: layout, masks: masks), chapter: prismTrays[tray], masks: masks)
    }

    /// Prism's trays, six specimens each, and the plate each is engraved on.
    static let prismTrays = ["Two Colours", "Three Colours", "Colour Order", "Overprint", "Spectrum"]
    static let prismPlates: [Picture] = [.fern, .seeds, .medusae, .radiolaria, .nautilus]
    /// Each tray's opener says the rule it adds, as the first tray's says the pack's.
    static let prismNotes = ["Each rod stirs only its knob's colours.", "Red, green and blue pass through each other.",
                             "Inks that share a colour block each other.", "Red passes cyan, and blocks yellow and magenta.",
                             "White stirs every colour."]

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
    /// A build `scripts/run-ios.sh` installs on the reference phone (Info.plist's `AnalyticsPlaytest`), never an archive.
    static let playtest = Bundle.main.infoDictionary?["AnalyticsPlaytest"] as? String == "YES"
}
