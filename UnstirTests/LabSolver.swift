// Copyright © 2026 Jack Lusher. All rights reserved.

// scripts/solve.sh compiles this file into a command-line tool, where there is no Unstir module to import.
#if canImport(Unstir)
@testable import Unstir
#endif

/// Solves a level under `LabRules`: the fewest moves that empty the stack, as `Play.count` counts them, by A* over
/// stacks (and, under ebb and flow, each knob's last sense), each move a commit to a knob other than the last one turned.
///
/// What it tries, so what its optimum is a bound over: every count from -12 to +12 when `exhaustive`, so a proof on
/// that range; otherwise, on each knob, the counts that bring the entry the turn lands on (or a pushed one) to 0 or to
/// the negation of one or two other entries of its rod (an overshoot that a later turn, or a fall, takes off), the
/// counts that bring its pointer to a mark it keys or to where it must end, and +-1 as a detour; each only where the
/// rules allow it. Its heuristic is admissible (`h`), so within those counts the optimum is proved.
final class LabSolver {
    let layout: Layout
    let rules: LabRules
    let dealt: [Twist]
    var exhaustive = false
    private(set) var expanded = 0
    private var commuting: [[Twist]: Bool] = [:]

    init(_ layout: Layout, rules: LabRules, dealt: [Twist]) {
        self.layout = layout
        self.rules = rules
        self.dealt = dealt
    }

    struct State: Hashable {
        var stack: [Twist], last: Int?
        /// Under `flip`, each knob's last sense, 0 before its first turn.
        var senses: [Int8] = []
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

    var start: State { State(stack: dealt, last: nil, senses: rules.flip ? Array(repeating: 0, count: layout.rods.count) : []) }

    private func h(_ s: State) -> Int {
        // Each rod whose entries don't sum to 0 needs a turn of its own (a fall only joins entries of one rod, so keeps
        // their sum); and a key at rest, off a mark a ward still to turn needs, a turn of its own too, shared by wards
        // on the same key and mark.
        var net: [Int: Int] = [:]
        for t in s.stack { net[t.rod, default: 0] += t.steps }
        let marks = Set(rules.keys.filter { w, k in
            net[w, default: 0] != 0 && net[k.key, default: 0] == 0
                && LabRules.pointer(k.key, stack: s.stack, dealt: dealt) != k.mark
        }.values)
        return net.values.filter { $0 != 0 }.count + marks.count
    }

    /// The counts tried on `rod` from stack `s`.
    func counts(_ rod: Int, _ stack: [Twist], sense: Int) -> [Int] {
        if exhaustive { return (-12...12).filter { $0 != 0 && allowed(rod, $0, stack, sense) } }
        let mine = stack.filter { $0.rod == rod }.map(\.steps)
        var want: Set<Int> = [0]
        for (i, a) in mine.enumerated() {
            want.insert(-a)
            for (j, b) in mine.enumerated() where j > i { want.insert(-a - b) }
        }
        var out: Set<Int> = []
        // The turn lands on some entry of the rod (worth trying them all, as which one depends on the count) or pushes.
        for base in Set(mine + [0]) {
            for w in want { out.insert(w - base) }
        }
        let p = LabRules.pointer(rod, stack: stack, dealt: dealt)
        for k in rules.keys.values where k.key == rod { out.insert(k.mark - p) }
        out.insert(-dealt.filter { $0.rod == rod }.reduce(0) { $0 + $1.steps } - p)
        for d in [1, -1] { out.insert(d) }
        return out.filter { $0 != 0 && abs($0) <= 12 && allowed(rod, $0, stack, sense) }.sorted()
    }

    private func allowed(_ rod: Int, _ steps: Int, _ stack: [Twist], _ sense: Int) -> Bool {
        rules.room(rod, stack: stack, dealt: dealt, sense: sense).contains(steps)
    }

    func moves(_ s: State) -> [(Twist, State)] {
        var out: [(Twist, State)] = []
        for rod in layout.rods.indices where rod != s.last {
            guard rules.opens(rod, stack: s.stack, dealt: dealt) else { continue }
            for n in counts(rod, s.stack, sense: rules.flip ? Int(s.senses[rod]) : 0) {
                var next = s.stack
                commit(&next, Twist(rod: rod, steps: n))
                var senses = s.senses
                if rules.flip { senses[rod] = n > 0 ? 1 : -1 }
                out.append((Twist(rod: rod, steps: n), State(stack: next, last: rod, senses: senses)))
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

    /// Plain untwisting under the rule: each move takes off a whole entry (its exact inverse lands on it) on a knob the
    /// rule allows; the fewest such moves, or nil when the rule strands it, which is when the level needs more than
    /// untwisting.
    func untwisting() -> Int? {
        var seen: Set<State> = [], level = [start], depth = 0
        while !level.isEmpty {
            var next: [State] = []
            for s in level {
                if s.stack.isEmpty { return depth }
                for i in s.stack.indices {
                    let t = s.stack[i], rod = t.rod
                    guard rod != s.last, rules.opens(rod, stack: s.stack, dealt: dealt),
                          allowed(rod, -t.steps, s.stack, rules.flip ? Int(s.senses[rod]) : 0),
                          landing(s.stack, rod: rod, steps: -t.steps) == i else { continue }
                    var after = s.stack
                    commit(&after, Twist(rod: rod, steps: -t.steps))
                    var senses = s.senses
                    if rules.flip { senses[rod] = t.steps > 0 ? -1 : 1 }
                    let n = State(stack: after, last: rod, senses: senses)
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
        let start = self.start
        return moves(start).compactMap { t, n in
            let after = LabSolver(layout, rules: rules, dealt: dealt)
            after.exhaustive = exhaustive
            return after.solve(from: n, limit: par - 1) != nil ? t : nil
        }
    }

    func solve(from start: State, limit: Int) -> [Twist]? {
        if start.stack.isEmpty { return [] }
        var best: [State: Int] = [start: 0]
        var open: [[State]] = Array(repeating: [], count: limit + 2)
        guard h(start) <= limit else { return nil }
        open[h(start)].append(start)
        var f = h(start)
        while f <= limit {
            guard let s = open[f].popLast() else { f += 1; continue }
            let g = best[s]!
            if s.stack.isEmpty { return [] }
            for (_, n) in moves(s) where g + 1 < best[n] ?? .max {
                best[n] = g + 1
                let fn = g + 1 + h(n)
                if fn <= limit { open[max(fn, f)].append(n) }
            }
        }
        return nil
    }
}
