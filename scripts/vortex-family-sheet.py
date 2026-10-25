#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/vortex-family-sheet.py   Lays scripts/shots.sh's vortex-family-* shots out as shots/vortex-family-compare.png:
# a row per picture (the three candidates, then whirlpool's five), clean and on vortex 01, 14 and 27.
import os
from PIL import Image, ImageDraw, ImageFont

os.chdir(os.path.join(os.path.dirname(__file__), ".."))
rows = [("isobars", "flow plates"), ("ephemeris", "celestial plates"), ("cords", "textiles"),
        ("glass", "whirlpool"), ("chainmail", "whirlpool"), ("coral", "whirlpool"), ("neurons", "whirlpool"),
        ("marbling", "whirlpool")]
cols = ["clean", "01", "14", "27"]
cell, gap, label, head = 420, 12, 360, 70
font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 30)
small = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 22)
sheet = Image.new("RGB", (label + len(cols) * (cell + gap), head + len(rows) * (cell + gap) + 20), (12, 12, 14))
d = ImageDraw.Draw(sheet)
for j, c in enumerate(cols):
    d.text((label + j * (cell + gap) + cell // 2, head // 2), "clean" if c == "clean" else f"vortex {c}", font=font,
           fill=(220, 220, 220), anchor="mm")
for i, (name, family) in enumerate(rows):
    y = head + i * (cell + gap)
    if i == 3:
        d.line([(10, y - gap // 2), (sheet.width - 10, y - gap // 2)], fill=(90, 90, 100), width=2)
    d.text((24, y + cell // 2 - 18), name, font=font, fill=(240, 240, 240) if i < 3 else (160, 160, 160), anchor="lm")
    d.text((24, y + cell // 2 + 20), family + (" (built)" if i < 3 else ""), font=small, fill=(130, 130, 140), anchor="lm")
    for j, c in enumerate(cols):
        path = f"shots/vortex-family-{name}-{c}.png"
        if not os.path.exists(path):
            continue
        # The tank, bezel and all, on a 1320 x 2868 Pro Max screen.
        tank = Image.open(path).convert("RGB").crop((40, 800, 1280, 2040)).resize((cell, cell), Image.LANCZOS)
        sheet.paste(tank, (label + j * (cell + gap), y))
sheet.save("shots/vortex-family-compare.png")
print("shots/vortex-family-compare.png")
