// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import simd

typealias P = SIMD2<Double>

/// Today's plate (`Picture.engineTurning`) as marks, the baseline for cost and for how a step shows.
func today() -> EscapementArt.Plate {
    var plate = EscapementArt.Plate()
    let from = P(-1.6, 1.4), first = -69.2 * Double.pi / 180, last = -13.1 * Double.pi / 180
    for i in 0..<90 {
        let a = first + (last - first) * Double(i) / 89
        plate.line([from, from + 4 * P(cos(a), sin(a))])
    }
    for j in -13...13 {
        for i in -13...13 {
            let x = Double(i) * 0.08 + (j & 1 == 1 ? 0.04 : 0), y = Double(j) * 0.08
            guard x * x + y * y < 1.1 else { continue }
            plate.line([P(x - 0.015, y + 0.0075), P(x, y - 0.0075), P(x + 0.015, y + 0.0075)])
        }
    }
    return plate
}

func plate(_ which: String, _ n: Int) -> EscapementArt.Plate {
    which == "today" ? today() : EscapementArt.plate(EscapementArt.Direction(rawValue: which)!, problem: n)
}

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, alpha: 1)
}

func raster(_ plate: EscapementArt.Plate, side w: Int) -> (CGContext, [UInt8]) {
    let ctx = CGContext(data: nil, width: w, height: w, bitsPerComponent: 8, bytesPerRow: 4 * w,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let r = Double(w) / 2
    ctx.translateBy(x: 0, y: Double(w))
    ctx.scaleBy(x: 1, y: -1)
    ctx.setFillColor(rgb(0xF3EAD8))
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: w))
    ctx.setLineJoin(.round)
    for mark in plate.marks where mark.points.count > 1 {
        let colour = rgb(mark.ink == .black ? 0x1A1A1A : mark.ink == .second ? plate.second : 0xF3EAD8)
        ctx.beginPath()
        ctx.addLines(between: mark.points.map { CGPoint(x: r + $0.x * r, y: r + $0.y * r) })
        if mark.width == 0 {
            ctx.setFillColor(colour)
            ctx.fillPath()
        } else {
            ctx.setStrokeColor(colour)
            ctx.setLineWidth(max(mark.width * r, 2.2 * Double(w) / 1284))
            ctx.strokePath()
        }
    }
    let px = Array(UnsafeBufferPointer(start: ctx.data!.assumingMemoryBound(to: UInt8.self), count: 4 * w * w))
    return (ctx, px)
}

/// `testThePlateIsInkOnBoneAndShowsAStepInEveryCore`'s measure, read off green so a red line counts as ink: in each
/// rod's core, the share inked and the share of that ink a 30° step moves onto paper.
func check(_ plate: EscapementArt.Plate, _ layout: Layout) -> [(on: Double, moved: Double)] {
    let w = 512, (_, px) = raster(plate, side: w), r = Double(w) / 2
    func inked(_ x: Double, _ y: Double) -> Bool {
        let i = Int(r + x * r), j = Int(r - y * r)
        return i >= 0 && j >= 0 && i < w && j < w && px[4 * (j * w + i) + 1] < 0x87
    }
    return layout.rods.map { rod in
        let core = rod.z * Tank.plateau, step = 2 / Double(w)
        var inside = 0, on = 0, moved = 0
        for y in stride(from: -core, through: core, by: step) {
            for x in stride(from: -core, through: core, by: step) where x * x + y * y <= core * core {
                inside += 1
                guard inked(rod.x + x, rod.y + y) else { continue }
                on += 1
                let c = cos(Tank.step), s = sin(Tank.step)
                if !inked(rod.x + c * x - s * y, rod.y + s * x + c * y) { moved += 1 }
            }
        }
        return (Double(on) / Double(inside), Double(moved) / Double(max(on, 1)))
    }
}

let args = CommandLine.arguments
switch args.count > 1 ? args[1] : "" {
case "render" where args.count >= 5:
    let side = args.count > 5 ? Int(args[5])! : 1284
    let (ctx, _) = raster(plate(args[2], Int(args[3])!), side: side)
    let out = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[4]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(out, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(out)
case "check" where args.count >= 5:
    let rods = check(plate(args[2], Int(args[3])!), Layout(rawValue: args[4])!)
    for (k, rod) in rods.enumerated() { print(String(format: "rod %d  inked %.2f  moved %.2f", k, rod.on, rod.moved)) }
    print(String(format: "worst  inked %.2f  moved %.2f  (the test asks over 0.10 and 0.50)", rods.map(\.on).min()!, rods.map(\.moved).min()!))
case "bench" where args.count >= 4:
    let n = Int(args[3])!
    var build = 0.0, draw = 0.0, marks = 0, points = 0
    for _ in 0..<5 {
        let t0 = Date()
        let p = plate(args[2], n)
        let t1 = Date()
        _ = raster(p, side: 1284)
        build += t1.timeIntervalSince(t0)
        draw += Date().timeIntervalSince(t1)
        marks = p.marks.count
        points = p.marks.reduce(0) { $0 + $1.points.count }
    }
    print(String(format: "%@ %d  geometry %.0f ms  raster at 1284 px %.0f ms  marks %d  points %d", args[2], n, build * 200, draw * 200, marks, points))
default:
    print("usage: render <a|b|c|today> <problem> <out.png> [side] | check <a|b|c|today> <problem> <layout> | bench <a|b|c|today> <problem>")
    exit(2)
}
