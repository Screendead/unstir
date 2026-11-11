// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class PayoffTests: XCTestCase {
    /// Solves the last level of `ids` on a stand-in scramble, with every other one holding a best, then again.
    @MainActor private func finishing(_ ids: [String], level: (String) -> Level, _ body: (_ first: Game, _ again: Game) -> Void) {
        let last = ids.last!
        let saved = ids.map { UserDefaults.standard.data(forKey: "best.\($0)") }
        defer { for (id, data) in zip(ids, saved) { UserDefaults.standard.set(data, forKey: "best.\(id)") } }
        func solve() -> Game {
            let game = Game(level: level(last), tankTurned: true, swirled: true, bank: (5, nil))
            game.commit(rod: 0, steps: -4)
            XCTAssertTrue(game.solved)
            return game
        }
        for id in ids.dropLast() { Best(over: 0, seconds: 9).save(id) }
        UserDefaults.standard.removeObject(forKey: "best.\(last)")
        let first = solve()
        body(first, solve())
    }

    /// The solve that gives the last of a tier's levels a best earns the curtain call, on a plain launch, in the tier's
    /// name and colours; solving it again earns none, and the card's label says it after the level's own result.
    @MainActor func testATiersFinishingSolveEarnsTheCurtainOnce() {
        finishing(Tier.whirlpool.levels.map(\.id)) {
            Level(id: $0, tier: .whirlpool, label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)])
        } _: { game, again in
            XCTAssertEqual(game.tierDone, .whirlpool)
            let payoff = Payoff(game)
            XCTAssertEqual(payoff?.tier, .whirlpool)
            XCTAssertEqual(payoff?.whole, false)
            XCTAssertEqual(payoff?.parts.map(\.name), ["Whirlpool"])
            XCTAssertEqual(payoff?.parts.first?.colours, Tier.whirlpool.colours)
            XCTAssertEqual(payoff?.stamp, "unstirred.")
            XCTAssertEqual(payoff?.spoken, "Whirlpool, unstirred.")
            XCTAssertTrue(game.finishSpoken.hasSuffix("Clean. Whirlpool, unstirred."), game.finishSpoken)
            XCTAssertNil(again.tierDone)
            XCTAssertNil(Payoff(again))
            XCTAssertFalse(again.finishSpoken.contains("Whirlpool"), again.finishSpoken)
        }
    }

    /// The solve that completes a paid pack earns it in the pack's name and colours over its levels counted, and the
    /// card's label keeps the completion's own sentence. First Stir, whose last level ends on the night forwards, has
    /// none.
    @MainActor func testAPacksLastLevelEarnsItToo() {
        finishing(Pack.lens.levels.map(\.id)) {
            Level(id: $0, pack: .lens, label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)])
        } _: { game, again in
            XCTAssertEqual(game.completed, .pack(.lens))
            let payoff = Payoff(game)
            XCTAssertEqual(payoff?.pack, .lens)
            XCTAssertNil(payoff?.tier)
            XCTAssertEqual(payoff?.whole, false)
            XCTAssertEqual(payoff?.parts.map(\.name), ["Lens"])
            XCTAssertEqual(payoff?.parts.first?.colours, Offer.pack(.lens).sweep)
            XCTAssertEqual(payoff?.paper, false)
            XCTAssertEqual(payoff?.stamp, "25 panels unstirred")
            XCTAssertEqual(payoff?.spoken, "Lens: 25 panels unstirred.")
            XCTAssertNil(payoff?.carded)
            XCTAssertTrue(game.finishSpoken.hasSuffix("Lens complete, 25 panels."), game.finishSpoken)
            XCTAssertNil(Payoff(again))
        }
        XCTAssertEqual(Pack.allCases.filter(\.ships), [.lens, .escapement, .prism])
        XCTAssertEqual(Payoff(pack: .escapement, paper: true).stamp, "30 problems unstirred")
    }

    /// The last tier's is the whole game's: every tier's name, the completion's line, and the credit, which the card's
    /// label carries too, in Jack's words.
    func testTheGamesNamesEveryTierAndCredits() {
        let game = Payoff(tier: .maelstrom)
        XCTAssertTrue(game.whole)
        XCTAssertEqual(game.parts.map(\.name), ["Plughole", "Whirlpool", "Vortex", "Maelstrom"])
        XCTAssertEqual(game.stamp, "every tier unstirred")
        XCTAssertTrue(game.spoken.hasPrefix("Plughole, Whirlpool, Vortex"), game.spoken)
        XCTAssertEqual(Payoff.Credit.shown, "made by screendead \u{00B7} thank you for playing")
        XCTAssertEqual(Payoff.Credit.spoken, "Made by screendead. Thank you for playing.")
        XCTAssertTrue(game.spoken.hasSuffix("Every tier unstirred. " + Payoff.Credit.spoken), game.spoken)
        XCTAssertEqual(game.carded, Payoff.Credit.spoken)
        XCTAssertFalse(Payoff(tier: .vortex).whole)
    }

    /// How long each curtain holds the screen, pinned as what Jack was told; the glass turns once and ends upright,
    /// and never under Reduce Motion; every line is up and has a second to be read before the curtain lifts.
    func testTheCurtainIsShortTurnsOnceAndLetsGo() {
        XCTAssertEqual(Payoff(tier: .plughole).length, 3.2)
        XCTAssertEqual(Payoff(pack: .prism).length, 3.2)
        XCTAssertEqual(Payoff(tier: .maelstrom).length, 7.4)
        XCTAssertEqual(Payoff(tier: .plughole, still: true).length, 2.6)
        XCTAssertEqual(Payoff(tier: .maelstrom, still: true).length, 5)
        for tier in [Tier.plughole, .maelstrom] {
            let payoff = Payoff(tier: tier), still = Payoff(tier: tier, still: true)
            for t in [-1, 0, payoff.length, .infinity] { XCTAssertEqual(payoff.turn(at: t), 0, "\(tier) \(t)") }
            XCTAssertEqual(payoff.turn(at: payoff.length / 2), .pi, accuracy: 1e-9)
            XCTAssertEqual(payoff.turn(at: payoff.length - 1e-9), 2 * .pi, accuracy: 1e-6)
            for t in stride(from: 0.0, to: still.length, by: 0.05) { XCTAssertEqual(still.turn(at: t), 0, "\(tier) \(t)") }
            for p in [payoff, still] {
                let lines = p.parts.count + (p.whole ? 2 : 1)
                XCTAssertLessThanOrEqual(p.rises(lines - 1) + 0.45 + 1, p.lifts, "\(tier) still \(p.still)")
                XCTAssertTrue(p.cues.allSatisfy { $0.at < p.lifts }, "\(tier) still \(p.still)")
            }
        }
    }

    /// Only sounds the game has, at their own levels: a tier's or a pack's name on the tier switch's and its stamp on
    /// two of the heal's notes; the game's names up the heal's scale and its stamp on the solve's chime, never while the
    /// solve's own chime, 3.3 s long, still rings. Under Reduce Motion the game's sounds as a tier's.
    func testTheCurtainsSounds() {
        let tier = Payoff(tier: .vortex).cues
        XCTAssertEqual(tier.map(\.effect), [.tier, .heal(4), .heal(6)])
        XCTAssertEqual(Payoff(pack: .escapement, paper: true).cues, tier)
        let game = Payoff(tier: .maelstrom)
        XCTAssertEqual(game.cues.map(\.effect), [.heal(1), .heal(3), .heal(4), .heal(6), .solve])
        XCTAssertEqual(game.cues.map(\.at), (0 ... 4).map(game.rises))
        XCTAssertGreaterThan(Payoff.lead + game.cues.last!.at, 3.3)
        XCTAssertEqual(Payoff(tier: .maelstrom, still: true).cues.map(\.effect), [.tier, .heal(4), .heal(6)])
    }

    /// The words never shrink. They stand over the glass only where every line lies inside it; else under it, the
    /// glass giving up what the room below lacks, no further than its least.
    func testTheGlassGivesTheWordsRoom() {
        // A name and a stamp, 60 pt of block, in a glass 200 across.
        let two = [CGRect(x: 0, y: 0, width: 150, height: 34), CGRect(x: 20, y: 38, width: 110, height: 22)]
        XCTAssertTrue(Payoff.fits(two, height: 60, r: 100))
        // The same lines wider than the glass's chord where they lie, and a tall block whose last line is at its foot.
        XCTAssertFalse(Payoff.fits(two.map { $0.insetBy(dx: -20, dy: 0) }, height: 60, r: 100))
        XCTAssertFalse(Payoff.fits([CGRect(x: 0, y: 150, width: 120, height: 22)], height: 172, r: 100))
        XCTAssertTrue(Payoff.fits([CGRect(x: 0, y: 150, width: 60, height: 22)], height: 172, r: 100))

        XCTAssertEqual(Payoff.scale(block: 100, room: 140, stage: 400), 1)
        XCTAssertEqual(Payoff.scale(block: 220, room: 140, stage: 400), 0.75, accuracy: 1e-9)
        XCTAssertEqual(Payoff.scale(block: 900, room: 140, stage: 400), Payoff.least)
        XCTAssertLessThan(Payoff.least, PlayLayout.leastFinished)
    }

    /// Every string the curtain adds is in the String Catalog, under the key the build looks up.
    func testTheCurtainsStringsAreInTheCatalog() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appending(path: "Sources/Localizable.xcstrings"))
        let strings = try XCTUnwrap((JSONSerialization.jsonObject(with: data) as? [String: Any])?["strings"] as? [String: Any])
        for key in ["made by screendead \u{00B7} thank you for playing", "Made by screendead. Thank you for playing.", "%@ unstirred",
                    "%@: %@ unstirred.", "%@, unstirred.", "Goes on to the result."] {
            XCTAssertNotNil(strings[key], key)
        }
    }
}
