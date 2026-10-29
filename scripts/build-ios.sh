#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/build-ios.sh [Debug|Release] [device|sim]   ANALYTICS=YES builds analytics in, and APTABASE_KEY, if
# set, turns its sending on.
# ANALYTICS_PLAYTEST=YES files a Release build's analytics as Debug.
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
  ${ANALYTICS:+ANALYTICS="$ANALYTICS"} ${APTABASE_KEY:+APTABASE_KEY="$APTABASE_KEY"} ${ANALYTICS_PLAYTEST:+ANALYTICS_PLAYTEST="$ANALYTICS_PLAYTEST"} build | grep -E 'error:|warning:|BUILD '
