// Copyright © 2026 Jack Lusher. All rights reserved.

import AppKit
import SwiftUI

// Usage: lab <scene 1-5> <out.png> [side px] [crop: x y half-width, tank units]
// Writes the scene held back at its late time, played at its early time, and where the two scene layers differ over a
// guide of the layout (white), side by side. The guide: each disc's edge (grey), each core less 0.02 (green), the knob
// and its margin (red), and the parts of each core another disc reaches (red tint).

let args = CommandLine.arguments
if args.count >= 3, args[1] == "figures" {
    // Every figure standing, large, for judging their outlines.
    MainActor.assumeIsolated {
        let r = ImageRenderer(content: Canvas { ctx, size in
            let pen = Pen(ctx: ctx, r: size.width / 2)
            ctx.fill(pen.rect(-1, -1, 1, 1), with: .color(.black))
            for (i, who) in [Figure.Who.father, .grandmother, .child, .neighbour, .crew].enumerated() {
                let f = Figure.standing(who).path(pen, x: -0.8 + 0.38 * Double(i), y: 0.4, h: who == .child ? 0.5 : 0.75)
                pen.solid(f, Dawn.ink)
            }
            pen.solid(Dog.sitting.path(pen, x: -0.6, y: 0.85, h: 0.3), Dawn.ink)
            pen.solid(Dog.sniffing.path(pen, x: 0.1, y: 0.85, h: 0.3), Dawn.ink)
        }.frame(width: 900, height: 900))
        r.scale = 1
        let rep = NSBitmapImageRep(cgImage: r.cgImage!)
        try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
    }
    exit(0)
}
guard args.count >= 3, let n = Int(args[1]), let scene = Dawn(rawValue: n) else {
    print("usage: lab <scene 1-5> <out.png> [side px]"); exit(2)
}
let side = args.count > 3 ? Int(args[3])! : 600
let crop = args.count > 6 ? (x: Double(args[4])!, y: Double(args[5])!, w: Double(args[6])!) : nil

@MainActor func render(_ draw: @escaping (GraphicsContext, CGFloat) -> Void, opaque: Bool) -> CGImage {
    let r = ImageRenderer(content: Canvas { ctx, size in draw(ctx, size.width / 2) }.frame(width: CGFloat(side), height: CGFloat(side)))
    r.scale = 1
    r.isOpaque = opaque
    if ProcessInfo.processInfo.environment["LAB_LINEAR"] != nil { r.colorMode = .extendedLinear }
    return r.cgImage!
}

func pixels(_ image: CGImage) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: 4 * side * side)
    let ctx = CGContext(data: &bytes, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 4 * side,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    return bytes
}

MainActor.assumeIsolated {
    let held = render({ ctx, r in
        scene.drawSky(ctx, r: r, minutes: scene.late); scene.drawLive(ctx, r: r, minutes: scene.late); scene.draw(ctx, r: r, played: [])
    }, opaque: true)
    let played = render({ ctx, r in
        scene.drawSky(ctx, r: r, minutes: scene.early); scene.drawLive(ctx, r: r, minutes: scene.early)
        scene.draw(ctx, r: r, played: scene.vignettes)
    }, opaque: true)
    let a = pixels(render({ ctx, r in scene.draw(ctx, r: r, played: []) }, opaque: false))
    let b = pixels(render({ ctx, r in scene.draw(ctx, r: r, played: scene.vignettes) }, opaque: false))
    let rods = scene.layout.rods
    let again = pixels(render({ ctx, r in scene.draw(ctx, r: r, played: []) }, opaque: false))
    let noise = (0..<side * side).filter { i in (0..<4).contains(where: { abs(Int(a[4 * i + $0]) - Int(again[4 * i + $0])) > 8 }) }
    if !noise.isEmpty { print("the held-back scene drawn twice differs at \(noise.count) pixels, e.g. \(noise.prefix(3).map { ($0 % side, $0 / side) })") }
    // Per vignette: how far its change reaches from its own centre (against the core less 0.02), how near the knob it
    // comes (against 0.085), and which other discs it enters.
    for k in scene.vignettes.sorted() {
        let one = pixels(render({ ctx, r in scene.draw(ctx, r: r, played: [k]) }, opaque: false))
        var far = 0.0, near = 9.0, enters: Set<Int> = [], farthest = (0.0, 0.0)
        let core0 = Tank.plateau * rods[k].z
        var stray: [(Double, Double, [Int])] = []
        for i in 0..<side * side where (0..<4).contains(where: { abs(Int(a[4 * i + $0]) - Int(one[4 * i + $0])) > 14 }) {
            let x = (Double(i % side) + 0.5) / Double(side) * 2 - 1, y = (Double(i / side) + 0.5) / Double(side) * 2 - 1
            let d = ((x - rods[k].x) * (x - rods[k].x) + (y - rods[k].y) * (y - rods[k].y)).squareRoot()
            if d > far { farthest = (x, y) }
            if d > core0 { stray.append((x, y, (0..<4).map { Int(one[4 * i + $0]) - Int(a[4 * i + $0]) })) }
            far = max(far, d); near = min(near, d)
            for (j, o) in rods.enumerated() where j != k && ((x - o.x) * (x - o.x) + (y - o.y) * (y - o.y)).squareRoot() < o.z { enters.insert(j) }
        }
        let core = Tank.plateau * rods[k].z
        if !stray.isEmpty { print("  \(stray.count) outside the core, e.g.", stray.prefix(4).map { String(format: "(%.3f, %.3f) %@", $0.0, $0.1, $0.2.description) }) }
        print(String(format: "vignette %d: reaches %.3f (at %.2f, %.2f) of %.3f%@, nearest the knob %.3f of 0.085%@, enters %@", k, far, farthest.0, farthest.1, core - 0.02,
                     far > core - 0.02 ? " OVER" : "", near, near < 0.085 ? " OVER" : "", enters.sorted().description))
    }
    let guide = render({ ctx, r in
        let pen = Pen(ctx: ctx, r: r)
        ctx.fill(pen.rect(-1, -1, 1, 1), with: .color(.black))
        for (k, rod) in rods.enumerated() {
            let core = Tank.plateau * rod.z
            // Red where another disc reaches into this core.
            for (j, other) in rods.enumerated() where j != k {
                var c = ctx
                c.clip(to: pen.circle(rod.x, rod.y, core))
                c.fill(pen.circle(other.x, other.y, other.z), with: .color(.red.opacity(0.22)))
            }
            ctx.stroke(pen.circle(rod.x, rod.y, rod.z), with: .color(.gray.opacity(0.6)), lineWidth: 1)
            ctx.stroke(pen.circle(rod.x, rod.y, core - 0.02), with: .color(.green), lineWidth: 1)
            ctx.fill(pen.circle(rod.x, rod.y, Tank.coreRadius + 0.015), with: .color(.red.opacity(0.6)))
        }
        for b in scene.bodies { ctx.stroke(pen.circle(b.x, b.y, b.radius), with: .color(.yellow), lineWidth: 1) }
        ctx.stroke(pen.circle(0, 0, 1), with: .color(.white.opacity(0.5)), lineWidth: 1)
    }, opaque: true)
    var g = pixels(guide)
    for i in 0..<side * side where (0..<4).contains(where: { abs(Int(a[4 * i + $0]) - Int(b[4 * i + $0])) > 8 }) {
        g[4 * i] = 255; g[4 * i + 1] = 255; g[4 * i + 2] = 255
    }
    let diff = CGContext(data: &g, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 4 * side,
                         space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.makeImage()!
    let sheet = CGContext(data: nil, width: 3 * side + 20, height: side, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    sheet.setFillColor(CGColor(gray: 0.15, alpha: 1)); sheet.fill(CGRect(x: 0, y: 0, width: 3 * side + 20, height: side))
    var images = [held, played, diff]
    if let crop {
        let px = Double(side) / 2
        let box = CGRect(x: (crop.x - crop.w + 1) * px, y: (crop.y - crop.w + 1) * px, width: 2 * crop.w * px, height: 2 * crop.w * px)
        images = images.map { $0.cropping(to: box)! }
    }
    for (i, image) in images.enumerated() {
        sheet.saveGState()
        if crop == nil { sheet.addEllipse(in: CGRect(x: i * (side + 10), y: 0, width: side, height: side)); sheet.clip() }
        sheet.draw(image, in: CGRect(x: i * (side + 10), y: 0, width: side, height: side))
        sheet.restoreGState()
    }
    let rep = NSBitmapImageRep(cgImage: sheet.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
}
