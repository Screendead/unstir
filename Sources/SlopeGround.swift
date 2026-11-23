// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What a level in play asks of the ground: how far it has taken the screen (the shelf draws aside and a terrace
/// rises under the tank, `Slope.terrace`), a solved tank's glint and Prism's clear water, each from 0 to 1.
struct SlopePlay: Equatable {
    var level = 0.0
    var glint = 0.0
    var clear = 0.0
}

/// The slope's ground (Slope.metal) for one frame of the camera. It drifts on its own clock, at half the screen's
/// rate, and draws again only for that or a new frame: `held` stops the clock, as while a level plays, and Reduce
/// Motion never starts it, so then it is a still.
struct SlopeGround: View {
    let frame: Slope.Frame
    var held = false
    var play = SlopePlay()
    /// The clock held at these seconds, for a harness's stills.
    var clock: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var scale
    /// When the clock read 0, and when it last stopped.
    @State private var epoch = Date.now
    @State private var stopped: Date?

    private var still: Bool { held || reduceMotion || clock != nil }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still)) { timeline in
            let t = clock ?? (reduceMotion ? 0 : (stopped ?? timeline.date).timeIntervalSince(epoch))
            // The near silhouette is the dive's alone, and gives way to the words at the largest type.
            let near = (1 - frame.stairs) * min(max((frame.slope.lip - 62) / 60, 0), 1)
            Rectangle().fill(.black)
                .colorEffect(ShaderLibrary.slope(.float2(frame.size), .float4(scale, t, near, 1),
                                                 .float4(play.level, play.glint, play.clear, 0),
                                                 .floatArray(frame.uniforms)))
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
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The slope seen from a camera that may move and zoom: the ground, and over it whatever `content` sets on it from
/// the same frame, so a pebble stays on its ledge through an animated dive. The camera animates as a whole, its zoom
/// by its logarithm, which holds the rate the world grows at steady.
struct SlopeScene<Content: View>: View, Animatable {
    var slope: Slope
    var camera: SlopeCamera
    var held = false
    var play = SlopePlay()
    var clock: Double?
    @ViewBuilder var content: (Slope.Frame) -> Content

    nonisolated var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<Double, AnimatablePair<Double, Double>>> {
        get { AnimatablePair(AnimatablePair(camera.y, log(camera.zoom)), AnimatablePair(play.level, AnimatablePair(play.glint, play.clear))) }
        set {
            camera = SlopeCamera(y: newValue.first.first, zoom: exp(newValue.first.second))
            play = SlopePlay(level: newValue.second.first, glint: newValue.second.second.first, clear: newValue.second.second.second)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                              height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
            let frame = Slope.Frame(slope, camera: camera, size: size)
            ZStack(alignment: .topLeading) {
                SlopeGround(frame: frame, held: held, play: play, clock: clock)
                content(frame)
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .ignoresSafeArea()
        }
    }
}

/// The dive as a finger moves it: the slope from the surface to the open water under the brink, scrolled natively.
/// `content` is laid out once, in the frame of the dive's top (`Slope.Frame.point` gives a world point its place in
/// the scrolled content), and the ground is drawn for wherever the scroll has reached, in the same pass that moves the
/// content, so the two never part. `start` is the ledge the dive opens on.
struct SlopeDive<Content: View>: View {
    var slope: Slope
    var start: Int?
    var held = false
    var play = SlopePlay()
    var clock: Double?
    @ViewBuilder var content: (Slope.Frame) -> Content

    private static var space: String { "slope.dive" }

    var body: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                              height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
            // The scroll view keeps its content clear of the status bar, so the content's top is that much lower in
            // the world than the screen's is at rest.
            let top = SlopeCamera(y: slope.top(in: size).y + geo.safeAreaInsets.top)
            let base = Slope.Frame(slope, camera: top, size: size)
            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        GeometryReader { inner in
                            let offset = -inner.frame(in: .named(Self.space)).minY
                            SlopeGround(frame: Slope.Frame(slope, camera: SlopeCamera(y: top.y + offset), size: size),
                                        held: held, play: play, clock: clock)
                                .frame(width: size.width, height: size.height)
                                .offset(y: offset)
                        }
                        ForEach(0 ..< Slope.count, id: \.self) { k in
                            Color.clear.frame(width: 1, height: 1).position(x: 0, y: base.point(CGPoint(x: 0, y: slope.y(k))).y).id(k)
                        }
                        content(base)
                    }
                    .frame(width: size.width, height: slope.floor - base.origin.y, alignment: .topLeading)
                }
                .coordinateSpace(.named(Self.space))
                .ignoresSafeArea()
                .onAppear { if let start { reader.scrollTo(start, anchor: .center) } }
            }
        }
    }
}

extension Slope {
    /// The slope for a Dynamic Type size: its ledges further apart and its lips drawn in as the body role grows.
    init(_ size: DynamicTypeSize) { self.init(type: TypeRole.body.points(at: size) / 17) }

    /// The ledge `level` rests on, for a tier's own levels.
    static func ledge(of level: Level) -> Int? {
        guard level.pack == nil, let tier = Tier.allCases.firstIndex(of: level.tier),
              let index = level.tier.levels.firstIndex(where: { $0.id == level.id }) else { return nil }
        return ledge(tier: tier, level: index + 1)
    }
}
