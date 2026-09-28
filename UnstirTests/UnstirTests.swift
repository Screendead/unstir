// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import os
import struct SwiftUI.EnvironmentValues
import XCTest
import simd
@testable import Unstir

final class UnstirTests: XCTestCase {
    /// The undo bank lives in the shared defaults, so every run starts it full.
    override func setUp() { UserDefaults.standard.removeObject(forKey: "undos.spent") }

    func testPush() {
        var s: [Twist] = [Twist(rod: 0, steps: 3)]
        XCTAssertEqual(s.commit(rod: 1, steps: -2, in: .tri), .pushed)
        XCTAssertEqual(s, [Twist(rod: 0, steps: 3), Twist(rod: 1, steps: -2)])
    }

    func testSameRodReduces() {
        var s: [Twist] = [Twist(rod: 2, steps: 5)]
        XCTAssertEqual(s.commit(rod: 2, steps: -2, in: .tri), .reduced)
        XCTAssertEqual(s, [Twist(rod: 2, steps: 3)])
    }

    func testCancelPopsAndEmptyIsSolved() {
        var s: [Twist] = [Twist(rod: 1, steps: 4), Twist(rod: 0, steps: 3)]
        XCTAssertEqual(s.commit(rod: 0, steps: -3, in: .tri), .cancelled)
        XCTAssertEqual(s, [Twist(rod: 1, steps: 4)])
        XCTAssertFalse(s.isEmpty)
        XCTAssertEqual(s.commit(rod: 1, steps: -4, in: .tri), .cancelled)
        XCTAssertTrue(s.isEmpty)
    }

    func testSeparateRodsCommute() {
        var s = [Twist].parse("0:+3,2:-4", in: .quad)
        XCTAssertEqual(s.commit(rod: 0, steps: -3, in: .quad), .cancelled)
        XCTAssertEqual(s.commit(rod: 2, steps: 4, in: .quad), .cancelled)
        XCTAssertTrue(s.isEmpty)
    }

    func testOverlappingTwistThatDoesNotCommutePushes() {
        var s = [Twist].parse("0:+3,1:+4", in: .quad)
        XCTAssertEqual(s.commit(rod: 0, steps: -3, in: .quad), .pushed)
    }

    /// After 1:+4 no point of rod 0's disc comes within reach of rod 2, so the word holds that disc still and every rod 0
    /// twist commutes with it, though rod 0 overlaps rod 1.
    func testTwistCommutesWithAWordThatHoldsItsDiscStill() {
        let stack = [Twist].parse("0:+1,2:+2,1:+4,2:-6,1:-4", in: .quad)
        for steps in [1, -5, 11] { XCTAssertTrue(Layout.quad.commutes(stack, above: 0, rod: 0, steps: steps)) }
    }

    /// Nightmare 11 as the player unstirred it: the picture came back while the old rule still held 21 entries.
    func testNightmare11UnstirsToEmpty() {
        var s = [Twist].parse("0:+4,1:-4,3:+2,0:-6,3:+7,0:-5,2:+2,1:+4,2:-6,1:-6", in: .quad)
        let moves = [(1, 2), (0, 11), (1, 4), (2, 6), (1, -4), (2, -2), (1, 4), (0, -6), (3, -7), (0, 6), (3, -2), (0, -4)]
        XCTAssertFalse(moves.map { s.commit(rod: $0.0, steps: $0.1, in: .quad) }.contains(.pushed))
        XCTAssertTrue(s.isEmpty)
    }

    /// 2:+6 cancels 2:-6 through a word that holds rod 2's disc still, which leaves 1:+4 and 1:-6 touching: they must
    /// merge then, so taking the rest of the rod 1 seam off later cancels.
    func testCancelBelowTheTopMergesWhatItUncovers() {
        var s = [Twist].parse("0:+4,1:-4,3:+2,0:-6,3:+7,0:-5,2:+2,1:+4,2:-6,1:-6", in: .quad)
        for (rod, steps) in [(0, 11), (1, 6), (2, 6), (1, -6), (0, -11)] { s.commit(rod: rod, steps: steps, in: .quad) }
        XCTAssertEqual(s.commit(rod: 1, steps: 2, in: .quad), .cancelled)
    }

    /// The old rule's stack on nightmare 11, captured by debugger, less its bottom 0:+4: the identity. Taking a twist off the
    /// top leaves it standing, so only the fine pass can call the win.
    @MainActor func testIdentityStackIsSolved() async throws {
        let captured = "1:-4 3:+2 0:-6 3:+7 0:-5 2:+2 1:+4 2:-6 1:-4 0:+11 1:+4 2:+6 1:-4 2:-2 1:+4 0:-6 3:-7 0:+6 3:-2 0:+1"
        let scramble = captured.split(separator: " ").map { t in Twist(rod: Int(t.prefix(1))!, steps: Int(t.dropFirst(2))!) }
        let game = Game(level: Level(id: "test", label: "", title: "", layout: .quad, scramble: scramble))
        game.commit(rod: 0, steps: -1)
        XCTAssertFalse(game.solved)
        // The fine pass runs off the main actor, about 1 s in Debug.
        let deadline = ContinuousClock.now + .seconds(10)
        while !game.solved, .now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(game.solved)
    }

    @MainActor func testResetZeroesMovesButCostsClean() {
        let game = Game(level: Level(id: "test-reset", label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)]))
        XCTAssertTrue(game.firstTry)
        game.commit(rod: 0, steps: -2)
        game.reset()
        XCTAssertEqual(game.moves, 0)
        game.commit(rod: 0, steps: -4)
        XCTAssertTrue(game.solved)
        XCTAssertEqual(game.over, 0)
        XCTAssertFalse(game.clean)
    }

    /// At par the newest stir can still be adjusted or undone, but a new stir ends the run.
    @MainActor func testEndlessEndsOnTheFirstStirPastPar() {
        let game = Game(level: .endless(Run(seed: 7)))
        for i in 0..<game.par { game.commit(rod: i % 2, steps: 1) }
        let last = (game.par - 1) % 2
        game.commit(rod: last, steps: 1)
        XCTAssertEqual(game.moves, game.par)
        game.undo()
        XCTAssertEqual(game.moves, game.par - 1)
        XCTAssertEqual(Best.undos, 9)
        game.commit(rod: last, steps: 1)
        XCTAssertFalse(game.finished)
        game.commit(rod: 1 - last, steps: 1)
        XCTAssertTrue(game.finished)
        XCTAssertFalse(game.solved)
    }

    /// Only the newest stir comes back free; turning an older rod back is a new stir.
    @MainActor func testTurnsOfOneRodInARowAreOneStir() {
        let game = Game(level: Level(id: "test-stir", label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)]))
        game.commit(rod: 0, steps: -1)
        game.commit(rod: 0, steps: 5)
        XCTAssertEqual(game.history, [Twist(rod: 0, steps: 4)])
        game.commit(rod: 0, steps: -4)
        XCTAssertEqual(game.moves, 0)
        game.commit(rod: 0, steps: 2)
        game.commit(rod: 1, steps: 1)
        game.commit(rod: 1, steps: -1)
        XCTAssertEqual(game.moves, 1)
        game.commit(rod: 0, steps: -2)
        XCTAssertEqual(game.history, [Twist(rod: 0, steps: 2), Twist(rod: 0, steps: -2)])
    }

    /// An undo takes back a whole stir, gives its move back and costs the clean; the stir before stays shut, and an
    /// empty bank refuses.
    @MainActor func testUndoSpendsTheBank() {
        Best.undos = 2
        let scramble = [Twist(rod: 0, steps: 4)]
        let atPar = Game(level: Level(id: "test-undo", label: "", title: "", layout: .tri, scramble: scramble))
        atPar.commit(rod: 1, steps: 1)
        atPar.commit(rod: 1, steps: 2)
        atPar.undo()
        XCTAssertEqual(atPar.moves, 0)
        atPar.commit(rod: 0, steps: -4)
        XCTAssertTrue(atPar.solved)
        XCTAssertEqual(atPar.over, 0)
        XCTAssertFalse(atPar.clean)

        let game = Game(level: Level(id: "test-undo-2", label: "", title: "", layout: .tri, scramble: scramble))
        game.commit(rod: 0, steps: 2)
        game.commit(rod: 2, steps: 1)
        game.undo()
        game.commit(rod: 0, steps: -2)
        XCTAssertEqual(game.history, [Twist(rod: 0, steps: 2), Twist(rod: 0, steps: -2)])
        XCTAssertEqual(Best.undos, 0)
        game.undo()
        XCTAssertEqual(game.moves, 2)
    }

    /// Unstirred back to the clean picture it opened on, the sandbox plays on; new rods clear the stir. Its undos are free.
    @MainActor func testSandboxNeverFinishes() {
        Best.undos = 0
        let game = Game(level: .sandbox)
        game.commit(rod: 1, steps: 1)
        game.undo()
        XCTAssertEqual(game.moves, 0)
        XCTAssertEqual(Best.undos, 0)
        game.commit(rod: 0, steps: 3)
        game.commit(rod: 0, steps: -3)
        game.commit(rod: 2, steps: 1)
        XCTAssertEqual(game.stack, [Twist(rod: 2, steps: 1)])
        game.nextLayout()
        XCTAssertEqual(game.stack, [])
    }

    /// An endless pent tank the player saw smudged where rods 1 and 2 overlap: 32 px at most, about 40 px across.
    func testVisibleSmudgeIsNotSolved() {
        let stack = [Twist].parse("2:-2,4:-3,3:-5,1:-4,4:+6,2:+2,1:+2,0:-7,4:-6,2:-2,3:+5,4:+6,0:+7,4:-3,2:+2,1:-2,2:-2,1:+4,2:+2",
                                  in: .pent)
        XCTAssertFalse(Layout.pent.looksSolved(stack))
        XCTAssertFalse(Layout.pent.same(stack, [], at: Tank.grid(Tank.pixelGrid), within: Tank.halfPixel), "the 2 px grid alone")
    }

    func testSameRodAnglesAdd() {
        for _ in 0..<1000 {
            let p = SIMD2(Double.random(in: -1...1), Double.random(in: -1...1))
            let rod = Layout.allCases.randomElement()!.rods.randomElement()!
            let a = Double.random(in: -6...6), b = Double.random(in: -6...6)
            let twice = Tank.twist(Tank.twist(p, rod: rod, angle: a), rod: rod, angle: b)
            XCTAssertLessThan(simd_distance(twice, Tank.twist(p, rod: rod, angle: a + b)), 1e-9)
        }
    }

    func testForwardThenInverseReturnsPoint() {
        for _ in 0..<1000 {
            let p = SIMD2(Double.random(in: -1...1), Double.random(in: -1...1))
            let rods = Layout.allCases.randomElement()!.rods
            let word = (0..<6).map { _ in (rods.randomElement()!, Double.random(in: -9...9) * Tank.step) }
            var q = p
            for (rod, a) in word { q = Tank.twist(q, rod: rod, angle: a) }
            for (rod, a) in word.reversed() { q = Tank.twist(q, rod: rod, angle: -a) }
            XCTAssertLessThan(simd_distance(q, p), 1e-9)
        }
    }

    func testLayoutGeometry() {
        let overlapping: [Layout: Int] = [.tri: 3, .quad: 4, .eye: 5, .pent: 5, .hex: 12]
        for layout in Layout.allCases {
            let rods = layout.rods
            var pairs = 0, reached: Set = [0], todo = [0]
            for (i, a) in rods.enumerated() {
                XCTAssertLessThanOrEqual(simd_length(SIMD2(a.x, a.y)) + a.z, 1 + 1e-9, "\(layout) rod \(i) leaves the tank")
                for (j, b) in rods.enumerated() where j > i {
                    let gap = simd_distance(SIMD2(a.x, a.y), SIMD2(b.x, b.y)) - Tank.plateau * (a.z + b.z)
                    XCTAssertGreaterThan(gap, 0, "\(layout) cores \(i) and \(j) touch")
                    if layout.overlaps(i, j) { pairs += 1 }
                }
            }
            while let i = todo.popLast() {
                for j in rods.indices where layout.overlaps(i, j) && reached.insert(j).inserted { todo.append(j) }
            }
            XCTAssertEqual(pairs, overlapping[layout], "\(layout)")
            XCTAssertEqual(reached.count, rods.count, "\(layout) overlap graph is not connected")
        }
    }

    /// Any undo-able twist, taken in any order, cancels; and the picture comes back exactly.
    func testUndoInAnyLegalOrder() {
        for layout in Layout.allCases {
            for seed in 0..<100 as Range<UInt64> {
                var rng = SplitMix64(state: seed)
                let word = layout.scramble(depth: 8, inversions: 2, rng: &rng)
                XCTAssertEqual(word.count, 8)
                let points = (0..<20).map { _ in SIMD2(Double.random(in: -1...1), Double.random(in: -1...1)) }
                var q = points.map { p in word.reduce(p) { Tank.twist($0, rod: layout.rods[$1.rod], angle: Double($1.steps) * Tank.step) } }
                var stack = word
                while let i = layout.removable(stack).randomElement() {
                    let t = stack[i]
                    XCTAssertEqual(stack.commit(rod: t.rod, steps: -t.steps, in: layout), .cancelled)
                    q = q.map { Tank.twist($0, rod: layout.rods[t.rod], angle: -Double(t.steps) * Tank.step) }
                }
                XCTAssertTrue(stack.isEmpty)
                for (a, b) in zip(q, points) { XCTAssertLessThan(simd_distance(a, b), 1e-9, "\(layout) seed \(seed)") }
            }
        }
    }

    func testLevelsNeverMerge() {
        let par = [1, 1, 2, 2, 3, 3, 4, 3, 2, 4, 5, 6, 7, 4, 5, 3, 7, 8, 6, 7, 8, 9, 7, 8, 10, 12, 14]
        XCTAssertEqual(Level.all.map(\.scramble.count), par)
        XCTAssertEqual(Level.all.filter(\.replay).count, 3)
    }

    /// Against the design table's inversion column.
    func testInversions() {
        XCTAssertEqual(Level.all.map { $0.layout.inversions($0.scramble) },
                       [0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1, 2, 0, 1, 1, 2, 2, 0, 1, 2, 3, 0, 1, 2, 3, 4])
    }

    /// Twice each level's par, strictly more inversions (against the nightmare design table), and room to stir on top.
    func testNightmare() {
        let nightmare = Level.nightmare
        XCTAssertEqual(nightmare.map(\.layout), Level.all.map(\.layout))
        XCTAssertEqual(nightmare.map(\.scramble.count), Level.all.map { 2 * $0.scramble.count })
        let inversions = nightmare.map { $0.layout.inversions($0.scramble) }
        XCTAssertEqual(inversions, [1, 1, 2, 2, 3, 3, 4, 4, 2, 3, 4, 5, 6, 3, 4, 3, 6, 7, 4, 5, 6, 8, 5, 6, 8, 10, 12])
        for (n, level) in zip(inversions, Level.all) { XCTAssertGreaterThan(n, level.layout.inversions(level.scramble), level.id) }
        XCTAssertFalse(nightmare.contains(where: \.replay))
        XCTAssertGreaterThanOrEqual(Tank.maxStack - nightmare.map(\.scramble.count).max()!, 8)
    }

    /// Nightmare's scrambles under ids of their own: a nightmare best or start must never open a Nightmare+ level or spend
    /// its first try.
    func testNightmarePlusKeepsItsOwnProgress() {
        XCTAssertEqual(Level.nightmarePlus.map(\.scramble), Level.nightmare.map(\.scramble))
        XCTAssertTrue(Set(Level.nightmarePlus.map(\.id)).isDisjoint(with: (Level.all + Level.nightmare).map(\.id)))
        XCTAssertTrue((Level.nightmare + Level.nightmarePlus).allSatisfy { $0.nightmare && $0.picture.isLive })
        XCTAssertTrue(Level.nightmarePlus.allSatisfy(\.plus))
        XCTAssertFalse((Level.all + Level.nightmare).contains(where: \.plus))
    }

    /// Against the design table. Coral reads only to 6 stirs and neurons to 14; each Nightmare+ level shows the twin of
    /// its Nightmare level's picture. The sandbox cycles every picture but the twins.
    func testNightmarePictures() {
        XCTAssertEqual(Array(sequence(first: Picture.grid, next: \.next).prefix(9)),
                       [.grid, .sunset, .city, .glass, .chainmail, .coral, .neurons, .marbling, .grid])
        let table: [(Picture, [Int])] = [(.glass, [1, 9, 14, 19, 23, 26, 27]), (.chainmail, [3, 10, 13, 18, 21, 24]),
                                         (.coral, [2, 5, 8, 16]), (.neurons, [4, 7, 11, 17, 20]), (.marbling, [6, 12, 15, 22, 25])]
        var want = [Picture?](repeating: nil, count: 27)
        for (picture, levels) in table { for n in levels { want[n - 1] = picture } }
        XCTAssertEqual(Level.nightmare.map(\.picture), want)
        XCTAssertLessThanOrEqual(Level.nightmare.filter { $0.picture == .coral }.map(\.scramble.count).max()!, 6)
        XCTAssertLessThanOrEqual(Level.nightmare.filter { $0.picture == .neurons }.map(\.scramble.count).max()!, 14)
        XCTAssertEqual(Level.nightmarePlus.map(\.picture), Level.nightmare.map(\.picture.twin))
        let twins = Set(table.map(\.0.twin))
        XCTAssertEqual(twins.count, 5)
        XCTAssertTrue(twins.isDisjoint(with: table.map(\.0)))
    }

    /// A live picture's shader gets the clock mod its period, so its data must repeat with it. Not the glass's: its seeds
    /// wander on 7-13 s circles, so it takes the raw clock. A twin's data is its sibling's, then its heartbeat's delays,
    /// all repeating with the twin's minute; the glass's and the static web's twins can only check their delays.
    func testLiveDataRepeats() {
        typealias Builder = (Int, Double) -> [Float]
        let builders: [(Picture, Builder)] = [(.chainmail, Picture.links), (.coral, Picture.kernels), (.marbling, Picture.drops)]
        let delays: Builder = { Picture.delays(t: $1) }
        let twins: [(Picture, Builder)] = builders.map { picture, data in (picture.twin, { data($0, $1) + delays($0, $1) }) }
            + [(.glassPlus, delays), (.neuronsPlus, delays)]
        for (picture, data) in builders + twins {
            for seed in [0, 12, 27] {
                for t in [0.0, 1.7, 0.5 * picture.period, picture.period - 0.01] {
                    let a = data(seed, t), b = data(seed, t + picture.period)
                    XCTAssertEqual(a.count, b.count)
                    XCTAssertLessThan(zip(a, b).map { abs($0 - $1) }.max()!, 1e-5, "\(picture) seed \(seed) t \(t)")
                }
            }
        }
    }

    /// The neural web's shader draws only p's nearest node (by its own search) and that node's dendrites, so every line,
    /// glow, knob and soma must lie where that search finds its node. Checked against a brute force over every node in a
    /// 5 x 5 window, on each seed that shows the web (the sandbox's and its levels'), for the web and its twin, whose
    /// lines are checked inflamed and at the heartbeat's peak.
    func testNeuronsStayInTheirRegions() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw XCTSkip("no Metal device") }
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Neurons.metal")
        let source = try String(contentsOf: url, encoding: .utf8)
            .replacingOccurrences(of: "#include <SwiftUI/SwiftUI_Metal.h>", with: "")
            .replacingOccurrences(of: "[[ stitchable ]]", with: "") + """

            // x the line, y the glow, z the soma's reach at p: as the shader draws them, or over every node near p.
            static float3 probe(float2 p, float ipx, device const packed_float3 *cells, bool brute, bool plus) {
                const float wide = 0.1, high = 0.0866025, left = -1.2, top = -1.1258;
                const int n = 24, rows = 26;
                // A soma and its glow end within 0.0225 of its node (0.0262 in the twin), a knob within 0.0055 (0.0065 in
                // the twin, swollen by the beat).
                float hot = plus ? 1.0 : 0.0, grow = plus ? throb(1.0).x : 1.0;
                float rs = plus ? 0.0262 : 0.0225, rk = plus ? 0.0065 * grow : 0.0055, soma = 0;
                float2 ink = 0;
                if (!brute) {
                    float2 a;
                    float f, da, db;
                    int2 at = nearest(p, cells, a, f, da, db);
                    uint flags = uint(f);
                    float d = sqrt(da);
                    if (flags & 64u) soma = d < rs ? 1.0 - d / rs : 0.0;
                    else if (flags & 128u) ink = float2(saturate((rk - d) * ipx + 0.5), glow(d));
                    dendrites(p, cells, at, a, flags, hot, grow, plus, ipx, ink);
                    return float3(ink, soma);
                }
                int jc = int(floor((p.y - top) / high));
                for (int j = max(jc - 2, 0); j <= min(jc + 2, rows - 1); j++) {
                    int ic = int(floor((p.x - left) / wide - 0.5 * float(j & 1)));
                    for (int i = max(ic - 2, 0); i <= min(ic + 2, n - 1); i++) {
                        float3 cell = float3(cells[j * n + i]);
                        uint flags = uint(cell.z);
                        float d = distance(p, cell.xy);
                        if (flags & 64u) soma = max(soma, d < rs ? 1.0 - d / rs : 0.0);
                        else if (flags & 128u) ink = float2(max(ink.x, saturate((rk - d) * ipx + 0.5)), ink.y + glow(d));
                        int odd = j & 1;
                        const int2 step[3] = {int2(1, 0), int2(odd, 1), int2(odd - 1, 1)};
                        for (int dir = 0; dir < 3; dir++) {
                            if ((flags & (1u << dir)) == 0u) continue;
                            float2 b = float3(cells[(j + step[dir].y) * n + i + step[dir].x]).xy;
                            edge(p, cell.xy, b, (flags >> (8u + 5u * uint(dir))) & 31u, hot, grow, plus, ipx, ink);
                        }
                    }
                }
                return float3(ink, soma);
            }

            // Counts the pixels whose line, glow or soma differ.
            kernel void scan(device const float *data [[buffer(0)]], device atomic_uint *bad [[buffer(1)]],
                             constant float &side [[buffer(2)]], constant uint &plus [[buffer(3)]],
                             uint2 gid [[thread_position_in_grid]]) {
                float2 p = (float2(gid) + 0.5) / side * 2.0 - 1.0;
                if (length_squared(p) > 1.0) return;
                device const packed_float3 *cells = (device const packed_float3 *)data;
                float3 s = probe(p, side / 2.0, cells, false, plus != 0u), b = probe(p, side / 2.0, cells, true, plus != 0u);
                if (abs(s.x - b.x) > 0.05) atomic_fetch_add_explicit(&bad[0], 1u, memory_order_relaxed);
                if (abs(s.y - b.y) > 0.01) atomic_fetch_add_explicit(&bad[1], 1u, memory_order_relaxed);
                if (abs(s.z - b.z) > 0.01) atomic_fetch_add_explicit(&bad[2], 1u, memory_order_relaxed);
            }
            """
        let library = try device.makeLibrary(source: source, options: nil)
        let scan = try device.makeComputePipelineState(function: try XCTUnwrap(library.makeFunction(name: "scan")))
        let queue = try XCTUnwrap(device.makeCommandQueue())
        var side = Float(2400)
        let seeds = [0, 4, 7, 11, 17, 20], webs = OSAllocatedUnfairLock(initialState: [Int: [Float]]())
        // A debug build takes most of a second over each web, so they build side by side.
        DispatchQueue.concurrentPerform(iterations: seeds.count) { k in
            let web = Picture.nodes(seed: seeds[k])
            webs.withLock { $0[seeds[k]] = web }
        }
        for seed in seeds {
            let data = webs.withLock { $0[seed]! }
            let cells = try XCTUnwrap(device.makeBuffer(bytes: data, length: 4 * data.count))
            for var plus: UInt32 in [0, 1] {
                let bad = try XCTUnwrap(device.makeBuffer(length: 12))
                memset(bad.contents(), 0, 12)
                let cb = try XCTUnwrap(queue.makeCommandBuffer()), enc = try XCTUnwrap(cb.makeComputeCommandEncoder())
                enc.setComputePipelineState(scan)
                enc.setBuffer(cells, offset: 0, index: 0)
                enc.setBuffer(bad, offset: 0, index: 1)
                enc.setBytes(&side, length: 4, index: 2)
                enc.setBytes(&plus, length: 4, index: 3)
                enc.dispatchThreads(MTLSize(width: Int(side), height: Int(side), depth: 1),
                                    threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
                enc.endEncoding()
                cb.commit()
                cb.waitUntilCompleted()
                XCTAssertNil(cb.error)
                let n = bad.contents().bindMemory(to: UInt32.self, capacity: 3)
                XCTAssertEqual([n[0], n[1], n[2]], [0, 0, 0], "line, glow and soma pixels off, seed \(seed)\(plus == 1 ? " twin" : "")")
            }
        }
    }

    /// From the prototype, so the Swift generator draws exactly as it does.
    func testDailyAndEndlessVectors() {
        let daily: [(Int, Layout, String)] = [
            (1001, .eye, "0:-4,3:-5,0:-4,2:-5,0:-3,3:-2,1:+5,2:-8,3:+2,0:+7,1:-8,3:+8,2:+4"),
            (1002, .pent, "4:-2,0:+5,1:+4,3:-4,2:+6,1:-8,4:-3,3:+5,4:-7,3:+8,2:-3,1:-3,2:-4,3:-5"),
            (1225, .quad, "2:+3,3:-6,2:-8,0:-3,1:-3,0:+5,1:-3,3:+4,0:+7,2:-4,1:+8,2:-4,0:+2,3:+6"),
        ]
        for (md, layout, word) in daily {
            let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: md / 100, day: md % 100, hour: 12))!
            let level = Level.daily(date)
            XCTAssertEqual(level.layout, layout)
            XCTAssertEqual(level.scramble, [Twist].parse(word, in: layout))
        }
        let endless: [(Int, Layout, String)] = [
            (0, .quad, "0:-4,3:+7,1:+4,2:+8"),
            (3, .hex, "1:+4,5:+2,6:+4,2:+2,1:+6,6:+8,2:-4"),
            (9, .eye, "0:+4,2:+2,1:-2,2:+4,0:+7,3:-3,2:-4,0:+6,3:+7,2:-2,1:+8,3:-4,0:+7"),
        ]
        for (tank, layout, word) in endless {
            let level = Level.endless(Run(seed: 7, tank: tank))
            XCTAssertEqual(level.layout, layout)
            XCTAssertEqual(level.scramble, [Twist].parse(word, in: layout))
        }
    }

    /// The grid's node colours against the prototype's oklch (colour.py): its top and bottom rows, x = -1 ... 1.
    @MainActor func testGridColoursMatchPrototype() {
        let rows: [(Double, [UInt32])] = [
            (-1, [0x00BDB6, 0x00BAC7, 0x00B4ED, 0x65A6FF, 0x9996FF, 0xCA7BFF, 0xFF51DD, 0xFF6999, 0xFF735F, 0xF48200, 0xE19000]),
            (1, [0x007974, 0x007780, 0x007399, 0x0064CE, 0x6429FF, 0x9600D5, 0xB20098, 0xC0005C, 0xC50D00, 0x9E5200, 0x915B00]),
        ]
        for (y, hexes) in rows {
            for (k, hex) in hexes.enumerated() {
                let c = Picture.field(Double(k) * 0.2 - 1, y).resolve(in: EnvironmentValues())
                for (got, want) in zip([c.red, c.green, c.blue], [hex >> 16, hex >> 8, hex].map { Float($0 & 0xFF) }) {
                    XCTAssertEqual(got * 255, want, accuracy: 2, "node \(k) at y \(y)")
                }
            }
        }
    }
}
