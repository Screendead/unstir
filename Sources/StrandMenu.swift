// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import UIKit

/// The strand's menu: the Shelf's column (docs/slope.md, 2) built so that nothing in the app runs for a frame. Its
/// art is baked once off the main thread (`StrandArt`), its two rests are native scroll views over layers that hold
/// those bitmaps (`StrandColumn`), and the travel between them is two Core Animation animations. At rest it draws
/// nothing. It takes what `SlopeMenu` takes, bar the hollows' and the archive ledge's views.
struct StrandMenu: View {
    let start: Tier?
    let focus: Level?
    let returning: Bool
    @Binding var settings: Bool
    @Binding var card: Offer?
    @Binding var archive: Bool
    var day: Date?
    var clock: Double?
    var held: String?
    var peeking = false
    var playing: Level?
    var revision = 0
    var run: Resume?
    var light = 1.0
    var bare = false
    let onPick: (Level, CGPoint?) -> Void

    init(start: Tier? = nil, focus: Level? = nil, returning: Bool = false, settings: Binding<Bool>, card: Binding<Offer?>,
         archive: Binding<Bool> = .constant(false), day: Date? = nil, clock: Double? = nil, held: String? = nil, peeking: Bool = false,
         playing: Level? = nil, revision: Int = 0, run: Resume? = nil, light: Double = 1, bare: Bool = false,
         onPick: @escaping (Level, CGPoint?) -> Void) {
        self.start = start
        self.focus = focus
        self.returning = returning
        _settings = settings
        _card = card
        _archive = archive
        self.day = day
        self.clock = clock
        self.held = held
        self.peeking = peeking
        self.playing = playing
        self.revision = revision
        self.run = run
        self.light = light
        self.bare = bare
        self.onPick = onPick
    }

    var body: some View {
        StrandHost(rest: Menu.rest(start: start, focus: playing ?? focus, returning: returning || playing != nil),
                   state: StrandView.State(revision: revision, playing: playing?.id, day: day), run: run, onPick: onPick)
            .ignoresSafeArea()
    }
}

private struct StrandHost: UIViewRepresentable {
    let rest: Menu.Rest
    let state: StrandView.State
    let run: Resume?
    let onPick: (Level, CGPoint?) -> Void

    func makeUIView(context: Context) -> StrandView {
        StrandView(rest: rest, state: state, run: run, onPick: onPick)
    }

    func updateUIView(_ view: StrandView, context: Context) {
        StrandCount.updates += 1
        view.onPick = onPick
        view.update(state, run: run)
    }
}

/// The menu's own view: the two rests, one hidden, and the travel between them.
final class StrandView: UIView, UIScrollViewDelegate {
    /// What the root hands down that can change what the menu shows.
    struct State: Equatable {
        var revision: Int
        var playing: String?
        var day: Date?
    }

    var onPick: (Level, CGPoint?) -> Void
    private var state: State
    private var run: Resume?
    private var opening: Menu.Rest?
    private var model: StrandModel?
    private(set) var plan: StrandPlan?
    private(set) var overview: StrandColumn?
    private(set) var dive: StrandColumn?
    private(set) var diving = false
    /// Every bitmap of both rests is on its layer.
    private(set) var whole = false
    private let backdrop = CAGradientLayer()
    private let surface = UIView()
    private let surfaceWords = StrandLayer()
    private var built = CGSize.zero
    private var inset: CGFloat = -1
    private var baking: Task<Void, Never>?
    private var travels = 0
    var scrolled: (() -> Void)?

    static let travel = 0.35
    /// The display's fastest: Core Animation otherwise gives an animation 60 frames a second on a phone.
    static let fast = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)

    init(rest: Menu.Rest, state: State, run: Resume?, onPick: @escaping (Level, CGPoint?) -> Void) {
        opening = rest
        self.state = state
        self.run = run
        self.onPick = onPick
        super.init(frame: .zero)
        backgroundColor = .black
        // Until the bake lands: one gradient, drawn once.
        backdrop.colors = [UIColor(red: 0.03, green: 0.028, blue: 0.05, alpha: 1).cgColor, UIColor(red: 0.018, green: 0.125, blue: 0.165, alpha: 1).cgColor,
                           UIColor(red: 0.008, green: 0.006, blue: 0.014, alpha: 1).cgColor]
        backdrop.actions = ["bounds": NSNull(), "position": NSNull(), "hidden": NSNull()]
        layer.addSublayer(backdrop)
        surface.isHidden = true
        surface.layer.addSublayer(surfaceWords)
        surface.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rise)))
        addSubview(surface)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        StrandCount.layouts += 1
        let top = window?.safeAreaInsets.top ?? safeAreaInsets.top
        guard !bounds.isEmpty, window != nil, bounds.size != built || top != inset else { return }
        built = bounds.size
        inset = top
        backdrop.frame = bounds
        surface.frame = CGRect(x: 0, y: top, width: 150, height: 52)
        build()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    func update(_ next: State, run: Resume?) {
        guard next != state || run != self.run else { return }
        state = next
        self.run = run
        if built != .zero { build() }
    }

    /// Reads the model and, where what it shows has changed, lays both rests out again and bakes what is new.
    /// Seam: a change of day, a purchase or a sync calls this too.
    func build() {
        StrandCount.reads += 1
        let model = StrandModel(today: state.day ?? .now, saved: run)
        guard model != self.model || plan?.size != built else { return }
        self.model = model
        let scale = window?.screen.scale ?? traitCollection.displayScale
        let plan = StrandPlan(model, size: built, top: inset, bottom: window?.safeAreaInsets.bottom ?? 0)
        let was = (overview?.contentOffset.y, dive?.contentOffset.y)
        overview?.removeFromSuperview()
        dive?.removeFromSuperview()
        let overview = StrandColumn(plan.overview, size: built, scale: scale), dive = StrandColumn(plan.dive, size: built, scale: scale)
        for column in [overview, dive] {
            column.delegate = self
            column.onHit = { [weak self] hit, point in self?.hit(hit, point) }
            insertSubview(column, belowSubview: surface)
        }
        self.plan = plan
        self.overview = overview
        self.dive = dive
        if let opening {
            switch opening {
            case .overview: break
            case let .ledge(level):
                diving = true
                dive.contentOffset.y = dive.offset(for: plan.dive.rows[level.id] ?? 0, at: built.height * 0.45)
            case let .tier(tier):
                diving = true
                dive.contentOffset.y = dive.offset(for: plan.dive.tops[Tier.allCases.firstIndex(of: tier) ?? 0], at: inset + 60)
            }
            self.opening = nil
        } else {
            if let y = was.0 { overview.contentOffset.y = min(y, max(plan.overview.height - built.height, 0)) }
            if let y = was.1 { dive.contentOffset.y = min(y, max(plan.dive.height - built.height, 0)) }
        }
        settle()

        let art = StrandArt.shared, have = art.have(plan.keys)
        let shown = diving ? dive : overview, other = diving ? overview : dive
        shown.fill(have, 0 ..< shown.count)
        place(have)
        whole = false
        baking?.cancel()
        baking = Task { [weak self] in
            var all = have
            if !shown.whole {
                StrandCount.bakes += 1
                all.merge(await art.bake(shown.rest.pieces.map(\.key) + [StrandPlan.surfaceWords], scale: scale)) { $1 }
                guard !Task.isCancelled else { return }
                shown.fill(all, 0 ..< shown.count)
                self?.place(all)
            }
            if art.have(other.rest.pieces.map(\.key)).count < Set(other.rest.pieces.map(\.key)).count { StrandCount.bakes += 1 }
            all.merge(await art.bake(other.rest.pieces.map(\.key), scale: scale)) { $1 }
            // The hidden rest's layers take their bitmaps a run-loop turn at a time, so no one commit carries them all.
            for from in stride(from: 0, to: other.count, by: 60) {
                guard !Task.isCancelled else { return }
                other.fill(all, from ..< min(from + 60, other.count))
                try? await Task.sleep(for: .milliseconds(4))
            }
            guard !Task.isCancelled, let self else { return }
            art.keep(Set(plan.keys))
            self.backdrop.isHidden = true
            self.whole = true
            #if DEBUG
            self.tour()
            #endif
        }
    }

    private func place(_ art: [StrandKey: StrandBitmap]) {
        guard let words = art[StrandPlan.surfaceWords], surfaceWords.contents == nil else { return }
        surfaceWords.contents = words.image
        surfaceWords.frame = CGRect(x: 14, y: ((52 - words.size.height) / 2).rounded(), width: words.size.width, height: words.size.height)
    }

    /// The rests as they stand with no travel under way.
    private func settle() {
        overview?.isHidden = diving
        dive?.isHidden = !diving
        overview?.isUserInteractionEnabled = !diving
        dive?.isUserInteractionEnabled = diving
        surface.isHidden = !diving
    }

    private func hit(_ hit: StrandHit, _ point: CGPoint) {
        switch hit.what {
        case let .level(level), let .daily(level): onPick(level, point)
        case .endless: onPick(.endless(run?.run ?? Run(seed: .random(in: .min ... .max))), point)
        case let .tier(tier): go(diving: true, tier: tier)
        }
    }

    @objc func rise() {
        guard diving, let plan, let dive else { return }
        // The tier the middle of the screen is in.
        let middle = dive.contentOffset.y + bounds.midY
        go(diving: false, tier: max((plan.dive.tops.lastIndex { $0 <= middle }) ?? 0, 0))
    }

    /// `p` goes to `to + k (p - from)`, as a layer's transform about the screen's middle.
    private func about(_ k: CGFloat, from: CGPoint, to: CGPoint) -> CATransform3D {
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        return CATransform3DMakeAffineTransform(CGAffineTransform(a: k, b: 0, c: 0, d: k, tx: to.x - c.x - k * (from.x - c.x), ty: to.y - c.y - k * (from.y - c.y)))
    }

    /// Between the rests, about `tier`: the rest left grows or shrinks away on top as it fades, over the rest arrived
    /// at, which is whole and takes touches from the first frame. Two animations in the render server; nothing is laid
    /// out or drawn for it.
    func go(diving to: Bool, tier: Int, animated: Bool = true) {
        guard let plan, let overview, let dive, to != diving else { return }
        travels += 1
        let travel = travels
        overview.layer.removeAnimation(forKey: "travel")
        dive.layer.removeAnimation(forKey: "travel")
        // The overview's sight of the tier, and the dive's: the same point of the screen where the dive can scroll there.
        var o = CGPoint(x: bounds.midX, y: plan.overview.tops[tier] - overview.contentOffset.y)
        var d = o
        if to {
            let at = min(max(o.y, inset + 60), bounds.height * 0.4)
            dive.setContentOffset(CGPoint(x: 0, y: dive.offset(for: plan.dive.tops[tier], at: at)), animated: false)
            d.y = plan.dive.tops[tier] - dive.contentOffset.y
        } else {
            overview.setContentOffset(CGPoint(x: 0, y: overview.offset(for: plan.overview.tops[tier], at: bounds.height * 0.3)), animated: false)
            o.y = plan.overview.tops[tier] - overview.contentOffset.y
            d = CGPoint(x: bounds.midX, y: min(max(plan.dive.tops[tier] - dive.contentOffset.y, 0), bounds.height))
        }
        diving = to
        let leaving = to ? overview : dive, arriving = to ? dive : overview
        settle()
        guard animated else { return }
        leaving.isHidden = false
        insertSubview(leaving, belowSubview: surface)
        let far = about(2.2, from: o, to: d), near = about(0.9, from: d, to: o)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let self, self.travels == travel else { return }
            leaving.isHidden = true
        }
        animate(leaving, to: to ? far : near, fade: true)
        animate(arriving, from: to ? near : far)
        if to {
            let show = CABasicAnimation(keyPath: "opacity")
            show.fromValue = 0
            show.toValue = 1
            show.duration = Self.travel
            show.preferredFrameRateRange = Self.fast
            surface.layer.add(show, forKey: "travel")
        }
        CATransaction.commit()
    }

    private func animate(_ column: StrandColumn, from: CATransform3D = CATransform3DIdentity, to: CATransform3D = CATransform3DIdentity, fade: Bool = false) {
        let move = CABasicAnimation(keyPath: "transform")
        move.fromValue = from
        move.toValue = to
        move.timingFunction = CAMediaTimingFunction(name: .easeOut)
        var parts: [CAAnimation] = [move]
        if fade {
            let out = CABasicAnimation(keyPath: "opacity")
            out.fromValue = 1
            out.toValue = 0
            parts.append(out)
        }
        let group = CAAnimationGroup()
        group.animations = parts
        group.duration = Self.travel
        for part in parts + [group] { part.preferredFrameRateRange = Self.fast }
        column.layer.add(group, forKey: "travel")
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        StrandCount.scrolls += 1
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrolled?()
    }
}
