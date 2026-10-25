#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/test-store.sh [build-for-testing] [xcodebuild args...]   Runs the tests with the StoreKit ones on
# (StoreTests), e.g. scripts/test-store.sh -only-testing:UnstirTests/StoreTests, or with build-for-testing only builds
# what they would run.
# storekitd refuses an SKTestSession ("is not installed for development") unless the host app carries get-task-allow,
# which CODE_SIGNING_ALLOWED=NO strips, so this signs ad hoc with StoreKit/Test.entitlements, into its own build folder
# so the unsigned builds in build/ aren't redone.
set -euo pipefail
cd "$(dirname "$0")/.."
udid=${UNSTIR_SIM:-$(xcrun simctl list devices available | grep 'Pro Max (' | head -1 | grep -oE '[0-9A-F-]{36}' || true)}
[[ -n "$udid" ]] || { echo "no Pro Max simulator: set UNSTIR_SIM" >&2; exit 2; }
action=test
[[ ${1:-} == build-for-testing ]] && { action=$1; shift; }
xcodegen generate --quiet
TEST_RUNNER_UNSTIR_STORE_TESTS=1 xcodebuild "$action" -project Unstir.xcodeproj -scheme Unstir -destination "id=$udid" \
  -derivedDataPath build/store CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  CODE_SIGN_ENTITLEMENTS=StoreKit/Test.entitlements "$@"
