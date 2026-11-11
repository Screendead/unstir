// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The curtain call (Jack's call PAYOFF = C): what the solve that finishes a tier, with the last tier the whole free
/// game, or a paid pack plays between its wave and its card. The header and controls leave, the glass dims and turns
/// once, and the tier's or pack's name stands over it above what was unstirred; the game's names each tier in turn,
/// then the credit.
struct Payoff: Equatable {
    /// UNSTIR_PAYOFFAT=s: the curtain held s seconds in on a level opened solved, for stills.
    @MainActor static var frozen: Double?
    /// UNSTIR_PAYOFFSKIP=s: ended s seconds in, as a tap ends it.
    @MainActor static var skips: Double?

    /// What was finished: a tier, the last being the whole free game, or else a paid pack.
    let tier: Tier?
    let pack: Pack?
    /// Under Reduce Motion nothing turns and the lines come up together.
    var still = false
    /// Escapement's paper, where nothing glows: the veil is bone, the name the plate's vermilion and the rest ink.
    var paper = false

    /// A name and its colours: a tier's, or the pack's.
    struct Part: Equatable {
        let name: String
        let colours: [Color]
        let glow: Color
    }

    struct Cue: Equatable {
        let at: Double
        let effect: Sound.Effect
    }

    /// The last tier's: the whole free game.
    var whole: Bool { tier != nil && tier == Tier.allCases.last }
    /// The tier's, each tier's for the game, or the pack's.
    var parts: [Part] {
        if let pack {
            let offer = Offer.pack(pack)
            return [Part(name: pack.name, colours: offer.sweep, glow: offer.glow)]
        }
        return (whole ? Tier.allCases : tier.map { [$0] } ?? []).map { Part(name: $0.name, colours: $0.colours, glow: $0.glow) }
    }
    /// What the log calls it.
    var label: String { whole ? "game" : tier?.rawValue ?? pack?.rawValue ?? "" }

    init(tier: Tier? = nil, pack: Pack? = nil, still: Bool = false, paper: Bool = false) {
        (self.tier, self.pack, self.still, self.paper) = (tier, pack, still, paper)
    }

    /// The curtain `game`'s solve earned: its tier's (`Game.tierDone`), or its pack's, on the solve that completes the
    /// pack (`Game.completed`).
    @MainActor init?(_ game: Game, still: Bool = false) {
        // Not First Stir's, whose last level ends on the night forwards.
        let pack = game.completed?.pack.flatMap { $0.ships ? $0 : nil }
        guard game.tierDone != nil || pack != nil else { return nil }
        self.init(tier: pack == nil ? game.tierDone : nil, pack: pack, still: still, paper: game.level.page.paper)
    }

    // MARK: time

    /// Seconds from the solve to the curtain's start: the solve's own wave runs out first.
    static let lead = 1.1

    /// Seconds the curtain holds the screen before the card comes: as short as its lines read.
    var length: Double { still ? (whole ? 5 : 2.6) : whole ? 7.4 : 3.2 }

    /// The glass's own turn, one whole turn over the curtain, so the picture ends upright.
    func turn(at t: Double) -> Double {
        guard !still, t > 0, t < length else { return 0 }
        let x = t / length
        return 2 * .pi * x * x * x * (x * (6 * x - 15) + 10)
    }

    /// When each of the curtain's lines comes up: a name by its place among `parts`, then the stamp, then the credit
    /// a beat after it.
    func rises(_ line: Int) -> Double {
        if still { return 0.2 }
        return (whole ? 0.5 : 0.4) + 0.6 * Double(line) + (line > parts.count ? 0.4 : 0)
    }
    /// When the curtain starts to lift.
    var lifts: Double { length - 0.5 }

    // MARK: words

    /// The one credit, shown after the whole free game and said by VoiceOver, in Jack's words.
    enum Credit {
        static var shown: String {
            String(localized: "made by screendead \u{00B7} thank you for playing",
                   comment: "The credit after the last free level. screendead is the maker's name, never translated")
        }
        static var spoken: String {
            String(localized: "Made by screendead. Thank you for playing.",
                   comment: "VoiceOver: the credit after the last free level. screendead is the maker's name, never translated")
        }
    }

    /// What the curtain says under the names.
    var stamp: String {
        if let pack {
            return String(localized: "\(pack.counted(pack.levels.count)) unstirred",
                          comment: "The curtain after a pack's last level, under the pack's name: its levels counted")
        }
        return whole ? Completion.free.line
            : String(localized: "unstirred.", comment: "The curtain after a tier's last level, under the tier's name")
    }

    /// The curtain as VoiceOver says it, as it starts.
    var spoken: String {
        if let pack {
            return String(localized: "\(pack.name): \(pack.counted(pack.levels.count)) unstirred.",
                          comment: "VoiceOver: the curtain after a pack's last level. The pack, then its levels counted")
        }
        guard let tier else { return "" }
        guard whole else { return Self.spoken(tier) }
        return parts.map(\.name).formatted(.list(type: .and)) + ". " + Completion.free.spoken + " " + Credit.spoken
    }

    private static func spoken(_ tier: Tier) -> String {
        String(localized: "\(tier.name), unstirred.", comment: "VoiceOver: the curtain after a tier's last level. The tier")
    }

    /// What the card's label adds for it, as the card's own lines already say a pack or the game is complete: a tier's
    /// finish, and after the game the credit.
    var carded: String? { pack != nil ? nil : whole ? Credit.spoken : tier.map(Self.spoken) }

    // MARK: sound

    /// The sounds it plays, each at its seconds in, all the game's own at their own levels: the tier switch's as the
    /// name comes up, and under the stamp two of the heal's notes, the fifth and the tonic above it. The game's names
    /// rise up the heal's scale instead, a note each, and its stamp lands on the solve's chime, the solve's own having
    /// rung out by then; under Reduce Motion its names come up as one, so it sounds as a tier's does. Mixed after a
    /// level's last heal and chime, with or without a pack's resolution, each curtain's loudest 0.4 s is within 2 LU
    /// of that solve's own.
    var cues: [Cue] {
        let stamp = rises(parts.count) + (still ? 0.45 : 0)
        guard whole, !still else {
            return [Cue(at: rises(0), effect: .tier), Cue(at: stamp, effect: .heal(4)), Cue(at: stamp + 0.15, effect: .heal(6))]
        }
        return zip(parts.indices, [1, 3, 4, 6]).map { Cue(at: rises($0), effect: .heal($1)) } + [Cue(at: stamp, effect: .solve)]
    }

    // MARK: room

    /// How far inside the glass's edge the words keep, as a share of its radius.
    static let inset = 0.94
    /// Between a glass that has given up room and the words under it.
    static let gap: CGFloat = 20

    /// Whether the curtain's lines, each `width` wide and from `top` to `bottom` in a block `height` tall, all lie
    /// inside a glass of radius `r` with the block centred on it.
    static func fits(_ lines: [CGRect], height: CGFloat, r: CGFloat) -> Bool {
        lines.allSatisfy { line in
            let reach = max(abs(line.minY - height / 2), abs(line.maxY - height / 2))
            return hypot(line.width / 2, reach) <= inset * r
        }
    }

    /// The least the glass shrinks to for the words: under a card's `PlayLayout.leastFinished`, as the curtain can't
    /// scroll and the game's six lines at the play screen's largest type need this much of the smallest phone.
    static let least: CGFloat = 0.45

    /// The text never shrinks: where the lines pass the glass's edge they stand under it instead, and the glass, its
    /// rim `stage` tall with `room` under it, scales about its top by this to leave them `block` and `gap`, down to
    /// `least`.
    static func scale(block: CGFloat, room: CGFloat, stage: CGFloat) -> CGFloat {
        guard stage > 0 else { return 1 }
        return min(max((stage + room - block - gap) / stage, least), 1)
    }
}
