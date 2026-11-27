# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: grid.py <bed.wav> <bass.wav> <bpm> <name>: the bed's onsets against its sixteenth grid, and the bass's share
# of energy from 300 Hz to 4 kHz (what a phone's speaker plays of it). The loop starts a quarter beat early.
import subprocess
import sys

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
