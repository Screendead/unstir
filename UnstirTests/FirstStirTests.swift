// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import XCTest
import simd
@testable import Unstir

final class FirstStirTests: XCTestCase {
    /// First Stir's harbour under an id no level has, so solving it saves no best.
    private func harbour(_ scramble: String = "2:+5,1:-4,0:+3", layout: Unstir.Layout = .tri) -> Level {
        var level = Level.firstStir[0]
        level.id = "first-stir-test"
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

    /// Every level of the pack is its story's: plughole rules, every vignette held back by the scramble as it opens.
    func testTheTable() throws {
        XCTAssertFalse(Level.firstStir.isEmpty)
        for level in Level.firstStir {
            let story = try XCTUnwrap(level.story, level.id)
            XCTAssertEqual(level.pack, .firstStir)
            XCTAssertEqual(level.layout, story.layout, level.id)
            XCTAssertEqual(level.motion, .none, level.id)
            XCTAssertTrue(level.seized.isEmpty && level.sockets.isEmpty && level.ratchets.isEmpty, level.id)
            XCTAssertEqual(level.par, level.scramble.count, level.id)
            XCTAssertFalse(level.note.isEmpty, level.id)
            XCTAssertTrue(story.vignettes.isSubset(of: level.layout.rods.indices), level.id)
            XCTAssertEqual(story.vignettes, story.vignettes.intersection(level.scramble.map(\.rod)), "\(level.id) opens with one played")
        }
    }

    /// The pixels of a tank `side` pixels across, in tank units, where vignette k's two states differ, glow included, past
    /// the renderer's own noise (up to 6 in 255 where nothing changed). A rescue scene's vignette is drawn alone, since
    /// how the renderer lays down light near any drawing shifts with what else the canvas holds.
    @MainActor private func footprint(_ k: Int, of story: Story, side: Int) throws -> [SIMD2<Double>] {
        func pixels(_ played: Set<Int>) throws -> [UInt8] {
            let render = if case .rescue(let n) = story {
                Rescue.render(n, vignette: k, played: !played.isEmpty, side: CGFloat(side), colorMode: .nonLinear)
            } else {
                story.render(.scene(played: played), side: CGFloat(side), scale: 1, colorMode: .nonLinear)
            }
            let image = try XCTUnwrap(render?.cgImage)
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

    /// How far inside its core's edge a vignette's change keeps, glow included, and the knob it keeps clear of: its
    /// radius, 0.07, and 0.015 more.
    private static let margin = 0.02, knob = 0.085

    /// Each vignette changes nothing past a pixel outside its own core, so the core the layer cuts in clips none of it.
    /// Over every heal order: no vignette's light reaches the core of a rod with an entry removable right after its heal,
    /// so light never shows the next move; and the entries left move none of it by half a pixel, so it never plays
    /// smeared (the lab's rule: a vignette plays only once every disc over it is still).
    @MainActor func testNoVignetteShowsTheNextMove() throws {
        let side = 256, pixel = 2.0 / Double(side)
        // Jack's call: the harbour as the lab drew it plays the lantern's falling shards (5 px at most on the largest
        // phone) and the boat's stern in the cottage's shear ring, still stirred.
        let known: Set<String> = ["first-stir-1: vignette 0 plays smeared by rod 2", "first-stir-1: vignette 1 plays smeared by rod 2"]
        var faults: Set<String> = []
        for level in Level.firstStir {
            let story = try XCTUnwrap(level.story)
            let layout = level.layout, rods = layout.rods
            func centre(_ rod: Int) -> SIMD2<Double> { SIMD2(rods[rod].x, rods[rod].y) }
            var marks: [Int: [SIMD2<Double>]] = [:]
            for k in story.vignettes {
                let m = try footprint(k, of: story, side: side)
                XCTAssertFalse(m.isEmpty, "\(level.id): vignette \(k) changes nothing")
                let core = Tank.plateau * rods[k].z
                XCTAssertTrue(m.allSatisfy { simd_distance($0, centre(k)) <= core + pixel }, "\(level.id): vignette \(k) leaves its core")
                // The art spec, which the lab's harbour predates: a margin inside the core's edge, and clear of the knob.
                if story != .harbour {
                    let far = m.max { simd_distance($0, centre(k)) < simd_distance($1, centre(k)) }!
                    let near = m.min { simd_distance($0, centre(k)) < simd_distance($1, centre(k)) }!
                    XCTAssertLessThanOrEqual(simd_distance(far, centre(k)), core - Self.margin + pixel,
                                             "\(level.id): vignette \(k) nears its core's edge at \(far)")
                    XCTAssertGreaterThanOrEqual(simd_distance(near, centre(k)), Self.knob - pixel,
                                                "\(level.id): vignette \(k) reaches under its knob at \(near)")
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

    /// The layers bake at the screen's scale on the largest phone, and at a lower one rather than pass the budget.
    func testTheLayersBakeWithinTheBudget() {
        // The Pro Max's tank: (440 points wide) / 1.045.
        let side: CGFloat = 421
        XCTAssertEqual(Harbour.bakeScale(side: side, scale: 3), 3)
        XCTAssertLessThanOrEqual(Harbour.layerBytes(side: side, scale: 3), Harbour.budget)
        let huge = Harbour.bakeScale(side: 2 * side, scale: 3)
        XCTAssertLessThan(huge, 3)
        XCTAssertLessThanOrEqual(Harbour.layerBytes(side: 2 * side, scale: huge), Harbour.budget)
    }
}
