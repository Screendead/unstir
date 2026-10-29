// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

if CommandLine.arguments.dropFirst().first == "escapement" { escapement(CommandLine.arguments.dropFirst(2).map { $0 }) }
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

/// solve.sh escapement <layout> <scramble> <clock rod> [limit]: the prover's fewest moves with the clock ticking after
/// each, and the line, or none within the limit. Exits when done.
func escapement(_ args: [String]) -> Never {
    guard (3...4).contains(args.count), let layout = Layout(rawValue: args[0]), let clock = Int(args[2]),
          layout.rods.indices.contains(clock), args.count < 4 || Int(args[3]) != nil else {
        print("usage: scripts/solve.sh escapement <layout> <scramble, e.g. 0:-1,1:+3> <clock rod> [limit, default 8]")
        exit(2)
    }
    let stack = [Twist].parse(args[1], in: layout), limit = args.count > 3 ? Int(args[3])! : 8
    let clock0 = ContinuousClock()
    var seen = 0, play: Play?
    let took = clock0.measure { play = Solver(layout).escapement(stack, clock: clock, limit: limit, seen: &seen) }
    print("entries \(stack.count), clock \(clock), counts \u{00B1}1 to \u{00B1}11 and each entry's inverse")
    if let play {
        print("optimum \(play.count): no shorter line exists among those counts; a line:")
        for (i, move) in play.moves.enumerated() { print("  \(i + 1). \(move)") }
    } else {
        print("no line within \(limit) moves")
    }
    let ms = Double(took.components.seconds) * 1e3 + Double(took.components.attoseconds) / 1e15
    print("\(seen) states, \(String(format: "%.2f", ms)) ms")
    exit(play == nil ? 1 : 0)
}
