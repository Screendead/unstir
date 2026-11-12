// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// A paid set of levels, outside the tier ladder: no pack best ever opens a tier. The raw value is the pack's level-id
/// prefix and `productID` is what StoreKit sells it as; bests and purchases are kept under both, so neither ever
/// changes (UnstirTests pins them).
enum Pack: String, CaseIterable, Sendable {
    case firstStir = "first-stir", lens, escapement, prism

    /// Never translated, as the App Store's names for the products aren't (Jack's call CAT1 = A).
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

    /// The bundle's product, which grants `bundled`. Its id says Complete, its old name, and never changes.
    static let completeID = "com.screendead.Unstir.complete"

    /// What the bundle grants, fixed: a later pack never joins it, and a bundle after it holds three packs of its own
    /// under a new product (Jack's call M1 = B2, round 14).
    static let bundled: [Pack] = [.lens, .escapement, .prism]

    static var productIDs: [String] { sold().map(\.productID) + [completeID] }

    /// Whether a Release build sells it. First Stir is out of v1, to be reworked (Jack, FS17), and Prism takes its place
    /// (PK1); a build outside Release keeps First Stir, so its levels, tests and films still run. Release also compiles
    /// its levels out (`FIRST_STIR`), leaving the case for its stored values.
    var ships: Bool { self != .firstStir }

    /// The packs a build sells.
    static func sold(release: Bool = Build.release) -> [Pack] { allCases.filter { !release || $0.ships } }

    /// "Lens and Escapement".
    static func named(_ packs: [Pack]) -> String {
        let names = packs.map(\.name)
        guard names.count > 1 else { return names.joined() }
        return String(localized: "\(names.dropLast().joined(separator: ", ")) and \(names.last!)",
                      comment: "Packs named in a list. Every name but the last, then the last")
    }

    /// Its levels counted by what they are, as its card and a completion say them.
    func counted(_ n: Int) -> String {
        switch self {
        case .firstStir: String(localized: "\(n) scenes", comment: "First Stir's levels, counted")
        case .lens: String(localized: "\(n) panels", comment: "Lens's levels, counted")
        case .escapement: String(localized: "\(n) problems", comment: "Escapement's levels, counted")
        case .prism: String(localized: "\(n) specimens", comment: "Prism's levels, counted")
        }
    }

    /// Levels 1 to `taste` play without the pack.
    var taste: Int { 3 }

    /// The player's progress has reached what the pack assumes, so its cover marks it new (Jack's call C6, round 13):
    /// Lens and Prism once every plughole level has a best, Escapement once maelstrom is open. First Stir, out of v1,
    /// never marks.
    func fits(best: (String) -> Best? = Best.load) -> Bool {
        switch self {
        case .lens, .prism: Tier.plughole.levels.allSatisfy { best($0.id) != nil }
        case .escapement: Tier.maelstrom.isOpen(unlocked: false, best)
        case .firstStir: false
        }
    }

    /// How many of the free levels have a best, once any of them is started or has one; nil before.
    func tastePlayed(best: (String) -> Best? = Best.load, started: (String) -> Bool = Best.started) -> Int? {
        let free = levels.prefix(taste)
        guard free.contains(where: { started($0.id) || best($0.id) != nil }) else { return nil }
        return free.filter { best($0.id) != nil }.count
    }

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
        #if FIRST_STIR
        case .firstStir: Level.firstStir
        #else
        case .firstStir: []
        #endif
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

    /// Whether `number` plays. `owned` is what StoreKit grants; the developer unlock counts only outside Release, in a
    /// playtest build or in the editors' build, and the harness's packs only outside Release, so a shipped build opens a
    /// pack past its taste for nothing but a purchase.
    func access(_ number: Int, owned: Set<Pack>, unlocked: Bool = Best.unlocked, harness: Set<Pack> = [],
                release: Bool = Build.release, playtest: Bool = Build.playtest, editors: Bool = Build.editors) -> Access {
        if release && !ships { return .withheld }
        if number <= taste { return .taste }
        if owned.contains(self) || ((!release || playtest || editors) && unlocked) || (!release && harness.contains(self)) {
            return .owned
        }
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
    /// Lens's 25 panels, each on its own halftone panel once that is drawn (`panel`, `LensArt.levels`) and on the test
    /// panel until then, `docs/lens-tables.md`'s table A: the draft table with lenses on rods
    /// of every size, but for 8, 11 and 18, moved off the four-rod glass. A rod is a lens or a twist for the whole level; every dealt lens entry magnifies by 1 to 3 steps
    /// and each lens nets at most +3. No entry merges as it is dealt, and par is the depth (`testLensLevels`), the
    /// solver's optimum (`testLensParIsTheOptimum`).
    static let lens: [Level] = [
        (Layout.tri, [0], "0:+2",
         String(localized: "level.lens-1.title", defaultValue: "Keyhole",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [0], "0:+1,1:+3",
         String(localized: "level.lens-2.title", defaultValue: "Peephole",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [0], "1:-2,2:+4,0:+3",
         String(localized: "level.lens-3.title", defaultValue: "Magnifying glass",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [1], "0:+3,1:+2,2:-4,1:+1",
         String(localized: "level.lens-4.title", defaultValue: "Monocle",
                comment: "Lens level title, a lens or a way of seeing")),
        (.eye, [2], "0:-4,2:+2,1:+5,3:-3",
         String(localized: "level.lens-5.title", defaultValue: "Goggles",
                comment: "Lens level title, a lens or a way of seeing")),
        (.eye, [0], "2:+3,0:+2,1:-4,3:+5,0:+1",
         String(localized: "level.lens-6.title", defaultValue: "Spyglass",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [0, 1], "2:+4,0:+2,1:+1",
         String(localized: "level.lens-7.title", defaultValue: "Binoculars",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [0, 2], "1:+4,0:+2,1:-3,2:+3,1:-5,0:+1",
         String(localized: "level.lens-8.title", defaultValue: "Spectacles",
                comment: "Lens level title, a lens or a way of seeing")),
        (.eye, [2, 3], "0:+3,2:+2,1:-4,3:+3,0:+2,2:+1",
         String(localized: "level.lens-9.title", defaultValue: "Sunglasses",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [2], "0:+3,2:+2,1:-5,0:-2,2:+1,1:+4",
         String(localized: "level.lens-10.title", defaultValue: "Pinhole",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [1, 2], "0:+3,1:+2,2:+1,0:-4,2:+2,1:+1,0:+5",
         String(localized: "level.lens-11.title", defaultValue: "Bifocals",
                comment: "Lens level title, a lens or a way of seeing")),
        (.eye, [0, 1], "2:+3,0:+2,3:-4,1:+3,2:-2,0:+1,3:+5",
         String(localized: "level.lens-12.title", defaultValue: "3D glasses",
                comment: "Lens level title, a lens or a way of seeing")),
        (.hex, [1, 4], "0:+3,1:+2,2:-4,4:+3,6:+2,0:-2,5:+4",
         String(localized: "level.lens-13.title", defaultValue: "Porthole",
                comment: "Lens level title, a lens or a way of seeing")),
        (.hex, [2, 5], "3:-3,2:+2,0:+4,5:+1,6:-3,2:+1,4:+5,5:+2",
         String(localized: "level.lens-14.title", defaultValue: "Periscope",
                comment: "Lens level title, a lens or a way of seeing")),
        (.eye, [2], "1:+4,2:+1,0:-5,3:+3,2:+2,1:-3,0:+4,3:-2",
         String(localized: "level.lens-15.title", defaultValue: "Telescope",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [0], "1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,0:+1",
         String(localized: "level.lens-16.title", defaultValue: "Eyepiece",
                comment: "Lens level title, a lens or a way of seeing")),
        (.hex, [1, 3, 5], "0:+2,1:+3,2:-4,3:+2,4:+3,5:+1,6:-5,0:+4,5:+2",
         String(localized: "level.lens-17.title", defaultValue: "Microscope",
                comment: "Lens level title, a lens or a way of seeing")),
        (.tri, [0, 2], "1:+3,0:+2,2:+1,1:-4,2:+1,1:+2,0:+1,1:-5,2:+1",
         String(localized: "level.lens-18.title", defaultValue: "Night vision",
                comment: "Lens level title, a lens or a way of seeing")),
        (.hex, [0], "1:+3,0:+2,4:-3,2:+4,0:+1,5:-3,3:+2,6:+4",
         String(localized: "level.lens-19.title", defaultValue: "Camera",
                comment: "Lens level title, a lens or a way of seeing")),
        (.hex, [0, 1, 4], "2:+3,0:+2,1:+3,5:-4,4:+2,3:+4,0:+1,6:-3,2:-2",
         String(localized: "level.lens-20.title", defaultValue: "Shutter",
                comment: "Lens level title, a lens or a way of seeing")),
        (.eye, [0, 3], "2:+4,0:+2,1:-5,3:+2,2:-3,0:+1,1:+4,3:+1,2:+3",
         String(localized: "level.lens-21.title", defaultValue: "Viewfinder",
                comment: "Lens level title, a lens or a way of seeing")),
        (.hex, [0, 2, 5], "1:+3,0:+1,2:+2,3:-4,6:+5,5:+3,4:-3,0:+2,1:-3,2:+1",
         String(localized: "level.lens-22.title", defaultValue: "Wide angle",
                comment: "Lens level title, a lens or a way of seeing")),
        (.hex, [0], "3:+4,0:+1,6:-3,1:+5,0:+1,2:-4,4:+3,0:+1,5:-5,3:+2",
         String(localized: "level.lens-23.title", defaultValue: "Fisheye",
                comment: "Lens level title, a lens or a way of seeing")),
        (.eye, [2, 3], "0:+4,2:+2,1:-3,3:+1,0:-4,3:+2,1:+5,2:+1,0:+3,1:-2",
         String(localized: "level.lens-24.title", defaultValue: "Telephoto",
                comment: "Lens level title, a lens or a way of seeing")),
        (.hex, [0, 1, 3, 5], "2:+3,0:+1,1:+2,4:-4,3:+3,6:+3,0:+1,5:+2,2:-5,1:+1,4:+4,0:+1",
         String(localized: "level.lens-25.title", defaultValue: "Kaleidoscope",
                comment: "Lens level title, a lens or a way of seeing")),
    ].enumerated().map { i, row in
        let (layout, slots, scramble, title): (Layout, [Int], String, String) = row
        let lenses = Set(slots)
        return Level(id: Pack.lens.id(i + 1), pack: .lens, label: String(format: "%02d", i + 1), title: title,
                     picture: .halftone, layout: layout, scramble: .parse(scramble, in: layout, lenses: lenses),
                     chapter: lensChapters[min(i / 6, 3)], lenses: lenses)
    }

    /// Lens's face (Jack, 2026-11-11): Kaleidoscope, which the pack's dock cover, its card's clip, its promoted-purchase
    /// image and the bundle's wedge all draw, so its bake stays in Caches (`PanelCache`). The taste stays levels 1 to 3.
    static var lensFace: Level { lens[24] }

    /// The halftone panel the level draws (`Halftone.panel`): a Lens level's number, and 0, the test panel, anywhere else.
    var panel: Int { pack == .lens ? Int(label) ?? 0 : 0 }

    /// The numbered picture the play screen bakes: `panel`, or an Escapement problem's number, for its own plate
    /// (`EscapementArt.plate`). Only the play screen asks: a dock cover, a card's clip and the promoted-purchase image
    /// draw `panel`, so for now they keep Escapement's shared plate.
    var plate: Int { pack == .escapement ? Int(label) ?? 0 : panel }

    /// Lens's chapters (Jack's call N1b, round 13): six levels each, the last seven.
    static let lensChapters = [
        String(localized: "chapter.lens.1", defaultValue: "Close-up",
               comment: "Lens chapter, a film-making word: the first six panels"),
        String(localized: "chapter.lens.2", defaultValue: "Cut-in",
               comment: "Lens chapter, a film-making word: panels 7 to 12"),
        String(localized: "chapter.lens.3", defaultValue: "Double-take",
               comment: "Lens chapter, a film-making word: panels 13 to 18"),
        String(localized: "chapter.lens.4", defaultValue: "Big Picture",
               comment: "Lens chapter, a film-making word: the last seven panels"),
    ]

    /// The problem book (docs/escapement-problems.md, scripts/escapement/problems.tsv) in its order: five chapters of
    /// six, each opening on a problem that teaches without words. Each problem's `par`, never shown, is the moves its
    /// slowest clock owes, which the prover (`Solver.escapement`) shows a line reaches; its note, the stipulation, states
    /// the tick budget instead (Jack's call EL1, round 11). The titles are a clock taken apart, not the book's (Jack's
    /// call N1, round 13); problem 1, D1's "The clock" (round 9), is "Mainspring" (N1a).
    static let escapement: [Level] = [
        // The Clock.
        problem(1, String(localized: "level.escapement-1.title", defaultValue: "Mainspring",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .tri, "0:-1,1:+3,0:-1,2:-4", clocks: [0], par: 2),
        problem(2, String(localized: "level.escapement-2.title", defaultValue: "Pendulum",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .tri, "0:-1,1:+3,0:-2,2:-4", clocks: [0], par: 3),
        problem(3, String(localized: "level.escapement-3.title", defaultValue: "Clock face",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .quad, "0:-1,1:+3,0:-1,2:-4", clocks: [0], par: 2),
        problem(4, String(localized: "level.escapement-4.title", defaultValue: "Cogwheel",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .quad, "0:-1,3:+2,0:-2,2:-4,1:-3,0:-1,2:-2", clocks: [0], par: 4),
        problem(5, String(localized: "level.escapement-5.title", defaultValue: "Winding key",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .eye, "2:-2,3:-2,1:-4,2:-2,3:-3,1:+3,2:-1,3:-5", clocks: [2], par: 5),
        problem(6, String(localized: "level.escapement-6.title", defaultValue: "Clockwork",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "1:-3,4:-2,3:-4,6:+3,1:-2,5:+3,2:-3,1:-1,3:+2", clocks: [1], par: 6),
        // Tempo.
        problem(7, String(localized: "level.escapement-7.title", defaultValue: "Counterweight",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .quad, "0:-2,2:+3,1:-2,0:-1", clocks: [0], par: 3),
        problem(8, String(localized: "level.escapement-8.title", defaultValue: "Snooze",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "0:-1,1:+4,0:-3,2:-4,3:-3,4:-5,0:-1", clocks: [0], par: 5),
        problem(9, String(localized: "level.escapement-9.title", defaultValue: "Hourglass",
                          comment: "Escapement level title, a part of a clock or a word for time"),
                .eye, "2:-3,0:+3,2:-2,3:+4,0:-3,2:-1,3:+3", clocks: [2], par: 6),
        problem(10, String(localized: "level.escapement-10.title", defaultValue: "Egg timer",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "0:-3,3:+3,2:-3,1:-2,0:-2,1:-4,0:-1,2:+3", clocks: [0], par: 6),
        problem(11, String(localized: "level.escapement-11.title", defaultValue: "Stopwatch",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "0:-3,1:+2,0:-2,2:+3,4:+5,0:-2,3:+2,4:-3,0:-1,3:-2", clocks: [0], par: 8),
        problem(12, String(localized: "level.escapement-12.title", defaultValue: "Standstill",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "1:-2,5:+4,2:+5,1:-2,3:+3,2:-3,1:-2,3:-4,0:-5,1:-1", clocks: [1], par: 7),
        // Two Clocks.
        problem(13, String(localized: "level.escapement-13.title", defaultValue: "Twin dials",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .quad, "0:-1,2:-2,1:+3,0:-1,2:-1,3:+2", clocks: [0, 2], par: 3),
        problem(14, String(localized: "level.escapement-14.title", defaultValue: "Hour hand",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .quad, "0:-1,1:+3,0:-1,3:+3,2:-2,0:-2,3:-3", clocks: [0, 2], par: 4),
        problem(15, String(localized: "level.escapement-15.title", defaultValue: "Minute hand",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "2:-1,3:-4,2:-4,4:-5,0:-2,4:+2,0:-1,4:-5", clocks: [0, 2], par: 5),
        problem(16, String(localized: "level.escapement-16.title", defaultValue: "Metronome",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "4:-2,2:+5,5:-3,4:-3,6:+4,1:-3,5:+2,4:-1,3:+2", clocks: [1, 4], par: 6),
        problem(17, String(localized: "level.escapement-17.title", defaultValue: "Chime",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "1:-3,3:+4,4:-3,0:-1,3:-5,1:-1,0:-1,4:+2,1:-1,0:-1,3:+5", clocks: [0, 1], par: 5),
        problem(18, String(localized: "level.escapement-18.title", defaultValue: "Cuckoo clock",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "2:-2,6:+2,3:-4,2:-2,4:-2,1:-1,5:+2,2:-1,1:-1,4:+4,2:-1,1:-1,5:-4", clocks: [1, 2], par: 6),
        // Wound Back.
        problem(19, String(localized: "level.escapement-19.title", defaultValue: "Rewind",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .tri, "0:+1,1:-3,0:+2,2:+4", clocks: [0], back: [0], par: 3),
        problem(20, String(localized: "level.escapement-20.title", defaultValue: "Fall back",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .quad, "2:+1,1:+3,2:+1,1:-3,2:+1,0:-1,1:-4,2:+2,0:-2,1:+5", clocks: [0, 2], back: [2], par: 5),
        problem(21, String(localized: "level.escapement-21.title", defaultValue: "Mirror dial",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "0:+2,3:+2,4:+5,0:+2,3:+3,2:-2,4:-3,0:+2,3:-4,2:-1", clocks: [0, 2], back: [0], par: 6),
        problem(22, String(localized: "level.escapement-22.title", defaultValue: "Anticlockwise",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "4:+2,2:-2,5:+3,4:+2,6:-5,1:-2,3:-2,4:+3,6:-5,1:-2,5:+3", clocks: [1, 4], back: [4], par: 7),
        problem(23, String(localized: "level.escapement-23.title", defaultValue: "Overwound",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "0:+2,3:-5,4:-5,0:+3,2:-2,3:+4,4:-3,0:+1,3:-4", clocks: [0], back: [0], par: 6),
        problem(24, String(localized: "level.escapement-24.title", defaultValue: "Reverse",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "1:+3,4:-2,5:+4,2:+2,1:+2,3:+3,2:-5,1:+2,3:+2,6:-2", clocks: [1], back: [1], par: 7),
        // Grand Complication.
        problem(25, String(localized: "level.escapement-25.title", defaultValue: "Moon phase",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "1:-2,3:-1,5:-3,0:+3", clocks: [1, 3, 5], par: 3),
        problem(26, String(localized: "level.escapement-26.title", defaultValue: "Calendar",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "2:-2,4:-3,3:+2,2:-2,4:+3,3:+5,2:-3,0:-2,4:+2,0:-2,3:+3,2:-1,1:+2", clocks: [0, 2], par: 8),
        problem(27, String(localized: "level.escapement-27.title", defaultValue: "Time zones",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .pent, "0:-3,3:-4,2:-5,1:-5,0:-2,1:+2,0:-1,1:+2,0:-2,2:+5,1:-2,0:-1,2:+2", clocks: [0], par: 9),
        problem(28, String(localized: "level.escapement-28.title", defaultValue: "Leap year",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "1:-2,0:+5,1:-3,4:-5,3:+3,6:+4,1:-2,5:-4,2:+3,1:-2,4:+5,2:+4", clocks: [1], par: 9),
        problem(29, String(localized: "level.escapement-29.title", defaultValue: "Eleventh hour",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "5:-1,4:+3,5:-2,2:+3,0:-5,5:-5,2:+4,3:-2,1:-2,2:+2,3:-2,1:-2,4:+3", clocks: [1, 3, 5], par: 8),
        problem(30, String(localized: "level.escapement-30.title", defaultValue: "Midnight",
                           comment: "Escapement level title, a part of a clock or a word for time"),
                .hex, "1:-4,5:+2,4:+2,5:+3,6:-4,3:-2,1:-4,5:-4,4:+5,3:-2,5:-3,0:+2", clocks: [1, 3], par: 8),
    ]

    /// The book's chapters, six problems each.
    static let escapementChapters = [
        String(localized: "chapter.escapement.1", defaultValue: "The Clock", comment: "Escapement chapter: one clock"),
        String(localized: "chapter.escapement.2", defaultValue: "Tempo",
               comment: "Escapement chapter: a chess player's word for a move as a unit of time"),
        String(localized: "chapter.escapement.3", defaultValue: "Two Clocks", comment: "Escapement chapter"),
        String(localized: "chapter.escapement.4", defaultValue: "Wound Back",
               comment: "Escapement chapter: a clock that ticks the other way"),
        String(localized: "chapter.escapement.5", defaultValue: "Grand Complication",
               comment: "Escapement chapter: a watchmaking word for a watch of many functions"),
    ]
    /// Each chapter's opener adds its rule to the stipulation, as its old title taught it (Jack's call N1, round 13),
    /// one whole key each so a translator sees both sentences together.
    private static func escapementOpener(_ chapter: Int, budget: Int) -> String {
        switch chapter {
        case 0: String(localized: "rule.escapement.1", defaultValue: "Unstir in \(budget) ticks. A clock ticks after every move. Each let-go is a move.",
                       comment: "Escapement's note under the tank opening its first chapter: the tick budget, then the chapter's rule")
        case 1: String(localized: "rule.escapement.2", defaultValue: "Unstir in \(budget) ticks. Sometimes the first move is to wait.",
                       comment: "Escapement's note under the tank opening its second chapter: the tick budget, then the chapter's rule")
        case 2: String(localized: "rule.escapement.3", defaultValue: "Unstir in \(budget) ticks. Two clocks tick in turn.",
                       comment: "Escapement's note under the tank opening its third chapter: the tick budget, then the chapter's rule")
        case 3: String(localized: "rule.escapement.4", defaultValue: "Unstir in \(budget) ticks. A wound-back clock ticks the other way.",
                       comment: "Escapement's note under the tank opening its fourth chapter: the tick budget, then the chapter's rule")
        default: String(localized: "rule.escapement.5", defaultValue: "Unstir in \(budget) ticks. Three clocks.",
                       comment: "Escapement's note under the tank opening its fifth chapter: the tick budget, then the chapter's rule")
        }
    }

    private static func problem(_ n: Int, _ title: String, _ layout: Layout, _ scramble: String, clocks: [Int],
                                back: [Int] = [], par: Int) -> Level {
        var level = Level(id: Pack.escapement.id(n), pack: .escapement, label: String(format: "%02d", n), title: title,
                          picture: .engineTurned, layout: layout, scramble: .parse(scramble, in: layout), ratchets: Set(clocks), woundBack: Set(back),
                          chapter: escapementChapters[(n - 1) / 6],
                          // A heal hands the clock its seam and it ticks; a wait, and it ticks again.
                          demo: n == 1 ? .parse("0:-3,1:+2", in: .tri) : [], fixedPar: par)
        // Problem 2 is the first whose par needs a wait, so its stipulation names the control.
        level.note = (n - 1) % 6 == 0 ? escapementOpener((n - 1) / 6, budget: level.budget)
            : n == 2 ? String(localized: "rule.escapement.wait", defaultValue: "Unstir in \(level.budget) ticks. Tap wait: the clock ticks, nothing turns.",
                              comment: "Escapement's note under the tank on problem 2, the first that needs a wait: the tick budget, then what the wait control does")
            : String(localized: "Unstir in \(level.budget) ticks.",
                     comment: "Escapement's stipulation under the tank: the tick budget")
        return level
    }

    /// Prism's 30 specimens, `docs/prism-design.md`'s table: five trays of six, each on its own plate. One white rod holds
    /// only the bottom entry, so no channel is ever clean alone; no entry merges as it is dealt; every stack is at most 8
    /// deep, as deeper ones read too busy (Jack's call PK1); par is the depth (`testPrismLevels`), the solver's optimum
    /// (`testPrismParIsTheOptimum`). `scripts/prism-levels.sh table` measures them.
    static let prism: [Level] = [
        // Two Colours, on the fern: red and cyan, which share no channel, so they always pass each other.
        (Layout.tri, "0:r,1:c,2:w", "2:+3,0:+4,1:-3",
         String(localized: "level.prism-1.title", defaultValue: "Frond",
                comment: "Prism level title, the plate's specimen")),
        (.quad, "0:r,1:c,2:r,3:w", "3:+3,2:-4,1:+3,0:+5",
         String(localized: "level.prism-2.title", defaultValue: "Bracken",
                comment: "Prism level title, the plate's specimen")),
        (.eye, "0:r,1:c,2:r,3:w", "3:+4,0:-3,2:+2,1:+5,0:+3",
         String(localized: "level.prism-3.title", defaultValue: "Fiddlehead",
                comment: "Prism level title, the plate's specimen")),
        (.quad, "0:r,1:r,2:c,3:w", "3:-3,0:+3,1:+4,2:-5,0:-2,1:+3",
         String(localized: "level.prism-4.title", defaultValue: "Maidenhair",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:r,1:r,2:c,3:c,4:w", "4:+3,0:+4,2:-3,1:+2,3:+4,0:-3,2:+5",
         String(localized: "level.prism-5.title", defaultValue: "Spore",
                comment: "Prism level title, the plate's specimen")),
        (.hex, "0:c,1:c,2:c,3:r,4:r,5:w,6:c", "5:-2,1:+5,6:+3,1:-5,4:-5,0:+3,2:-3,3:-4",
         String(localized: "level.prism-6.title", defaultValue: "Tree fern",
                comment: "Prism level title, the plate's specimen")),
        // Three Colours, on the seed heads: red, green and blue, three words that never meet.
        (.quad, "0:b,1:g,2:r,3:w", "3:-4,2:-5,1:-4,0:-3",
         String(localized: "level.prism-7.title", defaultValue: "Dandelion",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:b,1:g,2:r,3:w,4:r", "3:+3,1:-5,0:+4,4:-4,2:-2",
         String(localized: "level.prism-8.title", defaultValue: "Thistle",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:r,1:g,2:b,3:w,4:r", "3:-3,2:+2,1:-2,0:+3,4:+2,0:-2",
         String(localized: "level.prism-9.title", defaultValue: "Sunflower",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:g,1:g,2:r,3:b,4:w", "4:+4,2:+4,1:+2,0:+2,3:+5,1:+3",
         String(localized: "level.prism-10.title", defaultValue: "Poppy",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:g,1:w,2:b,3:b,4:r", "1:-5,2:-4,3:-5,0:+3,2:-5,4:-5,3:+5",
         String(localized: "level.prism-11.title", defaultValue: "Sycamore",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:b,1:w,2:r,3:r,4:g", "1:+5,2:-2,4:+3,0:+4,3:-2,2:-3,3:-3,2:+4",
         String(localized: "level.prism-12.title", defaultValue: "Acorn",
                comment: "Prism level title, the plate's specimen")),
        // Colour Order, on the medusae: cyan, magenta and yellow, each pair sharing a channel, so overlapping inks block.
        (.tri, "0:m,1:c,2:w", "2:-5,1:+5,0:-4,1:-5",
         String(localized: "level.prism-13.title", defaultValue: "Jellyfish",
                comment: "Prism level title, the plate's specimen")),
        (.quad, "0:w,1:m,2:c,3:y", "0:-5,1:+4,3:-4,2:-2",
         String(localized: "level.prism-14.title", defaultValue: "Moon jelly",
                comment: "Prism level title, the plate's specimen")),
        (.quad, "0:y,1:w,2:m,3:c", "1:-3,2:-3,0:+5,3:+3,2:+5",
         String(localized: "level.prism-15.title", defaultValue: "Sea nettle",
                comment: "Prism level title, the plate's specimen")),
        (.eye, "0:c,1:w,2:y,3:m", "1:+5,0:+5,2:-2,0:-5,3:+5",
         String(localized: "level.prism-16.title", defaultValue: "Tentacles",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:c,1:c,2:m,3:w,4:y", "3:+3,0:+5,4:+3,0:+3,2:-2,1:+2",
         String(localized: "level.prism-17.title", defaultValue: "Lion's mane",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:m,1:y,2:c,3:w,4:y", "3:+3,2:+5,4:+5,1:+4,0:-3,1:-5,2:-3",
         String(localized: "level.prism-18.title", defaultValue: "Compass jelly",
                comment: "Prism level title, the plate's specimen")),
        // Overprint, on the radiolarians: primaries and inks together; red passes cyan, and blocks yellow and magenta.
        (.quad, "0:c,1:b,2:y,3:w", "3:-5,2:-2,1:-4,0:+3,1:-3,0:-3",
         String(localized: "level.prism-19.title", defaultValue: "Plankton",
                comment: "Prism level title, the plate's specimen")),
        (.eye, "0:w,1:m,2:g,3:b", "0:-2,2:+3,3:+4,1:+3,3:-2,1:-4",
         String(localized: "level.prism-20.title", defaultValue: "Lattice",
                comment: "Prism level title, the plate's specimen")),
        (.eye, "0:w,1:b,2:y,3:m", "0:-4,3:+5,1:-2,2:-3,3:+5,1:+3,3:-4",
         String(localized: "level.prism-21.title", defaultValue: "Pollen",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:c,1:w,2:b,3:m,4:g", "1:+3,4:-2,0:+2,2:-2,3:+5,4:-5,2:+5",
         String(localized: "level.prism-22.title", defaultValue: "Sunburst",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:m,1:r,2:c,3:b,4:w", "4:+5,3:+2,0:-5,2:-3,1:+3,0:-5,1:-2,0:+2",
         String(localized: "level.prism-23.title", defaultValue: "Sea urchin",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:y,1:w,2:g,3:c,4:m", "1:-2,4:-5,3:-5,0:+3,2:+3,3:+3,4:+2,3:+2",
         String(localized: "level.prism-24.title", defaultValue: "Honeycomb",
                comment: "Prism level title, the plate's specimen")),
        // Spectrum, on the nautilus: every mask on one tank.
        (.tri, "0:w,1:m,2:r", "0:+2,1:+5,2:+3,1:-2,2:-2,1:-3",
         String(localized: "level.prism-25.title", defaultValue: "Ammonite",
                comment: "Prism level title, the plate's specimen")),
        (.quad, "0:y,1:c,2:r,3:w", "3:+5,2:+4,1:-4,0:-4,1:-4,0:+2,1:-4",
         String(localized: "level.prism-26.title", defaultValue: "Oyster",
                comment: "Prism level title, the plate's specimen")),
        (.eye, "0:b,1:w,2:m,3:y", "1:-4,0:+3,2:-2,3:-3,0:+5,2:+3,0:+3",
         String(localized: "level.prism-27.title", defaultValue: "Conch",
                comment: "Prism level title, the plate's specimen")),
        (.eye, "0:w,1:r,2:m,3:b", "0:-3,2:-2,3:-3,1:-5,2:+4,1:+5,2:-2,1:-2",
         String(localized: "level.prism-28.title", defaultValue: "Pearl",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:c,1:m,2:b,3:y,4:w", "4:-4,3:+5,0:-3,2:+2,1:+4,2:-3,1:+3,0:-4",
         String(localized: "level.prism-29.title", defaultValue: "Scallop",
                comment: "Prism level title, the plate's specimen")),
        (.pent, "0:y,1:m,2:r,3:w,4:g", "3:-3,2:+2,1:-2,2:-2,0:+3,4:+2,1:+2,0:-2",
         String(localized: "level.prism-30.title", defaultValue: "Nautilus",
                comment: "Prism level title, the plate's specimen")),
    ].enumerated().map { i, row in
        let (layout, mask, scramble, title): (Layout, String, String, String) = row
        let masks = Channels.masks(mask)!, tray = i / 6
        return Level(id: Pack.prism.id(i + 1), pack: .prism, label: String(format: "%02d", i + 1), title: title,
                     note: i % 6 == 0 ? prismNotes[tray] : "", picture: prismPlates[tray], layout: layout,
                     scramble: .parse(scramble, in: layout, masks: masks), chapter: prismTrays[tray], masks: masks)
    }

    /// Prism's trays, six specimens each, and the plate each is engraved on.
    static let prismTrays = [
        String(localized: "chapter.prism.1", defaultValue: "Two Colours", comment: "Prism tray: red and cyan"),
        String(localized: "chapter.prism.2", defaultValue: "Three Colours", comment: "Prism tray: red, green and blue"),
        String(localized: "chapter.prism.3", defaultValue: "Colour Order",
               comment: "Prism tray: inks that block each other"),
        String(localized: "chapter.prism.4", defaultValue: "Overprint",
               comment: "Prism tray: a printing word, primaries and inks together"),
        String(localized: "chapter.prism.5", defaultValue: "Spectrum", comment: "Prism tray: every colour"),
    ]
    static let prismPlates: [Picture] = [.fern, .seeds, .medusae, .radiolaria, .nautilus]
    /// Each tray's opener says the rule it adds, as the first tray's says the pack's.
    static let prismNotes = [
        String(localized: "rule.prism.1", defaultValue: "Each rod stirs only its knob's colours.",
               comment: "Prism's first tray's rule, under the tank"),
        String(localized: "rule.prism.2", defaultValue: "Red, green and blue pass through each other.",
               comment: "Prism's second tray's rule, under the tank"),
        String(localized: "rule.prism.3", defaultValue: "Inks that share a colour block each other.",
               comment: "Prism's third tray's rule, under the tank"),
        String(localized: "rule.prism.4", defaultValue: "Red passes cyan, and blocks yellow and magenta.",
               comment: "Prism's fourth tray's rule, under the tank"),
        String(localized: "rule.prism.5", defaultValue: "White stirs every colour.",
               comment: "Prism's fifth tray's rule, under the tank"),
    ]

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
    /// The editors' build (`EDITORS = YES`, Config/Unstir.xcconfig), for App Store editors on its own TestFlight group:
    /// settings shows a switch that opens every tier. Any other Release build compiles the switch out (guideline 2.5.19
    /// bars a hidden one, so it is in no build but this).
    static let editors: Bool = {
        #if EDITORS
        true
        #else
        false
        #endif
    }()
    #if EDITORS || DEBUG
    /// Whether settings shows the editors' switch: the editors' build, or a Debug launch with UNSTIR_EDITORS=1.
    @MainActor static var editorsSwitch = editors
    #endif
}
