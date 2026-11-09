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
  local wait=${hold:-$settle}
  # Lens's halftone bakes for 20 s or more the first time a Debug install draws it; the shots after read it from Caches.
  if [[ " $* " == *" PACK=lens "* && -z "${baked:-}" ]]; then wait=30; baked=1; fi
  sleep "$wait"
  settle=3
  xcrun simctl io "$udid" screenshot "shots/$name.png" >/dev/null 2>&1
  echo "shot $name"
}
pattern=${1:-}

# The same level-like scrambles (bottom first, three-rod layout) for every picture, one per depth.
depths=("0:+4" "1:+5,2:-4" "0:-6,1:+4,2:-5" "0:+5,2:-6,1:+3,0:-4" "2:-5,0:+4,1:-7,2:+3,0:-6")
# Each area's shots, in the index's order. Sourced, not run, as a later area reads values an earlier one set
# (par27 from the menu, nine from the shelf).
for area in menu play tiers vortex lens icon-promo first-stir shelf settings escapement prism store duo calm; do
  source "scripts/shots/$area.sh"
done
