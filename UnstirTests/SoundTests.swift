// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// The files the effects play, and when Escapement's ticks sound.
@MainActor final class SoundTests: XCTestCase {
    /// Every effect, each of its variants, names a file the bundle holds where `Sound.use` loads the effects, and none is
    /// a bed's name, which `use` would take for a bed.
    func testEveryEffectNamesABundledFile() {
        let effects: [Sound.Effect] = [.push, .seized, .solve, .spilled, .tap, .undo, .reset, .tier, .ratchet]
            + (1...6).map { .heal($0) }
        for effect in effects {
            for n in 0..<4 {
                let name = Sound.file(effect, n)
                XCTAssertNotNil(Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Sounds/glass"),
                                "\(effect) \(n): \(name)")
                XCTAssertNil(Sound.Bed(rawValue: name), name)
            }
        }
        XCTAssertEqual(Set((0..<4).map { Sound.file(.ratchet, $0) }).count, 4)
    }

    /// Jack's call soundsk2 = D (round 16): each clock's tick sounds as its core starts to turn, a beat after the lift
    /// and then a turn apart, in the order the clocks tick; an undo takes them back with the move.
    func testEachClocksTickSoundsAsItsCoreStartsToTurn() {
        var level = Level.escapement[12]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        XCTAssertEqual(g.ratchetTimes, [])
        g.commit(rod: 3, steps: -2)
        XCTAssertEqual(g.tick.map(\.rod), [0, 2])
        XCTAssertEqual(g.ratchetTimes.count, 2)
        for (t, want) in zip(g.ratchetTimes, [0.15, 0.45]) { XCTAssertEqual(t, want, accuracy: 1e-9) }
        g.undo()
        XCTAssertEqual(g.ratchetTimes, [])
        g.commit(rod: 3, steps: -2)
        g.commit(rod: 1, steps: -3)
        g.wait(on: 0)
        XCTAssertEqual(g.tick.map(\.rod), [2])
        XCTAssertEqual(g.ratchetTimes.count, 1)
        XCTAssertEqual(g.ratchetTimes[0], 0.15, accuracy: 1e-9)
    }

    /// The tick is Escapement's alone: only its levels have clocks, every one of them does, and a move anywhere else
    /// sounds none.
    func testOnlyEscapementTicks() {
        let levels = Tier.allCases.flatMap(\.levels) + Pack.allCases.flatMap(\.levels)
        XCTAssertEqual(Set(levels.filter { !$0.clocks.isEmpty }.map(\.pack)), [.escapement])
        XCTAssertTrue(Pack.escapement.levels.allSatisfy { !$0.clocks.isEmpty })
        var level = Level.plughole[0]
        level.id = "test-plughole"
        let g = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
        g.commit(rod: 1, steps: 2)
        XCTAssertEqual(g.ratchetTimes, [])
        g.commit(rod: 0, steps: -4)
        XCTAssertEqual(g.ratchetTimes, [])
    }
}
