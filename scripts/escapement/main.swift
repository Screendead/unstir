// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// A clock rod and the way it ticks: +1 over negative entries, or -1 (wound back) over positive ones.
struct Clock { var rod: Int; var dir: Int }

/// How a lift on the knob just let go counts. `final`: every lift that moves the knob is a move with its tick
/// (Jack's call, round 2). `lab`: a re-grab of the open stir's knob replays it at its new net with one tick, as
/// `lab-escapement` plays, so two moves in a row on one knob never happen.
enum Rule: String { case final, lab }

enum Move: Hashable, CustomStringConvertible {
    case wait
    case turn(Int, Int)
    var description: String {
        switch self {
        case .wait: "wait"
        case let .turn(r, s): "\(r):\(s > 0 ? "+" : "")\(s)"
        }
    }
    var rod: Int? { if case let .turn(r, _) = self { r } else { nil } }
}

struct Problem {
    var layout: Layout
    var stack: [Twist]
    /// In the order they tick.
    var clocks: [Clock]
    var rule: Rule

    func isClock(_ rod: Int) -> Bool { clocks.contains { $0.rod == rod } }
    func running(_ s: [Twist]) -> Bool { clocks.contains { c in s.contains { $0.rod == c.rod } } }

    /// Ticks still owed: the most any one clock needs, since every move ticks every running clock once.
    func owed(_ s: [Twist]) -> Int {
        clocks.map { c in max(0, -c.dir * s.filter { $0.rod == c.rod }.reduce(0) { $0 + $1.steps }) }.max() ?? 0
    }

    /// A lower bound on the moves left: every clock tick lands one step, and only a turn of a rod changes its net.
    func bound(_ s: [Twist]) -> Int {
        var net: [Int: Int] = [:]
        for t in s where !isClock(t.rod) { net[t.rod, default: 0] += t.steps }
        return max(owed(s), net.values.filter { $0 != 0 }.count)
    }

    /// The move and its ticks, or nil where a tick pushes: that entry can never pop, so the problem is lost.
    func play(_ s: [Twist], _ m: Move) -> [Twist]? {
        var s = s
        if case let .turn(r, n) = m { s.commit(rod: r, steps: n, in: layout) }
        for c in clocks where s.contains(where: { $0.rod == c.rod }) {
            if s.commit(rod: c.rod, steps: c.dir, in: layout) == .pushed, !keepsPushed { return nil }
        }
        return s
    }

    /// Waits and whole heals: turns that land on one entry and pop it.
    func cleanMoves(_ s: [Twist], after last: Move?) -> [Move] {
        var moves: [Move] = running(s) ? [.wait] : []
        var seen = Set<Move>()
        for i in s.indices where !isClock(s[i].rod) {
            let t = s[i]
            if rule == .lab, last?.rod == t.rod { continue }
            if s.landing(rod: t.rod, steps: -t.steps, in: layout) == i, seen.insert(.turn(t.rod, -t.steps)).inserted {
                moves.append(.turn(t.rod, -t.steps))
            }
        }
        return moves
    }

    /// Every turn of every working knob up to `span` steps either way, and the wait.
    func allMoves(_ s: [Twist], after last: Move?, span: Int) -> [Move] {
        var moves: [Move] = running(s) ? [.wait] : []
        for r in layout.rods.indices where !isClock(r) {
            if rule == .lab, last?.rod == r { continue }
            for n in -span...span where n != 0 { moves.append(.turn(r, n)) }
        }
        return moves
    }
}

/// ESC_PUSHED=1 plays on past a tick that pushes, to check that no such line ever empties the stack.
let keepsPushed = ProcessInfo.processInfo.environment["ESC_PUSHED"] == "1"

struct Key: Hashable {
    var s: [Twist]
    var last: Move?
    var left: Int
    /// Only the lab's rule reads the last move.
    init(s: [Twist], last: Move?, left: Int, rule: Rule) {
        self.s = s
        self.last = rule == .lab ? last : nil
        self.left = left
    }
}

/// Counts lines that empty the stack in at most `left` moves, capped, and keeps the first `keep` of them.
final class Counter {
    let p: Problem
    let span: Int?
    var memo: [Key: Int] = [:]
    let cap = 1_000_000
    init(_ p: Problem, span: Int?) { self.p = p; self.span = span }

    func moves(_ s: [Twist], _ last: Move?) -> [Move] {
        span.map { p.allMoves(s, after: last, span: $0) } ?? p.cleanMoves(s, after: last)
    }

    func count(_ s: [Twist], last: Move?, left: Int) -> Int {
        if s.isEmpty { return 1 }
        if left == 0 || p.bound(s) > left { return 0 }
        let k = Key(s: s, last: last, left: left, rule: p.rule)
        if let c = memo[k] { return c }
        var c = 0
        for m in moves(s, last) {
            guard let t = p.play(s, m) else { continue }
            c = min(cap, c + count(t, last: m, left: left - 1))
        }
        memo[k] = c
        return c
    }

    func lines(_ s: [Twist], last: Move?, left: Int, keep: Int) -> [[Move]] {
        if s.isEmpty { return [[]] }
        guard count(s, last: last, left: left) > 0 else { return [] }
        var out: [[Move]] = []
        for m in moves(s, last) {
            guard let t = p.play(s, m) else { continue }
            for l in lines(t, last: m, left: left - 1, keep: keep - out.count) {
                out.append([m] + l)
                if out.count >= keep { return out }
            }
        }
        return out
    }

    /// Fewest moves that empty the stack, searching up to `limit`.
    func optimum(limit: Int) -> Int? {
        (p.bound(p.stack)...max(limit, p.bound(p.stack))).first { count(p.stack, last: nil, left: $0) > 0 }
    }
}

/// The chance that a player choosing uniformly among the clean moves whose own tick doesn't push solves at par.
func chance(_ p: Problem, par: Int) -> Double {
    var memo: [Key: Double] = [:]
    func go(_ s: [Twist], _ last: Move?, _ left: Int) -> Double {
        if s.isEmpty { return 1 }
        if left == 0 { return 0 }
        let k = Key(s: s, last: last, left: left, rule: p.rule)
        if let c = memo[k] { return c }
        let next = p.cleanMoves(s, after: last).compactMap { m in p.play(s, m).map { (m, $0) } }
        let c = next.isEmpty ? 0 : next.map { go($0.1, $0.0, left - 1) }.reduce(0, +) / Double(next.count)
        memo[k] = c
        return c
    }
    return go(p.stack, nil, par)
}

/// Along a line, the clean moves whose own tick doesn't push but after which par is out of reach: the decisions, as
/// (waits, heals) among them.
func traps(_ p: Problem, line: [Move], par: Int) -> (waits: Int, heals: Int) {
    let clean = Counter(p, span: nil)
    var s = p.stack, last: Move? = nil, n = (waits: 0, heals: 0)
    for (i, m) in line.enumerated() {
        for o in p.cleanMoves(s, after: last) where o != m {
            if let t = p.play(s, o), clean.count(t, last: o, left: par - i - 1) == 0 {
                if o == .wait { n.waits += 1 } else { n.heals += 1 }
            }
        }
        s = p.play(s, m)!
        last = m
    }
    return n
}

/// Fewest clean moves to empty the stack from `s`, or nil if every clean line loses.
func cleanFinish(_ p: Problem, _ s: [Twist], last: Move?) -> Int? {
    var memo: [Key: Int?] = [:]
    func go(_ s: [Twist], _ last: Move?) -> Int? {
        if s.isEmpty { return 0 }
        let k = Key(s: s, last: last, left: 0, rule: p.rule)
        if let c = memo[k] { return c }
        let best = p.cleanMoves(s, after: last).compactMap { m in p.play(s, m).flatMap { go($0, m) } }.min().map { $0 + 1 }
        memo[k] = best
        return best
    }
    return go(s, last)
}

func describe(_ s: [Twist]) -> String {
    s.map { "\($0.rod):\($0.steps > 0 ? "+" : "")\($0.steps)" }.joined(separator: ",")
}

func parseClocks(_ s: String) -> [Clock] {
    s.split(separator: ",").map { part in
        let back = part.hasSuffix("-")
        return Clock(rod: Int(part.trimmingCharacters(in: CharacterSet(charactersIn: "+-")))!, dir: back ? -1 : 1)
    }
}

/// One problem's report: optimum, the proof's reach, clean lines and keys, each clean first move's fate, the chance.
func report(_ p: Problem, span: Int, quick: Bool) {
    let clean = Counter(p, span: nil)
    let owed = p.owed(p.stack)
    guard let par = clean.optimum(limit: owed + 12) else {
        print("unsolvable in clean moves")
        return
    }
    print("stack \(describe(p.stack))  clocks \(p.clocks.map { "\($0.rod)\($0.dir > 0 ? "+" : "-")" }.joined(separator: ","))  rule \(p.rule.rawValue)")
    print("owed \(owed)  clean optimum \(par)")
    let bound = p.bound(p.stack)
    var proof = par == bound ? "none shorter, absolute: par is the bound (ticks owed \(owed), rods to turn)" : "unproved"
    if !quick {
        let full = Counter(p, span: span)
        let start = Date()
        if let o = full.optimum(limit: par), o < par {
            print("SHORTER with partial turns or detours: \(o): \(full.lines(p.stack, last: nil, left: o, keep: 1)[0])")
            proof = "beaten"
        } else if par > bound {
            proof = "none shorter over turns of up to \(span) steps (\(Int(Date().timeIntervalSince(start) * 1000)) ms)"
        }
        let n = full.count(p.stack, last: nil, left: par)
        print("lines at \(par) over turns of up to \(span): \(n)\(n >= full.cap ? "+" : "")")
        let keys = Set(p.allMoves(p.stack, after: nil, span: span).filter { m in
            p.play(p.stack, m).map { full.count($0, last: m, left: par - 1) > 0 } ?? false
        })
        print("keys at \(par) over turns of up to \(span): \(keys.map(\.description).sorted().joined(separator: " "))")
    }
    print(proof)
    // Past a pushed tick a clock never stops, so the unbounded walks below would never end.
    if keepsPushed {
        print("clean lines at \(par), pushed ticks played on: \(clean.count(p.stack, last: nil, left: par))")
        return
    }
    let n = clean.count(p.stack, last: nil, left: par)
    print("clean lines at \(par): \(n)")
    for l in clean.lines(p.stack, last: nil, left: par, keep: 6) { print("  " + l.map(\.description).joined(separator: " ")) }
    for m in p.cleanMoves(p.stack, after: nil) {
        let fate: String
        if let t = p.play(p.stack, m) {
            fate = cleanFinish(p, t, last: m).map { $0 + 1 == par ? "par" : "solves in \($0 + 1)" } ?? "lost later"
        } else { fate = "lost at once" }
        print("  first \(m): \(fate)")
    }
    if let line = clean.lines(p.stack, last: nil, left: par, keep: 1).first {
        var s = p.stack, last: Move? = nil
        for (i, m) in line.enumerated() {
            let others = p.cleanMoves(s, after: last).filter { $0 != m }
            let fates = others.map { o -> String in
                guard let t = p.play(s, o) else { return "\(o) pushes" }
                return clean.count(t, last: o, left: par - i - 1) > 0 ? "\(o) also" : "\(o) dooms"
            }
            let t = p.play(s, m)!
            print("  \(i + 1). \(m)\(fates.isEmpty ? "" : "   [" + fates.joined(separator: ", ") + "]")   -> \(describe(t))")
            s = t
            last = m
        }
    }
    let c = chance(p, par: par)
    print(String(format: "chance at par %.4f  difficulty %.1f bits", c, c > 0 ? abs(log2(c)) : 99))
}

/// One dealt problem, if its clean optimum is what the clocks owe: key kind, heals and waits on the line that would miss
/// par, clock seams, seed, owed, entries, waits, lines at par, first moves that miss par, difficulty in bits, stack, line.
func score(_ p: Problem, seed: UInt64) {
    let stack = p.stack, clean = Counter(p, span: nil), o = p.owed(stack)
    let lines = clean.count(stack, last: nil, left: o)
    guard lines > 0 else { return }
    let line = clean.lines(stack, last: nil, left: o, keep: 1)[0]
    let first = p.cleanMoves(stack, after: nil)
    let losing = first.filter { m in p.play(stack, m).map { clean.count($0, last: m, left: o - 1) == 0 } ?? true }.count
    let kind = line[0] == .wait ? "quiet" : (line[0].rod == stack.last?.rod ? "top" : "under")
    let t = traps(p, line: line, par: o)
    let seams = stack.filter { p.isClock($0.rod) }.count
    let c = chance(p, par: o)
    print([kind, String(t.heals), String(t.waits), String(seams), String(seed), String(o), String(stack.count),
           String(line.filter { $0 == .wait }.count), String(lines), "\(losing)/\(first.count)",
           String(format: "%.2f", c > 0 ? abs(log2(c)) : 99), describe(stack), line.map(\.description).joined(separator: " ")]
        .joined(separator: "\t"))
    fflush(stdout)
}

/// Deals problems backwards from a line of `n` moves: each step back unticks every clock still running at that move,
/// then pushes the inverse of a heal (or nothing, for a wait), so the line plays forward to an empty stack. ESC_INSIDE is
/// the share of heals on rods that cross a clock's disc.
func build(_ layout: Layout, clocks: [Clock], n: Int, waits: ClosedRange<Int>, seeds: Range<UInt64>, rule: Rule) {
    let share = Double(ProcessInfo.processInfo.environment["ESC_INSIDE"] ?? "0.3")!
    let working = layout.rods.indices.filter { r in !clocks.contains { $0.rod == r } }
    for seed in seeds {
        var rng = SplitMix64(state: seed)
        let runs = clocks.indices.map { $0 == 0 ? n : Int.random(in: (n + 1) / 2...n, using: &rng) }.shuffled(using: &rng)
        let w = Int.random(in: waits, using: &rng)
        var waitAt = Set<Int>()
        while waitAt.count < min(w, n - 1) { waitAt.insert(Int.random(in: 1...n, using: &rng)) }
        var s: [Twist] = []
        var ok = true
        for t in stride(from: n, through: 1, by: -1) {
            for (c, run) in zip(clocks, runs).reversed() where run >= t { s.commit(rod: c.rod, steps: -c.dir, in: layout) }
            if !waitAt.contains(t) {
                let free = working.filter { r in !clocks.contains { layout.overlaps($0.rod, r) } }
                let inside = working.filter { !free.contains($0) }
                let r = (free.isEmpty || Double.random(in: 0..<1, using: &rng) < share ? inside : free).randomElement(using: &rng)!
                if s.commit(rod: r, steps: [-5, -4, -3, -2, 2, 3, 4, 5].randomElement(using: &rng)!, in: layout) != .pushed {
                    ok = false
                }
            }
        }
        guard ok else { continue }
        score(Problem(layout: layout, stack: s, clocks: clocks, rule: rule), seed: seed)
    }
}

/// Deals random problems and prints those whose clean optimum is what the clocks owe, with a few measures.
func search(_ layout: Layout, clocks: [Clock], heals: ClosedRange<Int>, owed: ClosedRange<Int>, seeds: Range<UInt64>,
            rule: Rule) {
    let working = layout.rods.indices.filter { r in !clocks.contains { $0.rod == r } }
    for seed in seeds {
        var rng = SplitMix64(state: seed)
        let h = Int.random(in: heals, using: &rng)
        var entries: [Twist] = (0..<h).map { _ in
            Twist(rod: working.randomElement(using: &rng)!, steps: [-5, -4, -3, -2, 2, 3, 4, 5].randomElement(using: &rng)!)
        }
        for c in clocks {
            var left = Int.random(in: owed, using: &rng)
            while left > 0 {
                let k = Int.random(in: 1...min(3, left), using: &rng)
                entries.append(Twist(rod: c.rod, steps: -c.dir * k))
                left -= k
            }
        }
        entries.shuffle(using: &rng)
        var stack: [Twist] = []
        for e in entries { stack.commit(e, in: layout) }
        guard stack.count == entries.count else { continue }
        score(Problem(layout: layout, stack: stack, clocks: clocks, rule: rule), seed: seed)
        fflush(stdout)
    }
}

let args = Array(CommandLine.arguments.dropFirst())
let rule = Rule(rawValue: ProcessInfo.processInfo.environment["ESC_RULE"] ?? "final") ?? .final
switch args.first {
case "check" where args.count >= 4:
    let layout = Layout(rawValue: args[1])!
    let p = Problem(layout: layout, stack: .parse(args[2], in: layout), clocks: parseClocks(args[3]), rule: rule)
    report(p, span: args.count > 4 ? Int(args[4])! : 6, quick: args.count > 5)
case "search" where args.count == 8:
    let r = { (s: String) -> ClosedRange<Int> in
        let f = s.split(separator: "-").map { Int($0)! }
        return f[0]...(f.count > 1 ? f[1] : f[0])
    }
    search(Layout(rawValue: args[1])!, clocks: parseClocks(args[2]), heals: r(args[3]), owed: r(args[4]),
           seeds: UInt64(args[5])!..<UInt64(args[6])!, rule: rule)
    _ = args[7]
case "book" where args.count == 2:
    // One line per problem of the book: number, layout, clocks, par, the bound, clean and split lines at par, keys,
    // difficulty in bits, the line.
    for row in try! String(contentsOfFile: args[1], encoding: .utf8).split(separator: "\n") {
        let f = row.split(separator: "\t").map(String.init)
        let layout = Layout(rawValue: f[1])!
        let p = Problem(layout: layout, stack: .parse(f[3], in: layout), clocks: parseClocks(f[2]), rule: rule)
        let clean = Counter(p, span: nil), full = Counter(p, span: 6)
        guard let par = clean.optimum(limit: p.owed(p.stack) + 12) else { print(f[0], "unsolvable"); continue }
        let keys = p.allMoves(p.stack, after: nil, span: 6).filter { m in
            p.play(p.stack, m).map { full.count($0, last: m, left: par - 1) > 0 } ?? false
        }
        let c = chance(p, par: par)
        print([f[0], f[1], f[2], String(par), String(p.bound(p.stack)), String(clean.count(p.stack, last: nil, left: par)),
               String(full.count(p.stack, last: nil, left: par)), keys.map(\.description).joined(separator: " "),
               String(format: "%.1f", c > 0 ? abs(log2(c)) : 99),
               clean.lines(p.stack, last: nil, left: par, keep: 1)[0].map(\.description).joined(separator: " ")]
            .joined(separator: "\t"))
        fflush(stdout)
    }
case "build" where args.count == 7:
    let f = args[4].split(separator: "-").map { Int($0)! }
    build(Layout(rawValue: args[1])!, clocks: parseClocks(args[2]), n: Int(args[3])!, waits: f[0]...(f.count > 1 ? f[1] : f[0]),
          seeds: UInt64(args[5])!..<UInt64(args[6])!, rule: rule)
default:
    print("""
    usage: scripts/escapement.sh check <layout> <scramble> <clocks> [span] [quick]
           scripts/escapement.sh search <layout> <clocks> <heals a-b> <owed a-b> <from seed> <to seed> -
           scripts/escapement.sh build <layout> <clocks> <moves> <waits a-b> <from seed> <to seed>
           scripts/escapement.sh book scripts/escapement/problems.tsv
    clocks: rods in tick order, each + or - (wound back), e.g. 0+ or 1+,3-.  ESC_RULE=final|lab
    """)
    exit(2)
}
