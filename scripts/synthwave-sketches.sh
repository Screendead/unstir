#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/synthwave-sketches.sh <dir>   Renders the synthwave menu's sketches (sound-src/synthwave-sketches.csd)
# for Jack's ear: each direction's bed as one seamless loop of its 16 bars at -16 LUFS, and its four effects, louder,
# as m4a in <dir>; then measures each bed's seam, each file's loudness, each bed's onsets against its beat grid, and
# how much of each bed's bass a phone's speaker keeps. Needs Homebrew's csound and ffmpeg, and numpy.
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
# The loop starts a quarter beat before its first downbeat, where nothing strikes: a wrap on an attack reads as a click.
DIRECTIONS="
outrun 120
night 96
dark 100
"
EFFECTS="Tap:tap:1.2 Swipe:swipe:1.6 Open:open:2.6 Locked:locked:0.9"

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
while read -r dir bpm; do
    [ -z "$dir" ] && continue
    dur=$(awk -v b="$bpm" 'BEGIN { print 3 * 64 * 60 / b }')
    render "$dir" "$bpm" "$dur" "$B/$dir-bed3.wav" &
    pids+=($!)
    render "$dir" "$bpm" "$dur" "$B/$dir-bass3.wav" --omacro:BASSONLY=1 &
    pids+=($!)
    for e in $EFFECTS; do
        IFS=: read -r ins name secs <<<"$e"
        render "$dir$ins" "$bpm" "$secs" "$B/$dir-$name-raw.wav" &
        pids+=($!)
    done
done <<<"$DIRECTIONS"
for pid in "${pids[@]}"; do wait "$pid"; done

PADS="6144 6400 6656 6912 7168 7424 7680 7936"
printf "%-15s %7s %7s %7s\n" file M I TP
while read -r dir bpm; do
    [ -z "$dir" ] && continue
    n=$(awk -v b="$bpm" 'BEGIN { printf "%d", 64 * 60 / b * 48000 }')
    lead=$(awk -v b="$bpm" 'BEGIN { printf "%d", 0.25 * 60 / b * 48000 }')
    for part in bed bass; do
        ffmpeg -hide_banner -nostdin -v error -y -i "$B/$dir-${part}3.wav" \
            -af "atrim=start_sample=$((n - lead)):end_sample=$((2 * n - lead)),asetpts=N/SR/TB" -c:a pcm_f32le \
            "$B/$dir-$part-raw.wav"
    done
    read -r _ i p < <(loud "$B/$dir-bed-raw.wav")
    g=$(gain "$i" $BED_I "$p")
    echo "$g" >"$B/$dir.gain"
    "$TOOL" finish "$B/$dir-bed-raw.wav" "$B/$dir-bed.wav" "$g"
    "$TOOL" finish "$B/$dir-bass-raw.wav" "$B/$dir-bass.wav" "$g"
    rm -f "$D/$dir-bed.m4a"
    for pad in $PADS; do
        "$TOOL" wrap "$B/$dir-bed.wav" "$B/$dir-bed-wrapped.wav" "$pad"
        afconvert -f m4af -d aac -b 256000 -q 127 "$B/$dir-bed-wrapped.wav" "$D/$dir-bed.m4a"
        "$TOOL" gapless "$D/$dir-bed.m4a" "$pad" "$n"
        "$TOOL" clean "$D/$dir-bed.m4a" "$n" && break
        rm "$D/$dir-bed.m4a"
    done
    [ -f "$D/$dir-bed.m4a" ] || { echo "$dir-bed: no AAC loops cleanly"; exit 1; }
    read -r m i p < <(loud "$B/$dir-bed.wav")
    printf "%-15s %7s %7s %7s\n" "$dir-bed" "$m" "$i" "$p"
    for e in $EFFECTS; do
        IFS=: read -r _ name _ <<<"$e"
        # Every effect's first event is scheduled at 20 ms: cut that, so it sounds on the touch.
        ffmpeg -hide_banner -nostdin -v error -y -i "$B/$dir-$name-raw.wav" -af "atrim=start_sample=912,asetpts=N/SR/TB" \
            -c:a pcm_f32le "$B/$dir-$name-cut.wav"
        mv "$B/$dir-$name-cut.wav" "$B/$dir-$name-raw.wav"
        read -r m _ p < <(loud "$B/$dir-$name-raw.wav")
        g=$(gain "$m" $FX_M "$p")
        "$TOOL" finish "$B/$dir-$name-raw.wav" "$B/$dir-$name.wav" "$g" trim
        afconvert -f m4af -d aac -b 256000 "$B/$dir-$name.wav" "$D/$dir-$name.m4a"
        read -r m i p < <(loud "$B/$dir-$name.wav")
        printf "%-15s %7s %7s %7s  onset %s\n" "$dir-$name" "$m" "$i" "$p" "$("$TOOL" onset "$B/$dir-$name.wav")"
    done
done <<<"$DIRECTIONS"

echo
echo "seams, as AVAudioFile decodes each bed (the decoded error is against the float source)"
while read -r dir _; do
    [ -z "$dir" ] && continue
    echo "$dir:"
    "$TOOL" seam "$D/$dir-bed.m4a" "$B/$dir-bed.wav" | sed 's/^/  /'
done <<<"$DIRECTIONS"

echo
echo "each bed's bass alone at its level in the bed: I, and I through the phone model, against the whole bed's"
while read -r dir _; do
    [ -z "$dir" ] && continue
    read -r _ bi _ < <(loud "$B/$dir-bass.wav")
    read -r _ bpi _ < <(loud "$B/$dir-bass.wav" "$PHONE")
    read -r _ i _ < <(loud "$B/$dir-bed.wav")
    read -r _ pi _ < <(loud "$B/$dir-bed.wav" "$PHONE")
    awk -v d="$dir" -v bi="$bi" -v bpi="$bpi" -v i="$i" -v pi="$pi" 'BEGIN {
        printf "%-7s bass %.1f against %.1f (%+.1f LU); through the phone model %.1f against %.1f (%+.1f LU)\n",
            d, bi, i, bi - i, bpi, pi, bpi - pi }'
done <<<"$DIRECTIONS"

echo
echo "onsets against each bed's sixteenth grid, and the bass's share of energy from 300 Hz to 4 kHz"
while read -r dir bpm; do
    [ -z "$dir" ] && continue
    python3 -I - "$B/$dir-bed.wav" "$B/$dir-bass.wav" "$bpm" "$dir" <<'EOF'
import subprocess, sys
import numpy as np
bed, bass, bpm, name = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
def mono(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)
sr, hop, win = 48000, 256, 1024
x = mono(bed)
frames = np.lib.stride_tricks.sliding_window_view(x, win)[::hop] * np.hanning(win)
mag = np.log1p(100 * np.abs(np.fft.rfft(frames, axis=1)))
flux = np.maximum(np.diff(mag, axis=0), 0).sum(axis=1)
thresh = np.median(flux) + 3 * np.std(flux)
peaks = [i for i in range(1, len(flux) - 1) if flux[i] > thresh and flux[i] >= flux[i - 1] and flux[i] > flux[i + 1]]
# Frame i of the diff covers frames i and i+1: its onset is near the start of frame i+1's window, plus the attack.
t = np.array([(i + 1) * hop + win / 2 for i in peaks]) / sr
step = 60 / bpm / 4
lead = 60 / bpm / 4
pos = (t - lead) / step
off = (pos - np.round(pos)) * step * 1000
print(f"{name}: {len(t)} onsets; off the grid by median {np.median(np.abs(off)):.1f} ms, worst {np.max(np.abs(off)):.1f} ms, "
      f"{np.mean(np.abs(off) < 12) * 100:.0f}% within 12 ms")
b = mono(bass)
spec = np.abs(np.fft.rfft(b)) ** 2
f = np.fft.rfftfreq(len(b), 1 / sr)
band = spec[(f >= 300) & (f <= 4000)].sum() / spec.sum()
print(f"{name}: bass energy from 300 Hz to 4 kHz {band * 100:.1f}% ({10 * np.log10(band):.1f} dB)")
EOF
done <<<"$DIRECTIONS"
ls "$D"
