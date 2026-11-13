// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// Game Center's achievements (Jack's call F5 = B, round 14; the list awaits his pick). Each is earned from the state
/// the game already stores, read afresh whenever it is asked (`Record`), so a player who signs in late is reported
/// everything they have already done, and nothing counts twice. Every input only ever grows (a best only improves, a
/// flag only sets, `Best.tanks` is a most), so a percent never goes down, which Game Center ignores anyway.
///
/// The raw value ends the id App Store Connect knows it by: once an achievement is live it can't be deleted nor its
/// points changed (AchievementTests pins them), so never rename a case.
enum Achievement: String, CaseIterable, Sendable {
    case firstDrop = "first-drop"
    case downThePlughole = "down-the-plughole"
    case intoTheVortex = "into-the-vortex"
    case theMaelstrom = "the-maelstrom"
    case unstirred
    case noWake = "no-wake"
    case turnOfTheTide = "turn-of-the-tide"
    case theEdgeTurns = "the-edge-turns"
    case todaysTank = "todays-tank"
    case aWeekOfTanks = "a-week-of-tanks"
    case brim
    case overTheLip = "over-the-lip"
    case inFocus = "in-focus"
    case timeWellSpent = "time-well-spent"
    case whiteLight = "white-light"
    case wholeShelf = "whole-shelf"

    var id: String { "com.screendead.Unstir.achievement.\(rawValue)" }

    var title: String {
        switch self {
        case .firstDrop: "First Drop"
        case .downThePlughole: "Down the Plughole"
        case .intoTheVortex: "Into the Vortex"
        case .theMaelstrom: "The Maelstrom"
        case .unstirred: "Unstirred"
        case .noWake: "No Wake"
        case .turnOfTheTide: "Turn of the Tide"
        case .theEdgeTurns: "The Edge Turns"
        case .todaysTank: "Today's Tank"
        case .aWeekOfTanks: "A Week of Tanks"
        case .brim: "Brim"
        case .overTheLip: "Over the Lip"
        case .inFocus: "In Focus"
        case .timeWellSpent: "Time Well Spent"
        case .whiteLight: "White Light"
        case .wholeShelf: "Whole Shelf"
        }
    }

    /// App Store Connect's pre-earned description; `earned` is its post-earned one.
    var goal: String {
        switch self {
        case .firstDrop: "Unstir a Plughole level."
        case .downThePlughole: "Solve every Plughole level."
        case .intoTheVortex: "Solve every Whirlpool level."
        case .theMaelstrom: "Solve every Vortex level."
        case .unstirred: "Reach par on every level of every tier."
        case .noWake: "Solve a daily clean: at par on the first try, with no undo or reset."
        case .turnOfTheTide: "Turn the tank."
        case .theEdgeTurns: "Stir the swirl."
        case .todaysTank: "Solve a daily on its first try."
        case .aWeekOfTanks: "Solve seven dailies on their first tries, on any days."
        case .brim: "Clear five tanks in one endless run."
        case .overTheLip: "Spill the brim."
        case .inFocus: "Solve every Lens level."
        case .timeWellSpent: "Solve every Escapement problem."
        case .whiteLight: "Solve every Prism specimen."
        case .wholeShelf: "Solve every level of Lens, Escapement and Prism."
        }
    }

    var earned: String {
        switch self {
        case .firstDrop: "Unstirred a Plughole level."
        case .downThePlughole: "Solved every Plughole level."
        case .intoTheVortex: "Solved every Whirlpool level."
        case .theMaelstrom: "Solved every Vortex level."
        case .unstirred: "Every level of every tier at par."
        case .noWake: "Solved a daily clean."
        case .turnOfTheTide: "Turned the tank."
        case .theEdgeTurns: "Stirred the swirl."
        case .todaysTank: "Solved a daily on its first try."
        case .aWeekOfTanks: "Solved seven dailies."
        case .brim: "Cleared five tanks in one run."
        case .overTheLip: "Spilled the brim."
        case .inFocus: "Solved every Lens level."
        case .timeWellSpent: "Solved every Escapement problem."
        case .whiteLight: "Solved every Prism specimen."
        case .wholeShelf: "Solved every level of Lens, Escapement and Prism."
        }
    }

    var points: Int {
        switch self {
        case .firstDrop, .turnOfTheTide, .theEdgeTurns, .todaysTank, .overTheLip: 5
        case .noWake, .aWeekOfTanks, .brim: 10
        case .downThePlughole: 15
        case .intoTheVortex, .inFocus, .timeWellSpent, .whiteLight: 20
        case .theMaelstrom: 25
        case .wholeShelf: 30
        case .unstirred: 50
        }
    }

    /// Nothing of it shows until earned. A pack's would otherwise be a shop window for a pack not bought.
    var hidden: Bool {
        switch self {
        case .overTheLip, .inFocus, .timeWellSpent, .whiteLight, .wholeShelf: true
        default: false
        }
    }

    /// The pitch's pressure flags, kept as it recommends, for Jack to keep or drop: a clean solve shuns the undo every
    /// player is given, a count of dailies pulls the player back, the most points ask the most, and a spill is a failure.
    var flagged: Bool { [.unstirred, .noWake, .aWeekOfTanks, .overTheLip].contains(self) }

    /// The packs Whole Shelf asks for, fixed: a later pack gets its own achievement, as points can't move once live.
    static let shelf: [(Achievement, Pack)] = [(.inFocus, .lens), (.timeWellSpent, .escapement), (.whiteLight, .prism)]

    /// Out of 100. Only A Week of Tanks and Brim report a share on the way; a hidden one reporting a share would show.
    func percent(_ r: Record) -> Double {
        func done(_ yes: Bool) -> Double { yes ? 100 : 0 }
        func open(_ tier: Tier) -> Bool { tier.isOpen(unlocked: false, r.best) }
        func whole(_ pack: Pack) -> Bool {
            pack.levels.count >= pack.planned && pack.levels.allSatisfy { r.best($0.id) != nil }
        }
        switch self {
        case .firstDrop: return done(Tier.plughole.levels.contains { r.best($0.id) != nil })
        case .downThePlughole: return done(open(.whirlpool))
        case .intoTheVortex: return done(open(.vortex))
        case .theMaelstrom: return done(open(.maelstrom))
        case .unstirred: return done(Tier.allCases.allSatisfy { $0.atPar(r.best).allSatisfy { $0 } })
        case .noWake: return done(r.clean)
        case .turnOfTheTide: return done(r.tankTurned)
        case .theEdgeTurns: return done(r.swirled)
        case .todaysTank: return done(r.dailies > 0)
        case .aWeekOfTanks: return Double(min(r.dailies, 7)) * 100 / 7
        case .brim: return Double(min(r.tanks, 5)) * 100 / 5
        case .overTheLip: return done(r.spilled)
        case .inFocus: return done(whole(.lens))
        case .timeWellSpent: return done(whole(.escapement))
        case .whiteLight: return done(whole(.prism))
        case .wholeShelf: return done(Self.shelf.allSatisfy { $0.0.percent(r) == 100 })
        }
    }

    /// What to report given what was reported before: each achievement whose percent has risen past it. Nothing at 0
    /// is reported, so a hidden one never shows unearned.
    static func due(_ r: Record, reported: [String: Double]) -> [(Achievement, Double)] {
        allCases.compactMap { a in
            let p = a.percent(r)
            return p > (reported[a.id] ?? 0) ? (a, p) : nil
        }
    }
}

extension Achievement {
    /// The stored state the achievements read. Nothing here is kept for them alone but `spilled`, which nothing else
    /// records.
    struct Record {
        var best: (String) -> Best? = { _ in nil }
        /// Dailies with a best: only a first try saves one, in any order of days.
        var dailies = 0
        /// Some daily's best is clean (`Game.clean`): only the daily shows clean, so only a daily earns No Wake (Jack,
        /// 2026-11-13).
        var clean = false
        var tankTurned = false
        var swirled = false
        /// Endless: most tanks cleared in one run.
        var tanks = 0
        var spilled = false

        static func stored() -> Record {
            let bests = UserDefaults.standard.dictionaryRepresentation().filter { $0.key.hasPrefix("best.") }
            let clean = bests.filter { $0.key.hasPrefix("best.daily-") }.values.contains { v in
                (v as? Data).flatMap { try? JSONDecoder().decode(Best.self, from: $0) }?.clean == true
            }
            return Record(best: Best.load, dailies: bests.keys.filter { $0.hasPrefix("best.daily-") }.count,
                          clean: clean, tankTurned: Best.tankTurned, swirled: Best.swirled, tanks: Best.tanks,
                          spilled: Best.spilled)
        }
    }
}
