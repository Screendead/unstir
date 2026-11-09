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
    /// The committed work drawn with four taps, nil for the glass's static limit (`Tank.fourTaps(pixels:)`). Never
    /// animated: only `Taps` moves it, at a still moment.
    var budget: Int?
    @Environment(\.displayScale) private var scale

    nonisolated var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get { AnimatablePair(AnimatablePair(liveAngle, wind), AnimatablePair(haze, turn)) }
        set { (liveAngle, wind, haze, turn) = (newValue.first.first, newValue.first.second, newValue.second.first, newValue.second.second) }
    }

    func body(content: Content) -> some View {
        let rods = layout.rods
        var floats: [Float] = [], channels: [Float] = []
        floats.reserveCapacity(4 * (stack.count + 1))
        func add(_ rod: Int, _ angle: Double) {
            channels.append(Float((masks[rod] ?? .white).rawValue))
            floats.append(Float(rods[rod].x)); floats.append(Float(rods[rod].y))
            // A lens's entry is marked by a negative radius, and takes its flow's time for the angle.
            let lens = lenses.contains(rod)
            floats.append(Float(lens ? -rods[rod].z : rods[rod].z))
            floats.append(Float(lens ? angle / Tank.step * Tank.lensRate : angle))
        }
        for (i, t) in stack.enumerated() { add(t.rod, Double(t.steps) * Tank.step * min(shares?[i] ?? wind, 1)) }
        if let tick { add(tick.rod, tick.angle) }
        if let liveRod { add(liveRod, liveAngle) }
        let breathes = breath.map { $0.angle != 0 } ?? false
        if breathes, let breath { add(breath.rod, breath.angle) }
        let n = floats.count / 4
        if floats.isEmpty { floats = [0, 0, 0, 0] }
        let r = side / 2
        // A live picture keeps four taps only to the budget less its fill: the same budget as without it. Counted in
        // committed work, so a touch never changes the taps: the drag, the breath or a tick in flight rides one entry
        // over, or Prism's its own cost (`weigh`), within the 41 the shader's comment measured on the 13 Pro Max's glass.
        // Two in flight at once, for the `Breath.fade` a touch takes to cut a slosh or a grab within a tick's flight,
        // drop to two taps at the budget's edge rather than run one more.
        let taps = budget.map { $0 - fillEntries } ?? Self.taps(side: side, scale: scale, fill: fillEntries)
        let weight = Self.weigh(channels, inFlight: n - stack.count)
        let limit = Float(taps + weight.rides)
        if let cost = weight.cost {
            let tint = whiteIsolate ? SIMD3<Float>(1, 1, 1) : SIMD3<Float>(isolate?.tint ?? SIMD3(1, 1, 1))
            return content.layerEffect(
                ShaderLibrary.unstirChannels(.float2(r, r), .float(r), .floatArray(floats), .floatArray(channels), .float(Float(n)),
                                             .float(Float(cost)), .float(limit), .float(Float(Tank.plateau)),
                                             .float(Float(Tank.swirlPlateau)), .float(Float(Tank.lensEdge)), .float(Float(scale)), .float(Float(haze)),
                                             .float3(wave.x, wave.y, wave.z), .float(Float(turn)),
                                             .float(Float(isolate?.rawValue ?? 0)), .float3(tint.x, tint.y, tint.z)),
                maxSampleOffset: CGSize(width: side, height: side))
        }
        return content.layerEffect(
            ShaderLibrary.unstir(.float2(r, r), .float(r), .floatArray(floats), .float(Float(n)), .float(limit), .float(Float(Tank.plateau)),
                                 .float(Float(Tank.swirlPlateau)), .float(Float(Tank.lensEdge)), .float(Float(scale)), .float(Float(haze)), .float3(wave.x, wave.y, wave.z), .float(Float(turn))),
            maxSampleOffset: CGSize(width: side, height: side))
    }
}

extension Unstirred {
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
        .task(id: [picture.rawValue, "\(seed)", "\(side)", "\(scale)"]) {
            if picture.isLive { await picture.prepare(seed: seed) }
            let baked = picture.isLive ? UIImage() : await picture.render(side: side, scale: scale)
            // The halftone's detached bake runs on when a change of pose cancels it, and may land after the new one.
            guard !Task.isCancelled else { return }
            image = baked
        }
    }
}
