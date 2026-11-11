// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What the solve that finishes a tier, or with the last tier the whole free game, plays between its wave and its
/// card. Three options for Jack to choose between, each only behind UNSTIR_PAYOFF, so a plain launch plays none:
/// `a`, the glass stirs itself; `b`, the bezel counts the tier's tanks; `c`, a curtain call.
struct Payoff: Equatable {
    enum Option: String { case a, b, c }
    /// A level's best as the tally lights it.
    enum Mark { case none, solved, par, clean }

    /// UNSTIR_PAYOFF=a, b or c; nil on a plain launch.
    @MainActor static var option: Option?
    /// UNSTIR_PAYOFFAT=s: the payoff held s seconds in, for stills.
    @MainActor static var frozen: Double?
    /// UNSTIR_PAYOFFSKIP=s: ended s seconds in, as a tap ends it.
    @MainActor static var skips: Double?

    let option: Option
    let tier: Tier
    /// Each level's best in the ladder's order: the tier's, or every tier's for the game.
    let marks: [Mark]
    /// Under Reduce Motion nothing winds, counts or turns: each option lands on what it leaves standing.
    var still = false

    struct Cue {
        let at: Double
        let effect: Sound.Effect
    }

    /// The last tier's: the whole free game.
    var whole: Bool { tier == Tier.allCases.last }
    var tiers: [Tier] { whole ? Tier.allCases : [tier] }
    var cleans: Int { marks.filter { $0 == .clean }.count }

    init(option: Option, tier: Tier, marks: [Mark], still: Bool = false) {
        (self.option, self.tier, self.marks, self.still) = (option, tier, marks, still)
    }

    @MainActor init?(_ game: Game, still: Bool = false) {
        guard let option = Self.option, let tier = game.tierDone else { return nil }
        self.still = still
        self.option = option
        self.tier = tier
        marks = (tier == Tier.allCases.last ? Tier.allCases : [tier]).flatMap(\.levels).map { level in
            guard let best = Best.load(level.id) else { return .none }
            return best.clean == true ? .clean : best.over == 0 ? .par : .solved
        }
    }

    /// Seconds from the solve to the payoff's start: the solve's own wave runs out first.
    static let lead = 1.1

    /// Seconds the payoff holds the screen before the card comes.
    var length: Double {
        if still { return option == .c ? (whole ? 6 : 3) : 0.9 }
        switch option {
        case .a: return whole ? 4 * Self.whirl + 1.3 : Self.whirl + 0.9
        case .b: return Double(marks.count) * pip + 0.9
        case .c: return whole ? 9.4 : 3.6
        }
    }

    /// Whether the header, the title, the caption and the controls leave for it: never for a halo fading on.
    var clearsChrome: Bool { option == .c || option == .a && whole && !still }
    /// Whether the knobs and every line on the glass leave for it.
    var clearsGlass: Bool { option != .b }

    // MARK: a, the glass stirs itself

    /// One whirl: the wind, a beat held, the unwind, and the rest before the next.
    static let whirl = 1.5
    private static let wound = 0.85, held = 0.95, unwound = 1.4

    /// How far whirl `k` is wound at `s` seconds into it, 0 to 1.
    private static func winding(_ s: Double) -> Double {
        if s <= 0 || s >= unwound { return 0 }
        if s < wound { let x = s / wound; return x * x * (3 - 2 * x) }
        if s < held { return 1 }
        let x = (s - held) / (unwound - held)
        return pow(1 - x, 3)
    }

    private var whirls: Int { whole ? 4 : 1 }

    /// The whirl `t` is in, and the seconds into it.
    private func whirl(at t: Double) -> (k: Int, s: Double)? {
        guard option == .a, !still, t >= 0, t < Double(whirls) * Self.whirl else { return nil }
        let k = Int(t / Self.whirl)
        return (k, t - Double(k) * Self.whirl)
    }

    /// The whirl's entries, as the shader reads them over the stack: three discs about the tank's centre, each inside
    /// the last one's rigid core, wound together through whole turns. No rod is the tank's size on a layout without a
    /// swirl, the swirl holds the rim rather than the centre, and no stir in play passes a turn.
    func entries(at t: Double) -> [Float] {
        guard let (k, s) = whirl(at: t) else { return [] }
        let turns = whole ? (k == whirls - 1 ? 2.5 : 1.5) : 2.0
        let angle = Float(2 * .pi * turns * Self.winding(s))
        guard angle != 0 else { return [] }
        return [0.999, 0.6, 0.36].flatMap { [0, 0, Float($0), angle] }
    }

    /// The light that runs out from the centre as a whirl lets go, as the shader's wave: its radius, negative for none.
    func wave(at t: Double) -> Float {
        if still { return -1 }
        switch option {
        case .a:
            // The last whirl has no rest after it but the payoff's own tail.
            guard t >= 0, t < length else { return -1 }
            let k = min(Int(t / Self.whirl), whirls - 1), s = t - Double(k) * Self.whirl - (Self.unwound - 0.25)
            return s >= 0 && s < 0.9 ? Float(1.9 * (1 - pow(1 - s / 0.9, 2))) : -1
        case .b:
            let s = t - Double(marks.count) * pip
            return s >= 0 && s < 0.9 ? Float(1.9 * (1 - pow(1 - s / 0.9, 2))) : -1
        case .c:
            return -1
        }
    }

    /// The tiers whose last pictures pass through the glass, each from its whirl's hold until the next's: the game's
    /// alone, and not the last tier's, which is the solved picture itself.
    var relay: [Level] { option == .a && whole && !still ? Tier.allCases.dropLast().compactMap(\.levels.last) : [] }

    /// How far relay picture `j` shows at `t`: in over its whirl's held beat, out over the next's.
    func relayed(_ j: Int, at t: Double) -> Double {
        func swap(_ k: Int) -> Double { min(max((t - Double(k) * Self.whirl - Self.wound) / (Self.held - Self.wound), 0), 1) }
        return swap(j) * (1 - swap(j + 1))
    }

    /// How far the glass's halo is lit: with each whirl's letting go, and for good after the last.
    func halo(at t: Double) -> Double {
        guard option == .a else { return 0 }
        return min(max((t - (still ? 0 : Double(whirls - 1) * Self.whirl + Self.unwound - 0.25)) / 0.6, 0), 1)
    }

    /// The tier whose colours the halo wears while the relay shows its picture, nil for the payoff's own.
    func passing(at t: Double) -> Tier? {
        guard whole, option == .a, !still, t >= Self.wound, t < Double(whirls - 1) * Self.whirl + Self.wound else { return nil }
        return Tier.allCases[min(Int((t - Self.wound) / Self.whirl), Tier.allCases.count - 1)]
    }

    // MARK: b, the bezel counts

    /// Seconds between one level's segment lighting and the next's.
    var pip: Double { whole ? 0.03 : 0.06 }

    /// How many segments are lit at `t`.
    func lit(at t: Double) -> Int { t < 0 ? 0 : still || !t.isFinite ? marks.count : min(Int(t / pip) + 1, marks.count) }

    // MARK: c, the curtain call

    /// The glass's own turn, one whole turn over the curtain, so the picture ends upright.
    func turn(at t: Double) -> Double {
        guard option == .c, !still, t > 0, t < length else { return 0 }
        let x = t / length
        return 2 * .pi * x * x * x * (x * (6 * x - 15) + 10)
    }

    /// When each of the curtain's lines comes up: a tier's name, by its place among `tiers`, the stamp and the credit.
    func rises(_ line: Int) -> Double { still ? 0.2 : whole ? 0.7 + 0.8 * Double(line) : 0.5 + 0.7 * Double(line) }
    /// When the curtain starts to lift.
    var lifts: Double { length - 0.5 }

    // MARK: words

    /// The one credit, after the whole free game. Its wording is Jack's to set.
    static var credit: String {
        String(localized: "made by Jack \u{00B7} thank you for playing", comment: "The credit after the last free level")
    }

    /// What the curtain says under the names: the stamp's word, or the completion's line.
    var stamp: String {
        whole ? String(localized: "every tier unstirred", comment: "The curtain after the last free level")
            : String(localized: "unstirred.", comment: "The curtain after a tier's last level, under the tier's name")
    }

    /// The tally's line on the card.
    var tally: String {
        String(localized: "\(marks.count) tanks unstirred \u{00B7} \(cleans) clean",
               comment: "Result card, a tier or the whole game finished: its levels, and how many clean")
    }

    /// Whether the card carries the credit; the curtain shows its own.
    var creditsOnCard: Bool { whole && option == .b }

    /// What VoiceOver hears of it, after the level's own result.
    var spoken: String {
        let done = whole ? String(localized: "The whole game finished: \(marks.count) tanks unstirred, \(cleans) clean.",
                                  comment: "VoiceOver: the last free level's card")
            : String(localized: "\(tier.name) finished: \(marks.count) tanks unstirred, \(cleans) clean.",
                     comment: "VoiceOver: the card of a tier's last level")
        return whole && option != .a ? done + " " + String(localized: "Made by Jack. Thank you for playing.",
                                                           comment: "VoiceOver: the credit after the last free level") : done
    }

    // MARK: sound

    /// The sounds it plays, each at its seconds in, from the set the game already has.
    var cues: [Cue] {
        if still { return [] }
        switch option {
        case .a:
            // Each whirl winds on the tier switch's sound and lets go on a run of the heal's notes, higher each time,
            // the last on the solve's chime.
            return (0 ..< whirls).flatMap { k -> [Cue] in
                let at = Double(k) * Self.whirl
                let run = (0 ..< 3).map { Cue(at: at + Self.held + 0.07 * Double($0), effect: .heal(min(k + $0 + (whole ? 1 : 3), 6))) }
                return [Cue(at: at, effect: .tier)] + run + (k == whirls - 1 ? [Cue(at: at + Self.unwound - 0.25, effect: .solve)] : [])
            }
        case .b:
            // A tick a segment, or for the game one in three, a heal's note as each tier's arc closes, then the chime.
            let ticks = stride(from: 0, to: marks.count, by: whole ? 3 : 1).map { Cue(at: Double($0) * pip, effect: .tick) }
            let arcs = tiers.indices.map {
                Cue(at: Double(($0 + 1) * marks.count / tiers.count) * pip, effect: .heal(whole ? 2 * $0 + 1 : 6))
            }
            return ticks + arcs + [Cue(at: Double(marks.count) * pip + 0.1, effect: .solve)]
        case .c:
            return tiers.indices.map { Cue(at: rises($0), effect: .tier) } + [Cue(at: rises(tiers.count), effect: .solve)]
        }
    }
}
