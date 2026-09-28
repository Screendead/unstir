// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

extension Level {
    /// Every twelve levels walk the grid's whole hue sweep, so the first screen shows all of it; whirlpool walks blood
    /// red through magenta to violet, maelstrom crimson down to bile. The daily is amber, endless cyan, the sandbox
    /// magenta.
    var colour: Color {
        guard let n = Int(label) else { return sandbox ? .magenta : run == nil ? .amber : .neonCyan }
        let t = Double((n - 1) % 12) / 11
        return switch tier {
        case .plughole: oklch(0.639, 0.34, 190 + 240 * t)
        case .whirlpool: oklch(0.62, 0.3, 23 - 82 * t)
        case .maelstrom: oklch(0.64, 0.3, 24 + 76 * t)
        }
    }
}

extension Tier {
    var sweep: LinearGradient {
        let colours: [Color] = switch self {
        case .plughole: [.neonCyan, .magenta, .amber]
        case .whirlpool: [.blood, .magenta, .violet]
        case .maelstrom: [Color(0xFF1A2A), Color(0xD4200C), Color(0xB89A00)]
        }
        return LinearGradient(colors: colours, startPoint: .leading, endPoint: .trailing)
    }

    var glow: Color {
        switch self {
        case .plughole: .magenta
        case .whirlpool: .blood
        case .maelstrom: Color(0xE0101C)
        }
    }

    /// The tier `n` rungs up the ladder, or down for negative `n`, if there is one.
    func step(_ n: Int) -> Tier? {
        let i = Self.allCases.firstIndex(of: self)! + n
        return Self.allCases.indices.contains(i) ? Self.allCases[i] : nil
    }

    /// For VoiceOver: the tier, and if it is locked, what opens it.
    var spoken: String {
        guard let below, !isOpen() else { return rawValue }
        let par = below.atPar(), lit = par.filter { $0 }.count
        return "\(rawValue), locked, opens with every \(below.rawValue) tank at par, \(lit) of \(par.count)"
    }
}

/// The tank's own twist as one rod about `centre`: the menu stirs a tier's list away and unstirs the next into place.
struct Stirred: ViewModifier, Animatable {
    var angle: Double
    /// 0 to 1: the list dims and greys as it goes.
    var fade: Double
    var centre: CGPoint
    var radius: CGFloat
    @Environment(\.displayScale) private var scale

    nonisolated var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(angle, fade) }
        set { (angle, fade) = (newValue.first, newValue.second) }
    }

    func body(content: Content) -> some View {
        content
            .layerEffect(
                // A low plateau: the whole disc shears, where the tank's 0.6 would spin the middle rows as a block.
                ShaderLibrary.unstir(.float2(centre), .float(radius), .floatArray([0, 0, 1, Float(angle)]),
                                     .float(1), .float(30), .float(0.1), .float(Float(scale)), .float(Float(0.3 * fade)),
                                     .float3(0, 0, -1), .float(0)),
                // Samples stay in the disc, which reaches past the view's edges by no more than this. The effect draws
                // its margin too, so a wider one is wasted work.
                maxSampleOffset: CGSize(width: max(radius - centre.x, 0), height: max(radius - centre.y, 0)),
                isEnabled: angle != 0 || fade != 0)
            .opacity(1 - 0.8 * fade)
    }
}

struct MenuView: View {
    /// UNSTIR_TIERDEMO: switches tiers on a timer through the same calls a finger makes.
    let demo: Bool
    let onPick: (Level) -> Void
    /// The tier picked in the strip, open or not. `shown` trails it while the old list stirs away, and `listed`, the
    /// scroll view's own list, trails that to the end of the switch: rebuilding it stalls a frame (about 40 ms on the
    /// simulator), unseen once the stir has settled over it.
    @State private var picked: Tier
    @State private var shown: Tier
    @State private var listed: Tier
    @State private var spin = 0.0
    @State private var fade = 0.0
    @State private var busy = false
    /// A drag let go short, springing back.
    @State private var settling = false
    /// Decided on a drag's first move: sideways stirs, anything else scrolls.
    @State private var sideways: Bool?
    /// Resets when a drag ends or is cancelled; `onEnded` runs only when it ends.
    @GestureState private var dragging = false
    /// The scroll view's height and its bottom safe area: the list draws on under the home indicator.
    @State private var viewport: CGFloat = 0
    /// The tier's list in the scroll view's space.
    @State private var list = CGRect.zero
    @Namespace private var strip
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far the outgoing list turns at its centre before the incoming one takes its place.
    private var turn: Double { reduceMotion ? 0 : 1.6 * .pi }
    /// The list's fade at the swap. At 1 the list read as black for about 0.3 s.
    private let dim = 0.55

    /// `start`: the harness's tier, shown even when locked. `frozen`: UNSTIR_TIERSPIN, the list held mid-twist.
    init(start: Tier? = nil, demo: Bool = false, frozen: (spin: Double, fade: Double)? = nil,
         onPick: @escaping (Level) -> Void) {
        self.demo = demo
        self.onPick = onPick
        let tier = start ?? Tier.stored()
        _picked = State(initialValue: tier)
        _shown = State(initialValue: tier)
        _listed = State(initialValue: tier)
        if let frozen {
            _spin = State(initialValue: frozen.spin)
            _fade = State(initialValue: frozen.fade)
            _busy = State(initialValue: true)
        }
    }

    var body: some View {
        // Daily and endless draw on every layout, so they open after the first hex level.
        let modes = Best.unlocked || Best.load(Level.plughole[22].id) != nil
        VStack(alignment: .leading, spacing: 0) {
            title.padding(.horizontal, 20).padding(.top, 28)
            tiers.padding(.top, 6)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Every stir in this tank has an exact inverse.")
                        .font(.mono(13)).opacity(0.55).padding(.top, 10)
                    LevelRow(level: Level.daily(), enabled: modes, pick: pick).padding(.top, 22)
                    LevelRow(level: .endless(Run(seed: .random(in: .min ... .max))),
                             detail: "deeper every tank \u{00B7} one over par ends it",
                             best: Best.tanks > 0 ? Text("best \(Best.tanks)") : nil, enabled: modes, pick: pick)
                    LevelRow(level: .sandbox, detail: "any picture, any rods \u{00B7} nothing counts", enabled: true,
                             pick: pick)
                    TierList(tier: listed, pick: pick).equatable()
                        .opacity(twisting ? 0 : 1)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: { list = $0 }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            // Once a drag is taken as sideways, the list stops scrolling under the stir.
            .scrollDisabled(sideways == true)
            .overlay(alignment: .topLeading) { twisted }
            .onGeometryChange(for: CGFloat.self) { $0.size.height + $0.safeAreaInsets.bottom } action: { viewport = $0 }
            .simultaneousGesture(swipe)
        }
        .foregroundStyle(Color.text)
        .background {
            // Builds the effect's pipeline before the first switch, which would otherwise stall on it.
            Color.black.frame(width: 2, height: 2).drawingGroup()
                .modifier(Stirred(angle: 0.1, fade: 0, centre: .zero, radius: 1))
        }
        .background(Color.black)
        .onChange(of: dragging) {
            // Cancelled, so `onEnded` never ran.
            if !dragging, sideways != nil {
                if sideways == true { released(0, predicted: 0) }
                sideways = nil
            }
        }
        .task { if demo { await tour() } }
    }

    /// While it turns, the list is drawn again, cut to the part on screen, over the scroll view, and that is what
    /// twists: a layer effect blanks a scroll view, and on the whole list its margin is too big. Flattened first, or
    /// with a margin the effect draws only some of the rows.
    private var twisted: some View {
        let w = list.width, top = band.lowerBound, h = band.upperBound - top
        return ZStack(alignment: .top) {
            if twisting {
                TierList(tier: shown, pick: pick).equatable()
                    .fixedSize(horizontal: false, vertical: true).frame(width: w)
                    .alignmentGuide(.top) { _ in top }
            }
        }
        .frame(width: w, height: h, alignment: .top)
        .clipped()
        .drawingGroup()
        .modifier(Stirred(angle: spin, fade: fade, centre: CGPoint(x: w / 2, y: h / 2), radius: reach))
        // The effect draws its sampling margin too, opaque.
        .clipped()
        .padding(.leading, list.minX)
        .padding(.top, list.minY + top)
        .allowsHitTesting(false)
    }

    private var twisting: Bool { busy || settling || sideways == true }

    /// The list's visible part, in its own space.
    private var band: ClosedRange<CGFloat> {
        let top = max(-list.minY, 0)
        return top ... max(min(viewport - list.minY, list.height), top + 1)
    }

    /// The middle of the list's visible part, in the scroll view's space.
    private var pivot: CGFloat { list.minY + (band.lowerBound + band.upperBound) / 2 }

    /// Out to the visible part's corners.
    private var reach: CGFloat { hypot(list.width, band.upperBound - band.lowerBound) / 2 }

    /// Cuts to the new tier's sweep at the swap: a gradient doesn't interpolate, and a cross-fade runs through grey.
    private var title: some View {
        Text("UNSTIR").font(.system(size: 34, weight: .black).width(.expanded)).tracking(8)
            .foregroundStyle(shown.sweep).shadow(color: shown.glow.opacity(0.6), radius: 12)
    }

    /// Every tier by name. Scrolls sideways once there are more than fit, keeping the picked one in view.
    private var tiers: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Tier.allCases, id: \.self) { t in
                        if t != Tier.allCases.first {
                            Text("\u{00B7}").font(.mono(15)).opacity(0.3).padding(.horizontal, 7).frame(height: 36)
                        }
                        Button { select(t) } label: { name(t) }
                            .buttonStyle(.plain)
                            .id(t)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            // Names run out into the black at the edges, so a strip wider than the screen reads as one that scrolls.
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.04),
                                         .init(color: .black, location: 0.9), .init(color: .clear, location: 1)],
                                 startPoint: .leading, endPoint: .trailing))
            .onChange(of: picked) { withAnimation { proxy.scrollTo(picked, anchor: .center) } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tier")
        .accessibilityValue(picked.spoken)
        .accessibilityAdjustableAction { direction in
            let n = switch direction {
            case .increment: 1
            case .decrement: -1
            @unknown default: 0
            }
            if let t = picked.step(n) { select(t) }
        }
    }

    private func name(_ t: Tier) -> some View {
        let isPicked = t == picked, open = t.isOpen()
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Text(t.rawValue).font(.mono(15, isPicked ? .semibold : .regular))
                    .foregroundStyle(isPicked ? AnyShapeStyle(t.sweep)
                                              : AnyShapeStyle(Color.text.opacity(open ? 0.6 : 0.36)))
                    .shadow(color: isPicked ? t.glow.opacity(0.8) : .clear, radius: 7)
                if !open {
                    Image(systemName: "lock.fill").font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isPicked ? t.glow : Color.text.opacity(0.36))
                }
            }
            .frame(height: 36)
            // The underline slides to the picked name as soon as it is picked; the list follows once it has stirred
            // away.
            if isPicked {
                Capsule().fill(t.sweep).frame(height: 2).shadow(color: t.glow, radius: 4)
                    .matchedGeometryEffect(id: "underline", in: strip)
            } else {
                Color.clear.frame(height: 2)
            }
        }
        .padding(.bottom, 6)
        .contentShape(Rectangle())
    }

    private func select(_ t: Tier) {
        guard let from = Tier.allCases.firstIndex(of: shown), let to = Tier.allCases.firstIndex(of: t) else { return }
        go(to: t, turning: to > from ? 1 : -1)
    }

    /// The outgoing list stirs away, then the incoming one unstirs, turning on the same way.
    private func go(to t: Tier, turning dir: Double) {
        guard t != shown, !busy else { return }
        busy = true
        Tier.store(t)
        withAnimation(.snappy(duration: 0.35)) { picked = t }
        withAnimation(.easeIn(duration: 0.32)) {
            spin = dir * turn
            fade = dim
        } completion: {
            shown = t
            spin = -dir * turn
            withAnimation(.easeOut(duration: 0.62)) {
                spin = 0
                fade = 0
            } completion: {
                listed = t
                busy = false
            }
        }
    }

    /// A drag is the strip's once its first 15 points run at least twice as far sideways as up or down; the scroll view
    /// keeps anything steeper, and the drag is then ignored to its end.
    nonisolated static func isSideways(_ move: CGSize) -> Bool { abs(move.width) > 2 * abs(move.height) }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 15)
            .updating($dragging) { _, dragging, _ in dragging = true }
            .onChanged { v in moved(v.translation, from: v.startLocation.y) }
            .onEnded { v in lifted(v.translation.width, predicted: v.predictedEndTranslation.width) }
    }

    private func moved(_ move: CGSize, from y: CGFloat) {
        if sideways == nil { sideways = Self.isSideways(move) }
        if sideways == true { dragged(move.width, at: y) }
    }

    private func lifted(_ dx: CGFloat, predicted: CGFloat) {
        if sideways == true { released(dx, predicted: predicted) }
        sideways = nil
    }

    /// A sideways drag stirs the list about the middle of the screen, the way the finger pulls it: leftward below the
    /// middle turns clockwise. Left heads for the next tier; with none that way it barely gives.
    private func dragged(_ dx: CGFloat, at y: CGFloat) {
        guard !busy else { return }
        let next = shown.step(dx < 0 ? 1 : -1)
        let hand = y > pivot ? 1.0 : -1.0
        let angle = -Double(dx) / 120 * hand * (next == nil ? 0.2 : 1)
        spin = reduceMotion ? 0 : angle
        fade = min(abs(angle) / (1.6 * .pi), 1) * dim
    }

    private func released(_ dx: CGFloat, predicted: CGFloat) {
        guard !busy else { return }
        if let next = shown.step(dx < 0 ? 1 : -1), abs(dx) > 70 || abs(predicted) > 200 {
            go(to: next, turning: spin < 0 ? -1 : 1)
        } else {
            settling = true
            withAnimation(.spring(duration: 0.4)) {
                spin = 0
                fade = 0
            } completion: {
                settling = false
            }
        }
    }

    /// Plughole, swiped to whirlpool, swiped to maelstrom, then plughole tapped in the strip.
    private func tour() async {
        func pause(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        // A finger's leftward swipe below the middle of the list, at 60 Hz, easing out, then let go.
        func swipe(_ dx: CGFloat) async {
            let y = pivot + 0.25 * reach
            for i in 1...20 {
                let t = Double(i) / 20
                moved(CGSize(width: dx * (1 - (1 - t) * (1 - t)), height: 0), from: y)
                await pause(1 / 60)
            }
            lifted(dx, predicted: 1.8 * dx)
        }
        await pause(1.6)
        await swipe(-140)
        await pause(2.8)
        await swipe(-140)
        await pause(3.4)
        select(.plughole)
    }

    /// A touch that ends a stir must not open the row it lifted over.
    private func pick(_ level: Level) { if !twisting { onPick(level) } }
}

/// A tier's rule and rows, and a locked tier's gate. Compared by tier alone, so a frame of a drag or a stir doesn't
/// rebuild it: nothing else it reads changes while the menu is up.
private struct TierList: View, Equatable {
    let tier: Tier
    let pick: (Level) -> Void

    nonisolated static func == (a: Self, b: Self) -> Bool { a.tier == b.tier }

    var body: some View {
        let open = tier.isOpen()
        return VStack(alignment: .leading, spacing: 0) {
            header(open: open)
            if !open, let below = tier.below { gate(below) }
            let levels = tier.levels
            ForEach(Array(levels.enumerated()), id: \.offset) { i, level in
                let reached = Best.unlocked || i == 0 || Best.load(levels[i - 1].id) != nil
                LevelRow(level: level, enabled: open && reached, pick: pick)
            }
        }
    }

    /// The tier's rule, named, with its progress.
    private func header(open: Bool) -> some View {
        let par = tier.atPar()
        return HStack(spacing: 10) {
            Text(tier.rawValue).font(.mono(11, .semibold)).foregroundStyle(tier.sweep)
            Rectangle().fill(tier.sweep).frame(height: 1).opacity(0.8)
            Text(open ? "\(par.filter { $0 }.count)/\(par.count) at par" : "locked").font(.mono(11)).opacity(0.4)
        }
        .padding(.top, 14).padding(.bottom, 8)
    }

    /// What opens a locked tier: a tick per level of the tier below, lit once that level is at par.
    private func gate(_ below: Tier) -> some View {
        let par = below.atPar(), lit = par.filter { $0 }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 11, weight: .semibold))
                Text("opens with every \(below.rawValue) tank at par").font(.mono(12))
                Spacer(minLength: 0)
                Text("\(lit)/\(par.count)").font(.mono(13, .semibold))
            }
            .foregroundStyle(tier.glow)
            .shadow(color: tier.glow.opacity(0.5), radius: 5)
            HStack(spacing: 0) {
                ForEach(Array(zip(below.levels, par).enumerated()), id: \.offset) { i, tick in
                    if i > 0 { Spacer(minLength: 0) }
                    Capsule().fill(tick.1 ? tick.0.colour : Color.text.opacity(0.24)).frame(width: 3, height: 16)
                        .shadow(color: tick.1 ? tick.0.colour : .clear, radius: 3)
                }
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Locked. Opens with every \(below.rawValue) tank at par: \(lit) of \(par.count).")
    }
}

private struct LevelRow: View {
    let level: Level
    var detail: String?
    var best: Text?
    let enabled: Bool
    let pick: (Level) -> Void

    var body: some View {
        let result = Best.load(level.id)
        return Button { pick(level) } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // A locked number stays bright enough that the hue walk still reads on first launch.
                Text(level.label).font(.mono(13, .semibold)).foregroundStyle(level.colour)
                    .shadow(color: enabled ? level.colour : .clear, radius: 4).opacity(enabled ? 1 : 0.7)
                    .frame(width: 34, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title).font(.mono(14)).multilineTextAlignment(.leading)
                    Text(detail ?? "\(level.layout.rods.count) rods \u{00B7} par \(level.par)").font(.mono(11)).opacity(0.32)
                }
                .opacity(enabled ? 1 : 0.38)
                Spacer(minLength: 8)
                Group {
                    if let best {
                        best.opacity(0.55)
                    } else if let result, result.clean == true {
                        Text("clean").fontWeight(.semibold).foregroundStyle(Color.lime).shadow(color: .lime, radius: 3)
                    } else if let result, result.over == 0 {
                        // Hints aside, as the tier gate counts it.
                        Text("par").foregroundStyle(Color.amber)
                    } else if let result {
                        Text("+\(result.over)").foregroundStyle(Color.magenta)
                    }
                }
                .font(.mono(11))
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
