#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""One case's frame from several sets, cropped at the same places and laid beside each other at twice the size, each
pixel doubled, for the eye: a row a place, a column a set. Needs Pillow.

  scripts/twist-oracle/crops.py <out.png> <case> <x,y>[,<x,y>...] <label>=<set dir>...

<x,y> is a crop's centre on the screenshot; a crop is 300 px across.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SIDE, ZOOM, GAP, HEAD = 300, 2, 12, 44


def main():
    a = sys.argv[1:]
    if len(a) < 4:
        print(__doc__)
        return 2
    out, case = a[0], a[1]
    numbers = [int(v) for v in a[2].split(",")]
    places = list(zip(numbers[::2], numbers[1::2]))
    sets = [s.split("=", 1) for s in a[3:]]
    cell = SIDE * ZOOM
    sheet = Image.new("RGB", (GAP + len(sets) * (cell + GAP), HEAD + len(places) * (cell + GAP)), (24, 24, 24))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 26)
    except OSError:
        font = ImageFont.load_default()
    for column, (label, folder) in enumerate(sets):
        frame = Image.open(Path(folder) / f"{case}.png").convert("RGB")
        x = GAP + column * (cell + GAP)
        draw.text((x, 8), label, fill=(235, 235, 235), font=font)
        for row, (cx, cy) in enumerate(places):
            crop = frame.crop((cx - SIDE // 2, cy - SIDE // 2, cx + SIDE // 2, cy + SIDE // 2))
            sheet.paste(crop.resize((cell, cell), Image.NEAREST), (x, HEAD + row * (cell + GAP)))
    sheet.save(out)
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
