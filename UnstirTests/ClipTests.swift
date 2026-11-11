// Copyright © 2026 Jack Lusher. All rights reserved.

import simd
import XCTest
@testable import Unstir

/// The pack cards' clips: each plays its level as a real `Game` would, loops without a jump, and holds a still inside it.
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

    func testTheSolvesSolveAndTheLensComesBackToItsRead() {
        for clip in [Clip.firstStir, .escapement] {
            XCTAssertEqual(clip.reels.last!.beats.last!.after.count, 0)
        }
        let lens = Clip.lens.reels[0]
        XCTAssertEqual(lens.beats.last!.after.map(\.twist), lens.opening.map(\.twist))
        XCTAssertNil(lens.beats[0].result, "the drag lets go where it took the lens, so nothing commits")
        // The lens it drags is the newest entry and that rod's only one, so the drag down takes it to clean, and a twist
        // lies under it on each rod beside it, for its rim to run whole through.
        let level = lens.level, newest = lens.opening.last!.twist, rods = level.layout.rods
        XCTAssertEqual(level.id, Level.lens[24].id, "Kaleidoscope, the pack's face")
        XCTAssertEqual(lens.opening.map(\.twist), Array(level.scramble.prefix(Reel.lensOpening)))
        XCTAssertEqual(lens.beats[0].gesture.knob, newest.rod)
        XCTAssertTrue(level.lenses.contains(newest.rod))
        XCTAssertEqual(lens.opening.filter { $0.twist.rod == newest.rod }.count, 1)
        XCTAssertEqual(lens.frame(at: lens.beats[0].start + 1.5).live!.angle / Tank.step, Double(-newest.steps), accuracy: 1e-9)
        let beside = lens.opening.map(\.twist.rod).filter { k in
            k != newest.rod && !level.lenses.contains(k)
                && simd_distance(SIMD2(rods[k].x, rods[k].y), SIMD2(rods[newest.rod].x, rods[newest.rod].y)) < rods[k].z + rods[newest.rod].z
        }
        XCTAssertEqual(Set(beside).count, 2)
        // Escapement ticks after each of its three moves, the last stopping the clock.
        XCTAssertEqual(Clip.escapement.reels[0].beats.map(\.ticked), [true, true, true])
        XCTAssertEqual(Clip.escapement.reels[0].beats.map(\.stops), [false, false, true])
        // First Stir's first heal leaves rod 1 an entry, so plays nothing; each after plays a vignette, and its time
        // steps back to the scene's earliest.
        let story = Clip.firstStir.reels[0]
        XCTAssertEqual(story.beats.map(\.heals), [false, true, true, true])
        XCTAssertEqual(story.frame(at: 0).caption, "6:40 am")
        XCTAssertEqual(story.frame(at: story.length).caption, "6:15 am")
    }

    /// The loop's seam: a reel that dips is black at both ends, and the lens's, which doesn't, ends as it began.
    func testEveryClipLoopsWithoutAJump() {
        for (name, clip) in clips {
            XCTAssertEqual(clip.period, clip.reels.reduce(0) { $0 + $1.shown }, accuracy: 1e-9, name)
            for reel in clip.reels where reel.dips {
                XCTAssertEqual(reel.frame(at: reel.from).dip, 1, accuracy: 1e-9, name)
                XCTAssertEqual(reel.frame(at: reel.to).dip, 1, accuracy: 1e-9, name)
            }
        }
        let lens = Clip.lens.reels[0], a = lens.frame(at: 0), b = lens.frame(at: lens.length - 1e-6)
        XCTAssertEqual(a.stack, b.stack)
        XCTAssertNil(a.finger)
        XCTAssertNil(b.finger)
        XCTAssertNil(b.live)
        XCTAssertEqual(a.knobs.values.reduce(0, +), b.knobs.values.reduce(0, +), accuracy: 1e-9)
    }

    /// The bundle's cut, whatever the build sells: a zoom, a tick, then Prism's buried red stir coming off under the cyan
    /// one, and its still on the tank.
    func testTheBundlesCutIsItsThreePacks() {
        let clip = Clip.complete
        XCTAssertEqual(clip.reels.map(\.level.pack), [.lens, .escapement, .prism])
        let prism = clip.reels[2], healed = prism.frame(at: prism.to).stack
        XCTAssertEqual(healed.map(\.rod), [2, 1], "the red stir, under the cyan one, comes off first")
        XCTAssertTrue(clip.still > 0 && clip.still < clip.period)
        let (reel, _, t) = clip.reel(at: clip.still)
        let f = reel.frame(at: t)
        XCTAssertEqual(f.dip, 0)
        XCTAssertNil(f.finger)
    }

    func testAboutSevenSecondsAndAStillInside() {
        // A cut of every pack has a fourth beat, First Stir's.
        for (name, clip) in clips where name != "every pack" {
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

    /// A lens follows the finger up and down, down zooming out: the fingertip falls a pitch a step.
    func testTheLensFingerRidesUpAndDown() {
        let reel = Clip.lens.reels[0], b = reel.beats[0], k = b.gesture.knob
        let f = reel.frame(at: b.start + 0.65)
        let steps = f.live!.angle / Tank.step
        XCTAssertLessThan(steps, -0.5)
        let rod = reel.level.layout.rods[k], at = SIMD2(rod.x, rod.y) + 0.5 * rod.z * SIMD2(0.7071, -0.7071)
        XCTAssertEqual(f.finger!.at.y, at.y - steps * LevelView.lensPitch, accuracy: 1e-9)
        XCTAssertEqual(f.finger!.at.x, at.x, accuracy: 1e-9)
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
