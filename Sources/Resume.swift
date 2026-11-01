// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// An unfinished try, as the calls the player made (Jack's call C2, round 13): replayed through the same `Game` calls,
/// they bring back what `Game.history` can't, which joins turns of one rod and drops what an undo took off.
struct Resume: Codable, Equatable {
    /// A turn names the knob, not the slot: the replay turns the tank the same way first, so each maps alike.
    enum Action: Codable, Equatable {
        case turn(knob: Int, steps: Int), tank(Int), wait(ratchet: Int), undo, reset
    }

    var version = 1
    /// The level's id; "endless" for the run.
    let id: String
    /// `Level.print` as saved: a level that no longer deals the same drops the save.
    let print: String
    /// `Game.firstTry` as the try began, which the try's own first move has since changed on disk.
    let firstTry: Bool
    var seconds: Double
    var actions: [Action]
    /// Endless: the run as this tank opened, and the brim as the try left it, for the menu's row.
    var run: Run?
    var brim: Int?

    init(id: String, print: String, firstTry: Bool, seconds: Double = 0, actions: [Action] = [], run: Run? = nil,
         brim: Int? = nil) {
        self.id = id
        self.print = print
        self.firstTry = firstTry
        self.seconds = seconds
        self.actions = actions
        self.run = run
        self.brim = brim ?? run?.brim
    }

    @MainActor init(of game: Game) {
        self.init(id: game.level.id, print: game.level.print, firstTry: game.firstTry, seconds: game.played(),
                  actions: game.actions, run: game.level.run, brim: game.level.run == nil ? nil : game.brim)
    }

    static func key(_ id: String) -> String { "resume.\(id)" }

    static func load(_ id: String) -> Resume? {
        UserDefaults.standard.data(forKey: key(id)).flatMap { try? JSONDecoder().decode(Resume.self, from: $0) }
    }

    static func save(_ r: Resume) {
        UserDefaults.standard.set(try? JSONEncoder().encode(r), forKey: key(r.id))
    }

    static func remove(_ id: String) { UserDefaults.standard.removeObject(forKey: key(id)) }

    /// A save with nothing played is none. Endless's is kept, as it carries the run from tank to tank.
    @MainActor static func save(_ game: Game) {
        guard game.storesResume, !game.replaying, !game.finished else { return }
        if !game.actions.isEmpty { save(Resume(of: game)) } else if game.level.run == nil { remove(game.level.id) }
    }

    /// At launch: every save but those of `known` ids goes, so yesterday's daily and a level an update took out never
    /// come back.
    @MainActor static func prune(known: Set<String>, defaults: UserDefaults = .standard) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("resume.") {
            let id = String(key.dropFirst("resume.".count))
            guard !known.contains(id) else { continue }
            defaults.removeObject(forKey: key)
            Log.write("resume \(id) dropped: no such level")
        }
    }

    /// Every id a save can belong to today.
    static var known: Set<String> {
        Set(Tier.allCases.flatMap(\.levels).map(\.id) + Pack.allCases.flatMap(\.levels).map(\.id) + ["endless", Level.daily().id])
    }

    /// UNSTIR_RESUME's line: UNSTIR_MOVES's `rod:steps`, rod -1 the tank and a ratchet's turn a wait, with `u` an undo
    /// and `r` a reset.
    static func actions(_ line: String, on level: Level) -> [Action] {
        line.split(separator: ",").compactMap { move in
            if move == "u" { return .undo }
            if move == "r" { return .reset }
            let f = move.split(separator: ":").compactMap { Int($0) }
            guard f.count == 2, f[1] != 0 else { return nil }
            if f[0] == Game.tank { return .tank(f[1]) }
            return level.kind(of: f[0]) == .ratchet ? .wait(ratchet: f[0]) : .turn(knob: f[0], steps: f[1])
        }
    }
}

extension Level {
    /// What deals the level, as a stable string: a save made on a level an update has since re-dealt is dropped.
    var print: String {
        func set(_ s: Set<Int>) -> String { s.sorted().map(String.init).joined(separator: ",") }
        let masks = self.masks.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value.rawValue)" }.joined(separator: ",")
        let run = self.run.map { " run=\($0.seed):\($0.tank):\($0.brim)" } ?? ""
        return "\(layout.rawValue) [\(scramble.map(\.description).joined(separator: ","))] seized=\(set(seized)) "
            + "sockets=\(set(sockets)) ratchets=\(set(ratchets)) back=\(set(woundBack)) lenses=\(set(lenses)) "
            + "masks=\(masks) motion=\(motion) par=\(par)\(run)"
    }
}
