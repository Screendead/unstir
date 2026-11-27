// Copyright © 2026 Jack Lusher. All rights reserved.

import UIKit

/// One baked bitmap's place in a rest: `pin`, a unit point of the bitmap, goes at `at` in the rest's own points.
struct StrandPiece: Sendable {
    let key: StrandKey
    let at: CGPoint
    var pin = CGPoint.zero
    var scale: CGFloat = 1
}

/// What a tap in a rest does, and the pebble it opens from.
struct StrandHit {
    enum What {
        case level(Level)
        case daily(Level)
        case tier(Int)
        case endless
    }

    let rect: CGRect
    let what: What
    let from: CGPoint
}

/// A rest laid out: every bitmap back to front, where a tap lands, and where each tier starts.
struct StrandRest {
    var height: CGFloat = 0
    var pieces: [StrandPiece] = []
    var hits: [StrandHit] = []
    var tops: [CGFloat] = []
    /// Each dive row's ledge, by its level's id.
    var rows: [String: CGFloat] = [:]
}

/// The menu's two rests for one model on one screen (docs/slope.md, 2): the overview, the whole column about two and
/// a half screens tall, and the dive, a row a level. Only arithmetic: no text is measured, so it is made on the main
/// thread before any art exists.
struct StrandPlan {
    let size: CGSize
    let overview: StrandRest
    let dive: StrandRest
    static let surfaceWords = StrandKey.words(StrandWords(lines: [.init(runs: [
        .init(text: String(localized: "\u{2191} surface", comment: "The slope's menu, in the dive: rises to the whole column"), size: 17),
    ])]))

    var keys: [StrandKey] { overview.pieces.map(\.key) + dive.pieces.map(\.key) + [Self.surfaceWords] }

    init(_ model: StrandModel, size: CGSize, top: CGFloat, bottom: CGFloat) {
        self.size = size
        overview = Self.overview(model, size: size, top: top, bottom: bottom)
        dive = Self.dive(model, size: size, top: top, bottom: bottom)
    }

    private static func ground(_ rest: inout StrandRest, size: CGSize, surface: CGFloat, depths: [StrandGround.Depth], dark: CGFloat) {
        let ground = StrandGround(width: size.width.rounded(.up), height: rest.height.rounded(.up), surface: surface, depths: depths, dark: dark,
                                  sharp: (surface + 40).rounded(.up), tile: size.height.rounded(.down))
        rest.pieces.insert(contentsOf: ground.tiles.enumerated().map { StrandPiece(key: .ground(ground, $0.offset), at: $0.element.origin) }, at: 0)
    }

    private static func overview(_ model: StrandModel, size: CGSize, top: CGFloat, bottom: CGFloat) -> StrandRest {
        var rest = StrandRest()
        let u = max(size.height / 926, 0.8), surface = (top + 84).rounded(), words = (size.width * 0.42).rounded()
        let first = surface + 250 * u, tier = 470 * u, terrace = 160 * u
        rest.pieces.append(StrandPiece(key: .words(StrandWords(lines: [.init(runs: [.init(text: "UNSTIR", voice: .name, size: 28, tracking: 9)])])), // loc: verbatim the wordmark
                                       at: CGPoint(x: 30, y: top + 20)))
        if let daily = model.daily {
            let lip = CGPoint(x: 150, y: surface + 46), pebble = CGPoint(x: lip.x - 10, y: lip.y - 9)
            rest.pieces.append(StrandPiece(key: .terrace(0), at: CGPoint(x: lip.x - 162, y: lip.y - StrandSprite.terraceTop - 162 * StrandSprite.terraceFall)))
            rest.pieces.append(StrandPiece(key: .pebble(rock: 0, lit: true, small: false), at: pebble, pin: CGPoint(x: 0.5, y: 0.5), scale: 0.7))
            var lines = [StrandWords.Line(runs: [.init(text: String(localized: "today"), voice: .place, size: 22)]),
                         StrandWords.Line(runs: [.init(text: daily.level.title, size: 15, ink: 0.9)], marks: daily.marks)]
            if let under = daily.under { lines.append(.init(runs: [.init(text: under, voice: .data, size: 13, ink: 0.84)])) }
            rest.pieces.append(StrandPiece(key: .words(StrandWords(lines: lines)), at: CGPoint(x: words, y: surface + 18)))
            rest.hits.append(StrandHit(rect: CGRect(x: 0, y: surface + 10, width: size.width, height: 72), what: .daily(daily.level), from: pebble))
            if let archive = model.archive {
                rest.pieces.append(StrandPiece(key: .words(StrandWords(lines: [
                    .init(runs: [.init(text: String(localized: "Archive"), size: 15, ink: 0.66)]),
                    .init(runs: [.init(text: archive, size: 13, ink: 0.66)]),
                ])), at: CGPoint(x: words, y: surface + 96)))
            }
        }
        for (k, rows) in model.tiers.enumerated() {
            let y = first + CGFloat(k) * tier
            rest.tops.append(y)
            for (t, group) in stride(from: 0, to: rows.rows.count, by: 9).map({ Array(rows.rows[$0 ..< min($0 + 9, rows.rows.count)]) }).enumerated() {
                let edge = y + CGFloat(t) * terrace
                rest.pieces.append(StrandPiece(key: .terrace(k), at: CGPoint(x: 0, y: edge - StrandSprite.terraceTop)))
                for (i, row) in group.enumerated() {
                    let x = 38 + 13.5 * CGFloat(i)
                    rest.pieces.append(StrandPiece(key: .pebble(rock: k, lit: row.lit, small: true),
                                                   at: CGPoint(x: x, y: edge + x * StrandSprite.terraceFall - 3), pin: CGPoint(x: 0.5, y: 0.5)))
                }
            }
            let ink = rows.open ? 1 : 0.66
            var lines = [StrandWords.Line(runs: [.init(text: rows.word, voice: .place, size: 22, ink: ink)]),
                         StrandWords.Line(runs: [.init(text: rows.under, voice: .data, size: 13, ink: rows.open ? 0.84 : 0.66)])]
            if let way = model.way, way.tier == k {
                lines.append(.init(runs: [.init(text: way.level.label + "  ", voice: .data, size: 15, ink: 0.9),
                                          .init(text: way.level.title + " \u{203A}", voice: .name, size: 17)]))
                let x = 38 + 13.5 * CGFloat(min(8, max(0, (rows.rows.firstIndex { $0.frontier } ?? 0) % 9)))
                let edge = y + CGFloat((rows.rows.firstIndex { $0.frontier } ?? 0) / 9) * terrace
                rest.hits.append(StrandHit(rect: CGRect(x: words - 8, y: y + 34, width: size.width - words + 8, height: 40), what: .level(way.level),
                                           from: CGPoint(x: x, y: edge + x * StrandSprite.terraceFall - 3)))
            }
            rest.pieces.append(StrandPiece(key: .words(StrandWords(lines: lines)), at: CGPoint(x: words, y: y - 14)))
            rest.hits.append(StrandHit(rect: CGRect(x: 0, y: y - 30, width: size.width, height: tier), what: .tier(k), from: CGPoint(x: 38, y: y)))
        }
        let last = first + CGFloat(model.tiers.count) * tier
        if model.daily != nil {
            var lines = [StrandWords.Line(runs: [.init(text: String(localized: "endless", comment: "The slope's menu: endless, written as a place under the last ledge"),
                                                       voice: .place, size: 28)])]
            if let line = model.endlessLine { lines.append(.init(runs: [.init(text: line, voice: .data, size: 13, ink: 0.84)])) }
            let at = CGPoint(x: (size.width * 0.55).rounded(), y: last + 20)
            rest.pieces.append(StrandPiece(key: .words(StrandWords(lines: lines, centred: true)), at: at, pin: CGPoint(x: 0.5, y: 0)))
            rest.hits.insert(StrandHit(rect: CGRect(x: at.x - 110, y: at.y - 16, width: 220, height: 90), what: .endless, from: CGPoint(x: at.x, y: at.y + 20)), at: 0)
        }
        rest.height = (last + 110 * u + bottom).rounded(.up)
        ground(&rest, size: size, surface: surface, depths: [.init(y: surface, m: -3)] + (0 ... model.tiers.count).map {
            .init(y: first + CGFloat($0) * tier, m: CGFloat($0) * 27)
        }, dark: last - 70 * u)
        return rest
    }

    private static func dive(_ model: StrandModel, size: CGSize, top: CGFloat, bottom: CGFloat) -> StrandRest {
        var rest = StrandRest(), depths = [StrandGround.Depth]()
        let surface = (top + 84).rounded(), pitch = StrandSprite.ledge.height
        var y = surface + 60
        depths.append(.init(y: surface, m: -3))
        for (k, rows) in model.tiers.enumerated() {
            rest.tops.append(y)
            rest.pieces.append(StrandPiece(key: .wall(k), at: CGPoint(x: 96 - StrandSprite.lip, y: y)))
            rest.pieces.append(StrandPiece(key: .words(StrandWords(lines: [
                .init(runs: [.init(text: rows.word, voice: .place, size: 28, ink: rows.open ? 1 : 0.66)]),
                .init(runs: [.init(text: rows.under, voice: .data, size: 13, ink: rows.open ? 0.84 : 0.66)]),
            ])), at: CGPoint(x: 112, y: y + pitch / 2), pin: CGPoint(x: 0, y: 0.5)))
            y += pitch
            depths.append(.init(y: y, m: CGFloat(k) * 27))
            for (i, row) in rows.rows.enumerated() {
                let lip = 96 + 5 * CGFloat(i % 9), pebble = CGPoint(x: lip - 18, y: y - (row.lit ? 7 : 5)), ink = row.open ? 1 : 0.66
                rest.rows[row.level.id] = y
                rest.pieces.append(StrandPiece(key: .ledge(k), at: CGPoint(x: lip - StrandSprite.lip, y: y)))
                rest.pieces.append(StrandPiece(key: .pebble(rock: k, lit: row.lit, small: false), at: pebble, pin: CGPoint(x: 0.5, y: 0.5),
                                               scale: row.frontier ? 1.375 : 1))
                rest.pieces.append(StrandPiece(key: .words(StrandWords(lines: [
                    .init(runs: [.init(text: row.number + "  ", voice: .data, size: row.frontier ? 17 : 15, ink: 0.9 * ink),
                                 .init(text: row.name, voice: .name, size: row.frontier ? 28 : 20, ink: ink)]
                              + (row.margin.map { [.init(text: "  " + $0, size: 13, magenta: true)] } ?? []), marks: row.marks),
                    .init(runs: [.init(text: row.facts, voice: .data, size: 13, ink: 0.84 * ink)]),
                ])), at: CGPoint(x: lip + 18, y: y + 6), pin: CGPoint(x: 0, y: 0.5)))
                if row.open {
                    rest.hits.append(StrandHit(rect: CGRect(x: 0, y: y - 50, width: size.width, height: pitch - 10), what: .level(row.level), from: pebble))
                }
                y += pitch
            }
            depths.append(.init(y: y - pitch, m: CGFloat(k) * 27 + CGFloat(rows.rows.count - 1)))
        }
        if model.daily != nil {
            var lines = [StrandWords.Line(runs: [.init(text: String(localized: "endless", comment: "The slope's menu: endless, written as a place under the last ledge"),
                                                       voice: .place, size: 34)])]
            if let line = model.endlessLine { lines.append(.init(runs: [.init(text: line, voice: .data, size: 13, ink: 0.84)])) }
            let at = CGPoint(x: (size.width / 2).rounded(), y: y + 150)
            rest.pieces.append(StrandPiece(key: .words(StrandWords(lines: lines, centred: true)), at: at, pin: CGPoint(x: 0.5, y: 0)))
            rest.hits.append(StrandHit(rect: CGRect(x: at.x - 120, y: at.y - 20, width: 240, height: 100), what: .endless, from: CGPoint(x: at.x, y: at.y + 24)))
        }
        rest.height = (y + 360 + bottom).rounded(.up)
        depths.append(.init(y: y + 110, m: 110))
        ground(&rest, size: size, surface: surface, depths: depths, dark: y - 40)
        return rest
    }
}

/// What the menu did on the main thread, for a tour to log: while it moves, only the scroll view's own callbacks.
@MainActor enum StrandCount {
    /// `layoutSubviews` of the menu's own view, and of a column, which UIKit calls for every scrolled frame.
    static var layouts = 0
    static var columnLayouts = 0
    static var scrolls = 0
    /// `updateUIView`, and the times it read the model again.
    static var updates = 0
    static var reads = 0
    /// Layers built, bitmaps set as a layer's contents, bakes started, and layers asked to draw themselves.
    static var layers = 0
    static var fills = 0
    static var bakes = 0
    static var displays = 0

    static var all: [Int] { [layouts, columnLayouts, scrolls, updates, reads, layers, fills, bakes, displays] }

    /// Each count's rise since `mark`, an earlier `all`.
    static func since(_ mark: [Int]) -> String {
        zip(["layouts", "column layouts", "scrolls", "updates", "reads", "layers", "fills", "bakes", "displays"], zip(all, mark))
            .map { "\($0) \($1.0 - $1.1)" }.joined(separator: ", ")
    }
}

/// A layer that only ever holds a baked bitmap: it counts any call to draw itself, which nothing should make.
final class StrandLayer: CALayer {
    override func display() {
        MainActor.assumeIsolated { StrandCount.displays += 1 }
        super.display()
    }

    // Standalone layers animate a change of contents or frame by default: a frame drawn at rest.
    override func action(forKey event: String) -> (any CAAction)? { nil }
}

/// A rest on the screen: a native scroll view over one layer per piece, each holding a bitmap baked elsewhere.
/// Scrolling moves the layers in the render server; nothing here runs for a frame but UIKit's own scroll.
final class StrandColumn: UIScrollView {
    let rest: StrandRest
    var onHit: ((StrandHit, CGPoint) -> Void)?
    private let content = UIView()
    private var layers: [StrandLayer] = []
    private var filled: [Bool]
    private let pixel: CGFloat

    init(_ rest: StrandRest, size: CGSize, scale: CGFloat) {
        self.rest = rest
        pixel = scale
        filled = Array(repeating: false, count: rest.pieces.count)
        super.init(frame: CGRect(origin: .zero, size: size))
        contentInsetAdjustmentBehavior = .never
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        delaysContentTouches = false
        alwaysBounceVertical = true
        scrollsToTop = false
        backgroundColor = .clear
        // A fade then fades each bitmap, with no off-screen pass for the whole column; and unclipped, a column
        // scaled down in a travel still covers the screen above and below.
        layer.allowsGroupOpacity = false
        content.layer.allowsGroupOpacity = false
        clipsToBounds = false
        content.frame = CGRect(x: 0, y: 0, width: size.width, height: rest.height)
        content.isUserInteractionEnabled = false
        contentSize = content.frame.size
        addSubview(content)
        for piece in rest.pieces {
            let layer = StrandLayer()
            layer.anchorPoint = piece.pin
            if case .ground = piece.key { layer.isOpaque = true }
            content.layer.addSublayer(layer)
            layers.append(layer)
        }
        StrandCount.layers += layers.count
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    var whole: Bool { filled.allSatisfy { $0 } }
    var count: Int { rest.pieces.count }

    /// Hands each piece of `range` its bitmap, if `art` has it and it has none yet.
    func fill(_ art: [StrandKey: StrandBitmap], _ range: Range<Int>) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for i in range where !filled[i] {
            let piece = rest.pieces[i]
            guard let bitmap = art[piece.key] else { continue }
            let size = CGSize(width: bitmap.size.width * piece.scale, height: bitmap.size.height * piece.scale)
            // On whole pixels, so a bitmap is never resampled at rest and the ground's tiles meet.
            let x = ((piece.at.x - piece.pin.x * size.width) * pixel).rounded() / pixel
            let y = ((piece.at.y - piece.pin.y * size.height) * pixel).rounded() / pixel
            layers[i].bounds = CGRect(origin: .zero, size: size)
            layers[i].position = CGPoint(x: x + piece.pin.x * size.width, y: y + piece.pin.y * size.height)
            layers[i].contents = bitmap.image
            filled[i] = true
            StrandCount.fills += 1
        }
        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        StrandCount.columnLayouts += 1
    }

    @objc private func tapped(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: content)
        guard let hit = rest.hits.first(where: { $0.rect.contains(point) }) else { return }
        onHit?(hit, content.convert(hit.from, to: superview))
    }

    /// The offset that puts the rest's `y` at `share` of the screen's height, kept inside what scrolls.
    func offset(for y: CGFloat, at screen: CGFloat) -> CGFloat {
        min(max(y - screen, 0), max(rest.height - bounds.height, 0))
    }
}
