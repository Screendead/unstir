#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/prism-plates.sh render <plate> <out.png> [side px] [layout]
#        scripts/prism-plates.sh check [plate...]
# Draws one of Prism's engravings (Engraving.swift) white on black on the Mac, with a layout's cores if given, or checks
# every plate against every layout: the share of each core lit, and the share of that light a 30° step moves.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/prism-plates
mkdir -p "$out"
if [[ ! -x "$out/plates" ]] || [[ -n "$(find Sources/Twist.swift Sources/Engraving.swift scripts/prism-plates/main.swift -newer "$out/plates")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  swiftc -O -o "$out/plates" Sources/Twist.swift Sources/Engraving.swift "$out/SplitMix64.swift" scripts/prism-plates/main.swift
fi
"$out/plates" "$@"
