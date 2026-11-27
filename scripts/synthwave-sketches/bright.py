# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: bright.py <wav>...: each file's spectral centroid and share of energy above 2 kHz and above 4 kHz.
import os
import subprocess
import sys

import numpy as np

for path in sys.argv[1:]:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    x = np.frombuffer(raw, dtype=np.float32).astype(np.float64)
    s = np.abs(np.fft.rfft(x)) ** 2
    f = np.fft.rfftfreq(len(x), 1 / 48000)
    c = (f * s).sum() / s.sum()
    up2 = 10 * np.log10(s[f >= 2000].sum() / s.sum())
    up4 = 10 * np.log10(s[f >= 4000].sum() / s.sum())
    name = os.path.basename(path).removesuffix(".wav")
    print(f"{name:18s} centroid {c:6.0f} Hz; above 2 kHz {up2:6.1f} dB, above 4 kHz {up4:6.1f} dB")
