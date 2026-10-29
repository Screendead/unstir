#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/run-ios.sh [Debug|Release]   UNSTIR_DEVICE names the phone (a UDID from `xcrun devicectl list devices`).
# UNSTIR_UNLOCK=1 opens every tier and level until a launch with UNSTIR_UNLOCK=0; unset leaves it as it is.
# UNSTIR_ANALYTICS=log writes each analytics event to the flight recorder instead of sending it.
# Every build this installs is a playtest: its analytics are filed as Debug, Release included (ANALYTICS_PLAYTEST).
set -euo pipefail
cd "$(dirname "$0")/.."
config="${1:-Debug}"
device="${UNSTIR_DEVICE:?set UNSTIR_DEVICE to a UDID from xcrun devicectl list devices}"
vars=()
[[ -n "${UNSTIR_UNLOCK:-}" ]] && vars+=("\"UNSTIR_UNLOCK\": \"$UNSTIR_UNLOCK\"")
[[ -n "${UNSTIR_ANALYTICS:-}" ]] && vars+=("\"UNSTIR_ANALYTICS\": \"$UNSTIR_ANALYTICS\"")
env=()
if (( ${#vars[@]} )); then
  env=(--environment-variables "{$(IFS=,; echo "${vars[*]}")}")
fi
ANALYTICS_PLAYTEST=YES scripts/build-ios.sh "$config"
xcrun devicectl device install app --device "$device" "build/Build/Products/$config-iphoneos/Unstir.app"
xcrun devicectl device process launch --device "$device" ${env[@]+"${env[@]}"} com.screendead.Unstir
