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
    # The bench takes about a minute and quits when done: pull the log until its last line is there, for up to 5 minutes.
    log=$(mktemp)
    for _ in $(seq 30); do
      sleep 10
      scripts/pull-log.sh "$log" >/dev/null 2>&1 || continue
      started=$(grep -n 'GPUBENCH start' "$log" | tail -1 | cut -d: -f1)
      [[ -n "$started" ]] && tail -n +"$started" "$log" | grep -q 'measured / assumed' && break
    done
    started=$(grep -n 'GPUBENCH start' "$log" | tail -1 | cut -d: -f1)
    [[ -n "$started" ]] || { echo "no bench in the phone's log"; exit 1; }
    tail -n +"$started" "$log" | grep 'GPUBENCH'
    ;;
  *) echo "usage: scripts/gpu-bench.sh [sim|phone]"; exit 2 ;;
esac
