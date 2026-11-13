// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

// frost-days.sh <from yyyymmdd> <days> [swift] | line <yyyymmdd>
let args = CommandLine.arguments.dropFirst().map { $0 }
if args.first == "line", args.count == 2, let ymd = Int(args[1]) { line(ymd) }
guard (2...3).contains(args.count), let from = Int(args[0]), let days = Int(args[1]) else {
    print("usage: scripts/frost-days.sh <from yyyymmdd> <days> [swift]")
    exit(2)
}
let swift = args.count == 3 && args[2] == "swift"
let calendar = Calendar(identifier: .gregorian)
var date = calendar.date(from: DateComponents(year: from / 10000, month: from / 100 % 100, day: from % 100, hour: 12))!
let clock = ContinuousClock()
var frosts = 0, slowest = (ymd: 0, ms: 0.0)
func ms(_ d: Duration) -> Double { Double(d.components.seconds) * 1e3 + Double(d.components.attoseconds) / 1e15 }
let total = clock.measure {
    for _ in 0..<days {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let ymd = c.year! * 10000 + c.month! * 100 + c.day!
        let (layout, stack) = Layout.daily(ymd)
        let solver = Solver(layout)
        var frost: (knobs: [Int], par: Int)?
        let took = ms(clock.measure { frost = solver.frost(stack) })
        if took > slowest.ms { slowest = (ymd, took) }
        if let frost {
            frosts += 1
            let untwisting = solver.untwistingPlay(stack, seized: Set(frost.knobs))!.count
            if swift {
                print("        \(ymd): ([\(frost.knobs.map(String.init).joined(separator: ", "))], \(frost.par)),")
            } else {
                print("\(ymd)\t\(layout.rawValue)\t\(stack.count)\t\(frost.knobs.map(String.init).joined(separator: ","))"
                      + "\tpar \(frost.par)\tuntwisting \(untwisting)\t\(String(format: "%.0f", took)) ms")
            }
        } else if !swift {
            print("\(ymd)\t\(layout.rawValue)\t\(stack.count)\t-\t\t\t\(String(format: "%.0f", took)) ms")
        }
        date = calendar.date(byAdding: .day, value: 1, to: date)!
    }
}
FileHandle.standardError.write(("\(frosts) frost days in \(days); slowest day \(slowest.ymd) "
    + "\(String(format: "%.0f", slowest.ms)) ms; \(String(format: "%.1f", ms(total) / 1000)) s in all\n").data(using: .utf8)!)

/// The day's optimal line and the park rule's, clockwise on a tie, as the harness's UNSTIR_MOVES takes them: a knob and
/// its steps, the tank as -1. Exits when done.
func line(_ ymd: Int) -> Never {
    let (layout, stack) = Layout.daily(ymd)
    let solver = Solver(layout)
    guard let frost = solver.frost(stack) else {
        print("\(ymd) is no frost day")
        exit(1)
    }
    let seized = Set(frost.knobs)
    func moves(_ play: Play) -> String {
        play.moves.map { move in
            switch move {
            case let .stir(knob, _, steps): "\(knob):\(steps > 0 ? "+" : "")\(steps)"
            case let .turn(steps, _): "-1:\(steps > 0 ? "+" : "")\(steps)"
            case .wait: "w"
            }
        }.joined(separator: ",")
    }
    print("\(ymd) \(layout.rawValue) seized \(frost.knobs.map(String.init).joined(separator: ",")) par \(frost.par)")
    let optimal = solver.optimalPlay(stack, seized: seized)!, park = solver.park(stack, seized: seized)!
    print("optimal \(optimal.count): \(moves(optimal))")
    print("park rule \(park.count): \(moves(park))")
    exit(0)
}
