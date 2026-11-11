#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/sounds.sh [listen <dir> | layers <dir>]   Renders the glass set from sound-src into Sounds/glass with
# Csound, then prints each file's loudness, peaks, onset, phone-speaker loss and size, and each bed's seam;
# spectrograms go to build/sounds/spec. Needs Homebrew's csound and ffmpeg. Everything is seeded, so a rerun renders
# the same samples; the AAC encoder isn't byte-deterministic, so a bed's .m4a may still come out with new bytes.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD

# The ceiling for every file's true peak: under the -1 dBTP limit, with room for the 16-bit rounding and for AAC.
CEILING=-1.2

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

# listen <dir>: every effect and bed in Sounds/glass as m4a in <dir>, and a few effects played in turn over a bed: the
# undo after a push, a heal undone and healed again, and Escapement's ticks through a few moves. An effect plays on
# both channels at its full level, as the app plays it, and the plays sit on plughole's bed at its own level. Then the
# packs' sketches (sound-src/sketches.csd), which the app never plays, each alone and over plughole's bed.
if [ "${1:-}" = listen ]; then
    D=${2:?usage: scripts/sounds.sh listen <dir>}
    L=build/sounds/listen
    mkdir -p "$D" "$L"
    G=Sounds/glass
    aac() { afconvert -f m4af -d aac -b 256000 "$1" "$2"; }
    for f in "$G"/*.caf; do
        n=$(basename "$f" .caf)
        [ "$n" = maelstrom ] && continue
        afconvert -f WAVE -d LEF32 "$f" "$L/$n.wav"
        aac "$L/$n.wav" "$D/$n.m4a"
    done
    for bed in menu loop whirlpool vortex maelstrom; do
        f=$G/$bed.m4a
        [ -f "$f" ] || f=$G/$bed.caf
        afconvert -f WAVE -d LEF32 "$f" "$L/bed-$bed.wav"
        name=$([ "$bed" = loop ] && echo plughole || echo "$bed")
        aac "$L/bed-$bed.wav" "$D/bed-$name.m4a"
    done
    # A bed played twice through, as the game loops it, to hear the seam.
    ffmpeg -hide_banner -nostdin -v error -y -i "$L/bed-vortex.wav" -af "aloop=loop=1:size=2304000" \
        -c:a pcm_f32le "$L/bed-vortex-twice.wav"
    aac "$L/bed-vortex-twice.wav" "$D/bed-vortex-twice.m4a"
    # play out seconds "effect@time ..." [bed]: the effects at those times over the first seconds of a bed (plughole's
    # unless given), faded.
    play() {
        local out=$1 secs=$2
        local inputs=(-i "$L/bed-${4:-loop}.wav") chain="[0]atrim=0:$secs,afade=t=out:st=$((secs - 2)):d=2[b];"
        local mix="[b]" k=1
        for ev in $3; do
            inputs+=(-i "$L/${ev%@*}.wav")
            local ms
            ms=$(awk -v t="${ev#*@}" 'BEGIN { printf "%d", t * 1000 }')
            chain="$chain[$k]pan=stereo|c0=c0|c1=c0,adelay=$ms|$ms[e$k];"
            mix="$mix[e$k]"
            k=$((k + 1))
        done
        ffmpeg -hide_banner -nostdin -v error -y "${inputs[@]}" \
            -filter_complex "$chain${mix}amix=inputs=$k:normalize=0:duration=first" -c:a pcm_f32le "$L/$out.wav"
    }
    play undo-after-push 6 "push@1 undo@2.6"
    # Two heals, the second undone, which steps its note back, healed again, one more heal, then the move that solves,
    # which sounds as the solve.
    play heal-undo 14 "heal-1@1 heal-2@3 undo@5 heal-2@6.6 heal-3@8.6 solve@10.6"
    for f in undo-after-push heal-undo; do aac "$L/$f.wav" "$D/$f.m4a"; done
    # The vortex bed under play: heals, a push and the solve.
    play vortex-with-play 14 "heal-1@2 push@4 heal-2@6 heal-3@8 solve@10.5" vortex
    aac "$L/vortex-with-play.wav" "$D/vortex-with-play.m4a"
    # Escapement's ticks in play, timed as the game times them: the first clock's 0.15 s after the lift (LevelView's
    # tickBeat), each next 0.3 s on (tickTurn), over moves of one, two and three clocks; the second and fifth moves
    # heal on the lift, and the last solves.
    play ratchet-in-play 16 "ratchet-1@1.15 heal-1@3.2 ratchet-2@3.35 ratchet-3@4.75 ratchet-4@5.05 ratchet-1@7.15
        heal-2@8.8 ratchet-2@8.95 ratchet-3@9.25 ratchet-4@10.65 ratchet-1@10.95 ratchet-2@11.25 solve@12.4
        ratchet-3@12.55 ratchet-4@12.85"
    aac "$L/ratchet-in-play.wav" "$D/ratchet-in-play.m4a"

    # Sketches: file, sketch, seconds, seed, the meter (I a layer's integrated loudness, M a tick's loudest 400 ms, or
    # = to take an earlier file's gain) and its target. A layer sits 2 LU under the bed, so a heal still stands about
    # 8 LU over the two. A take of a tick in a kept layer takes the layer's gain, so the layer plays as it was heard.
    SKETCHES="
sketch-lens-a lensA 20 2001 I -30
sketch-lens-b lensB 20 2002 I -30
sketch-escapement-a escA 20 2101 I -30
sketch-escapement-b escB 20 2102 I -30
sketch-prism-a prismA 20 2201 I -30
sketch-prism-b prismB 20 2202 I -30
sketch-tick-a tickA 0.4 2301 M -27
sketch-tick-b tickB 0.4 2302 M -27
sketch-ticks-a ticksA 14 2303 M -27
sketch-ticks-b ticksB 14 2304 M -27
sketch-tick-c tickC 0.4 2305 M -27
sketch-tick-d tickD 0.4 2306 M -27
sketch-tick-e tickE 0.4 2307 M -27
sketch-ticks-c ticksC 14 2308 M -27
sketch-ticks-d ticksD 14 2309 M -27
sketch-ticks-e ticksE 14 2310 M -27
sketch-escapement-b-tick-c escBtickC 20 2102 = sketch-escapement-b
sketch-escapement-b-tick-d escBtickD 20 2102 = sketch-escapement-b
sketch-escapement-b-tick-e escBtickE 20 2102 = sketch-escapement-b
"
    pids=()
    while read -r name sk secs seed _; do
        [ -z "$name" ] && continue
        (cd sound-src && csound --omacro:SKETCH="$sk" --omacro:SEED="$seed" --omacro:DUR="$secs" \
            --omacro:OUT="$ROOT/$L/$name-raw.wav" sketches.csd >"$ROOT/$L/$name.log" 2>&1) &
        pids+=($!)
    done <<<"$SKETCHES"
    for pid in "${pids[@]}"; do wait "$pid"; done
    while read -r name _ _ _ meter target; do
        [ -z "$name" ] && continue
        grep -q "0 errors in performance" "$L/$name.log" || { echo "csound failed: $L/$name.log"; tail -20 "$L/$name.log"; exit 1; }
        if [ "$meter" = = ]; then
            g=$(cat "$L/$target.gain")
        else
            read -r m i p < <(loud "$L/$name-raw.wav")
            g=$(gain "$([ "$meter" = I ] && echo "$i" || echo "$m")" "$target" "$p")
        fi
        echo "$g" >"$L/$name.gain"
        ffmpeg -hide_banner -nostdin -v error -y -i "$L/$name-raw.wav" -af "volume=${g}dB" -c:a pcm_f32le "$L/$name.wav"
        aac "$L/$name.wav" "$D/$name.m4a"
        read -r m i p < <(loud "$L/$name.wav")
        echo "$name: M $m, I $i, true peak $p"
    done <<<"$SKETCHES"
    # over out seconds sketch "effect@time ...": a stereo sketch from 1 s into plughole's bed, with effects as play's.
    over() {
        local out=$1 secs=$2
        local inputs=(-i "$L/bed-loop.wav" -i "$L/$3.wav")
        local chain="[0]atrim=0:$secs,afade=t=out:st=$((secs - 2)):d=2[b];[1]adelay=1000|1000[s];" mix="[b][s]" k=2
        for ev in ${4:-}; do
            inputs+=(-i "$L/${ev%@*}.wav")
            local ms
            ms=$(awk -v t="${ev#*@}" 'BEGIN { printf "%d", t * 1000 }')
            chain="$chain[$k]pan=stereo|c0=c0|c1=c0,adelay=$ms|$ms[e$k];"
            mix="$mix[e$k]"
            k=$((k + 1))
        done
        ffmpeg -hide_banner -nostdin -v error -y "${inputs[@]}" \
            -filter_complex "$chain${mix}amix=inputs=$k:normalize=0:duration=first" -c:a pcm_f32le "$L/$out.wav"
        aac "$L/$out.wav" "$D/$out.m4a"
    }
    for f in lens-a lens-b escapement-a escapement-b escapement-b-tick-c escapement-b-tick-d escapement-b-tick-e \
        prism-a prism-b; do over "sketch-$f-over-plughole" 22 "sketch-$f"; done
    # The ticks in play, with a heal on the second move's tick and the fifth's, as a tick that pops an entry heals.
    for f in ticks-a ticks-b ticks-c ticks-d ticks-e; do over "sketch-$f-over-plughole" 16 "sketch-$f" "heal-1@4.35 heal-2@9.95"; done
    ls "$D"
    exit 0
fi
# layers <dir>: each kept pack layer (Jack's call SOUNDSK: Lens B, Escapement B, Prism A) under its line in
# sound-src/layers-in-play.tsv, a real level played for three to four minutes: the menu's bed crossfading to plughole's
# as the level opens, the layer's loop entering with it and playing on under its resolution on the beat after the solve,
# and the game's effects at their own levels, as <pack>.mp3 at 160 kb/s; <pack>-bed-only.mp3 is the same without the
# layer, and layers-in-play.txt lists each line and each render's loudness. A layer plays at the gain its 20 s sketch
# takes in listen, so it sits where Jack heard it. The motif's whole cycles fill an 8-bar loop (Lens B's bowed glass
# takes 8), which runs free of the 48 s bed.
if [ "${1:-}" = layers ]; then
    D=${2:?usage: scripts/sounds.sh layers <dir>}
    L=build/sounds/layers
    T=sound-src/layers-in-play.tsv
    LOOP=25.6
    N=$(awk -v l=$LOOP 'BEGIN { printf "%d", l * 48000 }')
    mkdir -p "$D" "$L"
    for f in Sounds/glass/*.caf; do afconvert -f WAVE -d LEF32 "$f" "$L/$(basename "$f" .caf).wav"; done
    for bed in menu loop; do afconvert -f WAVE -d LEF32 "Sounds/glass/$bed.m4a" "$L/bed-$bed.wav"; done
    sketch() {  # sketch seed out [macros...]
        local sk=$1 seed=$2 out=$3
        shift 3
        (cd sound-src && csound --omacro:SKETCH="$sk" --omacro:SEED="$seed" "$@" --omacro:OUT="$ROOT/$out" sketches.csd \
            >"$ROOT/$out.log" 2>&1)
        grep -q "0 errors in performance" "$out.log" || { echo "csound failed: $out.log"; tail -20 "$out.log"; exit 1; }
    }
    LIST=$D/layers-in-play.txt
    {
        echo "The packs' kept layers in play (SOUNDSK: Lens B, Escapement B, Prism A), rendered by scripts/sounds.sh layers"
        echo "from sound-src/layers-in-play.tsv on branch sound-packs. Each line is real play of the level, checked on a"
        echo "real Game (SoundTests' testTheLayerLinesSoundAsTheGamePlaysThem): bursts at a practised player's pace, from"
        echo "a playtest's flight recorder (1.2 to 3.9 s commit to commit), between authored studies of 20 to 45 s; at that"
        echo "pace alone such a level takes about 30 s. Times are from the row's tap to when the game sounds each action (a"
        echo "knob's commit, 0.25 s after the lift, 0.3 on Escapement). The layer's loop is 8 bars (25.6 s) of the motif"
        echo "at 75 bpm, entering with the bed's crossfade; on the beat after the solve its resolution plays over it,"
        echo "and loop and bed carry on under the card. Loudness is ffmpeg's EBU R128 meter on each mp3: I"
        echo "integrated, M the loudest 400 ms, TP true peak."
        echo
    } >"$LIST"
    for row in "lens lensB 2002" "escapement escB 2102" "prism prismA 2201"; do
        read -r pack sk seed <<<"$row"
        # The sketch's own gain, as listen sets it: -30 LUFS integrated over its 20 s, under the true-peak ceiling.
        sketch "$sk" "$seed" "$L/$pack-sketch.wav" --omacro:DUR=20
        read -r _ i p < <(loud "$L/$pack-sketch.wav")
        g=$(gain "$i" -30 "$p")
        eval "$(python3 scripts/layers.py plan "$T" "$pack")"
        sketch "${sk}Loop" "$seed" "$L/$pack-loops.wav" --omacro:LOOP=$LOOP
        ffmpeg -hide_banner -nostdin -v error -y -i "$L/$pack-loops.wav" \
            -af "atrim=start_sample=$((2 * N)):end_sample=$((3 * N))" -c:a pcm_f32le "$L/$pack-loop.wav"
        macros=(--omacro:DUR="$LENGTH" --omacro:SOLVED="$SOLVED" --omacro:END="$END")
        [ "$pack" = escapement ] && macros+=(--omacro:REEDS="$REEDS" --omacro:NOTES="$NOTES" --omacro:LAST="$LAST")
        sketch "${sk}End" "$seed" "$L/$pack-end.wav" "${macros[@]}"
        read -r _ li _ < <(loud "$L/$pack-loop.wav" 0 "volume=${g}dB")
        python3 scripts/layers.py mix "$T" "$pack" "$L" "$g" only "$L/$pack-layer.wav"
        read -r _ lp _ < <(loud "$L/$pack-layer.wav")
        {
            printf "%s: %s, solved at %.2f s; the layer at its sketch's gain, %.1f dB, its loop alone I %s LUFS\n" \
                "$pack" "$LEVEL" "$SOLVED" "$g" "$li"
            echo "  the layer alone over the line, its loop and resolution with no bed or effects: I $lp LUFS"
            if [ "$pack" = escapement ]; then
                # The sketch's ticks are round 15's brass pawl, which the game's own tick replaces in play, so the
                # layer in play is measured against the sketch without them.
                for part in escBDry escBDrums; do
                    sketch "$part" "$seed" "$L/$pack-$part.wav" --omacro:DUR=20
                done
                read -r _ st _ < <(loud "$L/$pack-sketch.wav" 0 "volume=${g}dB")
                read -r _ sd _ < <(loud "$L/$pack-escBDry.wav" 0 "volume=${g}dB")
                read -r _ sr _ < <(loud "$L/$pack-escBDrums.wav" 0 "volume=${g}dB")
                echo "  the 20 s sketch at that gain: I $st LUFS with its ticks (round 15's brass pawl), $sd without"
                echo "  them, $sr its drums alone; in play the loop is those drums, and the reed sounds once a move"
            fi
            python3 scripts/layers.py line "$T" "$pack"
        } >>"$LIST"
        for with in 1 0; do
            name=$([ $with = 1 ] && echo "$pack" || echo "$pack-bed-only")
            python3 scripts/layers.py mix "$T" "$pack" "$L" "$g" $with "$L/$name.wav"
            ffmpeg -hide_banner -nostdin -v error -y -i "$L/$name.wav" -c:a libmp3lame -b:a 160k "$D/$name.mp3"
            read -r m i p < <(loud "$D/$name.mp3")
            echo "  $name.mp3: I $i LUFS, M $m LUFS, TP $p dBTP" | tee -a "$LIST"
        done
        echo >>"$LIST"
    done
    ls "$D"
    exit 0
fi
SRC=sound-src
OUT=Sounds/glass
B=build/sounds
rm -rf "$B/raw" "$B/wav" "$B/spec" "$OUT"
mkdir -p "$B/raw" "$B/wav" "$B/spec" "$OUT"
swiftc -O scripts/sounds.swift -o "$B/tool"
TOOL="$B/tool"

# An 8th-order Butterworth highpass at 250 Hz, as four biquads: roughly what an iPhone's speaker keeps.
PHONE="highpass=f=250:width_type=q:width=0.50980,highpass=f=250:width_type=q:width=0.60134"
PHONE="$PHONE,highpass=f=250:width_type=q:width=0.89998,highpass=f=250:width_type=q:width=2.56292"

# Effects: file, instrument, argument, seconds rendered, seed, loudest momentary loudness (LUFS), tail trimmed. The
# order of loudness is the first sketch's (solve, heal, spilled, push, seized), 4 LU down; the new ones sit among
# them, the tap under the heal. The ratchet sits where its ticks sat in the run Jack heard (-27 to -32), under the tap,
# as a move can land three.
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
seized seized 0 0.2 500 -26 yes
solve solve 0 3.3 600 -19 no
spilled spilled 0 4.6 700 -22 no
tap-1 tap 0 0.7 1001 -28 yes
tap-2 tap 1 0.7 1002 -28 yes
tap-3 tap 2 0.7 1003 -28 yes
tap-4 tap 3 0.7 1004 -28 yes
switch switch 0 1.8 1100 -25 yes
undo undo 0 1.0 1201 -24 yes
reset reset 0 2.4 1300 -22 yes
ratchet-1 ratchet 0 0.25 2306 -30 yes
ratchet-2 ratchet 0 0.25 14306 -30 yes
ratchet-3 ratchet 0 0.25 8306 -30 yes
ratchet-4 ratchet 0 0.25 18306 -30 yes
"
# Frames of each bed's own ends encoded round it, tried in turn (each shifts the AAC frame grid by a quarter frame).
PADS="6144 6400 6656 6912 7168 7424 7680 7936"
# Beds: file, bed, seed, integrated loudness (LUFS). A heal's momentary loudness sits 8 LU over a level's bed.
BEDS="
loop plughole 800 -28
whirlpool whirlpool 850 -28
vortex vortex 875 -28
maelstrom maelstrom 900 -28
menu menu 950 -29
"

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

# Layers: each pack's kept layer (Jack's call SOUNDSK: Lens B, Escapement B, Prism A) from sound-src/sketches.csd, at
# its 20 s sketch's gain (-30 LUFS integrated, under the ceiling, as listen sets it), so the app plays it as Jack heard
# it: the motif's whole cycles over 8 bars at 75 bpm (25.6 s) as layer-<pack>.m4a, encoded as a bed is, and the
# one-shots the game plays over it as layer-<pack>-<name>.caf: the resolution on the beat after the solve (Prism's
# swell from as early as the solve), and Escapement B's reed, a note a move and D on the solve. Each one-shot is
# name:instrument:seconds[:macro=value+...]. The loop is the third of three periods, which loopmaster makes seamless,
# turned to start a quarter beat (0.2 s, LEAD) before its first beat, where no layer has an onset: a wrap on the
# downbeat's attack reads to clean as a click. Sound.swift counts the beats from LEAD into the file.
LOOP=25.6
LOOPN=1228800
LEAD=9600
LAYERS="
lens lensB 2002 end:lensBEnd:8
escapement escB 2102 end:escBKick:4 a4:escBNote:4:NOTE=69+LEN=0.45+SEND=0.04 b4:escBNote:4:NOTE=71+LEN=0.45+SEND=0.04 e4:escBNote:4:NOTE=64+LEN=0.45+SEND=0.04 g4:escBNote:4:NOTE=67+LEN=0.45+SEND=0.04 d4:escBNote:6:NOTE=62+LEN=1.8+SEND=0.08
prism prismA 2201 end:prismAEndVoices:7 swell:prismAEndSwell:7
"
L=$B/layers
mkdir -p "$L"
layer() {  # sketch seed out [macros...]
    local sk=$1 seed=$2 out=$3
    shift 3
    (cd "$SRC" && csound --omacro:SKETCH="$sk" --omacro:SEED="$seed" "$@" --omacro:OUT="$ROOT/$out" sketches.csd \
        >"$ROOT/$out.log" 2>&1)
    grep -q "0 errors in performance" "$out.log" || { echo "csound failed: $out.log"; tail -20 "$out.log"; exit 1; }
}
echo "layers"
pids=()
while read -r pack sk seed shots; do
    [ -z "$pack" ] && continue
    layer "$sk" "$seed" "$L/$pack-sketch.wav" --omacro:DUR=20 &
    pids+=($!)
    layer "${sk}Loop" "$seed" "$L/$pack-loops.wav" --omacro:LOOP=$LOOP &
    pids+=($!)
    for shot in $shots; do
        IFS=: read -r part ins secs macros <<<"$shot"
        args=(--omacro:DUR="$secs")
        for m in ${macros//+/ }; do args+=(--omacro:"$m"); done
        layer "$ins" "$seed" "$L/$pack-$part.wav" "${args[@]}" &
        pids+=($!)
    done
done <<<"$LAYERS"
for pid in "${pids[@]}"; do wait "$pid"; done
while read -r pack sk seed shots; do
    [ -z "$pack" ] && continue
    read -r _ i p < <(loud "$L/$pack-sketch.wav")
    g=$(gain "$i" -30 "$p")
    echo "$g" >"$L/$pack.gain"
    ffmpeg -hide_banner -nostdin -v error -y -i "$L/$pack-loops.wav" \
        -filter_complex "[0]atrim=start_sample=$((3 * LOOPN - LEAD)):end_sample=$((3 * LOOPN)),asetpts=N/SR/TB[a];
            [0]atrim=start_sample=$((2 * LOOPN)):end_sample=$((3 * LOOPN - LEAD)),asetpts=N/SR/TB[b];
            [a][b]concat=v=0:a=1" -c:a pcm_f32le "$L/$pack-loop-raw.wav"
    "$TOOL" finish "$L/$pack-loop-raw.wav" "$B/wav/layer-$pack.wav" "$g"
    for rate in 128000 160000; do
        for pad in $PADS; do
            "$TOOL" wrap "$B/wav/layer-$pack.wav" "$B/wav/layer-$pack-wrapped.wav" "$pad"
            afconvert -f m4af -d aac -b $rate -q 127 "$B/wav/layer-$pack-wrapped.wav" "$OUT/layer-$pack.m4a"
            "$TOOL" gapless "$OUT/layer-$pack.m4a" "$pad" $LOOPN
            if "$TOOL" clean "$OUT/layer-$pack.m4a" $LOOPN; then echo "layer-$pack: AAC at $rate b/s, pre-roll $pad, gain $g dB"; break 2; fi
            rm "$OUT/layer-$pack.m4a"
        done
    done
    [ -f "$OUT/layer-$pack.m4a" ] || { echo "layer-$pack: no AAC loops cleanly"; exit 1; }
    for shot in $shots; do
        part=${shot%%:*}
        "$TOOL" finish "$L/$pack-$part.wav" "$OUT/layer-$pack-$part.caf" "$g" trim
    done
done <<<"$LAYERS"

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
for f in "$OUT"/layer-*.m4a "$OUT"/layer-*.caf; do row "$f" 0; done
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
while read -r pack _; do
    [ -z "$pack" ] && continue
    echo "layer-$pack:"
    "$TOOL" seam "$OUT/layer-$pack.m4a" "$B/wav/layer-$pack.wav" | sed 's/^/  /'
done <<<"$LAYERS"
