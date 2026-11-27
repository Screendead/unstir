# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: profile.py <wav>...: each swipe's RMS in 40 ms windows over its first second, and where its loudest window
# falls and how far it stands over the loudest window of the run (the first 0.4 s), where a stray accent shows.
import os
import subprocess
import sys

import numpy as np

W = 0.04
for path in sys.argv[1:]:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    x = np.frombuffer(raw, dtype=np.float32).astype(np.float64)
    w = int(W * 48000)
    n = min(len(x), 48000) // w
    db = np.array([20 * np.log10(np.sqrt((x[i * w:(i + 1) * w] ** 2).mean()) + 1e-9) for i in range(n)])
    run = int(0.4 / W)
    top = int(np.argmax(db))
    name = os.path.basename(path).removesuffix(".wav")
    print(f"{name}: loudest at {top * W:.2f} s, {db[top] - db[:run].max():+.1f} dB over the run's loudest")
    print("  " + " ".join(f"{v:.0f}" for v in db))
