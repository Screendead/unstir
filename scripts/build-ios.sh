#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/build-ios.sh [Debug|Release] [device|sim]   ANALYTICS=YES builds analytics in, and APTABASE_KEY, if
# set, turns its sending on.
# ANALYTICS_PLAYTEST=YES files a Release build's analytics as Debug. SUPPORT_ADDRESS and POLICY_URL set the address
# "report a problem" mails and the privacy policy's page. EDITORS=YES makes the editors' build, its settings' switch
# opening every tier. GAME_CENTER=YES builds Game Center's sign-in and achievements in. ICLOUD=YES syncs bests through
# iCloud, which needs the App ID's iCloud capability to sign for a device. ADAPTIVE_TAPS=YES learns and keeps each glass's
# four-tap budget on a plain launch.
set -euo pipefail
cd "$(dirname "$0")/.."
config="${1:-Debug}"
case "${2:-device}" in
  device) destination="generic/platform=iOS"; signing=() ;;
  sim) destination="generic/platform=iOS Simulator"; signing=(CODE_SIGNING_ALLOWED=NO) ;;
  *) echo "unknown target: $2" >&2; exit 2 ;;
esac
xcodegen generate --quiet
xcodebuild -project Unstir.xcodeproj -scheme Unstir -configuration "$config" \
  -destination "$destination" -derivedDataPath build \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration ${signing[@]+"${signing[@]}"} \
  ${ANALYTICS:+ANALYTICS="$ANALYTICS"} ${APTABASE_KEY:+APTABASE_KEY="$APTABASE_KEY"} ${ANALYTICS_PLAYTEST:+ANALYTICS_PLAYTEST="$ANALYTICS_PLAYTEST"} \
  ${GAME_CENTER:+GAME_CENTER="$GAME_CENTER"} ${ICLOUD:+ICLOUD="$ICLOUD"} ${ADAPTIVE_TAPS:+ADAPTIVE_TAPS="$ADAPTIVE_TAPS"} \
  ${SUPPORT_ADDRESS:+SUPPORT_ADDRESS="$SUPPORT_ADDRESS"} ${POLICY_URL:+POLICY_URL="$POLICY_URL"} \
  ${EDITORS:+EDITORS="$EDITORS"} build | grep -E 'error:|warning:|BUILD '
