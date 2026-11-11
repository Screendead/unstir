// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class PayoffTests: XCTestCase {
    /// A plain launch earns no payoff and says nothing more; with one switched on, the solve that gives the last of a
    /// tier's levels a best earns it, and a re-solve doesn't.
    @MainActor func testAPayoffComesOnlyWhenSwitchedOnAndOnce() {
        let ids = Tier.whirlpool.levels.map(\.id), last = ids.last!
        let saved = ids.map { UserDefaults.standard.data(forKey: "best.\($0)") }
        defer {
            Payoff.option = nil
            for (id, data) in zip(ids, saved) { UserDefaults.standard.set(data, forKey: "best.\(id)") }
        }
        func solve() -> Game {
            let level = Level(id: last, tier: .whirlpool, label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)])
            let game = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
            game.commit(rod: 0, steps: -4)
            XCTAssertTrue(game.solved)
            return game
        }
        for (i, id) in ids.dropLast().enumerated() { Best(over: 0, seconds: 9, clean: i < 4).save(id) }
        UserDefaults.standard.removeObject(forKey: "best.\(last)")
        Payoff.option = nil
        let plain = solve()
        XCTAssertNil(plain.tierDone)
        XCTAssertNil(Payoff(plain))
        XCTAssertFalse(plain.finishSpoken.contains("finished"))

        UserDefaults.standard.removeObject(forKey: "best.\(last)")
        Payoff.option = .b
        let game = solve()
        XCTAssertEqual(game.tierDone, .whirlpool)
        let payoff = Payoff(game)
        XCTAssertEqual(payoff?.marks.count, 27)
        XCTAssertEqual(payoff?.cleans, 4)
        XCTAssertEqual(payoff?.whole, false)
        XCTAssertTrue(game.finishSpoken.hasSuffix("Whirlpool finished: 27 tanks unstirred, 4 clean."), game.finishSpoken)
        XCTAssertNil(solve().tierDone)
    }

    /// Each option leaves the glass as the solve left it: nothing wound, turned or lit by a wave once its length is up
    /// or it has played, and nothing ever under Reduce Motion, where the tally is whole at once.
    func testEveryOptionLetsGoOfTheGlass() {
        for option in [Payoff.Option.a, .b, .c] {
            for tier in [Tier.plughole, .maelstrom] {
                let marks = [Payoff.Mark](repeating: .par, count: tier == .maelstrom ? 108 : 27)
                let payoff = Payoff(option: option, tier: tier, marks: marks)
                for t in [-1, payoff.length, .infinity] {
                    XCTAssertEqual(payoff.entries(at: t), [], "\(option) \(tier) \(t)")
                    XCTAssertEqual(payoff.turn(at: t), 0, "\(option) \(tier) \(t)")
                }
                XCTAssertEqual(payoff.wave(at: .infinity), -1)
                XCTAssertEqual(payoff.lit(at: .infinity), marks.count)
                XCTAssertEqual(payoff.lit(at: -1), 0)
                XCTAssertTrue(payoff.cues.allSatisfy { $0.at < payoff.length }, "\(option) \(tier)")
                let still = Payoff(option: option, tier: tier, marks: marks, still: true)
                for t in stride(from: 0.0, to: payoff.length, by: 0.05) {
                    XCTAssertEqual(still.entries(at: t), [], "\(option) \(tier) \(t)")
                    XCTAssertEqual(still.turn(at: t), 0, "\(option) \(tier) \(t)")
                    XCTAssertEqual(still.wave(at: t), -1, "\(option) \(tier) \(t)")
                    XCTAssertEqual(still.lit(at: t), marks.count, "\(option) \(tier) \(t)")
                }
                XCTAssertTrue(still.relay.isEmpty)
            }
        }
        // The game's whirl lets go on each lower tier's last picture in turn, one at a time.
        let game = Payoff(option: .a, tier: .maelstrom, marks: [])
        XCTAssertEqual(game.relay.map(\.id), ["L27", "N27", "V27"])
        for t in stride(from: 0.0, to: game.length, by: 0.01) {
            XCTAssertLessThanOrEqual((0 ..< 3).map { game.relayed($0, at: t) }.reduce(0, +), 1 + 1e-9, "\(t)")
        }
        XCTAssertEqual((0 ..< 3).map { game.relayed($0, at: game.length) }, [0, 0, 0])
    }
}
