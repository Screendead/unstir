// Copyright © 2026 Jack Lusher. All rights reserved.

// scripts/solve.sh compiles this file into a command-line tool, where there is no Unstir module to import.
#if canImport(Unstir)
@testable import Unstir
#endif

/// Solves a level under Charybdis's keys (`Ward`): the fewest moves that empty the stack, as `Play.count` counts them,
/// by A* over stacks, each move a commit to a knob other than the last one turned (two in a row on one knob are one).
///
/// What it tries, so what its optimum is a bound over: every count from -12 to +12 when `exhaustive`, a proof to that
/// range; otherwise, on each knob, the counts that bring the entry the turn lands on (or a pushed one) to 0 or to the
/// negation of one or two other entries of its rod (an overshoot that a later turn, or a fall, takes off), the counts
/// that bring its pointer to a mark it keys or to where it must end, and +-1 as a detour; each only where the wards
/// allow it. Its heuristic is admissible (`h`), so within those counts the optimum is proved; `exhaustive` agrees on
/// every level it finishes.
final class KeySolver {
    let layout: Layout
    let wards: [Int: Ward]
    let dealt: [Twist]
    var exhaustive = false
    /// Deep levels: only turns that take a whole entry off and a key's turns to a mark, never a detour pushed for its
    /// own sake: a bounded search, as maelstrom's par is. Within those every entry needs a turn of its own, so the
    /// heuristic counts entries and reaches maelstrom's depths.
    var deep = false
    private(set) var expanded = 0
    private var commuting: [[Twist]: Bool] = [:]

    init(_ layout: Layout, wards: [Int: Ward], dealt: [Twist]) {
        self.layout = layout
        self.wards = wards
        self.dealt = dealt
    }

    struct State: Hashable {
        var stack: [Twist], last: Int?
    }

    // MARK: Array.commit, with its commutation cached by word

    private func commutes(_ stack: [Twist], above i: Int, rod: Int, steps: Int) -> Bool {
        let above = stack[(i + 1)...]
        if above.allSatisfy({ !layout.overlaps($0.rod, rod) }) { return true }
        let turn = Twist(rod: rod, steps: steps), word = Array(above) + [turn]
        if let known = commuting[word] { return known }
        let found = layout.same(word, [turn] + above, at: Tank.samples, within: 1e-6)
        commuting[word] = found
        return found
    }

    private func landing(_ stack: [Twist], rod: Int, steps: Int) -> Int? {
        stack.indices.reversed().first { stack[$0].rod == rod && commutes(stack, above: $0, rod: rod, steps: steps) }
    }

    func commit(_ stack: inout [Twist], _ entry: Twist) {
        guard entry.steps != 0 else { return }
        if let i = landing(stack, rod: entry.rod, steps: entry.steps) {
            var rest = Array(stack[i...])
            rest[0].steps += entry.steps
            stack.removeSubrange(i...)
            if rest[0].steps != 0 { commit(&stack, rest[0]) }
            for t in rest.dropFirst() { commit(&stack, t) }
            return
        }
        stack.append(entry)
    }

    // MARK: The search

    var start: State { State(stack: dealt, last: nil) }

    private func h(_ s: State) -> Int {
        // Each rod whose entries don't sum to 0 needs a turn of its own (a fall only joins entries of one rod, so keeps
        // their sum); and a key at rest, off a mark a ward still to turn needs, a turn of its own too, shared by wards
        // on the same key and mark.
        var net: [Int: Int] = [:]
        for t in s.stack { net[t.rod, default: 0] += t.steps }
        let marks = Set(wards.filter { w, k in
            net[w, default: 0] != 0 && net[k.key, default: 0] == 0 && !k.open(stack: s.stack, dealt: dealt)
        }.values)
        let loose = net.values.filter { $0 != 0 }.count + marks.count
        guard deep else { return loose }
        // A key with no entry, off a mark a ward still needs, pushes one that a later turn takes off.
        let pushes = Set(wards.filter { w, k in
            s.stack.contains { $0.rod == w } && !s.stack.contains { $0.rod == k.key } && !k.open(stack: s.stack, dealt: dealt)
        }.values)
        return max(loose, s.stack.count + 2 * pushes.count)
    }

    /// The counts tried on `rod` from stack `stack`.
    func counts(_ rod: Int, _ stack: [Twist]) -> [Int] {
        let p = Ward.pointer(rod, stack: stack, dealt: dealt)
        var out: Set<Int> = []
        for k in wards.values where k.key == rod { for whole in -1...1 { out.insert(k.mark - p + 12 * whole) } }
        if deep {
            for i in stack.indices where stack[i].rod == rod && landing(stack, rod: rod, steps: -stack[i].steps) == i {
                out.insert(-stack[i].steps)
            }
            return out.filter { $0 != 0 && abs($0) <= 12 }.sorted()
        }
        if exhaustive { return (-12...12).filter { $0 != 0 } }
        let mine = stack.filter { $0.rod == rod }.map(\.steps)
        var want: Set<Int> = [0]
        for (i, a) in mine.enumerated() {
            want.insert(-a)
            for (j, b) in mine.enumerated() where j > i { want.insert(-a - b) }
        }
        // The turn lands on some entry of the rod (worth trying them all, as which one depends on the count) or pushes.
        for base in Set(mine + [0]) {
            for w in want { out.insert(w - base) }
        }
        out.insert(-dealt.filter { $0.rod == rod }.reduce(0) { $0 + $1.steps } - p)
        for d in [1, -1] { out.insert(d) }
        return out.filter { $0 != 0 && abs($0) <= 12 }.sorted()
    }

    func moves(_ s: State) -> [(Twist, State)] {
        var out: [(Twist, State)] = []
        for rod in layout.rods.indices where rod != s.last && wards.opens(rod, stack: s.stack, dealt: dealt) {
            for n in counts(rod, s.stack) {
                var next = s.stack
                commit(&next, Twist(rod: rod, steps: n))
                out.append((Twist(rod: rod, steps: n), State(stack: next, last: rod)))
            }
        }
        return out
    }

    /// The fewest moves, and one line that takes them; nil if none within `limit`.
    func solve(limit: Int = 24) -> [Twist]? {
        let start = self.start
        var best: [State: Int] = [start: 0]
        var from: [State: (State, Twist)] = [:]
        // Buckets by f, each a stack (LIFO), so ties go deep first.
        var open: [[State]] = Array(repeating: [], count: limit + 2)
        guard h(start) <= limit else { return nil }
        open[h(start)].append(start)
        var f = h(start)
        while f <= limit {
            guard let s = open[f].popLast() else { f += 1; continue }
            let g = best[s]!
            if g + h(s) < f { continue }
            if s.stack.isEmpty {
                var line: [Twist] = [], at = s
                while let (prev, t) = from[at] { line.append(t); at = prev }
                return line.reversed()
            }
            expanded += 1
            for (t, n) in moves(s) where g + 1 < best[n] ?? .max {
                best[n] = g + 1
                from[n] = (s, t)
                let fn = g + 1 + h(n)
                if fn <= limit { open[max(fn, f)].append(n) }
            }
        }
        return nil
    }

    /// Plain untwisting under the wards: each move takes off a whole entry (its exact inverse lands on it) on a knob
    /// that opens; the fewest such moves, or nil when the wards strand it, which is when the level needs more than
    /// untwisting.
    func untwisting() -> Int? {
        var seen: Set<State> = [], level = [start], depth = 0
        while !level.isEmpty {
            var next: [State] = []
            for s in level {
                if s.stack.isEmpty { return depth }
                for i in s.stack.indices {
                    let t = s.stack[i], rod = t.rod
                    guard rod != s.last, wards.opens(rod, stack: s.stack, dealt: dealt),
                          landing(s.stack, rod: rod, steps: -t.steps) == i else { continue }
                    var after = s.stack
                    commit(&after, Twist(rod: rod, steps: -t.steps))
                    let n = State(stack: after, last: rod)
                    if seen.insert(n).inserted { next.append(n) }
                }
            }
            level = next
            depth += 1
        }
        return nil
    }

    /// The first moves from which the optimum is still reachable, by solving after each.
    func keyMoves(par: Int) -> [Twist] {
        moves(start).compactMap { t, n in reaches(from: n, limit: par - 1) ? t : nil }
    }

    /// Along `line`, at each step the moves tried and those that still reach its length: a step where one move of
    /// several keeps par is forced.
    func choices(along line: [Twist]) -> [(tried: Int, keep: Int)] {
        var at = start, out: [(Int, Int)] = []
        for (i, t) in line.enumerated() {
            let next = moves(at)
            out.append((next.count, next.filter { reaches(from: $0.1, limit: line.count - i - 1) }.count))
            at = next.first { $0.0 == t }!.1
        }
        return out
    }

    /// The deepest the stack stands along `line`.
    func deepest(along line: [Twist]) -> Int {
        var stack = dealt, most = stack.count
        for t in line { commit(&stack, t); most = max(most, stack.count) }
        return most
    }

    /// Whether some line from `start` empties the stack within `limit` moves.
    func reaches(from start: State, limit: Int) -> Bool {
        if start.stack.isEmpty { return true }
        var best: [State: Int] = [start: 0]
        var open: [[State]] = Array(repeating: [], count: limit + 2)
        guard h(start) <= limit else { return false }
        open[h(start)].append(start)
        var f = h(start)
        while f <= limit {
            guard let s = open[f].popLast() else { f += 1; continue }
            let g = best[s]!
            if s.stack.isEmpty { return true }
            for (_, n) in moves(s) where g + 1 < best[n] ?? .max {
                best[n] = g + 1
                let fn = g + 1 + h(n)
                if fn <= limit { open[max(fn, f)].append(n) }
            }
        }
        return false
    }
}
