#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/lens-panels.sh render <panel> <out.png> [side px] [layout lenses stack]
#        scripts/lens-panels.sh time [side px] [panel...]
#        scripts/lens-panels.sh check <panel> <layout> [lens slots, comma-separated]
# Draws one of Lens's halftone panels (Halftone.swift, LensArt.swift) on the Mac as the app bakes it, stirred by a stack
# if given; times each panel's bake at a size; or checks that every step of every rod of a layout changes what shows
# in its core, as testEveryStepMovesContrastingPixelsOnTheHalftone does for the test panel.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/lens-panels
mkdir -p "$out"
sources=(Sources/Twist.swift Sources/Halftone.swift Sources/LensArt*.swift scripts/lens-panels/main.swift)
if [[ ! -x "$out/panels" ]] || [[ -n "$(find "${sources[@]}" -newer "$out/panels")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  swiftc -O -o "$out/panels" "${sources[@]}" "$out/SplitMix64.swift"
fi
"$out/panels" "$@"
