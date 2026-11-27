// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreText
import simd
import UIKit

/// The strand's four voices, as `SlopeVoice` names them, for words drawn off the main thread.
enum StrandVoice: Hashable, Sendable { case place, name, ui, data }

/// A block of words as one bitmap: its lines, each a run of voices, with a row's result marks after the last run.
struct StrandWords: Hashable, Sendable {
    struct Run: Hashable, Sendable {
        var text: String
        var voice = StrandVoice.ui
        var size: CGFloat = 17
        /// `SlopeInk`'s strength.
        var ink = 1.0
        var tracking: CGFloat = 0
        var magenta = false
    }

    struct Line: Hashable, Sendable {
        var runs: [Run]
        var marks: Int?
    }

    var lines: [Line]
    var centred = false
}

/// A rest's water, air and far walls: everything soft, painted a pixel at a time into tiles a screen tall.
struct StrandGround: Hashable, Sendable {
    /// The depth in ledges from plughole's first, which the water's colour counts from, at a height down the column.
    struct Depth: Hashable, Sendable {
        let y: CGFloat
        let m: CGFloat
    }

    let width: CGFloat
    let height: CGFloat
    let surface: CGFloat
    let depths: [Depth]
    /// Where the last tier's water starts going to endless's black.
    let dark: CGFloat
    /// The band from the top painted at the screen's scale, the water line in it; the rest is one pixel a point,
    /// which the compositor stretches.
    let sharp: CGFloat
    let tile: CGFloat

    var tiles: [CGRect] {
        var out = [CGRect(x: 0, y: 0, width: width, height: sharp)], y = sharp
        while y < height {
            out.append(CGRect(x: 0, y: y, width: width, height: min(tile, height - y)))
            y += tile
        }
        return out
    }

    func depth(_ y: CGFloat) -> CGFloat {
        guard let first = depths.first, let last = depths.last else { return 0 }
        if y <= first.y { return first.m }
        for (a, b) in zip(depths, depths.dropFirst()) where y < b.y {
            return a.m + (b.m - a.m) * (y - a.y) / max(b.y - a.y, 1)
        }
        return last.m
    }
}

/// One bitmap of the menu, named by everything that decides its pixels, so a bake is kept for as long as it is true.
enum StrandKey: Hashable, Sendable {
    case ground(StrandGround, Int)
    /// A tier's terrace at the overview, by its rock.
    case terrace(Int)
    /// A dive row's ledge and the wall under it, and the wall alone beside a tier's name.
    case ledge(Int)
    case wall(Int)
    case pebble(rock: Int, lit: Bool, small: Bool)
    case words(StrandWords)
}

/// The sprites' sizes in points, which the plan seats them by.
enum StrandSprite {
    static let terrace = CGSize(width: 176, height: 150)
    /// A terrace's top edge: where it leaves the leading edge, and how steeply it falls to its lip.
    static let terraceTop: CGFloat = 6
    static let terraceFall: CGFloat = 0.47
    static let ledge = CGSize(width: 150, height: 110)
    /// A ledge's lip in its sprite.
    static let lip: CGFloat = 140
    static func pebble(small: Bool) -> CGFloat { small ? 24 : 64 }
}

struct StrandBitmap: @unchecked Sendable {
    let image: CGImage
    /// In points.
    let size: CGSize
    var bytes: Int { image.bytesPerRow * image.height }
}

/// The menu's baked art: drawn once off the main thread, kept by key across every menu the root builds.
final class StrandArt: @unchecked Sendable {
    static let shared = StrandArt()
    private let lock = NSLock()
    private var made: [StrandKey: StrandBitmap] = [:]

    func have(_ keys: some Sequence<StrandKey>) -> [StrandKey: StrandBitmap] {
        lock.withLock {
            var out: [StrandKey: StrandBitmap] = [:]
            for key in keys { out[key] = made[key] }
            return out
        }
    }

    /// Draws what is missing of `keys`, each on a thread of the pool, and returns all of them.
    func bake(_ keys: [StrandKey], scale: CGFloat) async -> [StrandKey: StrandBitmap] {
        let missing = lock.withLock { Set(keys).filter { made[$0] == nil } }
        let drawn = await withTaskGroup(of: (StrandKey, StrandBitmap?).self) { group in
            for key in missing { group.addTask(priority: .userInitiated) { (key, StrandPaint.draw(key, scale: scale)) } }
            var out: [StrandKey: StrandBitmap] = [:]
            for await (key, bitmap) in group { out[key] = bitmap }
            return out
        }
        lock.withLock { made.merge(drawn) { old, _ in old } }
        return have(keys)
    }

    /// Forgets every bitmap no plan asks for now.
    func keep(_ keys: Set<StrandKey>) {
        lock.withLock { made = made.filter { keys.contains($0.key) } }
    }

    var bytes: Int { lock.withLock { made.values.reduce(0) { $0 + $1.bytes } } }
    var count: Int { lock.withLock { made.count } }
}

enum StrandPaint {
    typealias RGB = SIMD3<Float>

    /// Each tier's rock, lit and in shade, and the light its pebbles glow with.
    static let lit: [RGB] = [RGB(0.74, 0.58, 0.42), RGB(0.56, 0.34, 0.56), RGB(0.30, 0.42, 0.68), RGB(0.52, 0.22, 0.16)]
    static let shade: [RGB] = [RGB(0.30, 0.22, 0.17), RGB(0.20, 0.11, 0.22), RGB(0.08, 0.12, 0.24), RGB(0.16, 0.05, 0.05)]
    static let glow: [RGB] = [RGB(1, 0.82, 0.55), RGB(1, 0.62, 0.86), RGB(0.55, 0.76, 1), RGB(1, 0.46, 0.26)]
    static let ink = RGB(0xED, 0xEF, 0xF7) / 255
    static let magenta = RGB(1, 0.36, 0.78)

    static func draw(_ key: StrandKey, scale: CGFloat) -> StrandBitmap? {
        switch key {
        case let .ground(ground, tile): Self.ground(ground, tile, scale: scale)
        case let .terrace(rock): terrace(rock, scale: scale)
        case let .ledge(rock): ledge(rock, wallOnly: false, scale: scale)
        case let .wall(rock): ledge(rock, wallOnly: true, scale: scale)
        case let .pebble(rock, lit, small): pebble(rock, lit: lit, small: small, scale: scale)
        case let .words(words): Self.words(words, scale: scale)
        }
    }

    // MARK: The ground

    static func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }

    static func mix(_ a: RGB, _ b: RGB, _ t: Float) -> RGB { a + (b - a) * t }

    static func hash(_ a: Int32, _ b: Int32) -> Float {
        var h = UInt32(bitPattern: a) &* 0x9E37_79B1 ^ UInt32(bitPattern: b) &* 0x85EB_CA77
        h ^= h >> 15
        h &*= 0x2C1B_3C6D
        h ^= h >> 12
        return Float(h & 0xFF_FFFF) / 16_777_216
    }

    static func noise(_ t: Float, _ seed: Int32) -> Float {
        let i = t.rounded(.down), f = t - i
        return hash(Int32(i), seed) + (hash(Int32(i) + 1, seed) - hash(Int32(i), seed)) * f * f * (3 - 2 * f)
    }

    /// The water's colour by depth in ledges: sunlit green shallows, then each tier's own dark.
    static func water(_ m: Float) -> RGB {
        var c = mix(RGB(0.075, 0.30, 0.31), RGB(0.018, 0.125, 0.165), smooth(-2.8, 11, m))
        c = mix(c, RGB(0.105, 0.03, 0.155), smooth(24, 31, m))
        c = mix(c, RGB(0.02, 0.04, 0.15), smooth(51, 58, m))
        return mix(c, RGB(0.10, 0.016, 0.024), smooth(78, 85, m))
    }

    static func rock(_ m: Float) -> RGB {
        var c = mix(RGB(0.50, 0.36, 0.27), RGB(0.30, 0.165, 0.32), smooth(24, 31, m))
        c = mix(c, RGB(0.12, 0.185, 0.36), smooth(51, 58, m))
        return mix(c, RGB(0.23, 0.075, 0.07), smooth(78, 85, m))
    }

    static func ground(_ g: StrandGround, _ index: Int, scale: CGFloat) -> StrandBitmap? {
        let rect = g.tiles[index], k = Float(index == 0 ? scale : 1)
        let w = Int((Float(rect.width) * k).rounded(.up)), h = Int((Float(rect.height) * k).rounded(.up))
        guard w > 0, h > 0 else { return nil }
        let width = Float(g.width), surface = Float(g.surface), dark = Float(g.dark), top = Float(rect.minY)
        var wave = [Float](repeating: 0, count: w), bank = wave, side = wave
        for i in 0 ..< w {
            let x = (Float(i) + 0.5) / k
            wave[i] = surface + 2.2 * sin(x * 0.031) + 1.4 * sin(x * 0.083 + 1.3)
            bank[i] = exp(-x / 55) * 0.2
            side[i] = 1 - 0.3 * x / width
        }
        var px = [UInt8](repeating: 255, count: w * h * 4)
        px.withUnsafeMutableBufferPointer { out in
            for j in 0 ..< h {
                let y = top + (Float(j) + 0.5) / k
                let m = Float(g.depth(CGFloat(y))), gone = smooth(dark, dark + 260, y)
                let deep = mix(water(m), RGB(0.008, 0.006, 0.014), gone), stone = rock(m) * (1 - gone)
                let far = width * (0.80 + 0.07 * noise(y * 0.006, 7) + 0.03 * noise(y * 0.021, 11))
                let farther = width * (0.94 + 0.05 * noise(y * 0.009, 3))
                let cy = Int32((y / 31).rounded(.down))
                for i in 0 ..< w {
                    let x = (Float(i) + 0.5) / k, d = y - wave[i]
                    var c: RGB
                    if d < 0 {
                        c = mix(RGB(0.03, 0.028, 0.05), RGB(0.60, 0.37, 0.21), exp(d / 62) * 0.8)
                        let dx: Float = (x - 60) * 0.006, dy: Float = d * 0.02
                        let sun: Float = exp(-(dx * dx + dy * dy).squareRoot()) * 0.22
                        c += RGB(0.5, 0.3, 0.12) * sun
                    } else {
                        c = deep * side[i]
                        c *= 1 - 0.28 * smooth(far - 14, far + 14, x)
                        c *= 1 - 0.2 * smooth(farther - 10, farther + 10, x)
                        c += stone * bank[i]
                        if d < 300 {
                            let wide: Float = exp(-d / 46) * 0.16, line: Float = exp(-d / 1.3) * 0.55
                            c += RGB(0.55, 0.50, 0.30) * wide
                            c += RGB(1, 0.9, 0.72) * line
                        }
                        let cx = Int32((x / 31).rounded(.down))
                        if hash(cx, cy) > 0.8 {
                            let mx: Float = (Float(cx) + 0.15 + 0.7 * hash(cx &+ 91, cy)) * 31
                            let my: Float = (Float(cy) + 0.15 + 0.7 * hash(cx, cy &+ 57)) * 31
                            let r: Float = ((x - mx) * (x - mx) + (y - my) * (y - my)).squareRoot()
                            let mote: Float = max(1 - r / 1.2, 0) * 0.16 * (1 - gone)
                            c += RGB(0.7, 0.72, 0.8) * mote
                        }
                    }
                    // Dithered: the deep water's gradients band at eight bits.
                    let grain = (hash(Int32(i), Int32(j) &+ Int32(index) &* 7919) - 0.5) / 255
                    let v: RGB = simd_clamp(c + RGB(repeating: grain), RGB(repeating: 0), RGB(repeating: 1)) * 255 + RGB(repeating: 0.5)
                    let o = (j * w + i) * 4
                    out[o] = UInt8(v.z)
                    out[o + 1] = UInt8(v.y)
                    out[o + 2] = UInt8(v.x)
                }
            }
        }
        guard let provider = CGDataProvider(data: Data(px) as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        return StrandBitmap(image: image, size: rect.size)
    }

    // MARK: Sprites

    /// A bitmap `size` points across at `scale`, drawn with its origin at the top leading corner.
    static func raster(_ size: CGSize, scale: CGFloat, _ draw: (CGContext) -> Void) -> StrandBitmap? {
        let w = Int((size.width * scale).rounded(.up)), h = Int((size.height * scale).rounded(.up))
        guard w > 0, h > 0, let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        else { return nil }
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: scale, y: -scale)
        draw(ctx)
        return ctx.makeImage().map { StrandBitmap(image: $0, size: size) }
    }

    static func colour(_ c: RGB, _ alpha: CGFloat = 1) -> CGColor {
        CGColor(srgbRed: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: alpha)
    }

    static func gradient(_ stops: [(CGFloat, CGColor)]) -> CGGradient {
        CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: stops.map(\.1) as CFArray, locations: stops.map(\.0))!
    }

    static func terrace(_ rock: Int, scale: CGFloat) -> StrandBitmap? {
        let size = StrandSprite.terrace, top = StrandSprite.terraceTop, fall = StrandSprite.terraceFall, reach: CGFloat = 162
        return raster(size, scale: scale) { ctx in
            let lip = CGPoint(x: reach, y: top + reach * fall)
            let body = CGMutablePath()
            body.move(to: CGPoint(x: 0, y: top))
            body.addLine(to: lip)
            body.addQuadCurve(to: CGPoint(x: 0, y: size.height), control: CGPoint(x: 118, y: 108))
            body.closeSubpath()
            ctx.saveGState()
            ctx.addPath(body)
            ctx.clip()
            // Across the edge, so the light lies along the whole of it.
            ctx.drawLinearGradient(gradient([(0, colour(lit[rock], 0.92)), (0.3, colour(shade[rock] * 1.5, 0.6)), (1, colour(shade[rock], 0))]),
                                   start: CGPoint(x: 0, y: top), end: CGPoint(x: -fall * 62, y: top + 62), options: [.drawsAfterEndLocation])
            ctx.restoreGState()
            ctx.setStrokeColor(colour(glow[rock], 0.6))
            ctx.setLineWidth(1.2)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: 0, y: top + 0.6))
            ctx.addLine(to: CGPoint(x: lip.x - 1, y: lip.y + 0.1))
            ctx.strokePath()
        }
    }

    static func ledge(_ rock: Int, wallOnly: Bool, scale: CGFloat) -> StrandBitmap? {
        let size = StrandSprite.ledge, lip = StrandSprite.lip, wall = lip - 44
        return raster(size, scale: scale) { ctx in
            let body = CGMutablePath()
            body.move(to: .zero)
            if wallOnly {
                body.addLine(to: CGPoint(x: wall - 6, y: 0))
            } else {
                body.addLine(to: CGPoint(x: lip - 9, y: 0))
                body.addQuadCurve(to: CGPoint(x: lip, y: 8), control: CGPoint(x: lip, y: 0))
                body.addCurve(to: CGPoint(x: wall + 4, y: 58), control1: CGPoint(x: lip, y: 30), control2: CGPoint(x: wall + 26, y: 46))
            }
            body.addCurve(to: CGPoint(x: wall - 6, y: size.height), control1: CGPoint(x: wall - 12, y: 76), control2: CGPoint(x: wall + 4, y: 94))
            body.addLine(to: CGPoint(x: 0, y: size.height))
            body.closeSubpath()
            ctx.saveGState()
            ctx.addPath(body)
            ctx.clip()
            let face: [(CGFloat, CGColor)] = wallOnly ? [(0, colour(shade[rock] * 0.9)), (1, colour(shade[rock] * 0.8))]
                : [(0, colour(lit[rock] * 0.9)), (0.1, colour(mix(lit[rock], shade[rock], 0.45))), (0.5, colour(shade[rock] * 1.15)), (1, colour(shade[rock] * 0.9))]
            ctx.drawLinearGradient(gradient(face), start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            // The wall goes into shadow toward the leading edge.
            ctx.drawLinearGradient(gradient([(0, CGColor(gray: 0, alpha: 0.45)), (1, CGColor(gray: 0, alpha: 0))]),
                                   start: .zero, end: CGPoint(x: wall, y: 0), options: [])
            ctx.restoreGState()
            guard !wallOnly else { return }
            ctx.setStrokeColor(colour(glow[rock], 0.45))
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: wall - 30, y: 0.5))
            ctx.addLine(to: CGPoint(x: lip - 8, y: 0.5))
            ctx.strokePath()
        }
    }

    static func pebble(_ rock: Int, lit: Bool, small: Bool, scale: CGFloat) -> StrandBitmap? {
        let side = StrandSprite.pebble(small: small), mid = CGPoint(x: side / 2, y: side / 2)
        let rx: CGFloat = small ? (lit ? 4.6 : 3.2) : (lit ? 12 : 9), ry = rx * 0.72
        return raster(CGSize(width: side, height: side), scale: scale) { ctx in
            if lit {
                ctx.drawRadialGradient(gradient([(0, colour(glow[rock], 0.5)), (0.45, colour(glow[rock], 0.16)), (1, colour(glow[rock], 0))]),
                                       startCenter: mid, startRadius: 0, endCenter: mid, endRadius: side / 2, options: [])
            }
            let stone = CGRect(x: mid.x - rx, y: mid.y - ry, width: rx * 2, height: ry * 2)
            ctx.saveGState()
            ctx.addEllipse(in: stone)
            ctx.clip()
            let high = CGPoint(x: mid.x - rx * 0.3, y: mid.y - ry * 0.45)
            ctx.drawRadialGradient(gradient(lit ? [(0, colour(RGB(1, 0.975, 0.9))), (1, colour(RGB(0.78, 0.70, 0.56)))]
                                       : [(0, colour(RGB(0.36, 0.40, 0.46))), (1, colour(RGB(0.15, 0.17, 0.21)))]),
                                   startCenter: high, startRadius: 0, endCenter: high, endRadius: rx * 1.5, options: [.drawsAfterEndLocation])
            ctx.restoreGState()
        }
    }

    // MARK: Words

    static func font(_ voice: StrandVoice, _ size: CGFloat) -> CTFont {
        switch voice {
        case .place:
            let light = UIFont.systemFont(ofSize: size, weight: .light).fontDescriptor
            let serif = light.withDesign(.serif).flatMap { $0.withSymbolicTraits(.traitItalic) }
            return UIFont(descriptor: serif ?? light, size: size)
        case .name: return UIFont.systemFont(ofSize: size, weight: .light)
        case .ui: return UIFont.systemFont(ofSize: size, weight: .regular)
        case .data: return UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }

    static func words(_ words: StrandWords, scale: CGFloat) -> StrandBitmap? {
        let pad: CGFloat = 3, gap: CGFloat = 3, disc: CGFloat = 8
        struct Set { let line: CTLine; let width, ascent, descent: CGFloat; let marks: Int? }
        let sets: [Set] = words.lines.map { line in
            let text = NSMutableAttributedString()
            for run in line.runs {
                text.append(NSAttributedString(string: run.text, attributes: [
                    NSAttributedString.Key(kCTFontAttributeName as String): font(run.voice, run.size),
                    NSAttributedString.Key(kCTForegroundColorAttributeName as String): colour(run.magenta ? magenta : ink, run.ink),
                    NSAttributedString.Key(kCTKernAttributeName as String): run.tracking,
                ]))
            }
            let set = CTLineCreateWithAttributedString(text)
            var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
            let width = CGFloat(CTLineGetTypographicBounds(set, &ascent, &descent, &leading))
            return Set(line: set, width: width + (line.marks == nil ? 0 : 10 + disc * 3 + 8), ascent: ascent, descent: descent + leading, marks: line.marks)
        }
        let width = (sets.map(\.width).max() ?? 0).rounded(.up) + pad * 2
        let height = (sets.reduce(0) { $0 + $1.ascent + $1.descent } + gap * CGFloat(max(sets.count - 1, 0))).rounded(.up) + pad * 2
        return raster(CGSize(width: width, height: height), scale: scale) { ctx in
            var y = pad
            ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            for set in sets {
                let x = words.centred ? (width - set.width) / 2 : pad, base = y + set.ascent
                ctx.textPosition = CGPoint(x: x, y: base)
                CTLineDraw(set.line, ctx)
                if let marks = set.marks {
                    let left = x + set.width - disc * 3 - 8, mid = base - set.ascent * 0.36
                    for i in 0 ..< 3 {
                        let dot = CGRect(x: left + CGFloat(i) * (disc + 4), y: mid - disc / 2, width: disc, height: disc)
                        if i < marks {
                            ctx.setFillColor(colour(ink))
                            ctx.fillEllipse(in: dot)
                        } else {
                            ctx.setStrokeColor(colour(ink, 0.4))
                            ctx.setLineWidth(1)
                            ctx.strokeEllipse(in: dot.insetBy(dx: 0.5, dy: 0.5))
                        }
                    }
                }
                y += set.ascent + set.descent + gap
            }
        }
    }
}
