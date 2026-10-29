#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/gpu-bench.sh [sim]   times the tank's shader on the simulator's GPU (the Mac's), UNSTIR_SIM's or the
#                                     first "Pro Max"
#        scripts/gpu-bench.sh phone   builds Release, installs and launches it on UNSTIR_DEVICE through run-ios.sh with
#                                     UNSTIR_GPUBENCH=1, waits for the bench to quit, and pulls its lines from the log
# The app (GPUBench.swift) runs Unstir.metal's own shader bodies off screen at 1284 px and prints a stack entry's cost,
# each Prism specimen's per-channel cost against what Unstirred.channelCost assumes, and the slowest against the
# 8.333 ms of a 120 Hz frame. Let the phone cool between runs: heat skews it, and the last line names the thermal state.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle=com.screendead.Unstir
case "${1:-sim}" in
  sim)
    udid=${UNSTIR_SIM:-$(xcrun simctl list devices available | grep 'Pro Max (' | head -1 | grep -oE '[0-9A-F-]{36}')}
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b >/dev/null
    scripts/build-ios.sh Debug sim
    xcrun simctl install "$udid" build/Build/Products/Debug-iphonesimulator/Unstir.app
    SIMCTL_CHILD_UNSTIR_GPUBENCH=1 xcrun simctl launch --console-pty --terminate-running-process "$udid" "$bundle" 2>&1 |
      grep --line-buffered '^GPUBENCH'
    ;;
  phone)
    UNSTIR_GPUBENCH=1 scripts/run-ios.sh Release
    # The bench takes about a minute; it quits when done.
    sleep 90
    log=$(mktemp)
    scripts/pull-log.sh "$log" >/dev/null
    grep 'GPUBENCH' "$log" | tail -70
    ;;
  *) echo "usage: scripts/gpu-bench.sh [sim|phone]"; exit 2 ;;
esac
