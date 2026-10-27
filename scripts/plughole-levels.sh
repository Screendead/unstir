#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/plughole-levels.sh table                     measures every plughole level in Levels.swift
#        scripts/plughole-levels.sh check <layout> <scramble>  measures one scramble
#        scripts/plughole-levels.sh search <layout> <depth> <inversions> <from seed> <to seed>
# Prints a TSV line per level or scramble: level, layout, entries, optimum, untwisting, hidden, whole as dealt, right
# moves per step, forced steps, scramble. `search` deals seeded scrambles with the frozen generator and keeps those whose optimum is
# their entry count. See scripts/plughole-levels/main.swift for what each measure means.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/plughole-levels
mkdir -p "$out"
if [[ ! -x "$out/measure" ]] || [[ -n "$(find Sources/Twist.swift Sources/Levels.swift UnstirTests/Solver.swift scripts/plughole-levels/main.swift -newer "$out/measure")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  awk '/^extension Layout/,/^}/' Sources/Levels.swift > "$out/Generator.swift"
  swiftc -O -o "$out/measure" Sources/Twist.swift "$out/SplitMix64.swift" "$out/Generator.swift" \
    UnstirTests/Solver.swift scripts/plughole-levels/main.swift
fi
if [[ "${1:-}" == table ]]; then
  # The table's rows, from `static let plughole` to the end of its array.
  awk '/static let plughole/,/\] as \[/' Sources/Levels.swift | grep -oE '^\s+\(\.[a-z]+, "[^"]*"' |
    sed -E 's/^ *\(\.([a-z]+), "([^"]*)"/\1 \2/' | "$out/measure" table
else
  "$out/measure" "$@"
fi
