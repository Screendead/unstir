// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import XCTest
import simd
@testable import Unstir

final class FirstStirTests: XCTestCase {
    /// The harbour in the storm (scene 16) under an id no level has, so solving it saves no best.
    private func harbour(_ scramble: String = "2:+5,1:-4,0:+3", layout: Unstir.Layout = .tri) -> Level {
        var level = Level.firstStir[0]
        level.id = "first-stir-test"
        level.story = .storm(.harbour)
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
        // Chapter 2 carries on from it.
        let rescue = Array(Level.firstStir.dropFirst(dawn.count).prefix(Rescue.allCases.count))
        XCTAssertEqual(rescue.map { $0.story }, Rescue.allCases.map { .rescue($0) })
        XCTAssertEqual(rescue.map(\.scramble.count), [6, 6, 7, 7, 7])
        XCTAssertEqual(rescue.map(\.layout), [.pent, .eye, .quad, .tri, .pent])
        for level in rescue {
            let story = try XCTUnwrap(level.story, level.id), scene = try XCTUnwrap(story.scene, level.id)
            XCTAssertEqual(level.layout, scene.layout, level.id)
            XCTAssertTrue(level.seized.isEmpty && level.sockets.isEmpty && level.ratchets.isEmpty, level.id)
            XCTAssertEqual(story.vignettes.count, 3, level.id)
            XCTAssertEqual(story.vignettes, story.vignettes.intersection(level.scramble.map(\.rod)), "\(level.id) opens with one played")
            XCTAssertEqual(scene.late, time, level.id)
            XCTAssertLessThan(scene.early, scene.late, level.id)
            time = scene.early
        }
        XCTAssertEqual(time, 150, "chapter 2 ends at 2:30")
        // Chapter 3 carries on from it.
        let flood = Array(Level.firstStir.dropFirst(dawn.count + rescue.count).prefix(Flood.allCases.count))
        XCTAssertEqual(flood.map { $0.story }, Flood.allCases.map { .flood($0) })
        XCTAssertEqual(flood.map(\.scramble.count), [7, 8, 8, 8, 9])
        XCTAssertEqual(flood.map(\.layout), [.eye, .pent, .quad, .eye, .pent])
        for level in flood {
            let story = try XCTUnwrap(level.story, level.id), scene = try XCTUnwrap(story.scene, level.id)
            XCTAssertEqual(level.layout, scene.layout, level.id)
            XCTAssertTrue(level.seized.isEmpty && level.sockets.isEmpty && level.ratchets.isEmpty, level.id)
            XCTAssertEqual(story.vignettes.count, 3, level.id)
            XCTAssertEqual(story.vignettes, story.vignettes.intersection(level.scramble.map(\.rod)), "\(level.id) opens with one played")
            XCTAssertEqual(scene.late, time, level.id)
            XCTAssertLessThan(scene.early, scene.late, level.id)
            time = scene.early
        }
        XCTAssertEqual(time, 30, "chapter 3 ends at 12:30")
        // Chapter 4 carries on from it, back past midnight to 9:30 pm.
        let storm = Array(Level.firstStir.dropFirst(dawn.count + rescue.count + flood.count).prefix(Storm.allCases.count))
        XCTAssertEqual(storm.map { $0.story }, Storm.allCases.map { .storm($0) })
        XCTAssertEqual(storm.map(\.scramble.count), [8, 9, 9, 10, 10])
        XCTAssertEqual(storm.map(\.layout), [.tri, .quad, .pent, .eye, .pent])
        XCTAssertEqual(storm.map { $0.story?.vignettes }, [[0, 1, 2], [0, 2, 3], [0, 2, 3], [0, 1, 2], [0, 1, 3]])
        for level in storm {
            let story = try XCTUnwrap(level.story, level.id), scene = try XCTUnwrap(story.scene, level.id)
            XCTAssertEqual(level.layout, scene.layout, level.id)
            XCTAssertTrue(level.seized.isEmpty && level.sockets.isEmpty && level.ratchets.isEmpty, level.id)
            XCTAssertEqual(story.vignettes, story.vignettes.intersection(level.scramble.map(\.rod)), "\(level.id) opens with one played")
            XCTAssertEqual(scene.late, time, level.id)
            XCTAssertLessThan(scene.early, scene.late, level.id)
            time = scene.early
        }
        XCTAssertEqual(time, -150, "chapter 4 ends at 9:30 pm")
        // The harbour heals as the lab did: the cottage's entry is the bottom one, under every other rod's.
        XCTAssertEqual(storm[0].scramble.first?.rod, 2)
        XCTAssertEqual(storm[0].scramble.filter { $0.rod == 2 }.count, 2)
        // Chapter 5 carries on from it and closes the pack, its times in the evening's own minutes.
        let dusk = Array(Level.firstStir.suffix(Dusk.allCases.count))
        XCTAssertEqual(Level.firstStir.count, dawn.count + rescue.count + flood.count + storm.count + dusk.count)
        XCTAssertEqual(dusk.map { $0.story }, Dusk.allCases.map { .dusk($0) })
        XCTAssertEqual(dusk.map(\.scramble.count), [8, 8, 7, 6, 5])
        XCTAssertEqual(dusk.map(\.layout), [.quad, .eye, .pent, .quad, .tri])
        XCTAssertEqual(time + 24 * 60, 21 * 60 + 30, "chapter 5 opens at 9:30 pm")
        time = 21 * 60 + 30
        for level in dusk {
            let story = try XCTUnwrap(level.story, level.id), scene = try XCTUnwrap(story.scene, level.id)
            XCTAssertEqual(level.layout, scene.layout, level.id)
            XCTAssertTrue(level.seized.isEmpty && level.sockets.isEmpty && level.ratchets.isEmpty, level.id)
            XCTAssertEqual(story.vignettes.count, 3, level.id)
            XCTAssertEqual(story.vignettes, story.vignettes.intersection(level.scramble.map(\.rod)), "\(level.id) opens with one played")
            XCTAssertEqual(scene.late, time, level.id)
            XCTAssertLessThan(scene.early, scene.late, level.id)
            time = scene.early
        }
        XCTAssertEqual(time, 19 * 60 + 40, "chapter 5 ends at 7:40 pm")
        // The stir is the pack's last heal: the cup's one entry lies under every other, on tri, where every disc meets.
        let stir = try XCTUnwrap(dusk.last)
        XCTAssertEqual(stir.scramble.first?.rod, 2)
        XCTAssertEqual(stir.scramble.filter { $0.rod == 2 }.count, 1)
        XCTAssertEqual(Level.firstStir.map(\.id), (1...Level.firstStir.count).map { Pack.firstStir.id($0) })
        for level in Level.firstStir {
            let story = try XCTUnwrap(level.story, level.id)
            XCTAssertEqual(level.pack, .firstStir)
            XCTAssertEqual(level.motion, .none, level.id)
            XCTAssertEqual(level.par, level.scramble.count, level.id)
            XCTAssertTrue(story.vignettes.isSubset(of: level.layout.rods.indices), level.id)
        }
    }

    /// Chapter 2 opens on the sky chapter 1 ends on (F2): at 4:45 the Rescue's sky and sea are the dawn's.
    func testTheRescueOpensOnTheDawnsLastSky() {
        let dawn = Dawn.tones(Dawn.tea.early)
        XCTAssertEqual(Rescue.homeLight.late, Dawn.tea.early)
        XCTAssertEqual(Rescue.skyTones(Rescue.homeLight.late), [dawn.zenith, dawn.middle, dawn.low])
        XCTAssertEqual(Rescue.seaTones(Rescue.homeLight.late)[0], dawn.sea)
        XCTAssertNotEqual(Rescue.skyTones(Rescue.homeLight.early), [dawn.zenith, dawn.middle, dawn.low])
    }

    /// Chapter 3 opens on the sky and rain chapter 2 ends on (F2): at 2:30 the Flood's sky, sea and rain are the Rescue's.
    func testTheFloodOpensOnTheRescuesLastSky() {
        XCTAssertEqual(Flood.path.late, Rescue.door.early)
        XCTAssertEqual(Flood.skyTones(Flood.path.late), Rescue.skyTones(Rescue.door.early))
        XCTAssertEqual(Flood.seaTones(Flood.path.late), Rescue.seaTones(Rescue.door.early))
        XCTAssertEqual(Flood.rain(Flood.path.late), Rescue.rain(Rescue.door.early))
        XCTAssertNotEqual(Flood.skyTones(Flood.path.early), Rescue.skyTones(Rescue.door.early))
        XCTAssertLessThan(Flood.rain(Flood.quay.early), Double(Rescue.drops.count))
    }

    /// Chapter 4 opens on the sky chapter 3 ends on and ends on the sky chapter 5 opens on (F2): at 12:30 the Storm's sky
    /// and sea are the Flood's, and at 9:30 pm Dusk Before's, with the lab's storm between and no rain left at 9:30.
    func testTheStormsSkyMeetsItsNeighbours() {
        XCTAssertEqual(Storm.harbour.late, Flood.quay.early)
        XCTAssertEqual(Storm.washing.early + 24 * 60, Dusk.lamp.late)
        let peak = Storm.tones(Storm.harbour.late), dusk = Storm.tones(Storm.washing.early)
        XCTAssertEqual([peak.zenith, peak.middle, peak.low], Flood.skyTones(Flood.quay.early))
        XCTAssertEqual(peak.sea, Flood.seaTones(Flood.quay.early)[0])
        XCTAssertEqual([dusk.zenith, dusk.middle, dusk.low], Dusk.skyTones(Dusk.lamp.late))
        XCTAssertEqual(dusk.sea, Dusk.seaTone(Dusk.lamp.late))
        let storm = Storm.tones(Storm.lightning.late)
        XCTAssertEqual(storm.zenith, Tone(0x000000).mix(Dusk.skyTones(Dusk.lamp.late)[0], pow(Storm.back(Storm.lightning.late), 2)),
                       "the lab's storm by the end of the first scene")
        XCTAssertEqual(Storm.rain(Storm.washing.early), 0)
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
        // The Storm's window crosses midnight: minutes before it are negative.
        XCTAssertEqual(Storm.clock(Storm.harbour.late), "12:30 am")
        XCTAssertEqual(Storm.clock(Storm.harbour.early), "11:40 pm")
        XCTAssertEqual(Storm.clock(Storm.washing.early), "9:30 pm")
        XCTAssertEqual(Storm.clock(Storm.harbour.minutes(wound: 1, of: 8)), "12:24 am")
    }

    /// What moves with the time as a body never lies in a disc, its line and glow included, so no rod ever stirs it.
    func testTheBodiesStayClearOfEveryDisc() {
        let margin = Dawn.bodyGlow + Pen.line / 2
        let scenes: [(String, Unstir.Layout, [(x: Double, y: Double, radius: Double)])] =
            Dawn.allCases.map { ("\($0)", $0.layout, $0.bodies) } + Dusk.allCases.map { ("\($0)", $0.layout, $0.bodies) }
        XCTAssertFalse(Dusk.lamp.bodies.isEmpty)
        for (scene, layout, bodies) in scenes {
            for b in bodies {
                for rod in layout.rods {
                    XCTAssertGreaterThan(simd_distance(SIMD2(b.x, b.y), SIMD2(rod.x, rod.y)), rod.z + b.radius + margin, scene)
                }
                XCTAssertLessThan(simd_length(SIMD2(b.x, b.y)) + b.radius, 1, scene)
            }
        }
    }

    /// The pixels of a tank `side` pixels across, in tank units, where vignette k's two states differ, glow included, by
    /// more than 8 in 255, past the renderer's own noise (up to 6 where nothing changed).
    @MainActor private func footprint(_ story: Story, _ played: Set<Int>, side: Int) throws -> [SIMD2<Double>] {
        // Each render in its own pool: without them the test host was killed (signal kill) in a later test of the suite.
        func pixels(_ played: Set<Int>) throws -> [UInt8] { try autoreleasepool { try render(played) } }
        func render(_ played: Set<Int>) throws -> [UInt8] {
            let image = try XCTUnwrap(story.scene?.render(played: played, side: CGFloat(side), scale: 1, colorMode: .nonLinear)?.cgImage)
            var bytes = [UInt8](repeating: 0, count: 4 * side * side)
            let ctx = try XCTUnwrap(CGContext(data: &bytes, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 4 * side,
                                              space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return bytes
        }
        let held = try pixels([]), played = try pixels(played)
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
        var faults: Set<String> = []
        for level in Level.firstStir {
            let story = try XCTUnwrap(level.story)
            let layout = level.layout, rods = layout.rods
            func centre(_ rod: Int) -> SIMD2<Double> { SIMD2(rods[rod].x, rods[rod].y) }
            // The two layers the game bakes, every vignette held back and every one played, differ only in their cores.
            let stray = try footprint(story, story.vignettes, side: side).filter { p in
                !story.vignettes.contains { simd_distance(p, centre($0)) <= Tank.plateau * rods[$0].z + pixel }
            }
            XCTAssertTrue(stray.isEmpty, "\(level.id): the baked layers differ outside every core, at \(stray.prefix(3))")
            // Again at the largest phone's own pixels, the tank's side at 3x, where a stray the coarser render hides would
            // show.
            let phone = 1263, fine = 2.0 / Double(phone)
            let strays = try footprint(story, story.vignettes, side: phone).filter { p in
                !story.vignettes.contains { simd_distance(p, centre($0)) <= Tank.plateau * rods[$0].z + fine }
            }
            XCTAssertTrue(strays.isEmpty, "\(level.id): at the phone's scale the baked layers differ outside every core, at \(strays.prefix(3))")
            var marks: [Int: [SIMD2<Double>]] = [:]
            for k in story.vignettes {
                let m = try footprint(story, [k], side: side)
                XCTAssertFalse(m.isEmpty, "\(level.id): vignette \(k) changes nothing")
                let core = Tank.plateau * rods[k].z
                XCTAssertTrue(m.allSatisfy { simd_distance($0, centre(k)) <= core + pixel }, "\(level.id): vignette \(k) leaves its core")
                do {
                    // The art spec: 0.02 inside the core's edge, so no glow clips there, and clear of the knob.
                    let reach = m.map { (p: $0, d: simd_distance($0, centre(k))) }
                    let far = reach.max { $0.d < $1.d }!, near = reach.min { $0.d < $1.d }!
                    XCTAssertLessThanOrEqual(far.d, core - 0.02 + pixel, "\(level.id): vignette \(k) comes within 0.02 of its core's edge at \(far.p)")
                    XCTAssertGreaterThanOrEqual(near.d, Tank.coreRadius + 0.015 - pixel, "\(level.id): vignette \(k) reaches its knob at \(near.p)")
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
        XCTAssertEqual(faults, [])
    }

    /// With every vignette played, the composite is the played scene over the sky: where the held-back and played scenes
    /// agree, no core's edge shows where it is cut in.
    @MainActor func testTheCutInCoresLeaveNoSeam() throws {
        let side = 384
        for scene in Level.firstStir.compactMap({ $0.story?.scene }) {
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
        // A scene's four layers, the two skies and the scene held back and played.
        XCTAssertEqual(SceneLayer.bakeScale(side: side, scale: 3), 3)
        XCTAssertLessThanOrEqual(SceneLayer.layerBytes(side: side, scale: 3), Harbour.budget)
        let large = SceneLayer.bakeScale(side: 2 * side, scale: 3)
        XCTAssertLessThan(large, 3)
        XCTAssertLessThanOrEqual(SceneLayer.layerBytes(side: 2 * side, scale: large), Harbour.budget)
    }

    /// The night forwards (D1): all 25 scenes in story order, about two minutes, the clock never running back across a
    /// seam, each scene from its played state to its held-back one, every vignette going back as the first entry on its
    /// rod returns, so each frame is a stack the game can stand in.
    @MainActor func testTheNightForwardsPlaysTheNightInItsOwnOrder() {
        let levels = NightForwards.levels
        XCTAssertEqual(levels.map(\.id), Level.firstStir.reversed().map(\.id))
        XCTAssertEqual(levels.count, 25)
        XCTAssertTrue(levels.first!.endsFirstStir)
        XCTAssertFalse(Level.firstStir.dropLast().contains { $0.endsFirstStir })
        XCTAssertEqual(NightForwards.duration, 165, accuracy: 5)
        // One axis of minutes from the evening on: the chapters past midnight are a day on from Dusk Before's.
        func axis(_ level: Level, _ minutes: Double) -> Double {
            if case .dusk = level.story { return minutes }
            return minutes + 24 * 60
        }
        var last = -Double.infinity
        for t in stride(from: 0, through: NightForwards.duration, by: 0.05) {
            let now = NightForwards.at(t), level = levels[now.index], scene = level.story!.scene!
            let minutes = axis(level, scene.early + (scene.late - scene.early) * now.run)
            XCTAssertGreaterThanOrEqual(minutes, last, "t \(t)")
            last = minutes
            if now.next > 0 {
                let next = levels[now.index + 1], early = next.story!.scene!.early
                XCTAssertEqual(axis(next, early), minutes, accuracy: 1e-9, "the next scene takes over at the same minute")
            }
        }
        XCTAssertEqual(NightForwards.at(0).index, 0)
        XCTAssertEqual(NightForwards.at(NightForwards.duration).index, 24)
        XCTAssertEqual(NightForwards.at(NightForwards.duration).run, 1)
        for level in levels {
            let n = level.scramble.count, returns = NightForwards.returns(level)
            XCTAssertEqual(Set(returns.keys), level.story!.vignettes, level.id)
            XCTAssertEqual(NightForwards.shown(level, seconds: 0, cut: false).values.min(), 1, "\(level.id) opens played")
            XCTAssertEqual(NightForwards.shown(level, seconds: NightForwards.length, cut: false).values.max(), 0,
                           "\(level.id) ends held back")
            XCTAssertEqual(NightForwards.shown(level, seconds: NightForwards.length, cut: true).values.max(), 0, level.id)
            XCTAssertLessThanOrEqual(returns.values.max()! + NightForwards.fade, NightForwards.length - NightForwards.blend,
                                     level.id)
            // With c of the scramble's entries back, the film may show only what the game plays with the top n - c undone.
            var states: [Set<Int>] = []
            for c in 0...n {
                let game = Game(level: level, bank: (undos: 10, refilled: nil))
                for e in level.scramble.suffix(n - c).reversed() { game.commit(rod: e.rod, steps: -e.steps) }
                XCTAssertEqual(NightForwards.played(level, entries: c), game.played, "\(level.id) at \(c)")
                states.append(game.played)
            }
            for seconds in stride(from: 0, through: NightForwards.length, by: 0.02) {
                for cut in [false, true] {
                    let shown = NightForwards.shown(level, seconds: seconds, cut: cut)
                    XCTAssertTrue(states.contains(Set(shown.filter { $0.value > 0 }.keys)), "\(level.id) at \(seconds) s")
                    XCTAssertTrue(states.contains(Set(shown.filter { $0.value == 1 }.keys)), "\(level.id) at \(seconds) s")
                }
                let going = NightForwards.shown(level, seconds: seconds, cut: false).values.filter { 0 < $0 && $0 < 1 }
                XCTAssertLessThanOrEqual(going.count, 1, "\(level.id): one vignette goes back at a time")
            }
        }
    }
}
