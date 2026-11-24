// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What a screen asks of the ground beyond the camera, each from 0 to 1 and each animatable: how far a level has
/// taken the screen (the shelf draws aside and one terrace rises under the tank, `SlopeLay.terrace`), a solved tank's
/// glint, Prism's clear water, the ground's light (consent and the wide result draw it at 0.35) and how far it is
/// Escapement's page. The lone terrace is cut from `rock` and lit in `glow`, and `upper` stands a second over it.
struct SlopeLook: Equatable {
    var level = 0.0
    var glint = 0.0
    var clear = 0.0
    var light = 1.0
    var paper = 0.0
    var rock = SlopeColumn.Rock.sand
    /// The terrace's and the glint's light; warm when nil.
    var glow: SIMD3<Float>?
    /// A second terrace over the lone one, for a stone with a row of its own (wait, up a notch): the middle of its
    /// top on the screen, where that stone rests, and its width. It comes and goes with `level`.
    var upper: CGPoint?
    var upperWidth: CGFloat = 170
}

/// A column laid out and seen from a camera on a screen: what a screen's own views read their places from.
struct SlopeView {
    let lay: SlopeLay
    let top: CGFloat
    let size: CGSize
    /// How far a finger has pulled the camera off its place, already in `top`: everything on the column stands this
    /// much lower on the screen than `unpulled` has it.
    var pull: CGFloat = 0

    /// The camera where it rests: a pull moves the whole column as one, so a screen lays it out from here once and
    /// moves it by `pull`.
    var unpulled: SlopeView { SlopeView(lay: lay, top: top + pull, size: size) }

    /// A point of the column (x, depth) on the screen.
    func point(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x, y: p.y - top) }
    func y(_ depth: CGFloat) -> CGFloat { depth - top }
    /// Where ledge `n`'s pebble rests, and its lip.
    func seat(_ n: Int) -> CGPoint { point(lay.seat(n)) }
    func lip(_ n: Int) -> CGPoint { point(lay.lip(n)) }
    /// The stone on the dry bank, settings'.
    var bank: CGPoint { SlopeLay.bank(SlopeCamera(top: top, z: lay.z)) }
    /// The bank's top under that stone: where it rests (`rested(at:)`).
    var bankSeat: CGPoint { CGPoint(x: bank.x, y: bank.y + 5) }
}

/// The slope's ground (Slope.metal) for one camera. It drifts on its own clock, at 30 Hz, and draws again only for
/// that or a new camera. `held` stops the clock (a level is on screen, or something covers the slope), as `Power`
/// does while it saves or idles, and Reduce Motion never starts it: then the ground is a still. With `eggs`, the
/// menu's, an idle clock slows to its stop as the water goes still (`Calm`), and the ground draws until it has.
struct SlopeGround: View {
    let view: SlopeView
    var held = false
    var look = SlopeLook()
    /// The clock held at these seconds, for a harness's stills.
    var clock: Double?
    /// The near silhouette, the dive's alone; the largest type sizes and a level in play leave it out.
    var near = true
    /// Draws only this much of the screen's top, as the same ground would there.
    var band: CGFloat?
    var eggs: SlopeEggs?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var scale
    /// When the clock read 0; and when it last stopped, with what still water had cost it by then.
    @State private var epoch = Date.now
    @State private var stopped: (at: Date, lost: Double)?
    /// What still water had cost every clock before this one began.
    @State private var before = Power.shared.calm.lost(.now)
    /// Since when the camera has been held past the column's foot.
    @State private var sunk: Date?

    /// Nothing may move: the ground is a still whatever is asked of it.
    private var fixed: Bool { held || reduceMotion || look.paper >= 1 || Power.shared.saving }
    /// The water is going still, or coming back.
    private var turning: Bool { eggs != nil && !fixed && Power.shared.turning }
    /// A stone is skimming over it.
    private var skimming: Bool { eggs?.skim != nil && !fixed }
    /// How far past the foot of its travel the camera is: the menu's alone, where the foot is the drop-off.
    private var past: CGFloat {
        eggs != nil && rests && view.lay.column.foot == .dropOff ? view.top - view.lay.travel(height: view.size.height).upperBound : 0
    }
    /// The camera is at one of its two zooms: on its way between them it may pass either end of the travel, and that
    /// is no pull.
    private var rests: Bool { view.lay.e <= 0 || view.lay.e >= 1 }
    /// The mirrored sky's lights are coming out.
    private var dawning: Bool { past > SlopeEggs.held && !fixed }
    private var still: Bool { fixed || !turning && !skimming && !dawning && (clock != nil || Power.shared.idle) }

    #if DEBUG
    /// How many times a whole ground has been worked out for drawing, for `SlopeMenu.tour`'s log.
    static var draws = 0
    #endif

    /// How far the surface line stands off its place at x: Slope.metal's sway.
    private static func sway(_ x: CGFloat, _ t: Double, calm: Double) -> CGFloat {
        (1 - calm) * (3.2 * sin(x * 0.024 + t * 1.1) + 1.8 * sin(x * 0.063 - t * 1.6 + 1.3))
    }

    var body: some View {
        // A skimmed stone moves at the display's rate; the drift alone needs 30 Hz.
        TimelineView(.animation(minimumInterval: skimming ? nil : 1.0 / 30, paused: still)) { timeline in
            let power = Power.shared
            let lost = eggs == nil ? 0 : (stopped?.lost ?? power.calm.lost(timeline.date)) - before
            let t = clock ?? (reduceMotion ? 0 : (stopped?.at ?? timeline.date).timeIntervalSince(epoch) - lost)
            let calm = eggs == nil || fixed ? 0 : power.turning ? power.calm.level(timeline.date) : power.calm.to
            // The night stands over a surface pulled down past its place.
            let lift = eggs != nil && rests && view.lay.column.surface ? view.lay.travel(height: view.size.height).lowerBound - view.top : 0
            // The mirrored sky's lights come out while the camera is held past the foot; where nothing may move, all at once.
            let waited = min(max((sunk.map { timeline.date.timeIntervalSince($0) } ?? 0) / SlopeEggs.dawning, 0), 1)
            let out = fixed ? 1 : waited * waited * (3 - 2 * waited)
            let mirror = view.top - past + view.size.height
            let glow = look.glow ?? SIMD3(1, 0.86, 0.6)
            #if DEBUG
            let _ = band == nil ? Self.draws += 1 : ()
            #endif
            ZStack {
                let common: [Shader.Argument] = [
                    .float2(view.size),
                    .float4(scale, t, near ? view.lay.e * (1 - look.level) : 0, 1),
                    .float4(look.level, look.glint, look.clear, look.light),
                    .float4(glow.x, glow.y, glow.z, Float(look.rock.rawValue)),
                    .float(look.paper),
                    .float4(look.upper?.x ?? 0, look.upper?.y ?? 0, look.upperWidth / 2, look.upper == nil ? 0 : 1),
                    .floatArray(view.lay.uniforms(top: view.top, height: view.size.height))]
                // The menu's ground is its own function, so no other pays for an egg it never shows.
                let shader = eggs.map {
                    Shader(function: ShaderLibrary.default.slopeMenu, arguments: common + [.floatArray(
                        $0.uniforms(calm: calm, night: SlopeEggs.night(lift: lift), deep: SlopeEggs.deep(sunk: past), out: out,
                                    mirror: mirror, lay: view.lay, at: timeline.date))])
                } ?? Shader(function: ShaderLibrary.default.slope, arguments: common)
                Rectangle().fill(.black).colorEffect(shader)
                // The veil's band draws the water again, not what is on it.
                if let skim = eggs?.skim, skimming, band == nil {
                    SlopeSkimLayer(skim: skim, date: timeline.date) { -view.top + Self.sway($0, t, calm: calm) }
                        .frame(width: view.size.width, height: view.size.height)
                }
            }
        }
        .onChange(of: past > SlopeEggs.held) { sunk = past > SlopeEggs.held ? .now : nil }
        .onChange(of: still, initial: true) {
            let now = Date.now, lost = eggs == nil ? 0 : Power.shared.calm.lost(now)
            if still {
                stopped = (now, lost)
            } else if let stopped {
                // The clock takes up where it stopped, so nothing jumps.
                epoch += now.timeIntervalSince(stopped.at) - (lost - stopped.lost)
                self.stopped = nil
            }
        }
        .frame(width: view.size.width, height: band ?? view.size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A column seen from a camera that may travel and open: the ground, and over it whatever `content` sets on it from
/// the same frame, so a pebble stays on its ledge all the way from the overview to the dive. The camera holds ledge
/// `focus`'s top at `at`, a share of the screen's height, at zoom `z`, moved down the screen by `pull`; those three
/// and the look animate.
struct SlopeScene<Content: View>: View, Animatable {
    var column: SlopeColumn
    var focus: Int
    var at: CGFloat
    var z: CGFloat
    var pull: CGFloat = 0
    var held = false
    var look = SlopeLook()
    var clock: Double?
    var near = true
    var eggs: SlopeEggs?
    @ViewBuilder var content: (SlopeView) -> Content

    nonisolated var animatableData: AnimatablePair<AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>,
        AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, AnimatablePair<Double, Double>>>> {
        get {
            AnimatablePair(AnimatablePair(at, AnimatablePair(z, pull)), AnimatablePair(AnimatablePair(look.level, look.glint),
                                                                                       AnimatablePair(look.clear, AnimatablePair(look.light, look.paper))))
        }
        set {
            at = newValue.first.first
            z = newValue.first.second.first
            pull = newValue.first.second.second
            look.level = newValue.second.first.first
            look.glint = newValue.second.first.second
            look.clear = newValue.second.second.first
            look.light = newValue.second.second.second.first
            look.paper = newValue.second.second.second.second
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.whole
            let lay = SlopeLay(column, z: z)
            let view = SlopeView(lay: lay, top: lay.camera(on: focus, at: at, height: size.height).top - pull, size: size, pull: pull)
            SlopeLayer {
                SlopeGround(view: view, held: held, look: look, clock: clock, near: near, eggs: eggs)
                content(view)
            }
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea()
        }
    }
}

extension SlopeScene {
    /// The share of a screen `height` tall at which the overview holds ledge `n`.
    static func overview(_ column: SlopeColumn, holding n: Int, height: CGFloat) -> CGFloat {
        (SlopeLay(column, z: 0).tops[n] - SlopeLay.overview(height: height).top) / height
    }
}

/// The dive as a finger moves it: a column at full depth (or at any one zoom `z`), scrolled natively from its surface
/// to its foot. `content`
/// is laid out once, in the scrolled content's own frame (`SlopeView.point` gives a place in the column its place
/// there), and the ground is drawn for wherever the scroll has reached, in the same pass that moves the content, so
/// the two never part. It opens on `aim`, the same camera a `SlopeScene` at `z` 1 has for that ledge and share, kept
/// inside the dive's travel (`SlopeLay.rest`), and when `aim` changes it travels there in `seconds`, or cuts under
/// Reduce Motion; with no aim it opens at the surface. `onMove` hears the camera's depth as the scroll moves.
struct SlopeDive<Content: View>: View {
    var column: SlopeColumn
    var aim: SlopeAim?
    /// 1, the dive; 0 scrolls the overview, for a column grown past the screen at the largest type sizes.
    var z: CGFloat = 1
    var seconds = 0.9
    var held = false
    var look = SlopeLook()
    var clock: Double?
    var near = true
    var eggs: SlopeEggs?
    var onMove: ((CGFloat) -> Void)?
    @ViewBuilder var content: (SlopeView) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static var space: String { "slope.dive" }
    private static var mark: String { "slope.aim" }

    var body: some View {
        GeometryReader { geo in
            let size = geo.whole
            let lay = SlopeLay(column, z: z), travel = lay.travel(height: size.height)
            let base = SlopeView(lay: lay, top: travel.lowerBound, size: size)
            let rest = aim.map { lay.rest($0, height: size.height) }
            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: false) {
                    SlopeLayer {
                        GeometryReader { inner in
                            let offset = -inner.frame(in: .named(Self.space)).minY
                            SlopeGround(view: SlopeView(lay: lay, top: base.top + offset, size: size), held: held, look: look,
                                        clock: clock, near: near, eggs: eggs)
                                .offset(y: offset)
                                .preference(key: SlopeDiveTop.self, value: Optional(base.top + offset))
                        }
                        // The scroll's one target: the content's line that the aim puts at the screen's middle, which
                        // lies inside the content at both ends of the travel, as the line at the screen's top does not.
                        Color.clear.frame(width: 1, height: 1)
                            .slopePlace(CGPoint(x: 0, y: base.y(rest ?? travel.lowerBound) + size.height / 2))
                            .id(Self.mark)
                        content(base)
                    }
                    .frame(width: size.width, height: travel.upperBound - travel.lowerBound + size.height)
                }
                .coordinateSpace(.named(Self.space))
                // A scroll view keeps its content clear of the status bar and the home bar, and its scroll targets
                // stop short of both; the slope runs under them, so it gives that room back.
                .safeAreaPadding(.top, -geo.safeAreaInsets.top)
                .safeAreaPadding(.bottom, -geo.safeAreaInsets.bottom)
                .ignoresSafeArea()
                // Under the status bar the words and pebbles sink away into the water: the ground alone is drawn again
                // over them there, whole down to the bar's foot and gone 30 pt under it, so the water still runs
                // to the edge and no row is cut off or stands behind the clock.
                .overlayPreferenceValue(SlopeDiveTop.self, alignment: .top) { top in
                    let veil = geo.safeAreaInsets.top + 30
                    if let top, geo.safeAreaInsets.top > 0 {
                        SlopeGround(view: SlopeView(lay: lay, top: top, size: size), held: eggs == nil || held, look: look,
                                    clock: clock ?? 0, near: near, band: veil, eggs: eggs)
                            .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: geo.safeAreaInsets.top / veil),
                                                         .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
                            .ignoresSafeArea()
                    }
                }
                .onPreferenceChange(SlopeDiveTop.self) { top in if let top { onMove?(top) } }
                .onAppear { if aim != nil { reader.scrollTo(Self.mark, anchor: .center) } }
                .onChange(of: aim) {
                    // An aim taken away leaves the dive where the finger has it.
                    guard aim != nil else { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: seconds)) { reader.scrollTo(Self.mark, anchor: .center) }
                }
            }
        }
    }
}

extension SlopeDive {
    /// The dive opening with ledge `start` at the screen's middle.
    @available(*, deprecated, message: "pass aim: SlopeAim(ledge:)")
    init(column: SlopeColumn, start: Int?, held: Bool = false, look: SlopeLook = SlopeLook(), clock: Double? = nil, near: Bool = true,
         @ViewBuilder content: @escaping (SlopeView) -> Content) {
        self.init(column: column, aim: start.map { SlopeAim(ledge: $0, share: 0.5) }, held: held, look: look, clock: clock, near: near,
                  content: content)
    }
}

/// The inside of a hollow (docs/slope.md, 8.2; Slope.metal's `slopeHollow`): still dark water between two jambs of pale
/// stone, a floor and a ledge, and the cover's light falling from `source`, a point of the view, in three soft beams
/// of the pack's colours. A still: it has no clock.
struct SlopeHollowGround: View {
    var source: UnitPoint = UnitPoint(x: 0.5, y: 0.3)
    var beams: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)

    @Environment(\.displayScale) private var scale

    var body: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                              height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
            Rectangle().fill(.black)
                .colorEffect(ShaderLibrary.slopeHollow(
                    .float2(size), .float4(scale, 0, 0, 0), .float2(source.x * size.width, source.y * size.height),
                    .float3(beams.0.x, beams.0.y, beams.0.z), .float3(beams.1.x, beams.1.y, beams.1.z),
                    .float3(beams.2.x, beams.2.y, beams.2.z)))
                .frame(width: size.width, height: size.height)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The depth at a dive's screen top, handed up from inside its scroll.
private struct SlopeDiveTop: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    // Only the ground says where it is; its siblings' silence must not take that away.
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) { value = nextValue() ?? value }
}

private extension GeometryProxy {
    /// The whole screen's size, the safe areas in.
    var whole: CGSize {
        CGSize(width: size.width + safeAreaInsets.leading + safeAreaInsets.trailing,
               height: size.height + safeAreaInsets.top + safeAreaInsets.bottom)
    }
}

/// Lays views out at points of its own frame, as the slope's screens place everything: a child says where it goes
/// with `slopePlace`, `slopeLine`, `seated` or `rested`, and one that says nothing fills the frame. A placed child is offered
/// the width from its point to 16 pt short of the frame's side (one placed by its middle, the frame's width less
/// both margins, and it moves aside to stay inside them), so its words wrap there; one that would fill what
/// it is offered (a spacer, a bare shape) needs its own frame. Each child keeps its own frame where it is drawn, so a
/// scroll's targets, VoiceOver and taps find it there.
struct SlopeLayer: SwiftUI.Layout {
    struct Place: Equatable {
        var point: CGPoint
        var anchor = UnitPoint.center
        /// Words: their leading edge at the point, their first line's middle level with it.
        var line = false
        /// A stone: its pebble's underside and middle at the point, its words wherever they fall.
        var rest = false
    }

    /// What a placed view keeps clear of the frame's sides, and the least width it is ever offered.
    static let margin: CGFloat = 16
    static let least: CGFloat = 60

    private struct PlaceKey: LayoutValueKey {
        static let defaultValue: Place? = nil
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            guard let place = subview[PlaceKey.self] else {
                subview.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
                continue
            }
            if place.rest {
                // The words run from the pebble towards whichever side they are on, as far as that side's margin.
                let loose = subview.dimensions(in: .unspecified), middle = loose[HorizontalAlignment.stoneMiddle]
                let room = middle < loose.width / 2 ? bounds.width - Self.margin - place.point.x + middle
                    : place.point.x - Self.margin + loose.width - middle
                let proposal = ProposedViewSize(width: max(room, Self.least), height: nil)
                let own = subview.dimensions(in: proposal)
                subview.place(at: CGPoint(x: bounds.minX + place.point.x - own[HorizontalAlignment.stoneMiddle],
                                          y: bounds.minY + place.point.y - own[VerticalAlignment.stoneSeat]),
                              anchor: .topLeading, proposal: proposal)
                continue
            }
            // Its room runs to `margin` short of the frame's edges on the sides it grows towards, so words wrap inside
            // the screen and are never cut off.
            let ax = place.line ? 0 : place.anchor.x
            let before = place.point.x - Self.margin, after = bounds.width - Self.margin - place.point.x
            // Words that lead from their point have the room after it, ones that trail the room before it; anything
            // else may be as wide as the frame less its margins, and gives way sideways to stay inside them.
            let room = ax == 0 ? after : ax == 1 ? before : bounds.width - 2 * Self.margin
            let proposal = ProposedViewSize(width: max(room, Self.least), height: nil)
            let own = subview.dimensions(in: proposal)
            var x = place.point.x - own.width * ax
            if ax > 0, ax < 1, own.width > Self.least {
                x = max(Self.margin, min(x, bounds.width - Self.margin - own.width))
            }
            let y = place.point.y - (place.line ? own[.firstTextBaseline] * 0.62 : own.height * place.anchor.y)
            subview.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), anchor: .topLeading, proposal: proposal)
        }
    }

    fileprivate static func value<V: View>(_ view: V, _ place: Place) -> some View { view.layoutValue(key: PlaceKey.self, value: place) }
}

extension View {
    /// In a `SlopeLayer`: the view with its `anchor` at `point`.
    func slopePlace(_ point: CGPoint, anchor: UnitPoint = .center) -> some View {
        SlopeLayer.value(self, .init(point: point, anchor: anchor))
    }

    /// In a `SlopeLayer`: words with their leading edge at `point` and their first line's middle level with it, as a
    /// row's words stand beside its pebble.
    func slopeLine(_ point: CGPoint) -> some View { SlopeLayer.value(self, .init(point: point, line: true)) }

    /// In a `SlopeLayer`: a `Stone`, or anything holding one pebble, with that pebble resting at `point` of the ground
    /// (a seat, a point of the lone terrace), its words beside it wrapping short of the screen's side.
    func rested(at point: CGPoint) -> some View { SlopeLayer.value(self, .init(point: point, rest: true)) }

    /// In a `SlopeLayer`: a pebble set on its seat (`SlopeView.seat`), its underside a little into the sand.
    func seated(at seat: CGPoint) -> some View { slopePlace(seat, anchor: UnitPoint(x: 0.5, y: 0.93)) }
}

extension SlopeColumn {
    /// The main column on a screen of `size` at a Dynamic Type size (1.6): the pitch grows to hold a ledge's row, and
    /// from accessibility1 up the slope keeps to the leading edge and steps less, at the overview too, where a screen
    /// then gives each stretch the `height` its words need. On a narrower phone the lips move in by half the width
    /// lost. `header` is the room a tier's header takes in the dive.
    static func main(size: CGSize, type: DynamicTypeSize, header: CGFloat? = nil) -> SlopeColumn {
        let large = type.isAccessibilitySize
        let row = TypeRole.body.line(at: type).height * (large ? 2 : 1) + TypeRole.detail.line(at: type).height
        var column = main(size: size, pitch: max(110, row + 60), lip: large ? 62 : 132 - max(440 - size.width, 0) / 2,
                          step: large ? 1.5 : 6, header: header)
        if large {
            column.wall = 14
            column.spread = 8
        }
        return column
    }

    /// The main column's ledge for `level`, a tier's own.
    static func ledge(of level: Level) -> Int? {
        guard level.pack == nil, let tier = Tier.allCases.firstIndex(of: level.tier),
              let index = level.tier.levels.firstIndex(where: { $0.id == level.id }) else { return nil }
        return ledge(tier: tier, level: index + 1)
    }
}
