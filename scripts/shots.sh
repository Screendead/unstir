#!/bin/bash
# Usage: scripts/shots.sh [pattern]   Screenshots every harness case (or those whose name matches pattern) into shots/.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle=com.screendead.Unstir

udid=$(xcrun simctl list devices available | grep 'Pro Max (' | head -1 | grep -oE '[0-9A-F-]{36}' || true)
if [[ -z "$udid" ]]; then
  type=$(xcrun simctl list devicetypes | grep 'Pro Max' | head -1 | grep -oE 'com\.apple[^)]+')
  runtime=$(xcrun simctl list runtimes available | grep '^iOS' | tail -1 | grep -oE 'com\.apple\S+$')
  udid=$(xcrun simctl create "Unstir Pro Max" "$type" "$runtime")
fi
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null

scripts/build-ios.sh Debug sim
# Fresh install so the menu shows first-launch progress.
xcrun simctl uninstall "$udid" "$bundle" 2>/dev/null || true
xcrun simctl install "$udid" build/Build/Products/Debug-iphonesimulator/Unstir.app
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 2>/dev/null || true

mkdir -p shots
: > shots/index.txt
settle=6  # the first launch on a fresh install is slow
shot() {  # name description KEY=VALUE...
  local name=$1 desc=$2 vars=()
  shift 2
  echo "$name.png  $desc" >> shots/index.txt
  [[ -n "${pattern:-}" && "$name" != *$pattern* ]] && return
  for kv in "$@"; do vars+=("SIMCTL_CHILD_UNSTIR_$kv"); done
  env ${vars[@]+"${vars[@]}"} xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
  sleep "${hold:-$settle}"
  settle=3
  xcrun simctl io "$udid" screenshot "shots/$name.png" >/dev/null 2>&1
  echo "shot $name"
}
pattern=${1:-}

# The same level-like scrambles (bottom first, three-rod layout) for every picture, one per depth.
depths=("0:+4" "1:+5,2:-4" "0:-6,1:+4,2:-5" "0:+5,2:-6,1:+3,0:-4" "2:-5,0:+4,1:-7,2:+3,0:-6")

shot menu "Menu on first launch: only level 01 unlocked; daily and endless open after level 23."
shot menu-unlocked "Menu with every row unlocked (UNSTIR_UNLOCK)." UNLOCK=1
for picture in grid; do
  for d in 1 2 3 4 5; do
    stack=${depths[$((d - 1))]}
    shot "$picture-d$d" "$picture, depth-$d scramble $stack (rod:steps, 30 degrees per step, bottom first)." \
      PICTURE=$picture STACK="$stack"
  done
done
d2=${depths[1]}
shot grid-d2-right-half "grid depth 2 ($d2), mid-drag: top rod 2 turned back +2 of its 4 steps." STACK="$d2" LIVE=2:+2
shot grid-d2-right-almost "grid depth 2 ($d2), mid-drag: top rod 2 turned back +3.6 of 4 steps." STACK="$d2" LIVE=2:+3.6
shot grid-d2-probe "grid depth 2 ($d2), mid-drag: rod 2 turned +0.4 steps. Dashed ring and start tick: letting go here commits nothing." \
  STACK="$d2" LIVE=2:+0.4
shot grid-d2-wrong-rod "grid depth 2 ($d2), mid-drag: rod 1 turned -2.5 steps out of order (its undo is right, but only after rod 2)." \
  STACK="$d2" LIVE=1:-2.5
shot quad-probe "Level 12 (square), mid-drag: rod 1 turned +0.3 steps. Dashed ring and start tick: letting go here commits nothing." \
  LEVEL=12 LIVE=1:+0.3
shot quad-commit "Level 12 (square), mid-drag: rod 1 turned +2 steps. Solid ring: letting go here commits." LEVEL=12 LIVE=1:+2
# Each layout at its chapter's first and last level, the first two without a replay, then every level with a sunset or city.
for n in 01 04 07 08 09 13 14 18 19 22 23 27 05 11 15 06 10 16; do
  shot "level$n" "Level $n with its full scramble and its note." LEVEL=$n
done
# Mid-solve, where an inversion is on top: the top rod should not read from the still.
shot inversion-L12 "Level 12 part-solved: 0:-2 sits on 3:+7, quieter than the twist it covers." LEVEL=12 STACK=2:-3,0:+4,3:+7,0:-2
shot inversion-L27 "Level 27 part-solved at its first inversion: 4:+3 sits on 5:+6." LEVEL=27 STACK=2:+3,0:-5,5:+6,4:+3
shot daily "Today's daily." MODE=daily
shot endless "Endless, first tank of the run seeded 7." MODE=endless
shot hint-hex "Level 27 (hex, par 14) with a hint: the newest twist that can come off now, ringed, with its arrow." LEVEL=27 HINT=1
shot result "Level 05 result card after a harness solve through the real commit path: two wasted stirs taken back, then the inverse word (+2 over par)." \
  SCREEN=result LEVEL=5
shot result-clean "Level 06 (city) result card after a harness solve with nothing wasted." SCREEN=clean LEVEL=6
for w in 0.4 0.8 1.2; do
  shot "wave-$w" "Level 13 solved through the real commit path, solve wave held at radius $w from the last-turned rod." LEVEL=13 WAVE=$w
done
hold=2 shot open-L03 "Level 03 about a second into its opening replay (clean picture first, then each twist plays forward)." LEVEL=3 OPEN=1
# From launch: the texture lands and ignites, 1 s of clean picture, then 1.4 s of wind-in.
i=0
for h in 0.9 1.6 2.0 3.2; do
  i=$((i + 1))
  hold=$h shot "open-L12-$i" "Level 12 opening, ${h}s after launch: clean picture, then every twist growing together." LEVEL=12 OPEN=1
done
# Nightmare: the menu, each layout's first level and the last, probes on level 12's and level 27's top rods, and a result card.
# The live background is held 3 s in, so the probes compare.
shot menu-nightmare "Menu with nightmare on and every row unlocked." NIGHTMARE=1 UNLOCK=1
for n in 01 09 14 19 23 27; do
  shot "nightmare$n" "Nightmare level $n with its full scramble." NIGHTMARE=1 LEVEL=$n CLOCK=3
done
shot nightmare-probe-short "Nightmare level 12 (square), mid-drag: top rod 3 turned back +3 of its 4 steps, one detent short of the heal." \
  NIGHTMARE=1 LEVEL=12 LIVE=3:+3 CLOCK=3
shot nightmare-probe-heal "Nightmare level 12 (square), mid-drag: top rod 3 turned back all 4 steps, so its seam heals." NIGHTMARE=1 LEVEL=12 LIVE=3:+4 CLOCK=3
shot nightmare-probe-over "Nightmare level 12 (square), mid-drag: top rod 3 turned back 5 steps, one detent past the heal." NIGHTMARE=1 LEVEL=12 LIVE=3:+5 CLOCK=3
# The deepest level's top twist is 2:+2: short, heal and over.
for s in 1 2 3; do
  shot "nightmare27-probe-$s" "Nightmare level 27 (hex, par 28), mid-drag: top rod 2 turned back $s steps; it heals at 2." NIGHTMARE=1 LEVEL=27 LIVE=2:-$s CLOCK=3
done
shot nightmare-result "Nightmare level 05 result card after a harness solve: two wasted stirs taken back, then the inverse word (+2 over par)." \
  NIGHTMARE=1 SCREEN=result LEVEL=5 CLOCK=3
