// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// A First Stir scene on the pack's one night (Jack, F2): drawn in tank units as a sky and sea at a time, a scene with
/// some of its vignettes played, and the bodies that move with the time where no disc reaches. Its time is a function
/// of the stack: with n of the scramble's N entries gone, it stands n/N of the way from `late` back to `early`.
protocol StoryScene: Sendable {
    var layout: Layout { get }
    var vignettes: Set<Int> { get }
    /// Minutes after midnight as the level opens, and once every entry has gone.
    var late: Double { get }
    var early: Double { get }
    func drawSky(_ ctx: GraphicsContext, r: CGFloat, minutes: Double)
    func drawLive(_ ctx: GraphicsContext, r: CGFloat, minutes: Double)
    func draw(_ ctx: GraphicsContext, r: CGFloat, played: Set<Int>)
}

extension Dawn: StoryScene {}

extension StoryScene {
    func minutes(wound n: Int, of count: Int) -> Double { late - (late - early) * Double(n) / Double(max(count, 1)) }

    /// The time as the caption shows it (Jack, F3): "6:40 am".
    static func clock(_ minutes: Double) -> String {
        let m = (Int(minutes.rounded()) % 1440 + 1440) % 1440, h = m / 60
        return "\((h + 11) % 12 + 1):\(String(format: "%02d", m % 60)) \(h < 12 ? "am" : "pm")"
    }

    /// A tank-sized layer: the sky at a time (opaque), or the scene with `played` played over nothing.
    @MainActor
    func render(sky minutes: Double? = nil, played: Set<Int> = [], side: CGFloat, scale: CGFloat,
                colorMode: ColorRenderingMode = .extendedLinear) -> UIImage? {
        let r = ImageRenderer(content: Canvas { ctx, size in
            if let minutes { drawSky(ctx, r: size.width / 2, minutes: minutes) } else { draw(ctx, r: size.width / 2, played: played) }
        }
        .frame(width: side, height: side))
        r.scale = scale
        r.isOpaque = minutes != nil
        r.colorMode = colorMode
        return r.uiImage
    }
}

extension Story {
    /// The scene this story draws on the pack's night, where it has one; the harbour in the storm is the lab's own.
    var scene: (any StoryScene)? {
        switch self {
        case .harbour: nil
        case .dawn(let scene): scene
        }
    }
}

extension Game {
    /// How many of the scramble's entries have gone: the player's own pushes move no time, and a solve has wound it all.
    var wound: Int {
        let count = level.scramble.count
        return solved ? count : max(count - entries.filter { !$0.pushed }.count, 0)
    }

    /// The line under the tank: a scene's time, stepping back with each entry gone, else the level's note.
    var caption: String {
        guard let scene = level.story?.scene else { return level.note }
        return type(of: scene).clock(scene.minutes(wound: wound, of: level.scramble.count))
    }
}

/// A scene as the stack has played it: the held-back scene over the sky, each played core cut in from the all-played
/// scene and cross-faded as it plays (snapping back on an undo, as `StoryLayer` does), the sky and the live bodies wound
/// back as the scramble's entries go. Four layers bake as it appears, within `Harbour.budget`.
struct SceneLayer: View {
    let scene: any StoryScene
    let played: Set<Int>
    /// The scramble's entries gone, of `count`.
    let wound: Int
    let count: Int
    let side: CGFloat
    var onStrike: () -> Void = {}
    @Environment(\.displayScale) private var scale
    @State private var layers: (late: UIImage, early: UIImage, held: UIImage, played: UIImage)?
    /// The fraction of the window the time is wound back from, and when the rewind began.
    @State private var rewind: (from: Double, at: Date)?
    @State private var rested = 0.0
    @State private var playedAt: [Int: Date] = [:]

    private var night: Double { Double(wound) / Double(max(count, 1)) }

    var body: some View {
        TimelineView(.animation(paused: rewind == nil)) { timeline in
            let f = shown(at: timeline.date)
            let minutes = scene.late - (scene.late - scene.early) * f
            ZStack {
                if let layers {
                    sky(layers, f)
                    Canvas { ctx, size in scene.drawLive(ctx, r: size.width / 2, minutes: minutes) }
                    Image(uiImage: layers.held)
                    ForEach(scene.layout.rods.indices.filter(scene.vignettes.contains), id: \.self) { k in
                        let rod = scene.layout.rods[k], core = Tank.plateau * rod.z * side
                        ZStack {
                            sky(layers, f)
                            Image(uiImage: layers.played)
                        }
                        .mask(Circle().frame(width: core, height: core).position(x: side / 2 * (1 + rod.x), y: side / 2 * (1 + rod.y)))
                        .opacity(playedAt[k].map { at in
                            let x = min(max(timeline.date.timeIntervalSince(at) / Harbour.fade, 0), 1)
                            return x * x * (3 - 2 * x)
                        } ?? 0)
                    }
                } else {
                    Color.black
                }
            }
        }
        .frame(width: side, height: side)
        .drawingGroup(colorMode: .extendedLinear)
        .keyframeAnimator(initialValue: 0.0, trigger: layers != nil) { picture, o in picture.opacity(o) } keyframes: { _ in
            PictureLayer.strike
        }
        .onChange(of: layers != nil) { if layers != nil { onStrike() } }
        .onAppear {
            rested = night
            for k in played { playedAt[k] = .distantPast }
        }
        .onChange(of: played) { old, new in
            for k in new.subtracting(old) { playedAt[k] = .now }
            for k in old.subtracting(new) { playedAt[k] = nil }
        }
        // A vignette plays only as an entry goes, so the rewind's clock, which outlasts the fade, runs it too.
        // A heal mid-rewind winds on from where the sky stands, not from where the last rewind began.
        .onChange(of: wound) { old, new in
            if new > old { rewind = (shown(at: .now, toward: Double(old) / Double(max(count, 1))), .now) } else { rewind = nil; rested = night }
        }
        .task(id: rewind?.at) {
            guard rewind != nil, (try? await Task.sleep(for: .seconds(Harbour.rewind))) != nil else { return }
            rested = night
            rewind = nil
        }
        .task(id: "\(side) \(scale)") {
            let s = SceneLayer.bakeScale(side: side, scale: scale)
            guard let late = scene.render(sky: scene.late, side: side, scale: s), let early = scene.render(sky: scene.early, side: side, scale: s),
                  let held = scene.render(side: side, scale: s), let played = scene.render(played: scene.vignettes, side: side, scale: s)
            else { return }
            layers = (late, early, held, played)
        }
    }

    /// The fraction of the window the time stands wound back at `date`, rewinding toward `target` (`night` unless given).
    private func shown(at date: Date, toward target: Double? = nil) -> Double {
        guard let rewind else { return rested }
        let x = min(max(date.timeIntervalSince(rewind.at) / Harbour.rewind, 0), 1)
        return rewind.from + ((target ?? night) - rewind.from) * x * x * (3 - 2 * x)
    }

    private func sky(_ layers: (late: UIImage, early: UIImage, held: UIImage, played: UIImage), _ f: Double) -> some View {
        ZStack {
            Image(uiImage: layers.late)
            Image(uiImage: layers.early).opacity(f)
        }
        .frame(width: side, height: side)
    }

    /// The scale to bake at: the screen's, unless four tank-sized float layers would pass `Harbour.budget`.
    static func bakeScale(side: CGFloat, scale: CGFloat) -> CGFloat {
        min(scale, ((Double(Harbour.budget) / Double(layerBytes(side: side, scale: 1))).squareRoot() * 100).rounded(.down) / 100)
    }

    static func layerBytes(side: CGFloat, scale: CGFloat) -> Int {
        let px = side * scale
        return Int(8 * px * px * 4)
    }
}
