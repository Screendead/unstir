// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Measures Prism's specimens, every one under its masks.
//   free: the entries that can come off at the start (`Layout.removable`) under the masks, then read white.
//   blocked: the knobs whose newest entry can't come off at the start: turning one back pushes.
//   right/step, forced: as plughole's, over the untwist under the masks, every right move at each step equally likely.
//   cost: the per-channel shader's work in entries (`Unstirred.channelCost`: 3, plus a map per channel each entry holds).
//   ghost, triple: the share of the glass where the three channels' words send a point apart by more than two pixels,
//     and where all three part from each other: how much of the picture shows coloured ghosts, and how much of it is
//     the three-way split that reads as mush.
//   sums, least read: `read`'s line, untwisting the newest removable entry each move: how many of its moves are on a rod
//     stirred more than once, which shows the sum of its stirs, and the least share a once-stirred coloured rod's count
//     registers (`read`), which should be well over 0.
//   most: the most stirs any one rod holds; past 3 (the first five trays' most) a rod's moves read as guesses.

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

/// The plate's point each channel shows at the glass's `p` under `stack`, as the shader samples it: the newest entry's
/// inverse first.
func words(_ p: SIMD2<Double>, _ stack: [Twist], _ layout: Layout, _ masks: [Int: Channels]) -> [SIMD2<Double>] {
    Channels.each.map { c in
        stack.reversed().filter { (masks[$0.rod] ?? .white).contains(c) }
            .reduce(p) { Tank.twist($0, rod: layout.rods[$1.rod], angle: -Double($1.steps) * Tank.step) }
    }
}

/// How one untwist line reads, a move a line: what the core of the rod to turn shows the player before the move.
///   whole: the share of the core where the mask's channels lie together, so its ghost is one colour, not two.
///   read: the share where the right turn brings one of the mask's channels onto one the mask leaves alone, the
///     register the eye turns the ghost into. A white rod has no channel left alone: "-".
///   decoy: the wrong turn that registers the most of the core that way, and its share.
///   net: each of the mask's channels' own turn about this rod, summed over the rod's entries, against the move.
struct Read {
    var rod: Int, mask: Channels, right: Int, times: Int, net: Int, whole: Double, read: Double?
    var decoy: (key: Int, value: Double)?, before: [Twist]
}

func reads(_ layout: Layout, _ masks: [Int: Channels], _ dealt: [Twist]) -> [Read] {
    var stack = dealt, out: [Read] = []
    let apart = 2 / 568.0
    while !stack.isEmpty {
        guard let i = layout.removable(stack, masks: masks).last else { return out }
        let e = stack[i], mask = masks[e.rod] ?? .white, rod = layout.rods[e.rod], k = rod.z * Tank.plateau
        let core = Tank.grid(160).filter { simd_distance($0, SIMD2(rod.x, rod.y)) <= k }
        let inside = Channels.each.indices.filter { mask.contains(Channels.each[$0]) }
        let outside = Channels.each.indices.filter { !mask.contains(Channels.each[$0]) }
        let before = core.map { words($0, stack, layout, masks) }
        let whole = before.filter { q in inside.allSatisfy { simd_distance(q[$0], q[inside[0]]) <= apart } }.count
        var shares: [Int: Double] = [:]
        for turn in -5...6 where turn != 0 && !outside.isEmpty {
            let after = core.map { words($0, stack + [Twist(rod: e.rod, steps: turn)], layout, masks) }
            shares[turn] = inside.flatMap { c in outside.map { d in
                Double(after.filter { simd_distance($0[c], $0[d]) <= apart }.count) / Double(core.count)
            } }.max()!
        }
        let right = -e.steps
        let decoy = shares.filter { $0.key != right && $0.key != right + 12 && $0.key != right - 12 }.max { $0.value < $1.value }
        let net = stack.filter { $0.rod == e.rod }.map(\.steps).reduce(0, +)
        let times = stack.filter { $0.rod == e.rod }.count
        out.append(Read(rod: e.rod, mask: mask, right: right, times: times, net: net,
                        whole: Double(whole) / Double(core.count), read: shares[right], decoy: decoy, before: stack))
        stack.remove(at: i)
    }
    return out
}

func read(_ name: String, _ layout: Layout, _ masks: [Int: Channels], _ dealt: [Twist]) {
    for r in reads(layout, masks, dealt) {
        print([name, "\(r.rod)", String(r.mask.letter!), signed(r.right), "\(r.times)", signed(r.net),
               String(format: "%.2f", r.whole), r.read.map { String(format: "%.2f", $0) } ?? "-",
               r.decoy.map { "\(signed($0.key)) \(String(format: "%.2f", $0.value))" } ?? "-",
               string(r.before)].joined(separator: "\t"))
    }
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
    let cost = stack.reduce(3) { $0 + Int((masks[$1.rod] ?? .white).rawValue).nonzeroBitCount }
    let (ghost, triple) = split(stack, layout, masks)
    // sums: untwist moves on a rod holding more than one entry, which shows the sum of its stirs, not the move's count.
    // least: the least read share of a move on a once-stirred coloured rod, whose count must show.
    let line = reads(layout, masks, stack)
    let sums = line.filter { $0.times > 1 }.count
    let most = Dictionary(grouping: stack, by: \.rod).values.map(\.count).max() ?? 0
    let least = line.filter { $0.times == 1 }.compactMap(\.read).min().map { String(format: "%.2f", $0) } ?? "-"
    let fair = (!solve || optimum == stack.count) && untwisting == stack.count
        && [Twist].parse(string(stack), in: layout, masks: masks) == stack
    let fields = [name, layout.rawValue, string(masks), "\(stack.count)", "\(optimum)", "\(untwisting)",
                  "\(free.count)/\(white)", "\(blocked)", String(format: "%.2f", right / Double(stack.count)),
                  String(format: "%.1f", forced), "\(cost)", String(format: "%.0f%%", 100 * ghost),
                  String(format: "%.0f%%", 100 * triple), "\(sums)", least, "\(most)", string(stack)]
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
        // PRISM_ROD_CAP=n deals no rod more than n stirs: a rod stirred more often shows only their sum, and its decoys
        // read nearly as strongly as its count, so the move becomes a guess.
        let open = rodCap.map { cap in others.filter { r in stack.filter { $0.rod == r }.count < cap } } ?? others
        guard !open.isEmpty else { return nil }
        let t = Twist(rod: open[rng.below(open.count)], steps: steps())
        var next = stack
        guard next.commit(rod: t.rod, steps: t.steps, in: layout, masks: masks) == .pushed else { continue }
        stack = next
    }
    guard Set(stack.map(\.rod)) == Set(layout.rods.indices) else { return nil }
    return (masks, stack)
}

let rodCap = ProcessInfo.processInfo.environment["PRISM_ROD_CAP"].flatMap(Int.init)
let args = Array(CommandLine.arguments.dropFirst())
let header = ["level", "layout", "masks", "entries", "optimum", "untwisting", "free", "blocked", "right/step", "forced",
              "cost", "ghost", "triple", "sums", "least read", "most", "scramble"]
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
case "read":
    print(["level", "rod", "mask", "turn", "entries on rod", "rod's net", "whole", "read", "decoy", "stack before"].joined(separator: "\t"))
    var n = 0
    while let line = readLine() {
        let f = line.split(separator: " ").map(String.init)
        n += 1
        guard f.count == 3, let layout = Layout(rawValue: f[0]), let masks = Channels.masks(f[1]) else { continue }
        read("prism-\(n)", layout, masks, .parse(f[2], in: layout, masks: masks))
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
        guard stack.reduce(3, { $0 + Int((masks[$1.rod] ?? .white).rawValue).nonzeroBitCount }) <= 30 else { continue }
        let r = row("\(seed)", layout, masks, stack)
        if r.fair { print(r.line) }
        fflush(stdout)
    }
case "bury" where args.count == 4 || args.count == 5:
    // bury <layout> <masks> <scramble> [counts, e.g. 4,-4]: the deal with a second stir on its white rod buried mid-stack (Jack's call,
    // 2026-11-28), added at each place and count, or put in place of a coloured stir whose rod has others; each with
    // the place it sits at ahead of the measures. The solver is left to `check`. Every count but the white's own
    // ghost shares measures alike, so one count is enough to place it.
    guard let layout = Layout(rawValue: args[1]), let masks = Channels.masks(args[2]) else { exit(2) }
    let dealt = [Twist].parse(args[3], in: layout, masks: masks)
    let white = dealt[0].rod
    print((["how", "at"] + header).joined(separator: "\t"))
    for at in 2..<dealt.count - 1 {
        for steps in args.count == 5 ? args[4].split(separator: ",").compactMap({ Int($0) }) : [-5, -4, -3, -2, 2, 3, 4, 5] {
            let t = Twist(rod: white, steps: steps)
            var tries = [("add", Array(dealt[..<at]) + [t] + dealt[at...])]
            if dealt.filter({ $0.rod == dealt[at].rod }).count > 1 {
                tries.append(("for \(dealt[at].rod):\(signed(dealt[at].steps))", Array(dealt[..<at]) + [t] + dealt[(at + 1)...]))
            }
            for (how, stack) in tries {
                guard [Twist].parse(string(stack), in: layout, masks: masks) == stack,
                      stack.reduce(3, { $0 + Int((masks[$1.rod] ?? .white).rawValue).nonzeroBitCount }) <= 30 else { continue }
                let r = row("-", layout, masks, stack, optimum: false)
                if r.fair { print("\(how)\t\(at)\t\(r.line)") }
                fflush(stdout)
            }
        }
    }
default:
    print("usage: table < rows | check <layout> <masks> <scramble> | search <layout> <depth> <palette> <from> <to> | bury <layout> <masks> <scramble> [counts]")
    exit(2)
}
