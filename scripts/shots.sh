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
caches="$(xcrun simctl get_app_container "$udid" "$bundle" data)/Library/Caches"
launched=shots/.launched
lensbaked=""
settle=6  # the first launch on a fresh install is slow
shot() {  # name description KEY=VALUE...
  local name=$1 desc=$2 vars=()
  shift 2
  echo "$name.png  $desc" >> shots/index.txt
  [[ -n "${pattern:-}" && "$name" != *$pattern* ]] && return
  for kv in "$@"; do vars+=("SIMCTL_CHILD_UNSTIR_$kv"); done
  touch "$launched"
  env ${vars[@]+"${vars[@]}"} xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
  local wait=${hold:-$settle}
  # A Lens level bakes its own halftone panel the first time a Debug install draws it, for half a minute, or two on a
  # busy Mac; its later shots read it from Caches. So a level's first shot waits for a bake to land.
  if [[ " $* " == *" PACK=lens "* ]]; then
    local level; level=$(sed -nE 's/.* LEVEL=0*([0-9]+) .*/\1/p' <<< " $* ")
    if [[ " $lensbaked " != *" ${level:-1} "* ]]; then
      lensbaked+=" ${level:-1}"
      for _ in $(seq 240); do [[ -n "$(find "$caches" -name 'halftone-*' -newer "$launched" 2>/dev/null)" ]] && break; sleep 1; done
    fi
  fi
  # A harness solve's card lands its result marks one by one, the last some 1.5 s after the card shows.
  if [[ " $* " == *" SCREEN=result "* || " $* " == *" SCREEN=clean "* ]] && ((wait < 5)); then wait=5; fi
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
for area in menu play tiers vortex lens icon-promo first-stir shelf settings escapement prism store duo calm type marks; do
  source "scripts/shots/$area.sh"
done
