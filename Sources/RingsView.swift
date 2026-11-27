// Copyright © 2026 Jack Lusher. All rights reserved.

import UIKit

/// A layer that never animates a change by itself: every move is the engine's.
final class RingsLayer: CALayer {
    override func action(forKey event: String) -> CAAction? { nil }
}

/// What the main thread did for the menu, counted so a tour can say that a rest cost nothing.
@MainActor enum RingsCount {
    static var layouts = 0, updates = 0, reads = 0, builds = 0, bakes = 0, scrolls = 0

    static var all: [Int] { [layouts, updates, reads, builds, bakes, scrolls] }

    static func since(_ mark: [Int]) -> String {
        zip(["layouts", "updates", "model reads", "builds", "bakes", "scroll callbacks"], zip(all, mark))
            .map { "\($0) \($1.0 - $1.1)" }.joined(separator: ", ")
    }
}

/// Where everything stands on a screen, from its size and insets alone. The mock is 440 by 956; a smaller screen
/// draws the ring, the sun and the orbits in, and leaves every word and bead its size.
struct RingsPlan: Equatable {
    /// A finger's travel from one ring to the next.
    static let pitch: CGFloat = 240

    let size: CGSize
    let top, bottom: CGFloat
    let k: CGFloat
    /// The ring's centre, and its beads' distance from it.
    let centre: CGPoint
    let radius: CGFloat
    let horizon: CGFloat

    init(size: CGSize, top: CGFloat, bottom: CGFloat) {
        self.size = size
        self.top = top
        self.bottom = bottom
        let room = size.height - top - bottom
        k = min(1, size.width / 440, room / 860)
        centre = CGPoint(x: size.width / 2, y: (top + room * 0.465).rounded())
        radius = 190 * k
        horizon = (centre.y + RingsLook.set * k).rounded()
    }

    /// Bead `i` of `n`, from the centre: the seam between the last and the first is at the top.
    func bead(_ i: Int, of n: Int) -> CGPoint {
        let a = -CGFloat.pi / 2 + (CGFloat(i) + 0.5) * 2 * .pi / CGFloat(max(n, 1))
        return CGPoint(x: radius * cos(a), y: radius * sin(a))
    }

    /// The daily's orbit over the ring, and its star on it.
    var orbit: CGFloat { 300 * k }
    var daily: CGPoint { CGPoint(x: centre.x, y: centre.y - orbit) }

    /// Cover `i` of `n`, on the orbit under the ring.
    func cover(_ i: Int, of n: Int) -> CGPoint {
        let a = CGFloat.pi / 2 + 0.41 * (CGFloat(n - 1) / 2 - CGFloat(i))
        return CGPoint(x: centre.x + 304 * k * cos(a), y: centre.y + 304 * k * sin(a))
    }

    var packsLine: CGPoint { CGPoint(x: centre.x, y: centre.y + 422 * k) }
    var settings: CGPoint { CGPoint(x: centre.x, y: size.height - bottom - 10) }
    var wordmark: CGPoint { CGPoint(x: centre.x, y: top + 24) }
}

/// A ring at a depth from the one in front: 0 forward, positive deeper, negative passed. The one rule of the swipe,
/// which a finger, the pager's glide and the tour all go through.
struct RingsPose {
    let scale, beads, words, sun: CGFloat

    init(depth d: CGFloat) {
        scale = d >= 0 ? pow(0.78, d) : pow(1.5, -d)
        beads = d >= 0 ? 1 - min(max((d - 0.05) / 0.65, 0), 1) : max(0, 1 + d * 1.25)
        words = max(0, 1 - 2.2 * abs(d))
        sun = max(0, 1 - abs(d))
    }
}

/// The rings' menu (docs/rings.md): layers that hold bitmaps baked once (`RingsArt`), moved only by transform and
/// opacity. A hidden paging scroll view is the swipe; nothing here draws, and at rest nothing runs.
final class RingsView: UIView, UIScrollViewDelegate {
    /// What the root hands down that can change what the menu shows.
    struct State: Equatable {
        var revision: Int
        var day: Date?
        /// The store's settled state, as one number.
        var store: Int
    }

    enum Hit: Equatable {
        case settings, daily, cover(Int), bead(Int), middle, nothing
    }

    var onPick: (Level) -> Void = { _ in }
    var onOffer: (Offer) -> Void = { _ in }
    var onSettings: () -> Void = {}
    /// The tour's: a scripted glide has ended.
    var glided: (() -> Void)?

    private var state: State
    private(set) var model: RingsModel?
    private(set) var plan: RingsPlan?
    /// Every bitmap is on its layer.
    private(set) var whole = false
    /// The ring in front, or the nearer of two mid-swipe.
    private(set) var at: Int
    /// The bead named in the middle, of the ring in front.
    private(set) var picked: Int?

    private struct Seat {
        let piece: RingsPiece
        let layer: CALayer
        let at: CGPoint
        var size: CGSize?
        var turn: CGFloat = 0
    }

    private struct Ring {
        let whole = RingsLayer(), beads = RingsLayer(), words = RingsLayer(), rest = RingsLayer(), pick = RingsLayer()
        let sun = RingsLayer(), halo = RingsLayer()
        let under = RingsLayer(), pair = RingsLayer(), cue = RingsLayer()
        var dim: CGFloat = 1
    }

    private let pager = UIScrollView()
    private let scene = RingsLayer()
    private var seats: [Seat] = []
    private var rings: [Ring] = []
    private var ground: [(RingsGround, CALayer)] = []
    private var baking: Task<Void, Never>?
    private var picking: Task<Void, Never>?
    private var inset: CGFloat = -1

    /// The display's fastest: Core Animation otherwise gives an animation 60 frames a second on a phone.
    static let fast = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)

    init(state: State, opening: Int) {
        self.state = state
        at = opening
        super.init(frame: .zero)
        backgroundColor = RingsLook.backdrop
        scene.opacity = 0
        layer.addSublayer(scene)
        pager.isPagingEnabled = true
        pager.showsVerticalScrollIndicator = false
        pager.showsHorizontalScrollIndicator = false
        pager.contentInsetAdjustmentBehavior = .never
        pager.scrollsToTop = false
        pager.alwaysBounceVertical = true
        pager.isUserInteractionEnabled = false
        pager.delegate = self
        addSubview(pager)
        // The pager is only its physics: its pan listens on the whole menu, and it shows nothing.
        addGestureRecognizer(pager.panGestureRecognizer)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        RingsCount.layouts += 1
        let top = window?.safeAreaInsets.top ?? safeAreaInsets.top
        guard !bounds.isEmpty, window != nil, bounds.size != plan?.size || top != inset else { return }
        inset = top
        build()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    func update(_ next: State) {
        guard next != state else { return }
        state = next
        if plan != nil { build() }
    }

    // MARK: The layers

    /// Reads the model and, where what it shows or the screen has changed, lays the layers out again and bakes what
    /// is new. Seam for step two: the archive's and endless's rings are two more entries of `model.rings`.
    private func build() {
        RingsCount.reads += 1
        let model = RingsModel(today: state.day ?? .now)
        let plan = RingsPlan(size: bounds.size, top: inset, bottom: window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom)
        guard model != self.model || plan != self.plan else { return }
        RingsCount.builds += 1
        self.model = model
        self.plan = plan
        picked = nil
        picking?.cancel()
        let was = rings.isEmpty ? -1 : rings.count
        seats = []
        ground = []
        scene.sublayers = nil
        scene.frame = bounds
        let scale = window?.screen.scale ?? traitCollection.displayScale

        let back = RingsLayer(), suns = RingsLayer(), front = RingsLayer(), well = RingsLayer(), chrome = RingsLayer()
        for layer in [back, suns, front, well, chrome] { scene.addSublayer(layer) }
        for g in RingsLook.ground(width: plan.size.width, height: plan.size.height, horizon: plan.horizon) {
            let layer = RingsLayer(), parent = g.front ? front : back
            if g.eye > 0 {
                // The window's anchor is the vanishing point: the middle of its top edge.
                let window = RingsLayer()
                window.anchorPoint = CGPoint(x: 0.5, y: 0)
                window.frame = CGRect(x: g.x, y: g.y, width: g.width, height: g.height)
                window.masksToBounds = true
                var eye = CATransform3DIdentity
                eye.m34 = -1 / g.eye
                window.sublayerTransform = eye
                layer.anchorPoint = CGPoint(x: 0.5, y: 1)
                layer.minificationFilter = .trilinear
                window.addSublayer(layer)
                parent.addSublayer(window)
                seats.append(Seat(piece: .ground(g), layer: layer, at: CGPoint(x: g.width / 2, y: g.height),
                                  size: CGSize(width: g.spread, height: g.bakedHeight)))
            } else {
                parent.addSublayer(layer)
                seats.append(Seat(piece: .ground(g), layer: layer, at: CGPoint(x: g.x + g.width / 2, y: g.y + g.height / 2),
                                  size: CGSize(width: g.width, height: g.height)))
            }
            ground.append((g, layer))
        }

        rings = model.rings.enumerated().map { i, ring in
            var made = Ring()
            made.dim = RingsLook.dim(shut: !ring.open)
            made.whole.position = plan.centre
            // Faded by its sprites' own alphas, so a fading ring is never composited off screen first.
            for group in [made.beads, made.words, made.rest, made.pick] { group.allowsGroupOpacity = false }
            well.addSublayer(made.whole)
            made.whole.addSublayer(made.beads)
            made.whole.addSublayer(made.words)
            made.sun.position = plan.centre
            suns.addSublayer(made.sun)
            let side = 400 * plan.k
            seats.append(Seat(piece: .sun(ring.tier, shut: !ring.open), layer: made.sun, at: plan.centre, size: CGSize(width: side, height: side)))

            let n = ring.spots.count, spots = (0 ..< n).map { plan.bead($0, of: n) }
            for j in 0 ..< n where n > 1 {
                let a = spots[j], b = spots[(j + 1) % n]
                seat(.link(ring.tier), CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2), in: made.beads,
                     size: CGSize(width: hypot(b.x - a.x, b.y - a.y), height: 3), turn: atan2(b.y - a.y, b.x - a.x))
            }
            for (j, spot) in ring.spots.enumerated() {
                seat(.bead(ring.tier, spot.bead), spots[j], in: made.beads)
                seat(.text(Self.numeral(spot, ring.tier)), CGPoint(x: spots[j].x, y: spots[j].y + 0.5), in: made.beads)
            }
            made.beads.addSublayer(made.halo)
            made.halo.opacity = 0
            seats.append(Seat(piece: .halo, layer: made.halo, at: .zero))

            for text in Self.cues(model, i, radius: 163 * plan.k) { seat(.text(text), .zero, in: made.words) }
            if ring.open, let way = ring.way {
                seat(.text(RingsText(ring.word, .word, 38, .deep, .medium)), CGPoint(x: 0, y: -76), in: made.words)
                made.words.addSublayer(made.rest)
                made.words.addSublayer(made.pick)
                made.pick.opacity = 0
                let named = Self.named(ring.spots[way], under: ring.under)
                seat(.text(named.under), Self.under, in: made.rest)
                seat(.text(named.pair), Self.pair, in: made.rest)
                seat(.play, Self.cue, in: made.rest)
                for layer in [made.under, made.pair, made.cue] { made.pick.addSublayer(layer) }
            } else {
                seat(.text(RingsText(ring.word, .word, 38, .ink(0.2), .light, finish: .unlit(ring.tier))), CGPoint(x: 0, y: -34), in: made.words)
                seat(.text(RingsText(ring.under, .name, 16, .ink(0.7), wrap: 230)), CGPoint(x: 0, y: 20), in: made.words)
            }
            return made
        }

        seat(.wordmark, plan.wordmark, in: chrome)
        if let daily = model.daily {
            seat(.daily, plan.daily, in: chrome)
            seat(.text(RingsText(daily.title, .name, 16, .ink(0.96), tracking: 0.3,
                                 arc: .init(radius: plan.orbit, angle: -.pi / 2, lead: 30, side: -1))), plan.centre, in: chrome)
            if let under = daily.under {
                seat(.text(RingsText(under, .name, 16, .ink(0.58), tracking: 0.3,
                                     arc: .init(radius: plan.orbit, angle: -.pi / 2, lead: 30, side: 1))), plan.centre, in: chrome)
            }
        }
        for (i, cover) in model.covers.enumerated() {
            let c = plan.cover(i, of: model.covers.count), foot = RingsPaint.coverWidth / 2
            seat(.cover(cover.pack), c, in: chrome)
            seat(.text(RingsText(cover.name, .name, 16, .ink(0.96), finish: .shadowed)), CGPoint(x: c.x, y: c.y + foot + 20), in: chrome)
            if let line = cover.line {
                seat(.text(RingsText(line, .data, 12, cover.lit ? .gold : .ink(0.8), finish: .shadowed)),
                     CGPoint(x: c.x, y: c.y + foot + 39), in: chrome)
            }
        }
        if let line = model.packsLine {
            seat(.text(RingsText(line, .data, 12, .ink(0.8), tracking: 0.4, finish: .shadowed)), plan.packsLine, in: chrome)
        }
        seat(.settings, plan.settings, in: chrome)

        // A menu built again mid-swipe (a purchase landing, the store's first read) stays where the finger has it.
        let place = was == rings.count ? pager.contentOffset.y / RingsPlan.pitch : CGFloat(min(max(at, 0), max(rings.count - 1, 0)))
        pager.delegate = nil
        pager.frame = CGRect(x: 0, y: 0, width: bounds.width, height: RingsPlan.pitch)
        pager.contentSize = CGSize(width: bounds.width, height: RingsPlan.pitch * CGFloat(rings.count))
        pager.contentOffset = CGPoint(x: 0, y: RingsPlan.pitch * place)
        pager.delegate = self
        at = min(max(Int(place.rounded()), 0), max(rings.count - 1, 0))
        apply(place)

        let art = RingsArt.shared, pieces = Set(seats.map(\.piece)), have = art.have(pieces)
        whole = false
        baking?.cancel()
        if have.count == pieces.count {
            landed(have, pieces)
        } else {
            RingsCount.bakes += 1
            baking = Task { [weak self] in
                let all = await art.bake(pieces, scale: scale)
                guard !Task.isCancelled else { return }
                self?.landed(all, pieces)
            }
        }
    }

    private func seat(_ piece: RingsPiece, _ at: CGPoint, in parent: CALayer, size: CGSize? = nil, turn: CGFloat = 0) {
        let layer = RingsLayer()
        parent.addSublayer(layer)
        seats.append(Seat(piece: piece, layer: layer, at: at, size: size, turn: turn))
    }

    /// The bake is in: every layer takes its bitmap in one commit, and the scene shows.
    private func landed(_ art: [RingsPiece: RingsBitmap], _ pieces: Set<RingsPiece>) {
        for seat in seats { fill(seat.layer, art[seat.piece], at: seat.at, size: seat.size, turn: seat.turn) }
        RingsArt.shared.keep(pieces)
        whole = true
        if scene.opacity == 0 { fade(scene, to: 1, 0.2) }
        #if PROBES || DEBUG
        tour()
        #endif
    }

    private func fill(_ layer: CALayer, _ bitmap: RingsBitmap?, at: CGPoint, size: CGSize? = nil, turn: CGFloat = 0) {
        guard let bitmap else { return }
        let size = size ?? bitmap.size, scale = window?.screen.scale ?? 3
        var position = CGPoint(x: at.x + bitmap.offset.x, y: at.y + bitmap.offset.y)
        if turn == 0, layer.anchorPoint == CGPoint(x: 0.5, y: 0.5) {
            // On the pixel grid, so a bitmap is never drawn between pixels at rest.
            position.x = ((position.x - size.width / 2) * scale).rounded() / scale + size.width / 2
            position.y = ((position.y - size.height / 2) * scale).rounded() / scale + size.height / 2
        }
        layer.contents = bitmap.image
        layer.bounds = CGRect(origin: .zero, size: size)
        layer.position = position
        if turn != 0 { layer.transform = CATransform3DMakeRotation(turn, 0, 0, 1) }
    }

    private static let under = CGPoint(x: 0, y: -43), pair = CGPoint(x: 0, y: 8), cue = CGPoint(x: 0, y: 36)

    private static func numeral(_ spot: RingsModel.Spot, _ tier: Tier) -> RingsText {
        switch spot.bead {
        case .dull: RingsText(spot.number, .data, 11, .ink(0.62))
        case .solved: RingsText(spot.number, .data, 11, .tier(tier), .semibold)
        case .par: RingsText(spot.number, .data, 11, .dark, .semibold)
        case .next: RingsText(spot.number, .data, 15, .dark, .semibold)
        }
    }

    /// The middle's two lines for a level: what stands under the tier's name, and the level's number and name.
    private static func named(_ spot: RingsModel.Spot, under: String) -> (under: RingsText, pair: RingsText) {
        (RingsText(under, .data, 13, .dusk, .medium, tracking: 0.4),
         RingsText(runs: [.init(string: spot.number, voice: .data, size: 20, ink: .deep, weight: .semibold),
                          .init(string: spot.name, voice: .name, size: 30, ink: .deep, weight: .regular)], gap: 10))
    }

    /// The rings a swipe away, named over the sun and under it.
    private static func cues(_ model: RingsModel, _ i: Int, radius: CGFloat) -> [RingsText] {
        var out: [RingsText] = []
        if i > 0 {
            let up = model.rings[i - 1]
            out.append(RingsText("\u{2191} " + up.word, .data, 11, .tier(up.tier), .medium, tracking: 1, finish: .shadowed,
                                 arc: .init(radius: radius, angle: -.pi / 2)))
        }
        if i + 1 < model.rings.count {
            let down = model.rings[i + 1]
            out.append(RingsText("\u{2193} " + down.word, .data, 11, .tier(down.tier), .medium, tracking: 1, finish: .shadowed,
                                 arc: .init(radius: radius, angle: .pi / 2, inward: false)))
        }
        return out
    }

    // MARK: The swipe

    /// Everything that moves, at `place`: a ring's index, between two mid-swipe. Transforms and opacities only.
    private func apply(_ place: CGFloat) {
        for (i, ring) in rings.enumerated() {
            let pose = RingsPose(depth: CGFloat(i) - place)
            ring.whole.transform = CATransform3DMakeScale(pose.scale, pose.scale, 1)
            ring.beads.opacity = Float(pose.beads * ring.dim)
            ring.words.opacity = Float(pose.words)
            ring.sun.opacity = Float(pose.sun)
        }
        let middle = CGFloat(max(rings.count - 1, 0)) / 2
        for (g, layer) in ground where g.dx != 0 || g.dy != 0 || g.eye > 0 {
            if g.eye > 0 {
                // Laid back flat, then slid along itself towards the viewer. The art repeats, so it only ever goes half
                // a repeat either way, and its foot stays at the screen: the nearest line leaves under the screen's
                // foot as the slide wraps, and at rest the slide is nowhere near a wrap.
                var slide = g.dy * place
                if g.wrap > 0 { slide -= (slide / g.wrap).rounded() * g.wrap }
                layer.transform = CATransform3DTranslate(CATransform3DMakeRotation(.pi / 2, 1, 0, 0), g.dx * place,
                                                         slide + g.lead - g.wrap / 2, 0)
            } else {
                layer.transform = CATransform3DMakeTranslation(g.dx * (place - middle), g.dy * (place - middle), 0)
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        RingsCount.scrolls += 1
        let place = scrollView.contentOffset.y / RingsPlan.pitch
        at = min(max(Int(place.rounded()), 0), max(rings.count - 1, 0))
        apply(place)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        unpick()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        glided?()
    }

    /// Brings ring `index` forward, as a swipe does.
    func go(to index: Int, animated: Bool = true) {
        guard rings.indices.contains(index) else { return }
        unpick()
        pager.setContentOffset(CGPoint(x: 0, y: RingsPlan.pitch * CGFloat(index)), animated: animated)
    }

    /// A pose's: the swipe stopped at a place between rings.
    func hold(place: CGFloat) {
        pager.isPagingEnabled = false
        pager.contentOffset = CGPoint(x: 0, y: RingsPlan.pitch * place)
    }

    private func fade(_ layer: CALayer, to value: Float, _ seconds: Double = 0.16) {
        let from = layer.presentation()?.opacity ?? layer.opacity
        guard from != value || layer.opacity != value else { return }
        layer.opacity = value
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = from
        fade.toValue = value
        fade.duration = seconds
        fade.preferredFrameRateRange = Self.fast
        layer.add(fade, forKey: "fade")
    }

    // MARK: Taps

    /// What lies under a point: a bead by the nearest on the ring's circle, each with at least a 44 pt target.
    func hit(_ point: CGPoint) -> Hit {
        guard let plan, let model else { return .nothing }
        if hypot(point.x - plan.settings.x, point.y - plan.settings.y) < 26 { return .settings }
        let foot = RingsPaint.coverWidth / 2
        for i in model.covers.indices {
            let c = plan.cover(i, of: model.covers.count)
            if abs(point.x - c.x) < foot + 10, point.y > c.y - foot - 6, point.y < c.y + foot + 50 { return .cover(i) }
        }
        let v = CGPoint(x: point.x - plan.centre.x, y: point.y - plan.centre.y), r = hypot(v.x, v.y)
        if model.daily != nil, abs(r - plan.orbit) < 28, v.y < 0, abs(atan2(v.x, -v.y)) < 0.72 { return .daily }
        guard rings.indices.contains(at) else { return .nothing }
        let n = model.rings[at].spots.count
        if n > 0, abs(r - plan.radius) < 26 {
            let turn = (atan2(v.y, v.x) + .pi / 2) / (2 * .pi) * CGFloat(n) - 0.5
            return .bead((Int(turn.rounded()) % n + n) % n)
        }
        return r < plan.radius - 26 ? .middle : .nothing
    }

    @objc private func tapped(_ tap: UITapGestureRecognizer) {
        act(hit(tap.location(in: self)))
    }

    /// A tap on the middle, or on the bead it names, opens that level at once; a tap on any other bead names it in
    /// the middle, and the next plays it.
    func act(_ hit: Hit) {
        guard let model, model.rings.indices.contains(at) else { return }
        let ring = model.rings[at]
        switch hit {
        case .settings:
            Sound.shared.play(.tap)
            onSettings()
        case .daily:
            guard let daily = model.daily else { return }
            Sound.shared.play(.tap)
            onPick(daily.level)
        case let .cover(i):
            Sound.shared.play(.tap)
            Log.write("card \(model.covers[i].offer.key) shown")
            onOffer(model.covers[i].offer)
        case let .bead(i):
            guard ring.open else { return Sound.shared.play(.seized) }
            if i == picked ?? ring.way { open(ring.spots[i]) } else { pick(i) }
        case .middle:
            guard ring.open, let i = picked ?? ring.way else { return }
            open(ring.spots[i])
        case .nothing:
            unpick()
        }
    }

    private func open(_ spot: RingsModel.Spot) {
        guard spot.shut == nil else { return Sound.shared.play(.seized) }
        Sound.shared.play(.tap)
        onPick(spot.level)
    }

    /// Names bead `i` in the middle: its words are baked off the main thread and shown as they land.
    private func pick(_ i: Int) {
        guard let model, let plan, rings.indices.contains(at) else { return }
        let ring = model.rings[at], spot = ring.spots[i], layers = rings[at], index = at
        Sound.shared.play(.tap)
        picked = i
        let named = Self.named(spot, under: spot.facts)
        let cue = RingsText(spot.shut ?? String(localized: "tap again to play", comment: "The rings' middle, a level picked"),
                            .data, 13, .dusk, .medium, tracking: 0.4)
        let pieces: [RingsPiece] = [.text(named.under), .text(named.pair), .text(cue)]
        let scale = window?.screen.scale ?? 3
        picking?.cancel()
        picking = Task { [weak self] in
            let art = await RingsArt.shared.bake(pieces, scale: scale)
            guard let self, !Task.isCancelled, self.picked == i, self.at == index else { return }
            self.fill(layers.under, art[pieces[0]], at: Self.under)
            self.fill(layers.pair, art[pieces[1]], at: Self.pair)
            self.fill(layers.cue, art[pieces[2]], at: Self.cue)
            let seat = plan.bead(i, of: ring.spots.count)
            self.fill(layers.halo, RingsArt.shared.have([.halo])[.halo], at: seat)
            self.fade(layers.rest, to: 0)
            self.fade(layers.pick, to: 1)
            self.fade(layers.halo, to: 1)
        }
    }

    private func unpick() {
        guard picked != nil else { return }
        picked = nil
        picking?.cancel()
        for ring in rings {
            fade(ring.rest, to: 1)
            fade(ring.pick, to: 0)
            fade(ring.halo, to: 0)
        }
    }
}
