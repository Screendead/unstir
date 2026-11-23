// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreGraphics
import Foundation
import ImageIO
import Metal
import UniformTypeIdentifiers

// Draws the slope's ground on the Mac's GPU from Sources/Slope.metal and Sources/Slope.swift, with a stand-in pebble
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
                    constant float2 &size [[buffer(3)]], uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
        out.write(float4(slope((float2(gid) + 0.5) / view.x, half4(0.0h), size, view, play, g, 0)), gid);
    }
    """
let state = try device.makeComputePipelineState(function: device.makeLibrary(source: source + kernel, options: nil)
    .makeFunction(name: "lab")!)

let size = CGSize(width: number("w", 440), height: number("h", 956))
let scale = number("scale", 2)
let slope = Slope(type: number("type", 1))
var camera = slope.overview(in: size)
if let k = options["ledge"].flatMap(Int.init) { camera = slope.dive(to: k) }
if let y = options["y"].flatMap(Double.init) { camera = SlopeCamera(y: y, zoom: 1) }
if options["at"] == "top" { camera = slope.top(in: size) }
if options["at"] == "bottom" { camera = slope.bottom(in: size) }
if let z = options["zoom"].flatMap(Double.init) { camera.zoom = z }
// between=0.4: that far from the overview to the camera asked for, the zoom by its logarithm.
if let share = options["between"].flatMap(Double.init) {
    let wide = slope.overview(in: size)
    camera = SlopeCamera(y: wide.y + (camera.y - wide.y) * share, zoom: exp(log(wide.zoom) + (log(camera.zoom) - log(wide.zoom)) * share))
}
let frame = Slope.Frame(slope, camera: camera, size: size)
let pw = Int(size.width * scale), ph = Int(size.height * scale)

let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: pw, height: ph, mipmapped: false)
descriptor.usage = [.shaderWrite, .shaderRead]
let texture = device.makeTexture(descriptor: descriptor)!
let uniforms = frame.uniforms
let buffer = device.makeBuffer(bytes: uniforms, length: uniforms.count * 4, options: .storageModeShared)!
var view = SIMD4<Float>(Float(scale), Float(number("t", 3)), Float(number("near", 1)), Float(number("motes", 1)))
var play = SIMD4<Float>(Float(number("level", 0)), Float(number("glint", 0)), Float(number("clear", 0)), 0)
var points = SIMD2<Float>(Float(size.width), Float(size.height))

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
        enc.setBytes(&points, length: 8, index: 3)
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
    let columns = rock ? 0 ..< Int((slope.lip - 70) * scale) : Int((slope.lip + 18) * scale) ..< pw
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
        let depth = frame.depth(at: CGFloat(row) / scale)
        print(String(format: "y %4d  fathoms %6.1f  luminance %.4f  ink %.1f:1", row / Int(scale), depth / slope.pitch,
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
    if options["pebbles"] != "0" {
        let lit = Int(number("lit", 40))
        for k in 0 ..< Slope.count {
            let seat = frame.point(frame.seat(k))
            guard seat.y > -20, seat.y < size.height + 20 else { continue }
            if k < Slope.shallows ? k != Slope.daily && k != Slope.archive : Slope.bare(k) { continue }
            let on = k <= lit
            let rx = frame.length(on ? 8.4 : 6.8, least: on ? 2.5 : 2.1), ry = rx * (on ? 0.71 : 0.65)
            ctx.setFillColor(on ? CGColor(red: 0.93, green: 0.88, blue: 0.78, alpha: 1) : CGColor(red: 0.3, green: 0.37, blue: 0.4, alpha: 1))
            ctx.fillEllipse(in: CGRect(x: seat.x - rx, y: seat.y - 2 * ry + 0.12 * ry, width: 2 * rx, height: 2 * ry))
        }
    }
    let out = CommandLine.arguments[2]
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
default:
    print("usage: scripts/slope-lab.sh render <out.png> [key=value ...] | bench x [key=value ...]")
}
