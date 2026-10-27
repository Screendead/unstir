// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// The pack cards' clips: each plays its level as a real `Game` would, loops without a jump, and holds a still inside it.
@MainActor final class ClipTests: XCTestCase {
    private let clips: [(String, Clip)] = [("first stir", .firstStir), ("lens", .lens), ("lens solve", .lensSolve),
                                           ("escapement", .escapement), ("complete", .complete), ("complete cut", .completeCut)]

    /// Each reel's stacks are the ones a `Game` shows after the same moves, under an id of no pack level so a win keeps
    /// no best.
    func testEveryReelPlaysAsTheGameDoes() {
        for (name, clip) in clips {
            for reel in clip.reels {
                var level = reel.level
                level.id = "test-clip"
                let g = Game(level: level, tankTurned: true, bank: (3, nil))
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

    func testTheSolvesSolveAndTheLensComesBackToItsRead() {
        for clip in [Clip.firstStir, .lensSolve, .escapement] {
            XCTAssertEqual(clip.reels.last!.beats.last!.after.count, 0)
        }
        let lens = Clip.lens.reels[0]
        XCTAssertEqual(lens.beats.last!.after.map(\.twist), lens.opening.map(\.twist))
        XCTAssertNil(lens.beats[0].result, "the drag lets go where it took the lens, so nothing commits")
        // Escapement ticks after each of its three moves, the last stopping the clock.
        XCTAssertEqual(Clip.escapement.reels[0].beats.map(\.ticked), [true, true, true])
        XCTAssertEqual(Clip.escapement.reels[0].beats.map(\.stops), [false, false, true])
        // First Stir plays a vignette with every heal, and its time steps back to the scene's earliest.
        let story = Clip.firstStir.reels[0]
        XCTAssertEqual(story.beats.map(\.heals), [true, true, true])
        XCTAssertEqual(story.frame(at: 0).caption, "12:30 am")
        XCTAssertEqual(story.frame(at: story.length).caption, "11:40 pm")
    }

    /// The loop's seam: a reel that dips is black at both ends, and the lens's, which doesn't, ends as it began.
    func testEveryClipLoopsWithoutAJump() {
        for (name, clip) in clips {
            XCTAssertEqual(clip.period, clip.reels.reduce(0) { $0 + $1.length }, accuracy: 1e-9, name)
            for reel in clip.reels where reel.dips {
                XCTAssertEqual(reel.frame(at: 0).dip, 1, accuracy: 1e-9, name)
                XCTAssertEqual(reel.frame(at: reel.length).dip, 1, accuracy: 1e-9, name)
            }
        }
        let lens = Clip.lens.reels[0], a = lens.frame(at: 0), b = lens.frame(at: lens.length - 1e-6)
        XCTAssertEqual(a.stack, b.stack)
        XCTAssertNil(a.finger)
        XCTAssertNil(b.finger)
        XCTAssertNil(b.live)
        XCTAssertEqual(a.knobs.values.reduce(0, +), b.knobs.values.reduce(0, +), accuracy: 1e-9)
    }

    func testAboutSevenSecondsAndAStillInside() {
        for (name, clip) in [("first stir", Clip.firstStir), ("lens", .lens), ("lens solve", .lensSolve),
                             ("escapement", .escapement), ("complete cut", .completeCut)] {
            XCTAssertEqual(clip.period, 7, accuracy: 1.2, name)
        }
        for (name, clip) in clips {
            XCTAssertTrue(clip.still > 0 && clip.still < clip.period, name)
            let (reel, _, t) = clip.reel(at: clip.still)
            let f = reel.frame(at: t)
            XCTAssertEqual(f.dip, 0, name)
            XCTAssertNil(f.finger, "\(name): the still shows the tank, not a fingertip")
        }
    }

    /// A lens follows the finger up and down, up zooming in: the fingertip rises a pitch a step.
    func testTheLensFingerRidesUpAndDown() {
        let reel = Clip.lensSolve.reels[0], b = reel.beats[1]
        let f = reel.frame(at: b.start + 0.6)
        let rod = reel.level.layout.rods[0], at = SIMD2(rod.x, rod.y) + 0.5 * rod.z * SIMD2(0.7071, -0.7071)
        XCTAssertEqual(f.live!.angle, 0.9 * Tank.step, accuracy: 1e-9)
        XCTAssertEqual(f.finger!.at.y, at.y - 0.9 * LevelView.lensPitch, accuracy: 1e-9)
        XCTAssertEqual(f.finger!.at.x, at.x, accuracy: 1e-9)
    }
}
