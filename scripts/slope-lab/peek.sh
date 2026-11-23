#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: UNSTIR_SIM=<udid> scripts/slope-lab/peek.sh <out.png> [seconds] KEY=VALUE...
# One harness launch on a booted simulator that already has the build (scripts/build-ios.sh Debug sim, installed by
# this script when it is newer than the last one it installed), shot after `seconds` (3) and then stopped: a look at
# one case without scripts/shots.sh's rebuild, reinstall and index.
set -euo pipefail
cd "$(dirname "$0")/../.."
bundle=com.screendead.Unstir
udid=${UNSTIR_SIM:?set UNSTIR_SIM to a simulator udid}
out=$1
shift
wait=3
if [[ ${1:-} =~ ^[0-9.]+$ ]]; then wait=$1; shift; fi
app=build/Build/Products/Debug-iphonesimulator/Unstir.app
stamp=build/slope-lab/installed-$udid
mkdir -p build/slope-lab
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
if [[ ! -e $stamp || $app/Unstir.debug.dylib -nt $stamp || $app/default.metallib -nt $stamp ]]; then
  xcrun simctl install "$udid" "$app"
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 2>/dev/null || true
  touch "$stamp"
fi
vars=()
for kv in "$@"; do vars+=("SIMCTL_CHILD_UNSTIR_$kv"); done
env ${vars[@]+"${vars[@]}"} xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
sleep "$wait"
xcrun simctl io "$udid" screenshot "$out" >/dev/null 2>&1
xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
