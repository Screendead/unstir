// Copyright © 2026 Jack Lusher. All rights reserved.

#if FIRST_STIR
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

    /// What each vignette going back shows, told forwards: the outline's vignettes from played to held back, by scene (the
    /// pack's levels in order) and rod.
    static let beats: [[Int: String]] = [
        [0: String(localized: "The lantern is boarded up.", comment: "First Stir ending beat"),
         1: String(localized: "The boat is bailed, her mast stepped.", comment: "First Stir ending beat"),
         2: String(localized: "The door shuts; the fire is lit.", comment: "First Stir ending beat")],
        [3: String(localized: "A neighbour measures the broken panes.", comment: "First Stir ending beat"),
         0: String(localized: "The gulls come back to the rail.", comment: "First Stir ending beat"),
         1: String(localized: "Chimneys smoke across the town.", comment: "First Stir ending beat")],
        [0: String(localized: "The rope is coiled, the door shut.", comment: "First Stir ending beat"),
         1: String(localized: "She finds the float in the pool.", comment: "First Stir ending beat"),
         2: String(localized: "The dog sits by her boots.", comment: "First Stir ending beat")],
        [0: String(localized: "The haulers ease the rope and wave.", comment: "First Stir ending beat"),
         1: String(localized: "The boat comes upright.", comment: "First Stir ending beat"),
         2: String(localized: "Gulls wake into a paling sky.", comment: "First Stir ending beat")],
        [3: String(localized: "The lifeboat's lamp goes out.", comment: "First Stir ending beat"),
         2: String(localized: "She falls asleep against her father.", comment: "First Stir ending beat"),
         1: String(localized: "Three cups of tea, poured.", comment: "First Stir ending beat")],
        [0: String(localized: "The lifeboat comes into the harbour.", comment: "First Stir ending beat"),
         4: String(localized: "She leaves the torch on the sill.", comment: "First Stir ending beat"),
         2: String(localized: "Blankets are held out on the steps.", comment: "First Stir ending beat")],
        [0: String(localized: "They help Grandmother aboard.", comment: "First Stir ending beat"),
         1: String(localized: "The lifeboat comes alongside.", comment: "First Stir ending beat"),
         2: String(localized: "The stair window goes dark.", comment: "First Stir ending beat")],
        [3: String(localized: "The lifeboat is launched.", comment: "First Stir ending beat"),
         0: String(localized: "The lanterns reach the lighthouse.", comment: "First Stir ending beat"),
         1: String(localized: "Four lanterns held high in a row.", comment: "First Stir ending beat")],
        [0: String(localized: "She is helped down; the lamp burns on.", comment: "First Stir ending beat"),
         1: String(localized: "Lanterns gather far below.", comment: "First Stir ending beat"),
         2: String(localized: "Father climbs, his lantern left below.", comment: "First Stir ending beat")],
        [0: String(localized: "The signal lamp leaves the window.", comment: "First Stir ending beat"),
         1: String(localized: "Father ties the rope off.", comment: "First Stir ending beat"),
         3: String(localized: "The door opens; he is in.", comment: "First Stir ending beat")],
        [0: String(localized: "The rope is tied at the quay.", comment: "First Stir ending beat"),
         1: String(localized: "Father starts out along the path.", comment: "First Stir ending beat"),
         2: String(localized: "A lamp shows in the gallery.", comment: "First Stir ending beat")],
        [0: String(localized: "The town clock reads five past two.", comment: "First Stir ending beat"),
         2: String(localized: "The street lamp drowns and goes out.", comment: "First Stir ending beat"),
         3: String(localized: "Two men row down the street.", comment: "First Stir ending beat")],
        [3: String(localized: "She shines the torch from the window.", comment: "First Stir ending beat"),
         0: String(localized: "The weathervane bends over.", comment: "First Stir ending beat"),
         1: String(localized: "The water rises; the float drifts out.", comment: "First Stir ending beat")],
        [0: String(localized: "The teacup floats off the table.", comment: "First Stir ending beat"),
         1: String(localized: "She carries the dog upstairs.", comment: "First Stir ending beat"),
         3: String(localized: "The float drifts for the door.", comment: "First Stir ending beat")],
        [1: String(localized: "The boat sinks low.", comment: "First Stir ending beat"),
         3: String(localized: "The lantern is washed away.", comment: "First Stir ending beat"),
         4: String(localized: "A wave breaks over the wall.", comment: "First Stir ending beat")],
        [0: String(localized: "The lantern smashes.", comment: "First Stir ending beat"),
         1: String(localized: "The boat breaks loose and capsizes.", comment: "First Stir ending beat"),
         2: String(localized: "Father runs out; the lantern falls.", comment: "First Stir ending beat")],
        [0: String(localized: "Lightning forks into the sea.", comment: "First Stir ending beat"),
         3: String(localized: "The power fails; a candle is lit.", comment: "First Stir ending beat"),
         2: String(localized: "She hides in her father's arms.", comment: "First Stir ending beat")],
        [0: String(localized: "Spray climbs to the gallery.", comment: "First Stir ending beat"),
         2: String(localized: "The bell buoy heels over, ringing.", comment: "First Stir ending beat"),
         3: String(localized: "The hut's shutter tears off.", comment: "First Stir ending beat")],
        [0: String(localized: "The awning tears to strips.", comment: "First Stir ending beat"),
         1: String(localized: "The bicycle blows over.", comment: "First Stir ending beat"),
         2: String(localized: "The shop sign swings from one chain.", comment: "First Stir ending beat")],
        [0: String(localized: "The line snaps; a shirt flies off.", comment: "First Stir ending beat"),
         1: String(localized: "The neighbour bars her shutters.", comment: "First Stir ending beat"),
         3: String(localized: "She brings the dog in.", comment: "First Stir ending beat")],
        [0: String(localized: "Grandmother lights the lamp.", comment: "First Stir ending beat"),
         3: String(localized: "The gulls flock inland.", comment: "First Stir ending beat"),
         2: String(localized: "Windows light across the town.", comment: "First Stir ending beat")],
        [1: String(localized: "Grandmother reaches the lighthouse.", comment: "First Stir ending beat"),
         0: String(localized: "She waves from the quay rail.", comment: "First Stir ending beat"),
         2: String(localized: "A thin moon rises by the star.", comment: "First Stir ending beat")],
        [1: String(localized: "Father doubles the boat's lines.", comment: "First Stir ending beat"),
         3: String(localized: "The barometer falls to storm.", comment: "First Stir ending beat"),
         4: String(localized: "A lamp is lit behind the float.", comment: "First Stir ending beat")],
        [3: String(localized: "The float is hung in the window.", comment: "First Stir ending beat"),
         0: String(localized: "Father takes his oilskin and goes.", comment: "First Stir ending beat"),
         2: String(localized: "Grandmother gives her the float.", comment: "First Stir ending beat")],
        [0: String(localized: "The sun sinks toward a curl of cloud.", comment: "First Stir ending beat"),
         1: String(localized: "The kitchen clock ticks on.", comment: "First Stir ending beat"),
         2: String(localized: "She lays the spoon down.", comment: "First Stir ending beat")],
    ]
    /// How long a beat's line takes to fade in and out at the ends of its share.
    static let read = 0.3

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

    /// The line under the glass `seconds` into a scene, and how far it stands faded in: each vignette's beat over its own
    /// share of the run.
    static func beat(_ level: Level, seconds: Double) -> (text: String, opacity: Double)? {
        guard let scene = Level.firstStir.firstIndex(where: { $0.id == level.id }) else { return nil }
        let returns = returns(level), share = (length - blend) / Double(max(returns.count, 1))
        guard let (k, at) = returns.first(where: { abs(seconds - $0.value - fade / 2) < share / 2 }), let text = beats[scene][k]
        else { return nil }
        let start = at + fade / 2 - share / 2
        return (text, min(max(min(seconds - start, start + share - seconds) / read, 0), 1))
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
    /// Where its lines end, down from the glass's top; nil just under the glass.
    var foot: CGFloat?
    /// UNSTIR_ENDING=s: the film held this many seconds in.
    var frozen: Double?
    let onDone: () -> Void
    /// The black's diameter, in sides: it hides the bezel and knobs, and its foot is the lines' frame's.
    nonisolated static let backing: CGFloat = 1.12

    /// How far the lines are moved down from the black's foot so they end `foot` below the glass's top, or 48 pt under
    /// the black with no foot.
    nonisolated static func linesOffset(foot: CGFloat?, side: CGFloat) -> CGFloat {
        foot.map { $0 - (1 + backing) / 2 * side } ?? 48
    }
    @Environment(\.displayScale) private var scale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Each scene's layers with the side they were baked at: a change of pose bakes again, drawing the old ones
    /// stretched until the new land.
    @State private var layers: [Int: (side: CGFloat, layers: SceneLayers)] = [:]
    @State private var start: Date?
    @State private var index = 0
    @State private var done = false

    var body: some View {
        TimelineView(.animation(paused: start == nil || frozen != nil || done)) { timeline in
            let t = frozen ?? start.map { timeline.date.timeIntervalSince($0) } ?? 0
            let now = NightForwards.at(t)
            ZStack {
                Circle().fill(.black)
                frame(now)
                    .frame(width: side, height: side)
                    .clipShape(Circle())
            }
            .frame(width: side * Self.backing, height: side * Self.backing)
            .opacity(reduceMotion ? 1 : min(t / NightForwards.open, 1))
            .overlay(alignment: .bottom) {
                VStack(spacing: 6) {
                    let beat = NightForwards.beat(NightForwards.levels[now.index], seconds: now.seconds)
                    Text(verbatim: beat?.text ?? " ").font(.game(12)).lineLimit(1).opacity(0.8 * (beat?.opacity ?? 0))
                    Text(verbatim: clock(now)).font(.game(12)).opacity(0.55)
                    Text("tap to skip").font(.game(12)).opacity(0.35)
                }
                .offset(y: Self.linesOffset(foot: foot, side: side))
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
        .task(id: "\(index) \(side) \(scale)") { await bake(around: index) }
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
        if let scene = level.story?.scene, let baked = layers[i]?.layers {
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
        for k in [i, i + 1] where NightForwards.levels.indices.contains(k) && layers[k]?.side != side {
            guard let scene = NightForwards.levels[k].story?.scene else { continue }
            var images: [UIImage] = []
            for sky in [scene.late, scene.early, nil] as [Double?] {
                guard let image = scene.render(sky: sky, side: side, scale: s) else { return }
                images.append(image)
                await Task.yield()
            }
            guard let played = scene.render(played: scene.vignettes, side: side, scale: s), !Task.isCancelled else { return }
            layers[k] = (side, (images[0], images[1], images[2], played, SceneComposite.cores(scene, side: side, scale: s)))
        }
        for k in layers.keys where k < i { layers[k] = nil }
        if start == nil { start = .now }
    }
}
#endif
