#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/film.sh [pattern]   Records the animations in the simulator into shots/film/, each with a frame strip.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle=com.screendead.Unstir

# UNSTIR_SIM=<udid> picks the simulator; otherwise the first Pro Max.
udid=${UNSTIR_SIM:-$(xcrun simctl list devices available | grep 'Pro Max (' | head -1 | grep -oE '[0-9A-F-]{36}')}
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
scripts/build-ios.sh Debug sim
# Fresh install, so no level has been started and autoplay can finish clean.
xcrun simctl uninstall "$udid" "$bundle" 2>/dev/null || true
xcrun simctl install "$udid" build/Build/Products/Debug-iphonesimulator/Unstir.app
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 2>/dev/null || true
mkdir -p shots/film
pattern=${1:-}

tank=crop=1200:1200:60:820  # the tank on a 1320 x 2868 Pro Max screen
film() {  # name seconds strip-filter KEY=VALUE...
  local name=$1 secs=$2 strip=$3 vars=() mp4="shots/film/$1.mp4"
  shift 3
  [[ -n "$pattern" && "$name" != *$pattern* ]] && return
  for kv in "$@"; do vars+=("SIMCTL_CHILD_UNSTIR_$kv"); done
  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
  xcrun simctl io "$udid" recordVideo --codec=h264 --force "$mp4" >/dev/null 2>&1 &
  local rec=$!
  sleep 1.5  # the recorder takes a moment to start
  env "${vars[@]}" xcrun simctl launch "$udid" "$bundle" >/dev/null
  sleep "$secs"
  kill -INT "$rec"
  wait "$rec" || true
  # The strip starts at the first dark frame: the home screen is bright and the app is black.
  local start
  start=$(ffprobe -v error -f lavfi -i "movie=$mp4,signalstats" -show_entries frame=pts_time:frame_tags=lavfi.signalstats.YAVG \
    -of csv=p=0 | awk -F, '$2 < 40 && s == "" { s = $1 } END { print s }')
  # recordVideo writes a frame only when the screen changes; fps= resamples to even time steps.
  ffmpeg -loglevel error -y -i "$mp4" -vf "trim=start=${start:-0},setpts=PTS-STARTPTS,$strip" -frames:v 1 "shots/film/$name-strip.png"
  echo "filmed $name"
}

film open-L01 4.5 "$tank,fps=6,scale=240:-1,tile=6x5:padding=4" LEVEL=1 OPEN=1
film open-L12 5 "$tank,fps=6,scale=240:-1,tile=6x5:padding=4" LEVEL=12 OPEN=1
# The launch fade, then the 0.4 s ignition, at 30 frames a second.
film ignition-L12 2.5 "$tank,fps=30,scale=200:-1,tile=8x3:padding=4" LEVEL=12 OPEN=1
film autoplay-L09 9 "fps=3,scale=220:-1,tile=9x3:padding=4" LEVEL=9 OPEN=1 AUTOPLAY=1
film tour 8 "fps=4,scale=200:-1,tile=9x4:padding=4" TOUR=1 OPEN=1
# The tier strip: plughole swiped to whirlpool (open), swiped to maelstrom (locked, 17 ticks lit), then plughole tapped.
par27=$(printf '0%.0s' {1..27})
film tier-switch 11 "fps=6,scale=180:-1,tile=11x6:padding=4" TIERDEMO=1 BESTS=plughole:$par27,whirlpool:00001000000200000100
# The twins' heartbeat, still: from 2.2 s in (the neural web lands about 2 s after launch), one beat at 20 frames a second.
film heartbeat-maelstrom24-chainmail 3.5 "trim=start=2.2,setpts=PTS-STARTPTS,$tank,fps=20,scale=240:-1,tile=5x4:padding=4" TIER=maelstrom LEVEL=24
film heartbeat-maelstrom20-neurons 3.5 "trim=start=2.2,setpts=PTS-STARTPTS,$tank,fps=20,scale=240:-1,tile=5x4:padding=4" TIER=maelstrom LEVEL=20
# Endless's brim, the approved film's run through the real commit path (UNSTIR_BRIMDEMO): from 5 notches two heals settle it
# to 3, then five pushes fill it notch by notch until the last spills over the lip at twelve and the picture stirs together.
# Cropped taller than the tank, for the brim pin and the pour above it.
film endless-brim-run 11.5 "crop=1320:1460:0:700,fps=3,scale=200:-1,tile=8x4:padding=4" MODE=endless BRIM=5 BRIMDEMO=1
