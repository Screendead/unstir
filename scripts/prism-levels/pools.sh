#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/prism-levels/pools.sh <dir> [seeds per pool, 30 by default]
#        scripts/prism-levels/pools.sh <dir> <n> more    tops up each pool with under three readable rows (`pick.py
#                                                        --thin`) with the next 2n seeds, once a pool has its first n
# Writes the pools trays 6 to 15 are picked from, one (layout, depth, palette) a file, then:
#   scripts/prism-levels/pick.py --deep <dir>
# Every deal holds at most three stirs a rod (PRISM_ROD_CAP, unless set). Each palette deals from its own seeds, as a two-letter palette's rng draws alike whatever its letters. Four searches
# run at once at utility priority (POOL_JOBS sets how many); the mixed palettes on hex take the longest (tens of seconds a seed).
set -euo pipefail
cd "$(dirname "$0")/../.."
dir=$1 n=${2:-30}
export PRISM_ROD_CAP=${PRISM_ROD_CAP:-3}
mkdir -p "$dir"
scripts/prism-levels.sh check tri 0:r,1:c,2:w 2:+3,0:+4,1:-3 > /dev/null
from() { case $1 in rc) echo 1 ;; gm) echo 1001 ;; by) echo 2001 ;; rgb) echo 3001 ;; rcgb) echo 4001 ;; cmy) echo 5001 ;; *) echo 6001 ;; esac; }
if [[ "${3:-}" == more ]]; then
  scripts/prism-levels/pick.py --thin "$dir" | while read -r layout depth palette; do
    f="$dir/$layout-$depth-$palette.tsv"
    start=$(($(from "$palette") + n))
    echo "taskpolicy -c utility build/prism-levels/measure search $layout $depth $palette $start $((start + 2 * n - 1)) | tail -n +2 > $f.more && cat $f.more >> $f"
  done | xargs -P "${POOL_JOBS:-4}" -I{} bash -c {}
  exit
fi
scripts/prism-levels/pick.py --specs | while read -r layout depth palette; do
  f="$dir/$layout-$depth-$palette.tsv"
  [[ -s "$f" ]] && continue
  start=$(from "$palette")
  echo "taskpolicy -c utility build/prism-levels/measure search $layout $depth $palette $start $((start + n - 1)) > $f.part && mv $f.part $f"
done | xargs -P "${POOL_JOBS:-4}" -I{} bash -c {}
