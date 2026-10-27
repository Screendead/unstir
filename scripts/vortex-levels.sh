#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/vortex-levels.sh search <swirl layout> <depth> <inversions> <min swirls> <from seed> <to seed>
#        scripts/vortex-levels.sh check <swirl layout> <scramble>
# Prints a TSV line per scramble the frozen generator deals on a swirl layout whose par is its entry count: seed,
# entries, hidden, hidden swirls, swirls, entries above the top swirl, the top swirl's undo sign, swirl sizes from the
# top, the most entries removable at once, "hub" where hex's hub and the swirl are removable together, optimum,
# untwisting, ms, scramble.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/vortex-levels
mkdir -p "$out"
if [[ ! -x "$out/gen" ]] || [[ -n "$(find Sources/Twist.swift Sources/Levels.swift UnstirTests/Solver.swift scripts/vortex-levels/main.swift -newer "$out/gen")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  awk '/^extension Layout/,/^}/' Sources/Levels.swift > "$out/Generator.swift"
  swiftc -O -o "$out/gen" Sources/Twist.swift "$out/SplitMix64.swift" "$out/Generator.swift" UnstirTests/Solver.swift \
    scripts/vortex-levels/main.swift
fi
"$out/gen" "$@"
