#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/duo-feel.sh [--sim udid] [drags] [budgets...]   Plays the deepest levels (whirlpool, maelstrom and
# vortex 27, endless's tank 20), each as dealt and repeated to the full stack of 36 (UNSTIR_DEEP), on the phone
# UNSTIR_DEVICE names with the build scripts/run-ios.sh Release installed (or on the simulator given: a dry run of the
# plumbing), at each four-tap budget pinned (UNSTIR_TAPS=watch:n), a knob dragged 4 s at a time through the real
# let-go `drags` times (UNSTIR_TAPDRAG, 2 unset), and prints each run's taps lines from the flight recorder. Budgets
# unset: 42, four taps on every stack, and 23, the open Duo upright's starting limit (r16c-duoprior), its rule on this
# glass. Lets the phone cool past serious.
#
# What it reads: FrameWatch's display link in the app, one `taps drag` line a drag (counted frames, late ones by
# cause, the granted period, the main thread's CPU time, thermal state). The link times its own callbacks, not frames
# reaching the screen. On the 13 Pro Max the presentation probe (2026-11-04) showed it counts the frames the render
# server drops under a GPU overload, but it can't tell those from the main thread's own (a main-thread stall's late
# frames read gpu 7 times in 15), it reads only while a finger turns a rod, and on the simulator, with no phone GPU,
# its numbers say nothing of a phone's.
#
# What it doesn't do: play the Duo's speed. The local duo-feel probe shaded the tank at 1471 / sqrt(r) px, r the Duo's
# GPU over the A15's, and scaled it to this phone's glass; that probe stays off master, so this plays the device's own
# glass, and the Duo's own numbers wait on stage 6's real Duo. scripts/gpu-bench.sh times the shader at 1471 px.
set -euo pipefail
cd "$(dirname "$0")/.."
sim=
if [[ "${1:-}" == --sim ]]; then sim=$2; shift 2; fi
drags=${1:-2}
shift || true
budgets=("$@")
(( ${#budgets[@]} )) || budgets=(42 23)
levels=(
  'whirlpool 27|"UNSTIR_TIER":"whirlpool","UNSTIR_LEVEL":"27"'
  'maelstrom 27|"UNSTIR_TIER":"maelstrom","UNSTIR_LEVEL":"27"'
  'vortex 27|"UNSTIR_TIER":"vortex","UNSTIR_LEVEL":"27"'
  'endless tank 20|"UNSTIR_MODE":"endless","UNSTIR_RESUME":"","UNSTIR_RESUMETANK":"20"'
)
log=$(mktemp)
source scripts/harness.sh
finished() { harness_pull "$sim" "$log"; grep -c 'tapdrag done' "$log" || true; }
for entry in "${levels[@]}"; do
  for deep in dealt 36; do
    vars="\"UNSTIR_UNLOCK\":\"1\",\"UNSTIR_TAPDRAG\":\"$drags\",${entry#*|}"
    [[ $deep == 36 ]] && vars+=',"UNSTIR_DEEP":"36"'
    for b in "${budgets[@]}"; do
      before=$(finished)
      harness_launch "$sim" "$vars,\"UNSTIR_TAPS\":\"watch:$b\""
      for _ in $(seq 40); do
        sleep 3
        (( $(finished) > before )) && break
      done
      echo "== ${entry%%|*}, $deep, budget $b"
      awk -v k="$before" '/tapdrag done/ { if (++c > k) exit } c == k && /taps (prior|drag)/' "$log"
      if grep 'taps drag' "$log" | tail -1 | grep -qE 'thermal (serious|critical)'; then sleep 90; fi
    done
  done
done
