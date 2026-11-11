// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What the solve that finishes a tier, with the last tier the whole free game, or a paid pack plays between its wave
/// and its card. Three options for Jack to choose between, each only behind UNSTIR_PAYOFF, so a plain launch plays none:
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
    /// What was finished: a tier, the last being the whole free game, or else a paid pack.
    let tier: Tier?
    let pack: Pack?
    /// Each level's best in the ladder's order: the tier's, every tier's for the game, or the pack's.
    let marks: [Mark]
    /// Under Reduce Motion nothing winds, counts or turns: each option lands on what it leaves standing.
    var still = false
    /// Escapement's paper, where nothing glows: the halo is two rings in the plate's vermilion, the tally and the
    /// curtain vermilion and ink, and no second wave runs, as the shader's would turn the bone white.
    var paper = false

    /// A name and its colours: a tier's, or the pack's.
    struct Part: Equatable {
        let name: String
        let colours: [Color]
        let glow: Color
    }

    struct Cue {
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
    var cleans: Int { marks.filter { $0 == .clean }.count }
    /// What the log calls it.
    var label: String { whole ? "game" : tier?.rawValue ?? pack?.rawValue ?? "" }

    init(option: Option, tier: Tier? = nil, pack: Pack? = nil, marks: [Mark], still: Bool = false, paper: Bool = false) {
        (self.option, self.tier, self.pack, self.marks, self.still, self.paper) = (option, tier, pack, marks, still, paper)
    }

    /// The payoff `game`'s solve earned: its tier's (`Game.tierDone`), or its pack's, on the solve that completes the
    /// pack (`Game.completed`).
    @MainActor init?(_ game: Game, still: Bool = false) {
        let pack = game.completed?.pack
        guard let option = Self.option, game.tierDone != nil || pack != nil else { return nil }
        self.still = still
        self.option = option
        tier = pack == nil ? game.tierDone : nil
        self.pack = pack
        paper = game.level.page.paper
        let levels = pack?.levels ?? (game.tierDone == Tier.allCases.last ? Tier.allCases : [game.tierDone!]).flatMap(\.levels)
        marks = levels.map { level in
            guard let best = Best.load(level.id) else { return .none }
            // Escapement has no par: its bests are clean or solved.
            return best.clean == true ? .clean : best.over == 0 && level.ratchets.isEmpty ? .par : .solved
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
    /// the last one's rigid core, wound together through whole turns: the reverse of the swirl, which turns the glass's
    /// edge and lets go towards its centre.
    func entries(at t: Double) -> [Float] {
        guard let (k, s) = whirl(at: t) else { return [] }
        let turns = whole ? (k == whirls - 1 ? 2.5 : 1.5) : 2.0
        let angle = Float(2 * .pi * turns * Self.winding(s))
        guard angle != 0 else { return [] }
        return [0.999, 0.6, 0.36].flatMap { [0, 0, Float($0), angle] }
    }

    /// The light that runs out from the centre as a whirl lets go, as the shader's wave: its radius, negative for none.
    func wave(at t: Double) -> Float {
        if still || paper { return -1 }
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
    func passing(at t: Double) -> Part? {
        guard whole, option == .a, !still, t >= Self.wound, t < Double(whirls - 1) * Self.whirl + Self.wound else { return nil }
        return parts[min(Int((t - Self.wound) / Self.whirl), parts.count - 1)]
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

    /// When each of the curtain's lines comes up: a name, by its place among `parts`, the stamp and the credit.
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
        if let pack {
            return String(localized: "\(marks.count) \(pack.noun) unstirred",
                          comment: "The curtain after a pack's last level, under the pack's name: its levels by the pack's own word")
        }
        return whole ? String(localized: "every tier unstirred", comment: "The curtain after the last free level")
            : String(localized: "unstirred.", comment: "The curtain after a tier's last level, under the tier's name")
    }

    /// The tally's line on the card.
    var tally: String {
        // A pack's card already says how many it holds ("Lens complete · 25 panels").
        pack != nil ? String(localized: "\(cleans) of \(marks.count) clean",
                             comment: "Result card, a pack finished: how many of its levels were solved clean")
            : String(localized: "\(marks.count) tanks unstirred \u{00B7} \(cleans) clean",
                     comment: "Result card, a tier or the whole game finished: its levels, and how many clean")
    }

    /// Whether the card carries the credit; the curtain shows its own.
    var creditsOnCard: Bool { whole && option == .b }

    /// What VoiceOver hears of it, after the level's own result.
    var spoken: String {
        if let pack {
            return String(localized: "\(pack.name) finished: \(marks.count) \(pack.noun), \(cleans) clean.",
                          comment: "VoiceOver: the card of a pack's last level")
        }
        guard let tier else { return "" }
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
            let arcs = parts.indices.map {
                Cue(at: Double(($0 + 1) * marks.count / parts.count) * pip, effect: .heal(whole ? 2 * $0 + 1 : 6))
            }
            return ticks + arcs + [Cue(at: Double(marks.count) * pip + 0.1, effect: .solve)]
        case .c:
            return parts.indices.map { Cue(at: rises($0), effect: .tier) } + [Cue(at: rises(parts.count), effect: .solve)]
        }
    }
}
