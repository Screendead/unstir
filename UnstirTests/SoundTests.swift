// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
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

    /// Jack's calls soundsk2 = D and soundsk-haptic = B (round 16): each clock's tick sounds and lands its haptic as its
    /// core starts to turn, a beat after the lift and then a turn apart, in the order the clocks tick; an undo takes them
    /// back with the move.
    func testEachClocksTickSoundsAsItsCoreStartsToTurn() {
        var level = Level.escapement[12]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        XCTAssertEqual(g.tickCues, [])
        g.commit(rod: 3, steps: -2)
        XCTAssertEqual(g.tick.map(\.rod), [0, 2])
        XCTAssertEqual(g.tickCues.map(\.sounds), [[.ratchet], [.ratchet]])
        XCTAssertEqual(g.tickCues.map(\.haptic), [Self.plain, Self.plain])
        for (t, want) in zip(g.tickCues.map(\.at), [0.15, 0.45]) { XCTAssertEqual(t, want, accuracy: 1e-9) }
        XCTAssertNil(g.solveAt)
        g.undo()
        XCTAssertEqual(g.tickCues, [])
    }

    /// Jack's calls tk-push = B and tk-multi = C (round 16): every tick sounds its ratchet at its own time, a pushed one
    /// with the error haptic, and the move's first push sounds the push over its ratchet: the first pushed tick's, unless
    /// the move's own stir pushed, which then had it at the lift.
    func testAPushedTickSoundsThePushOverItsRatchetAtItsOwnTime() throws {
        let found = Pack.escapement.levels.lazy.compactMap { book -> (Level, Twist)? in
            var level = book
            level.id = "test-escapement"
            let working = level.layout.rods.indices.filter { level.kind(of: $0) == .working }
            let moves = working.flatMap { k in (1...11).flatMap { [$0, -$0] }.map { Twist(rod: k, steps: $0) } }
            return moves.first { t in
                let g = Game(level: level, tankTurned: true, bank: (3, nil))
                g.commit(rod: t.rod, steps: t.steps)
                return !g.stirPushed && g.tick.count > 1 && g.tick.contains { $0.pushed } && g.tick.contains { !$0.pushed }
            }.map { (level, $0) }
        }.first
        let (level, move) = try XCTUnwrap(found, "a move that doesn't push whose ticks mix a push with a plain tick")
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        g.commit(rod: move.rod, steps: move.steps)
        let cues = g.tickCues
        XCTAssertEqual(cues.count, g.tick.count)
        Self.assertEachPushFlagIsItsTicks(g)
        Self.assertTheMovesFirstPushAloneSounds(g)
        for (i, (cue, t)) in zip(cues, g.tick).enumerated() {
            XCTAssertEqual(cue.at, LevelView.tickBeat + LevelView.tickTurn * Double(i), accuracy: 1e-9)
            XCTAssertEqual(cue.sounds.first, .ratchet, "tick \(i)")
            XCTAssertEqual(cue.haptic, t.pushed ? .error : Self.plain, "tick \(i)")
        }
        XCTAssertEqual(cues.filter { $0.sounds.contains(.push) }.count, 1)
        g.undo()
        XCTAssertEqual(g.tickCues, [])
    }

    /// 13: a wait whose ticks both push, as knob 3's seam lies over both clocks: the first sounds the push over its
    /// ratchet, the second only its ratchet, both with the error haptic, and its ratchets both flash red, not only the
    /// last clock's.
    func testTwoClocksPushingInOneMoveSoundThePushOnce() {
        var level = Level.escapement[12]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (1, nil))
        g.wait(on: 2)
        XCTAssertFalse(g.stirPushed)
        XCTAssertEqual(g.tick.map(\.rod), [0, 2])
        XCTAssertEqual(g.tick.map(\.pushed), [true, true])
        Self.assertEachPushFlagIsItsTicks(g)
        XCTAssertEqual(g.pushedClock, 2)
        XCTAssertEqual(g.tickCues.map(\.sounds), [[.ratchet, .push], [.ratchet]])
        XCTAssertEqual(g.tickCues.map(\.haptic), [.error, .error])
    }

    /// 02's 1:-3 buries its clock's seam, so the stir pushes at the lift and the clock's tick pushes after it: the tick
    /// sounds only its ratchet, with the error haptic, as the stir had the move's push.
    func testAStirThatPushedKeepsTheMovesPushFromItsTicks() {
        var level = Level.escapement[1]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        let pushes = g.pushes
        g.commit(rod: 1, steps: -3)
        XCTAssertEqual(g.pushes, pushes + 1)
        XCTAssertTrue(g.stirPushed)
        XCTAssertTrue(g.tick.contains { $0.pushed })
        Self.assertEachPushFlagIsItsTicks(g)
        Self.assertTheMovesFirstPushAloneSounds(g)
        XCTAssertFalse(g.tickCues.contains { $0.sounds.contains(.push) })
        for (cue, t) in zip(g.tickCues, g.tick) { XCTAssertEqual(cue.haptic, t.pushed ? .error : Self.plain) }
    }

    /// Jack's call tk-finish = B (round 16): the move that solves sounds its ticks, and the solve's chime and success
    /// haptic land with its last tick, the wave with them; a solve with no tick after its lift lands at the lift. A move
    /// that runs the tank out of ticks sounds only as its finish, at the lift: none of its ticks sounds or lands a haptic.
    func testTheSolveLandsWithTheSolvingTick() {
        var level = Level.escapement[12]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        g.commit(rod: 3, steps: -2)
        g.commit(rod: 1, steps: -3)
        XCTAssertFalse(g.tickCues.contains { $0.solves })
        g.wait(on: 0)
        XCTAssertTrue(g.solved)
        XCTAssertEqual(g.tick.map(\.rod), [2])
        XCTAssertEqual(g.tickCues.map(\.sounds), [[.ratchet, .solve]])
        XCTAssertEqual(g.tickCues.map(\.haptic), [.success])
        XCTAssertEqual(g.tickCues.map(\.solves), [true])
        XCTAssertEqual(g.solveAt ?? -1, LevelView.tickBeat, accuracy: 1e-9)

        var two = Level.escapement[1]
        two.id = "test-escapement"
        two.scramble = .parse("1:+3", in: .tri)
        let quick = Game(level: two, tankTurned: true, bank: (3, nil))
        quick.commit(rod: 1, steps: -3)
        XCTAssertTrue(quick.solved)
        XCTAssertEqual(quick.tick.count, 0)
        XCTAssertNil(quick.solveAt)

        two.scramble = .parse("1:+3,0:-1", in: .tri)
        let h = Game(level: two, tankTurned: true, bank: (3, nil))
        h.wait(on: 0)
        XCTAssertTrue(h.lost)
        XCTAssertFalse(h.tick.isEmpty)
        XCTAssertEqual(h.tickCues, [])
        XCTAssertNil(h.solveAt)
        h.undo()
        XCTAssertFalse(h.finished)
        XCTAssertEqual(h.tickCues, [])
    }

    /// The task the view runs plays every cue in turn, at its time from the ticks' landing, and an undo between two stops
    /// the rest.
    func testSoundTicksLandsEachCueInTurnUntilAnUndo() async {
        var level = Level.escapement[12]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        g.commit(rod: 3, steps: -2)
        let want = g.tickCues
        XCTAssertEqual(want.count, 2)
        var felt: [TickCue] = []
        await g.soundTicks { felt.append($0) }
        XCTAssertEqual(felt, want)
        XCTAssertGreaterThanOrEqual(ContinuousClock.now - g.landed, .seconds(want[1].at))
        felt = []
        await g.soundTicks { cue in
            felt.append(cue)
            g.undo()
        }
        XCTAssertEqual(felt, [want[0]])
    }

    /// Each tick's flag says whether it pushed: the stack it left is one entry deeper than the one it found.
    private static func assertEachPushFlagIsItsTicks(_ g: Game, file: StaticString = #filePath, line: UInt = #line) {
        for (i, t) in g.tick.enumerated() {
            let after = i + 1 < g.tick.count ? g.tick[i + 1].stack : g.stack
            XCTAssertEqual(t.pushed, after.count > t.stack.count, "tick \(i)", file: file, line: line)
        }
    }

    /// Only the move's first push sounds the push: the stir's, at the lift, or else its first pushed tick's.
    private static func assertTheMovesFirstPushAloneSounds(_ g: Game, file: StaticString = #filePath, line: UInt = #line) {
        let first = g.stirPushed ? nil : g.tick.firstIndex { $0.pushed }
        for (i, cue) in g.tickCues.enumerated() {
            XCTAssertEqual(cue.sounds.contains(.push), i == first, "tick \(i)", file: file, line: line)
        }
    }

    private static let plain = SensoryFeedback.impact(flexibility: .rigid, intensity: 0.9)

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
        XCTAssertEqual(g.tickCues, [])
        g.commit(rod: 0, steps: -4)
        XCTAssertEqual(g.tickCues, [])
    }
}
