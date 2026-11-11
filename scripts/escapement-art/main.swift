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

func plate(_ which: String) -> EscapementArt.Plate {
    if which == "today" { return today() }
    if which.hasSuffix("alt"), let alternate = Int(which.dropLast(3)).flatMap(EscapementArt.alternate) { return alternate }
    guard let plate = Int(which).flatMap(EscapementArt.plate) else {
        print("no plate for problem \(which)")
        exit(2)
    }
    return plate
}

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, alpha: 1)
}

/// `hairline` is the thinnest a line is drawn, in pixels: the game's 2.2, which the default scales to this side as
/// against a Pro Max's glass, so a render looks as play does whatever its size.
func raster(_ plate: EscapementArt.Plate, side w: Int, hairline: Double? = nil) -> (CGContext, [UInt8]) {
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
            ctx.setLineWidth(max(mark.width * r, hairline ?? 2.2 * Double(w) / 1284))
            ctx.strokePath()
        }
    }
    let px = Array(UnsafeBufferPointer(start: ctx.data!.assumingMemoryBound(to: UInt8.self), count: 4 * w * w))
    return (ctx, px)
}

/// Where the game's controls fall on a plate, for composing round them: a knob on every rod of the layout, and round
/// each the hub a clock there would wear, as any rod may be one.
func overlay(_ ctx: CGContext, _ layout: Layout, side w: Int) {
    let r = Double(w) / 2
    func disc(_ rod: SIMD3<Double>, _ radius: Double) -> CGRect {
        CGRect(x: r + (rod.x - radius) * r, y: r + (rod.y - radius) * r, width: 2 * radius * r, height: 2 * radius * r)
    }
    for rod in layout.rods {
        ctx.setFillColor(rgb(0x1F3A5F))
        ctx.fillEllipse(in: disc(rod, 0.08))
        ctx.setStrokeColor(rgb(0x1F3A5F))
        ctx.setLineWidth(0.006 * r)
        ctx.strokeEllipse(in: disc(rod, 0.155))
    }
}

/// The second ink's share of the glass's pixels, and the radius of the circle about its marks' middle that holds them.
func second(_ plate: EscapementArt.Plate, hairline: Double? = nil) -> (share: Double, reach: Double) {
    let w = 512, (_, px) = raster(plate, side: w, hairline: hairline), r = Double(w) / 2
    var inside = 0, red = 0
    for j in 0..<w {
        for i in 0..<w where (Double(i) - r) * (Double(i) - r) + (Double(j) - r) * (Double(j) - r) < r * r {
            inside += 1
            let k = 4 * (j * w + i)
            if Int(px[k]) - Int(px[k + 1]) > 0x30 { red += 1 }
        }
    }
    let points = plate.marks.filter { $0.ink == .second }.flatMap(\.points)
    guard let lo = points.reduce(nil, { a, p in a.map { simd_min($0, p) } ?? p }),
          let hi = points.reduce(nil, { a, p in a.map { simd_max($0, p) } ?? p }) else { return (0, 0) }
    let middle = (lo + hi) / 2
    return (Double(red) / Double(inside), points.map { simd_distance($0, middle) }.max() ?? 0)
}

/// The plates' tests' measure, read off green so a red line counts as ink: in each rod's core, the share inked and the
/// share of that ink a 30° step moves onto paper.
func check(_ plate: EscapementArt.Plate, _ layout: Layout, hairline: Double? = nil) -> [(on: Double, moved: Double)] {
    let w = 512, (_, px) = raster(plate, side: w, hairline: hairline), r = Double(w) / 2
    func inked(_ x: Double, _ y: Double) -> Bool {
        let i = Int(r + x * r), j = Int(r + y * r)
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
case "render" where args.count >= 4:
    let side = args.count > 4 ? Int(args[4])! : 1284
    let (ctx, _) = raster(plate(args[2]), side: side)
    if args.count > 5 { overlay(ctx, Layout(rawValue: args[5])!, side: side) }
    let out = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[3]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(out, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(out)
case "check" where args.count >= 4:
    // The test bakes at an SE's glass at default type, 328 pt at 2x, where the hairline is heaviest against the picture
    // of any phone's (PlayLayoutTests' sizes).
    let p = plate(args[2]), layout = Layout(rawValue: args[3])!, rods = check(p, layout, hairline: 2.2 * 512 / 656), play = check(p, layout), ink = second(p, hairline: 2.2 * 512 / 656)
    for (k, rod) in rods.enumerated() {
        print(String(format: "rod %d  inked %.2f  moved %.2f  (at a Pro Max's weights %.2f and %.2f)", k, rod.on, rod.moved, play[k].on, play[k].moved))
    }
    print(String(format: "worst  inked %.2f  moved %.2f  (the test asks over 0.10 and 0.50)", rods.map(\.on).min()!, rods.map(\.moved).min()!))
    print(String(format: "second ink  share %.3f  reach %.2f  (the test asks under 0.03 and 0.40)", ink.share, ink.reach))
case "bench" where args.count >= 3:
    var build = 0.0, draw = 0.0, marks = 0, points = 0
    for _ in 0..<5 {
        let t0 = Date()
        let p = plate(args[2])
        let t1 = Date()
        _ = raster(p, side: 1284)
        build += t1.timeIntervalSince(t0)
        draw += Date().timeIntervalSince(t1)
        marks = p.marks.count
        points = p.marks.reduce(0) { $0 + $1.points.count }
    }
    print(String(format: "%@  geometry %.1f ms  raster at 1284 px %.0f ms  marks %d  points %d", args[2], build * 200, draw * 200, marks, points))
default:
    print("usage: render <problem|today> <out.png> [side] [layout] | check <problem|today> <layout> | bench <problem|today>")
    exit(2)
}
