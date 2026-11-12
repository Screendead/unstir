// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

// Measures maelstrom levels, and deals candidates that need a plan.
//   park f, park a: the park rule's fewest and most moves over its ties, parking the fewest seized knobs over unfinished
//     rings, and every one over a finished ring. one-visit, last-ring, nearest: the other rules of thumb, likewise.
//     "x" where some way its ties go strands a seam.
//   plan: every rule's fewest misses the optimum (`Solver.needsPlan`).
//   choice, deep, longest: the untwisting optimal line's choice points with a decoy, those whose decoy a lookahead of 3
//     or more moves refutes, and the longest such lookahead (`Solver.decoys`). Noisy: rank by it, never pick by it alone.
//   turns: the optimal line's tank turns. run: the park line's longest stretch of rods stirred without a turn, against
//     the bound `testMaelstromKeepsTheTankTurning` holds past quad, (par + 2) / 3 + 1.

func signed(_ n: Int) -> String { n > 0 ? "+\(n)" : "\(n)" }
func string(_ stack: [Twist]) -> String { stack.map { "\($0.rod):\(signed($0.steps))" }.joined(separator: ",") }
func set(_ s: Set<Int>) -> String { s.sorted().map(String.init).joined(separator: ",") }

/// The knobs that may seize: every rod but hex's hub.
func ring(_ layout: Layout) -> [Int] { layout == .hex ? Array(1...6) : Array(layout.rods.indices) }

func spacing(_ layout: Layout, _ seized: Set<Int>) -> String {
    guard seized.count == 2 else { return seized.count == 1 ? "one" : "\(seized.count)" }
    let r = ring(layout), s = seized.sorted()
    let a = r.firstIndex(of: s[0])!, b = r.firstIndex(of: s[1])!
    let d = min(abs(a - b), r.count - abs(a - b))
    return d == 1 ? "neighbours" : 2 * d == r.count ? "opposite" : d == 2 ? "twoapart" : "\(d)apart"
}

/// The park line's longest run of rods stirred without a turn, as `testMaelstromKeepsTheTankTurning` counts it.
func longestRun(_ play: Play) -> Int {
    var runs = [0], last: Int?
    for move in play.moves {
        switch move {
        case .turn: runs.append(0); last = nil
        case .wait: last = nil
        case let .stir(_, slot, _):
            if slot != last { runs[runs.count - 1] += 1 }
            last = slot
        }
    }
    return runs.max()!
}

let header = ["level", "layout", "seized", "spacing", "entries", "hidden", "optimum", "untwisting", "park f", "park a",
              "one-visit", "last-ring", "nearest", "plan", "choice", "deep", "longest", "turns", "run", "bound",
              "scramble"]

/// One TSV row, or nil when `keep` is set and the stack isn't a keeper: the optimum is what untwisting takes (no
/// detour), every rule's fewest misses it, and past quad the park line keeps the tank turning.
func row(_ name: String, _ layout: Layout, _ stack: [Twist], _ seized: Set<Int>, keep: Bool) -> String? {
    let solver = Solver(layout)
    let rules = Solver.rules.map { solver.ties(stack, seized: seized, rule: $0) }
    guard let untwisting = solver.untwistingPlay(stack, seized: seized) else { return keep ? nil : "\(name)\tunsolvable" }
    if keep, !rules.allSatisfy({ ($0?.best.count ?? .max) > untwisting.count }) { return nil }
    let park = solver.park(stack, seized: seized)
    let bound = (untwisting.count + 2) / 3 + 1, run = park.map(longestRun) ?? -1
    if keep, layout != .quad, park == nil || run > bound { return nil }
    guard let optimal = solver.optimalPlay(stack, seized: seized) else { return nil }
    if keep, optimal.count != untwisting.count { return nil }
    let plan = solver.needsPlan(stack, seized: seized, optimum: optimal.count)!
    let decoys = optimal.count == untwisting.count ? solver.decoys(stack, seized: seized, line: untwisting) : nil
    let points = Set(decoys?.map(\.at) ?? []), deep = Set(decoys?.filter { $0.survives >= 3 }.map(\.at) ?? [])
    let turns = optimal.moves.filter { if case .turn = $0 { true } else { false } }.count
    func span(_ t: (best: Play, worst: Play)?) -> String {
        guard let t else { return "x" }
        return t.best.count == t.worst.count ? "\(t.best.count)" : "\(t.best.count)-\(t.worst.count)"
    }
    let fields = [name, layout.rawValue, set(seized), spacing(layout, seized), "\(stack.count)",
                  "\(layout.inversions(stack))", "\(optimal.count)", "\(untwisting.count)"]
        + rules.map(span)
        + [plan ? "yes" : "no", decoys == nil ? "-" : "\(points.count)", decoys == nil ? "-" : "\(deep.count)",
           "\(decoys?.map(\.survives).max() ?? 0)", "\(turns)", "\(run)", "\(bound)", string(stack)]
    return fields.joined(separator: "\t")
}

/// A seized set a seed draws for a class, as the original maelstrom search drew them: one, neighbours or twoapart.
func drawSeized(_ layout: Layout, _ spec: String, rng: inout SplitMix64) -> Set<Int> {
    let r = ring(layout)
    switch spec {
    case "one": return [r[rng.below(r.count)]]
    case "neighbours", "twoapart":
        let a = rng.below(r.count)
        return [r[a], r[(a + (spec == "neighbours" ? 1 : 2)) % r.count]]
    default: return Set(spec.split(separator: ",").compactMap { Int($0) })
    }
}

/// FNV-1a, so each band draws its own seeds from one base.
func band(_ parts: [String]) -> UInt64 {
    parts.joined(separator: "|").utf8.reduce(0xcbf2_9ce4_8422_2325 as UInt64) { ($0 ^ UInt64($1)) &* 0x100_0000_01b3 }
}

let args = Array(CommandLine.arguments.dropFirst())
print(header.joined(separator: "\t"))
switch args.first {
case "table":
    // Lines of "<layout> <scramble> <seized>", in table order.
    var n = 0
    while let line = readLine() {
        let f = line.split(separator: " ")
        n += 1
        guard f.count == 3, let layout = Layout(rawValue: String(f[0])) else { continue }
        let seized = Set(f[2].split(separator: ",").compactMap { Int($0) })
        print(row("M\(n)", layout, .parse(String(f[1]), in: layout), seized, keep: false)!)
        fflush(stdout)
    }
case "check" where args.count == 4:
    guard let layout = Layout(rawValue: args[1]) else { exit(2) }
    print(row("-", layout, .parse(args[2], in: layout), Set(args[3].split(separator: ",").compactMap { Int($0) }), keep: false)!)
case "search" where args.count == 7:
    // As the first search drew a seed: depth in [lo, hi], up to a third of it hidden, then the seized set, then the
    // frozen generator's scramble; seed i of a band is 5 + FNV(random|layout|seized|lo|hi|) + i.
    guard let layout = Layout(rawValue: args[1]), let lo = Int(args[3]), let hi = Int(args[4]),
          let from = Int(args[5]), let to = Int(args[6]) else { exit(2) }
    let spec = args[2], tag = band(["random", layout.rawValue, spec, "\(lo)", "\(hi)", ""])
    for i in from..<to {
        let seed = 5 &+ tag &+ UInt64(i)
        var rng = SplitMix64(state: seed)
        let depth = lo + rng.below(hi - lo + 1), inversions = rng.below(depth / 3 + 1)
        let seized = drawSeized(layout, spec, rng: &rng)
        let stack = layout.scramble(depth: depth, inversions: inversions, rng: &rng)
        guard stack.count == depth, [Twist].parse(string(stack), in: layout) == stack,
              let line = row("\(seed)", layout, stack, seized, keep: true) else { continue }
        print(line)
        fflush(stdout)
    }
default:
    print("usage: table < rows | check <layout> <scramble> <seized> | search <layout> <one|neighbours|twoapart|set> <lo> <hi> <from> <to>")
    exit(2)
}
