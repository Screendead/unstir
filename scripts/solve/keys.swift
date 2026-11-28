// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// solve.sh <layout> <scramble> keys=2:0@3,... [exhaustive|deep] [limit=n]: a Charybdis level (`Ward`) solved: the
/// optimum and a line, what untwisting alone takes under the wards, which first moves reach the optimum, how many steps
/// of the line one move alone keeps par and how many moves tried there lose it, and the deepest the stack stands.
/// Exits when done.
func keys(_ args: [String]) -> Never {
    let keyArg = args.first { $0.hasPrefix("keys=") }
    let limitArg = args.first { $0.hasPrefix("limit=") }
    let rest = args.filter { $0 != keyArg && $0 != limitArg && $0 != "exhaustive" && $0 != "deep" }
    guard rest.count == 2, let layout = Layout(rawValue: rest[0]), Layout.allCases.contains(layout),
          let wards = keyArg.flatMap({ Ward.wards(String($0.dropFirst(5))) }), !wards.isEmpty else {
        print("usage: scripts/solve.sh <tri|quad|eye|pent|hex> <scramble> keys=<ward>:<key>@<mark>,... [exhaustive|deep] [limit=n]")
        exit(2)
    }
    let rods = layout.rods.indices
    guard wards.allSatisfy({ rods.contains($0.key) && rods.contains($0.value.key) }) else {
        print("a knob named is not on \(layout)")
        exit(2)
    }
    let stack = [Twist].parse(rest[1], in: layout)
    let solver = KeySolver(layout, wards: wards, dealt: stack)
    solver.exhaustive = args.contains("exhaustive")
    solver.deep = args.contains("deep")
    let limit = limitArg.flatMap { Int($0.dropFirst(6)) } ?? (solver.deep ? 60 : 24)
    func signed(_ t: Twist) -> String { "\(t.rod):\(t.steps > 0 ? "+" : "")\(t.steps)" }
    func ms(_ d: Duration) -> String {
        String(format: "%.0f ms", Double(d.components.seconds) * 1e3 + Double(d.components.attoseconds) / 1e15)
    }
    let clock = ContinuousClock()
    print("entries \(stack.count) on \(layout): \(stack.map(signed).joined(separator: ",")); keys=\(Ward.spelt(wards))")
    print(solver.exhaustive ? "counts tried: every one from -12 to +12 on every knob (a proof to that range)"
          : solver.deep ? "counts tried: whole entries off and keys to their marks, no detours (a bounded search, as maelstrom's)"
          : "counts tried: cancels, overshoots onto another entry, marks, and +-1 (the solver's bounded optimum)")
    var line: [Twist]?
    let took = clock.measure { line = solver.solve(limit: limit) }
    guard let line else {
        print("no line within \(limit) moves (\(ms(took)))")
        exit(1)
    }
    let plain = solver.untwisting()
    print("optimum \(line.count) (\(solver.expanded) states, \(ms(took)))")
    print("untwisting alone under the wards: " + (plain.map { "\($0)" + ($0 > line.count ? " (\($0 - line.count) over)" : "") }
          ?? "stranded, so the level needs a plan"))
    let firsts = solver.keyMoves(par: line.count)
    print("first moves that reach it: \(firsts.map(signed).joined(separator: ", ")) (\(firsts.count) of \(solver.moves(solver.start).count) tried)")
    var steps: [(tried: Int, keep: Int)] = []
    let looked = clock.measure { steps = solver.choices(along: line) }
    let forced = steps.filter { $0.tried > 1 && $0.keep == 1 }.count
    let wrong = steps.reduce(0) { $0 + $1.tried - $1.keep }
    print("forced \(forced) of \(line.count) steps; \(wrong) moves tried along the line lose par (\(ms(looked)))")
    print("deepest stack along the line \(solver.deepest(along: line))")
    print("a line: \(line.map(signed).joined(separator: ","))")
    exit(0)
}
