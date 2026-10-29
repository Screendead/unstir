// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// Prism's channel masks: a stir moves only its rod's channels, so commutation and the win are judged per channel.
final class PrismTests: XCTestCase {
    private let redCyan: [Int: Channels] = [0: .red, 1: .cyan]

    func testMasksParse() {
        XCTAssertEqual(Channels.masks("0:r,1:C,2:w"), [0: .red, 1: .cyan, 2: .white])
        XCTAssertEqual(Channels.masks(""), [:])
        XCTAssertNil(Channels.masks("0:x"))
        XCTAssertNil(Channels.masks("0:rg"))
        XCTAssertEqual([Channels.red, .green, .blue, .cyan, .magenta, .yellow, .white].compactMap(\.letter),
                       ["r", "g", "b", "c", "m", "y", "w"])
    }

    /// Tri's rods 0 and 1 overlap, so their turns fail to commute on a white picture, and commute once their masks share
    /// no channel.
    func testOverlappingEntriesWithDisjointMasksCommute() {
        let layout = Layout.tri, a = Twist(rod: 0, steps: 3), b = Twist(rod: 1, steps: 4)
        XCTAssertTrue(layout.overlaps(0, 1))
        XCTAssertFalse(layout.same([a, b], [b, a], at: Tank.samples, within: 1e-6))
        XCTAssertTrue(layout.same([a, b], [b, a], at: Tank.samples, within: 1e-6, masks: redCyan))
        XCTAssertFalse(layout.same([a, b], [b, a], at: Tank.samples, within: 1e-6, masks: [0: .red, 1: .magenta]))
        XCTAssertTrue(layout.commutes([a, b], above: 0, rod: 0, steps: -3, masks: redCyan))
        XCTAssertFalse(layout.commutes([a, b], above: 0, rod: 0, steps: -3, masks: [0: .red, 1: .yellow]))
        XCTAssertFalse(layout.commutes([a, b], above: 0, rod: 0, steps: -3))
    }

    /// A shared channel still commutes where the maps do on it: hex's hub and its swirl share a centre.
    func testASharedChannelCommutesWhereItsMapsDo() {
        let layout = Layout.hexSwirl, hub = Twist(rod: 0, steps: 2), swirl = Twist(rod: 7, steps: 3), rim = Twist(rod: 1, steps: 3)
        XCTAssertTrue(layout.commutes([hub, swirl], above: 0, rod: 0, steps: -2, masks: [0: .red, 7: .yellow]))
        XCTAssertFalse(layout.commutes([rim, swirl], above: 0, rod: 1, steps: -3, masks: [1: .red, 7: .yellow]))
        XCTAssertTrue(layout.commutes([rim, swirl], above: 0, rod: 1, steps: -3, masks: [1: .red, 7: .cyan]))
    }

    func testAnEntryMergesOnlyAsItsChannelsAllow() {
        XCTAssertEqual([Twist].parse("0:+3,1:+4,0:-1", in: .tri, masks: redCyan),
                       [Twist(rod: 0, steps: 2), Twist(rod: 1, steps: 4)])
        XCTAssertEqual([Twist].parse("0:+3,1:+4,0:-1", in: .tri, masks: [0: .red, 1: .magenta]).count, 3)
        XCTAssertEqual([Twist].parse("0:+3,1:+4,0:-1", in: .tri).count, 3)
        var stack = [Twist].parse("0:+3,1:+4", in: .tri, masks: redCyan)
        XCTAssertEqual(Layout.tri.removable(stack, masks: redCyan), [0, 1])
        XCTAssertEqual(Layout.tri.removable(stack), [1])
        XCTAssertEqual(stack.commit(rod: 0, steps: -3, in: .tri, masks: redCyan), .cancelled)
        XCTAssertEqual(stack, [Twist(rod: 1, steps: 4)])
        var white = [Twist].parse("0:+3,1:+4", in: .tri)
        XCTAssertEqual(white.commit(rod: 0, steps: -3, in: .tri), .pushed)
    }

    /// The win is every channel back: a word that leaves each channel's own word the identity is solved, though the whole
    /// word, read white, is not.
    func testLooksSolvedIsPerChannel() {
        let word = [Twist(rod: 0, steps: 3), Twist(rod: 1, steps: 4), Twist(rod: 0, steps: -3), Twist(rod: 1, steps: -4)]
        XCTAssertTrue(Layout.tri.looksSolved(word, masks: redCyan))
        XCTAssertFalse(Layout.tri.looksSolved(word))
        XCTAssertFalse(Layout.tri.looksSolved([Twist(rod: 1, steps: 4)], masks: redCyan))
        XCTAssertFalse(Layout.tri.looksSolved([Twist(rod: 0, steps: 3)], masks: [0: .red]))
    }

    /// Masks left out or all white leave every existing level's stack as it was dealt.
    func testWhiteMasksChangeNoLevel() {
        let levels = Tier.allCases.flatMap(\.levels) + Pack.allCases.flatMap(\.levels)
        for level in levels where level.masks.isEmpty {
            let white = Dictionary(uniqueKeysWithValues: level.layout.rods.indices.map { ($0, Channels.white) })
            var stack: [Twist] = []
            for t in level.scramble { stack.commit(t, in: level.layout, lenses: level.lenses, masks: white) }
            XCTAssertEqual(stack, level.scramble, level.id)
        }
    }

    /// A game on masks heals a buried entry its channels free, and wins once every channel is back.
    @MainActor func testAGameHealsByChannel() {
        let stack = [Twist].parse("2:+2,0:+3,1:+4", in: .tri, masks: redCyan)
        XCTAssertEqual(stack.count, 3)
        let level = Level(id: "test-prism", label: "", title: "", layout: .tri, scramble: stack, masks: redCyan)
        let game = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
        game.commit(rod: 0, steps: -3)
        XCTAssertEqual(game.stack, [Twist(rod: 2, steps: 2), Twist(rod: 1, steps: 4)])
        game.commit(rod: 1, steps: -4)
        XCTAssertFalse(game.solved)
        game.commit(rod: 2, steps: -2)
        XCTAssertTrue(game.solved)
    }

    func testTheSolverReadsMasks() throws {
        let stack = [Twist].parse("2:+2,0:+3,1:+4", in: .tri, masks: redCyan)
        let solver = Solver(.tri, masks: redCyan)
        let play = try XCTUnwrap(solver.optimalPlay(stack, seized: []))
        XCTAssertEqual(play.count, 3)
        XCTAssertFalse(solver.interacts[0][1])
        XCTAssertTrue(Solver(.tri).interacts[0][1])
        let deeper = [Twist].parse("2:+2,0:+3,1:+4,0:+2", in: .tri, masks: [0: .red, 1: .green])
        let optimum = try XCTUnwrap(Solver(.tri, masks: [0: .red, 1: .green]).optimum(deeper))
        XCTAssertEqual(Solver(.tri, masks: [0: .red, 1: .green])
            .exhaustive(deeper, limit: optimum, steps: [-5, -4, -2, 2, 4, 5]), optimum)
    }
}
