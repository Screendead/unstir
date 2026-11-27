// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// The fifth chapter's candidate rules, Debug prototypes only (`UNSTIR_LAB`): each a limit on which turns a level
/// allows, never on what a turn does to the picture, so every merge is `Array.commit`'s, the shader is untouched and
/// `scripts/solve.sh lab` proves each level's optimum. A knob's pointer is the player's own turns of it, upright as
/// dealt (`LevelView.turned`): what the stack holds of its rod less what was dealt.
struct LabRules: Hashable, Sendable {
    /// Keys: warded knob -> its key and the key's mark. A ward turns only while its key's pointer stands on the mark.
    var keys: [Int: Key] = [:]
    /// The keel: every knob's pointer summed, the tank's list, never passes this many steps either way.
    var keel: Int?
    /// Ebb and flow: each knob turns the other way from its own last turn.
    var flip = false

    struct Key: Hashable, Sendable {
        var key: Int, mark: Int
    }

    var isEmpty: Bool { keys.isEmpty && keel == nil && !flip }

    /// "keys=1:0@3,2:1@-2 keel=4 flip", in any order: knob 1 opens while knob 0 stands at +3 steps, knob 2 while knob 1
    /// stands at -2; the list kept within 4 steps; every knob alternating. Nil on a word it doesn't know.
    init?(_ s: String) {
        for word in s.split(whereSeparator: { $0 == " " || $0 == ";" }) {
            if word == "flip" {
                flip = true
            } else if word.hasPrefix("keel="), let n = Int(word.dropFirst(5)), n > 0 {
                keel = n
            } else if word.hasPrefix("keys=") {
                for part in word.dropFirst(5).split(separator: ",") {
                    let f = part.split(whereSeparator: { ":@".contains($0) })
                    guard f.count == 3, let w = Int(f[0]), let k = Int(f[1]), let m = Int(f[2]), w != k else { return nil }
                    keys[w] = Key(key: k, mark: m)
                }
            } else {
                return nil
            }
        }
    }

    init() {}

    static func pointer(_ rod: Int, stack: [Twist], dealt: [Twist]) -> Int {
        stack.reduce(0) { $0 + ($1.rod == rod ? $1.steps : 0) } - dealt.reduce(0) { $0 + ($1.rod == rod ? $1.steps : 0) }
    }

    /// The tank's list: every pointer summed.
    static func list(stack: [Twist], dealt: [Twist]) -> Int {
        stack.reduce(0) { $0 + $1.steps } - dealt.reduce(0) { $0 + $1.steps }
    }

    /// Whether knob `rod` may be taken up at all: a ward only while its key stands on the mark, a whole turn either way
    /// being the same place on the dial.
    func opens(_ rod: Int, stack: [Twist], dealt: [Twist]) -> Bool {
        guard let w = keys[rod] else { return true }
        return (Self.pointer(w.key, stack: stack, dealt: dealt) - w.mark) % 12 == 0
    }

    /// The turns of `rod` allowed, in steps, from a stack: the keel's room either way, and under ebb and flow only the
    /// sense opposite `sense`, the knob's last move (+1, -1, or 0 before its first), counted with `joined`, what the
    /// move in hand has turned it already.
    func room(_ rod: Int, stack: [Twist], dealt: [Twist], sense: Int, joined: Int = 0) -> ClosedRange<Int> {
        var low = Int.min / 2, high = Int.max / 2
        if let keel {
            let list = Self.list(stack: stack, dealt: dealt)
            low = -keel - list
            high = keel - list
        }
        if flip, sense > 0 { high = min(high, -joined) }
        if flip, sense < 0 { low = max(low, -joined) }
        return low...max(low, high)
    }
}
