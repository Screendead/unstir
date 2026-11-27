#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/synthwave-sketches.sh <dir>   Renders round two of the synthwave menu's sketches
# (sound-src/synthwave-sketches.csd) for Jack's ear: each bed as one seamless loop of its 16 bars at -16 LUFS, and each
# swipe, louder, as m4a in <dir>; then measures each bed's seam, each file's loudness, each bed's onsets against its
# beat grid, how much of each bed's bass a phone's speaker keeps, its bass against its round-one bed's, and its share
# of energy in the bands where a top line turns harsh. Round one (outrun, night and dark with four effects each) is
# this script's first commit. Needs Homebrew's csound and ffmpeg, and numpy.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
D=${1:?usage: scripts/synthwave-sketches.sh <dir>}
mkdir -p "$D"
D=$(cd "$D" && pwd)
B=build/synthwave
rm -rf "$B"
mkdir -p "$B"
swiftc -O scripts/sounds.swift -o "$B/tool"
TOOL="$B/tool"

CEILING=-1.2
BED_I=-16
# An effect's loudest 400 ms, over a bed's (about -14 at -16 integrated), as a tap is heard over the music.
FX_M=-11
# name, instrument, tempo, and the round-one bed whose bass line it keeps.
BEDS="
night-bed-2 night2 96 night
night-bed-3 night3 96 night
dark-bed-2 dark2 100 dark
dark-bed-3 dark3 100 dark
hybrid-bed hybrid 100 dark
"
REFS="
night 96
dark 100
"
# name, instrument, and the tempo of the bed it plays over, so its echo falls on that bed's grid.
SWIPES="
night-swipe-e nightSwipeE 100
dark-swipe-d darkSwipeD 96
both-swipe-e swipeBothE 100
both-swipe-d swipeBothD 96
"

# An 8th-order Butterworth highpass at 250 Hz, as four biquads: roughly what an iPhone's speaker keeps (sounds.sh's).
PHONE="highpass=f=250:width_type=q:width=0.50980,highpass=f=250:width_type=q:width=0.60134"
PHONE="$PHONE,highpass=f=250:width_type=q:width=0.89998,highpass=f=250:width_type=q:width=2.56292"

loud() {  # file [filter]: loudest momentary, integrated, true peak
    local filter="apad=pad_dur=0.5"
    [ -n "${2:-}" ] && filter="$2,$filter"
    ffmpeg -hide_banner -nostdin -nostats -i "$1" -af "$filter,ebur128=peak=true:framelog=info" -f null - 2>&1 |
        awk '/ M:/ { sub(/.* M: */, ""); m = $1 + 0; if (!seen || m > max) max = m; seen = 1 }
             /^ *I: / { i = $2 }
             /True peak:/ { tp = 1 }
             tp && /Peak:/ { p = $2; tp = 0 }
             END { printf "%.2f %s %s\n", max, i, p }'
}
gain() {  # measured target peak
    awk -v m="$1" -v t="$2" -v p="$3" -v c="$CEILING" 'BEGIN { g = t - m; if (p + g > c) g = c - p; printf "%.4f\n", g }'
}
render() {  # sketch bpm seconds out [macros...]
    local sk=$1 bpm=$2 dur=$3 out=$4
    shift 4
    (cd sound-src && csound --omacro:SKETCH="$sk" --omacro:BPM="$bpm" --omacro:DUR="$dur" "$@" \
        --omacro:OUT="$ROOT/$out" synthwave-sketches.csd >"$ROOT/$out.log" 2>&1) ||
        { echo "csound failed: $out.log"; tail -20 "$out.log"; exit 1; }
}

pids=()
bed3() {  # name instrument bpm: three periods of the bed, and of its bass alone
    local dur
    dur=$(awk -v b="$3" 'BEGIN { print 3 * 64 * 60 / b }')
    render "$2" "$3" "$dur" "$B/$1-bed3.wav" &
    pids+=($!)
    render "$2" "$3" "$dur" "$B/$1-bass3.wav" --omacro:BASSONLY=1 &
    pids+=($!)
}
while read -r name ins bpm _; do
    [ -z "$name" ] && continue
    bed3 "$name" "$ins" "$bpm"
done <<<"$BEDS"
while read -r ref bpm; do
    [ -z "$ref" ] && continue
    bed3 "ref-$ref" "$ref" "$bpm"
done <<<"$REFS"
while read -r name ins bpm; do
    [ -z "$name" ] && continue
    render "$ins" "$bpm" 1.6 "$B/$name-raw.wav" &
    pids+=($!)
done <<<"$SWIPES"
for pid in "${pids[@]}"; do wait "$pid"; done

# The loop starts a quarter beat before its first downbeat, where nothing strikes: a wrap on an attack reads as a click.
cutloop() {  # name bpm: the second period of the bed and of its bass
    local n lead
    n=$(awk -v b="$2" 'BEGIN { printf "%d", 64 * 60 / b * 48000 }')
    lead=$(awk -v b="$2" 'BEGIN { printf "%d", 0.25 * 60 / b * 48000 }')
    for part in bed bass; do
        ffmpeg -hide_banner -nostdin -v error -y -i "$B/$1-${part}3.wav" \
            -af "atrim=start_sample=$((n - lead)):end_sample=$((2 * n - lead)),asetpts=N/SR/TB" -c:a pcm_f32le \
            "$B/$1-$part-raw.wav"
    done
}
while read -r ref bpm; do
    [ -z "$ref" ] && continue
    cutloop "ref-$ref" "$bpm"
done <<<"$REFS"

PADS="6144 6400 6656 6912 7168 7424 7680 7936"
printf "%-15s %7s %7s %7s\n" file M I TP
while read -r name _ bpm _; do
    [ -z "$name" ] && continue
    n=$(awk -v b="$bpm" 'BEGIN { printf "%d", 64 * 60 / b * 48000 }')
    cutloop "$name" "$bpm"
    read -r _ i p < <(loud "$B/$name-bed-raw.wav")
    g=$(gain "$i" $BED_I "$p")
    "$TOOL" finish "$B/$name-bed-raw.wav" "$B/$name-bed.wav" "$g"
    "$TOOL" finish "$B/$name-bass-raw.wav" "$B/$name-bass.wav" "$g"
    rm -f "$D/$name.m4a"
    for pad in $PADS; do
        "$TOOL" wrap "$B/$name-bed.wav" "$B/$name-bed-wrapped.wav" "$pad"
        afconvert -f m4af -d aac -b 256000 -q 127 "$B/$name-bed-wrapped.wav" "$D/$name.m4a"
        "$TOOL" gapless "$D/$name.m4a" "$pad" "$n"
        "$TOOL" clean "$D/$name.m4a" "$n" && break
        rm "$D/$name.m4a"
    done
    [ -f "$D/$name.m4a" ] || { echo "$name: no AAC loops cleanly"; exit 1; }
    read -r m i p < <(loud "$B/$name-bed.wav")
    printf "%-15s %7s %7s %7s\n" "$name" "$m" "$i" "$p"
done <<<"$BEDS"
while read -r name _ _; do
    [ -z "$name" ] && continue
    # Every effect's first event is scheduled at 20 ms: cut that, so it sounds on the touch.
    ffmpeg -hide_banner -nostdin -v error -y -i "$B/$name-raw.wav" -af "atrim=start_sample=912,asetpts=N/SR/TB" \
        -c:a pcm_f32le "$B/$name-cut.wav"
    mv "$B/$name-cut.wav" "$B/$name-raw.wav"
    read -r m _ p < <(loud "$B/$name-raw.wav")
    g=$(gain "$m" $FX_M "$p")
    "$TOOL" finish "$B/$name-raw.wav" "$B/$name.wav" "$g" trim
    afconvert -f m4af -d aac -b 256000 "$B/$name.wav" "$D/$name.m4a"
    read -r m i p < <(loud "$B/$name.wav")
    printf "%-15s %7s %7s %7s  onset %s\n" "$name" "$m" "$i" "$p" "$("$TOOL" onset "$B/$name.wav")"
done <<<"$SWIPES"

echo
echo "seams, as AVAudioFile decodes each bed (the decoded error is against the float source)"
while read -r name _; do
    [ -z "$name" ] && continue
    echo "$name:"
    "$TOOL" seam "$D/$name.m4a" "$B/$name-bed.wav" | sed 's/^/  /'
done <<<"$BEDS"

echo
echo "each bed's bass alone at its level in the bed: I, and I through the phone model, against the whole bed's"
while read -r name _; do
    [ -z "$name" ] && continue
    read -r _ bi _ < <(loud "$B/$name-bass.wav")
    read -r _ bpi _ < <(loud "$B/$name-bass.wav" "$PHONE")
    read -r _ i _ < <(loud "$B/$name-bed.wav")
    read -r _ pi _ < <(loud "$B/$name-bed.wav" "$PHONE")
    awk -v d="$name" -v bi="$bi" -v bpi="$bpi" -v i="$i" -v pi="$pi" 'BEGIN {
        printf "%-12s bass %.1f against %.1f (%+.1f LU); through the phone model %.1f against %.1f (%+.1f LU)\n",
            d, bi, i, bi - i, bpi, pi, bpi - pi }'
done <<<"$BEDS"

echo
echo "onsets against each bed's sixteenth grid, and the bass's share of energy from 300 Hz to 4 kHz"
while read -r name _ bpm _; do
    [ -z "$name" ] && continue
    python3 -I scripts/synthwave-sketches/grid.py "$B/$name-bed.wav" "$B/$name-bass.wav" "$bpm" "$name"
done <<<"$BEDS"

echo
echo "each bed's bass against its round-one bed's, both before the level is set (the hybrid's passes through night's"
echo "lighter tape), and each bed's share of energy in the bands where a top line turns harsh, round one's in brackets"
while read -r name _ _ ref; do
    [ -z "$name" ] && continue
    python3 -I scripts/synthwave-sketches/against.py "$B/$name-bass-raw.wav" "$B/ref-$ref-bass-raw.wav" \
        "$B/$name-bed-raw.wav" "$B/ref-$ref-bed-raw.wav" "$name" "$ref"
done <<<"$BEDS"
ls "$D"
