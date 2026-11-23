// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The play screen on the slope (docs/slope.md, 4): the ground under a level, its header, title and caption, and the
/// terrace its controls rest on. `LevelView` keeps the state and hands each of these values and closures, as it hands
/// today's chrome (`PlayChrome.swift`); with `slopeWorld` off none of this is drawn.

/// The ground under a level (4.1): the slope drawn aside, the water at the level's depth and one terrace rising from the
/// screen's foot in its rock. A still while the level plays; `glint` lights the terrace once it is solved.
struct SlopePlayGround: View, Equatable {
    let level: Level
    var glint = 0.0

    /// Drawn again only when what it shows changes, never for the play screen's own state as a finger drags.
    nonisolated static func == (a: Self, b: Self) -> Bool { a.level == b.level && a.glint == b.glint }

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                              height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
            let column = SlopeColumn.main(size: size, type: typeSize)
            let lay = SlopeLay(column, z: 1)
            let (focus, at) = Self.place(level, lay, height: size.height)
            SlopeScene(column: column, focus: focus, at: at, z: 1, held: true,
                       look: Self.look(level, rock: lay.rocks[focus], glint: glint), near: false) { _ in EmptyView() }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// The ledge whose water a level plays in, and where the camera holds it: a tier's level its own; the daily, the
    /// sandbox and a pack's level the shallows; an archive day the archive's; endless the open water under the brink.
    static func place(_ level: Level, _ lay: SlopeLay, height: CGFloat) -> (Int, CGFloat) {
        if level.run != nil {
            let last = lay.count - 1
            return (last, (lay.tops[last] - (lay.endless - 0.5 * height)) / height)
        }
        if let ledge = SlopeColumn.ledge(of: level) { return (ledge, 0.49) }
        // The shallows with the surface just over the screen's top, so the header stands in water, never in the air.
        let ledge = level.archived ? SlopeColumn.archive : SlopeColumn.today
        return (ledge, (lay.tops[ledge] - SlopePlay.under) / height)
    }

    /// Prism plays in clear water and white light, Lens with its terrace lit in its glow, Escapement on paper.
    static func look(_ level: Level, rock: SlopeColumn.Rock, glint: Double) -> SlopeLook {
        var look = SlopeLook(level: 1, glint: glint, rock: rock)
        switch level.pack {
        case .prism?:
            look.clear = 1
            look.rock = .pale
            look.glow = SIMD3(1, 1, 1)
        case .lens?:
            look.glow = Self.rgb(Offer.pack(.lens).glow)
        default:
            break
        }
        if level.page.paper { look.paper = 1 }
        return look
    }

    private static func rgb(_ colour: Color) -> SIMD3<Float> {
        let c = colour.resolve(in: EnvironmentValues())
        return SIMD3(c.red, c.green, c.blue)
    }
}

extension Level {
    /// The slope's way back (4.2): "↑ levels" for a tier's and a pack's level, "↑ archive" for an archive day, "↑ menu"
    /// for the daily, endless and the sandbox.
    var slopeBack: String {
        let place = archived ? String(localized: "archive", comment: "The play screen's back button, to the archive")
            : pack == nil && (run != nil || sandbox || id.hasPrefix("daily-"))
            ? String(localized: "menu", comment: "The slope's play screen's back, from the daily or endless to the menu")
            : String(localized: "levels", comment: "The play screen's back button, to the menu")
        return "\u{2191} " + place
    }
}

/// The header (4.2): the way back top leading, the count top trailing, or under the way back where the player's type
/// is an accessibility size (`stacked`).
struct SlopePlayHeader<Count: View>: View {
    let back: String
    let backSpoken: String
    let stacked: Bool
    let hidden: Bool
    let leave: () -> Void
    @ViewBuilder let count: Count

    @Environment(\.page) private var page

    var body: some View {
        let way = Button(action: leave) {
            Text(back).font(.slope(.ui, .body)).foregroundStyle(page.paper ? page.ink : SlopeInk.ink2.colour).hit() // loc: verbatim localized by Level.slopeBack
        }
        .buttonStyle(Sounding())
        .accessibilityLabel(backSpoken) // loc: verbatim localized by Spoken.back
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: SlopePlay.stackGap) {
                    way
                    count
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    way
                    Spacer()
                    count
                }
            }
        }
        .font(.slope(.data, .label))
        .padding(.top, 8)
        .modifier(Unseen(hidden))
    }
}

/// The title (4.3), centred over the tank: the number, then the name; a pack's level its pack's name small over them,
/// in the gap above so the tank stands where every level's does. Prism's number is white with a faint white glow.
struct SlopePlayTitle: View {
    let label: String
    let title: String
    let pack: String?
    let prism: Bool
    let hidden: Bool

    @Environment(\.page) private var page

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 11) {
            Text(label).font(.slope(.data, .body)) // loc: verbatim a number, or localized by Level
                .foregroundStyle(page.paper ? page.ink : prism ? Color.white : SlopeInk.ink2.colour)
                .shadow(color: prism ? .white.opacity(0.45) : .clear, radius: 6)
            Text(title).font(.slope(.name, .display)).foregroundStyle(page.paper ? page.ink : SlopeInk.ink.colour) // loc: verbatim localized by Level and the caller
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            if let pack {
                // The size the title's 18 pt gap holds, as today's (`PlayTitle`).
                Text(verbatim: pack).font(.slope(.data, .detail)).dynamicTypeSize(.large) // loc: verbatim a pack's name, never translated
                    .foregroundStyle(page.paper ? page.ink : SlopeInk.ink3.colour)
                    .fixedSize()
                    .offset(y: -TypeRole.detail.line(at: .large).height - 2)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .padding(.top, 18)
        .modifier(Unseen(hidden))
    }
}

/// The note and every caption that takes its place (4.4), centred under the tank in the place voice, and plughole
/// 01's pointer to the settings hung under it once ever. The result's lines hang from it in `card`, as on today's
/// screen (`PlayCaption`).
struct SlopeCaption<Card: View>: View {
    let text: String
    /// The note at rest reads at `ink2`, a fresh note or a notice at `ink`.
    let lit: Bool
    let opacity: Double
    let minHeight: CGFloat
    let pointing: Bool
    let pointerShown: Bool
    let settled: Bool
    let type: DynamicTypeSize
    let quiet: Bool
    let skips: Bool
    let skip: () -> Void
    let hidden: Bool
    @ViewBuilder let card: Card

    @Environment(\.page) private var page

    var body: some View {
        Text(text) // loc: verbatim localized by LevelView, Game and say
            .font(.slope(.place, .body))
            .foregroundStyle(page.paper ? page.ink : SlopeInk.ink.colour)
            .opacity((page.paper || lit ? 1 : SlopeInk.ink2.strength) * opacity)
            .animation(.easeOut(duration: 0.6), value: lit)
            .overlay(alignment: .bottom) {
                if pointing {
                    Text(SlopePlay.pointer).font(.slope(.ui, .detail)) // loc: verbatim localized by pointer
                        .foregroundStyle(page.paper ? page.ink : SlopeInk.ink3.colour)
                        .fixedSize()
                        .opacity(pointerShown ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: settled)
                        .accessibilityLabel(SlopePlay.pointerSpoken) // loc: verbatim localized by pointerSpoken
                        .accessibilityHidden(!pointerShown)
                        .offset(y: TypeRole.detail.line(at: type).height + 7)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .top)
            .padding(.top, 14)
            .accessibilityHidden(quiet)
            .modifier(SkipButton(on: skips, skip: skip))
            .overlay(alignment: .top) { card }
            .modifier(Unseen(hidden))
    }
}

/// The terrace's row (4.5): its seats set on the ground's terrace, the stones at either end and a middle one centred,
/// and a second terrace's stone centred over it. It takes the controls' place in the play screen's stack, so the
/// layout's arithmetic stands.
struct SlopeTerrace: View {
    let seats: TerraceSeats
    /// The screen the ground's terrace is drawn for: each stone on the first row is set down on the terrace's top where
    /// it stands (`SlopeLay.terrace`), which rises and falls a few points across it.
    var ground: Ground?
    /// The second terrace's rock, or the paper's ink.
    var rock = SlopeColumn.Rock.sand

    /// The screen's height, safe areas in, and the space the row is measured in, whose origin is `top` under the
    /// screen's, so the row moves with the screen and its ground, as under the back swipe.
    struct Ground {
        var height: CGFloat
        var top: CGFloat
        var space: String
    }

    /// The row, as laid out in `ground`'s space.
    @State private var row = CGRect.zero

    var body: some View {
        VStack(spacing: LevelView.controlRows) {
            if let upper = seats.upper {
                // Its ledge's top a point over the pebble's underside, `rest` under the row's middle.
                // Lifted with the row under it, which its stones' terrace lifts.
                upper.frame(maxWidth: .infinity, minHeight: SlopePebble.target)
                    .background(alignment: .bottom) {
                        TerraceLedge(rock: rock).offset(y: PlayStone.rest - 1 - SlopePebble.target / 2 + TerraceLedge.height)
                    }
                    .offset(y: settle(row.midX))
            }
            // The middle stone halfway between its neighbours, as today's row spaces its three.
            HStack(spacing: 0) {
                seats.leading.offset(y: settle(row.minX + PlayStone.reach))
                Spacer(minLength: PlayLayout.controlGap)
                if let middle = seats.middle {
                    middle.offset(y: settle(row.midX))
                    Spacer(minLength: PlayLayout.controlGap)
                }
                seats.trailing.offset(y: settle(row.maxX - PlayStone.reach))
            }
            .frame(minHeight: SlopePebble.target)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ground?.space ?? "")) } action: { row = $0 }
        }
        .overlay(alignment: .bottom) {
            // Into the safe area's foot, under the row, where the terrace's sand is: the water's shade behind it, as no
            // word is set on lit sand (1.4). Nothing in the column moves for it.
            seats.under?.fixedSize()
                .background { Ellipse().fill(Color(0x061016).opacity(0.6)).padding(.horizontal, -14).padding(.vertical, -6).blur(radius: 7) }
                .alignmentGuide(.bottom) { $0[.top] - 6 }
        }
    }
}

extension SlopeTerrace {
    /// How far a stone whose pebble stands at `x` moves so the pebble rests on the terrace, a point into its sand.
    private func settle(_ x: CGFloat) -> CGFloat {
        guard let ground, row.height > 0 else { return 0 }
        return SlopeLay.terrace(x, height: ground.height) + 1 - (ground.top + row.midY + PlayStone.rest)
    }
}

/// A second terrace's ledge, a short overhung lip of the play terrace's rock standing out of the water over the first,
/// for a stone that needs a row of its own (4.5, 5.2). A stand-in until the ground draws it (Slope.metal draws one
/// terrace): its top bows, and on paper it is an ink outline.
struct TerraceLedge: View {
    var rock: SlopeColumn.Rock
    var width: CGFloat = 170

    static let height: CGFloat = 16

    @Environment(\.page) private var page

    var body: some View {
        let shape = Lip()
        Group {
            if page.paper {
                shape.stroke(page.ink, lineWidth: 1.2)
            } else {
                shape.fill(Color(0x2A2E36))
                    .overlay(shape.fill(LinearGradient(colors: [rock.light.opacity(0.7), rock.light.opacity(0.08)],
                                                       startPoint: .top, endPoint: .bottom)))
                    .overlay(shape.stroke(rock.light.opacity(0.35), lineWidth: 0.8).mask(alignment: .top) { Rectangle().frame(height: 3) })
            }
        }
        .frame(width: width, height: Self.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The lip: a top that bows up a few points, rounded noses at either end, and an underside cut back under them.
    private struct Lip: Shape {
        func path(in r: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: r.minX, y: r.minY + 5))
                p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + 4), control: CGPoint(x: r.midX, y: r.minY - 3))
                p.addQuadCurve(to: CGPoint(x: r.maxX - 16, y: r.maxY), control: CGPoint(x: r.maxX + 2, y: r.maxY - 2))
                p.addQuadCurve(to: CGPoint(x: r.minX + 18, y: r.maxY), control: CGPoint(x: r.midX, y: r.maxY - 5))
                p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + 5), control: CGPoint(x: r.minX - 3, y: r.maxY - 3))
                p.closeSubpath()
            }
        }
    }
}

/// The day's refill (4.5): "+2", the first ever "+2 undos", in data at label, rising 14 pt over undo's count and
/// standing 3 s once the opening is over.
struct SlopeRefill: View {
    let badge: Int
    let first: Bool
    let colour: Color
    let frozen: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        KeyframeAnimator(initialValue: LevelView.refillTime, trigger: badge) { s in
            let t = frozen ?? s, shown = badge > 0 ? LevelView.refillShown(t) : 0
            (first ? Text("+\(badge) undos", comment: "Over the undo button: the day's first refill") : Text(verbatim: "+\(badge)"))
                .font(.slope(.data, .label)).foregroundStyle(colour)
                .opacity(shown)
                .offset(y: reduceMotion ? -14 : -14 * min(max((t - 0.3) / 0.5, 0), 1))
        } keyframes: { _ in
            MoveKeyframe(0.0)
            LinearKeyframe(LevelView.refillTime, duration: LevelView.refillTime)
        }
        .fixedSize()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension PlayStone {
    /// The pebble stands this far under its words' middle, so it rests on the terrace while the words stay over the
    /// water above it, never on the lit sand.
    static let drop: CGFloat = 6
    /// Its underside under the row's middle, and its middle in from the row's end, at the default type size.
    static let rest: CGFloat = drop + 7
    static let reach: CGFloat = 10
}

/// A stone on the terrace that sounds as today's control did: undo's and reset's own sounds where `Stone` plays the
/// tap. Drawn as `Stone` draws one (1.4): the pebble with its words beside it, sinking while touched, rocking when
/// `refused` changes.
struct PlayStone: View {
    var label: Text
    var state = StoneState.lit
    var pale = false
    var engraved = false
    var trailing = false
    /// Nil for a tap that is only refused, which sounds `seized` alone.
    var effect: Sound.Effect? = .tap
    var refused = 0
    /// Escapement's wait, lit for a beat after a wait.
    var lit = false
    var action: () -> Void

    @ViewBuilder var body: some View {
        let button = Button(action: action) {
            Face(label: label, state: state, pale: pale, engraved: engraved, trailing: trailing, refused: refused, lit: lit)
        }
        if let effect { button.buttonStyle(Sounding(effect: effect, presses: true)) } else { button.buttonStyle(Silent()) }
    }

    private struct Silent: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label.environment(\.buttonPressed, configuration.isPressed)
        }
    }

    private struct Face: View {
        var label: Text
        var state: StoneState
        var pale: Bool
        var engraved: Bool
        var trailing: Bool
        var refused: Int
        var lit: Bool

        @Environment(\.buttonPressed) private var pressed
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.page) private var page
        @ScaledMetric(relativeTo: .body) private var grain = 1.0

        private var kind: SlopePebble.Kind {
            if engraved { return .engraved }
            switch state {
            case .dull: return .dull
            case .next: return pale ? .pale : .next
            case .lit, .armed, .pending: return pale ? .pale : .lit
            }
        }

        var body: some View {
            let width = (state == .dull ? 17 : 20) * min(grain, 1.4)
            HStack(spacing: 12) {
                if trailing { words }
                SlopePebble(kind: kind, width: width, lean: .radians(trailing ? 0.1 : -0.08),
                            glow: state == .armed ? Page.night.stop : nil, dimmed: state == .dull)
                    .keyframeAnimator(initialValue: 0.0, trigger: refused) { stone, degrees in
                        stone.rotationEffect(.degrees(reduceMotion ? 0 : degrees), anchor: .bottom)
                    } keyframes: { _ in
                        CubicKeyframe(6, duration: 0.05)
                        CubicKeyframe(-6, duration: 0.08)
                        CubicKeyframe(6, duration: 0.07)
                        CubicKeyframe(-6, duration: 0.06)
                        CubicKeyframe(0, duration: 0.04)
                    }
                    .offset(y: PlayStone.drop + ((pressed || lit) && !reduceMotion ? 2 : 0))
                    .scaleEffect(pressed || lit ? 0.97 : 1)
                    .brightness(pressed && reduceMotion ? -0.12 : 0)
                if !trailing { words }
            }
            .frame(minWidth: SlopePebble.target, minHeight: SlopePebble.target)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.2), value: pressed)
            .animation(.easeOut(duration: 0.15), value: lit)
            .onChange(of: refused) { Sound.shared.play(.seized) }
        }

        private var words: some View {
            let colour: Color = engraved ? page.ink : state == .armed ? Page.night.stop : SlopeInk.ink.colour
            return label.font(.slope(.ui, .body, lit ? .medium : nil)).foregroundStyle(colour)
                .opacity(engraved ? 1 : state == .dull ? SlopeInk.ink4.strength / SlopeInk.ink.strength : 1)
                .fixedSize()
        }
    }
}

/// Prism's swatches when colour letters are on (4.5): three pale stones between the note and the terrace, each glowing
/// in its channel and lettered R, G or B, held rather than tapped and filled while held.
struct SlopeSwatches: View {
    @Binding var isolated: Channels?

    var body: some View {
        HStack(spacing: 28) {
            ForEach(Channels.each, id: \.rawValue) { c in
                let held = isolated == c
                HStack(spacing: 8) {
                    SlopePebble(kind: .pale, width: held ? 22 : 18, glow: c.colour, breath: nil)
                        .brightness(held ? 0.08 : 0)
                    Text(verbatim: c.letters).font(.slope(.data, .body, held ? .semibold : nil)).foregroundStyle(c.colour) // loc: verbatim a channel's letter
                }
                .frame(minWidth: SlopePebble.target, minHeight: SlopePebble.target)
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.15), value: held)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: 60, perform: {}) { pressing in
                    if pressing { isolated = c } else if isolated == c { isolated = nil }
                }
                .accessibilityElement()
                .accessibilityLabel(c.alone) // loc: verbatim localized by Channels
                .accessibilityValue(held ? Text("on", comment: "VoiceOver: a switch, on") // loc: verbatim each a key
                                    : Text("off", comment: "VoiceOver: a switch, off"))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { isolated = held ? nil : c }
            }
        }
        .padding(.top, 4)
    }
}

/// The slope's play screen's words and measures.
enum SlopePlay {
    /// The most the terrace lifts its stones over the row the column lays out at the safe area's foot, `inset` over the
    /// screen's: the terrace's top stands 54 pt over the screen's foot, give or take 11 across it (`SlopeLay.terrace`),
    /// and a stone's underside `PlayStone.rest` under its row's middle, the row 4 pt over the safe area's foot.
    static func lift(inset: CGFloat) -> CGFloat {
        max(0, 54 + 11 - inset - 4 - SlopePebble.target / 2 + PlayStone.rest)
    }

    /// How far under the surface the shallows' camera stands, so no word is set within `SlopeInk.shallowest` of it.
    static let under: CGFloat = 48

    /// Between the way back and the count stacked under it.
    static let stackGap: CGFloat = 2

    /// Plughole 01's pointer: the gear it named is gone; settings is a stone at the surface (Jack's call, 12.7).
    static var pointer: String {
        String(localized: "sound, haptics, colour letters: in settings, at the surface",
               comment: "Plughole 01's pointer to the settings, on the slope")
    }

    static var pointerSpoken: String {
        String(localized: "Sound, haptics and colour letters are in settings, at the surface of the menu.",
               comment: "VoiceOver: plughole 01's pointer to the settings, on the slope")
    }

    /// The header's count at rest, at par with the stack not empty, and over par.
    static func parTone(moves: Int, par: Int) -> Color {
        moves < par ? SlopeInk.ink2.colour : moves == par ? .amber : .magenta
    }

    /// The caption's room: two lines of the note in the place voice at `type`.
    static func captionLines(type: DynamicTypeSize) -> CGFloat {
        2 * TypeRole.body.line(at: type, .light, design: .serif).height
    }

    /// Whether the count stands under the way back: the player's type at an accessibility size, the play screen's
    /// capped at `PlayLayout.typeCap`.
    static func stacked(_ type: DynamicTypeSize) -> Bool { type.isAccessibilitySize }

    /// How tall the title's name stands at `type` in a pane `width` wide: a line of the name voice at display, two
    /// where it wraps.
    static func titleHeight(_ level: Level?, type: DynamicTypeSize, width: CGFloat) -> CGFloat {
        let style = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle, compatibleWith:
            UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(type)))
        let name = UIFont(descriptor: style.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.light]]), size: 0)
        guard let level, width.isFinite else { return name.lineHeight }
        let number = TypeRole.body.width(of: level.label, at: type) + 11
        let words = (level.title as NSString).size(withAttributes: [.font: name]).width
        return name.lineHeight * (number + words <= width ? 1 : 2)
    }
}
