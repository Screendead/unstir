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
# The rim, played by a drawn fingertip (UNSTIR_FINGER) after two seconds at rest, its lessons learnt: vortex 01 swirled
# from the rim, healing the swirl's seam then the knob's; maelstrom 01's glass turned from the bezel, then its three
# knobs; vortex 02 with knob 3 seized, the glass turned from the bezel, a knob, the swirl from the glass's edge and a
# knob, at par 4 for its turn.
# The strips keep the tank and the room over twelve, whatever size the simulator records at.
rim="crop=iw:ih*0.56:0:ih*0.21,fps=3"
film rim-swirl 10 "$rim,scale=220:-1,tile=8x4:padding=4" TIER=vortex LEVEL=1 SWIRLED=1 TANKTURNED=1 FINGER=1 MOVES=4:-4,0:-3
film rim-seized 14 "$rim,scale=220:-1,tile=9x5:padding=4" TIER=maelstrom LEVEL=1 SWIRLED=1 TANKTURNED=1 FINGER=1 \
  MOVES=-1:+1,2:+8,3:-7,0:+4
film rim-both 15 "$rim,scale=220:-1,tile=9x5:padding=4" TIER=vortex LEVEL=2 SEIZED=3 PAR=4 SWIRLED=1 TANKTURNED=1 FINGER=1 \
  MOVES=-1:+1,0:+8,4:+7,1:-4
# The swirl's push: vortex 01's swirl healed, then stirred again over knob 0's seam, which stacks it (a red ring just
# inside the glass's edge), turned straight back and knob 0 healed.
film rim-swirl-push 12 "$rim,scale=220:-1,tile=9x4:padding=4" TIER=vortex LEVEL=1 SWIRLED=1 TANKTURNED=1 FINGER=1 \
  MOVES=4:-4,4:+3,4:-3,0:-3
# The swirl's breath on vortex 01, the swirl never stirred, so its lesson shows: after the opening, a slosh 1.5 s after
# the tank is the player's and another 12 s later. Then a fingertip landing on the rim 0.4 s into the first slosh, near
# its furthest, the breath fading out under the swirl's own turn as it heals the swirl's seam; and the same on knob 0,
# whose turn stacks.
film breath-rest 19 "crop=iw:ih*0.56:0:ih*0.21,fps=4,scale=180:-1,tile=11x7:padding=4" TIER=vortex LEVEL=1 TANKTURNED=1 OPEN=1
film breath-grab 7 "crop=iw:ih*0.56:0:ih*0.21,fps=10,scale=180:-1,tile=10x7:padding=4" TIER=vortex LEVEL=1 \
  TANKTURNED=1 FINGER=1 REST=1.9 MOVES=4:-4
film breath-grab-knob 7 "crop=iw:ih*0.56:0:ih*0.21,fps=10,scale=180:-1,tile=10x7:padding=4" TIER=vortex LEVEL=1 \
  TANKTURNED=1 FINGER=1 REST=1.9 MOVES=0:+1
# A cold first touch where the rim does both: vortex 02 with knob 3 seized, both lessons up, the fingertip
# landing inside the glass's edge, where the swirl's lesson points, and stirring with the swirl.
film rim-both-cold 8 "$rim,scale=220:-1,tile=8x3:padding=4" TIER=vortex LEVEL=2 SEIZED=3 PAR=4 FINGER=1 MOVES=4:+7
# Vortex's own family, each on vortex 01's tank (isobars' own level; UNSTIR_PICTURE for the others): the swirl healed
# from the rim, stirred back the other way, healed again and stirred on, so the whole tank winds over the picture and
# unwinds.
for p in isobars ephemeris cords; do
  film "vortex-family-$p" 10 "$tank,fps=3,scale=220:-1,tile=8x4:padding=4" TIER=vortex LEVEL=1 SWIRLED=1 FINGER=1 PICTURE=$p \
    MOVES=4:-4,4:-4,4:+4,4:+6
done
# First Stir 01, sunrise: the opening stirs the wrecked dawn in, then autoplay heals its four entries 2.5 s apart. Each
# heal steps the clock back and winds the sky back a quarter of its window, the sun sinking and the smoke going; the
# second, third and fourth play the lantern, the boat and the cottage, each a 0.4 s cross-fade in its core.
film firststir-01-solve 25 "$tank,fps=1.5,scale=200:-1,tile=9x4:padding=4" PACK=first-stir LEVEL=1 OPEN=1 AUTOPLAY=1 PACE=2.5
# The heal ring: a push on the lighthouse's rod (red), turned back (white, nothing plays), the boat's top entry healed
# (no vignette plays; the clock steps back), then the lighthouse's heal (magenta, its vignette).
film firststir-01-ring 14 "$tank,fps=2,scale=200:-1,tile=11x2:padding=4" PACK=first-stir LEVEL=1 MOVES=0:+2,0:-2,1:-2,0:-3 PACE=2.2
# A scene from each chapter unstirred by a drawn fingertip, every heal stepping the clock back and each vignette playing
# as its rod's last entry goes: sunrise (1), the lantern chain (8), the kitchen, flooded (14), the harbour at the
# storm's peak (16) and first stir (25), whose solve runs on into the night forwards.
fs="OWNED=first-stir FINGER=1 PACK=first-stir"
film firststir-ch1-sunrise 20 "$tank,fps=1,scale=200:-1,tile=10x2:padding=4" $fs LEVEL=1 MOVES=1:-2,0:-3,1:+4,2:-5
film firststir-ch2-chain 30 "$tank,fps=1,scale=200:-1,tile=10x3:padding=4" $fs LEVEL=8 MOVES=1:+3,0:-2,3:+5,2:+2,1:-5,0:+3,3:-4
film firststir-ch3-kitchen 33 "$tank,fps=1,scale=200:-1,tile=11x3:padding=4" $fs LEVEL=14 MOVES=1:-4,2:-2,3:-3,1:+2,2:+4,1:-5,3:+3,0:-4
film firststir-ch4-harbour 33 "$tank,fps=1,scale=200:-1,tile=11x3:padding=4" $fs LEVEL=16 MOVES=0:-3,1:-2,0:+4,1:-5,2:+2,0:-3,1:+4,2:-5
film firststir-ch5-stir 34 "$tank,fps=1,scale=200:-1,tile=12x3:padding=4" $fs LEVEL=25 MOVES=1:+3,0:-2,1:-5,0:+3,2:-4
# The night forwards whole, from First Stir 25 opened solved (UNSTIR_ENDING=-1 runs it from the start).
film firststir-ending 168 "$tank,fps=0.2,scale=160:-1,tile=8x4:padding=4" PACK=first-stir LEVEL=25 OWNED=first-stir SCREEN=clean ENDING=-1
# Prism, played by a drawn fingertip: specimen 1 heals the red rod buried under the cyan one first, which its colour
# frees, then the cyan, then the white bottom stir; specimen 5 on pent heals the solver's line, red and cyan words
# interleaved, the white last, owned since it is past the taste.
film prism-01-solve 13 "$tank,fps=2,scale=200:-1,tile=9x3:padding=4" PACK=prism LEVEL=1 FINGER=1 MOVES=0:-4,1:+3,2:-3
film prism-05-solve 24 "$tank,fps=1.5,scale=200:-1,tile=9x4:padding=4" PACK=prism LEVEL=5 OWNED=prism FINGER=1 \
  MOVES=0:+3,1:-2,0:-4,2:-5,3:-4,4:-3,2:+3
# The pack dock on the menu, Lens's cover tapped, its card grown out of it and its clip played through, then back
# (UNSTIR_SHELFDEMO, through the calls a finger makes).
film shelf-card 15 "fps=2,scale=180:-1,tile=15x2:padding=4" SHELFDEMO=1 STORE=lens:unowned
# Each card's clip (`Clip`), twice round its loop.
clip=crop=1100:1180:110:610  # the card's clip and First Stir's time under it
# A Debug build bakes Lens's halftone some 20 s the first time a size is asked for; one launch caches it for the films.
if [[ -z "$pattern" || clip-lens == *$pattern* || clip-complete == *$pattern* ]]; then
  SIMCTL_CHILD_UNSTIR_CARD=lens xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
  sleep 25
fi
film clip-first-stir 16 "$clip,fps=3,scale=200:-1,tile=12x4:padding=4" CARD=first-stir STORE=lens:unowned
film clip-lens 16 "$clip,fps=3,scale=200:-1,tile=12x4:padding=4" CARD=lens STORE=lens:unowned
film clip-escapement 16 "$clip,fps=3,scale=200:-1,tile=12x4:padding=4" CARD=escapement STORE=lens:unowned
film clip-prism 16 "$clip,fps=3,scale=200:-1,tile=12x4:padding=4" CARD=prism STORE=lens:unowned
film clip-complete 18 "$clip,fps=3,scale=200:-1,tile=12x4:padding=4" CARD=complete STORE=lens:unowned
# The menu's dock of covers, which keep their own loops.
film shelf-dock 9 "crop=1320:420:0:2380,fps=2,scale=440:-1,tile=4x4:padding=4" STORE=lens:unowned
# Escapement 1: the demonstration a first-time player sees before the first stir (a heal ticks the clock, a wait ticks it
# again, then the problem winds in), and lines played by a drawn fingertip: won, and a slip whose tick pushes, played on
# until the ticks run out. A ratchet's move (0:1) is a tap on it. Screen, so the header's budget shows with the tank.
film escapement-demo 14 "$tank,fps=3,scale=200:-1,tile=8x6:padding=4" PACK=escapement OPEN=1
film escapement-won 12 "$tank,fps=3,scale=200:-1,tile=8x5:padding=4" PACK=escapement LEVEL=2 FINGER=1 REST=1 MOVES=2:4,0:1,1:-3
screen=crop=iw:ih*0.75:0:ih*0.05  # the header and the tank, the budget's flaps with the clocks, at either scale
film escapement-out-of-ticks 15 "$screen,fps=3,scale=150:-1,tile=9x5:padding=4" PACK=escapement LEVEL=2 FINGER=1 REST=1 MOVES=2:4,1:-3,0:1
# Out of ticks as the clock stops with twists left: on 3, a tap, then knob 1, which pushes under knob 2's seam as the
# clock stops.
film escapement-stopped 11 "$tank,fps=3,scale=200:-1,tile=8x4:padding=4" PACK=escapement LEVEL=3 FINGER=1 REST=1 MOVES=0:1,1:-3
# Clean solves of the book's lines: 17's two clocks, the first uncovering the second's seam on every move, and 29's three,
# with its two taps (a ratchet's move, 1:1).
film escapement-two-clocks 19 "$tank,fps=2,scale=200:-1,tile=8x5:padding=4" PACK=escapement OWNED=escapement LEVEL=17 FINGER=1 REST=1 \
  MOVES=3:-5,4:-2,3:5,4:3,3:-4
# 16's line, the budget's flaps falling two a move while both clocks run, then one: 09 to 00 as clock 4 stops.
film escapement-budget-16 22 "$screen,fps=2,scale=150:-1,tile=11x4:padding=4" PACK=escapement OWNED=escapement LEVEL=16 FINGER=1 REST=1 \
  MOVES=3:-2,5:-2,1:1,6:-4,5:3,2:-5
# Each clock's flip count in its hub (ES2): 16's line clean, each hub flipping with its own clock's ticks and greying at
# 0 as its rod empties; and a wrong 6:-4 whose tick pushes clock 1's last, then waits on clock 4 out of ticks.
film escapement-hubs-16 22 "$screen,fps=2,scale=150:-1,tile=11x4:padding=4" PACK=escapement OWNED=escapement LEVEL=16 FINGER=1 REST=1 \
  MOVES=3:-2,5:-2,1:1,6:-4,5:3,2:-5
film escapement-hubs-16-wrong 20 "$screen,fps=2,scale=150:-1,tile=10x4:padding=4" PACK=escapement OWNED=escapement LEVEL=16 FINGER=1 REST=1 \
  MOVES=3:-2,5:-2,6:-4,4:1,4:1,4:1
film escapement-three-clocks 28 "$tank,fps=2,scale=160:-1,tile=10x6:padding=4" PACK=escapement OWNED=escapement LEVEL=29 FINGER=1 REST=1 \
  MOVES=4:-3,1:1,2:-2,1:1,2:-4,0:5,2:-3,4:-3
# Escapement 7, whose first move is a wait: a tap halfway out the clock's disc (0:2), then one on its ratchet (0:1),
# then the line.
film escapement-tap 15 "$tank,fps=3,scale=200:-1,tile=9x5:padding=4" PACK=escapement OWNED=escapement LEVEL=7 FINGER=1 REST=1 \
  MOVES=0:2,0:1,1:2,2:-3
# Lens: a launch first bakes the halftone into Caches, which takes 20 s or more in Debug; the films then read it.
if [[ -z "$pattern" || lens == *$pattern* || "$pattern" == lens* ]]; then
  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
  SIMCTL_CHILD_UNSTIR_PACK=lens xcrun simctl launch "$udid" "$bundle" >/dev/null
  sleep 35
fi
# The rim band on each rod size while it moves, for glitter: a drawn fingertip zooms the lens in a step at a time to +3,
# twists its neighbour two steps over it and back, zooms it out and heals the neighbour.
for size in "big tri 0 1" "mid quad 0 1" "small eye 2 0"; do
  read -r name layout lens twist <<< "$size"
  film "lens-glitter-$name" 15 "$tank,fps=3,scale=220:-1,tile=9x5:padding=4" PACK=lens LEVEL=1 LAYOUT=$layout LENSES=$lens \
    STACK=$twist:+4 FINGER=1 REST=1 MOVES=$lens:+1,$lens:+1,$lens:+1,$twist:+2,$twist:-2,$lens:-3,$twist:-4
done
# Two Lens levels solved by a drawn fingertip at par, the order read off the rims: 08 on quad, its lenses on small rods
# (radius 0.48), and 12 on eye, both big rods (0.58) lenses. A lens's move rides up and down; dealt lenses come out
# dragging down.
film lens-08-solve 19 "$tank,fps=1.5,scale=220:-1,tile=7x4:padding=4" PACK=lens LEVEL=8 OWNED=lens FINGER=1 REST=2.5 \
  MOVES=0:-1,1:+5,2:-3,3:+3,0:-2,1:-4
film lens-12-solve 21 "$tank,fps=1.5,scale=220:-1,tile=8x4:padding=4" PACK=lens LEVEL=12 OWNED=lens FINGER=1 REST=2.5 \
  MOVES=3:-5,0:-1,2:+2,1:-3,3:+4,0:-2,2:-3
