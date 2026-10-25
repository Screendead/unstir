#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/vortex-levels/pools.sh <dir>
# Writes the pools vortex's levels were picked from, one band per file, then picks them:
#   scripts/vortex-levels/pick.py <dir>
# Takes a few minutes on 8 cores, most of it hex.
set -euo pipefail
cd "$(dirname "$0")/../.."
dir=$1
mkdir -p "$dir"
scripts/vortex-levels.sh check quadSwirl 0:+3,4:+4 > /dev/null
gen=build/vortex-levels/gen
band() { "$gen" search "$1" "$2" "$3" "$4" 1 "$5" > "$dir/$1-$2-$3.tsv"; }
for d in 3 4 5 6 7 8 9; do for i in 0 1 2; do band quadSwirl $d $i 1 1500 & done; done; wait
for d in 4 5 6 7 8; do for i in 0 1 2 3; do band triSwirl $d $i 1 1500 & done; done; wait
for d in 6 7 8 9 10 11 12; do for i in 1 2 3 4; do band eyeSwirl $d $i 2 1500 & done; done; wait
for d in 8 10 12 13 14 16 18; do for i in 2 3 4 5 6; do band pentSwirl $d $i 2 800 & done; wait; done
for d in 12 14 16 18 20 22 24; do for i in 3 4 5 6 7 8; do band hexSwirl $d $i 3 400 & done; wait; done
