#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/maelstrom-levels.sh table                               measures every maelstrom level in Levels.swift
#        scripts/maelstrom-levels.sh check <layout> <scramble> <seized>  measures one
#        scripts/maelstrom-levels.sh search <layout> <one|neighbours|twoapart|seized set> <lo> <hi> <from> <to>
# Prints a TSV line per level: the optimum, what untwisting takes, every rule of thumb's fewest and most moves over its
# ties, whether it needs a plan, the decoys on the optimal line, the turns, and the park line's longest run without a
# turn against its bound. `search` deals seeds as the first maelstrom search did and keeps those that need a plan, with
# no detour, whose park line keeps the tank turning past quad. See scripts/maelstrom-levels/main.swift.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/maelstrom-levels
mkdir -p "$out"
if [[ ! -x "$out/measure" ]] || [[ -n "$(find Sources/Twist.swift Sources/Levels.swift UnstirTests/Solver.swift scripts/maelstrom-levels/main.swift -newer "$out/measure")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  awk '/^extension Layout/,/^}/' Sources/Levels.swift > "$out/Generator.swift"
  swiftc -O -o "$out/measure" Sources/Twist.swift "$out/SplitMix64.swift" "$out/Generator.swift" \
    UnstirTests/Solver.swift scripts/maelstrom-levels/main.swift
fi
if [[ "${1:-}" == table ]]; then
  # The table's rows, from `static let maelstrom` to the end of its array: layout, scramble, seized.
  awk '/static let maelstrom/,/\] as \[/' Sources/Levels.swift | grep -oE '^\s+\(\.[a-z]+, "[^"]*", \[[0-9,]*\]' |
    sed -E 's/^ *\(\.([a-z]+), "([^"]*)", \[([0-9,]*)\]/\1 \2 \3/' | "$out/measure" table
else
  "$out/measure" "$@"
fi
