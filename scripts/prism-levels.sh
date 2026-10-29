#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/prism-levels.sh table                              measures every Prism specimen in Pack.swift
#        scripts/prism-levels.sh check <layout> <masks> <scramble>  measures one, e.g. tri 0:r,1:c,2:w 2:+3,0:+4,1:-3
#        scripts/prism-levels.sh search <layout> <depth> <palette> <from seed> <to seed>
# Prints a TSV line per specimen or deal: level, layout, masks, entries, optimum, untwisting, free under the masks and
# read white, blocked knobs, right moves per step, forced steps, shader cost, ghost and triple shares, scramble. `search`
# deals seeded scrambles over one white bottom rod, every other rod a mask from the palette's letters (or the masks
# given, slot:letter pairs), and keeps those whose optimum is their depth. See scripts/prism-levels/main.swift.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/prism-levels
mkdir -p "$out"
if [[ ! -x "$out/measure" ]] || [[ -n "$(find Sources/Twist.swift Sources/Levels.swift UnstirTests/Solver.swift scripts/prism-levels/main.swift -newer "$out/measure")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  swiftc -O -o "$out/measure" Sources/Twist.swift "$out/SplitMix64.swift" UnstirTests/Solver.swift scripts/prism-levels/main.swift
fi
if [[ "${1:-}" == table ]]; then
  # The table's rows, from `static let prism` to the end of its array: (layout, "masks", "scramble").
  awk '/static let prism: \[Level\]/,/\]\.enumerated/' Sources/Pack.swift |
    grep -oE '\(\.?[A-Za-z.]*[a-z]+, "[^"]*", "[^"]*"' |
    sed -E 's/^\((Layout)?\.([a-z]+), "([^"]*)", "([^"]*)"/\2 \3 \4/' | "$out/measure" table
else
  "$out/measure" "$@"
fi
