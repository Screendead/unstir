// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

// Searches for vortex levels: scrambles the frozen generator deals on a swirl layout, seeded, kept where par is the
// entry count (the optimum equals the stack's length and plain untwisting reaches it).
//   search <layout> <depth> <inversions> <min swirls> <from seed> <to seed>   one TSV line per keeper
//   check <layout> <scramble>                                                  the same line for one scramble

func signed(_ n: Int) -> String { n > 0 ? "+\(n)" : "\(n)" }
func string(_ stack: [Twist]) -> String { stack.map { "\($0.rod):\(signed($0.steps))" }.joined(separator: ",") }

/// seed, entries, hidden, hidden swirls, swirls, entries above the top swirl, the top swirl's undo sign, swirl sizes
/// from the top, the most entries ever removable at once while untwisting, whether hex's hub and the swirl are ever
/// removable together, optimum, untwisting, ms, scramble.
func row(_ layout: Layout, _ stack: [Twist], seed: String, solver: Solver) -> (line: String, fair: Bool) {
    let swirl = layout.swirl!
    let top = Array(stack.reversed())
    let swirls = top.filter { $0.rod == swirl }
    let above = top.firstIndex { $0.rod == swirl } ?? -1
    var s = stack, widest = 0, together = false
    while !s.isEmpty {
        let r = layout.removable(s)
        widest = max(widest, r.count)
        together = together || Set(r.map { s[$0].rod }).isSuperset(of: [0, swirl]) && layout == .hexSwirl
        s.remove(at: r.last!)
    }
    var built: [Twist] = [], hiddenSwirls = 0
    for t in stack {
        if t.rod == swirl, let c = layout.covered(built, t.rod), abs(t.steps) <= c { hiddenSwirls += 1 }
        built.commit(rod: t.rod, steps: t.steps, in: layout)
    }
    let clock = ContinuousClock()
    var optimum: Int?, untwisting: Int?
    let took = clock.measure {
        optimum = solver.optimum(stack)
        untwisting = solver.untwistingPlay(stack)?.count
    }
    let ms = Double(took.components.seconds) * 1e3 + Double(took.components.attoseconds) / 1e15
    let undo = swirls.first.map { $0.steps > 0 ? "-" : "+" } ?? "."
    let fair = optimum == stack.count && untwisting == stack.count && [Twist].parse(string(stack), in: layout) == stack
    let fields: [String] = [seed, "\(stack.count)", "\(layout.inversions(stack))", "\(hiddenSwirls)",
                            "\(swirls.count)", "\(above)", undo, swirls.map { signed($0.steps) }.joined(separator: " "),
                            "\(widest)", together ? "hub" : ".",
                            "\(optimum ?? -1)", "\(untwisting ?? -1)", String(format: "%.0f", ms), string(stack)]
    return (fields.joined(separator: "\t"), fair)
}

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 3, let layout = Layout(rawValue: args[1]), layout.swirl != nil else {
    print("usage: search <swirl layout> <depth> <inversions> <min swirls> <from> <to>")
    print("       check <swirl layout> <scramble>")
    exit(2)
}
let solver = Solver(layout)
switch args[0] {
case "check":
    print(row(layout, .parse(args[2], in: layout), seed: "-", solver: solver).line)
case "search" where args.count == 7:
    let (depth, inversions, least) = (Int(args[2])!, Int(args[3])!, Int(args[4])!)
    for seed in UInt64(args[5])!...UInt64(args[6])! {
        var rng = SplitMix64(state: seed)
        let stack = layout.scramble(depth: depth, inversions: inversions, rng: &rng)
        guard stack.count == depth, stack.filter({ $0.rod == layout.swirl }).count >= least else { continue }
        let (line, fair) = row(layout, stack, seed: "\(seed)", solver: solver)
        if fair { print(line) }
        fflush(stdout)
    }
default:
    exit(2)
}
