#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/escapement-art.sh render <a|b|c|today> <problem> <out.png> [side]
#        scripts/escapement-art.sh check <a|b|c|today> <problem> <layout>
#        scripts/escapement-art.sh bench <a|b|c|today> <problem>
# Draws one of Escapement's plate sketches (Sources/EscapementArt*.swift; today is the shipped engine-turning) on the
# Mac with CoreGraphics, measures how a 30° step shows in each of a layout's cores as the plate's test does, or times
# its geometry and its raster at the Pro Max glass's size, five runs' mean.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/escapement-art
mkdir -p "$out"
if [[ ! -x $out/art || -n "$(find Sources/EscapementArt*.swift Sources/Twist.swift Sources/Levels.swift scripts/escapement-art/main.swift -newer $out/art)" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  swiftc -O -o "$out/art" Sources/Twist.swift "$out/SplitMix64.swift" Sources/EscapementArt*.swift scripts/escapement-art/main.swift
fi
"$out/art" "$@"
