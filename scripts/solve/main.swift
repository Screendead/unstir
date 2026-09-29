// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

let args = CommandLine.arguments.dropFirst().map { $0 }
guard (2...3).contains(args.count), let layout = Layout(rawValue: args[0]) else {
    print("usage: scripts/solve.sh <layout: \(Layout.allCases.map(\.rawValue).joined(separator: "|"))> <scramble, e.g. 0:+3,2:-4> [seized knobs, e.g. 1,4]")
    exit(2)
}
let seized = Set((args.count > 2 ? args[2] : "").split(separator: ",").compactMap { Int($0) })
let stack = [Twist].parse(args[1], in: layout)
let solver = Solver(layout)
let readings: [(String, Solver.Parking, Solver.Tie)] = [
    ("fewest seized knobs over unfinished rings, ties clockwise", .fewest, .clockwise),
    ("fewest seized knobs over unfinished rings, ties to the lower position", .fewest, .lowest),
    ("every seized knob over a finished ring or no preference, ties clockwise", .all, .clockwise),
    ("every seized knob over a finished ring or no preference, ties to the lower position", .all, .lowest),
]
let clock = ContinuousClock()
var optimal: Play?, untwisting: Play?, parks: [Play?] = [], lazy: Play?
let took = clock.measure {
    optimal = solver.optimalPlay(stack, seized: seized)
    untwisting = solver.untwistingPlay(stack, seized: seized)
    parks = readings.map { solver.park(stack, seized: seized, parking: $0.1, tie: $0.2) }
    lazy = solver.noLookahead(stack, seized: seized)
}
guard let optimal, let untwisting, let lazy else {
    print("unsolvable: some seam never comes under a working knob")
    exit(1)
}
let optimum = optimal.count
print("entries \(stack.count), seized \(seized.sorted().map(String.init).joined(separator: ",").ifEmpty("none"))")
print("optimum \(optimum)" + (untwisting.count > optimum ? ", where untwisting alone takes \(untwisting.count)" : ""))
for ((reading, _, _), park) in zip(readings, parks) {
    guard let park else { continue }
    print("park rule, \(reading): \(park.count)\(park.count == optimum ? " (fair)" : " (\(park.count - optimum) over)")")
}
print("no lookahead \(lazy.count) (planning gap \(lazy.count - optimum))")
print("optimal moves, one commit or turn each:")
for (i, move) in optimal.moves.enumerated() { print("  \(i + 1). \(move)") }
let ms = Double(took.components.seconds) * 1e3 + Double(took.components.attoseconds) / 1e15
print("\(solver.stacksSeen) stacks, \(String(format: "%.2f", ms)) ms")

extension String {
    func ifEmpty(_ other: String) -> String { isEmpty ? other : self }
}
