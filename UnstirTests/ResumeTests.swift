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
                      Level.mockUp, Level.endless(Run(seed: 7, tank: 2, brim: 1)), Level.firstStir[0]]
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
        // Progress is stored, never registered, where it can be: a registered flag outlives the test (`FreshDefaults`).
        defer { Resume.remove(id); Resume.remove("endless"); UserDefaults.standard.removeObject(forKey: "best.\(id)") }
        let g = Game(level: level, bank: (10, nil), storesResume: true)
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

        // Out of ticks keeps it, the losing move too (Jack's call, 2026-11-01, on C19); the lost card's undo saves on.
        let clock = Level.mockUp
        defer { Resume.remove(clock.id) }
        let c = Game(level: clock, bank: (10, nil), storesResume: true)
        let ratchet = try XCTUnwrap(clock.clocks.first?.rod)
        if let w = c.wasting { c.commit(rod: w.rod, steps: w.steps) }
        while !c.finished, c.wait(on: ratchet) {}
        XCTAssertTrue(c.lost)
        XCTAssertEqual(Resume.load(clock.id)?.actions, c.actions, "out of ticks keeps it")
        c.undo()
        XCTAssertFalse(c.lost)
        let saved = try XCTUnwrap(Resume.load(clock.id))
        XCTAssertEqual(saved.actions.last, .undo)
        XCTAssertNotNil(Game.resumed(clock, from: saved, bank: (c.bank, nil), storesResume: false), "a replay passes through the loss")
    }

    /// A tank out of ticks reopens on its lost card (Jack's call, 2026-11-01, on C19): its undo takes back the losing move
    /// as it does live, and again deals afresh with the save following it.
    func testALostTankReopensLost() throws {
        let level = Level.mockUp
        defer { Resume.remove(level.id) }
        let live = Game(level: level, bank: (10, nil), storesResume: true)
        let ratchet = try XCTUnwrap(level.clocks.first?.rod)
        if let w = live.wasting { live.commit(rod: w.rod, steps: w.steps) }
        var before = (stack: live.stack, ticks: live.escapement.ticks, moves: live.moves)
        while !live.finished {
            before = (live.stack, live.escapement.ticks, live.moves)
            XCTAssertTrue(live.wait(on: ratchet))
        }
        XCTAssertTrue(live.lost)
        let saved = try XCTUnwrap(Resume.load(level.id))
        let r = try JSONDecoder().decode(Resume.self, from: try JSONEncoder().encode(saved))
        let back = try XCTUnwrap(Game.resumed(level, from: r, bank: (live.bank, nil), storesResume: true))
        XCTAssertTrue(back.lost)
        XCTAssertTrue(back.finished)
        XCTAssertEqual(back.tick.count, 0, "the losing move's ticks are long played")
        assertSame(live, back, "reopened")
        XCTAssertEqual(back.pushedClock, live.pushedClock)
        XCTAssertEqual(back.lastStopped, live.lastStopped)

        back.undo()
        XCTAssertFalse(back.lost)
        XCTAssertEqual(back.stack, before.stack)
        XCTAssertEqual(back.escapement.ticks, before.ticks)
        XCTAssertEqual(back.moves, before.moves)
        XCTAssertEqual(back.bank, live.bank - 1)
        XCTAssertEqual(Resume.load(level.id)?.actions, saved.actions + [.undo])

        back.reset()
        XCTAssertEqual(back.stack, level.scramble)
        XCTAssertEqual(Resume.load(level.id)?.actions.last, .reset)
    }

    /// A solve on Escapement still clears the save, and a saved line that solves reopens nothing.
    func testAnEscapementSolveClearsItsSave() throws {
        let level = Level.mockUp
        defer { Resume.remove(level.id); UserDefaults.standard.removeObject(forKey: "best.\(level.id)") }
        let g = Game(level: level, bank: (10, nil), storesResume: true)
        // The book's line for problem 2: 2:+4, a wait, 1:-3.
        g.commit(rod: 2, steps: 4)
        XCTAssertNotNil(Resume.load(level.id))
        let ratchet = try XCTUnwrap(level.clocks.first?.rod)
        XCTAssertTrue(g.wait(on: ratchet))
        let line = Resume(of: g).actions + [.turn(knob: 1, steps: -3)]
        g.commit(rod: 1, steps: -3)
        XCTAssertTrue(g.solved)
        XCTAssertNil(Resume.load(level.id), "a solve clears it")
        let r = Resume(id: level.id, print: level.print, firstTry: true, actions: line)
        XCTAssertNil(Game.resumed(level, from: r, bank: (10, nil), storesResume: false),
                     "a line that solves reopens nothing")
    }

    /// A reset with nothing played changes nothing a replay needs, so it isn't recorded (C2's implementer call, round 13).
    func testAResetWithNothingPlayedIsNotSaved() throws {
        let level = Level.plughole[11]
        let g = Game(level: level, bank: (10, nil))
        let t = try XCTUnwrap(g.reachable)
        g.commit(rod: t.rod, steps: t.steps)
        g.undo()
        g.reset()
        XCTAssertEqual(Resume(of: g).actions, [.turn(knob: t.rod, steps: t.steps), .undo])
        let back = try XCTUnwrap(Game.resumed(level, from: Resume(of: g), bank: (g.bank, nil), storesResume: false))
        XCTAssertEqual(back.resets, g.resets)
        XCTAssertEqual(back.undos, g.undos)
        XCTAssertEqual(back.clean, g.clean)
        XCTAssertEqual(back.stack, level.scramble)
    }

    /// The app dying inside the solving move's fine pass: the replay finishes the try, its best taking the time played.
    func testALineThatSolvesSavesItsBestWithItsTime() throws {
        let id = "resume-test", level = Level(id: id, label: "", title: "", layout: .tri, scramble: .parse("0:+4", in: .tri))
        defer { UserDefaults.standard.removeObject(forKey: "best.\(id)") }
        let r = Resume(id: id, print: level.print, firstTry: true, seconds: 42, actions: [.turn(knob: 0, steps: -4)])
        XCTAssertNil(Game.resumed(level, from: r, bank: (10, nil), storesResume: false))
        XCTAssertEqual(Best.load(id)?.seconds, 42)
    }

    func testResumeKeepsTheDailysFirstTry() throws {
        let daily = Level.daily()
        defer { Resume.remove(daily.id) }
        let g = Game(level: daily, bank: (10, nil), storesResume: true)
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
        let maelstrom = Level.maelstrom[0], escapement = Level.mockUp, ratchet = escapement.clocks[0].rod
        XCTAssertEqual(Resume.actions("0:+2,u,-1:1,r,3:0", on: maelstrom), [.turn(knob: 0, steps: 2), .undo, .tank(1), .reset])
        XCTAssertEqual(Resume.actions("\(ratchet):1", on: escapement), [.wait(ratchet: ratchet)])

        let d = UserDefaults.standard
        defer { for id in ["daily-20000101", "L999", "L12"] { Resume.remove(id) } }
        for id in ["daily-20000101", "L999", "L12"] { Resume.save(Resume(id: id, print: "", firstTry: true, actions: [.undo])) }
        Resume.prune(known: Resume.known)
        XCTAssertNil(d.data(forKey: "resume.daily-20000101"), "yesterday's daily goes")
        XCTAssertNil(d.data(forKey: "resume.L999"), "a level an update took out goes")
        XCTAssertNotNil(d.data(forKey: "resume.L12"))
    }

    /// A save is dropped when its level's print changes, so the print is pinned as a literal: changing how it is spelt
    /// drops every player's save.
    func testThePrintNeverChanges() {
        XCTAssertEqual(Level.plughole[11].print, "quad [2:-3,0:+4,3:+7,0:-2,1:-3,2:-5] seized= sockets= ratchets= back= lenses= "
                       + "masks= motion=none par=6")
    }
}
