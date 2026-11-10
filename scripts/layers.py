#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""The packs' kept layers in play, for scripts/sounds.sh layers. Reads a pack's line from sound-src/layers-in-play.tsv
and times what the game sounds for it as Sound.swift and LevelView play it.

  layers.py plan <tsv> <pack>   prints the macros sketches.csd takes for the layer's resolution, as shell assignments
  layers.py mix <tsv> <pack> <dir> <gain dB> <with layer: 0|1|only> <out.wav>
                                mixes the level as heard: the menu's bed crossfading to plughole's, the layer's loop and
                                its resolution at the gain, and every effect at its own level; only, the layer alone
  layers.py line <tsv> <pack>   prints the line with each action's time and sounds, for the listing
  layers.py moves <tsv> <pack> <ratchet> [study scale]
                                prints the seconds a film of the line takes and the line as UNSTIR_MOVES with
                                UNSTIR_FINGER plays it: each action's step, its gap to the next made up by p<s> rests,
                                a study's (a gap over STUDY) scaled; a wait taps the clock on rod <ratchet>

<dir> holds the effects and beds decoded to WAV (as listen decodes them, bed-menu.wav and bed-loop.wav) and the
layer's renders, <pack>-loop.wav (one period) and <pack>-end.wav.
"""
import math
import subprocess
import sys

import numpy as np

RATE = 48000
BEAT = 0.8
# Sound.swift: a bed crossfades in over 1.5 s, equal power.
CROSSFADE = 1.5
# LevelView's tickBeat and tickTurn: each clock's tick a beat after the commit, then a turn apart.
TICK_BEAT, TICK_TURN = 0.15, 0.3
# The layer's loop gives way to its resolution over this, from the beat after the solve.
LOOP_OUT = 0.5
# The card stays up this long after the solve before the render fades out over FADE.
AFTER, FADE = 14.0, 3.0


def line(tsv, pack):
    rows = []
    for raw in open(tsv, encoding="utf-8"):
        if raw.startswith("#") or not raw.strip():
            continue
        p, level, at, action, sounds = raw.rstrip("\n").split("\t")
        if p == pack:
            rows.append((level, float(at), action, sounds.split(",") if sounds != "-" else []))
    return rows


def events(rows):
    """Every effect the game plays: (seconds, file), the tap's and the tick's variants counted as the app counts them."""
    out, taps, ratchets = [], 0, 0
    for _, at, _, sounds in rows:
        for s in sounds:
            if s == "tap":
                out.append((at, f"tap-{taps % 4 + 1}"))
                taps += 1
            elif s.startswith("heal"):
                n = int(s[4:])
                out.append((at, f"heal-{(n - 1) % 6 + 1}"))
            elif s.startswith("tick"):
                for i in range(int(s[4:])):
                    out.append((at + TICK_BEAT + TICK_TURN * i, f"ratchet-{ratchets % 4 + 1}"))
                    ratchets += 1
            else:
                out.append((at, s))
    return sorted(out)


def solved(rows):
    return next(at for _, at, _, sounds in rows if "solve" in sounds)


def end(rows):
    """The beat after the solve, where the layer resolves."""
    return math.ceil(solved(rows) / BEAT - 1e-9) * BEAT


def reeds(rows):
    """Escapement B's reed: each move's note on the next eighth, its place in the motif the moves made before it (an
    undo takes one back), and the solve's D on its last tick."""
    times, notes, moves, last = [], [], 0, None
    for _, at, action, sounds in rows:
        if action == "open":
            continue
        if action == "u":
            moves -= 1
            continue
        if "solve" in sounds:
            ticks = next(int(s[4:]) for s in sounds if s.startswith("tick"))
            last = at + TICK_BEAT + TICK_TURN * (ticks - 1)
            break
        times.append(math.ceil(at / (BEAT / 2) - 1e-9) * BEAT / 2)
        notes.append(moves)
        moves += 1
    return times, notes, last


def length(rows):
    return solved(rows) + AFTER


def read(path, mono=False):
    pan = ["-af", "pan=stereo|c0=c0|c1=c0"] if mono else ["-ac", "2"]
    raw = subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-v", "error", "-i", path, *pan, "-ar", str(RATE),
                          "-f", "f32le", "-"], check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype="<f4").reshape(-1, 2).astype(np.float64)


def tile(loop, n):
    return np.tile(loop, (n // len(loop) + 1, 1))[:n]


def ramp(n, start, seconds, rising):
    """Equal power over seconds from start: sin rising, cos falling, flat either side."""
    t = (np.arange(n) / RATE - start) / seconds
    level = np.clip(t, 0, 1) if rising else 1 - np.clip(t, 0, 1)
    return np.sin(level * math.pi / 2)[:, None]


def mix(tsv, pack, d, gain, layer, out):
    rows = line(tsv, pack)
    n = int(length(rows) * RATE)
    if layer == "only":
        total = np.zeros((n, 2))
    else:
        total = tile(read(f"{d}/bed-loop.wav"), n) * ramp(n, 0, CROSSFADE, True)
        menu = read(f"{d}/bed-menu.wav")[: int(CROSSFADE * RATE)]
        total[: len(menu)] += menu * ramp(len(menu), 0, CROSSFADE, False)
    if layer != "0":
        g = 10 ** (gain / 20)
        loop = tile(read(f"{d}/{pack}-loop.wav"), n) * ramp(n, 0, CROSSFADE, True) * ramp(n, end(rows), LOOP_OUT, False)
        resolution = read(f"{d}/{pack}-end.wav")[:n]
        total = total + g * loop
        total[: len(resolution)] += g * resolution
    for at, name in events(rows) if layer != "only" else []:
        fx = read(f"{d}/{name}.wav", mono=True)
        i = int(round(at * RATE))
        k = min(len(fx), n - i)
        total[i:i + k] += fx[:k]
    total *= ramp(n, length(rows) - FADE, FADE, False)
    subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "2",
                    "-i", "-", "-c:a", "pcm_f32le", out], input=total.astype("<f4").tobytes(), check=True)


def plan(tsv, pack):
    rows = line(tsv, pack)
    print(f"LEVEL={rows[0][0]} SOLVED={solved(rows):.3f} END={end(rows):.3f} LENGTH={length(rows):.3f}")
    if pack == "escapement":
        times, notes, last = reeds(rows)
        print(f"REEDS={','.join(f'{t:.3f}' for t in times)} NOTES={','.join(map(str, notes))} LAST={last:.3f}")


def listing(tsv, pack):
    rows = line(tsv, pack)
    times, notes, last = reeds(rows) if pack == "escapement" else ([], [], None)
    names = ["A4", "B4", "A4", "E4", "G4", "A4", "G4", "E4"]
    k = 0
    what = {"open": "the card's row tapped, the level opens", "u": "undo", "wait": "wait (a tap on a plate)"}
    for _, at, action, sounds in rows:
        reed = ""
        if pack == "escapement" and action not in ("open", "u"):
            if "solve" in sounds:
                reed = f"  reed D4 at {last:.2f}"
            else:
                reed = f"  reed {names[notes[k] % 8]} at {times[k]:.2f}"
                k += 1
        print(f"  {int(at // 60)}:{at % 60:05.2f}  {what.get(action, 'knob ' + action):<40} "
              f"{', '.join(sounds) or '-'}{reed}")
    print(f"  {int(end(rows) // 60)}:{end(rows) % 60:05.2f}  the beat after the solve: the layer's loop gives way to "
          "its resolution")


# UNSTIR_FINGER's time for each step from its start to the game sounding it, and from there to the next step's start:
# a knob's landing and hold, its turn (0.1 s a step and 0.25), and the lift's settle, then a second; a wait's tap; an
# undo's press. A level's opening winds in and rests (UNSTIR_REST, 2 s) before the first.
OPENING = 4.5
STUDY = 6.0


def lead(action):
    if action == "wait":
        return 0.63
    if action == "u":
        return 0.0
    return 0.45 + 0.1 * abs(int(action.split(":")[1])) + 0.25 + 0.25


def moves(tsv, pack, ratchet, scale):
    steps, clock, was, t = [], OPENING, 0.0, 0.0
    for _, at, action, _ in line(tsv, pack):
        if action == "open":
            continue
        gap = at - was
        was = at
        t += STUDY + (gap - STUDY) * scale if gap > STUDY else gap
        # The step starts so the game sounds it at its time on the film.
        start = t - lead(action)
        if start > clock + 0.05:
            steps.append(f"p{start - clock:.2f}")
            clock = start
        steps.append({"u": "u", "wait": f"{ratchet}:1"}.get(action, action))
        clock += lead(action) + 1.0
    print(f"{t + AFTER:.0f} {','.join(steps)}")


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "plan":
        plan(sys.argv[2], sys.argv[3])
    elif cmd == "mix":
        mix(sys.argv[2], sys.argv[3], sys.argv[4], float(sys.argv[5]), sys.argv[6], sys.argv[7])
    elif cmd == "line":
        listing(sys.argv[2], sys.argv[3])
    elif cmd == "moves":
        moves(sys.argv[2], sys.argv[3], int(sys.argv[4]), float(sys.argv[5]) if len(sys.argv) > 5 else 1.0)
