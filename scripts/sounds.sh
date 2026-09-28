#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/sounds.sh   Renders the glass set from sound-src into Sounds/glass with Csound, then prints each
# file's loudness, peaks, onset, phone-speaker loss and size, and each bed's seam; spectrograms go to build/sounds/spec.
# Needs Homebrew's csound and ffmpeg. Everything is seeded, so a rerun writes the same bytes.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
SRC=sound-src
OUT=Sounds/glass
B=build/sounds
rm -rf "$B/raw" "$B/wav" "$B/spec" "$OUT"
mkdir -p "$B/raw" "$B/wav" "$B/spec" "$OUT"
swiftc -O scripts/sounds.swift -o "$B/tool"
TOOL="$B/tool"

# The ceiling for every file's true peak: under the -1 dBTP limit, with room for the 16-bit rounding and for AAC.
CEILING=-1.2
# An 8th-order Butterworth highpass at 250 Hz, as four biquads: roughly what an iPhone's speaker keeps.
PHONE="highpass=f=250:width_type=q:width=0.50980,highpass=f=250:width_type=q:width=0.60134"
PHONE="$PHONE,highpass=f=250:width_type=q:width=0.89998,highpass=f=250:width_type=q:width=2.56292"

# Effects: file, instrument, argument, seconds rendered, seed, loudest momentary loudness (LUFS), tail trimmed. The
# order of loudness is the sketch's (solve, heal, tank, spilled, push, seized, tick), 4 LU down; the new ones sit
# among them, the tap under the heal.
EFFECTS="
tick-1 tick 0 0.05 101 -34 no
tick-2 tick 1 0.05 102 -34 no
tick-3 tick 2 0.05 103 -34 no
tick-4 tick 3 0.05 104 -34 no
push push 0 0.9 200 -23 yes
heal-1 heal 1 4.2 301 -20 yes
heal-2 heal 2 4.2 302 -20 yes
heal-3 heal 3 4.2 303 -20 yes
heal-4 heal 4 4.2 304 -20 yes
heal-5 heal 5 4.2 305 -20 yes
heal-6 heal 6 4.2 306 -20 yes
tank tank 0 0.9 400 -21 yes
seized seized 0 0.2 500 -26 yes
solve solve 0 3.3 600 -19 no
spilled spilled 0 4.6 700 -22 no
tap-1 tap 0 0.7 1001 -28 yes
tap-2 tap 1 0.7 1002 -28 yes
tap-3 tap 2 0.7 1003 -28 yes
tap-4 tap 3 0.7 1004 -28 yes
switch switch 0 1.8 1100 -25 yes
undo undo 0 1.0 1200 -24 yes
reset reset 0 2.4 1300 -22 yes
"
# Frames of each bed's own ends encoded round it, tried in turn (each shifts the AAC frame grid by a quarter frame).
PADS="6144 6400 6656 6912 7168 7424 7680 7936"
# Beds: file, bed, seed, integrated loudness (LUFS). A heal's momentary loudness sits 8 LU over a level's bed.
BEDS="
loop plughole 800 -28
whirlpool whirlpool 850 -28
maelstrom maelstrom 900 -28
menu menu 950 -29
"

# file [mono] [filter]: the loudest 400 ms (M), the integrated loudness (I) and the true peak, by ffmpeg's EBU R128
# meter. A mono file is measured as dual mono, since the phone plays it on both speakers. Half a second of silence
# after it gives a short sound its full windows.
loud() {
    local dual="" filter="apad=pad_dur=0.5"
    [ "${2:-0}" = 1 ] && dual=":dualmono=true"
    [ -n "${3:-}" ] && filter="$3,$filter"
    ffmpeg -hide_banner -nostdin -nostats -i "$1" -af "$filter,ebur128=peak=true$dual:framelog=info" -f null - 2>&1 |
        awk '/ M:/ { sub(/.* M: */, ""); m = $1 + 0; if (!seen || m > max) max = m; seen = 1 }
             /^ *I: / { i = $2 }
             /True peak:/ { tp = 1 }
             tp && /Peak:/ { p = $2; tp = 0 }
             END { printf "%.2f %s %s\n", max, i, p }'
}

# measured target peak: the gain in dB to the target, pulled back if it would take the true peak over the ceiling.
gain() {
    awk -v m="$1" -v t="$2" -v p="$3" -v c="$CEILING" 'BEGIN { g = t - m; if (p + g > c) g = c - p; printf "%.4f\n", g }'
}

echo "rendering"
pids=()
while read -r name bed seed target; do
    [ -z "$name" ] && continue
    (cd "$SRC" && csound --omacro:BED="$bed" --omacro:SEED="$seed" --omacro:OUT="$ROOT/$B/raw/$name.wav" \
        --omacro:STEM="$ROOT/$B/raw/$name-hum.wav" beds.csd >"$ROOT/$B/raw/$name.log" 2>&1) &
    pids+=($!)
done <<<"$BEDS"
while read -r name fx arg dur seed target trim; do
    [ -z "$name" ] && continue
    (cd "$SRC" && csound --omacro:FX="$fx" --omacro:N="$arg" --omacro:DUR="$dur" --omacro:SEED="$seed" \
        --omacro:OUT="$ROOT/$B/raw/$name.wav" effects.csd >"$ROOT/$B/raw/$name.log" 2>&1) &
    pids+=($!)
done <<<"$EFFECTS"
for pid in "${pids[@]}"; do wait "$pid"; done
for log in "$B"/raw/*.log; do
    grep -q "0 errors in performance" "$log" || { echo "csound failed: $log"; tail -20 "$log"; exit 1; }
done

echo "levels"
while read -r name fx arg dur seed target trim; do
    [ -z "$name" ] && continue
    read -r m _ p < <(loud "$B/raw/$name.wav" 1)
    "$TOOL" finish "$B/raw/$name.wav" "$OUT/$name.caf" "$(gain "$m" "$target" "$p")" \
        "$([ "$trim" = yes ] && echo trim || echo keep)"
done <<<"$EFFECTS"
while read -r name bed seed target; do
    [ -z "$name" ] && continue
    read -r _ i p < <(loud "$B/raw/$name.wav")
    g=$(gain "$i" "$target" "$p")
    echo "$g" >"$B/raw/$name.gain"
    "$TOOL" finish "$B/raw/$name.wav" "$B/wav/$name.wav" "$g"
    "$TOOL" finish "$B/raw/$name-hum.wav" "$B/wav/$name-hum.wav" "$g"
    # Apple's AAC, if it loops cleanly. Encoded cold, a loop's two ends click where they meet; so the encoder gets
    # the loop with its own last frames before it and first frames after, and the file marks those as priming and
    # remainder. The codec's error still differs at the two ends, so each pre-roll (a shift of the frame grid) is
    # decoded, at 128 kb/s and then at 160, and the first whose wrap is ordinary is kept; if none is, the bed is
    # lossless ALAC in CAF.
    for rate in 128000 160000; do
        for pad in $PADS; do
            "$TOOL" wrap "$B/wav/$name.wav" "$B/wav/$name-wrapped.wav" "$pad"
            afconvert -f m4af -d aac -b $rate -q 127 "$B/wav/$name-wrapped.wav" "$OUT/$name.m4a"
            "$TOOL" gapless "$OUT/$name.m4a" "$pad" 2304000
            if "$TOOL" clean "$OUT/$name.m4a"; then echo "$name: AAC at $rate b/s, pre-roll $pad"; break 2; fi
            rm "$OUT/$name.m4a"
        done
    done
    if [ ! -f "$OUT/$name.m4a" ]; then
        "$TOOL" finish "$B/wav/$name.wav" "$B/wav/$name-16.caf" 0
        afconvert -f caff -d alac "$B/wav/$name-16.caf" "$OUT/$name.caf"
        echo "$name: ALAC"
    fi
done <<<"$BEDS"

echo
printf "%-11s %6s %7s %7s %7s %7s %9s %9s %8s\n" file seconds "M" "I" "TP" "onset" "phone ΔM" "phone ΔI" bytes
total=0
row() {  # file, mono
    local f=$1 base
    base=$(basename "$f")
    local secs bytes
    secs=$(afinfo "$f" | awk '/estimated duration/ { printf "%.2f", $3 }')
    bytes=$(stat -f%z "$f")
    total=$((total + bytes))
    # A bed is measured as Core Audio decodes it (ffmpeg would keep the AAC's pre-roll).
    if [ "$2" = 0 ]; then
        afconvert -f WAVE -d LEF32 "$f" "$B/wav/${base%.*}-decoded.wav"
        f="$B/wav/${base%.*}-decoded.wav"
    fi
    read -r m i p < <(loud "$f" "$2")
    read -r pm pi _ < <(loud "$f" "$2" "$PHONE")
    local short=0
    [ "$2" = 1 ] && [ "${secs%.*}" -lt 1 ] && short=1
    printf "%-11s %6s %7.1f %7s %7.1f %7s %+9.1f %9s %8d\n" "${base%.*}" "$secs" "$m" \
        "$([ $short = 1 ] && echo - || echo "$i")" "$p" "$("$TOOL" onset "$f")" \
        "$(awk -v a="$pm" -v b="$m" 'BEGIN { print a - b }')" \
        "$([ $short = 1 ] && echo - || awk -v a="$pi" -v b="$i" 'BEGIN { printf "%+.1f", a - b }')" "$bytes"
    ffmpeg -hide_banner -nostdin -v error -y -i "$f" \
        -lavfi "apad=whole_dur=0.3,showspectrumpic=s=900x420:legend=1:fscale=log:drange=100:mode=combined" \
        "$B/spec/${base%.*}.png"
}
while read -r name _; do [ -n "$name" ] && row "$OUT/$name.caf" 1; done <<<"$EFFECTS"
bed() { ls "$OUT/$1".m4a "$OUT/$1".caf 2>/dev/null; }
while read -r name _; do [ -n "$name" ] && row "$(bed "$name")" 0; done <<<"$BEDS"
echo "total $total bytes"

echo
echo "each bed's hum alone, at its level in the bed (I, and I through the phone model, against the whole bed's)"
while read -r name _; do
    [ -z "$name" ] && continue
    read -r _ hi _ < <(loud "$B/wav/$name-hum.wav")
    read -r _ hpi _ < <(loud "$B/wav/$name-hum.wav" 0 "$PHONE")
    read -r _ bi _ < <(loud "$B/wav/$name.wav")
    read -r _ bpi _ < <(loud "$B/wav/$name.wav" 0 "$PHONE")
    awk -v n="$name" -v hi="$hi" -v hpi="$hpi" -v bi="$bi" -v bpi="$bpi" 'BEGIN {
        printf "%-10s hum %.1f against %.1f (%+.1f LU); through the phone model %.1f against %.1f (%+.1f LU), the hum losing %.1f LU\n",
            n, hi, bi, hi - bi, hpi, bpi, hpi - bpi, hi - hpi }'
done <<<"$BEDS"

echo
echo "seams, as AVAudioFile decodes each bed (the decoded error is against the float source)"
while read -r name _; do
    [ -z "$name" ] && continue
    echo "$name:"
    "$TOOL" seam "$(bed "$name")" "$B/wav/$name.wav" | sed 's/^/  /'
done <<<"$BEDS"
