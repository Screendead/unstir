#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/first-stir-sheet.py <first scene> <last scene> <out.png>
# Lays First Stir's -held shots (top row) over its -played shots (bottom row) for a run of scenes, each cut to the tank
# and the clock under it. Needs Pillow and the Pro Max shots (1320 x 2868) from scripts/shots.sh firststir-.
import sys
from pathlib import Path
from PIL import Image

first, last, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
shots = Path(__file__).resolve().parent.parent / "shots"
# The tank, its bezel and the caption under it on the Pro Max.
box = (30, 790, 1290, 2140)
w, h, gap = box[2] - box[0], box[3] - box[1], 24
scenes = range(first, last + 1)
sheet = Image.new("RGB", (len(scenes) * (w + gap) - gap, 2 * h + gap), "black")
for i, n in enumerate(scenes):
    for row, state in enumerate(["held", "played"]):
        shot = Image.open(shots / f"firststir-{n:02d}-{state}.png").convert("RGB")
        assert shot.size == (1320, 2868), f"{n} {state}: {shot.size}"
        sheet.paste(shot.crop(box), (i * (w + gap), row * (h + gap)))
sheet = sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS)
sheet.save(out)
