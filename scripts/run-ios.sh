#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/run-ios.sh [Debug|Release]   UNSTIR_DEVICE names the phone (a UDID from `xcrun devicectl list devices`).
# UNSTIR_UNLOCK=1 opens every tier and level until a launch with UNSTIR_UNLOCK=0; unset leaves it as it is.
set -euo pipefail
cd "$(dirname "$0")/.."
config="${1:-Debug}"
device="${UNSTIR_DEVICE:?set UNSTIR_DEVICE to a UDID from xcrun devicectl list devices}"
env=()
if [[ -n "${UNSTIR_UNLOCK:-}" ]]; then
  env=(--environment-variables "{\"UNSTIR_UNLOCK\": \"$UNSTIR_UNLOCK\"}")
fi
scripts/build-ios.sh "$config"
xcrun devicectl device install app --device "$device" "build/Build/Products/$config-iphoneos/Unstir.app"
xcrun devicectl device process launch --device "$device" ${env[@]+"${env[@]}"} com.screendead.Unstir
