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

    /// No map is asked for a short stack, one winding in, a cover's shares, a Lens level or Prism's channels.
    @MainActor func testOnlyADeepPlainGlassAsksForAMap() throws {
        try XCTSkipIf(StirMap.mode == nil)
        let stack = (0..<StirMap.least).map { Twist(rod: $0 % 3, steps: 2) }
        let glass = Unstirred(stack: stack, layout: .tri, liveAngle: 0, side: 100)
        XCTAssertNotNil(StirMap.key(glass, scale: 3))
        let without: [(inout Unstirred) -> Void] = [
            { $0.stack.removeLast() }, { $0.wind = 0.9 }, { $0.shares = [Double](repeating: 1, count: $0.stack.count) },
            { $0.lenses = [0] }, { $0.masks = [0: .red] },
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
    }

    /// The stored step keeps a tap a quarter pixel off its pixel's centre exact, across any glass the game draws.
    func testTheStoredStepHoldsAQuarterPixelAcrossTheGlass() {
        for pixels in [64, 300, 1137, 1284, 1471, 2048] {
            let quant = StirMap.quant(pixels: pixels)
            XCTAssertEqual(quant.truncatingRemainder(dividingBy: 4), 0)
            XCTAssertGreaterThanOrEqual(quant, 4)
            XCTAssertLessThanOrEqual(quant * Float(pixels), 65535)
        }
        XCTAssertEqual(MemoryLayout<StirMap.Args>.stride, 52)
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
