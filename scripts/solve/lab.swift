// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// solve.sh lab <layout> <scramble> [keys=1:0@3,...] [keel=n] [flip] [exhaustive] [limit=n]: a level under the fifth
/// chapter's candidate rules (`LabRules`) proved: the optimum and a line, what untwisting alone takes under the rules,
/// and which first moves reach the optimum. Exits when done.
func lab(_ args: [String]) -> Never {
    let words = args.dropFirst(2)
    let limitArg = words.first { $0.hasPrefix("limit=") }
    let ruleWords = words.filter { $0 != "exhaustive" && $0 != limitArg }.joined(separator: " ")
    guard args.count >= 2, let layout = Layout(rawValue: args[0]), Layout.allCases.contains(layout),
          let rules = LabRules(ruleWords) else {
        print("usage: scripts/solve.sh lab <tri|quad|eye|pent|hex> <scramble> [keys=1:0@3,2:1@-2] [keel=n] [flip] [exhaustive] [limit=n]")
        exit(2)
    }
    let rods = layout.rods.indices
    guard rules.keys.allSatisfy({ rods.contains($0.key) && rods.contains($0.value.key) }) else {
        print("a knob named is not on \(layout)")
        exit(2)
    }
    let stack = [Twist].parse(args[1], in: layout)
    let solver = LabSolver(layout, rules: rules, dealt: stack)
    solver.exhaustive = words.contains("exhaustive")
    let limit = limitArg.flatMap { Int($0.dropFirst(6)) } ?? 24
    let clock = ContinuousClock()
    var line: [Twist]?, plain: Int?
    let took = clock.measure {
        line = solver.solve(limit: limit)
        plain = solver.untwisting()
    }
    func signed(_ t: Twist) -> String { "\(t.rod):\(t.steps > 0 ? "+" : "")\(t.steps)" }
    print("entries \(stack.count): \(stack.map(signed).joined(separator: ",")); \(ruleWords)")
    print(solver.exhaustive ? "counts tried: every one from -12 to +12 on every knob (a proof to that range)"
          : "counts tried: cancels, overshoots onto another entry, marks, and +-1 (the solver's bounded optimum)")
    guard let line else {
        print("no line within \(limit) moves")
        exit(1)
    }
    print("optimum \(line.count)")
    print("untwisting alone under the rules: " + (plain.map { "\($0)" + ($0 > line.count ? " (\($0 - line.count) over)" : "") }
          ?? "stranded, so the level needs a plan"))
    let firsts = solver.keyMoves(par: line.count)
    print("first moves that reach it: \(firsts.map(signed).joined(separator: ", ")) (of \(solver.moves(solver.start).count) tried)")
    print("a line: \(line.map(signed).joined(separator: ","))")
    let ms = Double(took.components.seconds) * 1e3 + Double(took.components.attoseconds) / 1e15
    print("\(solver.expanded) states expanded, \(String(format: "%.0f", ms)) ms")
    exit(0)
}
