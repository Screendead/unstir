#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/taps-check.sh [--sim udid] [runs...]   Plays whirlpool 27, its stack cut or repeated (UNSTIR_DEEP), on
# the phone UNSTIR_DEVICE names with the build scripts/run-ios.sh Release installed (or on the simulator given, whose
# frames say nothing of a phone's GPU: a dry run), a knob dragged 4 s at a time through the real let-go
# (UNSTIR_TAPDRAG), and prints each run's taps lines from the flight recorder. Lets the phone cool past serious.
#   gpu    36 entries in flight at four taps (watch:42): late frames should read gpu, with the main thread idle.
#   calm   the same at two taps (watch:12): few late frames.
#   stall  calm with 20 ms of main-thread work every 0.5 s: the shipped cuts don't attribute, so every late frame
#          counts; the main thread's CPU time shows the stalls.
#   adapt  the law from 42: a step down only on 4 late frames in 30 within 4 of the budget (none on the 13 Pro Max).
#   prior  the law from the glass's static limit (40) with the same stack: four taps, climbing at the edge.
#   edge   the law from its static 40 at the budget's edge, Wc 40 (36 entries on the glass): climbs to 42, one a 600
#          clean frames, or finds the edge.
#   edgestall  edge with stall's main-thread work: about 2 late frames in any 30, under the 4 that step, so it holds
#          or climbs.
# Every run unset. A drag over the stored map draws four taps whatever the budget and the law never judges it
# (2026-11-13), so every run turns the map off (UNSTIR_MAP=off), which only a Debug or PROBES=YES build reads: on any
# other build these runs measure the map, not the budget.
set -euo pipefail
cd "$(dirname "$0")/.."
sim=
if [[ "${1:-}" == --sim ]]; then sim=$2; shift 2; fi
runs=("$@")
(( ${#runs[@]} )) || runs=(gpu calm stall adapt prior edge)
vars() {
  case $1 in
    gpu) echo '"UNSTIR_TAPS":"watch:42","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"4","UNSTIR_MAP":"off"' ;;
    calm) echo '"UNSTIR_TAPS":"watch:12","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"4","UNSTIR_MAP":"off"' ;;
    stall) echo '"UNSTIR_TAPS":"watch:12","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"4","UNSTIR_TAPSTALL":"20","UNSTIR_MAP":"off"' ;;
    adapt) echo '"UNSTIR_TAPS":"adapt:42","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"8","UNSTIR_MAP":"off"' ;;
    prior) echo '"UNSTIR_TAPS":"adapt","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"4","UNSTIR_MAP":"off"' ;;
    edge) echo '"UNSTIR_TAPS":"adapt","UNSTIR_DEEP":"36","UNSTIR_TAPDRAG":"12","UNSTIR_MAP":"off"' ;;
    edgestall) echo '"UNSTIR_TAPS":"adapt","UNSTIR_DEEP":"36","UNSTIR_TAPDRAG":"12","UNSTIR_TAPSTALL":"20","UNSTIR_MAP":"off"' ;;
    *) echo "unknown run $1" >&2; exit 1 ;;
  esac
}
level='"UNSTIR_UNLOCK":"1","UNSTIR_TIER":"whirlpool","UNSTIR_LEVEL":"27"'
log=$(mktemp)
source scripts/harness.sh
finished() { harness_pull "$sim" "$log"; grep -c 'tapdrag done' "$log" || true; }
for run in "${runs[@]}"; do
  before=$(finished)
  harness_launch "$sim" "$level,$(vars "$run")"
  for _ in $(seq 40); do
    sleep 3
    (( $(finished) > before )) && break
  done
  echo "== $run"
  awk -v k="$before" '/tapdrag done/ { if (++c > k) exit } c == k && /taps (prior|drag|down|up|probe|cap|reverted|held|two-tap|applied|hot|cool)/' "$log"
  if grep 'taps drag' "$log" | tail -1 | grep -qE 'thermal (serious|critical)'; then sleep 90; fi
done
