// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// First Stir's ending, the night forwards (the outline's open point 8, A; Jack's round 9, D1): after the pack's last
/// solve, every scene plays in story order, from the stir in the cup to the dawn, with no new art. Each scene runs from
/// its played state at `early` to its held-back state at `late`, the scramble's entries coming back bottom first, so
/// every frame is one the stack can stand in, and the next scene takes over at the same minute.
enum NightForwards {
    /// The scenes in story order: the pack's levels backwards.
    static let levels: [Level] = Level.firstStir.reversed()
    /// The fade in over the solved tank, before the first scene runs.
    static let open = 1.0
    /// Each scene's share of the film, its crossfade into the next included.
    static let length = 6.4
    /// The crossfade between scenes, which stand still through it.
    static let blend = 0.6
    /// How long a vignette takes to go back.
    static let fade = 1.2
    /// The last frame, the town at sunrise as the pack opened, held before the card.
    static let hold = 2.5
    static var duration: Double { open + length * Double(levels.count) + hold }

    /// Where the film stands `t` seconds in: the scene, how far its own clock has run (0 at `early`, 1 at `late`), its
    /// seconds since it began running, and how far the next scene has faded in over it.
    static func at(_ t: Double) -> (index: Int, run: Double, seconds: Double, next: Double) {
        let s = max(t - open, 0), last = levels.count - 1
        let index = min(Int(s / length), last), seconds = s - Double(index) * length
        let running = length - blend
        let run = min(seconds / running, 1)
        let x = index == last ? 0 : min(max((seconds - running) / blend, 0), 1)
        return (index, run, seconds, x * x * (3 - 2 * x))
    }

    /// The vignettes played with the scramble's bottom `entries` entries on the stack: the rest have gone.
    static func played(_ level: Level, entries: Int) -> Set<Int> {
        (level.story?.vignettes ?? []).subtracting(level.scramble.prefix(entries).map(\.rod))
    }

    /// The seconds into a scene's run at which each vignette starts to go back, in the order its rod's first entry
    /// returns: each fade centred in its own even share of the run, so no two overlap.
    static func returns(_ level: Level) -> [Int: Double] {
        let running = length - blend
        let order = (level.story?.vignettes ?? []).sorted { k, l in
            level.scramble.firstIndex { $0.rod == k }! < level.scramble.firstIndex { $0.rod == l }!
        }
        var at: [Int: Double] = [:]
        for (i, k) in order.enumerated() { at[k] = (Double(i) + 0.5) / Double(order.count) * running - fade / 2 }
        return at
    }

    /// Each vignette's played layer's opacity `seconds` into the scene: 1 until it goes back, then fading out over `fade`,
    /// or cut at once under Reduce Motion.
    static func shown(_ level: Level, seconds: Double, cut: Bool) -> [Int: Double] {
        returns(level).mapValues { at in
            if cut { return seconds < at ? 1 : 0 }
            let x = min(max((seconds - at) / fade, 0), 1)
            return 1 - x * x * (3 - 2 * x)
        }
    }
}

extension Level {
    /// The pack's last scene, whose solve plays the night forwards.
    var endsFirstStir: Bool { pack == .firstStir && id == Level.firstStir.last?.id }
}

/// The night forwards in the glass, the time under it running on, over a black that hides the bezel and knobs. It bakes
/// two scenes' layers at a time, the next while the current plays, and lets each go once it has passed. A tap ends it.
struct NightForwardsFilm: View {
    let side: CGFloat
    /// UNSTIR_ENDING=s: the film held this many seconds in.
    var frozen: Double?
    let onDone: () -> Void
    @Environment(\.displayScale) private var scale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var layers: [Int: SceneLayers] = [:]
    @State private var start: Date?
    @State private var index = 0
    @State private var done = false

    var body: some View {
        TimelineView(.animation(paused: start == nil || frozen != nil || done)) { timeline in
            let t = frozen ?? start.map { timeline.date.timeIntervalSince($0) } ?? 0
            let now = NightForwards.at(t)
            ZStack {
                Circle().fill(.black).frame(width: side * 1.12, height: side * 1.12)
                frame(now)
                    .frame(width: side, height: side)
                    .clipShape(Circle())
            }
            .opacity(reduceMotion ? 1 : min(t / NightForwards.open, 1))
            .overlay(alignment: .bottom) {
                VStack(spacing: 6) {
                    Text(clock(now)).font(.mono(12)).opacity(0.55)
                    Text("tap to skip").font(.mono(12)).opacity(0.35)
                }
                .offset(y: 48)
            }
            .onChange(of: now.index, initial: true) { index = now.index }
            .onChange(of: t >= NightForwards.duration) { if t >= NightForwards.duration { finish() } }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: finish)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The night, played forwards")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Skips it")
        .task(id: index) { await bake(around: index) }
    }

    @ViewBuilder private func frame(_ now: (index: Int, run: Double, seconds: Double, next: Double)) -> some View {
        ZStack {
            Color.black
            composite(now.index, run: now.run, seconds: now.seconds)
            if now.next > 0 {
                // One layer, so its cut-in cores fade with the scene rather than over it.
                composite(now.index + 1, run: 0, seconds: 0).compositingGroup()
                    .opacity(reduceMotion ? (now.next < 0.5 ? 0 : 1) : now.next)
            }
        }
        .drawingGroup(colorMode: .extendedLinear)
    }

    @ViewBuilder private func composite(_ i: Int, run: Double, seconds: Double) -> some View {
        let level = NightForwards.levels[i]
        if let scene = level.story?.scene, let baked = layers[i] {
            SceneComposite(scene: scene, layers: baked, sky: 1 - run, minutes: scene.early + (scene.late - scene.early) * run,
                           side: side, shown: NightForwards.shown(level, seconds: seconds, cut: reduceMotion))
        }
    }

    private func clock(_ now: (index: Int, run: Double, seconds: Double, next: Double)) -> String {
        let i = now.next >= 0.5 ? now.index + 1 : now.index
        guard let scene = NightForwards.levels[i].story?.scene else { return "" }
        let run = i == now.index ? now.run : 0
        return type(of: scene).clock(scene.early + (scene.late - scene.early) * run)
    }

    private func finish() {
        guard !done else { return }
        done = true
        onDone()
    }

    /// Bakes scene `i` and the next, then drops the ones behind. The film starts once its first two are in.
    private func bake(around i: Int) async {
        let s = min(SceneLayer.bakeScale(side: side, scale: scale), 2)
        for k in [i, i + 1] where NightForwards.levels.indices.contains(k) && layers[k] == nil {
            guard let scene = NightForwards.levels[k].story?.scene else { continue }
            var images: [UIImage] = []
            for sky in [scene.late, scene.early, nil] as [Double?] {
                guard let image = scene.render(sky: sky, side: side, scale: s) else { return }
                images.append(image)
                await Task.yield()
            }
            guard let played = scene.render(played: scene.vignettes, side: side, scale: s), !Task.isCancelled else { return }
            layers[k] = (images[0], images[1], images[2], played, SceneComposite.cores(scene, side: side, scale: s))
        }
        for k in layers.keys where k < i { layers[k] = nil }
        if start == nil { start = .now }
    }
}
