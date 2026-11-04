#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/taps-check.sh [--sim udid] [runs...]   Plays whirlpool 27, its stack cut or repeated (UNSTIR_DEEP), on
# the phone UNSTIR_DEVICE names with the build scripts/run-ios.sh Release installed (or on the simulator given, whose
# frames say nothing of a phone's GPU: a dry run), a knob dragged 4 s at a time through the real let-go
# (UNSTIR_TAPDRAG), and prints each run's taps lines from the flight recorder. Lets the phone cool past serious.
#   gpu    36 entries in flight at four taps (watch:42): late frames should read gpu, with the main thread idle.
#   calm   the same at two taps (watch:12): few late frames.
#   stall  calm with 20 ms of main-thread work every 0.5 s: late frames should read cpu.
#   adapt  the law from 42: a step down to 38 at the first commit after three misses, then held at two taps.
#   prior  the law from the glass's prior (30) with the same stack: two taps, nothing to step.
#   edge   the law from its prior at the budget's edge, Wc 30 (26 entries on the glass): holds or finds the phone's edge.
#   edgestall  edge with stall's main-thread work: a step down that the effect check reverts, as two taps don't help.
# Every run unset.
set -euo pipefail
cd "$(dirname "$0")/.."
sim=
if [[ "${1:-}" == --sim ]]; then sim=$2; shift 2; fi
runs=("$@")
(( ${#runs[@]} )) || runs=(gpu calm stall adapt prior edge)
vars() {
  case $1 in
    gpu) echo '"UNSTIR_TAPS":"watch:42","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"4"' ;;
    calm) echo '"UNSTIR_TAPS":"watch:12","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"4"' ;;
    stall) echo '"UNSTIR_TAPS":"watch:12","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"4","UNSTIR_TAPSTALL":"20"' ;;
    adapt) echo '"UNSTIR_TAPS":"adapt:42","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"8"' ;;
    prior) echo '"UNSTIR_TAPS":"adapt","UNSTIR_DEEP":"35","UNSTIR_TAPDRAG":"4"' ;;
    edge) echo '"UNSTIR_TAPS":"adapt","UNSTIR_DEEP":"26","UNSTIR_TAPDRAG":"12"' ;;
    edgestall) echo '"UNSTIR_TAPS":"adapt","UNSTIR_DEEP":"26","UNSTIR_TAPDRAG":"12","UNSTIR_TAPSTALL":"20"' ;;
    *) echo "unknown run $1" >&2; exit 1 ;;
  esac
}
level='"UNSTIR_UNLOCK":"1","UNSTIR_TIER":"whirlpool","UNSTIR_LEVEL":"27"'
log=$(mktemp)
pull() {
  if [[ -n $sim ]]; then
    cp "$(xcrun simctl get_app_container "$sim" com.screendead.Unstir data)/Library/unstir-log.txt" "$log" 2>/dev/null || true
  else
    scripts/pull-log.sh "$log" >/dev/null 2>&1 || true
  fi
}
finished() { pull; grep -c 'tapdrag done' "$log" || true; }
launch() {
  if [[ -n $sim ]]; then
    local args=()
    while IFS= read -r pair; do args+=("SIMCTL_CHILD_$pair"); done < <(echo "{$1}" | python3 -c \
      'import json, sys; [print(f"{k}={v}") for k, v in json.load(sys.stdin).items()]')
    env "${args[@]}" xcrun simctl launch --terminate-running-process "$sim" com.screendead.Unstir >/dev/null
  else
    xcrun devicectl device process launch --device "${UNSTIR_DEVICE:?set UNSTIR_DEVICE to a UDID from xcrun devicectl list devices}" \
      --terminate-existing --environment-variables "{$1}" com.screendead.Unstir >/dev/null
  fi
}
for run in "${runs[@]}"; do
  before=$(finished)
  launch "$level,$(vars "$run")"
  for _ in $(seq 40); do
    sleep 3
    (( $(finished) > before )) && break
  done
  echo "== $run"
  awk -v k="$before" '/tapdrag done/ { if (++c > k) exit } c == k && /taps (prior|drag|down|up|probe|cap|reverted|held|two-tap|applied|hot|cool)/' "$log"
  if grep 'taps drag' "$log" | tail -1 | grep -qE 'thermal (serious|critical)'; then sleep 90; fi
done
