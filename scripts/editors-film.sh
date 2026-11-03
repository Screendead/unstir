#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/editors-film.sh [--join]   Films the editors' reel's segments (scripts/film.sh editors-) and joins them
# into shots/film/editors-reel.mp4, about a minute of the later tiers and three packs for the App Store nomination's
# supplemental links. --join only joins segments already filmed. Takes the simulator scripts/film.sh takes (UNSTIR_SIM).
set -euo pipefail
cd "$(dirname "$0")/.."

# Each segment and the seconds it keeps from the picture's strike: the opening, the moves and the solve's wave, cut
# before the result card.
segments=(
  editors-whirlpool-03:12.2
  editors-vortex-02:9.4
  editors-maelstrom-01:13
  editors-lens-03:8.7
  editors-escapement-02:8.7
  editors-prism-01:9.8
)

[[ "${1:-}" == --join ]] || scripts/film.sh editors-

inputs=() chains="" labels=""
for i in "${!segments[@]}"; do
  name=${segments[i]%%:*} keep=${segments[i]##*:} mp4="shots/film/${segments[i]%%:*}.mp4"
  start=$(scripts/strike.sh "$mp4")
  # A launch that stalls past the take leaves no strike: film that segment again (scripts/film.sh <name>).
  [[ -n "$start" ]] || { echo "$name: no picture struck in its take" >&2; exit 1; }
  inputs+=(-fflags +igndts -i "$mp4")  # dts ignored, as scripts/film.sh says
  # recordVideo writes a frame only when the screen changes, so fps= first; film.sh may have shrunk a large segment,
  # so every one is scaled to the same size.
  chains+="[$i:v]trim=start=$start:duration=$keep,setpts=PTS-STARTPTS,fps=30,scale=1080:2346,setsar=1[v$i];"
  labels+="[v$i]"
  echo "$name from $start s, $keep s"
done
ffmpeg -loglevel error -y "${inputs[@]}" -filter_complex "${chains}${labels}concat=n=${#segments[@]}:v=1:a=0[out]" \
  -map "[out]" -c:v libx264 -crf 22 -preset slow -pix_fmt yuv420p -movflags +faststart shots/film/editors-reel.mp4
echo "joined shots/film/editors-reel.mp4: $(ffprobe -v error -show_entries format=duration -of csv=p=0 shots/film/editors-reel.mp4) s"
