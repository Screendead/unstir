// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The play screen's way out and, at its trailing edge, its count: moves against par, Escapement's ticks or the
/// sandbox's controls, which `LevelView` hands in. `hidden` while the chrome stands aside for the curtain.
struct PlayHeader<Count: View>: View {
    let back: String
    let backSpoken: String
    let hidden: Bool
    let leave: () -> Void
    @ViewBuilder let count: Count

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            UnstirButton(.quiet, action: leave) { Text(back).font(.ui(.button)) } // loc: verbatim localized by Level.back
                .accessibilityLabel(backSpoken) // loc: verbatim localized by Spoken.back
            Spacer()
            count
        }
        .font(.ui(.label))
        .padding(.top, 8)
        .modifier(Unseen(hidden))
    }
}

/// The header's count of moves against par, endless's without one (`par` nil). It flashes red on each push
/// (`pushes`), else reads in `tone`.
struct MovesCount: View {
    let moves: Int
    let par: Int?
    let pushes: Int
    let tone: Color
    let hidden: Bool
    let spoken: String

    var body: some View {
        (par.map { Text("moves \(moves) / par \($0)", comment: "The play screen's count. Moves, then par") }
            ?? Text("moves \(moves)", comment: "The play screen's count, endless. Moves"))
            // On black the wasted-twist alarm reads at full contrast, whatever the picture shows.
            .keyframeAnimator(initialValue: 0.0, trigger: pushes) { [tone] text, t in
                text.foregroundStyle(t > 0.5 ? Color.alarm : tone)
            } keyframes: { _ in
                // Red for 0.4 s. A trailing MoveKeyframe never lands, so the ramp ends the flash.
                MoveKeyframe(1.0)
                LinearKeyframe(0.0, duration: 0.8)
            }
            .opacity(hidden ? 0 : 1)
            .accessibilityLabel(spoken) // loc: verbatim localized by Game.movesSpoken
    }
}

/// The level's number and title, a pack's name small in the gap above them.
struct PlayTitle: View {
    let label: String
    let title: String
    let colour: Color
    /// The number's glow, none on paper.
    let glow: Color
    let pack: String?
    let hidden: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(label).fontWeight(.semibold).foregroundStyle(colour) // loc: verbatim a number, or localized by Level
                .shadow(color: glow, radius: 4)
            Text(title) // loc: verbatim localized by Level and the caller
        }
        .font(.ui(.headline, .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topLeading) {
            // In the gap above the title, so a pack level's tank sits where every other level's does.
            if let pack {
                // The size the title's 18 pt gap holds.
                Text(verbatim: pack.uppercased()).font(.ui(.eyebrow)).tracking(2).dynamicTypeSize(.large) // loc: verbatim a pack's name, never translated
                    .foregroundStyle(colour).opacity(0.75)
                    .offset(y: -TypeRole.eyebrow.line(at: .large).height - 2)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, 18)
        .modifier(Unseen(hidden))
    }
}

/// The caption under the tank, which the result and lost cards hang from: `card` is their slot, filled by `LevelView`
/// once the level has finished. The play controls fade rather than leave, and the card is an overlay, so the solved
/// tank stays exactly where it was played.
struct PlayCaption<Card: View>: View {
    let text: String
    let font: Font
    let opacity: Double
    /// Its room: the note's two lines (`LevelView.captionLines`).
    let minHeight: CGFloat
    /// Plughole 01's pointer to the settings, hung under the note.
    let pointing: Bool
    let pointerOpacity: Double
    let pointerHidden: Bool
    /// The opening is over: the pointer fades in with it.
    let settled: Bool
    let type: DynamicTypeSize
    /// Hidden from VoiceOver, under a card or the night forwards.
    let quiet: Bool
    /// The caption is the opening's skip.
    let skips: Bool
    let skip: () -> Void
    let hidden: Bool
    @ViewBuilder let card: Card

    var body: some View {
        Text(text) // loc: verbatim localized by LevelView, Game and say
            .font(font).opacity(opacity)
            // Hung under the note rather than stacked, so plughole 01's tank sits where every level's does. Beside the
            // menu the gear is in sight, so there is nothing to point at (Jack's call r16c-pointer = C).
            .overlay(alignment: .bottom) {
                if pointing {
                    LevelView.pointer.font(.ui(.detail)).fixedSize()
                        .opacity(pointerOpacity)
                        .animation(.easeOut(duration: 0.4), value: settled)
                        .accessibilityLabel(LevelView.pointerSpoken) // loc: verbatim localized by pointerSpoken
                        .accessibilityHidden(pointerHidden)
                        // A gap below the note's last line.
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

/// Undo and reset, and on Escapement the wait (`wait`, `LevelView`'s): between them where the row holds all three on a
/// line each (`inlineWait`), stepping aside while reset is armed, as "reset? tap again" needs the room; else on a row
/// of its own over them (`waitRow`), where it stays. `alone`: the row can't hold undo beside an armed reset on a line
/// each, so undo steps aside until the reset is made or lapses, and no label wraps.
struct PlayControls<Wait: View, Reset: View>: View {
    let waitRow: Bool
    let inlineWait: Bool
    let alone: Bool
    /// The sandbox's undo has no bank.
    let sandbox: Bool
    let bank: Int
    /// An empty bank only says when it refills, so it only taps.
    let spent: Bool
    let nothingToUndo: Bool
    let badge: RefillBadge
    let undo: () -> Void
    @ViewBuilder let wait: Wait
    @ViewBuilder let reset: Reset

    var body: some View {
        VStack(spacing: LevelView.controlRows) {
            if waitRow { wait }
            HStack {
                if !alone {
                    // Only a turn of the tank swings back: animated, a rod's undo would glide the stack's shader floats
                    // too.
                    UnstirButton(.secondary, effect: spent ? .tap : .undo, dim: nothingToUndo || spent, action: undo) {
                        if sandbox { Text("undo") } else { Text("undo \u{00B7} \(bank)") }
                    }
                        .accessibilityLabel(sandbox ? Text("Undo", comment: "VoiceOver: the undo button") // loc: verbatim each a key
                                            : Text("Undo, \(bank) left", comment: "VoiceOver: the undo button. Undos left"))
                        .disabled(nothingToUndo)
                        .overlay(alignment: .topTrailing) { badge }
                }
                Spacer()
                if inlineWait {
                    wait
                    Spacer()
                }
                reset
            }
        }
    }
}

/// The day's refill, over the undo control's count once the opening is over and the control live. Always present, to
/// see `badge` change.
struct RefillBadge: View {
    let badge: Int
    /// The day's first refill names what it adds.
    let first: Bool
    let colour: Color
    /// UNSTIR_CLOCK: held this many seconds in.
    let frozen: Double?
    let type: DynamicTypeSize

    var body: some View {
        KeyframeAnimator(initialValue: LevelView.refillTime, trigger: badge) { s in
            (first ? Text("+\(badge) undos", comment: "Over the undo button: the day's first refill") : Text(verbatim: "+\(badge)"))
                .font(.ui(.detail)).foregroundStyle(colour)
                .opacity(badge > 0 ? LevelView.refillShown(frozen ?? s) : 0)
        } keyframes: { _ in
            MoveKeyframe(0.0)
            LinearKeyframe(LevelView.refillTime, duration: LevelView.refillTime)
        }
        // Its trailing edge on the count's, just above the capsule.
        .offset(x: -22, y: -TypeRole.detail.line(at: type).height - 8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The slope's world (docs/slope.md) in place of today's screens. Set by `RootView`; a Debug launch with
/// UNSTIR_SLOPE=world starts in it, so the screens built on it can be seen before the default flips. No Release build
/// reads the variable.
enum SlopeWorld {
    static let launched: Bool = {
        #if DEBUG
        ProcessInfo.processInfo.environment["UNSTIR_SLOPE"] == "world"
        #else
        false
        #endif
    }()
}

extension EnvironmentValues {
    /// The play screen, the result and every other screen draw the slope's world (`SlopeWorld`).
    @Entry var slopeWorld = SlopeWorld.launched
}

/// What stands on the play screen's terrace (docs/slope.md, 4.5 and 5.2): a stone at each of its three seats, a second
/// terrace over it where one row can't hold its words, and a line under its stones. Play fills it with undo, wait and
/// reset; once a level has finished, the view in `LevelView`'s card slot fills it with the result's stones by
/// `terraceSeats(_:)`, and the play screen sets them on the terrace in its controls' place. A seat left nil is empty.
struct TerraceSeats {
    var leading: AnyView?
    var middle: AnyView?
    var trailing: AnyView?
    /// The second terrace's stone, centred over the first: Escapement's wait where the row can't hold three, or up a
    /// notch where three seats can't each hold their words on one line. The finished tank gives way for it.
    var upper: AnyView?
    /// Under the stones, in the safe area's foot: the daily's "next daily in 7 h".
    var under: AnyView?

    init(leading: AnyView? = nil, middle: AnyView? = nil, trailing: AnyView? = nil, upper: AnyView? = nil, under: AnyView? = nil) {
        self.leading = leading
        self.middle = middle
        self.trailing = trailing
        self.upper = upper
        self.under = under
    }

    /// The seats a card hands up, and where the terrace's row stands, met at the play screen's stack.
    struct Key: PreferenceKey {
        struct Value {
            var seats: TerraceSeats?
            var row: Anchor<CGRect>?
        }

        static var defaultValue: Value { Value() }
        static func reduce(value: inout Value, nextValue: () -> Value) {
            let next = nextValue()
            value.seats = next.seats ?? value.seats
            value.row = next.row ?? value.row
        }
    }

    /// Whether the card's seats take a second terrace: the play screen keeps the finished tank clear of it.
    struct Upper: PreferenceKey {
        static let defaultValue = false
        static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
    }
}

extension View {
    /// Hands `seats` to the play screen's terrace, from the view in `LevelView`'s card slot.
    func terraceSeats(_ seats: TerraceSeats) -> some View {
        transformPreference(TerraceSeats.Key.self) { $0.seats = seats }
            .preference(key: TerraceSeats.Upper.self, value: seats.upper != nil)
    }
}
