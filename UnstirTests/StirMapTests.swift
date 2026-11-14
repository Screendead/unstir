// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import simd
import SwiftUI
import XCTest
@testable import Unstir

/// The stored map (`StirMap`, and `storeTaps`, `stored`, `between` in Unstir.metal).
final class StirMapTests: XCTestCase {
    private static let kernels = """
        struct MapTestArgs { float radius, scale, rest, plateau, swirlPlateau, lensEdge, quant, bend; int kept, side; };
        kernel void store(texture2d<float, access::write> map [[texture(0)]], device const float *twists [[buffer(0)]],
                          constant MapTestArgs &a [[buffer(1)]], uint2 gid [[thread_position_in_grid]]) {
            storeTaps(map, gid, float2(a.radius), a.radius, twists, a.kept, a.plateau, a.swirlPlateau, a.lensEdge, a.scale,
                      a.rest, a.quant);
        }
        // Each tap's stored point beside the chain's, in device pixels.
        kernel void own(texture2d<half> map [[texture(0)]], device const float *twists [[buffer(0)]],
                        constant MapTestArgs &a [[buffer(1)]], device float2 *out [[buffer(2)]],
                        uint2 gid [[thread_position_in_grid]]) {
            Taps t = tapsThrough((float2(gid) + 0.5) / a.scale, float2(a.radius), a.radius, twists, a.kept, 1, a.plateau,
                                 a.swirlPlateau, a.lensEdge, a.scale, a.rest);
            int i = 8 * (gid.y * a.side + gid.x);
            out[i] = stored(map, 2 * int2(gid), a.quant);
            out[i + 1] = stored(map, 2 * int2(gid) + int2(1, 0), a.quant);
            out[i + 2] = stored(map, 2 * int2(gid) + int2(0, 1), a.quant);
            out[i + 3] = stored(map, 2 * int2(gid) + int2(1, 1), a.quant);
            out[i + 4] = (a.radius + t.q0 * a.radius) * a.scale;
            out[i + 5] = (a.radius + t.q1 * a.radius) * a.scale;
            out[i + 6] = (a.radius + t.q2 * a.radius) * a.scale;
            out[i + 7] = (a.radius + t.q3 * a.radius) * a.scale;
        }
        kernel void read(texture2d<half> map [[texture(0)]], device const float2 *points [[buffer(0)]],
                         constant MapTestArgs &a [[buffer(1)]], device float2 *out [[buffer(2)]],
                         uint i [[thread_position_in_grid]]) {
            out[i] = between(map, points[i], float2(a.radius), a.radius, a.scale, cos(a.rest), sin(a.rest), a.quant, a.bend);
        }
        """

    private struct Args {
        var radius, scale, rest, plateau, swirlPlateau, lensEdge, quant, bend: Float
        var kept, side: Int32
    }

    private func texture(_ kit: ShaderKit, _ n: Int) throws -> MTLTexture {
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: n, height: n, mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite]
        return try XCTUnwrap(kit.device.makeTexture(descriptor: desc))
    }

    /// A map's texel is its tap's point through the chain, to the stored step, turned glass and swirl too: what a
    /// rest frame reads in place of running the chain.
    func testAMapStoresEachTapsPointThroughTheChain() throws {
        let kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: Self.kernels)
        let layout = Layout.hexSwirl
        var rng = SplitMix64(state: 62)
        // Shallow and gentle, as `testTheShadersTapsMatchTheModel` is: two kernels need not round a deep chain alike.
        let stack = (0..<6).map { _ in Twist(rod: rng.below(layout.rods.count), steps: [-2, -1, 1, 2][rng.below(4)]) }
        let twists = Unstirred.entries(stack.map { ($0.rod, Double($0.steps) * Tank.step) }, layout: layout, lenses: [], masks: [:]).twists
        let side = 64, quant = StirMap.quant(pixels: side)
        var args = Args(radius: 16, scale: 2, rest: 0.4, plateau: Float(Tank.plateau), swirlPlateau: Float(Tank.swirlPlateau),
                        lensEdge: Float(Tank.lensEdge), quant: quant, bend: 16, kept: Int32(stack.count), side: Int32(side))
        let map = try texture(kit, 2 * side), grid = MTLSize(width: side, height: side, depth: 1), group = MTLSize(width: 8, height: 8, depth: 1)
        let entries = try kit.buffer(twists), out = try kit.buffer(SIMD2<Float>.self, count: 8 * side * side)
        try kit.run(try kit.pipeline("store"), grid: grid, group: group) { enc in
            enc.setTexture(map, index: 0)
            enc.setBuffer(entries, offset: 0, index: 0)
            enc.setBytes(&args, length: MemoryLayout<Args>.stride, index: 1)
        }
        try kit.run(try kit.pipeline("own"), grid: grid, group: group) { enc in
            enc.setTexture(map, index: 0)
            enc.setBuffer(entries, offset: 0, index: 0)
            enc.setBytes(&args, length: MemoryLayout<Args>.stride, index: 1)
            enc.setBuffer(out, offset: 0, index: 2)
        }
        let got = kit.read(out, as: SIMD2<Float>.self)
        var moved = 0
        for pixel in 0..<(side * side) {
            for j in 0..<4 {
                let held = got[8 * pixel + j], chain = got[8 * pixel + 4 + j]
                let x = Float(pixel % side) + 0.5 + (Float(j & 1) - 0.5) * 0.5, y = Float(pixel / side) + 0.5 + (Float(j >> 1) - 0.5) * 0.5
                // The turn carries a corner's taps off the square the map holds; no frame reads them (`pastTheGlass`).
                guard simd_distance(SIMD2(x, y), SIMD2(32, 32)) <= 32 else { continue }
                XCTAssertLessThan(simd_distance(held, chain), 0.75 / quant + 1e-3, "tap \(j) of pixel \(pixel)")
                if simd_distance(chain, SIMD2(x, y)) > 1 { moved += 1 }
            }
        }
        XCTAssertGreaterThan(moved, side * side)
    }

    /// A point between texels reads the map between them where it runs straight, and where it folds takes the
    /// nearest texel's point whole; a point past the glass is its own.
    func testAPointBetweenTexelsReadsAStraightMapAndTakesAFoldWhole() throws {
        let kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: Self.kernels)
        let side = 32, n = 2 * side, quant = StirMap.quant(pixels: side)
        var args = Args(radius: 8, scale: 2, rest: 0, plateau: 0, swirlPlateau: 0, lensEdge: 0, quant: quant, bend: 16, kept: 0, side: Int32(side))
        func bytes(_ point: (Int, Int) -> SIMD2<Float>) -> [UInt8] {
            var b = [UInt8](repeating: 0, count: 4 * n * n)
            for y in 0..<n {
                for x in 0..<n {
                    let p = point(x, y), vx = Int((p.x * quant).rounded()), vy = Int((p.y * quant).rounded()), i = 4 * (y * n + x)
                    // BGRA: red and green hold x, blue and alpha y.
                    (b[i + 2], b[i + 1], b[i], b[i + 3]) = (UInt8(vx & 255), UInt8(vx >> 8), UInt8(vy & 255), UInt8(vy >> 8))
                }
            }
            return b
        }
        // In tank units: two points inside the glass, off the texels' grid, and one past its edge.
        let points: [SIMD2<Float>] = [SIMD2(0.11, -0.23), SIMD2(-0.4, 0.31), SIMD2(0.9, 0.9)]
        func read(_ map: [UInt8]) throws -> [SIMD2<Float>] {
            let t = try texture(kit, n), out = try kit.buffer(SIMD2<Float>.self, count: points.count)
            t.replace(region: MTLRegionMake2D(0, 0, n, n), mipmapLevel: 0, withBytes: map, bytesPerRow: 4 * n)
            try kit.run("read", count: points.count) { enc in
                enc.setTexture(t, index: 0)
                enc.setBuffer(try! kit.buffer(points), offset: 0, index: 0)
                enc.setBytes(&args, length: MemoryLayout<Args>.stride, index: 1)
                enc.setBuffer(out, offset: 0, index: 2)
            }
            return kit.read(out, as: SIMD2<Float>.self)
        }
        func screen(_ p: SIMD2<Float>) -> SIMD2<Float> { (SIMD2(8, 8) + p * 8) * 2 }
        // The identity's map: every point reads as itself.
        let straight = try read(bytes { x, y in SIMD2((Float(x) + 0.5) / 2, (Float(y) + 0.5) / 2) })
        for (p, got) in zip(points, straight) { XCTAssertLessThan(simd_distance(got, screen(p)), 1 / quant + 1e-4) }
        // A map whose neighbours lie the glass apart: the nearest texel's point, never one between two.
        let far: (Int, Int) -> SIMD2<Float> = { x, y in SIMD2((x + y) % 2 == 0 ? 2 : 30, Float(y % 2 == 0 ? 3 : 29)) }
        let folded = try read(bytes(far))
        for (p, got) in zip(points.prefix(2), folded.prefix(2)) {
            let u = screen(p) * 2 - 0.5
            XCTAssertLessThan(simd_distance(got, far(Int(u.x.rounded()), Int(u.y.rounded()))), 1e-4)
        }
        XCTAssertLessThan(simd_distance(folded[2], screen(points[2])), 1e-4)
    }

    private func made(_ key: StirMap.Key) -> StirMap.Made {
        StirMap.Made(key: key, image: Image(systemName: "circle"), quant: StirMap.quant(pixels: key.pixels), id: 1)
    }

    /// A glass draws from a map only where the map holds a run of the frame's bottom entries, at its size: with a
    /// twist pushed since, a rod in hand or the glass turned, and never once an entry it holds is popped or merged.
    @MainActor func testAGlassDrawsFromAMapOnlyOfItsOwnStack() throws {
        try XCTSkipIf(StirMap.mode == nil)
        let stack = (0..<12).map { Twist(rod: $0 % 3, steps: $0 % 2 == 0 ? 2 : -3) }
        var glass = Unstirred(stack: stack, layout: .tri, liveAngle: 0, side: 100, turn: 0.5)
        let key = try XCTUnwrap(StirMap.key(glass, scale: 3))
        XCTAssertEqual(key.twists, glass.shader(scale: 3).twists)
        XCTAssertEqual(key.rest, 0.5)
        XCTAssertNil(glass.shader(scale: 3).mapped)
        glass.map = made(key)
        let rest = glass.shader(scale: 3)
        XCTAssertEqual(rest.name, "unstirMapped")
        XCTAssertEqual(rest.mapped?.kept, 12)
        var moved = glass
        moved.stack.append(Twist(rod: 1, steps: 4))
        (moved.liveRod, moved.liveAngle, moved.turn) = (2, 0.3, 0.9)
        XCTAssertEqual(moved.shader(scale: 3).mapped?.kept, 12)
        XCTAssertEqual(moved.shader(scale: 3).mapped?.rest, 0.5)
        XCTAssertEqual(moved.shader(scale: 3).twists.count, 56)
        let others: [(inout Unstirred) -> Void] = [
            { $0.stack.removeLast() }, { $0.stack[11].steps = 4 }, { $0.stack[0].steps = 1 }, { $0.wind = 0.5 }, { $0.side = 120 },
        ]
        for (i, change) in others.enumerated() {
            var other = glass
            change(&other)
            XCTAssertNil(other.shader(scale: 3).mapped, "change \(i)")
            XCTAssertEqual(other.shader(scale: 3).name, "unstir")
        }
        XCTAssertNil(glass.shader(scale: 2).mapped)
    }

    /// A frame drawn from the map draws four taps at any depth, past the budget too, with a rod in hand riding over it;
    /// a frame through the chain, the map's stack popped or merged since, keeps the budget's rule (Jack, 2026-11-13).
    @MainActor func testAFrameFromTheMapDrawsFourTapsAtAnyDepth() throws {
        try XCTSkipIf(StirMap.mode == nil)
        let stack = (0..<60).map { Twist(rod: $0 % 3, steps: $0 % 2 == 0 ? 2 : -3) }
        var glass = Unstirred(stack: stack, layout: .tri, liveAngle: 0, side: 100, budget: 40)
        let budget = glass.shader(scale: 3).fourTaps
        XCTAssertEqual(budget, 40)
        XCTAssertGreaterThan(Float(stack.count), budget, "past the budget, the chain draws two taps")
        glass.map = made(try XCTUnwrap(StirMap.key(glass, scale: 3)))
        XCTAssertEqual(glass.shader(scale: 3).fourTaps, TankShader.everyTap)
        var held = glass
        (held.liveRod, held.liveAngle) = (1, 0.4)
        XCTAssertNotNil(held.shader(scale: 3).mapped)
        XCTAssertEqual(held.shader(scale: 3).fourTaps, TankShader.everyTap)
        var popped = glass
        popped.stack.removeLast()
        XCTAssertNil(popped.shader(scale: 3).mapped)
        XCTAssertEqual(popped.shader(scale: 3).fourTaps, budget)
    }

    /// No map is asked for a short stack, one winding in or a cover's shares; a Lens level's holds its lenses' flow
    /// (but under UNSTIR_MAPLENS=0), and Prism's counts its channels' maps for its depth and holds a tile a word.
    @MainActor func testOnlyADeepGlassAsksForAMap() throws {
        try XCTSkipIf(StirMap.mode == nil)
        let stack = (0..<StirMap.least).map { Twist(rod: $0 % 3, steps: 2) }
        let glass = Unstirred(stack: stack, layout: .tri, liveAngle: 0, side: 100)
        XCTAssertEqual(StirMap.key(glass, scale: 3)?.tiles, [7])
        let without: [(inout Unstirred) -> Void] = [
            { $0.stack.removeLast() }, { $0.wind = 0.9 }, { $0.shares = [Double](repeating: 1, count: $0.stack.count) },
        ]
        for (i, change) in without.enumerated() {
            var other = glass
            change(&other)
            XCTAssertNil(StirMap.key(other, scale: 3), "change \(i)")
        }
        // A rod in hand, the breath and a tick ride above the map and are no part of it.
        var held = glass
        (held.liveRod, held.liveAngle, held.breath, held.tick) = (1, 0.7, (0, 0.1), (2, 0.2))
        XCTAssertEqual(StirMap.key(held, scale: 3), StirMap.key(glass, scale: 3))
        // A Lens level asks as any other does, from the same depth (Jack's call, 2026-11-13), its lens's entries as
        // the frame takes them; only the probe turns it off.
        XCTAssertEqual(StirMap.lensMaps, ProcessInfo.processInfo.environment["UNSTIR_MAPLENS"] != "0")
        var lens = glass
        lens.lenses = [0]
        let key = StirMap.key(lens, scale: 3)
        XCTAssertEqual(key == nil, !StirMap.lensMaps)
        if let key { XCTAssertTrue(lens.shader(scale: 3).twists.starts(with: key.twists)) }
        lens.stack.removeLast()
        XCTAssertNil(StirMap.key(lens, scale: 3))
        // Prism: red's word and cyan's (green and blue together), its depth the maps its entries hold.
        var prism = glass
        prism.masks = [0: .red, 1: .cyan]
        // Cyan's two channels an entry.
        prism.stack = (0..<(StirMap.prismLeast + 1) / 2).map { Twist(rod: 1, steps: $0 % 2 == 0 ? 1 : 2) }
        XCTAssertNotNil(StirMap.key(prism, scale: 3))
        prism.stack.removeLast()
        XCTAssertNil(StirMap.key(prism, scale: 3))
        prism.masks = [0: .red, 1: .cyan]
        prism.stack = (0..<4).map { Twist(rod: $0 % 2, steps: 2) }
        XCTAssertNil(StirMap.key(prism, scale: 3, least: 7))
        let tiles = try XCTUnwrap(StirMap.key(prism, scale: 3, least: 6))
        XCTAssertEqual(tiles.tiles, [1, 6])
        XCTAssertEqual(StirMap.slots(tiles.tiles), SIMD3(0, 1, 1))
        XCTAssertEqual(tiles.bytes, 2 * 16 * 300 * 300)
        XCTAssertEqual(StirMap.words(tiles).map { $0.count / 4 }, [2, 2])
        prism.masks[2] = .white
        XCTAssertEqual(StirMap.key(prism, scale: 3, least: 6)?.tiles, [1, 6])
        prism.stack.append(Twist(rod: 2, steps: 1))
        XCTAssertEqual(StirMap.key(prism, scale: 3, least: 6)?.tiles, [1, 6])
        XCTAssertEqual(StirMap.tiles([1, 2, 4, 7]), [1, 2, 4])
        XCTAssertEqual(StirMap.tiles([1, 3]), [1, 2])
        XCTAssertEqual(StirMap.slots(StirMap.tiles([3, 3])), SIMD3(0, 0, -1))
    }

    /// RenderBox draws nothing through a shader given two images (iOS 18.5: "Only one texture argument is allowed"), so
    /// a Lens glass draws its detail over a map only from the map's own image, which holds that very atlas above the
    /// map, and no shader the glass makes is given two.
    @MainActor func testALensGlassDrawsItsDetailOnlyFromTheMapsOwnImage() throws {
        try XCTSkipIf(StirMap.mode == nil)
        let stack = (0..<12).map { Twist(rod: $0 % 3, steps: $0 % 2 == 0 ? 2 : -3) }
        let detail = Halftone.test.detail(64, lenses: [Layout.tri.rods[0]])
        let fine = try XCTUnwrap(Fine(detail)), other = try XCTUnwrap(Fine(detail))
        var glass = Unstirred(stack: stack, layout: .tri, lenses: [0], liveAngle: 0, side: 100, fine: fine, crisp: 1)
        let twists = glass.shader(scale: 3).twists
        let plain = StirMap.Key(twists: twists, rest: 0, side: 100, scale: 3)
        var packed = plain
        packed.atlas = fine.texels
        var stale = plain
        stale.atlas = other.texels
        for (key, name) in [(packed, "unstirLensMapped"), (plain, "unstirLens"), (stale, "unstirLens")] {
            glass.map = made(key)
            let shader = glass.shader(scale: 3)
            XCTAssertEqual(shader.name, name)
            XCTAssertLessThanOrEqual(shader.parameters.filter { ["atlas", "map"].contains($0.name) }.count, 1, name)
        }
        XCTAssertEqual(glass.shader(scale: 3).mapped?.skip ?? 0, 0)
        glass.map = made(packed)
        XCTAssertEqual(glass.shader(scale: 3).mapped?.skip, detail.height + 1)
        // Before the detail is drawn the plain shader draws only a map that starts at its image's top.
        glass.crisp = 0
        XCTAssertEqual(glass.shader(scale: 3).name, "unstir")
        glass.map = made(plain)
        XCTAssertEqual(glass.shader(scale: 3).name, "unstirMapped")
        // The atlas's rows: its own texels in the surface's order, the last column and row drawn on.
        let rows = StirMap.pack(packed), width = packed.width
        XCTAssertEqual(width, max(600, detail.width))
        XCTAssertEqual(rows.count, 4 * width * (detail.height + 1))
        XCTAssertEqual(packed.bytes, 4 * width * (600 + detail.height + 1))
        for (x, y) in [(0, 0), (detail.width - 1, 3), (width - 1, detail.height), (7, detail.height - 1)] {
            let from = 4 * (min(y, detail.height - 1) * detail.width + min(x, detail.width - 1)), to = 4 * (y * width + x)
            XCTAssertEqual([rows[to + 2], rows[to + 1], rows[to]], Array(detail.pixels[from..<from + 3]), "\(x), \(y)")
        }
    }

    /// The stored step keeps a tap a quarter pixel off its pixel's centre exact, across any glass the game draws.
    func testTheStoredStepHoldsAQuarterPixelAcrossTheGlass() {
        for pixels in [64, 300, 1137, 1284, 1471, 2048] {
            let quant = StirMap.quant(pixels: pixels)
            XCTAssertEqual(quant.truncatingRemainder(dividingBy: 4), 0)
            XCTAssertGreaterThanOrEqual(quant, 4)
            XCTAssertLessThanOrEqual(quant * Float(pixels), 65535)
        }
        XCTAssertEqual(MemoryLayout<StirMap.Args>.stride, 72)
    }

    /// A holder draws the map it is asked for, and lets it go when none is wanted.
    @MainActor func testAHolderDrawsTheMapAskedFor() async throws {
        try XCTSkipIf(StirMap.mode == nil || MTLCreateSystemDefaultDevice() == nil)
        let stack = (0..<12).map { Twist(rod: $0 % 3, steps: 2) }
        let glass = Unstirred(stack: stack, layout: .tri, liveAngle: 0, side: 40)
        let holder = StirMap.Holder(), key = try XCTUnwrap(StirMap.key(glass, scale: 2))
        func settled(_ done: () -> Bool) async {
            for _ in 0..<200 where !done() { try? await Task.sleep(for: .milliseconds(25)) }
        }
        holder.want(glass, scale: 2)
        await settled { holder.made != nil }
        XCTAssertEqual(holder.made?.key, key)
        var short = glass
        short.stack.removeLast(4)
        holder.want(short, scale: 2)
        await settled { holder.made == nil }
        XCTAssertNil(holder.made)
    }
}

/// A Lens and a Prism glass over a stored map (`unstirLensMappedBody`, `unstirChannelsMappedBody` in Unstir.metal),
/// each held against the glass drawn through its chain, as the GPU bench runs both bodies on a texture.
final class StirMapPackTests: XCTestCase {
    private static let kernels = """
        struct PackLayer {
            texture2d<half> picture;
            float pixels;
            half4 sample(float2 p) const {
                constexpr sampler s(filter::linear, address::clamp_to_zero, coord::pixel);
                return picture.sample(s, p * pixels);
            }
        };
        struct PackArgs {
            float radius, scale, n, fourTaps, cost, plateau, swirlPlateau, lensEdge, held, hold, isolate, rest, quant, mode,
                  bend, tileR, tileG, tileB;
            int count, maskCount, fineCount, kind, kept, tile, skip;
        };
        kernel void storeTile(texture2d<float, access::write> map [[texture(0)]], device const float *twists [[buffer(0)]],
                              constant PackArgs &a [[buffer(1)]], uint2 gid [[thread_position_in_grid]]) {
            storeTaps(map, gid, float2(a.radius), a.radius, twists, a.kept, a.plateau, a.swirlPlateau, a.lensEdge, a.scale,
                      a.rest, a.quant, a.tile, a.skip);
        }
        // kind 0: Prism through its chains, 1: over the map; 2: Lens through its chain, 3: over the map.
        kernel void drawPack(texture2d<half> picture [[texture(0)]], texture2d<half, access::write> out [[texture(1)]],
                             texture2d<half> atlas [[texture(2)]], texture2d<half> map [[texture(3)]],
                             device const float *twists [[buffer(0)]], device const float *masks [[buffer(1)]],
                             constant PackArgs &a [[buffer(2)]], device const float *fine [[buffer(3)]],
                             uint2 gid [[thread_position_in_grid]]) {
            PackLayer layer = { picture, a.scale };
            float2 pos = (float2(gid) + 0.5) / a.scale, centre = float2(a.radius);
            float3 tint = float3(1, 1, 1), wave = float3(0, 0, -1);
            float4 mapped = float4(a.kept, a.rest, a.quant, a.mode);
            half4 c = a.kind == 0
                ? unstirChannelsBody(pos, layer, centre, a.radius, twists, a.count, masks, a.maskCount, a.n, a.cost, a.fourTaps,
                                     a.plateau, a.swirlPlateau, a.lensEdge, a.scale, 0.0, wave, a.rest, a.isolate, tint, a.held,
                                     a.hold)
                : a.kind == 1
                ? unstirChannelsMappedBody(pos, layer, centre, a.radius, twists, a.count, masks, a.maskCount, a.n, a.cost,
                                           a.fourTaps, a.plateau, a.swirlPlateau, a.lensEdge, a.scale, 0.0, wave, a.rest,
                                           a.isolate, tint, a.held, a.hold, map, mapped, a.bend,
                                           float3(a.tileR, a.tileG, a.tileB))
                : a.kind == 2
                ? unstirLensBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                                 a.lensEdge, a.scale, 0.0, wave, a.rest, atlas, fine, a.fineCount)
                : a.kind == 3
                ? unstirLensMappedBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau,
                                       a.swirlPlateau, a.lensEdge, a.scale, 0.0, wave, a.rest, fine, a.fineCount, map, mapped,
                                       a.bend, a.skip)
                : unstirBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                             a.lensEdge, a.scale, 0.0, wave, a.rest);
            out.write(c, gid);
        }
        """

    private struct Args {
        var radius, scale, n, fourTaps, cost, plateau, swirlPlateau, lensEdge, held, hold, isolate, rest, quant, mode, bend: Float
        var tileR: Float = 0, tileG: Float = 0, tileB: Float = 0
        var count, maskCount, fineCount: Int32
        var kind: Int32 = 0, kept: Int32 = 0, tile: Int32 = 0, skip: Int32 = 0
    }

    private static let side = 160, scale = 2.0

    private struct Kit {
        let kit: ShaderKit
        let store, draw: MTLComputePipelineState

        init() throws {
            kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: StirMapPackTests.kernels)
            (store, draw) = (try kit.pipeline("storeTile"), try kit.pipeline("drawPack"))
        }

        func texture(_ pixels: [UInt8], _ width: Int, _ height: Int, format: MTLPixelFormat = .rgba8Unorm) throws -> MTLTexture {
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: width, height: height, mipmapped: false)
            desc.usage = [.shaderRead, .shaderWrite]
            let t = try XCTUnwrap(kit.device.makeTexture(descriptor: desc))
            if !pixels.isEmpty {
                t.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: pixels, bytesPerRow: 4 * width)
            }
            return t
        }
    }

    /// Bands of each channel at its own pitch and slant, some 7 pixels a band: fine enough that a tap drawn off its
    /// point shows, smooth enough that the stored step's half a step, a 112th of a pixel, moves a value about a level.
    private func picture(_ kit: Kit) throws -> MTLTexture {
        let n = Self.side
        var bytes = [UInt8](repeating: 255, count: 4 * n * n)
        for y in 0..<n {
            for x in 0..<n {
                for (c, (a, b)) in [(0.9, 0.3), (-0.4, 0.8), (0.5, -0.7)].enumerated() {
                    bytes[4 * (y * n + x) + c] = UInt8(127.5 + 127.5 * sin((a * Double(x) + b * Double(y)) * .pi / 7))
                }
            }
        }
        return try kit.texture(bytes, n, n)
    }

    /// The glass of `glass` (its stack committed, a rod maybe in hand) drawn through its chain (`kind`) and over a map
    /// of its committed stack (`kind + 1`), mapped as `mode` says, and the plain chain's (`unstirBody`) for a Lens glass.
    private func draw(_ kit: Kit, _ glass: Unstirred, mode: StirMap.Mode, fine: Halftone.Detail? = nil) throws -> (chain: [UInt8], mapped: [UInt8], plain: [UInt8]) {
        let n = Self.side, scale = CGFloat(Self.scale)
        // The committed stack's key, as `StirMap.key` makes it, whether or not the game would ask for it.
        let committed = Unstirred.entries(glass.stack.map { ($0.rod, Double($0.steps) * Tank.step) }, layout: glass.layout,
                                          lenses: glass.lenses, masks: glass.masks)
        // A Lens glass's map holds its detail's atlas above it, as the game's one image does (`StirMap.pack`).
        let key = StirMap.Key(twists: committed.twists, masks: Unstirred.channelCost(committed.masks) == nil ? [] : committed.masks,
                              rest: glass.turn, side: glass.side, scale: scale, atlas: fine.map(Fine.Texels.init))
        if glass.lenses.isEmpty { XCTAssertEqual(StirMap.key(glass, scale: scale, least: 1), key) }
        let shader = glass.shader(scale: scale)
        let twists = shader.twists, masks = shader.prism?.masks ?? [Float](repeating: 7, count: twists.count / 4)
        let words = StirMap.words(key)
        let map = try kit.texture([], key.width, 2 * n * words.count + key.skip, format: .bgra8Unorm)
        if key.skip > 0 {
            map.replace(region: MTLRegionMake2D(0, 0, key.width, key.skip), mipmapLevel: 0, withBytes: StirMap.pack(key),
                        bytesPerRow: 4 * key.width)
        }
        let slots = StirMap.slots(key.tiles), table = fine?.table ?? [0]
        var args = Args(radius: Float(glass.side / 2), scale: Float(scale), n: Float(twists.count / 4), fourTaps: shader.fourTaps,
                        cost: Float(shader.prism?.cost ?? 0), plateau: Float(Tank.plateau), swirlPlateau: Float(Tank.swirlPlateau),
                        lensEdge: Float(Tank.lensEdge), held: Float(shader.prism?.held?.rawValue ?? 0), hold: shader.prism?.hold ?? 0,
                        isolate: Float(shader.prism?.isolate?.rawValue ?? 0), rest: Float(key.rest),
                        quant: StirMap.quant(pixels: key.pixels), mode: mode.rawValue, bend: StirMap.bend,
                        tileR: slots.x, tileG: slots.y, tileB: slots.z, count: Int32(twists.count), maskCount: Int32(masks.count),
                        fineCount: fine == nil ? 0 : Int32(table.count), skip: Int32(key.skip))
        for (tile, word) in words.enumerated() {
            var a = args
            (a.kept, a.tile) = (Int32(word.count / 4), Int32(tile))
            let buffer = try kit.kit.buffer(word)
            try kit.kit.run(kit.store, grid: MTLSize(width: n, height: n, depth: 1), group: MTLSize(width: 8, height: 8, depth: 1)) { enc in
                enc.setTexture(map, index: 0)
                enc.setBuffer(buffer, offset: 0, index: 0)
                enc.setBytes(&a, length: MemoryLayout<Args>.stride, index: 1)
            }
        }
        args.kept = Int32(key.twists.count / 4)
        let layer = try picture(kit), out = try kit.texture([], n, n)
        let atlas = try fine.map { try kit.texture($0.pixels, $0.width, $0.height) } ?? kit.texture([0, 0, 0, 255], 1, 1)
        let twistBuffer = try kit.kit.buffer(twists), maskBuffer = try kit.kit.buffer(masks), fineBuffer = try kit.kit.buffer(table)
        func run(_ kind: Int32) throws -> [UInt8] {
            args.kind = kind
            try kit.kit.run(kit.draw, grid: MTLSize(width: n, height: n, depth: 1), group: MTLSize(width: 8, height: 8, depth: 1)) { enc in
                enc.setTexture(layer, index: 0)
                enc.setTexture(out, index: 1)
                enc.setTexture(atlas, index: 2)
                enc.setTexture(map, index: 3)
                enc.setBuffer(twistBuffer, offset: 0, index: 0)
                enc.setBuffer(maskBuffer, offset: 0, index: 1)
                enc.setBytes(&args, length: MemoryLayout<Args>.stride, index: 2)
                enc.setBuffer(fineBuffer, offset: 0, index: 3)
            }
            var pixels = [UInt8](repeating: 0, count: 4 * n * n)
            out.getBytes(&pixels, bytesPerRow: 4 * n, from: MTLRegionMake2D(0, 0, n, n), mipmapLevel: 0)
            return pixels
        }
        let kind: Int32 = fine == nil ? 0 : 2
        return (try run(kind), try run(kind + 1), fine == nil ? [] : try run(4))
    }

    /// The mean and the most two frames' colour values differ by, in levels.
    private func difference(_ a: [UInt8], _ b: [UInt8]) -> (mean: Double, most: Int) {
        var sum = 0, most = 0
        for i in a.indices where i % 4 != 3 {
            let d = abs(Int(a[i]) - Int(b[i]))
            (sum, most) = (sum + d, max(most, d))
        }
        return (Double(sum) / Double(3 * a.count / 4), most)
    }

    /// Prism over its map draws its chains' glass: at rest within the stored step, with a rod held and its read drawn,
    /// and with a swatch held; a channel no entry moves has no tile; and by `chain`, a pixel any held entry moves is the
    /// chains' own to the byte.
    @MainActor func testPrismOverItsMapDrawsItsChainsGlass() throws {
        let kit = try Kit(), layout = Layout.pent
        let masks = try XCTUnwrap(Channels.masks("0:y,1:m,2:r,3:w,4:g"))
        let stack = [Twist].parse("3:-1,2:+2,1:-2,2:-1,0:+1,4:+2,1:+1,0:-2", in: layout, masks: masks)
        let side = CGFloat(Self.side) / CGFloat(Self.scale)
        let glass = Unstirred(stack: stack, layout: layout, masks: masks, liveAngle: 0, side: side)
        XCTAssertEqual(StirMap.key(glass, scale: CGFloat(Self.scale), least: 1)?.tiles, [1, 2, 4])
        let rest = try draw(kit, glass, mode: .mix)
        let still = difference(rest.chain, rest.mapped)
        XCTAssertLessThan(still.mean, 0.2, "at rest")
        XCTAssertLessThanOrEqual(still.most, 6, "at rest")
        var held = glass
        (held.liveRod, held.liveAngle, held.held, held.hold) = (0, -0.9 * Tank.step, masks[0], 1)
        let chain = try draw(kit, held, mode: .chain), mix = try draw(kit, held, mode: .mix)
        XCTAssertTrue(chain.chain == chain.mapped || difference(chain.chain, chain.mapped).most <= 6, "held, by chain")
        XCTAssertLessThan(difference(mix.chain, mix.mapped).mean, 0.5, "held")
        var swatch = glass
        swatch.isolate = .green
        let alone = try draw(kit, swatch, mode: .mix)
        XCTAssertLessThan(difference(alone.chain, alone.mapped).mean, 0.2, "swatch")
        // No entry holds blue: two tiles, and blue drawn through its empty word.
        let blueless = try XCTUnwrap(Channels.masks("0:r,1:g,2:y,3:r,4:g"))
        var other = glass
        (other.masks, other.stack) = (blueless, [Twist].parse("0:+2,1:-1,2:+1,3:-2,4:+1", in: layout, masks: blueless))
        XCTAssertEqual(StirMap.key(other, scale: CGFloat(Self.scale), least: 1).map { StirMap.slots($0.tiles) }, SIMD3(0, 1, -1))
        let two = try draw(kit, other, mode: .mix)
        XCTAssertLessThan(difference(two.chain, two.mapped).mean, 0.2, "blueless")
    }

    /// Lens over its map draws the chain's glass, and wherever the detail is drawn draws it to the byte: at rest, with
    /// a twist and with the lens in hand past x8.
    @MainActor func testLensOverItsMapDrawsTheDetailAsTheChainDoes() throws {
        let kit = try Kit(), layout = Layout.tri, lenses: Set<Int> = [0]
        let stack = [Twist].parse("1:+3,0:+3,2:-2,1:+1", in: layout, lenses: lenses)
        let side = CGFloat(Self.side) / CGFloat(Self.scale)
        let detail = Halftone.test.detail(Self.side, lenses: [layout.rods[0]])
        let glass = Unstirred(stack: stack, layout: layout, lenses: lenses, liveAngle: 0, side: side)
        var twisted = glass, zoomed = glass
        (twisted.liveRod, twisted.liveAngle) = (2, 1.4 * Tank.step)
        (zoomed.liveRod, zoomed.liveAngle) = (0, 0.9 * Tank.step)
        for (name, g) in [("rest", glass), ("twisted", twisted), ("zoomed", zoomed)] {
            for mode in [StirMap.Mode.chain, .mix] {
                let frames = try draw(kit, g, mode: mode, fine: detail)
                var detailed = 0, missed = 0
                for i in stride(from: 0, to: frames.chain.count, by: 4) {
                    let shown = (0..<3).contains { abs(Int(frames.chain[i + $0]) - Int(frames.plain[i + $0])) > 8 }
                    guard shown else { continue }
                    detailed += 1
                    if frames.chain[i..<i + 3] != frames.mapped[i..<i + 3] { missed += 1 }
                }
                XCTAssertGreaterThan(detailed, 100, name)
                XCTAssertEqual(missed, 0, "\(name), \(mode): of \(detailed) pixels showing the detail")
                XCTAssertLessThan(difference(frames.chain, frames.mapped).mean, mode == .chain || name == "rest" ? 0.2 : 0.5, "\(name), \(mode)")
            }
        }
    }
}
