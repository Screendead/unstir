// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import XCTest
import simd
@testable import Unstir

final class FirstStirTests: XCTestCase {
    /// The lab's harbour in the storm under an id no level has, so solving it saves no best.
    private func harbour(_ scramble: String = "2:+5,1:-4,0:+3", layout: Unstir.Layout = .tri) -> Level {
        var level = Level.firstStir[0]
        level.id = "first-stir-test"
        level.story = .harbour
        level.layout = layout
        level.scramble = .parse(scramble, in: layout)
        return level
    }

    /// A heal plays its rod's vignette and rings magenta; cancelling a push of the player's own plays none and rings
    /// nothing; the pack's undo brings the vignette back with its entry, and the solve has played all three.
    @MainActor func testAHealPlaysItsVignette() {
        let game = Game(level: harbour(), bank: (undos: 10, refilled: nil))
        XCTAssertEqual(game.played, [])
        game.commit(rod: 1, steps: 2)
        game.commit(rod: 1, steps: -2)
        XCTAssertEqual(game.played, [])
        XCTAssertEqual(game.cancels, 0)
        let dealt = game.entries
        game.commit(rod: 0, steps: -3)
        XCTAssertEqual(game.played, [0])
        XCTAssertEqual(game.cancels, 1)
        game.undo()
        XCTAssertEqual(game.played, [])
        XCTAssertEqual(game.entries, dealt)
        XCTAssertEqual(game.cancels, 1)
        game.commit(rod: 0, steps: -3)
        game.commit(rod: 1, steps: 4)
        XCTAssertEqual(game.played, [0, 1])
        game.commit(rod: 2, steps: -5)
        XCTAssertEqual(game.played, [0, 1, 2])
        // The lighthouse's heal rang twice, once either side of the undo.
        XCTAssertEqual(game.cancels, 4)
        XCTAssertTrue(game.solved)
    }

    /// A reset brings every vignette back.
    @MainActor func testAResetUnplaysEveryVignette() {
        let game = Game(level: harbour())
        game.commit(rod: 0, steps: -3)
        game.commit(rod: 1, steps: 4)
        XCTAssertEqual(game.played, [0, 1])
        XCTAssertTrue(game.reset())
        XCTAssertEqual(game.played, [])
        XCTAssertEqual(game.entries.map(\.tags), [[2], [1], [0]])
    }

    /// A vignette waits for every entry on its rod: here the lighthouse's two, which merge once the cottage's heal lets
    /// the newer fall onto the older. Quad's rods 0 and 2 never meet, and rod 1 holds no entry, so the boat has played.
    @MainActor func testAVignetteWaitsForEveryEntryOnItsRod() {
        let game = Game(level: harbour("0:+2,2:+3,0:+1", layout: .quad))
        XCTAssertEqual(game.played, [1])
        game.commit(rod: 2, steps: -3)
        XCTAssertEqual(game.played, [1, 2])
        XCTAssertEqual(game.stack, [Twist(rod: 0, steps: 3)])
        XCTAssertEqual(game.cancels, 1)
        game.commit(rod: 0, steps: -3)
        XCTAssertEqual(game.played, [0, 1, 2])
        XCTAssertEqual(game.cancels, 2)
    }

    /// A win the fine pass calls on a stack that only looks solved plays every vignette still held back.
    @MainActor func testALooksSolvedWinPlaysTheRest() async throws {
        // testIdentityStackIsSolved's stack, dealt as it stands: parsed, it would merge.
        let captured = "1:-4 3:+2 0:-6 3:+7 0:-5 2:+2 1:+4 2:-6 1:-4 0:+11 1:+4 2:+6 1:-4 2:-2 1:+4 0:-6 3:-7 0:+6 3:-2 0:+1"
        var level = harbour(layout: .quad)
        level.scramble = captured.split(separator: " ").map { t in Twist(rod: Int(t.prefix(1))!, steps: Int(t.dropFirst(2))!) }
        let game = Game(level: level)
        game.commit(rod: 0, steps: -1)
        XCTAssertFalse(game.solved)
        XCTAssertEqual(game.played, [])
        // The fine pass runs off the main actor, about 1 s in Debug.
        let deadline = ContinuousClock.now + .seconds(10)
        while !game.solved, .now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(game.solved)
        XCTAssertEqual(game.played, [0, 1, 2])
    }

    /// Every level of the pack is its story's: plughole rules, every vignette held back by the scramble as it opens, three
    /// to a scene (Jack, F1), the stirs the outline gives, and the night carried on from each scene to the next (F2).
    func testTheTable() throws {
        // Chapter 1 opens the pack; the other chapters' levels follow it.
        let dawn = Array(Level.firstStir.prefix(Dawn.allCases.count))
        XCTAssertEqual(dawn.map { $0.story }, Dawn.allCases.map { .dawn($0) })
        XCTAssertEqual(dawn.map(\.scramble.count), [4, 4, 5, 5, 6])
        XCTAssertEqual(dawn.map(\.layout), [.tri, .quad, .tri, .eye, .quad])
        var time = 400.0
        for level in dawn {
            let story = try XCTUnwrap(level.story, level.id), scene = try XCTUnwrap(story.scene, level.id)
            XCTAssertEqual(level.pack, .firstStir)
            XCTAssertEqual(level.layout, scene.layout, level.id)
            XCTAssertEqual(level.motion, .none, level.id)
            XCTAssertTrue(level.seized.isEmpty && level.sockets.isEmpty && level.ratchets.isEmpty, level.id)
            XCTAssertEqual(level.par, level.scramble.count, level.id)
            XCTAssertEqual(story.vignettes.count, 3, level.id)
            XCTAssertTrue(story.vignettes.isSubset(of: level.layout.rods.indices), level.id)
            XCTAssertEqual(story.vignettes, story.vignettes.intersection(level.scramble.map(\.rod)), "\(level.id) opens with one played")
            XCTAssertEqual(scene.late, time, level.id)
            XCTAssertLessThan(scene.early, scene.late, level.id)
            time = scene.early
        }
        XCTAssertEqual(time, 285, "chapter 1 ends at 4:45")
        for level in Level.firstStir {
            let story = try XCTUnwrap(level.story, level.id)
            XCTAssertEqual(level.pack, .firstStir)
            XCTAssertEqual(level.motion, .none, level.id)
            XCTAssertEqual(level.par, level.scramble.count, level.id)
            XCTAssertTrue(story.vignettes.isSubset(of: level.layout.rods.indices), level.id)
        }
    }

    /// Each scene's par is the optimum: no detour beats untwisting.
    func testFirstStirParIsTheOptimum() {
        for level in Level.firstStir {
            XCTAssertEqual(Solver(level.layout).optimum(level.scramble), level.par, level.id)
        }
    }

    /// The caption is the scene's time (Jack, F3), stepping back a share of its window with each of the scramble's entries
    /// gone: never for a push of the player's own, back again on an undo, at the window's start once solved.
    @MainActor func testTheCaptionTellsTheTimeGoingBack() {
        var level = Level.firstStir[0]
        level.id = "first-stir-test"
        let game = Game(level: level, bank: (undos: 10, refilled: nil))
        XCTAssertEqual(game.caption, "6:40 am")
        game.commit(rod: 0, steps: 2)
        XCTAssertEqual(game.caption, "6:40 am")
        game.commit(rod: 0, steps: -2)
        game.commit(rod: 1, steps: -2)
        XCTAssertEqual(game.caption, "6:34 am")
        game.undo()
        XCTAssertEqual(game.caption, "6:40 am")
        for (rod, steps) in [(1, -2), (0, -3), (1, 4), (2, -5)] { game.commit(rod: rod, steps: steps) }
        XCTAssertTrue(game.solved)
        XCTAssertEqual(game.caption, "6:15 am")
        XCTAssertEqual(Dawn.clock(12 * 60 + 5), "12:05 pm")
        XCTAssertEqual(Dawn.clock(5), "12:05 am")
    }

    /// What moves with the time as a body never lies in a disc, its line and glow included, so no rod ever stirs it.
    func testTheBodiesStayClearOfEveryDisc() {
        let margin = Dawn.bodyGlow + Pen.line / 2
        for scene in Dawn.allCases {
            for b in scene.bodies {
                for rod in scene.layout.rods {
                    XCTAssertGreaterThan(simd_distance(SIMD2(b.x, b.y), SIMD2(rod.x, rod.y)), rod.z + b.radius + margin, "\(scene)")
                }
                XCTAssertLessThan(simd_length(SIMD2(b.x, b.y)) + b.radius, 1, "\(scene)")
            }
        }
    }

    /// The pixels of a tank `side` pixels across, in tank units, where vignette k's two states differ, glow included, by
    /// more than 8 in 255, past the renderer's own noise (up to 6 where nothing changed).
    @MainActor private func footprint(_ story: Story, _ k: Int, side: Int) throws -> [SIMD2<Double>] {
        // Each render in its own pool: without them the test host was killed (signal kill) in a later test of the suite.
        func pixels(_ played: Set<Int>) throws -> [UInt8] { try autoreleasepool { try render(played) } }
        func render(_ played: Set<Int>) throws -> [UInt8] {
            let image = try XCTUnwrap((story.scene.map { $0.render(played: played, side: CGFloat(side), scale: 1, colorMode: .nonLinear) }
                                       ?? Harbour.render(.scene(played: played), side: CGFloat(side), scale: 1, colorMode: .nonLinear))?.cgImage)
            var bytes = [UInt8](repeating: 0, count: 4 * side * side)
            let ctx = try XCTUnwrap(CGContext(data: &bytes, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 4 * side,
                                              space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return bytes
        }
        let held = try pixels([]), played = try pixels([k])
        var marks: [SIMD2<Double>] = []
        for i in 0..<side * side where (0..<4).contains(where: { abs(Int(held[4 * i + $0]) - Int(played[4 * i + $0])) > 8 }) {
            let px = SIMD2(Double(i % side), Double(i / side)) + 0.5
            marks.append(px / Double(side) * 2 - 1)
        }
        return marks
    }

    /// Each vignette changes nothing past a pixel outside its own core, so the core the layer cuts in clips none of it.
    /// Over every heal order: no vignette's light reaches the core of a rod with an entry removable right after its heal,
    /// so light never shows the next move; and the entries left move none of it by half a pixel, so it never plays
    /// smeared (the lab's rule: a vignette plays only once every disc over it is still).
    @MainActor func testNoVignetteShowsTheNextMove() throws {
        let side = 512, pixel = 2.0 / Double(side)
        // Jack's call: the harbour as the lab drew it plays the lantern's falling shards (5 px at most on the largest
        // phone) and the boat's stern in the cottage's shear ring, still stirred. Its scene 16 is to be redrawn (F4).
        let known: Set<String> = ["first-stir-test: vignette 0 plays smeared by rod 2", "first-stir-test: vignette 1 plays smeared by rod 2"]
        var faults: Set<String> = []
        for level in Level.firstStir + [harbour()] {
            let story = try XCTUnwrap(level.story)
            let layout = level.layout, rods = layout.rods
            func centre(_ rod: Int) -> SIMD2<Double> { SIMD2(rods[rod].x, rods[rod].y) }
            var marks: [Int: [SIMD2<Double>]] = [:]
            for k in story.vignettes {
                let m = try footprint(story, k, side: side)
                XCTAssertFalse(m.isEmpty, "\(level.id): vignette \(k) changes nothing")
                let core = Tank.plateau * rods[k].z
                XCTAssertTrue(m.allSatisfy { simd_distance($0, centre(k)) <= core + pixel }, "\(level.id): vignette \(k) leaves its core")
                if story.scene != nil {
                    // The art spec: 0.02 inside the core's edge, so no glow clips there, and clear of the knob.
                    let far = m.map { simd_distance($0, centre(k)) }.max()!, near = m.map { simd_distance($0, centre(k)) }.min()!
                    XCTAssertLessThanOrEqual(far, core - 0.02 + pixel, "\(level.id): vignette \(k) comes within 0.02 of its core's edge")
                    XCTAssertGreaterThanOrEqual(near, Tank.coreRadius + 0.015 - pixel, "\(level.id): vignette \(k) reaches its knob")
                }
                marks[k] = m
            }
            var seen: Set<[Twist]> = []
            func heal(_ entries: [Game.Entry]) {
                guard seen.insert(entries.map(\.twist)).inserted else { return }
                let stack = entries.map(\.twist)
                for i in layout.removable(stack) {
                    var next = entries
                    next.commit(Game.Entry(twist: Twist(rod: stack[i].rod, steps: -stack[i].steps), pushed: true), in: layout)
                    let left = next.map(\.twist)
                    for k in Set(entries.flatMap(\.tags)).subtracting(next.flatMap(\.tags)) {
                        for j in layout.removable(left) {
                            let rod = left[j].rod, core = Tank.plateau * rods[rod].z
                            if marks[k]!.contains(where: { simd_distance($0, centre(rod)) < core + pixel }) {
                                faults.insert("\(level.id): vignette \(k)'s light reaches rod \(rod)'s core, removable next")
                            }
                        }
                        for rod in Set(left.map(\.rod)) {
                            let word = left.filter { $0.rod == rod }
                            let moved = marks[k]!.contains { p in
                                simd_distance(word.reduce(p) { Tank.twist($0, rod: rods[rod], angle: Double($1.steps) * Tank.step) }, p) > Tank.halfPixel
                            }
                            if moved { faults.insert("\(level.id): vignette \(k) plays smeared by rod \(rod)") }
                        }
                    }
                    heal(next)
                }
            }
            heal(level.scramble.map { Game.Entry(twist: $0, pushed: false, tags: story.vignettes.intersection([$0.rod])) })
        }
        XCTAssertEqual(faults, known)
    }

    /// With every vignette played, the composite is the played scene over the sky: where the held-back and played scenes
    /// agree, no core's edge shows where it is cut in.
    @MainActor func testTheCutInCoresLeaveNoSeam() throws {
        let side = 384
        for scene in Dawn.allCases {
            func layer(sky minutes: Double? = nil, played: Set<Int> = []) throws -> UIImage {
                try XCTUnwrap(scene.render(sky: minutes, played: played, side: CGFloat(side), scale: 1))
            }
            let late = try layer(sky: scene.late), early = try layer(sky: scene.early)
            let held = try layer(), played = try layer(played: scene.vignettes)
            func pixels(_ layers: SceneLayers, _ shown: [Int: Double]) throws -> [UInt8] {
                try autoreleasepool {
                    let r = ImageRenderer(content: SceneComposite(scene: scene, layers: layers, sky: 0.5, minutes: scene.late, side: CGFloat(side),
                                                                  shown: shown).drawingGroup(colorMode: .extendedLinear))
                    r.scale = 1
                    let image = try XCTUnwrap(r.cgImage)
                    var bytes = [UInt8](repeating: 0, count: 4 * side * side)
                    let ctx = try XCTUnwrap(CGContext(data: &bytes, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 4 * side,
                                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                    ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
                    return bytes
                }
            }
            let cores = SceneComposite.cores(scene, side: CGFloat(side), scale: 1)
            let cut = try pixels((late, early, held, played, cores), Dictionary(uniqueKeysWithValues: scene.vignettes.map { ($0, 1.0) }))
            let whole = try pixels((late, early, played, played, cores), [:]), none = try pixels((late, early, held, held, cores), [:])
            // Only where the two scenes agree: a vignette's faint glow tail can cross its core's edge, and steps there.
            var worst = 0
            for i in cut.indices where abs(Int(whole[i]) - Int(none[i])) <= 1 { worst = max(worst, abs(Int(cut[i]) - Int(whole[i]))) }
            XCTAssertLessThanOrEqual(worst, 1, "\(scene): a core's edge shows")
        }
    }

    /// The layers bake at the screen's scale on the largest phone, and at a lower one rather than pass the budget.
    func testTheLayersBakeWithinTheBudget() {
        // The Pro Max's tank: (440 points wide) / 1.045.
        let side: CGFloat = 421
        XCTAssertEqual(Harbour.bakeScale(side: side, scale: 3), 3)
        XCTAssertLessThanOrEqual(Harbour.layerBytes(side: side, scale: 3), Harbour.budget)
        let huge = Harbour.bakeScale(side: 2 * side, scale: 3)
        XCTAssertLessThan(huge, 3)
        XCTAssertLessThanOrEqual(Harbour.layerBytes(side: 2 * side, scale: huge), Harbour.budget)
        // A scene's four layers, the two skies and the scene held back and played.
        XCTAssertEqual(SceneLayer.bakeScale(side: side, scale: 3), 3)
        XCTAssertLessThanOrEqual(SceneLayer.layerBytes(side: side, scale: 3), Harbour.budget)
        let large = SceneLayer.bakeScale(side: 2 * side, scale: 3)
        XCTAssertLessThan(large, 3)
        XCTAssertLessThanOrEqual(SceneLayer.layerBytes(side: 2 * side, scale: large), Harbour.budget)
    }
}
