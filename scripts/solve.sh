#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/solve.sh <layout> <scramble> [seized knobs, comma-separated]
# Prints the optimum, the park rule's count under each reading, the no-lookahead player's count, and the optimal moves.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/solve
mkdir -p "$out"
if [[ ! -x "$out/solve" ]] || [[ -n "$(find Sources/Twist.swift Sources/Levels.swift UnstirTests/Solver.swift scripts/solve/main.swift -newer "$out/solve")" ]]; then
  # Tank.samples needs SplitMix64, and the rest of Levels.swift needs the app.
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  swiftc -O -o "$out/solve" Sources/Twist.swift "$out/SplitMix64.swift" UnstirTests/Solver.swift scripts/solve/main.swift
fi
"$out/solve" "$@"
