#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/store-media.sh [screens|preview|social|sound|all] [--cut]
# The App Store's media (Jack's calls ST4 and ST5 = A, docs/store-page.md) and plan step 3's social clips, from the
# harness, into $STORE_OUT (shots/store unless set):
#   screens/   the ten screenshots (shots.sh store-) at 1320 x 2868, RGB without alpha, each also captioned
#   preview/   the free-game preview, captioned for muted playback: 25 s (Jack's call STOREMEDIA = B), or
#              $STORE_PREVIEW s, from 15.6 (each segment keeping a second) to the segments' whole 27.6
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

# Seconds into take $1 to start from, $2 after just before its picture strikes, for $3 s, which the take must hold at the
# screen's full size: a shrunk take, or one from another simulator, would be scaled into the store's sizes unasked.
span() {
  local mp4="shots/film/$1.mp4" s size length
  size=$(ffprobe -v error -select_streams v -show_entries stream=width,height -of csv=s=x:p=0 "$mp4")
  [[ "$size" == 1320x2868 ]] || { echo "$1: its take is $size, not 1320x2868; film it again (FILM_FULL=1 scripts/film.sh '$1\$')" >&2; exit 1; }
  s=$(scripts/strike.sh "$mp4")
  [[ -n "$s" ]] || { echo "$1: no picture struck in its take; film it again (scripts/film.sh '$1\$')" >&2; exit 1; }
  s=$(awk -v a="$s" -v b="$2" 'BEGIN { print a + b }')
  # A take ending on a still screen has no frame after its last change; film.sh notes how long it really ran.
  length=$(ffprobe -v error -show_entries format_tags=comment -of csv=p=0 "$mp4" | awk '/^take / { print $2 }')
  [[ -n "$length" ]] || length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$mp4")
  awk -v a="$s" -v k="$3" -v l="$length" 'BEGIN { exit !(a + k <= l) }' ||
    { echo "$1: keeping $3 s from $s s runs past its take's end at $length s; film it longer" >&2; exit 1; }
  echo "$s"
}

if [[ "$what" == screens || "$what" == all ]]; then
  [[ "$cut" == --cut ]] || scripts/shots.sh store-
  python3 scripts/store-captions.py screens shots "$out/screens"
fi

# Each segment: film case, seconds after the strike it starts, seconds it keeps in the whole 27.6 s, the end it gives up
# to a shorter preview (head, tail, or - for none), caption. A strike is the bezel lighting, about a second before the
# picture; a keep that ends on a solve runs a second or more past its wave, as the time from strike to solve varies from
# take to take, so whirlpool 03 keeps its whole solve. The others give up the same share each: open-L12 its rest after
# the wind-in, the rim's two their rest before the finger lands, endless its pushes before the spill.
preview=(
  "store-open-L12|0.3|4|tail|A picture, stirred"
  "store-whirlpool-03|2.8|10.6|-|Turn the rods back in order"
  "rim-swirl|1|4.5|head|Vortex: the swirl"
  "rim-seized|1.8|4.5|head|Maelstrom: the tank turns"
  "endless-brim-run|4.5|4|head|Endless, and a daily"
)
if [[ "$what" == preview || "$what" == all ]]; then
  target=${STORE_PREVIEW:-25} whole=0 giving=0 least="" names=()
  for seg in "${preview[@]}"; do
    IFS='|' read -r name from keep gives words <<< "$seg"
    names+=("$name")
    whole=$(awk -v a="$whole" -v k="$keep" 'BEGIN { print a + k }')
    [[ "$gives" == - ]] && continue
    giving=$((giving + 1))
    least=$(awk -v a="${least:-$keep}" -v k="$keep" 'BEGIN { print (k < a ? k : a) }')
  done
  # Checked before filming: every segment that gives keeps at least a second.
  floor=$(awk -v w="$whole" -v g="$giving" -v k="$least" 'BEGIN { f = w - g * (k - 1); print (f > 15 ? f : 15) }')
  awk -v l="$target" -v f="$floor" -v w="$whole" 'BEGIN { exit !(l >= f && l <= 30 && l <= w) }' ||
    { echo "preview: STORE_PREVIEW is $target; it takes $floor to $whole s (Apple's 15 to 30, a second a segment)" >&2; exit 1; }
  share=$(awk -v l="$target" -v w="$whole" -v g="$giving" 'BEGIN { print (w - l) / g }')
  take "${names[@]}"
  mkdir -p "$out/preview"
  inputs=() chains="" labels="" n=${#preview[@]}
  for i in "${!preview[@]}"; do
    IFS='|' read -r name from keep gives words <<< "${preview[i]}"
    if [[ "$gives" != - ]]; then
      [[ "$gives" == head ]] && from=$(awk -v f="$from" -v s="$share" 'BEGIN { print f + s }')
      keep=$(awk -v k="$keep" -v s="$share" 'BEGIN { print k - s }')
    fi
    start=$(span "$name" "$from" "$keep")
    python3 scripts/store-captions.py film "$words" "$work/caption-$i.png"
    inputs+=(-fflags +igndts -i "shots/film/$name.mp4" -i "$work/caption-$i.png")  # dts ignored, as film.sh says
    # recordVideo writes a frame only when the screen changes, so fps= before the trim, which would otherwise start on
    # the first change after it, and tpad holds the last frame to the keep's end.
    chains+="[$((2 * i)):v]fps=30,trim=start=$start:duration=$keep,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=$keep,trim=duration=$keep,scale=1320:2868,setsar=1[f$i];"
    chains+="[f$i][$((2 * i + 1)):v]overlay=0:0[v$i];"
    labels+="[v$i]"
    echo "preview: $name from $start s, $keep s, \"$words\""
  done
  # 1320 x 2868 is 886 x 1925 at the preview's width: the 5 rows over go off the bottom, under the controls.
  ffmpeg -loglevel error -y "${inputs[@]}" -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -filter_complex "${chains}${labels}concat=n=$n:v=1:a=0,scale=886:1925,crop=886:1920:0:0,setsar=1[out]" \
    -map "[out]" -map "$((2 * n)):a" -shortest -t "$target" -r 30 -c:v libx264 -profile:v high -level 4.0 -b:v 11M \
    -maxrate 12M -bufsize 24M -preset slow -pix_fmt yuv420p -c:a aac -b:a 256k -movflags +faststart "$out/preview/preview.mp4"
  length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out/preview/preview.mp4")
  echo "preview: $length s"
  awk -v l="$length" 'BEGIN { exit !(l >= 15 && l <= 30) }' || { echo "preview: Apple takes 15 to 30 s" >&2; exit 1; }
fi

# Each clip: film case, seconds after the strike it starts, seconds it keeps. The clean takes show the picture alone
# (no finger, knob or count); store-whirlpool-03 shows the hand and the game round it.
social=(
  "clean-plughole-05|0|13.2"
  "clean-whirlpool-01|0|10.7"
  "editors-vortex-02|0|12"
  "store-whirlpool-03|0|13.9"
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
    start=$(span "$name" "$from" "$keep")
    suffix="" audio=(-an)
    if [[ "$what" == sound ]]; then
      suffix=-sound audio=(-map 0:a -c:a aac -b:a 256k -af "atrim=start=$start:duration=$keep,asetpts=PTS-STARTPTS,loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=out:st=$(awk -v k="$keep" 'BEGIN { print k - 0.3 }'):d=0.3,apad")
    fi
    # 9:16 out of the 1320 x 2868 screen, centred on the tank.
    ffmpeg -loglevel error -y -fflags +igndts -i "shots/film/$name.mp4" -map 0:v \
      -vf "fps=30,trim=start=$start:duration=$keep,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=$keep,scale=1320:2868,crop=1320:2347:0:252,scale=1080:1920,setsar=1" \
      "${audio[@]}" -t "$keep" -c:v libx264 -profile:v high -crf 18 -preset slow -pix_fmt yuv420p -movflags +faststart "$out/social/$name$suffix.mp4"
    echo "social: $name$suffix from $start s, $keep s"
  done
fi
