// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import XCTest
import simd
@testable import Unstir

final class FirstStirTests: XCTestCase {
    /// First Stir's harbour under an id no level has, so solving it saves no best.
    private func harbour(_ scramble: String = "2:+5,1:-4,0:+3", layout: Unstir.Layout = .tri) -> Level {
        var level = Level.firstStir[0]
        level.id = "first-stir-test"
        level.layout = layout
        level.scramble = .parse(scramble, in: layout)
        return level
    }

    /// A heal plays its rod's vignette and rings magenta; cancelling a push of the player's own plays none and rings
    /// nothing; the pack's undo brings the vignette back with its entry, and the solve has played all three.
    @MainActor func testAHealPlaysItsVignette() {
        let game = Game(level: harbour(), bank: (undos: 10, refilled: nil))
        XCTAssertEqual(game.played, [])
        game.commit(rod: 1, steps: 2)
        game.commit(rod: 1, steps: -2)
        XCTAssertEqual(game.played, [])
        XCTAssertEqual(game.cancels, 0)
        let dealt = game.entries
        game.commit(rod: 0, steps: -3)
        XCTAssertEqual(game.played, [0])
        XCTAssertEqual(game.cancels, 1)
        game.undo()
        XCTAssertEqual(game.played, [])
        XCTAssertEqual(game.entries, dealt)
        XCTAssertEqual(game.cancels, 1)
        game.commit(rod: 0, steps: -3)
        game.commit(rod: 1, steps: 4)
        XCTAssertEqual(game.played, [0, 1])
        game.commit(rod: 2, steps: -5)
        XCTAssertEqual(game.played, [0, 1, 2])
        // The lighthouse's heal rang twice, once either side of the undo.
        XCTAssertEqual(game.cancels, 4)
        XCTAssertTrue(game.solved)
    }

    /// A reset brings every vignette back.
    @MainActor func testAResetUnplaysEveryVignette() {
        let game = Game(level: harbour())
        game.commit(rod: 0, steps: -3)
        game.commit(rod: 1, steps: 4)
        XCTAssertEqual(game.played, [0, 1])
        XCTAssertTrue(game.reset())
        XCTAssertEqual(game.played, [])
        XCTAssertEqual(game.entries.map(\.tags), [[2], [1], [0]])
    }

    /// A vignette waits for every entry on its rod: here the lighthouse's two, which merge once the cottage's heal lets
    /// the newer fall onto the older. Quad's rods 0 and 2 never meet, and rod 1 holds no entry, so the boat has played.
    @MainActor func testAVignetteWaitsForEveryEntryOnItsRod() {
        let game = Game(level: harbour("0:+2,2:+3,0:+1", layout: .quad))
        XCTAssertEqual(game.played, [1])
        game.commit(rod: 2, steps: -3)
        XCTAssertEqual(game.played, [1, 2])
        XCTAssertEqual(game.stack, [Twist(rod: 0, steps: 3)])
        XCTAssertEqual(game.cancels, 1)
        game.commit(rod: 0, steps: -3)
        XCTAssertEqual(game.played, [0, 1, 2])
        XCTAssertEqual(game.cancels, 2)
    }

    /// A win the fine pass calls on a stack that only looks solved plays every vignette still held back.
    @MainActor func testALooksSolvedWinPlaysTheRest() async throws {
        // testIdentityStackIsSolved's stack, dealt as it stands: parsed, it would merge.
        let captured = "1:-4 3:+2 0:-6 3:+7 0:-5 2:+2 1:+4 2:-6 1:-4 0:+11 1:+4 2:+6 1:-4 2:-2 1:+4 0:-6 3:-7 0:+6 3:-2 0:+1"
        var level = harbour(layout: .quad)
        level.scramble = captured.split(separator: " ").map { t in Twist(rod: Int(t.prefix(1))!, steps: Int(t.dropFirst(2))!) }
        let game = Game(level: level)
        game.commit(rod: 0, steps: -1)
        XCTAssertFalse(game.solved)
        XCTAssertEqual(game.played, [])
        // The fine pass runs off the main actor, about 1 s in Debug.
        let deadline = ContinuousClock.now + .seconds(10)
        while !game.solved, .now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(game.solved)
        XCTAssertEqual(game.played, [0, 1, 2])
    }

    /// Every level of the pack is its story's: plughole rules, every vignette held back by the scramble as it opens.
    func testTheTable() throws {
        XCTAssertFalse(Level.firstStir.isEmpty)
        for level in Level.firstStir {
            let story = try XCTUnwrap(level.story, level.id)
            XCTAssertEqual(level.pack, .firstStir)
            XCTAssertEqual(level.layout, Harbour.layout, level.id)
            XCTAssertEqual(level.motion, .none, level.id)
            XCTAssertTrue(level.seized.isEmpty && level.sockets.isEmpty && level.ratchets.isEmpty, level.id)
            XCTAssertEqual(level.par, level.scramble.count, level.id)
            XCTAssertFalse(level.note.isEmpty, level.id)
            XCTAssertTrue(story.vignettes.isSubset(of: level.layout.rods.indices), level.id)
            XCTAssertEqual(story.vignettes, story.vignettes.intersection(level.scramble.map(\.rod)), "\(level.id) opens with one played")
        }
    }

    /// The layers bake at the screen's scale on the largest phone, and at a lower one rather than pass the budget.
    func testTheLayersBakeWithinTheBudget() {
        // The Pro Max's tank: (440 points wide) / 1.045.
        let side: CGFloat = 421
        XCTAssertEqual(Harbour.bakeScale(side: side, scale: 3), 3)
        XCTAssertLessThanOrEqual(Harbour.layerBytes(side: side, scale: 3), Harbour.budget)
        let huge = Harbour.bakeScale(side: 2 * side, scale: 3)
        XCTAssertLessThan(huge, 3)
        XCTAssertLessThanOrEqual(Harbour.layerBytes(side: 2 * side, scale: huge), Harbour.budget)
    }
}
