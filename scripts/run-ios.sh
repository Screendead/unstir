#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/run-ios.sh [Debug|Release]   UNSTIR_DEVICE names the phone (a UDID from `xcrun devicectl list devices`).
# UNSTIR_UNLOCK=1 opens every tier and level until a launch with UNSTIR_UNLOCK=0; unset leaves it as it is.
# UNSTIR_ANALYTICS=log writes each analytics event to the flight recorder instead of sending it.
# UNSTIR_GPUBENCH=1 times the tank's shader on the GPU and quits (scripts/gpu-bench.sh phone).
# UNSTIR_TAPS pins the four-tap budget (n), logs every drag at n (watch:n) or runs its law keeping nothing (adapt, adapt:n).
# UNSTIR_MAP=off|chain|show draws the glass without its stored map or another way (StirMap), UNSTIR_MAPLOG=1 logs each map
# as it lands, and UNSTIR_GPUBENCH=oracle with UNSTIR_ORACLECASES times the twist oracle's cases (scripts/gpu-bench.sh
# twists): probes all, read only by a build with PROBES=YES.
# Every build this installs is a playtest: its analytics are filed as Debug, Release included (ANALYTICS_PLAYTEST).
set -euo pipefail
cd "$(dirname "$0")/.."
config="${1:-Debug}"
device="${UNSTIR_DEVICE:?set UNSTIR_DEVICE to a UDID from xcrun devicectl list devices}"
vars=()
[[ -n "${UNSTIR_UNLOCK:-}" ]] && vars+=("\"UNSTIR_UNLOCK\": \"$UNSTIR_UNLOCK\"")
[[ -n "${UNSTIR_ANALYTICS:-}" ]] && vars+=("\"UNSTIR_ANALYTICS\": \"$UNSTIR_ANALYTICS\"")
[[ -n "${UNSTIR_GPUBENCH:-}" ]] && vars+=("\"UNSTIR_GPUBENCH\": \"$UNSTIR_GPUBENCH\"")
[[ -n "${UNSTIR_TAPS:-}" ]] && vars+=("\"UNSTIR_TAPS\": \"$UNSTIR_TAPS\"")
for name in UNSTIR_MAP UNSTIR_MAPLOG UNSTIR_ORACLECASES UNSTIR_ORACLESIDE; do
  [[ -n "${!name:-}" ]] && vars+=("\"$name\": \"${!name}\"")
done
env=()
if (( ${#vars[@]} )); then
  env=(--environment-variables "{$(IFS=,; echo "${vars[*]}")}")
fi
ANALYTICS_PLAYTEST=YES scripts/build-ios.sh "$config"
xcrun devicectl device install app --device "$device" "build/Build/Products/$config-iphoneos/Unstir.app"
xcrun devicectl device process launch --device "$device" ${env[@]+"${env[@]}"} com.screendead.Unstir
