// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

// Measures plughole levels.
//   hidden: `Layout.inversions`, the stirs no louder than the loudest undo-able stir they covered as they went on.
//   right moves per step: how many rods could come off next (`Layout.removable`), averaged over the untwist, every
//     right move at each step taken as equally likely. One is a forced read; more is slack.
//   forced: the steps with only one right move, likewise expected over the untwist.
//   whole: the rings whole as dealt, the right moves on the first step.

func signed(_ n: Int) -> String { n > 0 ? "+\(n)" : "\(n)" }
func string(_ stack: [Twist]) -> String { stack.map { "\($0.rod):\(signed($0.steps))" }.joined(separator: ",") }

/// Expected sums of right moves and of forced steps over the rest of the untwist.
func expected(_ stack: [Twist], _ layout: Layout, _ memo: inout [String: (Double, Double)]) -> (Double, Double) {
    if stack.isEmpty { return (0, 0) }
    let key = string(stack)
    if let hit = memo[key] { return hit }
    let r = layout.removable(stack)
    var right = Double(r.count), forced = r.count == 1 ? 1.0 : 0
    var sumRight = 0.0, sumForced = 0.0
    for i in r {
        var next = stack
        _ = next.commit(rod: stack[i].rod, steps: -stack[i].steps, in: layout)
        let (a, b) = expected(next, layout, &memo)
        sumRight += a
        sumForced += b
    }
    right += sumRight / Double(r.count)
    forced += sumForced / Double(r.count)
    memo[key] = (right, forced)
    return (right, forced)
}

func row(_ name: String, _ layout: Layout, _ stack: [Twist]) -> (line: String, fair: Bool) {
    let solver = Solver(layout)
    let optimum = solver.optimum(stack) ?? -1
    let untwisting = solver.untwistingPlay(stack)?.count ?? -1
    var memo: [String: (Double, Double)] = [:]
    let (right, forced) = expected(stack, layout, &memo)
    let fair = optimum == stack.count && untwisting == stack.count && [Twist].parse(string(stack), in: layout) == stack
    let fields = [name, layout.rawValue, "\(stack.count)", "\(optimum)", "\(untwisting)", "\(layout.inversions(stack))",
                  "\(layout.removable(stack).count)", String(format: "%.2f", right / Double(stack.count)), String(format: "%.1f", forced), string(stack)]
    return (fields.joined(separator: "\t"), fair)
}

let args = Array(CommandLine.arguments.dropFirst())
print(["level", "layout", "entries", "optimum", "untwisting", "hidden", "whole", "right/step", "forced", "scramble"]
    .joined(separator: "\t"))
switch args.first {
case "table":
    var n = 0
    while let line = readLine() {
        let f = line.split(separator: " ")
        n += 1
        guard f.count == 2, let layout = Layout(rawValue: String(f[0])) else { continue }
        print(row("L\(n)", layout, .parse(String(f[1]), in: layout)).line)
    }
case "check" where args.count == 3:
    guard let layout = Layout(rawValue: args[1]) else { exit(2) }
    print(row("-", layout, .parse(args[2], in: layout)).line)
case "search" where args.count == 6:
    guard let layout = Layout(rawValue: args[1]) else { exit(2) }
    let (depth, inversions) = (Int(args[2])!, Int(args[3])!)
    for seed in UInt64(args[4])!...UInt64(args[5])! {
        var rng = SplitMix64(state: seed)
        let stack = layout.scramble(depth: depth, inversions: inversions, rng: &rng)
        guard stack.count == depth else { continue }
        let (line, fair) = row("\(seed)", layout, stack)
        if fair { print(line) }
        fflush(stdout)
    }
default:
    print("usage: table < rows | check <layout> <scramble> | search <layout> <depth> <inversions> <from> <to>")
    exit(2)
}
