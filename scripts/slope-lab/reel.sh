#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: UNSTIR_SIM=<udid> scripts/slope-lab/reel.sh <out.png> <seconds> <from> <to> KEY=VALUE...
# Records one harness launch on a booted simulator that already has the build for `seconds`, and lays every frame the
# recorder kept between `from` and `to` seconds side by side at a sixth size: a look at a moment too short for
# strip.sh's screenshots, such as a ground's first frames (needs ffmpeg).
set -euo pipefail
udid=${UNSTIR_SIM:?set UNSTIR_SIM to a simulator udid}
out=$1 secs=$2 from=$3 to=$4
shift 4
dir=$(mktemp -d)
vars=()
for kv in "$@"; do vars+=("SIMCTL_CHILD_UNSTIR_$kv"); done
xcrun simctl terminate "$udid" com.screendead.Unstir 2>/dev/null || true
xcrun simctl io "$udid" recordVideo --codec=h264 --force "$dir/take.mp4" >/dev/null 2>&1 &
rec=$!
sleep 1.5
env ${vars[@]+"${vars[@]}"} xcrun simctl launch "$udid" com.screendead.Unstir >/dev/null
sleep "$secs"
kill -INT "$rec"
wait "$rec" || true
xcrun simctl terminate "$udid" com.screendead.Unstir 2>/dev/null || true
ffmpeg -loglevel error -fflags +igndts -i "$dir/take.mp4" -vf "select='between(t,$from,$to)',scale=220:-1,tile=16x6:padding=3" -fps_mode vfr -frames:v 1 -y "$out"
