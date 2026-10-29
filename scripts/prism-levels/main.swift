// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Measures Prism's specimens, every one under its masks.
//   free: the entries that can come off at the start (`Layout.removable`) under the masks, then read white.
//   blocked: the knobs whose newest entry can't come off at the start: turning one back pushes.
//   right/step, forced: as plughole's, over the untwist under the masks, every right move at each step equally likely.
//   cost: the per-channel shader's work in entries (`Unstirred.channelCost`: 2, plus a map per channel each entry holds).
//   ghost, triple: the share of the glass where the three channels' words send a point apart by more than two pixels,
//     and where all three part from each other: how much of the picture shows coloured ghosts, and how much of it is
//     the three-way split that reads as mush.

func signed(_ n: Int) -> String { n > 0 ? "+\(n)" : "\(n)" }
func string(_ stack: [Twist]) -> String { stack.map { "\($0.rod):\(signed($0.steps))" }.joined(separator: ",") }
func string(_ masks: [Int: Channels]) -> String {
    masks.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value.letter!)" }.joined(separator: ",")
}

/// Expected sums of right moves and of forced steps over the rest of the untwist.
func expected(_ stack: [Twist], _ layout: Layout, _ masks: [Int: Channels], _ memo: inout [[Twist]: (Double, Double)])
    -> (Double, Double) {
    if stack.isEmpty { return (0, 0) }
    if let hit = memo[stack] { return hit }
    let r = layout.removable(stack, masks: masks)
    var sum = (0.0, 0.0)
    for i in r {
        var next = stack
        _ = next.commit(rod: stack[i].rod, steps: -stack[i].steps, in: layout, masks: masks)
        let e = expected(next, layout, masks, &memo)
        sum = (sum.0 + e.0, sum.1 + e.1)
    }
    let out = (Double(r.count) + sum.0 / Double(r.count), (r.count == 1 ? 1 : 0) + sum.1 / Double(r.count))
    memo[stack] = out
    return out
}

/// The shares of the glass with ghosts, and with all three channels apart.
func split(_ stack: [Twist], _ layout: Layout, _ masks: [Int: Channels]) -> (ghost: Double, triple: Double) {
    let rods = layout.rods, apart = 2 / 568.0
    var ghost = 0, triple = 0, n = 0
    for p in Tank.grid(160) {
        let q = Channels.each.map { c in
            stack.filter { (masks[$0.rod] ?? .white).contains(c) }
                .reduce(p) { Tank.twist($0, rod: rods[$1.rod], angle: Double($1.steps) * Tank.step) }
        }
        let d = [simd_distance(q[0], q[1]) > apart, simd_distance(q[1], q[2]) > apart, simd_distance(q[0], q[2]) > apart]
        n += 1
        if d.contains(true) { ghost += 1 }
        if d.allSatisfy({ $0 }) { triple += 1 }
    }
    return (Double(ghost) / Double(n), Double(triple) / Double(n))
}

struct Row {
    var line: String
    /// Par is the depth, the solver's optimum, and untwisting reaches it; nothing merges as it is dealt.
    var fair: Bool
}

func row(_ name: String, _ layout: Layout, _ masks: [Int: Channels], _ stack: [Twist], optimum solve: Bool = true) -> Row {
    let solver = Solver(layout, masks: masks)
    let optimum = solve ? solver.optimum(stack) ?? -1 : -1
    let untwisting = solver.untwistingPlay(stack)?.count ?? -1
    var memo: [[Twist]: (Double, Double)] = [:]
    let (right, forced) = expected(stack, layout, masks, &memo)
    let free = layout.removable(stack, masks: masks)
    let white = layout.removable(stack).count
    let tops = Set(stack.map(\.rod)).map { rod in stack.lastIndex { $0.rod == rod }! }
    let blocked = tops.filter { !free.contains($0) }.count
    let cost = stack.reduce(2) { $0 + Int((masks[$1.rod] ?? .white).rawValue).nonzeroBitCount }
    let (ghost, triple) = split(stack, layout, masks)
    let fair = (!solve || optimum == stack.count) && untwisting == stack.count
        && [Twist].parse(string(stack), in: layout, masks: masks) == stack
    let fields = [name, layout.rawValue, string(masks), "\(stack.count)", "\(optimum)", "\(untwisting)",
                  "\(free.count)/\(white)", "\(blocked)", String(format: "%.2f", right / Double(stack.count)),
                  String(format: "%.1f", forced), "\(cost)", String(format: "%.0f%%", 100 * ghost),
                  String(format: "%.0f%%", 100 * triple), string(stack)]
    return Row(line: fields.joined(separator: "\t"), fair: fair)
}

/// A seeded deal: one white rod holding only the bottom entry, every other rod a mask from `palette` (or `fixed`'s), and
/// `depth - 1` stirs over it on those rods, each 2 to 5 steps either way, none merging as it is dealt and every rod dealt.
func deal(_ layout: Layout, depth: Int, palette: [Channels], fixed: [Int: Channels]?, rng: inout SplitMix64)
    -> (masks: [Int: Channels], stack: [Twist])? {
    var masks: [Int: Channels]
    if let fixed {
        masks = fixed
    } else {
        let white = rng.below(layout.rods.count)
        masks = [white: .white]
        for slot in layout.rods.indices where slot != white { masks[slot] = palette[rng.below(palette.count)] }
        // Every letter of the palette on some rod, as far as the rods go.
        guard Set(masks.values).subtracting([.white]).count >= min(palette.filter { $0 != .white }.count, layout.rods.count - 1)
        else { return nil }
    }
    guard let white = masks.first(where: { $0.value == .white })?.key else { return nil }
    let others = layout.rods.indices.filter { $0 != white }
    func steps() -> Int { (2 + rng.below(4)) * (rng.below(2) == 0 ? 1 : -1) }
    var stack = [Twist(rod: white, steps: steps())], tries = 0
    while stack.count < depth {
        tries += 1
        // Masks under which every stir merges deal nothing.
        guard tries < 200 else { return nil }
        let t = Twist(rod: others[rng.below(others.count)], steps: steps())
        var next = stack
        guard next.commit(rod: t.rod, steps: t.steps, in: layout, masks: masks) == .pushed else { continue }
        stack = next
    }
    guard Set(stack.map(\.rod)) == Set(layout.rods.indices) else { return nil }
    return (masks, stack)
}

let args = Array(CommandLine.arguments.dropFirst())
let header = ["level", "layout", "masks", "entries", "optimum", "untwisting", "free", "blocked", "right/step", "forced",
              "cost", "ghost", "triple", "scramble"]
switch args.first {
case "table":
    print(header.joined(separator: "\t"))
    var n = 0
    while let line = readLine() {
        let f = line.split(separator: " ").map(String.init)
        n += 1
        guard f.count == 3, let layout = Layout(rawValue: f[0]), let masks = Channels.masks(f[1]) else { continue }
        print(row("prism-\(n)", layout, masks, .parse(f[2], in: layout, masks: masks)).line)
        fflush(stdout)
    }
case "check" where args.count == 4:
    guard let layout = Layout(rawValue: args[1]), let masks = Channels.masks(args[2]) else { exit(2) }
    print(header.joined(separator: "\t"))
    print(row("-", layout, masks, .parse(args[3], in: layout, masks: masks)).line)
case "search" where args.count == 6:
    // search <layout> <depth> <palette letters, e.g. rgb, or a full mask string> <from seed> <to seed>
    guard let layout = Layout(rawValue: args[1]), let depth = Int(args[2]) else { exit(2) }
    let fixed = args[3].contains(":") ? Channels.masks(args[3]) : nil
    let palette = args[3].compactMap(Channels.init(letter:))
    print(header.joined(separator: "\t"))
    for seed in UInt64(args[4])!...UInt64(args[5])! {
        var rng = SplitMix64(state: seed)
        guard let (masks, stack) = deal(layout, depth: depth, palette: palette, fixed: fixed, rng: &rng) else { continue }
        // The cheap measures first; the solver only for a deal that keeps four taps.
        guard stack.reduce(2, { $0 + Int((masks[$1.rod] ?? .white).rawValue).nonzeroBitCount }) <= 30 else { continue }
        let r = row("\(seed)", layout, masks, stack)
        if r.fair { print(r.line) }
        fflush(stdout)
    }
default:
    print("usage: table < rows | check <layout> <masks> <scramble> | search <layout> <depth> <palette> <from> <to>")
    exit(2)
}
