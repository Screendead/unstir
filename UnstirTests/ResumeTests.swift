// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// Jack's call C2 (round 13): an unfinished level resumes, its saved calls replayed through the same `Game` calls.
@MainActor final class ResumeTests: XCTestCase {
    override func setUp() {
        for key in ["undos.spent", "undos.day", "undos.anchor", "undos.unseen", "undos.shown", "tank.turned"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /// Takes something off the stack: the newest twist a working knob reaches, else a turn of a turning tank, else a wait.
    private func heal(_ g: Game) {
        if let t = g.reachable { g.commit(rod: t.rod, steps: t.steps) } else if g.level.motion == .tank { g.turnTank(1) }
        else if let r = g.level.clocks.first?.rod { g.wait(on: r) }
    }

    /// A push, an undo, a heal, a reset, a heal, two turns of the tank where it turns, and a push, which leaves even the
    /// shortest of them unsolved.
    private func line(_ g: Game) {
        if let w = g.wasting { g.commit(rod: w.rod, steps: w.steps) }
        g.undo()
        heal(g)
        g.reset()
        heal(g)
        if g.level.motion == .tank { g.turnTank(1); g.turnTank(1) }
        if let w = g.wasting { g.commit(rod: w.rod, steps: w.steps) }
    }

    private func assertSame(_ a: Game, _ b: Game, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a.entries, b.entries, name, file: file, line: line)
        XCTAssertEqual(a.history, b.history, name, file: file, line: line)
        XCTAssertEqual(a.moves, b.moves, name, file: file, line: line)
        XCTAssertEqual(a.position, b.position, name, file: file, line: line)
        XCTAssertEqual(a.resets, b.resets, name, file: file, line: line)
        XCTAssertEqual(a.undos, b.undos, name, file: file, line: line)
        XCTAssertEqual(a.pushes, b.pushes, name, file: file, line: line)
        XCTAssertEqual(a.heals, b.heals, name, file: file, line: line)
        XCTAssertEqual(a.brim, b.brim, name, file: file, line: line)
        XCTAssertEqual(a.escapement.ticks, b.escapement.ticks, name, file: file, line: line)
        XCTAssertEqual(a.lost, b.lost, name, file: file, line: line)
        XCTAssertEqual(a.firstTry, b.firstTry, name, file: file, line: line)
        XCTAssertEqual(a.clean, b.clean, name, file: file, line: line)
        XCTAssertEqual(a.bank, b.bank, name, file: file, line: line)
        XCTAssertEqual(a.actions, b.actions, name, file: file, line: line)
    }

    func testResumeRebuildsEveryKindOfLevel() throws {
        let levels = [Level.plughole[11], Level.maelstrom[3], Level.vortex[4], Level.lens[2], Level.prism[0],
                      Level.escapement[1], Level.endless(Run(seed: 7, tank: 2, brim: 1)), Level.firstStir[0]]
        for level in levels {
            let g = Game(level: level, tankTurned: true, swirled: true, bank: (10, nil))
            g.startClock(at: Date(timeIntervalSinceNow: -42))
            line(g)
            XCTAssertFalse(g.finished, level.id)
            XCTAssertFalse(g.actions.isEmpty, level.id)
            let r = try JSONDecoder().decode(Resume.self, from: try JSONEncoder().encode(Resume(of: g)))
            let undos = Best.undos
            let back = try XCTUnwrap(Game.resumed(level, from: r, tankTurned: true, swirled: true, bank: (g.bank, nil),
                                                  storesResume: false), level.id)
            assertSame(g, back, level.id)
            XCTAssertEqual(back.played(), 42, accuracy: 1, level.id)
            XCTAssertEqual(Best.undos, undos, "a replayed undo spends nothing: \(level.id)")
        }
        // Endless refuses undo, so no saved run holds one.
        let run = Level.endless(Run(seed: 7, tank: 2, brim: 1))
        XCTAssertNil(Game.resumed(run, from: Resume(id: run.id, print: run.print, firstTry: true, actions: [.undo]),
                                  storesResume: false))
    }

    func testResumeDropsAChangedLevel() throws {
        let level = Level.plughole[11]
        let g = Game(level: level, bank: (10, nil))
        heal(g)
        let r = Resume(of: g)
        XCTAssertNotNil(Game.resumed(level, from: r, bank: (10, nil), storesResume: false))
        var redealt = level
        redealt.scramble = .parse("0:+4", in: level.layout)
        XCTAssertNil(Game.resumed(redealt, from: r, bank: (10, nil), storesResume: false), "an update re-dealt it")

        let maelstrom = Level.maelstrom[0], seized = try XCTUnwrap(maelstrom.seized.first)
        let refused = Resume(id: maelstrom.id, print: maelstrom.print, firstTry: true, actions: [.turn(knob: seized, steps: 1)])
        XCTAssertNil(Game.resumed(maelstrom, from: refused, bank: (10, nil), storesResume: false), "a seized knob refuses")
        let nothing = Resume(id: level.id, print: level.print, firstTry: true, actions: [.undo])
        XCTAssertNil(Game.resumed(level, from: nothing, bank: (10, nil), storesResume: false), "nothing to undo")
    }

    func testResumeClearsOnFinish() throws {
        let id = "resume-test", level = Level(id: id, label: "", title: "", layout: .tri, scramble: .parse("0:+4", in: .tri))
        defer { Resume.remove(id); Resume.remove("endless") }
        let g = Game(level: level, bank: (10, nil), storesProgress: false, storesResume: true)
        g.commit(rod: 1, steps: 2)
        XCTAssertEqual(Resume.load(id)?.actions, [.turn(knob: 1, steps: 2)])
        g.commit(rod: 1, steps: -2)
        XCTAssertEqual(Resume.load(id)?.actions.count, 2)
        g.commit(rod: 0, steps: -4)
        XCTAssertTrue(g.solved)
        XCTAssertNil(Resume.load(id), "a solve clears it")
        // "Again" deals afresh: its save replays through the solve without stopping there.
        g.reset()
        let again = try XCTUnwrap(Game.resumed(level, from: try XCTUnwrap(Resume.load(id)), bank: (10, nil), storesResume: false))
        XCTAssertEqual(again.resets, 1)
        XCTAssertEqual(again.stack, level.scramble)
        XCTAssertFalse(again.clean)

        // A run's cleared tank saves the next, empty, with the brim it carries.
        let run = Game(level: .endless(Run(seed: 7)), storesProgress: false, storesResume: true)
        if let w = run.wasting { run.commit(rod: w.rod, steps: w.steps) }
        while !run.finished, let t = run.reachable { run.commit(rod: t.rod, steps: t.steps) }
        XCTAssertTrue(run.solved)
        let next = try XCTUnwrap(Resume.load("endless"))
        XCTAssertEqual(next.actions, [])
        XCTAssertEqual(next.run?.tank, 1)
        XCTAssertEqual(next.run?.brim, run.brim)
        let tank = try XCTUnwrap(Game.resumed(.endless(try XCTUnwrap(next.run)), from: next, storesResume: false))
        XCTAssertEqual(tank.brim, run.brim)

        // A spill drops the run.
        let full = Game(level: .endless(Run(seed: 7, brim: Run.room - 1)), storesProgress: false, storesResume: true)
        let w = try XCTUnwrap(full.wasting)
        full.commit(rod: w.rod, steps: w.steps)
        XCTAssertTrue(full.spilled)
        XCTAssertNil(Resume.load("endless"), "a spill clears it")

        // Out of ticks clears it too; the lost card's undo saves it again.
        let clock = Level.escapement[1]
        defer { Resume.remove(clock.id) }
        let c = Game(level: clock, bank: (10, nil), storesProgress: false, storesResume: true)
        let ratchet = try XCTUnwrap(clock.clocks.first?.rod)
        if let w = c.wasting { c.commit(rod: w.rod, steps: w.steps) }
        while !c.finished, c.wait(on: ratchet) {}
        XCTAssertTrue(c.lost)
        XCTAssertNil(Resume.load(clock.id), "out of ticks clears it")
        c.undo()
        XCTAssertFalse(c.lost)
        let saved = try XCTUnwrap(Resume.load(clock.id))
        XCTAssertEqual(saved.actions.last, .undo)
        XCTAssertNotNil(Game.resumed(clock, from: saved, bank: (c.bank, nil), storesResume: false), "a replay passes through the loss")
    }

    func testResumeKeepsTheDailysFirstTry() throws {
        let daily = Level.daily()
        defer { Resume.remove(daily.id) }
        let g = Game(level: daily, bank: (10, nil), storesProgress: false, storesResume: true)
        heal(g)
        XCTAssertTrue(Best.started(daily.id))
        XCTAssertFalse(Game(level: daily).firstTry, "opened afresh, it would be practice")
        let r = try XCTUnwrap(Resume.load(daily.id))
        XCTAssertTrue(r.firstTry)
        let back = try XCTUnwrap(Game.resumed(daily, from: r, bank: (10, nil), storesResume: false))
        XCTAssertTrue(back.firstTry)
        XCTAssertTrue(back.counts)
    }

    func testTheHarnessLineAndThePrune() {
        let maelstrom = Level.maelstrom[0], escapement = Level.escapement[1], ratchet = escapement.clocks[0].rod
        XCTAssertEqual(Resume.actions("0:+2,u,-1:1,r,3:0", on: maelstrom), [.turn(knob: 0, steps: 2), .undo, .tank(1), .reset])
        XCTAssertEqual(Resume.actions("\(ratchet):1", on: escapement), [.wait(ratchet: ratchet)])

        let d = UserDefaults.standard
        defer { Resume.remove("daily-20000101"); Resume.remove("L12") }
        Resume.save(Resume(id: "daily-20000101", print: "", firstTry: true, actions: [.undo]))
        Resume.save(Resume(id: "L12", print: "", firstTry: true, actions: [.undo]))
        Resume.prune(known: Resume.known)
        XCTAssertNil(d.data(forKey: "resume.daily-20000101"), "yesterday's daily goes")
        XCTAssertNotNil(d.data(forKey: "resume.L12"))
    }
}
