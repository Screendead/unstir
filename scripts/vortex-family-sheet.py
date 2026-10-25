#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/vortex-family-sheet.py   Lays scripts/shots.sh's vortex-family-* shots out as shots/vortex-family-compare.png:
# a row per picture, clean and on the shallowest, a middle and the deepest of its levels.
import os
from PIL import Image, ImageDraw, ImageFont

os.chdir(os.path.join(os.path.dirname(__file__), ".."))
rows = [("isobars", "flow plates", ["01", "14", "27"]), ("ephemeris", "celestial plates", ["02", "13", "22"]),
        ("cords", "textiles", ["03", "16", "26"])]
cell, gap, label, head = 420, 12, 360, 20
font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 30)
small = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 22)
sheet = Image.new("RGB", (label + 4 * (cell + gap), head + len(rows) * (cell + gap) + 20), (12, 12, 14))
d = ImageDraw.Draw(sheet)
for i, (name, family, levels) in enumerate(rows):
    y = head + i * (cell + gap)
    d.text((24, y + cell // 2 - 18), name, font=font, fill=(240, 240, 240), anchor="lm")
    d.text((24, y + cell // 2 + 20), family, font=small, fill=(130, 130, 140), anchor="lm")
    for j, c in enumerate(["clean"] + levels):
        path = f"shots/vortex-family-{name}-{c}.png"
        if not os.path.exists(path):
            continue
        # The tank, bezel and all, on a 1320 x 2868 Pro Max screen.
        tank = Image.open(path).convert("RGB").crop((40, 800, 1280, 2040)).resize((cell, cell), Image.LANCZOS)
        sheet.paste(tank, (label + j * (cell + gap), y))
        d.text((label + j * (cell + gap) + 12, y + 12), "clean" if c == "clean" else f"vortex {c}", font=small,
               fill=(220, 220, 220))
sheet.save("shots/vortex-family-compare.png")
print("shots/vortex-family-compare.png")
