# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: against.py <bass.wav> <ref bass.wav> <bed.wav> <ref bed.wav> <name> <ref>: how far a bed's bass is from its
# round-one bed's, sample by sample, and each bed's share of energy in the bands where a top line turns harsh.
import subprocess
import sys

import numpy as np

bass, rbass, bed, rbed, name, ref = sys.argv[1:7]


def mono(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def shares(x):
    s = np.abs(np.fft.rfft(x)) ** 2
    f = np.fft.rfftfreq(len(x), 1 / 48000)
    return [10 * np.log10(s[(f >= lo) & (f < hi)].sum() / s.sum()) for lo, hi in ((500, 2000), (2000, 5000), (5000, 12000))]


a, b = mono(bass), mono(rbass)
n = min(len(a), len(b))
print(f"{name}: bass differs from {ref}'s by at most {np.max(np.abs(a[:n] - b[:n])):.2e} (its peak {np.max(np.abs(b)):.2f})")
mine, theirs = shares(mono(bed)), shares(mono(rbed))
print(f"{name}: 0.5-2 kHz {mine[0]:.1f} dB ({theirs[0]:.1f}), 2-5 kHz {mine[1]:.1f} ({theirs[1]:.1f}), "
      f"5-12 kHz {mine[2]:.1f} ({theirs[2]:.1f})")
