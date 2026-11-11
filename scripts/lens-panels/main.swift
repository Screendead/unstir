// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreGraphics
import Foundation
import ImageIO
import simd
import UniformTypeIdentifiers

// Lens's panels on the Mac, without the app: the clean bake, a stirred view, the bake's time and the contrast check.

func panel(_ name: String) -> Halftone.Panel {
    guard let p = Halftone.panels.first(where: { $0.name == name }) else {
        fatalError("no panel \(name); panels: \(Halftone.panels.map(\.name).joined(separator: " "))")
    }
    return p
}

func png(_ bytes: [UInt8], side: Int, _ path: String) {
    let provider = CGDataProvider(data: Data(bytes) as CFData)!
    let image = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * side,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                        provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

/// The clean bake seen through a stack, newest entry undone first, as the shader samples it (one tap, bilinear), black
/// outside the glass.
func stirred(_ clean: [UInt8], side: Int, layout: Layout, lenses: Set<Int>, stack: [Twist]) -> [UInt8] {
    var out = [UInt8](repeating: 255, count: 4 * side * side)
    let r = Double(side) / 2
    func at(_ i: Int, _ j: Int, _ c: Int) -> Double {
        Double(clean[4 * (min(max(j, 0), side - 1) * side + min(max(i, 0), side - 1)) + c])
    }
    for j in 0..<side {
        for i in 0..<side {
            var q = SIMD2((Double(i) + 0.5 - r) / r, (Double(j) + 0.5 - r) / r)
            let k = 4 * (j * side + i)
            guard simd_length(q) < 1 else { out[k] = 0; out[k + 1] = 0; out[k + 2] = 0; continue }
            for t in stack.reversed() {
                let rod = layout.rods[t.rod]
                q = lenses.contains(t.rod) ? Tank.lens(q, rod: rod, steps: -Double(t.steps))
                    : Tank.twist(q, rod: rod, angle: -Double(t.steps) * Tank.step)
            }
            let x = q.x * r + r - 0.5, y = q.y * r + r - 0.5
            let x0 = Int(floor(x)), y0 = Int(floor(y)), fx = x - floor(x), fy = y - floor(y)
            for c in 0..<3 {
                let v = (at(x0, y0, c) * (1 - fx) + at(x0 + 1, y0, c) * fx) * (1 - fy)
                    + (at(x0, y0 + 1, c) * (1 - fx) + at(x0 + 1, y0 + 1, c) * fx) * fy
                out[k + c] = UInt8(min(max(v, 0), 255) + 0.5)
            }
        }
    }
    return out
}


/// The same panel drawn as vector shapes through Core Graphics: each screen's whole dots as filled circles added in
/// light, then the strokes. A measure of what a vector bake would cost, not the app's bake: inks add in the context's
/// gamma, not in linear light.
func vector(_ p: Halftone.Panel, side: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 4 * side,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
    let r = Double(side) / 2
    ctx.translateBy(x: 0, y: CGFloat(side))
    ctx.scaleBy(x: CGFloat(r), y: -CGFloat(r))
    ctx.translateBy(x: 1, y: 1)
    ctx.setBlendMode(.plusLighter)
    let hex: [UInt32] = [0x00E5FF, 0xFF2BD6, 0xFFE600]
    for (k, ink) in Halftone.inks.enumerated() {
        let v = hex[k]
        ctx.setFillColor(CGColor(srgbRed: Double(v >> 16) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, alpha: 1))
        let a = ink.degrees * .pi / 180, cs = cos(a), sn = sin(a), pitch = Halftone.pitch
        let reach = Int((1.5 / pitch).rounded(.up))
        for j in -reach...reach {
            for i in -reach...reach {
                let cell = SIMD2(Double(i), Double(j)) * pitch
                let centre = SIMD2(cell.x * cs - cell.y * sn, cell.x * sn + cell.y * cs)
                guard abs(centre.x) < 1 + pitch, abs(centre.y) < 1 + pitch else { continue }
                let t = p.tones(centre)[k]
                guard t > 0 else { continue }
                let rad = pitch * (t / .pi).squareRoot()
                ctx.fillEllipse(in: CGRect(x: centre.x - rad, y: centre.y - rad, width: 2 * rad, height: 2 * rad))
            }
        }
    }
    ctx.setBlendMode(.normal)
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 1))
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    for s in p.strokes {
        ctx.setLineWidth(CGFloat(s.width))
        ctx.addLines(between: s.points.map { CGPoint(x: $0.x, y: $0.y) })
        ctx.strokePath()
    }
    return ctx
}

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "render" where args.count >= 3:
    let p = panel(args[1]), side = args.count > 3 ? Int(args[3])! : 1290
    let start = Date.now
    var bytes = p.pixels(side)
    print(String(format: "%@ %d px baked in %.0f ms", p.name, side, Date.now.timeIntervalSince(start) * 1000))
    if args.count > 6, let layout = Layout(rawValue: args[4]) {
        let lenses = Set(args[5].split(separator: ",").compactMap { Int($0) })
        bytes = stirred(bytes, side: side, layout: layout, lenses: lenses, stack: [Twist].parse(args[6], in: layout, lenses: lenses))
    }
    png(bytes, side: side, args[2])
case "vector" where args.count >= 3:
    let p = panel(args[1]), side = args.count > 3 ? Int(args[3])! : 1290
    let image = vector(p, side: side).makeImage()!
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
case "time":
    let side = args.count > 1 ? Int(args[1])! : 1290
    let names = args.count > 2 ? Array(args[2...]) : Halftone.panels.map(\.name)
    for name in names {
        let p = panel(name)
        _ = p.pixels(64)
        var best = Double.infinity
        for _ in 0..<3 {
            let start = Date.now
            _ = p.pixels(side)
            best = min(best, Date.now.timeIntervalSince(start))
        }
        var vectorBest = Double.infinity
        for _ in 0..<3 {
            let start = Date.now
            _ = vector(p, side: side).makeImage()
            vectorBest = min(vectorBest, Date.now.timeIntervalSince(start))
        }
        print(String(format: "%-10@ %d px: %5.0f ms a pixel at a time, %4.0f ms as vectors (best of 3), %4.1f MB as RGBA8, %3d strokes",
                     p.name, side, best * 1000, vectorBest * 1000, Double(4 * side * side) / 1e6, p.strokes.count))
    }
case "check" where args.count >= 3:
    let p = panel(args[1])
    guard let layout = Layout(rawValue: args[2]) else { fatalError("no layout \(args[2])") }
    let lenses = Set((args.count > 3 ? args[3] : "").split(separator: ",").compactMap { Int($0) })
    let aa = 1.0 / 568, spacing = 1.0 / 48
    var worst = 1.0
    for (k, rod) in layout.rods.enumerated() {
        let c = SIMD2(rod.x, rod.y), reach = Tank.plateau * rod.z
        var points: [SIMD2<Double>] = []
        for y in stride(from: -reach, through: reach, by: spacing) {
            for x in stride(from: -reach, through: reach, by: spacing) where x * x + y * y < reach * reach {
                points.append(c + SIMD2(x, y))
            }
        }
        let clean = points.map { p.light($0, aa: aa) }
        func changed(_ back: (SIMD2<Double>) -> SIMD2<Double>) -> Double {
            let moved = zip(points, clean).filter { q, light in
                let d = simd_abs(p.light(back(q), aa: aa) - light)
                return max(d.x, d.y, d.z) > 0.25
            }
            return Double(moved.count) / Double(points.count)
        }
        let shares = lenses.contains(k)
            ? [-3, -2, -1, 1, 2, 3].map { s in changed { Tank.lens($0, rod: rod, steps: -Double(s)) } }
            : (1...11).map { s in changed { Tank.twist($0, rod: rod, angle: -Double(s) * Tank.step) } }
        worst = min(worst, shares.min()!)
        print("rod \(k) \(lenses.contains(k) ? "lens  -3..+3" : "twist 1..11 "): "
              + shares.map { String(format: "%.2f", $0) }.joined(separator: " "))
    }
    print(String(format: "worst %.2f (the test panel's test asks more than 0.15)", worst))
    exit(worst > 0.15 ? 0 : 1)
case "read" where args.count >= 5:
    // How much of each twist rod's disc changes in coarse light under each step: the clean bake at 400 px, blurred
    // over two dot pitches so the screens' dots and every hairline average away, then compared with itself turned,
    // counting points whose gamma-encoded light moves more than 0.2 in a channel. A rod scores its weakest step.
    let p = panel(args[1])
    guard let layout = Layout(rawValue: args[2]) else { fatalError("no layout \(args[2])") }
    let lenses = Set(args[3].split(separator: ",").compactMap { Int($0) })
    let stack = [Twist].parse(args[4], in: layout, lenses: lenses)
    let n = 400, reach = Int((Halftone.pitch * Double(n) / 2).rounded())
    var coarse = p.pixels(n).enumerated().filter { $0.offset % 4 != 3 }.map { Double($0.element) / 255 }
    for _ in 0..<2 {
        for horizontal in [true, false] {
            var out = coarse
            for j in 0..<n {
                for i in 0..<n {
                    for c in 0..<3 {
                        var sum = 0.0
                        for d in -reach...reach {
                            let ii = min(max(horizontal ? i + d : i, 0), n - 1), jj = min(max(horizontal ? j : j + d, 0), n - 1)
                            sum += coarse[3 * (jj * n + ii) + c]
                        }
                        out[3 * (j * n + i) + c] = sum / Double(2 * reach + 1)
                    }
                }
            }
            coarse = out
        }
    }
    func at(_ q: SIMD2<Double>) -> SIMD3<Double> {
        let i = min(max(Int((q.x + 1) / 2 * Double(n)), 0), n - 1), j = min(max(Int((q.y + 1) / 2 * Double(n)), 0), n - 1)
        return SIMD3(coarse[3 * (j * n + i)], coarse[3 * (j * n + i) + 1], coarse[3 * (j * n + i) + 2])
    }
    var worst = 1.0
    for (k, rod) in layout.rods.enumerated() where !lenses.contains(k) && stack.contains(where: { $0.rod == k }) {
        let c = SIMD2(rod.x, rod.y), spacing = 1.0 / 100
        var points: [SIMD2<Double>] = []
        for y in stride(from: -rod.z, through: rod.z, by: spacing) {
            for x in stride(from: -rod.z, through: rod.z, by: spacing) where x * x + y * y < rod.z * rod.z && simd_length(c + SIMD2(x, y)) < 1 {
                points.append(c + SIMD2(x, y))
            }
        }
        let shares = (1...11).map { s -> Double in
            let moved = points.filter { q in
                let d = simd_abs(at(Tank.twist(q, rod: rod, angle: -Double(s) * Tank.step)) - at(q))
                return max(d.x, d.y, d.z) > 0.2
            }
            return Double(moved.count) / Double(points.count)
        }
        worst = min(worst, shares.min()!)
        print("rod \(k) twist 1..11: " + shares.map { String(format: "%.2f", $0) }.joined(separator: " "))
    }
    print(String(format: "weakest %.2f", worst))
    // The order read: a twist over a lens shows where it drags the lens's rim, so for each lens and each twist rod
    // whose disc reaches its core, the share that three steps of the twist change of the band two dot pitches either
    // side of the rim, inside the twist's disc, and that band's size as a share of the whole rim's.
    for (l, lens) in layout.rods.enumerated() where lenses.contains(l) {
        let lc = SIMD2(lens.x, lens.y), rim = Tank.plateau * lens.z, band = 2 * Halftone.pitch
        for (k, rod) in layout.rods.enumerated() where !lenses.contains(k) && stack.contains(where: { $0.rod == k }) {
            let kc = SIMD2(rod.x, rod.y)
            guard simd_distance(lc, kc) < rod.z + rim else { continue }
            var inside = 0, all = 0, moved = 0
            for y in stride(from: -rim - band, through: rim + band, by: 1.0 / 200) {
                for x in stride(from: -rim - band, through: rim + band, by: 1.0 / 200) {
                    let q = lc + SIMD2(x, y)
                    guard abs(simd_length(SIMD2(x, y)) - rim) < band, simd_length(q) < 1 else { continue }
                    all += 1
                    guard simd_distance(q, kc) < rod.z else { continue }
                    inside += 1
                    let d = [-3.0, 3].map { simd_abs(at(Tank.twist(q, rod: rod, angle: -$0 * Tank.step)) - at(q)) }.map { max($0.x, $0.y, $0.z) }
                    if d.min()! > 0.2 { moved += 1 }
                }
            }
            print(String(format: "lens %d under %d: %.2f of the rim's band reached, %.2f of that changed, %.3f of the band",
                         l, k, Double(inside) / Double(all), Double(moved) / Double(max(inside, 1)), Double(moved) / Double(all)))
        }
    }
default:
    print("""
    usage: scripts/lens-panels.sh render <panel> <out.png> [side px] [layout lenses stack]
           scripts/lens-panels.sh time [side px] [panel...]
           scripts/lens-panels.sh check <panel> <layout> [lens slots]
           scripts/lens-panels.sh read <panel> <layout> <lens slots> <scramble>
    panels: \(Halftone.panels.map(\.name).joined(separator: " "))
    """)
    exit(2)
}
