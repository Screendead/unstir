#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/prism-read-films.sh <out dir>
# Joins `scripts/film.sh prism-read-`'s takes, one film a move: today's glass and the three trials of reading it under
# a held rod (UNSTIR_PRISMREAD), the same slow sweep in each, cut from just before the fingertip lands to just before
# it lifts and captioned (Pillow, as this ffmpeg has no drawtext). Each is kept under 1.5 MB (needs ffmpeg).
set -euo pipefail
cd "$(dirname "$0")/.."
out=$1
mkdir -p "$out" build/prism-read
python3 - <<'PY'
from PIL import Image, ImageDraw, ImageFont
font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 26)
im = Image.new("RGBA", (1080, 1080), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
for i, text in enumerate(["today", "A  the other colours dim", "B  the rod's colours in white", "C  out of register dims"]):
    d.text((14 + 540 * (i % 2), 10 + 540 * (i // 2)), text, font=font, fill=(255, 255, 255, 255))
im.save("build/prism-read/captions.png")
PY
join() {  # move steps file-name
  local move=$1 n=$2 name=$3 v inputs=() graph="" i=0 len
  # 1.5 s of rest less the second kept, the 0.45 s the fingertip holds, the sweep, and the 0.25 s before it lifts.
  len=$(awk -v n="$n" 'BEGIN { print 1 + 0.45 + 0.7 * n + 0.2 }')
  for v in today a b c; do
    local take="shots/film/prism-read-$v-$move.mp4" from
    from=$(awk -v s="$(scripts/strike.sh "$take")" 'BEGIN { print s + 0.7 }')
    inputs+=(-fflags +igndts -i "$take")
    graph+="[$i:v]fps=30,trim=start=$from:duration=$len,setpts=PTS-STARTPTS,crop=1200:1200:60:820,scale=540:540[v$i];"
    i=$((i + 1))
  done
  local crf
  for crf in 24 27 30 33; do
    ffmpeg -loglevel error -y "${inputs[@]}" -i build/prism-read/captions.png -filter_complex \
      "$graph[v0][v1][v2][v3]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[g];[g][4:v]overlay=shortest=0[o]" \
      -map "[o]" -t "$len" -c:v libx264 -preset slow -crf $crf -pix_fmt yuv420p -movflags +faststart -an "$out/$name.mp4"
    (( $(stat -f %z "$out/$name.mp4") < 1500000 )) && break
  done
  echo "$name.mp4 $(stat -f %z "$out/$name.mp4") bytes, crf $crf"
}
join 01-cyan 4 1-frond-cyan-rod
join 01-red 5 2-frond-red-rod
join 01-white 4 3-frond-white-rod
join 08-blue 5 4-thistle-blue-rod
join 15-magenta 6 5-sea-nettle-magenta-rod-stirred-twice
join 30-yellow 3 6-last-specimen-yellow-rod-stirred-twice
