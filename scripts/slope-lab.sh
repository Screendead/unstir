#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/slope-lab.sh render <out.png> [key=value ...]
#        scripts/slope-lab.sh bench x [key=value ...]
# Draws the slope's ground (Sources/Slope.metal, laid out by Sources/SlopeGeometry.swift) on the Mac's GPU with a
# stand-in pebble on each seat, or times one pass of it; probe prints the brightest the ground gets where words go.
# The camera is the overview unless ledge=<n> holds that ledge at the screen's middle, or at=top or at=bottom is an end
# of the dive's travel; z=<0 to 1> is the zoom. w, h (440 x 956 points), scale (2), type=ax (the largest sizes'
# column), column=pack (a pack's own), t (seconds, 3), near, motes (1), level, glint, clear (0), light (1), rock (the
# lone terrace's), upper=1 (a second terrace over it), paper (0 to 1) and hollow=1 (the inside of a hollow) are the shader's; lit=<n> lights the pebbles
# down to ledge n and pebbles=0 draws none; zone=rock probes the rock's heart. The menu's eggs: lift=<pt> pulls the
# camera past the surface (or, negative, the foot), night, deep, reveal, calm, meteors (0 to 1), moon (1 new to -1 full),
# side, skim=<age,x,hop,count> and seam=<tiers at par, e.g. 0,2>.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/slope-lab
mkdir -p "$out"
if [[ ! -x "$out/lab" ]] || [[ -n "$(find Sources/SlopeGeometry.swift scripts/slope-lab/main.swift -newer "$out/lab")" ]]; then
  swiftc -O -o "$out/lab" Sources/SlopeGeometry.swift scripts/slope-lab/main.swift
fi
"$out/lab" "$@"
