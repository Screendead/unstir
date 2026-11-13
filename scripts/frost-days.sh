#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/frost-days.sh <from yyyymmdd> <days> [swift]
# Deals each day's daily and prints, per day, its layout, entries, the knobs its frost seizes (`Solver.frost`, "-" on a
# plain day), par and what untwisting takes, and the time the verdict took; with `swift`, only the frost days, as rows
# of `Frost.days`. A summary goes to stderr.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/frost-days
mkdir -p "$out"
if [[ ! -x "$out/frost" ]] || [[ -n "$(find Sources/Twist.swift Sources/Levels.swift UnstirTests/Solver.swift scripts/frost-days/main.swift -newer "$out/frost")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  awk '/^extension Layout/,/^}/' Sources/Levels.swift > "$out/Generator.swift"
  swiftc -O -o "$out/frost" Sources/Twist.swift "$out/SplitMix64.swift" "$out/Generator.swift" UnstirTests/Solver.swift \
    scripts/frost-days/main.swift
fi
"$out/frost" "$@"
