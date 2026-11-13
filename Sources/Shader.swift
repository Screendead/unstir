// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Turns the glass by `turn`, applies the stack (plus the live twist on top) as inverse maps and samples the picture.
struct Unstirred: ViewModifier, Animatable {
    var stack: [Twist]
    var layout: Layout
    /// The rods whose steps magnify rather than turn.
    var lenses: Set<Int> = []
    /// Prism's channels by slot, a missing slot white.
    var masks: [Int: Channels] = [:]
    var liveRod: Int?
    var liveAngle: Double
    var wind = 1.0
    /// Each entry's own share of its turn, in place of `wind`: a dock cover winds its stack an entry at a time.
    var shares: [Double]?
    var side: CGFloat
    /// Drains the colour towards grey.
    var haze = 0.0
    /// The glass's turn about the tank's centre, in radians clockwise.
    var turn = 0.0
    /// (x, y, radius) in tank units on the screen; a negative radius is off.
    var wave = SIMD3<Float>(0, 0, -1)
    /// A live picture's own cost per frame, in entries: it is redrawn under the shader every frame.
    var fillEntries = 0
    /// The swirl's breath, newest of all.
    var breath: (rod: Int, angle: Double)?
    /// Escapement: the clock's tick part way, on top of the stack and under the live twist.
    var tick: (rod: Int, angle: Double)?
    /// Prism: one channel drawn alone, the others hidden, while its swatch is held: in its own colour, or in white under
    /// Differentiate Without Colour (`whiteIsolate`).
    var isolate: Channels?
    var whiteIsolate = false
    /// Prism: the mask of the rod in the player's hand, whose channels the glass draws alone in their own colour, white
    /// fading in near the count (`unstirChannels`' `held`), and how far that is drawn over the plain glass, 1 in hand.
    /// Stepped by the caller, never animated: an animation started with the grab would take the turn's own with it.
    var held: Channels?
    var hold = 0.0
    /// The committed work drawn with four taps, nil for the glass's static limit (`Tank.fourTaps(pixels:)`). Never
    /// animated: only `Taps` moves it, at a still moment.
    var budget: Int?
    /// Lens: the panel's detail, which `unstirLens` draws where a lens magnifies, and its share against the bake, 0
    /// while the layer is not yet the lit panel, as the detail is drawn past the layer and would not strike with it.
    var fine: Fine?
    var crisp = 0.0
    /// The stored map of the committed stack, where the glass has one (`StirMap`): a level's, which `HeldUnstirred`
    /// gives, never a cover's or a clip's.
    var map: StirMap.Made?
    @Environment(\.displayScale) private var scale

    nonisolated var animatableData: AnimatablePair<AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>>, Double> {
        get { AnimatablePair(AnimatablePair(AnimatablePair(liveAngle, wind), AnimatablePair(haze, turn)), crisp) }
        set {
            let four = newValue.first
            (liveAngle, wind, haze, turn, crisp) = (four.first.first, four.first.second, four.second.first, four.second.second, newValue.second)
        }
    }

    func body(content: Content) -> some View {
        content.layerEffect(shader(scale: scale).shader, maxSampleOffset: CGSize(width: side, height: side))
    }

    /// UNSTIR_NUDGE=0.1: every glass's stir drawn that many device pixels right and down of where it sits, over the
    /// same picture, so nothing changes where the map is the identity. For the twist oracle: how far a frame's pixels
    /// move for a shift of the map no eye sees is what it lets another way of drawing the frame differ by.
    /// `0.1,-0.1` gives each axis its own.
    nonisolated static let nudge: (x: Double, y: Double) = {
        #if PROBES || DEBUG
        let f = (ProcessInfo.processInfo.environment["UNSTIR_NUDGE"] ?? "").split(separator: ",").compactMap { Double($0) }
        return f.isEmpty ? (0, 0) : (f[0], f.count > 1 ? f[1] : f[0])
        #else
        return (0, 0)
        #endif
    }()

    /// The frame's shader and its arguments on a display of `scale`, which the oracle's bench draws too (`OracleBench`).
    nonisolated func shader(scale: CGFloat) -> TankShader {
        DragProbe.count(.shader)
        var turns = stack.enumerated().map { i, t in (rod: t.rod, angle: Double(t.steps) * Tank.step * min(shares?[i] ?? wind, 1)) }
        if let tick { turns.append(tick) }
        if let liveRod { turns.append((liveRod, liveAngle)) }
        if let breath, breath.angle != 0 { turns.append(breath) }
        DragProbe.drew(sum: turns.reduce(0) { $0 + $1.angle }, turn: turn)
        let (twists, channels) = Self.entries(turns, layout: layout, lenses: lenses, masks: masks)
        let n = turns.count
        let r = side / 2
        // A live picture keeps four taps only to the budget less its fill: the same budget as without it. Counted in
        // committed work, so a touch never changes the taps: the drag, the breath or a tick in flight rides one entry
        // over, or Prism's its own cost (`weigh`), within the 41 the shader's comment measured on the 13 Pro Max's glass.
        // Two in flight at once, for the `Breath.fade` a touch takes to cut a slosh or a grab within a tick's flight,
        // drop to two taps at the budget's edge rather than run one more.
        let taps = budget.map { $0 - fillEntries } ?? Self.taps(side: side, scale: scale, fill: fillEntries)
        let weight = Self.weigh(channels, inFlight: n - stack.count)
        var shader = TankShader(centre: CGPoint(x: r + Self.nudge.x / scale, y: r + Self.nudge.y / scale), radius: r, twists: twists,
                                fourTaps: Float(taps + weight.rides),
                                scale: scale, haze: haze, wave: wave, turn: turn)
        if let map, let mode = StirMap.mode, map.key.side == side, map.key.scale == scale, twists.starts(with: map.key.twists),
           weight.cost != nil || map.key.masks.isEmpty {
            // Whatever the map holds of this frame's bottom entries, float for float, it holds rightly: a twist pushed
            // since, a rod in hand, a tick or the breath run above it. One popped or merged since, or the opening's
            // wind, leaves it another stack's, and the frame draws through the chain until the next lands. The same
            // entries are the same rods, so the same channels: a map of a stack all white draws Prism's every channel
            // from its one tile.
            shader.mapped = TankShader.Mapped(image: map.image, kept: map.key.twists.count / 4, rest: map.key.rest, quant: map.quant,
                                              mode: mode, tiles: StirMap.slots(map.key.tiles))
        }
        if let cost = weight.cost {
            let tint = whiteIsolate ? SIMD3<Float>(1, 1, 1) : SIMD3<Float>(isolate?.tint ?? SIMD3(1, 1, 1))
            shader.prism = TankShader.Prism(masks: channels, cost: cost, isolate: isolate, tint: tint)
            if let held, held != .white, hold > 0 { (shader.prism!.held, shader.prism!.hold) = (held, Float(min(hold, 1))) }
        } else if let fine, crisp > 0, !lenses.isEmpty {
            shader.fine = fine
            shader.fine?.table[Fine.share] = Float(min(crisp, 1))
            // The detail and the map are two images (`StirMap.lensMaps`).
            if !StirMap.lensMaps { shader.mapped = nil }
        }
        return shader
    }
}

/// The level's glass with the turn in hand on top of `rest`, read in this modifier's own body, so a frame of a drag
/// re-evaluates the shader's arguments and nothing above them (`Hand`). It keeps the glass's stored map (`StirMap`),
/// asked for by `rest`, the committed glass, so a map landing draws this body again and nothing above it either.
struct HeldUnstirred: ViewModifier, Equatable {
    let hand: Hand
    let rest: Unstirred
    /// The glass has eased home, where the tank's turn in hand no longer turns it.
    let eased: Bool
    @Environment(\.displayScale) private var scale
    @State private var maps = StirMap.Holder()

    nonisolated init(hand: Hand, rest: Unstirred, eased: Bool) {
        (self.hand, self.rest, self.eased) = (hand, rest, eased)
    }

    /// A live picture's timeline builds this again on every tick; one that draws the same frame builds no arguments.
    nonisolated static func == (a: HeldUnstirred, b: HeldUnstirred) -> Bool {
        DragProbe.count(.equal)
        return a.hand === b.hand && a.eased == b.eased && a.rest.draws(sameAs: b.rest)
    }

    func body(content: Content) -> some View {
        let _ = DragProbe.count(.leaf)
        DragProbe.built(rest, angle: hand.angle, turn: eased ? nil : hand.held)
        var u = rest
        u.liveAngle = hand.angle
        if !eased { u.turn += hand.held ?? 0 }
        if StirMap.mode != nil {
            maps.want(rest, scale: scale)
            u.map = maps.made
        }
        return content.modifier(u)
    }
}

/// Unstir.metal's `unstir`, `unstirChannels` where `prism` is set or `unstirLens` where `fine` is, each with `Mapped`
/// after its name where `mapped` is, its arguments by name. `parameters` lists them
/// in the signature's order, each array's count passed with it (`testTheTankShaderPassesTheSignaturesOrder`).
struct TankShader {
    var centre: CGPoint
    var radius: CGFloat
    /// Four floats an entry, bottom of the stack first (`Unstirred.entries`).
    var twists: [Float]
    /// Past this many entries' work only two taps run.
    var fourTaps: Float
    var plateau = Tank.plateau
    var swirlPlateau = Tank.swirlPlateau
    var lensEdge = Tank.lensEdge
    var scale: CGFloat
    var haze = 0.0
    var wave = SIMD3<Float>(0, 0, -1)
    var turn = 0.0
    var prism: Prism?
    /// `unstirLens`' own, in place of `unstir`; never with `prism`.
    var fine: Fine?

    /// `unstirChannels`' own: each entry's mask (a `Channels` raw value), the work in entries held against `fourTaps`,
    /// the channel drawn alone in `tint`, and the held rod's mask and how far its read is drawn (`Unstirred.held`).
    struct Prism {
        var masks: [Float]
        var cost: Int
        var isolate: Channels?
        var tint: SIMD3<Float>
        var held: Channels?
        var hold: Float = 0
    }

    /// The mapped stitchables' own, after the rest: the stored map's image, how many of the bottom entries it holds, the
    /// turn it was drawn at, its steps a pixel, how a tap between texels is drawn and, on Prism's glass, each channel's
    /// tile (`StirMap.slots`).
    var mapped: Mapped?

    struct Mapped {
        var image: Image
        var kept: Int
        var rest: Double
        var quant: Float
        var mode: StirMap.Mode
        var tiles = SIMD3<Float>(0, 0, 0)
    }

    var name: String { (prism != nil ? "unstirChannels" : fine != nil ? "unstirLens" : "unstir") + (mapped != nil ? "Mapped" : "") }

    var parameters: [(name: String, argument: Shader.Argument)] {
        // The shader reads min(n, count / 4) entries, so an empty stack's pad reads none.
        var list: [(name: String, argument: Shader.Argument)] = [
            ("centre", .float2(centre)), ("radius", .float(radius)), ("twists", .floatArray(twists.isEmpty ? [0, 0, 0, 0] : twists)),
        ]
        if let prism { list.append(("masks", .floatArray(prism.masks))) }
        list.append(("n", .float(Float(twists.count / 4))))
        if let prism { list.append(("cost", .float(Float(prism.cost)))) }
        list += [("fourTaps", .float(fourTaps)), ("plateau", .float(plateau)), ("swirlPlateau", .float(swirlPlateau)),
                 ("lensEdge", .float(lensEdge)), ("scale", .float(scale)), ("haze", .float(haze)),
                 ("wave", .float3(wave.x, wave.y, wave.z)), ("turn", .float(turn))]
        if let fine, prism == nil { list += [("atlas", .image(fine.atlas)), ("fine", .floatArray(fine.table))] }
        if let prism {
            list += [("isolate", .float(Float(prism.isolate?.rawValue ?? 0))),
                     ("tint", .float3(prism.tint.x, prism.tint.y, prism.tint.z)),
                     ("held", .float(Float(prism.held?.rawValue ?? 0))), ("hold", .float(prism.hold))]
        }
        if let mapped {
            list += [("map", .image(mapped.image)),
                     ("mapped", .float4(Float(mapped.kept), Float(mapped.rest), mapped.quant, mapped.mode.rawValue)),
                     ("bend", .float(StirMap.bend))]
            if prism != nil { list.append(("tiles", .float3(mapped.tiles.x, mapped.tiles.y, mapped.tiles.z))) }
        }
        return list
    }

    var shader: Shader { Shader(function: ShaderFunction(library: .default, name: name), arguments: parameters.map(\.argument)) }
}

/// A halftone panel's detail (`Halftone.Detail`) as the shader takes it: the atlas as an image, made once, and its
/// table.
struct Fine: Equatable {
    /// The table's float that scales the detail's weight.
    static let share = 5

    let atlas: Image
    var table: [Float]
    /// The atlas's bytes, for the log.
    let bytes: Int

    init?(_ detail: Halftone.Detail) {
        guard let provider = CGDataProvider(data: Data(detail.pixels) as CFData),
              let image = CGImage(width: detail.width, height: detail.height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: 4 * detail.width, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { return nil }
        atlas = Image(decorative: image, scale: 1)
        table = detail.table
        bytes = detail.pixels.count
    }
}

extension Unstirred {
    /// Whether the two draw the same frame: every stored field but the environment's
    /// (`testTheGlassComparesEveryField`).
    nonisolated func draws(sameAs o: Unstirred) -> Bool {
        let level = stack == o.stack && layout == o.layout && lenses == o.lenses && masks == o.masks && side == o.side
            && fillEntries == o.fillEntries && budget == o.budget
        let turns = liveRod == o.liveRod && liveAngle == o.liveAngle && wind == o.wind && shares == o.shares && turn == o.turn
            && breath?.rod == o.breath?.rod && breath?.angle == o.breath?.angle && tick?.rod == o.tick?.rod && tick?.angle == o.tick?.angle
        let look = haze == o.haze && wave == o.wave && isolate == o.isolate && whiteIsolate == o.whiteIsolate && held == o.held
            && hold == o.hold && fine == o.fine && crisp == o.crisp && map == o.map
        return level && turns && look
    }

    /// The entries both shaders read, bottom of the stack first: four floats each (the rod's x and y, its disc's radius,
    /// the angle), a lens's with a negative radius and its flow's time for the angle, and each one's mask, a `Channels`
    /// raw value, a missing slot white.
    nonisolated static func entries(_ turns: [(rod: Int, angle: Double)], layout: Layout, lenses: Set<Int>,
                                    masks: [Int: Channels]) -> (twists: [Float], masks: [Float]) {
        let rods = layout.rods
        var twists: [Float] = [], channels: [Float] = []
        twists.reserveCapacity(4 * turns.count)
        for (rod, angle) in turns {
            channels.append(Float((masks[rod] ?? .white).rawValue))
            let lens = lenses.contains(rod)
            twists += [Float(rods[rod].x), Float(rods[rod].y), Float(lens ? -rods[rod].z : rods[rod].z),
                       Float(lens ? angle / Tank.step * Tank.lensRate : angle)]
        }
        return (twists, channels)
    }

    /// The committed entries a glass `side` points across at `scale` draws with four taps, less a live picture's fill.
    nonisolated static func taps(side: CGFloat, scale: CGFloat, fill: Int) -> Int {
        Tank.fourTaps(pixels: Double(side * scale)) - fill
    }

    /// What the shaders weigh for a frame of `channels` (each entry's mask, raw), the last `inFlight` of them in
    /// flight: Prism's channel cost, nil where every entry is white and the plain shader counts entries, and how far
    /// over the budget the entries in flight ride: one entry, or Prism's own cost. Both shaders draw four taps where
    /// `cost ?? channels.count` is at most the budget less the fill, plus `rides`.
    nonisolated static func weigh(_ channels: [Float], inFlight: Int) -> (cost: Int?, rides: Int) {
        guard let cost = channelCost(channels) else { return (nil, min(inFlight, 1)) }
        return (cost, channels.suffix(inFlight).map { Int($0).nonzeroBitCount }.max() ?? 0)
    }

    /// The work `weigh` holds against the budget: four taps where it is at most the budget.
    nonisolated static func work(_ channels: [Float], inFlight: Int, fill: Int) -> Int {
        let w = weigh(channels, inFlight: inFlight)
        return (w.cost ?? channels.count) - w.rides + fill
    }

    /// The work of `stack` on a level with `masks` and a live picture's `fill`, with slot `held` in flight.
    nonisolated static func committedWork(stack: [Twist], masks: [Int: Channels], fill: Int, held: Int? = nil) -> Int {
        let rods = stack.map(\.rod) + (held.map { [$0] } ?? [])
        return work(rods.map { Float((masks[$0] ?? .white).rawValue) }, inFlight: held == nil ? 0 : 1, fill: fill)
    }

    nonisolated static func drawsFourTaps(work: Int, budget: Int) -> Bool { work <= budget }

    /// The per-channel shader's work in entries for these masks (raw values, an entry each), or nil when every one is
    /// white and the plain shader draws them. An entry costs a map per channel it holds, and the stack three entries
    /// more: the phone bench (2026-11-09) measured every specimen at or under this, rounded up, where a constant of two
    /// left five of them up to 7% over.
    nonisolated static func channelCost(_ masks: [Float]) -> Int? {
        let white = Float(Channels.white.rawValue)
        guard masks.contains(where: { $0 != white }) else { return nil }
        return masks.reduce(3) { $0 + Int($1).nonzeroBitCount }
    }
}

struct PictureLayer: View {
    let picture: Picture
    let side: CGFloat
    /// A live picture: the level's seed and its clock in seconds.
    var seed = 0
    var clock = 0.0
    /// The halftone's panel, a Lens level's number (`Level.panel`), 0 for the test panel; or on the play screen an
    /// Escapement problem's number (`Level.plate`).
    var panel = 0
    /// When the picture lands and starts to strike, for whatever strikes with it.
    var onStrike: () -> Void = {}
    @Environment(\.displayScale) private var scale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDimFlashingLights) private var dimFlashing
    @State private var image: UIImage?

    /// How long `strike` runs.
    static func strikeLength(calm: Bool) -> Double { KeyframeTimeline(initialValue: 0.0) { strike(calm: calm) }.duration }

    /// The picture's opacity as it lands: a flicker, or under Reduce Motion or Dim Flashing Lights (`calm`) a fade.
    @KeyframesBuilder<Double> static func strike(calm: Bool) -> some Keyframes<Double> {
        // Black until the screen's 0.27 s dip in has landed, or the fade swallows the strike.
        MoveKeyframe(0.0)
        LinearKeyframe(0.0, duration: 0.25)
        if calm {
            LinearKeyframe(1.0, duration: 0.25, timingCurve: .easeOut)
        } else {
            MoveKeyframe(0.8)
            LinearKeyframe(0.8, duration: 0.04)
            MoveKeyframe(0.1)
            LinearKeyframe(0.1, duration: 0.06)
            MoveKeyframe(0.95)
            LinearKeyframe(0.95, duration: 0.03)
            MoveKeyframe(0.35)
            LinearKeyframe(0.35, duration: 0.05)
            LinearKeyframe(1.0, duration: 0.16, timingCurve: .easeOut)
        }
    }

    var body: some View {
        let _ = DragProbe.count(.picture)
        ZStack {
            if picture.isLive, let data = picture.data(seed: seed, clock: clock) {
                Rectangle().fill(ShaderFunction(library: .default, name: "\(picture)")(
                    .float(side / 2), .float(2 / (side * scale)), .floatArray(data),
                    .float(Float(clock.truncatingRemainder(dividingBy: picture.period)))))
            } else if let image, abs(image.size.width - side) < 1 {
                Image(uiImage: image)
            } else if let image {
                // The size it had, until a change of pose's bake at the new size lands.
                Image(uiImage: image).resizable()
            } else {
                picture.ground
            }
        }
        .frame(width: side, height: side)
        // Flickers on like a neon tube when the texture lands. Over black, opacity is a colour multiply the shader samples for free.
        // Transparent until then, which over black matches the placeholder and keeps a live picture from showing before the strike.
        // Ink on paper is printed, not lit: it fades in over the paper, which lies under it inside the layer the shader samples.
        .keyframeAnimator(initialValue: 0.0, trigger: image != nil) { picture, o in picture.opacity(o) } keyframes: { _ in
            Self.strike(calm: reduceMotion || dimFlashing || picture.paper)
        }
        .background { if picture.paper { Color.bone } }
        .onChange(of: image != nil) { if image != nil { onStrike() } }
        // A live picture bakes nothing: the empty image only strikes the tube, once its data is ready.
        .task(id: [picture.rawValue, "\(seed)", "\(side)", "\(scale)", "\(panel)"]) {
            if picture.isLive { await picture.prepare(seed: seed) }
            let baked = picture.isLive ? UIImage() : await picture.render(side: side, scale: scale, panel: panel)
            // The halftone's detached bake runs on when a change of pose cancels it, and may land after the new one.
            guard !Task.isCancelled else { return }
            image = baked
        }
    }
}
