// Copyright © 2026 Jack Lusher. All rights reserved.

import AVFoundation
import SwiftUI
import XCTest
@testable import Unstir

/// The files the effects play, and when Escapement's ticks sound.
@MainActor final class SoundTests: XCTestCase {
    /// Every effect, each of its variants, names a file the bundle holds where `Sound.use` loads the effects, and none is
    /// a bed's name, which `use` would take for a bed.
    func testEveryEffectNamesABundledFile() {
        let effects: [Sound.Effect] = [.push, .seized, .solve, .spilled, .tap, .undo, .reset, .tier, .ratchet, .tick]
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

    /// Jack's call SOUNDSK: each sold pack's level plays its layer (Lens B, Escapement B, Prism A) and nothing else
    /// does; every layer's loop and one-shots are in the bundle, its loop the 8 bars `Sound.beat` counts, and none
    /// is an effect's or a bed's name, which `Sound.use` would load with the effects or as a bed.
    func testEachSoldPackPlaysItsLayerFromBundledFiles() throws {
        XCTAssertEqual(Pack.lens.levels.first?.layer, .lens)
        XCTAssertEqual(Pack.escapement.levels.first?.layer, .escapement)
        XCTAssertEqual(Pack.prism.levels.first?.layer, .prism)
        XCTAssertNil(Pack.firstStir.levels.first?.layer)
        XCTAssertNil(Tier.plughole.levels[0].layer)
        let parts: [Sound.Layer: [String]] = [.lens: ["end"], .escapement: ["end", "d4"] + Sound.reeds, .prism: ["end", "swell"]]
        for (layer, names) in parts {
            let loop = try XCTUnwrap(Bundle.main.url(forResource: layer.loop, withExtension: "m4a", subdirectory: "Sounds/glass"))
            let file = try AVAudioFile(forReading: loop)
            XCTAssertEqual(Double(file.length) / file.processingFormat.sampleRate, 32 * Sound.beat, accuracy: 1e-6, layer.loop)
            for name in names.map(layer.part) {
                XCTAssertNotNil(Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Sounds/glass"), name)
            }
        }
        XCTAssertEqual(Sound.reeds.count, 8)
    }

    /// Steps a layer track as the fader does, every 20 ms from `from` to `to` with `wanted` wanted, and gives back every
    /// action it took, each step's level appended to `levels`.
    private static func run(_ track: inout Sound.LayerTrack, _ wanted: Sound.Layer?, from: Double, to: Double,
                            levels: inout [Float]) -> [Sound.LayerTrack.Action] {
        var actions: [Sound.LayerTrack.Action] = []
        var t = from
        while t < to {
            let a = track.step(wanted: wanted, now: t)
            if a != .none { actions.append(a) }
            levels.append(track.level)
            t += 0.02
        }
        return actions
    }

    /// Jack (2026-11-11): the next level of the same pack carries the loop on in place, never from its start. The solve
    /// ducks it under the resolution from the resolution's beat, and it comes back on the bar after, its beats counted
    /// from the same first beat; the next level wants the same layer, and the loop's player is neither stopped nor
    /// started again.
    func testTheNextLevelOfAPackCarriesItsLoopOn() throws {
        var track = Sound.LayerTrack()
        var levels: [Float] = []
        XCTAssertEqual(track.step(wanted: .lens, now: 100), .start(.lens, at: 100 + 0.05))
        XCTAssertEqual(Self.run(&track, .lens, from: 100.02, to: 110, levels: &levels), [])
        XCTAssertTrue(track.settled(wanted: .lens))
        let first = try XCTUnwrap(track.firstBeat)

        let beat = try XCTUnwrap(track.resolve(at: 110, ringing: 4.9))
        XCTAssertEqual((beat - first) / Sound.beat, ((beat - first) / Sound.beat).rounded(), accuracy: 1e-6)
        XCTAssertGreaterThan(beat, 110)
        let back = try XCTUnwrap(track.returning)
        XCTAssertEqual((back - first) / (4 * Sound.beat), ((back - first) / (4 * Sound.beat)).rounded(), accuracy: 1e-6)
        XCTAssertGreaterThanOrEqual(back, beat + 4.9)
        levels = []
        XCTAssertEqual(Self.run(&track, .lens, from: 110, to: beat, levels: &levels), [])
        XCTAssertEqual(levels.min(), 1, "the loop holds full to the resolution's beat")
        levels = []
        XCTAssertEqual(Self.run(&track, .lens, from: beat, to: back, levels: &levels), [])
        XCTAssertEqual(levels.last, 0, "ducked under the resolution")
        XCTAssertFalse(track.settled(wanted: .lens))
        levels = []
        XCTAssertEqual(Self.run(&track, .lens, from: back, to: back + 3, levels: &levels), [])
        XCTAssertEqual(levels.last, 1)
        XCTAssertTrue(track.settled(wanted: .lens))
        XCTAssertEqual(track.firstBeat, first)
        XCTAssertEqual(track.playing, .lens)
    }

    /// Back to the pack's list and into another of its levels within `Sound.hold`: the loop fades out and back in, run
    /// on unheard in between. Away longer, it stops; another pack's loop starts from its top.
    func testALoopLeftBrieflyIsTakenUpWhereItHasGotTo() throws {
        var track = Sound.LayerTrack()
        var levels: [Float] = []
        _ = Self.run(&track, .prism, from: 0, to: 5, levels: &levels)
        let first = try XCTUnwrap(track.firstBeat)
        levels = []
        XCTAssertEqual(Self.run(&track, nil, from: 5, to: 5 + Sound.hold - 1, levels: &levels), [])
        XCTAssertEqual(levels.last, 0)
        XCTAssertEqual(Self.run(&track, .prism, from: 5 + Sound.hold - 1, to: 25, levels: &levels), [])
        XCTAssertEqual(track.firstBeat, first)
        XCTAssertTrue(track.settled(wanted: .prism))

        XCTAssertEqual(Self.run(&track, nil, from: 25, to: 25 + 1.5 + Sound.hold + 1, levels: &levels), [.stop])
        XCTAssertNil(track.playing)
        XCTAssertNil(track.firstBeat)
        _ = Self.run(&track, .prism, from: 50, to: 55, levels: &levels)
        XCTAssertEqual(Self.run(&track, .escapement, from: 55, to: 56, levels: &levels), [.start(.escapement, at: 55 + 0.05)])
    }

    /// Left in the beat before the resolution, the loop holds to it, then fades over the resolution's half second and
    /// runs on unheard.
    func testALoopLeftJustAfterTheSolveHoldsToTheResolutionsBeat() throws {
        var track = Sound.LayerTrack()
        var levels: [Float] = []
        _ = Self.run(&track, .escapement, from: 0, to: 5, levels: &levels)
        let beat = try XCTUnwrap(track.resolve(at: 5.01, ringing: 2.5))
        levels = []
        _ = Self.run(&track, nil, from: 5.02, to: beat, levels: &levels)
        XCTAssertEqual(levels.min(), 1)
        levels = []
        _ = Self.run(&track, nil, from: beat, to: beat + 0.6, levels: &levels)
        XCTAssertEqual(levels.last, 0)
        XCTAssertEqual(track.playing, .escapement)
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
    /// haptic land with its last tick, the wave with them; a solve with no tick after its lift lands at the lift.
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
        XCTAssertEqual(g.tickCues.map(\.sounds), [[.ratchet]])
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
    }

    /// A solving move that ticks more than one clock: only its last tick solves, with the chime and the success haptic,
    /// and every tick before it is the ratchet with its rigid haptic. The book's lines stop their clocks one at a time,
    /// so the tank is dealt one step on each clock of the problem with the most, the first to tick on top: a wait pops
    /// them all in turn.
    func testOnlyTheLastOfASolvingMovesTicksSolves() {
        var level = Level.escapement.max { $0.clocks.count < $1.clocks.count }!
        level.id = "test-escapement"
        level.scramble = level.clocks.reversed().map { Twist(rod: $0.rod, steps: -$0.dir) }
        XCTAssertEqual(level.clocks.count, 3)
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        g.wait(on: level.clocks[0].rod)
        XCTAssertTrue(g.solved)
        XCTAssertEqual(g.tick.map(\.rod), level.clocks.map(\.rod))
        let cues = g.tickCues, last = cues.count - 1
        XCTAssertEqual(cues.count, 3)
        for (i, cue) in cues.enumerated() {
            XCTAssertEqual(cue.at, LevelView.tickBeat + LevelView.tickTurn * Double(i), accuracy: 1e-9)
            XCTAssertEqual(cue.solves, i == last, "tick \(i)")
            XCTAssertEqual(cue.sounds, [.ratchet], "tick \(i)")
            XCTAssertEqual(cue.haptic, i == last ? .success : Self.plain, "tick \(i)")
        }
        XCTAssertEqual(g.solveAt ?? -1, 0.75, accuracy: 1e-9)
    }

    /// The task hands the solving tick to the view, which lands the chime, haptic and wave once: the cue itself sounds only
    /// its ratchet, so a win whose own change also lands them can't play the chime twice.
    func testSoundTicksHandsTheSolvingTickToTheView() async {
        var level = Level.escapement.max { $0.clocks.count < $1.clocks.count }!
        level.id = "test-escapement"
        level.scramble = level.clocks.reversed().map { Twist(rod: $0.rod, steps: -$0.dir) }
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        g.wait(on: level.clocks[0].rod)
        XCTAssertTrue(g.solved)
        var felt: [TickCue] = []
        await g.soundTicks { felt.append($0) }
        XCTAssertEqual(felt.map(\.solves), [false, false, true])
        XCTAssertFalse(felt.contains { $0.sounds.contains(.solve) })
    }

    /// A move that runs the tank out of ticks plays its ticks as any other move does, after the out-of-ticks sound at the
    /// lift, as before the solve's chime moved: the ratchet and its haptic on each, and the move's first push over it.
    func testAMoveThatRunsOutOfTicksPlaysItsTicks() {
        var two = Level.escapement[1]
        two.id = "test-escapement"
        two.scramble = .parse("1:+3,0:-1", in: .tri)
        let h = Game(level: two, tankTurned: true, bank: (3, nil))
        h.wait(on: 0)
        XCTAssertTrue(h.lost)
        XCTAssertFalse(h.tick.isEmpty)
        XCTAssertEqual(h.tickCues.count, h.tick.count)
        XCTAssertFalse(h.tickCues.contains(where: \.solves))
        XCTAssertNil(h.solveAt)
        for (cue, t) in zip(h.tickCues, h.tick) {
            XCTAssertEqual(cue.sounds.first, .ratchet)
            XCTAssertEqual(cue.haptic, t.pushed ? .error : Self.plain)
        }
        Self.assertTheMovesFirstPushAloneSounds(h)
        h.undo()
        XCTAssertFalse(h.finished)
        XCTAssertEqual(h.tickCues, [])

        // 02's line out of ticks: its stir pushes, its clock's tick pushes after it, and a wait runs it out.
        var level = Level.escapement[1]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (3, nil))
        g.commit(rod: 2, steps: 4)
        g.commit(rod: 1, steps: -3)
        g.wait(on: 0)
        XCTAssertTrue(g.lost)
        XCTAssertFalse(g.tickCues.isEmpty)
        for (cue, t) in zip(g.tickCues, g.tick) {
            XCTAssertEqual(cue.sounds.first, .ratchet)
            XCTAssertEqual(cue.haptic, t.pushed ? .error : Self.plain)
        }
        Self.assertTheMovesFirstPushAloneSounds(g)
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

    /// The lines `scripts/sounds.sh layers` renders the packs' layers under (sound-src/layers-in-play.tsv) are real
    /// play: each solves its level, and each action sounds what the file says, read off a real Game as LevelView's
    /// changes play them.
    func testTheLayerLinesSoundAsTheGamePlaysThem() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("sound-src/layers-in-play.tsv")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { throw XCTSkip("no tsv at \(url.path)") }
        let rows = text.split(separator: "\n").filter { !$0.hasPrefix("#") }.map { $0.split(separator: "\t").map(String.init) }
        let levels = Pack.allCases.flatMap(\.levels)
        var games: [String: Game] = [:], heard: [String] = [], wrong = false
        for row in rows {
            XCTAssertEqual(row.count, 5, row.joined(separator: " "))
            guard row.count == 5 else { continue }
            let (id, action, want) = (row[1], row[3], row[4])
            var got = "tap"
            if action != "open" {
                let g: Game
                if let made = games[id] {
                    g = made
                } else {
                    var level = try XCTUnwrap(levels.first { $0.id == id }, id)
                    level.id = "test-" + id
                    g = Game(level: level, tankTurned: true, swirled: true, bank: (10, nil))
                    games[id] = g
                }
                let heals = g.heals, pushes = g.pushes, ticks = g.tickEvents, bank = g.bank
                var sounds: [String] = []
                switch action {
                case "u":
                    g.undo()
                    sounds.append(bank > 0 ? "undo" : "tap")
                case "wait":
                    XCTAssertTrue(g.wait(on: g.level.clocks[0].rod), "\(id) \(row[2])")
                default:
                    let move = action.split(separator: ":").compactMap { Int($0) }
                    g.commit(rod: move[0], steps: move[1])
                }
                if g.heals > heals { sounds.append("heal\(g.heals)") }
                if g.pushes > pushes && !g.spilled { sounds.append("push") }
                if g.tickEvents != ticks { sounds.append("tick\(g.tick.count)") }
                if g.finished { sounds.append(g.solved ? "solve" : "spilled") }
                got = sounds.isEmpty ? "-" : sounds.joined(separator: ",")
            }
            if got != want { wrong = true }
            heard.append((row.dropLast() + [got]).joined(separator: "\t"))
        }
        XCTAssertFalse(wrong, "the game sounds these:\n" + heard.joined(separator: "\n"))
        XCTAssertEqual(games.count, 3)
        for (id, g) in games { XCTAssertTrue(g.solved, id) }
    }
}
