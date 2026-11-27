#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/prism-levels/pools.sh <dir> [seeds per pool, 30 by default]
# Writes the pools trays 6 to 15 are picked from, one (layout, depth, palette) a file, then:
#   scripts/prism-levels/pick.py --deep <dir>
# Each palette deals from its own seeds, as a two-letter palette's rng draws alike whatever its letters. Four searches
# run at once at utility priority; the mixed palettes on hex take the longest (tens of seconds a seed).
set -euo pipefail
cd "$(dirname "$0")/../.."
dir=$1 n=${2:-30}
mkdir -p "$dir"
scripts/prism-levels.sh check tri 0:r,1:c,2:w 2:+3,0:+4,1:-3 > /dev/null
from() { case $1 in rc) echo 1 ;; gm) echo 1001 ;; by) echo 2001 ;; rgb) echo 3001 ;; rcgb) echo 4001 ;; cmy) echo 5001 ;; *) echo 6001 ;; esac; }
scripts/prism-levels/pick.py --specs | while read -r layout depth palette; do
  f="$dir/$layout-$depth-$palette.tsv"
  [[ -s "$f" ]] && continue
  start=$(from "$palette")
  echo "taskpolicy -c utility build/prism-levels/measure search $layout $depth $palette $start $((start + n - 1)) > $f.part && mv $f.part $f"
done | xargs -P 4 -I{} bash -c {}
