#!/bin/bash
# Usage: scripts/run-ios.sh [Debug|Release]   UNSTIR_DEVICE names the phone (a UDID from `xcrun devicectl list devices`).
set -euo pipefail
cd "$(dirname "$0")/.."
config="${1:-Debug}"
device="${UNSTIR_DEVICE:?set UNSTIR_DEVICE to a UDID from xcrun devicectl list devices}"
scripts/build-ios.sh "$config"
xcrun devicectl device install app --device "$device" "build/Build/Products/$config-iphoneos/Unstir.app"
xcrun devicectl device process launch --device "$device" com.screendead.Unstir
