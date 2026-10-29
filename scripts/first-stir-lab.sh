#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/first-stir-lab.sh <scene 1-15> <out.png> [side px]
# Draws a scene of Dawn After, the Rescue or the Flood on the Mac: held back, played, and where the two differ over the layout's cores and knobs.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/first-stir-lab
mkdir -p "$out"
sources=(Sources/Twist.swift Sources/Levels.swift Sources/Pictures.swift Sources/StoryScene.swift Sources/FirstStirDawn.swift
         Sources/FirstStirRescue.swift Sources/FirstStirFlood.swift scripts/first-stir-lab/main.swift)
if [[ ! -x "$out/lab" ]] || [[ -n "$(find "${sources[@]}" -newer "$out/lab")" ]]; then
  # SplitMix64, `neon`, the hex colours, the scene protocol and `Tone` cut out of files that need the app, and each
  # chapter's levels left out.
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  { echo 'import SwiftUI'; awk '/^func neon/,/^}/' Sources/Pictures.swift
    echo 'extension Color { init(_ hex: UInt32) { self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255) } }'
    echo 'enum Harbour { static let line = 0.0075 }'
    awk '/^protocol StoryScene/,/^}/' Sources/StoryScene.swift
    awk '/^extension (Dawn|Rescue|Flood): StoryScene/' Sources/StoryScene.swift
    echo 'extension StoryScene { func drawLive(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {}; func drawOver(_ ctx: GraphicsContext, r: CGFloat, minutes: Double) {} }'
    awk '/^struct Tone/,/^}/' Sources/StoryScene.swift
  } > "$out/Shim.swift"
  for f in FirstStirDawn FirstStirRescue FirstStirFlood; do
    awk '/^extension Level \{/{skip=1} !skip{print} skip&&/^}/{skip=0}' "Sources/$f.swift" > "$out/$f.swift"
  done
  swiftc -O -swift-version 5 -o "$out/lab" Sources/Twist.swift "$out/SplitMix64.swift" "$out/Shim.swift" "$out/FirstStirDawn.swift" \
    "$out/FirstStirRescue.swift" "$out/FirstStirFlood.swift" scripts/first-stir-lab/main.swift
fi
"$out/lab" "$@"
