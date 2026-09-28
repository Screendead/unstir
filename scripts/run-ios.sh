#!/bin/bash
# Usage: scripts/run-ios.sh [Debug|Release]   UNSTIR_DEVICE overrides the reference device.
set -euo pipefail
cd "$(dirname "$0")/.."
config="${1:-Debug}"
device="${UNSTIR_DEVICE:-1B834EFE-A784-5F98-9B7A-CF6D83E2123A}"
scripts/build-ios.sh "$config"
xcrun devicectl device install app --device "$device" "build/Build/Products/$config-iphoneos/Unstir.app"
xcrun devicectl device process launch --device "$device" com.screendead.Unstir
