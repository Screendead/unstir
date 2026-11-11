#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/escapement-art-sheet.py plates <from> <to>   Draws each problem's plate on the Mac
#        (scripts/escapement-art.sh), cut to the glass, its layout's knobs and a clock's hub on every rod marked, as
#        shots/escapement-plates-<from>-<to>.png: for composing a plate round its rods.
#        scripts/escapement-art-sheet.py shots <from> <to>    Lays scripts/shots.sh's escapement-plate-* shots out as
#        shots/escapement-plates-<from>-<to>-played.png, a chapter's six problems a row, each as dealt over solved.
#        scripts/escapement-art-sheet.py solved <from> <to>   The same shots, solved only, as ...-solved.png.
#        scripts/escapement-art-sheet.py alternate <problem>  The problem's plate beside its alternate
#        (escapement-plate-alt-*), as dealt over solved, as shots/escapement-plate-alt-<problem>.png.
import os
import re
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

os.chdir(os.path.join(os.path.dirname(__file__), ".."))
font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 26)
ground, bone = (12, 12, 14), (243, 234, 216)
which, first, last = sys.argv[1], int(sys.argv[2]), int(sys.argv[-1])
# Each problem's title and layout, from its row in Pack.swift.
rows = re.findall(r'problem\((\d+), String\(localized: "[^"]+", defaultValue: "([^"]+)",[^\n]*\n[^\n]*\n\s*\.(\w+),',
                  open("Sources/Pack.swift").read())
problems = [(int(n), title, layout) for n, title, layout in rows if first <= int(n) <= last]
columns, gap, head = 6, 14, 48
if which == "plates":
    cell = (430, 430)
    os.makedirs("build/escapement-art/plates", exist_ok=True)
    mask = Image.new("L", cell, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, cell[0] - 1, cell[1] - 1), fill=255)
    lines = 1
else:
    # The play screen from above the tank to the caption on a 1320 x 2868 Pro Max, scaled to the cell.
    crop, cell, lines = (0, 760, 1320, 2200), (430, 469), 2
states = ["solved"] if which == "solved" else ["dealt", "solved"]
if which == "solved":
    lines = 1
if which == "alternate":
    (n, title, layout), columns = problems[0], 2
    problems = [(n, title, f"plate-{n}"), (n, f"{title}, alt", f"plate-alt-{n}")]
depth = -(-len(problems) // columns)
sheet = Image.new("RGB", (columns * (cell[0] + gap) + gap, depth * lines * (cell[1] + head) + gap), ground)
d = ImageDraw.Draw(sheet)
for i, (n, title, layout) in enumerate(problems):
    x, y = gap + i % columns * (cell[0] + gap), gap + i // columns * lines * (cell[1] + head)
    if which == "plates":
        out = f"build/escapement-art/plates/{n}.png"
        if subprocess.run(["scripts/escapement-art.sh", "render", str(n), out, str(2 * cell[0]), layout]).returncode:
            continue
        d.text((x + 4, y + 8), f"{n:02d} {title}", font=font, fill=bone)
        sheet.paste(Image.open(out).convert("RGB").resize(cell, Image.LANCZOS), (x, y + head), mask)
    else:
        for j, state in enumerate(states):
            shot = f"shots/escapement-{layout if which == 'alternate' else f'plate-{n}'}-{state}.png"
            if not os.path.exists(shot):
                continue
            d.text((x + 4, y + j * (cell[1] + head) + 8), f"{n:02d} {title}, {state}", font=font, fill=bone)
            sheet.paste(Image.open(shot).convert("RGB").crop(crop).resize(cell, Image.LANCZOS), (x, y + j * (cell[1] + head) + head))
out = f"shots/escapement-plate-alt-{first}.png" if which == "alternate" else \
    f"shots/escapement-plates-{first}-{last}{ {'plates': '', 'shots': '-played', 'solved': '-solved'}[which]}.png"
sheet.save(out)
print(out)
