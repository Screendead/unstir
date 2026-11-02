#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/editors-film.sh [--join]   Films the editors' reel's segments (scripts/film.sh editors-) and joins them
# into shots/film/editors-reel.mp4, about a minute of the later tiers and two packs for the App Store nomination's
# supplemental links. --join only joins segments already filmed. Takes the simulator scripts/film.sh takes (UNSTIR_SIM).
set -euo pipefail
cd "$(dirname "$0")/.."

# Each segment and the seconds it keeps from the picture's strike: the opening, the moves and the solve's wave, cut
# before the result card.
segments=(
  editors-whirlpool-03:13.5
  editors-vortex-02:11
  editors-maelstrom-01:13.5
  editors-escapement-02:10
  editors-prism-01:11.5
)

[[ "${1:-}" == --join ]] || scripts/film.sh editors-

inputs=() chains="" labels=""
for i in "${!segments[@]}"; do
  name=${segments[i]%%:*} keep=${segments[i]##*:} mp4="shots/film/${segments[i]%%:*}.mp4"
  # From just before the picture strikes: past the home screen (bright) and the app's black, whose wait varies with what
  # the launch compiles.
  start=$(ffprobe -v error -f lavfi -i "movie=$mp4,signalstats" -show_entries frame=pts_time:frame_tags=lavfi.signalstats.YAVG \
    -of csv=p=0 | awk -F, '$2 >= 40 { lit = 1 } lit && $2 < 40 && dark == "" { dark = $1; floor = $2 }
      dark != "" && on == "" { if ($2 < floor) floor = $2; if ($1 > dark + 0.3 && $2 > floor + 0.6) on = $1 }
      END { print (on > 0.2 ? on - 0.2 : 0) }')
  inputs+=(-i "$mp4")
  # recordVideo writes a frame only when the screen changes, so fps= first; film.sh may have shrunk a large segment,
  # so every one is scaled to the same size.
  chains+="[$i:v]trim=start=${start:-0}:duration=$keep,setpts=PTS-STARTPTS,fps=30,scale=1080:2346,setsar=1[v$i];"
  labels+="[v$i]"
  echo "$name from ${start:-0} s, $keep s"
done
ffmpeg -loglevel error -y "${inputs[@]}" -filter_complex "${chains}${labels}concat=n=${#segments[@]}:v=1:a=0[out]" \
  -map "[out]" -c:v libx264 -crf 22 -preset slow -pix_fmt yuv420p -movflags +faststart shots/film/editors-reel.mp4
echo "joined shots/film/editors-reel.mp4: $(ffprobe -v error -show_entries format=duration -of csv=p=0 shots/film/editors-reel.mp4) s"
