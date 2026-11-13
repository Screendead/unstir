#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/gpu-bench.sh [sim]   times the tank's shader on the simulator's GPU (the Mac's), UNSTIR_SIM's or the
#                                     first "Pro Max"
#        scripts/gpu-bench.sh phone   builds Release, installs and launches it on UNSTIR_DEVICE through run-ios.sh with
#                                     UNSTIR_GPUBENCH=1, waits for the bench to quit, and pulls its lines from the log
#        scripts/gpu-bench.sh twists [pattern]   builds Release with PROBES=YES, installs it on UNSTIR_DEVICE and times
#                                     the twist oracle's cases there (OracleBench.swift, scripts/twist-oracle.sh's, those
#                                     whose name holds the pattern): today's shader, the stored map and the map with
#                                     every moved tap through the chain, each as a share of today's, and what drawing
#                                     the map costs, by the GPU's clock at 1137 px, or ORACLE_SIDE's (1471, the Duo's).
#                                     It leaves the probes' build on the phone: install a plain one after.
# The app (GPUBench.swift) runs Unstir.metal's own shader bodies off screen and prints a stack entry's cost with four
# taps and two at 1137, 1284 and 1471 px, the glass's fill and whirlpool 27's whole frame at 1137 and 1471, then at
# 1284 each Prism specimen's per-channel cost against what Unstirred.channelCost assumes, and the slowest against the
# 8.333 ms of a 120 Hz frame, and each with its first move's rod in hand, its held read drawn against not, and Lens 01's and 25's frames on their own panels, as dealt and with every lens at x8,
# each through the plain shader and through the one that draws a lens's detail.
# Then it bakes Lens's panels cold on the CPU, bypassing Caches, at the play screen's glass:
# the cheapest and dearest of a quick pass over all 25, and Keyhole, each in wall-clock ms, and a cached panel's bytes.
# The simulator's bake runs on the Mac's CPU, unoptimised in Debug: only the phone's numbers mean anything.
# Let the phone cool between runs: heat skews it, and the last line names the thermal state.
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
    # The bench takes a minute or two and quits when done: pull the log until its last line is there, for up to 5 minutes.
    log=$(mktemp)
    for _ in $(seq 30); do
      sleep 10
      scripts/pull-log.sh "$log" >/dev/null 2>&1 || continue
      started=$(grep -n 'GPUBENCH start' "$log" | tail -1 | cut -d: -f1)
      [[ -n "$started" ]] && tail -n +"$started" "$log" | grep -qE 'GPUBENCH lens cache|GPUBENCH no' && break
    done
    started=$(grep -n 'GPUBENCH start' "$log" | tail -1 | cut -d: -f1)
    [[ -n "$started" ]] || { echo "no bench in the phone's log"; exit 1; }
    tail -n +"$started" "$log" | grep 'GPUBENCH'
    ;;
  twists)
    # The twist oracle's bench on the phone: today's shader against the stored map, on the GPU's own clock.
    cases=$(scripts/twist-oracle.sh cases "${2:-}")
    [[ -n "$cases" ]] || { echo "no oracle case matches '${2:-}'"; exit 2; }
    PROBES=YES UNSTIR_GPUBENCH=oracle UNSTIR_ORACLECASES="$cases" UNSTIR_ORACLESIDE="${ORACLE_SIDE:-}" scripts/run-ios.sh Release
    log=$(mktemp)
    for _ in $(seq 60); do
      sleep 10
      scripts/pull-log.sh "$log" >/dev/null 2>&1 || continue
      started=$(grep -n 'ORACLE start' "$log" | tail -1 | cut -d: -f1)
      [[ -n "$started" ]] && tail -n +"$started" "$log" | grep -qE 'ORACLE (done|no Metal)' && break
    done
    started=$(grep -n 'ORACLE start' "$log" | tail -1 | cut -d: -f1)
    [[ -n "$started" ]] || { echo "no oracle bench in the phone's log"; exit 1; }
    tail -n +"$started" "$log" | grep 'ORACLE'
    ;;
  *) echo "usage: scripts/gpu-bench.sh [sim|phone|twists [pattern]]"; exit 2 ;;
esac
