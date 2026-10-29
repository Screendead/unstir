// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Draws Prism's engravings on the Mac without the app, and checks each against every layout's cores: how much of each
// core is lit, and how much of that light a 30° step of the core moves, so a step reads in every core.

func bitmap(_ lines: [Engraving.Line], side: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side,
                        space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
    ctx.setFillColor(gray: 0, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
    let r = Double(side) / 2
    // y down, as the tank's units are.
    ctx.translateBy(x: 0, y: CGFloat(side))
    ctx.scaleBy(x: 1, y: -1)
    ctx.setStrokeColor(gray: 1, alpha: 1)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    for line in lines {
        ctx.setLineWidth(CGFloat(line.width * r))
        ctx.addLines(between: line.points.map { CGPoint(x: r + $0.x * r, y: r + $0.y * r) })
        ctx.strokePath()
    }
    return ctx
}

func png(_ ctx: CGContext, _ path: String, cores layout: Layout?) {
    if let layout {
        let side = Double(ctx.width), r = side / 2
        ctx.setStrokeColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
        ctx.setLineWidth(1.5)
        for rod in layout.rods {
            let c = CGPoint(x: r + rod.x * r, y: r + rod.y * r), k = rod.z * Tank.plateau * r
            ctx.strokeEllipse(in: CGRect(x: c.x - k, y: c.y - k, width: 2 * k, height: 2 * k))
        }
    }
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
}

/// Per core: the share of its pixels lit, and the share of its lit pixels a 30° step darkens.
func check(_ ctx: CGContext, _ layout: Layout) -> [(lit: Double, moved: Double)] {
    let side = ctx.width, r = Double(side) / 2
    let px = ctx.data!.bindMemory(to: UInt8.self, capacity: side * side)
    // The bitmap is stored top row first in memory once the context is flipped back: row 0 is y = -1.
    func at(_ x: Double, _ y: Double) -> Bool {
        let i = Int(r + x * r), j = Int(r + y * r)
        guard i >= 0, j >= 0, i < side, j < side else { return false }
        return px[j * side + i] > 127
    }
    return layout.rods.map { rod in
        let k = rod.z * Tank.plateau, step = 4 / Double(side)
        var inside = 0, lit = 0, moved = 0
        let (c, s) = (cos(Tank.step), sin(Tank.step))
        var y = -k
        while y <= k {
            var x = -k
            while x <= k {
                if x * x + y * y <= k * k {
                    inside += 1
                    if at(rod.x + x, rod.y + y) {
                        lit += 1
                        if !at(rod.x + c * x - s * y, rod.y + s * x + c * y) { moved += 1 }
                    }
                }
                x += step
            }
            y += step
        }
        return (Double(lit) / Double(inside), lit == 0 ? 0 : Double(moved) / Double(lit))
    }
}

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "render" where args.count >= 3:
    guard let plate = Engraving.Plate(rawValue: args[1]) else { print("plates: \(Engraving.Plate.allCases.map(\.rawValue))"); exit(2) }
    let side = args.count > 3 ? Int(args[3])! : 1200
    png(bitmap(Engraving.lines(plate), side: side), args[2], cores: args.count > 4 ? Layout(rawValue: args[4]) : nil)
case "check":
    let plates = args.count > 1 ? args.dropFirst().compactMap(Engraving.Plate.init(rawValue:)) : Engraving.Plate.allCases
    print("plate\tlayout\tleast lit\tleast moved\tper core lit/moved")
    for plate in plates {
        let ctx = bitmap(Engraving.lines(plate), side: 1024)
        for layout in Layout.allCases {
            let cores = check(ctx, layout)
            print([plate.rawValue, layout.rawValue, String(format: "%.3f", cores.map(\.lit).min()!),
                   String(format: "%.2f", cores.map(\.moved).min()!),
                   cores.map { String(format: "%.2f/%.2f", $0.lit, $0.moved) }.joined(separator: " ")].joined(separator: "\t"))
        }
    }
default:
    print("usage: render <plate> <out.png> [side] [layout] | check [plate...]")
    exit(2)
}
