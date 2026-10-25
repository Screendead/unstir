#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/picture-lab.sh render <picture> <out.png> [seed] [t] [side px] [layout stack]
#        scripts/picture-lab.sh bench <picture>...
# Renders a live picture on the Mac's GPU, stirred by a stack if given, or times its fill against a stack entry.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/picture-lab
mkdir -p "$out"
sources=(Sources/Twist.swift Sources/Levels.swift Sources/LivePictures.swift Sources/VortexPictures.swift scripts/picture-lab/main.swift)
if [[ ! -x "$out/lab" ]] || [[ -n "$(find "${sources[@]}" -newer "$out/lab")" ]]; then
  # The glass's cells and SplitMix64 cut out of files that need the app; Picture is a namespace here.
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  { echo 'import Foundation'; echo 'enum Picture {}'; echo 'extension Picture {'
    awk '/static func cells/,/^    }$/' Sources/LivePictures.swift; echo '}'; } > "$out/Cells.swift"
  swiftc -O -o "$out/lab" Sources/Twist.swift "$out/SplitMix64.swift" "$out/Cells.swift" Sources/VortexPictures.swift \
    scripts/picture-lab/main.swift
fi
"$out/lab" "$@"
