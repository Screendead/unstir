// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// The pack cards' clips: each plays its level as a real `Game` would.
@MainActor final class ClipTests: XCTestCase {
    private let clips: [(String, Clip)] = [("first stir", .firstStir), ("lens", .lens), ("escapement", .escapement), ("prism", .prism),
                                           ("complete", .complete), ("every pack", Clip.cut(of: Pack.allCases))]

    /// Each reel's stacks are the ones a `Game` shows after the same moves, under an id of no pack level so a win keeps
    /// no best. A reel that opens partway through its level opens where top-first moves leave the game.
    func testEveryReelPlaysAsTheGameDoes() {
        for (name, clip) in clips {
            for reel in clip.reels {
                var level = reel.level
                level.id = "test-clip"
                let g = Game(level: level, tankTurned: true, bank: (3, nil))
                for case .turn(let k, let keys) in Reel.solve(level, moves: level.scramble.count - reel.opening.count) {
                    g.commit(rod: k, steps: Int(keys.last!.steps))
                }
                XCTAssertEqual(g.stack, reel.opening.map(\.twist), name)
                for b in reel.beats {
                    switch b.gesture {
                    case .tap(let k): g.wait(on: k)
                    case .turn(let k, let keys):
                        let net = Int(keys.last!.steps.rounded())
                        if net != 0 { g.commit(rod: k, steps: net) }
                    }
                    XCTAssertEqual(g.stack, b.after.map(\.twist), "\(name) after \(b.gesture)")
                    XCTAssertEqual(g.played, Reel.played(level, b.after), name)
                }
            }
        }
    }

    /// The dock's covers stir what the cards' clips play, on pictures baked once rather than redrawn each frame, and their
    /// loop runs from clean to clean and holds the dealt stack between.
    func testEveryCoverStirsItsClipsLevel() {
        XCTAssertEqual(Offer.pack(.lens).covers.map(\.level.id), [Level.lens[24].id])
        XCTAssertEqual(Offer.pack(.escapement).covers.map(\.level.id), [Level.escapement[1].id])
        XCTAssertEqual(Offer.pack(.prism).covers.map(\.level.id), [Level.prism[0].id])
        XCTAssertEqual(Offer.complete.covers.map(\.level.pack), Pack.bundled)
        for offer in Offer.all {
            for (level, stack) in offer.covers {
                XCTAssertFalse(level.picture.isLive, "\(offer.name) cover: \(level.id)")
                // Lens's is Kaleidoscope as its clip opens, partway down its par line; every other is its level as dealt.
                let entries = level.pack == .lens ? Reel.lensOpening : level.scramble.count
                XCTAssertEqual(stack.map(\.twist), Array(level.scramble.prefix(entries)), "\(offer.name) cover: \(level.id)")
            }
        }
        for m in [3, 4, 7] {
            XCTAssertEqual(PackTank.wind(m, at: 0), Array(repeating: 0, count: m))
            XCTAssertEqual(PackTank.wind(m, at: 2.8), Array(repeating: 1, count: m))
            XCTAssertEqual(PackTank.wind(m, at: PackTank.period - 0.05), Array(repeating: 0, count: m))
        }
    }
}
