#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/shots.sh [pattern]   Screenshots every harness case (or those whose name matches pattern) into shots/.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle=com.screendead.Unstir

# UNSTIR_SIM=<udid> picks the simulator; otherwise the first Pro Max, made if there is none.
udid=${UNSTIR_SIM:-$(xcrun simctl list devices available | grep 'Pro Max (' | head -1 | grep -oE '[0-9A-F-]{36}' || true)}
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

shot menu "Menu on first launch: only level 01 unlocked, whirlpool and maelstrom locked; daily and endless open after level 23."
shot menu-unlocked "Menu with every row unlocked (UNSTIR_UNLOCK)." UNLOCK=1
# The tier strip and its gates. UNSTIR_BESTS registers bests for the one launch: a digit per level, that many over par.
par27=$(printf '0%.0s' {1..27})
some=00001000000200000100  # whirlpool 01 to 20 played, 17 of them at par
shot menu-whirlpool-locked "Menu on first launch, looking at whirlpool: locked, its rows dimmed, no plughole tick lit." TIER=whirlpool
shot menu-whirlpool-open "Menu on whirlpool, opened by every plughole tank at par: its level 01 playable, maelstrom still locked." \
  TIER=whirlpool BESTS=plughole:$par27
shot menu-maelstrom-locked "Menu looking at maelstrom, 17 of whirlpool's 27 at par: ticks 01 to 20 lit but 05, 12 and 18 (over par)." \
  TIER=maelstrom BESTS=plughole:$par27,whirlpool:$some
shot menu-maelstrom "Menu on maelstrom with every row unlocked (UNSTIR_UNLOCK)." TIER=maelstrom UNLOCK=1
shot menu-mid-switch "Menu mid-switch: whirlpool's list unstirring into place, held 0.4 turns short and a third faded (UNSTIR_TIERSPIN)." \
  TIER=whirlpool BESTS=plughole:$par27 TIERSPIN=-2.5:0.33
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
# A drag's own count: a lit segment per step from where the stir began, and the signed count off the finger. UNSTIR_TOUCH
# is where the finger went down (tank units), carried round by the turn; alone, a finger just down and not yet moved.
shot count-tri-plus3 "Level 01 (tri), finger down at the top of rod 0 and carried +3 steps round to its right: three segments clockwise from the notch, +3 to the left." \
  LEVEL=1 LIVE=0:+3 TOUCH=0,-0.8
shot count-quad-minus2 "Level 12 (square), finger down below rod 1 and carried -2 steps round: two segments anticlockwise from the notch, -2 up and left, off the finger." \
  LEVEL=12 LIVE=1:-2 TOUCH=0.354,0.7
shot count-let-go "Level 12 (square), rod 1 just let go at -2: its stir is still open, so the arc and count stay, faint." LEVEL=12 TURNED=1:-2
shot count-regrab "Level 12 (square), rod 1 let go at -2, grabbed again and turned -1 more: the count carries on to -3, the notch where this drag began." \
  LEVEL=12 TURNED=1:-2 LIVE=1:-1 TOUCH=0.354,0.7
shot grab-grid "Level 12 (square), a finger just down deep in rod 0, not yet moved: its disc and knob lit." LEVEL=12 TOUCH=0.4,-0.4
shot grab-overlap-grid "Level 12 (square), a finger just down where rods 0 and 1 overlap, not yet moved: both lit dimly until the motion picks one." \
  LEVEL=12 TOUCH=0.6,0
# Each layout at its chapter's first and last level, the first two without a replay, then every level with a sunset or city.
for n in 01 04 07 08 09 13 14 18 19 22 23 27 05 11 15 06 10 16; do
  shot "level$n" "Level $n with its full scramble and its note." LEVEL=$n
done
# Mid-solve, where an inversion is on top: the top rod should not read from the still.
shot inversion-L12 "Level 12 part-solved: 0:-2 sits on 3:+7, quieter than the twist it covers." LEVEL=12 STACK=2:-3,0:+4,3:+7,0:-2
shot inversion-L27 "Level 27 part-solved at its first inversion: 4:+3 sits on 5:+6." LEVEL=27 STACK=2:+3,0:-5,5:+6,4:+3
shot daily "Today's daily." MODE=daily
shot endless "Endless, first tank of the run seeded 7." MODE=endless
# UNSTIR_BRIM sets the notches endless opens with, for that launch only.
shot endless-brim "Endless, first tank, opened with 5 of the brim's 8 notches: the brim and the tank where moves and par were, no undo or reset." \
  MODE=endless BRIM=5
shot endless-cleared "Endless, first tank opened at 5 notches and cleared by the harness after two wasted stirs (2 notches) and five heals: the card shows the brim at 2." \
  SCREEN=result MODE=endless BRIM=5
shot endless-spilled "Endless, first tank opened at 7 notches, then rod 1 turned +1, which pushes: the brim spills, and the card shows tanks cleared and the best." \
  MODE=endless BRIM=7 TURNED=1:1
shot undo-refill "Level 12 opened on a new day with 6 undos banked: the bank refills to 8, and a +2 shows over the count, held 1 s after the opening (none here: a still launch)." \
  LEVEL=12 UNDOS=6 TODAY=2026-10-01 CLOCK=1
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
# Whirlpool: the menu, each layout's first level and the last (all glass), probes on level 12's and level 27's top rods,
# a result card, then each other picture at its deepest level and, on maelstrom, each twin. The live background is held
# 3 s in, so the probes compare; level 12 is marbling, so its probes are pinned to the glass.
shot menu-whirlpool "Menu on whirlpool with every row unlocked." TIER=whirlpool UNLOCK=1
for n in 01 09 14 19 23 27; do
  shot "whirlpool$n" "Whirlpool level $n with its full scramble." TIER=whirlpool LEVEL=$n CLOCK=3
done
shot whirlpool-probe-short "Whirlpool level 12 (square) on the glass, mid-drag: top rod 3 turned back +3 of its 4 steps, one detent short of the heal." \
  TIER=whirlpool LEVEL=12 PICTURE=glass LIVE=3:+3 CLOCK=3
shot whirlpool-probe-heal "Whirlpool level 12 (square) on the glass, mid-drag: top rod 3 turned back all 4 steps, so its seam heals." \
  TIER=whirlpool LEVEL=12 PICTURE=glass LIVE=3:+4 CLOCK=3
shot whirlpool-probe-over "Whirlpool level 12 (square) on the glass, mid-drag: top rod 3 turned back 5 steps, one detent past the heal." \
  TIER=whirlpool LEVEL=12 PICTURE=glass LIVE=3:+5 CLOCK=3
# The deepest level's top twist is 2:+2: short, heal and over.
for s in 1 2 3; do
  shot "whirlpool27-probe-$s" "Whirlpool level 27 (hex, par 28), mid-drag: top rod 2 turned back $s steps; it heals at 2." TIER=whirlpool LEVEL=27 LIVE=2:-$s CLOCK=3
done
shot whirlpool-grab-neurons "Whirlpool 20 (pentagon, neurons), a finger just down deep in rod 0: its disc and knob lit over the web." \
  TIER=whirlpool LEVEL=20 TOUCH=0.05,-0.62 CLOCK=3
shot whirlpool-grab-overlap-neurons "Whirlpool 20 (pentagon, neurons), a finger just down where rods 0 and 1 overlap: both lit dimly." \
  TIER=whirlpool LEVEL=20 TOUCH=0.266,-0.366 CLOCK=3
shot whirlpool-grab-marbling "Whirlpool 25 (hex, marbling), a finger just down deep in rod 1: its disc and knob lit." \
  TIER=whirlpool LEVEL=25 TOUCH=0.05,-0.6 CLOCK=3
shot whirlpool-grab-overlap-marbling "Whirlpool 25 (hex, marbling), a finger just down where rods 1 and 2 overlap, clear of the hub: both lit dimly." \
  TIER=whirlpool LEVEL=25 TOUCH=0.2425,-0.42 CLOCK=3
shot whirlpool-count-marbling "Whirlpool 22 (pentagon, marbling), finger down below rod 2 and carried +4 steps round: four segments, +4 off the finger." \
  TIER=whirlpool LEVEL=22 LIVE=2:+4 TOUCH=0.329,0.753 CLOCK=3
shot whirlpool-count-hex-below "Whirlpool 25 (hex, marbling), finger down to the lower right of rod 4 and carried +2 steps round to just under it: +2 swung off the hub's knob straight above." \
  TIER=whirlpool LEVEL=25 LIVE=4:+2 TOUCH=0.2165,0.685 CLOCK=3
shot whirlpool-result "Whirlpool level 05 result card after a harness solve: two wasted stirs taken back, then the inverse word (+2 over par)." \
  TIER=whirlpool SCREEN=result LEVEL=5 CLOCK=3
for level in 24:chainmail 16:coral 20:neurons 25:marbling; do
  n=${level%:*} picture=${level#*:}
  shot "whirlpool$n-$picture" "Whirlpool level $n ($picture) with its full scramble." TIER=whirlpool LEVEL=$n CLOCK=3
done
for level in 26:glass 24:chainmail 16:coral 20:neurons 25:marbling; do
  n=${level%:*} picture=${level#*:}
  shot "maelstrom$n-$picture" "Maelstrom level $n ($picture twin) with its full scramble." TIER=maelstrom LEVEL=$n CLOCK=3
done
# The turning tank: maelstrom scrambles on their twins with seized knobs, at home and turned one step, where every seam
# should sit concentric on the knob it lands under.
shot seized-m01-home "Maelstrom 01 (tri) with knob 0 seized, tank at home." TIER=maelstrom LEVEL=1 SEIZED=0 CLOCK=3
shot seized-m01-turned "Maelstrom 01 (tri) with knob 0 seized, tank turned one step (120 degrees clockwise): the seams around knob 0 now ring knob 1." \
  TIER=maelstrom LEVEL=1 SEIZED=0 TANK=1 CLOCK=3
shot seized-m09-home "Maelstrom 09 (square) with knob 1 seized, tank at home." TIER=maelstrom LEVEL=9 SEIZED=1 CLOCK=3
shot seized-m09-turned "Maelstrom 09 (square) with knob 1 seized, tank turned one step (90 degrees clockwise): the seams around knob 1 now ring knob 2." \
  TIER=maelstrom LEVEL=9 SEIZED=1 TANK=1 CLOCK=3
shot seized-m23-home "Maelstrom 23 (hex) with knobs 2 and 5 seized, tank at home." TIER=maelstrom LEVEL=23 SEIZED=2,5 CLOCK=3
shot seized-m23-turned "Maelstrom 23 (hex) with knobs 2 and 5 seized, tank turned one step (60 degrees clockwise): each ring seam moves one knob on, the hub's stays." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 TANK=1 CLOCK=3
shot seized-m23-half "Maelstrom 23 (hex) with knobs 2 and 5 seized, mid-drag on the rim: the tank held half a step (30 degrees) round." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 TANKLIVE=30 CLOCK=3
shot seized-m23-count "Maelstrom 23 (hex) with knobs 2 and 5 seized, finger down on the rim at lower left and carried two tank steps (120 degrees) round: two segments round the rim, +2 off the finger." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 TANKLIVE=120 TOUCH=-0.5,0.84 CLOCK=3
# How to turn the tank, shown on any level with seized knobs until the player has turned it once: a two-headed arc just
# outside the rim and a ghost finger rocking on it. UNSTIR_TANKTURNED=1 is a player who has, for the launch only. The ghost
# is held by UNSTIR_CLOCK, and UNSTIR_SHAKE holds a touch on a seized knob that far into its shake and the rim's pulse.
shot lesson-quad-grid "Level 12 (square, grid) with knob 1 seized, the tank never turned: the rim's two-headed arc and ghost finger." \
  LEVEL=12 SEIZED=1 CLOCK=3
shot lesson-hex-marbling "Whirlpool 25 (hex, marbling) with knobs 2 and 5 seized, the tank never turned: the rim's arc and ghost finger over a live picture." \
  TIER=whirlpool LEVEL=25 SEIZED=2,5 CLOCK=3
shot lesson-shake "Level 12 (square) with knob 1 seized, a finger just down on it, 0.15 s in: the knob turned a few degrees, the rim's arc swollen." \
  LEVEL=12 SEIZED=1 TOUCH=0.38,0.37 SHAKE=0.15 CLOCK=3
shot lesson-shake-turned "The same once the player has turned the tank before: no ghost, the arc back only for the pulse." \
  LEVEL=12 SEIZED=1 TOUCH=0.38,0.37 SHAKE=0.15 CLOCK=3 TANKTURNED=1
shot lesson-turned "Level 12 (square) with knob 1 seized, the tank turned before: no arc, no ghost." LEVEL=12 SEIZED=1 CLOCK=3 TANKTURNED=1
shot lesson-count "Whirlpool 25 (hex, marbling) with knobs 2 and 5 seized, the tank never turned: rod 1 at the top turned +1 by a finger just below its knob, its count swung off the rim's arc." \
  TIER=whirlpool LEVEL=25 SEIZED=2,5 LIVE=1:+1 TOUCH=0,-0.3 CLOCK=3
shot lesson-maelstrom01-free "Maelstrom 01 (tri) as the game loads it: no knob seized until maelstrom's own set, so no rim lesson and no note of seized knobs." \
  TIER=maelstrom LEVEL=1 CLOCK=3
# Can a finished ring be read on hex glass? 14 entries, as whirlpool 23 has, with one ring left without any, and the same
# stack with a 2-step twist on that ring buried under its neighbours.
ring3="1:+4,0:-3,2:+5,6:-4,4:+3,0:+5,5:-3,1:-5,2:-3,6:+4,0:-4,4:-5,5:+4,1:+3"
ring3buried="1:+4,0:-3,2:+5,3:+2,6:-4,4:+3,0:+5,5:-3,1:-5,2:-3,6:+4,0:-4,4:-5,5:+4,1:+3"
hub="2:+4,3:-3,5:+5,1:-4,4:+3,6:-5,2:-3,3:+5,1:+4,6:+3,4:-4,5:-3,2:+5,3:-4"
hubburied="2:+4,3:-3,0:+2,5:+5,1:-4,4:+3,6:-5,2:-3,3:+5,1:+4,6:+3,4:-4,5:-3,2:+5,3:-4"
shot seized-ring3-finished "Hex twin glass, 14 entries ($ring3), none on rod 3: its ring is finished." TIER=maelstrom LEVEL=23 SEIZED=2,5 STACK="$ring3" CLOCK=3
shot seized-ring3-buried "The same with 3:+2 buried fourth from the bottom ($ring3buried): rod 3's ring is not finished." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 STACK="$ring3buried" CLOCK=3
shot seized-hub-finished "Hex twin glass, 14 entries ($hub), none on the hub: its ring is finished." TIER=maelstrom LEVEL=23 SEIZED=2,5 STACK="$hub" CLOCK=3
shot seized-hub-buried "The same with 0:+2 buried third from the bottom ($hubburied): the hub's ring is not finished." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 STACK="$hubburied" CLOCK=3
