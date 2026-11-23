#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/slope-lab.sh render <out.png> [key=value ...]
#        scripts/slope-lab.sh bench x [key=value ...]
# Draws the slope's ground (Sources/Slope.metal, laid out by Sources/Slope.swift) on the Mac's GPU with a stand-in
# pebble on each level's seat, or times one pass of it. The camera is the overview unless ledge=<k>, y=<depth>,
# at=top or at=bottom dives, zoom=<z> sets the zoom and between=<share> stops that far from the overview to the dive.
# w, h (440 x 956 points), scale (2), type (the body size over its default, 1), t (seconds, 3), near (1), level, glint
# and clear (0) are the shader's; lit=<k> lights the pebbles down to ledge k and pebbles=0 draws none.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/slope-lab
mkdir -p "$out"
if [[ ! -x "$out/lab" ]] || [[ -n "$(find Sources/Slope.swift scripts/slope-lab/main.swift -newer "$out/lab")" ]]; then
  swiftc -O -o "$out/lab" Sources/Slope.swift scripts/slope-lab/main.swift
fi
"$out/lab" "$@"
