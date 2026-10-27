#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/escapement-book-sheet.py [order]   Lays scripts/shots.sh's escapement-book-* shots out as
# shots/escapement-book-sheet.png: a row per chapter of six, each tank cropped with its number, layout, clocks and par.
# With an order (comma-separated problem numbers, e.g. 25,26,27,28,30,29), only those, in one row, as
# shots/escapement-order-<order>.png.
import os
import sys
from PIL import Image, ImageDraw, ImageFont

os.chdir(os.path.join(os.path.dirname(__file__), ".."))
rows = [line.rstrip("\n").split("\t") for line in open("scripts/escapement/problems.tsv")]
pars = {int(n): p for n, p in [line.split() for line in os.popen(
    "grep -oE 'problem\\([0-9]+, .*par: [0-9]+' Sources/Pack.swift | sed -E 's/problem\\(([0-9]+),.*par: ([0-9]+)/\\1 \\2/'")]}
chapters = ["The Clock", "The Waiting Move", "Two Clocks", "Wound Back", "Grand Complication"]
cell, gap, head, foot = 420, 14, 56, 64
font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 26)
small = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 20)


def tank(n):
    # The tank on a 1320 x 2868 Pro Max screen, as film.sh crops it.
    return Image.open(f"shots/escapement-book-{n:02d}.png").convert("RGB").crop((60, 820, 1260, 2020)).resize((cell, cell))


def caption(d, x, y, n):
    _, layout, clocks, _ = rows[n - 1]
    d.text((x + 4, y + cell + 8), f"{n:02d}  {layout}  clocks {clocks}", font=small, fill=(235, 235, 235))
    d.text((x + 4, y + cell + 34), f"Unstir in {pars[n]}.", font=small, fill=(216, 64, 42))


order = [int(n) for n in sys.argv[1].split(",")] if len(sys.argv) > 1 else None
grid = [order] if order else [list(range(6 * c + 1, 6 * c + 7)) for c in range(5)]
sheet = Image.new("RGB", (6 * (cell + gap) + gap, len(grid) * (head + cell + foot) + gap), (12, 12, 14))
d = ImageDraw.Draw(sheet)
for i, line in enumerate(grid):
    y = gap + i * (head + cell + foot)
    title = "order " + ", ".join(map(str, order)) if order else f"{i + 1}. {chapters[i]}"
    d.text((gap, y + 14), title, font=font, fill=(243, 234, 216))
    for j, n in enumerate(line):
        x = gap + j * (cell + gap)
        sheet.paste(tank(n), (x, y + head))
        caption(d, x, y + head, n)
out = f"shots/escapement-order-{'-'.join(map(str, order))}.png" if order else "shots/escapement-book-sheet.png"
sheet.save(out)
print(out)
