#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/store-media.sh [screens|preview|social|sound|all] [--cut]
# The App Store's media (Jack's calls ST4 and ST5 = A, docs/store-page.md) and plan step 3's social clips, from the
# harness, into $STORE_OUT (shots/store unless set):
#   screens/   the ten screenshots (shots.sh store-) at 1320 x 2868, RGB without alpha, each also captioned
#   preview/   the 25 s free-game preview, captioned for muted playback
#   social/    short vertical clips of a picture snapping back, 1080 x 1920, silent; with sound, each again as
#              <name>-sound.mp4 (sound, which all leaves out, as it takes the Mac's audio output while it films)
# --cut reuses the shots and films already taken. Takes the simulator shots.sh and film.sh take (UNSTIR_SIM); needs
# ffmpeg and Pillow.
# Apple's numbers (App Store Connect help, "Screenshot specifications" and "App preview specifications", read
# 2026-11-02): iPhone with Dynamic Island (large display) screenshots 1320 x 2868 portrait, PNG or JPEG, no alpha, up to
# ten; previews 886 x 1920 portrait, 15 to 30 s, at most 30 fps, H.264 High up to level 4.0 at 10-12 Mbps, audio stereo
# AAC 256 kbps at 44.1 or 48 kHz. The page doesn't say a preview needs audio, so it carries a silent track.
set -euo pipefail
cd "$(dirname "$0")/.."
what=${1:-all} cut=${2:-}
out=${STORE_OUT:-shots/store}
export FILM_FULL=1
work=$(mktemp -d)
trap 'trash "$work" 2>/dev/null || true' EXIT

take() {  # film.sh case...
  [[ "$cut" == --cut ]] && return
  for name in "$@"; do scripts/film.sh "$name\$"; done
}

# Seconds into a take from just before its picture strikes.
struck() {
  local s
  s=$(scripts/strike.sh "shots/film/$1.mp4")
  [[ -n "$s" ]] || { echo "$1: no picture struck in its take; film it again (scripts/film.sh $1)" >&2; exit 1; }
  echo "$s"
}

if [[ "$what" == screens || "$what" == all ]]; then
  [[ "$cut" == --cut ]] || scripts/shots.sh store-
  python3 scripts/store-captions.py screens shots "$out/screens"
fi

# Each segment: film case, seconds after the strike it starts, seconds it keeps, caption.
preview=(
  "store-open-L12|0.3|4|A picture, stirred"
  "store-whirlpool-03|2.4|8|Turn the rods back in order"
  "rim-swirl|1|4.5|Vortex: the swirl"
  "rim-seized|1.8|4.5|Maelstrom: the tank turns"
  "endless-brim-run|4.5|4|Endless, and a daily"
)
if [[ "$what" == preview || "$what" == all ]]; then
  names=()
  for seg in "${preview[@]}"; do names+=("${seg%%|*}"); done
  take "${names[@]}"
  mkdir -p "$out/preview"
  inputs=() chains="" labels="" n=${#preview[@]}
  for i in "${!preview[@]}"; do
    IFS='|' read -r name from keep words <<< "${preview[i]}"
    start=$(struck "$name")
    start=$(awk -v a="$start" -v b="$from" 'BEGIN { print a + b }')
    python3 scripts/store-captions.py film "$words" "$work/caption-$i.png"
    inputs+=(-i "shots/film/$name.mp4" -i "$work/caption-$i.png")
    # recordVideo writes a frame only when the screen changes, so fps= first.
    chains+="[$((2 * i)):v]trim=start=$start:duration=$keep,setpts=PTS-STARTPTS,fps=30,trim=duration=$keep,scale=1320:2868,setsar=1[f$i];"
    chains+="[f$i][$((2 * i + 1)):v]overlay=0:0[v$i];"
    labels+="[v$i]"
    echo "preview: $name from $start s, $keep s, \"$words\""
  done
  # 1320 x 2868 is 886 x 1925 at the preview's width: the 5 rows over go off the bottom, under the controls.
  ffmpeg -loglevel error -y "${inputs[@]}" -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -filter_complex "${chains}${labels}concat=n=$n:v=1:a=0,scale=886:1925,crop=886:1920:0:0[out]" \
    -map "[out]" -map "$((2 * n)):a" -shortest -r 30 -c:v libx264 -profile:v high -level 4.0 -b:v 11M -maxrate 12M \
    -bufsize 24M -preset slow -pix_fmt yuv420p -c:a aac -b:a 256k -movflags +faststart "$out/preview/preview.mp4"
  echo "preview: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out/preview/preview.mp4") s"
fi

# Each clip: film case, seconds after the strike it starts, seconds it keeps. The clean takes show the picture alone
# (no finger, knob or count); store-whirlpool-03 shows the hand and the game round it.
social=(
  "clean-plughole-05|0|11.5"
  "clean-whirlpool-01|0|10"
  "editors-vortex-02|0|9.4"
  "store-whirlpool-03|0|11.5"
)
# sound: the same clips with the game's sound, played through BlackHole (Homebrew's blackhole-2ch and switchaudio-osx),
# which is the Mac's output for the takes and nothing else; the output goes back however the script ends.
if [[ "$what" == sound && "$cut" != --cut ]]; then
  output=$(SwitchAudioSource -c -t output)
  trap 'SwitchAudioSource -t output -s "$output" >/dev/null; trash "$work" 2>/dev/null || true' EXIT
  SwitchAudioSource -t output -s "BlackHole 2ch" >/dev/null
  export FILM_SOUND=1
fi
if [[ "$what" == social || "$what" == sound || "$what" == all ]]; then
  names=()
  for clip in "${social[@]}"; do names+=("${clip%%|*}"); done
  take "${names[@]}"
  [[ -n "${output:-}" ]] && SwitchAudioSource -t output -s "$output" >/dev/null
  mkdir -p "$out/social"
  for clip in "${social[@]}"; do
    IFS='|' read -r name from keep <<< "$clip"
    start=$(struck "$name")
    start=$(awk -v a="$start" -v b="$from" 'BEGIN { print a + b }')
    suffix="" audio=(-an)
    if [[ "$what" == sound ]]; then
      suffix=-sound audio=(-map 0:a -c:a aac -b:a 256k -af "loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=out:st=$(awk -v k="$keep" 'BEGIN { print k - 0.3 }'):d=0.3")
    fi
    # 9:16 out of the 1320 x 2868 screen, centred on the tank.
    ffmpeg -loglevel error -y -ss "$start" -t "$keep" -i "shots/film/$name.mp4" -map 0:v \
      -vf "fps=30,scale=1320:2868,crop=1320:2347:0:252,scale=1080:1920,setsar=1" "${audio[@]}" \
      -c:v libx264 -profile:v high -crf 18 -preset slow -pix_fmt yuv420p -movflags +faststart "$out/social/$name$suffix.mp4"
    echo "social: $name$suffix from $start s, $keep s"
  done
fi
