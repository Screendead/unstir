#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/escapement/pools-31-90.sh [out dir]
# Deals again every pool that scripts/escapement/plan-31-90.txt picks from, each with the seeds and cap it was dealt
# with, into build/pools unless given; then `scripts/escapement/pick.py build/pools scripts/escapement/plan-31-90.txt 31`
# picks problems 31 to 90 again. Hours on one core: run it in the background, under the Mac's load level.
set -euo pipefail
cd "$(dirname "$0")/../.."
out=${1:-build/pools}
p() { keep=$1 seeds=$2; shift 2; ESC_KEEP=$keep scripts/escapement/pools.sh "$out" "$seeds" "$@"; }
w() { keep=$1 seeds=$2; shift 2; ESC_WAITS=2-4 ESC_KEEP=$keep scripts/escapement/pools.sh "$out" "$seeds" "$@"; }
# A deeper stack shears the plate past reading, so the slots re-dealt for it (2026-11-27) keep to 26 entries.
e() { keep=$1 seeds=$2; shift 2; ESC_MOST=26 ESC_KEEP=$keep scripts/escapement/pools.sh "$out" "$seeds" "$@"; }
p 400 30000 pent 0+ 6 7 8
p 3000 30000 pent 0+ 17 19 21
p 400 30000 hex 1+ 7 8
p 3000 30000 hex 1+ 9
p 400 5000 pent 0+,2+ 8
p 400 8000 hex 1+,3+ 9 10 11
p 400 8000 hex 1+,2+ 9
p 400 30000 hex 1+,2+ 12
p 400 8000 pent 0+,1- 9 12 13
p 400 8000 hex 1+,3- 10 12
p 400 5000 hex 1+,3+,5+ 9
p 400 8000 hex 1+,2+,3+ 10
p 400 30000 hex 1- 11 15 19
p 3000 30000 hex 1- 14
p 400 8000 hex 1-,2- 12
p 400 20000 hex 1-,3- 13
w 3000 30000 hex 1+ 13 15 17
w 400 60000 hex 1+ 18
w 400 60000 pent 0+ 14 16
e 3000 400000 hex 1+ 18 19 20
e 3000 400000 hex 1- 17 18 19 20
e 3000 200000 hex 1+,2+ 11 12
e 3000 200000 hex 1+,2- 11 12
e 3000 200000 hex 1-,2- 12
e 3000 200000 hex 1+,2-,3+ 10
e 3000 200000 hex 1+,2+,3+ 10
e 3000 100000 hex 1+,3+,5+ 11 12
