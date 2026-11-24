#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Usage: scripts/slope-art-sheet.py [shots dir]

Lays the slope-art shots (scripts/shots.sh slope-art-) out a sheet a tier, shots/slope-art-sheet-<tier>.png:
today's picture and sets a, b and c across, as dealt over unstirred, each cut to the tank and the slope round it.
Needs Pillow.
"""
import sys
from pathlib import Path

from PIL import Image

shots = Path(sys.argv[1] if len(sys.argv) > 1 else "shots")
box, scale = (0, 700, 1320, 2140), 0.5
for tier in ["plughole", "whirlpool", "vortex", "maelstrom"]:
    cells = [[Image.open(shots / f"slope-art-{tier}-{art}{state}.png").crop(box) for art in ["today", "a", "b", "c"]]
             for state in ["", "-rest"]]
    w, h = int((box[2] - box[0]) * scale), int((box[3] - box[1]) * scale)
    sheet = Image.new("RGB", (4 * w, 2 * h))
    for row, line in enumerate(cells):
        for column, cell in enumerate(line):
            sheet.paste(cell.resize((w, h), Image.LANCZOS), (column * w, row * h))
    sheet.save(shots / f"slope-art-sheet-{tier}.png")
    print(shots / f"slope-art-sheet-{tier}.png")
