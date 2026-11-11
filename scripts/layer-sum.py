#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""How loud a pack's solve sums with its loop playing through it, against the effects' ceiling (scripts/sounds.sh's
CEILING). Usage: scripts/layer-sum.py [Sounds/glass]

For each pack it prints the hard bound, every peak added as if they all met (the loop, its resolution and one-shots, and
with plughole's bed, the solve's chime, the loudest heal and, on Escapement, the loudest ratchet), and the worst true
peak found over the alignments the game can make: the resolution on each of the loop's 32 beats, the solve 0, 0.4 or
0.79 s before it, and the bed at eight phases, with and without the loop. Every file plays at full level, a mono one on both channels, as
Sound.swift plays them. Needs ffmpeg and numpy.
"""
import subprocess
import sys

import numpy as np

G = sys.argv[1] if len(sys.argv) > 1 else "Sounds/glass"
R, BEAT, LEAD = 48000, 0.8, 0.2
PACKS = {"lens": [], "escapement": [("d4", None)], "prism": [("swell", -0.4)]}


def read(name, mono=False):
    pan = ["-af", "pan=stereo|c0=c0|c1=c0"] if mono else ["-ac", "2"]
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", f"{G}/{name}", *pan, "-ar", str(R), "-f", "f32le", "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype="<f4").reshape(-1, 2).astype(np.float64)


def true_peak(x):
    """Peak in dB, oversampled 4x through the FFT."""
    n = len(x)
    spec = np.zeros((2 * n + 1, 2), complex)
    spec[: n // 2 + 1] = np.fft.rfft(x, axis=0)
    return 20 * np.log10(np.abs(np.fft.irfft(spec, 4 * n, axis=0) * 4).max())


def peak(x):
    return np.abs(x).max()


def db(a):
    return 20 * np.log10(a)


bed, chime = read("loop.m4a"), read("solve.caf", True)
heal = max(peak(read(f"heal-{i}.caf", True)) for i in range(1, 7))
ratchet = max(peak(read(f"ratchet-{i}.caf", True)) for i in range(1, 5))
for pack, extra in PACKS.items():
    loop, end = read(f"layer-{pack}.m4a"), read(f"layer-{pack}-end.caf")
    shots = [(read(f"layer-{pack}-{name}.caf"), lead) for name, lead in extra]
    layer = peak(loop) + peak(end) + sum(peak(s) for s, _ in shots)
    room = peak(bed) + peak(chime) + heal + (ratchet if pack == "escapement" else 0)
    print(f"{pack}: bound, loop and its one-shots {db(layer):.1f} dB; with bed, chime, heal and any ratchet "
          f"{db(layer + room):.1f} dB; without the loop {db(layer + room - peak(loop)):.1f} dB")
    n = len(end) + 3 * R
    loops = np.tile(loop, (3, 1))
    beds = np.tile(bed, (int(np.ceil((3 * len(loop) + n) / len(bed))) + 1, 1))
    worst = {}
    for k in range(32):
        for lag in (0.0, 0.4, 0.79):
            beat = int((LEAD + k * BEAT) * R) + len(loop)
            s0 = beat - R
            solve = beat - int(lag * R)

            def at(x, i):
                out = np.zeros((n, 2))
                out[i - s0:i - s0 + len(x)] = x[: n - (i - s0)]
                return out
            fx = at(end, beat) + sum(at(s, solve if lead is None else max(beat + int(lead * R), solve))
                                     for s, lead in shots)
            lp, ch = loops[s0:s0 + n], at(chime, solve)
            mixes = [("loop and one-shots", fx + lp)]
            for off in range(0, len(bed), len(bed) // 8):
                bd = beds[off:off + n]
                mixes += [("with bed and chime, loop dropped", fx + ch + bd), ("with bed and chime", fx + ch + bd + lp)]
            for name, x in mixes:
                if peak(x) > worst.get(name, (0,))[0]:
                    worst[name] = (peak(x), x)
    for name, (_, x) in worst.items():
        print(f"  worst found, {name}: {true_peak(x):.1f} dBTP")
