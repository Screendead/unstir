// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What a screen asks of the ground beyond the camera, each from 0 to 1 and each animatable: how far a level has
/// taken the screen (the shelf draws aside and one terrace rises under the tank, `SlopeLay.terrace`), a solved tank's
/// glint, Prism's clear water, the ground's light (consent and the wide result draw it at 0.35) and how far it is
/// Escapement's page. The lone terrace is cut from `rock` and lit in `glow`.
struct SlopeLook: Equatable {
    var level = 0.0
    var glint = 0.0
    var clear = 0.0
    var light = 1.0
    var paper = 0.0
    var rock = SlopeColumn.Rock.sand
    /// The terrace's and the glint's light; warm when nil.
    var glow: SIMD3<Float>?
}

/// A column laid out and seen from a camera on a screen: what a screen's own views read their places from.
struct SlopeView {
    let lay: SlopeLay
    let top: CGFloat
    let size: CGSize

    /// A point of the column (x, depth) on the screen.
    func point(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x, y: p.y - top) }
    func y(_ depth: CGFloat) -> CGFloat { depth - top }
    /// Where ledge `n`'s pebble rests, and its lip.
    func seat(_ n: Int) -> CGPoint { point(lay.seat(n)) }
    func lip(_ n: Int) -> CGPoint { point(lay.lip(n)) }
    /// The stone on the dry bank, settings'.
    var bank: CGPoint { SlopeLay.bank(SlopeCamera(top: top, z: lay.z)) }
}

/// The slope's ground (Slope.metal) for one camera. It drifts on its own clock, at half the screen's rate, and draws
/// again only for that or a new camera: `held` stops the clock (a level is on screen, something covers the slope,
/// `Power` saves or idles), and Reduce Motion never starts it, so then it is a still.
struct SlopeGround: View {
    let view: SlopeView
    var held = false
    var look = SlopeLook()
    /// The clock held at these seconds, for a harness's stills.
    var clock: Double?
    /// The near silhouette, the dive's alone; the largest type sizes and a level in play leave it out.
    var near = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var scale
    /// When the clock read 0, and when it last stopped.
    @State private var epoch = Date.now
    @State private var stopped: Date?

    private var still: Bool { held || reduceMotion || clock != nil || look.paper >= 1 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still)) { timeline in
            let t = clock ?? (reduceMotion ? 0 : (stopped ?? timeline.date).timeIntervalSince(epoch))
            let glow = look.glow ?? SIMD3(1, 0.86, 0.6)
            Rectangle().fill(.black)
                .colorEffect(ShaderLibrary.slope(
                    .float2(view.size),
                    .float4(scale, t, near ? view.lay.e * (1 - look.level) : 0, 1),
                    .float4(look.level, look.glint, look.clear, look.light),
                    .float4(glow.x, glow.y, glow.z, Float(look.rock.rawValue)),
                    .float(look.paper),
                    .floatArray(view.lay.uniforms(top: view.top))))
        }
        .onChange(of: still, initial: true) {
            if still {
                stopped = .now
            } else if let at = stopped {
                // The clock takes up where it stopped, so nothing jumps.
                epoch += Date.now.timeIntervalSince(at)
                stopped = nil
            }
        }
        .frame(width: view.size.width, height: view.size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A column seen from a camera that may travel and open: the ground, and over it whatever `content` sets on it from
/// the same frame, so a pebble stays on its ledge all the way from the overview to the dive. The camera holds ledge
/// `focus`'s top at `at`, a share of the screen's height, at zoom `z`; those two and the look animate.
struct SlopeScene<Content: View>: View, Animatable {
    var column: SlopeColumn
    var focus: Int
    var at: CGFloat
    var z: CGFloat
    var held = false
    var look = SlopeLook()
    var clock: Double?
    var near = true
    @ViewBuilder var content: (SlopeView) -> Content

    nonisolated var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>,
        AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, AnimatablePair<Double, Double>>>> {
        get {
            AnimatablePair(AnimatablePair(at, z), AnimatablePair(AnimatablePair(look.level, look.glint),
                                                                  AnimatablePair(look.clear, AnimatablePair(look.light, look.paper))))
        }
        set {
            at = newValue.first.first
            z = newValue.first.second
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
            let view = SlopeView(lay: lay, top: lay.camera(on: focus, at: at, height: size.height).top, size: size)
            SlopeLayer {
                SlopeGround(view: view, held: held, look: look, clock: clock, near: near)
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

/// The dive as a finger moves it: a column at full depth, scrolled natively from its surface to its foot. `content`
/// is laid out once, in the scrolled content's own frame (`SlopeView.point` gives a place in the column its place
/// there), and the ground is drawn for wherever the scroll has reached, in the same pass that moves the content, so
/// the two never part. `start` is the ledge the dive opens on, held at the screen's middle.
struct SlopeDive<Content: View>: View {
    var column: SlopeColumn
    var start: Int?
    var held = false
    var look = SlopeLook()
    var clock: Double?
    var near = true
    @ViewBuilder var content: (SlopeView) -> Content

    private static var space: String { "slope.dive" }

    var body: some View {
        GeometryReader { geo in
            let size = geo.whole
            let lay = SlopeLay(column, z: 1), travel = lay.travel(height: size.height)
            // The scroll view keeps its content clear of the status bar, so the content's top is that much lower in
            // the column than the screen's is at rest.
            let base = SlopeView(lay: lay, top: travel.lowerBound + geo.safeAreaInsets.top, size: size)
            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: false) {
                    SlopeLayer {
                        GeometryReader { inner in
                            let offset = -inner.frame(in: .named(Self.space)).minY
                            SlopeGround(view: SlopeView(lay: lay, top: base.top + offset, size: size), held: held, look: look,
                                        clock: clock, near: near)
                                .offset(y: offset)
                        }
                        ForEach(0 ..< lay.count, id: \.self) { n in
                            Color.clear.frame(width: 1, height: 1).slopePlace(CGPoint(x: 0, y: base.y(lay.tops[n]))).id(n)
                        }
                        content(base)
                    }
                    .frame(width: size.width, height: travel.upperBound + size.height - base.top - geo.safeAreaInsets.bottom)
                }
                .coordinateSpace(.named(Self.space))
                .ignoresSafeArea()
                .onAppear { if let start { reader.scrollTo(start, anchor: .center) } }
            }
        }
    }
}

private extension GeometryProxy {
    /// The whole screen's size, the safe areas in.
    var whole: CGSize {
        CGSize(width: size.width + safeAreaInsets.leading + safeAreaInsets.trailing,
               height: size.height + safeAreaInsets.top + safeAreaInsets.bottom)
    }
}

/// Lays views out at points of its own frame, as the slope's screens place everything: a child says where it goes
/// with `slopePlace`, `slopeLine` or `seated`, and one that says nothing fills the frame. Each child keeps its own
/// frame where it is drawn, so a scroll's targets, VoiceOver and taps find it there.
struct SlopeLayer: SwiftUI.Layout {
    struct Place: Equatable {
        var point: CGPoint
        var anchor = UnitPoint.center
        /// Words: their leading edge at the point, their first line's middle level with it.
        var line = false
    }

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
            let own = subview.dimensions(in: .unspecified)
            let x = place.point.x - (place.line ? 0 : own.width * place.anchor.x)
            let y = place.point.y - (place.line ? own[.firstTextBaseline] * 0.62 : own.height * place.anchor.y)
            subview.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), anchor: .topLeading, proposal: .unspecified)
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

    /// In a `SlopeLayer`: a pebble set on its seat (`SlopeView.seat`), its underside a little into the sand.
    func seated(at seat: CGPoint) -> some View { slopePlace(seat, anchor: UnitPoint(x: 0.5, y: 0.93)) }
}

extension SlopeColumn {
    /// The main column on a screen of `size` at a Dynamic Type size (1.6): the pitch grows to hold a ledge's row, and
    /// from accessibility1 up the slope keeps to the leading edge and steps less. On a narrower phone the lips move in
    /// by half the width lost. `header` is the room a tier's header takes in the dive.
    static func main(size: CGSize, type: DynamicTypeSize, header: CGFloat? = nil) -> SlopeColumn {
        let large = type.isAccessibilitySize
        let row = TypeRole.body.line(at: type).height * (large ? 2 : 1) + TypeRole.detail.line(at: type).height
        return main(size: size, pitch: max(110, row + 60), lip: large ? 62 : 132 - max(440 - size.width, 0) / 2,
                    step: large ? 1.5 : 6, header: header)
    }

    /// The main column's ledge for `level`, a tier's own.
    static func ledge(of level: Level) -> Int? {
        guard level.pack == nil, let tier = Tier.allCases.firstIndex(of: level.tier),
              let index = level.tier.levels.firstIndex(where: { $0.id == level.id }) else { return nil }
        return ledge(tier: tier, level: index + 1)
    }
}
