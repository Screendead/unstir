// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

struct Run: Hashable, Sendable {
    var seed: UInt64
    var tank = 0
}

/// The difficulty ladder, easiest first: declaration order is the ladder, so a new tier goes in where it belongs. The
/// raw value is stored as the menu's choice, so it never changes.
enum Tier: String, CaseIterable {
    case plughole, whirlpool, maelstrom

    var name: String {
        switch self {
        case .plughole: "Plughole"
        case .whirlpool: "Whirlpool"
        case .maelstrom: "Maelstrom"
        }
    }

    /// Starts each of the tier's level ids. Whirlpool's and maelstrom's are from their old names, nightmare and
    /// nightmare+: progress is stored by id, so changing a prefix loses it unless the stored keys are remapped.
    var prefix: String {
        switch self {
        case .plughole: "L"
        case .whirlpool: "N"
        case .maelstrom: "N+"
        }
    }

    /// Nil for plughole.
    var below: Tier? {
        let i = Self.allCases.firstIndex(of: self)!
        return i == 0 ? nil : Self.allCases[i - 1]
    }

    var levels: [Level] {
        switch self {
        case .plughole: Level.plughole
        case .whirlpool: Level.whirlpool
        case .maelstrom: Level.maelstrom
        }
    }

    /// Per level, whether its best is at or under par. Hints don't count against it.
    func atPar(_ best: (String) -> Best? = Best.load) -> [Bool] {
        levels.map { best($0.id).map { $0.over == 0 } ?? false }
    }

    /// Plughole always; any other tier once every level of the tier below is at par.
    func isOpen(unlocked: Bool = Best.unlocked, _ best: (String) -> Best? = Best.load) -> Bool {
        unlocked || below.map { $0.atPar(best).allSatisfy { $0 } } ?? true
    }

    /// The tier the menu opens on: the last one stored, or the highest open one below it if that has closed since.
    static func stored(open: (Tier) -> Bool = { $0.isOpen() }) -> Tier {
        let tier = UserDefaults.standard.string(forKey: "tier").flatMap(Tier.init(rawValue:)) ?? .plughole
        return allCases.prefix(through: allCases.firstIndex(of: tier)!).last(where: open) ?? .plughole
    }

    /// A locked tier can be opened to look at, but only an open one is stored, so a look never comes back on launch.
    static func store(_ tier: Tier, open: (Tier) -> Bool = { $0.isOpen() }) {
        if open(tier) { UserDefaults.standard.set(tier.rawValue, forKey: "tier") }
    }
}

struct Level: Hashable, Sendable {
    var id: String
    /// Daily, endless and the sandbox are plughole's.
    var tier = Tier.plughole
    var label: String
    var title: String
    /// One line under the tank, for levels that teach something the title cannot.
    var note = ""
    var picture = Picture.grid
    var layout: Layout
    /// Plays the scramble forward on open and on reset. Past the first three levels nothing shows the order.
    var replay = false
    /// Applied bottom first; the player unwinds from the top.
    var scramble: [Twist]
    var run: Run?
    /// Knobs that ignore touch. The tank turns only on a level that has some, to carry their fluid to a working knob.
    var seized: Set<Int> = []
    /// Nil is one move per entry. A level with seized knobs also counts its turns of the tank.
    var fixedPar: Int?
    var par: Int { fixedPar ?? scramble.count }

    var sandbox: Bool { id == "sandbox" }

    static let plughole: [Level] = ([
        (.tri, "0:+4", "Turn it back.", "Turn a rod to look. Let go where you started and nothing happens."),
        (.tri, "1:-7", "Further than it looks.", ""),
        (.tri, "2:+3,0:-5", "Two stirs. Undo the second one first.", "The last rod you saw turn is on top."),
        (.tri, "0:+3,1:+5", "Nobody replays it for you now.", "Where two rings cross, the later one runs unbroken."),
        (.tri, "1:-2,2:+4,0:-6", "Where the discs overlap, order is everything.", ""),
        (.tri, "0:+2,1:-4,0:+5", "Corn syrup has a long memory.", "One rod was stirred twice. Its newer stir comes off first."),
        (.tri, "2:+2,0:-3,1:+5,2:-6", "Stirring is chaos. Unstirring is bookkeeping.", ""),
        (.tri, "1:-6,2:+4,0:+2", "The loudest swirl went in first.", "Turn a rod to look. A fresh hard ring means not that one."),
        (.quad, "0:+3,2:-4", "These two never touch. Either first.", "Rings that never meet come off in any order."),
        (.quad, "2:-4,0:-3,3:-5,1:-4", "Four rods, one rule.", ""),
        (.quad, "0:+4,2:-4,3:-5,1:-4,2:+6", "Take whichever ring is whole.", ""),
        (.quad, "2:-3,0:+4,3:+7,0:-2,1:-3,2:-5", "Quiet does not mean early.", ""),
        (.quad, "1:+2,2:-2,3:+4,0:+6,1:-7,3:+3,2:+4", "G. I. Taylor ran the film backwards. So can you.", ""),
        (.eye, "0:-3,2:+5,1:-6,3:-7", "Big rods shout. Small rods still count.", ""),
        (.eye, "1:-2,0:-5,3:+6,2:+3,0:-4", "A small stir on top of a big one.", ""),
        (.eye, "0:+4,2:+5,0:-4", "The tail follows the rod that moved last.", "Turned, stirred past, turned back: all it leaves is a tail."),
        (.eye, "3:+3,2:-3,0:-6,2:-3,0:-6,1:-3,3:+4", "Viscous, reversible, mildly smug.", ""),
        (.eye, "3:+4,2:-2,1:+6,0:-5,3:+6,1:-2,2:+5,3:-4", "Laminar, if you squint.", ""),
        (.pent, "4:+3,0:+5,4:-6,1:-3,2:+4,3:+7", "Five rods and no middle.", ""),
        (.pent, "1:+2,2:+4,1:+2,0:+4,3:+4,4:+5,1:+2", "Read the crossings, not the colours.", ""),
        (.pent, "4:+3,3:+6,1:-3,4:+4,2:-4,0:+3,4:+6,3:-7", "Every ring is nearly whole. One is.", ""),
        (.pent, "3:-4,0:-3,4:+5,3:-2,4:-3,1:-2,2:-2,3:+4,2:-3", "Chaotic advection, politely reversed.", ""),
        (.hex, "5:+4,3:+2,4:+5,6:-3,2:-4,5:+7,1:+7", "Seven rods. Same rule.", ""),
        (.hex, "3:-4,2:-5,0:+2,6:-3,4:-2,5:+6,4:+7,2:+4", "The hub cuts everything.", ""),
        (.hex, "6:-2,2:+3,4:+4,5:-6,1:+5,2:-2,1:-3,6:+6,2:-4,3:-5", "Low Reynolds number, high standards.", ""),
        (.hex, "1:+4,5:+3,2:+5,1:-3,0:-2,5:+3,2:-3,1:-4,4:+5,3:-3,2:-7,6:+2", "Mixing is easy. Ask anyone.", ""),
        (.hex, "2:+3,0:-5,5:+6,4:+3,0:+4,6:-7,0:+5,5:-6,6:-6,2:+4,5:+3,1:+5,3:+2,0:+6", "Unstirred, by hand.", ""),
    ] as [(Layout, String, String, String)]).enumerated().map { i, l in
        // The city only where par is 4 or less: deeper, it goes murky.
        Level(id: Tier.plughole.prefix + "\(i + 1)", label: String(format: "%02d", i + 1), title: l.2, note: l.3,
              picture: [5: .sunset, 11: .sunset, 15: .sunset, 6: .city, 10: .city, 14: .city, 16: .city][i + 1] ?? .grid,
              layout: l.0, replay: i < 3, scramble: .parse(l.1, in: l.0))
    }

    /// Twice the stirs of the same-numbered level, more of them hidden under louder ones, live pictures, nothing replayed.
    static let whirlpool: [Level] = ([
        (.tri, "0:-5,1:+3", "Turn them back.", "Same rules, twice the stirs, no replays. This is the last note."),
        (.tri, "2:+7,0:-7", "Both went further than they look.", ""),
        (.tri, "1:-6,2:+3,0:-4,1:+4", "Four stirs. Undo the fourth one first.", ""),
        (.tri, "2:-5,1:+4,2:+2,0:-5", "The newest seam is never broken.", ""),
        (.tri, "1:-2,0:+7,2:+3,0:-2,1:+6,2:-3", "Where the discs overlap, order is all you get.", ""),
        (.tri, "0:+7,2:-7,0:+3,1:+6,2:-7,1:-3", "The syrup remembers more than you do.", ""),
        (.tri, "0:-2,1:-2,0:+7,1:+4,0:+2,2:-6,1:+5,2:-7", "Bookkeeping, by candlelight.", ""),
        (.tri, "0:+4,2:+4,1:-6,0:-6,2:-6,1:+3", "Loudness is not a clock.", ""),
        (.quad, "2:+3,3:+2,0:-5,1:-2", "These two never touch. The others do.", ""),
        (.quad, "2:-2,3:-3,2:-3,3:-2,0:+3,1:+5,0:+4,1:+7", "Four rods. The rule has not changed.", ""),
        (.quad, "0:+4,1:-4,3:+2,0:-6,3:+7,0:-5,2:+2,1:+4,2:-6,1:-6", "Find the ring that is whole. It is there.", ""),
        (.quad, "2:+4,1:+2,2:-2,3:-2,0:+3,3:-4,0:+4,1:+5,2:-6,0:-2,1:+5,3:-4", "Quiet means nothing.", ""),
        (.quad, "2:-4,1:+5,2:-5,3:-3,2:-6,1:-2,3:-3,2:+5,1:+7,0:-5,3:+5,1:+4,0:+6,3:+5", "Taylor had a handle. You have a finger.", ""),
        (.eye, "1:-2,2:-2,0:+2,3:-4,1:-5,0:+7,2:+2,3:+3", "Big rods shout. Listen to the small ones.", ""),
        (.eye, "0:-3,2:-2,3:+4,0:-6,3:+7,1:-5,3:+6,1:-6,2:+5,0:+7", "Small on big, all the way down.", ""),
        (.eye, "0:-2,3:-2,2:+3,1:+4,0:-4,1:+3", "No tails this time. I checked.", ""),
        (.eye, "3:-2,2:+2,1:-3,2:-6,1:-2,0:-2,1:+4,3:+2,0:+2,2:-2,3:+2,0:+4,2:-7,1:+5", "Viscous, reversible, no longer smug.", ""),
        (.eye, "1:+4,0:+2,2:+4,3:-4,0:+5,2:+6,1:-4,3:+2,1:-3,2:+3,3:-4,0:-3,1:-6,3:+6,0:-7,2:+6", "Laminar. Squinting will not help.", ""),
        (.pent, "2:+2,0:+2,3:+2,1:-4,2:+5,1:-7,0:-7,3:+2,2:-3,3:+6,4:-4,0:-4", "Five rods and no middle. You remember.", ""),
        (.pent, "4:+3,2:-2,3:+5,1:+2,0:-5,2:-7,3:+3,4:-7,3:+4,2:-6,1:-4,0:+3,1:-3,0:+6", "Read the crossings. There is nothing else.", ""),
        (.pent, "4:-4,3:+7,4:-5,1:-3,2:+3,3:-6,0:-2,4:+7,1:+3,2:-2,0:+5,3:+4,2:+4,1:-4,2:+7,4:-4", "Every ring is nearly whole. Two are.", ""),
        (.pent, "0:-2,3:+4,1:+2,2:-2,1:+4,0:-3,4:+3,2:+4,1:+7,0:-4,2:-2,1:+2,4:+3,3:+4,2:-2,3:-2,0:-3,4:-5", "Chaotic advection, reversed without comment.", ""),
        (.hex, "5:-4,0:+3,1:-4,0:+4,4:-3,2:-3,3:+4,6:+2,0:+4,1:+5,3:+4,4:-3,5:-5,4:-6", "Seven rods. Same rule. Less light.", ""),
        (.hex, "3:+3,0:+5,4:+2,2:-2,1:-2,5:-3,0:+3,6:-3,5:+4,4:+4,3:+5,1:+4,0:-4,5:-5,1:-2,4:-7", "The hub still cuts everything.", ""),
        (.hex, "1:+2,3:-4,4:+4,2:+2,5:-2,3:-3,1:+3,0:-5,6:-4,4:+3,5:+5,2:-3,3:+4,2:-5,0:-5,6:+5,1:+4,5:-2,6:-6,0:-6", "At higher Reynolds number, this is impossible.", ""),
        (.hex, "1:+2,6:-2,3:+2,2:-4,1:+4,0:+5,6:+5,0:+6,4:-7,6:-2,2:-3,1:-3,6:+6,0:+3,5:-2,4:-2,3:+2,5:-4,0:+2,5:-5,4:-7,5:+3,4:-6,1:-2", "Mixing is easy. I would know.", ""),
        (.hex, "3:+3,4:-2,5:-2,6:-2,2:-2,4:-2,1:-4,3:+4,6:-4,1:-5,0:-7,2:+3,5:-4,1:+3,0:+5,1:+6,6:-3,5:+4,0:-6,6:+5,0:+4,2:-6,3:+7,1:+4,4:-4,2:+6,3:-5,2:+2", "Unstirred, by hand, in the dark.", ""),
    ] as [(Layout, String, String, String)]).enumerated().map { i, l in
        // The glass opens each layout and takes the deepest levels. Coral reads only to 6 stirs, and neurons, the dearest
        // to draw, to 14.
        Level(id: Tier.whirlpool.prefix + "\(i + 1)", tier: .whirlpool, label: String(format: "%02d", i + 1),
              title: l.2, note: l.3,
              picture: [3: .chainmail, 10: .chainmail, 13: .chainmail, 18: .chainmail, 21: .chainmail, 24: .chainmail,
                        2: .coral, 5: .coral, 8: .coral, 16: .coral, 4: .neurons, 7: .neurons, 11: .neurons, 17: .neurons,
                        20: .neurons, 6: .marbling, 12: .marbling, 15: .marbling, 22: .marbling, 25: .marbling][i + 1] ?? .glass,
              layout: l.0, scramble: .parse(l.1, in: l.0))
    }

    /// Until maelstrom has levels of its own: whirlpool's scrambles under ids of their own, so a whirlpool best or
    /// start never opens a level here or spends its first try, each on its whirlpool picture's twin.
    static let maelstrom: [Level] = whirlpool.enumerated().map { i, level in
        var level = level
        level.id = Tier.maelstrom.prefix + "\(i + 1)"
        level.tier = .maelstrom
        level.picture = level.picture.twin
        return level
    }

    /// Everyone gets the same tank that day: seeded from yyyymmdd.
    static func daily(_ date: Date = .now) -> Level {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        let ymd = c.year! * 10000 + c.month! * 100 + c.day!
        var rng = SplitMix64(state: UInt64(ymd))
        let layout = generated[rng.below(4)]
        let depth = 10 + rng.below(5)
        return Level(id: "daily-\(ymd)", label: "day", title: String(format: "Daily, %04d-%02d-%02d", c.year!, c.month!, c.day!),
                     layout: layout, scramble: layout.scramble(depth: depth, inversions: 3, rng: &rng))
    }

    static func endless(_ run: Run) -> Level {
        // Wrapping, to match the prototype's 64-bit arithmetic.
        var rng = SplitMix64(state: run.seed &* 1000 &+ UInt64(run.tank))
        let layout = generated[run.tank % 4]
        return Level(id: "endless", label: "\u{221E}", title: "Endless", layout: layout,
                     scramble: layout.scramble(depth: min(4 + run.tank, 24), inversions: run.tank / 3, rng: &rng), run: run)
    }

    static let sandbox = Level(id: "sandbox", label: "box", title: "Sandbox", layout: .tri, scramble: [])

    /// The triangle is hand-written: every rod overlaps, so the generator's ordered sizes overshoot there.
    private static let generated: [Layout] = [.quad, .eye, .pent, .hex]

}

extension Layout {
    /// Push-only scramble of `depth` entries, `inversions` of them no louder than an undo-able twist they cover.
    /// Ported draw for draw from the prototype, so the dailies match it.
    func scramble(depth: Int, inversions: Int, rng: inout SplitMix64) -> [Twist] {
        var stack: [Twist] = [], inv = inversions
        for i in 0..<depth {
            let top = removable(stack)
            let eligible = rods.indices.filter { k in !top.contains { stack[$0].rod == k } }
            let want = inv > 0 && rng.below(depth - i) < inv
            let louder = eligible.filter { (covered(stack, $0) ?? 1) < 8 }
            let under = eligible.filter { covered(stack, $0) != nil }
            let inverting = (want && !under.isEmpty) || louder.isEmpty
            let pool = inverting ? under : louder
            let k = pool[rng.below(pool.count)]
            let c = covered(stack, k) ?? 1
            let m: Int
            if inverting {
                m = 2 + rng.below(max(c - 1, 1))
                inv -= 1
            } else {
                m = c + 1 + rng.below(min(3, 8 - c))
            }
            var s = rng.below(2) == 0 ? m : -m
            // Never near-cancel the same rod's stir two below: that pattern is level 16's lesson, not noise.
            if let prev = stack.suffix(2).last(where: { $0.rod == k }), abs(s + prev.steps) <= 1 { s = -s }
            stack.commit(rod: k, steps: s, in: self)
        }
        return stack
    }

    /// The largest undo-able twist a new twist on rod k would cover, if any.
    func covered(_ stack: [Twist], _ k: Int) -> Int? {
        removable(stack).filter { overlaps(stack[$0].rod, k) }.map { abs(stack[$0].steps) }.max()
    }

    /// Entries no louder than the loudest undo-able twist they covered when they went on: the still frame hides these.
    func inversions(_ word: [Twist]) -> Int {
        var stack: [Twist] = [], n = 0
        for t in word {
            if let c = covered(stack, t.rod), abs(t.steps) <= c { n += 1 }
            stack.commit(rod: t.rod, steps: t.steps, in: self)
        }
        return n
    }
}

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476C_E5E4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func below(_ n: Int) -> Int { Int(next() % UInt64(n)) }
}

struct Best: Codable {
    var over: Int, hints: Int, seconds: Int
    /// Stored, because only a first try can be clean and a later one can match its numbers. Optional so saves from the
    /// test builds that predate it still decode and keep the next level open; v1 saves never decode, as they lack `over`.
    var clean: Bool?

    static func load(_ id: String) -> Best? {
        UserDefaults.standard.data(forKey: "best.\(id)").flatMap { try? JSONDecoder().decode(Best.self, from: $0) }
    }

    /// The harness's: this launch sees it as the id's best, and it is never written to disk.
    func fake(_ id: String) {
        if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.register(defaults: ["best.\(id)": data]) }
    }

    /// Keeps the better of this and the stored result: clean, then fewer over par, then fewer hints, then faster.
    func save(_ id: String) {
        func rank(_ b: Best) -> (Int, Int, Int, Int) { (b.clean == true ? 0 : 1, b.over, b.hints, b.seconds) }
        if let old = Best.load(id), rank(old) <= rank(self) { return }
        UserDefaults.standard.set(try? JSONEncoder().encode(self), forKey: "best.\(id)")
    }

    /// Set when a rod is first touched or a hint shown: probing counts as trying, only studying the still is free.
    static func started(_ id: String) -> Bool { UserDefaults.standard.bool(forKey: "started.\(id)") }
    static func start(_ id: String) { if !started(id) { UserDefaults.standard.set(true, forKey: "started.\(id)") } }

    /// Banked undos, shared by every level and mode: 10 to start, and nothing refills them yet. Stored as the number
    /// spent, so a fresh install reads 10.
    static var undos: Int {
        get { 10 - UserDefaults.standard.integer(forKey: "undos.spent") }
        set { UserDefaults.standard.set(10 - newValue, forKey: "undos.spent") }
    }

    /// The developer unlock, set by a launch with UNSTIR_UNLOCK=1 and cleared by one with UNSTIR_UNLOCK=0: every tier
    /// and every level open.
    static var unlocked: Bool {
        get { UserDefaults.standard.bool(forKey: "unlock") }
        set { UserDefaults.standard.set(newValue, forKey: "unlock") }
    }

    /// Endless: most tanks cleared in one run.
    static var tanks: Int {
        get { UserDefaults.standard.integer(forKey: "endless.tanks") }
        set { UserDefaults.standard.set(newValue, forKey: "endless.tanks") }
    }
}
