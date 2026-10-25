#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/escapement.sh check <layout> <scramble> <clocks> [span] [quick]
#        scripts/escapement.sh search <layout> <clocks> <heals a-b> <owed a-b> <from seed> <to seed> -
#        scripts/escapement.sh build <layout> <clocks> <moves> <waits a-b> <from seed> <to seed>
#        scripts/escapement.sh book scripts/escapement/problems.tsv
# Escapement's prover for the problem book's draft: every move ticks each running clock once, and a tick that pushes
# loses. check prints the optimum and its proof, the lines at par and each first move's fate; search deals problems
# whose optimum is what the clocks owe, build deals them backwards from a line, and book proves every problem in the
# draft book (docs/escapement-problems.md). ESC_RULE=lab plays the lab's re-grab instead of Jack's final tick.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/escapement
mkdir -p "$out"
if [[ ! -x "$out/prove" ]] || [[ -n "$(find Sources/Twist.swift Sources/Levels.swift scripts/escapement/main.swift -newer "$out/prove")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  swiftc -O -o "$out/prove" Sources/Twist.swift "$out/SplitMix64.swift" scripts/escapement/main.swift
fi
"$out/prove" "$@"
