#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/first-stir-lab.sh <scene 1-5> <out.png> [side px]
# Draws a Dawn After scene on the Mac: held back, played, and where the two differ over the layout's cores and knobs.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/first-stir-lab
mkdir -p "$out"
sources=(Sources/Twist.swift Sources/Levels.swift Sources/Pictures.swift Sources/FirstStirDawn.swift scripts/first-stir-lab/main.swift)
if [[ ! -x "$out/lab" ]] || [[ -n "$(find "${sources[@]}" -newer "$out/lab")" ]]; then
  # SplitMix64, `neon` and the hex colours cut out of files that need the app.
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  { echo 'import SwiftUI'; awk '/^func neon/,/^}/' Sources/Pictures.swift
    echo 'extension Color { init(_ hex: UInt32) { self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255) } }'
  } > "$out/Shim.swift"
  swiftc -O -swift-version 5 -o "$out/lab" Sources/Twist.swift "$out/SplitMix64.swift" "$out/Shim.swift" Sources/FirstStirDawn.swift \
    scripts/first-stir-lab/main.swift
fi
"$out/lab" "$@"
