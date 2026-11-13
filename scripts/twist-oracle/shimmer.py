#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""How much a film of the twist oracle's changes from frame to frame, beside the reference's take of the same case:
the mean and the 99th percentile of the difference between consecutive frames over the middle of the glass, in
levels. The takes never line up to the frame, so this reads the whole take's flicker, not a frame's (needs ffmpeg).

  shimmer.py <ref film dir> <set film dir>
"""
import subprocess
import sys
from pathlib import Path

import numpy as np

SIDE = 640


def activity(path):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-vf", f"crop={SIDE}:{SIDE}", "-pix_fmt", "gray",
                          "-f", "rawvideo", "-"], capture_output=True, check=True).stdout
    frames = np.frombuffer(raw, np.uint8).reshape(-1, SIDE, SIDE).astype(np.int16)
    steps = np.abs(np.diff(frames, axis=0)).mean(axis=(1, 2))
    moving = steps[steps > 0.05]
    return len(frames), float(steps.mean()), float(np.percentile(steps, 99)), float(moving.mean()) if len(moving) else 0.0, len(moving)


ref, got = Path(sys.argv[1]), Path(sys.argv[2])
print(f"{'film':8} {'frames':>12} {'mean change':>20} {'99th percentile':>20} {'mean while moving':>24} {'moving frames':>16}")
for path in sorted(got.glob("*.mp4")):
    if path.stem.endswith("-beside-ref") or not (ref / path.name).exists():
        continue
    a, b = activity(ref / path.name), activity(path)
    print(f"{path.stem:8} {a[0]:5d} {b[0]:5d}  {a[1]:8.3f} {b[1]:8.3f} {b[1] / max(a[1], 1e-9):5.3f}  {a[2]:8.2f} {b[2]:8.2f}  "
          f"{a[3]:8.3f} {b[3]:8.3f} {b[3] / max(a[3], 1e-9):5.3f}  {a[4]:6d} {b[4]:6d}")
