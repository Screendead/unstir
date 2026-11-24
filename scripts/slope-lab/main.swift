// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreGraphics
import Foundation
import ImageIO
import Metal
import UniformTypeIdentifiers

// Draws the slope's ground on the Mac's GPU from Sources/Slope.metal and Sources/SlopeGeometry.swift, with a stand-in pebble
// on every ledge's seat, or times the pass. Arguments are key=value words (scripts/slope-lab.sh lists them).

var options: [String: String] = [:]
for word in CommandLine.arguments.dropFirst(2) {
    let parts = word.split(separator: "=", maxSplits: 1)
    if parts.count == 2 { options[String(parts[0])] = String(parts[1]) }
}
func number(_ key: String, _ fallback: Double) -> Double { options[key].flatMap(Double.init) ?? fallback }

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
let device = MTLCreateSystemDefaultDevice()!
let queue = device.makeCommandQueue()!
let source = try String(contentsOf: root.appendingPathComponent("Sources/Slope.metal"), encoding: .utf8)
    .replacingOccurrences(of: "#include <SwiftUI/SwiftUI_Metal.h>", with: "")
    .replacingOccurrences(of: "[[ stitchable ]]", with: "")
let kernel = """

    kernel void lab(texture2d<float, access::write> out [[texture(0)]], device const float *g [[buffer(0)]],
                    constant float4 &view [[buffer(1)]], constant float4 &play [[buffer(2)]],
                    constant float4 &lone [[buffer(3)]], constant float4 &more [[buffer(4)]],
                    constant float4 &upper [[buffer(5)]], device const float *eggs [[buffer(6)]],
                    uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
        float2 pos = (float2(gid) + 0.5) / view.x;
        out.write(float4(more.w > 0.0 ? slopeHollow(pos, half4(0.0h), more.xy, view, float2(0.5 * more.x, 0.3 * more.y),
                                                    float3(1.0, 0.16, 0.16), float3(0.16, 1.0, 0.3), float3(0.2, 0.4, 1.0))
                                      : slope(pos, half4(0.0h), more.xy, view, play, lone, more.z, upper, g, 0, eggs, 20)), gid);
    }
    """
let state = try device.makeComputePipelineState(function: device.makeLibrary(source: source + kernel, options: nil)
    .makeFunction(name: "lab")!)

let size = CGSize(width: number("w", 440), height: number("h", 956))
let scale = number("scale", 2)
// type=ax is the largest sizes' column: a taller pitch, the lips at the leading edge, at the overview too.
let ax = options["type"] == "ax"
var column = SlopeColumn.main(size: size, pitch: ax ? 196 : 110, lip: ax ? 62 : 132 - max(440 - size.width, 0) / 2, step: ax ? 1.5 : 6)
if ax {
    column.wall = 14
    column.spread = 8
}
if options["column"] == "pack" {
    column = SlopeColumn(stretches: (0 ..< 5).map { _ in .init(rock: .pale, terraces: [6], header: 110) }, foot: .floor, surface: false, first: nil)
}
let z = number("z", options["ledge"] != nil || options["at"] != nil ? 1 : 0)
let lay = SlopeLay(column, z: z)
var camera = SlopeLay.overview(height: size.height)
camera.z = z
if let n = options["ledge"].flatMap(Int.init) { camera = lay.camera(on: n, height: size.height) }
if options["at"] == "top" { camera.top = lay.travel(height: size.height).lowerBound }
if options["at"] == "bottom" { camera.top = lay.travel(height: size.height).upperBound }
// lift=<pt> pulls the camera up past its place, as a finger pulls the menu down; a negative one pulls it past the foot.
camera.top -= number("lift", 0)
let pw = Int(size.width * scale), ph = Int(size.height * scale)

let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: pw, height: ph, mipmapped: false)
descriptor.usage = [.shaderWrite, .shaderRead]
let texture = device.makeTexture(descriptor: descriptor)!
let uniforms = lay.uniforms(top: camera.top)
let buffer = device.makeBuffer(bytes: uniforms, length: uniforms.count * 4, options: .storageModeShared)!
var view = SIMD4<Float>(Float(scale), Float(number("t", 3)), Float(number("near", 1)), Float(number("motes", 1)))
var play = SIMD4<Float>(Float(number("level", 0)), Float(number("glint", 0)), Float(number("clear", 0)), Float(number("light", 1)))
var lone = SIMD4<Float>(1, 0.86, 0.6, Float(number("rock", 0)))
// upper=1 stands a second terrace over the lone one, at the screen's middle.
var upper = SIMD4<Float>(Float(size.width / 2), Float(size.height - 118), 85, Float(number("upper", 0)))
var more = SIMD4<Float>(Float(size.width), Float(size.height), Float(number("paper", 0)), Float(number("hollow", 0)))
// The menu's eggs (Slope.metal's SlopeEgg, in its order): night, deep, calm, meteors, moon (the terminator) and side,
// reveal (the mirrored sky's lights), skim=age,x,hop,count and seam=<tiers, e.g. 0,2>.
let skim = (options["skim"] ?? "0,0,0,0").split(separator: ",").compactMap { Float($0) }
let seams = (options["seam"] ?? "").split(separator: ",").compactMap { Int($0) }
var eggs: [Float] = [Float(number("night", 0)), Float(number("deep", 0)), Float(number("calm", 0)), Float(number("meteors", 0)),
                     Float(number("moon", 0)), Float(number("side", 1)),
                     Float(lay.travel(height: size.height).upperBound + size.height), Float(number("reveal", 1))]
    + skim + (0 ..< 4).map { seams.contains($0) ? 1 : 0 }
// nook=1 stands the spur under the last ledge.
eggs += number("nook", 0) > 0 ? [64, Float(lay.tops[lay.count - 1] + 1.3 * column.pitch), 0, 0] : [0, 0, 0, 0]
let eggBuffer = device.makeBuffer(bytes: eggs, length: eggs.count * 4, options: .storageModeShared)!

/// GPU seconds for one pass, the least of `tries`.
func pass(tries: Int) -> Double {
    var best = Double.infinity
    for _ in 0 ..< tries {
        let cb = queue.makeCommandBuffer()!, enc = cb.makeComputeCommandEncoder()!
        enc.setComputePipelineState(state)
        enc.setTexture(texture, index: 0)
        enc.setBuffer(buffer, offset: 0, index: 0)
        enc.setBytes(&view, length: 16, index: 1)
        enc.setBytes(&play, length: 16, index: 2)
        enc.setBytes(&lone, length: 16, index: 3)
        enc.setBytes(&more, length: 16, index: 4)
        enc.setBytes(&upper, length: 16, index: 5)
        enc.setBuffer(eggBuffer, offset: 0, index: 6)
        enc.dispatchThreads(MTLSize(width: pw, height: ph, depth: 1), threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
        enc.endEncoding()
        cb.commit()
        cb.waitUntilCompleted()
        best = min(best, cb.gpuEndTime - cb.gpuStartTime)
    }
    return best
}

switch CommandLine.arguments.dropFirst().first {
case "bench":
    print(String(format: "%.3f ms a pass at %d x %d px", pass(tries: 40) * 1000, pw, ph))
case "probe":
    // The brightest the water gets where words go (right of the lips' line), by depth: its WCAG luminance, and what
    // the full ink reads at over it.
    _ = pass(tries: 1)
    var bytes = [UInt8](repeating: 0, count: pw * ph * 4)
    texture.getBytes(&bytes, bytesPerRow: pw * 4, from: MTLRegionMake2D(0, 0, pw, ph), mipmapLevel: 0)
    func lin(_ v: UInt8) -> Double { let c = Double(v) / 255; return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
    // zone=rock reads the rock's heart instead, where a hollow's name goes.
    let rock = options["zone"] == "rock"
    let columns = rock ? 0 ..< Int((column.lip - 60) * scale) : Int((column.lip + 8 * column.step + 18) * scale) ..< pw
    let band = Int(40 * scale)
    for row in stride(from: 0, to: ph, by: band) {
        var all: [Double] = []
        for y in row ..< min(row + band, ph) {
            for x in columns {
                let i = 4 * (y * pw + x)
                all.append(0.2126 * lin(bytes[i]) + 0.7152 * lin(bytes[i + 1]) + 0.0722 * lin(bytes[i + 2]))
            }
        }
        all.sort()
        let worst = all[Int(Double(all.count - 1) * 0.999)]
        let depth = camera.top + CGFloat(row) / scale
        print(String(format: "y %4d  fathoms %6.1f  luminance %.4f  ink %.1f:1", row / Int(scale), depth / column.pitch,
                     worst, (0.8632 + 0.05) / (worst + 0.05)))
    }
case "render":
    _ = pass(tries: 1)
    var bytes = [UInt8](repeating: 0, count: pw * ph * 4)
    texture.getBytes(&bytes, bytesPerRow: pw * 4, from: MTLRegionMake2D(0, 0, pw, ph), mipmapLevel: 0)
    let ctx = CGContext(data: &bytes, width: pw, height: ph, bitsPerComponent: 8, bytesPerRow: pw * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // Core Graphics' y runs up: flip to the screen's, in points.
    ctx.translateBy(x: 0, y: CGFloat(ph))
    ctx.scaleBy(x: scale, y: -scale)
    if options["pebbles"] != "0", number("hollow", 0) == 0 {
        let lit = Int(number("lit", 16))
        for n in 0 ..< lay.count where n != 1 || column.first == nil {
            let seat = lay.seat(n), y = seat.y - camera.top
            guard y > -20, y < size.height + 20 else { continue }
            let on = n <= lit
            let rx = lay.half(on ? .lit : .dull), ry = rx * 0.72
            ctx.setFillColor(on ? CGColor(red: 0.93, green: 0.88, blue: 0.78, alpha: 1) : CGColor(red: 0.3, green: 0.37, blue: 0.4, alpha: 1))
            ctx.fillEllipse(in: CGRect(x: seat.x - rx, y: y - 2 * ry + 0.14 * ry, width: 2 * rx, height: 2 * ry))
        }
    }
    let out = CommandLine.arguments[2]
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
default:
    print("usage: scripts/slope-lab.sh render <out.png> [key=value ...] | bench x [key=value ...]")
}
