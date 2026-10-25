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
  # GitHub takes videos under 10 MB; a live picture changes every frame, so a long film can pass that.
  if (( $(stat -f %z "$mp4") > 9500000 )); then
    ffmpeg -loglevel error -y -i "$mp4" -vf scale=660:-2 -c:v libx264 -crf 24 -pix_fmt yuv420p -an "${mp4%.mp4}-small.mp4"
    mv "${mp4%.mp4}-small.mp4" "$mp4"
  fi
  echo "filmed $name"
}

film open-L01 4.5 "$tank,fps=6,scale=240:-1,tile=6x5:padding=4" LEVEL=1 OPEN=1
film open-L12 5 "$tank,fps=6,scale=240:-1,tile=6x5:padding=4" LEVEL=12 OPEN=1
# The launch fade, then the 0.4 s ignition, at 30 frames a second.
film ignition-L12 2.5 "$tank,fps=30,scale=200:-1,tile=8x3:padding=4" LEVEL=12 OPEN=1
film autoplay-L09 9 "fps=3,scale=220:-1,tile=9x3:padding=4" LEVEL=9 OPEN=1 AUTOPLAY=1
film tour 8 "fps=4,scale=200:-1,tile=9x4:padding=4" TOUR=1 OPEN=1
# The tier strip: plughole swiped to whirlpool (open), swiped to vortex (locked, 17 ticks lit), then plughole tapped.
par27=$(printf '0%.0s' {1..27})
film tier-switch 11 "fps=6,scale=180:-1,tile=11x6:padding=4" TIERDEMO=1 BESTS=plughole:$par27,whirlpool:00001000000200000100
# The twins' heartbeat, still: from 2.2 s in (the neural web lands about 2 s after launch), one beat at 20 frames a second.
film heartbeat-maelstrom22-chainmail 3.5 "trim=start=2.2,setpts=PTS-STARTPTS,$tank,fps=20,scale=240:-1,tile=5x4:padding=4" TIER=maelstrom LEVEL=22
film heartbeat-maelstrom18-neurons 3.5 "trim=start=2.2,setpts=PTS-STARTPTS,$tank,fps=20,scale=240:-1,tile=5x4:padding=4" TIER=maelstrom LEVEL=18
# Endless's brim, the approved film's run through the real commit path (UNSTIR_BRIMDEMO): from 5 notches two heals settle it
# to 3, then five pushes fill it notch by notch until the last spills over the lip at twelve and the picture stirs together.
# Cropped taller than the tank, for the brim pin and the pour above it.
film endless-brim-run 11.5 "crop=1320:1460:0:700,fps=3,scale=200:-1,tile=8x4:padding=4" MODE=endless BRIM=5 BRIMDEMO=1
# The rim's cues (UNSTIR_RIM), each the lead and both alternatives, played by a drawn fingertip (UNSTIR_FINGER) after two
# seconds at rest, cues learnt: vortex 01 swirled from the rim, healing the swirl's seam then the knob's; maelstrom 01's
# glass turned from the bezel, then its three knobs; vortex 02 with knob 3 seized, the glass turned from the bezel, a
# knob, the swirl from the glass's edge and a knob, at par 4 for its turn.
# The strips keep the tank and the glyphs' room over twelve, whatever size the simulator records at.
rim="crop=iw:ih*0.56:0:ih*0.21,fps=3"
for v in knob bands glyphs; do
  film "rim-$v-swirl" 10 "$rim,scale=220:-1,tile=8x4:padding=4" TIER=vortex LEVEL=1 SWIRLED=1 TANKTURNED=1 RIM=$v FINGER=1 \
    MOVES=4:-4,0:-3
  film "rim-$v-seized" 14 "$rim,scale=220:-1,tile=9x5:padding=4" TIER=maelstrom LEVEL=1 SWIRLED=1 TANKTURNED=1 RIM=$v FINGER=1 \
    MOVES=-1:+1,2:+8,3:-7,0:+4
  film "rim-$v-both" 15 "$rim,scale=220:-1,tile=9x5:padding=4" TIER=vortex LEVEL=2 SEIZED=3 PAR=4 SWIRLED=1 TANKTURNED=1 RIM=$v \
    FINGER=1 MOVES=-1:+1,0:+8,4:+7,1:-4
done
# The swirl's push, knob cue: vortex 01's swirl healed, then stirred again over knob 0's seam, which stacks it (red on the
# cue's ring inside the glass), turned straight back and knob 0 healed. Its count sits inside the ticks throughout.
film rim-knob-swirl-push 12 "$rim,scale=220:-1,tile=9x4:padding=4" TIER=vortex LEVEL=1 SWIRLED=1 TANKTURNED=1 FINGER=1 \
  MOVES=4:-4,4:+3,4:-3,0:-3
# A cold first touch where the rim does both, knob cue: vortex 02 with knob 3 seized, both lessons up, the fingertip
# landing on the swirl's ticks inside the glass's edge, where its lesson points, and stirring with the swirl.
film rim-knob-both-cold 8 "$rim,scale=220:-1,tile=8x3:padding=4" TIER=vortex LEVEL=2 SEIZED=3 PAR=4 FINGER=1 MOVES=4:+7
# Vortex's own family, a pitch: each candidate on vortex 01 (UNSTIR_PICTURE), the swirl healed from the rim, stirred
# back the other way, healed again and stirred on, so the whole tank winds over the picture and unwinds.
for p in isobars ephemeris cords; do
  film "vortex-family-$p" 10 "$tank,fps=3,scale=220:-1,tile=8x4:padding=4" TIER=vortex LEVEL=1 SWIRLED=1 FINGER=1 PICTURE=$p \
    MOVES=4:-4,4:-4,4:+4,4:+6
done
