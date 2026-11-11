#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/escapement-art-sheet.py <a|b|c>   Lays scripts/shots.sh's escapement-art-<direction>-* shots out as
#        shots/escapement-art-<direction>-sheet.png: Pendulum, Cogwheel, Hourglass and Moon phase, as dealt over solved.
#        scripts/escapement-art-sheet.py family    Draws direction b's plate for all 30 problems on the Mac
#        (scripts/escapement-art.sh) as shots/escapement-art-family-sheet.png, a row a chapter, each cut to the glass.
import os
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

os.chdir(os.path.join(os.path.dirname(__file__), ".."))
font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 26)
ground, bone = (12, 12, 14), (243, 234, 216)
which = sys.argv[1]
if which == "family":
    cell, gap, head = 300, 12, 44
    os.makedirs("build/escapement-art/b", exist_ok=True)
    sheet = Image.new("RGB", (6 * (cell + gap) + gap, 5 * (cell + head) + gap), ground)
    d = ImageDraw.Draw(sheet)
    mask = Image.new("L", (cell, cell), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, cell - 1, cell - 1), fill=255)
    for n in range(1, 31):
        out = f"build/escapement-art/b/{n}.png"
        subprocess.run(["scripts/escapement-art.sh", "render", "b", str(n), out, str(2 * cell)], check=True)
        x, y = gap + (n - 1) % 6 * (cell + gap), gap + (n - 1) // 6 * (cell + head)
        d.text((x + 4, y + 6), f"{n:02d}", font=font, fill=bone)
        sheet.paste(Image.open(out).convert("RGB").resize((cell, cell), Image.LANCZOS), (x, y + head), mask)
    out = "shots/escapement-art-family-sheet.png"
else:
    problems = [(2, "Pendulum"), (4, "Cogwheel"), (9, "Hourglass"), (25, "Moon phase")]
    # The play screen from above the tank to the caption on a 1320 x 2868 Pro Max, scaled to the cell.
    crop, cell, gap, head = (0, 760, 1320, 2200), (660, 720), 14, 48
    sheet = Image.new("RGB", (4 * (cell[0] + gap) + gap, 2 * (cell[1] + head) + gap), ground)
    d = ImageDraw.Draw(sheet)
    for j, state in enumerate(["dealt", "solved"]):
        for i, (n, name) in enumerate(problems):
            x, y = gap + i * (cell[0] + gap), gap + j * (cell[1] + head)
            d.text((x + 4, y + 8), f"{n:02d} {name}, {state}", font=font, fill=bone)
            shot = Image.open(f"shots/escapement-art-{which}-{n}-{state}.png").convert("RGB")
            sheet.paste(shot.crop(crop).resize(cell, Image.LANCZOS), (x, y + head))
    out = f"shots/escapement-art-{which}-sheet.png"
sheet.save(out)
print(out)
