// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

// lenses=0,2 may come anywhere after the scramble.
let all = CommandLine.arguments.dropFirst().map { $0 }
let lensArg = all.dropFirst(2).first { $0.hasPrefix("lenses=") }
let args = all.filter { $0 != lensArg }
guard (2...3).contains(args.count), let layout = Layout(rawValue: args[0]) else {
    let layouts = (Layout.allCases + Layout.swirls).map(\.rawValue).joined(separator: "|")
    print("usage: scripts/solve.sh <layout: \(layouts)> <scramble, e.g. 0:+3,2:-4> [seized knobs, e.g. 1,4] [lenses=0,2]")
    exit(2)
}
let seized = Set((args.count > 2 ? args[2] : "").split(separator: ",").compactMap { Int($0) })
let lenses = Set((lensArg?.dropFirst("lenses=".count) ?? "").split(separator: ",").compactMap { Int($0) })
if let swirl = layout.swirl, lenses.contains(swirl) {
    print("rod \(swirl) is the swirl, which is never a lens")
    exit(2)
}
if let swirl = layout.swirl, seized.contains(swirl) {
    print("rod \(swirl) is the swirl, held from the rim, and is never seized")
    exit(2)
}
let stack = [Twist].parse(args[1], in: layout, lenses: lenses)
let solver = Solver(layout, lenses: lenses)
let readings: [(String, Solver.Parking)] = [
    ("fewest seized knobs over unfinished rings", .fewest),
    ("every seized knob over a finished ring or no preference", .all),
]
let clock = ContinuousClock()
var optimal: Play?, untwisting: Play?, parks: [(best: Play, worst: Play)?] = [], lazy: Play?
let took = clock.measure {
    optimal = solver.optimalPlay(stack, seized: seized)
    untwisting = solver.untwistingPlay(stack, seized: seized)
    parks = readings.map { solver.parkTies(stack, seized: seized, parking: $0.1) }
    lazy = solver.noLookahead(stack, seized: seized)
}
guard let optimal, let untwisting, let lazy else {
    print("unsolvable: some seam never comes under a working knob")
    exit(1)
}
let optimum = optimal.count
print("entries \(stack.count), seized \(seized.sorted().map(String.init).joined(separator: ",").ifEmpty("none"))"
      + (lenses.isEmpty ? "" : ", lenses \(lenses.sorted().map(String.init).joined(separator: ","))"))
print("optimum \(optimum)" + (untwisting.count > optimum ? ", where untwisting alone takes \(untwisting.count)" : ""))
for ((reading, _), park) in zip(readings, parks) {
    guard let park else {
        print("park rule, \(reading): some way its ties go strands a seam")
        continue
    }
    let (best, worst) = (park.best.count, park.worst.count)
    let verdict = worst == optimum ? "fair" : "\(worst - optimum) over"
    print("park rule, \(reading): \(best == worst ? "\(worst) however ties go" : "\(best) to \(worst) as ties go") (\(verdict))")
}
print("no lookahead \(lazy.count) (planning gap \(lazy.count - optimum))")
print("optimal moves, one commit or turn each:")
for (i, move) in optimal.moves.enumerated() { print("  \(i + 1). \(move)") }
let ms = Double(took.components.seconds) * 1e3 + Double(took.components.attoseconds) / 1e15
print("\(solver.stacksSeen) stacks, \(String(format: "%.2f", ms)) ms")

extension String {
    func ifEmpty(_ other: String) -> String { isEmpty ? other : self }
}
