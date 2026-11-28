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

/// Where everything stands on a screen, from its size, insets and type size alone. The mock is 440 by 956; a smaller
/// screen draws the ring, the sun and the orbits in, and leaves every word and bead its size. Under accessibility type
/// the mock's own layout for it holds (`launch-ax.png`): the ring a little higher, the sun whole over a lower horizon,
/// the daily's words set flat under its star, and every word at the size the system gives its role, never smaller, up
/// to accessibility3, past which it stops growing.
struct RingsPlan: Equatable {
    /// A finger's travel from one ring to the next.
    static let pitch: CGFloat = 240

    let size: CGSize
    let top, bottom: CGFloat
    let k: CGFloat
    let type: UIContentSizeCategory
    let large: Bool
    /// The ring's centre, and its beads' distance from it.
    let centre: CGPoint
    let radius: CGFloat
    let horizon: CGFloat

    init(size: CGSize, top: CGFloat, bottom: CGFloat, type: UIContentSizeCategory = .large) {
        self.size = size
        self.top = top
        self.bottom = bottom
        // The menu's text stops growing past accessibility3: the two largest sizes draw as it (Jack, 2026-11-28).
        self.type = min(type, .accessibilityExtraLarge)
        large = type.isAccessibilityCategory
        let room = size.height - top - bottom
        k = min(1, size.width / 440, room / 860)
        centre = CGPoint(x: size.width / 2, y: (top + room * 0.465 - (large ? 34 * k : 0)).rounded())
        radius = 190 * k
        horizon = (centre.y + (large ? RingsLook.setClear : RingsLook.set) * k).rounded()
    }

    /// A word's size: the mock's, or under accessibility type the size the system gives `role` there.
    func pt(_ size: CGFloat, _ role: UIFont.TextStyle) -> CGFloat {
        guard large else { return size }
        return UIFontMetrics(forTextStyle: role).scaledValue(for: size, compatibleWith: UITraitCollection(preferredContentSizeCategory: type))
    }

    /// Bead `i` of `n`, from the centre: the seam between the last and the first is at the top.
    func bead(_ i: Int, of n: Int) -> CGPoint {
        let a = -CGFloat.pi / 2 + (CGFloat(i) + 0.5) * 2 * .pi / CGFloat(max(n, 1))
        return CGPoint(x: radius * cos(a), y: radius * sin(a))
    }

    /// The daily's orbit over the ring, and its star on it.
    var orbit: CGFloat { (large ? 320 : 300) * k }
    var daily: CGPoint { CGPoint(x: centre.x, y: centre.y - orbit) }

    /// Cover `i` of `n`, on the orbit under the ring.
    func cover(_ i: Int, of n: Int) -> CGPoint {
        let a = CGFloat.pi / 2 + 0.41 * (CGFloat(n - 1) / 2 - CGFloat(i))
        let r = (large ? 288 : 304) * k
        return CGPoint(x: centre.x + r * cos(a), y: centre.y + r * sin(a))
    }

    var packsLine: CGPoint { CGPoint(x: centre.x, y: centre.y + (large ? 447 : 422) * k) }
    var settings: CGPoint { CGPoint(x: centre.x, y: size.height - bottom - 10) }
    var wordmark: CGPoint { CGPoint(x: centre.x, y: top + (large ? 10 : 24)) }
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
        /// Endless's saved run, as the root reads it.
        var endless: Resume?
        /// The type size the menu is shown at.
        var type: UIContentSizeCategory = .large
    }

    enum Hit: Equatable {
        case settings, daily, cover(Int), bead(Int), middle, renew, nothing
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
    /// The ring the swipe last committed to, so its sound plays once for each new ring, never on a scroll callback.
    private var landing = 0

    private struct Seat {
        let piece: RingsPiece
        let layer: CALayer
        let at: CGPoint
        var size: CGSize?
        var turn: CGFloat = 0
        /// Drawn in with the ring on a small screen.
        var shrink: CGFloat = 1
    }

    private struct Ring {
        let whole = RingsLayer(), beads = RingsLayer(), words = RingsLayer(), rest = RingsLayer(), pick = RingsLayer()
        let sun = RingsLayer(), halo = RingsLayer()
        let under = RingsLayer(), pair = RingsLayer(), cue = RingsLayer()
        /// Endless's "new run", and the same armed.
        let renew = RingsLayer(), armed = RingsLayer()
        var dim: CGFloat = 1
        /// Where the middle's cue stands, from the centre: the play mark, or endless's new run.
        var cueAt = CGPoint(x: 0, y: 36)
    }

    private let pager = UIScrollView()
    private let scene = RingsLayer()
    private var seats: [Seat] = []
    private var rings: [Ring] = []
    private var ground: [(RingsGround, CALayer)] = []
    private var baking: Task<Void, Never>?
    private var picking: Task<Void, Never>?
    private var inset: CGFloat = -1
    /// The ring a launch opens on, until the first build finds its index.
    private let opening: RingsHue
    /// When a first tap armed endless's new run (`ResetArm`).
    private var armedAt: Date?

    /// The display's fastest: Core Animation otherwise gives an animation 60 frames a second on a phone.
    static let fast = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)

    init(state: State, opening: RingsHue) {
        self.state = state
        self.opening = opening
        at = 0
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
        if #available(iOS 26, *) {
            // The pager stands under the status bar, where UIKit gives a scroll view a blurred edge of its backdrop,
            // rendered again on every frame it scrolls: 16 offscreen passes a frame on a 13 Pro Max. It holds nothing.
            for edge in [pager.topEdgeEffect, pager.bottomEdgeEffect, pager.leftEdgeEffect, pager.rightEdgeEffect] { edge.isHidden = true }
        }
        pager.delegate = self
        addSubview(pager)
        // The pager is only its physics: its pan listens on the whole menu, and it shows nothing.
        addGestureRecognizer(pager.panGestureRecognizer)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        NotificationCenter.default.addObserver(self, selector: #selector(motionChanged),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
    }

    @objc private func motionChanged() {
        apply(pager.contentOffset.y / RingsPlan.pitch)
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
        #if PROBES || DEBUG
        let began = Date.now
        #endif
        let model = RingsModel(today: state.day ?? .now, endless: state.endless)
        #if PROBES || DEBUG
        Log.write("rings model read \(Int(Date.now.timeIntervalSince(began) * 1000)) ms")
        #endif
        let plan = RingsPlan(size: bounds.size, top: inset, bottom: window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom, type: state.type)
        guard model != self.model || plan != self.plan else { return }
        RingsCount.builds += 1
        // The ring in front stays in front when rings come or go (the daily's and endless's opening).
        let ahead = self.model.flatMap { $0.rings.indices.contains(at) ? $0.rings[at].hue : nil } ?? opening
        armedAt = nil
        self.model = model
        self.plan = plan
        spoken = nil
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
        for g in RingsLook.ground(width: plan.size.width, height: plan.size.height, horizon: plan.horizon, low: plan.large) {
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
            seats.append(Seat(piece: .sun(ring.hue, shut: !ring.open, clear: plan.large), layer: made.sun, at: plan.centre, shrink: plan.k))
            if ring.spots.isEmpty {
                let orbit = RingsLayer()
                made.beads.addSublayer(orbit)
                seats.append(Seat(piece: .orbit(ring.hue), layer: orbit, at: .zero, shrink: plan.k))
            }

            let n = ring.spots.count, spots = (0 ..< n).map { plan.bead($0, of: n) }
            for j in 0 ..< n where n > 1 {
                let a = spots[j], b = spots[(j + 1) % n]
                seat(.link(ring.hue), CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2), in: made.beads,
                     size: CGSize(width: hypot(b.x - a.x, b.y - a.y), height: 3), turn: atan2(b.y - a.y, b.x - a.x))
            }
            for (j, spot) in ring.spots.enumerated() {
                seat(.bead(ring.hue, spot.bead), spots[j], in: made.beads)
                if !spot.number.isEmpty {
                    seat(.text(Self.numeral(spot, ring.hue)), CGPoint(x: spots[j].x, y: spots[j].y + 0.5), in: made.beads)
                }
            }
            made.beads.addSublayer(made.halo)
            made.halo.opacity = 0
            seats.append(Seat(piece: .halo, layer: made.halo, at: .zero))

            // Under accessibility type the rings a swipe away go unnamed, as the mock has it: the middle needs the room.
            if !plan.large {
                for text in Self.cues(model, i, radius: 163 * plan.k) { seat(.text(text), .zero, in: made.words) }
            }
            if ring.open, let lead = ring.lead {
                made.words.addSublayer(made.rest)
                made.words.addSublayer(made.pick)
                made.pick.opacity = 0
                let cue: RingsText? = ring.renews ? Self.renew(armed: false, plan) : nil
                let m = Self.middle(word: ring.word, lead, under: plan.large ? ring.brief ?? ring.under : ring.under, cue: cue, plan: plan)
                made.cueAt = m.cue
                seat(.text(m.word.text), m.word.at, in: made.words)
                seat(.text(m.under.text), m.under.at, in: made.rest)
                seat(.text(m.pair.text), m.pair.at, in: made.rest)
                if ring.renews {
                    made.rest.addSublayer(made.renew)
                    made.rest.addSublayer(made.armed)
                    made.armed.opacity = 0
                    seats.append(Seat(piece: .text(Self.renew(armed: false, plan)), layer: made.renew, at: m.cue))
                    seats.append(Seat(piece: .text(Self.renew(armed: true, plan)), layer: made.armed, at: m.cue))
                } else if !plan.large {
                    seat(.play, m.cue, in: made.rest)
                }
                for layer in [made.under, made.pair, made.cue] { made.pick.addSublayer(layer) }
            } else {
                let word = RingsText(ring.word, .word, plan.large ? plan.pt(28, .title1) : 38, .ink(0.2), .light, finish: .unlit(ring.hue))
                let under = RingsText(ring.under, .name, plan.pt(16, .callout), .ink(0.7), wrap: plan.large ? 260 * plan.k : 230)
                let tall = RingsPaint.measure(word).height
                seat(.text(word), CGPoint(x: 0, y: plan.large ? -tall / 2 : -34), in: made.words)
                seat(.text(under), CGPoint(x: 0, y: plan.large ? RingsPaint.measure(under).height / 2 + 4 : 20), in: made.words)
            }
            return made
        }

        seat(.wordmark, plan.wordmark, in: chrome)
        if let daily = model.daily {
            seat(.daily, plan.daily, in: chrome)
            if plan.large {
                // Flat under the star, each line under the last.
                let wide = plan.size.width - 32
                let title = RingsText(daily.title, .name, plan.pt(17, .headline), .ink(1), finish: .shadowed, wrap: wide)
                // Shadowed words carry 8 points of pad a side, closed up here.
                let tall = RingsPaint.measure(title).height - 16
                seat(.text(title), CGPoint(x: plan.daily.x, y: plan.daily.y + 14 + tall / 2), in: chrome)
                if let under = daily.under {
                    let line = RingsText(under, .data, plan.pt(13, .footnote), .ink(0.62), finish: .shadowed, wrap: wide)
                    seat(.text(line), CGPoint(x: plan.daily.x, y: plan.daily.y + 14 + tall + (RingsPaint.measure(line).height - 16) / 2),
                         in: chrome)
                }
            } else {
                seat(.text(RingsText(daily.title, .name, 16, .ink(0.96), tracking: 0.3,
                                     arc: .init(radius: plan.orbit, angle: -.pi / 2, lead: 30, side: -1))), plan.centre, in: chrome)
                if let under = daily.under {
                    seat(.text(RingsText(under, .name, 16, .ink(0.58), tracking: 0.3,
                                         arc: .init(radius: plan.orbit, angle: -.pi / 2, lead: 30, side: 1))), plan.centre, in: chrome)
                }
            }
        }
        for (i, cover) in model.covers.enumerated() {
            let n = model.covers.count, c = plan.cover(i, of: n), foot = RingsPaint.coverWidth / 2
            seat(.cover(cover.pack), c, in: chrome)
            if plan.large {
                // One line a cover, its name and its news; the middle one's lower, clear of its neighbours'.
                let label = RingsText([cover.name, cover.line].compactMap { $0 }.joined(separator: " "), .name, plan.pt(15, .subheadline),
                                      .ink(0.96), finish: .shadowed, wrap: n % 2 == 1 && i == n / 2 ? plan.size.width - 40 : plan.size.width / 2 - 10)
                let drop: CGFloat = n % 2 == 1 && i == n / 2 ? 22 : 4
                seat(.text(label), CGPoint(x: c.x, y: c.y + foot + drop + RingsPaint.measure(label).height / 2), in: chrome)
            } else {
                seat(.text(RingsText(cover.name, .name, 16, .ink(0.96), finish: .shadowed)), CGPoint(x: c.x, y: c.y + foot + 20), in: chrome)
                if let line = cover.line {
                    seat(.text(RingsText(line, .data, 12, cover.lit ? .gold : .ink(0.8), finish: .shadowed)),
                         CGPoint(x: c.x, y: c.y + foot + 39), in: chrome)
                }
            }
        }
        if let line = model.packsLine {
            seat(.text(RingsText(line, .data, plan.pt(12, .caption1), .ink(0.8), tracking: plan.large ? 0 : 0.4, finish: .shadowed,
                                 wrap: plan.large ? plan.size.width - 16 : nil)), plan.packsLine, in: chrome)
        }
        seat(.settings, plan.settings, in: chrome)

        // A menu built again mid-swipe (a purchase landing, the store's first read) stays where the finger has it.
        let place = was == rings.count ? pager.contentOffset.y / RingsPlan.pitch : CGFloat(model.rings.firstIndex { $0.hue == ahead } ?? 0)
        pager.delegate = nil
        pager.frame = CGRect(x: 0, y: 0, width: bounds.width, height: RingsPlan.pitch)
        pager.contentSize = CGSize(width: bounds.width, height: RingsPlan.pitch * CGFloat(rings.count))
        pager.contentOffset = CGPoint(x: 0, y: RingsPlan.pitch * place)
        pager.delegate = self
        at = min(max(Int(place.rounded()), 0), max(rings.count - 1, 0))
        landing = at
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
        for seat in seats { fill(seat.layer, art[seat.piece], at: seat.at, size: seat.size, turn: seat.turn, shrink: seat.shrink) }
        RingsArt.shared.keep(pieces)
        whole = true
        if scene.opacity == 0 { fade(scene, to: 1, 0.2) }
        #if PROBES || DEBUG
        tour()
        #endif
    }

    private func fill(_ layer: CALayer, _ bitmap: RingsBitmap?, at: CGPoint, size: CGSize? = nil, turn: CGFloat = 0, shrink: CGFloat = 1) {
        guard let bitmap else { return }
        let size = size ?? CGSize(width: bitmap.size.width * shrink, height: bitmap.size.height * shrink), scale = window?.screen.scale ?? 3
        var position = CGPoint(x: at.x + bitmap.offset.x * shrink, y: at.y + bitmap.offset.y * shrink)
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

    /// The middle's words and where each stands from the centre: the ring's word, what stands under it, the level's
    /// number and name, and where the cue goes. Under accessibility type each is measured and set under the last, the
    /// number and name each on a line of its own and wrapped to the sun.
    private static func middle(word: String, _ spot: RingsModel.Spot, under: String, cue: RingsText?, plan: RingsPlan)
        -> (word: (text: RingsText, at: CGPoint), under: (text: RingsText, at: CGPoint), pair: (text: RingsText, at: CGPoint), cue: CGPoint) {
        guard plan.large else {
            let named = named(spot, under: under)
            return ((RingsText(word, .word, 38, .deep, .medium), CGPoint(x: 0, y: -76)), (named.under, Self.under), (named.pair, Self.pair), Self.cue)
        }
        let wide = 270 * plan.k
        let title = RingsText(word, .word, plan.pt(28, .title1), .deep, .medium)
        let line = RingsText(under, .data, plan.pt(13, .footnote), .dusk, .medium, wrap: wide)
        let name = RingsText.Run(string: spot.name, voice: .name, size: plan.pt(28, .title1), ink: .deep, weight: .regular)
        let pair = RingsText(runs: spot.number.isEmpty ? [name]
                                 : [.init(string: spot.number, voice: .data, size: plan.pt(20, .title1), ink: .deep, weight: .semibold), name],
                             gap: 0, stack: true, wrap: wide)
        // Each piece's bitmap is padded; the stack closes the pads up. It starts where a stack of the word, one line, a
        // number and a one-line name and a cue would stand centred a little over the sun's middle, so the word stays put
        // while a picked bead's words take the rest's place.
        func tall(_ text: RingsText) -> CGFloat { RingsPaint.measure(text).height - 6 }
        let model = [title, RingsText("0", .data, plan.pt(13, .footnote)),
                     RingsText(runs: [.init(string: "0", voice: .data, size: plan.pt(20, .title1)),
                                      .init(string: "X", voice: .name, size: plan.pt(28, .title1))], gap: 0, stack: true),
                     RingsText("0", .data, plan.pt(13, .footnote))]
        let stack = [title, line, pair] + (cue.map { [$0] } ?? []), talls = stack.map(tall)
        var y = -model.map(tall).reduce(0, +) / 2 - 10 * plan.k
        let at = talls.map { tall -> CGPoint in
            defer { y += tall }
            return CGPoint(x: 0, y: y + tall / 2)
        }
        let cueAt = cue == nil ? CGPoint(x: 0, y: y + 12) : at[3]
        return ((title, at[0]), (line, at[1]), (pair, at[2]), cueAt)
    }

    private static func numeral(_ spot: RingsModel.Spot, _ hue: RingsHue) -> RingsText {
        switch spot.bead {
        case .dull: RingsText(spot.number, .data, 11, .ink(0.62))
        case .solved: RingsText(spot.number, .data, 11, .hue(hue), .semibold)
        case .par: RingsText(spot.number, .data, 11, .dark, .semibold)
        case .next: RingsText(spot.number, .data, 15, .dark, .semibold)
        }
    }

    /// The middle's two lines for a level: what stands under the tier's name, and the level's number and name.
    private static func named(_ spot: RingsModel.Spot, under: String) -> (under: RingsText, pair: RingsText) {
        let name = RingsText.Run(string: spot.name, voice: .name, size: 30, ink: .deep, weight: .regular)
        return (RingsText(under, .data, 13, .dusk, .medium, tracking: 0.4),
                RingsText(runs: spot.number.isEmpty ? [name]
                              : [.init(string: spot.number, voice: .data, size: 20, ink: .deep, weight: .semibold), name], gap: 10))
    }

    /// Endless's new run, in the play mark's place.
    private static func renew(armed: Bool, _ plan: RingsPlan) -> RingsText {
        RingsText(armed ? String(localized: "new run? tap again", comment: "Endless's row: armed, a second tap drops the saved run")
                      : String(localized: "new run", comment: "Endless's row: drops the saved run"),
                  .data, plan.pt(15, .subheadline), .dusk, .medium, tracking: 0.4, wrap: plan.large ? 270 * plan.k : nil)
    }

    /// The cue a picked bead shows: what opens it, or that a second tap plays it.
    private static func pickCue(_ spot: RingsModel.Spot, _ plan: RingsPlan) -> RingsText {
        // One line, as two would reach the horizon; what opens a shut bead is longer, and wraps.
        RingsText(spot.shut ?? String(localized: "tap again to play", comment: "The rings' middle, a level picked"),
                  .data, plan.pt(13, .footnote), .dusk, .medium, tracking: plan.large ? 0 : 0.4,
                  wrap: plan.large && spot.shut != nil ? 270 * plan.k : nil)
    }

    /// The rings a swipe away, named over the sun and under it.
    private static func cues(_ model: RingsModel, _ i: Int, radius: CGFloat) -> [RingsText] {
        var out: [RingsText] = []
        if i > 0 {
            let up = model.rings[i - 1]
            out.append(RingsText("\u{2191} " + up.word, .data, 11, .hue(up.hue), .medium, tracking: 1, finish: .shadowed,
                                 arc: .init(radius: radius, angle: -.pi / 2)))
        }
        if i + 1 < model.rings.count {
            let down = model.rings[i + 1]
            out.append(RingsText("\u{2193} " + down.word, .data, 11, .hue(down.hue), .medium, tracking: 1, finish: .shadowed,
                                 arc: .init(radius: radius, angle: .pi / 2, inward: false)))
        }
        return out
    }

    // MARK: The swipe

    /// Everything that moves, at `place`: a ring's index, between two mid-swipe. Transforms and opacities only. Under
    /// Reduce Motion the rings only cross-fade and the ground stands still.
    private func apply(_ place: CGFloat) {
        let still = UIAccessibility.isReduceMotionEnabled
        for (i, ring) in rings.enumerated() {
            let pose = RingsPose(depth: CGFloat(i) - place), scale = still ? 1 : pose.scale
            ring.whole.transform = CATransform3DMakeScale(scale, scale, 1)
            ring.beads.opacity = Float(pose.beads * ring.dim)
            ring.words.opacity = Float(pose.words)
            ring.sun.opacity = Float(pose.sun)
        }
        let middle = CGFloat(max(rings.count - 1, 0)) / 2, place = still ? middle : place
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

    /// The finger let go: the page the pager will settle on is known now, so its sound plays with the release.
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let target = Int((targetContentOffset.pointee.y / RingsPlan.pitch).rounded())
        commit(to: min(max(target, 0), max(rings.count - 1, 0)))
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        landing = at
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        landing = at
        glided?()
    }

    /// Brings ring `index` forward, as a swipe does, with its sound unless `sounds` is false (a pose for a shot).
    func go(to index: Int, animated: Bool = true, sounds: Bool = true) {
        guard rings.indices.contains(index) else { return }
        unpick()
        if sounds { commit(to: index) } else { landing = index }
        pager.setContentOffset(CGPoint(x: 0, y: RingsPlan.pitch * CGFloat(index)), animated: animated)
    }

    /// A swipe settling on a new ring: a deeper one falls, a shallower one rises. Once a ring, preloaded with the other
    /// effects, so a glide costs its frames nothing.
    private func commit(to index: Int) {
        guard index != landing else { return }
        let effect: Sound.Effect = index > landing ? .deeper : .shallower
        // Logged with sound off too, so a muted run can check the swipe's sound against the finger.
        Log.write("rings \(landing)→\(index): \(effect)")
        Sound.shared.play(effect)
        landing = index
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
            if abs(point.x - c.x) < foot + 10, point.y > c.y - foot - 6, point.y < c.y + foot + (plan.large ? 80 : 50) { return .cover(i) }
        }
        let v = CGPoint(x: point.x - plan.centre.x, y: point.y - plan.centre.y), r = hypot(v.x, v.y)
        if model.daily != nil, plan.large ? abs(point.x - plan.daily.x) < 200 && point.y > plan.daily.y - 30 && point.y < plan.daily.y + 110
            : abs(r - plan.orbit) < 28 && v.y < 0 && abs(atan2(v.x, -v.y)) < 0.72 { return .daily }
        guard rings.indices.contains(at) else { return .nothing }
        let n = model.rings[at].spots.count
        if n > 0, abs(r - plan.radius) < 26 {
            let turn = (atan2(v.y, v.x) + .pi / 2) / (2 * .pi) * CGFloat(n) - 0.5
            return .bead((Int(turn.rounded()) % n + n) % n)
        }
        let cue = rings[at].cueAt
        if model.rings[at].renews, abs(v.x - cue.x) < 90, abs(v.y - cue.y) < 14 { return .renew }
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
            guard ring.open else { return }
            if let i = picked { open(ring.spots[i]) } else if let lead = ring.lead { open(lead) }
        case .renew:
            renew()
        case .nothing:
            unpick()
        }
    }

    private func open(_ spot: RingsModel.Spot) {
        guard spot.shut == nil else { return Sound.shared.play(.seized) }
        Sound.shared.play(.tap)
        onPick(spot.anew ? .endless(Run(seed: .random(in: .min ... .max))) : spot.level)
    }

    /// Endless's new run: a first tap arms it for `ResetArm.window` (under VoiceOver until a second), and a second
    /// drops the saved run and deals another, so a slip never loses one.
    private func renew() {
        guard rings.indices.contains(at) else { return }
        let layers = rings[at], tap = ResetArm.tap(now: .now, armedAt: armedAt, played: true, held: UIAccessibility.isVoiceOverRunning)
        armedAt = tap.armedAt
        Sound.shared.play(.tap)
        guard tap.reset else {
            Log.write("rings new run armed")
            fade(layers.renew, to: 0)
            fade(layers.armed, to: 1)
            UIAccessibility.post(notification: .announcement,
                                 argument: String(localized: "Tap again for a new run", comment: "VoiceOver: endless's new run, armed"))
            let armed = tap.armedAt
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(ResetArm.window))
                guard let self, self.armedAt == armed, !UIAccessibility.isVoiceOverRunning else { return }
                self.armedAt = nil
                self.fade(layers.renew, to: 1)
                self.fade(layers.armed, to: 0)
            }
            return
        }
        Log.write("rings new run")
        Resume.remove("endless")
        onPick(.endless(Run(seed: .random(in: .min ... .max))))
    }

    /// Names bead `i` in the middle: its words are baked off the main thread and shown as they land.
    private func pick(_ i: Int) {
        guard let model, let plan, rings.indices.contains(at) else { return }
        let ring = model.rings[at], spot = ring.spots[i], layers = rings[at], index = at
        Sound.shared.play(.tap)
        picked = i
        let cue = Self.pickCue(spot, plan)
        let m = Self.middle(word: ring.word, spot, under: plan.large ? spot.brief ?? spot.facts : spot.facts, cue: cue, plan: plan)
        let pieces: [RingsPiece] = [.text(m.under.text), .text(m.pair.text), .text(cue)]
        let scale = window?.screen.scale ?? 3
        picking?.cancel()
        picking = Task { [weak self] in
            let art = await RingsArt.shared.bake(pieces, scale: scale)
            guard let self, !Task.isCancelled, self.picked == i, self.at == index else { return }
            self.fill(layers.under, art[pieces[0]], at: m.under.at)
            self.fill(layers.pair, art[pieces[1]], at: m.pair.at)
            self.fill(layers.cue, art[pieces[2]], at: m.cue)
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

    // MARK: VoiceOver

    /// The elements of the ring in front, made when VoiceOver first asks for them, so nothing is made at rest without it.
    private var spoken: (at: Int, elements: [Any], middle: RingsSpoken?)?

    override var accessibilityElements: [Any]? {
        get {
            if let spoken, spoken.at == at { return spoken.elements }
            let made = speak()
            spoken = (at, made.elements, made.middle)
            return made.elements
        }
        set {}
    }

    /// The daily, the middle (adjustable: a swipe up or down brings the next ring or the one before), each bead of the
    /// ring in front, the covers and settings. Under VoiceOver a bead opens at once: naming it first is for the eye.
    private func speak() -> (elements: [Any], middle: RingsSpoken?) {
        guard let model, let plan, model.rings.indices.contains(at) else { return ([], nil) }
        let ring = model.rings[at]
        var out: [Any] = []
        func around(_ p: CGPoint, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: p.x - w / 2, y: p.y - h / 2, width: w, height: h) }
        @discardableResult
        func element(_ label: String, _ value: String?, _ frame: CGRect, _ traits: UIAccessibilityTraits = .button,
                     _ activate: @escaping () -> Void) -> RingsSpoken {
            let made = RingsSpoken(accessibilityContainer: self)
            made.accessibilityLabel = Self.said(label)
            made.accessibilityValue = value.map(Self.said)
            made.accessibilityTraits = traits
            made.accessibilityFrameInContainerSpace = frame
            made.activate = activate
            out.append(made)
            return made
        }
        if let daily = model.daily {
            element(daily.title, daily.under, around(plan.daily, 320, 64)) { [weak self] in self?.act(.daily) }
        }
        let lead = ring.open ? ring.lead : nil
        let value = lead.map {
            $0.number.isEmpty ? [ring.under, $0.name].filter { !$0.isEmpty }.joined(separator: ", ")
                : String(localized: "\(ring.under), next \($0.number) \($0.name)",
                         comment: "VoiceOver: the rings' middle. The tier's count, then the number and name of the level it plays")
        } ?? ring.under
        let side = 2 * (plan.radius - 26)
        let middle = element(ring.word, value, around(plan.centre, side, side), lead == nil ? .adjustable : [.button, .adjustable]) {
            [weak self] in self?.act(.middle)
        }
        middle.step = { [weak self] by in self?.step(by) }
        if ring.renews {
            element(String(localized: "New run", comment: "VoiceOver: starts a new endless run"), nil,
                    around(CGPoint(x: plan.centre.x + rings[at].cueAt.x, y: plan.centre.y + rings[at].cueAt.y), 180, 40)) { [weak self] in self?.act(.renew) }
        }
        if ring.open {
            for (j, spot) in ring.spots.enumerated() {
                let p = plan.bead(j, of: ring.spots.count)
                let state = spot.shut ?? (j == ring.way
                    ? String(localized: "next, \(spot.facts)", comment: "VoiceOver: the rings' bead of the level the middle plays. Its best and par")
                    : spot.facts)
                // loc: verbatim a level's number, then its title, localized by Levels
                element(spot.number.isEmpty ? spot.name : "\(spot.number) \(spot.name)", state, around(CGPoint(x: plan.centre.x + p.x, y: plan.centre.y + p.y), 44, 44),
                        spot.shut == nil ? .button : [.button, .notEnabled]) { [weak self] in self?.open(spot) }
            }
        }
        for (i, cover) in model.covers.enumerated() {
            let c = plan.cover(i, of: model.covers.count), foot = RingsPaint.coverWidth / 2
            element(cover.name, cover.line, CGRect(x: c.x - foot - 10, y: c.y - foot - 6, width: 2 * foot + 20, height: 2 * foot + 56)) {
                [weak self] in self?.act(.cover(i))
            }
        }
        element(String(localized: "settings", comment: "VoiceOver: the rings' settings, the motes at the foot"), nil,
                around(plan.settings, 52, 52)) { [weak self] in self?.act(.settings) }
        return (out, middle)
    }

    /// A line as VoiceOver should say it: the drawn lines' middle dots read as pauses.
    private static func said(_ line: String) -> String { line.replacingOccurrences(of: " \u{00B7} ", with: ", ") }

    /// The next ring, or the one before, brought forward at once, and VoiceOver taken to its middle.
    private func step(_ by: Int) {
        guard rings.indices.contains(at + by) else { return }
        go(to: at + by, animated: false)
        _ = accessibilityElements
        UIAccessibility.post(notification: .layoutChanged, argument: spoken?.middle)
    }
}

/// One thing VoiceOver reads on the rings, with what activating or adjusting it does.
private final class RingsSpoken: UIAccessibilityElement {
    var activate: () -> Void = {}
    var step: ((Int) -> Void)?

    override func accessibilityActivate() -> Bool {
        activate()
        return true
    }

    override func accessibilityIncrement() { step?(1) }
    override func accessibilityDecrement() { step?(-1) }
}
