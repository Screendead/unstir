// Copyright © 2026 Jack Lusher. All rights reserved.

// scripts/solve.sh compiles this file into a command-line tool, where there is no Unstir module to import.
#if canImport(Unstir)
@testable import Unstir
#endif

/// One commit or turn of the tank, as `Game.commit` and `Game.turnTank` take it.
enum Move: Hashable, CustomStringConvertible {
    /// A knob's turn, stirring the slot under it.
    case stir(knob: Int, slot: Int, steps: Int)
    /// A turn of the tank the short way.
    case turn(steps: Int, to: Int)

    var description: String {
        func signed(_ n: Int) -> String { n > 0 ? "+\(n)" : "\(n)" }
        return switch self {
        case let .stir(knob, slot, steps): "knob \(knob) \(signed(steps)) (slot \(slot))"
        case let .turn(steps, to): "tank \(signed(steps)) to \(to)"
        }
    }
}

struct Play {
    var moves: [Move] = []

    /// Moves as `Game.history` counts them: commits to one slot in a row join, and a stir that nets nothing drops out
    /// and shuts, so the next commit to that slot is a new move. Turns in a row join too; no play turns in a row.
    var count: Int {
        var history: [(slot: Int, net: Int)] = [], open = false
        for move in moves {
            let (slot, steps) = switch move {
            case let .stir(_, slot, steps): (slot, steps)
            case let .turn(steps, _): (-1, steps)
            }
            if open, history.last?.slot == slot {
                history[history.count - 1].net += steps
                if slot >= 0, history.last!.net == 0 { history.removeLast(); open = false }
            } else {
                history.append((slot, steps))
                open = true
            }
        }
        return history.count
    }
}

/// Solves turning-tank levels on one layout: the fewest moves that empty the stack, and two rules of thumb. Stacks are
/// interned and what is found about each is cached, so every solve on one solver shares the work.
///
/// The optimum mostly untwists whole seams. While every stack keeps the rods-only rule (an entry is whole exactly when
/// no entry above it overlaps its rod, and untwisting it only takes it out), only rods that miss each other commute,
/// and a push or a partial merge uncovers nothing and leaves a seam that needs a stir of its own, so untwisting is
/// fastest. The real maps break the rule: a word can hold a disc still, like [0:-3, 3:-7, 0:+3] over rod 1 on quad, and
/// a push that builds one can save moves. So the optimum also tries detours from every stack that keeps the rule: a
/// commit of up to 11 steps either way or of an entry's exact inverse, where the stack it leaves breaks the rule,
/// joined by untwists of the same slot before and after it; and a commit turned straight back that leaves a different
/// stack, which costs nothing. That is a bounded search, not a proof. It skips detours from stacks already off the
/// rule, detours that keep the rule and break it only after later untwists, two detours in one stir, and stirs turned
/// back over three or more commits.
final class Solver {
    let layout: Layout
    private var ids: [[Twist]: Int] = [:]
    private var stacks: [[Twist]] = []
    private var memo: [[Untwist]?] = []
    private var ruled: [Bool?] = []
    /// Keyed by stack id * rods + slot.
    private var runMemo: [Int: [Run]] = [:], detourMemo: [Int: [Run]] = [:]

    struct Untwist {
        var index: Int, slot: Int, steps: Int, to: Int
    }

    /// Commits to one slot in a row: one move, or none when they net nothing.
    private struct Run {
        var to: Int, commits: [Int]
        var cost: Int { commits.reduce(0, +) == 0 ? 0 : 1 }
    }

    /// Where a blocked rule of thumb would rather leave the seized knobs.
    enum Parking {
        /// Over as few rings that still have a seam as it can.
        case fewest
        /// Every one over a ring with no seam left, else no preference: the rule as worded.
        case all
    }

    /// Which of two equally near positions a blocked rule of thumb turns to.
    enum Tie {
        case clockwise
        /// The lower position counted clockwise from home, as the port behind the first table picked it.
        case lowest
    }

    init(_ layout: Layout) { self.layout = layout }

    var stacksSeen: Int { stacks.count }

    private func id(_ stack: [Twist]) -> Int {
        if let id = ids[stack] { return id }
        ids[stack] = stacks.count
        stacks.append(stack)
        memo.append(nil)
        ruled.append(nil)
        return stacks.count - 1
    }

    private func untwists(_ id: Int) -> [Untwist] {
        if let known = memo[id] { return known }
        let stack = stacks[id]
        // `Layout.removable`, through `landing`.
        let whole = stack.indices.filter { landing(stack, rod: stack[$0].rod, steps: -stack[$0].steps) == $0 }
        let found = whole.map { i in
            var after = stack
            after.commit(rod: stack[i].rod, steps: -stack[i].steps, in: layout)
            return Untwist(index: i, slot: stack[i].rod, steps: -stack[i].steps, to: self.id(after))
        }
        memo[id] = found
        return found
    }

    private func rodsOnly(_ id: Int) -> Bool {
        if let known = ruled[id] { return known }
        let found = rodsOnly(stacks[id])
        ruled[id] = found
        return found
    }

    /// Whether the stack keeps the rods-only rule: its whole entries are those with no entry above overlapping their
    /// rod, and untwisting one only takes it out.
    private func rodsOnly(_ stack: [Twist]) -> Bool {
        stack.indices.allSatisfy { i in
            let t = stack[i]
            if stack[(i + 1)...].contains(where: { overlap[$0.rod][t.rod] }) {
                // Not whole. `parts` usually shows that before the landing has checked every newer entry of the rod.
                return parts(stack, above: i, rod: t.rod, steps: -t.steps)
                    || landing(stack, rod: t.rod, steps: -t.steps) != i
            }
            // `Array.commit` takes the entry out and commits the ones above it again, and each must push.
            var rest = Array(stack[..<i])
            return stack[(i + 1)...].allSatisfy { t in
                defer { rest.append(t) }
                return landing(rest, rod: t.rod, steps: t.steps) == nil
            }
        }
    }

    /// `Array.landing`, through `commutes`.
    private func landing(_ stack: [Twist], rod: Int, steps: Int) -> Int? {
        stack.indices.reversed().first { stack[$0].rod == rod && commutes(stack, above: $0, rod: rod, steps: steps) }
    }

    /// `Layout.commutes`, asked once per word, and not at all for a word `parts` finds.
    private func commutes(_ stack: [Twist], above i: Int, rod: Int, steps: Int) -> Bool {
        guard stack[(i + 1)...].contains(where: { overlap[$0.rod][rod] }) else { return true }
        if parts(stack, above: i, rod: rod, steps: steps) { return false }
        let word = Array(stack[(i + 1)...]) + [Twist(rod: rod, steps: steps)]
        if let known = commuting[word] { return known }
        let found = layout.commutes(stack, above: i, rod: rod, steps: steps)
        commuting[word] = found
        return found
    }

    /// Words that `parts` passes, each with the turn after it: whether `Layout.commutes` passes them.
    private var commuting: [[Twist]: Bool] = [:]

    /// Whether the entries above index i and a turn of `rod` by `steps` fail to commute where the turned disc meets the
    /// first disc above that overlaps it: words that fail usually show it within a point or two there. It maps points
    /// as `Layout.same` does, with a looser tolerance than `Layout.commutes`, so any word it parts, `Layout.commutes`
    /// would.
    private func parts(_ stack: [Twist], above i: Int, rod: Int, steps: Int) -> Bool {
        guard let q = stack[(i + 1)...].first(where: { overlap[$0.rod][rod] })?.rod else { return false }
        let rods = layout.rods, turn = Double(steps) * Tank.step
        func above(_ p: SIMD2<Double>) -> SIMD2<Double> {
            stack[(i + 1)...].reduce(p) { Tank.twist($0, rod: rods[$1.rod], angle: Double($1.steps) * Tank.step) }
        }
        return lens[rod][q].contains { p in
            let d = Tank.twist(above(p), rod: rods[rod], angle: turn) - above(Tank.twist(p, rod: rods[rod], angle: turn))
            return (d * d).sum() > 1e-6
        }
    }

    private lazy var overlap = layout.rods.indices.map { i in layout.rods.indices.map { layout.overlaps(i, $0) } }

    /// lens[i][j]: `Tank.samples` inside both rods' discs.
    private lazy var lens: [[[SIMD2<Double>]]] = layout.rods.map { a in
        layout.rods.map { b in
            Tank.samples.filter { p in [a, b].allSatisfy { rod in
                let d = p - SIMD2(rod.x, rod.y)
                return (d * d).sum() < rod.z * rod.z
            } }
        }
    }

    /// `Array.commit` as rods-only overlap has it: the rod's newest entry takes the turn when nothing above it overlaps
    /// the rod, and nothing above it moves.
    private func rodsOnlyCommit(_ stack: [Twist], slot: Int, steps: Int) -> [Twist] {
        var stack = stack
        if let i = stack.lastIndex(where: { $0.rod == slot }),
           !stack[(i + 1)...].contains(where: { overlap[$0.rod][slot] }) {
            stack[i].steps += steps
            if stack[i].steps == 0 { stack.remove(at: i) }
        } else {
            stack.append(Twist(rod: slot, steps: steps))
        }
        return stack
    }

    /// Every run of commits to `slot` from stack `id` the optimum tries: untwists of whole seams, which join when one
    /// uncovers another, and detours from `id` or from a stack those untwists reach.
    private func runs(_ id: Int, slot: Int) -> [Run] {
        let key = id * layout.rods.count + slot
        if let known = runMemo[key] { return known }
        var best: [Int: Run] = [:]
        func add(_ run: Run) {
            if let known = best[run.to], (known.cost, known.commits.count) <= (run.cost, run.commits.count) { return }
            best[run.to] = run
        }
        func untwisting(from id: Int, after commits: [Int]) {
            // Off the rule every commit lands off it too, so detours from there would be tried without end.
            if rodsOnly(id) {
                for detour in detours(id, slot: slot) { add(Run(to: detour.to, commits: commits + detour.commits)) }
            }
            for u in untwists(id) where u.slot == slot {
                add(Run(to: u.to, commits: commits + [u.steps]))
                untwisting(from: u.to, after: commits + [u.steps])
            }
        }
        untwisting(from: id, after: [])
        let found = Array(best.values)
        runMemo[key] = found
        return found
    }

    /// Detours from stack `id` on `slot`: each commit the class comment names, then any untwists of the slot after it.
    private func detours(_ id: Int, slot: Int) -> [Run] {
        let key = id * layout.rods.count + slot
        if let known = detourMemo[key] { return known }
        let stack = stacks[id]
        let plain = Set(untwists(id).filter { $0.slot == slot }.map { stacks[$0.to] })
        var found: [Run] = []
        func untwisting(from id: Int, after commits: [Int]) {
            found.append(Run(to: id, commits: commits))
            for u in untwists(id) where u.slot == slot { untwisting(from: u.to, after: commits + [u.steps]) }
        }
        for steps in Set(Array(-11...11) + stack.filter { $0.rod == slot }.map { -$0.steps }) where steps != 0 {
            var after = stack
            guard after.commit(rod: slot, steps: steps, in: layout) != .refused else { continue }
            var back = after
            if back.commit(rod: slot, steps: -steps, in: layout) != .refused, back != stack {
                found.append(Run(to: self.id(back), commits: [steps, -steps]))
            }
            guard !plain.contains(after), after != rodsOnlyCommit(stack, slot: slot, steps: steps) || !rodsOnly(after)
            else { continue }
            untwisting(from: self.id(after), after: [steps])
        }
        detourMemo[key] = found
        return found
    }

    /// reach[position][slot]: whether a working knob sits over the slot.
    private func reach(_ seized: Set<Int>) -> [[Bool]] {
        (0..<layout.order).map { p in layout.rods.indices.map { !seized.contains(layout.knob(over: $0, at: p)) } }
    }

    private func wrap(_ position: Int) -> Int { (position % layout.order + layout.order) % layout.order }

    private func shortWay(_ from: Int, _ to: Int) -> Int {
        let d = wrap(to - from)
        return 2 * d > layout.order ? d - layout.order : d
    }

    /// Nil when some seam can never come under a working knob. `home` also asks for the tank back at 0 at the end.
    func optimum(_ stack: [Twist], seized: Set<Int> = [], from position: Int = 0, home: Bool = false) -> Int? {
        optimalPlay(stack, seized: seized, from: position, home: home)?.count
    }

    /// The untwisting play, unless a detour beats it.
    func optimalPlay(_ stack: [Twist], seized: Set<Int> = [], from position: Int = 0, home: Bool = false) -> Play? {
        guard let plain = untwistingPlay(stack, seized: seized, from: position, home: home) else { return nil }
        return search(stack, seized: seized, from: position, home: home, below: plain.count) ?? plain
    }

    /// Breadth-first over (stack, position), moving only by untwisting a whole seam or turning the tank.
    func untwistingPlay(_ stack: [Twist], seized: Set<Int> = [], from position: Int = 0, home: Bool = false) -> Play? {
        let order = layout.order, reach = self.reach(seized)
        let start = id(stack) * order + wrap(position)
        func done(_ state: Int) -> Bool { stacks[state / order].isEmpty && (!home || state % order == 0) }
        var parent: [Int: (from: Int, move: [Move])] = [:]
        var frontier = [start], goal = done(start) ? start : nil
        while goal == nil, !frontier.isEmpty {
            var next: [Int] = []
            func visit(_ state: Int, from: Int, by move: [Move]) {
                guard state != start, parent[state] == nil else { return }
                parent[state] = (from, move)
                next.append(state)
                if goal == nil, done(state) { goal = state }
            }
            for state in frontier {
                let (id, p) = (state / order, state % order)
                for u in untwists(id) where reach[p][u.slot] {
                    // A further untwist of the same slot joins the stir, so it costs nothing more.
                    let knob = layout.knob(over: u.slot, at: p)
                    var chain = [(u.to, [Move.stir(knob: knob, slot: u.slot, steps: u.steps)])]
                    while let (to, moves) = chain.popLast() {
                        visit(to * order + p, from: state, by: moves)
                        chain += untwists(to).filter { $0.slot == u.slot }
                            .map { ($0.to, moves + [.stir(knob: knob, slot: u.slot, steps: $0.steps)]) }
                    }
                }
                for q in 0..<order where q != p && !seized.isEmpty {
                    visit(id * order + q, from: state, by: [.turn(steps: shortWay(p, q), to: q)])
                }
            }
            frontier = next
        }
        return goal.map { path(to: $0, parent) }
    }

    /// The fewest moves under `bound`, detours too, breadth-first by cost: a stir turned straight back costs nothing.
    private func search(_ stack: [Twist], seized: Set<Int>, from position: Int, home: Bool, below bound: Int) -> Play? {
        let order = layout.order
        let start = id(stack) * order + wrap(position)
        func done(_ state: Int) -> Bool { stacks[state / order].isEmpty && (!home || state % order == 0) }
        var cost = [start: 0], parent: [Int: (from: Int, move: [Move])] = [:]
        var layer = [start]
        for d in 0..<bound {
            var next: [Int] = [], i = 0
            // Stirs that cost nothing extend this layer as it runs.
            while i < layer.count {
                let state = layer[i]
                i += 1
                guard cost[state] == d else { continue }
                if done(state) { return path(to: state, parent) }
                let (id, p) = (state / order, state % order)
                func visit(_ to: Int, _ c: Int, _ move: [Move]) {
                    guard d + c < bound, cost[to].map({ d + c < $0 }) ?? true else { return }
                    cost[to] = d + c
                    parent[to] = (state, move)
                    if c == 0 { layer.append(to) } else { next.append(to) }
                }
                for knob in layout.rods.indices where !seized.contains(knob) {
                    let slot = layout.slot(of: knob, at: p)
                    for run in runs(id, slot: slot) {
                        visit(run.to * order + p, run.cost, run.commits.map { .stir(knob: knob, slot: slot, steps: $0) })
                    }
                }
                for q in 0..<order where q != p && !seized.isEmpty {
                    visit(id * order + q, 1, [.turn(steps: shortWay(p, q), to: q)])
                }
            }
            layer = next
        }
        return nil
    }

    private func path(to goal: Int, _ parent: [Int: (from: Int, move: [Move])]) -> Play {
        var state = goal, moves: [Move] = []
        while let link = parent[state] {
            moves = link.move + moves
            state = link.from
        }
        return Play(moves: moves)
    }

    /// The fair player: untwists the newest whole seam a working knob reaches. When none is, turns to a position where
    /// one is, choosing by `parking` where the seized knobs land, then the nearest, then by `tie`.
    func park(_ stack: [Twist], seized: Set<Int> = [], from position: Int = 0, parking: Parking = .fewest,
              tie: Tie = .clockwise) -> Play? {
        play(stack, seized: seized, from: position, tie: tie) { stack, turn, to in
            let rings = Set(stack.map(\.rod))
            let over = seized.filter { rings.contains(self.layout.slot(of: $0, at: to)) }.count
            return [parking == .fewest ? over : min(over, 1), abs(turn)]
        }
    }

    /// Untwists the newest whole seam a working knob reaches. When none is, turns to the nearest position where one is,
    /// clockwise on a tie.
    func noLookahead(_ stack: [Twist], seized: Set<Int> = [], from position: Int = 0) -> Play? {
        play(stack, seized: seized, from: position, tie: .clockwise) { _, turn, _ in [abs(turn)] }
    }

    /// `rank(stack, turn, to)` orders the positions a blocked player may turn to, lowest first, and `tie` breaks ties.
    private func play(_ stack: [Twist], seized: Set<Int>, from position: Int, tie: Tie,
                      rank: ([Twist], Int, Int) -> [Int]) -> Play? {
        let reach = self.reach(seized)
        var id = id(stack), p = wrap(position), play = Play()
        while !stacks[id].isEmpty {
            let whole = untwists(id)
            if let u = whole.filter({ reach[p][$0.slot] }).max(by: { $0.index < $1.index }) {
                play.moves.append(.stir(knob: layout.knob(over: u.slot, at: p), slot: u.slot, steps: u.steps))
                id = u.to
                continue
            }
            guard let q = (0..<layout.order).filter({ q in q != p && whole.contains { reach[q][$0.slot] } }).map({ q -> (Int, [Int]) in
                let turn = shortWay(p, q)
                return (q, rank(stacks[id], turn, q) + [tie == .clockwise ? (turn < 0 ? 1 : 0) : q])
            }).min(by: { $0.1.lexicographicallyPrecedes($1.1) })?.0
            else { return nil }
            play.moves.append(.turn(steps: shortWay(p, q), to: q))
            p = q
        }
        return play
    }

    /// The fewest moves up to `limit` when a move may be any commits to one slot under a working knob, up to `commits`
    /// of them joined, each by a count from `steps` or an entry's exact inverse: pushes and partial merges as well as
    /// untwists. Nil past the limit. Uncached and exponential, to check `optimum` on small cases.
    func exhaustive(_ stack: [Twist], seized: Set<Int> = [], limit: Int, steps: [Int], commits: Int = 1) -> Int? {
        struct State: Hashable {
            var stack: [Twist], position: Int
        }
        let reach = self.reach(seized)
        guard !stack.isEmpty else { return 0 }
        var seen: Set<State> = [State(stack: stack, position: 0)], frontier = Array(seen)
        for depth in stride(from: 1, through: limit, by: 1) {
            var next: [State] = []
            for state in frontier {
                var after = (0..<layout.order).filter { $0 != state.position && !seized.isEmpty }
                    .map { State(stack: state.stack, position: $0) }
                for slot in layout.rods.indices where reach[state.position][slot] {
                    var joined = [state.stack]
                    for _ in 0..<commits {
                        joined = joined.flatMap { stack in
                            Set(steps + stack.filter { $0.rod == slot }.map { -$0.steps }).compactMap { k -> [Twist]? in
                                var stack = stack
                                return stack.commit(rod: slot, steps: k, in: layout) == .refused ? nil : stack
                            }
                        }
                        after += joined.map { State(stack: $0, position: state.position) }
                    }
                }
                if after.contains(where: { $0.stack.isEmpty }) { return depth }
                next += after.filter { seen.insert($0).inserted }
            }
            frontier = next
        }
        return nil
    }
}
